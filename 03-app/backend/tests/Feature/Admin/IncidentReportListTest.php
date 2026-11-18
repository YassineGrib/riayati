<?php

namespace Tests\Feature\Admin;

use App\Enums\ReportStatus;
use App\Filament\Resources\IncidentReports\IncidentReportResource;
use App\Filament\Resources\IncidentReports\Pages\ListIncidentReports;
use App\Filament\Widgets\ReportStatsOverview;
use App\Models\IncidentReport;
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class IncidentReportListTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
        $this->actingAs($this->admin);
        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    private function report(array $attributes = [], ?User $reporter = null): IncidentReport
    {
        return IncidentReport::create(array_merge([
            'reference' => IncidentReport::nextReference(),
            'user_id' => ($reporter ?? User::factory()->father()->create())->id,
            'description' => 'بلاغ للاختبار',
            'incident_at' => now()->subHour(),
            'status' => ReportStatus::UnderReview,
        ], $attributes));
    }

    public function test_list_shows_report_columns_and_view_link(): void
    {
        $reporter = User::factory()->mother()->create(['name' => 'أمينة']);
        $report = $this->report([], $reporter);
        $report->attachments()->create([
            'path' => 'private/evidence.pdf', 'original_name' => 'evidence.pdf',
            'mime' => 'application/pdf', 'kind' => 'file', 'size' => 20, 'sha256' => str_repeat('a', 64),
        ]);

        Livewire::test(ListIncidentReports::class)
            ->assertCanSeeTableRecords([$report])
            ->assertTableColumnStateSet('reference', $report->reference, $report)
            ->assertTableColumnStateSet('user.name', 'أمينة', $report)
            ->assertTableColumnStateSet('attachments_count', 1, $report)
            ->assertTableColumnFormattedStateSet('incident_at', $report->incident_at->format('Y-m-d H:i'), $report)
            ->assertTableColumnFormattedStateSet('status', 'قيد المراجعة', $report)
            ->assertSee('أم')->assertDontSee('private/evidence.pdf')
            ->assertTableActionHasUrl('view', IncidentReportResource::getUrl('view', ['record' => $report]), $report);
        $this->get(IncidentReportResource::getUrl('view', ['record' => $report]))->assertOk();
    }

    public function test_list_filters_by_status(): void
    {
        $pending = $this->report();
        $reviewed = $this->report();
        $reviewed->markReviewed($this->admin);

        Livewire::test(ListIncidentReports::class)->filterTable('status', 'reviewed')
            ->assertCanSeeTableRecords([$reviewed])->assertCanNotSeeTableRecords([$pending]);
    }

    public function test_list_filters_by_reporter_role(): void
    {
        $father = $this->report();
        $mother = $this->report([], User::factory()->mother()->create());

        Livewire::test(ListIncidentReports::class)->filterTable('role', 'mother')
            ->assertCanSeeTableRecords([$mother])->assertCanNotSeeTableRecords([$father]);
    }

    public function test_list_filters_by_inclusive_incident_date_range(): void
    {
        $before = $this->report(['incident_at' => '2026-11-09 23:59:59']);
        $start = $this->report(['incident_at' => '2026-11-10 00:00:00']);
        $end = $this->report(['incident_at' => '2026-11-12 23:59:59']);
        $after = $this->report(['incident_at' => '2026-11-13 00:00:00']);

        Livewire::test(ListIncidentReports::class)->filterTable('incident_at', ['from' => '2026-11-10', 'until' => '2026-11-12'])
            ->assertCanSeeTableRecords([$start, $end])->assertCanNotSeeTableRecords([$before, $after]);
    }

    public function test_mark_reviewed_sets_status_reviewer_and_timestamp(): void
    {
        $report = $this->report();
        Livewire::test(ListIncidentReports::class)->callTableAction('markReviewed', $report);

        $report->refresh();
        $this->assertSame(ReportStatus::Reviewed, $report->status);
        $this->assertSame($this->admin->id, $report->reviewed_by);
        $this->assertNotNull($report->reviewed_at);
    }

    public function test_mark_reviewed_preserves_original_review_on_repeat(): void
    {
        $report = $this->report();
        $firstAdmin = User::factory()->admin()->create();
        $report->markReviewed($firstAdmin);
        $timestamp = $report->reviewed_at->toDateTimeString();
        $this->travel(1)->hours();

        Livewire::test(ListIncidentReports::class)->callTableAction('markReviewed', $report);

        $this->assertSame($firstAdmin->id, $report->refresh()->reviewed_by);
        $this->assertSame($timestamp, $report->reviewed_at->toDateTimeString());
    }

    public function test_bulk_action_only_marks_under_review_records(): void
    {
        $pending = $this->report();
        $reviewed = $this->report();
        $unselected = $this->report();
        $firstAdmin = User::factory()->admin()->create();
        $reviewed->markReviewed($firstAdmin);
        $timestamp = $reviewed->reviewed_at->toDateTimeString();
        $this->travel(1)->hours();

        Livewire::test(ListIncidentReports::class)->callTableBulkAction('markReviewed', [$pending, $reviewed]);

        $this->assertSame(ReportStatus::Reviewed, $pending->refresh()->status);
        $this->assertSame($this->admin->id, $pending->reviewed_by);
        $this->assertSame($firstAdmin->id, $reviewed->refresh()->reviewed_by);
        $this->assertSame($timestamp, $reviewed->reviewed_at->toDateTimeString());
        $this->assertSame(ReportStatus::UnderReview, $unselected->refresh()->status);
    }

    public function test_resource_has_no_create_edit_or_delete_actions(): void
    {
        $report = $this->report();
        $this->assertFalse(IncidentReportResource::canCreate());
        $this->assertFalse(IncidentReportResource::canEdit($report));
        $this->assertFalse(IncidentReportResource::canDelete($report));
        $this->assertSame(['index', 'view'], array_keys(IncidentReportResource::getPages()));

        Livewire::test(ListIncidentReports::class)->assertActionDoesNotExist('create')
            ->assertTableActionDoesNotExist('edit')->assertTableActionDoesNotExist('delete')
            ->assertTableBulkActionDoesNotExist('delete');
    }

    public function test_parents_cannot_open_report_list_or_view(): void
    {
        $report = $this->report();
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $this->actingAs($parent)->get(IncidentReportResource::getUrl())->assertForbidden();
            $this->get(IncidentReportResource::getUrl('view', ['record' => $report]))->assertForbidden();
        }
    }

    public function test_stats_and_navigation_badge_count_seeded_reports(): void
    {
        $this->freezeTime();
        $this->report()->forceFill(['created_at' => now()->subDays(8)])->save();
        $this->report();
        $reviewed = $this->report();
        $reviewed->forceFill(['created_at' => now()->subDays(7)->addSecond()])->save();
        $reviewed->markReviewed($this->admin);

        $widget = Livewire::test(ReportStatsOverview::class)
            ->assertSee('قيد المراجعة')->assertSee('تمت مراجعتها')->assertSee('وردت هذا الأسبوع')
            ->assertSee('2')->assertSee('1');
        $stats = $widget->instance()->getSectionContentComponent()->getDefaultChildComponents();
        $this->assertSame([2, 1, 2], array_map(fn ($stat) => $stat->getValue(), $stats));
        $this->assertSame('2', IncidentReportResource::getNavigationBadge());
        Livewire::test(ListIncidentReports::class)->assertSeeLivewire(ReportStatsOverview::class);
    }
}

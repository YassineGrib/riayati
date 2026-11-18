<?php

namespace Tests\Feature\Admin;

use App\Enums\ReportStatus;
use App\Enums\VisitStatus;
use App\Filament\Pages\Dashboard;
use App\Filament\Resources\IncidentReports\IncidentReportResource;
use App\Filament\Widgets\DashboardStats;
use App\Filament\Widgets\LatestReports;
use App\Filament\Widgets\ReportsByStatusChart;
use App\Filament\Widgets\ReportsPerWeekChart;
use App\Models\Family;
use App\Models\IncidentReport;
use App\Models\User;
use App\Models\Visit;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(now()->setDate(2026, 11, 19)->setTime(12, 0));
        $this->actingAs(User::factory()->admin()->create());
        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    private function report(string $createdAt, ReportStatus $status = ReportStatus::UnderReview): IncidentReport
    {
        $report = IncidentReport::create([
            'reference' => IncidentReport::nextReference(),
            'user_id' => User::factory()->father()->create()->id,
            'description' => 'بلاغ تجريبي', 'incident_at' => $createdAt, 'status' => $status,
        ]);
        $report->forceFill(['created_at' => $createdAt])->save();

        return $report;
    }

    private function chartData(string $widget): array
    {
        $instance = Livewire::test($widget)->instance();

        return (new \ReflectionMethod($instance, 'getData'))->invoke($instance);
    }

    public function test_empty_dashboard_renders_all_four_widgets_and_zero_counts(): void
    {
        $this->get('/admin')->assertOk();
        Livewire::test(Dashboard::class)
            ->assertSeeLivewire(DashboardStats::class)->assertSeeLivewire(ReportsPerWeekChart::class)
            ->assertSeeLivewire(ReportsByStatusChart::class)->assertSeeLivewire(LatestReports::class);
        $stats = Livewire::test(DashboardStats::class)->instance()->getSectionContentComponent()->getDefaultChildComponents();
        $this->assertSame([0, 0, 0, 0, 0], array_map(fn ($stat) => $stat->getValue(), $stats));
        $this->assertSame(array_fill(0, 8, 0), $this->chartData(ReportsPerWeekChart::class)['datasets'][0]['data']);
        $this->assertSame([0, 0], $this->chartData(ReportsByStatusChart::class)['datasets'][0]['data']);
    }

    public function test_stats_count_parents_linked_families_and_active_future_visits(): void
    {
        $this->report('2026-11-19 08:00:00');
        $this->report('2026-11-18 08:00:00', ReportStatus::Reviewed);
        $family = Family::create();
        $father = User::factory()->father()->create(['family_id' => $family->id]);
        User::factory()->mother()->create(['family_id' => $family->id]);
        User::factory()->mother()->create(['family_id' => Family::create()->id]);
        foreach (VisitStatus::cases() as $status) {
            Visit::create(['family_id' => $family->id, 'proposed_by' => $father->id,
                'starts_at' => now()->addDay(), 'ends_at' => now()->addDay()->addHour(), 'status' => $status]);
        }
        Visit::create(['family_id' => $family->id, 'proposed_by' => $father->id,
            'starts_at' => now()->subDay(), 'ends_at' => now()->subDay()->addHour(), 'status' => VisitStatus::Confirmed]);
        $stats = Livewire::test(DashboardStats::class)->instance()->getSectionContentComponent()->getDefaultChildComponents();
        $this->assertSame([1, 1, 5, 1, 3], array_map(fn ($stat) => $stat->getValue(), $stats));
    }

    public function test_charts_zero_fill_eight_monday_weeks_and_split_statuses(): void
    {
        $this->report('2026-09-27 23:59:59'); // Before the eight-week window.
        $this->report('2026-09-28 00:00:00');
        $this->report('2026-10-04 23:59:59', ReportStatus::Reviewed);
        $this->report('2026-10-05 00:00:00');
        $this->report('2026-11-19 08:00:00');
        $this->report('2026-11-23 00:00:00'); // Outside this week.
        $data = $this->chartData(ReportsPerWeekChart::class);
        $this->assertSame([2, 1, 0, 0, 0, 0, 0, 1], $data['datasets'][0]['data']);
        $this->assertCount(8, $data['labels']);
        $this->assertSame([5, 1], $this->chartData(ReportsByStatusChart::class)['datasets'][0]['data']);
    }

    public function test_latest_reports_shows_only_five_newest_with_read_only_view_links(): void
    {
        $reports = collect(range(1, 7))->map(fn ($day) => $this->report("2026-11-{$day} 08:00:00"));
        $latest = $reports->last();
        $page = Livewire::test(LatestReports::class)->assertCanSeeTableRecords($reports->slice(2)->reverse(), inOrder: true)
            ->assertCanNotSeeTableRecords($reports->take(2))
            ->assertTableActionHasUrl('view', IncidentReportResource::getUrl('view', ['record' => $latest]), $latest)
            ->assertTableActionDoesNotExist('edit')->assertTableActionDoesNotExist('delete')
            ->assertTableActionDoesNotExist('markReviewed');
        $this->assertCount(5, $page->instance()->getTableRecords());
    }

    public function test_guests_and_both_parent_roles_cannot_access_dashboard_or_widgets(): void
    {
        auth()->logout();
        $this->get('/admin')->assertRedirect('/admin/login');
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $this->actingAs($parent)->get('/admin')->assertForbidden();
            foreach ([DashboardStats::class, ReportsPerWeekChart::class, ReportsByStatusChart::class, LatestReports::class] as $widget) {
                Livewire::test($widget)->assertForbidden();
            }
        }
    }
}

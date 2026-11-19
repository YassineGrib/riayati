<?php

namespace Tests\Feature\Admin;

use App\Enums\VisitStatus;
use App\Filament\Resources\Visits\Pages\ListVisits;
use App\Filament\Resources\Visits\VisitResource;
use App\Models\Family;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class VisitResourceTest extends TestCase
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

    private function createFamilyWithParents(): array
    {
        $family = Family::create();
        $father = User::factory()->father()->create([
            'name' => 'كمال الأب',
            'family_id' => $family->id,
        ]);
        $mother = User::factory()->mother()->create([
            'name' => 'ليلى الأم',
            'family_id' => $family->id,
        ]);

        return [$family, $father, $mother];
    }

    public function test_guests_and_parents_cannot_access_visits_pages(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();

        $visit = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-25 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-25 14:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        // Guest redirected
        auth()->logout();
        $this->get(VisitResource::getUrl('index'))->assertRedirect(route('filament.admin.auth.login'));
        $this->get(VisitResource::getUrl('view', ['record' => $visit]))->assertRedirect(route('filament.admin.auth.login'));

        // Father 403
        $this->actingAs($father);
        $this->get(VisitResource::getUrl('index'))->assertForbidden();
        $this->get(VisitResource::getUrl('view', ['record' => $visit]))->assertForbidden();

        // Mother 403
        $this->actingAs($mother);
        $this->get(VisitResource::getUrl('index'))->assertForbidden();
        $this->get(VisitResource::getUrl('view', ['record' => $visit]))->assertForbidden();
    }

    public function test_admin_can_view_visits_list_and_sees_expected_columns(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();

        $visit = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-25 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-25 14:00:00'),
            'status' => VisitStatus::Proposed,
            'note' => 'زيارة الحديقة العامة',
        ]);

        Livewire::test(ListVisits::class)
            ->assertCanSeeTableRecords([$visit])
            ->assertTableColumnFormattedStateSet('starts_at', '2026-11-25', $visit)
            ->assertTableColumnFormattedStateSet('time_range', '10:00 - 14:00', $visit)
            ->assertTableColumnFormattedStateSet('status', 'بانتظار الرد', $visit)
            ->assertTableColumnFormattedStateSet('proposer_role', 'أب', $visit)
            ->assertSee('كمال الأب')
            ->assertSee('ليلى الأم')
            ->assertTableActionHasUrl('view', VisitResource::getUrl('view', ['record' => $visit]), $visit);

        $this->get(VisitResource::getUrl('view', ['record' => $visit]))->assertOk();
    }

    public function test_list_status_badges_format_all_statuses(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();

        $proposed = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-21 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-21 12:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        $accepted = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-22 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-22 12:00:00'),
            'status' => VisitStatus::Accepted,
            'responded_by' => $mother->id,
            'responded_at' => now(),
        ]);

        $declined = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $mother->id,
            'starts_at' => Carbon::parse('2026-11-23 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-23 12:00:00'),
            'status' => VisitStatus::Declined,
            'responded_by' => $father->id,
            'responded_at' => now(),
        ]);

        $confirmed = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-24 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-24 12:00:00'),
            'status' => VisitStatus::Confirmed,
            'responded_by' => $mother->id,
            'responded_at' => now()->subDay(),
            'confirmed_at' => now(),
        ]);

        Livewire::test(ListVisits::class)
            ->assertTableColumnFormattedStateSet('status', 'بانتظار الرد', $proposed)
            ->assertTableColumnFormattedStateSet('status', 'تم القبول', $accepted)
            ->assertTableColumnFormattedStateSet('status', 'مرفوضة', $declined)
            ->assertTableColumnFormattedStateSet('status', 'مؤكدة', $confirmed);
    }

    public function test_list_filters_by_status(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();

        $proposed = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-21 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-21 12:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        $confirmed = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-24 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-24 12:00:00'),
            'status' => VisitStatus::Confirmed,
        ]);

        Livewire::test(ListVisits::class)
            ->filterTable('status', VisitStatus::Confirmed->value)
            ->assertCanSeeTableRecords([$confirmed])
            ->assertCanNotSeeTableRecords([$proposed]);
    }

    public function test_list_filters_by_date_range(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();

        $before = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-19 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-19 12:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        $inside = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-25 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-25 12:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        $after = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-30 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-30 12:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        Livewire::test(ListVisits::class)
            ->filterTable('starts_at', ['from' => '2026-11-20', 'until' => '2026-11-26'])
            ->assertCanSeeTableRecords([$inside])
            ->assertCanNotSeeTableRecords([$before, $after]);
    }

    public function test_visit_view_page_shows_details_read_only(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();

        $visit = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-25 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-25 14:00:00'),
            'note' => 'زيارة ممتعة في نهاية الأسبوع',
            'status' => VisitStatus::Confirmed,
            'responded_by' => $mother->id,
            'responded_at' => Carbon::parse('2026-11-20 15:00:00'),
            'confirmed_at' => Carbon::parse('2026-11-21 09:00:00'),
        ]);

        $this->get(VisitResource::getUrl('view', ['record' => $visit]))
            ->assertOk()
            ->assertSee('زيارة ممتعة في نهاية الأسبوع')
            ->assertSee('كمال الأب')
            ->assertSee('ليلى الأم')
            ->assertSee('مؤكدة')
            ->assertDontSee('حفظ')
            ->assertDontSee('تعديل')
            ->assertDontSee('حذف');
    }

    public function test_visit_resource_cannot_create_edit_or_delete(): void
    {
        [$family, $father, $mother] = $this->createFamilyWithParents();
        $visit = Visit::create([
            'family_id' => $family->id,
            'proposed_by' => $father->id,
            'starts_at' => Carbon::parse('2026-11-25 10:00:00'),
            'ends_at' => Carbon::parse('2026-11-25 14:00:00'),
            'status' => VisitStatus::Proposed,
        ]);

        $this->assertFalse(VisitResource::canCreate());
        $this->assertFalse(VisitResource::canEdit($visit));
        $this->assertFalse(VisitResource::canDelete($visit));
        $this->assertFalse(VisitResource::canDeleteAny());
    }
}

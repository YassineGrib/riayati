<?php

namespace Tests\Feature\Api;

use App\Enums\VisitStatus;
use App\Models\Family;
use App\Models\User;
use App\Models\Visit;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VisitTest extends TestCase
{
    use RefreshDatabase;

    private User $father;

    private User $mother;

    protected function setUp(): void
    {
        parent::setUp();
        $family = Family::create();
        $this->father = User::factory()->father()->create(['family_id' => $family->id]);
        $this->mother = User::factory()->mother()->create(['family_id' => $family->id]);
    }

    private function as(User $user): static
    {
        return $this->actingAs($user, 'sanctum');
    }

    private function slot(int $days = 3, string $from = '10:00', string $to = '14:00'): array
    {
        return ['date' => now()->addDays($days)->format('Y-m-d'), 'from' => $from, 'to' => $to];
    }

    private function propose(User $by, array $slot = null, array $extra = []): int
    {
        return $this->as($by)->postJson('/api/visits', ($slot ?? $this->slot()) + $extra)->assertCreated()->json('visit.id');
    }

    public function test_a_parent_proposes_a_visit_and_the_other_must_respond(): void
    {
        $response = $this->as($this->father)->postJson('/api/visits', $this->slot() + ['note' => 'مكان التسليم أمام المدرسة'])
            ->assertCreated()
            ->assertJsonPath('visit.status', 'proposed')
            ->assertJsonPath('visit.from', '10:00')
            ->assertJsonPath('visit.proposed_by_me', true)
            ->assertJsonPath('visit.needs_my_response', false);

        $id = $response->json('visit.id');
        $this->as($this->mother)->getJson("/api/visits/{$id}")
            ->assertOk()
            ->assertJsonPath('visit.proposed_by_me', false)
            ->assertJsonPath('visit.needs_my_response', true)
            ->assertJsonPath('visit.note', 'مكان التسليم أمام المدرسة');
    }

    public function test_the_full_flow_propose_accept_confirm(): void
    {
        $id = $this->propose($this->father);

        $this->as($this->mother)->postJson("/api/visits/{$id}/accept")->assertOk()->assertJsonPath('visit.status', 'accepted');
        $this->as($this->father)->getJson("/api/visits/{$id}")->assertJsonPath('visit.can_confirm', true);
        $this->as($this->father)->postJson("/api/visits/{$id}/confirm")
            ->assertOk()
            ->assertJsonPath('visit.status', 'confirmed')
            ->assertJsonPath('visit.timeline.2.step', 'confirmed');

        $visit = Visit::find($id);
        $this->assertSame($this->mother->id, $visit->responded_by);
        $this->assertNotNull($visit->confirmed_at);
    }

    public function test_a_declined_visit_is_final_and_frees_the_slot(): void
    {
        $id = $this->propose($this->father);

        $this->as($this->mother)->postJson("/api/visits/{$id}/decline")->assertOk()->assertJsonPath('visit.status', 'declined');
        $this->as($this->mother)->postJson("/api/visits/{$id}/accept")->assertStatus(409);
        $this->as($this->father)->postJson("/api/visits/{$id}/confirm")->assertStatus(409);
        // the same slot can be proposed again
        $this->propose($this->father);
    }

    public function test_only_the_other_parent_responds_and_only_the_proposer_confirms(): void
    {
        $id = $this->propose($this->father);

        $this->as($this->father)->postJson("/api/visits/{$id}/accept")->assertForbidden();
        $this->as($this->father)->postJson("/api/visits/{$id}/decline")->assertForbidden();
        $this->as($this->father)->postJson("/api/visits/{$id}/confirm")->assertStatus(409); // not accepted yet

        $this->as($this->mother)->postJson("/api/visits/{$id}/accept")->assertOk();
        $this->as($this->mother)->postJson("/api/visits/{$id}/confirm")->assertForbidden();
        $this->as($this->mother)->postJson("/api/visits/{$id}/accept")->assertStatus(409); // already answered
    }

    public function test_overlapping_visits_are_refused_but_back_to_back_is_fine(): void
    {
        $this->propose($this->father, $this->slot(3, '10:00', '14:00'));

        $this->as($this->mother)->postJson('/api/visits', $this->slot(3, '13:00', '16:00'))
            ->assertUnprocessable()->assertJsonValidationErrors('from');
        $this->as($this->mother)->postJson('/api/visits', $this->slot(3, '14:00', '16:00'))->assertCreated();
    }

    public function test_validation(): void
    {
        $this->as($this->father)->postJson('/api/visits', $this->slot(3, '14:00', '10:00'))->assertJsonValidationErrors('to');
        $this->as($this->father)->postJson('/api/visits', ['date' => now()->subDay()->format('Y-m-d'), 'from' => '10:00', 'to' => '12:00'])->assertJsonValidationErrors('date');
        $this->as($this->father)->postJson('/api/visits', ['date' => 'tomorrow', 'from' => '10', 'to' => '12'])->assertJsonValidationErrors(['date', 'from']);
        $this->as($this->father)->postJson('/api/visits', $this->slot() + ['note' => str_repeat('ب', 301)])->assertJsonValidationErrors('note');
        $this->assertDatabaseCount('visits', 0);
    }

    public function test_a_proposal_cannot_be_accepted_after_it_has_started(): void
    {
        $id = $this->propose($this->father);
        $this->travel(4)->days();

        $this->as($this->mother)->postJson("/api/visits/{$id}/accept")->assertUnprocessable()->assertJsonValidationErrors('visit');
    }

    public function test_an_unlinked_parent_is_told_to_link_first(): void
    {
        $alone = User::factory()->mother()->create();

        $this->as($alone)->getJson('/api/visits')->assertForbidden()->assertJsonPath('code', 'not_linked');
        $this->as($alone)->postJson('/api/visits', $this->slot())->assertForbidden()->assertJsonPath('code', 'not_linked');
    }

    public function test_guests_and_admins_cannot_use_the_calendar(): void
    {
        $this->getJson('/api/visits')->assertUnauthorized();
        $this->as(User::factory()->admin()->create())->getJson('/api/visits')->assertForbidden();
    }

    public function test_another_family_cannot_see_or_touch_the_visit(): void
    {
        $id = $this->propose($this->father);

        $otherFamily = Family::create();
        $a = User::factory()->father()->create(['family_id' => $otherFamily->id]);
        User::factory()->mother()->create(['family_id' => $otherFamily->id]);

        $this->as($a)->getJson("/api/visits/{$id}")->assertNotFound();
        $this->as($a)->postJson("/api/visits/{$id}/accept")->assertNotFound();
        $this->as($a)->getJson('/api/visits')->assertJsonCount(0, 'visits');
    }

    public function test_the_month_view_and_the_upcoming_list(): void
    {
        $soon = $this->propose($this->father, $this->slot(2));
        $later = $this->propose($this->father, $this->slot(40));
        $declined = $this->propose($this->father, $this->slot(5));
        $this->as($this->mother)->postJson("/api/visits/{$declined}/decline");

        $month = now()->addDays(40)->format('Y-m');
        $this->as($this->mother)->getJson("/api/visits?month={$month}")->assertOk()->assertJsonCount(1, 'visits')->assertJsonPath('visits.0.id', $later);

        $upcoming = $this->as($this->mother)->getJson('/api/visits/upcoming')->assertOk();
        $ids = collect($upcoming->json('visits'))->pluck('id')->all();
        $this->assertSame([$soon, $later], $ids); // sorted, declined left out
        $this->as($this->mother)->getJson('/api/visits?month=2026-13')->assertUnprocessable();
    }

    public function test_the_payload_never_reveals_the_other_parents_identity(): void
    {
        $id = $this->propose($this->father);

        $payload = $this->as($this->mother)->getJson("/api/visits/{$id}")->json('visit');

        $this->assertArrayNotHasKey('proposed_by', $payload);
        $this->assertStringNotContainsString($this->father->email, json_encode($payload));
        $this->assertStringNotContainsString($this->father->name, json_encode($payload));
    }

    public function test_status_labels_match_the_app_copy(): void
    {
        $this->assertSame('بانتظار الرد', VisitStatus::Proposed->label());
        $this->assertSame('مؤكدة', VisitStatus::Confirmed->label());
    }
}

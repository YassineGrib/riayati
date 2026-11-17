<?php

namespace Tests\Feature\Api;

use App\Models\Family;
use App\Models\InviteCode;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FamilyLinkTest extends TestCase
{
    use RefreshDatabase;

    private function invite(User $user): string
    {
        return $this->actingAs($user, 'sanctum')->postJson('/api/family/invite')->assertCreated()->json('code');
    }

    public function test_a_parent_can_generate_a_code_in_the_agreed_format(): void
    {
        $father = User::factory()->father()->create();

        $code = $this->invite($father);

        $this->assertMatchesRegularExpression('/^[A-HJKMNP-Z2-9]{3}-[A-HJKMNP-Z2-9]{3}$/', $code);
        $this->assertNotNull($father->fresh()->family_id);
        $this->assertTrue(InviteCode::first()->expires_at->between(now()->addHours(47), now()->addHours(49)));
    }

    public function test_a_new_code_replaces_the_previous_unused_one(): void
    {
        $father = User::factory()->father()->create();

        $first = $this->invite($father);
        $second = $this->invite($father);

        $this->assertNotSame($first, $second);
        $this->assertDatabaseCount('invite_codes', 1);
    }

    public function test_the_other_parent_links_with_the_code_and_both_become_linked(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $code = $this->invite($father);

        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => strtolower($code)])
            ->assertOk()
            ->assertJson(['linked' => true, 'partner_role' => 'father']);

        $this->assertSame($father->fresh()->family_id, $mother->fresh()->family_id);
        $this->assertTrue($father->fresh()->isLinked());
        $this->actingAs($father, 'sanctum')->getJson('/api/family')->assertJson(['linked' => true, 'partner_role' => 'mother']);
        $this->assertNotNull(InviteCode::first()->used_at);
    }

    public function test_a_code_works_only_once(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $other = User::factory()->mother()->create();
        $code = $this->invite($father);

        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $code])->assertOk();
        $this->actingAs($other, 'sanctum')->postJson('/api/family/link', ['code' => $code])->assertUnprocessable();
    }

    public function test_an_expired_or_unknown_code_is_rejected_with_the_same_message(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $code = $this->invite($father);
        InviteCode::query()->update(['expires_at' => now()->subMinute()]);

        $expired = $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $code]);
        $unknown = $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => 'ZZZ-ZZZ']);

        $expired->assertUnprocessable();
        $this->assertSame($expired->json('errors.code'), $unknown->json('errors.code'));
        $this->assertNull($mother->fresh()->family_id);
    }

    public function test_two_parents_with_the_same_role_cannot_be_linked(): void
    {
        $father = User::factory()->father()->create();
        $otherFather = User::factory()->father()->create();
        $code = $this->invite($father);

        $this->actingAs($otherFather, 'sanctum')->postJson('/api/family/link', ['code' => $code])->assertUnprocessable();
        $this->assertFalse($father->fresh()->isLinked());
    }

    public function test_you_cannot_redeem_your_own_code(): void
    {
        $father = User::factory()->father()->create();
        $code = $this->invite($father);

        $this->actingAs($father, 'sanctum')->postJson('/api/family/link', ['code' => $code])->assertUnprocessable();
    }

    public function test_an_already_linked_family_cannot_take_a_third_member(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $code = $this->invite($father);
        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $code])->assertOk();

        $this->actingAs($father, 'sanctum')->postJson('/api/family/invite')->assertStatus(409);
    }

    public function test_a_parent_already_linked_elsewhere_cannot_link_again(): void
    {
        $father1 = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $code1 = $this->invite($father1);
        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $code1])->assertOk();

        $father2 = User::factory()->father()->create();
        $code2 = $this->invite($father2);

        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $code2])->assertStatus(409);
        $this->assertNull($father2->fresh()->partner());
    }

    public function test_the_pending_family_of_the_redeemer_is_cleaned_up(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $this->invite($mother); // the mother generated a code too, creating her own family
        $motherFamily = $mother->fresh()->family_id;
        $fatherCode = $this->invite($father);

        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $fatherCode])->assertOk();

        $this->assertNull(Family::find($motherFamily));
        $this->assertSame($father->fresh()->family_id, $mother->fresh()->family_id);
    }

    public function test_an_admin_and_guests_cannot_use_linking(): void
    {
        $this->postJson('/api/family/invite')->assertUnauthorized();
        $this->actingAs(User::factory()->admin()->create(), 'sanctum')->postJson('/api/family/invite')->assertForbidden();
    }
}

<?php

namespace Tests\Feature\Api;

use App\Enums\Role;
use App\Models\Family;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    private function data(User $user, array $overrides = []): array
    {
        return array_merge(['name' => 'أمينة الجديدة', 'email' => $user->email,
            'phone' => '+213 555-123-456', 'wilaya' => 'الجزائر', 'children_count' => 2], $overrides);
    }

    public function test_update_persists_normalized_details_and_me_returns_them(): void
    {
        $user = User::factory()->mother()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/me', $this->data($user))
            ->assertOk()->assertJsonPath('user.phone', '+213555123456')
            ->assertJsonPath('user.wilaya', 'الجزائر')->assertJsonPath('user.children_count', 2);
        $this->getJson('/api/me')->assertJsonPath('user.name', 'أمينة الجديدة');
        $this->assertDatabaseHas('users', ['id' => $user->id, 'phone' => '+213555123456', 'children_count' => 2]);
    }

    public function test_email_must_be_unique_after_normalization(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/me', $this->data($user, [
            'email' => 'TAKEN@example.com', 'current_password' => 'password',
        ]))->assertUnprocessable()->assertJsonValidationErrors('email');
    }

    public function test_email_change_requires_correct_current_password_and_is_atomic(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $this->actingAs($user, 'sanctum');
        $original = $user->name;
        foreach ([null, 'wrong'] as $password) {
            $this->putJson('/api/me', $this->data($user, [
                'email' => 'new@example.com', 'current_password' => $password,
            ]))->assertUnprocessable()->assertJsonValidationErrors('current_password');
            $this->assertSame($original, $user->fresh()->name);
        }
        $this->putJson('/api/me', $this->data($user, [
            'email' => 'NEW@example.com', 'current_password' => 'old-password',
        ]))->assertOk()->assertJsonPath('user.email', 'new@example.com');
    }

    public function test_wrong_password_has_arabic_field_error(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/me', $this->data($user, [
            'email' => 'new@example.com', 'current_password' => 'wrong',
        ]))->assertJsonPath('errors.current_password.0', 'كلمة المرور الحالية غير صحيحة.');
    }

    public function test_phone_format_and_optional_details(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');
        foreach (['123', '+33123456789', '05551234567', '+2130555123456', ['bad']] as $phone) {
            $this->putJson('/api/me', $this->data($user, ['phone' => $phone]))
                ->assertUnprocessable()->assertJsonValidationErrors('phone');
        }
        $this->putJson('/api/me', $this->data($user, ['phone' => '0555 123-456']))
            ->assertOk()->assertJsonPath('user.phone', '0555123456');
    }

    public function test_optional_details_can_be_cleared(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/me', $this->data($user));
        $this->putJson('/api/me', $this->data($user, ['phone' => null, 'wilaya' => null, 'children_count' => null]))
            ->assertOk()->assertJsonPath('user.phone', null)->assertJsonPath('user.wilaya', null)
            ->assertJsonPath('user.children_count', null);
    }

    public function test_validation_boundaries(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');
        foreach ([-1, 21, 1.5] as $count) {
            $this->putJson('/api/me', $this->data($user, ['children_count' => $count]))
                ->assertUnprocessable()->assertJsonValidationErrors('children_count');
        }
        $this->putJson('/api/me', $this->data($user, ['name' => 'أ', 'email' => 'bad', 'wilaya' => str_repeat('a', 61)]))
            ->assertJsonValidationErrors(['name', 'email', 'wilaya']);
    }

    public function test_role_and_unknown_fields_cannot_be_changed(): void
    {
        $user = User::factory()->mother()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/me', $this->data($user, [
            'role' => 'admin', 'family_id' => 100, 'password' => 'hacked', 'id' => 99,
        ]))->assertOk()->assertJsonPath('user.role', 'mother');
        $this->assertSame(Role::Mother, $user->fresh()->role);
        $this->assertNull($user->fresh()->family_id);
    }

    public function test_count_boundaries_and_unchanged_email_do_not_require_password(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');
        foreach ([0, 20] as $count) {
            $this->putJson('/api/me', $this->data($user, ['children_count' => $count]))
                ->assertOk()->assertJsonPath('user.children_count', $count);
        }
    }

    public function test_guests_cannot_update(): void
    {
        $this->putJson('/api/me', [])->assertUnauthorized();
    }

    public function test_linked_parents_private_data_never_appears(): void
    {
        $family = Family::create();
        $user = User::factory()->mother()->create(['family_id' => $family->id]);
        $partner = User::factory()->father()->create(['family_id' => $family->id, 'phone' => '0666666666',
            'wilaya' => 'وهران', 'children_count' => 9]);
        $this->actingAs($user, 'sanctum');
        foreach ([$this->getJson('/api/me'), $this->putJson('/api/me', $this->data($user))] as $response) {
            $response->assertOk()->assertJsonPath('user.partner_role', 'father');
            $this->assertSame(['id', 'name', 'email', 'role', 'linked', 'partner_role', 'phone', 'wilaya', 'children_count'], array_keys($response->json('user')));
            foreach ([$partner->email, $partner->name, $partner->phone, $partner->wilaya] as $secret) {
                $this->assertStringNotContainsString($secret, $response->getContent());
            }
        }
    }

    public function test_updates_are_throttled(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');
        for ($i = 0; $i < 6; $i++) {
            $this->putJson('/api/me', $this->data($user))->assertOk();
        }
        $this->putJson('/api/me', $this->data($user))->assertStatus(429);
    }
}

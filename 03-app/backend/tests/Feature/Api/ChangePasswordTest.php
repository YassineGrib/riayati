<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ChangePasswordTest extends TestCase
{
    use RefreshDatabase;

    private function data(array $overrides = []): array
    {
        return array_merge([
            'current_password' => 'old-password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ], $overrides);
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->putJson('/api/password', $this->data())->assertUnauthorized();
    }

    public function test_wrong_current_password_does_not_change_password_or_tokens(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $token = $user->createToken('phone');
        $this->withToken($token->plainTextToken)->putJson('/api/password', $this->data(['current_password' => 'wrong']))
            ->assertUnprocessable()->assertJsonValidationErrors('current_password')
            ->assertJsonPath('errors.current_password.0', 'كلمة المرور الحالية غير صحيحة.');
        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $token->accessToken->id]);
    }

    public function test_success_updates_password_and_revokes_only_other_tokens_of_this_user(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $current = $user->createToken('phone');
        $other = $user->createToken('tablet');
        $unrelated = User::factory()->create()->createToken('unrelated');
        $this->withToken($current->plainTextToken)->putJson('/api/password', $this->data())->assertOk();
        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $current->accessToken->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $other->accessToken->id]);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $unrelated->accessToken->id]);
        $this->withToken($current->plainTextToken)->getJson('/api/me')->assertOk();
    }

    public function test_new_password_requires_eight_characters_and_confirmation(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $this->withToken($user->createToken('phone')->plainTextToken)
            ->putJson('/api/password', $this->data(['password' => 'short', 'password_confirmation' => 'different']))
            ->assertUnprocessable()->assertJsonValidationErrors('password');
        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    public function test_password_changes_are_rate_limited(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $this->withToken($user->createToken('phone')->plainTextToken);
        for ($i = 0; $i < 6; $i++) {
            $this->putJson('/api/password', $this->data(['current_password' => 'wrong']))->assertUnprocessable();
        }
        $this->putJson('/api/password', $this->data())->assertStatus(429);
    }
}

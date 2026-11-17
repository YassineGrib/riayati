<?php

namespace Tests\Feature\Api;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function valid(array $overrides = []): array
    {
        return array_merge([
            'name' => 'أمينة',
            'email' => 'amina@example.com',
            'password' => 'password-123',
            'role' => 'mother',
            'terms' => true,
        ], $overrides);
    }

    public function test_a_parent_can_register_and_gets_a_token(): void
    {
        $this->postJson('/api/register', $this->valid())
            ->assertCreated()
            ->assertJsonPath('user.role', 'mother')
            ->assertJsonPath('user.linked', false)
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'role', 'phone', 'wilaya', 'children_count']]);

        $user = User::firstWhere('email', 'amina@example.com');
        $this->assertNotNull($user->terms_accepted_at);
        $this->assertSame(Role::Mother, $user->role);
        $this->assertNotSame('password-123', $user->password);
    }

    public function test_registration_cannot_create_an_admin(): void
    {
        $this->postJson('/api/register', $this->valid(['role' => 'admin']))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');

        $this->assertDatabaseCount('users', 0);
    }

    public function test_registration_requires_consent_a_strong_enough_password_and_a_unique_email(): void
    {
        $this->postJson('/api/register', $this->valid(['terms' => false]))->assertJsonValidationErrors('terms');
        $this->postJson('/api/register', $this->valid(['password' => 'short']))->assertJsonValidationErrors('password');

        User::factory()->create(['email' => 'amina@example.com']);
        $this->postJson('/api/register', $this->valid())->assertJsonValidationErrors('email');
    }

    public function test_login_returns_a_token_for_correct_credentials(): void
    {
        User::factory()->mother()->create(['email' => 'amina@example.com', 'password' => 'password-123',
            'phone' => '0555123456', 'wilaya' => 'الجزائر', 'children_count' => 0]);

        $this->postJson('/api/login', ['email' => 'AMINA@example.com', 'password' => 'password-123'])
            ->assertOk()
            ->assertJsonStructure(['token', 'user'])
            ->assertJsonPath('user.phone', '0555123456')
            ->assertJsonPath('user.wilaya', 'الجزائر')
            ->assertJsonPath('user.children_count', 0);
    }

    public function test_login_gives_the_same_error_for_a_wrong_password_and_an_unknown_email(): void
    {
        User::factory()->create(['email' => 'amina@example.com', 'password' => 'password-123']);

        $wrong = $this->postJson('/api/login', ['email' => 'amina@example.com', 'password' => 'nope-nope-1']);
        $unknown = $this->postJson('/api/login', ['email' => 'nobody@example.com', 'password' => 'password-123']);

        $wrong->assertUnprocessable();
        $this->assertSame($wrong->json('errors.email'), $unknown->json('errors.email'));
    }

    public function test_me_requires_a_token_and_logout_revokes_it(): void
    {
        $this->getJson('/api/me')->assertUnauthorized();

        $token = $this->postJson('/api/register', $this->valid())->json('token');
        $this->withToken($token)->getJson('/api/me')->assertOk()->assertJsonPath('user.email', 'amina@example.com');

        $this->withToken($token)->postJson('/api/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_the_profile_never_exposes_the_other_parents_details(): void
    {
        $user = User::factory()->mother()->create();
        $payload = $this->actingAs($user, 'sanctum')->getJson('/api/me')->json('user');

        $this->assertSame(['id', 'name', 'email', 'role', 'linked', 'partner_role', 'phone', 'wilaya', 'children_count'], array_keys($payload));
    }

    public function test_login_is_rate_limited(): void
    {
        for ($i = 0; $i < 6; $i++) {
            $this->postJson('/api/login', ['email' => 'a@example.com', 'password' => 'x']);
        }

        $this->postJson('/api/login', ['email' => 'a@example.com', 'password' => 'x'])->assertStatus(429);
    }
}

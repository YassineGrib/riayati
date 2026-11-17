<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_reset_link_points_to_the_web_page_and_the_answer_hides_whether_the_email_exists(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'amina@example.com']);

        $known = $this->postJson('/api/forgot-password', ['email' => 'amina@example.com']);
        $unknown = $this->postJson('/api/forgot-password', ['email' => 'nobody@example.com']);

        $known->assertOk();
        $this->assertSame($known->json('message'), $unknown->json('message'));
        Notification::assertSentTo($user, ResetPassword::class, function ($n) use ($user) {
            return str_contains($n->toMail($user)->actionUrl, '/reset-password/');
        });
        // Only the known address produced a notification.
        Notification::assertSentTimes(ResetPassword::class, 1);
    }

    public function test_a_valid_token_sets_the_new_password_and_signs_out_other_sessions(): void
    {
        $user = User::factory()->create(['email' => 'amina@example.com', 'password' => 'old-password-1']);
        $user->createToken('phone');
        $token = Password::createToken($user);

        $this->postJson('/api/reset-password', [
            'token' => $token, 'email' => 'amina@example.com',
            'password' => 'new-password-1', 'password_confirmation' => 'new-password-1',
        ])->assertOk();

        $this->assertTrue(Hash::check('new-password-1', $user->fresh()->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_a_bad_token_is_rejected(): void
    {
        User::factory()->create(['email' => 'amina@example.com']);

        $this->postJson('/api/reset-password', [
            'token' => 'wrong', 'email' => 'amina@example.com',
            'password' => 'new-password-1', 'password_confirmation' => 'new-password-1',
        ])->assertUnprocessable()->assertJsonValidationErrors('email');
    }

    public function test_the_web_page_opens_and_the_form_submits(): void
    {
        $user = User::factory()->create(['email' => 'amina@example.com']);
        $token = Password::createToken($user);

        $this->get('/reset-password/'.$token.'?email=amina@example.com')->assertOk()->assertSee('تعيين كلمة مرور جديدة');

        $this->post('/reset-password', [
            'token' => $token, 'email' => 'amina@example.com',
            'password' => 'new-password-1', 'password_confirmation' => 'new-password-1',
        ])->assertRedirect(route('password.reset.done'));
    }
}

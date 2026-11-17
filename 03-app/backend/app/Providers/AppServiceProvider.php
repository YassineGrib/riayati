<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // The emailed link opens a small web page (resources/views/auth/reset-password.blade.php).
        ResetPassword::createUrlUsing(fn ($user, string $token) => url('/reset-password/'.$token).'?email='.urlencode($user->getEmailForPasswordReset()));
    }
}

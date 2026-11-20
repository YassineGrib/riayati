<?php

use App\Http\Controllers\Api\PasswordResetController;
use Illuminate\Support\Facades\Route;

// The public landing + download page lives in public/landing (uploaded by tools/deploy-landing.ps1).
// Without it (local development, tests) the root answers with the app name.
Route::get('/', function () {
    $page = public_path('landing/index.html');

    return is_file($page)
        ? response()->file($page, ['Cache-Control' => 'no-cache'])
        : response()->json(['name' => config('app.name')]);
});

// Page opened from the password-reset email.
Route::get('/reset-password/{token}', fn (string $token) => view('auth.reset-password', [
    'token' => $token,
    'email' => request('email'),
]))->name('password.reset');

Route::post('/reset-password', [PasswordResetController::class, 'resetFromWeb'])
    ->middleware('throttle:6,1')->name('password.reset.submit');

Route::view('/reset-password-done', 'auth.reset-done')->name('password.reset.done');

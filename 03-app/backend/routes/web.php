<?php

use App\Http\Controllers\Api\PasswordResetController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json(['name' => config('app.name')]));

// Page opened from the password-reset email.
Route::get('/reset-password/{token}', fn (string $token) => view('auth.reset-password', [
    'token' => $token,
    'email' => request('email'),
]))->name('password.reset');

Route::post('/reset-password', [PasswordResetController::class, 'resetFromWeb'])
    ->middleware('throttle:6,1')->name('password.reset.submit');

Route::view('/reset-password-done', 'auth.reset-done')->name('password.reset.done');

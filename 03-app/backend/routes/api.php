<?php

use App\Http\Controllers\Api\AttachmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CenterController;
use App\Http\Controllers\Api\ContentController;
use App\Http\Controllers\Api\FamilyController;
use App\Http\Controllers\Api\PasswordController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\VisitController;
use Illuminate\Support\Facades\Route;

// Public: email + password only (no OTP).
Route::middleware('throttle:6,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [PasswordResetController::class, 'forgot']);
    Route::post('/reset-password', [PasswordResetController::class, 'reset']);
});

// Attachment files: reachable only with a valid, unexpired signed link issued to the author or an admin.
Route::get('/attachments/{attachment}/download', [AttachmentController::class, 'download'])
    ->middleware(['signed', 'throttle:60,1'])->name('attachments.download');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/contents', [ContentController::class, 'index']);
    Route::get('/contents/{slug}', [ContentController::class, 'show']);
    Route::get('/centers', [CenterController::class, 'index']);
    Route::get('/centers/{id}', [CenterController::class, 'show'])->whereNumber('id');
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'updateProfile'])->middleware('throttle:6,1');
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::put('/password', [PasswordController::class, 'update'])->middleware('throttle:6,1');

    // Linking the two parents' accounts with an invite code.
    Route::get('/family', [FamilyController::class, 'show']);
    Route::post('/family/invite', [FamilyController::class, 'invite']);
    Route::post('/family/link', [FamilyController::class, 'link'])->middleware('throttle:10,1');

    // Shared visit calendar (the two linked parents only).
    Route::get('/visits', [VisitController::class, 'index']);
    Route::get('/visits/upcoming', [VisitController::class, 'upcoming']);
    Route::post('/visits', [VisitController::class, 'store'])->middleware('throttle:30,1');
    Route::get('/visits/{visit}', [VisitController::class, 'show'])->whereNumber('visit');
    Route::post('/visits/{visit}/accept', [VisitController::class, 'accept'])->whereNumber('visit');
    Route::post('/visits/{visit}/decline', [VisitController::class, 'decline'])->whereNumber('visit');
    Route::post('/visits/{visit}/confirm', [VisitController::class, 'confirm'])->whereNumber('visit');

    // Incident reports. There is no update or delete route on purpose: a submitted report is evidence.
    Route::get('/reports', [ReportController::class, 'index']);
    Route::post('/reports', [ReportController::class, 'store'])->middleware('throttle:20,1');
    Route::get('/reports/{report}', [ReportController::class, 'show'])->whereNumber('report');
    Route::get('/reports/{report}/pdf', [ReportController::class, 'pdf'])->whereNumber('report')->middleware('throttle:20,1');
    Route::get('/reports/{report}/attachments/{attachment}/link', [AttachmentController::class, 'link'])
        ->whereNumber(['report', 'attachment']);
});

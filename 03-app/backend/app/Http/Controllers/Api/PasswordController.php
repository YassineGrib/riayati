<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\PersonalAccessToken;

class PasswordController extends Controller
{
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string', 'current_password:sanctum'],
            'password' => ['required', 'string', 'min:8', 'max:128', 'confirmed'],
            'password_confirmation' => ['required', 'string'],
        ]);

        $user = $request->user();
        $currentToken = $user->currentAccessToken();
        DB::transaction(function () use ($user, $currentToken, $data) {
            // User's hashed cast hashes the new password before persistence.
            $user->password = $data['password'];
            $user->save();
            $user->tokens()->when(
                $currentToken instanceof PersonalAccessToken,
                fn ($query) => $query->whereKeyNot($currentToken->getKey()),
            )->delete();
        });

        return response()->json(['message' => 'تم تغيير كلمة المرور بنجاح.']);
    }
}

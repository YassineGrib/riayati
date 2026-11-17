<?php

namespace App\Http\Controllers\Api;

use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email:rfc', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'max:128'],
            // Admins are never created from the app: only father or mother.
            'role' => ['required', Rule::in(Role::registrable())],
            'terms' => ['required', 'accepted'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => strtolower($data['email']),
            'password' => $data['password'],
            'role' => $data['role'],
            'terms_accepted_at' => now(),
        ]);

        return response()->json([
            'user' => $this->payload($user),
            'token' => $user->createToken($data['device_name'] ?? 'mobile')->plainTextToken,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::where('email', strtolower($data['email']))->first();

        // One message for both cases, so the response never reveals which part was wrong.
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['البريد الإلكتروني أو كلمة المرور غير صحيحة. تحقق منهما وحاول مجددًا.'],
            ]);
        }

        return response()->json([
            'user' => $this->payload($user),
            'token' => $user->createToken($data['device_name'] ?? 'mobile')->plainTextToken,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'تم تسجيل الخروج.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->payload($request->user())]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();
        // Normalize before uniqueness and format checks; never coerce arrays to strings.
        if (is_string($request->input('email'))) {
            $request->merge(['email' => strtolower(trim($request->input('email')))]);
        }
        if (is_string($request->input('phone'))) {
            $phone = preg_replace('/[\s-]+/u', '', $request->input('phone'));
            $request->merge(['phone' => $phone === '' ? null : $phone]);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:80'],
            'email' => ['required', 'string', 'email:rfc', 'max:190', Rule::unique('users', 'email')->ignore($user)],
            'phone' => ['nullable', 'string', 'max:20', 'regex:/^(?:\+213|0)[0-9]{9}$/D'],
            'wilaya' => ['nullable', 'string', 'max:60'],
            'children_count' => ['nullable', 'integer', 'min:0', 'max:20'],
            'current_password' => $request->input('email') !== $user->email
                ? ['required', 'string', 'current_password:sanctum']
                : ['exclude'],
        ]);

        // The password is a verification field only; role and unknown fields are ignored.
        unset($data['current_password']);
        if ($data['email'] !== $user->email) {
            $user->email_verified_at = null;
        }
        $user->fill($data)->save();

        return response()->json(['user' => $this->payload($user)]);
    }

    /** What the app may know about an account. The other parent's details are never included. */
    private function payload(User $user): array
    {
        $partner = $user->partner();

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role->value,
            'linked' => $partner !== null,
            'partner_role' => $partner?->role->value,
            'phone' => $user->phone,
            'wilaya' => $user->wilaya,
            'children_count' => $user->children_count,
        ];
    }
}

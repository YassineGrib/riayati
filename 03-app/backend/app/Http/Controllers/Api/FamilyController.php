<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Family;
use App\Models\InviteCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class FamilyController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $partner = $request->user()->partner();

        return response()->json([
            'linked' => $partner !== null,
            'partner_role' => $partner?->role->value,
        ]);
    }

    /** Generate a code for the other parent. A new code replaces any earlier unused one. */
    public function invite(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role->isParent(), 403);

        return DB::transaction(function () use ($user) {
            $family = $user->family ?? Family::create();
            if (! $user->family_id) {
                $user->family()->associate($family)->save();
            }

            if ($family->isFull()) {
                return response()->json(['message' => 'حسابكما مرتبطان بالفعل.'], 409);
            }

            InviteCode::where('user_id', $user->id)->whereNull('used_at')->delete();
            $invite = InviteCode::issue($user, $family);

            return response()->json([
                'code' => $invite->display(),
                'expires_at' => $invite->expires_at->toIso8601String(),
            ], 201);
        });
    }

    /** Enter the other parent's code. Nothing is shared until this succeeds. */
    public function link(Request $request): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'max:16']]);
        $user = $request->user();
        abort_unless($user->role->isParent(), 403);

        $code = InviteCode::normalize($data['code']);

        return DB::transaction(function () use ($user, $code) {
            $invite = InviteCode::where('code', $code)
                ->whereNull('used_at')
                ->where('expires_at', '>', now())
                ->lockForUpdate()
                ->first();

            // Same message for unknown, expired, used and own codes.
            if (! $invite || $invite->user_id === $user->id) {
                throw ValidationException::withMessages(['code' => ['الرمز غير صحيح أو انتهت صلاحيته.']]);
            }

            if ($invite->user->role === $user->role) {
                throw ValidationException::withMessages(['code' => ['يجب أن يكون أحد الحسابين أبًا والآخر أمًا.']]);
            }

            if ($invite->family->isFull()) {
                return response()->json(['message' => 'هذا الحساب مرتبط بالفعل.'], 409);
            }

            $previousFamily = $user->family;
            if ($previousFamily && $previousFamily->id !== $invite->family_id && $previousFamily->users()->count() > 1) {
                return response()->json(['message' => 'حسابك مرتبط بالفعل بحساب آخر.'], 409);
            }

            $user->family()->associate($invite->family)->save();
            $invite->update(['used_at' => now(), 'used_by' => $user->id]);

            // A family created only to hold a pending invite is no longer needed.
            if ($previousFamily && $previousFamily->id !== $invite->family_id && $previousFamily->users()->count() === 0) {
                $previousFamily->delete();
            }

            return response()->json(['linked' => true, 'partner_role' => $invite->user->role->value]);
        });
    }
}

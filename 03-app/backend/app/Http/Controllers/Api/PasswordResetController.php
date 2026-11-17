<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PasswordResetController extends Controller
{
    /** Always answers the same way, so the endpoint cannot be used to find out which emails have accounts. */
    public function forgot(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'string', 'email']]);

        Password::sendResetLink(['email' => strtolower($data['email'])]);

        return response()->json(['message' => 'إذا كان البريد مسجّلًا لدينا فقد أرسلنا إليه رابط الاستعادة.']);
    }

    /** JSON version (used by tests and any future in-app reset). */
    public function reset(Request $request): JsonResponse
    {
        $this->performReset($request);

        return response()->json(['message' => 'تم تعيين كلمة المرور الجديدة. يمكنك تسجيل الدخول الآن.']);
    }

    /** Web form submitted from the page the emailed link opens. */
    public function resetFromWeb(Request $request): RedirectResponse
    {
        $this->performReset($request);

        return redirect()->route('password.reset.done');
    }

    private function performReset(Request $request): void
    {
        $data = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string', 'min:8', 'max:128', 'confirmed'],
        ]);

        $status = Password::reset(
            ['email' => strtolower($data['email']), 'password' => $data['password'], 'token' => $data['token']],
            function (User $user, string $password) {
                $user->forceFill(['password' => Hash::make($password), 'remember_token' => Str::random(60)])->save();
                // A reset signs the account out everywhere.
                $user->tokens()->delete();
                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['email' => ['رابط الاستعادة غير صالح أو انتهت صلاحيته. اطلب رابطًا جديدًا.']]);
        }
    }
}

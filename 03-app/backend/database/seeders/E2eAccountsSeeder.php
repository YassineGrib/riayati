<?php

namespace Database\Seeders;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Local-only accounts for end-to-end testing on the emulator (not linked yet,
 * so the linking flow can be exercised). Refuses to run outside local/testing.
 */
class E2eAccountsSeeder extends Seeder
{
    public const PASSWORD = 'E2e-Local-Only-2026';

    public function run(): void
    {
        abort_unless(app()->environment(['local', 'testing']), 403, 'Local only.');

        foreach ([
            ['e2e-father@riayati.test', 'أب اختبار', Role::Father],
            ['e2e-mother@riayati.test', 'أم اختبار', Role::Mother],
            ['e2e-admin@riayati.test', 'مسؤول اختبار', Role::Admin],
        ] as [$email, $name, $role]) {
            User::updateOrCreate(
                ['email' => $email],
                [
                    'name' => $name,
                    'password' => self::PASSWORD,
                    'role' => $role,
                    'family_id' => null,
                    'terms_accepted_at' => now(),
                ]
            );
        }
    }
}

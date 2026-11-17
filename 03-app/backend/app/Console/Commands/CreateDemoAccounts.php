<?php

namespace App\Console\Commands;

use App\Enums\Role;
use App\Models\Family;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

#[Signature('riayati:demo-accounts {--domain=riayati.test}')]
#[Description('Create linked demo accounts (father, mother, admin) for the academic defence. Passwords are random and printed once.')]
class CreateDemoAccounts extends Command
{
    public function handle(): int
    {
        $domain = $this->option('domain');
        $accounts = [
            ['father', 'الأب التجريبي', Role::Father],
            ['mother', 'الأم التجريبية', Role::Mother],
            ['admin', 'المسؤول التجريبي', Role::Admin],
        ];

        if (User::whereIn('email', array_map(fn ($a) => "{$a[0]}@{$domain}", $accounts))->exists()) {
            $this->error('Demo accounts already exist for this domain.');

            return self::FAILURE;
        }

        $family = Family::create();
        $rows = [];
        foreach ($accounts as [$local, $name, $role]) {
            $password = Str::password(14, symbols: false);
            User::create([
                'name' => $name,
                'email' => "{$local}@{$domain}",
                'password' => $password,
                'role' => $role,
                // The two parents are already linked, so the calendar works in the demo.
                'family_id' => $role->isParent() ? $family->id : null,
                'terms_accepted_at' => now(),
            ]);
            $rows[] = [$role->value, "{$local}@{$domain}", $password];
        }

        $this->table(['Role', 'Email', 'Password (shown once)'], $rows);

        return self::SUCCESS;
    }
}

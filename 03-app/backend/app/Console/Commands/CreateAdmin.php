<?php

namespace App\Console\Commands;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

#[Signature('riayati:create-admin {email} {--name=المسؤول}')]
#[Description('Create an admin account with a random password (printed once).')]
class CreateAdmin extends Command
{
    public function handle(): int
    {
        $email = strtolower($this->argument('email'));

        if (User::where('email', $email)->exists()) {
            $this->error('An account with this email already exists.');

            return self::FAILURE;
        }

        $password = Str::password(16, symbols: false);
        User::create([
            'name' => $this->option('name'),
            'email' => $email,
            'password' => $password,
            'role' => Role::Admin,
            'terms_accepted_at' => now(),
        ]);

        $this->info("Admin created: {$email}");
        $this->line("Password (shown once, store it safely): {$password}");

        return self::SUCCESS;
    }
}

<?php

namespace Database\Factories;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'name' => fake()->firstName(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => Role::Father,
            'terms_accepted_at' => now(),
            'remember_token' => Str::random(10),
        ];
    }

    public function father(): static
    {
        return $this->state(['role' => Role::Father]);
    }

    public function mother(): static
    {
        return $this->state(['role' => Role::Mother]);
    }

    public function admin(): static
    {
        return $this->state(['role' => Role::Admin]);
    }

    public function unverified(): static
    {
        return $this->state(['email_verified_at' => null]);
    }
}

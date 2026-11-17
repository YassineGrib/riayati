<?php

namespace Tests\Feature;

use App\Enums\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AccountCommandsTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_admin_makes_an_admin_and_refuses_duplicates(): void
    {
        $this->artisan('riayati:create-admin', ['email' => 'boss@example.com'])->assertSuccessful();

        $this->assertSame(Role::Admin, User::firstWhere('email', 'boss@example.com')->role);
        $this->artisan('riayati:create-admin', ['email' => 'boss@example.com'])->assertFailed();
    }

    public function test_demo_accounts_are_created_with_the_parents_already_linked(): void
    {
        $this->artisan('riayati:demo-accounts')->assertSuccessful();

        $father = User::firstWhere('email', 'father@riayati.test');
        $mother = User::firstWhere('email', 'mother@riayati.test');
        $admin = User::firstWhere('email', 'admin@riayati.test');

        $this->assertTrue($father->isLinked());
        $this->assertSame($mother->id, $father->partner()->id);
        $this->assertNull($admin->family_id);
        $this->artisan('riayati:demo-accounts')->assertFailed();
    }
}

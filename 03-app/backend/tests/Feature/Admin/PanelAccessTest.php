<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PanelAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');
    }

    public function test_father_gets_403_on_admin(): void
    {
        $this->actingAs(User::factory()->father()->create())->get('/admin')->assertForbidden();
    }

    public function test_mother_gets_403_on_admin(): void
    {
        $this->actingAs(User::factory()->mother()->create())->get('/admin')->assertForbidden();
    }

    public function test_admin_sees_dashboard_200(): void
    {
        $this->actingAs(User::factory()->admin()->create())->get('/admin')->assertOk();
    }

    public function test_panel_is_rtl_arabic(): void
    {
        $this->actingAs(User::factory()->admin()->create())->get('/admin')
            ->assertOk()->assertSee('dir="rtl"', false)->assertSee('lang="ar"', false);
    }
}

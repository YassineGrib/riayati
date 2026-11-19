<?php

namespace Tests\Feature\Admin;

use App\Enums\Role;
use App\Filament\Resources\Users\Pages\ListUsers;
use App\Filament\Resources\Users\UserResource;
use App\Models\Family;
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Livewire\Livewire;
use Tests\TestCase;

class UserResourceTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
        $this->actingAs($this->admin);
        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    public function test_guests_and_parents_cannot_access_users_pages(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();

        // Guest redirected to login
        auth()->logout();
        $this->get(UserResource::getUrl('index'))->assertRedirect(route('filament.admin.auth.login'));
        $this->get(UserResource::getUrl('view', ['record' => $father]))->assertRedirect(route('filament.admin.auth.login'));

        // Father gets 403
        $this->actingAs($father);
        $this->get(UserResource::getUrl('index'))->assertForbidden();
        $this->get(UserResource::getUrl('view', ['record' => $father]))->assertForbidden();

        // Mother gets 403
        $this->actingAs($mother);
        $this->get(UserResource::getUrl('index'))->assertForbidden();
        $this->get(UserResource::getUrl('view', ['record' => $father]))->assertForbidden();
    }

    public function test_admin_can_view_users_list_and_sees_expected_columns(): void
    {
        $family = Family::create();
        $father = User::factory()->father()->create([
            'name' => 'طارق الأب',
            'family_id' => $family->id,
            'phone' => '0555123456',
            'wilaya' => 'الجزائر',
            'children_count' => 3,
        ]);
        $mother = User::factory()->mother()->create([
            'name' => 'سارة الأم',
            'family_id' => $family->id,
            'phone' => '0666123456',
            'wilaya' => 'الجزائر',
            'children_count' => 3,
        ]);

        // Add a Sanctum personal access token with last_used_at
        DB::table('personal_access_tokens')->insert([
            'tokenable_type' => User::class,
            'tokenable_id' => $father->id,
            'name' => 'test-device',
            'token' => hash('sha256', 'dummy-token'),
            'abilities' => '["*"]',
            'last_used_at' => now()->subMinutes(15),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Livewire::test(ListUsers::class)
            ->assertCanSeeTableRecords([$father, $mother])
            ->assertTableColumnStateSet('name', 'طارق الأب', $father)
            ->assertTableColumnStateSet('phone', '0555123456', $father)
            ->assertTableColumnStateSet('wilaya', 'الجزائر', $father)
            ->assertTableColumnStateSet('children_count', 3, $father)
            ->assertTableColumnFormattedStateSet('role', 'أب', $father)
            ->assertTableColumnFormattedStateSet('linked_status', 'مرتبط', $father)
            ->assertTableColumnFormattedStateSet('partner_name', 'سارة الأم', $father)
            ->assertTableColumnFormattedStateSet('partner_name', 'طارق الأب', $mother)
            ->assertTableActionHasUrl('view', UserResource::getUrl('view', ['record' => $father]), $father);

        $this->get(UserResource::getUrl('view', ['record' => $father]))->assertOk();
    }

    public function test_users_table_and_view_never_load_passwords_or_tokens(): void
    {
        $father = User::factory()->father()->create([
            'password' => bcrypt('SecretPassword123!'),
            'remember_token' => 'super-secret-remember-token',
        ]);

        DB::table('personal_access_tokens')->insert([
            'tokenable_type' => User::class,
            'tokenable_id' => $father->id,
            'name' => 'secret-device',
            'token' => 'secret-hashed-token-value',
            'abilities' => '["*"]',
            'last_used_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Check list page response
        $listResponse = $this->get(UserResource::getUrl('index'));
        $listResponse->assertOk();
        $listResponse->assertDontSee($father->password);
        $listResponse->assertDontSee('super-secret-remember-token');
        $listResponse->assertDontSee('secret-hashed-token-value');

        // Check view page response
        $viewResponse = $this->get(UserResource::getUrl('view', ['record' => $father]));
        $viewResponse->assertOk();
        $viewResponse->assertDontSee($father->password);
        $viewResponse->assertDontSee('super-secret-remember-token');
        $viewResponse->assertDontSee('secret-hashed-token-value');

        // Check the eloquent query used by UserResource does not load password or remember_token
        $record = UserResource::getEloquentQuery()->where('users.id', $father->id)->first();
        $this->assertNotNull($record);
        $this->assertNull($record->password);
        $this->assertNull($record->remember_token);
    }

    public function test_list_excludes_admins(): void
    {
        $father = User::factory()->father()->create();

        Livewire::test(ListUsers::class)
            ->assertCanSeeTableRecords([$father])
            ->assertCanNotSeeTableRecords([$this->admin]);
    }

    public function test_list_filters_by_role(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();

        Livewire::test(ListUsers::class)
            ->filterTable('role', Role::Father->value)
            ->assertCanSeeTableRecords([$father])
            ->assertCanNotSeeTableRecords([$mother]);

        Livewire::test(ListUsers::class)
            ->filterTable('role', Role::Mother->value)
            ->assertCanSeeTableRecords([$mother])
            ->assertCanNotSeeTableRecords([$father]);
    }

    public function test_list_filters_by_linked_status(): void
    {
        $family = Family::create();
        $linkedFather = User::factory()->father()->create(['family_id' => $family->id]);
        $linkedMother = User::factory()->mother()->create(['family_id' => $family->id]);

        $unlinkedFather = User::factory()->father()->create(['family_id' => null]);

        $loneFamily = Family::create();
        $loneMother = User::factory()->mother()->create(['family_id' => $loneFamily->id]);

        Livewire::test(ListUsers::class)
            ->filterTable('linked', 'linked')
            ->assertCanSeeTableRecords([$linkedFather, $linkedMother])
            ->assertCanNotSeeTableRecords([$unlinkedFather, $loneMother]);

        Livewire::test(ListUsers::class)
            ->filterTable('linked', 'unlinked')
            ->assertCanSeeTableRecords([$unlinkedFather, $loneMother])
            ->assertCanNotSeeTableRecords([$linkedFather, $linkedMother]);
    }

    public function test_list_filters_by_wilaya(): void
    {
        $algiersUser = User::factory()->father()->create(['wilaya' => 'الجزائر']);
        $oranUser = User::factory()->mother()->create(['wilaya' => 'وهران']);

        Livewire::test(ListUsers::class)
            ->filterTable('wilaya', 'الجزائر')
            ->assertCanSeeTableRecords([$algiersUser])
            ->assertCanNotSeeTableRecords([$oranUser]);
    }

    public function test_one_parent_family_and_missing_profile_details_render_without_errors(): void
    {
        $singleParent = User::factory()->father()->create([
            'phone' => null,
            'wilaya' => null,
            'children_count' => null,
            'family_id' => null,
        ]);

        Livewire::test(ListUsers::class)
            ->assertCanSeeTableRecords([$singleParent])
            ->assertTableColumnFormattedStateSet('linked_status', 'غير مرتبط', $singleParent)
            ->assertTableColumnFormattedStateSet('partner_name', '—', $singleParent);

        $this->get(UserResource::getUrl('view', ['record' => $singleParent]))
            ->assertOk()
            ->assertSee('غير محدد');
    }

    public function test_user_view_page_shows_profile_and_family_details_read_only(): void
    {
        $family = Family::create();
        $father = User::factory()->father()->create([
            'name' => 'أحمد علي',
            'email' => 'ahmed@riayati.test',
            'phone' => '0555999888',
            'wilaya' => 'قسنطينة',
            'children_count' => 2,
            'family_id' => $family->id,
        ]);
        $mother = User::factory()->mother()->create([
            'name' => 'فاطمة الزهراء',
            'email' => 'fatima@riayati.test',
            'family_id' => $family->id,
        ]);

        $this->get(UserResource::getUrl('view', ['record' => $father]))
            ->assertOk()
            ->assertSee('أحمد علي')
            ->assertSee('ahmed@riayati.test')
            ->assertSee('0555999888')
            ->assertSee('قسنطينة')
            ->assertSee('2')
            ->assertSee('فاطمة الزهراء')
            ->assertDontSee('حفظ')
            ->assertDontSee('تعديل')
            ->assertDontSee('حذف');
    }

    public function test_user_resource_cannot_create_edit_or_delete(): void
    {
        $user = User::factory()->father()->create();

        $this->assertFalse(UserResource::canCreate());
        $this->assertFalse(UserResource::canEdit($user));
        $this->assertFalse(UserResource::canDelete($user));
        $this->assertFalse(UserResource::canDeleteAny());
    }
}

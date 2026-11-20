<?php

namespace Tests\Feature\Admin;

use App\Enums\CenterKind;
use App\Filament\Resources\SupportCenters\Pages\CreateSupportCenter;
use App\Filament\Resources\SupportCenters\Pages\EditSupportCenter;
use App\Filament\Resources\SupportCenters\Pages\ListSupportCenters;
use App\Filament\Resources\SupportCenters\SupportCenterResource;
use App\Models\SupportCenter;
use App\Models\User;
use App\Support\Wilayas;
use Database\Seeders\SupportCenterPlaceholderSeeder;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class SupportCenterResourceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->actingAs(User::factory()->admin()->create());
        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    public function test_crud_publish_and_delete_confirmation(): void
    {
        Livewire::test(CreateSupportCenter::class)->fillForm(['name' => 'بيانات تجريبية', 'kind' => 'court', 'wilaya' => '16', 'phone' => '0000000000', 'is_published' => true])->call('create')->assertHasNoFormErrors();
        $center = SupportCenter::firstOrFail();
        $this->assertTrue($center->is_published);
        Livewire::test(EditSupportCenter::class, ['record' => $center->id])->fillForm(['name' => 'معدل', 'is_published' => false])->call('save')->assertHasNoFormErrors();
        $this->assertSame('معدل', $center->refresh()->name);
        $this->assertFalse($center->is_published);
        $other = SupportCenter::create(['name' => 'Keep', 'kind' => 'ngo']);
        $page = Livewire::test(ListSupportCenters::class)->mountTableAction('delete', $center);
        $this->assertTrue($page->instance()->getMountedAction()->isConfirmationRequired());
        $this->assertModelExists($center);
        $page->callMountedAction();
        $this->assertModelMissing($center);
        $this->assertModelExists($other);
    }

    public function test_tabs_and_filters(): void
    {
        $records = collect(CenterKind::cases())->map(fn ($kind) => SupportCenter::create(['name' => $kind->value, 'kind' => $kind, 'wilaya' => $kind === CenterKind::Court ? '16' : '31']));
        $page = Livewire::test(ListSupportCenters::class)->assertCanSeeTableRecords($records);
        foreach ($records as $record) {
            $page->set('activeTab', $record->kind->value)->assertCanSeeTableRecords([$record])->assertCanNotSeeTableRecords($records->where('id', '!=', $record->id));
        }
        $page->set('activeTab', 'all')->filterTable('kind', 'court')->assertCanSeeTableRecords([$records->first()])->assertCanNotSeeTableRecords($records->skip(1));
        $page->resetTableFilters()->filterTable('wilaya', '16')->assertCanSeeTableRecords([$records->first()])->assertCanNotSeeTableRecords($records->skip(1));
    }

    public function test_access_and_validation(): void
    {
        Livewire::test(CreateSupportCenter::class)->fillForm(['name' => '', 'kind' => 'invalid', 'wilaya' => '99', 'phone' => 'invalid'])->call('create')->assertHasFormErrors(['name', 'kind', 'wilaya', 'phone']);
        $center = SupportCenter::create(['name' => 'Test', 'kind' => 'ngo']);
        $urls = [SupportCenterResource::getUrl(), SupportCenterResource::getUrl('create'), SupportCenterResource::getUrl('view', ['record' => $center]), SupportCenterResource::getUrl('edit', ['record' => $center])];
        auth()->logout();
        foreach ($urls as $url) {
            $this->get($url)->assertRedirect('/admin/login');
        }
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $this->actingAs($parent);
            foreach ($urls as $url) {
                $this->get($url)->assertForbidden();
            }Livewire::test(CreateSupportCenter::class)->assertForbidden();
        }
    }

    public function test_catalogue_and_placeholder_seed(): void
    {
        $options = Wilayas::options();
        $this->assertCount(58, $options);
        $this->assertSame('01 - أدرار', $options['01']);
        $this->assertSame('58 - المنيعة', $options[58]);
        $this->seed(SupportCenterPlaceholderSeeder::class);
        $this->seed(SupportCenterPlaceholderSeeder::class);
        $this->assertSame(7, SupportCenter::count());
        $this->assertSame(0, SupportCenter::published()->count());
        foreach (SupportCenter::all() as $center) {
            $this->assertStringContainsString('بيانات تجريبية', $center->name);
            $this->assertSame('0000000000',$center->phone);
        }
    }
}

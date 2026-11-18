<?php

namespace Tests\Feature\Admin;

use App\Enums\ContentType;
use App\Filament\Resources\Contents\ContentResource;
use App\Filament\Resources\Contents\Pages\CreateContent;
use App\Filament\Resources\Contents\Pages\EditContent;
use App\Filament\Resources\Contents\Pages\ListContents;
use App\Filament\Resources\Contents\Pages\ViewContent;
use App\Models\Content;
use App\Models\User;
use Database\Seeders\ContentPlaceholderSeeder;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class ContentResourceTest extends TestCase
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

    private function data(array $overrides = []): array
    {
        return array_merge(['title' => 'عنوان تجريبي', 'type' => 'article', 'slug' => 'sample-content',
            'category' => 'تجريبي', 'reference' => null, 'summary' => 'ملخص تجريبي',
            'body' => '<p>نص تجريبي</p>', 'is_published' => false], $overrides);
    }

    private function content(array $overrides = []): Content
    {
        return Content::create($this->data(array_merge(['created_by' => $this->admin->id], $overrides)));
    }

    public function test_admin_can_create_edit_publish_unpublish_and_keep_original_creator(): void
    {
        $this->freezeTime();
        Livewire::test(CreateContent::class)->fillForm($this->data(['is_published' => true]))
            ->call('create')->assertHasNoFormErrors();
        $content = Content::firstOrFail();
        $this->assertSame($this->admin->id, $content->created_by);
        $this->assertSame(ContentType::Article, $content->type);
        $this->assertSame(now()->toDateTimeString(), $content->published_at->toDateTimeString());
        $publishedAt = $content->published_at->toDateTimeString();
        $this->travel(1)->hours();
        $this->actingAs(User::factory()->admin()->create());
        Livewire::test(EditContent::class, ['record' => $content->id])
            ->fillForm(['title' => 'عنوان معدل'])->call('save')->assertHasNoFormErrors();
        $this->assertSame($publishedAt, $content->refresh()->published_at->toDateTimeString());
        $this->assertSame($this->admin->id, $content->created_by);
        Livewire::test(EditContent::class, ['record' => $content->id])
            ->fillForm(['is_published' => false])->call('save')->assertHasNoFormErrors();
        $this->assertNull($content->refresh()->published_at);
        $this->assertSame(0, Content::published()->count());
        Livewire::test(EditContent::class, ['record' => $content->id])
            ->fillForm(['is_published' => true])->call('save')->assertHasNoFormErrors();
        $this->assertSame(now()->toDateTimeString(), $content->refresh()->published_at->toDateTimeString());
        $this->assertSame(1, Content::published()->count());
    }

    public function test_tabs_filter_each_type_and_all(): void
    {
        $records = collect(ContentType::cases())->map(fn ($type) => $this->content(['type' => $type, 'slug' => $type->value]));
        $page = Livewire::test(ListContents::class)->assertCanSeeTableRecords($records);
        foreach ($records as $record) {
            $page->set('activeTab', $record->type->value)->assertCanSeeTableRecords([$record])
                ->assertCanNotSeeTableRecords($records->where('id', '!=', $record->id));
        }
        $page->set('activeTab', 'all')->assertCanSeeTableRecords($records);
    }

    public function test_delete_requires_confirmation_and_deletes_only_selected_row(): void
    {
        $content = $this->content();
        $other = $this->content(['slug' => 'keep-me']);
        $page = Livewire::test(ListContents::class)->mountTableAction('delete', $content);
        $this->assertTrue($page->instance()->getMountedAction()->isConfirmationRequired());
        $this->assertModelExists($content);
        $page->callMountedAction()->assertHasNoActionErrors();
        $this->assertModelMissing($content);
        $this->assertModelExists($other);
    }

    public function test_required_fields_enum_and_unique_slug_are_validated(): void
    {
        $content = $this->content();
        Livewire::test(CreateContent::class)->fillForm($this->data())->call('create')
            ->assertHasFormErrors(['slug' => 'unique']);
        Livewire::test(CreateContent::class)->fillForm($this->data(['title' => '', 'slug' => '', 'body' => '', 'type' => 'invalid']))
            ->call('create')->assertHasFormErrors(['title', 'slug', 'body', 'type']);
        Livewire::test(EditContent::class, ['record' => $content->id])->fillForm(['title' => 'معدل'])
            ->call('save')->assertHasNoFormErrors();
        $this->assertSame(1, Content::count());
    }

    public function test_long_arabic_rich_body_is_sanitized_on_view_and_not_in_table(): void
    {
        $body = '<p>'.str_repeat('نص تجريبي طويل ', 1000).'</p><script>alert("unsafe")</script><img src=x onerror="alert(1)"><a href="javascript:alert(2)">رابط</a>';
        $content = $this->content(['body' => $body]);
        Livewire::test(ListContents::class)->assertCanSeeTableRecords([$content])->assertDontSee('<script>alert', false);
        $this->get(ContentResource::getUrl('view', ['record' => $content]))->assertOk()
            ->assertSee('نص تجريبي طويل')->assertDontSee('<script>alert', false)
            ->assertDontSee('onerror=', false)->assertDontSee('href="javascript:', false);
    }

    public function test_guests_and_parents_cannot_access_any_content_page_or_write(): void
    {
        $content = $this->content();
        $urls = [ContentResource::getUrl(), ContentResource::getUrl('create'),
            ContentResource::getUrl('view', ['record' => $content]), ContentResource::getUrl('edit', ['record' => $content])];
        auth()->logout();
        foreach ($urls as $url) {
            $this->get($url)->assertRedirect('/admin/login');
        }
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $this->actingAs($parent);
            foreach ($urls as $url) {
                $this->get($url)->assertForbidden();
            }
            Livewire::test(CreateContent::class)->assertForbidden();
            Livewire::test(EditContent::class, ['record' => $content->id])->assertForbidden();
            Livewire::test(ViewContent::class, ['record' => $content->id])->assertForbidden();
            Livewire::test(ListContents::class)->assertForbidden();
        }
        $this->assertModelExists($content);
    }

    public function test_placeholder_seeder_is_opt_in_idempotent_and_never_published(): void
    {
        $this->assertSame(0, Content::count());
        $this->seed(ContentPlaceholderSeeder::class);
        $this->seed(ContentPlaceholderSeeder::class);
        $this->assertSame(6, Content::count());
        $this->assertSame(0, Content::published()->count());
        foreach (Content::all() as $content) {
            $this->assertStringContainsString('نص تجريبي', $content->title);
            $this->assertStringContainsString('نص تجريبي', $content->body);
        }
        $this->assertCount(4, Content::pluck('type')->unique());
    }
}

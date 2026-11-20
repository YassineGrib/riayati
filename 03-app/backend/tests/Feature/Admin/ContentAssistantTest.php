<?php

namespace Tests\Feature\Admin;

use App\Filament\Resources\Contents\Pages\CreateContent;
use App\Filament\Resources\Contents\Pages\EditContent;
use App\Filament\Resources\Contents\Pages\ListContents;
use App\Models\Content;
use App\Models\User;
use App\Services\Assistant\TextChunker;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Factory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Livewire\Livewire;
use Tests\TestCase;

class ContentAssistantTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->actingAs(User::factory()->admin()->create());
        Filament::setCurrentPanel(Filament::getPanel('admin'));
        config(['riayati.assistant.key' => 'test-secret-key']);
        Http::preventStrayRequests();
        Http::fake(fn ($r) => Http::response(['embeddings' => array_fill(0, count($r['requests']), ['values' => array_fill(0, 768, 1)])]));
    }

    private function data(array $overrides = []): array
    {
        return array_merge(['title' => 'قانون تجريبي', 'reference' => 'مرجع 1', 'slug' => 'test-law', 'type' => 'guide',
            'body' => '<p>حقوق &amp; واجبات الأسرة.</p>', 'is_published' => true, 'use_in_assistant' => true, 'created_by' => auth()->id()], $overrides);
    }

    public function test_toggle_indexes_on_create_and_edit_and_removes_on_disable_unpublish_delete(): void
    {
        Livewire::test(CreateContent::class)->fillForm($this->data())->call('create')->assertHasNoFormErrors();
        $content = Content::firstOrFail();
        $this->assertTrue($content->use_in_assistant);
        $this->assertSame(1, $content->chunks()->count());
        $this->assertStringContainsString('حقوق & واجبات', $content->chunks()->first()->text);
        $oldId = $content->chunks()->first()->id;
        Livewire::test(EditContent::class, ['record' => $content->id])->fillForm(['body' => '<p>نص معدل.</p>'])->call('save')->assertHasNoFormErrors();
        $this->assertNotSame($oldId, $content->chunks()->first()->id);
        $this->assertStringContainsString('نص معدل', $content->chunks()->first()->text);
        $content->refresh()->update(['is_published' => false]);
        $this->assertSame(0, $content->chunks()->count());
        $content->update(['is_published' => true]);
        $content->update(['use_in_assistant' => false]);
        $this->assertSame(0, $content->chunks()->count());
        $content->update(['use_in_assistant' => true]);
        $this->assertSame(1, $content->chunks()->count());
        $content->delete();
        $this->assertDatabaseCount('content_chunks', 0);
        $this->assertDatabaseHas('admin_activities', ['action' => 'content.assistant_reindexed']);
    }

    public function test_missing_key_keeps_saved_content_and_logs_only_safe_warning(): void
    {
        config(['riayati.assistant.key' => null]);
        Log::spy();
        $content = Content::create($this->data());
        $this->assertModelExists($content);
        $this->assertSame(0, $content->chunks()->count());
        Log::shouldHaveReceived('warning')->once()->with('Assistant indexing unavailable.', ['content_id' => $content->id]);
        Http::assertNothingSent();
    }

    public function test_later_batch_failure_leaves_no_partial_chunks(): void
    {
        config(['riayati.assistant.chunk_chars' => 20, 'riayati.assistant.chunk_overlap' => 2]);
        Http::swap(new Factory);
        Http::preventStrayRequests();
        Http::fakeSequence()->push(['embeddings' => array_fill(0, 100, ['values' => array_fill(0, 768, 1)])])
            ->push(['error' => 'test-secret-key'], 500)->pushStatus(500);
        Log::spy();
        $content = Content::create($this->data(['body' => str_repeat('نص قانوني. ', 300)]));
        $this->assertModelExists($content);
        $this->assertSame(0, $content->chunks()->count());
        Http::assertSentCount(3);
        Log::shouldHaveReceived('warning')->once()->with('Assistant indexing unavailable.', ['content_id' => $content->id]);
    }

    public function test_header_action_and_command_reindex_only_enabled_published_texts(): void
    {
        $content = Content::create($this->data());
        Content::create($this->data(['slug' => 'draft', 'is_published' => false]));
        Content::create($this->data(['slug' => 'disabled', 'use_in_assistant' => false]));
        $content->chunks()->delete();
        Livewire::test(ListContents::class)->callAction('reindexAssistant')->assertNotified();
        $this->assertSame(1, $content->chunks()->count());
        $this->artisan('assistant:reindex')->expectsOutput('Indexed: 1; failed: 0')->assertSuccessful();
        $this->assertDatabaseCount('content_chunks', 1);
        Http::assertSentCount(3);
        config(['riayati.assistant.key' => null]);
        $this->artisan('assistant:reindex')->expectsOutput('Indexed: 0; failed: 1')->assertFailed();
    }

    public function test_chunking_preserves_arabic_boundaries_overlap_and_citation_prefix(): void
    {
        config(['riayati.assistant.chunk_chars' => 60, 'riayati.assistant.chunk_overlap' => 10]);
        $content = new Content($this->data(['body' => '<p>'.str_repeat('حقوق الأسرة محفوظة. ', 30).'</p><script>unsafe</script>']));
        $chunks = app(TextChunker::class)->chunks($content);
        $this->assertGreaterThan(2, count($chunks));
        $prefix = "قانون تجريبي — مرجع 1\n";
        foreach ($chunks as $chunk) {
            $this->assertStringStartsWith($prefix, $chunk);
            $this->assertStringNotContainsString('<', $chunk);
            $this->assertStringNotContainsString('unsafe', $chunk);
            $this->assertTrue(mb_check_encoding($chunk, 'UTF-8'));
        }
        $first = mb_substr($chunks[0], mb_strlen($prefix));
        $second = mb_substr($chunks[1], mb_strlen($prefix));
        $this->assertStringStartsWith(trim(mb_substr($first, -10)), $second);
    }
}

<?php

namespace Tests\Feature\Api;

use App\Models\Content;
use App\Models\User;
use App\Services\Assistant\AssistantService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Factory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class AssistantApiTest extends TestCase
{
    use RefreshDatabase;

    private string $modelAnswer = 'Answer from source';

    protected function setUp(): void
    {
        parent::setUp();
        config(['riayati.assistant.key' => 'test-secret-key']);
        Http::preventStrayRequests();
        Http::fake(fn ($request) => str_contains($request->url(), 'batchEmbedContents')
            ? Http::response(['embeddings' => array_fill(0, count($request['requests']), ['values' => $this->vector()])])
            : (str_contains($request->url(), ':embedContent')
                ? Http::response(['embedding' => ['values' => $this->vector()]])
                : Http::response(['candidates' => [['content' => ['parts' => [['text' => $this->modelAnswer]]]]]])));
    }

    private function vector(): array
    {
        return array_merge([1], array_fill(0, 767, 0));
    }

    private function parentLogin(): void
    {
        $this->withToken(User::factory()->mother()->create(['name' => 'PRIVATE_ACCOUNT_NAME'])->createToken('test')->plainTextToken);
    }

    private function content(array $overrides = []): Content
    {
        return Content::create(array_merge(['title' => 'مصدر القانون', 'reference' => 'مرجع 1', 'slug' => 'law', 'type' => 'law',
            'body' => '<p>نص المصدر القانوني.</p>', 'is_published' => true, 'use_in_assistant' => true, 'created_by' => User::factory()->admin()->create()->id], $overrides));
    }

    public function test_guests_and_admins_are_denied(): void
    {
        $this->postJson('/api/assistant', ['question' => 'test'])->assertUnauthorized();
        $this->withToken(User::factory()->admin()->create()->createToken('test')->plainTextToken)
            ->postJson('/api/assistant', ['question' => 'test'])->assertForbidden();
        Http::assertNothingSent();
    }

    public function test_question_validation(): void
    {
        $this->parentLogin();
        foreach ([[], ['question' => []], ['question' => '  '], ['question' => str_repeat('س', 501)]] as $data) {
            $this->postJson('/api/assistant', $data)->assertUnprocessable()->assertJsonValidationErrors('question');
        }
        Http::assertNothingSent();
    }

    public function test_no_sources_skips_answer_generation(): void
    {
        $this->parentLogin();
        $this->postJson('/api/assistant', ['question' => 'ما القانون؟'])->assertOk()
            ->assertJson(['answer' => AssistantService::INSUFFICIENT, 'sufficient' => false, 'sources' => []]);
        Http::assertSentCount(1);
        Http::assertNotSent(fn ($r) => str_contains($r->url(), 'generateContent'));
    }

    public function test_sources_and_outgoing_payload_exclude_account_data(): void
    {
        $content = $this->content();
        $this->parentLogin();
        $response = $this->postJson('/api/assistant', ['question' => 'ما القانون؟', 'report' => 'PRIVATE_REPORT']);
        $response->assertOk()->assertJsonPath('sufficient', true)->assertJsonCount(1, 'sources')
            ->assertJsonPath('sources.0.id', $content->id)->assertJsonPath('sources.0.reference', 'مرجع 1');
        $this->assertStringNotContainsString('test-secret-key', $response->getContent());
        Http::assertSent(fn ($r) => str_contains($r->url(), 'generateContent') && str_contains($r->body(), 'excerpts_data'));
        foreach (Http::recorded() as [$request]) {
            $this->assertStringNotContainsString('PRIVATE_ACCOUNT_NAME', $request->body());
            $this->assertStringNotContainsString('PRIVATE_REPORT', $request->body());
            $this->assertStringNotContainsString('test-secret-key', $request->url());
            $this->assertSame(['test-secret-key'], $request->header('x-goog-api-key'));
        }
    }

    public function test_stale_draft_and_disabled_chunks_are_excluded(): void
    {
        foreach ([['slug' => 'draft', 'is_published' => false], ['slug' => 'disabled', 'use_in_assistant' => false]] as $data) {
            $content = $this->content($data);
            $content->chunks()->create(['position' => 0, 'text' => 'PRIVATE_DRAFT', 'embedding' => $this->vector()]);
        }
        $this->parentLogin();
        $this->postJson('/api/assistant', ['question' => 'test'])->assertOk()->assertJsonPath('sufficient', false)->assertJsonCount(0, 'sources');
        Http::assertNotSent(fn ($r) => str_contains($r->url(), 'generateContent'));
    }

    public function test_low_similarity_and_provider_insufficiency(): void
    {
        $content = $this->content();
        $content->chunks()->update(['embedding' => json_encode(array_merge([0, 1], array_fill(0, 766, 0)))]);
        $this->parentLogin();
        $this->postJson('/api/assistant', ['question' => 'test'])->assertJsonPath('sufficient', false);
        Http::assertNotSent(fn ($r) => str_contains($r->url(), 'generateContent'));
        $content->chunks()->update(['embedding' => json_encode($this->vector())]);
        $this->modelAnswer = 'SOURCES_INSUFFICIENT';
        $this->postJson('/api/assistant', ['question' => 'test'])->assertJsonPath('sufficient', false)->assertJsonPath('answer', AssistantService::INSUFFICIENT);
    }

    public function test_missing_key_and_connection_failure_return_safe_503(): void
    {
        Log::spy();
        $this->parentLogin();
        config(['riayati.assistant.key' => null]);
        $this->postJson('/api/assistant', ['question' => 'test'])->assertStatus(503)->assertExactJson(['message' => 'المساعد غير متاح حاليًا، حاول لاحقًا.']);
        Http::assertNothingSent();
        config(['riayati.assistant.key' => 'test-secret-key']);
        Http::swap(new Factory);
        Http::fake(['*' => Http::failedConnection('test-secret-key PRIVATE_REPORT')]);
        $response = $this->postJson('/api/assistant', ['question' => 'test'])->assertStatus(503);
        $this->assertStringNotContainsString('test-secret-key', $response->getContent());
        Log::shouldNotHaveReceived('error');
        Log::shouldNotHaveReceived('warning');
    }

    public function test_throttle_is_twelve_per_minute(): void
    {
        $this->parentLogin();
        for ($i = 0; $i < 12; $i++) {
            $this->postJson('/api/assistant', ['question' => 'test'])->assertOk();
        }
        $this->postJson('/api/assistant', ['question' => 'test'])->assertStatus(429);
    }
}

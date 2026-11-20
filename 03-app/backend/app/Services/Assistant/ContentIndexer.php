<?php

namespace App\Services\Assistant;

use App\Models\Content;
use App\Services\AdminActivityLog;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class ContentIndexer
{
    public function __construct(private TextChunker $chunker, private GeminiClient $gemini, private AdminActivityLog $activity) {}

    public function reindex(Content $content): bool
    {
        $content->chunks()->delete();
        if (! $content->is_published || ! $content->use_in_assistant) {
            return false;
        }
        $success = false;
        try {
            $texts = $this->chunker->chunks($content);
            $vectors = $this->gemini->embedDocuments($texts);
            DB::transaction(function () use ($content, $texts, $vectors): void {
                foreach ($texts as $position => $text) {
                    $content->chunks()->create(['position' => $position, 'text' => $text, 'embedding' => $vectors[$position]]);
                }
            });
            $success = count($texts) > 0;
        } catch (Throwable) {
            Log::warning('Assistant indexing unavailable.', ['content_id' => $content->id]);
        }
        $admin = auth()->user();
        if ($admin?->isAdmin()) {
            $this->activity->record($admin, 'content.assistant_reindexed', $content, ['success' => $success]);
        }

        return $success;
    }

    public function reindexAll(): array
    {
        $indexed = $failed = 0;
        foreach (Content::published()->where('use_in_assistant', true)->lazyById() as $content) {
            $this->reindex($content) ? $indexed++ : $failed++;
        }

        return ['indexed' => $indexed, 'failed' => $failed];
    }
}

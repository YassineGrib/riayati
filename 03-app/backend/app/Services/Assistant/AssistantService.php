<?php

namespace App\Services\Assistant;

use App\Models\ContentChunk;

class AssistantService
{
    public const INSUFFICIENT = 'لا تتوفر لدي مصادر كافية في النصوص المدخلة للإجابة عن هذا السؤال. يُرجى مراجعة مختص أو النص الرسمي للقانون.';

    public function __construct(private GeminiClient $gemini) {}

    public function answer(string $question): array
    {
        $vector = $this->gemini->embedQuestion($question);
        $best = [];
        $query = ContentChunk::whereHas('content', fn ($q) => $q->published()->where('use_in_assistant', true))->with('content')->orderBy('id');
        foreach ($query->lazyById() as $chunk) {
            $score = $this->cosine($vector, $chunk->embedding);
            if ($score >= config('riayati.assistant.min_score')) {
                $best[] = ['chunk' => $chunk, 'score' => $score];
                usort($best, fn ($a, $b) => ($b['score'] <=> $a['score']) ?: ($a['chunk']->id <=> $b['chunk']->id));
                $best = array_slice($best, 0, config('riayati.assistant.top_k'));
            }
        }
        if ($best === []) {
            return ['answer' => self::INSUFFICIENT, 'sufficient' => false, 'sources' => []];
        }
        $excerpts = [];
        $sources = [];
        foreach ($best as $i => $match) {
            $chunk = $match['chunk'];
            $content = $chunk->content;
            $excerpts[] = '['.($i + 1).'] '.$content->title.' / '.$content->reference."\n".$chunk->text;
            $sources[$content->id] = $content->only(['id', 'title', 'reference', 'slug']);
        }
        $answer = $this->gemini->generate($question, implode("\n\n", $excerpts));
        $sufficient = ! str_contains($answer, 'SOURCES_INSUFFICIENT');

        return ['answer' => $sufficient ? 'مساعد آلي، وليس محاميًا. '.$answer : self::INSUFFICIENT,
            'sufficient' => $sufficient, 'sources' => array_values($sources)];
    }

    private function cosine(array $a, array $b): float
    {
        if (count($a) !== count($b)) {
            return -1;
        }
        $dot = $aa = $bb = 0;
        foreach ($a as $i => $value) {
            if (! is_numeric($b[$i] ?? null) || ! is_finite((float) $b[$i])) {
                return -1;
            }
            $dot += $value * $b[$i];
            $aa += $value * $value;
            $bb += $b[$i] * $b[$i];
        }

        return $aa > 0 && $bb > 0 ? $dot / sqrt($aa * $bb) : -1;
    }
}

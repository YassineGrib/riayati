<?php

namespace App\Services\Assistant;

use App\Models\Content;

class TextChunker
{
    public function chunks(Content $content): array
    {
        $text = preg_replace('/<(script|style)\b[^>]*>.*?<\/\1>/isu', '', $content->body);
        $text = preg_replace('/<\/?(?:p|div|li|h[1-6]|br)\b[^>]*>/iu', "\n", $text);
        $text = trim(preg_replace('/[\t ]+/u', ' ', strip_tags(html_entity_decode($text, ENT_QUOTES | ENT_HTML5, 'UTF-8'))));
        if ($text === '') {
            return [];
        }
        $size = max(1, (int) config('riayati.assistant.chunk_chars'));
        $overlap = min($size - 1, max(0, (int) config('riayati.assistant.chunk_overlap')));
        $prefix = strip_tags(html_entity_decode($content->title.' — '.$content->reference, ENT_QUOTES | ENT_HTML5, 'UTF-8'))."\n";
        $chunks = [];
        for ($start = 0, $length = mb_strlen($text); $start < $length;) {
            $part = mb_substr($text, $start, $size);
            if ($start + $size < $length && preg_match_all('/[\n.!?؟؛]/u', $part, $matches, PREG_OFFSET_CAPTURE)) {
                $boundary = mb_strlen(substr($part, 0, end($matches[0])[1])) + 1;
                if ($boundary > max($size / 2, $overlap)) {
                    $part = mb_substr($part, 0, $boundary);
                }
            }
            $chunks[] = $prefix.trim($part);
            if ($start + mb_strlen($part) >= $length) {
                break;
            }
            $start += max(1, mb_strlen($part) - $overlap);
        }

        return $chunks;
    }
}

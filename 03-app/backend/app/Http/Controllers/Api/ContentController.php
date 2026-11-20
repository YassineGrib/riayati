<?php

namespace App\Http\Controllers\Api;

use App\Enums\ContentType;
use App\Http\Controllers\Controller;
use App\Models\Content;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ContentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['type' => ['nullable', Rule::enum(ContentType::class)], 'q' => ['nullable', 'string', 'max:255']]);
        $query = Content::published();
        foreach (['type'] as $field) {
            if (isset($data[$field])) {
                $query->where($field, $data[$field]);
            }
        }
        if (! empty($data['q'])) {
            $query->where(function ($query) use ($data): void {
                $query->where('title', 'like', '%'.$data['q'].'%')->orWhere('summary', 'like', '%'.$data['q'].'%');
            });
        }
        $page = $query->orderByDesc('id')->paginate(20)->withQueryString();
        $page->through(fn (Content $record): array => $this->serialize($record));

        return response()->json($page);
    }

    public function show(string $slug): JsonResponse
    {
        $record = Content::published()->where('slug', $slug)->firstOrFail();

        return response()->json(['data' => $this->serialize($record) + ['body' => $record->body]]);
    }

    private function serialize(Content $record): array
    {
        return $record->only(['id', 'type', 'title', 'slug', 'category', 'reference', 'summary', 'published_at']) + ['type_label' => $record->type->label()];
    }
}

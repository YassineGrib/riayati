<?php

namespace App\Http\Controllers\Api;

use App\Enums\CenterKind;
use App\Http\Controllers\Controller;
use App\Models\SupportCenter;
use App\Support\Wilayas;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CenterController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['kind' => ['nullable', Rule::enum(CenterKind::class)], 'q' => ['nullable', 'string', 'max:255'], 'wilaya' => ['nullable', Rule::in(array_keys(Wilayas::options()))]]);
        $query = SupportCenter::published();
        foreach (['kind', 'wilaya'] as $field) {
            if (isset($data[$field])) {
                $query->where($field, $data[$field]);
            }
        }
        if (! empty($data['q'])) {
            $query->where(function ($query) use ($data): void {
                $query->where('name', 'like', '%'.$data['q'].'%')->orWhere('address', 'like', '%'.$data['q'].'%');
            });
        }
        $page = $query->orderByDesc('id')->paginate(20)->withQueryString();
        $page->through(fn (SupportCenter $record): array => $this->serialize($record));

        return response()->json($page);
    }

    public function show(string $id): JsonResponse
    {
        $record = SupportCenter::published()->where('id', $id)->firstOrFail();

        return response()->json(['data' => $this->serialize($record) + ['notes' => $record->notes]]);
    }

    private function serialize(SupportCenter $record): array
    {
        return $record->only(['id', 'name', 'kind', 'wilaya', 'address', 'phone', 'hotline', 'email', 'website', 'hours']) + ['kind_label' => $record->kind->label()];
    }
}

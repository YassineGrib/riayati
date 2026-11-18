<?php

namespace App\Models;

use App\Enums\ContentType;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['type', 'title', 'slug', 'category', 'reference', 'summary', 'body', 'is_published', 'created_by'])]
class Content extends Model
{
    protected function casts(): array
    {
        return ['type' => ContentType::class, 'is_published' => 'boolean', 'published_at' => 'datetime'];
    }

    protected static function booted(): void
    {
        static::saving(function (Content $content): void {
            if (! $content->is_published) {
                $content->published_at = null;
            } elseif ($content->published_at === null || $content->isDirty('is_published')) {
                $content->published_at = now();
            }
        });
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}

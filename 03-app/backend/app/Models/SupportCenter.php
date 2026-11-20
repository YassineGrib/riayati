<?php

namespace App\Models;

use App\Enums\CenterKind;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name', 'kind', 'wilaya', 'address', 'phone', 'hotline', 'email', 'website', 'hours', 'notes', 'is_published'])]
class SupportCenter extends Model
{
    protected function casts(): array
    {
        return ['kind' => CenterKind::class, 'is_published' => 'boolean'];
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }
}

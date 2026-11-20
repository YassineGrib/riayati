<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

#[Fillable(['admin_id', 'action', 'subject_type', 'subject_id', 'meta', 'ip'])]
class AdminActivity extends Model
{
    public const UPDATED_AT = null;

    protected function casts(): array
    {
        return ['meta' => 'array'];
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }
}

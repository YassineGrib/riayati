<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;

/** Two linked parents (a father and a mother) who share the visit calendar. */
class Family extends Model
{
    public const MAX_MEMBERS = 2;

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function isFull(): bool
    {
        return $this->users()->count() >= self::MAX_MEMBERS;
    }
}

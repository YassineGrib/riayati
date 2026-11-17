<?php

namespace App\Models;

use App\Enums\Role;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'role', 'family_id', 'terms_accepted_at', 'phone', 'wilaya', 'children_count'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'terms_accepted_at' => 'datetime',
            'password' => 'hashed',
            'role' => Role::class,
            'children_count' => 'integer',
        ];
    }

    public function family(): BelongsTo
    {
        return $this->belongsTo(Family::class);
    }

    /** The other parent in the same family, if the two accounts are linked. */
    public function partner(): ?self
    {
        if (! $this->family_id) {
            return null;
        }

        return self::where('family_id', $this->family_id)->whereKeyNot($this->getKey())->first();
    }

    public function isLinked(): bool
    {
        return $this->partner() !== null;
    }

    public function isAdmin(): bool
    {
        return $this->role === Role::Admin;
    }
}

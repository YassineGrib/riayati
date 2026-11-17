<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['code', 'user_id', 'family_id', 'expires_at', 'used_at', 'used_by'])]
class InviteCode extends Model
{
    /** No 0/O, 1/I/L: codes are read aloud and typed by hand. */
    private const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

    public const LENGTH = 6;

    public const TTL_HOURS = 48;

    protected function casts(): array
    {
        return ['expires_at' => 'datetime', 'used_at' => 'datetime'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function family(): BelongsTo
    {
        return $this->belongsTo(Family::class);
    }

    public static function issue(User $user, Family $family): self
    {
        do {
            $code = '';
            for ($i = 0; $i < self::LENGTH; $i++) {
                $code .= self::ALPHABET[random_int(0, strlen(self::ALPHABET) - 1)];
            }
        } while (self::where('code', $code)->exists());

        return self::create([
            'code' => $code,
            'user_id' => $user->id,
            'family_id' => $family->id,
            'expires_at' => now()->addHours(self::TTL_HOURS),
        ]);
    }

    /** "k7m-4q2" -> "K7M4Q2" */
    public static function normalize(string $input): string
    {
        return strtoupper(preg_replace('/[^A-Za-z0-9]/', '', $input) ?? '');
    }

    /** "K7M4Q2" -> "K7M-4Q2" */
    public function display(): string
    {
        return substr($this->code, 0, 3).'-'.substr($this->code, 3);
    }
}

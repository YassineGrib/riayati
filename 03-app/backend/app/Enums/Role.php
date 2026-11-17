<?php

namespace App\Enums;

enum Role: string
{
    case Father = 'father';
    case Mother = 'mother';
    case Admin = 'admin';

    public function isParent(): bool
    {
        return $this === self::Father || $this === self::Mother;
    }

    /** Roles a person may pick for themselves when registering in the app. */
    public static function registrable(): array
    {
        return [self::Father->value, self::Mother->value];
    }
}

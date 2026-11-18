<?php

namespace App\Enums;

enum ContentType: string
{
    case Article = 'article';
    case Law = 'law';
    case Ruling = 'ruling';
    case Guide = 'guide';

    public function label(): string
    {
        return match ($this) {
            self::Article => 'مقال',
            self::Law => 'قانون',
            self::Ruling => 'اجتهاد قضائي',
            self::Guide => 'دليل',
        };
    }

    public function color(): string
    {
        return match ($this) {
            self::Article => 'info',
            self::Law => 'primary',
            self::Ruling => 'warning',
            self::Guide => 'success',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())->mapWithKeys(fn (self $type): array => [$type->value => $type->label()])->all();
    }
}

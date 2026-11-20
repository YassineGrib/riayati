<?php

namespace App\Enums;

enum CenterKind: string
{
    case Court = 'court';
    case LegalAid = 'legal_aid';
    case ChildProtection = 'child_protection';
    case Psychological = 'psychological';
    case Social = 'social';
    case Ngo = 'ngo';
    case Hotline = 'hotline';

    public function label(): string
    {
        return match ($this) {
            self::Court => 'محكمة شؤون الأسرة',self::LegalAid => 'مساعدة قانونية',self::ChildProtection => 'حماية الطفولة',self::Psychological => 'دعم نفسي',self::Social => 'مصالح اجتماعية',self::Ngo => 'جمعية',self::Hotline => 'خط مساعدة',
        };
    }

    public function color(): string
    {
        return match ($this) {
            self::Court => 'primary',self::LegalAid => 'info',self::ChildProtection => 'warning',self::Psychological => 'success',self::Social => 'info',self::Ngo => 'gray',self::Hotline => 'danger',
        };
    }

    public static function options(): array
    {
        return collect(self::cases())->mapWithKeys(fn (self $kind): array => [$kind->value => $kind->label()])->all();
    }
}

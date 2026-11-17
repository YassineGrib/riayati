<?php

namespace App\Enums;

enum VisitStatus: string
{
    case Proposed = 'proposed';
    case Accepted = 'accepted';
    case Declined = 'declined';
    case Confirmed = 'confirmed';

    public function label(): string
    {
        return match ($this) {
            self::Proposed => 'بانتظار الرد',
            self::Accepted => 'تم القبول',
            self::Declined => 'مرفوضة',
            self::Confirmed => 'مؤكدة',
        };
    }

    /** Statuses that occupy the calendar slot (a declined visit frees it). */
    public static function active(): array
    {
        return [self::Proposed->value, self::Accepted->value, self::Confirmed->value];
    }
}

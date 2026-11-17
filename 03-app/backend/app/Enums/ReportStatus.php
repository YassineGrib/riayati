<?php

namespace App\Enums;

enum ReportStatus: string
{
    case UnderReview = 'under_review';
    case Reviewed = 'reviewed';

    public function label(): string
    {
        return match ($this) {
            self::UnderReview => 'قيد المراجعة',
            self::Reviewed => 'تمت المراجعة',
        };
    }
}

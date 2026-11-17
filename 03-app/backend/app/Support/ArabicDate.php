<?php

namespace App\Support;

use Carbon\CarbonInterface;

class ArabicDate
{
    private const MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'جوان', 'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

    /** "17 نوفمبر 2026 · 09:30" (Algerian month names, Western digits as in the app). */
    public static function format(CarbonInterface $date, bool $withTime = true): string
    {
        $text = $date->day.' '.self::MONTHS[$date->month - 1].' '.$date->year;

        return $withTime ? $text.' · '.$date->format('H:i') : $text;
    }
}

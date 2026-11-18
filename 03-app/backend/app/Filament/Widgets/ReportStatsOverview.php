<?php

namespace App\Filament\Widgets;

use App\Enums\ReportStatus;
use App\Models\IncidentReport;
use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class ReportStatsOverview extends StatsOverviewWidget
{
    protected static bool $isDiscovered = false;

    protected static ?bool $isLazyLoaded = false;

    public static function canView(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    protected function getStats(): array
    {
        return [
            Stat::make('قيد المراجعة', IncidentReport::where('status', ReportStatus::UnderReview)->count())
                ->description('تحتاج إلى مراجعة')->color('info'),
            Stat::make('تمت مراجعتها', IncidentReport::where('status', ReportStatus::Reviewed)->count())
                ->description('منذ بداية الاستخدام')->color('success'),
            Stat::make('وردت هذا الأسبوع', IncidentReport::where('created_at', '>=', now()->subDays(7))->count()),
        ];
    }
}

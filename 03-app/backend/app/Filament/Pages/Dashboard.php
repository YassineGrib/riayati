<?php

namespace App\Filament\Pages;

use App\Filament\Widgets\DashboardStats;
use App\Filament\Widgets\LatestReports;
use App\Filament\Widgets\ReportsByStatusChart;
use App\Filament\Widgets\ReportsPerWeekChart;
use Filament\Facades\Filament;

class Dashboard extends \Filament\Pages\Dashboard
{
    protected static ?string $title = 'الرئيسية';

    public static function canAccess(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    public function getWidgets(): array
    {
        return [DashboardStats::class, ReportsPerWeekChart::class, ReportsByStatusChart::class, LatestReports::class];
    }
}

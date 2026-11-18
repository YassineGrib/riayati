<?php

namespace App\Filament\Widgets;

use App\Enums\ReportStatus;
use App\Enums\Role;
use App\Enums\VisitStatus;
use App\Models\Family;
use App\Models\IncidentReport;
use App\Models\User;
use App\Models\Visit;
use Filament\Facades\Filament;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Database\Eloquent\Builder;

class DashboardStats extends StatsOverviewWidget
{
    protected static ?bool $isLazyLoaded = false;

    public static function canView(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    protected function getStats(): array
    {
        $reports = IncidentReport::query()->selectRaw('status, COUNT(*) as total')->groupBy('status')->pluck('total', 'status');

        return [
            Stat::make('قيد المراجعة', (int) ($reports[ReportStatus::UnderReview->value] ?? 0))->color('info'),
            Stat::make('تمت المراجعة', (int) ($reports[ReportStatus::Reviewed->value] ?? 0))->color('success'),
            Stat::make('إجمالي الأولياء', User::whereIn('role', [Role::Father, Role::Mother])->count()),
            Stat::make('الأسر المرتبطة', Family::whereHas('users', fn (Builder $query) => $query->where('role', Role::Father))
                ->whereHas('users', fn (Builder $query) => $query->where('role', Role::Mother))->count()),
            Stat::make('الزيارات القادمة', Visit::whereIn('status', VisitStatus::active())->where('starts_at', '>=', now())->count()),
        ];
    }
}

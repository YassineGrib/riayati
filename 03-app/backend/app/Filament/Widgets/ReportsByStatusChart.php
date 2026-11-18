<?php

namespace App\Filament\Widgets;

use App\Enums\ReportStatus;
use App\Models\IncidentReport;
use Filament\Facades\Filament;
use Filament\Widgets\ChartWidget;

class ReportsByStatusChart extends ChartWidget
{
    protected static ?bool $isLazyLoaded = false;

    protected ?string $heading = 'البلاغات حسب الحالة';

    protected ?string $maxHeight = '300px';

    public static function canView(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    protected function getData(): array
    {
        $counts = IncidentReport::query()->selectRaw('status, COUNT(*) as total')->groupBy('status')->pluck('total', 'status');

        return [
            'labels' => array_map(fn (ReportStatus $status): string => $status->label(), ReportStatus::cases()),
            'datasets' => [[
                'data' => array_map(fn (ReportStatus $status): int => (int) ($counts[$status->value] ?? 0), ReportStatus::cases()),
                'backgroundColor' => ['#2563eb', '#16a34a'],
            ]],
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}

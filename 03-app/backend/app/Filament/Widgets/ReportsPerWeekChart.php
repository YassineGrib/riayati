<?php

namespace App\Filament\Widgets;

use App\Models\IncidentReport;
use Carbon\CarbonInterface;
use Filament\Facades\Filament;
use Filament\Widgets\ChartWidget;

class ReportsPerWeekChart extends ChartWidget
{
    protected static ?bool $isLazyLoaded = false;

    protected ?string $heading = 'البلاغات خلال آخر ٨ أسابيع';

    protected ?string $description = 'كل أسبوع يبدأ يوم الاثنين';

    protected ?array $options = ['scales' => ['y' => ['beginAtZero' => true, 'ticks' => ['precision' => 0]]]];

    public static function canView(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    protected function getData(): array
    {
        $start = now()->startOfWeek(CarbonInterface::MONDAY)->subWeeks(7);
        $labels = [];
        $counts = [];

        for ($week = 0; $week < 8; $week++) {
            $from = $start->copy()->addWeeks($week);
            $labels[] = $from->format('Y-m-d');
            $counts[] = IncidentReport::where('created_at', '>=', $from)
                ->where('created_at', '<', $from->copy()->addWeek())->count();
        }

        return ['labels' => $labels, 'datasets' => [['label' => 'البلاغات', 'data' => $counts]]];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}

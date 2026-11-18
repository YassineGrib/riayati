<?php

namespace App\Filament\Resources\IncidentReports\Pages;

use App\Filament\Resources\IncidentReports\IncidentReportResource;
use App\Filament\Widgets\ReportStatsOverview;
use Filament\Resources\Pages\ListRecords;

class ListIncidentReports extends ListRecords
{
    protected static string $resource = IncidentReportResource::class;

    protected function getHeaderWidgets(): array
    {
        return [
            ReportStatsOverview::class,
        ];
    }
}

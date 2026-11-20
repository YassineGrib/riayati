<?php

namespace App\Filament\Resources\SupportCenters\Pages;

use App\Filament\Resources\SupportCenters\SupportCenterResource;
use Filament\Actions\EditAction;
use Filament\Resources\Pages\ViewRecord;

class ViewSupportCenter extends ViewRecord
{
    protected static string $resource = SupportCenterResource::class;

    protected function getHeaderActions(): array
    {
        return [EditAction::make()->label('تعديل')];
    }
}

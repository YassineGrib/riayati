<?php

namespace App\Filament\Resources\Visits\Pages;

use App\Filament\Resources\Visits\VisitResource;
use Filament\Resources\Pages\ViewRecord;

class ViewVisit extends ViewRecord
{
    protected static string $resource = VisitResource::class;

    public function mount(int|string $record): void
    {
        parent::mount($record);

        $this->getRecord()->loadMissing(['family.users', 'proposer']);
    }

    public function getTitle(): string
    {
        $record = $this->getRecord();

        return 'زيارة '.$record->starts_at->format('Y-m-d');
    }

    protected function getHeaderActions(): array
    {
        return [];
    }
}

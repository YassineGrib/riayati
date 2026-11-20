<?php

namespace App\Filament\Resources\SupportCenters\Pages;

use App\Filament\Resources\SupportCenters\SupportCenterResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditSupportCenter extends EditRecord
{
    protected static string $resource = SupportCenterResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()->label('حذف')->requiresConfirmation()
            ->modalHeading('حذف المركز؟')->modalDescription('سيتم حذف هذا المركز فقط ولا يمكن التراجع عن الحذف.')
            ->modalSubmitActionLabel('تأكيد الحذف')];
    }
}

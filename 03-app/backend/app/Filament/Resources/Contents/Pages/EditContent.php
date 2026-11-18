<?php

namespace App\Filament\Resources\Contents\Pages;

use App\Filament\Resources\Contents\ContentResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditContent extends EditRecord
{
    protected static string $resource = ContentResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()->label('حذف')->requiresConfirmation()
            ->modalHeading('حذف المحتوى؟')->modalDescription('سيتم حذف هذا المحتوى فقط ولا يمكن التراجع عن الحذف.')
            ->modalSubmitActionLabel('تأكيد الحذف')];
    }
}

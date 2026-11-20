<?php

namespace App\Filament\Resources\SupportCenters\Pages;

use App\Enums\CenterKind;
use App\Filament\Resources\SupportCenters\SupportCenterResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListSupportCenters extends ListRecords
{
    protected static string $resource = SupportCenterResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()->label('إضافة مركز')];
    }

    public function getTabs(): array
    {
        $tabs = ['all' => Tab::make('الكل')];
        foreach (CenterKind::cases() as $type) {
            $tabs[$type->value] = Tab::make($type->label())->modifyQueryUsing(fn (Builder $query): Builder => $query->where('kind', $type));
        }

        return $tabs;
    }
}

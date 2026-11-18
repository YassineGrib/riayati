<?php

namespace App\Filament\Resources\Contents\Pages;

use App\Enums\ContentType;
use App\Filament\Resources\Contents\ContentResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListContents extends ListRecords
{
    protected static string $resource = ContentResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()->label('إضافة محتوى')];
    }

    public function getTabs(): array
    {
        $tabs = ['all' => Tab::make('الكل')];
        foreach (ContentType::cases() as $type) {
            $tabs[$type->value] = Tab::make(match ($type) {
                ContentType::Article => 'المقالات',
                ContentType::Law => 'القوانين',
                ContentType::Ruling => 'الاجتهادات القضائية',
                ContentType::Guide => 'الأدلة',
            })->modifyQueryUsing(fn (Builder $query): Builder => $query->where('type', $type));
        }

        return $tabs;
    }
}

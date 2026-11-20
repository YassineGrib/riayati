<?php

namespace App\Filament\Resources\Contents\Pages;

use App\Enums\ContentType;
use App\Filament\Resources\Contents\ContentResource;
use App\Services\Assistant\ContentIndexer;
use Filament\Actions\Action;
use Filament\Actions\CreateAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListContents extends ListRecords
{
    protected static string $resource = ContentResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()->label('إضافة محتوى'),
            Action::make('reindexAssistant')->label('إعادة فهرسة المساعد')
                ->action(function (ContentIndexer $indexer): void {
                    $result = $indexer->reindexAll();
                    Notification::make()->title('فهرسة المساعد')
                        ->body("تمت فهرسة {$result['indexed']} نصًا؛ تعذرت فهرسة {$result['failed']} نصًا.")
                        ->status($result['failed'] > 0 ? 'warning' : 'success')->send();
                }),
        ];
    }

    public function getSubheading(): ?string
    {
        return 'المساعد الآلي يستند فقط إلى النصوص المنشورة والمفعّلة والمفهرسة. راجع النصوص قبل نشرها؛ لا تُدخل بيانات شخصية.';
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

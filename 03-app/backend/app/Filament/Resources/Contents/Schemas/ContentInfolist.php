<?php

namespace App\Filament\Resources\Contents\Schemas;

use App\Enums\ContentType;
use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ContentInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make('تفاصيل المحتوى')->columns(2)->columnSpanFull()->schema([
                TextEntry::make('title')->label('العنوان')->wrap()->columnSpanFull(),
                TextEntry::make('type')->label('النوع')->badge()
                    ->formatStateUsing(fn (ContentType $state): string => $state->label())
                    ->color(fn (ContentType $state): string => $state->color()),
                TextEntry::make('slug')->label('المعرّف الفريد'),
                TextEntry::make('category')->label('التصنيف')->placeholder('—'),
                TextEntry::make('reference')->label('المرجع')->placeholder('—'),
                TextEntry::make('summary')->label('الملخص')->wrap()->columnSpanFull()->placeholder('—'),
                IconEntry::make('is_published')->label('منشور')->boolean(),
                TextEntry::make('published_at')->label('تاريخ النشر')->dateTime('Y-m-d H:i')->placeholder('غير منشور'),
                TextEntry::make('body')->label('النص')->html()->columnSpanFull()
                    ->extraAttributes(['style' => 'overflow-wrap: anywhere']),
            ]),
        ]);
    }
}

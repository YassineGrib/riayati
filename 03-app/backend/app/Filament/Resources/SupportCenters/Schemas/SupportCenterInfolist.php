<?php

namespace App\Filament\Resources\SupportCenters\Schemas;

use App\Enums\CenterKind;
use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class SupportCenterInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            TextEntry::make('name')->label('الاسم')->wrap()->placeholder('—'),
            TextEntry::make('kind')->label('النوع')->badge()->formatStateUsing(fn (CenterKind $state): string => $state->label())->color(fn (CenterKind $state): string => $state->color())->wrap()->placeholder('—'),
            TextEntry::make('wilaya')->label('الولاية')->wrap()->placeholder('—'),
            TextEntry::make('address')->label('العنوان')->wrap()->placeholder('—'),
            TextEntry::make('phone')->label('الهاتف')->wrap()->placeholder('—'),
            TextEntry::make('hotline')->label('خط المساعدة')->wrap()->placeholder('—'),
            TextEntry::make('email')->label('البريد الإلكتروني')->wrap()->placeholder('—'),
            TextEntry::make('website')->label('الموقع')->wrap()->placeholder('—'),
            TextEntry::make('hours')->label('ساعات العمل')->wrap()->placeholder('—'),
            TextEntry::make('notes')->label('ملاحظات')->wrap()->placeholder('—'),
            IconEntry::make('is_published')->label('منشور')->boolean(),
        ]);
    }
}

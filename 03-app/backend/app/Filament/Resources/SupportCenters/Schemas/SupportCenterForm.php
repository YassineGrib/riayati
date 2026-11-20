<?php

namespace App\Filament\Resources\SupportCenters\Schemas;

use App\Enums\CenterKind;
use App\Support\Wilayas;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;
use Illuminate\Validation\Rule;

class SupportCenterForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Select::make('kind')->label('النوع')->options(CenterKind::options())->required()->rules([Rule::enum(CenterKind::class)]),
            Select::make('wilaya')->label('الولاية')->options(Wilayas::options())->searchable()->rules([Rule::in(array_keys(Wilayas::options()))]),
            TextInput::make('name')->label('الاسم')->required()->maxLength(255),
            TextInput::make('address')->label('العنوان')->maxLength(255),
            TextInput::make('phone')->label('الهاتف')->maxLength(40)->regex('/^[0-9+(). \-]{2,40}$/'),
            TextInput::make('hotline')->label('خط المساعدة')->maxLength(40)->regex('/^[0-9+(). \-]{2,40}$/'),
            TextInput::make('email')->label('البريد الإلكتروني')->email()->maxLength(255),
            TextInput::make('website')->label('الموقع')->url()->maxLength(255),
            TextInput::make('hours')->label('ساعات العمل')->maxLength(255),
            Textarea::make('notes')->label('ملاحظات')->columnSpanFull(),
            Toggle::make('is_published')->label('منشور')->default(false),
        ]);
    }
}

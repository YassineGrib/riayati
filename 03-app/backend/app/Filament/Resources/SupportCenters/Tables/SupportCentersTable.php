<?php

namespace App\Filament\Resources\SupportCenters\Tables;

use App\Enums\CenterKind;
use App\Support\Wilayas;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class SupportCentersTable
{
    public static function configure(Table $table): Table
    {
        return $table->defaultSort('id', 'desc')->columns([
            TextColumn::make('name')->label('الاسم')->searchable()->wrap(),
            TextColumn::make('kind')->label('النوع')->badge()->formatStateUsing(fn (CenterKind $state): string => $state->label())->color(fn (CenterKind $state): string => $state->color()),
            TextColumn::make('wilaya')->label('الولاية')->formatStateUsing(fn ($state) => Wilayas::options()[$state] ?? $state),
            TextColumn::make('phone')->label('الهاتف'), IconColumn::make('is_published')->label('منشور')->boolean(),
        ])->filters([SelectFilter::make('kind')->label('النوع')->options(CenterKind::options()), SelectFilter::make('wilaya')->label('الولاية')->options(Wilayas::options()), TernaryFilter::make('is_published')->label('منشور')])
            ->recordActions([ViewAction::make()->label('عرض'), EditAction::make()->label('تعديل'), DeleteAction::make()->label('حذف')->requiresConfirmation()]);
    }
}

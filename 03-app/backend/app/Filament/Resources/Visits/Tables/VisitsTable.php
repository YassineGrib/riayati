<?php

namespace App\Filament\Resources\Visits\Tables;

use App\Enums\Role;
use App\Enums\VisitStatus;
use App\Models\Visit;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class VisitsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('starts_at', 'desc')
            ->columns([
                TextColumn::make('starts_at')
                    ->label('تاريخ الزيارة')
                    ->date('Y-m-d')
                    ->sortable(),
                TextColumn::make('time_range')
                    ->label('التوقيت')
                    ->state(fn (Visit $record): string => $record->starts_at->format('H:i').' - '.$record->ends_at->format('H:i')),
                TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (VisitStatus $state): string => $state->label())
                    ->color(fn (VisitStatus $state): string => match ($state) {
                        VisitStatus::Proposed => 'info',
                        VisitStatus::Accepted => 'warning',
                        VisitStatus::Declined => 'danger',
                        VisitStatus::Confirmed => 'success',
                    }),
                TextColumn::make('family_parents')
                    ->label('العائلة (الوالدان)')
                    ->state(function (Visit $record): string {
                        $names = $record->family?->users->pluck('name')->filter()->values();

                        return $names && $names->isNotEmpty() ? $names->join(' و ') : '—';
                    }),
                TextColumn::make('proposer_role')
                    ->label('مقدّم الطلب')
                    ->state(fn (Visit $record): string => match ($record->proposer?->role) {
                        Role::Father => 'أب',
                        Role::Mother => 'أم',
                        default => '—',
                    })
                    ->description(fn (Visit $record): ?string => $record->proposer?->name),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('الحالة')
                    ->options([
                        VisitStatus::Proposed->value => VisitStatus::Proposed->label(),
                        VisitStatus::Accepted->value => VisitStatus::Accepted->label(),
                        VisitStatus::Declined->value => VisitStatus::Declined->label(),
                        VisitStatus::Confirmed->value => VisitStatus::Confirmed->label(),
                    ]),
                Filter::make('starts_at')
                    ->label('تاريخ الزيارة')
                    ->form([
                        DatePicker::make('from')->label('من تاريخ'),
                        DatePicker::make('until')->label('إلى تاريخ'),
                    ])
                    ->query(fn (Builder $query, array $data): Builder => $query
                        ->when($data['from'] ?? null, fn (Builder $query, string $date): Builder => $query->whereDate('starts_at', '>=', $date))
                        ->when($data['until'] ?? null, fn (Builder $query, string $date): Builder => $query->whereDate('starts_at', '<=', $date))),
            ])
            ->recordActions([
                ViewAction::make()->label('عرض')->icon('heroicon-o-eye'),
            ])
            ->toolbarActions([]);
    }
}

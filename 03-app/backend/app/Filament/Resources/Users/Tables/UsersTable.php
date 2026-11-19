<?php

namespace App\Filament\Resources\Users\Tables;

use App\Enums\Role;
use App\Models\User;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class UsersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('name')
                    ->label('الاسم')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('role')
                    ->label('الدور')
                    ->badge()
                    ->formatStateUsing(fn (Role $state): string => match ($state) {
                        Role::Father => 'أب',
                        Role::Mother => 'أم',
                        Role::Admin => 'مسؤول',
                    })
                    ->color(fn (Role $state): string => match ($state) {
                        Role::Father => 'info',
                        Role::Mother => 'primary',
                        default => 'gray',
                    }),
                TextColumn::make('phone')
                    ->label('الهاتف')
                    ->placeholder('غير محدد')
                    ->extraAttributes(['dir' => 'ltr'])
                    ->searchable(),
                TextColumn::make('wilaya')
                    ->label('الولاية')
                    ->placeholder('غير محدد')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('children_count')
                    ->label('عدد الأطفال')
                    ->placeholder('0')
                    ->sortable(),
                TextColumn::make('linked_status')
                    ->label('حالة الربط')
                    ->badge()
                    ->state(function (User $record): string {
                        return ($record->family_id !== null && ($record->family?->users->count() ?? 0) >= 2)
                            ? 'مرتبط'
                            : 'غير مرتبط';
                    })
                    ->color(fn (string $state): string => $state === 'مرتبط' ? 'success' : 'gray'),
                TextColumn::make('partner_name')
                    ->label('الطرف الآخر')
                    ->state(function (User $record): string {
                        if (! $record->family_id) {
                            return '—';
                        }
                        $partner = $record->family?->users->first(fn ($u) => $u->id !== $record->id);

                        return $partner?->name ?? '—';
                    }),
                TextColumn::make('created_at')
                    ->label('تاريخ الانضمام')
                    ->date('Y-m-d')
                    ->sortable(),
                TextColumn::make('last_activity_at')
                    ->label('آخر نشاط')
                    ->dateTime('Y-m-d H:i')
                    ->placeholder('لا يوجد نشاط')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('role')
                    ->label('الدور')
                    ->options([
                        Role::Father->value => 'أب',
                        Role::Mother->value => 'أم',
                    ]),
                SelectFilter::make('linked')
                    ->label('حالة الربط')
                    ->options([
                        'linked' => 'مرتبط',
                        'unlinked' => 'غير مرتبط',
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return match ($data['value'] ?? null) {
                            'linked' => $query->whereHas('family', fn (Builder $q) => $q->has('users', '>=', 2)),
                            'unlinked' => $query->where(fn (Builder $q) => $q->whereNull('family_id')->orWhereDoesntHave('family', fn (Builder $fq) => $fq->has('users', '>=', 2))),
                            default => $query,
                        };
                    }),
                SelectFilter::make('wilaya')
                    ->label('الولاية')
                    ->options(fn (): array => User::whereNotNull('wilaya')->where('wilaya', '!=', '')->orderBy('wilaya')->pluck('wilaya', 'wilaya')->toArray())
                    ->searchable(),
            ])
            ->recordActions([
                ViewAction::make()->label('عرض')->icon('heroicon-o-eye'),
            ])
            ->toolbarActions([]);
    }
}

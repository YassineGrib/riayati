<?php

namespace App\Filament\Resources\Visits\Schemas;

use App\Enums\Role;
use App\Enums\VisitStatus;
use App\Models\Visit;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Group;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class VisitInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->columns(['lg' => 3])->components([
            Group::make([
                Section::make('تفاصيل الزيارة')->schema([
                    TextEntry::make('starts_at')
                        ->label('تاريخ الزيارة')
                        ->date('Y-m-d'),
                    TextEntry::make('time_range')
                        ->label('التوقيت')
                        ->state(fn (Visit $record): string => $record->starts_at->format('H:i').' - '.$record->ends_at->format('H:i')),
                    TextEntry::make('status')
                        ->label('الحالة')
                        ->badge()
                        ->formatStateUsing(fn (VisitStatus $state): string => $state->label())
                        ->color(fn (VisitStatus $state): string => match ($state) {
                            VisitStatus::Proposed => 'info',
                            VisitStatus::Accepted => 'warning',
                            VisitStatus::Declined => 'danger',
                            VisitStatus::Confirmed => 'success',
                        }),
                    TextEntry::make('note')
                        ->label('ملاحظات الزيارة')
                        ->placeholder('لا توجد ملاحظات')
                        ->columnSpanFull(),
                ])->columns(3),
                Section::make('أطراف الزيارة')->schema([
                    TextEntry::make('family_parents')
                        ->label('الوالدان')
                        ->state(function (Visit $record): string {
                            $names = $record->family?->users->pluck('name')->filter()->values();

                            return $names && $names->isNotEmpty() ? $names->join(' و ') : '—';
                        }),
                    TextEntry::make('proposer.name')
                        ->label('مقدّم المقترح'),
                    TextEntry::make('proposer.role')
                        ->label('دور مقدّم المقترح')
                        ->formatStateUsing(fn (?Role $state): string => match ($state) {
                            Role::Father => 'أب',
                            Role::Mother => 'أم',
                            default => '—',
                        }),
                ])->columns(3),
            ])->columnSpan(['lg' => 2]),
            Group::make([
                Section::make('سجل التحديثات')->schema([
                    TextEntry::make('created_at')
                        ->label('تاريخ الاقتراح')
                        ->dateTime('Y-m-d H:i')
                        ->icon('heroicon-o-calendar')
                        ->iconColor('primary'),
                    TextEntry::make('responded_at')
                        ->label('تاريخ الرد')
                        ->dateTime('Y-m-d H:i')
                        ->visible(fn (Visit $record): bool => $record->responded_at !== null),
                    TextEntry::make('confirmed_at')
                        ->label('تاريخ التأكيد')
                        ->dateTime('Y-m-d H:i')
                        ->visible(fn (Visit $record): bool => $record->confirmed_at !== null)
                        ->icon('heroicon-o-check-circle')
                        ->iconColor('success'),
                ]),
            ]),
        ]);
    }
}

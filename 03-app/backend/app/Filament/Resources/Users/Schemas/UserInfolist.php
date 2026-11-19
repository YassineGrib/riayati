<?php

namespace App\Filament\Resources\Users\Schemas;

use App\Enums\Role;
use App\Models\User;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Group;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class UserInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->columns(['lg' => 3])->components([
            Group::make([
                Section::make('بيانات الحساب')->schema([
                    TextEntry::make('name')->label('الاسم'),
                    TextEntry::make('email')->label('البريد الإلكتروني'),
                    TextEntry::make('role')->label('الدور')
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
                    TextEntry::make('phone')->label('رقم الهاتف')
                        ->placeholder('غير محدد')
                        ->extraAttributes(['dir' => 'ltr']),
                    TextEntry::make('wilaya')->label('الولاية')
                        ->placeholder('غير محدد'),
                    TextEntry::make('children_count')->label('عدد الأطفال')
                        ->placeholder('غير محدد'),
                    TextEntry::make('created_at')->label('تاريخ الانضمام')
                        ->dateTime('Y-m-d H:i'),
                    TextEntry::make('last_activity_at')->label('آخر نشاط')
                        ->dateTime('Y-m-d H:i')
                        ->placeholder('لا يوجد نشاط'),
                ])->columns(2),
            ])->columnSpan(['lg' => 2]),
            Group::make([
                Section::make('بيانات العائلة والربط')->schema([
                    TextEntry::make('linked_status')->label('حالة الربط')
                        ->badge()
                        ->state(fn (User $record): string => ($record->family_id !== null && ($record->family?->users->count() ?? 0) >= 2) ? 'مرتبط' : 'غير مرتبط')
                        ->color(fn (string $state): string => $state === 'مرتبط' ? 'success' : 'gray'),
                    TextEntry::make('partner_name')->label('اسم الطرف الآخر')
                        ->state(fn (User $record): string => $record->family?->users->first(fn ($u) => $u->id !== $record->id)?->name ?? 'غير محدد'),
                    TextEntry::make('partner_role')->label('دور الطرف الآخر')
                        ->state(fn (User $record): string => match ($record->family?->users->first(fn ($u) => $u->id !== $record->id)?->role) {
                            Role::Father => 'أب',
                            Role::Mother => 'أم',
                            default => 'غير محدد',
                        }),
                    TextEntry::make('family_id')->label('معرّف العائلة')
                        ->placeholder('لا توجد عائلة'),
                ]),
            ]),
        ]);
    }
}

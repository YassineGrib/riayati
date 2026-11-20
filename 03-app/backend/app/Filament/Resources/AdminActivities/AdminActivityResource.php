<?php

namespace App\Filament\Resources\AdminActivities;

use App\Models\AdminActivity;
use BackedEnum;
use Filament\Facades\Filament;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Auth\Access\Response;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use UnitEnum;

class AdminActivityResource extends Resource
{
    protected static ?string $model = AdminActivity::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBuildingOffice;

    protected static string|UnitEnum|null $navigationGroup = 'الحسابات';

    protected static ?string $navigationLabel = 'سجل النشاط';

    protected static ?string $modelLabel = 'سجل النشاط';

    protected static ?string $pluralModelLabel = 'سجل النشاط';

    protected static ?string $recordTitleAttribute = 'action';

    public static function getAuthorizationResponse(string|UnitEnum $action, ?Model $record = null): Response
    {
        if (! (Filament::auth()->user()?->isAdmin() ?? false)) {
            return Response::deny();
        }

        return parent::getAuthorizationResponse($action, $record);
    }

    public static function canViewAny(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    public static function canView(Model $record): bool
    {
        return static::canViewAny();
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit(Model $record): bool
    {
        return false;
    }

    public static function canDelete(Model $record): bool
    {
        return false;
    }

    public static function canDeleteAny(): bool
    {
        return false;
    }

    public static function table(Table $table): Table
    {
        return $table->defaultSort('created_at', 'desc')->columns([
            TextColumn::make('admin.name')->label('المسؤول'),
            TextColumn::make('action')->label('الإجراء'),
            TextColumn::make('subject_type')->label('نوع السجل'),
            TextColumn::make('subject_id')->label('رقم السجل'),
            TextColumn::make('created_at')->label('التاريخ')->dateTime('Y-m-d H:i')->sortable(),
        ])->filters([
            SelectFilter::make('action')->label('الإجراء')
                ->options(fn () => AdminActivity::query()->distinct()->pluck('action', 'action')->all()),
            SelectFilter::make('admin_id')->label('المسؤول')->relationship('admin', 'name'),
        ])->recordActions([]);
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with('admin');
    }

    public static function getPages(): array
    {
        return ['index' => Pages\ListAdminActivities::route('/')];
    }
}

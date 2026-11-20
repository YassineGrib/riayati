<?php

namespace App\Filament\Resources\SupportCenters;

use App\Filament\Resources\SupportCenters\Pages\CreateSupportCenter;
use App\Filament\Resources\SupportCenters\Pages\EditSupportCenter;
use App\Filament\Resources\SupportCenters\Pages\ListSupportCenters;
use App\Filament\Resources\SupportCenters\Pages\ViewSupportCenter;
use App\Filament\Resources\SupportCenters\Schemas\SupportCenterForm;
use App\Filament\Resources\SupportCenters\Schemas\SupportCenterInfolist;
use App\Filament\Resources\SupportCenters\Tables\SupportCentersTable;
use App\Models\SupportCenter;
use BackedEnum;
use Filament\Facades\Filament;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Auth\Access\Response;
use Illuminate\Database\Eloquent\Model;
use UnitEnum;

class SupportCenterResource extends Resource
{
    protected static ?string $model = SupportCenter::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBuildingOffice;

    protected static string|UnitEnum|null $navigationGroup = 'المحتوى';

    protected static ?string $navigationLabel = 'مراكز وهيئات';

    protected static ?string $modelLabel = 'مراكز وهيئات';

    protected static ?string $pluralModelLabel = 'مراكز وهيئات';

    protected static ?string $recordTitleAttribute = 'name';

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
        return static::canViewAny();
    }

    public static function canEdit(Model $record): bool
    {
        return static::canViewAny();
    }

    public static function canDelete(Model $record): bool
    {
        return static::canViewAny();
    }

    public static function canDeleteAny(): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return SupportCenterForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return SupportCenterInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return SupportCentersTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListSupportCenters::route('/'),
            'create' => CreateSupportCenter::route('/create'),
            'view' => ViewSupportCenter::route('/{record}'),
            'edit' => EditSupportCenter::route('/{record}/edit'),
        ];
    }
}

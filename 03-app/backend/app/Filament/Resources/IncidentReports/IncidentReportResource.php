<?php

namespace App\Filament\Resources\IncidentReports;

use App\Enums\ReportStatus;
use App\Filament\Resources\IncidentReports\Pages\ListIncidentReports;
use App\Filament\Resources\IncidentReports\Pages\ViewIncidentReport;
use App\Filament\Resources\IncidentReports\Schemas\IncidentReportInfolist;
use App\Filament\Resources\IncidentReports\Tables\IncidentReportsTable;
use App\Models\IncidentReport;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class IncidentReportResource extends Resource
{
    protected static ?string $model = IncidentReport::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentText;

    protected static ?string $navigationLabel = 'البلاغات';

    protected static ?string $modelLabel = 'بلاغ';

    protected static ?string $pluralModelLabel = 'البلاغات';

    protected static ?string $recordTitleAttribute = 'reference';

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

    public static function getNavigationBadge(): ?string
    {
        return (string) IncidentReport::where('status', ReportStatus::UnderReview)->count();
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with('user')->withCount('attachments');
    }

    public static function infolist(Schema $schema): Schema
    {
        return IncidentReportInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return IncidentReportsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListIncidentReports::route('/'),
            'view' => ViewIncidentReport::route('/{record}'),
        ];
    }
}

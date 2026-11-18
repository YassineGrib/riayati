<?php

namespace App\Filament\Widgets;

use App\Enums\ReportStatus;
use App\Filament\Resources\IncidentReports\IncidentReportResource;
use App\Models\IncidentReport;
use Filament\Actions\ViewAction;
use Filament\Facades\Filament;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class LatestReports extends TableWidget
{
    protected static ?bool $isLazyLoaded = false;

    protected int|string|array $columnSpan = 'full';

    public static function canView(): bool
    {
        return Filament::auth()->user()?->isAdmin() ?? false;
    }

    public function table(Table $table): Table
    {
        return $table->heading('أحدث البلاغات')
            ->query(IncidentReport::query()->with('user:id,name')->reorder()->orderByDesc('created_at')->orderByDesc('id')->limit(5))
            ->paginated(false)
            ->columns([
                TextColumn::make('reference')->label('رقم البلاغ'),
                TextColumn::make('user.name')->label('مقدّم البلاغ'),
                TextColumn::make('created_at')->label('تاريخ الإرسال')->dateTime('Y-m-d H:i'),
                TextColumn::make('status')->label('الحالة')->badge()
                    ->formatStateUsing(fn (ReportStatus $state): string => $state->label())
                    ->color(fn (ReportStatus $state): string => $state === ReportStatus::Reviewed ? 'success' : 'info'),
            ])
            ->recordUrl(fn (IncidentReport $record): string => IncidentReportResource::getUrl('view', ['record' => $record]))
            ->recordActions([
                ViewAction::make()->label('عرض')->url(fn (IncidentReport $record): string => IncidentReportResource::getUrl('view', ['record' => $record])),
            ]);
    }
}

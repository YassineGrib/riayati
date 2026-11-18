<?php

namespace App\Filament\Resources\IncidentReports\Tables;

use App\Enums\ReportStatus;
use App\Enums\Role;
use App\Models\IncidentReport;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Actions\BulkAction;
use Filament\Actions\ViewAction;
use Filament\Facades\Filament;
use Filament\Forms\Components\DatePicker;
use Filament\Support\Enums\FontFamily;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class IncidentReportsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('reference')->label('رقم البلاغ')
                    ->fontFamily(FontFamily::Mono)->extraAttributes(['dir' => 'ltr'])->searchable(),
                TextColumn::make('user.name')->label('مقدّم البلاغ')->searchable()
                    ->description(fn (IncidentReport $record): string => match ($record->user->role) {
                        Role::Father => 'أب',
                        Role::Mother => 'أم',
                        Role::Admin => 'مسؤول',
                    }),
                TextColumn::make('incident_at')->label('تاريخ الحادثة')->dateTime('Y-m-d H:i')->sortable(),
                TextColumn::make('attachments_count')->label('المرفقات'),
                TextColumn::make('status')->label('الحالة')->badge()
                    ->formatStateUsing(fn (ReportStatus $state): string => $state->label())
                    ->color(fn (ReportStatus $state): string => $state === ReportStatus::Reviewed ? 'success' : 'info'),
            ])
            ->filters([
                SelectFilter::make('status')->label('الحالة')->options([
                    ReportStatus::UnderReview->value => ReportStatus::UnderReview->label(),
                    ReportStatus::Reviewed->value => ReportStatus::Reviewed->label(),
                ]),
                SelectFilter::make('role')->label('الدور')->options([
                    Role::Father->value => 'أب',
                    Role::Mother->value => 'أم',
                ])->query(fn (Builder $query, array $data): Builder => $query
                    ->when($data['value'] ?? null, fn (Builder $query, string $role): Builder => $query
                        ->whereHas('user', fn (Builder $query): Builder => $query->where('role', $role)))),
                Filter::make('incident_at')->label('تاريخ الحادثة')->form([
                    DatePicker::make('from')->label('من تاريخ'),
                    DatePicker::make('until')->label('إلى تاريخ'),
                ])->query(fn (Builder $query, array $data): Builder => $query
                    ->when($data['from'] ?? null, fn (Builder $query, string $date): Builder => $query->whereDate('incident_at', '>=', $date))
                    ->when($data['until'] ?? null, fn (Builder $query, string $date): Builder => $query->whereDate('incident_at', '<=', $date))),
            ])
            ->recordActions([
                ViewAction::make()->label('عرض')->icon('heroicon-o-eye'),
                Action::make('markReviewed')->label('تعيين كمُراجَع')->icon('heroicon-o-check')->color('success')
                    ->authorize(fn (): bool => Filament::auth()->user()?->isAdmin() ?? false)
                    ->requiresConfirmation()->modalHeading('تأكيد المراجعة؟')
                    ->modalDescription('سيتم تسجيل مراجعة البلاغ باسمك مع وقت المراجعة.')
                    ->modalSubmitActionLabel('تأكيد المراجعة')
                    ->action(fn (IncidentReport $record) => self::markReviewed($record, Filament::auth()->user())),
            ])
            ->toolbarActions([
                BulkAction::make('markReviewed')->label('تعيين كمُراجَع')->color('success')
                    ->authorize(fn (): bool => Filament::auth()->user()?->isAdmin() ?? false)
                    ->requiresConfirmation()->modalHeading('تأكيد المراجعة؟')
                    ->modalDescription('ستتم مراجعة البلاغات المحددة التي لا تزال قيد المراجعة.')
                    ->modalSubmitActionLabel('تأكيد المراجعة')
                    ->deselectRecordsAfterCompletion()
                    ->action(function (Collection $records): void {
                        $admin = Filament::auth()->user();
                        foreach ($records as $record) {
                            self::markReviewed($record, $admin);
                        }
                    }),
            ]);
    }

    private static function markReviewed(IncidentReport $record, User $admin): void
    {
        abort_unless($admin->isAdmin(), 403);

        // Re-read under a lock so stale selections cannot overwrite a previous review.
        DB::transaction(function () use ($record, $admin): void {
            $report = IncidentReport::whereKey($record->getKey())->lockForUpdate()->firstOrFail();

            if ($report->status === ReportStatus::UnderReview) {
                $report->markReviewed($admin);
            }
        });
    }
}

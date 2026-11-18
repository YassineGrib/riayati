<?php

namespace App\Filament\Resources\IncidentReports\Schemas;

use App\Enums\ReportStatus;
use App\Enums\Role;
use App\Models\IncidentReport;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Components\ViewEntry;
use Filament\Schemas\Components\Group;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class IncidentReportInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->columns(['lg' => 3])->components([
            Group::make([
                Section::make('الوصف')->schema([
                    TextEntry::make('description')->hiddenLabel()->wrap()
                        ->extraAttributes(['style' => 'white-space: pre-wrap; overflow-wrap: anywhere']),
                ]),
                Section::make('المرفقات')
                    ->description('روابط الملفات مؤقتة وتنتهي بعد وقت قصير. افتح الملف من هنا عند الحاجة.')
                    ->schema([
                        RepeatableEntry::make('attachments')->hiddenLabel()
                            ->placeholder('لا توجد مرفقات')
                            ->grid(['sm' => 2])->schema([
                                ViewEntry::make('evidence')->hiddenLabel()
                                    ->view('filament.admin.attachment-tile'),
                            ]),
                    ]),
            ])->columnSpan(['lg' => 2]),
            Group::make([
                Section::make('مقدّم البلاغ')->schema([
                    TextEntry::make('user.name')->label('الاسم'),
                    TextEntry::make('user.role')->label('الدور')
                        ->formatStateUsing(fn (Role $state): string => match ($state) {
                            Role::Father => 'أب',
                            Role::Mother => 'أم',
                            Role::Admin => 'مسؤول',
                        }),
                    TextEntry::make('user.phone')->label('الهاتف')
                        ->visible(fn (IncidentReport $record): bool => filled($record->user->phone))
                        ->extraAttributes(['dir' => 'ltr']),
                    TextEntry::make('user.wilaya')->label('الولاية')
                        ->visible(fn (IncidentReport $record): bool => filled($record->user->wilaya)),
                    TextEntry::make('incident_at')->label('تاريخ الحادثة')->dateTime('Y-m-d H:i'),
                ]),
                Section::make('سجل الحالة')->schema([
                    TextEntry::make('status')->label('الحالة')->badge()
                        ->formatStateUsing(fn (ReportStatus $state): string => $state->label())
                        ->color(fn (ReportStatus $state): string => $state === ReportStatus::Reviewed ? 'success' : 'info'),
                    TextEntry::make('created_at')->label('أُرسل البلاغ')->dateTime('Y-m-d H:i')
                        ->icon('heroicon-o-check-circle')->iconColor('success'),
                    TextEntry::make('reviewer.name')->label('تمت المراجعة بواسطة')
                        ->visible(fn (IncidentReport $record): bool => $record->status === ReportStatus::Reviewed),
                    TextEntry::make('reviewed_at')->label('تاريخ المراجعة')->dateTime('Y-m-d H:i')
                        ->icon('heroicon-o-check-circle')->iconColor('success')
                        ->visible(fn (IncidentReport $record): bool => $record->status === ReportStatus::Reviewed),
                ])->extraAttributes(['class' => 'report-timeline']),
            ]),
        ]);
    }
}

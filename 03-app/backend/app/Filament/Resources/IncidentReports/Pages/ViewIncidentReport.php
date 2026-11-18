<?php

namespace App\Filament\Resources\IncidentReports\Pages;

use App\Enums\ReportStatus;
use App\Filament\Resources\IncidentReports\IncidentReportResource;
use App\Models\IncidentReport;
use App\Services\ReportPdf;
use Filament\Actions\Action;
use Filament\Facades\Filament;
use Filament\Resources\Pages\ViewRecord;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ViewIncidentReport extends ViewRecord
{
    protected static string $resource = IncidentReportResource::class;

    public function mount(int|string $record): void
    {
        parent::mount($record);

        $this->getRecord()->loadMissing(['attachments', 'reviewer']);
    }

    public function getTitle(): string
    {
        return $this->getRecord()->reference;
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('downloadPdf')->label('تحميل PDF')->icon('heroicon-o-arrow-down-tray')
                ->color('gray')
                ->action(function (ReportPdf $pdf): StreamedResponse {
                    abort_unless(Filament::auth()->user()?->isAdmin(), 403);
                    $report = $this->getRecord()->loadMissing(['user', 'attachments']);

                    return response()->streamDownload(
                        function () use ($pdf, $report): void {
                            echo $pdf->render($report);
                        },
                        $report->reference.'.pdf',
                        ['Content-Type' => 'application/pdf'],
                    );
                }),
            Action::make('markReviewed')->label('تمت المراجعة')->icon('heroicon-o-check')
                ->requiresConfirmation()->modalHeading('تأكيد المراجعة؟')
                ->visible(fn (): bool => $this->getRecord()->status === ReportStatus::UnderReview)
                ->action(function (): void {
                    $admin = Filament::auth()->user();
                    abort_unless($admin?->isAdmin(), 403);

                    DB::transaction(function () use ($admin): void {
                        $report = IncidentReport::whereKey($this->getRecord()->getKey())->lockForUpdate()->firstOrFail();
                        if ($report->status === ReportStatus::UnderReview) {
                            $report->markReviewed($admin);
                        }
                    });

                    $this->getRecord()->refresh()->loadMissing(['user', 'attachments', 'reviewer']);
                }),
        ];
    }
}

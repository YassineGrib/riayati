<?php

namespace App\Http\Controllers\Api;

use App\Enums\ReportStatus;
use App\Http\Controllers\Controller;
use App\Models\IncidentReport;
use App\Models\ReportAttachment;
use App\Services\AdminActivityLog;
use App\Services\ReportPdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Throwable;

class ReportController extends Controller
{
    /** The signed-in parent's own reports, newest first. */
    public function index(Request $request): JsonResponse
    {
        $request->validate(['status' => ['nullable', 'in:under_review,reviewed']]);

        $reports = IncidentReport::where('user_id', $request->user()->id)
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->withCount('attachments')
            ->latest()
            ->get();

        return response()->json(['reports' => $reports->map(fn ($r) => array_merge(
            $r->setRelation('attachments', collect())->toApi(false),
            ['attachments_count' => $r->attachments_count],
        ))]);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->role->isParent(), 403);

        $max = config('riayati.reports.max_files');
        $data = $request->validate([
            'description' => ['required', 'string', 'min:3', 'max:5000'],
            'incident_at' => ['required', 'date', 'before_or_equal:now'],
            'files' => ['nullable', 'array', "max:{$max}"],
            'files.*' => ['file', 'max:'.config('riayati.reports.max_file_kb'), 'mimetypes:'.implode(',', config('riayati.reports.allowed_mimes'))],
        ]);

        $stored = [];
        try {
            $report = DB::transaction(function () use ($request, $data, &$stored) {
                $report = IncidentReport::create([
                    'reference' => IncidentReport::nextReference(),
                    'user_id' => $request->user()->id,
                    'description' => trim($data['description']),
                    'incident_at' => $data['incident_at'],
                    'status' => ReportStatus::UnderReview,
                ]);

                foreach ($request->file('files', []) as $file) {
                    $mime = $file->getMimeType();
                    // Random name on the private disk: the original name is kept only in the database.
                    $path = $file->store("reports/{$report->id}", 'local');
                    $stored[] = $path;

                    $report->attachments()->create([
                        'path' => $path,
                        'original_name' => mb_substr($file->getClientOriginalName(), 0, 190),
                        'mime' => $mime,
                        'kind' => ReportAttachment::kindFor($mime),
                        'size' => $file->getSize(),
                        'sha256' => hash_file('sha256', $file->getRealPath()),
                    ]);
                }

                return $report;
            });
        } catch (Throwable $e) {
            Storage::disk('local')->delete($stored);
            throw $e;
        }

        return response()->json(['report' => $report->load('attachments')->toApi()], 201);
    }

    public function show(Request $request, int $report): JsonResponse
    {
        return response()->json(['report' => $this->visible($request, $report)->load('attachments')->toApi()]);
    }

    public function pdf(Request $request, int $report, ReportPdf $pdf): Response
    {
        $model = $this->visible($request, $report)->load('attachments', 'user');

        $body = $pdf->render($model);
        if ($request->user()->isAdmin()) {
            app(AdminActivityLog::class)->record($request->user(), 'report.pdf_downloaded', $model);
        }

        return response($body, 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="'.$model->reference.'.pdf"',
            'Cache-Control' => 'private, no-store',
        ]);
    }

    /** 404 (not 403) for someone else's report, so its existence is not revealed. */
    private function visible(Request $request, int $id): IncidentReport
    {
        $report = IncidentReport::find($id);
        abort_unless($report && Gate::forUser($request->user())->allows('view', $report), 404);

        return $report;
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\IncidentReport;
use App\Models\ReportAttachment;
use App\Services\AttachmentLinks;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AttachmentController extends Controller
{
    /** Hands the app a temporary link. Only the author and admins get one. */
    public function link(Request $request, int $report, int $attachment): JsonResponse
    {
        $model = IncidentReport::find($report);
        abort_unless($model && Gate::forUser($request->user())->allows('view', $model), 404);

        $file = $model->attachments()->whereKey($attachment)->firstOrFail();
        $ttl = config('riayati.reports.link_ttl_minutes');

        return response()->json([
            'url' => AttachmentLinks::for($file),
            'expires_at' => now()->addMinutes($ttl)->toIso8601String(),
        ]);
    }

    /** Reached only through a valid, unexpired signed link (the `signed` middleware checks it). */
    public function download(ReportAttachment $attachment): StreamedResponse
    {
        abort_unless(Storage::disk('local')->exists($attachment->path), 404);

        return Storage::disk('local')->response($attachment->path, null, [
            'Content-Type' => $attachment->mime,
            'Content-Disposition' => "inline; filename*=UTF-8''".rawurlencode($attachment->original_name),
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ]);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['incident_report_id', 'path', 'original_name', 'mime', 'kind', 'size', 'sha256'])]
class ReportAttachment extends Model
{
    public function report(): BelongsTo
    {
        return $this->belongsTo(IncidentReport::class, 'incident_report_id');
    }

    public static function kindFor(string $mime): string
    {
        return match (true) {
            str_starts_with($mime, 'image/') => 'image',
            str_starts_with($mime, 'video/') => 'video',
            default => 'file',
        };
    }

    /** The storage path is never exposed: files are only reachable through short-lived signed links. */
    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'kind' => $this->kind,
            'name' => $this->original_name,
            'mime' => $this->mime,
            'size' => $this->size,
            'sha256' => $this->sha256,
        ];
    }
}

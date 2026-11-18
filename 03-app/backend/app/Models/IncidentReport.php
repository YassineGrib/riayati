<?php

namespace App\Models;

use App\Enums\ReportStatus;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['reference', 'user_id', 'description', 'incident_at', 'status'])]
class IncidentReport extends Model
{
    protected function casts(): array
    {
        return [
            'incident_at' => 'datetime',
            'reviewed_at' => 'datetime',
            'status' => ReportStatus::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(ReportAttachment::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    /** RIA-2026-0142. Call inside the transaction that creates the report. */
    public static function nextReference(): string
    {
        $year = now()->year;
        $last = static::where('reference', 'like', "RIA-{$year}-%")->orderByDesc('reference')->value('reference');
        $next = $last ? ((int) substr($last, -4)) + 1 : 1;

        return sprintf('RIA-%d-%04d', $year, $next);
    }

    public function markReviewed(User $admin): void
    {
        $this->forceFill([
            'status' => ReportStatus::Reviewed,
            'reviewed_at' => now(),
            'reviewed_by' => $admin->id,
        ])->save();
    }

    public function toApi(bool $detail = true): array
    {
        $data = [
            'id' => $this->id,
            'reference' => $this->reference,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'incident_at' => $this->incident_at->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
            'attachments_count' => $this->attachments->count(),
        ];

        if ($detail) {
            $data['description'] = $this->description;
            $data['attachments'] = $this->attachments->map->toApi()->all();
        } else {
            $data['excerpt'] = mb_strimwidth($this->description, 0, 140, '…');
        }

        return $data;
    }
}

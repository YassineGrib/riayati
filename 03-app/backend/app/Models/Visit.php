<?php

namespace App\Models;

use App\Enums\VisitStatus;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['family_id', 'proposed_by', 'starts_at', 'ends_at', 'note', 'status'])]
class Visit extends Model
{
    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'responded_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'status' => VisitStatus::class,
        ];
    }

    public function family(): BelongsTo
    {
        return $this->belongsTo(Family::class);
    }

    public function proposer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'proposed_by');
    }

    /** True when a visit in the same family already occupies part of this time range. */
    public static function overlaps(int $familyId, \DateTimeInterface $start, \DateTimeInterface $end): bool
    {
        return static::where('family_id', $familyId)
            ->whereIn('status', VisitStatus::active())
            ->where('starts_at', '<', $end)
            ->where('ends_at', '>', $start)
            ->exists();
    }

    /**
     * What the app needs, from the viewer's side. It never contains the other parent's name or email:
     * the calendar is the only thing the two parents share.
     */
    public function toApi(User $viewer): array
    {
        $mine = $this->proposed_by === $viewer->id;

        return [
            'id' => $this->id,
            'date' => $this->starts_at->format('Y-m-d'),
            'from' => $this->starts_at->format('H:i'),
            'to' => $this->ends_at->format('H:i'),
            'starts_at' => $this->starts_at->toIso8601String(),
            'ends_at' => $this->ends_at->toIso8601String(),
            'note' => $this->note,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'proposed_by_me' => $mine,
            'needs_my_response' => $this->status === VisitStatus::Proposed && ! $mine,
            'can_confirm' => $this->status === VisitStatus::Accepted && $mine,
            'timeline' => array_values(array_filter([
                ['step' => 'proposed', 'at' => $this->created_at->toIso8601String()],
                $this->responded_at ? ['step' => $this->status === VisitStatus::Declined ? 'declined' : 'accepted', 'at' => $this->responded_at->toIso8601String()] : null,
                $this->confirmed_at ? ['step' => 'confirmed', 'at' => $this->confirmed_at->toIso8601String()] : null,
            ])),
        ];
    }
}

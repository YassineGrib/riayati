<?php

namespace App\Http\Controllers\Api;

use App\Enums\VisitStatus;
use App\Http\Controllers\Controller;
use App\Models\Visit;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class VisitController extends Controller
{
    /** Visits of one month (default: the current month), for the calendar grid. */
    public function index(Request $request): JsonResponse
    {
        $user = $this->linked($request);
        $data = $request->validate(['month' => ['nullable', 'date_format:Y-m']]);

        $start = Carbon::createFromFormat('Y-m-d', ($data['month'] ?? now()->format('Y-m')).'-01')->startOfMonth();

        $visits = Visit::where('family_id', $user->family_id)
            ->whereBetween('starts_at', [$start, $start->copy()->endOfMonth()])
            ->orderBy('starts_at')->get();

        return response()->json(['month' => $start->format('Y-m'), 'visits' => $visits->map->toApi($user)]);
    }

    /** What is next: open and agreed visits that have not ended yet. */
    public function upcoming(Request $request): JsonResponse
    {
        $user = $this->linked($request);

        $visits = Visit::where('family_id', $user->family_id)
            ->whereIn('status', VisitStatus::active())
            ->where('ends_at', '>', now())
            ->orderBy('starts_at')->limit(10)->get();

        return response()->json(['visits' => $visits->map->toApi($user)]);
    }

    public function show(Request $request, int $visit): JsonResponse
    {
        $user = $this->linked($request);

        return response()->json(['visit' => $this->own($user->family_id, $visit)->toApi($user)]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $this->linked($request);
        $data = $request->validate([
            'date' => ['required', 'date_format:Y-m-d'],
            'from' => ['required', 'date_format:H:i'],
            'to' => ['required', 'date_format:H:i'],
            'note' => ['nullable', 'string', 'max:300'],
        ]);

        $start = Carbon::createFromFormat('Y-m-d H:i', "{$data['date']} {$data['from']}");
        $end = Carbon::createFromFormat('Y-m-d H:i', "{$data['date']} {$data['to']}");

        if ($end->lessThanOrEqualTo($start)) {
            throw ValidationException::withMessages(['to' => ['يجب أن يكون وقت الانتهاء بعد وقت البدء.']]);
        }
        if ($start->lessThanOrEqualTo(now())) {
            throw ValidationException::withMessages(['date' => ['اختر موعدًا في المستقبل.']]);
        }

        return DB::transaction(function () use ($user, $start, $end, $data) {
            if (Visit::overlaps($user->family_id, $start, $end)) {
                throw ValidationException::withMessages(['from' => ['يتعارض هذا الوقت مع زيارة أخرى في التقويم.']]);
            }

            $visit = Visit::create([
                'family_id' => $user->family_id,
                'proposed_by' => $user->id,
                'starts_at' => $start,
                'ends_at' => $end,
                'note' => isset($data['note']) ? trim($data['note']) ?: null : null,
                'status' => VisitStatus::Proposed,
            ]);

            return response()->json(['visit' => $visit->toApi($user)], 201);
        });
    }

    /** The other parent accepts a proposal. */
    public function accept(Request $request, int $visit): JsonResponse
    {
        return $this->respond($request, $visit, VisitStatus::Accepted);
    }

    /** The other parent declines a proposal. A declined visit is final and frees the slot. */
    public function decline(Request $request, int $visit): JsonResponse
    {
        return $this->respond($request, $visit, VisitStatus::Declined);
    }

    /** The parent who proposed confirms once the other has accepted. */
    public function confirm(Request $request, int $visit): JsonResponse
    {
        $user = $this->linked($request);

        return DB::transaction(function () use ($user, $visit) {
            $model = $this->own($user->family_id, $visit, lock: true);

            if ($model->proposed_by !== $user->id) {
                return response()->json(['message' => 'يؤكّد الزيارة من اقترحها.'], 403);
            }
            if ($model->status !== VisitStatus::Accepted) {
                return response()->json(['message' => 'لا يمكن التأكيد قبل قبول الطرف الآخر.'], 409);
            }
            $this->ensureNotStarted($model);

            $model->forceFill(['status' => VisitStatus::Confirmed, 'confirmed_at' => now()])->save();

            return response()->json(['visit' => $model->toApi($user)]);
        });
    }

    private function respond(Request $request, int $visit, VisitStatus $decision): JsonResponse
    {
        $user = $this->linked($request);

        return DB::transaction(function () use ($user, $visit, $decision) {
            $model = $this->own($user->family_id, $visit, lock: true);

            if ($model->proposed_by === $user->id) {
                return response()->json(['message' => 'يرد الطرف الآخر على اقتراحك.'], 403);
            }
            if ($model->status !== VisitStatus::Proposed) {
                return response()->json(['message' => 'تم الرد على هذا الاقتراح من قبل.'], 409);
            }
            if ($decision === VisitStatus::Accepted) {
                $this->ensureNotStarted($model);
            }

            $model->forceFill(['status' => $decision, 'responded_by' => $user->id, 'responded_at' => now()])->save();

            return response()->json(['visit' => $model->toApi($user)]);
        });
    }

    private function ensureNotStarted(Visit $visit): void
    {
        if ($visit->starts_at->lessThanOrEqualTo(now())) {
            throw ValidationException::withMessages(['visit' => ['انتهى موعد هذا الاقتراح.']]);
        }
    }

    /** Only the two linked parents use the calendar. An unlinked parent is told to link first. */
    private function linked(Request $request)
    {
        $user = $request->user();
        abort_unless($user->role->isParent(), 403);
        abort_unless($user->isLinked(), response()->json([
            'message' => 'اربط حسابك بحساب الطرف الآخر لاستخدام التقويم المشترك.',
            'code' => 'not_linked',
        ], 403));

        return $user;
    }

    /** A visit of the viewer's own family, or 404 (never reveals other families' visits). */
    private function own(int $familyId, int $id, bool $lock = false): Visit
    {
        $query = Visit::where('family_id', $familyId)->whereKey($id);

        return ($lock ? $query->lockForUpdate() : $query)->firstOrFail();
    }
}

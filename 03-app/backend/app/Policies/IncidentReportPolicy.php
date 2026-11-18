<?php

namespace App\Policies;

use App\Models\IncidentReport;
use App\Models\User;

/**
 * A report is visible to its author and to admins, nobody else. In particular not to the other parent.
 * There is deliberately no update or delete ability: a submitted report is evidence.
 */
class IncidentReportPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    public function view(User $user, IncidentReport $report): bool
    {
        return $user->id === $report->user_id || $user->isAdmin();
    }
}

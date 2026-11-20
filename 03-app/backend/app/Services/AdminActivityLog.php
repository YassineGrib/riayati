<?php

namespace App\Services;

use App\Models\AdminActivity;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class AdminActivityLog
{
    public function record(User $admin, string $action, Model $subject, array $meta = []): void
    {
        AdminActivity::create(['admin_id' => $admin->id, 'action' => $action, 'subject_type' => $subject->getMorphClass(), 'subject_id' => $subject->getKey(), 'meta' => $meta, 'ip' => app()->bound('request') ? request()->ip() : null]);
    }
}

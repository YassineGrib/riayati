<?php

namespace App\Observers;

use App\Models\Content;
use App\Models\User;
use App\Services\AdminActivityLog;
use Illuminate\Database\Eloquent\Model;

class AdminContentObserver
{
    public function __construct(private AdminActivityLog $log) {}

    public function created(Model $model): void
    {
        $this->record($model, 'created');
    }

    public function updated(Model $model): void
    {
        $this->record($model, 'updated');
    }

    public function deleted(Model $model): void
    {
        $this->record($model, 'deleted');
    }

    private function record(Model $model, string $action): void
    {
        $admin = auth()->user();
        if ($admin instanceof User && $admin->isAdmin()) {
            $this->log->record($admin, ($model instanceof Content ? 'content.' : 'center.').$action, $model);
        }
    }
}

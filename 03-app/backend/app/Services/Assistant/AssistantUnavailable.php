<?php

namespace App\Services\Assistant;

use Illuminate\Contracts\Debug\ShouldntReport;
use RuntimeException;

class AssistantUnavailable extends RuntimeException implements ShouldntReport {}

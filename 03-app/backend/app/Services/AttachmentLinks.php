<?php

namespace App\Services;

use App\Models\ReportAttachment;
use Illuminate\Support\Facades\URL;

class AttachmentLinks
{
    public static function for(ReportAttachment $attachment): string
    {
        return URL::temporarySignedRoute(
            'attachments.download',
            now()->addMinutes(config('riayati.reports.link_ttl_minutes')),
            ['attachment' => $attachment->id],
        );
    }
}

<?php

return [
    'reports' => [
        // Limits promised in the app (UI copy: "up to 5 files, 30 MB each").
        'max_files' => 5,
        'max_file_kb' => 30 * 1024,
        // Checked against the file's real content type, not its extension.
        'allowed_mimes' => [
            'image/jpeg', 'image/png', 'image/webp',
            'video/mp4', 'video/quicktime',
            'application/pdf',
        ],
        // Attachment links stay valid for a few minutes only.
        'link_ttl_minutes' => 5,
    ],
];

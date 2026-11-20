<?php

return [
    'assistant' => [
        'key' => env('GEMINI_API_KEY'),
        'embedding_model' => env('GEMINI_EMBEDDING_MODEL', 'gemini-embedding-001'),
        'answer_model' => env('GEMINI_ANSWER_MODEL', 'gemini-flash-latest'),
        'dimensions' => 768,
        'top_k' => 4,
        'min_score' => 0.55,
        'max_question_chars' => 500,
        'chunk_chars' => 900,
        'chunk_overlap' => 150,
        'timeout' => 20,
        'retries' => 1,
    ],
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

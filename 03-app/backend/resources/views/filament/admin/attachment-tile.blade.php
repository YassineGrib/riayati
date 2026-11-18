@php
    $attachment = $getRecord();
    $url = \App\Services\AttachmentLinks::for($attachment);
@endphp

<div class="attachment-tile">
    <a href="{{ $url }}" target="_blank" rel="noopener" class="attachment-tile-link">
        <div class="attachment-tile-preview">
            @if ($attachment->kind === 'image')
                <img src="{{ $url }}" alt="{{ $attachment->original_name }}" loading="lazy" />
            @else
                <x-filament::icon
                    :icon="$attachment->kind === 'video' ? 'heroicon-o-video-camera' : 'heroicon-o-document-text'"
                    class="fi-icon fi-size-lg"
                />
            @endif
        </div>
        <div class="attachment-tile-info">
            <span class="attachment-tile-name">{{ $attachment->original_name }}</span>
            <span class="attachment-tile-size" dir="ltr">{{ \Illuminate\Support\Number::fileSize($attachment->size) }}</span>
        </div>
    </a>
    <div class="attachment-tile-fingerprint" x-data="{ copied: false }">
        <span dir="ltr">SHA-256: {{ substr($attachment->sha256, 0, 12) }}…</span>
        <x-filament::button
            type="button" color="gray" size="xs" icon="heroicon-o-clipboard-document"
            aria-label="نسخ SHA-256"
            data-fingerprint="{{ $attachment->sha256 }}"
            x-on:click="window.navigator.clipboard.writeText($el.dataset.fingerprint).then(() => { copied = true; setTimeout(() => copied = false, 2000) })"
        >
            <span x-show="!copied">نسخ</span>
            <span x-show="copied" x-cloak>تم النسخ</span>
        </x-filament::button>
    </div>
</div>

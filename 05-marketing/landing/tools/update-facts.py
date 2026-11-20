#!/usr/bin/env python3
"""Update the inline release facts: python tools/update-facts.py path/to/riayati.apk."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path, help='Path to the actual signed release APK')
    parser.add_argument('--page', type=Path, default=Path(__file__).resolve().parents[1] / 'index.html')
    args = parser.parse_args()
    if not args.apk.is_file() or args.apk.stat().st_size == 0:
        parser.error('APK must be an existing, non-empty file')
    if args.apk.suffix.lower() != '.apk':
        parser.error('Expected a .apk file')
    digest = hashlib.sha256()
    byte_count = 0
    with args.apk.open('rb') as apk:
        for chunk in iter(lambda: apk.read(1024 * 1024), b''):
            digest.update(chunk)
            byte_count += len(chunk)
    size_mb = round(byte_count / 1_000_000, 2)
    text = args.page.read_text(encoding='utf-8')
    block_pattern = r'(// === RELEASE CONFIG:.*?// === END RELEASE CONFIG ===)'
    block = re.search(block_pattern, text, re.S)
    if not block:
        parser.error('Release configuration block was not found')
    updated = block.group(1)
    for key, value in [('sizeMB', size_mb), ('sha256', digest.hexdigest())]:
        updated, count = re.subn(r'(^\s*' + key + r':\s*)[^,\n]+',
                                 lambda match: match.group(1) + json.dumps(value),
                                 updated, flags=re.M)
        if count != 1:
            parser.error('Expected exactly one config field: ' + key)
    text = text[:block.start()] + updated + text[block.end():]
    temporary = args.page.with_suffix('.html.tmp')
    temporary.write_text(text, encoding='utf-8', newline='\n')
    temporary.replace(args.page)
    print(f'Updated {args.page.name}: {byte_count:,} bytes ({size_mb:.2f} MB)')
    print(f'SHA-256: {digest.hexdigest()}')
    print('Version and platform are unchanged. Signature and architecture must be checked separately.')


if __name__ == '__main__':
    main()

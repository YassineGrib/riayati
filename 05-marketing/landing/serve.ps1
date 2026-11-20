param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$marketingRoot = Split-Path -Parent $PSScriptRoot
Write-Host "Open http://127.0.0.1:$Port/landing/index.html (Ctrl+C to stop)"
python -m http.server $Port --bind 127.0.0.1 --directory $marketingRoot

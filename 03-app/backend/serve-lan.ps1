# Dev server reachable from a phone on the same Wi-Fi, with upload limits that
# match production (public/.user.ini is ignored by PHP's built-in server).
# Usage:  powershell -File serve-lan.ps1 [-Port 8765]
param([int]$Port = 8765)

$backend = $PSScriptRoot
$router = Join-Path $backend 'vendor\laravel\framework\src\Illuminate\Foundation\resources\server.php'
$tmp = [IO.Path]::GetTempPath().TrimEnd('\')

Set-Location (Join-Path $backend 'public')
php -d upload_max_filesize=32M -d post_max_size=170M -d max_file_uploads=10 `
    -d display_errors=0 -d "upload_tmp_dir=$tmp" -S "0.0.0.0:$Port" $router

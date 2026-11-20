# Updates the Riayati backend on Hostinger (riayati.site). Run from the repo root:
#   powershell -File tools\deploy-hostinger.ps1
# Needs the SSH key C:\Users\<you>\.ssh\riayati_deploy (public part added in hPanel > SSH Access).
# Never overwrites .env, the SQLite database or uploaded evidence on the server.
$ErrorActionPreference = 'Stop'
$hostIp = '191.96.63.216'; $port = 65002; $user = 'u514106451'
$key = "$env:USERPROFILE\.ssh\riayati_deploy"
$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root '03-app\backend'
$tmp = Join-Path $env:TEMP 'riayati-deploy'; New-Item -ItemType Directory -Force $tmp | Out-Null

# Pin the server host key (ED25519 SHA256:3jNxRhjTJ9N71Nf9y57h/YxFoVPjHdpHy1QW+8jToJU).
$known = Join-Path $tmp 'known_hosts'
ssh-keyscan -p $port -t ed25519 $hostIp 2>$null | Out-File $known -Encoding ascii
$fp = ssh-keygen -lf $known
if ($fp -notmatch '3jNxRhjTJ9N71Nf9y57h/YxFoVPjHdpHy1QW\+8jToJU') { throw "Host key changed: $fp" }
$opt = @('-i', $key, '-o', 'BatchMode=yes', '-o', 'IdentitiesOnly=yes', '-o', 'StrictHostKeyChecking=yes', '-o', "UserKnownHostsFile=$known")

$tgz = Join-Path $tmp 'backend.tgz'
Remove-Item $tgz -ErrorAction SilentlyContinue
tar -czf $tgz --exclude=./vendor --exclude=./node_modules --exclude=./.env --exclude=./.git `
  --exclude=./storage/logs --exclude=./storage/framework --exclude=./storage/app `
  --exclude='./database/*.sqlite' --exclude=./public/hot --exclude=./public/storage `
  --exclude=./public/css/filament --exclude=./public/js/filament --exclude=./public/fonts/filament `
  --exclude=./tests --exclude=./bootstrap/cache -C $backend .
scp -P $port @opt $tgz "${user}@${hostIp}:riayati-backend.tgz"

$remote = @'
set -e
cd riayati-app
tar -xzf ../riayati-backend.tgz
mkdir -p storage/app/private storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
PHP=/opt/alt/php83/usr/bin/php
COMPOSER_MEMORY_LIMIT=-1 $PHP /usr/local/bin/composer install --no-dev --optimize-autoloader --no-interaction 2>&1 | tail -3
$PHP artisan migrate --force --no-interaction 2>&1 | tail -5
$PHP artisan config:cache | tail -1
$PHP artisan route:cache | tail -1
$PHP artisan view:cache | tail -1
rm -f ../riayati-backend.tgz
echo deployed
'@
$remote = $remote -replace "`r", ''
ssh -p $port @opt "${user}@${hostIp}" $remote

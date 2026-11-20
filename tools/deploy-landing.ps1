# Publishes the landing + download page (and optionally the signed APK) to riayati.site.
#   powershell -File tools\deploy-landing.ps1 [-Apk C:\path\riayati.apk]
# Needs ~\.ssh\riayati_deploy. The backend (route "/") is updated by tools\deploy-hostinger.ps1.
param([string]$Apk = '')
$ErrorActionPreference = 'Continue'   # native stderr is noise; real failures are checked with $LASTEXITCODE
$hostIp = '191.96.63.216'; $port = 65002; $user = 'u514106451'
$key = "$env:USERPROFILE\.ssh\riayati_deploy"
$root = Split-Path -Parent $PSScriptRoot
$landing = Join-Path $root '05-marketing\landing'
$tmp = Join-Path $env:TEMP 'riayati-landing'; New-Item -ItemType Directory -Force $tmp | Out-Null

$known = Join-Path $tmp 'known_hosts'
ssh-keyscan -p $port -t ed25519 $hostIp 2>$null | Out-File $known -Encoding ascii
if ((ssh-keygen -lf $known) -notmatch '3jNxRhjTJ9N71Nf9y57h/YxFoVPjHdpHy1QW\+8jToJU') { throw 'Host key changed' }
$opt = @('-i', $key, '-o', 'BatchMode=yes', '-o', 'IdentitiesOnly=yes', '-o', 'StrictHostKeyChecking=yes', '-o', "UserKnownHostsFile=$known")

# Production files only (no tools, no local server script, no guide).
$tgz = Join-Path $tmp 'landing.tgz'; Remove-Item $tgz -ErrorAction SilentlyContinue
tar -czf $tgz --exclude=./tools --exclude=./serve.ps1 --exclude=./DEPLOY.md -C $landing .
scp -P $port @opt $tgz "${user}@${hostIp}:landing.tgz"
if ($LASTEXITCODE -ne 0) { throw 'scp failed' }
$remote = @'
set -e
cd riayati-app/public
mkdir -p landing downloads
tar -xzf ~/landing.tgz -C landing
cp landing/.htaccess downloads/.htaccess
rm -f ~/landing.tgz
ls landing | head -20
'@ -replace "`r", ''
ssh -p $port @opt "${user}@${hostIp}" $remote

if ($Apk) {
  $local = (Get-FileHash $Apk -Algorithm SHA256).Hash.ToLower()
  scp -P $port @opt $Apk "${user}@${hostIp}:riayati-app/public/downloads/riayati.apk"
  $remoteHash = (ssh -p $port @opt "${user}@${hostIp}" 'sha256sum riayati-app/public/downloads/riayati.apk').Split(' ')[0]
  if ($remoteHash -ne $local) { throw "APK hash mismatch: local $local, server $remoteHash" }
  "APK uploaded, SHA-256 matches: $local"
}

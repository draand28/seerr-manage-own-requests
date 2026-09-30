# Install the "Manage Own Requests" patch into a Seerr source checkout.
#
#   .\install.ps1 [-SeerrDir seerr]
#
# The directory defaults to .\seerr and is cloned if missing. Override the
# pinned upstream commit with $env:SEERR_REF if you are rebasing onto newer Seerr.
[CmdletBinding()]
param(
  [string]$SeerrDir = "seerr"
)

$ErrorActionPreference = "Stop"

$SeerrRepo = if ($env:SEERR_REPO) { $env:SEERR_REPO } else { "https://github.com/seerr-team/seerr.git" }
$SeerrRef = if ($env:SEERR_REF) { $env:SEERR_REF } else { "e9590629b8215676a352ec2413d7c8ee7e6974df" }
$PatchDir = Join-Path $PSScriptRoot "patches"

if (-not (Test-Path (Join-Path $SeerrDir ".git"))) {
  Write-Host "==> Initializing Seerr checkout in $SeerrDir"
  git init -q $SeerrDir
  git -C $SeerrDir remote add origin $SeerrRepo
}

Write-Host "==> Checking out $SeerrRef"
git -C $SeerrDir fetch --depth 1 origin $SeerrRef
git -C $SeerrDir checkout --detach -f FETCH_HEAD

Get-ChildItem -Path $PatchDir -Filter *.patch | ForEach-Object {
  Write-Host "==> Applying $($_.Name)"
  git -C $SeerrDir apply $_.FullName
}

if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  corepack enable
}

Write-Host "==> Installing dependencies and building"
Push-Location $SeerrDir
try {
  pnpm install --frozen-lockfile
  pnpm build
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "Done. Start Seerr with:  cd $SeerrDir; pnpm start"
Write-Host "Then grant `"Manage Own Requests`" under Settings > Users > Permissions."

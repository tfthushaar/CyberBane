<#
.SYNOPSIS
  Builds Cyberbane release archives (spec §22.2).

.DESCRIPTION
  - Writes the version into src/r6/scripts/Cyberbane/Core/Version.reds.
  - Fails the build if any .reds file still contains the marker TODO-RELEASE.
  - Produces dist/Cyberbane-<Version>.zip with the game-root layout so it installs
    with a mod manager or by hand.
  - Produces dist/CyberbaneDebug-<Version>.zip when the optional debug add-on exists.

.PARAMETER Version
  Semantic version, e.g. 1.0.0.

.EXAMPLE
  ./tools/build.ps1 -Version 1.0.0
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Version
)

$ErrorActionPreference = 'Stop'

$root     = Split-Path -Parent $PSScriptRoot
$srcDir   = Join-Path $root 'src'
$distDir  = Join-Path $root 'dist'
$optDir   = Join-Path $root 'optional'
$verFile  = Join-Path $srcDir 'r6/scripts/Cyberbane/Core/Version.reds'

# --- version code: major*10000 + minor*100 + patch -------------------------
$parts = $Version.Split('.')
$code  = [int]$parts[0] * 10000 + [int]$parts[1] * 100 + [int]$parts[2]

# --- release-blocker check -------------------------------------------------
Write-Host "Checking for TODO-RELEASE markers..."
$offenders = Get-ChildItem -Path $srcDir -Recurse -Filter *.reds |
  Select-String -Pattern 'TODO-RELEASE' -List
if ($offenders) {
  $offenders | ForEach-Object { Write-Host "  $($_.Path)" }
  throw "Build aborted: TODO-RELEASE marker(s) present."
}

# --- stamp the version -----------------------------------------------------
Write-Host "Stamping version $Version (code $code) into Version.reds..."
$verText = Get-Content -Raw -Path $verFile
$verText = [regex]::Replace($verText, 'CyberbaneVersion\(\) -> String = "[^"]*"', "CyberbaneVersion() -> String = `"$Version`"")
$verText = [regex]::Replace($verText, 'CyberbaneVersionCode\(\) -> Int32 = \d+', "CyberbaneVersionCode() -> Int32 = $code")
Set-Content -Path $verFile -Value $verText -Encoding UTF8 -NoNewline

# --- package ---------------------------------------------------------------
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }

$mainZip = Join-Path $distDir "Cyberbane-$Version.zip"
if (Test-Path $mainZip) { Remove-Item $mainZip -Force }
Write-Host "Packaging $mainZip..."
Compress-Archive -Path (Join-Path $srcDir '*') -DestinationPath $mainZip

if (Test-Path $optDir) {
  $dbgZip = Join-Path $distDir "CyberbaneDebug-$Version.zip"
  if (Test-Path $dbgZip) { Remove-Item $dbgZip -Force }
  Write-Host "Packaging $dbgZip..."
  Compress-Archive -Path (Join-Path $optDir 'CyberbaneDebug/*') -DestinationPath $dbgZip
}

Write-Host "Done. Output in $distDir"

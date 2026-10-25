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
# Read/write as UTF-8 without BOM via .NET so the file's encoding is preserved
# (Windows PowerShell 5.1's Get-Content/Set-Content would corrupt non-ASCII and
# add a BOM, which the redscript compiler should not have to tolerate).
Write-Host "Stamping version $Version (code $code) into Version.reds..."
$verText = [System.IO.File]::ReadAllText($verFile)
$verText = [regex]::Replace($verText, 'CyberbaneVersion\(\) -> String = "[^"]*"', "CyberbaneVersion() -> String = `"$Version`"")
$verText = [regex]::Replace($verText, 'CyberbaneVersionCode\(\) -> Int32 = \d+', "CyberbaneVersionCode() -> Int32 = $code")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($verFile, $verText, $utf8NoBom)

# --- package ---------------------------------------------------------------
# Zip with forward-slash entry paths so mod managers (Vortex) and all extractors
# read the game-root layout correctly. Windows PowerShell 5.1's Compress-Archive
# writes backslash separators, which some extractors flatten into one folder, so we
# build the archive explicitly with System.IO.Compression instead.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-ModZip {
  param([string]$SourceDir, [string]$ZipPath)
  if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
  $base = (Resolve-Path $SourceDir).Path.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    Get-ChildItem -Path $SourceDir -Recurse -File | ForEach-Object {
      $rel = $_.FullName.Substring($base.Length) -replace '\\', '/'
      [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, $_.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
  } finally {
    $zip.Dispose()
  }
}

if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }

$mainZip = Join-Path $distDir "Cyberbane-$Version.zip"
Write-Host "Packaging $mainZip..."
New-ModZip -SourceDir $srcDir -ZipPath $mainZip

if (Test-Path $optDir) {
  $dbgZip = Join-Path $distDir "CyberbaneDebug-$Version.zip"
  Write-Host "Packaging $dbgZip..."
  New-ModZip -SourceDir (Join-Path $optDir 'CyberbaneDebug') -ZipPath $dbgZip
}

Write-Host "Done. Output in $distDir"

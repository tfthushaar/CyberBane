<#
.SYNOPSIS
  Fails if any script the mod has ever shipped is missing from src.

.DESCRIPTION
  Installing a new version over an old one doesn't remove files, so a deleted script stays on every install
  that updated by extracting the zip and still gets compiled. Once anything it calls is gone it fails to
  compile, and that stops every script mod the player has.

  So no .reds file is ever deleted: a file the mod no longer needs is replaced by a stub at the same path,
  and installing over the top overwrites the old copy.

  Run by tools/build.ps1 and tools/validate.ps1. Paths come from the whole history of every branch,
  with renames counted as a removal of the old path.
#>
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

$ever = & git -C $root log --all --no-renames --format= --name-only -- src
if ($LASTEXITCODE -ne 0) {
  throw "Could not read the git history, so removed scripts cannot be checked."
}

$paths = @($ever | Where-Object { $_ -like '*.reds' } | Sort-Object -Unique)
if ($paths.Count -eq 0) {
  throw "The git history lists no scripts at all, so this check would prove nothing."
}

$missing = @($paths | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Host "  $_" }
  throw ("A script from an earlier version is missing from src. Do not delete scripts: old " +
         "installs keep them and they will stop compiling. Restore the path as a stub.")
}

Write-Host "Every script ever shipped is still in src ($($paths.Count) checked)."

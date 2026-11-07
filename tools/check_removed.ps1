<#
.SYNOPSIS
  Fails if any script the mod has ever shipped is missing from src.

.DESCRIPTION
  Installing a new version over an old one does not remove files. A script deleted from the mod
  stays in r6\scripts\Cyberbane on every install that updated by extracting the zip, and redscript
  compiles it with everything else. So the moment anything it calls is removed, that file fails to
  compile, and a failed compile stops every script mod the player has. That is how 1.7.0 broke:
  Spawn/VanillaChase.reds was deleted in 1.5.0, and CBChaseVehicle, which it called, was removed in
  1.7.0.

  The rule this enforces: no .reds file is ever deleted. A file the mod no longer needs is replaced
  by a stub at the same path, so that installing over the top overwrites the old copy. An install
  then always ends up with exactly the files in the zip, whichever version it started from.

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

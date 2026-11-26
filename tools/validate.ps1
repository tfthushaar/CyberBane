<#
.SYNOPSIS
  Compile-validates the Cyberbane redscript against an installed Cyberpunk 2077.

.DESCRIPTION
  Builds an isolated sandbox containing the mod plus its redscript dependencies
  (Codeware and Mod Settings, read from the game's RED4ext plugins) and compiles
  it with the game's own scc.exe against a private copy of the vanilla script
  cache. Nothing in the game folder is modified. Prints any compile errors.

.PARAMETER GameDir
  Path to the Cyberpunk 2077 install (the folder containing bin, r6, engine).

.EXAMPLE
  ./tools/validate.ps1 -GameDir "D:\SteamLibrary\steamapps\common\Cyberpunk 2077"
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$GameDir
)

$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot
$src    = Join-Path $root 'src/r6/scripts/Cyberbane'
$scc    = Join-Path $GameDir 'engine/tools/scc.exe'
$vanilla = Join-Path $GameDir 'r6/cache/final.redscripts'
$cwScripts = Join-Path $GameDir 'red4ext/plugins/Codeware/Scripts'
$msDir  = Join-Path $GameDir 'red4ext/plugins/mod_settings'

foreach ($p in @($scc, $vanilla, $cwScripts, $msDir)) {
  if (-not (Test-Path $p)) { throw "Required path not found: $p" }
}

& (Join-Path $PSScriptRoot 'check_removed.ps1')
& (Join-Path $PSScriptRoot 'check_abilities.ps1')
# Every key the code asks for is in the English, with as many slots as it passes (see check_loc.ps1).
& (Join-Path $PSScriptRoot 'check_loc.ps1')
# No two street-talk lines share an action id (see check_talk_ids.ps1).
& (Join-Path $PSScriptRoot 'check_talk_ids.ps1')
# Wrapped game events call wrappedMethod as a statement (see check_wraps.ps1).
& (Join-Path $PSScriptRoot 'check_wraps.ps1')
# No class a save already holds has its saved fields changed (see check_saved_fields.ps1).
& (Join-Path $PSScriptRoot 'check_saved_fields.ps1')
# No function is declared twice (see check_duplicates.ps1).
& (Join-Path $PSScriptRoot 'check_duplicates.ps1')

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("cyberbane-validate-" + [Guid]::NewGuid().ToString('N'))
$scripts = Join-Path $sandbox 'scripts'
try {
  New-Item -ItemType Directory -Path $scripts -Force | Out-Null
  Copy-Item $cwScripts (Join-Path $scripts 'Codeware') -Recurse
  New-Item -ItemType Directory -Path (Join-Path $scripts 'mod_settings') -Force | Out-Null
  Copy-Item (Join-Path $msDir '*.reds') (Join-Path $scripts 'mod_settings')
  Copy-Item $src (Join-Path $scripts 'Cyberbane') -Recurse
  $base = Join-Path $sandbox 'base.redscripts'
  Copy-Item $vanilla $base
  $out = Join-Path $sandbox 'out.redscripts'

  Write-Host "Compiling against $vanilla ..."
  & $scc -compile $scripts -outputCacheFile $out $base
  if (Test-Path $out) {
    Write-Host "`nOK: Cyberbane compiles cleanly against this game version." -ForegroundColor Green
  } else {
    throw "Compilation failed (no output produced). See the errors above."
  }
}
finally {
  if (Test-Path $sandbox) { Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
}

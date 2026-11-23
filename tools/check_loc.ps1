<#
.SYNOPSIS
  Fails if Cyberbane's localization keys do not line up (2.7.1).

.DESCRIPTION
  Every line Cyberbane shows the player is a key, with its English in
  src/r6/scripts/Cyberbane/Localization/en-us/English.reds. A key the code asks for that the English does not define shows
  on screen as the key itself, and a slot count that does not match the English leaves {0} in the line or drops a value.
  This runs tools/check_loc.py, which checks both, plus doubled keys and Define methods nobody calls.

  Run by tools/build.ps1 and tools/validate.ps1. Needs Python on the PATH.
#>
$ErrorActionPreference = 'Stop'
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
  throw "check_loc: Python is not on the PATH, so the localization keys cannot be checked."
}
& $py.Source -I (Join-Path $PSScriptRoot 'check_loc.py')
if ($LASTEXITCODE -ne 0) {
  throw "check_loc: localization faults (see above)."
}

<#
.SYNOPSIS
  Fails if a wrapped game event uses what wrappedMethod returns.

.DESCRIPTION
  Some redscript builds, and mods that replace a game event, type the event as Void. A wrapped event (cb func) that
  stores or returns wrappedMethod(...) then fails to compile, and a failed compile stops every script mod the player
  has. Every wrapped event calls wrappedMethod as a statement and returns true or false itself.

  Run by tools/build.ps1 and tools/validate.ps1.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'src/r6/scripts/Cyberbane'
$bad = @()
$count = 0
foreach ($file in Get-ChildItem -Path $src -Recurse -Filter *.reds) {
  $text = [System.IO.File]::ReadAllText($file.FullName)
  $wraps = [regex]::Matches($text, '@wrapMethod\([^)]*\)\s*\r?\n[^\r\n]*\bcb\s+func\b[^\r\n{]*\{')
  foreach ($m in $wraps) {
    $count++
    # The event's body: from its opening brace to the matching close.
    $i = $m.Index + $m.Length
    $depth = 1
    while ($i -lt $text.Length -and $depth -gt 0) {
      if ($text[$i] -eq '{') { $depth++ } elseif ($text[$i] -eq '}') { $depth-- }
      $i++
    }
    $body = $text.Substring($m.Index + $m.Length, $i - ($m.Index + $m.Length))
    foreach ($line in ($body -split "`n")) {
      $code = ($line -split '//')[0]
      if ($code -match '(return|=)\s*wrappedMethod\(') {
        $lineNo = ($text.Substring(0, $m.Index) -split "`n").Count
        $bad += "$($file.FullName.Substring($src.Length + 1)) (event at line $lineNo): $($code.Trim())"
      }
    }
  }
}
if ($bad.Count -gt 0) {
  Write-Host "A wrapped game event uses what wrappedMethod returns; call it as a statement instead:" -ForegroundColor Red
  $bad | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  throw "check_wraps failed"
}
Write-Host "Wrapped events: $count, each calling wrappedMethod as a statement."

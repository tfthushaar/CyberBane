<#
.SYNOPSIS
  Fails if a function is declared twice: two members of the same name in one class, or two global functions of the
  same name anywhere in the mod.

.DESCRIPTION
  redscript compiles a second declaration of the same name without a word, and every caller then reads whichever one
  it settles on. CBConfig once declared CorpContractPay twice (30000 and 2500), and both corporate jobs paid the same.

  Counted: methods and statics inside a class, methods added with @addMethod(Class), and global functions, each by
  its name and the types it takes, so an overload (CBRoleName for an Int32 and for an ECBApexRole) is its own. Two
  under opposite @if conditions are two as well. Not counted: @wrapMethod and @replaceMethod, which stack on a game
  function by design.

  Run by tools/build.ps1 and tools/validate.ps1.
#>
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'src/r6/scripts/Cyberbane'

$classRx = '^(?:public\s+|private\s+)?(?:abstract\s+|final\s+|native\s+)*(?:class|struct)\s+(\w+)'
$funcRx = '^\s*(?:(?:public|private|protected|static|final|native|cb|exec|callback|const|quest)\s+)*func\s+(\w+)\s*\('
$annoRx = '^@(wrapMethod|replaceMethod|addMethod|wrapGlobal|replaceGlobal)\s*\(\s*(\w*)'

$seen = @{}   # key -> "file:line"
$bad = @()
$count = 0

# The types a signature takes, from the "(" after the name to its closing ")", over as many lines as it runs.
function Get-ParamTypes([string[]]$lines, [int]$at, [int]$col) {
  $text = ''
  $depth = 0
  $i = $at
  $start = $col
  while ($i -lt $lines.Count) {
    $l = ($lines[$i] -split '//', 2)[0]
    for ($k = $start; $k -lt $l.Length; $k++) {
      $ch = $l[$k]
      if ($ch -eq '(' -or $ch -eq '<') { $depth += 1; if ($depth -eq 1 -and $ch -eq '(') { continue } }
      if ($ch -eq ')' -or $ch -eq '>') { $depth -= 1; if ($depth -eq 0) { return (Format-Types $text) } }
      $text += $ch
    }
    $text += ' '
    $i += 1
    $start = 0
  }
  return (Format-Types $text)
}

function Format-Types([string]$params) {
  $types = @()
  $depth = 0
  $part = ''
  foreach ($ch in $params.ToCharArray()) {
    if ($ch -eq '<') { $depth += 1 }
    if ($ch -eq '>') { $depth -= 1 }
    if ($ch -eq ',' -and $depth -eq 0) { $types += $part; $part = ''; continue }
    $part += $ch
  }
  if ($part.Trim() -ne '') { $types += $part }
  $out = @()
  foreach ($t in $types) {
    $bits = $t -split ':', 2
    $type = if ($bits.Count -eq 2) { $bits[1] } else { $bits[0] }
    $mods = if ($bits[0] -match '\bout\b') { 'out ' } else { '' }
    $out += $mods + ($type -replace '\s+', '')
  }
  return ($out -join ',')
}

foreach ($f in Get-ChildItem -Path $src -Recurse -Filter *.reds | Sort-Object FullName) {
  $rel = $f.FullName.Substring($src.Length + 1)
  $lines = @(Get-Content -LiteralPath $f.FullName)
  $class = $null
  $anno = $null
  $annoClass = $null
  $cond = ''
  $n = 0
  foreach ($line in $lines) {
    $n += 1
    $code = ($line -split '//', 2)[0]
    if ($code.Trim() -eq '') { continue }
    $a = [regex]::Match($code, $annoRx)
    if ($a.Success) {
      $anno = $a.Groups[1].Value
      $annoClass = $a.Groups[2].Value
      continue
    }
    if ($code -match '^\s*@if\s*\((.*)\)\s*$') {
      $cond = ' @if ' + ($Matches[1] -replace '\s+', '')
      continue
    }
    if ($code -match '^\s*@') { continue }
    $c = [regex]::Match($code, $classRx)
    if ($c.Success) {
      $class = $c.Groups[1].Value
      $anno = $null
      $cond = ''
      continue
    }
    if ($code -match '^\}') {
      $class = $null
      continue
    }
    $m = [regex]::Match($code, $funcRx)
    if (-not $m.Success) {
      $anno = $null
      continue
    }
    $name = $m.Groups[1].Value
    $sig = $name + '(' + (Get-ParamTypes $lines ($n - 1) ($m.Index + $m.Length - 1)) + ')' + $cond
    $key = $null
    if ($anno -eq 'addMethod') {
      $key = "$annoClass.$sig"
    } elseif ($anno) {
      $key = $null   # a wrap or a replacement of the game's own
    } elseif ($class) {
      $key = "$class.$sig"
    } elseif ($code -match '^\S') {
      $key = "global $sig"
    }
    $anno = $null
    $cond = ''
    if (-not $key) { continue }
    $count += 1
    if ($seen.ContainsKey($key)) {
      $bad += "  $key is declared at $($seen[$key]) and again at ${rel}:$n"
    } else {
      $seen[$key] = "${rel}:$n"
    }
  }
}
if ($count -eq 0) {
  throw "No functions were found, so this check would prove nothing."
}
if ($bad.Count -gt 0) {
  $bad | ForEach-Object { Write-Host $_ }
  throw "A function is declared twice: callers read only one of them. Give each its own name."
}
Write-Host "Declarations: $count functions, each declared once."

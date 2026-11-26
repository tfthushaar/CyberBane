<#
.SYNOPSIS
  Fails if a class that a released save already holds has its saved fields changed.

.DESCRIPTION
  Adding, removing, renaming or retyping a `persistent let` on a class that saves already exist for wipes everything
  that class saved, in every one of those saves. New saved data goes in a new ScriptableSystem class instead.

  tools/saved_fields.txt lists every class with saved fields and its fields in order, as the last release had them.
  This check compares the code against it:
    - a listed class whose fields differ in any way, or that is gone, fails;
    - a class not listed yet fails until it is added with -Update, so that it is protected from then on;
    - a saved field of type String, ResRef or Variant fails, listed or not.

  Run with -Update only for a new class, or for a change to a class that has never shipped: it rewrites the list
  from the code.

  Run by tools/build.ps1 and tools/validate.ps1.
#>
param(
  [switch]$Update
)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'src/r6/scripts/Cyberbane'
$listFile = Join-Path $PSScriptRoot 'saved_fields.txt'

$classRx = '^\s*(?:public\s+|private\s+)?(?:abstract\s+|final\s+|native\s+)*(?:class|struct)\s+(\w+)'
$fieldRx = '^\s*(?:public\s+|private\s+|protected\s+)?persistent\s+let\s+(\w+)\s*:\s*([^;=]+?)\s*[;=]'

$found = [ordered]@{}   # class -> list of "name: type"
$where = @{}            # class -> file
$bad = @()

foreach ($f in Get-ChildItem -Path $src -Recurse -Filter *.reds | Sort-Object FullName) {
  $rel = $f.FullName.Substring($src.Length + 1)
  $class = $null
  $n = 0
  foreach ($line in Get-Content -LiteralPath $f.FullName) {
    $n += 1
    $code = ($line -split '//', 2)[0]
    $c = [regex]::Match($code, $classRx)
    if ($c.Success) {
      $class = $c.Groups[1].Value
      continue
    }
    $m = [regex]::Match($code, $fieldRx)
    if (-not $m.Success) { continue }
    $name = $m.Groups[1].Value
    $type = ($m.Groups[2].Value -replace '\s+', '')
    if (-not $class) {
      $bad += "  ${rel}:$n saves $name outside any class"
      continue
    }
    if ($type -match '(^|<)(String|ResRef|Variant)(>|$)') {
      $bad += "  ${rel}:$n $class.$name is saved as $type, which saves cannot hold safely"
    }
    if (-not $found.Contains($class)) {
      $found[$class] = New-Object System.Collections.Generic.List[string]
      $where[$class] = $rel
    } elseif ($where[$class] -ne $rel) {
      $bad += "  $class saves fields in two files ($($where[$class]) and $rel)"
    }
    $found[$class].Add("${name}: $type")
  }
}
if ($found.Count -eq 0) {
  throw "No saved fields were found, so this check would prove nothing."
}

if ($Update) {
  if ($bad.Count -gt 0) {
    $bad | ForEach-Object { Write-Host $_ }
    throw "Saved fields: fix these before the list is written."
  }
  $out = New-Object System.Collections.Generic.List[string]
  $out.Add('# Every class with saved fields, and its fields in order, as the code had them when this was last written.')
  $out.Add('# Written by tools/check_saved_fields.ps1 -Update. A change to a class listed here wipes its data in old saves.')
  foreach ($k in $found.Keys) {
    $out.Add('')
    $out.Add("class $k")
    foreach ($fld in $found[$k]) { $out.Add("  $fld") }
  }
  [System.IO.File]::WriteAllLines($listFile, $out)
  $total = ($found.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
  Write-Host "Saved fields: list written, $($found.Count) classes, $total fields."
  return
}

if (-not (Test-Path $listFile)) {
  throw "tools/saved_fields.txt is missing. Write it once with: tools/check_saved_fields.ps1 -Update"
}
$known = [ordered]@{}
$cur = $null
foreach ($line in Get-Content -LiteralPath $listFile) {
  if ($line -match '^\s*#' -or $line.Trim() -eq '') { continue }
  if ($line -match '^class\s+(\w+)') {
    $cur = $Matches[1]
    $known[$cur] = New-Object System.Collections.Generic.List[string]
    continue
  }
  if ($cur) { $known[$cur].Add($line.Trim()) }
}

foreach ($k in $known.Keys) {
  if (-not $found.Contains($k)) {
    $bad += "  $k is gone or saves nothing now; it saved: $($known[$k] -join ', ')"
    continue
  }
  $was = @($known[$k])
  $now = @($found[$k])
  if (($was -join '|') -ne ($now -join '|')) {
    $added = $now | Where-Object { $was -notcontains $_ }
    $removed = $was | Where-Object { $now -notcontains $_ }
    $what = @()
    if ($added) { $what += "added $($added -join ', ')" }
    if ($removed) { $what += "removed $($removed -join ', ')" }
    if (-not $added -and -not $removed) { $what += 'the same fields in another order' }
    $bad += "  $k ($($where[$k])): $($what -join '; ')"
  }
}
foreach ($k in $found.Keys) {
  if (-not $known.Contains($k)) {
    $bad += "  $k ($($where[$k])) is new: add it with tools/check_saved_fields.ps1 -Update once its fields are settled"
  }
}

if ($bad.Count -gt 0) {
  $bad | ForEach-Object { Write-Host $_ }
  throw "Saved fields changed on a class saves already hold: that wipes what it saved. Put new saved data in a new class."
}
$total = ($found.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
Write-Host "Saved fields: $($found.Count) classes, $total fields, as released."

<#
.SYNOPSIS
  Fails if two street-talk actions share an id, or an id falls inside another file's range of actions.

.DESCRIPTION
  Every line V can pick in street talk carries an action id, a constant such as
  `public func CBTalkActWatch() -> Int32 = 33`, and the answer is found by comparing the id the
  player picked against those constants in one long chain (CBStreetTalk, Reactions/StreetTalk.reds).
  The ids are picked by hand in fifteen files, so nothing stopped two of them taking the same
  number, and when they did the first test in the chain won. 2.6.5 gave the lead witness's lines 32
  and 33, which the street-pay lines already had: "Keep an eye out for me" (250eb) charged the
  witness's price, answered "Never saw you", sent the person away and set no watch, and leaning on a
  witness got the witness's directions instead of a hush (reported on 2.7.8).

  Some actions are told apart by range rather than one by one (CBTalkActIsFacedown, CBTalkActIsAlly,
  CBTalkActIsParley): `act >= CBTalkActA() && act <= CBTalkActB()`. An id of another file landing
  inside such a range would go to the wrong answer in the same way, so that is refused too.

  Run by tools/build.ps1 and tools/validate.ps1.
#>
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'src/r6/scripts/Cyberbane'

# The four lines every conversation has (CBTalkGreet and the rest) are picked from the same numbers.
$defRx = 'func\s+(CBTalk(?:Act\w+|Greet|Dismiss|Antagonize|Intimidate))\(\)\s*->\s*Int32\s*=\s*(\d+)'
$ids = @{}       # name -> id
$files = @{}     # name -> file
$bad = @()

foreach ($f in Get-ChildItem -Path $src -Recurse -Filter *.reds) {
  $rel = $f.FullName.Substring($src.Length + 1)
  $text = Get-Content -LiteralPath $f.FullName -Raw
  foreach ($m in [regex]::Matches($text, $defRx)) {
    $name = $m.Groups[1].Value
    if ($ids.ContainsKey($name)) {
      $bad += "  $name is defined twice ($($files[$name]) and $rel)"
      continue
    }
    $ids[$name] = [int]$m.Groups[2].Value
    $files[$name] = $rel
  }
}
if ($ids.Count -eq 0) {
  throw "No street-talk action ids were found, so this check would prove nothing."
}

foreach ($group in ($ids.GetEnumerator() | Group-Object Value | Where-Object Count -gt 1)) {
  $names = ($group.Group | ForEach-Object { "$($_.Key) ($($files[$_.Key]))" }) -join ', '
  $bad += "  id $($group.Name) is taken by $names"
}

# Ranges: every "act >= CBTalkActA() && act <= CBTalkActB()" in a CBTalkActIs* helper.
$rangeRx = 'act\s*>=\s*(CBTalkAct\w+)\(\)\s*&&\s*act\s*<=\s*(CBTalkAct\w+)\(\)'
foreach ($f in Get-ChildItem -Path $src -Recurse -Filter *.reds) {
  $rel = $f.FullName.Substring($src.Length + 1)
  $text = Get-Content -LiteralPath $f.FullName -Raw
  foreach ($m in [regex]::Matches($text, $rangeRx)) {
    $lo = $m.Groups[1].Value; $hi = $m.Groups[2].Value
    if (-not $ids.ContainsKey($lo) -or -not $ids.ContainsKey($hi)) {
      $bad += "  a range in $rel names an action that is not defined ($lo .. $hi)"
      continue
    }
    foreach ($e in $ids.GetEnumerator()) {
      if ($e.Value -ge $ids[$lo] -and $e.Value -le $ids[$hi] -and $files[$e.Key] -ne $files[$lo]) {
        $bad += "  $($e.Key) ($($files[$e.Key]), id $($e.Value)) falls inside $lo..$hi of $rel"
      }
    }
  }
}

if ($bad.Count -gt 0) {
  $bad | ForEach-Object { Write-Host $_ }
  throw "Street-talk action ids clash: the first answer in the chain would take the other's line. Give each its own id."
}
Write-Host "Street talk: $($ids.Count) action ids, each its own."

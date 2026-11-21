<#
.SYNOPSIS
  Fails if the mod grants any NPC an ability that crash rule 5 forbids.

.DESCRIPTION
  Crash rule 5: the abilities Cyberbane gives the people it spawns are behaviour only. Cyberware
  powers (a Kerenzikov, a Sandevistan, a Second Heart, Berserk, a biomonitor, optical camo), combat
  stims, cooling, charge jumps, reinforcement calls and the deadliest quickhacks are flags the
  game's NPC AI reads to fire effects, animations and systems on characters it never built for
  them. 1.5.0 removed them after a reproduced crash. 2.6.0 to 2.6.2 put several back without
  anyone noticing, and the reports that followed were crashes to desktop with Rivals close by.

  This makes the rule a build step, the way check_removed.ps1 holds rule 17. It looks for each
  forbidden ability's TweakDB id written as a literal (t"Ability.<name>") anywhere in src. Stat
  packages (a pain editor, ICE, subdermal armour, hit-reaction immunity) are allowed and are not
  listed.

  Run by tools/build.ps1 and tools/validate.ps1.
#>
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'src'

$banned = @(
  'HasKerenzikov', 'HasKerenzikovOmen',
  'HasSandevistan', 'HasSandevistanTier1', 'HasSandevistanTier2', 'HasSandevistanTier3',
  'HasSecondHeart', 'HasBerserk', 'HasHealthMonitor', 'HasHealthMonitorBomb',
  'HasChargeJump', 'HasMechanicalControl',
  'CanUseOpticalCamo', 'CanUseOpticalCamoOda', 'CanUseStaticCamo', 'CanUseTerrainCamo', 'CanBuffCamoQuickHack',
  'CanUseCombatStims', 'CanUseCoolingSystem', 'CanCallReinforcements',
  'CanDeathQuickHack', 'CanSuicideQuickHack', 'CanGrenadeQuickHack', 'CanMadnessQuickHack', 'CanTakeControlQuickHack'
)
$pattern = 't"Ability\.(' + ($banned -join '|') + ')"'

$files = @(Get-ChildItem -Path $src -Recurse -Filter '*.reds')
if ($files.Count -eq 0) {
  throw "No scripts found under src, so this check would prove nothing."
}

$hits = @($files | Select-String -Pattern $pattern -CaseSensitive)
if ($hits.Count -gt 0) {
  $hits | ForEach-Object { Write-Host ("  {0}:{1}  {2}" -f $_.Path.Substring($root.Length + 1), $_.LineNumber, $_.Line.Trim()) }
  throw ("A forbidden ability is granted (crash rule 5). Give what it does as stats the game reads for " +
         "every target (evasion, health, armour, damage) or as a behaviour ability instead.")
}

Write-Host "No forbidden NPC abilities ($($files.Count) scripts checked)."

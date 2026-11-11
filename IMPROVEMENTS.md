# Cyberbane improvements

A working list of what players have asked for, what the mod already does about it, and what is
left.

The released version is 1.8.5. The "Requests after 1.8.3", "Requests after 1.8.2", "Requests after 1.8.1", "Requests after 1.8.0", "Requests after 1.7.8", "Requests after 1.7.7", "Requests after 1.7.6", "Requests after 1.7.3", "Requests after 1.7.2", "Requests after 1.7.0", "Requests after 1.6.8" and "Requests after 1.6.4" sections at the top are the current ones;
everything below it was written against 1.5.0 and is kept for the reasoning rather than as a
description of today's code. The original point-by-point section and the backlog describe the mod
as it was *before* that backlog was built, and each entry's own status line says what has been
done since - so read the status lines, not the surrounding prose, for what is true now.

Every idea here has to follow the crash rules that came out of 1.5.0, which are summarised here
because the file holding them in full (`STATUS.md`) is a local developer note and is not part of
this repository: no police system calls, one AI order per NPC, no entity work inside attach
events, removals only through `CBDeleteTaggedSafe`, nothing removed in V's sight, nothing touching
an NPC that has left the world, behaviour-only ability kits, no runtime appearance changes, no
loot drops from corpses, and UI as data rather than injected widgets. **No `.reds` file is ever
deleted: a retired one becomes a stub at the same path** (`tools/check_removed.ps1` fails the build
otherwise), because installing over the top does not remove files and an old copy keeps compiling.

## Requests after 1.8.3

### "Netrunners in the crew, with better hacks, and everyone more tactical"

**Status: in 1.8.5** (`Spawn/Tactics.reds`, new; `Spawn/ApexSquad.reds`, `Spawn/HitSquad.reds`, `Spawn/Spawner.reds`,
`Model/Reputation.reds`). Combat is the game's AI (every Cyberbane move order is `ignoreInCombat`), which
picks tactics from abilities, so the work is abilities, applied the way Much Better AI applies them
(read from the archetype, through the ability's package, skipped when already applied, no hand-to-hand
ability for machines or cyberpsychos). None of its code; its spacing, aim and netrunner-cadence shaping
stay its own, and `CBAiKitOwner` stands all of this down when it or New Game Plus is installed.
- `CBApplyTactics` by fighting style (`CBFightStyleOf`): rifle (PrefersCovers, CanUseShootingSpots,
  CanShootWhileMoving; elite adds CanPreciseShoot, CanCatchUp), shotgun, sniper (PrefersShootingSpots),
  blade (CanBlock, CanParry), heavy (CanBlock; elite CanGuardBreak), netrunner. Called from the squad,
  apex seat and apex member kits.
- **Hacks without hooks.** The game's `HackActionSelector` already offers every hack, each gated by
  its ability (`Condition.AbilityCan...QuickHack`) and its own cooldown and tier. `CBGiveNetrunnerHacks`
  grants seven (Overheat, Blind, Weapon Malfunction, Jam, Locomotion, Cyberware, Overload) to records whose
  archetype is a netrunner, never Death or the take-over hacks. The alternative Much Better AI uses,
  wrapping `AISubActionQuickHack_Record_Implementation` and swapping the action, was not needed.
- **Netrunner seat.** `CBNetrunnerSeatRecord`: the gang's captured `roleNetrunnerRecord` (so More Netrunners
  records come once met), else the base game's netrunner for Tyger Claws, Maelstrom, Voodoo Boys,
  Scavengers or Arasaka. One per crew of three or more without its apex squad (`NetrunnerSeatMinCrew`).
- A netrunner kill no longer becomes `sampleRecord` or `eliteRecord`; `CBPruneUniqueRivals` moves an old
  one to the netrunner chair.
- **Grenadier.** The first shooter of a crew without its apex (`TakeCrewGrenadier`, reset with the squad
  anchor) gets frag and flashbang grenades.
- `CBKitCyberpsycho` returned when `CBAiKitOwner()` was false: inverted, fixed.

### "Nicknames keep repeating" (decided: earned from rank 2, much more variety)

**Status: in 1.8.5** (`Data/Names.reds`, `Rivals/RivalSystem.reds`). Pools went from 11 to 13 a source to 33
to 35, appended so stored indices still name the same nickname. `CBRivalEarnedNickname` (rank 2 or more, or
has killed V) gates the display. `CBRivalPickFreeEpithet` prefers one the save has never used, recorded in the
name book's list as `E|` entries, so no saved shape changed.

### "Killed over 320 6th Streets and still no 'ready to send their best' reaction"

**Status: fixed in 1.8.4** (`Spawn/Queue.reds`). `CBApexProgressLine` showed "ready to send their best" on
`CBApexEligible` alone: hostile, enough kills, a usable apex record. The lane checks far more before it
sends anyone: `CBHitSquadsOn` (the Hit squads setting and They Will Remember), the apex daily cap and the
day's budget, a busy lane and `CBArrivalsHeld`. `CBApexBlocker` asks those in the lane's order and the
Hub shows the first one ("their best waits: none left today"); `CBApexLaneNote` logs it once a minute
while the lane stands still with a gang ready. Separately, `CBLanePick` required the crew template
`fs.sampleRecord` even for the apex lane, which builds from `CBApexRecordFor`; that requirement is gone
for apex. The 6th Street roster records all exist on 2.5. Which blocker that player hit is unknown
without their log; the new line will say.

### "Night City Allies: Jackie doesn't react when a Rival attacks me"

**Status: fixed in 1.8.4** (`Spawn/Spawner.reds`). The game turns an NPC hostile with
`SetAttitudeTowardsAgentGroup` (`AIActionHelper.TryChangingAttitudeToHostile`), which covers V's companions;
`CBMakeHostileToPlayer` set an agent attitude toward V alone. Now it also pairs the NPC with each
companion (`ScriptedPuppet.IsPlayerCompanion`, found in the NPC registry), both directions, agent to agent.
The group form is deliberately not used: it changes attitudes between whole groups, which reaches vanilla
NPCs. `CBCompanionHostilityTick` repeats the pairing every five ticks for a companion recruited mid-fight.

### "A Valentino barged in while I was doing the Rite of Passage gig"

**Status: fixed in 1.8.4** (`Core/SafeAreas.reds`, `Spawn/Hunt.reds`). "On a job" was the tracked objective's
pins only, and once the hunt had located V the search-order hold lifted, so hunters chased V into the job.
`CBRefreshJobPins` adds every active objective's pins (journal quests, phases, objectives; read-only, both
patches) every thirty ticks; `IsOnJob` (a scene or near those pins, without the hostile zones the quest
area includes) holds everybody out like a sanctuary, located or not, and stops engagement and cut-off
removal. Why a Valentino was after V at all needs the player's log. Cross-gang hostility was considered
and declined: it changes what vanilla NPCs do.

## Requests after 1.8.2

### "Should this mod keep separate records on separate playthroughs?"

Reported: "Right after slaughtering everyone at the Ho-Oh, I quit the game, installed this mod, and loaded
a different character who hadn't even done The Ride yet. Within 5 minutes I got texts from three
different T-Claws telling me they are hunting me down."

**Status: fixed in 1.8.3** (`Core/CyberbaneService.reds`, `Core/CyberbaneSystem.reds`, `Rivals/DeathLedger.reds`,
`Settings/CyberbaneSettings.reds`, `Core/CyberbaneRuntime.reds`, `Signals/Common.reds`). Everything in the
service (the death ledger, gang strength, sightings, forget and start-over notes) is keyed by the
playthrough id, and every reader filters by it, so the id was the only thing keeping two characters
apart. `CBGeneratePlaythroughId` was eight `RandRange` draws with no check against ids already in use,
drawn in `OnAttach` at the first moment of a load, from a source nothing says is seeded differently
per launch. Two characters on one id read each other's records: `CBApplyDeathLedger` turned the other
character's deaths into Killer Rivals, two texts each, which matches the report. It also ran the other
way, and Start over on one retired the shared id and wiped the other on its next load.

- **New ids are unique.** `CBMintPlaythroughId` draws until `IsPlaythroughIdInUse` says no record of any
  kind holds it (`EnsurePlaythroughId`, `HardReset`).
- **Each playthrough is put on record** (`CBPlaythroughBirth`: id, birth game time, lifepath) and its saves
  carry the birth in `m_installedAt`, a saved field that existed and was never written, so no saved shape
  changed. `VerifyPlaythroughOwner` runs from `StartSession` before the notes and the ledger: a save whose
  birth or lifepath disagrees with its id's record moves to a playthrough of its own
  (`MoveToOwnPlaythrough`), joining one already split off for the same character (`FindSplit`), copying the
  old id's gang strength and sightings that are not ahead of its own clock, and never retiring the old id.
  Killer Rivals it got from the other character's deaths go (`CBForeignKillers`: exact match on record,
  place and time, and only for deaths more than a day ahead of the save's clock). Saves from before 1.8.3
  take the birth on record unless the lifepath differs. The first of them to load only *claims* the id
  (`legacyClaim`), because in the reported case the contaminated save is the one being played and loads
  first; a V with another lifepath on a claimed id marks it `disputed`, and every save on a disputed id
  moves off it, so both characters separate once each has loaded once, in either order.
- **Same lifepath, both from before 1.8.3, cannot be told apart.** "This save is another character" in Mod
  Settings does the same split for the loaded save, carried out on a settled tick, and moves any forget
  still pending on the Hub with it.

**Whether `RandRange` repeats across launches has not been tested.** Start the game, load a save with no
Cyberbane data and note the id in the log; restart, load another and compare. It no longer matters for
new ids, but it says whether the report was this or something else. The log now names the playthrough at
every session start and every death the ledger applies, with its time and place.

### Bug pass after 1.8.2

**Status: in 1.8.3.** Every system was read, starting from the code 1.8.0 to 1.8.2 added, and checked by
script for erase-in-loop, mutation during `for in`, unguarded settings reads, unguarded divisions,
unresolved calls, saved entity handles, the reset list and the crash rules (spawns and removals only
through their guarded paths, no prevention-system calls beyond point tests). Fixed:

- **Reset all Cyberbane data kept firing.** Mod Settings keeps the accepted value, writes it to its file and
  pushes it to the listener on every launch and with every later change (`ModClass::RegisterListener` and
  `NotifyListeners` in mod_settings), so setting the field to false in script never reached it: once used,
  the switch asked for a reset on every launch, applied to the first save loaded, and again whenever any
  setting was applied. Both action switches now act only on the way from off to on, remembered in the
  service (`SwitchFlipped`). A switch found on with nothing on record is taken as already done. The
  per-variable accept callback was not usable: Mod Settings 0.2.21, the last 2.31 build, fires it for every
  variable on every Apply.
- **Custom preset** fell through `ApplyPreset` to the Default branch.
- **The one-shot clock check** counted a Skip Time inside its 60 ticks as ordinary time; it restarts on a jump.
- **Turf book lists** pad independently and the loss lists are kept the same length.
- **Start over kept 1.8.2's per-Rival session state** (found after pulling 1.8.3). `HardReset` sets
  `m_nextRivalId` back to 0, while `m_pendingForgets`, `m_pendingFind` and `m_formerBodyIds` stayed, so a
  waiting forget or purchase, or a knocked-out pre-reset Rival left in view as an orphan and killed later,
  could land on the new Rival given the same id. `HardReset` clears all three.

Checked and left alone: "Friend of a Faction" counts any faction, NCPD included, while its progress line
says "with one gang". The title's name and the label it takes agree with any faction, so the intent is
not clear enough to change.

## Requests after 1.8.1

### "Knocked a Rival out, ran him over, and now a marker is stuck and no other Rival comes"

**Status: fixed in 1.8.2** (`Rivals/RivalSystem.reds`, `Signals/CombatSignals.reds`, `Spawn/Spawner.reds`,
`UI/Tracking.reds`, `Rivals/Whereabouts.reds`, `Reactions/CombatFlee.reds`). One gap behind it: an
encounter can end while the body is still in the world (spared, got away), and the body kept `CB_Rival`.
When it streamed back in, `CBApplySpawnSetup` could not find whose it was and fell back to the active
Rival: their name, their build, a chase order and a marker on somebody lying in the street, which nothing
ever removed. If it died, `CBResolveSlainRival` made the same fallback and could slay the wrong Rival.
Now `CBCloseRivalEncounter` retires a living body (`CBRetireRivalBody`: off `CB_Rival` and `CB_Lair`, onto
`CB_Orphan` for the orphan sweep) and remembers whose it was for the session, so a later death still
slays that Rival (`TakeFormerRivalBody`). Setup and `CBTrackOnMap` skip anybody not `CBStillStanding`.
The hideout watch no longer waits forever on a knocked-out body whose escapee record has gone, and the
escapee cap evicts a Rival's mercy last. The escape path now closes through `CBCloseRivalEncounter` too.

### "Loading after dying in a fight hangs at 25%" (since 1.7.7 or 1.7.8, still in 1.8.1)

**Status: probable cause fixed in 1.8.2; not reproduced** (`Core/WorldState.reds`, `Signals/CombatSignals.reds`,
`Core/CyberbaneSystem.reds`). Nothing found loops: every loop added since 1.7.6 advances, and the name
lists are at most 437 combinations. What is certain is that `CBWorldStable` never treated V's death as a
transition. The game marks it (`PlayerStateMachine.Vitals`) three seconds before the death screen, and
for those seconds cars kept driving at the body, crews were ordered out and lanes stayed free. It now
stands down while `Vitals` is Dead or Resurrecting (`CBVDown`); the deferred death and hit work waits it
out. And the death ledger, the one thing a load does only after a death (making the killer a Rival,
texting), moved from the player-attached callback inside the load to the first settled tick.

### "Let me forget one Rival" and "Let me pay to ambush one"

**Status: added in 1.8.2** (`UI/Hud.reds`, `Rivals/RivalSystem.reds`, `Rivals/Whereabouts.reds`,
`Core/CyberbaneService.reds`). Two more buttons under the Hub's action button, Rivals only, each asking
twice. Forgetting one does what `CBPurgeRivals` does for one Rival and is kept in the service
(`CBForgottenRival`, id and record) so an older save does not bring them back. Ambush sells a tipped
sighting: where they were seen when that still holds, otherwise a usable spot 95 to 150 m from V. From
there it is the 1.6.2 lead and hideout, unchanged. Price 1500 + 1000 per rank.

## Requests after 1.8.0

### Crash report: "Likely culprit: Cyberbane", OnDeath -> CBOnPuppetDeath -> DropEscapeeByEntity

**Status: fixed in 1.8.1** (`Signals/CombatSignals.reds`). An access violation in the game's code while
`DropEscapeeByEntity` ran from `ScriptedPuppet.OnDeath`, on a worker thread (faulting thread is not the
main thread), 39 minutes in. That function is unchanged since 0.1.1 and only walks one array, so the
array was being changed underneath it: puppet events run on the game's worker threads, several at once,
and since 1.7.7 more of them write that list (a death can break a nearby enemy and add them). The game's
own scripts never change a shared system inside a puppet event; they queue it. `OnDeath` now queues
`CBOnPuppetDeath` with `DelayCallbackNextFrame`, and `OnHit` queues its flee and spared checks the same
way (one per puppet at a time); the fast tick is already a delay callback, so all of it runs in turn.
What a hit was is still written onto the puppet at once. Player death stays synchronous: the death
screen may come before another frame, and the ledger has to be written.

### "Does modded chrome count? Every slot equipped, Chrome Saint 76/85, visible chrome 22"

**Status: fixed in 1.8.1** (`Signals/ChromeSignal.reds`). Chrome read `GetActiveItem` once per area: eleven
implants at most, whatever the slots, and nothing a Cyberware-EX slot held. And its body term is the
share of capacity used, which a capacity mod lowers. Now every slot of every area is read (bounded by
`GetNumberOfSlots(area, true)`, because `GetItemInEquipSlot` does not check), the best implant per area
sets that area's quality as before, and the body term is the larger of capacity used and slots filled.
Every slot filled reads as about 90. Modded items count wherever they sit, at their quality. Visible
chrome is unchanged by design: only arms, eyes, skin and legs show, and covered ones count a quarter.
The log line now gives installed chrome with slots and capacity.

## Requests after 1.7.8

### "It looks like it has become a little harder to make Rivals"

**Status: fixed in 1.8.0** (`Core/CyberbaneSystem.reds`, `Reactions/CombatFlee.reds`, `Reactions/Morale.reds`).
The log agreed: 7 Rivals and 8 spared messages in a 1.7.6 session, none of either in 40 minutes of 1.7.8
with two massacres. Three causes:

- **Knockouts were thrown away (a 1.7.8 regression).** `CBOnPuppetHit` runs `CBCombatFleeCheck` before
  `CBSparedCheck`, so a hit that knocks somebody out first logs them as a runner (zero health is under a
  quarter). 1.7.8's guard against two records for one person then kept that and dropped the spared
  record, and with it the mercy. No Spared Rival, no `CBSettleMercy`: no renown, standing, Conduct,
  `nonLethal`, `quietTakedowns` or `psychosPacified`. Now a spared record replaces a runner record,
  never the reverse, and `CBCombatFleeCheck` and `CBMoraleEligible` skip anybody not
  `CBStillStanding`: a defeated NPC had also been given a flee order.
- **The escape clock started when they were first hurt,** not when they ran. `MarkEscapeeFleeing` now
  restarts it.
- **The limits were silent.** `CBCreateRival` refused at the Max rivals setting and at three per gang
  without a word; it logs once a minute now. Neither limit changed.

Unchanged and intended since 1.7.7: a runner has to get away to become a Rival, and fewer enemies break.

### "Are there any other bugs like this?"

**Status: five found and fixed in 1.8.0.** Searched by shape: duplicate guards, two writers on one event,
states nothing ends, guards at the top of a function, and refusals the log never mentions.

- **A runner who failed to get away stayed broken for good.** The hunt skips `cbMoraleBroken`, so nothing
  ordered them again: the crew stayed live, its lane busy, and `CBChaseGiveUp` charged V for running.
  `CBRally` at the end of the escape window clears it.
- **Distance alone counted as escaping.** A wounded record 60 m off but still in combat became a Rival
  (`CBHandleEscape`), with no link to the body V then killed. Now running, or out of combat, as well.
- **The Morale switch returned from `CBCombatFleeCheck` before the wounded were recorded**, so it also
  turned off the wounded-and-got-away Rivals. It now only zeroes the break chance.
- **Two map pins on one body.** A re-attached NPC loses `cbMapped` and is set up again; `CBTrackOnMap`
  now unregisters any pin it already noted for that owner.
- **A Dogtown holder stored by 1.7.8** (before `sealed`) would have taken four in-game hours to revert.
  `CBTurfTickDistrict` restores the home gang at once.

Checked and found sound: seating on re-attach (`TakeArrivalBoarder`), the apex build (`WasBuiltAt`), kits
(applied-package check), the threat bar (dedupes by id), bounties (one-shot), and every other duplicate guard.

## Requests after 1.7.7

All in 1.7.8. Compiled on 2.5 and not yet played.

### "I keep becoming allied to gangs I'm killing"

**Status: fixed in 1.7.8** (`Model/GangRivalries.reds`). Per gang a kill already cost twice what it
earned, but the credit went to every enemy of the victim and ignored what V had done to them. A gang V
hurt in the last 48 in-game hours now earns nothing, one V has any kills against stops at +45, just
short of Allied, and `enemyOfEnemyShare` is a slider. A gang V has never hurt can still reach +75,
which the Friend of the Gang title needs.

### "Does turf do anything? Dogtown is still under Barghest"

**Status: fixed in 1.7.8** (`Model/Territory.reds`, `Model/TurfBook.reds`, `Data/Factions.reds`). Dogtown
is sealed on purpose and stays Barghest's (`sealed` on the district); Pacifica could not be taken from
outside because nobody next door was at war with it. Holders are now written down in
their own per-save system, a new class so no saved shape changes. Taking a district needs a 1.6 times
lead for four in-game hours, and it lasts until retaken; home gangs count for 40% on ground they have
lost. Damage on a gang's own streets counts again there. The old gang hits back every two days or so
once at 70 strength.

Who is visible on the street cannot change: the game's own gangs come from world data, a script has
only a crowd density control, and deleting them breaks crash rules 4 and 5. So what shows is the HUD
line, the game's own map (the record handed to the row, no widget touched), and optional patrols.
Street clashes between gangs were proposed and declined.

### "Turf patrols"

**Status: in 1.7.8, experimental and off by default** (`Spawn/TurfPatrol.reds`). Two to four of the holder,
one group at a time, only with 8 places left under the spawn cap, never during an encounter, a job, the
story, stealth or in a safe area. They go through `CBSpawnGroup`, `CBIssueMove` and `CBDeleteTaggedSafe`.

### "Tired of answering how to get a title; can titles actually mean something?"

**Status: in 1.7.8** (`Data/Titles.reds`, `Model/TitleEngine.reds`, `UI/Hud.reds`). The Titles screen lists all
of them, with the exact conditions, live progress and the effect. The title being worn gives its
effect. One at a time, so they never stack with each other, and each only moves a number Cyberbane
already owns and bounds: nothing touches V's stats. `titlePerks` turns them off.

### "Make sure stacking effects from multiple systems doesn't cause unintended behaviour"

**Status: audited in 1.7.8, across everything the mod changes in the game.** Every writer of attitudes, AI
orders, stims, money, spawns, map pins and messages was listed and checked for two systems acting on
one thing. Already bounded: all enemy strength goes through one function with a ceiling per stat; prices,
standing, fear senses, recognition and crew size clamp after every input; spawns share the cap of 18;
texts share a queue. Fixed: a re-streamed enemy being built twice and healed; the Morale intensity
slider escaping the break ceiling; the low-health route escaping the group limit; one Rival's death
creating two successors; duplicate escapee records; lanes firing together and costing a car; patrols
ignoring the hit-squads switch and They Will Remember.

## Requests after 1.7.6

Four reports and a bug pass, all in 1.7.7. Compiled on 2.5 and not yet played; the game functions they
use were read in the 2.5 scripts and in the public 2.31 copy.

### "They crash somewhere and sit inside the car until I go up to them"

**Status: fixed in 1.7.7** (`Spawn/Spawner.reds`, `Spawn/Arrival.reds`, `Spawn/Hunt.reds`). Three causes.

- **The order out of the car never worked.** `CBUnmountOnce` sent an empty `AIUnmountCommand`. The task
  that runs that command reads its `mountData` and stays in progress when it has none, so the crew
  stayed seated, and the game's combat took them out only once V came close. It now sends the
  `ExitVehicle` AI event the game sends its own passengers, asks up to five more times for anybody
  still seated, and logs anybody who never gets out.
- **The speed was 80 m/s.** The game's police send the same order at 20 and stop 20 m short. Now the same.
- **A car at V kept going to where V had been.** It now brakes once it is within reach of V. A crew
  whose car parked beside V also knows where V is, instead of having to find V again.

### "Multiple Rivals with the same names"

**Status: fixed in 1.7.7** (`Data/Names.reds`, `Rivals/RivalSystem.reds`). A name was arithmetic on the
Rival's id, nothing checked whether it was taken, and four first names by three surnames repeats every
twelve Rivals. Gangs now have 23 first names and 19 surnames, and the gangs that use handles have about
140 each. **A name is never reused in a save.** The roster alone cannot promise that: it drops the
oldest of the fallen past 32 and "Forget every rival" empties it. So `Rivals/NameBook.reds` is a
separate per-save system holding every full name used, which nothing clears. A new class, because a
new field on `CyberbaneSystem` would wipe saves. Names from before the book are covered without
knowing them: every pair the old lists could make is never given out again (`CBRivalNameIsNew`,
`MarkOldNames`). **Names only ever go on the end of a list**: a Rival is saved as a position in it.
Existing Rivals keep their names. The limit is the size of the lists, 200 to 425 new names per gang;
past that a name repeats and the log says so. The nicknames are shared the same way across the
roster, but there are only a dozen or so per kind, so those can repeat once all are in use.

### "They either run away scared or don't mind you at all"

**Status: fixed in 1.7.7** (`Reactions/Crowd.reds`). The two tiers both sent the same thing, a Terror
stim and a stage-3 SpreadFear, so there was nothing between no reaction and a stampede, and the
slider only moved the point where one became the other. The game's crowd code has four stages: a look,
walking away, hands up, running. `CBFearStage` picks one by fear and distance, and the stim goes
straight from V to that one person. A gang member's fear used to be shouted at 10 m, so one nervous
ganger on a corner sent every civilian near them running; they look at V now, and that broadcast is
gone. It never affected the person sending it: `IsStimuliEventValid` drops a stim whose source is its
own target. New thresholds are `CivFear*`, left apart from `CivTier*`, which also price vendors and name V on the Hub.

### "Gangs with a vendetta could set up roadblocks, or hide in their car to ambush"

**Status: the ambush is in 1.7.7, experimental and off by default** (`Spawn/Arrival.reds`,
`carAmbushes`). The roadblock is not: the game's are spawned and tracked by the prevention system,
which crash rule 1 keeps us out of. The ambush is an ordinary car arrival that parks ahead of a driving
V and waits. The wait always ends in the normal launch, when V comes within 45 m, gets 300 m away, or
after a minute, so a crew cannot be stranded. Vendetta crews without their apex squad only. Off, the
setting is the first thing tested and every car takes the path it always took.

### Bug pass

The 1.7.6 log has no failed deliveries or refused spawns. Scans found no unformatted strings, unguarded
divisions, or unbounded saved lists. Two bugs turned up, both fixed: the nickname repeat above, and an
**apex squad sent twice**. Killed inside the 90-tick drive clock, the squad looked undelivered, because
the muster forgets its chairs when all four are in or all are down. `PendingApexCame` now remembers.

A second, wider pass after that read Economy, Narrative, Reactions, Signals, the scoring and title code
and the Rival lifecycle with the comments stripped, and cross-checked the whole tree by script (dead
functions, wrapped methods, the reset list, localization keys, unbounded lists). Two more fixes:
**Freeze reputation** only stopped kills, so deeds, gigs, titles and rumours kept adding to it; the
four `Add*Points` now refuse a gain while frozen. And `CBMoraleBreak` made a Rival on the spot, before
anybody knew if the person got away; it now goes through the escapee path like any other runner.

### "Make the enemies who broke flee, and make it depend on various factors"

**Status: done in 1.7.7** (`Reactions/Morale.reds`, `Reactions/CombatFlee.reds`). A broken enemy never ran:
its Terror reaches the people around it and, per `IsStimuliEventValid`, not the sender. It now gets a
sprint order to a point away from V with `ignoreInCombat` false, which the game keeps active in a fight.
They stay hostile, because a neutral NPC shot in the back would be an assault to the police.
`CBBreakChance` replaces the flat threshold: shock times the gang's fear of V, plus being hurt, being
alone, a leader dying, a brutal kill; times rank; less for a vendetta; 40% at most, and nothing on the
first body. The low-health check uses the same sum instead of a coin flip. Default cap 35%, on a renamed
field so the new default reaches everyone. Nowhere to run means they keep fighting. Rerun if they arrive
with V close, up to three times. A crew member who gets away is taken off the crew (`CBRunnerGotAway`).


## Requests after 1.7.3

Three requests and one crash report, the requests all in 1.7.5. Compiled on 2.5; the hooks read in
both the 2.5 scripts and the public 2.31 copy, where they are identical.

### "Can't see the new hub button. Maybe other mods that add their own buttons"

**Status: fixed in 1.7.5** (`UI/HubTab.reds`). 1.7.3 added the tab to `HubMenuUtility.CreateMenuData`,
which only one of the game's two hubs calls. The radial hub (`radial_hub_menu_enabled`) builds its own
list, and a CET `Override` of `CreateMenuData` that does not call the original drops anything added
to it. The reporter has seven menu mods, so which applied is unknown, but the fix covers both: the tab
goes in at `AddMenus` on each hub's panel, which receives the row whoever built it. In the radial hub
it joins Character's group. "Hub in the pause menu" stays the way out.

### "I have 14 max rivals enabled, but I can see max 10"

**Status: 1.7.5 did not fix it for the user; 1.7.6 adds Up and Down buttons** (`UI/Hud.reds`,
`ListWindow`). Why the wheel did not move it is not known: it may never have reached the page, or the
list may have had ten or fewer entries. The buttons are clicked like everything else on the page,
so they work wherever clicks do, and the first scroll each time the page opens is logged
("Hub list scrolled"), which settles the question next time. Every list stopped at `CBHudListRows` (10),
and Gangs has 16 factions as well. Rivals and Gangs now build the whole list, then show a window onto
it that the mouse wheel and the right stick move. A line over the list says which part is showing.
The City and Turf top out at 8 districts and Titles at 21 rows, all of which fit.

### "Pay off a gang from the Hub after clicking on it, with a confirm button"

**Status: fixed in 1.7.6. The cause was every click arriving twice.** The left mouse button and A are
bound to both `click` and `select`, and the Hub took either, so each press ran twice: the log has
every title chosen written two times. A gang toggles open, so the second run closed it again, and
the two-step buttons (Forget every rival, Start over, and 1.7.5's pay-off) were armed and confirmed
in one press. The Hub now takes `click` alone, as the game's pause menu does.

### Crash report: "Likely culprit: Cyberbane", Execute -> HasEquipment

**Status: not Cyberbane.** A police MaxTac soldier's weapon record
(`Items.Preset_Ajax_Military_MaxTac_2nd_wave`) came back as a garbage pointer inside the game's own AI
task `AddWeapon.Execute`. The reporter matched the name `Execute` against mod sources and found
`CBOpenThreadAction.Execute` in `UI/RealPhone.reds`, which overrides a notification action and cannot
be renamed. Cyberbane calls nothing on that path. Expect more reports like it on any game `Execute`.

## Requests after 1.7.2

Two requests, both in 1.7.3. Neither has been played: they compile on 2.5, and every game function
they hook was read in both the 2.5 scripts and a public copy of the 2.31 ones.

### "They don't spawn in the safe area, however unlock the door and walk in"

**Status: fixed in 1.7.3** (`Spawn/Sanctuary.reds`). The safe-area rules only ever spoke for where
somebody is placed. Once out, nothing stopped them: the search ring follows V inside, a hunter who has
found V is handed V to walk to, and the game lets an NPC through any closed, powered, unlocked door
(`Door.EvaluateOffMeshLinksTask`). The rule is now about V: while V is in a safe area, unless the
player opted in, nobody gets a move order, nobody is handed V as a target, anybody who has lost sight
of V stops fighting V, and a door will not open for anybody of ours. Every order on foot goes
through `CBOrderPursue`, so that is where it is enforced. The door itself is never locked or changed,
because the story uses it. Search points also refuse a safe area wherever V is.

### "Move the Hub to the top row, using the game's own interface"

**Status: built in 1.7.3, and the default after the user tried it in game** (`UI/HubTab.reds`). "Hub
in the pause menu" under Interface puts it back where it was. The top row is a list, so one more entry is a real tab. A tab has to open a screen the game already knows,
and adding a new one needs a new interface file, so the tab opens the Stats screen with a marker, and
that screen hides its content and shows the Hub. Its screens row is the game's own tab label and key
glyph, its button and rows are cut from the game's button art, its hints are the game's, and it draws
nothing over the game's background. With the pause menu option on, the new hooks pass straight through.

## Requests after 1.7.0

Three reports from players on 1.7.0, two of them fixed in 1.7.1. None of the fixes has been played
yet: they compile by every check that can be made here, and the reasoning was read against the
game's own 2.31 and 2.5 scripts.

### "I get tips, I check the map and I just see the NCPD icons" (and "I can't see the new icons")

**Status: the tip pin is fixed in 1.7.1** (`Rivals/Whereabouts.reds`, `CBLeadPinTick`). The reporter
is on 1.7.0. `CustomPositionVariant`, which the pin used from 1.6.5, is the role of the player's own
waypoint, not a look: the map keeps one pin in that role and writes to whichever it finds (another
mod saw its pin moved to a spot nobody chose: spuddeh's NC Zoning District Guide, `WorldActions.reds`),
and 2.31's auto-drive unregisters any tracked pin of that variant on arrival
(`autoDriveSystem.script`).

**"I don't want a cyberpsycho pin. I want a proper custom pin that can't be confused with anything
else."** Done in 1.7.1 (`UI/RivalPin.reds`). Any vanilla variant brings its own icon, label and
filter (`HuntForPsychoVariant` is filed under the Cyberpsycho filter, `world_map.tweak`), so the look
no longer comes from the variant. The base is `ApartmentVariant`: drawn on the world map, read by no
2.31 or 2.5 script, player-trackable, and in `CommonFilterGroup` (Your Property, with the player's
own waypoint and vehicles). `debugCaption` carries `CB_RIVAL|<name>`, and five wraps redraw any pin
with that tag: `BaseWorldMapMappinController.UpdateIcon`, `MinimapPOIMappinController.UpdateIcon`,
`QuestMappinController.UpdateIcon` (the world pin, whose `displayName` would otherwise print the
tag within `showNameMinRange`), `WorldMapTooltipController.SetData` (title and description) and
`MinimapContainerController.CreateMappinUIProfile` (the waypoint's own minimap profile, so it is on
the minimap untracked). The glyph is `ChoiceIcons.BountyHuntIcon` (`mappin_icons.inkatlas`,
`bounty_hunt`), which on both patches no map variant, pin record or script draws: the same mark as
the Rival minimap marker. Tinted `CBHudAmber`, unbound first. Technique and both crash traps from
Spuddeh's NC Zoning District Guide (MIT, `MapMarker.reds`): identity is read only where the mappin is
alive, never in `UpdateTrackedState`. All five signatures match the decompiled game code exactly.
A glyph that is Cyberbane's alone, rather than an unused game one, needs an `.archive` with its own
atlas, which needs WolvenKit.

The markers on people (gold, purple, white) were traced through `minimap.script` and
`minimapMappins.script` on both patches: a pin with `GameplayRoleMappinData` goes to the device mappin,
spawn profile Always, drawn when `m_showOnMiniMap` is set and `m_textureID` is valid, the same path the
game uses for a tagged NPC, and the fallback icon `MappinIcons.NPCMappin` is the game's own NPC role
icon. Nothing in script stops them. If they still do not show, that is native, and the next report
should say whether the pin or the markers are meant.

### "When I get to his location he isn't there, then he spawns in front of me"

**Status: fixed in 1.7.1** (`CBLairTryPlace`, `CBPointHiddenFrom` in `Spawn/Spawner.reds`). Two
causes. The place was only filled while V was 30-85 m from it, so arriving at the pin found nobody;
and the visibility test was `CBPointOutOfSight`, which passes any point behind V and any point 70 m
or more in front, both right for somebody walking at V and wrong for somebody standing still where V
is looking. The body appears seconds after the point is chosen, which is when V turns. Now the only
distance rule is 10 m from V, there is a second ring of spots at 22 m, and a spot needs static
geometry across all three rays from V's eye (shins, waist, head), or to be out of frame and 70 m off.
The rays run before the path query, so the extra spots cost little.

### "1.7 gets me a red error"

**Status: fixed in 1.7.2. The cause was found from a player's log, and it was not what 1.7.1 thought.**

```
[UNRESOLVED_FN] At ...\r6\scripts\Cyberbane\Spawn\VanillaChase.reds:51:17:
function 'CBChaseVehicle' not found
```

`Spawn/VanillaChase.reds` was deleted from the mod in 1.5.0. Installing over the top does not remove
files, so it stayed on every install updated by hand and was compiled with everything else, and it
kept compiling because `CBChaseVehicle` was still in `Spawn/Arrival.reds`, dead. 1.7.0 deleted that
function as dead code. Reproduced exactly: a clean 1.7.1 plus the old file gives the same error.

**Two things said here before were wrong.** "Nothing was removed from `src` since 1.6.4, so an install
over the top leaves no stale file" only looked as far back as 1.6.4, and the file dated from before
it. Every check on 1.7.1 compiled the clean tree, which is exactly the one thing a player with an old
folder does not have. The three syntax forms rewritten in 1.7.1 were not the cause. They stay
rewritten, because that cost nothing.

**The fix is the rule, not the function.** Putting `CBChaseVehicle` back would have left the next
deleted symbol to do the same thing. An install now always ends up with exactly the files in the
zip, whichever version it started from: every script ever shipped stays at its path, the two retired
ones as stubs (`Spawn/VanillaChase.reds`, `Compat/FenixRebirth.reds`), and `tools/check_removed.ps1`
fails the build and the validation if any path from the git history goes missing. Tested by
extracting the real zip over older versions and compiling the result.

### "Crews get stuck inside buildings and underground so cannot be killed"

**Status: fixed in 1.7.1, at the rules rather than the report.** None of it has been played yet.

The rule that was being broken is that nobody is put, or kept, where they and V cannot reach each
other. It was broken in five places, and 1.7.0's removal of the road gate made one of them much more
likely.

- `CBPointReachable` accepted any route of any length, so a ramp three blocks away joined a car park
  to the street above it. It now refuses a route over three times the straight line plus 40 m.
  Placement, search points and the Rival's place all ask it, and `CBNavAnchor` has stopped carrying
  its own copy.
- `CBSpawnGroup` asked only of the first body. The rest had to be within 18 m in a straight line, in
  any direction. `CBPointArrivable` now ties each to the first, on all four placement routes.
- Cars: the pursuit-point route had no route test at all. There is no road query to go back to:
  `NavGenAgentSize` has only `Human`, nothing shows what the navmesh masks mean, and the road query
  belongs to the prevention system (crash rule 1). So a spot now needs open sky (`CBPointCovered`, a
  ceiling across five rays, while V is under open sky too), room, and a route. The candidates went
  from 6 to 12 over a wider range so that cars keep coming. `IsEntityInInteriorArea`, the game's own
  test, cannot be asked of a point, so it is asked of the car once it exists, before anybody boards.
- A car's crew were created at an untested sum beside the car. They are now snapped to the ground
  within 3 m (`ArrivalSeatSnap`).
- `CBCombatReleaseTick` looked only past 45 m and counted anybody close as engaged, so somebody stuck
  under V held every release off. `CBCutOffTick` now judges the person: not seeing V, not seen by V,
  and either on one patch of ground or with no route. Past `ChaseLoseDistance` it leaves them to the
  chase, so a real escape still counts as one. After 21 s they stop counting as engaged, after 45 s
  they are removed out of sight, and a Rival among them closes their encounter and comes back later.

A roof cannot stop an arrival outright: the close-in last resort skips that test, because a gate that
refuses everywhere is how this mod has gone quiet before.

### "Map marker is non-existent for leaders"

**Status: fixed in 1.7.1 as a regression from 1.7.0. What the player means by "leaders" is inferred.**

Nothing in the code treats a Rival who holds the leader's chair differently: same spawn, same tags,
same pin. What did change is that 1.7.0 moved every marker from `QuestEntityMappinDefinition` to
`DeviceMappinDefinition`, which has `showOnMap = false`, so nobody the mod sends has been on the big
map since, and a leader is who somebody goes to the map to find. The pin is now
`DeviceWorldMapMappinDefinition`, the same pin with the map on, so the minimap and in-world behaviour
stay as they were. `ApartmentVariant` puts it in the map's Your Property filter, since `GenericRole`
is in none (a definition's variant list is not enforced: neither the 1.6.8 pin nor the 1.7.0 pin was
on its list). `UI/RivalPin.reds` draws it on the map from a `CB_RIVAL|+` caption, in the marker's own
colour, with who it is and "Hunting you."

Pins also have an owner now. psiberx's map pin sample warns that a pin on an object goes to an
unpredictable place when the object does, and an NPC who streamed out took the pin's id with it.
`CBMarkerSweep` keeps owners on the system and takes down any pin whose owner has left. **If the
report comes back on 1.7.1, ask whether the leader was on the minimap in a fight or expected on the
map before they arrived, because a Rival has no marker until they are in the world.**

Two more ideas, from a different player, recorded and not built. The ideas under each are
starting points, and none of them has been decided.

### "More explicit or active ways to become friendly with a gang besides fighting their enemies"

**Status: open, not built.**

What V can do today, at the default numbers. Friendly starts at 15 standing and Allied at 50.

- Hurt a gang's enemies: they warm by half of what the victim lost, up to 75 (`CBCreditRivalGangs`).
- Let one of their Rivals walk: +3 (`MercyRivalCredit`).
- Pay off a hostile gang: standing jumps to 15, the edge of Friendly, and then drifts back towards
  their baseline at a point a day (`CBBrokerPeace`, `CBApplyDecay`). It only exists for a gang that
  is already hostile.
- Tribute: +5, but a gang pays it because it fears V, so it is not something V can choose.

**Found while writing this: leaving their people alive does not work.** The Hub's Gangs screen and
`Model/GangRivalries.reds` both call it a way to be thought well of, and it loses standing. A
non-lethal takedown costs a quarter of what the kill would (`NonLethalStandingShare`) and earns
+0.4 (`MercyCredit`), both in `CBApplyKill`:

| Who | Cost | Mercy | Net |
|---|---|---|---|
| Ganger | -0.50 | +0.40 | -0.10 |
| Elite | -1.00 | +0.40 | -0.60 |
| Officer | -1.50 | +0.40 | -1.10 |
| Boss | -6.25 | +0.40 | -5.85 |

Nobody seeing it scales both sides alike, so the sign stays the same. `MercyCeiling` (20) can never
be reached this way, and the slow drift back to baseline works against it too. Fix this before
adding anything new, because it is the route the mod already tells players to use. Until it is
fixed, the only way to warm a gang without hurting their enemies is letting a Rival walk.

Ideas:

- **Favours over the phone.** A gang V is on neutral terms with texts a small ask with a price, and
  V answers on the same reply rows the pay-off uses (`UI/RealPhone.reds`). This adds no new engine
  surface, and it is the only one here that is not fighting.
- **Keeping the peace on their streets.** Time on a gang's turf with no trouble warms them slowly,
  read from what is already stored, the way Laying Low reads `lastIncidentAt`.
- **Spending on their turf.** Natural, but `GetBuyPrice` only works out a price, so seeing a real
  purchase would need a new wrap, which is a 2.31 risk.

Whatever is built keeps to the save rule: no new `persistent let` on anything the save holds. Keep
new records in the play service, keyed by playthrough, as sightings and gang strength are.

### "Be part of the turf wars and change the tides for a chosen gang"

The player's example: "killing x amount of tiger claws while in their turf reduces their dominion
over a region by y%".

**Status: half there. Picking a side and any effect by region are not built.**

What exists (`Model/Territory.reds`): every one of a gang's people V puts down costs it strength
(0.8 a member, 3 an officer, 8 a boss), and a district is split by strength squared. A gang sharing
a district with one other gang at full strength, in a short stretch and before rebuilding:

| Ordinary kills | Strength | Share of the district |
|---|---|---|
| 0 | 100 | 50% |
| 20 | 84 | 41% |
| 40 | 68 | 32% |
| 56 | 55 | 23% |
| 80 | 36 | 11% |

They rebuild 12 strength an in-game day and never fall below 15. Under 55 a gang at war with them
from next door moves in. The Hub's Turf screen shows all of it.

What is missing:

- **It is citywide.** A Tyger Claw killed anywhere costs the same strength, which lowers their share
  of every district at once. Where V did it makes no difference, and that is the player's request.
- **V cannot choose a side.** Hurting one gang helps whoever is next door, by accident. A gang that
  likes V gets nothing from V except a thank-you text when it moves in.

Ideas:

- **Pressure by district.** Keep a number per gang and district, fed from the district of the kill
  (`CBEventDistrict`), and apply it to that gang's weight in `CBTurfContenders`. It decays the way
  strength recovers. Arithmetic on our own numbers, so it touches no engine state.
- **Backing a gang.** One gang at a time, chosen on the Turf screen with the Hub's existing action
  button. Their gains become V's news, and holding a district for them pays or raises standing.
- **Show V's hand.** The Turf screen says what V has done to a district, so the effect can be seen.

The same player likes gangs going extinct. Here a gang is weakened and never wiped out, on purpose
(`GangStrengthFloor`), so that would be a design change rather than an addition.

## Requests after 1.6.8

All from one play session, all fixed in 1.7.0. None of this has been played yet: it compiles and
the logic was read against the game's scripts. The Hunt, car and marker sections below say what to
look for in the log on the first session.

### "They spawn but they don't actively search"

**Status: fixed in 1.7.0** (`Spawn/Hunt.reds`, `Reactions/Director.reds`). Five causes: the hunt's
clocks ran from the warning instead of from arrival; the search was a walk to random points; the
Director sent Terror to our own hunters and through them to their crew (`CBSentByUs`); the combat
release deleted hunters who were still closing (`cbReleaseAway`); and the give-up clock ran while a
car was coming. A log line every 30 s now says how a search is going.

### "All the apex do is use guns"

**Status: fixed in 1.7.0** (`Data/ApexRoster.reds`, `Spawn/ApexSquad.reds`). Chairs fell back to one
record unless V had killed that kind. There is now a roster of 88 verified records for 14 gangs.
`CBArchetypeRole` was also wrong: it filed melee and snipers in the wrong chairs.

### "They don't arrive in cars"

**Status: fixed in 1.7.0, cause inferred** (`Spawn/Arrival.reds`, `Spawn/RivalEncounter.reds`). The
last on-foot car in the log is dated before the 1.4.7 road gate, which makes the gate the likeliest
blocker; the native's behaviour at zero heat cannot be read from here. The gate is gone, along with
the 60% Rival roll and an oversized fit box. **The on-foot car path has never appeared in a log, so
this is its first real run:** `carsWhileOnFoot` is the first switch on any crash report.

### "They are marked by NCPD markers. Can they have our own?"

**Status: fixed in 1.7.0** (`UI/Tracking.reds`). `GameplayRoleMappinData` on a device mappin draws
any UI icon record on the minimap, coloured by quality. The icon is the game's own
`ChoiceIcons.BountyHuntIcon`, which has not been seen on screen yet. A truly bespoke icon needs an
`.archive`, which needs WolvenKit, which is not on this machine.

**Correction:** 1.6.5 said `GangWatchVariant` is never on the minimap. That was only true of a
position pin, and only `minimap.script` was searched. On an NPC it is drawn, as an NCPD scanner,
which `minimapMappins.script` says outright (`IsNcpdScanner`). That is what this report was.

### "Barghest give me wanted stars outside Dogtown"

**Status: fixed in 1.7.0, cause inferred** (`Rivals/RivalSystem.reds`, `CBRecordDrawsPolice`).
`prevention_dogtown_*` records are Barghest-affiliated police, and they could be sampled into crews
and Rivals. Whether that is what this player's save held has not been confirmed.

### "Fix any and all bugs you notice in all systems"

**Status: done in 1.7.0.** Every source file has now been read. What that found, past the reports
above, was mostly one kind of bug: a name typed by hand that the game spells differently, which
fails silently. `JapanTown` (15 district values unmapped, ten of them Japantown), `TheMox`, MaxTac (not an affiliation at all),
`SandevistanPlayerBuff`, and the Wraiths and Konpeki Ghost missing from our own tables. Every
`t"..."` record (160) and every status or record tag (35) has since been checked against the game's
files, and all resolve. The other pattern was units: three callers read hit points as a percentage.

**Left as they are, deliberately:** deeds other than the Heist have no verified quest fact, so they
do not fire (`Data/Deeds.reds` says why). Look scores nothing, because no clothing record carries a
visual tag. `CBPanicDrivingTick`'s stim has no radius, and giving it one could draw police.

## Requests after 1.6.4

### "I got a text that they'd put it on my map, but I can't find it. What does the icon look like?"

**Status: it was a bug, fixed in 1.6.5** (`Rivals/Whereabouts.reds`, `CBLeadPinTick`).

The lead pin was `Mappins.DefaultStaticMappin` with `GangWatchVariant`. Read against the game's UI
scripts: the minimap's `CreateMappinUIProfile` has no profile for that variant on a plain position
pin and returns `MappinUIProfile.None`, so it was never on the minimap; the world map draws every
pin, but `MappinToTexturePart` gives this variant `map_bounty` (the NCPD scanner icon),
`IsPoliceTooltip` gives it the police tooltip, and it shares the NCPD group's filter and zoom
clustering. In a district full of hustles it was indistinguishable. `CustomPositionVariant` is the
only variant the minimap always draws for a position pin, has its own icon (`dynamic_event`) and a
journal-free "custom location" tooltip, and is trackable from the world map.

Same cause, not changed: the markers on people (`UI/Tracking.reds`, quest entity pins with
`GangWatchVariant`) are also not drawn on the minimap. The only minimap-visible choices there are
the yellow quest markers taken out in 1.4.7 or the gameplay-role marker path, which needs testing
in game. The readme no longer claims minimap markers on people.

## Requests after 1.6.3

### "I can't access my phone, it says you can't do that right now."

**Status: it was Cyberbane, fixed in 1.6.4** (`Spawn/Spawner.reds`, `Spawn/Hunt.reds`).

The notice is the game's one answer for every reason `PhoneSystem.IsPhoneEnabled()` can be false
(combat, the cinematic camera, the NoPhone / PhoneInterrupted / BlockAllHubMenu tags, scene tiers
3-5, device control, diving, a forced-hidden phone). Cyberbane sets none of those directly, but it
drove the first one: the game counts V as in combat while any hostile tracks V
(`playerCombatController.script`, `m_isTracked`), and `CBMakeHostileToPlayer` injected V into
every spawn's target tracker at setup. So every hunt locked the phone, saving and fast travel from
the moment anybody was placed. The injection now happens only from the hunt, once V is Located,
and only for hunters within `HuntEngageDistance` (`CBHuntEngage`); a waiting Rival is never given
it. That also makes the search, the scout's call-in and the waiting Rival work as designed.

### "How do I bring Dread down?"

**Status: answered, and fixed in 1.6.4** (`Model/Decay.reds`, `Model/ScoreMath.reds`,
`Model/Reputation.reds`, `UI/Hud.reds`).

Dread is 0.35 body count + 0.20 visible chrome + 0.15 look + 0.20 jobs + 0.10 heat. Chrome and
look follow what V wears. The body count decayed 0.5%/day on points that saturate (so it never
visibly moved) and the jobs never decayed, so 55% of Dread only rose. Both now fade a fixed number
of points of their 0..100 value per day (`CBFadeDreadPoints`) down to a floor from V's lifetime
record (`CBKillDreadFloor`, `CBDeedDreadFloor`). Knockouts add `NonLethalDreadShare` of a kill's
Dread, massacres count bodies only, and the Hub's reason line uses visible chrome and says what
brings it down.

**And Laying Low finally works,** which doubles all of that. §11.5 of the spec has said since the
first draft that three in-game days without putting anybody down doubles the decay of kill-dread,
heat and faction renown; nothing had ever implemented it, so answering "how do I bring Dread down"
with "lie low" was only half true. `CBIsLayingLow` reads `lastIncidentAt`, which is already saved
and already written on every kill including non-lethal ones, so it needed **no new persistent
field** - worth remembering as a first question whenever something looks like it needs one.
Excluded on purpose: V's archetype mix, standing drifting to baseline, and district renown.

So the short answer for a player: cover your chrome and dress down for an immediate drop (a third
of Dread), then stop putting people down - three in-game days of that and the rest fades twice as
fast, though a long record never fades to nothing.

## Requests after 1.6.2

### "Sometimes enemies spawned by Cyberbane despawn mid fight. Hit squads, not Rivals."

**Status: it was a bug, fixed in 1.6.3** (`Spawn/HitSquad.reds`, `Spawn/Hunt.reds`).

`CBHitSquadTick` still carried the crew despawn from before the hunt existed: on the slow tick, once
`HitSquadDespawnMinutes * 60` had passed since the crew was sent, every living `CB_Squad` member out
of view was deleted and the rest were orphaned (and deleted the moment they were out of view). That
was compared against `CBGameSeconds`, so "five minutes" was under forty real seconds, and the slow
tick runs once an in-game hour - any fight that hourly look landed in lost its flankers. Only
`CB_Squad` was ever swept, which is why Rivals were never affected.

**The fix:** the timer is gone, not retuned - no length of it can know whether a fight is on. The
hunt owns a crew's lifetime (`CBChaseGiveUp` when V gets away, the story stand-down). The two jobs
the timer also did moved where they belong: a survivor of a crew V gave the slip becomes a Hunter
Rival in `CBChaseGiveUp`, and knocked-out crew are cleared by the remains sweep. The combat release
no longer lets go of anybody while somebody of ours is close to V or can see V, and the Rival
retire backstop does not fire while the hunt is Located.

### "I'm not getting tips to hunt my Rivals."

**Status: it was a bug, fixed in 1.6.3** (`Rivals/Whereabouts.reds`).

A sighting needed the body attached at the moment the encounter ended, and the commonest escape -
V outrunning them - ends with the body 120 m+ away and streamed out. The Rival lane's queued Rival
was also excluded from tips, and that is nearly always the Rival V just lost. Now the active Rival's
last standing position is kept every other tick and used as a fallback (escapees keep theirs too),
being queued no longer blocks a tip (finding them first takes them off the queue), and an untold
sighting gets likelier to be told the longer it waits (`TipChanceRisePerHour`).

### "The hit squads don't contain apex members." / "A hit squad should contain an apex squad and other crew."

**Status: done in 1.6.3** (`Spawn/HitSquad.reds`, `Spawn/FactionApex.reds`).

Only a vendetta crew brought its apex, and only through `CBSendByCar`, which refuses whenever V is
on foot - so no crew ever had one. Every crew is now its gang's apex squad plus the rest
(`CBCrewBringsApex`, one decision for the spawn, the text and the HUD). An apex squad is always
four: every placement marks its chair, and `CBApexMusterTick` walks in the chairs still missing.

### "Gang Retaliation has a cool territory war graph - can we borrow from it?"

**Status: done in 1.6.3** (`Model/Territory.reds`, the Hub's Turf screen).

Gang strength falls with what V does to a gang and recovers over in-game days, districts are split
between their gangs by strength, and a broken gang's district is pushed into by a gang at war with
it from next door. Strength lives in the play service, as sightings do, so no save changes shape.
The Turf screen is one row per district drawn with the existing row grid and text meters.

## Requests after 1.6.1

### "I dont get the messages where you can either pay for the vendetta to be over or not, is it a bug?"

**Status: it was a bug, fixed in 1.6.2** (`Model/Reputation.reds`, `Economy/Peace.reds`).

Yes, and it was reachable for almost nobody. The answer V can send - pay what they want, or refuse
- is attached to a phone thread, and a thread only gets one when the gang sends a message through
`CBPhoneFromGang`. For a vendetta, the only such message was the one sent the moment the gang swore
it. But a vendetta is kept in the save (`fs.vendettaSince`) while the phone's threads are
deliberately not (see the "Session only" note in `UI/PhoneMessages.reds` - keeping them would mean a
new persistent field, which wipes everyone's reputation). So:

- swear a vendetta, and the offer is there for the rest of that session;
- save, quit, come back, and the vendetta is still on file, the gang never announces it again, and
  the phone has nothing in it to answer.

The Hub's pay-off shortcut still worked throughout, so the feature was never gone - but the
messages the README describes could not be reached at all by anyone who had angered a gang in an
earlier session, which is most people who hit it.

**The fix:** every gang that is hostile to V and can be bought now states its price once a session,
unprompted, from the vendetta watch. It goes out through `CBPhoneFromGang`, so it re-files the
thread and re-opens the answer through the path that already existed - no new persistent field, no
new engine call, no new widget. One gang per pass so a save with several enemies does not fill the
phone at once, and a gang V has already turned down stays turned down until the next session.

### "Rivals should show their names in the scanner, like the named NCPD targets do."

**Status: done in 1.6.2** (`UI/ScannerName.reds`).

- A Rival scans under the name Cyberbane uses everywhere else, with their class underneath. These
  are the same two lines the game shows for a named NCPD target.
- It wraps `NPCPuppet.CompileScannerChunks`. The game builds the scan as normal, and then the name
  chunk is written again for a Rival's body only.
- The body carries its Rival id from set-up, so a corpse or somebody knocked out still scans as
  themselves.
- Checked against the 2.31 and 2.5 script source. Both build the name chunk with the same code,
  and every call used exists with the same signature on both.

### "It would be peak to track my Nemesis and go ambush them. Like they do with us."

**Status: built in 1.6.2** (`Rivals/Whereabouts.reds`), using the staged plan this section first
laid out. The research found real crash risk in the obvious version of the idea, so the version
that was built is shaped around each risk. Each one is listed below with how it was answered.
The in-game checks at the end are still owed: nothing here could be compiled or played where it
was written.

**What it does**

1. **Seen.** When a Rival walks away from an encounter alive, the spot they were standing on is
   recorded. That happens through `CBRivalEscapedByPlayer` (V lost them, which covers the retire
   sweep and `CBChaseGiveUp`), `CBHandleEscape` and `CBHandleSpared`.
2. **Tip.** On the slow tick, now and then, a gang at war with theirs that does not want V dead
   texts V where, or the street does. A pin goes on the map. One lead at a time; it goes stale
   after an in-game day.
3. **Waiting.** Within about 80 m of the pin, on foot and calm, the Rival is placed there idle,
   tagged `CB_Lair`.
4. **The fight.** In combat or hurt by V, the tag becomes `CB_Rival` (`CBLairPromote`), and it is
   an ordinary Rival encounter from then on.
5. **Ambush.** Killed while still `CB_Lair`: extra renown, a History line, word from the tipster.

**The risks found, and how each was answered**

1. **Spawning at the riskiest moment** (V arriving by car or fast travel, while the world
   streams). A waiting Rival is placed only when all of these hold:
   - V has been on foot, out of combat and in a settled world for `LairCalmTicks` ticks;
   - no story hold, safe area or job is in the way;
   - nothing else of Cyberbane's is out or on its way;
   - there is room under `MaxLiveSpawns`.

   The spawn point passes every test an ordinary arrival passes (`CBNavSnap`, `CBSettleOnGround`,
   `CBSafeAreaBlocksSpawn`, `CBPointOutOfSight`, `CBPointReachable`), and the body is created with
   the same `CBCreateSpawn` call.
2. **Bodies living away from V.** One waiting Rival at a time, held in session fields on the
   system. They are taken back out through `CBDeleteTaggedSafe`, out of sight, in any of these
   cases:
   - V gets more than `LairLeaveDistance` away;
   - the story takes the stage;
   - the switch goes off;
   - the body never appears.

   A body that is down is never removed by this code. The mercy path settles it, or, if V did
   not put them down, the slot is simply let go. While they wait, the Rival lane counts as busy
   (`CBLaneBusy`), so a second Rival body cannot appear. Their state is Active rather than
   Hunting, so `CBLiveRivalPresent` does not read them as a Rival out hunting V.
3. **A pin for a place.** `MappinSystem.RegisterMappin(data, position)` exists on 2.31 and 2.5.
   The game's own drop point and fast travel systems register their pins again in `OnRestored`
   on every load, which they could not do if the save kept them. So a position pin does not
   outlive the session, and Cyberbane re-pins from the stored lead the same way. Within a session
   there is one pin, removed in every way a lead can end: it goes stale, is spent, is replaced,
   the Rival is forgotten, Start over, the switch, the map markers setting.
4. **The hunt working against it.** While waiting the body carries `CB_Lair`, not `CB_Rival`, so
   `CBHuntTick`, `CBHuntOrderTag`, `CBChaseGiveUp`, the retire sweep and the lanes cannot see it.
   `CBApplySpawnSetup` gives it no order at all. The boss bar waits for the fight.
5. **Nowhere to send them.** Sightings are positions a body Cyberbane placed actually stood on.
   They are filtered when noted and again when tipped (`CBLairPointUsable`: not at a job, not in
   a safe area, not in a police-free zone). Then they are checked once more at placement.
6. **No save may change shape.** Sightings live in the global service (`CBSighting`), where
   Codeware allows the layout to change. Every read is checked against the Rival in the loaded
   save: same playthrough, same id, same record, still Active or Hunting. Anything from a newer
   branch of the playthrough is dropped.

**Checks to run in game**

- Fast travel to the data term nearest a lead, and separately drive into the district at speed.
  Nobody may be placed until V is on foot and the world has settled.
- Walk up, leave, and come back. The body must be removed and placed again, never duplicated.
- Save with a lead pinned and load. Exactly one pin, no leftover body.
- Get a lead near a gig or story objective. Nobody may be placed inside it.
- Kill them silently, kill them loudly, knock them out, and let them run. Each must end the lead
  and count exactly once. Knocking them out must not make a second Rival of them.
- Confirm the pin shows with the Rival marker's icon. `Mappins.DefaultStaticMappin` with
  `GangWatchVariant` is what the code asks for; if the game draws a different icon, that is the
  line to change.

**A wider version: Rivals who live in the city**

The proposal: once somebody becomes a Rival they stay in the world, going about their business.
V can hunt or ambush them at any time, and when their turn comes they still ambush V as they do
now.

As a design this is where a nemesis system wants to end up, and it fits the mod. It cannot be
built literally, but it can be built as an illusion.

- **Literally, no.** The game only loads ground, collision and navmesh around V, and only runs
  NPCs near V. A Rival kept spawned on the far side of the city has nothing to stand on and
  nothing to walk on. Up to 15 of them (`RivalMaxActiveHardCap`) would also use almost all of the
  18-body ceiling (`MaxLiveSpawns`), leaving no room for the crews and apex squads they belong to.
  Keeping their bodies in the save (`persistSpawn`) breaks the rule that Cyberbane writes no
  entities to the save. That rule is part of why removing the mod makes no permanent change to the game.
- **As an illusion, yes.** Each Rival gets a place, saved as data only: a district and a point,
  which moves now and then on a timetable (home turf by day, somewhere else at night, gone to
  ground after an escape). Their body exists only while V is near that point. Stage 3 above
  already does this for one Rival, so this generalises it rather than replacing it. Rivals'
  ambushes on V stay exactly as they are.
- **What it adds to the risks above.** V would pass close to Rivals all the time, mostly while
  driving, so spawns triggered by V's arrival would become routine rather than occasional. The
  encounter code also assumes one Rival in the world at a time, through a single active Rival id.
  So:
  - only one Rival may be placed at a time;
  - placement happens on foot only;
  - anybody already hunting V always takes priority.
- **The first version is in 1.6.2.** A Rival is found where they were last seen, through a tip,
  and caught there. Free roaming (a place that moves on a timetable between sightings) can come
  later, once the waiting Rival has proved itself in game; it would reuse everything above and
  only change where the point comes from.

## Status after 1.5.0

The backlog below was written before any of it was built. This is where each item stands now.

**Done in 1.5.0:**

- 1 Random countdowns everywhere: crew and apex countdowns and every warning vary by up to 40
  and 35 percent.
- 2 Show countdowns setting: on by default; off shows "any moment", "soon", "before long" or
  "later".
- 3 Pacing setting (When they come): Timetable, Unpredictable or Reactive.
- 4 Heat that cools: a gang whose crew or apex squad loses V, or whose scout is put down, leaves
  V alone for its usual cooldown.
- 5 Graded threat on the HUD line (SCOUT, CREW, HEAVY CREW, APEX SQUAD, RIVAL), and crew
  warnings that say how many are coming.
- 6 Tracking stage: a broker text or an overheard line when somebody starts coming, and TRACKED
  on the HUD line in the last two minutes.
- 7 Scouts before crews, with a setting.
- 9 Suspicion moment: a sighting has to hold for two seconds, shown as SPOTTED.
- 10 Stealth counts: crouching, night and the hunting gang's colours shorten sight and hearing.
- 11 Search like guards: run to the area, walk it, varied give-up time.
- 12 Losing them on purpose: a safe area, or driving out of the searched district, doubles how
  fast they give up.
- 13 Loot that scales with level, and cash from crews.
- 14 Bounty for a wiped crew.
- 15 A cost for running: a little renown with that gang, and a text.
- 18 Difficulty scales crew size, spawn distance, hunter senses and warning length.
- 19 Immersive Shooting AI: detected through the Mod Settings list. It has no script module to
  test, so a copy that does not register settings is not seen.
- 21 The city talks about the hunt: the tracking notice is sometimes an overheard line.
- 22 Rivals who know their streets: more likely to come in the district they came from.
- 23 Time of day: Unpredictable pacing favours night for crews and Rivals, and day for apex
  squads. Hunters see less far at night. Weather is not used.
- 25 A clearer end: LOST THEM or THREAT ENDED on the HUD line for a few seconds.

**Not done, and why:**

- 8 Sound cues: the event names for an engine and a car door cannot be checked offline. A wrong
  name is silent, so this needs testing in game first.
- 16 Loot on the body: needs an in-game check that items given to a live spawned NPC show in
  their loot. Until then the inventory path stays.
- 17 Trophies: an NPC's weapon record may be an NPC-only variant that is broken in V's hands.
  Needs checking in game.
- 20 Fair start: the accuracy stat for NPCs cannot be confirmed offline, and a stat modifier
  that has to be removed later adds timing risk.
- 24 Car crews that suit the gang: needs per-gang vehicle records and seats beyond four. Out of
  scope for a stability release.

The HUD keeps a single status line throughout. The name on it is cut at 22 characters and the
whole line at 76, so it fits on every screen.

---

## Player feedback, point by point

### 1. "Better loot for the harder squads. Has to be incentive to not just running away."

**Status: implemented (1.4.8, adjusted in 1.5.0).**

- Loot scales with who you killed (`Spawn/Loot.reds`):
  - crew: sometimes ammo and common parts;
  - Rivals: better parts the higher their rank, one step better for a crew leader;
  - apex squad members: rare and epic parts with a chance of legendary ones.
- A small chance of an iconic weapon from apex members, rank 4 Rivals and crew leaders. It comes
  from a hand-picked list of weapons found by exploring, at most once each per session.
- Bounties: killing a Rival, or wiping out an apex squad, pays eddies from a gang at war with
  theirs.
- 1.5.0 puts loot straight into V's inventory rather than in a bag on the body (crash rule).

**Still missing:**

- Loot is only ammo, crafting parts and the occasional iconic. Nothing scales with V's level, and
  a crew of six pays almost nothing.
- Wiping out a crew pays no bounty; only Rivals and apex squads do.
- Running has no cost, except that a Rival you escape comes back promoted. Nothing happens when
  a crew or apex squad loses you.
- The iconic list has not been checked in game.

### 2. "I hate that it's on a timer, some randomization option would be nice."

**Status: partly implemented.**

What already varies:

- **The daily timetable.** The day is split into three stretches. Each kind of encounter gets
  windows inside them, in an order rolled daily, at a random moment inside each window
  (`Spawn/Schedule.reds`).
- **Reasons for crews (1.4.8).** A crew comes because V provoked the gang, hung around on their
  turf, hurt them recently, or they swore a vendetta. They no longer come just because a window
  opened (`CBCrewReason`, `Spawn/Queue.reds`).
- **Rival countdowns** carry random jitter (`CBRivalHuntTicksFor`).

What still runs like a clock:

- Once a crew is picked, its countdown is fixed by how much the gang hates V: 90 to 240 seconds,
  with no randomness (`CBLaneTicksFor`).
- An apex squad always takes 180 seconds to set off (`ApexQueueTicks`).
- Every warning lasts a fixed time: crew 45 seconds, Rival 40, apex 45.
- The Hub and the HUD show exact countdowns ("CREW IN 2:13", "ON THEIR WAY 0:45"). That is what
  teaches a player to keep a clock in their head.
- There is no setting for any of this.

### 3. "Spawning in randomly pulls me out of the immersion... Maybe a warning... how strong the threat is... On harder difficulties they kill you almost immediately with Much Better AI, Immersive Shooting."

**Status: mostly implemented (1.4.7 to 1.5.0). A few parts are missing.**

What exists:

- **Warnings before anyone sets off (1.4.8).**
  - The gang texts that a crew is coming and roughly where they think V is.
  - A Rival texts before coming.
  - The apex squad is named and announced.
  - An allied gang tips V off when its enemies send people.
- **A HUD line** while anyone is hunting V (1.4.8): who it is, and whether they are on their way,
  searching, have found V, or are losing the trail.
- **Nobody placed in view.** Spawn points are checked to be out of sight (1.4.7). Spawn distances
  went up in 1.4.8: crews 85 m, Rivals 80 m, apex squads 90 m, cars 140 m.
- **Difficulty.** On Hard and Very Hard the apex build adds less (`CBDifficultyStepDown`, 1.4.8).
  Default apex strength dropped from 70 to 55.
- **Much Better AI.** When it is installed, Cyberbane's own ability kits and morale breaks stand
  down.

What is missing:

- **No graded strength in the warning.** Only two cases come close: a vendetta crew says
  "everybody we have", and the apex warning says "four of ours". There is no clear scale such as
  a couple of scouts, a full crew, or their best.
- **No separate "you are being tracked" stage.** "On their way" is the closest. Nothing tells V
  that someone is looking for them before anyone has set off.
- **Difficulty only changes the apex build.** Crew size, spawn distance and how fast hunters
  find V are the same on every difficulty.
- **Immersive Shooting is not detected.** It makes every enemy far deadlier, and Cyberbane adds
  its build on top.
- **No grace on first contact.** A hunter who sees V fights at once with full accuracy, and on
  high difficulty with AI mods that can be the whole fight.

### 4. "Code them to be out of view and then make them search for you too, instead of always a guaranteed encounter. Cat and mouse."

**Status: implemented (1.4.8).**

`Spawn/Hunt.reds`:

- Hunters spawn out of sight and are given a rough tip of where V is. The tip is up to 45 m off,
  not V's real position.
- They go to that spot and search, and the search circle narrows over time.
- They find V by:
  - sight: line of sight within 35 m;
  - noise: within 70 m after a kill or a firefight;
  - already fighting: within 80 m.
- Lose them, stay clear long enough, and they give up. A Rival you lose texts you and comes back
  promoted.

**Still missing:**

- Once a hunter sees V, the game's own combat takes over at once. There is no "did I just see
  something" moment of the kind the game gives its own NPCs when they get suspicious.
- Searchers do not search like the game's own guards: no investigating, no calling out to each
  other, no flashlights at night.
- Nothing helps V hide beyond breaking line of sight and distance. Disguises, crowds, staying
  crouched and darkness make no difference to the hunt.
- How long they search before giving up is fixed (150 seconds after losing V).

---

## Backlog

Ordered roughly by value to the player. "Risk" is the crash risk under the 1.5.0 rules.

### Pacing without a clock

1. **Random countdowns everywhere.** Add jitter to crew and apex countdowns and to every warning
   length, the way Rivals already have it, for example plus or minus 40 percent.
   Risk: none (numbers only).
2. **A "Show countdowns" setting.** On by default for now, off for players who want it.
   - When off, the Hub and the HUD line use words instead of times: "soon", "closing in", "any
     minute".
   - The HUD line keeps its states (on their way, searching, have you) but drops the numbers.

   Risk: none (UI text).
3. **A pacing setting: Timetable, Unpredictable, or Reactive only.**
   - Timetable is today's behaviour.
   - Unpredictable replaces fixed windows with a chance per minute that rises with heat, so
     nothing can be counted.
   - Reactive only means nobody comes unless V gives them a reason (provocation, turf, vendetta).

   Risk: none (scheduling only).
4. **Heat that cools.** A hunt that loses V lowers that gang's urgency for a while, and so does
   staying out of their turf. Lying low then becomes a real choice, the way it is with the
   police. Risk: none.

### Warnings and threat

5. **Graded threat in every warning and on the HUD.** One clear scale used in the text, the Hub
   and the HUD line, for example SCOUTS, CREW, HEAVY CREW, APEX:
   - the crew warning says how many and in what ("two cars", "six of them on foot");
   - the Rival warning says their rank and traits in their own words.

   Risk: none (text).
6. **A tracking stage before "on their way".** When a lane picks a gang, V first gets a short,
   vague signal that someone is asking around. That could be a broker text, a line of overheard
   chatter, or the HUD line reading TRACKED. The warning and the departure come later. This is the
   "imminent spawn soon" cue the player asked for. Risk: none (text and HUD).
7. **A scout before the squad (optional).**
   - For crews, one scout on foot or on a bike comes first and searches for V.
   - If the scout spots V and lives for a short while, they call it in and the crew comes to the
     scout's last sighting.
   - If V deals with the scout quietly, the crew never learns where V is and the hunt cools.

   This gives passive play a real cat and mouse loop. Risk: low. It uses the existing spawn and
   hunt paths; the call-in is a lane decision, not an engine call.
8. **Sound cues before contact.** An engine and a door slam when a car crew gets out within
   earshot. A short phone buzz when the HUD line changes state. Uses the game's own sound events
   on the player. Risk: low (sounds played on the player only, as the apex horn already is).

### Cat and mouse

9. **A suspicion moment on first sight.** When a hunter first sees V, mark them "spotting" for a
   second or two before they commit, and give V a short HUD cue. Breaking line of sight in that
   window drops back to searching.
   - Needs care: the game's own perception may start combat anyway.
   - The safe version only changes what Cyberbane does: no orders, and no telling the others.

   Risk: low if it stays inside Cyberbane's own logic.
10. **Stealth counts.** Searchers use shorter sight and hearing ranges when V is crouched, in the
    dark, in a crowd, or wearing a disguise of their own gang. The concealment and disguise
    signals already exist. Risk: none (numbers in the hunt tick).
11. **Search like guards.** Searchers walk rather than run once they reach the area, spread out to
    different points (partly done), and give up in a randomized time instead of a fixed 150
    seconds. Risk: none (existing single move order).
12. **Losing them on purpose.** Getting into a vehicle and leaving the district, entering a safe
    area, or changing clothes while out of sight gives an extra chance that the hunt goes cold.
    Risk: none.

### Rewards and reasons to stay

13. **Loot that scales.** Scale crafting parts and eddies with V's level and the encounter's
    threat grade. Give crews a small eddie payout per member so a wiped crew is worth something.
    Risk: none (items to V's inventory, same path as now).
14. **A bounty for a wiped crew**, smaller than an apex bounty, paid by a rival gang that does not
    want V dead. Risk: none.
15. **A cost for running.** When a crew or apex squad loses V, the gang texts something
    dismissive and V loses a little renown with them. A Rival who gets away already promotes.
    Fighting and winning should be the better deal. Risk: none.
16. **Loot on the body instead of in the inventory (investigate first).** The safe version gives
    the items to the NPC when it spawns, not after it dies. The game then shows them in the
    body's loot like anything else they carried, and nothing is dropped.
    - It must be verified in game that giving items to a live spawned NPC is safe and shows up
      in their loot.
    - Until then, the inventory path stays.

    Risk: medium until verified.
17. **Trophies.** Killing a named Rival gives one item they used, taken from their character
    record's own weapon, so V has something to show for the nemesis they finally put down.
    Risk: low (a record lookup plus an inventory item).

### Difficulty and compatibility

18. **Difficulty scales more than the apex build.** On Hard and Very Hard, smaller crews, longer
    spawn distances, shorter hunter sight and hearing ranges, and a longer warning. The aim is
    that harder difficulty means harder fights, not instant deaths. Risk: none.
19. **Detect Immersive Shooting AI** the same way Much Better AI does, and scale Cyberbane's
    damage build down when it is installed. Risk: none (string match on installed mods, as for
    Much Better AI).
20. **A "fair start" option.** For the first few seconds after a hunter first sees V, they get
    reduced accuracy through the existing single stat-build pass, so the first volley is not the
    end of the fight. Risk: low (one stat modifier, removed after a short delay, through the same
    function that applies the build).

### Immersion

21. **The city talks about the hunt.** Overheard lines near V mention that a gang is looking for
    someone ("Maelstrom's been asking about a merc"). A broker texts with what they heard before
    the gang does. Risk: none (existing overheard and phone systems).
22. **Rivals who learn V's habits.** A Rival is more likely to be waiting near places V spends time
    (the district V is in most often, near the apartment, but never inside safe areas). Risk:
    none (choice of search area).
23. **Time of day and weather.** Crews more likely at night, scouts less effective in rain, apex
    squads favouring the day. Risk: none.
24. **Car crews that suit the gang.** Bikes for scouts, vans for big crews, and the gang's own cars
    where TweakDB has them. Risk: low (record choice only, same convoy path).
25. **A clearer end to a hunt.** When a hunt ends, a short line says how it ended: they lost you,
    you wiped them out, or they gave up for now. It closes the loop without the Hub. Risk: none.

---

## Already done for the same goals

These answer the same feedback and are in the code. They are listed so they are not rebuilt:

- **Warnings first, then departure.** The crew, Rival and apex lanes all warn first (1.4.8).
- **Searching before fighting.** Hunt states and last known position (1.4.8).
- **Turf lookouts.** Hanging around on hostile turf gets V noticed and provokes that gang
  (1.4.8).
- **Escalation.** An apex squad is the answer to a beaten crew, never a timer (1.4.8).
- **Arrivals on Cyberbane's own terms.** Out-of-sight placement, the convoy, and crews that only
  get out once the car has slowed (1.4.7 to 1.5.0).
- **Rivals who talk.** They text when they find V, escape, or are lost (1.4.8).
- **Fairer numbers.** Difficulty step-down and a lower default apex strength (1.4.8).

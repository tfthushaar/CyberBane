# Cyberbane improvements

A working list of what players have asked for, what the mod already does about it, and what is
left.

The released version is 1.7.1. The "Requests after 1.7.0", "Requests after 1.6.8" and "Requests after 1.6.4" sections at the top are the current ones;
everything below it was written against 1.5.0 and is kept for the reasoning rather than as a
description of today's code. The original point-by-point section and the backlog describe the mod
as it was *before* that backlog was built, and each entry's own status line says what has been
done since - so read the status lines, not the surrounding prose, for what is true now.

Every idea here has to follow the crash rules that came out of 1.5.0, which are summarised here
because the file holding them in full (`STATUS.md`) is a local developer note and is not part of
this repository: no police system calls, one AI order per NPC, no entity work inside attach
events, removals only through `CBDeleteTaggedSafe`, nothing removed in V's sight, nothing touching
an NPC that has left the world, behaviour-only ability kits, no runtime appearance changes, no
loot drops from corpses, and UI as data rather than injected widgets.

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
(`autoDriveSystem.script`). The pin is now `HuntForPsychoVariant`: no 2.31 or 2.5 script owns it, the
tooltip is null-safe with no journal entry, it has its own icon, and CET mods mark spawned hostiles
with exactly this `Mappins.DefaultStaticMappin` pairing. It is not drawn on the minimap until it is
tracked (`minimap.script` has no plain-position entry for it), which the readme says.

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

**Status: open, waiting on a log.** The reporter went back to 1.6.4. A red error at launch is a
redscript compile failure. What was checked, all clean: every mod-internal call by name, argument
count and value type; every `this.` field and literal; every engine name against the official 2.31 and
2.5 scripts with Codeware 1.20.6 and 1.21.2 (and back to 2.2 for anything new since 1.6.4); engine
call argument counts (3,172 call/version pairs); 244 game enum references; collisions of the mod's
824 globals and 56 added members with vanilla and Codeware; and the forms new in 1.7.0 (array
literals in `for`, `return` and arguments, a string inside an interpolation) against redscript
0.5.31's own parser, typechecker and desugaring. Nothing was removed from `src` since 1.6.4, so an
install over the top leaves no stale file. What is left is outside the files: another mod in the
same compile, or a framework build that does not match the patch. `r6\logs\redscript_rCURRENT.log`
settles it.

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

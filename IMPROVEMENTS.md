# Cyberbane improvements

A working list of what players have asked for, what the mod already does about it, and what is
left. Checked against the code on the development branch at 1.5.0.

Players on Nexus are on 1.4.7. Everything marked "1.4.8" or "1.5.0" below is in the code but has
not been released yet, so the player who wrote this feedback has not seen any of it. The
point-by-point section and the backlog describe the code as it was before the backlog was built;
the status section says what has been done since.

Every idea here has to follow the crash rules in STATUS.md (1.5.0 notes): no police system
calls, one AI order per NPC, no entity work inside attach events, removals only through
`CBDeleteTaggedSafe`, behaviour-only ability kits, no runtime appearance changes, no loot drops
from corpses.

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
- The iconic list has not been checked in game (see STATUS.md).

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

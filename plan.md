# Cyberbane plan: the road to 2.5.0

Status: **The road is built (2026-11-18). Done: 2.3.1 to 2.5.0, all released, with a bug pass over every system
inside 2.4.2 and the final pass inside 2.5.0, which also brought a crew of my own, the whole Hub rebuilt with
pictures, the map remembering, and the last two upgrades to Rivals' places. Next: I play it all.** I wrote this on
2026-11-18 from IMPROVEMENTS.md after the 2.3.0 prune, and it replaces my old plan (the road to 2.0.0, all built).
The newest sections (where it stands, what I learnt from Night City Alive, the Hub drawn) are a draft until I have
been through them again.

2.3.0 is out (the registry crash fixed at the source, IMPROVEMENTS.md pruned). Everything below builds on it, one
release per phase, and ends at **2.5.0, the final form**: the last features in, a crew of my own, then a
comprehensive bug pass over every file.

**[n]** is item n in IMPROVEMENTS.md. Sizes as there: **S** small, **M** a new state machine on existing pieces,
**L** new spawns or several systems at once. **Verify** means an engine call is probed on 2.5 and 2.31 before
anything is built on it.

## Where it stands (2026-11-18)

**Completed and pushed** (each compiled on 2.5 and 2.31 and with every installed script mod, audits clean, an update
rehearsal from the release before; none played yet):

| Version | Commit | What it is |
|---|---|---|
| 2.3.1 | 016d612 | The street reads V: witnesses who tell the gang [2], night, rain and blood [3]-[5], district tempers [6], places that remember [7], keep watch [8], the braindance [9], wannabes [1], lifepath head start [72], known car and gun [73] [74], officers who see through disguises [78]; the line library [L1] and the street's lines [L2]; `CBStreetBook`; settings headings Turf and Word on the street with hidden sub-options |
| 2.3.2 | be84fea | A code for each gang [10]-[19], [21], gang voices [L3], gangs adapt [40] (`CBLedgerBook`), mixed crews [U1], the sergeant [U2], builds that read the fight [U3], apex teamwork [U4], surrender made default [E1] |
| 2.3.3 | 2d192bf | The event engine with the sit-down moved onto it unchanged; word of what's coming [32]; funerals, celebrations, initiations, recruiting [22]-[25]; arms deals [28]; rackets [29] |
| 2.3.4 | 7712243 | Executions [27], front lines [30], hunts [26], power struggles [31] (`CBGangLifeBook`) |
| 2.4.0 | 06854fe | War chest and manpower [34] [35], back a gang [33], set gangs on each other [70], a common enemy [36], V's own streets [37], peace with terms and the Claws' protection [U6] [11], turf patrols made sturdy (still experimental) [U5] [E3]; `CBWarBook` |
| 2.4.1 | 9fde2de | A fair first volley [44], lie low [41], the metro said [42], haunts [46] and hunters using what they know [U8], scouts worth catching with the bribe [U7] [68], lookouts in the crowd [50]; `CBHuntBook`; a Being hunted heading. [45] and [89] were found already built |
| 2.4.2 | ba60842, cb2eacb | Trackers [49], open season [48], lying in wait made default [E2] with V's road [47] and the Wraiths' road [18], the Claws' assassin [11]; then the fixes from player reports (Talk on F, nobody stopping until I talk to them, They Will Remember's hostility and disguises followed, its panel kept off the Hub) and from the bug pass over every file (apex squads at full health, freeze reputation freezing everything, gang chairs, street events, skills in V's menace) |
| 2.4.3 | 37687a2 | A price on V's head and the hunters' ladder [39], the corporations hire killers [20], corporate interest [88]; rival gangers clash on contested streets [N1]; the web of gangs on the Hub [H1]. [N2] dropped (the game's own gunfire already does it). A fix: Rivals came no more with crews off, with They Will Remember, or after peace with their gang |
| 2.4.4 | 9420e11 | The facedown [53] [54] and a Rival on their feet [64], humiliation [55], back from the dead [56], Rivals at war [57] and bonds [58], trophies [60], where they ended up [61], places with meaning [62], last words [63], Rival chrome [U9], places lived in [U10], tactics by kind [U11], Rivals' lines [L4], "Nobody kills you but me" made default [E4], the Rivals tree [H2]; `CBRivalBook`. A fix: how V fights was misread from 1.3.2 on |
| 2.4.5 | f15be9e | Run with a crew [65] on the game's own follower role, one of theirs [66], ransom [67], feed the street a lie [69], informants with a life [U12], the sergeant's parley [U2] |
| 2.4.6 | 8979f48 | Voices [79], panic in the dark [80], the screamsheet [81], the legend told [82], the morning brief [83], a Rival's story [84], Street Cred follows the legend [87], presets with a shape [90], events for other mods [91], phone threads with answers [U13], the scanner tells the story [U14], titles for what's new [U15], and every line since 2.4.3 rewritten to draw on what the street knows [L5]. Not built: the map remembering [85] and Ambient Factions [92] |
| 2.5.0 | b2c8659, 56c0c7b, db1eeda, 36ba068, 34ebfb2, 6e0a8d5, a32a24b, 917777f | A crew of my own [C1]-[C10] (`CBCrewBook`, the Betrayer); the Hub rebuilt with pictures: the map, the crew, the web and the tree first, tiles, cards, segmented bars, text that fits; the map remembers [85] (`CBMapBook`), with TweakXL a CYBERBANE box in the map's custom filters; a lookout who gets away moves a Rival [U10] and a ripperdoc as a lead [U9]; the final pass and a second one. Ambient Factions [92] dropped |

**In progress:** nothing. The road ends at 2.5.0.

**Left** (renumbered: the hunt group shipped in three, so everything after it moved up):

Nothing. What was not built, and why, is in IMPROVEMENTS.md.

**Moved or dropped along the way:** [43] sound before contact (no door or engine sound event confirmed); [76] [77]
(I do not have Wannabe Edgerunner or Dark Future installed, so there was nothing to probe); tribute haggled by text (folded into [U13]);
[U1]'s car seats keep one record. Each is noted in its release's section and in IMPROVEMENTS.md.

**Next:** I play the road, 2.3.1 to 2.5.0; then the rest of the road to 2.5.0, built straight through; I play the whole of it at the
end instead of stopping after 2.4.2. The bug pass over every system came first, with the 2.5.0 pass's method, and what
it found went out inside 2.4.2. [H1] the web went out in 2.4.3 and draws the 2.4.0 systems (wars, truces, backing,
standing), so it will help me check them when I play.

## Learnt from Night City Alive (2026-11-18)

I read it in full (NCA Lite, Standard Density 2.3.3: four scripts and the TweakXL files) to learn from it; I have
not run it, and nothing of it is copied into Cyberbane. Credit to its author for the ideas. What it is: a density
and liveliness mod, built mostly from TweakDB edits.

**How it works:**
- **Gangs fight gangs** by editing the game's attitude groups (TweakXL `attitude.yml`): the Wraiths against the
  Aldecaldos, 6th Street, the Scavengers, Maelstrom and the Valentinos; the Claws against Maelstrom and the
  Valentinos; the police against the gangs. Every member of those groups, anywhere, then fights on sight.
- **A louder street** by raising the "aggressive" weight of the game's stims (gunshots, weapons drawn, bumps) and
  letting crowd members process more of them (wraps on `ReactionManagerComponent`: `HandleStimEvent`,
  `ShouldStimBeProcessedByCrowd`, `ShouldTriggerAggressiveCrowdNPCCombat`), so some civilians fight back at close
  range; police investigate gunshots that are not V's; a vehicle hit broadcasts the game's crime-witness stim.
- **Gangs in traffic** by adding gang members as random passengers per car (TweakXL) and, once, at the world's
  load, editing the crowd registry of the always-loaded sector through Codeware's `Resource/Load` callback: police
  cars replaced in City Center, gang bikes added by district. Zero cost while playing.
- Its gates are the ones Cyberbane uses: the `NoCombat` status tag, the safe-zone state, the safe-area manager,
  and a navmesh check.

**What fits Cyberbane, rebuilt my way (scripts only, inside the crash rules):**
- **[N1] Rival gangers clash on contested streets** (2.4.3). In a contested district (a challenger in the turf
  book, or two gangs at war both on the streets V is in), now and then the world's own gangers of the two gangs
  meet and fight: a pair or two set hostile to each other through their attitude agents (the way 2.3.4's fights
  already are), tracked, and put back when it is over or V has gone. The winner's side moves the turf book like a
  front line. Never a story NPC (the Safety Gate), never at a job, never in a safe area or with `NoCombat` on V,
  never between gangs in a truce [36], never a switched-off faction; one clash at a time, minutes apart.
  **Optimisation:** no new scan. The Director's walk already reads each nearby person's faction and position; it
  keeps the last few gangers of each warring side it saw in a small buffer, and the clash is chosen from that.
- **[N2] The street hears a gang fight** (2.4.3, verify first). People near any gang fight (ours or [N1]) flee;
  the game's own gunfire stims probably already do this, so it is checked before anything is built, and dropped if
  they do.

**What does not fit, and why:**
- Attitude groups edited for good (TweakDB) and police against gangs (the prevention system): both outside the rules.
  The game also lets a script change two groups' relation (`AttitudeSystem.SetAttitudeRelation`), but that is
  world-wide, every member everywhere including quest scenes, so it is not used; pairwise, scoped and reverted is.
- Gangs in traffic by turf: needs passenger records (TweakDB) or editing streamed world data with custom records,
  and would not follow turf that changes after the world has loaded.
- A crowd that fights back: a wrap on the game's reaction system's hot path, the one place Cyberbane keeps off
  (it touches only the talk partner's stim filter). With both mods installed the player gets NCA's crowd and
  Cyberbane's fear and talk together; they compile together cleanly.

**Better approaches for what is already built:**
- **Sit-downs and arms deals hold together whatever the game's data says.** Neither sets the two gangs' people
  neutral to each other. Where the game's attitudes already make them enemies (the 2.2.0 note saw sit-down sides
  fighting each other), and far more often with NCA installed (it makes the Valentinos and 6th Street, the Claws
  and Maelstrom, and others enemies), they can shoot each other on appearing, and a sit-down whose people kill each
  other can never be crashed by V (`CBTakenOutByV` counts only V's work). Better: at placement, set the two sides
  neutral to each other pairwise (the inverse of 2.3.4's fight start, same helper); when V crashes it, or the first
  shot lands, let them be. **Into the bug pass.**
- **Arms deal partners** were picked from Cyberbane's own rival lists only. Better: also ask the game
  (`AttitudeSystem.GetAttitudeRelation` of the two attitude groups, a read) and prefer a partner the game does not
  make hostile, with the neutral setting above as the safety net. **Into the bug pass.**
- **Fights between gangs (2.3.4)** set pairwise attitudes; that stays the right way (scoped). Where the game already
  makes the two groups enemies the start step changes nothing, which is harmless.
- **Witnesses (2.3.1)** are tracked by Cyberbane and never use the game's crime-witness stim, which calls the
  police. NCA uses that stim; ours is the right choice for the rules.
- **Turf patrols** spawn people (live cap, cost per tick); NCA's traffic presence is free but needs TweakDB. Ours
  stays, experimental.
- **Optimisation:** NCA does its heavy work once at load and early-outs in every wrap. Cyberbane's static tables
  (tempers, codes, voices) are already switch functions with no allocation; the Director's walk is capped and
  rotates. The lesson for 2.5.0's performance check: measure with NCA's density, where the registry fills fastest,
  and make sure every per-tick reader added since 2.3.0 returns on its first line when idle (most do; the pass
  checks every one).

**Compatibility:** Cyberbane and NCA compile together (checked 2026-11-18). No method is wrapped by both (Cyberbane wraps
`ReactionManagerComponent.OnEventReceived`, NCA others). NCA's `CanTriggerAlertedFromHostileStim` replaces rather
than wraps, which matters only to a mod wrapping that method. Added to 2.5.0's compatibility list.

## The Hub, drawn (added 2026-11-18)

Two pictures in the Hub, in the game's own look (the Hub's colours, fonts and boxes): how the gangs stand with
each other and with V, and who is who among each gang's Rivals. Both read only the books that already exist; neither
adds saved data and neither needs a new tab.

**[H1] The web of gangs** (Factions page, 2.4.3). A button on the page switches between the list and the web; the
Hub remembers which for the session.
- **V in the middle, the 11 gangs on a ring** around, each placed roughly where it lives (Maelstrom and the Claws at
  the top for Watson and Westbrook, the Valentinos and 6th Street lower middle for Heywood and Santo Domingo, the
  Animals, Voodoo Boys and Barghest lower left for Pacifica and Dogtown, the Wraiths and Aldecaldos at the bottom
  for the Badlands), so the ring reads as a rough Night City and stays where the player learnt it. The
  corporations, NCPD and MaxTac sit in a small row beneath, with V's lines only.
- **V's line to each gang**, drawn by posture: thick green Allied, green Friendly, thin grey Neutral, amber Hostile,
  thick red Vendetta. On the line, a word for what is live: OPEN SEASON, TRACKER, PROTECTED, BACKED, PEACE PAID.
- **Lines between gangs**: red for at war now (a challenger in the turf book, a front line, both sides fighting),
  dim red for the standing feud (the profile's enemies), cyan for a truce [36], amber with an arrow where V set one
  on the other [70], and a mark on the side V backs [33]. A clash [N1] lights its line for a day.
- **Each gang's box**: name, posture word and standing, a strength bar (manpower) and a chest bar [34] [35], streets
  held, the leader's name. Tinted by posture.
- **Picking a gang** lights its lines and dims the rest to a quarter. The detail area below says it in words ("At war
  with the Valentinos over Heywood, losing. Truce with Maelstrom, 2 days left. Friendly to you, 64."), and the
  list's actions act on it (pay off, back, peace terms). The mouse picks the box under it; keys and pad go round
  the ring.
- **Not cluttered**: only live relations at full strength, standing feuds dim, a one-line legend along the bottom.

**[H2] The Rivals tree** (Rivals page, 2.4.4, with the bonds and feuds it draws). The same switch: list or tree.
- **One gang at a time**: gang chips across the top in their posture colour, left and right to change; "All" shows
  a compact row of small trees, one per gang with Rivals.
- **A flow chart, top down**: the leader's box, lines down to the three lieutenant slots (the hierarchy that
  already exists: `CBFactionState` leader and lt1 to lt3), then the gang's other Rivals in a row beneath as the
  bench. An empty slot says EMPTY and names who steps up next (`CBHierarchyScore`, the order `CBHierarchyFill`
  already uses).
- **Each box**: name and title, level, state (Hunting, Dormant, Debtor, lying low), two trait tags, chrome [U9],
  and V's record with them (met, beaten, escaped). Marks for a fresh promotion and for one hunting V now.
- **Side links**: bonds [58] in cyan between boxes, feuds between Rivals [57] in red, a line to V's own Rival
  [59]; V's nemesis (the most meetings) gets a red line up to a small V marker in the corner.
- **The fallen**: a strip along the bottom, greyed, with how each ended and by whose hand; one who came back [56]
  is marked.
- Picking a box shows that Rival's page (the existing detail) below, and its actions act on them.

**How it is drawn** (the drawing kit, built with [H1]):
- Inside the Hub's own canvas, the way the Hub already builds its boxes; nothing is put into the game's menus, so
  crash rule 7 (the game's screens get data, never injected widgets) stands.
- Boxes are the Hub's existing clickable box (`NewBox` with its band and text). A straight line is a thin
  rectangle with its pivot at one end (`SetRenderTransformPivot`), sized to the distance and turned with
  `SetRotation`; both are base-game calls, present in the 2.31 and 2.5 sources (checked). The tree's lines are
  horizontal and vertical, so they need no turning. "Dim" is lower opacity, never dashes, so one line stays one
  rectangle.
- **Optimisation**: a pool built once when the Hub opens (about 64 lines and 20 boxes), hidden until used, like the
  row pool; filled from the books when the page opens, when something is picked, and when an action changes
  something. Nothing per frame, no animation beyond the existing hover. Positions are fixed tables (switch
  functions) scaled with the Hub's scale; text goes through the Hub's fit and trim helpers.
- **Verify first**: a turned rectangle draws cleanly at the Hub's smallest and largest scale and takes no clicks
  (`SetInteractive(false)`). If it looks rough at odd angles, the web's lines go to elbows like the tree's.

**Settings**: none; the switch lives on each page. One option under Messages and HUD (open as pictures or lists) only
if my playtest shows it is needed.

**Done when**: every relation in the books shows on the web and says the same in words as the list; the tree matches
the hierarchy after a promotion, a slaying and a return; both work with mouse, keys and pad, on both patches, at
the smallest and largest Hub scale; opening the Hub costs no more than it does now.

## The shape of it

Nine groups of ideas that share code, built and tested together, in the order of dependency, shipped as eight
releases and a final one (now eleven, since gang life and the hunt each shipped in parts). Group 0 is plumbing only and changes nothing a player sees, so it ships inside the
first release that uses it.

| Version | Group | Items | Size | Status |
|---|---|---|---|---|
| **2.3.1** | 1 The street reads V, and talks like it | [1]-[9], [68]\*, [72]-[74], [78]; [L1], [L2]; `CBStreetBook` | M-L | done |
| **2.3.2** | 2 A code for each gang | [10]-[19], [21], [40]; [U1]-[U4]; [L3]; [E1]; `CBLedgerBook` | M-L | done |
| **2.3.3** | 3 Gang life, first half | [22]-[25], [28], [29], [32]; the event engine | L | done |
| **2.3.4** | 3 Gang life, second half | [26], [27], [30], [31]; `CBGangLifeBook` | M-L | done |
| **2.4.0** | 4 Turf, money and war | [33]-[37], [70]; [U5], [U6]; [E3]; `CBWarBook` | M-L | done |
| **2.4.1** | 5 Being hunted, first part | [41], [42], [44], [46], [50]; [U7], [U8]; [68]; `CBHuntBook` | M | done |
| **2.4.2** | 5 Being hunted, second part | [47]-[49]; [E2]; [11], [18] | M | done |
| **2.4.3** | 5 Being hunted, third part, and the war in the street | [39], [88], [20]; [N1], [N2]; [H1] and the drawing kit | L | done |
| **2.4.4** | 6 Rivals | [53]-[64]; [U9]-[U11]; [L4]; [E4]; [H2]; `CBRivalBook` | M-L | done |
| **2.4.5** | 7 Talk and allies | [65]-[67], [69]; [U12]; [U2]'s parley | M-L | done |
| **2.4.6** | 8 Telling it | [79]-[85], [87], [90]-[92]; [U13]-[U15]; [L5]; voices, mod events | M | done |
| **2.5.0** | 9 A crew of my own, then the final form | [C1]-[C10]; `CBCrewBook`; the comprehensive bug pass, optimisation, [U16], [L6], every default confirmed, settings and README for good | L | done |

\* [68] moved from 2.3.1 to 2.4.1. Not built: [43], [76], [77] (see "Where it stands").

Why this order: the event engine (0) carries every gang event (3) and some Rival moments (6). Gang codes (2)
decide how each gang behaves in events, wars and hunts (3-5). The war chest and front lines (4) feed bounties
and open season (5). Allies (7) reuse the Rival follower (6). Telling it (8) reads the History every other
group writes, so it goes last, when there is something to tell. The crew (9) needs nearly everything before it:
the spared Rivals and the Rival follower (6), the frightened ganger and the friendly gang's followers (7), the
phone deals, the arrivals and the hunt, so it comes last of all, in 2.5.0.

**Why the numbers.** 2.3.x is the street and the gangs: how the city sees V, what each gang is, and what it does
with its days. 2.4.0 opens the war (gangs with money, manpower and sides to take), which changes how the game is
played, so it gets the minor number; 2.4.x builds on it (hunted, Rivals, allies, the telling). 2.5.0 adds one
idea, the crew, which is where the Rivals and allies releases were always heading, and then it is the whole mod
made right.

**Every release** is its own zip from `build.ps1 -Version x.y.z`, its own CHANGELOG entry, pushed to main when
its release checks pass (below); I put it on Nexus myself. A release is never stretched to take the next
group's work: if a group runs long it ships in two (for example 2.4.1 and 2.4.1's second half as 2.4.2), and the
versions after it move up one.

## Upgrades to what exists

Alongside the new ideas, the systems Cyberbane already has get deeper. Each upgrade ships in the release whose
new work it shares code with, so nothing is built twice. **[Un]** names an upgrade; its detail is in its
release's section. What each system does today was read from the code for this plan.

| Upgrade | Today | After | Release |
|---|---|---|---|
| **[U1] Crews that aren't clones** | Every crew member is spawned from one record, the last member of the gang V put down | Crews mixed from the gang's captured role records and its own roster, by grade: a heavy, shooters, a blade, sometimes a netrunner | 2.3.2 |
| **[U2] A crew sergeant** | A crew is a group of equals | One member leads: named on the HUD line, holds the crew together; when they fall the rest's nerve drops; can be parleyed with | 2.3.2 |
| **[U3] Scaling that reads the fight** | Enemies are built from V's menace (level, Street Cred, skills) times a strength slider, with random apex traits | The same build, also weighed by district danger, how strong the gang is right now, its code [10]-[19], how V fights [40], and difficulty [89]; bounded both ways, and said in words on the Hub ("they are sending their heaviest for you") | 2.3.2 |
| **[U4] Apex squads that work as a team** | Four chairs with their own kits, fighting side by side | The netrunner tells the squad where V is, the tank holds a line, the blade flanks; a squad that loses V searches as one; each gang's squad has a record against V ("the Iron Saints have beaten you twice") | 2.3.2 |
| **[U5] Turf patrols, made robust** | Experimental and off: a few of the new holders, all one person, walk towards wherever V is, in a district they took | Still experimental and off by default, but solid: a real beat round the corner they hold, mixed people [U1], they see through a mask the way everyone else does, turn together when one is hurt, leave cleanly from every state, cost the war chest, clash on front lines [30], can be bribed [68] or followed back to a racket [29] | 2.4.0 |
| **[U6] Tribute and peace with terms** | Tribute arrives; peace is one price | Tribute can be haggled by text; peace can be paid in eddies, a Rival's whereabouts, a district handed back, or a favour done | 2.4.0 |
| **[U7] Scouts worth catching** | One scout spawns near V; six seconds of sight calls the crew; put down first, the gang cools off | The scout searches V's district the way hunters do; each gang sends its own kind (a Claw on a bike, a Maelstrom chromed spotter, a Voodoo Boys netrunner who pings rather than walks); calling it in takes a moment you can stop; a scout can be grabbed, bribed [68] or fed a lie [69]; one who sees V twice and gets away can come back a Rival | 2.4.1 |
| **[U8] Hunters who use what they know** | Hunters search a narrowing circle round where V was last seen | They also check V's known car [73] and haunts [46], come towards V's gunfire, and use a lookout's report [50] | 2.4.1 |
| **[U9] Rival chrome** | Climbing adds a rank and a random trait; two traits grant a kit; nothing shows | Every climb (a rank, an escape, being spared, killing V) can come with an implant, chosen against how V hurt them: shot, subdermal armour; cut, a dermal plating; hacked, a firewall; outrun, reinforced tendons. Implants are stats and the game's own behaviour abilities only. Each one is on their Rival page and in the scanner, the street hears about the ripperdoc visit, and a ripperdoc can be where V catches them | 2.4.4 |
| **[U10] Places that are lived in** | A Rival waits at their place with up to three bodyguards standing still | The guards walk a short beat, the Rival keeps hours (home by night, out by day), and a guard who spots V and gets away moves them to a second place | 2.4.4 |
| **[U11] Rival tactics by kind** | All Rivals fight with the game's AI for their record, built up by grade | A Rival fights the way they were made: a Survivor keeps distance, a Killer pushes, an Avenger goes for V alone, a Broken one is reckless; through `Spawn/Tactics.reds` | 2.4.4 |
| **[U12] Informants with a life** | An informant texts two or three tips, then calls it square | A page of who owes V and how many tips are left; an informant's gang can find out, and saving them is a hunt [26] | 2.4.5 |
| **[U13] Phone threads with answers** | A gang's thread can be answered pay or refuse | Also threaten, insult or stall, each moving standing or the clock; a Rival's thread can be answered | 2.4.6 |
| **[U14] The scanner tells the story** | A Rival's name and title in the scanner | Also their chrome [U9], a crew's sergeant [U2], a scout's job [U7], and how this gang sees V | 2.4.6 |
| **[U15] Titles for what's new** | Titles from kills, deeds and districts, each with a small perk | Titles for the new systems (war, hunters' ladder, gang life, chrome taken) and one per gang | 2.4.6 |
| **[U16] Every default confirmed** | Four features are off and experimental | Three made default in their releases ([E1], [E2], [E4]); turf patrols stay experimental ([E3]); at 2.5.0 every default is played and confirmed | 2.5.0 |

**Rules the upgrades keep.** Rival chrome never uses Kerenzikov, Sandevistan, optical camo, stims, cooling or
quickhacks beyond the netrunner rule (crash rule 5), and never changes how anybody looks: it is stats, the game's
behaviour abilities and words. Implants are derived from what the Rival already has (rank, escapes, mercies,
kills, scars, traits, id), so nothing new is saved on `CBRival`. Mixed crews still spawn people only (`CBRecordIsPerson`),
never a story character (`CBRecordUnfitTemplate`), and keep one order each. Scaling stays inside the existing
ceilings (`ApexHealthMultCeiling` and the rest) and the strength sliders.

---

## Lines that sound like Night City

Everything Cyberbane says (about 300 places: texts, threads, overheard lines, talk lines and answers, refusals,
announcements, HUD notes) is rewritten to sound like the person saying it, in the release that already touches
those lines, so each is written once and in context.

| Lines | What changes | Release |
|---|---|---|
| **[L1] The line library** | One picker for every line: who speaks (a passer-by, a ganger of a given gang, a broker, a Rival, V), several variants per moment, no repeats (the picker remembers what it said), and context it can draw on: the hour, the weather, the district and its temper, what V just did, V's title, lifepath and standing, a place that remembers [7]. Lines are written whole for each speaker, never words swapped into a template. | 2.3.1 |
| **[L2] The street's lines** | The crowd, overheard lines, passers-by in talk, the grapevine and the rumours, rewritten through the library, naming real things from the History and real places. | 2.3.1 |
| **[L3] Each gang's voice** | Every gang's texts, warnings, threats, refusals and talk answers in its own voice, from its code: Valentinos' family and honour, the Claws' face and business, Maelstrom's chrome, the Animals' strength, the Voodoo Boys' data and the Net, 6th Street's veterans, the Mox looking after their own, the Scavengers, the Wraiths, the Aldecaldos' family, Barghest's soldiers. | 2.3.2 |
| **[L4] Rivals' lines** | Catchphrases grown into a voice per Rival: the announcement, taunts mid-fight, texts that remember their history with V (scars, escapes, kin), last words [63]. | 2.4.4 |
| **[L5] Texts, threads and notes** | Brokers', contacts' and gangs' phone threads; the HUD's "Cyberbane:" notes said in the world wherever they can be (a hint about settings stays a hint). | 2.4.6 |
| **[L6] Every line read once more** | Consistency, length, repeats, nothing out of character, in the 2.5.0 pass. | 2.5.0 |

**Rules for lines.** Nobody the game wrote speaks for Cyberbane. Text only, in the game's subtitle and phone
looks (no new audio; the voiced moments are [79], with the game's own voice lines). Each new feature from 2.3.1
on writes its lines through the library from the start.

## The experimental features made default

Four features ship today off and marked experimental. Three are made concrete (clear to see, with an ending and a
use) and **on by default**, in the release they belong to. Turf patrols stay experimental and off by default, and
are made robust instead. New features in this plan also ship **on by default**,
each with its switch; where one is heavy it starts at a gentle frequency instead of off.

| Feature | What makes it concrete | Release |
|---|---|---|
| **[E1] Surrender** | Who gives up comes from the gang codes (Barghest never, the Animals rarely, the Mox often); a clear hands-up beat in the subtitles and on the scanner; three endings (let go, grab and question, shoot, each with its consequence); later a use in ransom [67]. | 2.3.2 |
| **[E2] Gangs lie in wait** (car ambushes) | Built into waiting on V's road [47] and V's haunts [46]: the ambush is set where V is known to go, warned of when a lookout or informant could know, and pays off as a fight with an exit. | 2.4.2 |
| **[E3] Turf patrols** (stays experimental, off by default) | [U5], made robust: see 2.4.0. | 2.4.0 |
| **[E4] Nobody kills you but me** | With the facedown [53] and Rival chrome [U9]: the Rival arrives with an announcement, fights at V's side, and leaves with a facedown line that sets up their next fight. | 2.4.4 |

At 2.5.0 every default is played again in the comprehensive pass and confirmed. Turf patrols are the one thing
left marked experimental, by choice.

---

## Mod Settings, tidy and easy to read

Today: 135 options under 14 headings on one long Mod Settings page, every option shown all the time, some
headings mixing unrelated things ("A living street" holds bagmen, sit-downs, surrender and a Rival helping V),
and the plan adds about forty more. So the layout is settled now, in 2.3.1, and every later release puts its
switches straight into their final place. The tidying is done a heading at a time, in the release that already
touches that heading, as part of its push; 2.5.0 only checks it.

**How it is made easy:**
- **Hidden until it matters.** Every option that only matters while a switch is on is hidden while that switch
  is off (`ModSettings.dependency`, found in Mod Settings 0.2.21 and the current release, and used by New Game
  Plus; an older Mod Settings ignores it and shows everything, as today). A player who turns Rivals off sees one
  line where there were twelve.
- **Each heading is one idea**, named in the player's words, with its main switch first, then what is most often
  changed, and anything experimental last, marked "(experimental)".
- **Labels say what the player will see** ("Witnesses tell the gang"), never a system's name. **Descriptions** are one
  or two sentences: what happens in play, then what turning it up, down or off does. Units are always said
  (real minutes, in-game days, per cent).
- **No heading over 15 options.** Ideas that are one thing to a player share one switch (funerals, celebrations,
  initiations and recruitment are "Gatherings"; V's car and V's gun are "Known by your car and gun"; keeping watch
  and bribing a lookout are "Pay the street").
- **Nobody's values move.** Mod Settings stores values by class and field name (`user.ini`, `[CyberbaneSettings]`),
  so moving an option to another heading or renaming its label keeps every player's choice. Field names never
  change.

**The final layout** (new options in brackets, by release):

| # | Heading | What is on it |
|---|---|---|
| 1 | General | Enabled, preset, how messages arrive, the HUD line, map markers |
| 2 | How often they come | Pacing, the gap, Rivals, crews and apex squads per day, the two frequency sliders |
| 3 | Crews and apex squads | Crews (main switch), Vendetta crews and their size, scouts, apex squads, apex strength and traits, loot; [fair first volley: 2.4.1; sound before contact: not built] |
| 4 | Being hunted | Arrivals by car, cars while on foot, cars per arrival, gangs lie in wait (default from 2.4.2), bounties; [lookouts, lie low, lose them on the metro, haunts: 2.4.1; trackers, open season, road: 2.4.2; the hunters' ladder: 2.4.3] |
| 5 | Rivals | Rivals (main switch), how many, strength, team-ups and their size, hideouts, deaths remembered, flaws, psycho breaks, cyberpsycho Rivals; [Rival chrome: 2.4.4] |
| 6 | Rivals and you | Send word, the mercy choice, informants, "Nobody kills you but me" (default from 2.4.4); [the facedown, back from the dead, Rivals at war, trophies, a Rival of your own: 2.4.4] |
| 7 | Gangs | Gang reactions (main switch), hostile on sight, warnings, disguises, tribute and its size, surrender (default from 2.3.2); [known by your car and gun, bosses see through disguises: 2.3.1; gang codes, gangs adapt: 2.3.2; run with a crew, one of theirs: 2.4.5] |
| 8 | Turf and war | Turf wars (main switch), turf on the map, the enemy-of-my-enemy share, turf patrols (experimental, last); [war chest, back a gang, set gangs on each other, a common enemy, your own streets: 2.4.0] |
| 9 | Gang life | Bagmen, favours, sit-downs and their size and apex fighters; [gatherings, hunts and executions, deals and rackets, front lines, power struggles, how often: 2.3.3] |
| 10 | The crowd | Crowd reactions (main switch), how strongly, how many react, panic driving, morale and how strongly; [witnesses, wannabes, district temperaments: 2.3.1] |
| 11 | Word on the street | Overheard lines and their gap, how fast rumours spread, while you were out; [places remember, the braindance goes round: 2.3.1] |
| 12 | Street talk | Street talk (main switch), talk first, stopping walkers, shakedowns, liars, haggling, phone deals, intel, talk bubbles; [pay the street: 2.3.1; ransom, feed the street a lie: 2.4.5] |
| 13 | Reputation and money | The gain, dread and decay sliders, brutal conduct, clothing counts, the Street Cred floor, title perks, vendor prices and the discount cap, the gig bonus; [a head start from your lifepath: 2.3.1; Street Cred follows the legend: 2.4.6] |
| 14 | Messages and HUD | Toasts, word travel, the inbox gap, message hold, phone sound, countdowns, the district line, the apex bar and sound, HUD scale, the Hub in the pause menu; [morning brief, the map remembers, voices: 2.4.6] |
| 15 | Safe areas and jobs | Quest areas and their radius, spawns and combat in safe zones |
| 16 | Factions in play | One switch per faction |
| 17 | How gangs see you | All gangs, then one per gang |
| 18 | Advanced | They Will Remember, the log, freeze reputation, reset, separate this save; [Ambient Factions of Night City: 2.4.6] |

**Each release** moves the options on the headings it touches into this layout, adds their dependencies, and
rewrites any label or description there that is unclear (2.3.1: The crowd, Word on the street, Street talk,
Gangs, Reputation and money; 2.3.2: Gangs, Crews; 2.3.3: Gang life; 2.4.0: Turf and war; 2.4.1: Crews, Being
hunted; 2.4.4: the two Rivals headings; 2.4.6: Messages and HUD, Advanced). `tools/audit_settings.py` checks each
dependency names a Bool on the same heading, no heading is over 15, and every option has a label and description.

---

## Ground rules (every group)

- **Crash rules** (kept in full in my notes): no police or prevention system; one AI order per NPC through
  `CBIssueMove` / `CBTalkHold`; spawns through `CBSpawnGroup` / `CBCreateSpawn`; removals through
  `CBDeleteTaggedSafe` / `CBRemoveOne`, never in V's sight; nothing on hit/death threads or in attach events
  (queue to the next frame); **`CBNpcSafe` before any native read of an NPC** (the 2.3.0 lesson); UI as data;
  no loot on bodies, no runtime appearance changes; never delete a `.reds` file.
- **Every new tag** joins the sanctuary hold, combat release, downed sweep and setup (`CBQueueSpawnSetup`), or
  is written down as deliberately left out. **Every new ally or follower** is a CB_Ally-style spawn, never a
  world NPC taken over.
- **Saves:** no new `persistent` field on a class a save holds (`CBRival`, `CBFactionState`, the system).
  New saved data goes in a new book (group 0). **Derive before storing** (hashes of ids, the History log).
- **Wired in, never bolted on.** A new feature reads from and writes to the systems that already exist and keeps
  no copy of its own: standing through `CBActingStanding` and the scoring engine (so the gang stances set by hand
  hold), recognition through `CBRecognizes` (so masks, colours and the gang view hold), the History log for
  anything worth telling later, the rumour engine for word spreading, the line library [L1] for anything said,
  the Hub, the scanner and the HUD for what V can see, the lanes and the live-spawn cap (`CBSpawnRoom`) for anyone
  spawned, the existing pay path for eddies, the hold, release, sweep and setup lists for any tag, quest clearance
  and safe areas, messages Off, They Will Remember (Auto hands off), and the difficulty level. A feature that
  needs a number another system already knows asks that system for it. Each release's section lists its seams
  (below); the release check confirms each one in code, and that what was there before still uses them the same
  way.
- **Settings:** every feature has a switch and ships **on by default**; nothing new is marked experimental (turf
  patrols keep their experimental mark). Each switch goes on its heading in the final layout (above), with its
  dependency on its main switch, a label in the player's words and a description that says what happens in play.
- **Release checks, every release** (before it is pushed):
  1. A bug check of the release's own diff: every change against its callers, the crash rules and default
     behaviour; the mechanical sweeps (below) over the files it touched; and the seams where unchanged code calls
     what changed.
  1b. **The seams check.** Every seam the release's section lists is found in code, both ways (the feature reads
     the system, and the system's other readers still see the same numbers when the feature is off). Two new
     features that can act on the same NPC, lane or spawn are listed and checked together: one order, one owner,
     one exit.
  2. Compiled on 2.5 and 2.31, and with They Will Remember and Equipment-EX installed.
  3. Settings, scoring, API and orphan audits clean; `check_removed`; no `persistent` field added or removed on
     a class a save already holds (`git diff` of the release, counted).
  4. Update rehearsal: the previous release's zip in the sandbox, this one extracted over it, compiled.
  5. Every new switch turns its feature fully off, and with every new switch off, everything that was there
     before behaves as it did.
  6. CHANGELOG (player-facing), README if players see it, IMPROVEMENTS (built items removed), my notes (what was
     built and anything learnt), the spec. Pushed.
- **The mechanical sweeps** (from the 2.0.0 and 2.1.0 passes): duplicate global function names (2.3.1: redscript
  accepts a second one silently); `continue`; negative field defaults; raw deletes
  and AI commands outside their helpers; parallel arrays, saved ones especially, read past the shortest; tags
  missing from the hold, release, sweep or setup; anything changing shared state on a hit, death or attach
  event; `[0]` reads without a size check; any native read of an NPC before `CBNpcSafe`; every `GetAll()` walk.

---

## Foundations, built where they are first used

Shared pieces that several releases lean on. Each is built in the first release that needs it, so nothing is
refactored before it is used and tested, and no release carries code that does nothing yet.

**0.1 Save books.** (`CBStreetBook` in 2.3.1, `CBLedgerBook` in 2.3.2, `CBGangLifeBook` in 2.3.4, `CBWarBook` in 2.4.0, `CBHuntBook` in 2.4.1, all built; `CBRivalBook` in 2.4.4.) New ScriptableSystems on the `CBTurfBook` / `CBIntelBook` pattern: parallel arrays trimmed
to the shortest on load, `Pad` once, `Clear` from HardReset, bounds-checked readers.
- `CBStreetBook`: places that remember [7], V's haunts [46], V's car and weapon as the gangs know them [73] [74].
- `CBLedgerBook` (2.3.2): the fight-style ledger (0.4) alone, so `CBWarBook` can be laid out whole when 2.4.0
  first needs it (a persistent field added to a book already in saves is the risk the books exist to avoid).
- `CBWarBook` (2.4.0): each gang's war chest [34] and manpower [35], the gang V backs [33], V's own streets [37],
  open season [48], "one of theirs" [66].
- `CBHuntBook`: bounties and the hunters' ladder [39].
- `CBRivalBook`: a Rival's bond [58], trophies given [60], where a retired Rival ended up [61], who came back
  from the dead [56]. Keyed by Rival id, cleared with the Rival (`CBForgetRival`, the purge, HardReset).

**0.2 The event engine** (2.3.3). `Spawn/StreetEvents.reds`: an event is a kind, one or two gangs, a place, a time, a
window, a pin (`KeepMeetPin`), a list of people placed out of sight, and an outcome whether or not V comes.
The sit-down is moved onto it first, **with no change in behaviour** (it is the regression test: crash, deal,
sizes, the apex fighters, pins, words count). Every event in group 3 is then a table entry plus its own outcome.

**0.3 Gang codes data** (2.3.2). A `CBGangCode` per gang in `Data/Factions.reds`: what they respect, what they never
forgive, how they fight (a tactics profile for `Spawn/Tactics.reds`), how they make peace, and tuning numbers.
Read only from group 2 on.

**0.4 The fight-style ledger** (2.3.2). Per gang, how V hurts them, from the `CBKillInfo` method flags already scored
(headshots, stealth, quickhacks, melee, range, driving, grenades, night). Decays daily. Read by [40].

**0.5 Voices** (2.4.6). `CBSayVoiced(npc, context)`: `GameObject.PlayVoiceOver` with the `Scripts:CBStreetTalk` context
already let through by the talk wrap, behind `CBNpcSafe`. **Verify** the voiceset line names (taunt, scream,
plea, greeting) on both patches; any that do not exist are dropped, never faked.

**0.6 Mod events** (2.4.6). `CBEmit(name, ...)` with Codeware custom events [91]; call sites are added as each group
lands (RivalSlain, StandingChanged, HuntStarted, EventStarted, ...).

**Done when** (2.3.3, where the engine lands): a sit-down plays exactly as in 2.2.0.

---

## 2.3.1. Group 1: The street reads V, and talks like it

What ordinary people and the street notice about V. All on the Director, the crowd, witnesses, talk and the
rumour engine.

- **[6] District temperaments** first: data in `Data/Districts.reds` (word speed, how easily people scare, how
  long they remember), read by the witness count, `Model/RumorEngine.reds` and the crowd stages. **S**
- **[3] A wounded V** and **[4] fresh from a fight**: V's health and a post-fight window, read on the tick;
  crowd stages, lookout timing, talk lines. **S**
- **[5] Night and weather**: night from the clock now; weather **verify** (the weather system read).
  Feeds the lanes' pacing and scouts' sight. **S**
- **[2] Witnesses who call the gang**: a witness to V hurting a ganger is flagged, says a line, and after a few
  seconds tells the gang (skips the scout, gives the hunt V's district). Stopped by talking to them or putting
  them down. **Never** the crowd's own call-police reaction (prevention system). **M**
- **[8] Pay someone to keep watch**: a talk line on the lanes' own warnings. **S** ([68] bribe a lookout moved to
  2.4.1: the scout is spawned hostile, so there is nobody to bribe until [U7] reworks scouts.)
- **[9] The braindance goes round**: a big deed reaches every district at once, through the rumour engine. **S**
- **[1] Wannabes**: a melee-record challenger (no gun given or taken: a record that fights with fists), out of a
  safe area; win, walk away or lose each says something. **M**
- **[7] Places remember**: big deeds kept in `CBStreetBook` for a few days; overheard lines, jumpier gangers,
  and the lanes avoid sending people through them. **M**
- **[72] A head start from the lifepath**: seeds standing **only for a playthrough born on this version**
  (`VerifyPlaythroughOwner`'s new-birth path), never an existing save. **S**
- **[73] V's car is known**, **[74] a signature weapon**: counted in `CBStreetBook`; give a masked V away.
  **S to M**
- **[78] Enforcers see through disguises**: a per-person look timer for lieutenants, Rivals and apex fighters.
  **S**
- **[76] Wannabe Edgerunner** and **[77] Dark Future**: not built in 2.3.1. Neither mod was installed, so there was
  no API to probe, and the rule is to drop rather than guess (decision 3). Back on the list if they are installed.

- **[L1] The line library** first: `Narrative/Lines.reds`, a picker over line sets per speaker and moment,
  with a memory of recent lines and context from the street read (`CBReadStreet`), the clock, the weather and
  `CBStreetBook`. The existing `CBWhisperPick*` and `CBLineBag` calls move onto it. **M**
- **[L2] The street's lines**: every overheard line, crowd line, passer-by's talk answer, grapevine and rumour line
  rewritten through the library. **M**

**Seams.** [6] temperaments are read by the witness count, the rumour engine's speed, the crowd stages and how
long [7] places remember, and named on the Hub's district line. [3] [4] wounded and fresh from a fight are read
by the crowd stages, the lanes' lookout timing and the line library. [5] night and weather feed the lanes'
pacing, the witness count and the lines. [2] witnesses go into the kill scoring's witnessed flag, start the hunt
with V's district (the scout skipped), write to the History, give talk a reason and a line to stop them, and
stand back when They Will Remember owns witnesses. [8] [68] are talk lines on the lanes' own warnings, paid
through the existing pay path, quiet with messages Off. [9] goes through the rumour engine and the grapevine. [1]
wannabes spawn through `CBSpawnGroup` and the setup queue under the live cap, with their tag on the hold,
release, sweep and setup lists, and score through the kill scoring like any fight. [7] places live in
`CBStreetBook`, are read by the overheard lines, Morale and the lanes. [72] seeds standing through the scoring
engine. [73] [74] [78] are read by `CBRecognizes`, so every system that asks it (the Director, talk, patrols,
crews) sees the same answer, and the gang view set by hand still wins. Every line goes through [L1].

**Settings:** The crowd (witnesses, wannabes, temperaments), Word on the street (places remember, the braindance
goes round), Street talk (pay the street), Gangs (known by your car and gun, bosses see through disguises),
Reputation and money (a head start from your lifepath). **Done when:** a witness can be stopped; a wannabe fight resolves all three
ways; a masked V in their known car is recognised; nothing changes for an existing save's numbers.

---

## 2.3.2. Group 2: A code for each gang

Turns the data from 0.3 into behaviour, gang by gang, and adds adaptation. Hub page last.

- **[10]-[19] The codes**, one gang at a time, each through existing levers: standing weights (mercy,
  surrender, funerals), `Spawn/Tactics.reds` profiles (6th Street's suppression and flanking, the Claws'
  lone assassin at night, the Animals' melee-heavy crews), Morale numbers (Barghest never breaks, the Animals
  only fear Body), the lanes (Mox never send an apex squad, Wraiths' car ambush in the Badlands), and talk costs
  (Claws' insults, Valentinos' call-out before shooting). The Claws' protection demand [11] is a weekly text
  with a crew if ignored. The VDB's remote hack [15] is a status effect on V **verified** first, or left as
  a HUD and subtitle beat if no safe effect exists.
- **[20] The corporations**: contracts instead of crews; built in group 5 on the bounty board, listed here so the
  code table has it.
- **[40] Gangs that adapt**: from the ledger (0.4), a gang's crews change record choice and stat build (armour,
  a netrunner, snipers, melee, bikes), say so in a text, and fade back when V changes. Looks never change.
  **M to L**
- **[21] What they respect**: a Hub page per gang, filled in as V learns each rule (from the History). **S**

**Settings:** one switch, Gang codes (on), and Gangs adapt (on).

**Upgrades in this release:**
- **[U1] Crews that aren't clones**: `CBSpawnHitSquad` picks each member from the gang's captured role records
  (`roleTankRecord` and the rest, already filled as V fights them) and its roster by grade, instead of the one
  `sampleRecord`. The car path seats the same mix. **M**
- **[U2] A crew sergeant**: one member is marked leader at setup (a tag joining the hold, release, sweep and
  setup lists); the HUD line names them; their fall drops the crew's nerve in Morale; a parley with them holds
  the whole crew. **M**
- **[U3] Scaling that reads the fight**: new terms inside `CBApplyApexBuild` (district danger, gang strength, the
  gang's code, the fight-style ledger, difficulty), all bounded by the existing ceilings and sliders; the Hub's
  gang page says in words what they are sending. **M**
- **[U4] Apex squads as a team**: the netrunner's sight feeds the hunt's located state, chair tactics through
  `Spawn/Tactics.reds`, a squad that loses V searches together; each gang's squad record against V from the
  History. **M**

**Seams.** The codes are read through the levers that exist (standing weights, `Spawn/Tactics.reds`, Morale,
the lanes, talk costs), never a second copy of them. The ledger (0.4) is filled from the `CBKillInfo` method flags
the scoring already computes. [U1] [U3] build inside `CBSpawnHitSquad` and `CBApplyApexBuild`, under the existing
ceilings and sliders and the difficulty level. [U2] the sergeant's tag joins every list; the parley is the
existing parley. [U4] feeds the hunt's located state. [E1] surrender uses the existing surrender state, its
endings score through the scoring engine and write to the History. The gang view set by hand still decides who
knows V.

**Built in 2.3.2, and what moved.** All of [10], [12]-[17], [19], [21], [40], [L3], [E1], [U1]-[U4], with these
parts moved: the Claws' weekly protection demand to 2.4.0 with [U6] (it is a negotiation by text) and their lone
assassin at night to 2.4.1 (a hunt kind); the Wraiths' road ambush to 2.4.1 with [E2]; [U1] seats the mix only on
foot (`CBSendByCar` takes one record; the car path is for [E2]); [U2]'s parley with the sergeant to 2.4.5 (talk
refuses anybody sent after V); the VDB's remote hack is a HUD and subtitle beat, no status effect.

**Done when:** each gang's rule can be seen
working once in game (a checklist in my notes), and adaptation shows within a play session and fades. A crew arrives mixed (not five of one person), its sergeant falling shakes the rest, an apex squad that loses V searches together, and the Hub says in words what each gang is sending.

---

## 2.3.3. Group 3: Gang life

Events with a time and a place, on the event engine (0.2) and the codes (2). Each is a table entry with its own
people, outcome and Hub/History lines.

- **[32] Word of what's coming** first: events are announced through overheard lines and broker texts, with a
  pin when V hears. Every event below uses it. **S**
- **[22] Funerals**, **[23] celebrations**, **[24] initiations**, **[25] recruitment drives**: gatherings with a
  crash or an approach (pay respects at a funeral is a talk line). **M** each, one machinery.
- **[26] Hunts** (a fugitive run past V) and **[27] executions** (a lieutenant and a prisoner, set hostile to
  each other the way companions are set against our crews; stop it or not). **M**
- **[28] Arms deals** and **[29] rackets**: loot through the existing loot path (inventory, never a body); hits
  drain the war chest once group 4 exists, the district's strength before. Rackets are found through intel.
  **M**
- **[30] Front lines**: two gangs' people placed out of sight and set hostile to each other in a contested
  district; the winner pushes the turf. **M to L**
- **[31] Power struggles**: when a leader dies, two lieutenants (`Rivals/Hierarchy.reds`) text V for help;
  back one, kill both. **M to L**

**Seams.** Every event is on the engine (0.2) with the sit-down's pins, out-of-sight placing, removal and the
live cap; a crash scores through the kill scoring; outcomes write the History and move the turf book and the
gang's strength; [32] word of what's coming goes through the rumour engine and broker texts with messages Off
respected; front lines and power struggles read the gang codes and `Rivals/Hierarchy.reds`; loot goes through
the existing loot path.

**Shipped in two** (the group ran long, as the rule above allows): **2.3.3** is the engine (`Spawn/StreetEvents.reds`),
the sit-down moved onto it unchanged, [32] word of what's coming, the gatherings [22]-[25] (one switch, Gatherings),
arms deals [28] and rackets [29] (one switch) and How often. Funerals are owed on a Rival's or a boss's death and
celebrations on a district taken; paying respects is talk act 34. **2.3.4** is the fights between gangs, which need
two groups set hostile to each other (the pairwise attitudes companions already use): [26] hunts, [27] executions,
[30] front lines, [31] power struggles. (I meant to play at the end of 2.3.4; I now play 2.3.1 to 2.4.2 together.)

**Settings:** a new page, **Gang life**: one switch per event kind and one "how often". Heavy ones (front lines, power struggles, executions) start at a gentle frequency. **Done when:** each event can be crashed, approached and missed, and the
cap on live spawns is never broken when two events overlap.

---

## 2.4.0. Group 4: Turf, money and war

Gives the turf war a strategy. Uses `CBWarBook`, the events, and the turf book.

- **[34] The war chest**: each gang's money. Bagmen, rackets and tribute fill it; crews, apex squads and payouts
  empty it; a broke gang sends fewer people. Hub words: flush, counting every eddie, broke. **M**
- **[35] Manpower**: a massacre empties the ranks; crews come smaller and greener, refilling over days. **S to M**
- **[33] Back a gang**: pick one on the Turf screen; V's work for it counts double where it fights, and holding a
  district for it pays a weekly cut through the tribute path. **S to M**
- **[70] Set gangs on each other**: a talk line that raises the front-line chance between two gangs. **M**
- **[36] A common enemy**: two warring gangs truce against a terrifying V; their people stop fighting and a joint
  crew comes. Rare. **M**
- **[37] V's own streets**: at legendary standing, a district V has broken every gang in is V's: no crews sent
  there, gangs passing through pay. Endgame. **L**

**Settings:** Gangs page (war chest, back a gang), Turf page (common enemy, own streets; own streets starts gentle).
**Upgrades in this release:**
- **[U5] Turf patrols, made robust** ([E3]; stays experimental and off by default). What is weak today, read from
  `Spawn/TurfPatrol.reds`, and what replaces it:
  - *They shadow V.* Each walk picks a point round V, so a patrol follows V about. Now a **beat**: three or four
    points round the corner they came in on (`CBPursuitPoints` from the patrol's own start, kept in the session),
    walked in turn, one order each through `CBIssueMove`; a walker who has not moved since the last walk tick
    gets the next point (stuck), never a second order on top.
  - *All one person.* Spawned from the one `sampleRecord`. Now mixed from the holder's role records and roster
    ([U1], already built in 2.3.2).
  - *Hostile by posture alone.* Set-up reads `GetPosture`, so a masked V in their colours is still attacked. Now
    through `CBRecognizes`, like the Director, with [73] and [74] giving V away; Neutral or better, they nod V
    through.
  - *Each one on its own.* When V hurts one, the rest turn together (one pass on the next frame, never in the hit
    event), and a witness [2] in the crowd can carry word to the holder.
  - *Exits.* Every state that stops a patrol (a story hold, a quest area, a job, a sanctuary, a hunt starting, the
    district changing, the life running out, a sit-down or event [0.2] nearby) ends it the same way: walk off
    away from V, then `CBDeleteTaggedSafe` out of sight, with the downed sweep and the combat release covering
    the rest. Checked after a load (no CB_Patrol left, the book's patrol fields cleared).
  - *A budget of its own.* It spawns only with room under the live cap after the lanes, events and hunts, never
    in a district with a sit-down or event, and never while a crew is pending.
  - *What it is for.* Patrols cost the holder's war chest [34] and grow its grip on the district, putting one
    down loosens it (the turf book), take part in front lines [30], can be bribed [68] (paid through the
    existing pay path) or followed back to a racket [29] (a pin through intel).
  - The switch stays on the Turf page, marked experimental, off by default. **M**
- **[U6] Tribute and peace with terms**: a haggle on tribute by text; peace answered with eddies, a Rival's
  whereabouts, a district, or a favour. Same peace path (`CBBrokerPeace`, `CBCallOffGang`). **M**

**Seams.** The war chest and manpower are read by the lanes (crew size and how often), apex eligibility, the
tribute and peace paths and the Hub; filled by the bagmen, rackets and tribute that exist. Backing a gang moves
standing through the scoring engine and pays through the tribute path. Patrols ([U5]) are described above.

**Built in 2.4.0.** All of [33]-[37], [70], [E3]/[U5] (still experimental), and of [U6] the peace haggled by text
(once a day, off the phone thread), peace for a favour (talk act 38: crash their enemy's next event), and the Claws'
protection money ([11], talk act 37). Tribute haggled by text is not built: tribute is paid to V unasked, and a reply
to it would need a fourth phone answer kind for little play; left in IMPROVEMENTS as part of [U13]'s thread answers.
`CBWarBook` holds the open-season and one-of-theirs fields for 2.4.2 (used) and 2.4.5 already.

**Done when:** robbing bagmen visibly slows a gang's crews; backing a gang moves a district; nothing in the turf
book's save layout changes (new data is in `CBWarBook`). With the experimental switch on, a patrol walks its beat
without following V, nods a disguised V through, turns as one, leaves from every state, can be bribed and followed
to a racket; peace can be bought in each of its terms.

---

## 2.4.1 to 2.4.3. Group 5: Being hunted

A second nemesis line, and fairer, more readable hunts.

- **[44] A fair first volley**, **[43] sound before contact**, **[45] a cost for running**, **[41] lie low on
  purpose**: small changes to the hunt and the build pass. **S** each. **Verify** the stat used for accuracy
  and the vanilla sound events used.
- **[42] Lose them on the metro or in a cab**: metro is already known; Delamain taxi **verify**. **S**
- **[46] Hunters learn V's haunts** and **[47] waiting on V's road**: from `CBStreetBook`, outside quest
  clearance and never inside a safe area. **S to M**
- **[50] Lookouts in the crowd** and **[49] tracked**: a scannable lookout who reports V (stops the turf watch if
  dealt with); a Rival netrunner's tracker as a Cyberbane flag on V (HUD line TRACKED), cleared at a
  ripperdoc (**verify** how a ripperdoc visit is seen). **M**
- **[48] Open season**: one in-game day of a gang's full anger, with a way out (survive, kill the leader, pay).
  **M**, on at a gentle frequency.
- **[39] A price on V's head, and the hunters' ladder**: `CBHuntBook`; named solos from person records, ranks ten
  to one, a Hub page; posted by gangs, corporations [20] and Rivals. **L**, on at a gentle frequency.
- **[88] Corporate interest** and **[89] harder means harder** (extends `CBDifficultyLevel`, which already
  trims crews and lengthens warnings). **S to M**

**Settings:** Pacing page (lie low, metro, haunts), Crews page (fair volley, sounds, lookouts, tracked),
a block on the Rivals page for the ladder.

**Upgrades in this release:**
- **[68] Bribe a lookout** (from 2.3.1), with [U7]: a scout who has not yet called it in can be paid off in talk.
- **[U7] Scouts worth catching**: the scout gets search orders from the hunt (`CBHuntPickSearchPoint`), one order
  at a time; a scout kind per gang code (a bike spawn for the Claws, a netrunner for the Voodoo Boys who reports
  without walking up); a call-in delay with a subtitle, stopped by a takedown, a grab or talk (bribe, a lie);
  a scout who sees V twice and escapes goes to the Rival births as a Hunter. **M**
- **[U8] Hunters who use what they know**: the search centre also weighs V's known car, V's haunts, gunfire
  within earshot and lookout reports. **S to M**

**Seams.** Haunts, the road and V's car come from `CBStreetBook` (2.3.1). Lookouts reuse the witness of
2.3.1. Bounties read the war chest; the ladder writes the History; open season raises the lanes through the
existing queue, never a second queue. Scouts and hunters keep the one-order rule through `CBIssueMove`.
[89] extends `CBDifficultyLevel`, which the lanes already read.

**[N1] and [N2]** join 2.4.3 (see "Learnt from Night City Alive"), and **[H1] the web of gangs** with the
Hub's drawing kit (see "The Hub, drawn"). If 2.4.3 runs long it ships in two: the bounties and corporations
first, then the war in the street and the web.

**Shipped in three** (the group ran long): **2.4.1** is [44] (accuracy x0.4 for 2.5 s on `CBEngageV`), [41] (heat
words; a trail gone cold on a change of clothes or district while searching, `CBChaseGiveUp(cold)`), [42] (the
metro was already a story hold that calls hunters back; now said), [46]/[U8] (haunts in `CBHuntBook`, a closer tip,
sense x1.15 by the known car or gun), [U7]/[68] (scouts neutral until they call it in, bribed in talk act 39, the
Voodoo Boys' netrunner scout, the HUD line), [50] (the turf watch's lookout in the crowd). [45] and [89] were built
already (the run penalty in `CBChaseGiveUp`; difficulty in crew size, spawn distance, warnings and sense). [43] not
built: no sound event confirmed. **2.4.2**: [49] tracked, [48] open season, [47] V's road with [E2] lying in wait,
the Claws' assassin, the Wraiths' road. **2.4.3**: [39] the bounty and the hunters' ladder, [88] corporate interest,
[20] the corporations' contracts. The groups after move up: Rivals 2.4.4, talk 2.4.5, the telling 2.4.6.

**Built in 2.4.3.** [39] in `Spawn/Bounty.reds`, kept in the hunt book's fields laid out for it in 2.4.1: a price from
a sworn gang with a leader and money in its chest (40% of the chest), a Rival of rank three who has met V three
times, or a corporation that wants V dead; ten hunters on the ladder, named and built by rank (the Afterlife's solos
with Phantom Liberty, the payer's own best without it), each `CB_Squad` with `CB_Bounty` beside it so every crew list
reaches them; the one just above V comes, about every nine game hours; V takes the place of one beaten above. The
price ends paid from the Standing page, with whoever put it up dead, or when they stop wanting V dead. [20]: a
corporation's crews stop at the crew reason, apex eligibility and `CBGangMaySend`, and it puts out a contract that
can be bought off at one and a half times. [88]: once V is a Legend, a weekly chance of a corporation's offer on a
hostile gang's leader, or a warning when V stands low with it; the offer is kept as "Arasaka:Valentinos" in the one
name the book saves for it. [N1] in `Spawn/Clashes.reds`: the Director's walk keeps the last few of each side it saw,
and a pair or two are set hostile to each other through their attitude agents, with what they thought before put
back after. [N2] is not built: every NPC who fires an unsilenced gun already sends the game's own gunshot stim
(`weapon.script`), and the crowd already runs from it. [H1] in `UI/HubWeb.reds` and the Hub: a list or web switch on
the Gangs page; turned lines rotate clockwise on screen by the angle of the screen's own coordinates, the way the
game's photo-mode stickers are turned. And a fix found on the way: since 2.0.0 the lane let go of every Rival it
picked while crews were off, while They Will Remember sent the gangs' people, or once their gang was no longer
hostile, because it asked them the crews' question.

**Done when:** a hunt can be shaken by the metro, open season can be
survived all three ways, and the ladder moves when V kills a hunter. A scout can be stopped mid-call, grabbed, bribed and fed a lie, and each gang's scout is its own kind.

---

## 2.4.4. Group 6: Rivals (was 2.4.2)

The facedown and a Rival's life around V. Uses the announcement, the mercy lines, talk, and `CBRivalBook`.

- **[53] The facedown** and **[54] just you and me**: at the announcement, a short choice list (stare down,
  draw, walk away, one-on-one); the crew holds back through the hold state talk already uses. **M**
- **[55] Humiliation**: a fourth mercy line. **S to M**
- **[63] Last words**, **[62] places with meaning**, **[61] where they ended up**: lines and positions already
  kept. **S** each.
- **[64] A Rival on their feet**: talk lines for a Debtor or a held-back Rival met in the street. **M**
- **[56] Back from the dead**: an archived Slain Rival returns (state change on fields that exist), never one
  finished with a fatal flaw or a finisher. **S to M**
- **[57] Rivals at war with each other** and **[58] bonds**: off-screen outcomes in the History; bonds in
  `CBRivalBook`. **M**
- **[60] Trophies**: the weapon from their record, given through the loot path. **Verify** reading the record's
  primary weapon. **S to M**
- **[59] A Rival of your own**: a CB_Ally-style follower, called by text once a day. **M** Built as the crew's
  first member ([C1] in 2.5.0), on the follower role and the `CB_Own` tag the crew uses, so nothing is built twice.

**Settings:** Rivals page.

**Upgrades in this release:**
- **[U9] Rival chrome**: `CBRivalImplants(r)` derives the set from what the Rival already has; each implant is
  a term in `CBRivalTraitTerms` and, where the game has one, a behaviour ability in `CBKitRivalTraits`
  (subdermal armour, anti-stun, catch-up, guard break, seeing through smoke). Answers V's method from the
  scars already kept. Shown on the Rival page and in the scanner; a "went under the knife" line after a climb; a
  ripperdoc visit is a place V can catch them (a lead, through Whereabouts). **M**
- **[U10] Places that are lived in**: guards walk a short beat (`CBPatrolWalk`, one order each), the Rival's
  hours by time of day, a guard who escapes moves the lead. **M**
- **[U11] Rival tactics by kind**: a tactics profile per Rival source and trait. **S to M**
- **[H2] The Rivals tree**: the gang's leader, lieutenants and bench as a flow chart on the Rivals page, with the
  bonds, feuds and the fallen (see "The Hub, drawn"). Uses 2.4.3's drawing kit. **M**

**Seams.** Chrome is derived from the Rival's existing fields and applied in `CBRivalTraitTerms` and
`CBKitRivalTraits`; the facedown uses the talk hold state; trophies use the loot path; places use Whereabouts and
`CBPatrolWalk`; the street hears through the rumour engine; everything shows on the Rival page and the scanner.

**Built in 2.4.4.** Everything above, in `Rivals/RivalMoments.reds` and a new save book, `CBRivalBook` (a bond, how a
Rival's story ended and when, a trophy taken, a return, a humiliation, chrome already heard of, the place that matters,
one feud I set going). The facedown opens when the Rival is within 24 m and nobody has fired: the Rival and their
people are set neutral to V through their own attitude agents, held with the talk's own hold, and kept out of the
hunt's orders and engagement; talk to the Rival to choose. Let go, they stand down the way a crew called off does, so
the hunt never counts it as me running. Chrome is derived from what the Rival already has (rank, escapes, mercies,
kills, scars), so nothing new is saved on `CBRival`; it adds terms under the build's ceilings and the game's own
behaviour abilities, never cyberware effects. The trophy is the weapon the game itself works out the Rival carries
(`AIActionTransactionSystem.CalculateEquipmentItems`). "Nobody kills you but me" is a new setting, `nobodyButMe`, so
the new default reaches everybody. Two parts are not built: a guard who escapes moving the Rival to a second place,
and a ripperdoc visit as a place to catch them; both need the leads to be moved and planted, which the whereabouts
system cannot do safely yet. And a fix found on the way: from 1.3.2 the weapon behind every kill was misread (the
method values were tested as bit positions), so gunfire, quickhacks, explosives and finishers never counted.

**Done when:** each facedown outcome has been played; a Rival comes back from the dead
only when allowed; a trophy arrives in the inventory and never on a body. A Rival who escaped a gunfight comes back armoured, and it shows on their page, in the scanner and in the street's word; guards walk their beat.

---

## 2.4.5. Group 7: Talk and allies (was 2.4.3)

The payoffs of being liked, and talk as a weapon.

- **[65] Run with a crew**: one to three CB_Ally-style followers of a Friendly gang (one follow order each,
  **verify** the follow command), set against whoever fights V; home after an hour or off their turf. **M to L**
  The follow command is the game's follower role (verified in the source: see [C6]). In 2.5.0 these become the
  crew's lent soldiers ([C4]).
- **[66] One of theirs**: at Allied, counts as wearing their colours everywhere; favours become duties. Stored in
  `CBWarBook`. **M**
- **[67] Ransom**: a surrendered ganger held for their gang's money or a rescue crew (needs Surrender on). **M**
- **[69] Feed the street a lie**: sends the next scout or crew to the wrong district, or sells V out. **M**

**Settings:** Street talk page; run with a crew and ransom start at a gentle frequency.

**Upgrades in this release:**
- **[U12] Informants with a life**: a page on the Hub, and an informant's gang finding out as a hunt event. **M**

**Seams.** Followers are CB_Ally-style spawns with one follow order, set against crews the way companions
already are; "one of theirs" is read by `CBRecognizes`; ransom starts from [E1] surrender; a lie moves the hunt's
search centre and the lanes' target district; informants keep the intel book.

**Built in 2.4.5.** In `Reactions/Allies.reds`. The borrowed crew is spawned (CB_Ally with CB_Follower beside it) and
given the game's follower role, `AIFollowerRole` through `AIHumanComponent.SetCurrentRole`, the way the game makes the
Flathead follow; the role finds its target through an entity reference, so I point it at the player the way the game
names the player ("#player"). Cleared with `AINoRole`, their own attitude group comes back, and they get one order, the
walk home. "One of theirs" uses the save field the war book laid out for it in 2.4.0 and reaches everything through
the colours V counts as wearing (`GetDisguiseFaction`) and recognition, so nothing is built twice; a week's duty is kept
in the History as the enemy's kill count when it was asked. Ransom answers in twenty seconds. A lie is taken by the
next hunt that starts for that gang. An informant found out is owed a hunt on the event engine, their own gang on both
sides. The sergeant's parley holds the crew the way a facedown does, and paying or scaring them off is the pay-off's
own call-off (`CBCallOffGang`). Not played: the follower role on a body the game did not place is the part to watch.

**Done when:** followers never take a
second order and are cleared out of sight; a lie can be seen working and failing. An informant whose gang finds out can be saved or lost.

---

## 2.4.6. Group 8: Telling it (was 2.4.4)

Last, because it reads what every other group writes.

- **[79] Voices for the moments**: call sites for 0.5 at announcements, breaks, surrenders and greetings.
- **[80] Panic in the dark**: lines and nerve when V picks off a crew unseen. **S to M**
- **[81] The screamsheet**, **[82] the legend, told**, **[84] a Rival's story**: Hub pages written from the
  History. **[83] Morning brief**: one broker text at dawn. **[85] The map remembers**: pins for a day, capped.
  **S** each.
- **[87] Street Cred follows the legend**: **verify** the experience call. **S**
- **[90] Presets with a shape**: Nemesis, Turf war, Quiet life, added to the preset list (values are stored by
  name, so nobody's settings move). **S**
- **[92] Ambient Factions of Night City**: detected by module, its gangs counted as theirs, lanes stand back
  during its wars. **S**

**Upgrades in this release:**
- **[U13] Phone threads with answers**, **[U14] the scanner tells the story**, **[U15] titles for what's new**:
  through the existing threads (`UI/RealPhone.reds`), the scanner wrap (`UI/ScannerName.reds`) and the title
  engine. **S to M** each.

**Seams.** The pages read only the History and the books; voices go through the talk wrap's context;
presets set values by name; mod events are emitted where each system already logs.

**Built in 2.4.6.** In `Narrative/Telling.reds`, the phone (`UI/RealPhone.reds`), the scanner and the Hub. Voices use
only voiceset lines the game itself plays (`enemy_warning`, `fear_beg`), through the context the talk wrap already
lets through; a greeting is not one of them, so a friendly gang's greeting stays a subtitle. Street Cred is the game's
own `ExperiencePointsEvent`, the way its bounties give it. Events go out through the game's callback system
(`DispatchEventAs`), compiled on both patches. The phone's rows come from one list for what is shown and what is done.
Every line written since 2.4.3 now draws on what the street knows (V's title, where V is, the hour and the weather,
the history with whoever is speaking), and every line after this is written that way. Not built: the map remembering
[85], which needs world-map pins of its own where Cyberbane has only ever placed one at a time, and Ambient Factions
[92], which is not installed here to probe.

**Done when:** every page fills from a real History, and the brief and screamsheet stay quiet with messages Off. A gang thread can be threatened or stalled, and the scanner shows chrome, sergeants and scouts.

---

## 2.5.0, first: Group 9: A crew of my own (added 2026-11-18)

The one new idea in 2.5.0, and the payoff of everything before it: the Rivals I spare, the gangers I frighten and the
friends I make on the street can end up working for me, and when somebody hunts me, I can call them. It is built
first in 2.5.0, so the comprehensive pass that follows covers it with everything else.

**Is it feasible?** Yes, with one new engine call, and it is the game's own. The game makes the Flathead my companion
with a follower role: `new AIFollowerRole`, `SetFollowTarget(player)`, `AIHumanComponent.SetCurrentRole`
(subCharacterSystem.script). Setting that role (aiRole.script, `AIFollowerRole.OnRoleSet`) moves the NPC into my
attitude group, joins my squad, registers them to my fights and gives them the follower threat preset; clearing it
(`OnRoleCleared`) puts their own attitude group back. A role is how they behave, so it is no move order, and the one
order a crew member ever gets is to walk home at the end. With the role set, `IsPlayerCompanion` is true for them,
and the rules I already wrote for my companions reach them without new code: every hunter Cyberbane sends is set
hostile to them and re-checked each tick (`CBMakeHostileToCompanions`, `CBCompanionHostilityTick`), and the Safety
Gate keeps the Director, morale, the crowd and talk's threats away from them.

How I get people:
- **[C1] The ones who owe me.** A Rival I have spared twice is already a Debtor and texts me tips. The mercy lines
  where they lie get a fourth answer, "[Recruit] You owe me. Work for me.", and a Debtor can be asked by text later.
  The most loyal kind. [59] is the first of them. **M**
- **[C2] The ones I frighten.** "[Intimidate] You work for me now" already turns a ganger into an informant
  (`CBIntelTurn`). Pushed further, somebody frightened enough joins instead. They come because they are afraid, fear
  wears off, and they still have friends in the gang they came from: low loyalty, drifting lower. **S to M**
- **[C3] The ones I pay.** A merc for hire, found the way a Rival's whereabouts are bought: a fixer texts a price in
  my district and I answer in the thread (the 1.9.7 phone deals, haggling included). Loyal while paid. **M**
- **[C4] The ones my friends lend me.** An Allied gang lends a soldier; these are [65]'s followers. Loyal while the
  gang likes me, and gone the day it stops. **S** on top of [65]

Five on the roster, up to three out at once, inside the live-spawn cap so there is always room for whoever is
hunting me.

How a crew works:
- **[C5] Calling them.** A thread on my phone, "My crew", with a reply that only shows while I am hunted, ambushed or
  in a fight with Cyberbane's people: "Need you. Now." The Hub has the same button. They come from the district they
  live in, by car when I am outdoors and on foot when not, out of my sight like every arrival, and each can be
  called once an hour. With **Come on their own**, the most loyal turn up unasked when an ambush springs. **M**
- **[C6] Whose side they are on.** The follower role above. They never take a move order while they follow; when
  the fight has been over for a minute, or I drive off, they get the one order, home, and are cleared once I cannot
  see them. Nothing of mine can turn them on me: they are left out of the rearm watch, the cut-off, the combat
  release and the orphan sweep through one new list of tags, mine, next to `CBStreetTags`. **M**
- **[C7] Loyalty, and betrayal.** Each member has a loyalty that starts from how I got them: owed is high, paid is
  middling, frightened is low and drifts down day by day. It rises with fights won together, a fair cut of a
  bounty, and picking them up when they go down; it falls when I leave them lying, when one of the crew dies, when I
  stop paying, and when I hurt the gang they came from. Below a line, a call can go wrong, all the more when the
  people hunting me are their old gang:
  - they stay away and tell the hunters where I am, so the hunt skips its scout and comes straight at me (the
    informant's set-up already works this way);
  - or they come, and turn on me in the fight: the role is cleared, they are set hostile to me alone, and they
    become a Rival of a new kind, the Betrayer, who knows my haunts.
  I can always see it coming: the crew page shows who is restless, they say so by text ("You still owe me for the
  last job"), and paying them, talking to them or letting them go settles it. **M**
- **[C8] People with a life.** Each keeps a name (the name book), a rank that climbs with the fights they win, scars,
  a nickname earned the way a Rival earns one, and a seat from their record (heavy, blade, netrunner or shooter,
  kitted with the apex role kit). One killed is gone for good: their old gang hears, the street buries them (the
  2.3.3 funeral, for one of mine), and whoever killed them becomes a lead. **M**
- **[C9] What it costs, and what it changes.** A weekly cut, taken from what I earn on the street or asked for by
  text; unpaid, loyalty falls. Running people is renown, the gangs that hate me answer it with bigger crews, and
  while I am away my own streets ([37]) are watched by them. **S to M**
- **[C10] The crew page.** On the Hub: who is on it, where they live, loyalty as a bar, who is out and who is hurt,
  with Call, Pay and Let go; drawn with 2.4.3's kit and built as data, like every other page. **M**

**Settings:** a Crew heading: My crew (on), Come on their own (off), Betrayal (on), how readily a frightened ganger
joins, and the weekly cut.

**Seams.** Recruiting adds a line to the mercy list (`CBRivalMercyLines`), a step to the turn (`CBIntelTurn`) and a
deal to the phone; the roster is `CBCrewBook`, a new book, so no saved class changes shape, with its arrays kept in
step the way `CBIntelBook` keeps its informants; members are spawned through `CBSpawnGroup` or the car arrival with a
new `CB_Own` tag and set up in `CBApplySpawnSetup` with the follower role; a Betrayer goes through `CBCreateRival` with
`ECBRivalSource.Betrayer` added after `Hunter`, and `ValidateRivals` learns the new top value so the source is not
reset on load.

**Verify:** the follower role on a body the DynamicEntitySystem spawned, on both patches, and what happens to it
when that body streams out and back; what a follower does when I get into a car (the game seats its own companions
by script, so mine are sent home past a distance instead); the follower's downed state (`FollowerDefeated`) on an
ordinary gang record; and that clearing the role really restores the attitude group on a spawned body.

**Built in 2.5.0.** In `Reactions/Crew.reds`, with the roster in `CBCrewBook` (a list of `CBCrewMember`, and the
last twelve who left), a Hub page and a phone thread. Where it differs from the plan above: they arrive on foot from
out of my sight, the way a borrowed crew does, because the car arrival belongs to the hunt's lanes; the funeral is
their old gang's (it buries them, and the crew texts me), since the street's funerals are a gang's; whoever killed
one is marked (on the scanner, as "KILLED <name>"), and becomes a Rival with that on their record if they get away
when the hunt gives up; a Rival who killed one is a lead at once. Hub actions (call, pay, let go, hire) wait for the
game to be back, like every other. My own streets bring in a quarter more while two or more are on the crew. A
Betrayer is a new Rival source, `ECBRivalSource.Betrayer`, which `ValidateRivals` keeps on load; one who owed me
turns back into the same Rival they were.

**Done when:** a recruited Rival, a frightened ganger and a hired merc have each been called into a hunt and fought
the hunters; none has taken a second order, or turned on me without the page having warned me first; a betrayal
has been played both ways, the tip-off and the turn, and the Betrayer has come back as a Rival; one of the crew has
died and been buried; and nobody of mine is left in the world once a fight is over.

---

## 2.5.0: The final form

Besides the crew above, no new idea goes in. 2.5.0 is everything from 2.3.1 to 2.4.6, and the crew, made to work
together, checked end to end, and documented for good. It starts only when 2.4.6 is out.

**Done in 2.5.0.** The every-file read was the 2.4.2 pass; this one read what came after it (2.4.3 to the crew)
against each other and against what was already there, and went through the pairs in the list below. What it found:
the re-arm watch turned a facedown's or a parley's held people hostile again inside its first thirty seconds, and V's
companions stayed at war with people holding still or a crew paid to leave (`CBCalmTowardCompanions`); both fixed at
the source. The Hub was rebuilt as I asked: every page that has a picture opens as one (the web, the tree, the map,
the crew) with a switch to a list, Standing as tiles and rows, a bar on every list, and text that is drawn smaller
to fit before anything is shortened, and only ever at a word. The layouts were laid out to scale before they went in
and checked for overlap.

**And a second pass, after the map and the last two upgrades.** I built [U9] and [U10],
then read the mod again by system, against the pairs below and against the new pieces. What it found, each fixed at
the source:
- **V's own crew in the old code.** The Safety Gate judged one of V's crew walking home, or a gang's people lent to
  V, as anybody V had put down, so they could come back as a Rival; it now passes over anybody tagged as V's. One of
  the crew who turned was not in the story's stand-down and stayed when a scene began. A bounty hunter, who is
  `CB_Squad` for the lists, was counted as one of a gang's crew, so a hunter who killed one of V's crew and got away
  came back as a crew's Rival; the counts and both survivor picks pass over `CB_Bounty`.
- **Forgetting Rivals.** The crew's names and stories are the Rival records they came from, and forget, forget every
  rival, another save's forget notes and the archive trim could all take that record away. `CBCrewBook.Keeps` and
  `RivalKeptByCrew` now guard every one of those paths, and the Rival book keeps their rows.
- **Start over** cleared the war book's saved fields and none of its session ones: a gang's offer to take V in, a lie
  still steering a crew, a ransom still due, the last street clash on the web. `CBWarBook.ResetSession` clears them on
  a load and on Start over, and Start over first ends what is live the way it ends on its own (`CBWarStandDown`,
  `CBCrewStandDown`: a clash's gangers put back, followers' roles ended). The map book numbered its memories from 1
  again with the old pins still up, so the first new memory could take an old pin; its clear takes the pins down.
- **[U9] and [U10] themselves.** A ripperdoc's clinic is usually a safe area, where no lead may be, so the lead is now
  a usable spot outside the nearest clinic that has one; the district is named only when the clinic is near the
  last sighting. The lookout who runs keeps their one order, and a mask or the gang's colours gets V past the
  lookouts the way it gets V past the street (`CBSeesThroughDisguise`).
- **A crash opening the Gangs page**, the first thing I hit in play. `CBWebPair` searched the gangs' rival lists with
  `ArrayContains` straight on what `CBGangRivalsOf` returned, inside `||`, and the game took the name it searched for
  as an address. No script that has run in a game before did that; eight written since 2.3.0 did. Every one now
  searches a named local, and the mechanical sweep flags the shape (`ARRAY-TEMP`).
- **The pictures were too small to read**, and too busy: 16 to 20 px names and 11 px lines at 1080p, three lines and
  two unlabelled bars a box, a line from V to every gang and every old feud drawn at once. Every box now has a name
  and a word or two in the pictures' type (`CBPicName` and the rest, 26/21/18), the web and the maps are drawn taller
  (`CBWebTallHeight`, the button moving down with them, `PlaceActions`), V's lines go only to gangs that are more than
  neutral, gangs' old feuds and the words on lines come only for the gang picked, a long name gives up its nickname
  or first name before it is cut (`CBHudBoxName`), and each picture's words underneath are its legend alone. Laid
  out to scale at 1080p before it went in. The tree's bench no longer hangs from nothing when it holds one or two.
- **Talking.** The conversation's hold-position order ran on in combat (`ignoreInCombat` left false), so somebody V
  picked a fight with stood still until it ran out, and cancelling it alone did not stop it, so somebody V left stood
  frozen; it now gives way to a fight and is ended the way the game ends its own (`CBEndHold`). A passer-by V stopped
  is put back into foot traffic (`TryAndJoinTraffic`) or walks on. Both were there in 2.3.0.
- **Frightened into the crew** [C2] almost never happened: it was tried only from "You work for me now", which a
  successful Intimidate seldom reached, only for somebody who read as afraid, and only with the informants on. A
  successful Intimidate now tries it, and leaned-on counts as frightened (`CBCrewTakesFrightened`).
- **The bar over a Rival V spared** stayed up: the threat bar let go only of somebody gone or down, and a spared or
  outrun Rival gets up and walks off. It now lets go of anybody without a tag it is for (`CBBarStillOnV`), which
  the encounter's close takes off (`CBRetireRivalBody`), and the same for a crew or apex squad called off.
- **The Rivals tree's lines did not connect.** A bond and V's nemesis were lines from the middle of one box to the
  middle of another, so only a stroke in the air between them showed, across the chair lines; they are words in the
  box now (a bond in cyan, the nemesis in red, or what V and they have been through, or "Never met you"). The thin
  connectors lost the glow that read as a second line, the fallen move up when the bench is empty, only the first
  empty chair names who steps up (without the nickname, so it fits), and the buttons beside the words close up
  where one is hidden (`PackActions`).

**1. The comprehensive bug pass.** Like the 2.0.0 pass, over the whole mod and not only what changed:
- **Every file read end to end**, system by system (Core, Model, Signals, Reactions, Spawn, Rivals, Economy,
  Narrative, UI, Settings, API, Data, Localization, Compat), against the game's own source wherever an engine
  call is involved, on both patches.
- **The relations between systems.** With nine groups added, the risk is where they meet: an event, a hunt, a
  Rival and an ally on the same street at once; open season during a sit-down; a backed gang's war chest paying
  a bounty; a follower in a facedown; a lie sending a crew into a funeral; my crew called into open season; a
  Betrayer turning during a sit-down. Every pair of systems that can act on
  the same NPC, lane, pin or spawn budget is listed and checked: one AI order, one owner, the live-spawn cap,
  removals out of sight, and an exit for every state.
- **The mechanical sweeps** over every file (the list under Ground rules), and the audits.
- **Saves**: every book loads from a save made on each release from 2.2.0 to 2.4.6, and from a save with no
  Cyberbane at all; no `persistent` field on an old class has changed since 2.2.0.
- **Every switch**: each feature fully off when switched off, and with every setting at its default the mod
  behaves as designed. Presets set what they say they set.
- **Performance**: the cost of every tick added since 2.3.0 measured in a dense district (Jig-Jig Street, Kabuki
  market) with Night City Alive; anything per NPC per tick budgeted or cut, as the 2.0.0 optimisation pass did.
- **Compatibility**: They Will Remember (Auto, On, Off), Night City Alive (compiled together 2026-11-18; its density
  and its gang attitudes against sit-downs, deals and [N1]), Much Better AI, New Game Plus, Equipment-EX, Street Sense,
  and the reflection-only mods present and absent.
- Every finding fixed at its source, and the pass repeated on what the fixes touched until a pass finds
  nothing.

**2. Optimisation.** Whatever the performance check flags, only where play is unchanged.

**2b. [U16] Every default confirmed.** Every feature, the three made default in [E1], [E2], [E4] and the heavy ones
that started gentle, is played at its default and its frequency set for good. Turf patrols are played with their
experimental switch on and stay off by default.

**3. Settings for good.** The layout was settled in 2.3.1, so this is a check, not a regroup: every heading as
the table says, none over 15, every dependency hiding what it should, every label and description read once more
in game, presets setting what they say, and nobody's values moved.

**4. Documents for good.** CHANGELOG 2.5.0 as one entry players can read in a minute; the README rewritten for
the final form (kept short, the video kept); IMPROVEMENTS.md holding only what was not built and why; my notes
and the spec brought up to date; the Nexus description and the spawn-and-chance list redone for 2.5.0.

**5. The release.** `build.ps1 -Version 2.5.0`, the release checks, an update rehearsal from 2.2.0 and from
2.4.6, pushed.

---

## Decisions

1. **Defaults.** Settled: everything ships on by default with its own switch, and three of the experimental
   features become default in their releases ([E1], [E2], [E4]). Turf patrols stay experimental and off by
   default, made robust in 2.4.0 ([E3]). The heavy new ones (open season, the hunters' ladder, front lines,
   power struggles, executions, V's own streets, run with a crew, ransom) start at a gentle frequency.
2. **Rival chrome's reach.** As planned it is stats, behaviour abilities and words, which the crash rules allow.
   Visible chrome (a Rival who looks more chromed) would need appearance changes or new records, which the rules
   forbid; it stays out unless I revisit that rule.
3. **Other mods.** Wannabe Edgerunner, Dark Future and Ambient Factions are read through reflection only and are
   never required. If any of their APIs cannot be found on probing, that item is dropped rather than guessed.
4. **Order.** 2.3.1 and 2.3.2 could have swapped if the gang codes mattered more than the street; everything from 2.3.3
   on depends on both, and the version numbers stay in order whatever ships first.
5. **Playtesting.** Changed 2026-11-18: I stopped building at 2.4.2, and after the bug pass over every system I
   play 2.3.1 to 2.4.2 together. Before that, the rule was: every release is pushed when its release checks pass,
   and I play at the end of each major phase: **2.3.4** (the street and the gangs; was 2.3.3 before gang life
   shipped in two), **2.4.4** (the war, the hunt, Rivals, allies, the telling) and **2.5.0**. Because nothing is
   played between those, each release's bug check also re-checks the releases before it in the same phase where
   they meet.
6. **The crew in 2.5.0.** Added 2026-11-18. 2.5.0 was meant to take no new idea; the crew is the exception,
   because it is where the Rivals (6) and allies (7) groups were always heading and it needs both. It ships on by
   default with betrayal on, and Come on their own off until I have played it.
7. **Still open after 2.5.0.** Settled 2026-11-18: the map remembering [85] is built, with pins of its own and its
   own box in the map's filters the way Gang Retaliation does it, on a filter type and a variant nobody else uses;
   Ambient Factions [92] is dropped; a lookout escaping to move a Rival's lead [U10] and a ripperdoc as a lead [U9]
   are built. All of it is in 2.5.0.

# Changelog

All notable changes to Cyberbane are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-28

First full release. Everything below is what changed since 0.1.19.

### Fixed
- **Wounding someone and walking away now makes a Rival.** Cyberbane only remembered an enemy
  if it first decided they should run, so half of everyone you shot to the brink and left
  behind was never even considered. It remembers them either way now. This is the one that
  was stopping "leave them alive" from working.
- **A gang that never managed to send its apex no longer loses the bodies anyway.** The kill
  count was spent the moment the warning went out, so if the hunter failed to turn up for any
  reason you were charged twenty kills for someone who never arrived, and it looked like the
  feature did not exist. The count is only spent once they are actually there.
- **Nobody arriving at all is no longer possible.** Cyberbane looks for solid ground before it
  puts anyone down, and if that search came up empty it simply did not place them. One bad
  search quietly switched off Rivals, hit squads and apex hunters together. It now falls back
  to putting them in close rather than not at all.

### Added
- **Enemies have nerve.** Who breaks and runs now depends on what they are. Rank and file
  crack, officers mostly hold, elites rarely run and bosses never do, instead of everyone
  rolling the same dice. Thanks to cshiai's Much Better AI for the idea of giving each enemy a
  temperament rather than one global chance.
- The Hub's gang screen counts down to each gang's apex hunter, so you can see how close they
  are instead of guessing.

## [0.1.19] - 2026-10-28

### Fixed
- **Stealth takedowns were invisible to the mod.** Cyberbane worked out who was responsible
  for a body from damage events, and a takedown does not produce one. So knocking someone out
  never made them a Rival no matter how many you spared, and a lethal takedown earned no
  reputation at all. Takedowns are now recognised, lethal and non-lethal both. If sparing
  people has done nothing for you, this is why.
- Sparing someone used to take two minutes of standing around before anything came of it.
  It now settles in about twenty-five seconds.
- **Witnesses have to be able to see you.** Anyone inside the radius counted before, even
  through a wall or on another floor, which made quiet work far harder than it looked. Line
  of sight is checked now, so cover and walls do what you would expect.

### Changed
- Rivals come from sparing and from enemies who get away far more often: sparing is roughly
  double what it was, and survivors and avengers are up as well. They were rare enough that
  players could spare a dozen people and never see one.

### Compatibility
- **Much Better AI** is detected automatically and needs no setup. Its Nerve system owns
  morale, so Cyberbane stops pushing the same enemy to panic and stops breaking the same squad
  on top of it. Everything else Cyberbane does carries on, including tracking who got away, so
  Rivals still come from enemies that Much Better AI sent running.

## [0.1.18] - 2026-10-27

### Fixed
- **The Hub's first screen was writing over itself.** The Legend tab had grown past the space
  it was given, so the bottom of it ran straight through the footer line and off the end of
  the panel. The panel is taller now, the text sits at a size that fits, and the wording is
  tighter. Nothing was dropped.
- The Hub can no longer overflow like that again, whatever gets added to a screen later. If a
  screen ever runs long it now ends in a visible "..." instead of printing over the panel.
- Your current district reads properly in the Hub. It said "SantoDomingo" where it should say
  "Santo Domingo".

## [0.1.17] - 2026-10-27

### Fixed
- **Titles name the place or the gang now.** "Butcher of the District" was never meant to be
  the title you earned, and the readme has been advertising "Butcher of Watson" the whole
  time. Six titles were shipping placeholder wording because the part that fills in the name
  was never written. They now read Butcher of Watson, Ghost of Pacifica, Heywood's Problem,
  The Merc from Watson, the Animals' Nightmare and Friend of the Mox. This also fixes titles
  you have already earned, so you do not need a new save to see it.
- **Mercy counts however they went down.** Sparing someone only registered when they dropped
  to a hit Cyberbane could see. Anyone who went down to a burn, a quickhack tick, an
  explosion or another mod's damage could end up beaten and breathing with Cyberbane none the
  wiser, so walking away earned you nothing. It now checks downed enemies directly, whatever
  put them there. If you use a dismemberment or gore mod, this is the one that was biting you.
- **Someone who dies after you spare them no longer comes back as a Rival.** If you left
  somebody alive and they bled out afterwards, they could still return with a grudge. They
  are dead, so now they stay dead. Leaving them alive and walking off still works exactly as
  before.

## [0.1.16] - 2026-10-27

### Added
- **Word spreads because somebody saw it.** Every kill used to count as though a crowd had
  watched it. Cyberbane now checks who was actually alive and close enough to see, and that
  decides how far the story travels. Leave people alive and your name moves fast and far.
  Leave nobody and the street never learns who did it: you build almost no reputation you can
  claim, word barely leaves the district, and the place gets a name for something it cannot
  identify instead. Two ways to play fall out of one rule, and it is now a decision in every
  fight rather than a number on a timer.
- **The street gets word back to you.** When a rumour about you reaches a district it had not
  touched before, someone who trades in information may get in touch about what they heard.
  If people saw you do it, your name is in the message. If nobody did, it arrives as a
  question about who is doing this. These are Cyberbane messages rather than calls from real
  fixers, and they switch off with the rest of the mod's messages.
- **A gang does not lose its best and move on.** Put a Rival down and someone can step into
  their place carrying the same grudge, inheriting the standing of the one they replaced
  instead of starting from nothing. The higher the one you killed, the likelier it is. You
  can no longer decapitate a crew in a single fight.

### Changed
- The Hub counts the work nobody saw, and explains what it is worth.
- The Log is now the file the street keeps on you, put together from what people actually
  witnessed. Work nobody saw never reaches that page.
- Because of the witness change, killing in an empty place now builds far less reputation
  than it did. That is the point of the feature, but it will feel different if you have been
  working quietly. Nothing was taken away from what you have already earned.

## [0.1.15] - 2026-10-27

### Fixed
- Rivals, hit squads and apex hunters no longer arrive hanging in mid-air. They were being put
  down at your own height, which is right on flat ground and wrong everywhere else: on a motel
  walkway, a stairwell, a raised lot or the lip of an overpass, the spot behind you sits over a
  drop, and whoever came for you stood in the air above it until something knocked them loose.
  Cyberbane now finds the floor that is actually under that spot and puts them on it. Where
  there is no floor there at all, they come in closer to you instead of being placed blind.
  Thanks to the player who reported this from the Sunset Motel during Ghost Town, with the
  version and patch attached.

## [0.1.14] - 2026-10-27

### Changed
- The conduct axis now runs Professional to Cyberpsycho in the Hub. It is what Night City would
  actually call it, and it reads a lot better than the old wording.
- The heavy a gang sends now scales with your build. It reads the same measure of how dangerous
  you are that the rest of the mod uses, your level, Street Cred and skills together, so an early
  character meets something beatable and a maxed-out merc meets something that can actually take
  a beating. The Hub shows roughly how tough the next one will be.

### Fixed
- Cyberbane no longer remembers a one-off story character as the template for the people a gang
  sends after you. It keeps generic gang archetypes only, so you will never meet a walking
  duplicate of someone you already put down. Hit squads had the same gap and are covered too.

## [0.1.13] - 2026-10-27

### Changed
- The heavy a gang sends after you is a real fight now. It is still built from that gang's own
  toughest member rather than any story character, but it is lifted to boss grade, so it no
  longer goes down like the elite it was based on.

### Fixed
- Removed the last two places where Cyberbane kept a list inside a saved record. One of them was
  the same shape that caused the crashes people were reporting, and it turned out to be written
  but never read, so it is simply gone. Every list Cyberbane saves now sits where the game
  expects one. Your kill tallies by enemy type restart from zero as part of this, so one or two
  titles that count those may need earning again. Rivals, gangs, districts, reputation and the
  titles you already hold are untouched.

## [0.1.12] - 2026-10-27

### Added
- Keep hitting the same gang and they stop sending squads and send someone who matters. Put
  enough of one crew down and their apex comes looking for you: a named heavy built from the
  toughest member of theirs you have actually fought, with a couple of their people alongside.
  You get a warning line first, then they arrive. No story character is ever involved, so this
  cannot spoil anything or interfere with a quest, and it works for every gang rather than only
  the ones with a famous name. It uses the same setting as hit squads.
- The Hub counts the gang heavies and Rivals you have put down, so the ones you beat stay on
  the board.

### Compatibility
- If another mod already handles gangs coming after you, such as They Will Remember or Night
  City Remembers, Cyberbane now stands its apex enforcers down alongside its hit squads instead
  of sending a second wave on top of theirs. This is automatic and needs no setup.

## [0.1.11] - 2026-10-27

### Added
- Beat someone down and walk away and they can come back as a Rival who remembers it. Sparing
  an enemy was always meant to make a nemesis and never actually did. Finishing them off
  afterwards cancels it, as you would expect.
- The Hub explains itself now. Every screen says what its numbers mean instead of showing bare
  abbreviations, gangs list standing, fear and respect in words, and each Rival tells you how
  they came to hate you. The first screen ends with a line stating exactly what the city is
  doing about you right now, and what it would take to change that.

### Changed
- Night City reacts far more. The thresholds for people noticing you and backing off were set so
  high that most characters never crossed them, which made the mod look like it was doing
  nothing. They are much lower now, the reaction ranges are wider, and more people are checked
  at a time. Intensity and the per-moment cap are still yours to set.
- Visible cyberware counts for more and reads from further off. Chromed legs now count alongside
  arms, eyes and skin, and the more obvious your chrome the further away people clock it.
- Rivals turn up more often, and one that has climbed the ranks comes for you harder than a
  fresh one does.
- Overheard lines come a little more often and from a little further away.

### Fixed
- The Hub key could do nothing at all on some setups. It now works whether your setup reports the
  key press or the release, falls back to F7 when the key setting has not filled in yet, and
  registers itself at several points during startup instead of relying on a single moment.
- Hardened one more place that read an entry without checking it first, the same class of fault
  behind the earlier crashes.

## [0.1.10] - 2026-10-26

### Fixed
- **They Will Remember compatibility was never actually switching itself on.** The setting has
  an Auto mode, and the README said Cyberbane would spot the mod and stand down from the
  systems that overlap. The detection behind Auto had never been written, so Auto quietly
  behaved as Off and both mods ran their own hostility and hit squads side by side. Cyberbane
  now asks Mod Settings which mods are installed, which is the same list you see in the
  settings menu, and backs off when it finds They Will Remember. Night City Remembers is
  recognized too, since it replaces They Will Remember and overlaps the same way. You can
  still force the compatibility mode on or off yourself. If you have been running either mod
  alongside Cyberbane, this is the fix you wanted.
- **Cyberbane now leaves people alone in places the game treats as safe.** Apartments, clinics,
  bars, memorials and similar spots are tagged as safe areas by the game itself, and Cyberbane
  was ignoring that: crowd fear, gang reactions, morale breaks and panic driving all still ran
  inside them. Mourners at the North Oak columbarium would scatter from a well-chromed V, and
  driving the game's flee behaviour around a cramped interior is a bad idea besides. All four
  systems now stand down in a safe area. Thanks to the player who tracked their columbarium
  crashes down to this mod and reported it with the mod list attached.

### Note
Your build counts toward how frightening you are, not just your reputation, so a New Game Plus
character carrying maxed-out chrome and skills reads as terrifying from the first minute even
on a fresh save. That is working as intended out in the city. It is the reason the safe-area
fix above mattered so much in a quiet interior.

## [0.1.9] - 2026-10-26

This release fixes the crash the last three releases kept chasing. The earlier fixes all
treated it as a problem with how Cyberbane looked up its own data, because that is where the
crash reports pointed. It was not: the fault was in how rumors were stored, and each fix moved
it one step further down the same code path instead of removing it.

### Fixed
- **Fixed the recurring crash in the background tick, at the root this time.** Cyberbane spreads
  word of what you have done from one district to the next, and each rumor carried the list of
  districts it had already reached. That list was stored inside your save in a shape the game
  does not reliably bring back, and a list that came back malformed asked the game for an
  impossible amount of memory the moment the rumor spread, which crashed it. Rumors now track
  where they have been as a single number instead of a list, so there is nothing left to come
  back wrong. The same change was made to the traits your Rivals carry, which were stored the
  same way. Thanks to everyone who kept sending crash reports through 0.1.6, 0.1.7 and 0.1.8 -
  the stack traces are what made the real cause findable.
- **Crashes after finishing an NCPD crime.** Clearing a crime scene is the most common way to
  set a rumor going, so NCPD jobs were the likeliest thing to trigger the crash above. Finishing
  one also makes the whole encounter despawn at once, which is exactly when the background tick
  resumes after standing down - so the crash tended to land just after the job, rather than
  during it.
- **Cyberbane now checks its save data when you load.** Anything stored that does not make sense
  is repaired or dropped on load instead of being handed to the game later. This was documented
  behaviour that had never actually been written.
- **Closed off the rest of the same class of crash.** Six more places read a game system without
  first checking it was there, which is the same mistake behind the 0.1.6 crash - sleeping, fast
  travelling, loading or a cutscene could still catch any of them. They are all guarded now, and
  anything that looks up a game system goes through one checked path.
- Cyberbane no longer removes a spawned Rival from inside that Rival's own death, which could
  pull it out from under the game mid-death. The cleanup now happens a moment later, once things
  have settled.
- Reading the district you are in no longer queries the police system on every kill; kills use
  the value the background tick already sampled.
- A kill-streak that never ends, a long session spent turning gangs hostile, and a playthrough
  with many finished Rivals no longer grow their internal lists without limit.

### Changed
- Job payout bonuses are no longer paid twice on a single reward. An NCPD job that pushed your
  Street Cred over a level handed out two rewards at once, and Cyberbane was topping up the
  second one and then counting it again in the first.

### Note on saves
Your reputation, Rivals, titles, factions, districts and log all carry over. Rumors in flight
are cleared once on first load (they expire after three in-game days anyway, and the district
renown they had already earned you is kept), and Rivals start the new storage with a clean set
of traits, which fills back in as they climb. Nothing else is affected.

## [0.1.8] - 2026-10-26

### Fixed
- Fixed the remaining crash in the background tick, which could hit after a load as well as after
  a transition. Cyberbane looks up its content service through the game, and during a load or
  while the world is streaming that lookup could come back pointing at freed memory that still
  looked valid, so the game crashed when the slow tick used it. Cyberbane now looks that service
  up once, at a safe moment, reuses it from then on, and holds the slow tick until it is ready, so
  the tick never touches the unstable lookup again. Thanks to r3bels90 for pinpointing the exact
  call and cause.

## [0.1.7] - 2026-10-26

### Fixed
- The Hub now shows your current Renown and Dread the moment you open it, including right after
  a fast travel or sleep. Before this, the Street Cred floor on Renown and your chrome could read
  as 0 for a short time after a world transition, because those values were only refreshed on a
  slow timer. Opening the Hub now refreshes them on the spot.

## [0.1.6] - 2026-10-26

### Fixed
- Fixed a crash that could still happen after sleeping, fast travelling, skipping time, or
  entering a braindance. Cyberbane was looking up its own data while the game was mid-transition,
  before the service that holds it was ready, which crashed the game. Cyberbane now checks that
  the service is ready first and waits instead of crashing. Thanks to the players who tracked
  down the exact cause and shared their crash reports.

## [0.1.5] - 2026-10-26

Updated for Cyberpunk 2077 2.5.

### Changed
- Cyberbane now runs on Cyberpunk 2077 2.5. Install the 2.5 versions of the required
  frameworks (RED4ext, redscript, Codeware, Mod Settings).

### Fixed
- Reworked how Cyberbane runs during world streaming so it no longer reads world data while the
  game is still loading it in. Cyberbane stands its background systems down during loading, fast
  travel, time skips, and scenes, and resumes once the world has settled. This fixed the
  fast-travel crash.

## [0.1.1] - 2026-10-26

### Changed
- Everyone now reacts to how dangerous you look, not just civilians. Gang members and the
  police can also notice you and back off or flee. Visible cyberware now drives fear directly,
  so a heavily chromed V gets reactions even before building a reputation. Bosses and MaxTac
  hold their ground, and gangs with a vendetta still attack on sight.
- Your whole build counts. Your character level, Street Cred and skills now feed into how
  intimidating you are, so a high-level, skilled, well-known merc gets reactions a fresh
  character never would.

### Added
- Wounded enemies can lose their nerve and run. Catch them and that is the end of it; let one
  get away and it comes back as a named Rival with a grudge.
- Rivals are a proper nemesis now. They actually turn up and chase you, they climb the ranks
  while you leave them alone, and every time one escapes it returns a rank higher and scarred.
  Put down the one hunting you and it is finally finished.

### Performance
- The background NPC checks now do the heavier work only for nearby NPCs, and the tracked-NPC
  list is capped, so dense crowds stay smooth.

## [0.1.0] - 2026-10-25

First public release, available on [Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/35847).

### Added
- **Core runtime:** persistent per-save system and global cross-save service, logging,
  tunable config, shared types, the full Mod Settings page, and Codeware localization.
- **Reputation model:** Renown and Dread with their district/faction spread, archetypes
  (Butcher, Ghost, Professional, Chromed, Netrunner, Brawler), titles, and time decay.
- **Code axis:** a Night-City-flavoured conduct meter - Professional (clean, controlled
  work, mercy) versus Cyberpsycho (civilian kills, brutality) - that shifts how people read you.
- **Combat tracking:** kills attributed to you and classified by faction and class; an
  encounter tracker that flags massacres and boss-downs; Street Cred, police Heat and
  chrome (cyberware) all feed the model.
- **The city reacts:** recognized NPCs drop overheard whispers whose tone follows the
  faction's posture, your Code and notable kills (gang bosses, MaxTac). On-screen messages
  for rank-ups, titles, massacres and boss/MaxTac kills.
- **Crowds that react:** pedestrians read how frightening you are and, as you get close,
  cower or flee; once your reputation turns to terror the panic spreads through the crowd.
  How many react at once is capped so the streets never empty all at once.
- **Gangs that turn on you:** a gang you have pushed to a vendetta gives you one spoken warning
  the first time they place you, then attacks on sight. Turn the systems off and every attitude
  change is undone.
- **Enemies that break:** cut down enough of a squad and the survivors can lose their nerve
  and run, though someone always stands and fights. Those who get away can return as Rivals.
- **Vendor prices move with your reputation:** the more the city fears you (and the cleaner
  your reputation as a professional), the better your buy prices; a mad-dog reputation costs
  you extra. The swing is capped, set in Mod Settings, and only ever touches what you pay.
- **Tribute:** a gang you have made feared, but not yet pushed into open war, may quietly pay
  you eddies to stay on their good side. Pay enough gangs and you earn the Feared Landlord title.
- **Hit squads:** turn a gang hostile enough and they send people after you. A squad of the
  kind of member you have fought spawns out of sight and comes for you; squads never stack,
  sit on a cooldown, and clear themselves if you slip away. Give one the slip and a survivor
  can come back as a Hunter Rival. Toggle and frequency in Mod Settings.
- **Rivals that come to you:** a Rival who is hunting you can actually show up in the world,
  wearing the face and gang you remember, instead of only existing on the Hub.
- **The Hub:** a reputation screen in Cyberpunk's own style, opened with the Hub key (F7 by
  default, rebindable in Mod Settings). Each press steps through tabs for your standing (Renown,
  Dread, Code, Street Cred, and what the city fears you for), factions, rivals, titles, and a log
  of what you have done; the press after the last tab closes it. No menu and no mouse needed.
- **Rivals:** named, persistent enemies that rank up, carry traits, taunt about your
  history, and remember your deaths across saves. They climb the ranks on their own when
  ignored, and slaying one can raise an avenger from the same crew.
- **Rumors & districts:** notable deeds spread outward from where they happened, so your
  reputation builds locally before it goes city-wide.
- **Deeds & factions:** notable jobs shift Renown, Dread, faction standing and titles.

- **Gig payouts scale with your legend:** fixers and clients pay the famous more. Sizable job
  payouts get a bonus on top that grows with your Renown tier.
- **Panic driving:** when you are terrifying and fighting out in the open, nearby drivers panic
  and clear the street.
- **Disguise:** masks and hoods make you harder to place, and dressing in a gang's colours makes
  that gang slower to recognize you. (The clothing data this reads from is tuned over time.)
- **Broker peace:** pay a gang you can buy off to drop a hostility or vendetta. The price
  scales with how much blood is between you. From the Hub, hold Shift and press the Hub key to
  buy off the worst gang you can afford; mods can also trigger it through the public API.

- **Presets and titles from the Hub:** a Subtle / Default / Dramatic preset in Mod Settings tunes
  how loud and frequent reactions are in one pick. From the Hub, Ctrl and the Hub key cycle which
  title you wear, or leave it on Auto to always show your highest.

### Compatibility

- A They Will Remember compatibility mode: when it is on, Cyberbane stands down from the
  systems that overlap (hostility on sight, hit squads, faction disguises) and keeps the rest.

### Safety

- The systems that touch NPCs now leave companions, vendors, and anyone in a scripted
  scene or workspot alone, on top of the existing hands-off rule for quest characters.

_Built for Cyberpunk 2077 v2.31. Cyberbane is in active development, so expect frequent updates._

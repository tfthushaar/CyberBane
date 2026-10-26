# Changelog

All notable changes to Cyberbane are documented here.
This project follows [Semantic Versioning](https://semver.org/).

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
  work, mercy) versus Mad Dog (civilian kills, brutality) - that shifts how people read you.
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

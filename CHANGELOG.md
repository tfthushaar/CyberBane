# Changelog

All notable changes to Cyberbane are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Core runtime:** persistent per-save system and global cross-save service, logging,
  tunable config, shared types, the full Mod Settings page, and Codeware localization.
- **Reputation model:** Renown and Dread with their district/faction spread, archetypes
  (Butcher, Ghost, Professional, Chromed, Netrunner, Brawler), titles, and time decay.
- **Code axis:** a Night-City-flavoured conduct meter — Professional (clean, controlled
  work, mercy) versus Mad Dog (civilian kills, brutality) — that shifts how people read you.
- **Combat tracking:** kills attributed to you and classified by faction and class; an
  encounter tracker that flags massacres and boss-downs; Street Cred, police Heat and
  chrome (cyberware) all feed the model.
- **The city reacts:** recognized NPCs drop overheard whispers whose tone follows the
  faction's posture, your Code and notable kills (gang bosses, MaxTac). On-screen messages
  for rank-ups, titles, massacres and boss/MaxTac kills.
- **Crowds that react:** pedestrians read how frightening you are and, as you get close,
  cower or flee; once your reputation turns to terror the panic spreads through the crowd.
  How many react at once is capped so the streets never empty all at once.
- **Gangs that turn on you:** a gang you have pushed to a vendetta attacks on sight once
  they recognize you. Turn the systems off and every attitude change is undone.
- **Enemies that break:** cut down enough of a squad and the survivors can lose their nerve
  and run, though someone always stands and fights. Those who get away can return as Rivals.
- **Vendor prices move with your reputation:** the more the city fears you (and the cleaner
  your reputation as a professional), the better your buy prices; a mad-dog reputation costs
  you extra. The swing is capped, set in Mod Settings, and only ever touches what you pay.
- **Tribute:** a gang you have made feared, but not yet pushed into open war, may quietly pay
  you eddies to stay on their good side. Pay enough gangs and you earn the Feared Landlord title.
- **Hit squads:** turn a gang hostile enough and they send people after you. A squad of the
  kind of member you have fought spawns out of sight and comes for you; squads never stack,
  sit on a cooldown, and clear themselves if you slip away. Toggle and frequency in Mod Settings.
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

### Safety

- The systems that touch NPCs now leave companions, vendors, and anyone in a scripted
  scene or workspot alone, on top of the existing hands-off rule for quest characters.

_Cyberbane is in active development and has not had a public release yet._

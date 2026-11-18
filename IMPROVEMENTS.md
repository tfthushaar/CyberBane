# Cyberbane improvements

Ideas not built yet that fit the rules below: every entry here can be built with scripts alone, within the crash
rules and without changing an existing save's layout. Player requests are in [PLAYER_REQUESTS.md](PLAYER_REQUESTS.md);
what each version changed is in [CHANGELOG.md](CHANGELOG.md). Item numbers are kept as stable names, so a number
missing from the list is an idea that was dropped as not buildable.

The list comes from three places: what Cyberbane already has and could do more with; how other games handle
reputation, nemeses, gangs and being hunted; and what other Cyberpunk 2077 mods do and players keep asking for.
Sources are at the end. Ideas from other games and mods are taken as ideas: none of their code, numbers or text
is copied, and each is redesigned around what Cyberbane already has.

## The rules every idea has to fit

- **The crash rules** (in full in PLAYER_REQUESTS.md): no police or prevention-system calls, one AI order per
  NPC, no entity work inside attach events or on hit and death threads, removals only through
  `CBDeleteTaggedSafe`, nothing removed in V's sight, nothing read from an NPC before `CBNpcSafe` says it is
  safe, behaviour-only kits, no runtime appearance changes, no loot put on bodies, UI as data rather than
  injected widgets.
- **Scripts only**: no archives, no TweakDB records, no audio files.
- **Saves**: no new `persistent let` on a class that is already saved, because it wipes everyone's progress.
  New saved state goes in a system of its own (the `CBTurfBook` and `CBIntelBook` pattern).
- **Nobody the game wrote speaks for Cyberbane.** No fixer, romance partner or story character sends its texts
  or says its lines (`UI/PhoneMessages.reds` says why). Its voices are its own: gangs, brokers, Rivals, unknown
  numbers, people in the street.
- No retired `.reds` file is deleted; it becomes a stub (`tools/check_removed.ps1`).

**Sizes.** **S**: numbers, text, or one small hook. **M**: a new state machine on pieces that already exist.
**L**: new spawns, several systems at once, or something to prove in game first. **Verify**: an engine call to
probe on 2.31 and 2.5 before anything is built on it.

---

## If you build ten

By impact for the effort, most first:

1. *(Built in 2.4.6: voices, with the game's own lines.)*
2. *(Built in 2.3.2: gangs that adapt, and a code for each gang.)*
3. *(Built in 2.4.3: the corporations, who hire killers.)*
4. *(Built in 2.4.4: the facedown, and the rest of the Rivals' stories.)*
5. *(Built in 2.4.3: a price on V's head, and the hunters' ladder.)*
6. *(Built in 2.3.3: funerals and the rest of gang life's gatherings, deals and rackets.)*
7. *(Built in 2.4.0: back a gang, the war chest, and the rest of the turf war.)*
8. *(Built in 2.4.5: run with a crew, and the rest of talk and allies.)*
9. *(Built in 2.4.6: panic in the dark.)*

## 3. Gang life

Built in 2.3.3 and 2.3.4 (`Spawn/StreetEvents.reds`): every idea that was here.

## 4. Turf and war

Built in 2.4.0 (`Economy/War.reds`, `Model/WarBook.reds`): every idea that was here.

## 5. Being hunted

43. **Sound before contact.** *(Not built in 2.4.1: no door or engine sound event could be confirmed in the game's own scripts; the apex horn is the one verified sound.)* An engine and a door slam when a car crew gets out within earshot, a phone buzz
    when the HUD line changes, played on the player as the apex horn already is. **S** *(old backlog 8)*
## 6. Rivals

Built in 2.4.4 (`Rivals/RivalMoments.reds`, `Rivals/RivalBook.reds`), except a Rival of your own, which is
the first member of the crew in 2.5.0.

59. **A Rival of your own.** A Rival spared twice and frightened enough can be made V's: they stop hunting, text
    intel (as the Debtor does) and can be called by text once a day to come and fight beside V. **M**
## 7. Talk

Built in 2.4.5 (`Reactions/Allies.reds`): every idea that was here.

## 8. Who V is

76. **Humanity.** *(Not built in 2.3.1: Wannabe Edgerunner was not installed to probe its API, and the rule is to drop rather than guess.)* With Wannabe Edgerunner installed, read through its API: low humanity frightens crowds and
    warms Maelstrom, V's episodes become rumours ("the merc's going psycho"), and killing somebody who surrendered
    costs humanity. **S to M**
77. **Nerve.** *(Not built in 2.3.1, for the same reason with Dark Future.)* With Dark Future installed: a facedown, open season or being badly outnumbered drains V's Nerve,
    and a win restores some. **S**

## 9. How it is told

Built in 2.4.6 (`Narrative/Telling.reds`), and the map remembering in 2.5.1.

*(85, the map remembering, built in 2.5.1: `UI/MapPins.reds`.)*

## 10. Rewards, settings and other mods

92. *(Dropped in 2.5.1 at my word: not installed here, and not wanted.)* **Ambient Factions of Night City.** Count its gangs' people as their gang's, and have the lanes stand back
    while it has a gang war going near V. **S**

---

## Sources

Other games:

- Shadow of Mordor and Shadow of War: [power struggles](https://gamerguides.com/shadow-of-mordor/guide/side-quests/power-struggles),
  [domination, betrayal and death threats](https://www.rpgsite.net/feature/6192-shadow-of-war-domination-guide-the-nemesis-system-betrayal-death-threats-resurrection-and-more-orc-dominating-mechanics-explained),
  [the Nemesis system and orders](https://www.gamepressure.com/middle-earth-shadow-of-war/nemesis-system-and-orders/z8a32b)
- Assassin's Creed Odyssey: [the mercenary system](https://www.pushsquare.com/news/2018/10/guide_assassins_creed_odyssey_mercenaries_-_how_to_beat_them_bounties_tiers_and_rewards),
  [a wanted system enforced by named mercenaries](https://gamesradar.com/assassins-creed-odysseys-wanted-system-is-enforced-by-mordor-style-mercenary-characters)
- Metal Gear Solid V: [the revenge system](https://metalgear.fandom.com/wiki/Revenge_System_(enemy_preparedness))
- Ghost of Tsushima: [standoffs](https://primagames.com/tips/how-master-standoffs-ghost-tsushima),
  [the legend system](https://samurai-gamers.com/ghost-of-tsushima/legend-level-guide/)
- Fallout: New Vegas: [reputations and disguises](https://fallout-archive.fandom.com/wiki/Fallout:_New_Vegas_reputations)
- Red Dead Redemption 2: [honor](https://reddead.fandom.com/wiki/Honor)
- Mafia III: [rackets and underbosses](https://kotaku.com/mafia-iii-promises-an-open-world-that-you-can-actually-1782839184)
- Crusader Kings III: [schemes, secrets and hooks](https://forum.paradoxplaza.com/forum/threads/ck3-dev-diary-5-schemes-secrets-and-hooks.1289167)
- Watch Dogs: Legion: [the play-as-anyone simulation](https://gamedeveloper.com/design/how-watch-dogs-legion-s-play-as-anyone-simulation-works),
  [relationships and revenge](https://www.videogameschronicle.com/reviews/watch-dogs-legion/)
- Sleeping Dogs: [Face and Triad reputation](https://en.wikipedia.org/wiki/Sleeping_Dogs_(video_game))
- Grand Theft Auto: San Andreas: [gangs and turf wars](https://gtabase.com/gta-san-andreas/gangs),
  [recruiting](https://www.grandtheftwiki.com/Recruiting)
- Far Cry 5: [resistance and escalation](https://en.wikipedia.org/wiki/Far_Cry_5)
- RimWorld: [AI storytellers](https://rimworldwiki.com/wiki/AI_Storytellers)
- Batman: Arkham Asylum: [enemy design](https://store.epicgames.com/news/the-verbs-and-villains-that-shape-rocksteady-s-batman-arkham-asylum)
- Kingdom Come: Deliverance: [reputation](https://kingdomcomedeliverance.wiki.gg/wiki/Reputation),
  [cleanliness](https://kingdomcomedeliverance.wiki.gg/wiki/Cleanliness)

Cyberpunk:

- Cyberpunk RED: [reputation and facedowns](https://www.worldanvil.com/w/cyberpunk-konigskind/a/reputation-article),
  [gangs and combat](https://rtalsoriangames.com/2020/10/29/cyberpunk-red-alert-gangs-and-combat)
- The gangs' lore: [Cyberpunk 2077 gangs explained](https://www.gamesradar.com/cyberpunk-2077-gangs-explained)
- The gang critique: [issues, shortcomings and ideas](https://www.gamepressure.com/newsroom/cyberpunk-2077-issues-shortcomings-and-ideas-how-to-salvage-the-g/zc2a18)
- Update 2.3: [autodrive and Delamain taxis](https://www.cyberpunk.net/update-2.3)

Other Cyberpunk 2077 mods:

- [They Will Remember](https://nexusmods.com/cyberpunk2077/mods/19747)
- [Ambient Factions of Night City](https://www.notebookcheck.net/A-new-mod-adds-gangs-turf-wars-and-clashes-with-the-police-in-Cyberpunk-2077.1164109.0.html)
- [Gangs of Night City](https://nexusmods.com/cyberpunk2077/mods/7233)
- [Wannabe Edgerunner](https://pcgamer.com/cyberpunk-2077-mod-turns-you-into-a-real-edgerunners-cyberpsycho)
- [Dark Future](https://www.nexusmods.com/cyberpunk2077/mods/16300)
- [Immersive NPCs](https://www.pcgameshardware.de/Cyberpunk-2077-Spiel-20697/News/Mod-Immersive-NPCs-Begleiter-rekrutieren-1558568/)
- Tools: [Audioware](https://wiki.redmodding.org/cyberpunk-2077-modding/modding-guides/sound/custom-sounds-and-custom-emitters-with-audioware),
  [Codeware](https://github.com/psiberx/cp2077-codeware/releases)

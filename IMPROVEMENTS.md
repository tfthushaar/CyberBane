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

1. **Voices for the moments** (79). The people Cyberbane moves finally sound like it, in their own voices.
2. *(Built in 2.3.2: gangs that adapt, and a code for each gang.)*
3. **What is left of the codes** (11, 18, 20): the Claws' protection and assassin, the Wraiths' road, the corps.
4. **The facedown** (53). A Cyberpunk-canon moment before every Rival fight.
5. **A price on V's head, and the hunters' ladder** (39). A second nemesis line with a goal of its own.
6. **Funerals** (22). Closes the loop on every Rival V kills, and feeds kin.
7. **Back a gang, and the war chest** (33, 34). A side to take and a strategy in the turf war.
8. **Run with a crew** (65). The payoff for being liked.
9. **Panic in the dark** (80). Stealth play gets the terror loud play already has.
11. **Tyger Claws: protection and the assassin.** (The rest of their code, a cheap peace and a dear insult, is
    built.) Working Japantown draws a weekly protection demand by text, and a crew if V ignores it; when they
    want V dead they send one assassin with a blade at night, not a crowd. Fits with 2.4.0's tribute and peace
    by text ([U6]) and 2.4.1's hunts. **M**
18. **Wraiths: the road.** (The Aldecaldos' family code is built.) Wraiths ambush V's car on Badlands roads:
    the car ambush, out there, with [E2] in 2.4.1. **S**
20. **The corporations: money, not grudges.** Arasaka, Militech and Kang Tao send no gangers. They post a
    contract on V and hire solos (item 39), and they can be bought off at a corporate price. **M**

## 3. Gang life: events with a time and a place

Built on the sit-down's machinery: a time, a place, a pin once V hears of it (item 32), spawns out of sight, and
an outcome whether or not V turns up. *(Shadow of Mordor's and Shadow of War's power struggles; the old item 20)*

22. **Funerals.** A day after V kills a Rival or a lieutenant, their people gather on their turf to remember
    them. Attack it: their hatred doubles (the Valentinos never forgive it) and kin may swear revenge on the spot.
    Stay away: nothing. Walk up empty-handed with good standing: **[Pay respects]** eases the grudge, though the
    dead one's kin may still spit. **M**
23. **Celebrations.** A gang celebrates a win (turf taken, V's crew beaten): a lieutenant drinking with their
    people in a club's back room or a street party. Crash it and the lieutenant is easy to reach; leave it and
    the gang grows stronger in that district. **M**
24. **Initiations.** A recruit has to prove themselves: rob a shop, beat somebody, kill somebody. V comes upon
    it and stops it (the recruit runs, the gang is annoyed, the street likes it) or lets it happen. **M**
25. **Recruitment drives.** A gang signs up new blood in a district; unless V scatters them, its turf there
    grows faster for a day. A broker's text says where. **M**
26. **Hunts.** A gang chasing somebody through the streets (an informant, a debtor) runs them past V. Shelter
    them (**[Get behind me]**) and they owe V tips; hand them over for the gang's standing; or look away. **M**
27. **Executions.** A lieutenant executes a prisoner at a marked place at a set hour. Stop it and the prisoner
    owes V; let it happen and the street hears V let it. The one part of the old item 20 not built. **M to L**
28. **Arms deals.** Two gangs, or a gang and a corporate fence, trade guns at a set place. Hit it: the loot goes
    to V's inventory, both sides lose strength, and buyer and seller blame each other. **M**
29. **Rackets.** Each gang's business as a place V can hit, found through intel (the squeeze, scans,
    informants): the Valentinos' chop shop, the Claws' BD den, the Scavs' clinic, Maelstrom's chrome workshop,
    a stash house. Hitting one drains the war chest (item 34) and the district's strength. **M** *(Mafia III)*
30. **Front lines.** In a contested district, the two gangs' people clash now and then: both sides spawned out
    of sight and set hostile to each other, the way Cyberbane already sets its people against V's companions.
    V can pick a side; the winner pushes the turf. **M to L** *(Ambient Factions of Night City; San Andreas's
    turf wars)*
31. **Power struggles.** When a leader dies, two lieutenants fight for the chair (`Rivals/Hierarchy.reds` has
    the seats). For a few days each texts V asking for help against the other. Back one and they win and owe V;
    kill both and the gang is leaderless, weaker and wilder for a while. **M to L** *(Shadow of War)*
32. **Word of what's coming.** Overheard lines and broker texts mention an event before it happens ("Claws are
    burying Kenji tomorrow night, by the shrine"), so V can plan for it instead of only stumbling on it. Rumour
    engine, `Narrative/Whispers.reds`. **S**

## 4. Turf and war

33. **Back a gang.** Pick one gang on the Turf screen. What V does to its enemies in a district counts double for
    it there, its gains are V's news, and holding a district for it pays V a weekly cut (the tribute path) and
    raises standing. The half of "be part of the turf wars" still missing in PLAYER_REQUESTS.md. **S to M**
    *(San Andreas)*
34. **The war chest.** Each gang has money. Bagmen, rackets and tribute fill it; crews, apex squads and the
    eddies it pays out empty it. Robbing bagmen and hitting rackets slows how often it can send people, and the
    Hub says it in words ("flush", "counting every eddie", "broke"). **M** *(Mafia III)*
35. **Manpower.** A massacre empties a gang's ranks for a while: its crews come smaller and greener, it hires
    outsiders in its colours, or it sends nobody, and it fills back up over days. Strength already falls; this
    makes it show in who turns up. **S to M**
36. **A common enemy.** When V is a terror to two gangs at war with each other, they call a truce against V for a
    while: their people stop fighting each other and a joint crew comes. Rare, and a big moment when it happens.
    **M**
37. **V's own streets.** At legendary standing, a district where V has broken every gang and nobody holds it
    becomes V's: no crews are sent there, the street greets V, and a gang passing through pays V for the
    privilege. The endgame of the turf war. **L** *(San Andreas; Saints Row)*

## 5. Being hunted

39. **A price on V's head, and the hunters' ladder.** A gang, a corporation or a Rival can post a bounty on V.
    Named independent hunters take it: a roster of solos, each with a look, a trait, a signature and a rank from
    ten to one, who come alone or in pairs at their own time. Kill one ranked above V and V takes their place on
    the ladder (a Hub page); at the top V is the most dangerous merc in Night City. The bounty ends when V pays
    it, or kills whoever posted it. A hunter V beats and leaves alive can become a Rival. **L** *(Assassin's
    Creed Odyssey's mercenaries; New Vegas's hit squads)*
41. **Lie low on purpose.** Staying off a gang's turf, out of fights, or in a safe place cools that gang faster,
    and the Hub says each gang's heat in words. Changing clothes out of sight or leaving the district gives an
    extra chance the trail goes cold. **S** *(old backlog 4 and 12)*
42. **Lose them on the metro or in a cab.** Riding the NCART or a Delamain cab out of the district while hunted
    loses them, if no hunter saw V get in. Cyberbane already knows when V is on the metro (it holds arrivals
    then). **S** *(2.1's metro, 2.3's taxis)*
43. **Sound before contact.** An engine and a door slam when a car crew gets out within earshot, a phone buzz
    when the HUD line changes, played on the player as the apex horn already is. **S** *(old backlog 8)*
44. **A fair first volley.** For two seconds after a hunter first sees V, their accuracy is lowered through the
    existing build pass, so the opening shots are not the end of the fight. **S** *(old backlog 20)*
45. **A cost for running.** When a crew or apex squad loses V in a straight run (not by stealth or disguise), the
    gang texts something dismissive and V loses a little renown with them. **S** *(old backlog 15)*
46. **Hunters who learn V's haunts.** Rivals and crews are likelier to wait near where V spends time: the district
    V is in most, the street outside V's apartment (never inside a safe area), a bar V keeps going back to.
    **S** *(old backlog 22)*
47. **Waiting on V's road.** With a job tracked far away, a vendetta crew may wait near the destination, outside
    its quest clearance, and spring when V arrives. **M**
48. **Open season.** The top of a gang's anger: its leader declares open season for one in-game day. A crew every
    hour, every one of its people hostile on sight citywide, its Rivals together. Survive the day, kill the
    leader, or pay a crippling price; surviving earns a title and leaves the gang afraid for a week. **M**
    *(Far Cry 5's escalation tiers)*
49. **Tracked.** A Rival's netrunner can plant a tracker on V with a quickhack. Until V visits a ripperdoc, that
    gang always knows the district V is in, and the HUD line says TRACKED. **S to M**
50. **Lookouts in the crowd.** On hostile turf, one passer-by is really the gang's lookout. A scan shows it; deal
    with them (talk, a takedown) before they report V and the turf provocation never happens. **M**

## 6. Rivals

53. **The facedown.** When V and a Rival meet face to face (the announcement's beat), V chooses:
    **[Stare them down]** (Cool and renown against their rank and nerve), **[Draw]** or **[Walk away]**. Win and
    some of their people break and run, and the Rival fights shaken; lose and their crew is emboldened; walk away
    and they let V go once, and the street hears of it. **M** *(Cyberpunk RED's Facedown; Ghost of Tsushima's
    standoff)*
54. **Just you and me.** A fourth choice at the facedown: their crew holds back (the hold state talk already
    uses) and the Rival fights alone, until V breaks the terms (a gun in a fistfight, a grenade). Valentinos and
    Animals accept more often. **M**
55. **Humiliation.** A fourth line at mercy: **[Humiliate]**. They lose rank and their nickname turns mocking;
    they either quit the gang or come back obsessed (a Rival who hates V, sometimes a cyberpsychotic break). The
    gang fears V more. **S to M** *(Shadow of War's shaming)*
56. **Back from the dead.** Rarely, a Rival V killed comes back weeks later, rebuilt by a back-alley ripperdoc:
    heavier chrome, a new nickname, a line about it. Never one V finished with a fatal flaw or a finisher, so a
    death V made sure of stays a death. **S to M** *(Shadow of Mordor)*
57. **Rivals at war with each other.** Rivals of gangs at war hunt each other between V's encounters, and one
    can kill the other off screen (in the History; the winner climbs). V can arrange it by passing one the
    other's hiding place, from a **[Collect]**. **M**
58. **Bonds beyond kin.** Each Rival gets one bond on their page: a mentor, a protégé, a lover, a partner. Killing
    one moves the other (vengeance, fear or quitting); sparing one puts the other in V's debt. Kin and bodyguards,
    generalised. **M** *(Watch Dogs: Legion's relationships)*
59. **A Rival of your own.** A Rival spared twice and frightened enough can be made V's: they stop hunting, text
    intel (as the Debtor does) and can be called by text once a day to come and fight beside V. **M**
60. **Trophies.** Killing a named Rival gives V something of theirs: the weapon from their record, into V's
    inventory, named in the History. The bigger the Rival, the better the trophy. **S to M** *(old backlog 17)*
61. **Where they ended up.** A Rival who retired or was run out of town is not gone for good: months later a
    text from them, a small job, a warning, or an invitation to finish it. **S**
62. **Places with meaning.** A Rival who calls V out picks somewhere that matters: where V first beat them, where
    their kin died. Positions are already kept for leads and the call-out. **S**
63. **Last words.** A dying Rival says something of their own, from their history with V. **S**
64. **A Rival on their feet.** A Rival met in the street who is not fighting (a Debtor, one holding back from
    fear) gets lines of their own: **[Call it even]**, **[Where's (another Rival)?]**, **[Get out of Night
    City]**. The one part of "talking to a Rival" left out of 1.9.9. **M**

## 7. Talk

65. **Run with a crew.** With a gang Friendly or better, **[Watch my back]** on one of its people: one to three of
    them follow V for a while (one follow order each) and fight whoever fights V, set the way companions are set
    against Cyberbane's crews. They go home after an hour, if V leaves their turf for long, or if V shoots one.
    Once a day. **M to L** *(San Andreas's recruits; Gangs of Night City's allies)*
66. **One of theirs.** At Allied, a gang offers to make V one of its own. Accept and its people greet V by name,
    V counts as wearing its colours everywhere, its enemies treat V as one of them, and favours become duties: a
    weekly ask, and standing falls if V ignores too many. Leave whenever V likes, at a cost. **M**
67. **Ransom.** Hold a ganger who surrendered: **[Ransom]** texts their gang, which pays or sends a crew to take
    them back. Or let them go, or hand them to a gang at war with theirs for its standing. **M** *(Mount &
    Blade)*
68. **Bribe a lookout.** Pay a gang's lookout to look the other way: V's presence on their turf goes unreported
    for an hour. **S**
69. **Feed the street a lie.** **[Spread the word]** to a talkative passer-by or a frightened ganger: "I'm headed
    to Pacifica", "Tell them I'm dead". A Cool check against how well the gang knows V. Success sends the next
    scout or crew to the wrong place, or cools the gang for a while; failure, or a liar's temper, sells V out and
    they come sooner. **M** *(Crusader Kings' schemes)*
70. **Set gangs on each other.** Tell a ganger their enemies are planning a hit on them. Success raises the chance
    of a front-line clash (item 30) between those gangs, and a little turf moves. **M**

## 8. Who V is

76. **Humanity.** *(Not built in 2.3.1: Wannabe Edgerunner was not installed to probe its API, and the rule is to drop rather than guess.)* With Wannabe Edgerunner installed, read through its API: low humanity frightens crowds and
    warms Maelstrom, V's episodes become rumours ("the merc's going psycho"), and killing somebody who surrendered
    costs humanity. **S to M**
77. **Nerve.** *(Not built in 2.3.1, for the same reason with Dark Future.)* With Dark Future installed: a facedown, open season or being badly outnumbered drains V's Nerve,
    and a win restores some. **S**

## 9. How it is told

79. **Voices for the moments.** People speak at Cyberbane's moments in their own voices, using the game's own
    voiceset lines: a taunt as the announcement starts, a scream when they break, a plea when they surrender, a
    greeting from a friendly gang. Played with `GameObject.PlayVoiceOver`; the context `Scripts:CBStreetTalk` is
    already reserved in Cyberbane's wrap of it. No new audio. **S to M, verify** (the line names on both patches)
80. **Panic in the dark.** When V picks off a crew one by one unseen, the rest grow afraid: lines in the subtitles
    ("Where'd he go?!", "Kenji's not answering"), they bunch up, their nerve falls faster, and one may run.
    Morale and the subtitles. **S to M** *(Batman: Arkham's predator rooms)*
81. **The screamsheet.** A Hub page of headlines in Night City's tabloid voice, written from the History: "MERC
    GUTS CLAW BOSS IN KABUKI", "6TH STREET LOSES ARROYO", a few a day. Data UI only. **S to M** *(Cyberpunk's
    screamsheets; Dwarf Fortress's legends)*
82. **The legend, told.** A button on the History page that tells V's story in a few paragraphs, from the biggest
    entries, the way the street would tell it. **S**
83. **Morning brief.** At dawn each in-game day, one broker text: what happened overnight, who is hunting V, what
    is coming. **S**
84. **A Rival's story on their page.** Their history with V as a timeline: how they were born, each scar, each
    meeting, the texts, where they were last seen. **S**
85. **The map remembers.** For a day, the Turf map pins where things happened: a Rival's death, a crashed
    sit-down, a takeover. **S**

## 10. Rewards, settings and other mods

87. **Street Cred follows the legend.** The biggest deeds (a Rival's death, a sit-down crashed, open season
    survived) give a little of the game's own Street Cred, so its vendors and gigs follow. **S, verify** (the
    experience call)
88. **Corporate interest.** At legendary standing, a corporation takes notice: a Cyberbane contact (never a story
    character) offers a contract against a gang or warns V off. **S to M**
89. **Harder means harder fights.** On Hard and Very Hard, smaller crews, longer spawn distances, shorter hunter
    sight and longer warnings, so harder means harder fights rather than instant deaths. **S** *(old backlog 18)*
90. **Presets with a shape.** Presets that change what the mod is about, not only how much: **Nemesis** (Rivals
    first), **Turf war** (gangs and districts first), **Quiet life** (the street and talk, nobody hunting).
    **S**
91. **Events other mods can hear.** Codeware custom events ("Cyberbane/RivalSlain", "Cyberbane/StandingChanged",
    "Cyberbane/HuntStarted") alongside `API/CyberbaneAPI.reds`, so other mods react without calling in. **S**
92. **Ambient Factions of Night City.** Count its gangs' people as their gang's, and have the lanes stand back
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

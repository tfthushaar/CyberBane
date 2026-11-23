// Cyberbane - English, the language every other one falls back to (2.7.1)
//
// Every line Cyberbane shows the player is in this one file: one class, one method per part of the mod. The code asks for
// a line by its key (CBT and CBTf, in Localization/Text.reds). Log lines are not here: they are for bug reports.
//
// To translate Cyberbane:
//   1. Copy this file into a folder of your own beside Cyberbane's, for example r6/scripts/Cyberbane_de/English.reds,
//      and rename the copy (German.reds). Your own folder, so updating Cyberbane never overwrites your work.
//   2. In your copy, replace CBLocalizationEnUs with CyberbaneText_ and your language with its dash as an underscore:
//      CyberbaneText_de_de, CyberbaneText_fr_fr, CyberbaneText_es_es, CyberbaneText_pt_br, CyberbaneText_ru_ru,
//      CyberbaneText_zh_cn and so on, the codes the game uses for its interface languages. Cyberbane finds your package by
//      that name.
//   3. Replace the module line just below with one of your own, for example: module CyberbaneDe
//      Keep the import line as it is.
//   4. Translate the second text in each this.Text(...) line and leave the first one, the key, exactly as it is.
//      Numbered slots like {0} and {1} are filled in by the game (a gang, a place, a number): put them wherever your
//      language needs them, in any order. A line you have not translated yet can be deleted, and the English shows
//      there instead. Keep every method, even an empty one.
//   5. A line spoken to V can have a female and a male form: this.Text(key, "female", "male").
//   6. Comments above a line say what fills its slots.
//   7. Keep these as they are, because Cyberbane reads them: a talk choice's tag in square brackets and the space after
//      it ("[Greet] ", translate the word inside if you like), straight double quotes round a nickname (\"Wall\"),
//      the three spaces before a bracket in a Hub line ("   ("), \n line breaks, and a leading space where a line has one.
//      Notes start with a small letter, because the game puts "Cyberbane: " in front of them.
// When Cyberbane adds or changes lines, they show in English until your file has them; each release's changelog says
// which parts of this file changed.

module Cyberbane.Localization

import Codeware.Localization.*

public class CBLocalizationEnUs extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    this.DefineSettings();
    this.DefineHomeGround();
    this.DefineGangHomes();
    this.DefineCrewHome();
    this.DefineCrewJobs();
    this.DefineRivalPlaces();
    this.DefineCyberbaneAPI();
    this.DefineSmasherEncounters();
    this.DefineCyberbaneRuntime();
    this.DefineCyberbaneSystem();
    this.DefineSafeAreas();
    this.DefineStealthState();
    this.DefineStoryHold();
    this.DefineWorldState();
    this.DefineDistricts();
    this.DefineGangCodes();
    this.DefineTitles();
    this.DefineTraits();
    this.DefineGigBonus();
    this.DefinePeace();
    this.DefineTribute();
    this.DefineWar();
    this.DefineDeedEngine();
    this.DefineEncounter();
    this.DefineGangRivalries();
    this.DefineLedger();
    this.DefineReputation();
    this.DefineRumorEngine();
    this.DefineStreetBook();
    this.DefineStreetRead();
    this.DefineTerritory();
    this.DefineTitleEngine();
    this.DefineTitleNaming();
    this.DefineGangVoice();
    this.DefineGrapevine();
    this.DefineTelling();
    this.DefineWhispers();
    this.DefineAllies();
    this.DefineCombatFlee();
    this.DefineCrew();
    this.DefineCrewBanner();
    this.DefineCrewKit();
    this.DefineDirector();
    this.DefineStreetIntel();
    this.DefineStreetPay();
    this.DefineStreetTalk();
    this.DefineTalkTopics();
    this.DefineWitnesses();
    this.DefineBirths();
    this.DefineDeathLedger();
    this.DefineHierarchy();
    this.DefineRivalLife();
    this.DefineRivalMoments();
    this.DefineRivalSystem();
    this.DefineWhereabouts();
    this.DefineCombatSignals();
    this.DefineConcealment();
    this.DefineBounty();
    this.DefineClashes();
    this.DefineClearedStreets();
    this.DefineFactionApex();
    this.DefineHangouts();
    this.DefineHitSquad();
    this.DefineHunt();
    this.DefineHuntGrows();
    this.DefineHunted();
    this.DefineLivingStreet();
    this.DefineLoot();
    this.DefineQueue();
    this.DefineRivalEncounter();
    this.DefineSpawner();
    this.DefineStreetEvents();
    this.DefineStreetStories();
    this.DefineWannabe();
    this.DefineBossBar();
    this.DefineHubTab();
    this.DefineHubWeb();
    this.DefineHud();
    this.DefineHud2();
    this.DefineHud3();
    this.DefineMapPins();
    this.DefineNotify();
    this.DefinePhoneMessages();
    this.DefineRealPhone();
    this.DefineRivalPin();
    this.DefineScannerName();
    this.DefineTracking();
  }

  // ---- The Mod Settings page. ------------------------------------------------------------------------------
  protected func DefineSettings() -> Void {
    // ---- Settings: categories -------------------------------------------
    this.Text("Cyberbane-Settings-Category-General", "General");
    this.Text("Cyberbane-Settings-Category-Pacing", "How often they come");
    this.Text("Cyberbane-Settings-Category-Crews", "Crews and apex squads");
    this.Text("Cyberbane-Settings-Category-Reputation", "Reputation and money");
    this.Text("Cyberbane-Settings-Category-Civilians", "Crowds and morale");
    this.Text("Cyberbane-Settings-Category-Talk", "Street talk");
    this.Text("Cyberbane-Settings-StreetTalk", "Talk to people");
    this.Text("Cyberbane-Settings-StreetTalk-Desc", "Look at somebody up close with your hands empty and a Talk prompt comes up; press F and the game's own choice list opens: Greet, questions, deals, Dismiss, Antagonize, Intimidate and more. Scroll and press F to choose. How they answer, and what it does to your standing, depends on whether they know you, how much they and their gang fear and respect you, and how you work.");
    this.Text("Cyberbane-Settings-TalkShakedowns", "Shake-downs pay");
    this.Text("Cyberbane-Settings-TalkShakedowns-Desc", "Whether a ganger you intimidate may pay you to go away, once a day per gang. It costs you Conduct. Off, they only give up a Rival's hiding place or leave.");
    this.Text("Cyberbane-Settings-TalkFirst", "Ask first");
    this.Text("Cyberbane-Settings-TalkFirst-Desc", "On: looking at somebody up close brings up a single Talk prompt, and F opens the lines, the way the game's own conversations start. Off: the lines come up straight away.");
    this.Text("Cyberbane-Settings-TalkStopWalkers", "Passers-by stop to talk");
    this.Text("Cyberbane-Settings-TalkStopWalkers-Desc", "Somebody walking past stops when you start talking to them, and walks on when you are done. Off, they keep walking and the conversation ends when they are out of reach.");
    this.Text("Cyberbane-Settings-TalkLiars", "Some people lie");
    this.Text("Cyberbane-Settings-TalkLiars-Desc", "Now and then somebody sells you a story instead of a Rival's hiding place. The street lets you know afterwards. Off, everybody who tells you something tells the truth.");
    this.Text("Cyberbane-Settings-TalkHaggle", "Haggling");
    this.Text("Cyberbane-Settings-TalkHaggle-Desc", "When somebody names a price, in the street or by text, you can tell them it is too much, once. They may come down, stand firm, or ask for more. Off, the price is the price.");
    this.Text("Cyberbane-Settings-TalkPhoneDeals", "Leads are a deal by text");
    this.Text("Cyberbane-Settings-TalkPhoneDeals-Desc", "Asking around for a Rival on the Hub puts the word out, and somebody texts you a price you answer in the thread. Off, the Hub's button pays and hands you the place at once. Needs messages going to the phone.");
    this.Text("Cyberbane-Settings-StreetIntel", "Make people talk");
    this.Text("Cyberbane-Settings-StreetIntel-Desc", "Hold a ganger in a grab for a few seconds, crouch over one you put down, or scan one, and they may give up a Rival's hiding place, a Rival's fatal flaw, or who is coming for you. A Rival's body can carry word of another.");
    this.Text("Cyberbane-Settings-TalkBubbles", "Show who has something to say");
    this.Text("Cyberbane-Settings-TalkBubbles-Desc", "The game's talk icon over up to two people nearby who know where a Rival is lying low.");
    this.Text("Cyberbane-Settings-Informants", "Informants");
    this.Text("Cyberbane-Settings-Informants-Desc", "A Rival you spare twice may owe you, and a ganger you frighten enough can be turned. Either texts you a few tips over the next days. Now and then the last one is a set-up.");
    this.Text("Cyberbane-Settings-RivalFlaws", "Fatal flaws");
    this.Text("Cyberbane-Settings-RivalFlaws-Desc", "Some senior Rivals have one fatal flaw: a blade, something heavy, a bare fist, a quickhack or explosives kills them outright. Their people can tell you which.");
    this.Text("Cyberbane-Settings-MercyChoice", "Mercy is your choice");
    this.Text("Cyberbane-Settings-MercyChoice-Desc", "A Rival you put down alive is spared only when you walk off (or put your weapon away from a distance), or tell them so where they lie; finish them and they die. You can also make them give up another Rival, or run them out of Night City. Off, a Rival left breathing is spared as soon as the fight ends.");
    this.Text("Cyberbane-Settings-SendWord", "Calling out");
    this.Text("Cyberbane-Settings-SendWord-Desc", "Call a Rival out from their page on the Hub, and now and then a Rival calls you out instead of coming. They name a place and wait there with their people. Finishing it there pays more.");
    this.Text("Cyberbane-Settings-Category-Street", "Gang life");
    this.Text("Cyberbane-Settings-Bagmen", "Bagmen");
    this.Text("Cyberbane-Settings-Bagmen-Desc", "Now and then a gang's bagman walks the week's take across its turf near you, with one lookout. Put the bagman down and the eddies are yours; the gang takes the loss and won't like you for it.");
    this.Text("Cyberbane-Settings-Favours", "Favours");
    this.Text("Cyberbane-Settings-Favours-Desc", "Ask a ganger who doesn't hate you whether they need anything done: run off a rival gang's lookout (they fight: put them down or make them run), or have a word with somebody who owes them money (scare them into paying with Intimidate or Antagonize; hurting them ends the favour). They pay, warm to you, and sometimes pass on a lead.");
    this.Text("Cyberbane-Settings-SitDowns", "Sit-downs");
    this.Text("Cyberbane-Settings-SitDowns-Desc", "Word reaches you that two gangs at war are meeting at a place and an hour. Crash it and both gangs lose strength and fear you more.");
    this.Text("Cyberbane-Settings-SitDownSize", "People per gang at a sit-down");
    this.Text("Cyberbane-Settings-SitDownSize-Desc", "How many of each gang turn up to a sit-down. Two gangs meet, so the sit-down has twice this many people. If too many of Cyberbane's people are already out, fewer turn up.");
    this.Text("Cyberbane-Settings-SitDownApex", "Apex fighters per gang at a sit-down");
    this.Text("Cyberbane-Settings-SitDownApex-Desc", "How many of each gang's people at a sit-down are its best, as tough and as well equipped as its apex squad: a heavy, a shooter, a blade and a netrunner, in that order. They stand their ground and drop apex loot. The rest are rank and file. Never more than the people per gang.");
    this.Text("Cyberbane-Settings-WhileOut", "While you were out");
    this.Text("Cyberbane-Settings-WhileOut-Desc", "A little after you load, one line about the latest thing that changed the street.");
    this.Text("Cyberbane-Settings-Surrender", "Gangers surrender");
    this.Text("Cyberbane-Settings-ClearedStreets", "Cleared streets stay clear (experimental)");
    this.Text("Cyberbane-Settings-ClearedStreets-Desc", "Wipe a gang out of a spot (six or more of theirs dead in one fight, none of them left standing there) and for three in-game days their people keep away from it: anybody of theirs who turns up there walks off, and the game takes them away once you can't see them, the way it does with somebody who runs. Story characters, vendors and anybody already fighting are never touched. Off by default.");
    this.Text("Cyberbane-Settings-Surrender-Desc", "Some beaten gangers give up instead of running: hands up, not fighting, and your scanner says so. The Mox and the Scavengers give up often, Barghest never. Let them go and their gang thinks better of you; grab them and they talk; shoot them and the street hears about it, and their gang takes it hard.");
    this.Text("Cyberbane-Settings-ClaimHelp", "Nobody kills you but me (experimental)");
    this.Text("Cyberbane-Settings-ClaimHelp-Desc", "When one gang has you badly outnumbered, a Rival with a claim on you may turn up and fight at your side, then walk off with a promise of next time. Once a day at most.");
    this.Text("Cyberbane-Settings-Category-Gangs", "Gangs");
    this.Text("Cyberbane-Settings-Category-Rivals", "Rivals");
    this.Text("Cyberbane-Settings-Category-RivalsYou", "Rivals and you");
    this.Text("Cyberbane-Settings-Category-MyCrew", "Your crew");
    this.Text("Cyberbane-Settings-Voices", "Voices for the moments");
    this.Text("Cyberbane-Settings-Voices-Desc", "People speak in their own game voices at Cyberbane's moments: a Rival's people as they find you, somebody giving up, a crew's sergeant calling a halt. Only the game's own voice lines. Off, and those moments are subtitles alone.");
    this.Text("Cyberbane-Settings-MorningBrief", "Morning brief");
    this.Text("Cyberbane-Settings-MorningBrief-Desc", "At dawn each in-game day a broker texts you: what happened overnight, who is after you, and what is coming. Quiet when messages are off.");
    this.Text("Cyberbane-Settings-PanicInDark", "Panic in the dark");
    this.Text("Cyberbane-Settings-PanicInDark-Desc", "Pick off a crew without being seen and the rest grow afraid: they call out for whoever stopped answering, and after the second, somebody may run. Off, and a crew keeps its nerve however quietly you work.");
    this.Text("Cyberbane-Settings-MyCrew", "Your crew");
    this.Text("Cyberbane-Settings-MyCrew-Desc", "People can end up working for you: a Rival you spared before and beat down again, a ganger you frightened badly enough, a solo a broker offers, or one lent by a Friendly or Allied gang. Call them from the phone or the Hub when somebody comes for you. Off, and nobody offers, nobody joins, and nobody comes.");
    this.Text("Cyberbane-Settings-CrewComeOnOwn", "Come on their own");
    this.Text("Cyberbane-Settings-CrewComeOnOwn-Desc", "The most loyal of your crew turn up unasked when an ambush springs on you. Off, and they only come when you call.");
    this.Text("Cyberbane-Settings-CrewOnJobs", "Your crew on jobs");
    this.Text("Cyberbane-Settings-CrewOnJobs-Desc", "Where your crew comes when you call. Gigs and side jobs: everywhere except the main story's own missions. Never: not near any job on the map. Everywhere but the story: any job, but never into the story itself. A cutscene or a safe place like your apartment always keeps them out.");
    this.Text("Cyberbane-Settings-CrewCanDie", "Your crew can die");
    this.Text("Cyberbane-Settings-CrewCanDie-Desc", "On, your crew can be killed like anybody else, and the ones who fall go on the memorial. Off, the game protects them the way it protects its own companions: hurt badly enough, they go down instead of dying, get back up a little later, and are out for a few hours once the fight is over.");
    this.Text("Cyberbane-Settings-CrewCallKey", "Call your crew (key)");
    this.Text("Cyberbane-Settings-CrewCallKey-Desc", "A key that calls your crew, or sends them home when they are with you. Not set at first: pick a key nothing else uses. It only works out in the game, never in a menu. The phone (My crew, Need you. Now.) and the Hub's Crew page do the same.");
    this.Text("Cyberbane-Settings-CrewBetrayal", "Betrayal");
    this.Text("Cyberbane-Settings-CrewBetrayal-Desc", "Somebody whose loyalty you let run low may sell you to the people hunting you, or come when called and turn on you in the fight, and live on as a Rival. The crew page and their texts always warn you first. Off, and nobody ever betrays you.");
    this.Text("Cyberbane-Settings-CrewFrightJoin", "Frightened into joining");
    this.Text("Cyberbane-Settings-CrewFrightJoin-Desc", "A ganger already afraid of you always joins your crew when you Intimidate them, if there is room. This slider sets how often one who only gives in to Intimidate joins too, instead of passing you tips. At 0, only the already afraid join.");
    this.Text("Cyberbane-Settings-CrewCutMult", "The weekly cut");
    this.Text("Cyberbane-Settings-CrewCutMult-Desc", "What your crew asks for each week, against the usual. At 0 they work for nothing and never ask.");
    this.Text("Cyberbane-Settings-StreetCredFollows", "Street Cred follows the legend");
    this.Text("Cyberbane-Settings-StreetCredFollows-Desc", "The biggest things you do (a Rival killed, open season survived, a bounty hunter beaten, the top of the hunters' ladder) give a little of the game's own Street Cred, so its vendors and gigs follow your name. Off, and Cyberbane leaves Street Cred to the game.");
    this.Text("Cyberbane-Settings-RunWithCrew", "Run with a crew");
    this.Text("Cyberbane-Settings-RunWithCrew-Desc", "With a gang Friendly to you or better, ask one of its people to watch your back: two of them (three if they are Allied) come and follow you, the way the game's own companions do, and fight whoever fights you. They go home after an in-game hour, when you leave their turf for long, drive off, go to a job, or shoot one of them. Once a day. Off, and nobody comes with you.");
    this.Text("Cyberbane-Settings-OneOfTheirs", "One of theirs");
    this.Text("Cyberbane-Settings-OneOfTheirs-Desc", "A gang that is Allied with you may offer to make you one of its own. Say yes to any of its people and you count as wearing their colours everywhere, their enemies know you as one of them, their people greet you, and once a week they ask a favour that costs standing if you ignore it. You can leave whenever you like, at a cost. Off, and nobody makes the offer.");
    this.Text("Cyberbane-Settings-Ransom", "Ransom");
    this.Text("Cyberbane-Settings-Ransom-Desc", "Talk to a ganger who has given up: hold them for their gang's money, which they pay or come to take back by force, or hand them to a gang at war with theirs. Needs Surrender on. Off, and you can only let them go.");
    this.Text("Cyberbane-Settings-TalkLies", "Feed the street a lie");
    this.Text("Cyberbane-Settings-TalkLies-Desc", "Tell a talkative passer-by or a frightened ganger that you have left town, and whoever is after you starts looking in the wrong place and cools off for a while. A bad liar, or a listener who lies for a living, sells you out instead. Off, and the line is not offered.");
    this.Text("Cyberbane-Settings-RivalChrome", "Rivals get chrome");
    this.Text("Cyberbane-Settings-RivalChrome-Desc", "Every time a Rival climbs (a rank, an escape, being spared, putting you down) they can come back with an implant that answers how you hurt them: shot, subdermal armour; cut, dermal plating; hacked, a firewall; outrun, reinforced tendons; burned, smoke-filter optics. Stats and the game's own abilities only; it shows on their page and in the scanner. Off, and Rivals only have their traits.");
    this.Text("Cyberbane-Settings-Facedown", "The facedown");
    this.Text("Cyberbane-Settings-Facedown-Desc", "When a Rival gets close before anybody has fired, everyone stops: talk to them to stare them down, draw first, walk away, or ask for a fight one on one. A Rival who owes you or is afraid of you can be talked out of it altogether. Off, and Rivals just open fire.");
    this.Text("Cyberbane-Settings-NobodyButMe", "Nobody kills you but me");
    this.Text("Cyberbane-Settings-NobodyButMe-Desc", "Outnumbered by one gang, a Rival of another gang with a claim on you (they beat you, got away from you, or you let them go) can turn up to fight at your side, then leaves with a promise to finish it with you later. About once a day at most.");
    this.Text("Cyberbane-Settings-BackFromDead", "Back from the dead");
    this.Text("Cyberbane-Settings-BackFromDead-Desc", "Rarely, a Rival you killed comes back weeks later, rebuilt by a back-alley ripperdoc, with heavier chrome and a new name. Never one you finished with a finisher or their fatal flaw. Off, and the dead stay dead.");
    this.Text("Cyberbane-Settings-RivalFeuds", "Rivals at war, and their bonds");
    this.Text("Cyberbane-Settings-RivalFeuds-Desc", "Rivals of gangs at war hunt each other between your fights, and one can kill the other off screen; you can set one on another when you spare them. Two Rivals of a gang can be bound as mentor and protégé, lovers or partners: kill one and the other answers it. Off, and Rivals only ever go after you, never each other.");
    this.Text("Cyberbane-Settings-Trophies", "Trophies");
    this.Text("Cyberbane-Settings-Trophies-Desc", "Kill a named Rival of rank two or more and the weapon they carried goes into your inventory, once each. Off, and only the usual loot.");
    this.Text("Cyberbane-Settings-Category-SafeAreas", "Safe areas and jobs");
    this.Text("Cyberbane-Settings-Preset-Desc", "Subtle, Default or Dramatic sets how loud and how often everything is, in one go, overwriting what is there. Nemesis puts your Rivals first, Turf war the gangs and their streets, and Quiet life keeps the street and talk with hardly anybody hunting you. Custom leaves your own numbers as they are.");
    this.Text("Cyberbane-Settings-RenownGain-Desc", "How fast your name spreads.");
    this.Text("Cyberbane-Settings-DreadGain-Desc", "How fast you become frightening. Dread is the score that makes people back off.");
    this.Text("Cyberbane-Settings-Decay-Desc", "How fast reputation fades when you stop earning it. Zero never fades.");
    this.Text("Cyberbane-Settings-RumorSpread-Desc", "How far word about you carries between districts. Lower keeps your name local.");
    this.Text("Cyberbane-Settings-StreetCredFloor-Desc", "Counts the Street Cred you already have as reputation already earned.");
    this.Text("Cyberbane-Settings-CivReactions-Desc", "Whether civilians look over, step aside, freeze or run when you come near.");
    this.Text("Cyberbane-Settings-CivIntensity-Desc", "How strongly civilians react to you. Low: they look over. Middle: they flinch and step aside. High: the people closest to you freeze or run.");
    this.Text("Cyberbane-Settings-MaxReactingCiv-Desc", "How many civilians may react at the same time.");
    this.Text("Cyberbane-Settings-PanicDriving-Desc", "Whether drivers pull away in a hurry when a frightening V is near.");
    this.Text("Cyberbane-Settings-GangReactions-Desc", "Whether gang members read your standing with them and act on it.");
    this.Text("Cyberbane-Settings-HostileOnSight-Desc", "Whether a gang at vendetta draws the moment they recognise you.");
    this.Text("Cyberbane-Settings-Warnings-Desc", "Whether a hostile gang gives you one spoken warning before turning on you.");
    this.Text("Cyberbane-Settings-CyberpsychoRivals-Desc", "A cyberpsycho you take alive may come back as a rival, with their own name and strength.");
    this.Text("Cyberbane-Settings-FactionDisguises-Desc", "Whether wearing a gang's or a corporation's own gear makes them slower to place you. The more of it you wear, the better it works.");
    this.Text("Cyberbane-Settings-ClothingCounts", "Clothes and masks count");
    this.Text("Cyberbane-Settings-ClothingCounts-Desc", "On: clothes cover chrome, a mask hides who you are, a gang's gear fools that gang, and what you wear changes how dangerous you look. Off: wear anything, nothing you have on is read and all your chrome shows.");
    this.Text("Cyberbane-Settings-TurfOnMap", "Turf on the map");
    this.Text("Cyberbane-Settings-TurfOnMap-Desc", "Whether the game's map lists the gang that has taken a district. Turn off if another mod draws its own territory on the map.");
    this.Text("Cyberbane-Settings-Tribute-Desc", "Whether a gang that fears you sends eddies to stay on your good side.");
    this.Text("Cyberbane-Settings-TributeMult-Desc", "How much that tribute pays.");
    this.Text("Cyberbane-Settings-HitSquads-Desc", "Whether gangs send people after you. This also controls apex squads.");
    this.Text("Cyberbane-Settings-HitSquadFreq-Desc", "How soon a gang with a grudge comes for you. Each gang waits by how it stands with you, how hurt and how broken it is, and how far off you are; this stretches or shortens all of it.");
    this.Text("Cyberbane-Settings-Morale-Desc", "Whether enemies can lose their nerve and run. How likely depends on how hurt and alone they are, their rank, what they just saw, and how much their gang fears you.");
    this.Text("Cyberbane-Settings-MoraleIntensity-Desc", "How easily enemies break. Zero means nobody runs.");
    this.Text("Cyberbane-Settings-MaxBreakFraction-Desc", "The most of one group that may run, so a room never routs together.");
    this.Text("Cyberbane-Settings-VendorPricing-Desc", "Whether your reputation changes what vendors charge you.");
    this.Text("Cyberbane-Settings-MaxDiscount-Desc", "The largest discount your reputation can earn you, as a percentage.");
    this.Text("Cyberbane-Settings-GigBonus-Desc", "Whether fixers pay the famous more on job payouts.");
    this.Text("Cyberbane-Settings-GigBonusMult-Desc", "How big that payout bonus is.");
    this.Text("Cyberbane-Settings-Rivals-Desc", "Whether enemies who get away from you, or who you spare, come back as named Rivals.");
    this.Text("Cyberbane-Settings-MaxRivals-Desc", "How many Rivals you carry at once. At the limit nobody new takes against you, and the ones you have close in faster.");
    this.Text("Cyberbane-Settings-DeathsRemembered-Desc", "Whether whoever kills you can come back as a Rival.");
    this.Text("Cyberbane-Settings-RivalHideouts-Desc", "Gangs and the street sometimes text you where a Rival was last seen. Go there on foot and they may be waiting, not expecting you.");
    this.Text("Cyberbane-Settings-RivalTeamUps-Desc", "Now and then, a Rival who comes for you brings other Rivals of the same gang, more often when the one leading runs a crew. Each fights, falls, runs or is spared on their own. Off, Rivals always come one at a time.");
    this.Text("Cyberbane-Settings-RivalTeamSize-Desc", "How many Rivals one team-up can be, counting the one leading it.");
    this.Text("Cyberbane-Settings-PsychoBreaks-Desc", "A top-rank Rival who keeps losing to you may push their chrome too far and come back a cyberpsycho: relentless, harder to put down, but never unkillable.");
    this.Text("Cyberbane-Settings-RivalFreq-Desc", "How soon a Rival comes looking again. Each waits by how much they hold against you; this stretches or shortens all of it.");
    this.Text("Cyberbane-Settings-Whispers-Desc", "Whether you overhear people talking about you as you pass.");
    this.Text("Cyberbane-Settings-WhisperCooldown-Desc", "The gap between overheard lines.");
    this.Text("Cyberbane-Settings-CarsOnFoot-Desc", "Lets gangs, Rivals and apex squads drive to you while you are on foot, pull up and get out. Off, they only drive while you are driving and otherwise walk in out of sight. Turning it off takes effect at once.");
    this.Text("Cyberbane-Settings-Toasts-Desc", "Whether Cyberbane says anything on screen at all: phone, cards, notices and overheard lines. Off changes nothing about the way the mod plays. The answer to a button you press on the Hub or here still shows. Two things have settings of their own: the line at the top of the screen (Hunt line on the HUD, under General) and the bars under it (Rival and apex bars, under Messages and HUD).");
    this.Text("Cyberbane-Settings-MessageHold-Desc", "How long Cyberbane's words stay on screen, as a percentage: messages, the phone's pop-ups, what you overhear, and every line of a conversation, including what people tell you. Longer lines stay longer on their own; this stretches them all. A message waits for the one before it to finish, so none is cut short.");
    this.Text("Cyberbane-Settings-EncounterGap-Desc", "How long the city leaves you alone after a fight before anybody new is picked to come for you, in real minutes of play. Menus and loading screens don't count. With Everybody rests after a fight off, Rivals, crews and apex squads each rest on their own.");
    this.Text("Cyberbane-Settings-RestTogether", "Everybody rests after a fight");
    this.Text("Cyberbane-Settings-RestTogether-Desc", "On: after any fight with Cyberbane's people, Rivals, crews and apex squads all wait out the minutes above before the next one is picked, and nobody new is lined up while a fight is on. Off: each of the three keeps its own rest, so a Rival, then a crew, then an apex squad can come one after another.");
    this.Text("Cyberbane-Settings-SleepPeace", "Quiet after a night at home (game hours)");
    this.Text("Cyberbane-Settings-SleepPeace-Desc", "Sleep in one of your own beds and nobody is sent after you for this many in-game hours afterwards. Anybody already on their way still comes. 0 turns it off.");
    this.Text("Cyberbane-Settings-HomeGround", "Home ground");
    this.Text("Cyberbane-Settings-HomeGround-Desc", "The building around each of your apartments, with its lobby, corridors and car park: about a hundred metres around the apartment, at any height. Cyberbane learns each one the first time you are inside it or sleep there. Quiet: nobody Cyberbane sends comes for you there, people already looking for you won't find you there, and no bagmen, gang events or street fights start there. A fight that followed you in carries on. Quiet except a vendetta: the same, except a gang at Vendetta may still come for you there. Open: home ground is like anywhere else.");
    this.Text("Cyberbane-Settings-TurfWars-Desc", "Hurting a gang weakens it, most of all on its own streets. A broken gang loses its districts to its enemies next door, and they stay taken until somebody takes them back. Off keeps every gang on its own streets.");
    this.Text("Cyberbane-Settings-VendettaApexSquad-Desc", "Every crew a gang sends is led by its apex squad: a heavy, a shooter, a blade and a netrunner. Off sends the crew alone.");
    this.Text("Cyberbane-Settings-ApexArrivalSound-Desc", "Plays the game's own MaxTac descent horn when a gang sends its apex squad.");
    this.Text("Cyberbane-Settings-ApexBossBar-Desc", "The name and health bars at the top of the screen: one for a Rival, one for each apex. The line of text above them is a setting of its own: Hunt line on the HUD, under General.");
    this.Text("Cyberbane-Settings-VendettaSquads-Desc", "A gang at vendetta simply comes for you rather than rolling dice. The Hub shows how long until they arrive.");
    this.Text("Cyberbane-Settings-VendettaSquadSize-Desc", "How many a vendetta sends at full menace. Lower it if the frame rate dips when a crew arrives.");
    this.Text("Cyberbane-Settings-VehicleArrivals-Desc", "Rivals, crews and apex squads drive to you whenever a car can be sent, and give chase if you are driving. If a car cannot get through, they come on foot.");
    this.Text("Cyberbane-Settings-ApexStrength-Desc", "How dangerous a gang's apex squad is, as a percentage of a full boss build. 100 matches the game's own set piece enforcers; 55 is hard but fair. They are also measured against you: each takes a few seconds of your best weapon's fire to put down, longer the higher this is, hits hard enough to get through your armour, and scales with your level the way Adam Smasher does, a share of his strength each (more the higher this is). No single hit takes more than a set part of their health. Rivals have their own slider, under Rivals.");
    this.Text("Cyberbane-Settings-RivalStrength-Desc", "How dangerous a Rival is, as a percentage of a full boss build. A new Rival gets part of it and grows into the rest with every escape, mercy and kill, and running a crew adds a little. 55 is hard but fair. Your menace and the game's difficulty scale it further.");
    this.Text("Cyberbane-Settings-LootDrops-Desc", "Anyone Cyberbane sends who you put down leaves you something, straight into your inventory. The higher they ranked, the better it is.");
    this.Text("Cyberbane-Settings-Scouts-Desc", "A gang that cannot find you sends one scout ahead of the crew. Put the scout down, pay them to keep quiet (with Pay the street on, under Street talk), or stay out of their sight until they lose you, and the crew never comes.");
    this.Text("Cyberbane-Settings-DistrictLine-Desc", "Where you stand in the district you are in, shown on the hunt line while nobody is after you. Always: it stays up. Briefly: it shows when you arrive somewhere and when your standing there changes, then clears. Off: never shown.");
    this.Text("Cyberbane-Settings-DistrictLineSeconds-Desc", "How long the district line stays up, when it is set to Briefly.");
    this.Text("Cyberbane-Settings-HudLine-Desc", "The line of text at the top of the screen. Everything: the full story, all the time. Hunts only: only while somebody is on their way or out looking. Off: hidden. The Rival and apex bars under it are a setting of their own: Rival and apex bars, under Messages and HUD.");
    this.Text("Cyberbane-Settings-ShowCountdowns-Desc", "Show exact times on the Hub and the HUD line. Off says soon, any moment or later instead.");
    this.Text("Cyberbane-Settings-Bounties-Desc", "Putting down a Rival, a crew or an apex squad earns you eddies, paid by a gang at war with theirs. This is a reward to you, not the price on your head (that is A price on your head, under Being hunted).");
    this.Text("Cyberbane-Settings-ApexTraits-Desc", "Each apex gets two traits of its own, so no two fight the same way. Stands down on its own when New Game Plus is installed.");
    this.Text("Cyberbane-Settings-TwrCompat-Desc", "Auto or On: They Will Remember or Night City Remembers decides who is hostile to you, and Cyberbane follows it: every gang it has hostile is hostile here, hostility on sight is left to it, and nobody it has hostile offers you a word. They Will Remember also takes over crews and disguises. Night City Remembers sends nobody after you, so Cyberbane's crews still come. Off: Cyberbane decides; turn hostility off in the other mod's own settings so the two do not disagree.");
    this.Text("Cyberbane-Settings-LogLevel-Desc", "How much Cyberbane writes to its log. Only worth raising for a bug report.");
    this.Text("Cyberbane-Settings-FreezeReputation-Desc", "Stops your reputation changing. Everything already earned keeps working.");
    this.Text("Cyberbane-Settings-HudScale-Desc", "Size of Cyberbane's own screens and bars, on top of the scaling it already does for your resolution.");
    this.Text("Cyberbane-Settings-ResetAll-Desc", "Clears everything Cyberbane recorded on this save: scores, factions, districts, Rivals, titles and log. Turn it on and hit Apply. It stays on in this menu afterwards and does nothing more; to reset again, turn it off, Apply, then on and Apply. Older saves of this playthrough are reset too when they load; Undo the last Start over on the Hub's History page takes that back, and a save from before it then loads as it was.");
    this.Text("Cyberbane-Settings-SeparateSave-Desc", "For two characters whose Cyberbane records got mixed up, so one is followed by what the other did. Load the character that should not have them, turn this on and hit Apply: that save gets records of its own and keeps everything it earned, and Rivals made from the other character's deaths go. Use it on each of that character's saves. Like the reset, off and on again to use it again.");
    this.Text("Cyberbane-Settings-SafeZoneSpawns", "Allow spawns in safe areas");
    this.Text("Cyberbane-Settings-QuestAreas", "Stay out of quest areas");
    this.Text("Cyberbane-Settings-QuestAreaRadius", "Quest area size (metres)");
    this.Text("Cyberbane-Settings-QuestAreas-Desc", "Nobody is sent after you while you are on a job (any active one, tracked or not), in a conversation or in a restricted area, and hunters already out hold back until you leave it, even once they have found you. The story's own scenes are protected whatever this is set to.");
    this.Text("Cyberbane-Settings-QuestAreaRadius-Desc", "How close to an active objective counts as being on the job. 80 covers almost every gig site.");
    this.Text("Cyberbane-Settings-SafeZoneSpawns-Desc", "Let them turn up inside apartments, bars and clinics. Off by default, because the game disarms you there.");
    this.Text("Cyberbane-Settings-SafeZoneCombat", "Let me fight in safe areas");
    this.Text("Cyberbane-Settings-SafeZoneCombat-Desc", "Keeps your hands free in a safe area so you can fight back. Use it with the setting above.");
    this.Text("Cyberbane-Settings-Category-UI", "Messages and HUD");
    this.Text("Cyberbane-Settings-HubPauseMenu", "Hub in the pause menu");
    this.Text("Cyberbane-Settings-HubPauseMenu-Desc", "Off: the Hub is the CYBERBANE tab at the top of the game menu, after Journal (with the game's radial menu, open Character and it is beside it). On: the tab goes, and the Hub is Cyberbane in the pause menu (Escape). Turn this on if you cannot find the tab.");
    this.Text("Cyberbane-Settings-Category-Factions", "Factions");
    this.Text("Cyberbane-Settings-Category-GangView", "How gangs see you");
    this.Text("Cyberbane-Settings-Category-Advanced", "Advanced");
    this.Text("Cyberbane-Settings-Category-Turf", "Turf");
    this.Text("Cyberbane-Settings-Category-Hunted", "Being hunted");
    this.Text("Cyberbane-Settings-FairVolley", "A fair first volley");
    this.Text("Cyberbane-Settings-FairVolley-Desc", "For a couple of seconds after Cyberbane's people first find you, their aim is off, so the opening shots aren't the end of the fight.");
    this.Text("Cyberbane-Settings-LieLow", "Lie low");
    this.Text("Cyberbane-Settings-LieLow-Desc", "While they're still searching for you, changing clothes or slipping into another district out of sight can make them lose the trail. It works before they get to you too: once a gang has sent people, changing how you look, putting on a mask, leaving the district, riding the metro or going home each break the trail. One change and they come in looking in the wrong place; two or more and they may lose you before they set off. Not a gang at Vendetta, one that has a tracker on you, or one whose streets you are standing on: they know where you are. The Hub's gang page says when a gang is still hot about you or cooling off.");
    this.Text("Cyberbane-Settings-Haunts", "They learn your haunts");
    this.Text("Cyberbane-Settings-Haunts-Desc", "The districts you spend most time in become known. A hunt that starts in one of them starts closer to you.");
    this.Text("Cyberbane-Settings-Trackers", "Trackers");
    this.Text("Cyberbane-Settings-Trackers-Desc", "A quickhack from one of Cyberbane's netrunners can plant a tracker on you: for half a day that gang knows where you are, and the HUD line says so. Spend a minute somewhere safe (home, a clinic, a ripperdoc's chair) to dig it out.");
    this.Text("Cyberbane-Settings-OpenSeason", "Open season");
    this.Text("Cyberbane-Settings-OpenSeason-Desc", "The top of a gang's anger. Sworn against you, with many of theirs dead and a leader to call it, a gang can declare open season: for a whole day every one of them knows your face and a crew comes every hour. Survive it, kill their leader, or pay a crippling price. Surviving leaves them afraid of you.");
    this.Text("Cyberbane-Settings-StreetClashes", "Rival gangs clash in the street");
    this.Text("Cyberbane-Settings-StreetClashes-Desc", "On a contested street, where a gang is challenging for the district or two gangs at war both work the corners, now and then a few of their people go at each other while you are around. Whoever is left standing gains a little ground. Never at a job, in a scene or somewhere safe, and only one clash every ten minutes or so. Off, and gangs only fight each other in Cyberbane's own street events.");
    this.Text("Cyberbane-Settings-PriceOnHead", "A price on your head");
    this.Text("Cyberbane-Settings-PriceOnHead-Desc", "A gang sworn against you, a Rival who has met you often, or a corporation can put a price on you. Named solos from the hunters' ladder take it, one at a time and sometimes two, about once every nine in-game hours, and text you first. Beat one ranked above you and you take their place; at the top you are the most dangerous merc in Night City. It ends when you pay it off on the Hub, kill whoever put it up (a gang's leader, when a gang did), or they stop wanting you dead. Off, and nobody puts a price on you.");
    this.Text("Cyberbane-Settings-CorpContracts", "The corporations hire killers");
    this.Text("Cyberbane-Settings-CorpContracts-Desc", "Arasaka, Militech and Kang Tao send no crews of their own: when they want you dead they open a contract and hire the hunters' ladder, and the contract can be bought off at a corporate price. Once you are a Legend, a corporation may also offer you a contract on a gang's leader, or warn you off. Off, and the corporations send crews like any gang.");
    this.Text("Cyberbane-Settings-Lookouts", "Lookouts in the crowd");
    this.Text("Cyberbane-Settings-Lookouts-Desc", "On a hostile gang's streets, somebody in the crowd is watching for you, and your scanner shows who. Put them down, or pay or scare them into silence (with Pay the street on, under Street talk), before they report you, and the gang never hears you were there.");
    this.Text("Cyberbane-Settings-Category-Word", "Word on the street");

    // ---- Settings: 2.3.1, the street reads you -------------------------------
    this.Text("Cyberbane-Settings-StreetReadsMoment", "Night, rain and blood");
    this.Text("Cyberbane-Settings-StreetReadsMoment-Desc", "The street reads the moment. At night and in the rain a face is harder to place and fewer people see a kill. Badly hurt, people back away from you and gangers who feared you get bolder. Just after a fight, the crowd keeps its distance and talks about what it saw.");
    this.Text("Cyberbane-Settings-DistrictTempers", "District temperaments");
    this.Text("Cyberbane-Settings-DistrictTempers-Desc", "Each district takes things its own way. Watson talks fast and forgets fast, Heywood remembers every name and tells the Valentinos, City Center sees nothing, Pacifica and Dogtown are hard to scare. Sets how fast word moves on, how easily people frighten, how long a place remembers and how often a witness talks.");
    this.Text("Cyberbane-Settings-WitnessesCall", "Witnesses tell the gang");
    this.Text("Cyberbane-Settings-WitnessesCall-Desc", "Somebody who sees you hurt a ganger may go and tell their gang. You get a few seconds: talk to them, or put them down. If word gets out, the gang comes looking for you in that district without sending a scout first. They never call the police.");
    this.Text("Cyberbane-Settings-Wannabes", "Wannabes");
    this.Text("Cyberbane-Settings-Wannabes-Desc", "Once your name means something, a kid out to make theirs can square up to you, fists only. Beat them, walk away or lose, and the street hears how it went. Never in a safe area or near a job.");
    this.Text("Cyberbane-Settings-PlacesRemember", "Places remember");
    this.Text("Cyberbane-Settings-PlacesRemember-Desc", "Where something big happened (a room full of bodies, a boss put down) the street remembers for a few days: people there talk about it, the gang that lost people there is jumpy, and it is slow to send anybody back. How long depends on the district.");
    this.Text("Cyberbane-Settings-BraindanceGoesRound", "The braindance goes round");
    this.Text("Cyberbane-Settings-BraindanceGoesRound-Desc", "When you do something huge in front of people, somebody recorded it, and it is on every BD stall in the city at once instead of spreading a district at a time.");
    this.Text("Cyberbane-Settings-PayTheStreet", "Pay the street");
    this.Text("Cyberbane-Settings-PayTheStreet-Desc", "Two more things to say in street talk. Pay somebody off the street to keep watch, and for a few hours in that district you get more warning of anybody coming for you, and a text when they show. And a witness running to a gang, a gang's lookout in the crowd, or a scout who hasn't called it in yet can be paid to forget they saw you.");
    this.Text("Cyberbane-Settings-KnownByCarAndGun", "Known by your car and gun");
    this.Text("Cyberbane-Settings-KnownByCarAndGun-Desc", "Keep turning up to fights in the same car, or keep using the same gun, and the gangs come to know it. Once they do, a mask will not hide you in that car or with that gun in your hands. The Hub's gang page says what they know.");
    this.Text("Cyberbane-Settings-BossesSeeThrough", "Bosses see through disguises");
    this.Text("Cyberbane-Settings-BossesSeeThrough-Desc", "A gang's officers and elites take a closer look. Stay near one for a few seconds with a mask or their colours on and they may see who you are.");
    this.Text("Cyberbane-Settings-GangCodes", "Gang codes");
    this.Text("Cyberbane-Settings-GangCodes-Desc", "Each gang lives by its own code: what it respects, what it never forgives, how it fights and how it makes peace. The Valentinos value mercy and never forget a shot surrender, the Claws are business, the Animals respect fists, Barghest never break, the Mox protect Jig-Jig Street and never send their best, killing Scavengers pleases everybody. The Hub's gang page tells you each gang's code as you learn it. Off, every gang behaves alike.");
    this.Text("Cyberbane-Settings-GangsAdapt", "Gangs adapt to how you fight");
    this.Text("Cyberbane-Settings-GangsAdapt-Desc", "Each gang notices how you hurt its people. Keep shooting them and they come in armour; keep fighting up close and they come tougher; keep hacking them and they run fresh ICE; keep taking them quietly and their hunters keep their eyes open. They text you when they change, and it fades when you change how you fight. How they look never changes.");
    this.Text("Cyberbane-Settings-Gatherings", "Gatherings");
    this.Text("Cyberbane-Settings-Gatherings-Desc", "Gangs gather near you at a set time, and the street tells you where and when: a funeral after a Rival or a boss of theirs dies, a celebration after they take a district, an initiation, a recruiting drive. Crash one and they feel it (a funeral is never forgiven); let it happen and they come out stronger. At a funeral you can pay your respects instead.");
    this.Text("Cyberbane-Settings-DealsAndRackets", "Arms deals and rackets");
    this.Text("Cyberbane-Settings-DealsAndRackets-Desc", "A gang buying guns from another, or collecting its take, near you at a set time. Crash a deal and the crate is yours; hit a racket and the cash is. Leave them be and the gang grows stronger.");
    this.Text("Cyberbane-Settings-WarChest", "War chests and manpower");
    this.Text("Cyberbane-Settings-WarChest-Desc", "Every gang has money and people. Its streets earn it eddies; crews, apex squads, tribute and the rewards it pays out for kills cost it. Rob its bagmen and hit its rackets and it sends fewer people; massacre its crews and its ranks empty for days. The Hub's gang page says if a gang is flush, counting every eddie, or broke.");
    this.Text("Cyberbane-Settings-BackAGang", "Back a gang");
    this.Text("Cyberbane-Settings-BackAGang-Desc", "Tell one of a gang that likes you that their war is yours. Hurting their enemies where they fight counts double with them, and every week they pay you a cut for each district they hold. Their enemies like you less. You can change sides once a week.");
    this.Text("Cyberbane-Settings-CommonEnemy", "A common enemy");
    this.Text("Cyberbane-Settings-CommonEnemy-Desc", "Rarely, two gangs at war that both fear and hate you call a truce for a day and send their crews together. Only once you're Infamous.");
    this.Text("Cyberbane-Settings-OwnStreets", "Your own streets");
    this.Text("Cyberbane-Settings-OwnStreets-Desc", "The endgame of the turf war: as a Legend, a district where your name is everything and every gang is broken becomes yours. No crews come there, and the gangs passing through pay you every week.");
    this.Text("Cyberbane-Settings-TalkIncite", "Set gangs on each other");
    this.Text("Cyberbane-Settings-TalkIncite-Desc", "In street talk, tell a ganger their enemies are planning a hit on them. Believed, both gangs lose a little ground and the next street fight near you is between them. Not believed, they take offence.");
    this.Text("Cyberbane-Settings-GangFights", "Fights between gangs");
    this.Text("Cyberbane-Settings-GangFights-Desc", "Gangs at war settle things near you, and the street tells you where and when: an execution of one of a rival gang's people, a street fight that decides who holds the ground, a hunt for somebody who crossed them. Step in, pick a side, or let it play out. They come up less often than gatherings.");
    this.Text("Cyberbane-Settings-PowerStruggles", "Power struggles");
    this.Text("Cyberbane-Settings-PowerStruggles-Desc", "When a gang's leader falls and two of their lieutenants want the chair, both text you for help. Kill one and the other takes the chair and owes you; kill both and the gang tears itself apart. Sparing one decides nothing.");
    this.Text("Cyberbane-Settings-GangLifeOften", "How often gangs get together");
    this.Text("Cyberbane-Settings-GangLifeOften-Desc", "How often gatherings, deals and rackets come up. At 1.0, about one every forty minutes of play when there's a gang around; sit-downs keep their own pace.");
    this.Text("Cyberbane-Settings-LifepathHeadStart", "A head start from your lifepath");
    this.Text("Cyberbane-Settings-LifepathHeadStart-Desc", "When Cyberbane starts a playthrough (a new game, or Start over) your past counts: a Nomad starts known and liked by the Aldecaldos and disliked by the Wraiths, a Street Kid known to the Valentinos and Heywood, a Corpo known to Arasaka and not kindly. A playthrough Cyberbane already knows is never changed.");

    // ---- Settings: general ----------------------------------------------
    this.Text("Cyberbane-Settings-Enabled", "Enabled");
    this.Text("Cyberbane-Settings-Enabled-Desc", "Turns Cyberbane on or off. Off stops every reaction and reverts temporary changes; your reputation is kept.");
    this.Text("Cyberbane-Settings-Preset", "Preset");
    this.Text("Cyberbane-Settings-MessageDelivery", "Where messages go");
    this.Text("Cyberbane-Settings-MessageAmount", "How much you hear");
    this.Text("Cyberbane-Settings-MessageSize", "Message size");
    this.Text("Cyberbane-Settings-MessageSize-Desc", "How big the message cards under your health bar, and Cyberbane's own subtitle line, are drawn. 100 is the usual size.");
    this.Text("Cyberbane-Settings-MessageAmount-Desc", "How often the street's chatter reaches you: word going round about you and lines overheard in passing. Less chatter spaces them out, Rarely spaces them out further. Warnings, demands, offers, your crew and answers to what you did always come through.");
    this.Text("Cyberbane-Settings-PhoneSound", "Message tone");
    this.Text("Cyberbane-Settings-MapMarkers", "Mark them on the map");
    this.Text("Cyberbane-Settings-MapMarkers-Desc", "Who carries a Cyberbane marker on your map and minimap: gold for a Rival, purple for an apex squad, white for everybody else (a crew, a bagman, somebody a favour is about). Everyone: all of them. Named only: Rivals, apex squads, and the people a favour or a bagman is about. Off leaves you to find them.");
    this.Text("Cyberbane-Settings-MapRemembers", "The map remembers");
    this.Text("Cyberbane-Settings-MapRemembers-Desc", "For a day after something big happens, a pin marks the spot: where a Rival fell, a gathering you crashed, a district that changed hands, one of your crew you lost. Hover it for who and when. With TweakXL installed, every Cyberbane pin also gets its own CYBERBANE box in the map's custom filters. Off when Mark them on the map is off.");
    this.Text("Cyberbane-MapFilter", "Cyberbane");
    this.Text("Cyberbane-Settings-PhoneSound-Desc", "Plays the phone's own text message tone when a message arrives.");
    this.Text("Cyberbane-Settings-MessageDelivery-Desc", "Phone puts everyone who gets in touch into your phone as a contact. Cards draws them on the left instead and keeps Cyberbane out of the phone. Notices is the old centre screen line. Off is silence, and changes nothing about the way the mod plays.");

    // ---- Settings: reputation -------------------------------------------
    this.Text("Cyberbane-Settings-RenownGain", "Renown gain");
    this.Text("Cyberbane-Settings-DreadGain", "Dread gain");
    this.Text("Cyberbane-Settings-Decay", "Decay rate");
    this.Text("Cyberbane-Settings-RumorSpread", "Rumor spread");
    this.Text("Cyberbane-Settings-StreetCredFloor", "Street Cred reputation floor");

    // ---- Settings: civilians --------------------------------------------
    this.Text("Cyberbane-Settings-CivReactions", "Civilian reactions");
    this.Text("Cyberbane-Settings-CivIntensity", "Civilian intensity");
    this.Text("Cyberbane-Settings-MaxReactingCiv", "Max reacting civilians");
    this.Text("Cyberbane-Settings-PanicDriving", "Panic driving");

    // ---- Settings: gangs ------------------------------------------------
    this.Text("Cyberbane-Settings-GangReactions", "Gang reactions");
    this.Text("Cyberbane-Settings-HostileOnSight", "Hostile on sight");
    this.Text("Cyberbane-Settings-Warnings", "Warnings");
    this.Text("Cyberbane-Settings-FactionDisguises", "Faction-colour disguises");
    this.Text("Cyberbane-Settings-Tribute", "Tribute");
    this.Text("Cyberbane-Settings-TributeMult", "Tribute amount");
    this.Text("Cyberbane-Settings-HitSquads", "Hit squads");
    this.Text("Cyberbane-Settings-HitSquadFreq", "How eager gangs are");
    this.Text("Cyberbane-Settings-EarlyGrace", "Before you're known");
    this.Text("Cyberbane-Settings-EarlyGrace-Desc", "Until your Street Cred reaches 20, around the time of the Heist, the street has barely heard of you. Your name grows more slowly, gangs and Rivals take longer to come for you, fewer people swear to get even, and no gang sends its best before Street Cred 15. It all eases off as your Street Cred climbs. Off, the street treats you as known from your first day.");
    this.Text("Cyberbane-Settings-ApexOn", "Apex squads");
    this.Text("Cyberbane-Settings-ApexOn-Desc", "Whether a gang that has earned it sends its best after you. Off, nobody ever sends an apex squad.");

    // ---- Settings: factions (1.9.1) -------------------------------------
    this.Text("Cyberbane-Settings-FactionOn-TygerClaws", "Tyger Claws");
    this.Text("Cyberbane-Settings-FactionOn-Maelstrom", "Maelstrom");
    this.Text("Cyberbane-Settings-FactionOn-Valentinos", "Valentinos");
    this.Text("Cyberbane-Settings-FactionOn-SixthStreet", "6th Street");
    this.Text("Cyberbane-Settings-FactionOn-Animals", "Animals");
    this.Text("Cyberbane-Settings-FactionOn-VoodooBoys", "Voodoo Boys");
    this.Text("Cyberbane-Settings-FactionOn-Scavengers", "Scavengers");
    this.Text("Cyberbane-Settings-FactionOn-Mox", "The Mox");
    this.Text("Cyberbane-Settings-FactionOn-Wraiths", "Wraiths");
    this.Text("Cyberbane-Settings-FactionOn-Aldecaldos", "Aldecaldos");
    this.Text("Cyberbane-Settings-FactionOn-Barghest", "Barghest");
    this.Text("Cyberbane-Settings-FactionOn-Scrappers", "Scrappers (Dogtown, Phantom Liberty)");
    this.Text("Cyberbane-Settings-FactionOn-Arasaka", "Arasaka");
    this.Text("Cyberbane-Settings-FactionOn-Militech", "Militech");
    this.Text("Cyberbane-Settings-FactionOn-KangTao", "Kang Tao");
    this.Text("Cyberbane-Settings-FactionOn-NCPD", "NCPD and MaxTac");
    this.Text("Cyberbane-Settings-FactionOn-Desc", "On: Cyberbane keeps a book on them and they act on it. Off: Cyberbane leaves them alone entirely. They never turn on you on sight because of Cyberbane, send nobody after you, make no Rivals and never text you. What you do to them still counts towards your reputation. Hostility set by the game or by another mod, such as They Will Remember, is not Cyberbane's to switch off.");
    this.Text("Cyberbane-Settings-GangViewAll", "All gangs");
    this.Text("Cyberbane-Settings-GangViewAll-Desc", "How every gang treats you. Earned in play is whatever you have earned with them. Choose anything else and every gang acts that way, whatever you do. Vendetta: every one of their people knows your face and attacks on sight, and they send crews and apex squads after you. Hostile: they know who you are and send crews when you give them a reason. A mask or their colours still hides you. How eager gangs are still sets how soon they come. Neutral: they leave you be. Friendly and Allied: lower prices on their turf, and a warning when their enemies come for you. Set a gang below to give it its own. What you earn keeps counting and comes back with Earned in play. Applies to every save.");
    this.Text("Cyberbane-Settings-GangView-Desc", "How this gang treats you. Same as All gangs follows the first setting on this page. Earned in play is whatever you have earned with them. Choose anything else and they act that way, whatever you do. What you earn keeps counting and comes back with Earned in play.");
    this.Text("Cyberbane-Settings-FactionOn-NCPD-Desc", "On: the police read your standing with them. Off: Cyberbane leaves the police alone entirely. Cyberbane never turns a cop on you on sight either way: the law has heat and stars for that. Wanted levels, and hostility set by another mod such as They Will Remember, are not Cyberbane's to switch off.");

    // ---- Settings: morale -----------------------------------------------
    this.Text("Cyberbane-Settings-Morale", "Combat morale");
    this.Text("Cyberbane-Settings-MoraleIntensity", "Morale intensity");
    this.Text("Cyberbane-Settings-MaxBreakFraction", "Most of a group that can run");

    // ---- Settings: police -----------------------------------------------

    // ---- Settings: economy ----------------------------------------------
    this.Text("Cyberbane-Settings-VendorPricing", "Vendor pricing");
    this.Text("Cyberbane-Settings-MaxDiscount", "Max discount (%)");
    this.Text("Cyberbane-Settings-GigBonus", "Gig reward bonus");
    this.Text("Cyberbane-Settings-GigBonusMult", "Gig bonus amount");

    // ---- Settings: rivals -----------------------------------------------
    this.Text("Cyberbane-Settings-Rivals", "Rivals");
    this.Text("Cyberbane-Settings-MaxRivals", "Max active Rivals");
    this.Text("Cyberbane-Settings-DeathsRemembered", "Night City remembers your deaths");
    this.Text("Cyberbane-Settings-RivalHideouts", "Tips on where Rivals are");
    this.Text("Cyberbane-Settings-RivalTeamUps", "Rivals team up");
    this.Text("Cyberbane-Settings-RivalTeamSize", "Rivals per team-up");
    this.Text("Cyberbane-Settings-PsychoBreaks", "Cyberpsychotic breaks");
    this.Text("Cyberbane-Settings-RivalFreq", "How eager Rivals are");

    // ---- Settings: interface --------------------------------------------
    this.Text("Cyberbane-Settings-Whispers", "Whispers");
    this.Text("Cyberbane-Settings-WhisperCooldown", "Whisper cooldown (s)");
    this.Text("Cyberbane-Settings-Toasts", "Show messages");
    this.Text("Cyberbane-Settings-CarsOnFoot", "Cars arrive on foot too");
    this.Text("Cyberbane-Settings-CarsPerArrival", "Cars per arrival");
    this.Text("Cyberbane-Settings-CarsPerArrival-Desc", "How many cars one crew or apex squad can arrive in. A group too big for one car comes in several, one after another, each picked to seat as many as it can; past this many, the rest walk in.");

    // ---- Settings: compatibility ----------------------------------------
    this.Text("Cyberbane-Settings-TwrCompat", "They Will Remember / Night City Remembers");
    this.Text("Cyberbane-Settings-VehicleArrivals", "Arrive by car");
    this.Text("Cyberbane-Settings-CarAmbushes", "Gangs lie in wait");
    this.Text("Cyberbane-Settings-CarAmbushes-Desc", "A gang sworn against you can park a car up the road and pull out as you drive past, more often where you're known to go; the Wraiths do it on Badlands roads whatever their grudge. On foot with a job tracked far away, a crew may wait for you near it instead, outside the job itself. A lookout you paid to keep watch warns you.");
    this.Text("Cyberbane-Settings-LootDrops", "Loot from the people sent after you");
    this.Text("Cyberbane-Settings-Bounties", "Rewards for kills");
    this.Text("Cyberbane-Settings-Scouts", "Scouts before crews");
    this.Text("Cyberbane-Settings-ShowCountdowns", "Show countdowns");
    this.Text("Cyberbane-Settings-HudLine", "Hunt line on the HUD");
    this.Text("Cyberbane-Settings-DistrictLine", "District line");
    this.Text("Cyberbane-Settings-DistrictLineSeconds", "District line, seconds");
    this.Text("Cyberbane-Settings-ApexStrength", "Apex strength");
    this.Text("Cyberbane-Settings-RivalStrength", "Rival strength");
    this.Text("Cyberbane-Settings-ApexTraits", "Apex traits");
    this.Text("Cyberbane-Settings-ApexBossBar", "Rival and apex bars");
    this.Text("Cyberbane-Settings-ApexArrivalSound", "Apex squad arrival horn");
    this.Text("Cyberbane-Settings-VendettaApexSquad", "Crews bring the apex squad");
    this.Text("Cyberbane-Settings-TurfWars", "Turf wars");
    this.Text("Cyberbane-Settings-TitlePerks", "Title effects");
    this.Text("Cyberbane-Settings-TitlePerks-Desc", "Whether the title you go by does anything. Off makes every title just a name.");
    this.Text("Cyberbane-Settings-TurfPatrols", "Turf patrols (experimental)");
    this.Text("Cyberbane-Settings-TurfPatrols-Desc", "Off by default. In a district that has changed hands, a few of the new owners walk a beat round their corner while you are around: mixed people, paid out of their war chest. If you are at war with them and they recognise you they attack; hurt one and they all turn on you. A beat walked without trouble tightens their hold on the street.");
    this.Text("Cyberbane-Settings-EnemyOfEnemy", "Enemy of my enemy");
    this.Text("Cyberbane-Settings-EnemyOfEnemy-Desc", "How much a gang warms to you when you kill its enemies, as a share of what the victims' gang loses. Zero means it never does. A gang you have hurt lately gives you nothing.");
    this.Text("Cyberbane-Settings-UnseenDread", "How frightening unseen work is");
    this.Text("Cyberbane-Settings-UnseenDread-Desc", "How much a killing nobody witnessed still adds to how frightening you are. Zero counts only what people saw.");
    this.Text("Cyberbane-Settings-BrutalConduct", "Melee kills cost Conduct");
    this.Text("Cyberbane-Settings-BrutalConduct-Desc", "Whether killing with a blade, bare hands or a takedown counts against your Conduct. Witnessed kills only.");
    this.Text("Cyberbane-Settings-EncounterGap", "Minutes between encounters");
    this.Text("Cyberbane-Settings-MessageHold", "How long words stay on screen");
    this.Text("Cyberbane-Settings-WordTravel", "Word travels (in-game minutes)");
    this.Text("Cyberbane-Settings-WordTravel-Desc", "How long news of what you did (a body, a dead Rival, a payout, a crew changing hands) takes to get round where it happened. From further away it takes longer, a district at a time, and nothing reaches you in the middle of a fight. The same story is only told once while it gets around. 0 sends it as soon as the fight is over.");
    this.Text("Cyberbane-Settings-InboxGap", "Gap between messages (seconds)");
    this.Text("Cyberbane-Settings-InboxGap-Desc", "The least time between two pieces of news arriving. Anything waiting arrives later, in order. 0 lets them through as soon as they are due.");
    this.Text("Cyberbane-Settings-CyberpsychoRivals", "Spared cyberpsychos come back");
    this.Text("Cyberbane-Settings-VendettaSquads", "Vendetta hit squads");
    this.Text("Cyberbane-Settings-VendettaSquadSize", "Vendetta squad size");

    // ---- Settings: debug ------------------------------------------------
    this.Text("Cyberbane-Settings-LogLevel", "Log level");
    this.Text("Cyberbane-Settings-FreezeReputation", "Freeze reputation");
    this.Text("Cyberbane-Settings-ResetAll", "Reset all Cyberbane data");
    this.Text("Cyberbane-Settings-SeparateSave", "This save is another character");
    this.Text("Cyberbane-Settings-HudScale", "Interface size");

    // ---- Core ------------------------------------------------------------
    this.Text("Cyberbane-Name", "Cyberbane");

    // ---- Settings: what each dropdown can be set to ----------------------------------------------------
    this.Text("Cyberbane-Settings-Value-Preset-Subtle", "Subtle");
    this.Text("Cyberbane-Settings-Value-Preset-Default", "Default");
    this.Text("Cyberbane-Settings-Value-Preset-Dramatic", "Dramatic");
    this.Text("Cyberbane-Settings-Value-Preset-Custom", "Custom");
    this.Text("Cyberbane-Settings-Value-Preset-Nemesis", "Nemesis");
    this.Text("Cyberbane-Settings-Value-Preset-TurfWar", "Turf war");
    this.Text("Cyberbane-Settings-Value-Preset-QuietLife", "Quiet life");
    this.Text("Cyberbane-Settings-Value-MessageDelivery-Phone", "Phone");
    this.Text("Cyberbane-Settings-Value-MessageDelivery-Cards", "Cards");
    this.Text("Cyberbane-Settings-Value-MessageDelivery-Notices", "Notices");
    this.Text("Cyberbane-Settings-Value-MessageDelivery-Off", "Off");
    this.Text("Cyberbane-Settings-Value-MessageAmount-Everything", "Everything");
    this.Text("Cyberbane-Settings-Value-MessageAmount-LessChatter", "Less chatter");
    this.Text("Cyberbane-Settings-Value-MessageAmount-Rarely", "Rarely");
    this.Text("Cyberbane-Settings-Value-HudLine-Everything", "Everything");
    this.Text("Cyberbane-Settings-Value-HudLine-HuntsOnly", "Hunts only");
    this.Text("Cyberbane-Settings-Value-HudLine-Off", "Off");
    this.Text("Cyberbane-Settings-Value-MarkerScope-Off", "Off");
    this.Text("Cyberbane-Settings-Value-MarkerScope-NamedOnly", "Named only");
    this.Text("Cyberbane-Settings-Value-MarkerScope-Everyone", "Everyone");
    this.Text("Cyberbane-Settings-Value-HomeGround-Open", "Open");
    this.Text("Cyberbane-Settings-Value-HomeGround-Quiet", "Quiet");
    this.Text("Cyberbane-Settings-Value-HomeGround-QuietButVendetta", "Quiet except a vendetta");
    this.Text("Cyberbane-Settings-Value-CrewOnJobs-Never", "Never");
    this.Text("Cyberbane-Settings-Value-CrewOnJobs-GigsAndSideJobs", "Gigs and side jobs");
    this.Text("Cyberbane-Settings-Value-CrewOnJobs-EverywhereButStory", "Everywhere but the story");
    this.Text("Cyberbane-Settings-Value-DistrictLine-Always", "Always");
    this.Text("Cyberbane-Settings-Value-DistrictLine-Briefly", "Briefly");
    this.Text("Cyberbane-Settings-Value-DistrictLine-Off", "Off");
    this.Text("Cyberbane-Settings-Value-GangViewAll-Earned", "Earned in play");
    this.Text("Cyberbane-Settings-Value-GangViewAll-Allied", "Allied");
    this.Text("Cyberbane-Settings-Value-GangViewAll-Friendly", "Friendly");
    this.Text("Cyberbane-Settings-Value-GangViewAll-Neutral", "Neutral");
    this.Text("Cyberbane-Settings-Value-GangViewAll-Hostile", "Hostile");
    this.Text("Cyberbane-Settings-Value-GangViewAll-Vendetta", "Vendetta");
    this.Text("Cyberbane-Settings-Value-GangView-AllGangs", "Same as All gangs");
    this.Text("Cyberbane-Settings-Value-GangView-Earned", "Earned in play");
    this.Text("Cyberbane-Settings-Value-GangView-Allied", "Allied");
    this.Text("Cyberbane-Settings-Value-GangView-Friendly", "Friendly");
    this.Text("Cyberbane-Settings-Value-GangView-Neutral", "Neutral");
    this.Text("Cyberbane-Settings-Value-GangView-Hostile", "Hostile");
    this.Text("Cyberbane-Settings-Value-GangView-Vendetta", "Vendetta");
    this.Text("Cyberbane-Settings-Value-TwrCompat-Auto", "Auto");
    this.Text("Cyberbane-Settings-Value-TwrCompat-On", "On");
    this.Text("Cyberbane-Settings-Value-TwrCompat-Off", "Off");
    this.Text("Cyberbane-Settings-Value-LogLevel-Off", "Off");
    this.Text("Cyberbane-Settings-Value-LogLevel-Info", "Info");
    this.Text("Cyberbane-Settings-Value-LogLevel-Verbose", "Verbose");
  }

  // ---- Home ground, a night at home, and slipping a gang's countdown. --------------------------------------
  protected func DefineHomeGround() -> Void {
    // A note when Cyberbane first learns one of V's homes. Notes start lower case: the game puts "Cyberbane: " in front.
    this.Text("Cyberbane-Home-Learned", "this building counts as your home ground now. While you are in it, Cyberbane's people leave you be (Home ground, under How often they come).");
    // After a night in V's own bed. {0} is a number of in-game hours.
    this.Text("Cyberbane-Home-Rested", "a night in your own bed. Nobody new comes looking for you for the next {0} hours.");
    // Why nobody is on their way, on the Hub ("waiting: ...").
    this.Text("Cyberbane-Held-HomeGround", "you are on home ground");
    // {0} is how much longer, in real time ("40m", "2h").
    this.Text("Cyberbane-Held-SleepPeace", "you slept at home: quiet for about {0} more");
    // On the Standing page, a lane lined up but waiting out everybody's rest after another fight. {0} the lane ("A gang crew"),
  // {1} who, {2} how long.
  this.Text("Cyberbane-Hud-WaitingOutTheBreather", "{0}   {1}  waiting out the breather, {2}");
  // When a gang sends people, once a day at most. {0} is the district V is in.
    this.Text("Cyberbane-Slip-Hint", "they only know roughly where you are. Change how you look, put a mask on or get out of {0} before they get here, and they may lose you.");
    this.Text("Cyberbane-Slip-HintNoDistrict", "they only know roughly where you are. Change how you look, put a mask on or get somewhere else before they get here, and they may lose you.");
    // They lost V before they set off. {0} is the gang.
    this.Text("Cyberbane-Slip-Lost", "{0} went where you were. You weren't. They'll be a while picking up your trail again.");
    // On the Standing page, under Visible chrome, about what V is wearing. Each starts with a space: it follows another line.
    this.Text("Cyberbane-Standing-Masked", " Masked: gangs take longer to find you, and a crew on its way can lose you.");
    // {0} is the gang.
    this.Text("Cyberbane-Standing-Colours", " In {0} gear: their people are slower to pick you out.");
  }

  // ---- CyberbaneAPI ----------------------------------------------------------------------------------------
  protected func DefineCyberbaneAPI() -> Void {
    // {0} name
    this.Text("Cyberbane-CyberbaneAPI-PutYouDownTheyWillBe", "{0} put you down. They will be looking for you.");
    // {0} name
    this.Text("Cyberbane-CyberbaneAPI-PutYouDownAgainTheyAre", "{0} put you down again. They are getting better at it.");
  }

  // ---- SmasherEncounters -----------------------------------------------------------------------------------
  protected func DefineSmasherEncounters() -> Void {
    this.Text("Cyberbane-SmasherEncounters-AdamSmasherIsAfterYou", "Adam Smasher is after you");
  }

  // ---- CyberbaneRuntime ------------------------------------------------------------------------------------
  protected func DefineCyberbaneRuntime() -> Void {
    this.Text("Cyberbane-CyberbaneRuntime-ItHasNotBeenAskedYet", "it has not been asked yet this session");
  }

  // ---- CyberbaneSystem -------------------------------------------------------------------------------------
  protected func DefineCyberbaneSystem() -> Void {
    this.Text("Cyberbane-CyberbaneSystem-ReputationWipedNightCityHasNever", "reputation wiped. Night City has never heard of you.");
    this.Text("Cyberbane-CyberbaneSystem-ThisSaveHasItsOwnRecords", "this save has its own records now. Nothing another character did follows you here.");
    // {0} dropped
    this.Text("Cyberbane-CyberbaneSystem-ThisSaveHasItsOwnRecords-2", "this save has its own records now. {0} Rival(s) from another character's deaths are gone.");
    // {0} removed
    this.Text("Cyberbane-CyberbaneSystem-ClearedRivals", "cleared {0} rivals.");
    // {0} lastName
    this.Text("Cyberbane-CyberbaneSystem-Forgot", "forgot {0}.");
    // {0} forgot
    this.Text("Cyberbane-CyberbaneSystem-ForgotRivals", "forgot {0} rivals.");
  }

  // ---- SafeAreas -------------------------------------------------------------------------------------------
  protected func DefineSafeAreas() -> Void {
    this.Text("Cyberbane-SafeAreas-WorldStillLoading", "world still loading");
    this.Text("Cyberbane-SafeAreas-YouCannotDrawHere", "you cannot draw here");
    this.Text("Cyberbane-SafeAreas-YouAreOnAJob", "you are on a job");
    this.Text("Cyberbane-SafeAreas-ProtectedArea", "protected area");
    this.Text("Cyberbane-SafeAreas-SafeArea", "safe area");
    this.Text("Cyberbane-SafeAreas-NoGroundToStandOn", "no ground to stand on");
    this.Text("Cyberbane-SafeAreas-TheGameRefusedTheSpawn", "the game refused the spawn");
    this.Text("Cyberbane-SafeAreas-NoGangMemberOnFile", "no gang member on file");
    this.Text("Cyberbane-SafeAreas-NowhereOutOfYourSight", "nowhere out of your sight");
    this.Text("Cyberbane-SafeAreas-YouAreInsideSomebodyElseS", "you are inside somebody else's turf");
    this.Text("Cyberbane-SafeAreas-TheStoryHasTheStage", "the story has the stage");
    this.Text("Cyberbane-SafeAreas-YouAreSomewhereSafe", "you are somewhere safe");
    this.Text("Cyberbane-SafeAreas-YouAreInAScene", "you are in a scene");
    this.Text("Cyberbane-SafeAreas-YouAreOnSomebodyElseS", "you are on somebody else's turf");
    this.Text("Cyberbane-SafeAreas-TheNCPDAreAfterYou", "the NCPD are after you");
    this.Text("Cyberbane-SafeAreas-RestrictedArea", "restricted area");
    this.Text("Cyberbane-SafeAreas-DangerousArea", "dangerous area");
    this.Text("Cyberbane-SafeAreas-OpenCity", "open city");
  }

  // ---- StealthState ----------------------------------------------------------------------------------------
  protected func DefineStealthState() -> Void {
    // {0} CBStoryLabel(sys.GetStoryHold())
    this.Text("Cyberbane-StealthState-HoldingOffNobodyWalksInOn", "Holding off: {0}. Nobody walks in on the story.");
    this.Text("Cyberbane-StealthState-SomebodyElseSTerritory", "somebody else's territory");
    // {0} zone
    this.Text("Cyberbane-StealthState-HoldingOffTheGameCallsThis", "Holding off: the game calls this a {0}. Nobody walks in on you there.");
    this.Text("Cyberbane-StealthState-HoldingOffWhileYouAreWorking", "Holding off while you are working quietly. They will not walk in on a stealth job.");
    this.Text("Cyberbane-StealthState-HoldingOffQuietJob", "holding off, quiet job");
    this.Text("Cyberbane-StealthState-WaitingTheirTurn", "waiting their turn");
    this.Text("Cyberbane-StealthState-HoldingOffYouAreBusy", "holding off, you are busy");
    this.Text("Cyberbane-StealthState-CannotReachYouHere", "cannot reach you here");
    this.Text("Cyberbane-StealthState-HoldingWorldIsLoading", "holding, world is loading");
    this.Text("Cyberbane-StealthState-HoldingOffStory", "holding off, story");
  }

  // ---- StoryHold -------------------------------------------------------------------------------------------
  protected func DefineStoryHold() -> Void {
    this.Text("Cyberbane-StoryHold-ASceneIsPlaying", "a scene is playing");
    this.Text("Cyberbane-StoryHold-TheStoryIsDirectingWhatYou", "the story is directing what you can do");
    this.Text("Cyberbane-StoryHold-SomebodyFromTheStoryIsWith", "somebody from the story is with you");
    this.Text("Cyberbane-StoryHold-YouAreNotYourselfRightNow", "you are not yourself right now");
    this.Text("Cyberbane-StoryHold-WhoeverWasAfterYouLostYou", "Whoever was after you lost you on the ride. They're still looking where you were.");
  }

  // ---- WorldState ------------------------------------------------------------------------------------------
  protected func DefineWorldState() -> Void {
    this.Text("Cyberbane-WorldState-TheWorldIsStillLoading", "The world is still loading.");
    this.Text("Cyberbane-WorldState-YouReDown", "You're down.");
    this.Text("Cyberbane-WorldState-TheGameIsPaused", "The game is paused.");
    this.Text("Cyberbane-WorldState-YouReInPhotoMode", "You're in photo mode.");
    this.Text("Cyberbane-WorldState-AMenuIsOpen", "A menu is open.");
    this.Text("Cyberbane-WorldState-YouReBusyWithSomethingSitting", "You're busy with something (sitting, a grab, a machine).");
    this.Text("Cyberbane-WorldState-YouReInTheMiddleOf", "You're in the middle of a scene.");
  }

  // ---- Districts -------------------------------------------------------------------------------------------
  protected func DefineDistricts() -> Void {
    this.Text("Cyberbane-Districts-WatsonTalksFastAndForgetsFast", "Watson talks fast and forgets fast.");
    this.Text("Cyberbane-Districts-WestbrookScaresEasilyAndKeepsIt", "Westbrook scares easily and keeps it to itself.");
    this.Text("Cyberbane-Districts-CityCenterSeesNothingAndSays", "City Center sees nothing and says less.");
    this.Text("Cyberbane-Districts-HeywoodRemembersEveryNameAndTells", "Heywood remembers every name, and tells the Valentinos.");
    this.Text("Cyberbane-Districts-SantoDomingoHasSeenWorseAnd", "Santo Domingo has seen worse, and looks after its own.");
    this.Text("Cyberbane-Districts-PacificaHasSeenEverything", "Pacifica has seen everything.");
    this.Text("Cyberbane-Districts-DogtownIsAWarZoneAnd", "Dogtown is a war zone, and Barghest hears everything.");
    this.Text("Cyberbane-Districts-OutInTheBadlandsWordTravels", "Out in the Badlands word travels slowly and is never lost.");
  }

  // ---- GangCodes -------------------------------------------------------------------------------------------
  protected func DefineGangCodes() -> Void {
    // {0} respect
    this.Text("Cyberbane-GangCodes-TheirCodeTheyRespect", "Their code: they respect {0}.");
    // {0} CBCodeNeverShort(f)
    this.Text("Cyberbane-GangCodes-NeverForgive", "Never forgive {0}. ");
    // {0} CBCodeFightShort(f)
    this.Text("Cyberbane-GangCodes-Fight", "Fight {0}. ");
    // {0} CBCodePeaceShort(f)
    this.Text("Cyberbane-GangCodes-Peace", "Peace: {0}.");
    this.Text("Cyberbane-GangCodes-HonourFamilyAndAFairFight", "honour, family and a fair fight, and mercy most of all");
    this.Text("Cyberbane-GangCodes-BusinessAndFace", "business and face");
    this.Text("Cyberbane-GangCodes-ChromeTheMoreOnShowThe", "chrome, the more on show the better");
    this.Text("Cyberbane-GangCodes-TheNeighbourhoodAndItsPeople", "the neighbourhood and its people");
    this.Text("Cyberbane-GangCodes-StrengthFistsOverGuns", "strength: fists over guns");
    this.Text("Cyberbane-GangCodes-Information", "information");
    this.Text("Cyberbane-GangCodes-LookingAfterTheirOwn", "looking after their own");
    this.Text("Cyberbane-GangCodes-NothingAndNobodyMissesThem", "nothing, and nobody misses them");
    this.Text("Cyberbane-GangCodes-TheRoad", "the road");
    this.Text("Cyberbane-GangCodes-FamilyAFavourRepaidAHarm", "family: a favour repaid, a harm remembered");
    this.Text("Cyberbane-GangCodes-Discipline", "discipline");
    this.Text("Cyberbane-GangCodes-AGoodHaulAndAChance", "a good haul, and a chance to walk away");
    this.Text("Cyberbane-GangCodes-AShotSurrenderDouble", "a shot surrender (double)");
    this.Text("Cyberbane-GangCodes-AnInsult", "an insult");
    this.Text("Cyberbane-GangCodes-HiddenChrome", "hidden chrome");
    this.Text("Cyberbane-GangCodes-HurtingSantoDomingoSPeople", "hurting Santo Domingo's people");
    this.Text("Cyberbane-GangCodes-ACowardWithAGun", "a coward with a gun");
    this.Text("Cyberbane-GangCodes-AnyoneTheyCanTTrace", "anyone they can't trace");
    this.Text("Cyberbane-GangCodes-HurtingJigJigStreetSPeople", "hurting Jig-Jig Street's people");
    this.Text("Cyberbane-GangCodes-MuchTheyRunAndNeverCome", "much: they run, and never come back as Rivals");
    this.Text("Cyberbane-GangCodes-AnyoneOnTheirRoad", "anyone on their road");
    this.Text("Cyberbane-GangCodes-HarmToFamilyTwiceAsLong", "harm to family, twice as long");
    this.Text("Cyberbane-GangCodes-AnythingButOnlyInDogtown", "anything, but only in Dogtown");
    this.Text("Cyberbane-GangCodes-AShotSurrenderButOnlyIn", "a shot surrender, but only in Dogtown");
    this.Text("Cyberbane-GangCodes-TogetherAndKinTakeAFallen", "together, and kin take a fallen Rival's place");
    this.Text("Cyberbane-GangCodes-FastAndTheyDRatherPay", "fast, and they'd rather pay than lose");
    this.Text("Cyberbane-GangCodes-ForYourChrome", "for your chrome");
    this.Text("Cyberbane-GangCodes-LikeSoldiers", "like soldiers");
    this.Text("Cyberbane-GangCodes-JuicedAndBarelyAfraid", "juiced, and barely afraid");
    this.Text("Cyberbane-GangCodes-ThroughTheNetFewInPerson", "through the Net, few in person");
    this.Text("Cyberbane-GangCodes-InSmallCrewsNeverTheirBest", "in small crews, never their best");
    this.Text("Cyberbane-GangCodes-WhenYouReHurtTheyBreak", "when you're hurt; they break when you're not");
    this.Text("Cyberbane-GangCodes-OnTheRoad", "on the road");
    this.Text("Cyberbane-GangCodes-AsOneFamily", "as one family");
    this.Text("Cyberbane-GangCodes-InNumbersNeverBreakingOrSurrendering", "in numbers, never breaking or surrendering");
    this.Text("Cyberbane-GangCodes-InTheRuinsTheyKnowAnd", "in the ruins they know, and break when it turns");
    this.Text("Cyberbane-GangCodes-SpareTheirsItCountsMoreThan", "spare theirs, it counts more than eddies");
    this.Text("Cyberbane-GangCodes-PayTheyReCheapest", "pay, they're cheapest");
    this.Text("Cyberbane-GangCodes-Pay", "pay");
    this.Text("Cyberbane-GangCodes-PayAndLeaveTheirNeighbourhoodAlone", "pay, and leave their neighbourhood alone");
    this.Text("Cyberbane-GangCodes-LeaveTheirPeopleAloneSpareThe", "leave their people alone, spare the ones who give up");
    this.Text("Cyberbane-GangCodes-CheapAndNobodyElseMinds", "cheap, and nobody else minds");
    this.Text("Cyberbane-GangCodes-PayAndStayOffTheirRoad", "pay, and stay off their road");
    this.Text("Cyberbane-GangCodes-SpareTheFamily", "spare the family");
    this.Text("Cyberbane-GangCodes-PayALotOrStayOut", "pay a lot, or stay out of Dogtown");
    this.Text("Cyberbane-GangCodes-CheapAndSpareTheOnesWho", "cheap, and spare the ones who give up");
  }

  // ---- Titles ----------------------------------------------------------------------------------------------
  protected func DefineTitles() -> Void {
    this.Text("Cyberbane-Titles-Cyberbane", "Cyberbane");
    this.Text("Cyberbane-Titles-LivingLegend", "Living Legend");
    this.Text("Cyberbane-Titles-AFactionSNightmare", "A Faction's Nightmare");
    this.Text("Cyberbane-Titles-FriendOfAFaction", "Friend of a Faction");
    this.Text("Cyberbane-Titles-ButcherOfTheDistrict", "Butcher of the District");
    this.Text("Cyberbane-Titles-GhostOfTheDistrict", "Ghost of the District");
    this.Text("Cyberbane-Titles-RivalBreaker", "Rival-Breaker");
    this.Text("Cyberbane-Titles-TheDistrictSProblem", "The District's Problem");
    this.Text("Cyberbane-Titles-ChromeSaint", "Chrome Saint");
    this.Text("Cyberbane-Titles-GlitchInTheSystem", "Glitch in the System");
    this.Text("Cyberbane-Titles-FistOfNightCity", "Fist of Night City");
    this.Text("Cyberbane-Titles-PsychoWhisperer", "Psycho Whisperer");
    this.Text("Cyberbane-Titles-PsychoHunter", "Psycho Hunter");
    this.Text("Cyberbane-Titles-Untouchable", "Untouchable");
    this.Text("Cyberbane-Titles-RedTide", "Red Tide");
    this.Text("Cyberbane-Titles-MaxTacSProblem", "MaxTac's Problem");
    this.Text("Cyberbane-Titles-TheMerciful", "The Merciful");
    this.Text("Cyberbane-Titles-KonpekiGhost", "Konpeki Ghost");
    this.Text("Cyberbane-Titles-FearedLandlord", "Feared Landlord");
    this.Text("Cyberbane-Titles-TheMercFromTheDistrict", "The Merc from the District");
    this.Text("Cyberbane-Titles-NumberOne", "Number One");
    this.Text("Cyberbane-Titles-Warlord", "Warlord");
    this.Text("Cyberbane-Titles-OpenSeasonSurvivor", "Open Season Survivor");
    this.Text("Cyberbane-Titles-PartyCrasher", "Party Crasher");
    this.Text("Cyberbane-Titles-TrophyHunter", "Trophy Hunter");
    this.Text("Cyberbane-Titles-Made", "Made");
    this.Text("Cyberbane-Titles-RewardsForKillsPay25More", "Rewards for kills pay 25% more, and people read you as 10% more frightening.");
    this.Text("Cyberbane-Titles-EnemiesAre15MoreLikelyTo", "Enemies are 15% more likely to break.");
    this.Text("Cyberbane-Titles-EnemiesAre10MoreLikelyTo", "Enemies are 10% more likely to break.");
    this.Text("Cyberbane-Titles-RewardsForKillsPay10More", "Rewards for kills pay 10% more.");
    this.Text("Cyberbane-Titles-RewardsForKillsPay15More", "Rewards for kills pay 15% more.");
    this.Text("Cyberbane-Titles-PeopleReadYouAs10More", "People read you as 10% more frightening.");
    this.Text("Cyberbane-Titles-EnemiesAre25MoreLikelyTo", "Enemies are 25% more likely to break and people read you as 15% more frightening. Rewards for kills pay 25% more. Crews send one extra.");
    this.Text("Cyberbane-Titles-YouEarnAnExtra10On", "You earn an extra 10% on every job and vendors charge 5% less. 10% more people recognise you.");
    this.Text("Cyberbane-Titles-EnemiesAre20MoreLikelyTo", "Enemies are 20% more likely to break. Paying a gang off costs 25% more.");
    this.Text("Cyberbane-Titles-PayingAGangOffCosts30", "Paying a gang off costs 30% less, and each kill costs you 25% less standing with that gang.");
    this.Text("Cyberbane-Titles-YourKillsHurtAGangS", "Your kills hurt a gang's hold on its streets 30% more. Each kill costs you 25% more standing.");
    this.Text("Cyberbane-Titles-HuntersFindYou20LessEasily", "Hunters find you 20% less easily, and 10% fewer people recognise you.");
    this.Text("Cyberbane-Titles-RewardsForKillsPay40More", "Rewards for kills pay 40% more.");
    this.Text("Cyberbane-Titles-VendorsCharge6LessToKeep", "Vendors charge 6% less to keep you happy. 5% more people recognise you.");
    this.Text("Cyberbane-Titles-PeopleReadYouAs15More", "People read you as 15% more frightening, and enemies are 10% more likely to break.");
    this.Text("Cyberbane-Titles-HuntersGiveUpOnYou25", "Hunters give up on you 25% sooner.");
    this.Text("Cyberbane-Titles-EnemiesAre15MoreLikelyTo-2", "Enemies are 15% more likely to break, and kills earn you 10% more Renown.");
    this.Text("Cyberbane-Titles-SparingPeopleEarns50MoreGoodwill", "Sparing people earns 50% more goodwill with their gang.");
    this.Text("Cyberbane-Titles-RewardsForKillsPay20More", "Rewards for kills pay 20% more.");
    this.Text("Cyberbane-Titles-HuntersFindYou15LessEasily", "Hunters find you 15% less easily and give up on you 15% sooner.");
    this.Text("Cyberbane-Titles-EnemiesAre20MoreLikelyTo-2", "Enemies are 20% more likely to break. 10% more people recognise you.");
    this.Text("Cyberbane-Titles-CrewsRivalsAndApexSquadsLeave", "Crews, Rivals and apex squads leave 25% more loot.");
    this.Text("Cyberbane-Titles-SparingPeopleEarnsTwiceTheGoodwill", "Sparing people earns twice the goodwill and paying a gang off costs 20% less. People find you 25% less frightening.");
    this.Text("Cyberbane-Titles-HuntersFindYou25LessEasily", "Hunters find you 25% less easily and 15% fewer people recognise you. Kills earn you 10% less Renown.");
    this.Text("Cyberbane-Titles-TributePays50More", "Tribute pays 50% more.");
    this.Text("Cyberbane-Titles-YouEarnAnExtra5On", "You earn an extra 5% on every job and vendors charge 2% less.");
  }

  // ---- Traits ----------------------------------------------------------------------------------------------
  protected func DefineTraits() -> Void {
    this.Text("Cyberbane-Traits-Tough", "Tough");
    this.Text("Cyberbane-Traits-Armored", "Armored");
    this.Text("Cyberbane-Traits-Deadeye", "Deadeye");
    this.Text("Cyberbane-Traits-Quick", "Quick");
    this.Text("Cyberbane-Traits-PackLeader", "Pack Leader");
    this.Text("Cyberbane-Traits-GrudgeBearer", "Grudge-Bearer");
    this.Text("Cyberbane-Traits-HardToScare", "Hard to Scare");
    this.Text("Cyberbane-Traits-ChromedOut", "Chromed-Out");
    this.Text("Cyberbane-Traits-Scarred", "Scarred");
    this.Text("Cyberbane-Traits-Confident", "Confident");
    this.Text("Cyberbane-Traits-Humiliated", "Humiliated");
    this.Text("Cyberbane-Traits-Shaken", "Shaken");
    this.Text("Cyberbane-Traits-OldWound", "Old Wound");
    this.Text("Cyberbane-Traits-Reckless", "Reckless");
    this.Text("Cyberbane-Traits-Cyberpsycho", "Cyberpsycho");
  }

  // ---- GigBonus --------------------------------------------------------------------------------------------
  protected func DefineGigBonus() -> Void {
    // {0} bonus
    this.Text("Cyberbane-GigBonus-ThrewAnExtraEbOnThat", "Threw an extra {0}eb on that one. Your name is worth something now.");
  }

  // ---- Peace -----------------------------------------------------------------------------------------------
  protected func DefinePeace() -> Void {
    this.Text("Cyberbane-Peace-NightCityRemembers", "Night City Remembers");
    this.Text("Cyberbane-Peace-TheyWillRemember", "They Will Remember");
    this.Text("Cyberbane-Peace-NCR", "NCR");
    this.Text("Cyberbane-Peace-TWR", "TWR");
    this.Text("Cyberbane-Peace-ItsAttitudeClassIsNotIn", "its attitude class is not in this build");
    this.Text("Cyberbane-Peace-Nothing", "nothing");
    // {0} (StrLen(seen) > 0 ? "; " : ""), {1} NameToString(name), {2} CBReflectParamNames(paramList), {3} retName
    this.Text("Cyberbane-Peace-TakesAndAnswers", "{0}{1} takes {2} and answers {3}");
    // {0} seen
    this.Text("Cyberbane-Peace-ItsFunctionsAreNotTheShape", "its functions are not the shape Cyberbane asks, one gang's number in and yes or no out ({0})");
    this.Text("Cyberbane-Peace-ItHasNoneOfTheFunctions", "it has none of the functions Cyberbane knows to ask (IsFactionHostileByIndex)");
    this.Text("Cyberbane-Peace-ItsAttitudeSystemIsNotRunning", "its attitude system is not running");
    this.Text("Cyberbane-Peace-ItWouldNotTakeTheQuestion", "it would not take the question");
    // {0} cost
    this.Text("Cyberbane-Peace-ThereSHardlyAnyOfUs", "There's hardly any of us left. {0}eb to bury our dead, and it's over.");
    // {0} cost
    this.Text("Cyberbane-Peace-YouMadeYourPointEbAnd", "You made your point. {0}eb and nobody of ours comes near you again.");
    // {0} cost
    this.Text("Cyberbane-Peace-WeReDoneFightingYouEb", "We're done fighting you. {0}eb and we let it go.");
    // {0} cost
    this.Text("Cyberbane-Peace-OrPayEbAndItStops", "Or pay {0}eb and it stops.");
    // {0} cost
    this.Text("Cyberbane-Peace-EbAndWeCallItOff", "{0}eb and we call it off. Your choice.");
    // {0} cost
    this.Text("Cyberbane-Peace-UnlessEbReachesUsFirst", "Unless {0}eb reaches us first.");
    // {0} cost
    this.Text("Cyberbane-Peace-YouAreStillWalkingAroundEb", "You are still walking around. {0}eb and we let you keep doing it.");
    // {0} cost
    this.Text("Cyberbane-Peace-OurPriceHasNotChangedEb", "Our price has not changed. {0}eb and we call every one of ours off you.");
    // {0} cost
    this.Text("Cyberbane-Peace-EbThatIsWhatItCosts", "{0}eb. That is what it costs to stop being our problem.");
    // {0} cost
    this.Text("Cyberbane-Peace-WeHaveNotForgottenYouEb", "We have not forgotten you. {0}eb and we do.");
    // {0} cost
    this.Text("Cyberbane-Peace-EbSettlesWhatIsBetweenUs", "{0}eb settles what is between us. Think about it.");
    // {0} cost
    this.Text("Cyberbane-Peace-YouCanKeepLookingOverYour", "You can keep looking over your shoulder, or you can pay {0}eb.");
    // {0} cost
    this.Text("Cyberbane-Peace-EbAndWeForgetAboutYou", "{0}eb and we forget about you. Come back when you have it.");
    this.Text("Cyberbane-Peace-Vendetta", "vendetta");
    this.Text("Cyberbane-Peace-Hostility", "hostility");
    // {0} cost, {1} what
    this.Text("Cyberbane-Peace-EbReceivedTheIsOverDo", "{0}eb received. The {1} is over. Do not make us revisit it.");
  }

  // ---- Tribute ---------------------------------------------------------------------------------------------
  protected func DefineTribute() -> Void {
    // {0} amount
    this.Text("Cyberbane-Tribute-EbNoStringsWeWouldRather", "{0}eb. No strings. We would rather pay you than fight you, and there's more where that came from.");
    // {0} amount
    this.Text("Cyberbane-Tribute-EbAsAgreedWeWouldRather", "{0}eb, as agreed. We would rather pay you than fight you.");
  }

  // ---- War -------------------------------------------------------------------------------------------------
  protected func DefineWar() -> Void {
    this.Text("Cyberbane-War-Broke", "broke");
    this.Text("Cyberbane-War-Flush", "flush");
    this.Text("Cyberbane-War-CountingEveryEddie", "counting every eddie");
    this.Text("Cyberbane-War-NobodyLeftToSend", ", nobody left to send");
    this.Text("Cyberbane-War-RanksThin", ", ranks thin");
    this.Text("Cyberbane-War-AndYouBackThem", ", and you back them");
    this.Text("Cyberbane-War-YouBackThem", "you back them");
    // {0} CBFactionLabel(truce)
    this.Text("Cyberbane-War-InATruceWithAgainstYou", ", in a truce with {0} against you");
    this.Text("Cyberbane-War-District", "district");
    this.Text("Cyberbane-War-Districts", "districts");
    // {0} cut, {1} streets, {2} plural
    this.Text("Cyberbane-War-YourCutForTheWeekEb", "Your cut for the week: {0}eb. {1} {2} ours, thanks to you.");
    // {0} CBDistrictLabel(d)
    this.Text("Cyberbane-War-NobodyRunsAnyMoreButYou", "Nobody runs {0} any more but you. The gangs pass through on your say-so.");
    // {0} toll
    this.Text("Cyberbane-War-TheGangsPaidTheirWayThrough", "The gangs paid their way through your streets this week: {0}eb.");
    // {0} CBCapFirst(CBFactionLabel(fs.id)), {1} CBFactionLabel(other)
    this.Text("Cyberbane-War-AndHaveStoppedKillingEachOther", "{0} and {1} have stopped killing each other. They're coming for you together.");
    this.Text("Cyberbane-War-YouDidWhatWeAskedWe", "You did what we asked. We're square. For now.");
    this.Text("Cyberbane-War-YouDidnTPayThatS", "You didn't pay. That's bad for business. Yours.");
    // {0} amount
    this.Text("Cyberbane-War-YouWorkJapantownYouPayThe", "You work Japantown, you pay the Claws. {0}eb, to any of ours on the street, in the next two days. Don't make us come asking.");
    // {0} book.ProtectAmount()
    this.Text("Cyberbane-War-PayEbProtection", "[Pay] {0}eb. Protection.");
    this.Text("Cyberbane-War-SideWithThemYourWarIs", "[Side with them] Your war is my war.");
    // {0} CBCapFirst(CBFactionLabel(enemy))
    this.Text("Cyberbane-War-LieArePlanningAHitOn", "[Lie] {0} are planning a hit on you.");
    this.Text("Cyberbane-War-DealWhatWouldItTakeTo", "[Deal] What would it take to end this?");
    this.Text("Cyberbane-War-NotNow", "Not now.");
    this.Text("Cyberbane-War-YouRePaidUpDonT", "You're paid up. Don't worry about it.");
    this.Text("Cyberbane-War-ThatSShortComeBackWith", "That's short. Come back with all of it.");
    this.Text("Cyberbane-War-PleasureDoingBusinessJapantownSSafe", "Pleasure doing business. Japantown's safe for you this week.");
    this.Text("Cyberbane-War-SmartNobodyOfOursBothersA", "Smart. Nobody of ours bothers a paying customer.");
    this.Text("Cyberbane-War-ThenYouReWithUsHurt", "Then you're with us. Hurt our enemies and you'll get your cut.");
    this.Text("Cyberbane-War-GoodEveryStreetWeTakeYou", "Good. Every street we take, you get a piece.");
    this.Text("Cyberbane-War-WelcomeToTheWarChoomOur", "Welcome to the war, choom. Our enemies are yours now.");
    this.Text("Cyberbane-War-WhoNeverHeardOfThem", "Who? Never heard of them.");
    this.Text("Cyberbane-War-TheyReWhatThenWeHit", "They're what? Then we hit them first.");
    this.Text("Cyberbane-War-IKnewItIKnewThey", "I knew it. I knew they'd try something. Thanks, merc.");
    this.Text("Cyberbane-War-EverybodySGoingToHearAbout", "Everybody's going to hear about this.");
    this.Text("Cyberbane-War-NiceTryYouWantUsFighting", "Nice try. You want us fighting so you can pick at the bones.");
    this.Text("Cyberbane-War-YouThinkIMStupid", "You think I'm stupid?");
    this.Text("Cyberbane-War-ThereSNothingToEnd", "There's nothing to end.");
    // {0} quote
    this.Text("Cyberbane-War-EbSendItAndWeRe", "{0}eb. Send it and we're done.");
    // {0} quote, {1} CBFactionLabel(enemy)
    this.Text("Cyberbane-War-EddiesOfThemOrDoUs", "Eddies, {0} of them. Or do us a favour: break up whatever {1} have going next near here. Do that and we're square.");
  }

  // ---- DeedEngine ------------------------------------------------------------------------------------------
  protected func DefineDeedEngine() -> Void {
    // {0} CBTitleDisplayById(sys, content, tid)
    this.Text("Cyberbane-DeedEngine-HeardThemCallingYouToday", "Heard them calling you {0} today.");
    this.Text("Cyberbane-DeedEngine-YourNameCameUpAgainToday", "Your name came up again today. It is getting around.");
  }

  // ---- Encounter -------------------------------------------------------------------------------------------
  protected func DefineEncounter() -> Void {
    this.Text("Cyberbane-Encounter-HeardWhatYouLeftBehindPeople", "Heard what you left behind. People are going to be repeating that one.");
  }

  // ---- GangRivalries ---------------------------------------------------------------------------------------
  protected func DefineGangRivalries() -> Void {
    // {0} enemyLabel
    this.Text("Cyberbane-GangRivalries-YouHaveDoneMoreToThan", "You have done more to {0} than half our own crew. Our streets are yours. Prices too.");
    this.Text("Cyberbane-GangRivalries-YouHaveEarnedItOurStreets", "You have earned it. Our streets are yours. Prices too.");
    // {0} enemyLabel
    this.Text("Cyberbane-GangRivalries-WordIsYouHaveBeenMaking", "Word is you have been making life hard for {0}. You are welcome on our streets.");
    this.Text("Cyberbane-GangRivalries-YouAreAllRightByUs", "You are all right by us. You are welcome on our streets.");
    // {0} label
    this.Text("Cyberbane-GangRivalries-HeadsUpJustSentPeopleYour", "Heads up. {0} just sent people your way. Watch the road.");
  }

  // ---- Ledger ----------------------------------------------------------------------------------------------
  protected func DefineLedger() -> Void {
    this.Text("Cyberbane-Ledger-WeHeardHowYouShootOur", "We heard how you shoot. Our people are wearing plate now.");
    this.Text("Cyberbane-Ledger-YouLikeYourGunsWeBought", "You like your guns. We bought armour. Let's see who wins.");
    this.Text("Cyberbane-Ledger-EveryOneOfOursIsPlated", "Every one of ours is plated up for you, merc.");
    this.Text("Cyberbane-Ledger-YouLikeItUpCloseWe", "You like it up close? We're sending people who can take a hit.");
    this.Text("Cyberbane-Ledger-HeardYouFightWithYourHands", "Heard you fight with your hands. Ours are tougher now.");
    this.Text("Cyberbane-Ledger-NextTimeYouGetCloseYou", "Next time you get close, you'll find out we got harder.");
    this.Text("Cyberbane-Ledger-OurPeopleAreRunningFreshICE", "Our people are running fresh ICE. Your hacks won't land like they used to.");
    this.Text("Cyberbane-Ledger-WePaidANetrunnerToLock", "We paid a netrunner to lock us down. Try your tricks now.");
    this.Text("Cyberbane-Ledger-TheyReBringingICEForYou", "They're bringing ICE for you, merc.");
    this.Text("Cyberbane-Ledger-YouAndYourGrenadesWeWear", "You and your grenades. We wear heavier now.");
    this.Text("Cyberbane-Ledger-BlowUsUpAgainSeeHow", "Blow us up again. See how many of us stay down.");
    this.Text("Cyberbane-Ledger-WeLearnedFromEveryBlastCome", "We learned from every blast. Come try another.");
    this.Text("Cyberbane-Ledger-SneakingWonTWorkTwiceEvery", "Sneaking won't work twice. Every one of ours keeps their eyes open now.");
    this.Text("Cyberbane-Ledger-YouLikeTheShadowsWeVe", "You like the shadows? We've got people watching every one.");
    this.Text("Cyberbane-Ledger-NoMoreBodiesWithNobodySeeing", "No more bodies with nobody seeing. We're looking for you now.");
  }

  // ---- Reputation ------------------------------------------------------------------------------------------
  protected func DefineReputation() -> Void {
    this.Text("Cyberbane-Reputation-YouAreDeadToUsEvery", "You are dead to us. Every one of ours who sees you will try.");
  }

  // ---- RumorEngine -----------------------------------------------------------------------------------------
  protected func DefineRumorEngine() -> Void {
    // {0} where
    this.Text("Cyberbane-RumorEngine-In", " in {0}");
    // {0} (StrLen(where) > 0 ? " in " + where : "")
    this.Text("Cyberbane-RumorEngine-SomebodyHadARecorderRunningWhat", "Somebody had a recorder running. What you did{0} is on every BD stall from Kabuki to Pacifica.");
    this.Text("Cyberbane-RumorEngine-ItSABraindanceNowKids", "It's a braindance now. Kids in Japantown are playing your night on repeat.");
    this.Text("Cyberbane-RumorEngine-EveryScrollerInTheCityHas", "Every scroller in the city has the footage. Your face, frame by frame.");
  }

  // ---- StreetBook ------------------------------------------------------------------------------------------
  protected func DefineStreetBook() -> Void {
    this.Text("Cyberbane-StreetBook-PeopleHaveStartedNoticingWhatYou", "People have started noticing what you drive. Turn up in it again and a mask won't help.");
    this.Text("Cyberbane-StreetBook-ThatGunOfYoursHasA", "That gun of yours has a reputation now. Use it with your face covered and they'll still know it's you.");
    // {0} carName, {1} gunName
    this.Text("Cyberbane-StreetBook-TheyKnowYourAndYourA", "They know your {0} and your {1}. A mask won't hide you with either.");
    // {0} carName
    this.Text("Cyberbane-StreetBook-TheyKnowYourAMaskWon", "They know your {0}. A mask won't hide you in it.");
    // {0} gunName
    this.Text("Cyberbane-StreetBook-TheyKnowYourAMaskWon-2", "They know your {0}. A mask won't hide you with it in your hands.");
    this.Text("Cyberbane-StreetBook-TheyKnowTheCarYouDrive", "They know the car you drive. A mask won't hide you in it.");
    this.Text("Cyberbane-StreetBook-TheyKnowYourGunAMask", "They know your gun. A mask won't hide you with it in your hands.");
  }

  // ---- StreetRead ------------------------------------------------------------------------------------------
  protected func DefineStreetRead() -> Void {
    this.Text("Cyberbane-StreetRead-Butcher", "butcher");
    this.Text("Cyberbane-StreetRead-Ghost", "ghost");
    this.Text("Cyberbane-StreetRead-Professional", "professional");
    this.Text("Cyberbane-StreetRead-ChromedUpMerc", "chromed-up merc");
    this.Text("Cyberbane-StreetRead-Netrunner", "netrunner");
    this.Text("Cyberbane-StreetRead-Brawler", "brawler");
  }

  // ---- Territory -------------------------------------------------------------------------------------------
  protected func DefineTerritory() -> Void {
    this.Text("Cyberbane-Territory-Broken", "broken");
    this.Text("Cyberbane-Territory-Bleeding", "bleeding");
    this.Text("Cyberbane-Territory-Hurting", "hurting");
    this.Text("Cyberbane-Territory-Strong", "strong");
    // {0} cap
    this.Text("Cyberbane-Territory-AreBrokenHalfTheirCornersAre", "{0} are broken. Half their corners are empty, and everybody knows who emptied them.");
    // {0} cap
    this.Text("Cyberbane-Territory-AreBleedingTheirCornersHaveBeen", "{0} are bleeding. Their corners have been thin since you started on them.");
    this.Text("Cyberbane-Territory-CONTESTED", "CONTESTED - ");
    // {0} holder
    this.Text("Cyberbane-Territory-HELDBY", "HELD BY {0} - ");
    // {0} CBCapFirst(o), {1} h, {2} place
    this.Text("Cyberbane-Territory-HitInLastNightTheyWant", "{0} hit {1} in {2} last night. They want it back.");
    // {0} wCap, {1} place, {2} l
    this.Text("Cyberbane-Territory-HaveTakenBackFrom", "{0} have taken {1} back from {2}.");
    // {0} wCap, {1} l, {2} place
    this.Text("Cyberbane-Territory-HavePushedOutOfItS", "{0} have pushed {1} out of {2}. It's their streets now.");
    // {0} place, {1} lCap
    this.Text("Cyberbane-Territory-IsOursNowCouldNotHold", "{0} is ours now. {1} could not hold it after what you did to them. We remember who to thank.");
    // {0} wCap, {1} place, {2} l
    this.Text("Cyberbane-Territory-MovedIntoTheMomentCouldNot", "{0} moved into {1} the moment {2} could not hold it. Everybody knows who broke them.");
  }

  // ---- TitleEngine -----------------------------------------------------------------------------------------
  protected func DefineTitleEngine() -> Void {
    // {0} CBTitleDisplay(sys, def)
    this.Text("Cyberbane-TitleEngine-PeopleAreCallingYouNow", "People are calling you {0} now.");
    this.Text("Cyberbane-TitleEngine-ReachTheTopOfTheHunters", "Reach the top of the hunters' ladder.");
    this.Text("Cyberbane-TitleEngine-MakeADistrictYourOwnA", "Make a district your own: a Legend, where every gang is broken.");
    this.Text("Cyberbane-TitleEngine-LiveThroughAGangSOpen", "Live through a gang's open season.");
    this.Text("Cyberbane-TitleEngine-CrashThreeOfTheGangsGatherings", "Crash three of the gangs' gatherings, deals or sit-downs.");
    this.Text("Cyberbane-TitleEngine-TakeATrophyOffThreeNamed", "Take a trophy off three named Rivals.");
    this.Text("Cyberbane-TitleEngine-BecomeOneOfAGangS", "Become one of a gang's own.");
    this.Text("Cyberbane-TitleEngine-ReachThisMuchRenown", "Reach this much Renown");
    this.Text("Cyberbane-TitleEngine-InstalledChromeScoreFromHowMuch", "Installed chrome score, from how much of your cyberware capacity or slots you fill and how good the implants are");
    this.Text("Cyberbane-TitleEngine-QuickhackKillsBuildIt", "Quickhack kills build it.");
    this.Text("Cyberbane-TitleEngine-KillPeopleWithQuickhacks", "Kill people with quickhacks");
    this.Text("Cyberbane-TitleEngine-KillCyberpsychos", "Kill cyberpsychos");
    this.Text("Cyberbane-TitleEngine-TakeCyberpsychosDownWithoutKillingThem", "Take cyberpsychos down without killing them");
    this.Text("Cyberbane-TitleEngine-FistsAndBluntWeaponsBuildIt", "Fists and blunt weapons build it, knockouts included.");
    this.Text("Cyberbane-TitleEngine-PutPeopleDownDeadOrBreathing", "Put people down, dead or breathing");
    this.Text("Cyberbane-TitleEngine-WinFightsOf2OrMore", "Win fights of 2 or more kills with your health never under 95%");
    // {0} CBConfig.MassacreTotalKills(), {1} CBConfig.MassacreWindowKills(), {2} RoundF(CBConfig.MassacreWindowSeconds())
    this.Text("Cyberbane-TitleEngine-MassacresBodiesInOneFightOr", "Massacres: {0} bodies in one fight, or {1} within {2} seconds");
    this.Text("Cyberbane-TitleEngine-KillMaxTacOfficers", "Kill MaxTac officers");
    this.Text("Cyberbane-TitleEngine-KillRivals", "Kill Rivals");
    this.Text("Cyberbane-TitleEngine-TakePeopleDownWithoutKillingThem", "Take people down without killing them");
    // {0} CBReqNum("Take people down without killing them", stats.nonLethal, 100, {1} CBKillsByClass(sys, EnumInt(ECBVictimClass.Civilian))
    this.Text("Cyberbane-TitleEngine-NeverKillACivilianYouHave", "{0}.\nNever kill a civilian. You have killed {1}.");
    this.Text("Cyberbane-TitleEngine-CollectTributeFromGangsAfraidOf", "Collect tribute from gangs afraid of you");
    this.Text("Cyberbane-TitleEngine-ReachThisStandingWithOneGang", "Reach this standing with one gang");
    this.Text("Cyberbane-TitleEngine-YouHaveNotFoughtOneYet", "You have not fought one yet.");
    // {0} CBCapFirst(CBFactionLabel(gang)), {1} Min(most, 75), {2} RoundF(score.GetFactionFear(gang)), {3} fearNeed
    this.Text("Cyberbane-TitleEngine-75KilledFear", "{0}: {1}/75 killed, fear {2}/{3}.");
    // {0} fearNeed, {1} (Equals(gang, n"") ? "You have not fought one yet."             : CBCa
    this.Text("Cyberbane-TitleEngine-OneGangHasToLose75", "One gang has to lose 75 people to you and fear you at {0} or more.\n{1}");
    this.Text("Cyberbane-TitleEngine-KillingPeopleBuildsItBrutallyFaster", "Killing people builds it, brutally faster.");
    this.Text("Cyberbane-TitleEngine-KillsInOneDistrict", "Kills in one district");
    this.Text("Cyberbane-TitleEngine-TakingPeopleDownUnseenBuildsIt", "Taking people down unseen builds it.");
    this.Text("Cyberbane-TitleEngine-QuietNonLethalTakedownsInOne", "Quiet non-lethal takedowns in one district");
    this.Text("Cyberbane-TitleEngine-ReachThisMuchDread", "Reach this much Dread");
    this.Text("Cyberbane-TitleEngine-ReachThisMuchRenownInOne", "Reach this much Renown in one district");
    this.Text("Cyberbane-TitleEngine-KillsNobodySaw", "Kills nobody saw");
    // {0} CBReqStyle(sys, ECBArchetype.Ghost, "Taking people down unseen builds , {1} CBReqNum("Kills nobody saw", stats.unattributed, CBConfig.KonpekiUnatt
    this.Text("Cyberbane-TitleEngine-FinishTheHeistOrDoBoth", "Finish The Heist, or do both of these:\n{0}\n{1}.");
    this.Text("Cyberbane-TitleEngine-Renown", "Renown");
    this.Text("Cyberbane-TitleEngine-Dread", "Dread");
    this.Text("Cyberbane-TitleEngine-RivalsKilled", "Rivals killed");
    // {0} RoundF(CBConfig.TitleFearNeeded())
    this.Text("Cyberbane-TitleEngine-GangsThatFearYouAtOr", "Gangs that fear you at {0} or more");
    // {0} where
    this.Text("Cyberbane-TitleEngine-BestSoFar", ", best so far {0}");
    this.Text("Cyberbane-TitleEngine-NotSettledYet", "not settled yet");
    // {0} CBArchetypeName(EnumInt(style)), {1} how, {2} yours
    this.Text("Cyberbane-TitleEngine-MustBeYourMainFightingStyle", "{0} must be your main fighting style. {1} Yours is {2}.");
  }

  // ---- TitleNaming -----------------------------------------------------------------------------------------
  protected func DefineTitleNaming() -> Void {
    this.Text("Cyberbane-TitleNaming-Watson", "Watson");
    this.Text("Cyberbane-TitleNaming-Westbrook", "Westbrook");
    this.Text("Cyberbane-TitleNaming-CityCenter", "City Center");
    this.Text("Cyberbane-TitleNaming-Heywood", "Heywood");
    this.Text("Cyberbane-TitleNaming-SantoDomingo", "Santo Domingo");
    this.Text("Cyberbane-TitleNaming-Pacifica", "Pacifica");
    this.Text("Cyberbane-TitleNaming-Dogtown", "Dogtown");
    this.Text("Cyberbane-TitleNaming-TheBadlands", "the Badlands");
    this.Text("Cyberbane-TitleNaming-Maelstrom", "Maelstrom");
    this.Text("Cyberbane-TitleNaming-TheTygerClaws", "the Tyger Claws");
    this.Text("Cyberbane-TitleNaming-TheValentinos", "the Valentinos");
    this.Text("Cyberbane-TitleNaming-6thStreet", "6th Street");
    this.Text("Cyberbane-TitleNaming-TheAnimals", "the Animals");
    this.Text("Cyberbane-TitleNaming-TheVoodooBoys", "the Voodoo Boys");
    this.Text("Cyberbane-TitleNaming-TheScavs", "the Scavs");
    this.Text("Cyberbane-TitleNaming-TheMox", "the Mox");
    this.Text("Cyberbane-TitleNaming-Barghest", "Barghest");
    this.Text("Cyberbane-TitleNaming-TheScrappers", "the Scrappers");
    this.Text("Cyberbane-TitleNaming-TheAldecaldos", "the Aldecaldos");
    this.Text("Cyberbane-TitleNaming-TheWraiths", "the Wraiths");
    this.Text("Cyberbane-TitleNaming-Arasaka", "Arasaka");
    this.Text("Cyberbane-TitleNaming-Militech", "Militech");
    this.Text("Cyberbane-TitleNaming-KangTao", "Kang Tao");
    this.Text("Cyberbane-TitleNaming-TheNCPD", "the NCPD");
    this.Text("Cyberbane-TitleNaming-MaxTac", "MaxTac");
    this.Text("Cyberbane-TitleNaming-TygerClaws", "Tyger Claws");
    this.Text("Cyberbane-TitleNaming-Valentinos", "Valentinos");
    this.Text("Cyberbane-TitleNaming-Animals", "Animals");
    this.Text("Cyberbane-TitleNaming-VoodooBoys", "Voodoo Boys");
    this.Text("Cyberbane-TitleNaming-Scavs", "Scavs");
    this.Text("Cyberbane-TitleNaming-Mox", "Mox");
    this.Text("Cyberbane-TitleNaming-Scrappers", "Scrappers");
    this.Text("Cyberbane-TitleNaming-Aldecaldos", "Aldecaldos");
    this.Text("Cyberbane-TitleNaming-Wraiths", "Wraiths");
    this.Text("Cyberbane-TitleNaming-NCPD", "NCPD");
    // {0} s
    this.Text("Cyberbane-TitleNaming-S", "{0}'s");
    // {0} token
    this.Text("Cyberbane-TitleNaming-ButcherOf", "Butcher of {0}");
    // {0} token
    this.Text("Cyberbane-TitleNaming-GhostOf", "Ghost of {0}");
    // {0} CBCapFirst(CBPossessive(token))
    this.Text("Cyberbane-TitleNaming-Problem", "{0} Problem");
    // {0} token
    this.Text("Cyberbane-TitleNaming-TheMercFrom", "The Merc from {0}");
    // {0} CBCapFirst(CBPossessive(token))
    this.Text("Cyberbane-TitleNaming-Nightmare", "{0} Nightmare");
    // {0} token
    this.Text("Cyberbane-TitleNaming-FriendOf", "Friend of {0}");
  }

  // ---- GangVoice -------------------------------------------------------------------------------------------
  protected func DefineGangVoice() -> Void {
    this.Text("Cyberbane-GangVoice-ThisIsValentinoBloodSStreet", "This is Valentino blood's street. Walk away, and we let you keep your face.");
    this.Text("Cyberbane-GangVoice-PorLaFamiliaIMGiving", "Por la familia, I'm giving you one chance. Turn around.");
    this.Text("Cyberbane-GangVoice-YouDisrespectThisBarrioYouDisrespect", "You disrespect this barrio, you disrespect all of us. Go.");
    this.Text("Cyberbane-GangVoice-ThisStreetPaysTheClawsYou", "This street pays the Claws. You don't. Leave.");
    this.Text("Cyberbane-GangVoice-BadForBusinessYouBeingHere", "Bad for business, you being here. Worse for you.");
    this.Text("Cyberbane-GangVoice-WalkAwayNowAndNobodyLoses", "Walk away now and nobody loses face. Stay and you lose more.");
    this.Text("Cyberbane-GangVoice-NiceChromeBeAShameIf", "Nice chrome. Be a shame if we peeled it off you.");
    this.Text("Cyberbane-GangVoice-MeatLikeYouDoesnTWalk", "Meat like you doesn't walk Maelstrom streets. Run.");
    this.Text("Cyberbane-GangVoice-KeepWalkingOrLeaveYourImplants", "Keep walking, or leave your implants on the way out.");
    this.Text("Cyberbane-GangVoice-ThisIsA6thStreetNeighbourhood", "This is a 6th Street neighbourhood. We keep it safe. Move along.");
    this.Text("Cyberbane-GangVoice-WeVeDoneToursThatD", "We've done tours that'd break you. Don't make this one.");
    this.Text("Cyberbane-GangVoice-PatrolSWatchingYouMercKeep", "Patrol's watching you, merc. Keep it peaceful or keep walking.");
    this.Text("Cyberbane-GangVoice-YouLookingForABeatingKeep", "You looking for a beating? Keep walking this way.");
    this.Text("Cyberbane-GangVoice-SmallThingLikeYouOnAnimal", "Small thing like you on Animal ground. Cute. Go.");
    this.Text("Cyberbane-GangVoice-PutTheGunDownAndI", "Put the gun down and I'll show you what strong is. Or leave.");
    this.Text("Cyberbane-GangVoice-WeAlreadyKnowEverythingAboutYou", "We already know everything about you. Leave before we use it.");
    this.Text("Cyberbane-GangVoice-YourICEIsPaperMercDon", "Your ICE is paper, merc. Don't make us prove it.");
    this.Text("Cyberbane-GangVoice-LoaAreWatchingYouSoAre", "Loa are watching you. So are we. Walk.");
    this.Text("Cyberbane-GangVoice-NobodyHurtsAnyoneOnOurStreet", "Nobody hurts anyone on our street. That includes you. Go.");
    this.Text("Cyberbane-GangVoice-WeLookAfterOurOwnHere", "We look after our own here. You're not ours.");
    this.Text("Cyberbane-GangVoice-LeaveTheGirlsAloneAndWalk", "Leave the girls alone and walk on. Last time I say it.");
    this.Text("Cyberbane-GangVoice-NicePartsWalkAwayBeforeWe", "Nice parts. Walk away before we take them.");
    this.Text("Cyberbane-GangVoice-KeepMovingUnlessYouWannaEnd", "Keep moving, unless you wanna end up in a bathtub.");
    this.Text("Cyberbane-GangVoice-EverythingOnYouHasAPrice", "Everything on you has a price. Don't make us collect.");
    this.Text("Cyberbane-GangVoice-ThisIsWraithRoadTurnYour", "This is Wraith road. Turn your car around.");
    this.Text("Cyberbane-GangVoice-OutHereNobodyHearsYouScream", "Out here nobody hears you scream. Leave.");
    this.Text("Cyberbane-GangVoice-TheDesertTakesEveryoneDonT", "The desert takes everyone. Don't hurry it.");
    this.Text("Cyberbane-GangVoice-YouReNearTheFamilyS", "You're near the family's camp. Show some respect and move on.");
    this.Text("Cyberbane-GangVoice-WeDonTWantTroubleDon", "We don't want trouble. Don't bring any.");
    this.Text("Cyberbane-GangVoice-FamilyLooksAfterFamilyYouRe", "Family looks after family. You're not family. Keep going.");
    this.Text("Cyberbane-GangVoice-RestrictedZoneLeaveTheArea", "Restricted zone. Leave the area.");
    this.Text("Cyberbane-GangVoice-ThisIsYourOnlyWarningCivilian", "This is your only warning, civilian. Turn back.");
    this.Text("Cyberbane-GangVoice-YouAreBeingTrackedComplyAnd", "You are being tracked. Comply and withdraw.");
    this.Text("Cyberbane-GangVoice-ThisPileSSpokenForFind", "This pile's spoken for. Find your own.");
    this.Text("Cyberbane-GangVoice-WalkOnChoomNothingHereWorth", "Walk on, choom. Nothing here worth bleeding for.");
    this.Text("Cyberbane-GangVoice-WePullWhatWePullDon", "We pull what we pull. Don't make us pull you apart.");
    this.Text("Cyberbane-GangVoice-NightCity", "Night City");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YouHurtTheFamilyNowThe", "You hurt the family. Now the family comes for you in {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-WeKnowYouReInPray", "We know you're in {0}. Pray to whoever you pray to. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-HonourSaysWeTellYouFirst", "Honour says we tell you first: we're coming, {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YouCostUsFaceThatS", "You cost us face. That's a debt. We're collecting in {0}. {1}");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-BusinessIsBusinessYouReBad", "Business is business. You're bad for ours. {0} {1}.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-WeFoundYouInTryNot", "We found you in {0}. {1} Try not to embarrass yourself.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-WeWantThoseImplantsChoomComing", "We want those implants, choom. Coming to {0} to get them. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-HeardYouReInHopeYour", "Heard you're in {0}. Hope your chrome's worth it. {1}");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-YourArmsDLookBetterOn", "Your arms'd look better on one of us. {0} See you in {1}.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-SquadSRollingOutToYou", "Squad's rolling out to {0}. You don't get to hurt our people and walk. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-TargetConfirmedIn", "Target confirmed in {0}. {1}");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-WeProtectThisCityFromPeople", "We protect this city from people like you. {0} {1}.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YouThinkYouReStrongWe", "You think you're strong? We're coming to {0} to find out. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-JuicedUpAndHeadedYourWay", "Juiced up and headed your way in {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-GonnaBreakYouInHalfMerc", "Gonna break you in half, merc. {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-WeTracedYouToBeforeYou", "We traced you to {0} before you knew we were looking. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YourLocationIsYourTimeIs", "Your location is {0}. Your time is short. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-TheNetToldUsWhereYou", "The Net told us where you are: {0}. {1}");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-YouHurtOneOfOursWe", "You hurt one of ours. We don't let that go. {0} {1}.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-ComingToThisIsForHer", "Coming to {0}. This is for her. {1}");
    // {0} coming
    this.Text("Cyberbane-GangVoice-WeProtectOurOwnAndYou", "We protect our own, and you made it personal. {0}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-FreshPartsWalkingRoundWeRe", "Fresh parts walking round {0}. We're coming shopping. {1}");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-PriceOnYourOrgansJustWent", "Price on your organs just went up. {0} {1}.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-FoundYouInHoldStill", "Found you in {0}. Hold still. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YouReOnOurRoadNow", "You're on our road now, {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-EnginesAreRunning", "Engines are running. {0}. {1}");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-OutHereNobodyComesToHelp", "Out here nobody comes to help. {0} {1}.");
    // {0} coming, {1} place
    this.Text("Cyberbane-GangVoice-YouHurtFamilyTheClanDoesn", "You hurt family. The clan doesn't forget. {0} {1}.");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-WeDRatherNotDoThis", "We'd rather not do this. You gave us no choice. {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-FamilySComingForYouIn", "Family's coming for you in {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-HostileLocatedInUnitDeployed", "Hostile located in {0}. Unit deployed. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-EngagingTargetIn", "Engaging target in {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YouWereWarnedStrikeTeamInbound", "You were warned. Strike team inbound to {0}. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-EverythingYouVeGotIsSalvage", "Everything you've got is salvage now. Coming to {0} to strip it. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-WeKnowEveryHoleInYou", "We know every hole in {0}. You don't. {1}");
    // {0} place, {1} coming
    this.Text("Cyberbane-GangVoice-YouTookFromUsWeRe", "You took from us. We're coming to take it back, {0}. {1}");
    this.Text("Cyberbane-GangVoice-NoTengoNadaParaTiWalk", "No tengo nada para ti. Walk.");
    this.Text("Cyberbane-GangVoice-YouDonTTalkToFamily", "You don't talk to family like you've earned it.");
    this.Text("Cyberbane-GangVoice-NotOneWordPendejo", "Not one word, pendejo.");
    this.Text("Cyberbane-GangVoice-YouCanTAffordMyTime", "You can't afford my time.");
    this.Text("Cyberbane-GangVoice-TalkCostsYouReBrokeTo", "Talk costs. You're broke to me.");
    this.Text("Cyberbane-GangVoice-MakeAnAppointmentNever", "Make an appointment. Never.");
    this.Text("Cyberbane-GangVoice-TalkSForMeatMove", "Talk's for meat. Move.");
    this.Text("Cyberbane-GangVoice-IDonTTalkToYou", "I don't talk to you. I take from you.");
    this.Text("Cyberbane-GangVoice-YourVoiceIsUglyShutIt", "Your voice is ugly. Shut it.");
    this.Text("Cyberbane-GangVoice-MoveAlongMerc", "Move along, merc.");
    this.Text("Cyberbane-GangVoice-NothingToDiscussKeepWalking", "Nothing to discuss. Keep walking.");
    this.Text("Cyberbane-GangVoice-YouReNotClearedToTalk", "You're not cleared to talk to me.");
    this.Text("Cyberbane-GangVoice-WordsAreForTheWeak", "Words are for the weak.");
    this.Text("Cyberbane-GangVoice-TalkToMyFists", "Talk to my fists.");
    this.Text("Cyberbane-GangVoice-NotInterestedWalk", "Not interested. Walk.");
    this.Text("Cyberbane-GangVoice-WeHaveNothingToSayTo", "We have nothing to say to you.");
    this.Text("Cyberbane-GangVoice-YouReNotWorthTheBandwidth", "You're not worth the bandwidth.");
    this.Text("Cyberbane-GangVoice-GoTheNetSWatchingYou", "Go. The Net's watching you.");
    this.Text("Cyberbane-GangVoice-NotTalkingToYouSweetie", "Not talking to you, sweetie.");
    this.Text("Cyberbane-GangVoice-YouLostTheRightToTalk", "You lost the right to talk to us.");
    this.Text("Cyberbane-GangVoice-KeepWalking", "Keep walking.");
    this.Text("Cyberbane-GangVoice-WhatYouWantADiscountOn", "What, you want a discount on your kidneys?");
    this.Text("Cyberbane-GangVoice-TalkSCheapYouReNot", "Talk's cheap. You're not.");
    this.Text("Cyberbane-GangVoice-BeatIt", "Beat it.");
    this.Text("Cyberbane-GangVoice-RoadSThisWayTakeIt", "Road's this way. Take it.");
    this.Text("Cyberbane-GangVoice-NothingToSayToYou", "Nothing to say to you.");
    this.Text("Cyberbane-GangVoice-GetLostDesertSBigEnough", "Get lost, desert's big enough.");
    this.Text("Cyberbane-GangVoice-NotNowNotToYou", "Not now. Not to you.");
    this.Text("Cyberbane-GangVoice-YouKnowWhatYouDid", "You know what you did.");
    this.Text("Cyberbane-GangVoice-FamilyDoesnTTalkToYou", "Family doesn't talk to you anymore.");
    this.Text("Cyberbane-GangVoice-MoveAlongCivilian", "Move along, civilian.");
    this.Text("Cyberbane-GangVoice-NoComment", "No comment.");
    this.Text("Cyberbane-GangVoice-ThisConversationIsOverBeforeIt", "This conversation is over before it started.");
    this.Text("Cyberbane-GangVoice-BusyThisWonTStripItself", "Busy. This won't strip itself.");
    this.Text("Cyberbane-GangVoice-GotNothingToSellYou", "Got nothing to sell you.");
    this.Text("Cyberbane-GangVoice-TalkToSomebodyWhoCares", "Talk to somebody who cares.");
    this.Text("Cyberbane-GangVoice-OurHermanoStoppedAnsweringWeLl", "Our hermano stopped answering. We'll find you another way.");
    this.Text("Cyberbane-GangVoice-YouTookOurEyesTheFamily", "You took our eyes. The family still sees.");
    this.Text("Cyberbane-GangVoice-OurManWentQuietCostlyFor", "Our man went quiet. Costly for you, later.");
    this.Text("Cyberbane-GangVoice-LostAScoutWeHaveMore", "Lost a scout. We have more money than you have luck.");
    this.Text("Cyberbane-GangVoice-SpotterSOfflineWeLlTrack", "Spotter's offline. We'll track you by your chrome.");
    this.Text("Cyberbane-GangVoice-KilledOurEyesWeLlGrow", "Killed our eyes? We'll grow new ones.");
    this.Text("Cyberbane-GangVoice-LostContactWithOurReconWe", "Lost contact with our recon. We'll regroup.");
    this.Text("Cyberbane-GangVoice-ScoutSDownDoesnTMatter", "Scout's down. Doesn't matter. We'll find you.");
    this.Text("Cyberbane-GangVoice-OurGuySNotAnsweringLucky", "Our guy's not answering. Lucky you. For now.");
    this.Text("Cyberbane-GangVoice-YouGotOurBoyNextOne", "You got our boy. Next one's bigger.");
    this.Text("Cyberbane-GangVoice-YouCutOneThreadTheWeb", "You cut one thread. The web is still here.");
    this.Text("Cyberbane-GangVoice-OurEyesWentDarkTheNet", "Our eyes went dark. The Net didn't.");
    this.Text("Cyberbane-GangVoice-SheStoppedAnsweringYouDBetter", "She stopped answering. You'd better pray she's alright.");
    this.Text("Cyberbane-GangVoice-LostOurLookoutWeLlBe", "Lost our lookout. We'll be back.");
    this.Text("Cyberbane-GangVoice-LostOurGuyWhateverThereS", "Lost our guy. Whatever, there's always another.");
    this.Text("Cyberbane-GangVoice-HeSNotAnsweringMoreParts", "He's not answering. More parts for us, then.");
    this.Text("Cyberbane-GangVoice-RiderSGoneQuietTheRoad", "Rider's gone quiet. The road remembers you.");
    this.Text("Cyberbane-GangVoice-LostOurSpotterDesertSStill", "Lost our spotter. Desert's still ours.");
    this.Text("Cyberbane-GangVoice-OurCousinSNotAnsweringIf", "Our cousin's not answering. If he's hurt, you'll answer for it.");
    this.Text("Cyberbane-GangVoice-LostOurScoutWeLlFind", "Lost our scout. We'll find you.");
    this.Text("Cyberbane-GangVoice-ReconUnitLostAdjusting", "Recon unit lost. Adjusting.");
    this.Text("Cyberbane-GangVoice-ForwardObserverDownMissionContinues", "Forward observer down. Mission continues.");
    this.Text("Cyberbane-GangVoice-OurLookoutWentQuietWeLl", "Our lookout went quiet. We'll dig you up some other way.");
    this.Text("Cyberbane-GangVoice-LostOurEyesInTheRuins", "Lost our eyes in the ruins. Plenty more where he came from.");
    this.Text("Cyberbane-GangVoice-OkayOkayIYieldOnMy", "Okay! Okay. I yield, on my mother.");
    this.Text("Cyberbane-GangVoice-BastaItSOverIM", "Basta! It's over, I'm done!");
    this.Text("Cyberbane-GangVoice-PorFavorIGiveUp", "Por favor! I give up!");
    this.Text("Cyberbane-GangVoice-EnoughILlPayYouJust", "Enough! I'll pay you, just stop!");
    this.Text("Cyberbane-GangVoice-IYieldBadBusinessThis", "I yield! Bad business, this!");
    this.Text("Cyberbane-GangVoice-StopYouWinYouWin", "Stop! You win, you win!");
    this.Text("Cyberbane-GangVoice-FineFineTakeWhateverIM", "Fine! Fine! Take whatever, I'm out!");
    this.Text("Cyberbane-GangVoice-MyChromeSFriedIM", "My chrome's fried, I'm done!");
    this.Text("Cyberbane-GangVoice-DonTScrapMeIQuit", "Don't scrap me! I quit!");
    this.Text("Cyberbane-GangVoice-IMOutHandsWhereYou", "I'm out! Hands where you can see them!");
    this.Text("Cyberbane-GangVoice-StandDownStandDownIM", "Stand down, stand down! I'm done!");
    this.Text("Cyberbane-GangVoice-SurrenderingDonTShoot", "Surrendering! Don't shoot!");
    this.Text("Cyberbane-GangVoice-OkayYouReStrongerIM", "Okay, you're stronger! I'm done!");
    this.Text("Cyberbane-GangVoice-EnoughYouWinThisOne", "Enough! You win this one!");
    this.Text("Cyberbane-GangVoice-IMDisconnectingIMOut", "I'm disconnecting! I'm out!");
    this.Text("Cyberbane-GangVoice-EnoughYouVeMadeYourPoint", "Enough! You've made your point!");
    this.Text("Cyberbane-GangVoice-StopIYield", "Stop! I yield!");
    this.Text("Cyberbane-GangVoice-OkayOkayIMDonePlease", "Okay! Okay, I'm done, please!");
    this.Text("Cyberbane-GangVoice-IGiveUpDonTHurt", "I give up! Don't hurt me!");
    this.Text("Cyberbane-GangVoice-EnoughIMOutOfThis", "Enough! I'm out of this!");
    this.Text("Cyberbane-GangVoice-DonTShootILlGo", "Don't shoot! I'll go, I'll go!");
    this.Text("Cyberbane-GangVoice-OkayTakeThePartsIM", "Okay! Take the parts, I'm out!");
    this.Text("Cyberbane-GangVoice-PleaseIMDone", "Please! I'm done!");
    this.Text("Cyberbane-GangVoice-AlrightRoadSYoursIM", "Alright! Road's yours! I'm done!");
    this.Text("Cyberbane-GangVoice-EnoughIGive", "Enough! I give!");
    this.Text("Cyberbane-GangVoice-OkayForTheFamilySSake", "Okay! For the family's sake, I'm done!");
    this.Text("Cyberbane-GangVoice-StopIYieldIYield", "Stop! I yield, I yield!");
    this.Text("Cyberbane-GangVoice-TakeItTakeTheHaulI", "Take it! Take the haul, I'm out!");
    this.Text("Cyberbane-GangVoice-OkayNotWorthDyingOverJunk", "Okay! Not worth dying over junk!");
    this.Text("Cyberbane-GangVoice-IMDoneIMWalking", "I'm done! I'm walking!");
    this.Text("Cyberbane-GangVoice-OkayOkayIMDone", "Okay! Okay! I'm done!");
    this.Text("Cyberbane-GangVoice-DonTShootIGiveUp", "Don't shoot! I give up!");
    this.Text("Cyberbane-GangVoice-EnoughItSOverIM", "Enough! It's over, I'm out!");
  }

  // ---- Grapevine -------------------------------------------------------------------------------------------
  protected func DefineGrapevine() -> Void {
    // {0} where
    this.Text("Cyberbane-Grapevine-HeardWhatYouDidToTheir", "Heard what you did to their boss. {0} is talking about it.");
    // {0} where
    this.Text("Cyberbane-Grapevine-BossOfTheirsDownCanT", "Boss of theirs, down. {0} can't shut up about it, and they're using your name.");
    // {0} where
    this.Text("Cyberbane-Grapevine-EveryBarInIsDrinkingTo", "Every bar in {0} is drinking to that boss of theirs tonight. Or to you. Depends on the bar.");
    // {0} where
    this.Text("Cyberbane-Grapevine-WordOutOfIsYouLeft", "Word out of {0} is you left a mess. People are repeating it.");
    // {0} where
    this.Text("Cyberbane-Grapevine-WhatYouLeftInTheAmbulances", "What you left in {0}? The ambulances are still counting.");
    // {0} where
    this.Text("Cyberbane-Grapevine-PeopleInAreDescribingItTo", "People in {0} are describing it to each other in detail. Your name keeps coming up.");
    // {0} where
    this.Text("Cyberbane-Grapevine-YourNameCameUpInToday", "Your name came up in {0} today. Thought you should know.");
    // {0} where
    this.Text("Cyberbane-Grapevine-TheyAreTalkingAboutYouIn", "They are talking about you in {0}. Not quietly.");
    // {0} where
    this.Text("Cyberbane-Grapevine-HeardAboutWordTravelsFasterThan", "Heard about {0}. Word travels faster than you do.");
    // {0} where
    this.Text("Cyberbane-Grapevine-SomebodyInKnowsYourNameNow", "Somebody in {0} knows your name now. Make of that what you will.");
    // {0} where
    this.Text("Cyberbane-Grapevine-YourNameSDoingTheRounds", "Your name's doing the rounds in {0}. Fixers, bartenders, the lot.");
    // {0} where
    this.Text("Cyberbane-Grapevine-BodiesTurningUpInAndNobody", "Bodies turning up in {0} and nobody can say whose work it is.");
    // {0} where
    this.Text("Cyberbane-Grapevine-SomethingIsWorkingNoNameOn", "Something is working {0}. No name on it. People are nervous.");
    // {0} where
    this.Text("Cyberbane-Grapevine-HeardHasAProblemNobodyCan", "Heard {0} has a problem nobody can describe. Know anything?");
    // {0} where
    this.Text("Cyberbane-Grapevine-WhateverHappenedInNoWitnessesWalked", "Whatever happened in {0}, no witnesses walked. Street is spooked.");
    // {0} where
    this.Text("Cyberbane-Grapevine-PeopleInAreLockingTheirDoors", "People in {0} are locking their doors and not saying why.");
    this.Text("Cyberbane-Grapevine-OutThere", "out there");
    this.Text("Cyberbane-Grapevine-AcrossTown", "across town");
    // {0} from
    this.Text("Cyberbane-Grapevine-YouAreALongWayFrom", "You are a long way from {0}. Whatever happened there followed you here anyway.");
    // {0} from
    this.Text("Cyberbane-Grapevine-WordCameInFromBeforeYou", "Word came in from {0} before you did. No name on it. Still made people careful.");
    // {0} from
    this.Text("Cyberbane-Grapevine-SomethingOutOfHasPeopleHere", "Something out of {0} has people here talking. You would not know anything about it.");
    // {0} from
    this.Text("Cyberbane-Grapevine-PeopleHereHeardAboutNobodyCan", "People here heard about {0}. Nobody can say who. Welcome to the neighbourhood.");
    // {0} from
    this.Text("Cyberbane-Grapevine-TheyKnowAboutTheBossYou", "They know about the boss you put down in {0}. That story got here before you.");
    // {0} from
    this.Text("Cyberbane-Grapevine-TheBossInEverybodyHereHas", "The boss in {0}? Everybody here has heard. Not all of them are sorry.");
    // {0} from
    this.Text("Cyberbane-Grapevine-WhatYouLeftInIsBeing", "What you left in {0} is being repeated on this side of town. Word for word.");
    // {0} from
    this.Text("Cyberbane-Grapevine-TheyVeHeardAboutHereSome", "They've heard about {0} here. Some people moved their kids indoors.");
    // {0} from
    this.Text("Cyberbane-Grapevine-YourNameIsAlreadyInCirculation", "Your name is already in circulation here. Came up from {0}.");
    // {0} from
    this.Text("Cyberbane-Grapevine-YouAreKnownOnThisSide", "You are known on this side of town now. Word travelled out of {0}.");
    // {0} from
    this.Text("Cyberbane-Grapevine-HeardAboutBeforeYouEverWalked", "Heard about {0} before you ever walked in here. People notice.");
    // {0} from
    this.Text("Cyberbane-Grapevine-TheyWereTalkingAboutHereBefore", "They were talking about {0} here before you arrived. You should know that.");
  }

  // ---- Telling ---------------------------------------------------------------------------------------------
  protected func DefineTelling() -> Void {
    this.Text("Cyberbane-Telling-TheMercEverybodySTalkingAbout", "the merc everybody's talking about");
    this.Text("Cyberbane-Telling-Merc", "merc");
    this.Text("Cyberbane-Telling-Choom", "choom");
    this.Text("Cyberbane-Telling-AroundHere", "around here");
    this.Text("Cyberbane-Telling-InTheRainInTheMiddle", "in the rain, in the middle of the night");
    this.Text("Cyberbane-Telling-InThePouringRain", "in the pouring rain");
    this.Text("Cyberbane-Telling-InTheMiddleOfTheNight", "in the middle of the night");
    this.Text("Cyberbane-Telling-Somebody", "Somebody");
    // {0} gone, {1} gone
    this.Text("Cyberbane-Telling-TalkToMe", "{0}? {1}, talk to me!");
    this.Text("Cyberbane-Telling-WhereDTheyGoAnybodySee", "Where'd they go?! Anybody see them?");
    // {0} gone
    this.Text("Cyberbane-Telling-SNotAnswering", "{0}'s not answering.");
    // {0} book.darkKills
    this.Text("Cyberbane-Telling-ThatSOfUsWhereARE", "That's {0} of us! Where ARE they?!");
    this.Text("Cyberbane-Telling-ICanTSeeThemI", "I can't see them, I can't see anything!");
    // {0} gone
    this.Text("Cyberbane-Telling-TooWeNeedToGetOut", "{0} too? We need to get out of here.");
    this.Text("Cyberbane-Telling-StayTogetherBacksToTheWall", "Stay together! Backs to the wall!");
    this.Text("Cyberbane-Telling-QuietNightNobodySSaidYour", "Quiet night. Nobody's said your name.");
    // {0} worst
    this.Text("Cyberbane-Telling-Overnight", "Overnight: {0}");
    // {0} night
    this.Text("Cyberbane-Telling-BusyNightThingsTheStreetS", "Busy night: {0} things the street's talking about.");
    this.Text("Cyberbane-Telling-OneOfYourRivalsIsOut", " One of your Rivals is out looking for you.");
    // {0} hunters
    this.Text("Cyberbane-Telling-OfYourRivalsAreOutLooking", " {0} of your Rivals are out looking.");
    // {0} price
    this.Text("Cyberbane-Telling-ThereSStillOnYourHead", " There's still {0} on your head.");
    // {0} CBCapFirst(CBFactionLabel(open))
    this.Text("Cyberbane-Telling-AreStillInOpenSeasonOn", " {0} are still in open season on you.");
    this.Text("Cyberbane-Telling-MorningBrief", "Morning brief");
    // {0} out, {1} after, {2} CBYou(sys, game)
    this.Text("Cyberbane-Telling-StaySharp", "{0}{1} Stay sharp, {2}.");
    this.Text("Cyberbane-Telling-NIGHTCITY", "NIGHT CITY");
    this.Text("Cyberbane-Telling-AGANG", "A GANG");
    // {0} gang, {1} where
    this.Text("Cyberbane-Telling-MERCPUTSNAMEINTHEGROUND", "MERC PUTS {0} NAME IN THE GROUND IN {1}");
    // {0} where
    this.Text("Cyberbane-Telling-NAMEDKILLERDIESIN", "NAMED KILLER DIES IN {0}");
    // {0} gang, {1} where
    this.Text("Cyberbane-Telling-LOSEANAMEIN", "{0} LOSE A NAME IN {1}");
    // {0} gang, {1} where
    this.Text("Cyberbane-Telling-LOSETHEIRBIGFISHIN", "{0} LOSE THEIR BIG FISH IN {1}");
    // {0} where
    this.Text("Cyberbane-Telling-SITDOWNTURNSBLOODBATHIN", "SIT-DOWN TURNS BLOODBATH IN {0}");
    // {0} where, {1} gang
    this.Text("Cyberbane-Telling-CHANGESHANDSMOVEIN", "{0} CHANGES HANDS: {1} MOVE IN");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Telling-PRICEONMERCSHEADEDDIES", "PRICE ON MERC'S HEAD: {0} EDDIES");
    // {0} RoundF(e.value), {1} where
    this.Text("Cyberbane-Telling-RANKBOUNTYHUNTERFOUNDDEADIN", "RANK {0} BOUNTY HUNTER FOUND DEAD IN {1}");
    this.Text("Cyberbane-Telling-NEWNUMBERONEONTHEHUNTERS", "NEW NUMBER ONE ON THE HUNTERS' BOARD");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Telling-MERCCLIMBSTONUMBER", "MERC CLIMBS TO NUMBER {0}");
    // {0} gang
    this.Text("Cyberbane-Telling-OPENSEASONENDSMERCSTILLBREATHING", "{0} OPEN SEASON ENDS: MERC STILL BREATHING");
    // {0} where, {1} gang
    this.Text("Cyberbane-Telling-GANGWARINWALKAWAYWINNERS", "GANG WAR IN {0}: {1} WALK AWAY WINNERS");
    this.Text("Cyberbane-Telling-DEADMANWALKINGKILLERBACKFROM", "DEAD MAN WALKING: KILLER BACK FROM THE GRAVE");
    // {0} gang
    this.Text("Cyberbane-Telling-STARTAKESOUTARIVALS", "{0} STAR TAKES OUT A RIVAL'S NAME");
    // {0} where
    this.Text("Cyberbane-Telling-BLOODBATHIN", "BLOODBATH IN {0}");
    // {0} gang, {1} where
    this.Text("Cyberbane-Telling-BESTWIPEDOUTIN", "{0} BEST WIPED OUT IN {1}");
    // {0} where
    this.Text("Cyberbane-Telling-BELONGSTOONEMERCNOW", "{0} BELONGS TO ONE MERC NOW");
    // {0} you
    this.Text("Cyberbane-Telling-TheyCallYou", "They call you {0}. ");
    this.Text("Cyberbane-Telling-MostOfNightCityHasNever", "Most of Night City has never heard of you, and the ones who have are still deciding what to make of it.");
    // {0} CBTopDistrictWords(sys)
    this.Text("Cyberbane-Telling-YourNameIsKnownInAnd", "Your name is known in {0}, and it was not always.");
    // {0} stats.rivalsSlain
    this.Text("Cyberbane-Telling-YouHavePutOfYourRivals", " You have put {0} of your Rivals in the ground");
    // {0} stats.apexKills
    this.Text("Cyberbane-Telling-AndOfTheGangsBestWith", ", and {0} of the gangs' best with them.");
    // {0} CBCapFirst(CBFactionLabel(nightmare))
    this.Text("Cyberbane-Telling-HateYouMoreThanAnybodyAnd", " {0} hate you more than anybody, and they have reason to.");
    this.Text("Cyberbane-Telling-OnTheHuntersBoardYouAre", " On the hunters' board you are number one, and every solo with a gun knows it.");
    // {0} book.LadderRank()
    this.Text("Cyberbane-Telling-OnTheHuntersBoardYouAre-2", " On the hunters' board you are number {0}.");
    // {0} CBCapFirst(CBFactionLabel(mine))
    this.Text("Cyberbane-Telling-CallYouOneOfTheirOwn", " {0} call you one of their own.");
    this.Text("Cyberbane-Telling-ForAllOfItYouLeave", " For all of it, you leave more people breathing than most would, and the street has noticed.");
    this.Text("Cyberbane-Telling-AFewStreets", "a few streets");
    this.Text("Cyberbane-Telling-YouHaveMetOnceSince", " You have met once since.");
    // {0} r.encounters
    this.Text("Cyberbane-Telling-YouHaveMetTimesSince", " You have met {0} times since.");
    this.Text("Cyberbane-Telling-TheyGotAwayFromYouOnce", " They got away from you once.");
    // {0} r.escapes
    this.Text("Cyberbane-Telling-TheyHaveGotAwayFromYou", " They have got away from you {0} times.");
    this.Text("Cyberbane-Telling-YouLetThemLiveOnce", " You let them live once.");
    // {0} r.sparedByV
    this.Text("Cyberbane-Telling-YouHaveLetThemLiveTimes", " You have let them live {0} times.");
    this.Text("Cyberbane-Telling-TheyHavePutYouDownOnce", " They have put you down once.");
    // {0} r.killedV
    this.Text("Cyberbane-Telling-TheyHavePutYouDownTimes", " They have put you down {0} times.");
    this.Text("Cyberbane-Telling-YouKilledThemOnceTheyCame", " You killed them once. They came back.");
    this.Text("Cyberbane-Telling-YouHumiliatedThemWhereTheyLay", " You humiliated them where they lay, and they have not forgotten.");
    // {0} CBDistrictLabel(s.district)
    this.Text("Cyberbane-Telling-LastSeenIn", " Last seen in {0}.");
    // {0} place
    this.Text("Cyberbane-Telling-YouPutThemDownAndWalked", "You put them down and walked away, back in {0}.");
    this.Text("Cyberbane-Telling-YouPutThemDownAndWalked-2", "You put them down and walked away.");
    // {0} inPlace
    this.Text("Cyberbane-Telling-TheyRanFromYouAndLived", "They ran from you{0} and lived.");
    // {0} inPlace
    this.Text("Cyberbane-Telling-TheyAreTheOneWhoPut", "They are the one who put you down{0}.");
    // {0} inPlace
    this.Text("Cyberbane-Telling-YouKilledSomebodyOfTheirsAnd", "You killed somebody of theirs{0}, and they swore on it.");
    // {0} inPlace
    this.Text("Cyberbane-Telling-TheyRanWithYourCrewAnd", "They ran with your crew, and turned on you{0}. They know where you sleep.");
    // {0} place
    this.Text("Cyberbane-Telling-TheyCameAfterYouForThe", "They came after you for the money, out of {0}.");
    this.Text("Cyberbane-Telling-TheyCameAfterYouForThe-2", "They came after you for the money.");
    this.Text("Cyberbane-Telling-SWORNAGAINSTYOU", "SWORN AGAINST YOU");
    this.Text("Cyberbane-Telling-HOSTILETOYOU", "HOSTILE TO YOU");
    this.Text("Cyberbane-Telling-FRIENDLYTOYOU", "FRIENDLY TO YOU");
    this.Text("Cyberbane-Telling-ALLIEDWITHYOU", "ALLIED WITH YOU");
    this.Text("Cyberbane-Telling-YOURGANG", "YOUR GANG");
  }

  // ---- Whispers --------------------------------------------------------------------------------------------
  protected func DefineWhispers() -> Void {
    this.Text("Cyberbane-Whispers-PasserBy", "Passer-by");
    this.Text("Cyberbane-Whispers-Local", "Local");
    this.Text("Cyberbane-Whispers-SomeoneNearby", "Someone nearby");
    this.Text("Cyberbane-Whispers-Ganger", "Ganger");
    this.Text("Cyberbane-Whispers-Lookout", "Lookout");
    this.Text("Cyberbane-Whispers-CrewMember", "Crew member");
    this.Text("Cyberbane-Whispers-NCPDOfficer", "NCPD Officer");
    this.Text("Cyberbane-Whispers-PatrolCop", "Patrol Cop");
    this.Text("Cyberbane-Whispers-Maelstromer", "Maelstromer");
    this.Text("Cyberbane-Whispers-TygerClaw", "Tyger Claw");
    this.Text("Cyberbane-Whispers-Valentino", "Valentino");
    this.Text("Cyberbane-Whispers-Animal", "Animal");
    this.Text("Cyberbane-Whispers-VoodooBoy", "Voodoo Boy");
    this.Text("Cyberbane-Whispers-Scav", "Scav");
    this.Text("Cyberbane-Whispers-Scrapper", "Scrapper");
    this.Text("Cyberbane-Whispers-Aldecaldo", "Aldecaldo");
    this.Text("Cyberbane-Whispers-Wraith", "Wraith");
    this.Text("Cyberbane-Whispers-ArasakaSecurity", "Arasaka Security");
    // {0} where
    this.Text("Cyberbane-Whispers-In", "in {0}");
    // {0} where
    this.Text("Cyberbane-Whispers-HeardTheyFoundARoomFull", "Heard they found a room full of bodies {0}.");
    // {0} where
    this.Text("Cyberbane-Whispers-WholeCrewWentQuietNobodyS", "Whole crew went quiet {0}. Nobody's saying who.");
    // {0} where
    this.Text("Cyberbane-Whispers-WordIsSomebodyClearedABuilding", "Word {0} is somebody cleared a building on their own.");
    // {0} where
    this.Text("Cyberbane-Whispers-TraumaTeamWouldnTEvenGo", "Trauma Team wouldn't even go in {0}. Nothing left to save.");
    // {0} where
    this.Text("Cyberbane-Whispers-ScrollersAreSayingLookedLikeA", "Scrollers are saying {0} looked like a war zone. One shooter.");
    // {0} gang, {1} where
    this.Text("Cyberbane-Whispers-TheyPutABossOfIn", "They put a boss of {0} in the ground {1}.");
    // {0} CBCapFirst(gang), {1} where
    this.Text("Cyberbane-Whispers-LostSomeoneWhoMattered", "{0} lost someone who mattered {1}.");
    // {0} gang, {1} where
    this.Text("Cyberbane-Whispers-HeardAreShortABoss", "Heard {0} are short a boss {1}.");
    // {0} where
    this.Text("Cyberbane-Whispers-SomebodyTookABossOffThe", "Somebody took a boss off the board {0}.");
    // {0} where
    this.Text("Cyberbane-Whispers-SomethingWentDownStreetSStill", "Something went down {0}. Street's still chewing on it.");
    // {0} where
    this.Text("Cyberbane-Whispers-YouHearAboutThatJob", "You hear about that job {0}?");
    // {0} where
    this.Text("Cyberbane-Whispers-EveryoneSTalkingAboutWhatHappened", "Everyone's talking about what happened {0}.");
    // {0} where
    this.Text("Cyberbane-Whispers-FixersAreCallingItTheJob", "Fixers {0} are calling it the job of the year.");
    // {0} CBCapFirst(gang), {1} where
    this.Text("Cyberbane-Whispers-AreCountingBodies", "{0} are counting bodies {1}.");
    // {0} gang, {1} where
    this.Text("Cyberbane-Whispers-AnotherOneOfDown", "Another one of {0} down {1}.");
    // {0} gang
    this.Text("Cyberbane-Whispers-NotAGoodWeekToBe", "Not a good week to be {0}.");
    // {0} CBCapFirst(gang), {1} where
    this.Text("Cyberbane-Whispers-ArePullingTheirPeopleOffThe", "{0} are pulling their people off the corners {1}. Scared, if you ask me.");
    // {0} where
    this.Text("Cyberbane-Whispers-WordIsSomebodySBeenBusy", "Word is somebody's been busy {0}.");
    this.Text("Cyberbane-Whispers-ThatCrew", "that crew");
    // {0} st.leader
    this.Text("Cyberbane-Whispers-YouPutDownOneOfOur", "You put down one of our bosses. {0} runs things now, and remembers.");
    // {0} st.leader
    this.Text("Cyberbane-Whispers-WeKnowWhatYouDidTo", "We know what you did to ours. {0} has your name on a list.");
    // {0} gang
    this.Text("Cyberbane-Whispers-ThatWasABossOfYou", "That was a boss of {0} you killed. Someone's getting paid for you.");
    this.Text("Cyberbane-Whispers-EveryOneOfUsKnowsYour", "Every one of us knows your face now. Think about that.");
    this.Text("Cyberbane-Whispers-YouPutDownOneOfOur-2", "You put down one of our bosses. The crew doesn't forget that.");
    this.Text("Cyberbane-Whispers-WeKnowWhatYouDidTo-2", "We know what you did to ours. We're not done.");
    this.Text("Cyberbane-Whispers-ThatSTheMercWhoWent", "That's the merc who went up against MaxTac and walked away.");
    this.Text("Cyberbane-Whispers-MaxTacCameForThatOneMaxTac", "MaxTac came for that one. MaxTac went home light.");
    this.Text("Cyberbane-Whispers-IVeSeenTheFootageThey", "I've seen the footage. They took on MaxTac and they're still breathing.");
    this.Text("Cyberbane-Whispers-YouDonTSurviveMaxTacThat", "You don't survive MaxTac. That one did.");
    this.Text("Cyberbane-Whispers-YouVePutEnoughOfUs", "You've put enough of us in the ground. Walk away, or you're next.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Whispers-RememberEveryOneTurnAround", "{0} remember every one. Turn around.");
    this.Text("Cyberbane-Whispers-LastWarningAfterThisItS", "Last warning. After this it's not talking.");
    this.Text("Cyberbane-Whispers-YouVeGotALotOf", "You've got a lot of nerve showing up here. Walk away while you still can.");
    this.Text("Cyberbane-Whispers-WrongStreetChoomTurnAround", "Wrong street, choom. Turn around.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Whispers-WantYouGoneThisIsThe", "{0} want you gone. This is the only time we ask nicely.");
    this.Text("Cyberbane-Whispers-YouReStandingOnOurBlock", "You're standing on our block. That's one mistake. Don't make two.");
    this.Text("Cyberbane-Whispers-TheseAreTheirStreetsNowNobody", "These are their streets now. Nobody argues.");
    this.Text("Cyberbane-Whispers-GangsPayToWalkThroughHere", "Gangs pay to walk through here now. Pay them, I mean.");
    this.Text("Cyberbane-Whispers-ThatSWhoRunsThisPlace", "That's who runs this place. Not the Claws, not anybody. Them.");
    this.Text("Cyberbane-Whispers-BusyNightForThatOneBetter", "Busy night for that one. Better them than us.");
    this.Text("Cyberbane-Whispers-StillGotTheFightOnThem", "Still got the fight on them. Give them room.");
    this.Text("Cyberbane-Whispers-WhateverJustHappenedIMGlad", "Whatever just happened, I'm glad it wasn't me.");
    this.Text("Cyberbane-Whispers-BloodSStillFreshOnThat", "Blood's still fresh on that one. Don't look.");
    this.Text("Cyberbane-Whispers-TheyJustDidSomethingYouCan", "They just did something. You can see it on them.");
    this.Text("Cyberbane-Whispers-WalkDonTRunJustWalk", "Walk. Don't run, just walk.");
    this.Text("Cyberbane-Whispers-SomebodySNotGoingHomeTonight", "Somebody's not going home tonight, and that's who did it.");
    this.Text("Cyberbane-Whispers-NCPDSAllOverTheNet", "NCPD's all over the net looking for that one.");
    this.Text("Cyberbane-Whispers-CopsWantThatFaceIM", "Cops want that face. I'm not standing next to it.");
    this.Text("Cyberbane-Whispers-EveryPatrolInTheDistrictS", "Every patrol in the district's got that one's description.");
    this.Text("Cyberbane-Whispers-HavenTHeardThatOneS", "Haven't heard that one's name in days. Gone quiet.");
    this.Text("Cyberbane-Whispers-ThoughtTheyDSkippedTownGuess", "Thought they'd skipped town. Guess not.");
    this.Text("Cyberbane-Whispers-QuietLatelyThatSWhenYou", "Quiet lately. That's when you worry.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-ThatSForReal", "That's {0}. For real.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-TheyCallThatOneEarnedIt", "They call that one {0}. Earned it, too.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-RightThereDonTMakeA", "{0}, right there. Don't make a thing of it.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-BigNameBleedsLikeAnybody", "{0}. Big name. Bleeds like anybody.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-TheyCallThatOneWeCall", "They call that one {0}. We call them a target.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-ThatSEyesDown", "That's {0}. Eyes down.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-DonTThatS", "Don't. That's {0}.");
    // {0} st.title
    this.Text("Cyberbane-Whispers-YouKnowWhoThatIsKeep", "You know who that is? {0}. Keep walking.");
    this.Text("Cyberbane-Whispers-HeardWhatThatOneLeavesBehind", "Heard what that one leaves behind. They hose the place down after.");
    this.Text("Cyberbane-Whispers-ThatSTheOneWhoDoesn", "That's the one who doesn't stop when it's over.");
    this.Text("Cyberbane-Whispers-DonTEndUpInA", "Don't end up in a room with that one. Nobody comes out in one piece.");
    this.Text("Cyberbane-Whispers-BodiesTurnUpAndNobodySaw", "Bodies turn up and nobody saw a thing. That's them.");
    this.Text("Cyberbane-Whispers-YouDonTSeeThatOne", "You don't see that one coming. That's the whole point.");
    this.Text("Cyberbane-Whispers-HalfTheJobsOnTheNet", "Half the jobs on the net they never got pinned for.");
    this.Text("Cyberbane-Whispers-ThatOneDoesCleanWorkIn", "That one does clean work. In, out, nobody hurt who didn't have to be.");
    this.Text("Cyberbane-Whispers-FixersLoveThatOneJobDone", "Fixers love that one. Job done, no mess.");
    this.Text("Cyberbane-Whispers-ARealProRareTheseDays", "A real pro. Rare these days.");
    this.Text("Cyberbane-Whispers-MoreChromeThanMeatOnThat", "More chrome than meat on that one.");
    this.Text("Cyberbane-Whispers-HowMuchOfThemIsEven", "How much of them is even left under all that?");
    this.Text("Cyberbane-Whispers-RipperdocsMustLoveThatOne", "Ripperdocs must love that one.");
    this.Text("Cyberbane-Whispers-NetrunnerFriesYouFromAcrossThe", "Netrunner. Fries you from across the street. Keep your ICE up.");
    this.Text("Cyberbane-Whispers-ThatOneCooksBrainsForA", "That one cooks brains for a living.");
    this.Text("Cyberbane-Whispers-DonTJackInNearThat", "Don't jack in near that one. Seriously.");
    this.Text("Cyberbane-Whispers-SawThatOnePutAGuy", "Saw that one put a guy down with bare hands. One punch.");
    this.Text("Cyberbane-Whispers-DoesnTEvenNeedAGun", "Doesn't even need a gun. That's the scary part.");
    this.Text("Cyberbane-Whispers-FistsLikeThatWhoNeedsA", "Fists like that, who needs a piece?");
    this.Text("Cyberbane-Whispers-WaitIsThatReallyThemOn", "Wait. Is that really them? On our street?");
    this.Text("Cyberbane-Whispers-EverybodyInTheCityKnowsThat", "Everybody in the city knows that face.");
    this.Text("Cyberbane-Whispers-IMTellingEveryoneISaw", "I'm telling everyone I saw them. Nobody's going to believe me.");
    this.Text("Cyberbane-Whispers-NobodyKnowsWhoThatIsThat", "Nobody knows who that is. That's worse.");
    this.Text("Cyberbane-Whispers-NoNameNoFaceOnThe", "No name, no face on the net, and people are scared anyway.");
    this.Text("Cyberbane-Whispers-ThatOneSABadDay", "That one's a bad day away from cyberpsycho.");
    this.Text("Cyberbane-Whispers-HeardTheyShootWhoeverSIn", "Heard they shoot whoever's in the way. Civvies too.");
    this.Text("Cyberbane-Whispers-SomebodyShouldCallMaxTacBeforeIt", "Somebody should call MaxTac before it's too late.");
    this.Text("Cyberbane-Whispers-LookAtTheEyesNobodyS", "Look at the eyes. Nobody's home.");
    this.Text("Cyberbane-Whispers-LeavesPeopleBreathingThinksThatMakes", "Leaves people breathing. Thinks that makes them a saint.");
    this.Text("Cyberbane-Whispers-SoftPutsPeopleToSleepInstead", "Soft. Puts people to sleep instead of finishing it.");
    this.Text("Cyberbane-Whispers-ThatOneLeavesPeopleBreathingWeird", "That one leaves people breathing. Weird, for a merc.");
    this.Text("Cyberbane-Whispers-GotACodeThatOneDoesn", "Got a code, that one. Doesn't kill who doesn't need killing.");
    this.Text("Cyberbane-Whispers-PutMyCousinDownOnceAnd", "Put my cousin down once and he woke up. Not a scratch on him.");
    this.Text("Cyberbane-Whispers-HardButFairNotManyLike", "Hard, but fair. Not many like that left.");
    this.Text("Cyberbane-Whispers-LookAtThoseArmsMilitaryGrade", "Look at those arms. Military grade, easy.");
    this.Text("Cyberbane-Whispers-AllThatChromeOutInThe", "All that chrome out in the open. Nobody's going to try them.");
    this.Text("Cyberbane-Whispers-DonTStareAtTheChrome", "Don't stare at the chrome. They notice.");
    this.Text("Cyberbane-Whispers-ThatSNotABodyThat", "That's not a body. That's a weapon with legs.");
    this.Text("Cyberbane-Whispers-SomethingHeavyUnderThatJacketMoves", "Something heavy under that jacket. Moves wrong for flesh.");
    this.Text("Cyberbane-Whispers-DressesPlainDoesnTFoolAnyone", "Dresses plain. Doesn't fool anyone who's looking.");
    // {0} st.districtLabel
    this.Text("Cyberbane-Whispers-EverybodyInKnowsThatFace", "Everybody in {0} knows that face.");
    // {0} st.districtLabel
    this.Text("Cyberbane-Whispers-ThatOnePracticallyRunsNow", "That one practically runs {0} now.");
    // {0} st.districtLabel
    this.Text("Cyberbane-Whispers-AskAnyoneInTheyLlTell", "Ask anyone in {0}. They'll tell you about that one.");
    // {0} st.districtLabel
    this.Text("Cyberbane-Whispers-NotFromHeardTheNameThough", "Not from {0}. Heard the name, though.");
    // {0} st.districtLabel
    this.Text("Cyberbane-Whispers-WhatSThatOneDoingIn", "What's that one doing in {0}?");
    // {0} CBCapFirst(holder)
    this.Text("Cyberbane-Whispers-HalfTheCornersRanAreEmpty", "Half the corners {0} ran are empty now. Guess why.");
    // {0} CBCapFirst(holder)
    this.Text("Cyberbane-Whispers-DonTScareAnybodyRoundHere", "{0} don't scare anybody round here any more. That one saw to it.");
    // {0} st.hunter
    this.Text("Cyberbane-Whispers-SComingForYouEverybodyOn", "{0}'s coming for you. Everybody on the block knows it.");
    // {0} st.hunter
    this.Text("Cyberbane-Whispers-EnjoyTheWalkHasPlansFor", "Enjoy the walk. {0} has plans for you.");
    // {0} st.hunter
    this.Text("Cyberbane-Whispers-WhenFindsYouIWantA", "When {0} finds you, I want a good seat.");
    // {0} gang
    this.Text("Cyberbane-Whispers-ThatSAFriendOfYou", "That's a friend of {0}. You hear me? A friend.");
    this.Text("Cyberbane-Whispers-TreatThatOneLikeFamilyBoss", "Treat that one like family. Boss's orders.");
    this.Text("Cyberbane-Whispers-OneOfOursNearEnoughAnybody", "One of ours, near enough. Anybody starts something, we finish it.");
    // {0} gang
    this.Text("Cyberbane-Whispers-ThatOneSAllRightBy", "That one's all right by {0}.");
    this.Text("Cyberbane-Whispers-GoodWithTheCrewThatOne", "Good with the crew, that one. Leave it.");
    this.Text("Cyberbane-Whispers-HeardTheyVeBeenDoingUs", "Heard they've been doing us favours. Nod, don't stare.");
    // {0} gang
    this.Text("Cyberbane-Whispers-ThatOneSPutMoreOf", "That one's put more of {0} in the ground than the cops ever did.");
    this.Text("Cyberbane-Whispers-EveryFuneralThisMonthThatOne", "Every funeral this month, that one's the reason.");
    this.Text("Cyberbane-Whispers-YouKnowHowManyOfOurs", "You know how many of ours? Too many.");
    this.Text("Cyberbane-Whispers-WeKnowYourFaceAllOf", "We know your face. All of us.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Whispers-KeepWalkingYouReOnStreets", "Keep walking. You're on {0} streets.");
    // {0} st.leader
    this.Text("Cyberbane-Whispers-RunsThisCrewNowWantsA", "{0} runs this crew now. Wants a word with you.");
    // {0} st.leader
    this.Text("Cyberbane-Whispers-WhenHearsYouCameByIt", "When {0} hears you came by, it's on.");
    this.Text("Cyberbane-Whispers-DonTLookAtThemJust", "Don't look at them. Just don't.");
    this.Text("Cyberbane-Whispers-NobodyStartsAnythingNotWithThat", "Nobody starts anything. Not with that one.");
    this.Text("Cyberbane-Whispers-IfTheyWantTheCornerThey", "If they want the corner, they can have it.");
    this.Text("Cyberbane-Whispers-ThatOneLetSomeOfOurs", "That one let some of ours walk. People remember that.");
    this.Text("Cyberbane-Whispers-CouldVeFinishedMyBrotherDidn", "Could've finished my brother. Didn't. I don't forget.");
    this.Text("Cyberbane-Whispers-BossPaysThatOneToStay", "Boss pays that one to stay off our backs. Don't make it worse.");
    this.Text("Cyberbane-Whispers-WeSendThemEddiesSoThey", "We send them eddies so they leave us alone. Think about that.");
    this.Text("Cyberbane-Whispers-DonTWeReDoneAlright", "Don't. We're done, alright? We're done.");
    this.Text("Cyberbane-Whispers-ThereSHardlyAnyOfUs", "There's hardly any of us left. Just let us be.");
    this.Text("Cyberbane-Whispers-WhateverTheBossesSaidIM", "Whatever the bosses said, I'm not dying for it.");
    // {0} gang
    this.Text("Cyberbane-Whispers-ThatSTheOneWhoBroke", "That's the one who broke {0}. Nobody move.");
    this.Text("Cyberbane-Whispers-WhoSUnderTheMaskNever", "Who's under the mask? Never mind. I don't want to know.");
    this.Text("Cyberbane-Whispers-CanTSeeAFaceDon", "Can't see a face. Don't need to.");
    this.Text("Cyberbane-Whispers-MaskedUpAfterDarkThatS", "Masked up after dark. That's never good.");
    this.Text("Cyberbane-Whispers-MaskedUpInTheMiddleOf", "Masked up in the middle of the day. That's never good.");
    this.Text("Cyberbane-Whispers-SomebodyWhoDoesnTWantTo", "Somebody who doesn't want to be known. Fine by me.");
    this.Text("Cyberbane-Whispers-BleedingAlreadySomebodyDidUsA", "Bleeding already? Somebody did us a favour.");
    this.Text("Cyberbane-Whispers-LookWhoSLeakingShameIf", "Look who's leaking. Shame if it got worse.");
    this.Text("Cyberbane-Whispers-HurtAndOnOurStreetBad", "Hurt and on our street. Bad combination, merc.");
    this.Text("Cyberbane-Whispers-SomebodySoftenedYouUpLuckyUs", "Somebody softened you up. Lucky us.");
    this.Text("Cyberbane-Whispers-SomebodyGetThatMercToA", "Somebody get that merc to a ripperdoc.");
    this.Text("Cyberbane-Whispers-TheyReHurtGiveThemRoom", "They're hurt. Give them room, they've earned it.");
    this.Text("Cyberbane-Whispers-StillStandingWithAllThatBlood", "Still standing, with all that blood. Respect.");
    this.Text("Cyberbane-Whispers-WhoeverDidThatToThemIs", "Whoever did that to them is in worse shape. Count on it.");
    this.Text("Cyberbane-Whispers-TheyReBleedingSomebodySGoing", "They're bleeding. Somebody's going to try their luck tonight.");
    this.Text("Cyberbane-Whispers-LookAtThatEvenLegendsLeak", "Look at that. Even legends leak.");
    this.Text("Cyberbane-Whispers-HurtAndStillWalkingAroundBrave", "Hurt and still walking around. Brave or stupid.");
    this.Text("Cyberbane-Whispers-DonTHelpDonTLook", "Don't help. Don't look. Just walk.");
    this.Text("Cyberbane-Whispers-ThatSALotOfBlood", "That's a lot of blood for somebody still on their feet.");
    this.Text("Cyberbane-Whispers-SmellThatCorditeSomethingJustWent", "Smell that? Cordite. Something just went down.");
    this.Text("Cyberbane-Whispers-StillShakingOffAFightThat", "Still shaking off a fight, that one. Don't be the next one.");
    this.Text("Cyberbane-Whispers-HeardTheShotsAMinuteAgo", "Heard the shots a minute ago. Now look who walks by.");
    this.Text("Cyberbane-Whispers-WhateverThatWasItJustHappened", "Whatever that was, it just happened. Keep moving.");
    this.Text("Cyberbane-Whispers-OutWalkingAtThisHourCourse", "Out walking at this hour. Course they are.");
    this.Text("Cyberbane-Whispers-NightBelongsToPeopleLikeThat", "Night belongs to people like that.");
    this.Text("Cyberbane-Whispers-NobodyGoodIsOutThisLate", "Nobody good is out this late. Present company included.");
    this.Text("Cyberbane-Whispers-LockTheDoorWhenYouGet", "Lock the door when you get home tonight. Just saying.");
    this.Text("Cyberbane-Whispers-PouringDownAndThatOneDoesn", "Pouring down and that one doesn't even flinch.");
    this.Text("Cyberbane-Whispers-WetNightAndTheyReStill", "Wet night, and they're still working.");
    this.Text("Cyberbane-Whispers-RainWashesTheBloodOffThe", "Rain washes the blood off the streets. Busy night for the rain.");
    this.Text("Cyberbane-Whispers-CanTSeeAFaceIn", "Can't see a face in this weather. Didn't need to.");
    this.Text("Cyberbane-Whispers-ThisIsWhereYouDidIt", "This is where you did it. To our people. And you come back here?");
    this.Text("Cyberbane-Whispers-YouVeGotSomeNerveStanding", "You've got some nerve, standing on this corner of all places.");
    this.Text("Cyberbane-Whispers-WeStillHavenTWashedThis", "We still haven't washed this street. And here you are.");
    this.Text("Cyberbane-Whispers-RightHereMyFriendsRightHere", "Right here. My friends, right here. Keep walking before I forget myself.");
    this.Text("Cyberbane-Whispers-ThisIsWhereTheyFoundThe", "This is where they found the bodies. Right here.");
    this.Text("Cyberbane-Whispers-StillCanTGetTheStains", "Still can't get the stains out of this pavement. And look who's back.");
    this.Text("Cyberbane-Whispers-DonTStandThereThatS", "Don't stand there. That's where it happened.");
    this.Text("Cyberbane-Whispers-NCPDTookAWeekToBag", "NCPD took a week to bag everybody from this block. Everybody knows whose work it was.");
    // {0} theirs
    this.Text("Cyberbane-Whispers-ThisIsWhereLostTheirBoss", "This is where {0} lost their boss. Right on this corner.");
    // {0} CBCapFirst(theirs)
    this.Text("Cyberbane-Whispers-StillLeaveCandlesOnThisSpot", "{0} still leave candles on this spot.");
    this.Text("Cyberbane-Whispers-TheirBossWentDownRightThere", "Their boss went down right there. The one who did it is walking past us.");
    // {0} CBCapFirst(theirs)
    this.Text("Cyberbane-Whispers-SentTheirBestHereTheirBest", "{0} sent their best here. Their best didn't leave.");
    // {0} CBPossessive(theirs)
    this.Text("Cyberbane-Whispers-ThisIsWhereHeavyHittersCame", "This is where {0} heavy hitters came to die. Look who came back to visit.");
    this.Text("Cyberbane-Whispers-MaxTacLostOneOfTheirsRight", "MaxTac lost one of theirs right about here. Nobody believed it till they saw the scorch marks.");
    this.Text("Cyberbane-Whispers-YouKnowWhatHappenedOnThis", "You know what happened on this street? MaxTac happened. And then that one happened to MaxTac.");
    this.Text("Cyberbane-Whispers-MaskOrNoMaskThatS", "Mask or no mask, that's their car. Everybody knows that car.");
    this.Text("Cyberbane-Whispers-NiceMaskShameAboutTheRide", "Nice mask. Shame about the ride.");
    this.Text("Cyberbane-Whispers-YouCanCoverYourFaceCan", "You can cover your face. Can't cover that car.");
    this.Text("Cyberbane-Whispers-SameCarEveryTimeYouD", "Same car every time. You'd think a pro would know better.");
    this.Text("Cyberbane-Whispers-HideYourFaceAllYouWant", "Hide your face all you want. That gun's famous.");
    this.Text("Cyberbane-Whispers-KnowThatPieceAnywhereOnlyOne", "Know that piece anywhere. Only one merc carries it like that.");
    this.Text("Cyberbane-Whispers-TheMaskSNewTheGun", "The mask's new. The gun isn't.");
    this.Text("Cyberbane-Whispers-EverybodyOnTheBlockHasSeen", "Everybody on the block has seen that gun on a scroller. Everybody.");
    this.Text("Cyberbane-Whispers-KabukiSGoingToBeBuzzing", "Kabuki's going to be buzzing about this by tonight.");
    this.Text("Cyberbane-Whispers-InWatsonYouReOldNews", "In Watson you're old news by morning. Not that one, though.");
    this.Text("Cyberbane-Whispers-SomebodyLlBeSellingTheStory", "Somebody'll be selling the story at the market in an hour.");
    this.Text("Cyberbane-Whispers-KeepItDownThisIsJapantown", "Keep it down. This is Japantown, not Watson.");
    this.Text("Cyberbane-Whispers-FolksRoundHerePayGoodMoney", "Folks round here pay good money not to see things like that.");
    this.Text("Cyberbane-Whispers-CharterHillDoesnTNeedThis", "Charter Hill doesn't need this kind of attention.");
    this.Text("Cyberbane-Whispers-DonTLookCorpoRuleNumber", "Don't look. Corpo rule number one: you never saw a thing.");
    this.Text("Cyberbane-Whispers-SomebodyCallBuildingSecurityActuallyDon", "Somebody call building security. Actually, don't.");
    this.Text("Cyberbane-Whispers-NotInFrontOfTheArasaka", "Not in front of the Arasaka tower. Have some class.");
    this.Text("Cyberbane-Whispers-MyAbuelaWarnedMeAboutPeople", "My abuela warned me about people like that.");
    this.Text("Cyberbane-Whispers-InHeywoodWeRememberFacesThat", "In Heywood we remember faces. That one's hard to forget.");
    this.Text("Cyberbane-Whispers-TheValentinosHearEverythingThatHappens", "The Valentinos hear everything that happens on this street. Everything.");
    this.Text("Cyberbane-Whispers-WorkingFolksDonTNeedThis", "Working folks don't need this kind of trouble.");
    this.Text("Cyberbane-Whispers-ArroyoSSeenWorseNotMuch", "Arroyo's seen worse. Not much worse.");
    this.Text("Cyberbane-Whispers-KeepWalkingWeVeGotShifts", "Keep walking. We've got shifts to get to.");
    this.Text("Cyberbane-Whispers-PacificaSSeenItAllStill", "Pacifica's seen it all. Still, that one's new.");
    this.Text("Cyberbane-Whispers-NobodyCallsTheCopsInPacifica", "Nobody calls the cops in Pacifica. Nobody comes.");
    this.Text("Cyberbane-Whispers-VoodooBoysLlKnowAboutThis", "Voodoo Boys'll know about this before it's done happening.");
    this.Text("Cyberbane-Whispers-BarghestWillKnowAboutThisBefore", "Barghest will know about this before you finish blinking.");
    this.Text("Cyberbane-Whispers-InDogtownYouDonTStare", "In Dogtown you don't stare. You survive.");
    this.Text("Cyberbane-Whispers-HansenSPeopleAreAlwaysWatching", "Hansen's people are always watching. Always.");
    this.Text("Cyberbane-Whispers-ScrappersLlHaveThatStrippedAnd", "Scrappers'll have that stripped and sold by morning.");
    this.Text("Cyberbane-Whispers-LongWayFromTheCityTo", "Long way from the city to run into that one.");
    this.Text("Cyberbane-Whispers-OutHereYouHearAName", "Out here you hear a name once and never forget it.");
    this.Text("Cyberbane-Whispers-ClansLlBeTalkingAboutThis", "Clans'll be talking about this round every fire tonight.");
    this.Text("Cyberbane-Whispers-NowThatSAMercWorth", "Now that's a merc worth knowing. Preem.");
    this.Text("Cyberbane-Whispers-SolidNoMessNoNoise", "Solid. No mess, no noise.");
    this.Text("Cyberbane-Whispers-IDTakeThatOneOn", "I'd take that one on a job any day.");
    this.Text("Cyberbane-Whispers-IfYouNeedSomethingDoingThat", "If you need something doing, that's who you call.");
    this.Text("Cyberbane-Whispers-YouVeGotSomeNerveShowing", "You've got some nerve showing your face around here.");
    this.Text("Cyberbane-Whispers-LookWhoCrawledOntoOurStreet", "Look who crawled onto our street.");
    this.Text("Cyberbane-Whispers-KeepWalkingYouReNotWelcome", "Keep walking. You're not welcome and you know it.");
    this.Text("Cyberbane-Whispers-OneDayYouLlBeSomewhere", "One day you'll be somewhere without an audience.");
    this.Text("Cyberbane-Whispers-DonTStareChoomJustKeep", "Don't stare, choom. Just keep walking.");
    this.Text("Cyberbane-Whispers-EyesDownKeepMoving", "Eyes down. Keep moving.");
    this.Text("Cyberbane-Whispers-IMNotGettingInvolvedNeither", "I'm not getting involved. Neither are you.");
    this.Text("Cyberbane-Whispers-WhateverThatOneWantsLetThem", "Whatever that one wants, let them have it.");
  }

  // ---- Allies ----------------------------------------------------------------------------------------------
  protected func DefineAllies() -> Void {
    this.Text("Cyberbane-Allies-RansomYourPeopleCanHaveYou", "[Ransom] Your people can have you back. For a price.");
    // {0} CBCapFirst(CBFactionLabel(buyer))
    this.Text("Cyberbane-Allies-HandOverWillWantAWord", "[Hand over] {0} will want a word with you.");
    this.Text("Cyberbane-Allies-WatchMyBackSomeOfYours", "[Watch my back] Some of yours could ride with me for a while.");
    this.Text("Cyberbane-Allies-QuitTheGangIMOut", "[Quit the gang] I'm out. Tell them I'm done.");
    this.Text("Cyberbane-Allies-JoinTellThemYesIM", "[Join] Tell them yes. I'm one of yours.");
    // {0} CBFactionLabel(after), {1} CBLieDistrictLabel(sys)
    this.Text("Cyberbane-Allies-LieIfAskILeftFor", "[Lie] If {0} ask, I left for {1}.");
    this.Text("Cyberbane-Allies-WelcomeToTheFamilyDonT", "Welcome to the family. Don't make us regret it.");
    this.Text("Cyberbane-Allies-YouReOneOfUsNow", "You're one of us now. Act like it.");
    this.Text("Cyberbane-Allies-JustLikeThatFineDonT", "Just like that? Fine. Don't come crying to us.");
    this.Text("Cyberbane-Allies-OutSOutNobodyHereOwes", "Out's out. Nobody here owes you anything now.");
    this.Text("Cyberbane-Allies-NotNowEverybodySBusy", "Not now. Everybody's busy.");
    this.Text("Cyberbane-Allies-CanTSpareAnybodyRightNow", "Can't spare anybody right now.");
    this.Text("Cyberbane-Allies-NobodyCanGetHereTryAgain", "Nobody can get here. Try again later.");
    // {0} here, {1} you
    this.Text("Cyberbane-Allies-OneOfOursIsOnThe", "One of ours is on the way to {0}. Keep them breathing, {1}.");
    // {0} sent, {1} here
    this.Text("Cyberbane-Allies-OfOursAreOnTheirWay", "{0} of ours are on their way to {1}. Bring them back in one piece.");
    // {0} you, {1} sent
    this.Text("Cyberbane-Allies-ForYouOfOursTheyLl", "For you, {0}? {1} of ours. They'll stick with you for an hour. Don't waste them.");
    this.Text("Cyberbane-Allies-TimeSUpWeReHeading", "Time's up. We're heading back.");
    this.Text("Cyberbane-Allies-ThisIsnTOurPartOf", "This isn't our part of town. We're going home.");
    this.Text("Cyberbane-Allies-LostYouWeLlCatchUp", "Lost you. We'll catch up some other time.");
    this.Text("Cyberbane-Allies-LooksLikeYouVeGotBusiness", "Looks like you've got business. We'll leave you to it.");
    this.Text("Cyberbane-Allies-YouShotOneOfUsWe", "You shot one of us. We're done here.");
    this.Text("Cyberbane-Allies-YouReNotOneOfOurs", "You're not one of ours any more. You know why.");
    this.Text("Cyberbane-Allies-YouVeBledForUs", "You've bled for us");
    this.Text("Cyberbane-Allies-YouVeDoneRightByUs", "You've done right by us");
    // {0} deed, {1} CBYou(sys, game)
    this.Text("Cyberbane-Allies-MoreThanOnceWantToBe", "{0}, {1}, more than once. Want to be one of ours? Say so to any of us on the street.");
    this.Text("Cyberbane-Allies-YouDidWhatWeAskedThat", "You did what we asked. That's what family does.");
    this.Text("Cyberbane-Allies-WeAskedYouDidnTCome", "We asked, you didn't come through. People are noticing.");
    // {0} CBYou(sys, game), {1} CBFactionLabel(e)
    this.Text("Cyberbane-Allies-FamilyBusinessAreGettingComfortablePut", "Family business, {0}: {1} are getting comfortable. Put down five of them this week, dead or out cold. We'll know.");
    // {0} CBHere(sys), {1} amount
    this.Text("Cyberbane-Allies-WeHearYouVeGotOne", "We hear you've got one of ours in {0}. {1}eb, you say? We'll see.");
    // {0} amount, {1} CBYou(sys, game)
    this.Text("Cyberbane-Allies-ForOneOfOursYouVe", "{0} for one of ours. You've got some nerve, {1}. Give us a minute.");
    this.Text("Cyberbane-Allies-TheyLlPayTheyDBetter", "They'll pay. They'd better pay.");
    this.Text("Cyberbane-Allies-YouThinkTheyCareEnoughTo", "You think they care enough to pay? ...They'd better.");
    // {0} CBCapFirst(CBPossessive(CBFactionLabel(gang)))
    this.Text("Cyberbane-Allies-DropTheRansom", "{0} drop: the ransom");
    this.Text("Cyberbane-Allies-AFewBlocksOver", "a few blocks over");
    // {0} amount, {1} place
    this.Text("Cyberbane-Allies-EbLeftAtOurDropIn", "{0}eb, left at our drop in {1}. Let them walk first. Come alone.");
    // {0} amount
    this.Text("Cyberbane-Allies-EbNowLetThemWalkAnd", "{0}eb. Now let them walk, and we never did business.");
    this.Text("Cyberbane-Allies-WeDonTPayForOur", "We don't pay for our people. We come and get them.");
    this.Text("Cyberbane-Allies-WeLlTakeItFromHere", "We'll take it from here. Good doing business.");
    this.Text("Cyberbane-Allies-NoNoNotThemAnybodyBut", "No. No, not them, anybody but them...");
    this.Text("Cyberbane-Allies-YouReHandingMeToTHEM", "You're handing me to THEM? You're worse than they say.");
    this.Text("Cyberbane-Allies-WhoDIEvenTell", "Who'd I even tell?");
    // {0} away, {1} CBFactionLabel(gang)
    this.Text("Cyberbane-Allies-GoneToGotItThatS", "Gone to {0}. Got it. That's what {1} will hear.");
    // {0} CBHere(sys), {1} away
    this.Text("Cyberbane-Allies-SureYouWereNeverInLeft", "Sure. You were never in {0}. Left for {1}, I'll tell them.");
    this.Text("Cyberbane-Allies-FunnyPrettySureTheyLlPay", "Funny. Pretty sure they'll pay more for where you really are.");
    this.Text("Cyberbane-Allies-SureSureHeyIKnowWho", "Sure, sure. ...Hey, I know who'd love to hear from me.");
    // {0} CBFactionLabel(book.InformantFaction(i))
    this.Text("Cyberbane-Allies-SomebodyIn", "somebody in {0}");
    this.Text("Cyberbane-Allies-OneTipLeft", ", one tip left");
    // {0} tips
    this.Text("Cyberbane-Allies-TipsLeft", ", {0} tips left");
    // {0} out
    this.Text("Cyberbane-Allies-YourInformants", "Your informants: {0}.");
    this.Text("Cyberbane-Allies-YourInformant", "Your informant");
    // {0} CBCapFirst(CBFactionLabel(gang))
    this.Text("Cyberbane-Allies-TheyKnowKnowIVeBeen", "They know. {0} know I've been talking to you. They're coming for me in the next few hours, and I'll run your way. If you want me alive, be ready.");
    this.Text("Cyberbane-Allies-CrewSergeant", "Crew sergeant");
    // {0} crewSize, {1} CBYou(sys, game)
    this.Text("Cyberbane-Allies-HoldItNobodyShootOfUs", "Hold it! Nobody shoot. {0} of us and one of you, {1}. Let's hear what you've got to say.");
    // {0} CBCapFirst(CBFactionLabel(faction))
    this.Text("Cyberbane-Allies-EasyTalkFirstThenWeLl", "Easy. {0} talk first. Then we'll see.");
    this.Text("Cyberbane-Allies-HoldYourFireIWantTo", "Hold your fire! I want to hear this before we start.");
    // {0} price
    this.Text("Cyberbane-Allies-PayEbAndYouTellThem", "[Pay] {0}eb, and you tell them you never found me.");
    this.Text("Cyberbane-Allies-ThreatenWalkAwayWhileYouStill", "[Threaten] Walk away while you still can.");
    this.Text("Cyberbane-Allies-DrawTalkSOver", "[Draw] Talk's over.");
    this.Text("Cyberbane-Allies-PleasureWeNeverSawYou", "Pleasure. We never saw you.");
    this.Text("Cyberbane-Allies-MoneyTalksBoysWeReDone", "Money talks. Boys, we're done here.");
    this.Text("Cyberbane-Allies-YouCanTCoverThatYour", "You can't cover that. Your loss.");
    this.Text("Cyberbane-Allies-NotWorthItWeReOut", "...Not worth it. We're out.");
    this.Text("Cyberbane-Allies-FineFINENobodySPayingUs", "Fine. FINE. Nobody's paying us enough for this.");
    this.Text("Cyberbane-Allies-BigWordsLightThemUp", "Big words. Light them up!");
    this.Text("Cyberbane-Allies-IsThatAThreatTakeThem", "Is that a threat? Take them!");
    this.Text("Cyberbane-Allies-YourCall", "Your call.");
    this.Text("Cyberbane-Allies-Family", "family");
    // {0} you
    this.Text("Cyberbane-Allies-HeyGoodToSeeYou", "Hey, {0}. Good to see you.");
    this.Text("Cyberbane-Allies-ThatSOneOfOursMake", "That's one of ours. Make room.");
    this.Text("Cyberbane-Allies-AnybodyBotheringYouRoundHereYou", "Anybody bothering you round here, you tell us.");
    // {0} you
    this.Text("Cyberbane-Allies-LookingSharp", "Looking sharp, {0}.");
  }

  // ---- CombatFlee ------------------------------------------------------------------------------------------
  protected func DefineCombatFlee() -> Void {
    // {0} CBRivalDisplayName(sys.GetContent(), fallen)
    this.Text("Cyberbane-CombatFlee-IsDownFinishThemWalkOff", "{0} is down. Finish them, walk off to spare them, or put your weapon away and walk up to talk to them.");
    // {0} CBRivalDisplayName(content, already)
    this.Text("Cyberbane-CombatFlee-LeftNightCityInTheBack", "{0} left Night City in the back of a truck. Nobody expects them back.");
    // {0} name
    this.Text("Cyberbane-CombatFlee-OwesYouOneNowPeopleLike", "{0} owes you one now. People like that remember both ways.");
    // {0} name
    this.Text("Cyberbane-CombatFlee-YouLetWalkAgainTheyCame", "You let {0} walk again. They came back worse for it.");
  }

  // ---- Crew ------------------------------------------------------------------------------------------------
  protected func DefineCrew() -> Void {
    this.Text("Cyberbane-Crew-MyCrew", "My crew");
    this.Text("Cyberbane-Crew-Heavy", "heavy");
    this.Text("Cyberbane-Crew-Blade", "blade");
    this.Text("Cyberbane-Crew-Shooter", "shooter");
    this.Text("Cyberbane-Crew-Wall", "Wall");
    this.Text("Cyberbane-Crew-Anvil", "Anvil");
    this.Text("Cyberbane-Crew-Brick", "Brick");
    this.Text("Cyberbane-Crew-Bulldozer", "Bulldozer");
    this.Text("Cyberbane-Crew-Mountain", "Mountain");
    this.Text("Cyberbane-Crew-Knives", "Knives");
    this.Text("Cyberbane-Crew-Edge", "Edge");
    this.Text("Cyberbane-Crew-Whisper", "Whisper");
    this.Text("Cyberbane-Crew-PaperCut", "Paper Cut");
    this.Text("Cyberbane-Crew-Ribbons", "Ribbons");
    this.Text("Cyberbane-Crew-Ghost", "Ghost");
    this.Text("Cyberbane-Crew-Static", "Static");
    this.Text("Cyberbane-Crew-Daemon", "Daemon");
    this.Text("Cyberbane-Crew-Wire", "Wire");
    this.Text("Cyberbane-Crew-Blackout", "Blackout");
    this.Text("Cyberbane-Crew-Trigger", "Trigger");
    this.Text("Cyberbane-Crew-Ricochet", "Ricochet");
    this.Text("Cyberbane-Crew-TapTap", "Tap-Tap");
    this.Text("Cyberbane-Crew-Longshot", "Longshot");
    // {0} gang
    this.Text("Cyberbane-Crew-OnceOfWhoOwesYouA", "once of {0}, who owes you a life");
    this.Text("Cyberbane-Crew-WhoOwesYouALife", "who owes you a life");
    // {0} gang
    this.Text("Cyberbane-Crew-OnceOfScaredIntoWorkingFor", "once of {0}, scared into working for you");
    this.Text("Cyberbane-Crew-ScaredIntoWorkingForYou", "scared into working for you");
    // {0} gang
    this.Text("Cyberbane-Crew-OnLoanFrom", "on loan from {0}");
    this.Text("Cyberbane-Crew-OnLoan", "on loan");
    this.Text("Cyberbane-Crew-ASoloPaidByTheWeek", "a solo, paid by the week");
    // {0} gang
    this.Text("Cyberbane-Crew-OwesYouALifeEx", "owes you a life, ex-{0}");
    this.Text("Cyberbane-Crew-OwesYouALife", "owes you a life");
    // {0} gang
    this.Text("Cyberbane-Crew-ScaredEx", "scared, ex-{0}");
    this.Text("Cyberbane-Crew-ScaredIntoIt", "scared into it");
    // {0} gang
    this.Text("Cyberbane-Crew-OnLoan-2", "on loan, {0}");
    this.Text("Cyberbane-Crew-PaidSolo", "paid solo");
    this.Text("Cyberbane-Crew-RecruitYouOweMeWorkFor", "[Recruit] You owe me. Work for me.");
    // {0} you
    this.Text("Cyberbane-Crew-WorkForYouIDRather", "Work for you? I'd rather bleed out right here, {0}.");
    this.Text("Cyberbane-Crew-YouLetMeLiveThatDoesn", "You let me live. That doesn't make me yours.");
    // {0} you
    this.Text("Cyberbane-Crew-TwiceYouHadMeTwiceAnd", "Twice you had me, {0}. Twice. And now you want me fetching your coffee? No.");
    // {0} you
    this.Text("Cyberbane-Crew-YeahYeahIOweYouTwice", "...Yeah. Yeah, I owe you. Twice over. Call and I'll come, {0}.");
    this.Text("Cyberbane-Crew-GuessMyOldCrewCanFind", "Guess my old crew can find a new number two. I'm with you.");
    // {0} CBHere(sys)
    this.Text("Cyberbane-Crew-YouCouldVeEndedMeIn", "You could've ended me in {0}. You didn't. That buys you my gun.");
    this.Text("Cyberbane-Crew-ItSMeSavedYourNumber", "It's me. Saved your number. Whatever you need, I'm there.");
    this.Text("Cyberbane-Crew-ToldMyOldCrewIM", "Told my old crew I'm done. They took it about as well as you'd think. Call me.");
    this.Text("Cyberbane-Crew-PatchedUpArmedBoredSayThe", "Patched up, armed, bored. Say the word.");
    // {0} CBRivalDisplayName(sys.GetContent(), r), {1} CBFactionLabel(r.faction)
    this.Text("Cyberbane-Crew-WalkedOutOnAndRunsWith", "{0} walked out on {1} and runs with you now. Nobody saw that coming.");
    this.Text("Cyberbane-Crew-CanTNotNow", "Can't. Not now.");
    this.Text("Cyberbane-Crew-IOweYouTipsNotMy", "I owe you tips. Not my life. Let's keep it that way.");
    this.Text("Cyberbane-Crew-IMOutOfThatLife", "I'm out of that life. Don't ask again.");
    this.Text("Cyberbane-Crew-FunnyIWasGoingToAsk", "Funny. I was going to ask you the same thing. I'm in.");
    this.Text("Cyberbane-Crew-PayingADebtWithMyTrigger", "Paying a debt with my trigger finger. Fair. I'm in.");
    // {0} CBHere(sys)
    this.Text("Cyberbane-Crew-ItSMeFromIDon", "It's me. From {0}. I don't want trouble with you. Ever. Tell me where to be.");
    // {0} CBYou(sys, game)
    this.Text("Cyberbane-Crew-OkayOkayIMYoursJust", "Okay. Okay! I'm yours. Just... don't look at me like that, {0}.");
    // {0} CBCapFirst(CBFactionLabel(t.faction))
    this.Text("Cyberbane-Crew-WorkForYouBetterThanThe", "Work for you? Better than the other thing. Fine. {0} never paid me anyway.");
    this.Text("Cyberbane-Crew-WhateverYouSayILlKeep", "Whatever you say. I'll keep my phone on. Please.");
    this.Text("Cyberbane-Crew-LendOneOfYoursOnMy", "[Lend] One of yours on my crew. For good.");
    this.Text("Cyberbane-Crew-NobodyToSpareRightNow", "Nobody to spare right now.");
    // {0} CBCapFirst(CBFactionLabel(t.faction))
    this.Text("Cyberbane-Crew-SayIMYoursNowAs", "{0} say I'm yours now. As long as you're good with them, I'm good with you.");
    // {0} name, {1} CBCrewSeatWord(m.seat)
    this.Text("Cyberbane-Crew-SYoursGoodBringThemHome", "{0}'s yours. Good {1}. Bring them home when it matters.");
    // {0} name, {1} CBYou(sys, game)
    this.Text("Cyberbane-Crew-TakeAndRememberWhoYourFriends", "Take {0}. And remember who your friends are, {1}.");
    this.Text("Cyberbane-Crew-Broker", "Broker");
    // {0} CBCrewFirst(sys, recruiter), {1} solo, {2} seat, {3} rank, {4} book.offerPrice
    this.Text("Cyberbane-Crew-FromYourCrewSentMeFound", "{0} from your crew sent me. Found you {1}: a {2}, a {3} already. {4}eb up front, then the weekly cut, and that's the friends price.");
    // {0} CBCrewFirst(sys, recruiter), {1} solo, {2} seat, {3} book.offerPrice
    this.Text("Cyberbane-Crew-YourVouchesForThisOneFights", "Your {0} vouches for this one: {1}, {2}, fights behind them. {3}eb to sign. Say the word.");
    // {0} solo, {1} seat, {2} book.offerPrice
    this.Text("Cyberbane-Crew-GotASoloLookingForSteady", "Got a solo looking for steady work: {0}, a {1}. Wants {2}eb up front, then the weekly cut. Interested?");
    // {0} solo, {1} seat, {2} book.offerPrice
    this.Text("Cyberbane-Crew-WordSOutYouReBuilding", "Word's out you're building a crew. {0} wants in: {1}, clean record, {2}eb to sign. Say the word.");
    this.Text("Cyberbane-Crew-ThatSoloFoundOtherWork", "That solo found other work.");
    this.Text("Cyberbane-Crew-YourCrewSFull", "Your crew's full.");
    // {0} book.offerPrice
    this.Text("Cyberbane-Crew-ComeBackWithEb", "Come back with {0}eb.");
    this.Text("Cyberbane-Crew-HeardGoodThingsAboutThisCrew", "Heard good things about this crew. Didn't think I'd get the chance. Call me.");
    this.Text("Cyberbane-Crew-MoneySInIMYours", "Money's in. I'm yours till it stops. Call when it gets loud.");
    // {0} CBHere(sys)
    this.Text("Cyberbane-Crew-SignedAndLoadedWhereInDo", "Signed and loaded. Where in {0} do you want me?");
    this.Text("Cyberbane-Crew-NobodySAnswering", "Nobody's answering.");
    this.Text("Cyberbane-Crew-YouDonTHaveACrew", "You don't have a crew yet.");
    this.Text("Cyberbane-Crew-TheyReOnTheirWayHome", "They're on their way home. Give them a minute.");
    this.Text("Cyberbane-Crew-TheyReAlreadyWithYou", "They're already with you.");
    this.Text("Cyberbane-Crew-FinishTheRoundFirst", "Finish the round first.");
    this.Text("Cyberbane-Crew-NotWhileYouReDrivingGet", "Not while you're driving. Get out and call.");
    this.Text("Cyberbane-Crew-TooManyPeopleAroundTheyCan", "Too many people around. They can't get close.");
    // {0} who, {1} CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour())
    this.Text("Cyberbane-Crew-SStillPatchedUpAboutH", "{0}'s still patched up, about {1}h");
    // {0} who, {1} StrLower(away)
    this.Text("Cyberbane-Crew-S", "{0}'s {1}");
    // {0} who
    this.Text("Cyberbane-Crew-SSparringWithYou", "{0}'s sparring with you");
    // {0} who, {1} CeilF((CBConfig.MyCrewCallSeconds() - (now - m.calledAt)) / 60.0)
    this.Text("Cyberbane-Crew-JustGotBackGiveItMinutes", "{0} just got back, give it {1} minutes");
    // {0} parts
    this.Text("Cyberbane-Crew-NobodyCanComeYet", "Nobody can come yet: {0}.");
    this.Text("Cyberbane-Crew-EverybodySHurtBusyOrJust", "Everybody's hurt, busy or just got back.");
    this.Text("Cyberbane-Crew-NotIntoTheStoryCallWhen", "Not into the story. Call when it's done.");
    this.Text("Cyberbane-Crew-YouReInTheMiddleOf", "You're in the middle of something. Call after.");
    this.Text("Cyberbane-Crew-SomewhereSafeTheyLlWaitFor", "Somewhere safe. They'll wait for you outside.");
    this.Text("Cyberbane-Crew-YouReOnAJobThey", "You're on a job. They stay out of those.");
    this.Text("Cyberbane-Crew-ThatSNoGigTheyStay", "That's no gig. They stay out of the big story.");
    this.Text("Cyberbane-Crew-TheStorySGotYouWe", "The story's got you. We'll be around when it lets go.");
    this.Text("Cyberbane-Crew-YouReTiedUpWeLl", "You're tied up. We'll head back.");
    this.Text("Cyberbane-Crew-YouReSafeInThereWe", "You're safe in there. We'll head back.");
    this.Text("Cyberbane-Crew-ThatSYourJobNotOurs", "That's your job, not ours. Heading back.");
    this.Text("Cyberbane-Crew-ThisIsTheBigStoryWe", "This is the big story. We stay out of that one.");
    this.Text("Cyberbane-Crew-WeReHeadingBack", "We're heading back.");
    this.Text("Cyberbane-Crew-NobodyCouldGetThroughToYou", "Nobody could get through to you. Try again somewhere more open.");
    this.Text("Cyberbane-Crew-WhoeverItIs", "whoever it is");
    // {0} here
    this.Text("Cyberbane-Crew-ComingToWeLlWalkWith", "Coming to {0}. We'll walk with you till you say otherwise.");
    this.Text("Cyberbane-Crew-OnMyWayTellMeWhen", "On my way. Tell me when you want us gone.");
    this.Text("Cyberbane-Crew-QuietDayFineByMeComing", "Quiet day? Fine by me. Coming to keep you company.");
    // {0} who
    this.Text("Cyberbane-Crew-HeardWereWaitingForYouAlready", "Heard {0} were waiting for you. Already on my way.");
    // {0} here
    this.Text("Cyberbane-Crew-DonTCallDonTNeed", "Don't call, don't need to. Coming to {0}.");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-Crew-MyOldCrewFineIM", "{0}? My old crew. ...Fine. I'm coming.");
    // {0} who
    this.Text("Cyberbane-Crew-IKnowHowFightILl", "I know how {0} fight. I'll be there.");
    // {0} here
    this.Text("Cyberbane-Crew-AgainSameAsAlwaysComingTo", "Again? Same as always. Coming to {0}.");
    this.Text("Cyberbane-Crew-KeepYourHeadDownIKnow", "Keep your head down. I know the way by now.");
    // {0} here
    this.Text("Cyberbane-Crew-OnMyWayToHoldOn", "On my way to {0}. Hold on.");
    // {0} CBWhenTail(game)
    this.Text("Cyberbane-Crew-ComingDonTDieBeforeI", "Coming{0}. Don't die before I get there.");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-Crew-GotItWonTKnowWhat", "Got it. {0} won't know what hit them.");
    this.Text("Cyberbane-Crew-IMDownStillBreathingFinish", "I'm down! Still breathing. Finish them.");
    this.Text("Cyberbane-Crew-HitBadIMDownNot", "Hit bad. I'm down, not out. Keep going.");
    this.Text("Cyberbane-Crew-CanTGetUpDonT", "Can't get up. Don't let them finish me.");
    this.Text("Cyberbane-Crew-CouldnTGetThroughToYou", "Couldn't get through to you. Call again.");
    // {0} RoundF(CBConfig.MyCrewHurtDays() * 24.0)
    this.Text("Cyberbane-Crew-YouStayedWithMeILl", "You stayed with me. I'll live. Out for {0} hours while they patch me up.");
    this.Text("Cyberbane-Crew-Home", "home");
    // {0} home
    this.Text("Cyberbane-Crew-CleanWeReHeadingBackTo", "Clean. We're heading back to {0}.");
    this.Text("Cyberbane-Crew-ThatSDoneCallAgainSame", "That's done. Call again, same price.");
    // {0} CBYou(sys, game)
    this.Text("Cyberbane-Crew-NotBadNotBadAtAll", "Not bad, {0}. Not bad at all.");
    this.Text("Cyberbane-Crew-QuietNowWeReGoing", "Quiet now. We're going.");
    this.Text("Cyberbane-Crew-GoWeLlFindOurOwn", "Go, we'll find our own way home.");
    this.Text("Cyberbane-Crew-NiceOfYouToWaitWe", "Nice of you to wait. We'll walk.");
    // {0} home
    this.Text("Cyberbane-Crew-LostYouHeadingBackTo", "Lost you. Heading back to {0}.");
    // {0} home
    this.Text("Cyberbane-Crew-HeadingBackToCallWhenYou", "Heading back to {0}. Call when you need us.");
    this.Text("Cyberbane-Crew-GoingYouKnowWhereToFind", "Going. You know where to find us.");
    // {0} CBCrewFirst(sys, promoted), {1} CBCrewNickname(promoted.seat, promoted.seed)
    this.Text("Cyberbane-Crew-TheStreetSCallingNowEarned", "The street's calling {0} \"{1}\" now. Earned it.");
    // {0} CBCrewFirst(sys, promoted), {1} CBCrewRankWord(rank)
    this.Text("Cyberbane-Crew-IsGettingGoodAtThisNow", "{0} is getting good at this. {1} now.");
    this.Text("Cyberbane-Crew-YouLeftMeLyingThereI", "You left me lying there. I'll remember that.");
    this.Text("Cyberbane-Crew-WokeUpAloneOnThePavement", "Woke up alone on the pavement. Thanks for nothing.");
    this.Text("Cyberbane-Crew-CleanStillWithYou", "Clean. Still with you.");
    this.Text("Cyberbane-Crew-ThatSHandledLeadOn", "That's handled. Lead on.");
    this.Text("Cyberbane-Crew-AnybodyElseWantSomeDidnT", "Anybody else want some? Didn't think so.");
    this.Text("Cyberbane-Crew-YouShouldHavePaidMe", "You should have paid me.");
    this.Text("Cyberbane-Crew-YouLeftMeLyingInThe", "You left me lying in the street. Now you know how it feels.");
    this.Text("Cyberbane-Crew-YouKeptKillingMyPeopleThey", "You kept killing my people. They're still my people.");
    this.Text("Cyberbane-Crew-NothingPersonalTheyPayBetter", "Nothing personal. They pay better.");
    // {0} reason
    this.Text("Cyberbane-Crew-NotComingTheyKnowExactlyWhere", "Not coming. They know exactly where you are now. {0}");
    // {0} name
    this.Text("Cyberbane-Crew-SoldYouOutWhoeverSAfter", "{0} sold you out. Whoever's after you knows where you're standing.");
    // {0} CBYou(sys, game)
    this.Text("Cyberbane-Crew-SorryBetterOffer", "Sorry, {0}. Better offer.");
    this.Text("Cyberbane-Crew-ShouldVePaidMeWhatI", "Should've paid me what I was worth.");
    this.Text("Cyberbane-Crew-TurnAroundSlowlyThisWasAlways", "Turn around. Slowly. This was always going to happen.");
    // {0} name
    this.Text("Cyberbane-Crew-TurnedOnYouDidNotSee", "{0} turned on you. Did not see that coming. Or maybe we did.");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-Crew-GotAwayTheyKnowYourHaunts", "{0} got away. They know your haunts, your habits, your crew. Expect them.");
    // {0} m.wins
    this.Text("Cyberbane-Crew-FightsWithYouAndThisIs", " {0} fights with you, and this is how it ends.");
    // {0} name, {1} by, {2} wins
    this.Text("Cyberbane-Crew-IsDeadDidItYouKnow", "{0} is dead. {1} did it.{2} You know what to do.");
    // {0} name, {1} CBHere(sys), {2} wins
    this.Text("Cyberbane-Crew-IsDeadInFindWhoDid", "{0} is dead, in {1}.{2} Find who did it.");
    // {0} CBCrewFirst(sys, m)
    this.Text("Cyberbane-Crew-WeLentYouYouWereSupposed", "We lent you {0}. You were supposed to bring them back.");
    // {0} CBCrewPastName(sys, p)
    this.Text("Cyberbane-Crew-ThatWasForRestEasy", "That was for {0}. Rest easy.");
    // {0} CBCrewPastName(sys, past), {1} CBRivalDisplayName(sys.GetContent(), nr)
    this.Text("Cyberbane-Crew-TheOneWhoKilledGotAway", "The one who killed {0} got away. The street calls them {1} now. We won't forget.");
    // {0} CBCrewFirst(sys, m)
    this.Text("Cyberbane-Crew-WeWantBackYouKnowWhy", "We want {0} back. You know why.");
    this.Text("Cyberbane-Crew-IMDoneDonTCall", "I'm done. Don't call this number again.");
    // {0} book.CutOwed()
    this.Text("Cyberbane-Crew-WeekSUpTheCutS", "Week's up. The cut's {0}eb. Everybody's asking.");
    // {0} CBYou(sys, game), {1} book.CutOwed()
    this.Text("Cyberbane-Crew-PaydayEbForTheCrew", "Payday, {0}. {1}eb for the crew.");
    this.Text("Cyberbane-Crew-BeenThinkingAboutWhetherThisIs", "Been thinking about whether this is worth it.");
    this.Text("Cyberbane-Crew-YouStillOweMeForThe", "You still owe me for the last job. I don't work for free.");
    this.Text("Cyberbane-Crew-StillThinkingAboutYouLeavingMe", "Still thinking about you leaving me lying there.");
    this.Text("Cyberbane-Crew-WeLostOneCouldVeBeen", "We lost one. Could've been me. Could still be.");
    // {0} CBFactionLabel(m.faction)
    this.Text("Cyberbane-Crew-YouKeepPuttingDownSomeOf", "You keep putting down {0}. Some of them were my friends.");
    this.Text("Cyberbane-Crew-NotAsScaredOfYouAs", "Not as scared of you as I used to be. Just so you know.");
    this.Text("Cyberbane-Crew-NobodySOwedAnything", "Nobody's owed anything.");
    // {0} owed
    this.Text("Cyberbane-Crew-YouDonTHaveEb", "You don't have {0}eb.");
    this.Text("Cyberbane-Crew-CutSInEverybodySHappy", "Cut's in. Everybody's happy. For now.");
    this.Text("Cyberbane-Crew-PaidInFullThatSHow", "Paid in full. That's how you keep a crew.");
    // {0} first
    this.Text("Cyberbane-Crew-TookItWellTooWellIf", "{0} took it well. Too well, if you ask me.");
    // {0} first
    this.Text("Cyberbane-Crew-SaysThanksForTheWorkDoor", "{0} says thanks for the work. Door's open if you ever need them.");
    this.Text("Cyberbane-Crew-NeedYouNow", "Need you. Now.");
    this.Text("Cyberbane-Crew-GoHomeIVeGotThis", "Go home. I've got this.");
    // {0} book.CutOwed()
    this.Text("Cyberbane-Crew-HereSTheCutEb", "Here's the cut: {0}eb");
    this.Text("Cyberbane-Crew-HereSTheCut", "Here's the cut");
    this.Text("Cyberbane-Crew-WorkForMe", "Work for me.");
    // {0} book.offerPrice
    this.Text("Cyberbane-Crew-DealEb", "Deal: {0}eb");
    this.Text("Cyberbane-Crew-Deal", "Deal");
    this.Text("Cyberbane-Crew-TooMuch", "Too much");
    this.Text("Cyberbane-Crew-NotNow", "Not now");
    this.Text("Cyberbane-Crew-DoneTheyLlBeOnYour", "Done. They'll be on your crew thread.");
    // {0} book.offerPrice
    this.Text("Cyberbane-Crew-FineEbAndTheyReYours", "Fine. {0}eb, and they're yours. Last offer.");
    // {0} book.offerPrice
    this.Text("Cyberbane-Crew-GoodPeopleCostMoneyEb", "Good people cost money. {0}eb.");
    this.Text("Cyberbane-Crew-YourLossSomebodyElseWillTake", "Your loss. Somebody else will take them.");
    this.Text("Cyberbane-Crew-WITHYOU", "WITH YOU");
    this.Text("Cyberbane-Crew-HURT", "HURT");
    this.Text("Cyberbane-Crew-RESTING", "RESTING");
    this.Text("Cyberbane-Crew-RESTLESS", "RESTLESS");
    // {0} CBCrewWordHurt(), {1} hours
    this.Text("Cyberbane-Crew-H", "{0}, {1}H");
    this.Text("Cyberbane-Crew-READY", "READY");
    this.Text("Cyberbane-Crew-YourCrewIsSwitchedOffIn", "Your crew is switched off in Mod Settings.");
    this.Text("Cyberbane-Crew-NobodyWorksForYouYetFour", "Nobody works for you yet. Four ways in: beat down a Rival you have spared before and, while they are on the ground, tell them to work for you; scare a ganger badly enough and tell them they work for you now; hire a solo a broker offers you; or ask a Friendly or Allied gang to lend you one of theirs.");
    // {0} book.Count(), {1} CBConfig.MyCrewRoster()
    this.Text("Cyberbane-Crew-OfOnTheRoster", "{0} of {1} on the roster.");
    // {0} book.CutOwed()
    this.Text("Cyberbane-Crew-TheyAreOwedEb", " They are owed {0}eb.");
    this.Text("Cyberbane-Crew-TheCutIsDueWithinA", " The cut is due within a day.");
    // {0} days
    this.Text("Cyberbane-Crew-TheCutIsDueInDays", " The cut is due in {0} days.");
    this.Text("Cyberbane-Crew-YouCalledYourCrewAndOne", "You called your crew, and one of them came.");
    // {0} n
    this.Text("Cyberbane-Crew-YouCalledYourCrewAndCame", "You called your crew, and {0} came.");
    this.Text("Cyberbane-Crew-YourCrewFoughtBesideYouAnd", "Your crew fought beside you, and won.");
    // {0} n
    this.Text("Cyberbane-Crew-YouPaidYourCrewTheirCut", "You paid your crew their cut: {0}eb.");
    this.Text("Cyberbane-Crew-YouPutDownTheOneWho", "You put down the one who turned on you.");
    // {0} name
    this.Text("Cyberbane-Crew-JoinedYourCrew", "{0} joined your crew.");
    // {0} name
    this.Text("Cyberbane-Crew-DiedFightingForYou", "{0} died fighting for you.");
    // {0} name
    this.Text("Cyberbane-Crew-TurnedOnYouInTheMiddle", "{0} turned on you in the middle of a fight.");
    // {0} name
    this.Text("Cyberbane-Crew-SoldYouOutToThePeople", "{0} sold you out to the people hunting you.");
    // {0} name
    this.Text("Cyberbane-Crew-WalkedOutOnYourCrew", "{0} walked out on your crew.");
    // {0} name
    this.Text("Cyberbane-Crew-YouLetGo", "You let {0} go.");
    // {0} name
    this.Text("Cyberbane-Crew-YouAvenged", "You avenged {0}.");
    // {0} StrUpper(CBCrewRankWord(CBCrewRankOf(npc.GetGame(), m))), {1} StrUpper(CBCrewSeatWord(m.seat))
    this.Text("Cyberbane-Crew-YOURCREW", "YOUR CREW  /  {0}  /  {1}");
    this.Text("Cyberbane-Crew-YOURCREWSPARRING", "YOUR CREW  /  SPARRING");
    this.Text("Cyberbane-Crew-TURNEDONYOU", "TURNED ON YOU");
    // {0} StrUpper(CBCrewFirstName(sys, p.kind, p.faction, p.rival, p.seed))
    this.Text("Cyberbane-Crew-KILLED", "KILLED {0}");
    this.Text("Cyberbane-Crew-WouldTakeABulletForYou", "would take a bullet for you");
    this.Text("Cyberbane-Crew-Solid", "solid");
    this.Text("Cyberbane-Crew-DoingTheJob", "doing the job");
    this.Text("Cyberbane-Crew-Restless", "restless");
    this.Text("Cyberbane-Crew-CloseToWalkingOrWorse", "close to walking, or worse");
    this.Text("Cyberbane-Crew-TheCutYouOweThem", "the cut you owe them");
    this.Text("Cyberbane-Crew-YouLeftThemLyingInThe", "you left them lying in the street");
    this.Text("Cyberbane-Crew-LosingOneOfTheCrew", "losing one of the crew");
    // {0} CBFactionLabel(m.faction)
    this.Text("Cyberbane-Crew-WhatYouKeepDoingTo", "what you keep doing to {0}");
    this.Text("Cyberbane-Crew-TheyAreLessAfraidOfYou", "they are less afraid of you than they were");
    this.Text("Cyberbane-Crew-FELL", "FELL");
    this.Text("Cyberbane-Crew-LETGO", "LET GO");
    this.Text("Cyberbane-Crew-WALKED", "WALKED");
    this.Text("Cyberbane-Crew-SOLDYOUOUT", "SOLD YOU OUT");
    // {0} StrLower(CBCrewRankWord(CBCrewRank(bbOffer.offerWins)))
    this.Text("Cyberbane-Crew-YourRecruiterFoundThemTheyCome", "Your recruiter found them: they come as a {0}, more loyal than most. ");
    // {0} StrUpper(solo), {1} book.offerSender, {2} seat, {3} book.offerPrice, {4} found
    this.Text("Cyberbane-Crew-ASoloPutForwardAEb", "{0}\nA solo {1} put forward: a {2}, {3}eb to sign, then the weekly cut. {4}Paid people are loyal while the money keeps coming. The offer stands for a day.");
    this.Text("Cyberbane-Crew-TheCity", "the city");
    // {0} since
    this.Text("Cyberbane-Crew-WithYou", ", with you {0}.");
    // {0} CBCrewSeatWord(m.seat), {1} CBCrewFromWords(m), {2} home, {3} (StrLen(since) > 0 ? s", with you \(since)." : ".")
    this.Text("Cyberbane-Crew-ALivesIn", "A {0}, {1}. Lives in {2}{3}\n");
    this.Text("Cyberbane-Crew-NoFightsWonWithYouYet", "No fights won with you yet");
    this.Text("Cyberbane-Crew-OneFightWonWithYou", "One fight won with you");
    // {0} m.wins
    this.Text("Cyberbane-Crew-FightsWonWithYou", "{0} fights won with you");
    this.Text("Cyberbane-Crew-OneScarToShowForIt", ", one scar to show for it");
    // {0} m.scars
    this.Text("Cyberbane-Crew-ScarsToShowForIt", ", {0} scars to show for it");
    // {0} CBCrewNickname(m.seat, m.seed)
    this.Text("Cyberbane-Crew-KnownAs", ", known as \"{0}\"");
    // {0} wins, {1} scars, {2} CBCrewRankWord(rank), {3} rank, {4} (rank >= 3 ? s", known as \"\(CBCrewNickname(m.seat, m.seed))\"" : "")
    this.Text("Cyberbane-Crew-RankOf6", "{0}{1}. {2}, rank {3} of 6{4}.\n");
    // {0} m.loyalty, {1} CBCrewLoyaltyWord(m.loyalty)
    this.Text("Cyberbane-Crew-LoyaltyOf100", "Loyalty {0} of 100: {1}.");
    // {0} worry
    this.Text("Cyberbane-Crew-WhatSEatingThem", " What's eating them: {0}.");
    this.Text("Cyberbane-Crew-HeadingHomeNow", "Heading home now.\n");
    this.Text("Cyberbane-Crew-WithYouNow", "With you now.\n");
    // {0} CeilF((m.hurtUntil - now) / CBConfig.SecondsPerHour())
    this.Text("Cyberbane-Crew-HurtBackOnTheirFeetIn", "Hurt: back on their feet in about {0} hours.\n");
    this.Text("Cyberbane-Crew-JustGotBackTheyCanBe", "Just got back. They can be called again within the hour.\n");
    this.Text("Cyberbane-Crew-CallThemLikeThisAndThey", "Call them like this and they might sell you out, or worse. Pay them, win with them, or let them go.\n");
  }

  // ---- CrewBanner ------------------------------------------------------------------------------------------
  protected func DefineCrewBanner() -> Void {
    this.Text("Cyberbane-CrewBanner-Red", "Red");
    this.Text("Cyberbane-CrewBanner-Orange", "Orange");
    this.Text("Cyberbane-CrewBanner-Gold", "Gold");
    this.Text("Cyberbane-CrewBanner-Green", "Green");
    this.Text("Cyberbane-CrewBanner-Cyan", "Cyan");
    this.Text("Cyberbane-CrewBanner-Blue", "Blue");
    this.Text("Cyberbane-CrewBanner-Violet", "Violet");
    this.Text("Cyberbane-CrewBanner-White", "White");
    this.Text("Cyberbane-CrewBanner-Allied", "Allied");
    this.Text("Cyberbane-CrewBanner-Respected", "Respected");
    this.Text("Cyberbane-CrewBanner-Neutral", "Neutral");
    this.Text("Cyberbane-CrewBanner-Hostile", "Hostile");
    this.Text("Cyberbane-CrewBanner-Hated", "Hated");
    this.Text("Cyberbane-CrewBanner-YourCrew", "Your crew");
    // {0} who, {1} CBCrewStandWord(v), {2} v
    this.Text("Cyberbane-CrewBanner-ToThem", "{0}, to them: {1} ({2}).");
    // {0} gang
    this.Text("Cyberbane-CrewBanner-AtWar", "at war, {0}");
    this.Text("Cyberbane-CrewBanner-AtWar-2", "at war");
    this.Text("Cyberbane-CrewBanner-KilledByARival", "killed by a Rival");
    // {0} gang
    this.Text("Cyberbane-CrewBanner-KilledBy", "killed by {0}");
    this.Text("Cyberbane-CrewBanner-BesideYou", "beside you");
    this.Text("Cyberbane-CrewBanner-Today", "today");
    this.Text("Cyberbane-CrewBanner-Yesterday", "yesterday");
    // {0} days
    this.Text("Cyberbane-CrewBanner-DaysAgo", "{0} days ago");
    this.Text("Cyberbane-CrewBanner-ASoloYouPaid", "a solo you paid");
    // {0} gang
    this.Text("Cyberbane-CrewBanner-OnceOfWhoOwedYouA", "once of {0}, who owed you a life");
    this.Text("Cyberbane-CrewBanner-WhoOwedYouALife", "who owed you a life");
    // {0} CBCrewRankWord(f.rank), {1} CBCrewSeatWord(f.seat), {2} origin
    this.Text("Cyberbane-CrewBanner-A", "{0}, a {1}, {2}.\n");
    this.Text("Cyberbane-CrewBanner-DiedFightingBesideYou", "Died fighting beside you");
    // {0} killers
    this.Text("Cyberbane-CrewBanner-DiedInTheWarTheyStarted", "Died in the war they started on {0}");
    this.Text("Cyberbane-CrewBanner-DiedInAWarTheyStarted", "Died in a war they started for you");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-CrewBanner-KilledBy-2", "Killed by {0}");
    // {0} CBDistrictLabel(f.district)
    this.Text("Cyberbane-CrewBanner-In", " in {0},");
    this.Text("Cyberbane-CrewBanner-Day", "day");
    this.Text("Cyberbane-CrewBanner-Days", "days");
    // {0} days, {1} days == 1 ? "day" : "days"
    this.Text("Cyberbane-CrewBanner-AfterWithYourCrew", " after {0} {1} with your crew.");
    this.Text("Cyberbane-CrewBanner-OnTheirFirstDayWithYour", " on their first day with your crew.");
    this.Text("Cyberbane-CrewBanner-Fight", "fight");
    this.Text("Cyberbane-CrewBanner-Fights", "fights");
    // {0} f.wins, {1} f.wins == 1 ? "fight" : "fights"
    this.Text("Cyberbane-CrewBanner-WonBesideYou", " {0} {1} won beside you.");
    // {0} CBCrewItemName(f.weapon), {1} CBCrewTierWord(f.weaponTier)
    this.Text("Cyberbane-CrewBanner-TheyCarriedYourItCameBack", "They carried your {0} ({1}). It came back to you.");
    this.Text("Cyberbane-CrewBanner-TheyCarriedNothingOfYours", "They carried nothing of yours.");
    // {0} parts
    this.Text("Cyberbane-CrewBanner-ChromeYouGaveThem", " Chrome you gave them: {0}.");
    this.Text("Cyberbane-CrewBanner-Time", "time");
    this.Text("Cyberbane-CrewBanner-Times", "times");
    // {0} f.trained, {1} f.trained == 1 ? "time" : "times", {2} f.spars, {3} f.spars == 1 ? "time" : "times"
    this.Text("Cyberbane-CrewBanner-TrainedSparredWithYou", " Trained {0} {1}, sparred with you {2} {3}.");
    this.Text("Cyberbane-CrewBanner-Earning", "earning");
    this.Text("Cyberbane-CrewBanner-Recruiting", "recruiting");
    this.Text("Cyberbane-CrewBanner-None", "none");
    this.Text("Cyberbane-CrewBanner-ILlWorkTheStreetFor", "I'll work the street for you. You'll see a cut every day.");
    this.Text("Cyberbane-CrewBanner-ILlAskAroundForPeople", "I'll ask around for people worth having. When I find one, the broker will text you.");
    this.Text("Cyberbane-CrewBanner-DoneWorkingIMHereWhen", "Done working. I'm here when you need me.");
  }

  // ---- CrewKit ---------------------------------------------------------------------------------------------
  protected func DefineCrewKit() -> Void {
    this.Text("Cyberbane-CrewKit-LegendTheTopOfTheClimb", "Legend: the top of the climb.");
    this.Text("Cyberbane-CrewKit-1MoreFightWon", "1 more fight won");
    // {0} need
    this.Text("Cyberbane-CrewKit-MoreFightsWon", "{0} more fights won");
    // {0} left, {1} (left == 1 ? "" : "s")
    this.Text("Cyberbane-CrewKit-ATrainingMoreSparCountAs", "a training ({0} more spar{1} count as one)");
    // {0} ways, {1} train
    this.Text("Cyberbane-CrewKit-Or", "{0}, or {1}");
    // {0} CBCrewRankWord(rank + 1), {1} ways
    this.Text("Cyberbane-CrewKit-Next", "Next, {0}: {1}.");
    this.Text("Cyberbane-CrewKit-Legend", "Legend");
    this.Text("Cyberbane-CrewKit-Enforcer", "Enforcer");
    this.Text("Cyberbane-CrewKit-Lieutenant", "Lieutenant");
    this.Text("Cyberbane-CrewKit-Veteran", "Veteran");
    this.Text("Cyberbane-CrewKit-Soldier", "Soldier");
    this.Text("Cyberbane-CrewKit-Rookie", "Rookie");
    this.Text("Cyberbane-CrewKit-GamedataQuality", "gamedataQuality");
    this.Text("Cyberbane-CrewKit-Legendary", "legendary");
    this.Text("Cyberbane-CrewKit-Epic", "epic");
    this.Text("Cyberbane-CrewKit-Rare", "rare");
    this.Text("Cyberbane-CrewKit-Uncommon", "uncommon");
    this.Text("Cyberbane-CrewKit-Common", "common");
    this.Text("Cyberbane-CrewKit-Something", "something");
    this.Text("Cyberbane-CrewKit-MoreDamage", "more damage");
    this.Text("Cyberbane-CrewKit-MoreArmour", "more armour");
    this.Text("Cyberbane-CrewKit-MoreHealth", "more health");
    this.Text("Cyberbane-CrewKit-ShruggingOffHits", "shrugging off hits");
    this.Text("Cyberbane-CrewKit-HarderHitsOnDronesMechsAnd", "harder hits on drones, mechs and robots");
    this.Text("Cyberbane-CrewKit-FireResistance", "fire resistance");
    this.Text("Cyberbane-CrewKit-ResistanceToChemicals", "resistance to chemicals");
    this.Text("Cyberbane-CrewKit-ShockResistance", "shock resistance");
    this.Text("Cyberbane-CrewKit-BlastResistance", "blast resistance");
    this.Text("Cyberbane-CrewKit-ResistanceToBladesAndFists", "resistance to blades and fists");
    this.Text("Cyberbane-CrewKit-ResistanceToQuickhacks", "resistance to quickhacks");
    this.Text("Cyberbane-CrewKit-ResistanceToBleedingAndBurning", "resistance to bleeding and burning");
    this.Text("Cyberbane-CrewKit-ResistanceToTheBigOnes", "resistance to the big ones");
    this.Text("Cyberbane-CrewKit-ResistanceToMachines", "resistance to machines");
    this.Text("Cyberbane-CrewKit-Fireproof", "fireproof");
    this.Text("Cyberbane-CrewKit-Shockproof", "shockproof");
    this.Text("Cyberbane-CrewKit-NoBleeding", "no bleeding");
    this.Text("Cyberbane-CrewKit-PoisonProof", "poison-proof");
    this.Text("Cyberbane-CrewKit-ASandevistanSSpeedHarderTo", "a Sandevistan's speed: harder to hit, more damage");
    this.Text("Cyberbane-CrewKit-KerenzikovReflexesHarderToHit", "Kerenzikov reflexes: harder to hit");
    this.Text("Cyberbane-CrewKit-ASecondHeartMoreHealth", "a second heart: more health");
    this.Text("Cyberbane-CrewKit-OpticalCamoHarderToHit", "optical camo: harder to hit");
    this.Text("Cyberbane-CrewKit-BerserkMoreArmourMoreDamage", "Berserk: more armour, more damage");
    this.Text("Cyberbane-CrewKit-ABiomonitorMoreHealth", "a biomonitor: more health");
    this.Text("Cyberbane-CrewKit-NoFlinching", "no flinching");
    this.Text("Cyberbane-CrewKit-And", " and ");
    // {0} CeilF((k.trainUntil - now) / CBConfig.SecondsPerHour())
    this.Text("Cyberbane-CrewKit-TRAININGH", "TRAINING, {0}H");
    // {0} CeilF((k.warUntil - now) / CBConfig.SecondsPerHour())
    this.Text("Cyberbane-CrewKit-ATWARH", "AT WAR, {0}H");
    // {0} sm.X, {1} sm.Y, {2} share, {3} hitCap
    this.Text("Cyberbane-CrewKit-SmasherXHealthXDamageAt", " Smasher x{0} health, x{1} damage at their level; their share {2}; no more than {3}% a hit.");
    this.Text("Cyberbane-CrewKit-SomebodyDroppedOffAWeaponOf", "Somebody dropped off a weapon of yours. Said it was what they were carrying for you.");
    // {0} CBCrewName(sys, m)
    this.Text("Cyberbane-CrewKit-IsNotHereForThatOut", "{0} is not here for that: out with you, training or at war.");
    this.Text("Cyberbane-CrewKit-NobodyToSparWith", "nobody to spar with");
    this.Text("Cyberbane-CrewKit-ARoundIsAlreadyOn", "a round is already on");
    this.Text("Cyberbane-CrewKit-YourCrewIsOutWithYou", "your crew is out with you");
    this.Text("Cyberbane-CrewKit-TheyAreNotHere", "they are not here");
    this.Text("Cyberbane-CrewKit-TheyAreHurt", "they are hurt");
    this.Text("Cyberbane-CrewKit-OnceADayEach", "once a day each");
    this.Text("Cyberbane-CrewKit-NotHereNotNow", "not here, not now");
    this.Text("Cyberbane-CrewKit-SomebodyIsHuntingYou", "somebody is hunting you");
    this.Text("Cyberbane-CrewKit-TooManyPeopleAround", "too many people around");
    // {0} blocked
    this.Text("Cyberbane-CrewKit-NoSpar", "no spar: {0}.");
    this.Text("Cyberbane-CrewKit-NoSparTheyCouldNotGet", "no spar: they could not get to you.");
    this.Text("Cyberbane-CrewKit-OnMyWayHandsUpWhen", "On my way. Hands up when I get there. Don't hold back, I won't.");
    this.Text("Cyberbane-CrewKit-RealTroubleComingRoundSOff", "Real trouble coming. Round's off. Call us if you need us.");
    this.Text("Cyberbane-CrewKit-YouGotMeGoodRoundI", "You got me. Good round. I'll be sharper for it.");
    this.Text("Cyberbane-CrewKit-ToldYouIWouldnTHold", "Told you I wouldn't hold back. Again tomorrow?");
    this.Text("Cyberbane-CrewKit-TimeNotBadEitherOfUs", "Time. Not bad, either of us.");
    // {0} StrLower(CBCrewRankWord(CBCrewRankOf(game, m)))
    this.Text("Cyberbane-CrewKit-ThatSTheWorkOfA", " That's the work of a {0} now.");
    this.Text("Cyberbane-CrewKit-ThatWentTooFarILl", "That went too far. I'll live. Give me a couple of days.");
    // {0} total
    this.Text("Cyberbane-CrewKit-YourCrewSWorkBroughtIn", "Your crew's work brought in {0}eb.");
    // {0} hurt
    this.Text("Cyberbane-CrewKit-GotHurtDoingIt", " {0} got hurt doing it.");
    this.Text("Cyberbane-CrewKit-ThatWeaponIsNotInYour", "that weapon is not in your bag any more.");
    // {0} CBCrewName(sys, m)
    this.Text("Cyberbane-CrewKit-HandedYourWeaponBack", "{0} handed your weapon back.");
    // {0} CBCrewName(sys, m)
    this.Text("Cyberbane-CrewKit-HasNoRoomForMoreChrome", "{0} has no room for more chrome.");
    this.Text("Cyberbane-CrewKit-ThatImplantWouldDoNothingFor", "that implant would do nothing for them in a fight.");
    this.Text("Cyberbane-CrewKit-ThatImplantIsNotInYour", "that implant is not in your bag any more.");
    // {0} CBCrewItemName(rec), {1} CBCapFirst(what)
    this.Text("Cyberbane-CrewKit-GotThePutInFeelIt", "Got the {0} put in. Feel it already. {1}, next time you call.");
    // {0} cost
    this.Text("Cyberbane-CrewKit-TrainingCostsEb", "training costs {0}eb.");
    // {0} RoundF(hours)
    this.Text("Cyberbane-CrewKit-HeadingOutGiveMeHoursAnd", "Heading out. Give me {0} hours, and I'll come back worth more.");
    // {0} CBCapFirst(CBFactionLabel(gang))
    this.Text("Cyberbane-CrewKit-ConsiderItStartedYouWonT", "{0}. Consider it started. You won't hear from me for a while.");
    // {0} CBCrewRankWord(CBCrewRankOf(game, m))
    this.Text("Cyberbane-CrewKit-BackNowBetterGearAndThey", "Back. {0} now, better gear, and they put in some field chrome. Call me.");
    // {0} CBCapFirst(label)
    this.Text("Cyberbane-CrewKit-ItSDoneLostCornersPeople", "It's done. {0} lost corners, people and nerve. They know whose crew did it, so watch yourself.");
    // {0} name, {1} name
    this.Text("Cyberbane-CrewKit-CameForUsIsnTComing", "{0} came for us. {1} isn't coming back.");
    // {0} CBCapFirst(label)
    this.Text("Cyberbane-CrewKit-WereReadyForMeIGot", "{0} were ready for me. I got out, barely. I need a few days.");
    // {0} CBCrewRankWord(rank), {1} rank
    this.Text("Cyberbane-CrewKit-RankOf6", "Rank: {0} ({1} of 6).");
    // {0} CBCrewItemName(ItemID.GetTDBID(k.weapon)), {1} CBCrewTierWord(k.weaponTier), {2} CBCrewSeatWord(m.seat)
    this.Text("Cyberbane-CrewKit-CarryingYourTheyFightAsA", " Carrying your {0} ({1}): they fight as a {2}.");
    // {0} parts
    this.Text("Cyberbane-CrewKit-Chrome", " Chrome: {0}.");
    // {0} k.trained, {1} CBConfig.CrewTrainMax()
    this.Text("Cyberbane-CrewKit-TrainedOfTimes", " Trained {0} of {1} times.");
    this.Text("Cyberbane-CrewKit-SharpFromASpar", " Sharp from a spar.");
    this.Text("Cyberbane-CrewKit-WorkingTheStreetForYou", " Working the street for you.");
    this.Text("Cyberbane-CrewKit-RecruitingForTheCrewTheBroker", " Recruiting for the crew: the broker's solos come more often, cheaper, and with fights behind them.");
    this.Text("Cyberbane-CrewKit-YourCrewIsFullSoThey", " Your crew is full, so they have nobody to bring until somebody leaves.");
    // {0} k.spars
    this.Text("Cyberbane-CrewKit-SparredTimes", " Sparred {0} times.");
    // {0} CBCrewRankWord(CBConfig.CrewWarMinRank())
    this.Text("Cyberbane-CrewKit-AtTheyCanBeSentTo", " At {0} they can be sent to start a war.");
  }

  // ---- Director --------------------------------------------------------------------------------------------
  protected func DefineDirector() -> Void {
    this.Text("Cyberbane-Director-NiceMaskIDKnowThat", "Nice mask. I'd know that walk anywhere.");
    this.Text("Cyberbane-Director-YouThinkAScrapOfCloth", "You think a scrap of cloth fools me? I know who you are.");
    this.Text("Cyberbane-Director-TookMeASecondNotTwo", "Took me a second. Not two. Hello, merc.");
    this.Text("Cyberbane-Director-WearingOurColoursDoesnTMake", "Wearing our colours doesn't make you one of us. I see you.");
    this.Text("Cyberbane-Director-NiceJacketShameAboutWhoS", "Nice jacket. Shame about who's in it.");
  }

  // ---- StreetIntel -----------------------------------------------------------------------------------------
  protected func DefineStreetIntel() -> Void {
    this.Text("Cyberbane-StreetIntel-ABlade", "a blade");
    this.Text("Cyberbane-StreetIntel-SomethingHeavy", "something heavy");
    this.Text("Cyberbane-StreetIntel-ABareFist", "a bare fist");
    this.Text("Cyberbane-StreetIntel-AQuickhack", "a quickhack");
    this.Text("Cyberbane-StreetIntel-Explosives", "explosives");
    this.Text("Cyberbane-StreetIntel-OldKnifeWoundThatNeverClosed", "Old knife wound that never closed right. One good cut and they bleed out.");
    this.Text("Cyberbane-StreetIntel-GotAPlateInTheirSkull", "Got a plate in their skull. Hit them with something heavy and that's it.");
    this.Text("Cyberbane-StreetIntel-GlassJawEverybodyKnowsOneClean", "Glass jaw. Everybody knows. One clean punch and they don't get up.");
    this.Text("Cyberbane-StreetIntel-CheapChromeNeverFirewalledAnyNetrunner", "Cheap chrome, never firewalled. Any netrunner could cook them.");
    this.Text("Cyberbane-StreetIntel-HalfTheirBodySScarsFrom", "Half their body's scars from the last blast that caught them. One more explosion and they're done.");
    this.Text("Cyberbane-StreetIntel-AnOpenKnifeWoundABlade", "an open knife wound; a blade will finish them");
    this.Text("Cyberbane-StreetIntel-ACrackedSkullPlateSomethingHeavy", "a cracked skull plate; something heavy will finish them");
    this.Text("Cyberbane-StreetIntel-AGlassJawACleanPunch", "a glass jaw; a clean punch will finish them");
    this.Text("Cyberbane-StreetIntel-UnshieldedChromeAQuickhackWillFinish", "unshielded chrome; a quickhack will finish them");
    this.Text("Cyberbane-StreetIntel-OldBurnsExplosivesWillFinishThem", "old burns; explosives will finish them");
    // {0} CBRivalDisplayName(sys.GetContent(), r), {1} CBFlawWord(kind)
    this.Text("Cyberbane-StreetIntel-HadAFatalFlawYouFound", "{0} had a fatal flaw: {1}. You found it.");
    this.Text("Cyberbane-StreetIntel-OursAreAlreadyOnTheirWay", "Ours are already on their way to you. Minutes.");
    this.Text("Cyberbane-StreetIntel-TheyReSendingTheirBestAfter", "They're sending their best after you. Soon.");
    this.Text("Cyberbane-StreetIntel-OursArePuttingACrewTogether", "Ours are putting a crew together for you. Won't be long.");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-StreetIntel-SOutLookingForYouAsking", "{0}'s out looking for you. Asking everybody.");
    this.Text("Cyberbane-StreetIntel-ItSOnYourMap", " It's on your map.");
    // {0} i.name, {1} i.place, {2} i.pin
    this.Text("Cyberbane-StreetIntel-SLyingLowThatSAll", "{0}'s lying low {1}. That's all I know!{2}");
    // {0} i.name, {1} i.place, {2} i.pin
    this.Text("Cyberbane-StreetIntel-OkayLetGo", "Okay! {0}, {1}. Let go!{2}");
    // {0} i.name, {1} i.place, {2} i.pin
    this.Text("Cyberbane-StreetIntel-IsHoledUpPlease", "{0} is holed up {1}. Please.{2}");
    this.Text("Cyberbane-StreetIntel-IDonTKnowAnythingI", "I don't know anything! I swear!");
    this.Text("Cyberbane-StreetIntel-NothingIGotNothing", "Nothing! I got nothing!");
    this.Text("Cyberbane-StreetIntel-IMNobodyIDonT", "I'm nobody, I don't hear anything!");
    // {0} i.name, {1} i.place, {2} i.pin
    this.Text("Cyberbane-StreetIntel-IsLyingLow", "{0} is lying low {1}.{2}");
    this.Text("Cyberbane-StreetIntel-WorkForYouNo", "Work for you? No.");
    this.Text("Cyberbane-StreetIntel-WorkForYouINoBut", "Work for you? I... no. But I'll stay out of your way. Swear.");
    this.Text("Cyberbane-StreetIntel-NotThatAnythingButThatI", "Not that. Anything but that. I never saw you, alright?");
    this.Text("Cyberbane-StreetIntel-OkayOkayIHearThingsI", "Okay. Okay. I hear things, I'll text you. Just don't tell anyone.");
    this.Text("Cyberbane-StreetIntel-FineILlKeepMyEars", "Fine. I'll keep my ears open. Now get away from me before somebody sees.");
    this.Text("Cyberbane-StreetIntel-HeardYouReTryingToBuy", "Heard you're trying to buy my people. Come buy me.");
    this.Text("Cyberbane-StreetIntel-RatOnMyOwnIM", "Rat on my own? I'm telling them you asked.");
    this.Text("Cyberbane-StreetIntel-YouPickedTheWrongOneEverybody", "You picked the wrong one. Everybody's going to hear about this.");
    this.Text("Cyberbane-StreetIntel-YouLlPayForThat", "You'll pay for that!");
    this.Text("Cyberbane-StreetIntel-NoGetThemGetThem", "No! Get them, get them!");
    this.Text("Cyberbane-StreetIntel-ThatSItNowItS", "That's it. Now it's personal.");
    // {0} left
    this.Text("Cyberbane-StreetIntel-TalkWhereAreYourPeopleHiding", "Talk. Where are your people hiding? ({0})");
    this.Text("Cyberbane-StreetIntel-GoToHellIMNot", "Go to hell. I'm not telling you anything.");
    this.Text("Cyberbane-StreetIntel-DoItThenIMNot", "Do it, then. I'm not talking.");
    this.Text("Cyberbane-StreetIntel-WhoSentYouTalkAndI", "Who sent you? Talk, and I call you a trauma team.");
    this.Text("Cyberbane-StreetIntel-NothingOnTheBodyWorthHaving", "Nothing on the body worth having.");
    // {0} CBIntelWritten(i)
    this.Text("Cyberbane-StreetIntel-OnTheBodyABurnerPhone", "On the body, a burner phone: {0}");
    this.Text("Cyberbane-StreetIntel-GoToHell", "...go to hell...");
    // {0} CBIntelWritten(i)
    this.Text("Cyberbane-StreetIntel-ScanTheirMessagesMention", "Scan: their messages mention {0}");
    // {0} CBPlacePhrase(fake)
    this.Text("Cyberbane-StreetIntel-LastOneThenWeReSquare", "Last one, then we're square. Somebody you want is waiting {0}. Go now.");
    // {0} CBFactionLabel(faction)
    this.Text("Cyberbane-StreetIntel-ThatInformantOfYoursSoldYou", "That informant of yours? Sold you to {0}. They're coming.");
    this.Text("Cyberbane-StreetIntel-QuietOutThereNothingWorthYour", "Quiet out there. Nothing worth your time yet.");
    this.Text("Cyberbane-StreetIntel-ThatSItWeReSquare", " That's it. We're square.");
    // {0} CBIntelSpeaker(faction)
    this.Text("Cyberbane-StreetIntel-OnTheInside", "{0} on the inside");
    this.Text("Cyberbane-StreetIntel-YouLetMeWalkTwiceI", "You let me walk. Twice. I don't forget that. I hear things, and you'll hear them too.");
  }

  // ---- StreetPay -------------------------------------------------------------------------------------------
  protected func DefineStreetPay() -> Void {
    // {0} price
    this.Text("Cyberbane-StreetPay-PayEbYouDidnTSee", "[Pay] {0}eb. You didn't see anything.");
    this.Text("Cyberbane-StreetPay-Body", "[Body] ");
    this.Text("Cyberbane-StreetPay-Intimidate", "[Intimidate] ");
    // {0} (body ? "[Body] " : "[Intimidate] ")
    this.Text("Cyberbane-StreetPay-NobodyHearsAboutThisUnderstand", "{0}Nobody hears about this. Understand?");
    // {0} price
    this.Text("Cyberbane-StreetPay-PayEbKeepAnEyeOut", "[Pay] {0}eb. Keep an eye out for me.");
    this.Text("Cyberbane-StreetPay-AlreadyToldYouISawNothing", "Already told you. I saw nothing.");
    this.Text("Cyberbane-StreetPay-ThatSNotEnoughToForget", "That's not enough to forget a face.");
    this.Text("Cyberbane-StreetPay-ComeBackWithTheEddiesOr", "Come back with the eddies. Or don't.");
    this.Text("Cyberbane-StreetPay-SawWhatIWasLookingAt", "Saw what? I was looking at my phone.");
    this.Text("Cyberbane-StreetPay-NeverSeenYouBeforeInMy", "Never seen you before in my life.");
    this.Text("Cyberbane-StreetPay-EddiesSpendTheSameAsGang", "Eddies spend the same as gang money. Better, even.");
    this.Text("Cyberbane-StreetPay-IVeGotABadMemory", "I've got a bad memory. Always have.");
    this.Text("Cyberbane-StreetPay-IMNotSayingAnythingTo", "I'm not saying anything to anybody!");
    this.Text("Cyberbane-StreetPay-OkayOkayIDidnTSee", "Okay! Okay. I didn't see a thing.");
    this.Text("Cyberbane-StreetPay-ISwearIMNotTelling", "I swear, I'm not telling anybody.");
    this.Text("Cyberbane-StreetPay-PleaseIVeGotKidsI", "Please. I've got kids. I saw nothing.");
    this.Text("Cyberbane-StreetPay-UnderstoodUnderstood", "Understood. Understood!");
    this.Text("Cyberbane-StreetPay-GetAwayFromMeTheyLl", "Get away from me! They'll hear about this!");
    this.Text("Cyberbane-StreetPay-YouDonTScareMeThey", "You don't scare me. They will.");
    this.Text("Cyberbane-StreetPay-TouchMeAndEverybodyHearsIt", "Touch me and everybody hears it twice as fast.");
    this.Text("Cyberbane-StreetPay-EyesCostMoneyChoom", "Eyes cost money, choom.");
    this.Text("Cyberbane-StreetPay-ComeBackWhenYouCanPay", "Come back when you can pay.");
    // {0} hours
    this.Text("Cyberbane-StreetPay-DealAnybodyComesLookingForYou", "Deal. Anybody comes looking for you round here in the next {0} hours, you'll hear it from me first.");
    this.Text("Cyberbane-StreetPay-ISeeEverythingOnThisBlock", "I see everything on this block anyway. Now you'll see it too.");
    this.Text("Cyberbane-StreetPay-YouGotItILlText", "You got it. I'll text you the second somebody bad turns the corner.");
    this.Text("Cyberbane-StreetPay-Trouble", "Trouble");
    // {0} coming
    this.Text("Cyberbane-StreetPay-JustTurnedOntoTheBlockLooking", "{0} just turned onto the block. Looking for you.");
    // {0} coming
    this.Text("Cyberbane-StreetPay-HeadsUpHeadedYourWay", "Heads up. {0}, headed your way.");
    // {0} coming
    this.Text("Cyberbane-StreetPay-YouPaidMeToWatchI", "You paid me to watch. I'm watching {0} walk right up to you. Move.");
    // {0} coming
    this.Text("Cyberbane-StreetPay-SawAskingAboutYouTwoMinutes", "Saw {0} asking about you two minutes ago. Thought you'd want to know.");
  }

  // ---- StreetTalk ------------------------------------------------------------------------------------------
  protected func DefineStreetTalk() -> Void {
    this.Text("Cyberbane-StreetTalk-VReachedForAWeaponA", "V reached for a weapon a moment ago");
    this.Text("Cyberbane-StreetTalk-PutYourWeaponAwayToTalk", "put your weapon away to talk to people. Look at somebody up close with empty hands and the choices come up.");
    this.Text("Cyberbane-StreetTalk-Talk", "Talk");
    this.Text("Cyberbane-StreetTalk-YourLoss", "Your loss.");
    this.Text("Cyberbane-StreetTalk-SuitYourself", "Suit yourself.");
    this.Text("Cyberbane-StreetTalk-MoveAlong", "Move along.");
    this.Text("Cyberbane-StreetTalk-NotNowKeepWalking", "Not now. Keep walking.");
    this.Text("Cyberbane-StreetTalk-KeepWalkingMerc", "Keep walking, merc.");
    this.Text("Cyberbane-StreetTalk-NotTalkingToYouMove", "Not talking to you. Move.");
    this.Text("Cyberbane-StreetTalk-WrongStreetToStopOn", "Wrong street to stop on.");
    this.Text("Cyberbane-StreetTalk-TheyAreHereForYouThere", "they are here for you. There is nothing to talk about.");
    this.Text("Cyberbane-StreetTalk-TheyAreARivalSPeople", "they are a Rival's people, on the Rival's own ground. Words will not settle this.");
    this.Text("Cyberbane-StreetTalk-TheyArePartOfAJob", "they are part of a job, so they will not talk.");
    this.Text("Cyberbane-StreetTalk-TheyBelongToAStorySo", "they belong to a story, so Cyberbane leaves them be.");
    this.Text("Cyberbane-StreetTalk-MaxTacDoesNotTalk", "MaxTac does not talk.");
    this.Text("Cyberbane-StreetTalk-TheyOrSomethingBesideThemHave", "they, or something beside them, have a prompt of their own on F (their own conversation, a door, a seat, an item). Use it, or step to one side and look at them again.");
    // {0} prompt.title, {1} first, {2} ArraySize(prompt.choices)
    this.Text("Cyberbane-StreetTalk-ChoiceS", "\"{0}\" / \"{1}\", {2} choice(s)");
    this.Text("Cyberbane-StreetTalk-HolsterToTalk", "Holster to talk");
    this.Text("Cyberbane-StreetTalk-JustSpokeToThem", "Just spoke to them");
    this.Text("Cyberbane-StreetTalk-BusyFighting", "Busy fighting");
    this.Text("Cyberbane-StreetTalk-NotWhileYouReInA", "Not while you're in a fight");
    this.Text("Cyberbane-StreetTalk-RunningFromYou", "Running from you");
    this.Text("Cyberbane-StreetTalk-PartOfAJob", "Part of a job");
    this.Text("Cyberbane-StreetTalk-HostileGroundStepOutFirst", "Hostile ground: step out first");
    this.Text("Cyberbane-StreetTalk-HostileToYou", "Hostile to you");
    this.Text("Cyberbane-StreetTalk-Friendly", "friendly");
    this.Text("Cyberbane-StreetTalk-AfraidOfYou", "afraid of you");
    this.Text("Cyberbane-StreetTalk-Hostile", "hostile");
    this.Text("Cyberbane-StreetTalk-KnowsYou", "knows you");
    this.Text("Cyberbane-StreetTalk-Wary", "wary");
    this.Text("Cyberbane-StreetTalk-GreetGoodToSeeYouHow", "[Greet] Good to see you. How's the crew?");
    this.Text("Cyberbane-StreetTalk-GreetHeyThere", "[Greet] Hey there.");
    this.Text("Cyberbane-StreetTalk-GreetEasyIMJustSaying", "[Greet] Easy. I'm just saying hi.");
    this.Text("Cyberbane-StreetTalk-CoolEasyNobodyNeedsToBleed", "[Cool] Easy. Nobody needs to bleed today.");
    this.Text("Cyberbane-StreetTalk-ParleyEasyIMNotHere", "[Parley] Easy. I'm not here to fight.");
    this.Text("Cyberbane-StreetTalk-GreetRelaxNotHereForTrouble", "[Greet] Relax. Not here for trouble.");
    this.Text("Cyberbane-StreetTalk-GreetEveningOfficer", "[Greet] Evening, officer.");
    this.Text("Cyberbane-StreetTalk-GreetHeyChoom", "[Greet] Hey, choom.");
    this.Text("Cyberbane-StreetTalk-AskQuickQuestionOfficer", "[Ask] Quick question, officer.");
    this.Text("Cyberbane-StreetTalk-AskGotAMinute", "[Ask] Got a minute?");
    // {0} CBRivalDisplayName(sys.GetContent(), tipRival)
    this.Text("Cyberbane-StreetTalk-AmbushTipWhereSLyingLow", "[Ambush tip] Where's {0} lying low? I'll pay.");
    this.Text("Cyberbane-StreetTalk-IntimidateYouWorkForMeNow", "[Intimidate] You work for me now.");
    this.Text("Cyberbane-StreetTalk-AskNeedAnythingDone", "[Ask] Need anything done?");
    this.Text("Cyberbane-StreetTalk-DealLetSTalkBusiness", "[Deal] Let's talk business.");
    this.Text("Cyberbane-StreetTalk-DismissCatchYouLater", "[Dismiss] Catch you later.");
    this.Text("Cyberbane-StreetTalk-DismissGetLost", "[Dismiss] Get lost.");
    this.Text("Cyberbane-StreetTalk-DismissOutOfMyWay", "[Dismiss] Out of my way.");
    this.Text("Cyberbane-StreetTalk-DismissNotNow", "[Dismiss] Not now.");
    this.Text("Cyberbane-StreetTalk-AntagonizeShouldnTYouBeEating", "[Antagonize] Shouldn't you be eating a donut somewhere?");
    this.Text("Cyberbane-StreetTalk-AntagonizeWhatAreYouLookingAt", "[Antagonize] What are you looking at?");
    this.Text("Cyberbane-StreetTalk-AntagonizeYourBossKnowYouRe", "[Antagonize] Your boss know you're this soft?");
    this.Text("Cyberbane-StreetTalk-AntagonizeBoo", "[Antagonize] Boo.");
    this.Text("Cyberbane-StreetTalk-AntagonizeYourCrewSAJoke", "[Antagonize] Your crew's a joke.");
    this.Text("Cyberbane-StreetTalk-AntagonizeGotAProblem", "[Antagonize] Got a problem?");
    this.Text("Cyberbane-StreetTalk-IntimidateBackOffBadge", "[Intimidate] Back off, badge.");
    // {0} t.leadName
    this.Text("Cyberbane-StreetTalk-IntimidateWhereSHidingTalk", "[Intimidate] Where's {0} hiding? Talk.");
    this.Text("Cyberbane-StreetTalk-LeaveNotWorthIt", "[Leave] Not worth it.");
    this.Text("Cyberbane-StreetTalk-LeaveTakeItEasy", "[Leave] Take it easy.");
    this.Text("Cyberbane-StreetTalk-LeaveForgetIt", "[Leave] Forget it.");
    this.Text("Cyberbane-StreetTalk-WantToEndUpLikeThe", "Want to end up like the last ones?");
    this.Text("Cyberbane-StreetTalk-YouNeverSawMeKeepIt", "You never saw me. Keep it that way.");
    this.Text("Cyberbane-StreetTalk-ThisDoesnTHaveToGet", "This doesn't have to get ugly. Walk.");
    this.Text("Cyberbane-StreetTalk-SeeTheseWalkAway", "See these? Walk away.");
    this.Text("Cyberbane-StreetTalk-ICouldCookYourImplantsFrom", "I could cook your implants from here.");
    this.Text("Cyberbane-StreetTalk-IDonTNeedAGun", "I don't need a gun for you.");
    this.Text("Cyberbane-StreetTalk-WalkAwayNow", "Walk away. Now.");
    this.Text("Cyberbane-StreetTalk-MoveAlongCitizen", "Move along, citizen.");
    this.Text("Cyberbane-StreetTalk-KeepItCleanTonight", "Keep it clean tonight.");
    this.Text("Cyberbane-StreetTalk-MhmDonTMakeMeRun", "Mhm. Don't make me run your ID.");
    this.Text("Cyberbane-StreetTalk-HHiIDonTWant", "H-hi. I don't want any trouble.");
    this.Text("Cyberbane-StreetTalk-PleaseIMJustGoingHome", "Please, I'm just going home.");
    this.Text("Cyberbane-StreetTalk-OkayOkayHi", "Okay. Okay. Hi.");
    // {0} gift
    this.Text("Cyberbane-StreetTalk-NoWayItSYouHere", "No way. It's you. Here, drinks are on me. {0}eb.");
    // {0} gift
    this.Text("Cyberbane-StreetTalk-WaitTillITellEveryoneTake", "Wait till I tell everyone. Take this, {0}eb, for the stories.");
    // {0} gift
    this.Text("Cyberbane-StreetTalk-YouReTheRealThingHere", "You're the real thing. Here, {0}eb. Don't argue.");
    // {0} title
    this.Text("Cyberbane-StreetTalk-NoWaySayingHiToMe", "No way. {0}, saying hi to me?");
    // {0} title
    this.Text("Cyberbane-StreetTalk-WaitTillITellEveryone", "Wait till I tell everyone. {0}!");
    this.Text("Cyberbane-StreetTalk-HeyBigFanSeriously", "Hey! Big fan. Seriously.");
    this.Text("Cyberbane-StreetTalk-HeyGoodToSeeYouAround", "Hey! Good to see you around.");
    this.Text("Cyberbane-StreetTalk-EveningStaySafeOutThere", "Evening. Stay safe out there.");
    this.Text("Cyberbane-StreetTalk-HeardGoodThingsAboutYou", "Heard good things about you.");
    this.Text("Cyberbane-StreetTalk-YouAgain", "You again?");
    this.Text("Cyberbane-StreetTalk-BackAlreadyWhatNow", "Back already? What now?");
    this.Text("Cyberbane-StreetTalk-WeJustTalked", "We just talked.");
    this.Text("Cyberbane-StreetTalk-UhHi", "Uh. Hi.");
    this.Text("Cyberbane-StreetTalk-DoIKnowYou", "Do I know you?");
    this.Text("Cyberbane-StreetTalk-TheCrew", "the crew");
    this.Text("Cyberbane-StreetTalk-GoodToSeeYouChoom", "Good to see you, choom.");
    this.Text("Cyberbane-StreetTalk-AlwaysWelcomeHere", "Always welcome here.");
    // {0} label
    this.Text("Cyberbane-StreetTalk-YouNeedAnythingYouAsk", "You need anything, you ask {0}.");
    this.Text("Cyberbane-StreetTalk-TheBossSaysHi", "The boss says hi.");
    this.Text("Cyberbane-StreetTalk-WeGoodWeReGoodRight", "We good? We're good. Right?");
    this.Text("Cyberbane-StreetTalk-HeyYeahHiIMNot", "Hey. Yeah. Hi. I'm not looking for anything.");
    this.Text("Cyberbane-StreetTalk-DidnTSeeYouWhateverYou", "Didn't see you. Whatever you need, it's fine.");
    this.Text("Cyberbane-StreetTalk-FineWalkAwayThisTime", "Fine. Walk away. This time.");
    this.Text("Cyberbane-StreetTalk-YouVeGotNerveGoOn", "You've got nerve. Go on, before I change my mind.");
    this.Text("Cyberbane-StreetTalk-AlrightNobodyHereSawYou", "Alright. Nobody here saw you.");
    this.Text("Cyberbane-StreetTalk-YouVeGotNerveWalkingUp", "You've got nerve, walking up to me.");
    this.Text("Cyberbane-StreetTalk-KeepWalkingBeforeIChangeMy", "Keep walking before I change my mind.");
    this.Text("Cyberbane-StreetTalk-NotYourStreetNotYourFriend", "Not your street. Not your friend.");
    this.Text("Cyberbane-StreetTalk-BackAgainWhatIsItNow", "Back again? What is it now?");
    this.Text("Cyberbane-StreetTalk-YouAgainMakeItQuick", "You again. Make it quick.");
    this.Text("Cyberbane-StreetTalk-ThoughtWeWereDone", "Thought we were done.");
    this.Text("Cyberbane-StreetTalk-HeyYouReAllRightI", "Hey. You're all right, I guess.");
    this.Text("Cyberbane-StreetTalk-EveningKeepItFriendly", "Evening. Keep it friendly.");
    this.Text("Cyberbane-StreetTalk-PutItOnYourMap", " Put it on your map.");
    // {0} name, {1} CBPlacePhrase(s.district), {2} pin
    this.Text("Cyberbane-StreetTalk-SinceYouReHereHasBeen", "Since you're here: {0} has been seen {1}. Do us a favour.{2}");
    this.Text("Cyberbane-StreetTalk-WatchTheAttitude", "Watch the attitude.");
    this.Text("Cyberbane-StreetTalk-SureMoveAlong", "Sure. Move along.");
    this.Text("Cyberbane-StreetTalk-GoingIMGoing", "Going. I'm going.");
    this.Text("Cyberbane-StreetTalk-SorrySorry", "Sorry. Sorry.");
    this.Text("Cyberbane-StreetTalk-YouGotIt", "You got it.");
    this.Text("Cyberbane-StreetTalk-WhateverChoom", "Whatever, choom.");
    this.Text("Cyberbane-StreetTalk-BusyHuhFine", "Busy, huh? Fine.");
    this.Text("Cyberbane-StreetTalk-WatchYourself", "Watch yourself.");
    this.Text("Cyberbane-StreetTalk-WalkWhileYouCan", "Walk while you can.");
    this.Text("Cyberbane-StreetTalk-YeahYeah", "Yeah, yeah.");
    this.Text("Cyberbane-StreetTalk-RealFunnyMoveItBeforeI", "Real funny. Move it before I run your ID.");
    this.Text("Cyberbane-StreetTalk-KeepTalkingAndSeeWhereIt", "Keep talking and see where it gets you.");
    this.Text("Cyberbane-StreetTalk-IVeGotYourFaceNow", "I've got your face now, merc.");
    this.Text("Cyberbane-StreetTalk-LeaveMeAlone", "Leave me alone!");
    this.Text("Cyberbane-StreetTalk-IDonTWantTrouble", "I don't want trouble!");
    this.Text("Cyberbane-StreetTalk-Psycho", "Psycho!");
    this.Text("Cyberbane-StreetTalk-TheHellSYourProblem", "The hell's your problem?");
    this.Text("Cyberbane-StreetTalk-GetOutOfMyFace", "Get out of my face.");
    this.Text("Cyberbane-StreetTalk-RealToughGoBotherSomeoneElse", "Real tough. Go bother someone else.");
    this.Text("Cyberbane-StreetTalk-NotFunnyChoomNotFunnyAt", "Not funny, choom. Not funny at all.");
    this.Text("Cyberbane-StreetTalk-CarefulFriendsHaveLimits", "Careful. Friends have limits.");
    this.Text("Cyberbane-StreetTalk-SayThatAgainAndWeRe", "Say that again and we're done.");
    this.Text("Cyberbane-StreetTalk-YouReDead", "You're dead.");
    this.Text("Cyberbane-StreetTalk-BigMistake", "Big mistake.");
    this.Text("Cyberbane-StreetTalk-BeenWaitingForThis", "Been waiting for this.");
    this.Text("Cyberbane-StreetTalk-NotHereNotNowButSoon", "Not here. Not now. But soon.");
    this.Text("Cyberbane-StreetTalk-IMNotRunningFromYou", "I'm not running from you!");
    this.Text("Cyberbane-StreetTalk-EnoughENOUGH", "Enough! ENOUGH!");
    this.Text("Cyberbane-StreetTalk-OkayOkayForgetIt", "Okay, okay! Forget it!");
    this.Text("Cyberbane-StreetTalk-NotWorthItNotWorthIt", "Not worth it. Not worth it.");
    this.Text("Cyberbane-StreetTalk-WhateverYouSay", "Whatever you say.");
    this.Text("Cyberbane-StreetTalk-AlrightLetSDance", "Alright. Let's dance.");
    this.Text("Cyberbane-StreetTalk-YouPickedTheWrongOne", "You picked the wrong one.");
    this.Text("Cyberbane-StreetTalk-SayThatToMyFaceOh", "Say that to my face. Oh wait.");
    this.Text("Cyberbane-StreetTalk-KeepRunningYourMouthSeeWhat", "Keep running your mouth, see what happens.");
    this.Text("Cyberbane-StreetTalk-BigTalkWalkAway", "Big talk. Walk away.");
    this.Text("Cyberbane-StreetTalk-AnotherWordAndYouReBleeding", "Another word and you're bleeding.");
    this.Text("Cyberbane-StreetTalk-ThreateningAnOfficerBold", "Threatening an officer? Bold.");
    this.Text("Cyberbane-StreetTalk-TryThatAgainIDareYou", "Try that again. I dare you.");
    this.Text("Cyberbane-StreetTalk-OkayIMGoing", "Okay! I'm going!");
    this.Text("Cyberbane-StreetTalk-PleaseIDidnTSeeAnything", "Please, I didn't see anything!");
    this.Text("Cyberbane-StreetTalk-DonTHurtMe", "Don't hurt me!");
    this.Text("Cyberbane-StreetTalk-YeahWhateverPoser", "Yeah? Whatever, poser.");
    this.Text("Cyberbane-StreetTalk-IsThatSupposedToScareMe", "Is that supposed to scare me?");
    this.Text("Cyberbane-StreetTalk-GoPractiseOnSomeoneElse", "Go practise on someone else.");
    this.Text("Cyberbane-StreetTalk-WhoaOkayNoNeedForThat", "Whoa. Okay. No need for that, choom.");
    this.Text("Cyberbane-StreetTalk-ThatSHowYouTreatFriends", "That's how you treat friends? Noted.");
    this.Text("Cyberbane-StreetTalk-LetSSeeYouBackThat", "Let's see you back that up.");
    this.Text("Cyberbane-StreetTalk-WrongOneToPush", "Wrong one to push.");
    this.Text("Cyberbane-StreetTalk-ThatSupposedToScareMe", "That supposed to scare me?");
    this.Text("Cyberbane-StreetTalk-HeardOfYouThoughtYouD", "Heard of you. Thought you'd be scarier.");
    this.Text("Cyberbane-StreetTalk-WalkAwayWhileIMFeeling", "Walk away while I'm feeling generous.");
    // {0} paid
    this.Text("Cyberbane-StreetTalk-HereTakeItAndGo", "Here. {0}. Take it and go.");
    // {0} paid
    this.Text("Cyberbane-StreetTalk-EddiesThatSAllIGot", "{0} eddies. That's all I got, I swear.");
    // {0} paid
    this.Text("Cyberbane-StreetTalk-FineWeReSquareRight", "Fine! {0}. We're square, right?");
    this.Text("Cyberbane-StreetTalk-AlrightAlrightIMGone", "Alright, alright! I'm gone.");
    this.Text("Cyberbane-StreetTalk-IMLeavingLookIM", "I'm leaving. Look, I'm leaving.");
    this.Text("Cyberbane-StreetTalk-DidnTMeanAnythingByIt", "Didn't mean anything by it!");
    // {0} name, {1} place, {2} pin
    this.Text("Cyberbane-StreetTalk-FineSLyingLowYouDidn", "Fine! {0}'s lying low {1}. You didn't hear it from me.{2}");
    // {0} name, {1} place, {2} pin
    this.Text("Cyberbane-StreetTalk-HoledUpPleaseJustGo", "{0}? Holed up {1}. Please, just go.{2}");
    // {0} name, {1} place, {2} pin
    this.Text("Cyberbane-StreetTalk-OkayLastIHeardThatS", "Okay! {0}, {1}. Last I heard. That's all I know.{2}");
  }

  // ---- TalkTopics ------------------------------------------------------------------------------------------
  protected func DefineTalkTopics() -> Void {
    this.Text("Cyberbane-TalkTopics-AskWhatSTheWordOn", "[Ask] What's the word on the street?");
    this.Text("Cyberbane-TalkTopics-AskWhoRunsTheseStreets", "[Ask] Who runs these streets?");
    this.Text("Cyberbane-TalkTopics-AskAnyoneLookingForMe", "[Ask] Anyone looking for me?");
    this.Text("Cyberbane-TalkTopics-BackSomethingElse", "[Back] Something else.");
    // {0} price
    this.Text("Cyberbane-TalkTopics-PayEb", "[Pay] {0}eb.");
    // {0} price
    this.Text("Cyberbane-TalkTopics-PayEbForSafePassage", "[Pay] {0}eb for safe passage.");
    // {0} price
    this.Text("Cyberbane-TalkTopics-PayEbMakeTheCall", "[Pay] {0}eb. Make the call.");
    this.Text("Cyberbane-TalkTopics-HaggleThatSTooMuch", "[Haggle] That's too much.");
    // {0} (body ? "[Body] " : "[Intimidate] ")
    this.Text("Cyberbane-TalkTopics-OrYouCouldJustTellMe", "{0}Or you could just tell me.");
    this.Text("Cyberbane-TalkTopics-ForgetItNeverMind", "[Forget it] Never mind.");
    this.Text("Cyberbane-TalkTopics-PayWhatDoesItCostTo", "[Pay] What does it cost to walk your streets?");
    this.Text("Cyberbane-TalkTopics-PayCallOffTheCrewYou", "[Pay] Call off the crew you sent after me.");
    this.Text("Cyberbane-TalkTopics-BusinessYeahBusinessIsGoodWhat", "Business. Yeah. Business is good. What do you need?");
    this.Text("Cyberbane-TalkTopics-AnythingNameIt", "Anything. Name it.");
    this.Text("Cyberbane-TalkTopics-MoneyTalksGoOn", "Money talks. Go on.");
    this.Text("Cyberbane-TalkTopics-IMListening", "I'm listening.");
    this.Text("Cyberbane-TalkTopics-BusinessWithYouDependsWhatIt", "Business with you? Depends what it pays.");
    this.Text("Cyberbane-TalkTopics-NothingToSellYouNotToday", "Nothing to sell you. Not today.");
    this.Text("Cyberbane-TalkTopics-YourMoneySNoGoodHere", "Your money's no good here.");
    this.Text("Cyberbane-TalkTopics-YouCanTBuyYourWay", "You can't buy your way out of what you did.");
    // {0} price, {1} hours
    this.Text("Cyberbane-TalkTopics-EbAndNobodyOfOursTouches", "{0}eb, and nobody of ours touches you. {1} hours. After that you're fair game again.");
    // {0} price, {1} hours
    this.Text("Cyberbane-TalkTopics-WalkOurStreetsInOnePiece", "Walk our streets in one piece? {0}eb. Buys you {1} hours.");
    this.Text("Cyberbane-TalkTopics-WhatCrewNobodySComingNot", "What crew? Nobody's coming. Not from us.");
    this.Text("Cyberbane-TalkTopics-ThoseAreMyPeopleHopeThey", "Those are my people. Hope they find you.");
    this.Text("Cyberbane-TalkTopics-CallThemOffIDRather", "Call them off? I'd rather watch.");
    // {0} price
    this.Text("Cyberbane-TalkTopics-TheyReAlreadyMovingEbAnd", "They're already moving. {0}eb and I make a call.");
    // {0} price
    this.Text("Cyberbane-TalkTopics-EbAndITellThemYou", "{0}eb, and I tell them you were somewhere else.");
    this.Text("Cyberbane-TalkTopics-ComeBackWhenYouVeGot", "Come back when you've got it.");
    this.Text("Cyberbane-TalkTopics-ThatSNotTheNumberChoom", "That's not the number, choom.");
    this.Text("Cyberbane-TalkTopics-DoneWordGoesRoundYouWalk", "Done. Word goes round: you walk, nobody of ours stops you. For a while.");
    this.Text("Cyberbane-TalkTopics-PleasureKeepYourHeadDownAnd", "Pleasure. Keep your head down and nobody of ours will lift a finger.");
    this.Text("Cyberbane-TalkTopics-TooLateOrTheyNeverLeft", "Too late, or they never left. Keep your eddies.");
    this.Text("Cyberbane-TalkTopics-AlrightILlTellThemYou", "Alright. I'll tell them you weren't where they thought. Don't make me regret it.");
    this.Text("Cyberbane-TalkTopics-DoneTheyLlTurnAroundNext", "Done. They'll turn around. Next time I can't help you.");
    this.Text("Cyberbane-TalkTopics-StreetKidCameUpOnThese", "[Street Kid] Came up on these streets myself.");
    this.Text("Cyberbane-TalkTopics-NomadOutInTheBadlandsWe", "[Nomad] Out in the Badlands, we look after our own.");
    this.Text("Cyberbane-TalkTopics-CorpoIKnowHowYourBosses", "[Corpo] I know how your bosses think.");
    this.Text("Cyberbane-TalkTopics-MakeItQuickCitizen", "Make it quick, citizen.");
    this.Text("Cyberbane-TalkTopics-DependsWhatYouReAsking", "Depends what you're asking.");
    this.Text("Cyberbane-TalkTopics-SureChoomWhatDoYouNeed", "Sure, choom. What do you need?");
    this.Text("Cyberbane-TalkTopics-ForYouAlways", "For you? Always.");
    this.Text("Cyberbane-TalkTopics-WWhatDoYouWantTo", "W-what do you want to know?");
    this.Text("Cyberbane-TalkTopics-IDonTKnowAnythingI", "I don't know anything. I mean, ask.");
    this.Text("Cyberbane-TalkTopics-OkayOkayWhat", "Okay. Okay. What?");
    this.Text("Cyberbane-TalkTopics-TalkFast", "Talk fast.");
    this.Text("Cyberbane-TalkTopics-YouVeGotAMinuteLess", "You've got a minute. Less.");
    this.Text("Cyberbane-TalkTopics-MakeItQuick", "Make it quick.");
    this.Text("Cyberbane-TalkTopics-WhatAbout", "What about?");
    this.Text("Cyberbane-TalkTopics-ToldYouAlreadyThatSAll", "Told you already. That's all I've got.");
    this.Text("Cyberbane-TalkTopics-YouReStandingOnItThat", "You're standing on it. That's where they found them all. Still gives me chills.");
    this.Text("Cyberbane-TalkTopics-RightHereBodiesEverywhereNotLong", "Right here. Bodies everywhere, not long ago. Nobody's been the same.");
    // {0} CBCapFirst(CBFactionLabel(st.placeGang))
    this.Text("Cyberbane-TalkTopics-ThisCornerLostTheirBossRight", "This corner? {0} lost their boss right there. Still raw.");
    this.Text("Cyberbane-TalkTopics-WordIsYouReBleedingChoom", "Word is you're bleeding, choom. Get that seen to before somebody finishes the job.");
    this.Text("Cyberbane-TalkTopics-TheWordIsThereSBlood", "The word is there's blood on your jacket. People notice that.");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-TalkTopics-ArePushingInRoundHereWon", "{0} are pushing in round here. Won't be quiet much longer.");
    this.Text("Cyberbane-TalkTopics-QuietLatelyTooQuiet", "Quiet lately. Too quiet.");
    this.Text("Cyberbane-TalkTopics-NothingPeopleKeepWaitingForSomething", "Nothing. People keep waiting for something to happen.");
    this.Text("Cyberbane-TalkTopics-SameOldNightCitySomebodyS", "Same old Night City. Somebody's always bleeding.");
    this.Text("Cyberbane-TalkTopics-NothingWorthTheBreath", "Nothing worth the breath.");
    this.Text("Cyberbane-TalkTopics-CorposUpTopTheRestOf", "Corpos up top, the rest of us down here. Same as always.");
    this.Text("Cyberbane-TalkTopics-SameAsFiveMinutesAgo", "Same as five minutes ago.");
    this.Text("Cyberbane-TalkTopics-NobodyOwnsTheseStreetsNotReally", "Nobody owns these streets. Not really.");
    this.Text("Cyberbane-TalkTopics-DependsWhoSGotTheMost", "Depends who's got the most guns tonight.");
    this.Text("Cyberbane-TalkTopics-WeDoDonTForgetIt", "We do. Don't forget it.");
    this.Text("Cyberbane-TalkTopics-YouReStandingOnOurs", "You're standing on ours.");
    // {0} CBCapFirst(label)
    this.Text("Cyberbane-TalkTopics-RunIt", "{0} run it.");
    this.Text("Cyberbane-TalkTopics-WhatSLeftOfThemAnyway", " What's left of them, anyway.");
    this.Text("Cyberbane-TalkTopics-TheyReBleedingThoughEverybodyCan", " They're bleeding, though. Everybody can see it.");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-TalkTopics-WantIt", " {0} want it.");
    this.Text("Cyberbane-TalkTopics-TheyLikeYouFarAsI", " They like you, far as I hear.");
    this.Text("Cyberbane-TalkTopics-AndTheyWantYouDeadSo", " And they want you dead, so.");
    this.Text("Cyberbane-TalkTopics-LikeISaidWatchYourself", "Like I said. Watch yourself.");
    this.Text("Cyberbane-TalkTopics-ACrewOfGIsOn", "A crew of %g is on its way to you. Minutes, maybe less.");
    this.Text("Cyberbane-TalkTopics-GAreSendingTheirBestAfter", "%G are sending their best after you. Real soon.");
    this.Text("Cyberbane-TalkTopics-AnyMinuteNow", "Any minute now.");
    // {0} when
    this.Text("Cyberbane-TalkTopics-GArePuttingACrewTogether", "%G are putting a crew together for you. {0}");
    // {0} CBRivalDisplayName(content, r)
    this.Text("Cyberbane-TalkTopics-IsGettingReadyToComeFor", "{0} is getting ready to come for you.");
    // {0} CBRivalDisplayName(content, r)
    this.Text("Cyberbane-TalkTopics-IsOutLookingForYouAsking", "{0} is out looking for you. Asking around.");
    // {0} CBRivalDisplayName(content, r)
    this.Text("Cyberbane-TalkTopics-HeardWantsAWordWithYou", "Heard {0} wants a word with you. Not a nice one.");
    this.Text("Cyberbane-TalkTopics-NobodyIVeHeardOfLucky", "Nobody I've heard of. Lucky you.");
    this.Text("Cyberbane-TalkTopics-NotThatIKnowDoesnT", "Not that I know. Doesn't mean nobody is.");
    this.Text("Cyberbane-TalkTopics-QuietFarAsIHear", "Quiet, far as I hear.");
    this.Text("Cyberbane-TalkTopics-Somebody", "somebody");
    this.Text("Cyberbane-TalkTopics-OursAreComingForYouYou", "Ours are coming for you. You didn't hear it from me.");
    this.Text("Cyberbane-TalkTopics-YouLlFindOut", "You'll find out.");
    this.Text("Cyberbane-TalkTopics-ISaidWhatISaid", "I said what I said.");
    this.Text("Cyberbane-TalkTopics-HavenTHeardAThingWorth", "Haven't heard a thing worth selling.");
    this.Text("Cyberbane-TalkTopics-NobodySTalkingAboutThemNot", "Nobody's talking about them. Not to me.");
    this.Text("Cyberbane-TalkTopics-AlreadySaidTooMuchToday", "Already said too much today.");
    this.Text("Cyberbane-TalkTopics-AskMeTomorrowTooManyEars", "Ask me tomorrow. Too many ears around.");
    this.Text("Cyberbane-TalkTopics-HeardYouVeBeenAskingAbout", "Heard you've been asking about me. Here I am. Come find out.");
    this.Text("Cyberbane-TalkTopics-OneOfMineSaysYouWere", "One of mine says you were asking. Bad idea.");
    this.Text("Cyberbane-TalkTopics-IDonTSellOutMy", "I don't sell out my own.");
    this.Text("Cyberbane-TalkTopics-AskMeAgainAndSeeWhat", "Ask me again and see what happens.");
    this.Text("Cyberbane-TalkTopics-YouThinkIDRatWalk", "You think I'd rat? Walk away.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-ForYouEddiesFirst", "For you? {0}. Eddies first.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-AndIRememberEverything", "{0} and I remember everything.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-SellingOutMyOwnCosts", "Selling out my own costs. {0}.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-AndYouNeverHeardMyName", "{0}, and you never heard my name.");
    // {0} name, {1} p
    this.Text("Cyberbane-TalkTopics-YeahIKnowWhere", "{0}? Yeah, I know where. {1}.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-ThatOneAndTheyReYours", "That one? {0} and they're yours.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-WorthEveryEddieTrustMe", "{0}. Worth every eddie, trust me.");
    // {0} name
    this.Text("Cyberbane-TalkTopics-ThatOneWhoSoldYouS", "That one who sold you {0}'s hiding place? Sold you a story. Nobody's been there.");
    // {0} name, {1} CBPlacePhrase(fake)
    this.Text("Cyberbane-TalkTopics-SHoledUpSwearIt", "{0}'s holed up {1}. Swear it.");
    // {0} name, {1} CBPlacePhrase(fake)
    this.Text("Cyberbane-TalkTopics-LastIHeardWasGoLook", "Last I heard, {0} was {1}. Go look.");
    this.Text("Cyberbane-TalkTopics-TheyMoveAroundCanTPin", "They move around. Can't pin them for you, not today.");
    // {0} name, {1} place, {2} pin
    this.Text("Cyberbane-TalkTopics-SHoledUp", "{0}'s holed up {1}.{2}");
    // {0} name, {1} place, {2} pin
    this.Text("Cyberbane-TalkTopics-LyingLowDonTSayWhere", "{0}? Lying low {1}. Don't say where you heard it.{2}");
    // {0} name, {1} place, {2} pin
    this.Text("Cyberbane-TalkTopics-SawLastNight", "Saw {0} {1}. Last night.{2}");
    // {0} name
    this.Text("Cyberbane-TalkTopics-HeardYouReAfterIMight", "Heard you're after {0}. I might know where they're lying low. For a price.");
    // {0} name
    this.Text("Cyberbane-TalkTopics-YouReTheOneLookingFor", "You're the one looking for {0}, right? I know a thing or two. Costs, though.");
    // {0} name
    this.Text("Cyberbane-TalkTopics-WordIsYouWantICould", "Word is you want {0}. I could help with that, if you make it worth my while.");
    this.Text("Cyberbane-TalkTopics-ForgetItNothingToSellAnymore", "Forget it. Nothing to sell anymore.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-FineDonTPushIt", "Fine. {0}. Don't push it.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-AlrightAlright", "Alright, alright. {0}.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-FinalOffer", "{0}. Final offer.");
    this.Text("Cyberbane-TalkTopics-ForgetItDealSOff", "Forget it. Deal's off.");
    this.Text("Cyberbane-TalkTopics-YouKnowWhatFindOutYourself", "You know what? Find out yourself.");
    // {0} p
    this.Text("Cyberbane-TalkTopics-NowItSWantToTry", "Now it's {0}. Want to try again?");
    this.Text("Cyberbane-TalkTopics-TakeItOrLeaveIt", "Take it or leave it.");
    this.Text("Cyberbane-TalkTopics-ThatSThePriceNotA", "That's the price. Not a cent less.");
    this.Text("Cyberbane-TalkTopics-NothingToTellAnymore", "Nothing to tell anymore.");
    this.Text("Cyberbane-TalkTopics-NiceTryPriceJustWentTo", "Nice try. Price just went to nothing, because you get nothing.");
    this.Text("Cyberbane-TalkTopics-ThreatenMeAgainGoOn", "Threaten me again. Go on.");
    this.Text("Cyberbane-TalkTopics-ThatSNotHowThisWorks", "That's not how this works.");
    this.Text("Cyberbane-TalkTopics-ANomadShouldVeGuessedFrom", "A nomad. Should've guessed from the smell.");
    this.Text("Cyberbane-TalkTopics-YourClanIsnTWelcomeHere", "Your clan isn't welcome here, nomad.");
    this.Text("Cyberbane-TalkTopics-YeahThenYouKnowHowIt", "Yeah? Then you know how it works round here.");
    this.Text("Cyberbane-TalkTopics-HuhThoughtYouLookedFamiliar", "Huh. Thought you looked familiar.");
    this.Text("Cyberbane-TalkTopics-StreetKidHuhRespect", "Street kid, huh. Respect.");
    this.Text("Cyberbane-TalkTopics-FamilySFamilyYouNeedAnything", "Family's family. You need anything, you come to us.");
    this.Text("Cyberbane-TalkTopics-TheRoadBroughtYouBackHuh", "The road brought you back, huh? Good.");
    this.Text("Cyberbane-TalkTopics-ThenYouKnowTheyDSell", "Then you know they'd sell us both out for a quarter point. Fine. We talk.");
    this.Text("Cyberbane-TalkTopics-ExCorpoDidnTThinkYou", "Ex-corpo. Didn't think you'd get it. Maybe you do.");
  }

  // ---- Witnesses -------------------------------------------------------------------------------------------
  protected func DefineWitnesses() -> Void {
    this.Text("Cyberbane-Witnesses-Them", "them");
    this.Text("Cyberbane-Witnesses-Witness", "Witness");
    // {0} gang
    this.Text("Cyberbane-Witnesses-OhThatWasOneOfThey", "Oh, that was one of {0}. They're gonna want to know about this.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Witnesses-ISawThatISawYour", "I saw that. I saw your face. {0} pay for faces.");
    // {0} gang
    this.Text("Cyberbane-Witnesses-SomebodySGotToTellMight", "Somebody's got to tell {0}. Might as well be me.");
    // {0} gang
    this.Text("Cyberbane-Witnesses-NobodySawNothingRightWrongI", "Nobody saw nothing, right? Wrong. I'm telling {0}.");
    // {0} gang, {1} where
    this.Text("Cyberbane-Witnesses-SomebodyRanToTheyKnowYou", "Somebody ran to {0}. They know you were in {1}.");
    // {0} gang
    this.Text("Cyberbane-Witnesses-SomebodyRanToTheyKnowIt", "Somebody ran to {0}. They know it was you.");
    this.Text("Cyberbane-Witnesses-THEM", "THEM");
    // {0} (StrLen(who) > 0 ? who : "THEM"), {1} StrUpper(CBTimeText(left))
    this.Text("Cyberbane-Witnesses-AWITNESSISRUNNINGTO", "A WITNESS IS RUNNING TO {0}   -   {1}");
  }

  // ---- Births ----------------------------------------------------------------------------------------------
  protected func DefineBirths() -> Void {
    // {0} name
    this.Text("Cyberbane-Births-HasYourNameNowThatIs", "{0} has your name now. That is on you.");
    // {0} b.predecessor
    this.Text("Cyberbane-Births-YouPutInTheGroundFamily", "You put {0} in the ground. Family doesn't forget. I know how you fight now.");
    // {0} name
    this.Text("Cyberbane-Births-WalkedAwayFromYouBreathingThey", "{0} walked away from you breathing. They will not forget it.");
    // {0} name
    this.Text("Cyberbane-Births-GotClearOfYouYouHave", "{0} got clear of you. You have not seen the last of them.");
    // {0} name, {1} b.predecessor
    this.Text("Cyberbane-Births-PicksUpWhereLeftOff", "{0} picks up where {1} left off.");
  }

  // ---- DeathLedger -----------------------------------------------------------------------------------------
  protected func DefineDeathLedger() -> Void {
    // {0} CBRivalDisplayName(content, created)
    this.Text("Cyberbane-DeathLedger-PutYouInTheGroundOnce", "{0} put you in the ground once. Remember that next time.");
  }

  // ---- Hierarchy -------------------------------------------------------------------------------------------
  protected func DefineHierarchy() -> Void {
    this.Text("Cyberbane-Hierarchy-LEADER", "LEADER");
    this.Text("Cyberbane-Hierarchy-LT", "LT");
    this.Text("Cyberbane-Hierarchy-LIEUTENANT", "LIEUTENANT");
    // {0} CBRivalDisplayName(content, heir)
    this.Text("Cyberbane-Hierarchy-RunsUsNowNothingAboutYou", "{0} runs us now. Nothing about you has changed.");
    this.Text("Cyberbane-Hierarchy-Burned", "burned");
    this.Text("Cyberbane-Hierarchy-Fried", "fried");
    this.Text("Cyberbane-Hierarchy-CutUp", "cut up");
    this.Text("Cyberbane-Hierarchy-ShotUp", "shot up");
  }

  // ---- RivalLife -------------------------------------------------------------------------------------------
  protected func DefineRivalLife() -> Void {
    this.Text("Cyberbane-RivalLife-TheVoicesKnowYourName", "The voices know your name.");
    this.Text("Cyberbane-RivalLife-CanTStopWonTStop", "Can't stop. Won't stop. Hear it?");
    this.Text("Cyberbane-RivalLife-EverythingSSoLoudYouFirst", "Everything's so loud. You first.");
    this.Text("Cyberbane-RivalLife-IWatchedYourBackIKnow", "I watched your back. I know where it's soft.");
    this.Text("Cyberbane-RivalLife-YouNeverPaidMeWhatI", "You never paid me what I was worth.");
    this.Text("Cyberbane-RivalLife-ILearnedEverythingFromYouIncluding", "I learned everything from you. Including this.");
    this.Text("Cyberbane-RivalLife-BloodPaysForBlood", "Blood pays for blood.");
    this.Text("Cyberbane-RivalLife-ICarryThemWithMeEvery", "I carry them with me. Every step.");
    this.Text("Cyberbane-RivalLife-YouTookOneOfOursI", "You took one of ours. I'm taking you.");
    this.Text("Cyberbane-RivalLife-YouShouldHaveFinishedIt", "You should have finished it.");
    this.Text("Cyberbane-RivalLife-MercySTheLastMistakeYou", "Mercy's the last mistake you'll make.");
    this.Text("Cyberbane-RivalLife-IWokeUpYouWonT", "I woke up. You won't.");
    this.Text("Cyberbane-RivalLife-LieDownYouKnowHowThis", "Lie down. You know how this goes.");
    this.Text("Cyberbane-RivalLife-AgainFineSameEnding", "Again? Fine. Same ending.");
    this.Text("Cyberbane-RivalLife-IVeDoneThisBefore", "I've done this before.");
    this.Text("Cyberbane-RivalLife-NobodyWalksAwayFromMeTwice", "Nobody walks away from me twice.");
    this.Text("Cyberbane-RivalLife-MyStreetMyRulesMyKill", "My street. My rules. My kill.");
    this.Text("Cyberbane-RivalLife-YouReJustAStoryThey", "You're just a story they tell. I'm the ending.");
    this.Text("Cyberbane-RivalLife-StillBreathingBetThatBugsYou", "Still breathing. Bet that bugs you.");
    this.Text("Cyberbane-RivalLife-EveryScarSAPromise", "Every scar's a promise.");
    this.Text("Cyberbane-RivalLife-IKeepComingBackYouKeep", "I keep coming back. You keep running out of luck.");
    this.Text("Cyberbane-RivalLife-NothingPersonalJustBusiness", "Nothing personal. Just business.");
    this.Text("Cyberbane-RivalLife-NightCitySTooSmallFor", "Night City's too small for both of us.");
    this.Text("Cyberbane-RivalLife-YouMadeItPersonal", "You made it personal.");
    this.Text("Cyberbane-RivalLife-WaitingForYouAtTheirPlace", "Waiting for you at their place, ready. The street knows you called them out.");
    this.Text("Cyberbane-RivalLife-OwesYouTheirLifeAndKnows", "Owes you their life, and knows it. Keeps their head down.");
    this.Text("Cyberbane-RivalLife-LeftNightCityNobodyExpectsThem", "Left Night City. Nobody expects them back.");
    this.Text("Cyberbane-RivalLife-DeadPeopleStillTalkAboutHow", "Dead. People still talk about how.");
    this.Text("Cyberbane-RivalLife-GoneQuietNobodySSeenThem", "Gone quiet. Nobody's seen them in a while.");
    this.Text("Cyberbane-RivalLife-OutLookingForYouAskingEverybody", "Out looking for you. Asking everybody where you sleep.");
    this.Text("Cyberbane-RivalLife-GettingTheirPeopleTogetherYouLl", "Getting their people together. You'll hear from them soon.");
    // {0} CBWhen(r.huntTicks)
    this.Text("Cyberbane-RivalLife-LickingTheirWoundsBack", "Licking their wounds. Back {0}.");
    this.Text("Cyberbane-RivalLife-AroundKeepingTheirEarsOpenFor", "Around. Keeping their ears open for your name.");
    this.Text("Cyberbane-RivalLife-ThatSThem", "That's them!");
    // {0} name
    this.Text("Cyberbane-RivalLife-ThatSTheOnePutDown", "That's the one {0} put down before!");
    // {0} name
    this.Text("Cyberbane-RivalLife-ThatSThemTheOneWalked", "That's them. The one {0} walked away from.");
    // {0} name
    this.Text("Cyberbane-RivalLife-ThatSWhoDidItWants", "That's who did it. {0} wants them.");
    this.Text("Cyberbane-RivalLife-NowhereNearHereTheyWouldAgree", "nowhere near here they would agree to meet. Try somewhere else.");
    // {0} CBCapFirst(place), {1} meant, {2} pin, {3} CBRivalCatchphrase(r)
    this.Text("Cyberbane-RivalLife-YouAndMeILlBe", "You and me. {0}.{1} I'll be waiting.{2} {3}");
    // {0} CBCapFirst(place), {1} pin, {2} CBRivalCatchphrase(r)
    this.Text("Cyberbane-RivalLife-GotYourMessageComeAndTry", "Got your message. {0}. Come and try.{1} {2}");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-RivalLife-TheyNamedThePlaceAndYou", "They named the place, and you went. {0} didn't walk away from it.");
    this.Text("Cyberbane-RivalLife-SpareWalkAwayNextTimeI", "[Spare] Walk away. Next time I won't stop.");
    // {0} CBRivalDisplayName(sys.GetContent(), other)
    this.Text("Cyberbane-RivalLife-CollectYouOweMeYourLife", "[Collect] You owe me your life. Where's {0}?");
    this.Text("Cyberbane-RivalLife-ExileLeaveNightCityTonightDon", "[Exile] Leave Night City. Tonight. Don't come back.");
    this.Text("Cyberbane-RivalLife-HumiliateLookAtYouCrawlingEverybody", "[Humiliate] Look at you. Crawling. Everybody's going to hear about this.");
    // {0} CBRivalDisplayName(sys.GetContent(), target)
    this.Text("Cyberbane-RivalLife-SetOnIsTheOneYou", "[Set on] {0} is the one you want. I know where they sleep.");
    this.Text("Cyberbane-RivalLife-NotYetStayDownIHaven", "[Not yet] Stay down. I haven't decided.");
    this.Text("Cyberbane-RivalLife-OkayOkayIMGoneYou", "Okay. Okay. I'm gone. You'll never see me again.");
    this.Text("Cyberbane-RivalLife-FineNightCitySYoursI", "Fine. Night City's yours. I'm done.");
    this.Text("Cyberbane-RivalLife-ThisIsMyCityILl", "This is my city. I'll crawl back if I have to.");
    this.Text("Cyberbane-RivalLife-RunFromYouNever", "Run? From you? Never.");
    this.Text("Cyberbane-RivalLife-IDonTKnowAnythingWorth", "I don't know anything worth my life. I swear.");
    // {0} CBIntelSpoken(i)
    this.Text("Cyberbane-RivalLife-WeReEven", "{0} We're even.");
    // {0} CBRivalCatchphrase(r)
    this.Text("Cyberbane-RivalLife-IWonTForgetThis", "...I won't forget this. {0}");
    this.Text("Cyberbane-RivalLife-WhyDoesnTMatterIOwe", "Why? ...Doesn't matter. I owe you.");
  }

  // ---- RivalMoments ----------------------------------------------------------------------------------------
  protected func DefineRivalMoments() -> Void {
    this.Text("Cyberbane-RivalMoments-SubdermalArmour", "subdermal armour");
    this.Text("Cyberbane-RivalMoments-DermalPlating", "dermal plating");
    this.Text("Cyberbane-RivalMoments-AFirewall", "a firewall");
    this.Text("Cyberbane-RivalMoments-ReinforcedTendons", "reinforced tendons");
    this.Text("Cyberbane-RivalMoments-SmokeFilterOptics", "smoke-filter optics");
    this.Text("Cyberbane-RivalMoments-CouldnTFinishItForThem", "Couldn't... finish it. For them.");
    this.Text("Cyberbane-RivalMoments-TellMyFamilyITried", "Tell my family... I tried.");
    this.Text("Cyberbane-RivalMoments-SameAsThemSameAsThem", "Same as them. Same... as them.");
    this.Text("Cyberbane-RivalMoments-BeatYouOnceNobodyCanTake", "Beat you once. Nobody... can take that.");
    this.Text("Cyberbane-RivalMoments-ShouldVeStayedDownTheFirst", "Should've stayed down... the first time.");
    this.Text("Cyberbane-RivalMoments-LuckyYouGotLucky", "Lucky. You got... lucky.");
    this.Text("Cyberbane-RivalMoments-RanOutOfRoad", "Ran out of road.");
    this.Text("Cyberbane-RivalMoments-ThoughtIDAlwaysGetAway", "Thought I'd always... get away.");
    this.Text("Cyberbane-RivalMoments-EveryTimeButThisOne", "Every time... but this one.");
    this.Text("Cyberbane-RivalMoments-YouLetMeLiveShouldVe", "You let me live... should've left it there.");
    this.Text("Cyberbane-RivalMoments-SecondChanceWastedIt", "Second chance... wasted it.");
    this.Text("Cyberbane-RivalMoments-MercyAndThenThis", "Mercy... and then this.");
    this.Text("Cyberbane-RivalMoments-AtLeastNobodySLaughingNow", "At least... nobody's laughing now.");
    this.Text("Cyberbane-RivalMoments-WorthItToSeeYourFace", "Worth it... to see your face.");
    this.Text("Cyberbane-RivalMoments-ToldYouIDComeBack", "Told you... I'd come back.");
    this.Text("Cyberbane-RivalMoments-NightCityRemembersMe", "Night City... remembers me.");
    this.Text("Cyberbane-RivalMoments-NotLikeThis", "Not like this...");
    this.Text("Cyberbane-RivalMoments-YouLlSeeMeAgain", "You'll... see me again.");
    this.Text("Cyberbane-RivalMoments-IStillSmellTheSmokeBecause", "I still smell the smoke because of you!");
    this.Text("Cyberbane-RivalMoments-YouBurnedMeIDonT", "You burned me. I don't burn twice!");
    this.Text("Cyberbane-RivalMoments-RememberTheFireIDo", "Remember the fire? I do!");
    this.Text("Cyberbane-RivalMoments-StillGotYourBladeMarksCome", "Still got your blade marks. Come add some!");
    this.Text("Cyberbane-RivalMoments-CutMeOnceNotAgain", "Cut me once. Not again!");
    this.Text("Cyberbane-RivalMoments-IWearYourScarsYouLl", "I wear your scars. You'll wear mine!");
    this.Text("Cyberbane-RivalMoments-StayOutOfMyHeadThis", "Stay out of my head this time!");
    this.Text("Cyberbane-RivalMoments-FryMeAgainTryIt", "Fry me again? Try it!");
    this.Text("Cyberbane-RivalMoments-IPaidForAFirewallBecause", "I paid for a firewall because of you!");
    this.Text("Cyberbane-RivalMoments-YouRememberHowThisEnds", "You remember how this ends!");
    this.Text("Cyberbane-RivalMoments-DownYouGoAgain", "Down you go. Again.");
    this.Text("Cyberbane-RivalMoments-SameAsLastTimeMerc", "Same as last time, merc!");
    this.Text("Cyberbane-RivalMoments-CaughtYouThisTime", "Caught you this time!");
    this.Text("Cyberbane-RivalMoments-NoRunningToday", "No running today!");
    this.Text("Cyberbane-RivalMoments-YouCanTLoseMe", "You can't lose me!");
    this.Text("Cyberbane-RivalMoments-NobodyLaughsAtMeNobody", "Nobody laughs at me! Nobody!");
    this.Text("Cyberbane-RivalMoments-WhoSCrawlingNow", "Who's crawling now?!");
    this.Text("Cyberbane-RivalMoments-SayItAgainSayIt", "Say it again! Say it!");
    this.Text("Cyberbane-RivalMoments-ThisIsForMyFamily", "This is for my family.");
    this.Text("Cyberbane-RivalMoments-YouLetMeWalkLastTime", "You let me walk last time. Big mistake.");
    this.Text("Cyberbane-RivalMoments-Once", "once");
    // {0} r.escapes
    this.Text("Cyberbane-RivalMoments-Times", "{0} times");
    // {0} r.escapes == 1 ? "once" : s"\(r.escapes) times"
    this.Text("Cyberbane-RivalMoments-GotAwayFromYouNotRunning", "Got away from you {0}. Not running today.");
    this.Text("Cyberbane-RivalMoments-IStillHaveTheScarsYou", "I still have the scars you gave me.");
    // {0} name
    this.Text("Cyberbane-RivalMoments-WantsALookAtYouFirst", "{0} wants a look at you first. Talk to them to face them down, or draw.");
    this.Text("Cyberbane-RivalMoments-MyFamily", "my family");
    // {0} who
    this.Text("Cyberbane-RivalMoments-EverybodyStopIWantToLook", "Everybody stop. I want to look at the one who killed {0} before I do this.");
    // {0} you
    this.Text("Cyberbane-RivalMoments-AgainYouRememberHowThisEnded", "Again, {0}? You remember how this ended last time. Look at me first.");
    this.Text("Cyberbane-RivalMoments-YouLetMeWalkOnceHold", "You let me walk once. Hold it, everybody. I want to see if that was mercy or a mistake.");
    // {0} you
    this.Text("Cyberbane-RivalMoments-NobodyMoveLastTimeIRan", "Nobody move. Last time I ran from {0}. Not today. Today we talk first.");
    // {0} you
    this.Text("Cyberbane-RivalMoments-SoYouReDonTReach", "So you're {0}. Don't reach for it yet. I want a look at you first.");
    // {0} CBCapFirst(CBHere(sys))
    this.Text("Cyberbane-RivalMoments-YouAndMeHandsWhereI", "{0}, you and me. Hands where I can see them.");
    this.Text("Cyberbane-RivalMoments-DonTReachForItYet", "Don't reach for it yet. Look at me first.");
    this.Text("Cyberbane-RivalMoments-EverybodyStopIWantToSee", "Everybody stop. I want to see this one's face.");
    this.Text("Cyberbane-RivalMoments-BossIsGoingDownForgetThe", "Boss is going down! Forget the deal, take them!");
    // {0} name
    this.Text("Cyberbane-RivalMoments-NobodyPutsInTheGroundLight", "Nobody puts {0} in the ground. Light them up!");
    this.Text("Cyberbane-RivalMoments-ThatSEnoughFairSOver", "That's enough. Fair's over. Get them!");
    this.Text("Cyberbane-RivalMoments-WeSaidWeDStayOut", "We said we'd stay out. We lied. Drop them!");
    this.Text("Cyberbane-RivalMoments-ThatSNotHowThisWorks", "That's not how this works! Get them!");
    this.Text("Cyberbane-RivalMoments-NoRulesThenLightThemUp", "No rules then. Light them up!");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-RivalMoments-AskedForAFairFightAnd", "{0} asked for a fair fight and got one. Their people watched them lose.");
    this.Text("Cyberbane-RivalMoments-StareThemDownLookAtMe", "[Stare them down] Look at me. Think hard about this.");
    this.Text("Cyberbane-RivalMoments-DrawLetSGo", "[Draw] Let's go.");
    this.Text("Cyberbane-RivalMoments-WalkAwayNotToday", "[Walk away] Not today.");
    this.Text("Cyberbane-RivalMoments-JustYouAndMeTellYour", "[Just you and me] Tell your people to stay out of it.");
    this.Text("Cyberbane-RivalMoments-CallItEvenILetYou", "[Call it even] I let you live once. We're even.");
    // {0} CBRivalDisplayName(sys.GetContent(), other)
    this.Text("Cyberbane-RivalMoments-AskWhereSThenWeRe", "[Ask] Where's {0}? Then we're done.");
    this.Text("Cyberbane-RivalMoments-ExileGetOutOfNightCity", "[Exile] Get out of Night City. Tonight.");
    this.Text("Cyberbane-RivalMoments-FineFINELetSGetThis", "...Fine. FINE. Let's get this over with.");
    this.Text("Cyberbane-RivalMoments-DonTDonTLookAt", "Don't... don't look at me like that.");
    this.Text("Cyberbane-RivalMoments-ThatSItThatSThe", "That's it? That's the look everybody's scared of?");
    this.Text("Cyberbane-RivalMoments-YouBlinkedTakeThem", "You blinked. Take them!");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-RivalMoments-HadYouAndLetYouWalk", "{0} had you and let you walk. Once. The street's talking about why.");
    this.Text("Cyberbane-RivalMoments-GoOnThenThisOnceNext", "Go on, then. This once. Next time there's no talking.");
    this.Text("Cyberbane-RivalMoments-WalkIWantEverybodyToSee", "Walk. I want everybody to see you walk away from me.");
    this.Text("Cyberbane-RivalMoments-NobodyTouchesThisOneItS", "Nobody touches this one. It's between them.");
    this.Text("Cyberbane-RivalMoments-JustYouAndMeThenNobody", "Just you and me, then. Nobody else.");
    this.Text("Cyberbane-RivalMoments-FairEnoughBackOffAllOf", "Fair enough. Back off, all of you. This one's mine.");
    this.Text("Cyberbane-RivalMoments-FairFightsAreForPeopleWho", "Fair fights are for people who can afford to lose.");
    this.Text("Cyberbane-RivalMoments-WhyWouldIDoThatGet", "Why would I do that? Get them!");
    this.Text("Cyberbane-RivalMoments-EvenFineDonTComeLooking", "...Even. Fine. Don't come looking for me.");
    this.Text("Cyberbane-RivalMoments-WeReSquareIMDone", "We're square. I'm done with you.");
    this.Text("Cyberbane-RivalMoments-EvenYouDonTGetTo", "Even? You don't get to decide that.");
    this.Text("Cyberbane-RivalMoments-IDonTKnowAnythingI", "I don't know anything. I swear. Just... let me go.");
    // {0} CBIntelSpoken(i)
    this.Text("Cyberbane-RivalMoments-NowWeReDone", "{0} Now we're done.");
    this.Text("Cyberbane-RivalMoments-OkayIMGoneYouLl", "Okay. I'm gone. You'll never see me again.");
    this.Text("Cyberbane-RivalMoments-NightCitySYoursIM", "Night City's yours. I'm out.");
    this.Text("Cyberbane-RivalMoments-YourFuneral", "Your funeral.");
    this.Text("Cyberbane-RivalMoments-IMDoneIMDone", "...I'm done. I'm done with all of it.");
    this.Text("Cyberbane-RivalMoments-NobodyWillEverLookAtMe", "Nobody will ever look at me the same. I'm out.");
    this.Text("Cyberbane-RivalMoments-LaughGoOnILlRemember", "Laugh. Go on. I'll remember every second of this.");
    this.Text("Cyberbane-RivalMoments-YouLlPayForThisEvery", "You'll pay for this. Every word of it.");
    this.Text("Cyberbane-RivalMoments-Kneeler", "Kneeler");
    this.Text("Cyberbane-RivalMoments-Doormat", "Doormat");
    this.Text("Cyberbane-RivalMoments-SecondPlace", "Second Place");
    this.Text("Cyberbane-RivalMoments-TheFloor", "the Floor");
    this.Text("Cyberbane-RivalMoments-DustEater", "Dust Eater");
    this.Text("Cyberbane-RivalMoments-LapDog", "Lap Dog");
    this.Text("Cyberbane-RivalMoments-GlassJaw", "Glass Jaw");
    this.Text("Cyberbane-RivalMoments-Crawler", "Crawler");
    this.Text("Cyberbane-RivalMoments-Pushover", "Pushover");
    this.Text("Cyberbane-RivalMoments-IDonTKnowWhoYou", "I don't know who you mean.");
    // {0} CBRivalDisplayName(sys.GetContent(), other)
    this.Text("Cyberbane-RivalMoments-YeahIVeWantedThatOne", "{0}? ...Yeah. I've wanted that one for a long time.");
    this.Text("Cyberbane-RivalMoments-TheirGun", "their gun");
    // {0} StrLen(what) > 0 ? what : "their gun", {1} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-RivalMoments-YouTookOffSomethingToRemember", "you took {0} off {1}. Something to remember them by.");
    // {0} name, {1} deadName, {2} name
    this.Text("Cyberbane-RivalMoments-BuriedWhoeverDidItItWasn", "{0} buried {1}. Whoever did it, it wasn't you, and {2} knows it.");
    // {0} name, {1} deadName
    this.Text("Cyberbane-RivalMoments-TrainedWordIsTheyVeGone", "{0} trained {1}. Word is they've gone very quiet since.");
    // {0} name, {1} deadName
    this.Text("Cyberbane-RivalMoments-PackedABagTheNightDied", "{0} packed a bag the night {1} died and left Night City.");
    // {0} deadName, {1} CBBondLossLine(kind)
    this.Text("Cyberbane-RivalMoments-YouKilled", "You killed {0}. {1}");
    this.Text("Cyberbane-RivalMoments-TheyTaughtMeEverythingIM", "They taught me everything. I'm going to use all of it on you.");
    this.Text("Cyberbane-RivalMoments-IMadeThemWhatTheyWere", "I made them what they were. Now I'll make you nothing.");
    this.Text("Cyberbane-RivalMoments-ThereSNothingLeftOfMe", "There's nothing left of me but this. I'm coming.");
    this.Text("Cyberbane-RivalMoments-WeWerePartnersNowIM", "We were partners. Now I'm going to finish what we started.");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-RivalMoments-YouLetLiveIWonT", "You let {0} live. I won't forget that. I owe you.");
    this.Text("Cyberbane-RivalMoments-MentorTo", "mentor to");
    this.Text("Cyberbane-RivalMoments-ProtGOf", "protégé of");
    this.Text("Cyberbane-RivalMoments-InLoveWith", "in love with");
    this.Text("Cyberbane-RivalMoments-PartnersWith", "partners with");
    // {0} CBRivalDisplayName(sys.GetContent(), a), {1} CBRivalDisplayName(sys.GetContent(), b), {2} w, {3} l
    this.Text("Cyberbane-RivalMoments-YouPointedAtWalkedAwayFrom", "You pointed {0} at {1}. {2} walked away from it; {3} didn't.");
    // {0} w, {1} l
    this.Text("Cyberbane-RivalMoments-CaughtUpWithOnlyOneOf", "{0} caught up with {1}. Only one of them walked away. One less name after you, and one bigger.");
    this.Text("Cyberbane-RivalMoments-MissMeSomeBackAlleyRipperdoc", "Miss me? Some back-alley ripperdoc put me back together. More chrome than meat now. I remember everything.");
    this.Text("Cyberbane-RivalMoments-Lazarus", "Lazarus");
    this.Text("Cyberbane-RivalMoments-SecondLife", "Second Life");
    this.Text("Cyberbane-RivalMoments-Stitched", "Stitched");
    this.Text("Cyberbane-RivalMoments-TheRevenant", "the Revenant");
    this.Text("Cyberbane-RivalMoments-BackAgain", "Back Again");
    this.Text("Cyberbane-RivalMoments-Patchwork", "Patchwork");
    this.Text("Cyberbane-RivalMoments-Rebuilt", "Rebuilt");
    // {0} CBIntelSpoken(i)
    this.Text("Cyberbane-RivalMoments-RememberMeIMOutOf", "Remember me? I'm out of the life, but I still hear things. {0} Call it a favour.");
    // {0} CBCapFirst(CBFactionLabel(r.faction))
    this.Text("Cyberbane-RivalMoments-HeadsUpForOldTimesSake", "Heads up, for old times' sake. {0} still talk about you. They haven't forgotten. Neither have I, but I'm not coming.");
    this.Text("Cyberbane-RivalMoments-ThoughtICouldLeaveItI", "Thought I could leave it. I can't. I'm back in Night City, and we're going to finish this.");
    // {0} CBRivalDisplayName(sys.GetContent(), r), {1} CBCapFirst(fresh)
    this.Text("Cyberbane-RivalMoments-WentUnderTheKnifeAndThey", "{0} went under the knife. {1}, and they're telling everybody it's for you.");
    this.Text("Cyberbane-RivalMoments-WhereYouPutMyFamilyIn", "Where you put my family in the ground.");
    this.Text("Cyberbane-RivalMoments-WhereYouLeftMeLying", "Where you left me lying.");
  }

  // ---- RivalSystem -----------------------------------------------------------------------------------------
  protected func DefineRivalSystem() -> Void {
    // {0} CBRivalDisplayName(content, r)
    this.Text("Cyberbane-RivalSystem-WordIsWentBackUnderThe", "Word is {0} went back under the knife after you and came out wrong. Cyberpsycho now. Watch yourself.");
    this.Text("Cyberbane-RivalSystem-ARival", "A rival");
    this.Text("Cyberbane-RivalSystem-ARival-2", "a Rival");
    this.Text("Cyberbane-RivalSystem-NotThisTime", "not this time");
    // {0} CBRivalDisplayName(content, rival)
    this.Text("Cyberbane-RivalSystem-IsDeadAndEverybodyKnowsWho", "{0} is dead and everybody knows who did it.");
    // {0} CBRivalDisplayName(content, rival)
    this.Text("Cyberbane-RivalSystem-IsDeadSomebodyGotToThem", "{0} is dead. Somebody got to them before you did.");
    // {0} CBRivalDisplayName(content, r)
    this.Text("Cyberbane-RivalSystem-HasMovedUpWhileYouWere", "{0} has moved up while you were busy elsewhere.");
  }

  // ---- Whereabouts -----------------------------------------------------------------------------------------
  protected func DefineWhereabouts() -> Void {
    this.Text("Cyberbane-Whereabouts-AroundTown", "around town");
    // {0} name, {1} inPlace, {2} pin
    this.Text("Cyberbane-Whereabouts-HeardYouGotBeefWithOur", "Heard you got beef with {0}. Our people saw them {1} not long ago.{2}");
    // {0} name, {1} inPlace, {2} pin
    this.Text("Cyberbane-Whereabouts-HasBeenSeenYouWantThem", "{0} has been seen {1}. You want them, they are yours. Nobody here will miss them.{2}");
    // {0} name, {1} inPlace, {2} pin
    this.Text("Cyberbane-Whereabouts-WordFromOurCornersIsLying", "Word from our corners: {0} is lying low {1}. Do us all a favour.{2}");
    // {0} name, {1} inPlace, {2} pin
    this.Text("Cyberbane-Whereabouts-SawEarlierHeardTheyHaveIt", "Saw {0} {1} earlier. Heard they have it in for you.{2}");
    // {0} name, {1} inPlace, {2} pin
    this.Text("Cyberbane-Whereabouts-YourFriendIsHoledUpYou", "Your friend {0} is holed up {1}. You did not hear it from me.{2}");
    // {0} staleName[k], {1} CBPlacePhrase(staleWhere[k])
    this.Text("Cyberbane-Whereabouts-MovedOnFromTookTooLong", "{0} moved on from {1}. Took too long.");
    this.Text("Cyberbane-Whereabouts-NobodyAtThePlaceYetThey", "nobody at the place yet. They only show while you cannot see the spot: back off a little and look away.");
    this.Text("Cyberbane-Whereabouts-NobodyAtThePlaceYetCome", "nobody at the place yet. Come on foot, out of a fight and off any job, and give it a moment.");
    this.Text("Cyberbane-Whereabouts-NobodyAtThePlaceYetThey-2", "nobody at the place yet. They will not show while somebody else is after you.");
    this.Text("Cyberbane-Whereabouts-NobodyHomeTheyKeepHoursOut", "nobody home. They keep hours: out by day, back here after dark.");
    this.Text("Cyberbane-Whereabouts-RIVAL", "RIVAL");
    this.Text("Cyberbane-Whereabouts-SoSomebodySoldMeOutFine", "So somebody sold me out. Fine. Come and get it.");
    // {0} CBRivalCatchphrase(r)
    this.Text("Cyberbane-Whereabouts-YouCameGood", "You came. Good. {0}");
    this.Text("Cyberbane-Whereabouts-CameToFinishItYourselfGood", "Came to finish it yourself? Good. Saves me the trip.");
    // {0} name
    this.Text("Cyberbane-Whereabouts-HeardAboutNeverSawYouComing", "Heard about {0}. Never saw you coming. Clean work.");
    // {0} name
    this.Text("Cyberbane-Whereabouts-WordIsNeverSawItComing", "Word is {0} never saw it coming.");
    // {0} price
    this.Text("Cyberbane-Whereabouts-NotEnoughEddiesForThatIt", "not enough eddies for that. It costs {0}eb.");
    this.Text("Cyberbane-Whereabouts-NobodyCouldFindThemFromHere", "nobody could find them from here. Try again somewhere else.");
    // {0} name, {1} price
    this.Text("Cyberbane-Whereabouts-HeardYouReAskingAfterI", "Heard you're asking after {0}. I know where they sleep. {1}eb and it's yours.");
    // {0} name, {1} price
    this.Text("Cyberbane-Whereabouts-WeKnowWhereEbAndYou", "{0}? We know where. {1}eb, and you didn't get it from us.");
    // {0} name, {1} price
    this.Text("Cyberbane-Whereabouts-WordIsYouWantEbBuys", "Word is you want {0}. {1}eb buys you an address.");
    // {0} CBCapFirst(CBYou(sys, game))
    this.Text("Cyberbane-Whereabouts-CompanyIsHere", "Company! {0} is here!");
    this.Text("Cyberbane-Whereabouts-WeVeBeenMadeGoGo", "We've been made. Go, go, tell them!");
    // {0} CBYou(sys, game)
    this.Text("Cyberbane-Whereabouts-ThatSIMOutOf", "That's {0}. I'm out of here.");
    // {0} CBPossessive(name)
    this.Text("Cyberbane-Whereabouts-OneOfPeopleSawYouComing", "One of {0} people saw you coming and ran to warn them. They've moved, not far.");
    // {0} name
    this.Text("Cyberbane-Whereabouts-KnowsYouReComingNowTheir", "{0} knows you're coming now: their lookout got away. They're holed up a few streets over.");
    // {0} name
    this.Text("Cyberbane-Whereabouts-GotWarnedAndWentToGround", "{0} got warned and went to ground. Nobody knows where now.");
    // {0} name, {1} implant
    this.Text("Cyberbane-Whereabouts-IsInARipperdocSChair", "{0} is in a ripperdoc's chair right now, getting {1} put in for you. Catch them outside when they walk out.");
    // {0} name, {1} implant
    this.Text("Cyberbane-Whereabouts-WordIsWentUnderTheKnife", "Word is {0} went under the knife: {1}. They're laid up by the ripperdoc's, if you hurry.");
    this.Text("Cyberbane-Whereabouts-TheyLlBeThereAfterDark", " They'll be there after dark.");
  }

  // ---- CombatSignals ---------------------------------------------------------------------------------------
  protected func DefineCombatSignals() -> Void {
    this.Text("Cyberbane-CombatSignals-YouShotSomebodyWithTheirHands", "You shot somebody with their hands up. People saw.");
    // {0} CBTierName(tierAfter)
    this.Text("Cyberbane-CombatSignals-PeopleHaveStoppedAskingWhoYou", "People have stopped asking who you are. On the street you are {0} now.");
    this.Text("Cyberbane-CombatSignals-YouTookDownSomebodyWhoMattered", "You took down somebody who mattered. That will be around by morning.");
    this.Text("Cyberbane-CombatSignals-YouPutDownAMaxTacOperative", "You put down a MaxTac operative. Nobody does that twice and stays quiet.");
  }

  // ---- Concealment -----------------------------------------------------------------------------------------
  protected func DefineConcealment() -> Void {
    this.Text("Cyberbane-Concealment-ItsDisguiseClassIsNotIn", "its disguise class is not in this build");
    this.Text("Cyberbane-Concealment-IsDisguiseReady", " IsDisguiseReady");
    this.Text("Cyberbane-Concealment-IsFaceDisguiseEnabled", " IsFaceDisguiseEnabled");
    this.Text("Cyberbane-Concealment-IsAffiliationDisguiseEnabled", " IsAffiliationDisguiseEnabled");
    this.Text("Cyberbane-Concealment-DisguiseScore", " DisguiseScore");
    this.Text("Cyberbane-Concealment-Cover", " Cover");
    this.Text("Cyberbane-Concealment-CoverScore", " CoverScore");
    // {0} missing
    this.Text("Cyberbane-Concealment-ItHasNeitherAFaceReading", "it has neither a face reading nor a gang reading Cyberbane can ask for (missing:{0})");
    this.Text("Cyberbane-Concealment-ItsDisguiseSystemIsNotRunning", "its disguise system is not running");
    this.Text("Cyberbane-Concealment-ItHasNotReadYourOutfit", "it has not read your outfit yet");
  }

  // ---- Bounty ----------------------------------------------------------------------------------------------
  protected func DefineBounty() -> Void {
    this.Text("Cyberbane-Bounty-HeavyGuns", "heavy guns");
    this.Text("Cyberbane-Bounty-ACyberdeck", "a cyberdeck");
    this.Text("Cyberbane-Bounty-ALongRifle", "a long rifle");
    this.Text("Cyberbane-Bounty-APistolAndPatience", "a pistol and patience");
    this.Text("Cyberbane-Bounty-Patient", "patient");
    this.Text("Cyberbane-Bounty-Reckless", "reckless");
    this.Text("Cyberbane-Bounty-WorksNights", "works nights");
    this.Text("Cyberbane-Bounty-AProfessional", "a professional");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-Bounty-WhoeverPutThePriceOnYou", "Whoever put the price on you is dead. {0}'s money died with them. The board's clean.");
    // {0} who
    this.Text("Cyberbane-Bounty-NoMorePriceOnYourHead", "No more price on your head: {0} isn't around to pay it.");
    this.Text("Cyberbane-Bounty-PaidYourNameSOffThe", "Paid. Your name's off the board. Anybody still coming is coming on their own time.");
    this.Text("Cyberbane-Bounty-MoneyTalksTheContractSWithdrawn", "Money talks. The contract's withdrawn.");
    // {0} who
    this.Text("Cyberbane-Bounty-ThePricePutOnYouIs", "The price {0} put on you is gone. Nobody's collecting.");
    this.Text("Cyberbane-Bounty-YourNameSOffTheBoard", "Your name's off the board. Whoever was paying stopped paying.");
    this.Text("Cyberbane-Bounty-ArasakaLiaison", "Arasaka liaison");
    this.Text("Cyberbane-Bounty-MilitechProcurement", "Militech procurement");
    this.Text("Cyberbane-Bounty-KangTaoRepresentative", "Kang Tao representative");
    this.Text("Cyberbane-Bounty-TheBoard", "The board");
    this.Text("Cyberbane-Bounty-WeToldYouToStop", "We told you to stop. ");
    // {0} warned, {1} amount
    this.Text("Cyberbane-Bounty-AContractHasBeenOpenedOn", "{0}A contract has been opened on you. {1} eddies, payable to whoever closes it. It can also be withdrawn, for a price. Think about which you'd rather.");
    // {0} you, {1} amount, {2} who
    this.Text("Cyberbane-Bounty-ThereSAPriceOnYour", "There's a price on your head, {0}. {1} eddies from {2}, and the board's already arguing about who takes it.");
    // {0} CBCapFirst(who), {1} amount, {2} here
    this.Text("Cyberbane-Bounty-PutEbOnYouEverySolo", "{0} put {1}eb on you. Every solo in {2} just read your name off the board.");
    // {0} who, {1} amount, {2} here
    this.Text("Cyberbane-Bounty-WordIsWouldPayToSee", "Word is {0} would pay {1} to see you dead. Watch who's watching you in {2}.");
    // {0} amount, {1} you
    this.Text("Cyberbane-Bounty-EddiesOnThatSMoreThan", "{0} eddies on {1}. That's more than most people see in a year, and every gun for hire knows it.");
    // {0} price
    this.Text("Cyberbane-Bounty-NotEnoughEddiesToClearThe", "not enough eddies to clear the price any more. It costs {0}eb.");
    this.Text("Cyberbane-Bounty-BOUNTYHUNTER", "BOUNTY HUNTER");
    this.Text("Cyberbane-Bounty-BroughtAFriend", " Brought a friend.");
    this.Text("Cyberbane-Bounty-YouReNotEvenOnThe", "You're not even on the board yet. After you, I'm one step higher.");
    // {0} vRank, {1} rank
    this.Text("Cyberbane-Bounty-YouReNumberIMNumber", "You're number {0}. I'm number {1}. That changes tonight.");
    // {0} vRank
    this.Text("Cyberbane-Bounty-NumberOnTheBoardSomebodyHas", "Number {0} on the board. Somebody has to take it off you.");
    // {0} CBHunterName(seed), {1} rank
    this.Text("Cyberbane-Bounty-Rank", "{0} (rank {1})");
    // {0} book.BountyAmount(), {1} you, {2} standing, {3} pair
    this.Text("Cyberbane-Bounty-EddiesSaysIFindYouNothing", "{0} eddies says I find you, {1}. Nothing personal. {2}{3}");
    // {0} CBPossessive(CBBountyPosterName(sys, game, book.BountyBy())), {1} CBHunterTraitWord(seed), {2} CBHunterKindWord(seed), {3} pair
    this.Text("Cyberbane-Bounty-ITookContractIWorkWith", "I took {0} contract. I work {1}, with {2}. You'll see.{3}");
    // {0} CBHere(sys), {1} book.BountyAmount(), {2} pair
    this.Text("Cyberbane-Bounty-DonTBotherLeavingIVe", "Don't bother leaving {0}. I've got your face and {1} reasons.{2}");
    // {0} when, {1} you, {2} pair
    this.Text("Cyberbane-Bounty-ILikeWorkingSeeYouSoon", "I like working {0}. See you soon, {1}.{2}");
    // {0} you, {1} standing, {2} pair
    this.Text("Cyberbane-Bounty-SeeYouSoon", "See you soon, {0}. {1}{2}");
    // {0} name
    this.Text("Cyberbane-Bounty-WasNumberOneOnTheHunters", "{0} was number one on the hunters' ladder. Now you are. The most dangerous merc in Night City, and every solo with a gun knows it.");
    this.Text("Cyberbane-Bounty-TopOfTheBoardNobodyIn", "Top of the board. Nobody in this city is worth more to kill, or harder to.");
    // {0} name, {1} CBHere(sys), {2} after
    this.Text("Cyberbane-Bounty-CameForYouInAndLost", "{0} came for you in {1} and lost. You're number {2} on the hunters' ladder now.");
    // {0} CBHunterHandle(seed), {1} after
    this.Text("Cyberbane-Bounty-TheBoardSBeenRewrittenYou", "The board's been rewritten: you took {0}'s place. Number {1}.");
    // {0} rank, {1} CBWhenTail(game)
    this.Text("Cyberbane-Bounty-SolosAreTalkingYouBeatA", "Solos are talking. You beat a rank {0}{1}, and that makes you one.");
    // {0} CBCapFirst(CBHunterHandle(seed)), {1} after
    this.Text("Cyberbane-Bounty-WonTBeCollectingAnythingNow", "{0} won't be collecting anything now. Number {1} on the board is you.");
    // {0} name, {1} CBFactionLabel(gang)
    this.Text("Cyberbane-Bounty-YouLeftBreathingTheyReOff", "You left {0} breathing. They're off the board: word is they've signed on with {1} under a new name, and they want you for themselves.");
    // {0} npc.cbBountyRank
    this.Text("Cyberbane-Bounty-BOUNTYHUNTERRANK", "BOUNTY HUNTER, RANK {0}");
    // {0} amount, {1} CBBountyPosterName(sys, game, book.BountyBy()), {2} CBBountyPayOff(sys, game)
    this.Text("Cyberbane-Bounty-APriceOnYourHeadEddies", "A price on your head: {0} eddies from {1}. Pay {2}eb to have it withdrawn, or kill whoever put it up.");
    // {0} v
    this.Text("Cyberbane-Bounty-YouAreNumberOnTheHunters", "You are number {0} on the hunters' ladder.");
    this.Text("Cyberbane-Bounty-YouAreNotOnTheHunters", "You are not on the hunters' ladder yet.");
    // {0} CBHunterName(book.HunterSeed(next)), {1} book.HunterRank(next), {2} CBHunterTraitWord(book.HunterSeed(next)), {3} CBHunterKindWord(book.HunterSeed(next))
    this.Text("Cyberbane-Bounty-NextToComeForYouRank", " Next to come for you: {0}, rank {1}, {2}, with {3}.");
    this.Text("Cyberbane-Bounty-YouVeCostUsMoreThis", "You've cost us more this month than our security budget allows. This is the only courtesy call you get. Stop.");
    this.Text("Cyberbane-Bounty-WeKnowYourNameWeD", "We know your name. We'd rather not have to put a price on it. Keep away from our people.");
    // {0} CBYou(sys, game), {1} leaderName, {2} CBFactionLabel(target), {3} pay
    this.Text("Cyberbane-Bounty-AProposalForOfHasBecome", "A proposal for {0}. {1} of {2} has become an obstacle to our interests. Kill them yourself within the week and {3} eddies are yours. We were never in touch.");
    // {0} pay
    this.Text("Cyberbane-Bounty-SatisfactoryEddiesHaveBeenTransferredWe", "Satisfactory. {0} eddies have been transferred. We may call again.");
  }

  // ---- Clashes ---------------------------------------------------------------------------------------------
  protected func DefineClashes() -> Void {
    // {0} w, {1} l, {2} here, {3} w
    this.Text("Cyberbane-Clashes-DidYouSeeThatAndWent", "Did you see that? {0} and {1} went at it right here in {2}. {3} walked away.");
    // {0} CBCapFirst(l), {1} w, {2} here
    this.Text("Cyberbane-Clashes-LostACoupleOnTheCorner", "{0} lost a couple on the corner just now. {1} are pushing into {2}.");
    // {0} here, {1} CBWhenTail(game), {2} w
    this.Text("Cyberbane-Clashes-GangTroubleInCameOutOf", "Gang trouble in {0}{1}. {2} came out of it on top.");
    // {0} w, {1} l, {2} here
    this.Text("Cyberbane-Clashes-ThatWasAndWhoeverHoldsNext", "That was {0} and {1}. Whoever holds {2} next week, it won't be quiet.");
  }

  // ---- ClearedStreets --------------------------------------------------------------------------------------
  protected func DefineClearedStreets() -> Void {
    // {0} CBFactionLabel(gang)
    this.Text("Cyberbane-ClearedStreets-NobodyFromWillStandOnThat", "Nobody from {0} will stand on that corner for a while. Not after what you did there.");
    // {0} CBCapFirst(CBFactionLabel(gang))
    this.Text("Cyberbane-ClearedStreets-AreGivingThatBlockAWide", "{0} are giving that block a wide berth. Can't say I blame them.");
  }

  // ---- FactionApex -----------------------------------------------------------------------------------------
  protected func DefineFactionApex() -> Void {
    this.Text("Cyberbane-FactionApex-TheirBest", "Their best");
    // {0} name
    this.Text("Cyberbane-FactionApex-IsComingForYouAndNot", "{0} is coming for you, and not alone. Four of ours.");
    this.Text("Cyberbane-FactionApex-NoReasonRecorded", "no reason recorded");
  }

  // ---- Hangouts --------------------------------------------------------------------------------------------
  protected func DefineHangouts() -> Void {
    // {0} CBCapFirst(CBFactionLabel(gang))
    this.Text("Cyberbane-Hangouts-HangingOut", "{0}, hanging out");
    // {0} CBFactionLabel(gang)
    this.Text("Cyberbane-Hangouts-SomeOfTheHangOutRound", "Some of the {0} hang out round the corner, if you're looking for them.");
    // {0} CBFactionLabel(gang)
    this.Text("Cyberbane-Hangouts-LookingForAFewOfThem", "Looking for {0}? A few of them are a street over. Usually are, this time of day.");
  }

  // ---- HitSquad --------------------------------------------------------------------------------------------
  protected func DefineHitSquad() -> Void {
    // {0} team
    this.Text("Cyberbane-HitSquad-WithTheirApexSquad", " with their apex squad ({0})");
  }

  // ---- Hunt ------------------------------------------------------------------------------------------------
  protected func DefineHunt() -> Void {
    this.Text("Cyberbane-Hunt-THREATENDED", "THREAT ENDED");
    this.Text("Cyberbane-Hunt-ACarOnItsWay", ", a car on its way");
    this.Text("Cyberbane-Hunt-ANAMEHERE", "A NAME HERE");
    this.Text("Cyberbane-Hunt-KNOWNHERE", "KNOWN HERE");
    this.Text("Cyberbane-Hunt-TALKEDABOUTHERE", "TALKED ABOUT HERE");
    this.Text("Cyberbane-Hunt-UNKNOWNHERE", "UNKNOWN HERE");
    // {0} CBClip(CBBarFactionLabel(open), CBConfig.HudNameMaxChars()), {1} Max(left, 1)
    this.Text("Cyberbane-Hunt-OPENSEASONHLEFT", "OPEN SEASON: {0}   -   {1}H LEFT");
    // {0} CBClip(CBBarFactionLabel(tracker), CBConfig.HudNameMaxChars())
    this.Text("Cyberbane-Hunt-ATRACKERONYOU", "A TRACKER ON YOU: {0}");
    // {0} StrUpper(CBTimeText(left))
    this.Text("Cyberbane-Hunt-ASCOUTHASSEENYOUCALLING", "A SCOUT HAS SEEN YOU: CALLING IT IN   -   {0}");
    // {0} hunterWho, {1} StrUpper(CBTimeText(hunterEta))
    this.Text("Cyberbane-Hunt-APRICEONYOURHEADON", "A PRICE ON YOUR HEAD: {0}   -   ON THEIR WAY {1}");
    // {0} who
    this.Text("Cyberbane-Hunt-HUNTED", "HUNTED: {0}");
    this.Text("Cyberbane-Hunt-HUNTED-2", "HUNTED");
    this.Text("Cyberbane-Hunt-SOMEBODY", "SOMEBODY");
    // {0} what, {1} StrUpper(CBTimeText(eta))
    this.Text("Cyberbane-Hunt-HUNTEDONTHEIRWAY", "HUNTED: {0}   -   ON THEIR WAY {1}");
    // {0} CBClip(tracker, CBConfig.HudNameMaxChars())
    this.Text("Cyberbane-Hunt-TRACKED", "TRACKED: {0}");
    // {0} head
    this.Text("Cyberbane-Hunt-THEYHAVEYOU", "{0}   -   THEY HAVE YOU");
    // {0} head
    this.Text("Cyberbane-Hunt-SPOTTED", "{0}   -   SPOTTED");
    // {0} head
    this.Text("Cyberbane-Hunt-LOSINGYOURTRAIL", "{0}   -   LOSING YOUR TRAIL");
    // {0} head
    this.Text("Cyberbane-Hunt-SEARCHINGFORYOU", "{0}   -   SEARCHING FOR YOU");
    this.Text("Cyberbane-Hunt-YourOpticsFlickerSomebodyIsTracing", "your optics flicker. Somebody is tracing you through the Net.");
    // {0} where, {1} coming
    this.Text("Cyberbane-Hunt-EverybodyWeHaveIsComingFor", "Everybody we have is coming for you. Somebody saw you in {0}. {1}");
    // {0} where, {1} coming
    this.Text("Cyberbane-Hunt-YouAreOnOurStreetsIn", "You are on our streets in {0}. {1}");
    // {0} coming, {1} where
    this.Text("Cyberbane-Hunt-WeHearYouAreIn", "{0} We hear you are in {1}.");
    // {0} CBFactionLabel(faction)
    this.Text("Cyberbane-Hunt-FourOfSBest", "Four of {0}'s best");
    this.Text("Cyberbane-Hunt-YouBeatOurBestOnceThat", " You beat our best once. That was luck.");
    // {0} beaten
    this.Text("Cyberbane-Hunt-YouVeBeatenOurBestTimes", " You've beaten our best {0} times. Not this one.");
    // {0} name, {1} CBHuntWhereLine(sys, game), {2} record
    this.Text("Cyberbane-Hunt-AndThreeOfOursAreOn", "{0} and three of ours are on the road. Last we heard you were in {1}.{2}");
    // {0} where
    this.Text("Cyberbane-Hunt-HeardYouAreInIAm", "Heard you are in {0}. I am coming.");
    // {0} where
    this.Text("Cyberbane-Hunt-IPutYouDownOnceHeard", "I put you down once. Heard you are in {0}. Let's do it again.");
    // {0} where
    this.Text("Cyberbane-Hunt-YouLetMeLiveBadCall", "You let me live. Bad call. I know you are in {0}.");
    // {0} where
    this.Text("Cyberbane-Hunt-StillBreathingBothOfUsNot", "Still breathing, both of us. Not for long. You are in {0}, right?");
    this.Text("Cyberbane-Hunt-SCOUT", "SCOUT");
    this.Text("Cyberbane-Hunt-SomebodyIsWalkingYourBlockAsking", "Somebody is walking your block asking questions. Just one, for now.");
    this.Text("Cyberbane-Hunt-OurGuyStoppedAnsweringWeWill", "Our guy stopped answering. We will find you another way.");
    this.Text("Cyberbane-Hunt-OurScoutLostYouYouWon", "Our scout lost you. You won't get that lucky twice.");
    this.Text("Cyberbane-Hunt-OurEyesLostYouInThe", "Our eyes lost you in the crowd. We'll find you another day.");
    // {0} CBCrewComingLine(sys, game, fs)
    this.Text("Cyberbane-Hunt-OurScoutHasEyesOnYou", "Our scout has eyes on you. {0}");
  }

  // ---- HuntGrows -------------------------------------------------------------------------------------------
  protected func DefineHuntGrows() -> Void {
    // {0} CBPossessive(CBFactionLabel(gang))
    this.Text("Cyberbane-HuntGrows-YouSurvivedOpenSeasonAWhole", "You survived {0} open season. A whole day of their best, and you're still standing. They're scared now.");
    // {0} CBCapFirst(CBPossessive(CBFactionLabel(gang)))
    this.Text("Cyberbane-HuntGrows-YouKilledTheOneWhoCalled", "You killed the one who called it. {0} open season is over.");
    // {0} CBFactionLabel(hacker)
    this.Text("Cyberbane-HuntGrows-SomethingJustPingedInYourCyberdeck", "something just pinged in your cyberdeck: {0} planted a tracker. Spend a minute somewhere safe to dig it out.");
    this.Text("Cyberbane-HuntGrows-TheTrackerSGoneNobodyKnows", "the tracker's gone. Nobody knows where you are.");
    // {0} CBFactionLabel(fs.id)
    this.Text("Cyberbane-HuntGrows-OpenSeasonEveryOneOfKnows", "Open season. Every one of {0} knows your face, and we're coming every hour for the next twenty-four. Run.");
    // {0} CBFactionLabel(gang)
    this.Text("Cyberbane-HuntGrows-CarFullOfJustParkedUp", "Car full of {0} just parked up the road, engine running. They're waiting for you.");
  }

  // ---- Hunted ----------------------------------------------------------------------------------------------
  protected func DefineHunted() -> Void {
    this.Text("Cyberbane-Hunted-StillHotAboutYou", "still hot about you");
    this.Text("Cyberbane-Hunted-CoolingOff", "cooling off");
    this.Text("Cyberbane-Hunted-WhoeverWasAfterYouLostYou", "Whoever was after you lost you when you changed. They're looking for somebody else now.");
    this.Text("Cyberbane-Hunted-WhoeverWasAfterYouLostYour", "Whoever was after you lost your trail when you crossed over.");
    // {0} price
    this.Text("Cyberbane-Hunted-PayEbTellThemYouDidn", "[Pay] {0}eb. Tell them you didn't find me.");
    this.Text("Cyberbane-Hunted-FindWhatIMJustWalking", "Find what? I'm just walking.");
    this.Text("Cyberbane-Hunted-ThatDoesnTBuyMySilence", "That doesn't buy my silence.");
    this.Text("Cyberbane-Hunted-NeverSawYouNobodyHereBut", "Never saw you. Nobody here but me.");
    this.Text("Cyberbane-Hunted-YouWereNeverHereGoodDoing", "You were never here. Good doing business.");
    this.Text("Cyberbane-Hunted-ILlTellThemTheTrail", "I'll tell them the trail went cold. Don't make me a liar.");
  }

  // ---- LivingStreet ----------------------------------------------------------------------------------------
  protected func DefineLivingStreet() -> Void {
    this.Text("Cyberbane-LivingStreet-Now", "now");
    // {0} CBClockWord(at)
    this.Text("Cyberbane-LivingStreet-Today", "{0} today");
    // {0} CBClockWord(at)
    this.Text("Cyberbane-LivingStreet-Tomorrow", "{0} tomorrow");
    // {0} CBHudLogLine(sys, e, now)
    this.Text("Cyberbane-LivingStreet-LastYouHeard", "Last you heard: {0}");
    // {0} CBCapFirst(CBPossessive(CBFactionLabel(this.m_bagFaction)))
    this.Text("Cyberbane-LivingStreet-TakeMadeItToTheDrop", "{0} take made it to the drop. Next week, maybe.");
    this.Text("Cyberbane-LivingStreet-VIsSomewhereTheStoryA", "V is somewhere the story, a job, a safe place or home ground keeps quiet");
    this.Text("Cyberbane-LivingStreet-VIsInAFight", "V is in a fight");
    this.Text("Cyberbane-LivingStreet-VIsInACar", "V is in a car");
    this.Text("Cyberbane-LivingStreet-VIsIndoors", "V is indoors");
    this.Text("Cyberbane-LivingStreet-SomebodyIsOutHuntingV", "somebody is out hunting V");
    this.Text("Cyberbane-LivingStreet-SomebodyIsOnTheirWayFor", "somebody is on their way for V");
    this.Text("Cyberbane-LivingStreet-VSDistrictIsNotKnown", "V's district is not known yet");
    // {0} CBCapFirst(CBPossessive(CBFactionLabel(holder)))
    this.Text("Cyberbane-LivingStreet-DropTheTakeIsHeadedHere", "{0} drop: the take is headed here");
    this.Text("Cyberbane-LivingStreet-OneLookout", "One lookout.");
    this.Text("Cyberbane-LivingStreet-NobodyWatchingHisBack", "Nobody watching his back.");
    // {0} CBCapFirst(CBPossessive(CBFactionLabel(holder))), {1} watch
    this.Text("Cyberbane-LivingStreet-BagmanIsWalkingTheWeekS", "{0} bagman is walking the week's take to their drop. {1} Heavy pockets. I marked the drop.");
    // {0} CBCapFirst(CBPossessive(CBFactionLabel(holder))), {1} watch
    this.Text("Cyberbane-LivingStreet-BagmanIsDoingTheRoundsNear", "{0} bagman is doing the rounds near you with the week's take. {1} Heavy pockets.");
    // {0} take
    this.Text("Cyberbane-LivingStreet-YouTookTheBagEb", "you took the bag: {0}eb.");
    // {0} CBPossessive(CBFactionLabel(this.m_bagFaction))
    this.Text("Cyberbane-LivingStreet-SomebodyRobbedBagmanWordIsIt", "Somebody robbed {0} bagman. Word is it was you.");
    this.Text("Cyberbane-LivingStreet-NotRightNowComeBackAnother", "Not right now. Come back another time.");
    // {0} CBFactionLabel(t.faction), {1} CBFactionLabel(g)
    this.Text("Cyberbane-LivingStreet-AFavourForRunOffThe", "A favour for {0}: run off the {1} lookout");
    // {0} CBPossessive(CBFactionLabel(g))
    this.Text("Cyberbane-LivingStreet-OneOfLookoutsIsWatchingOur", "One of {0} lookouts is watching our corner, a couple of streets over. Run them off. Marked it for you.");
    // {0} place
    this.Text("Cyberbane-LivingStreet-SomebodyInOwesUsAndKeeps", "Somebody in {0} owes us and keeps forgetting. Go and collect. Lean on them, and if they swing, fists only: nobody pays from a body bag. I marked it for you.");
    this.Text("Cyberbane-LivingStreet-NothingThatNeedsYouTodayAsk", "Nothing that needs you today. Ask me again sometime.");
    // {0} CBFactionLabel(faction), {1} place
    this.Text("Cyberbane-LivingStreet-AFavourForCollectADebt", "A favour for {0}: collect a debt in {1}");
    this.Text("Cyberbane-LivingStreet-OwesMoney", "Owes money");
    this.Text("Cyberbane-LivingStreet-PayThoseThievesComeAndTake", "Pay those thieves? Come and take it, then.");
    this.Text("Cyberbane-LivingStreet-IMNotPayingYouWant", "I'm not paying. You want it, earn it.");
    this.Text("Cyberbane-LivingStreet-FistsThenWinnerKeepsTheMoney", "Fists, then. Winner keeps the money.");
    this.Text("Cyberbane-LivingStreet-YouKilledThemNobodyPaysFrom", "You killed them? Nobody pays from a body bag. The money's gone, and so is our patience.");
    this.Text("Cyberbane-LivingStreet-ForgetItSomebodyGotToThem", "Forget it. Somebody got to them before you did, and a body doesn't pay.");
    this.Text("Cyberbane-LivingStreet-HeardTheyPutYouOnThe", "Heard they put you on the ground. Forget the money.");
    this.Text("Cyberbane-LivingStreet-TheyReStillNotPayingForget", "They're still not paying. Forget it.");
    this.Text("Cyberbane-LivingStreet-ForgetItTheyPaidUpBefore", "Forget it. They paid up before you got to them.");
    this.Text("Cyberbane-LivingStreet-ForgetItTheLookoutSGone", "Forget it. The lookout's gone. Somebody else ran them off.");
    // {0} CBIntelWritten(i)
    this.Text("Cyberbane-LivingStreet-AndSomethingExtra", " And something extra: {0}");
    // {0} pay, {1} tip
    this.Text("Cyberbane-LivingStreet-HeardYouHadToPutThem", "Heard you had to put them on the ground. They paid. {0}eb, and you've got friends here.{1}");
    // {0} pay, {1} tip
    this.Text("Cyberbane-LivingStreet-SawWhatYouDidEbAnd", "Saw what you did. {0}eb, and you've got friends here.{1}");
    // {0} next
    this.Text("Cyberbane-LivingStreet-TheyGaveUpANameBefore", "They gave up a name before they paid: somebody in {0} owes us too. Same deal. I marked it.");
    this.Text("Cyberbane-LivingStreet-WeReSquareForTodayNext", "We're square for today. Next time it's you and me.");
    this.Text("Cyberbane-LivingStreet-DonTThankMeNobodyElse", "Don't thank me. Nobody else gets to kill you. That's mine.");
    this.Text("Cyberbane-LivingStreet-EnjoyItTheNextFightS", "Enjoy it. The next fight's ours, and I won't be on your side.");
    this.Text("Cyberbane-LivingStreet-NobodyKillsYouButMeKeep", "Nobody kills you but me. Keep your head down.");
    this.Text("Cyberbane-LivingStreet-NobodyKillsThisOneButMe", "Nobody kills this one but me!");
    this.Text("Cyberbane-LivingStreet-BackOffThisMercSMine", "Back off! This merc's mine!");
  }

  // ---- Loot ------------------------------------------------------------------------------------------------
  protected func DefineLoot() -> Void {
    // {0} line, {1} amount
    this.Text("Cyberbane-Loot-EbFromUs", "{0} {1}eb, from us.");
    // {0} line, {1} amount
    this.Text("Cyberbane-Loot-SomebodyWantedThatDoneEb", "{0} Somebody wanted that done. {1}eb.");
    this.Text("Cyberbane-Loot-ThatOne", "That one");
    // {0} name
    this.Text("Cyberbane-Loot-HeardYouPutInTheGround", "Heard you put {0} in the ground.");
    // {0} label
    this.Text("Cyberbane-Loot-YouTookApartTheBestOf", "You took apart the best of {0}.");
    this.Text("Cyberbane-Loot-YouTookApartTheirBest", "You took apart their best.");
  }

  // ---- Queue -----------------------------------------------------------------------------------------------
  protected func DefineQueue() -> Void {
    // {0} spawning + standing, {1} CBConfig.MaxLiveSpawns(), {2} spawning, {3} standing, {4} parts
    this.Text("Cyberbane-Queue-OfTakenStillSpawningStanding", "{0} of {1} taken: {2} still spawning, {3} standing [{4}]");
    this.Text("Cyberbane-Queue-OurPeopleAreOnTheirWay", "Our people are on their way.");
    // {0} name, {1} count
    this.Text("Cyberbane-Queue-AndThreeOfOurBestAre", "{0} and three of our best are on their way. {1} more of ours with them.");
    // {0} count
    this.Text("Cyberbane-Queue-OfOursAreOnTheirWay", "{0} of ours are on their way.");
    this.Text("Cyberbane-Queue-RivalsAreOffInModSettings", "Rivals are off in Mod Settings");
    this.Text("Cyberbane-Queue-NoneOfYourRivalsCanCome", "none of your Rivals can come right now");
    this.Text("Cyberbane-Queue-NobodyHasAGrudgeAgainstYou", "nobody has a grudge against you yet");
    // {0} CBRememberModName()
    this.Text("Cyberbane-Queue-SendsTheGangsPeople", "{0} sends the gangs' people");
    this.Text("Cyberbane-Queue-CrewsAreOffInModSettings", "crews are off in Mod Settings");
    this.Text("Cyberbane-Queue-NoGangIsAngryEnoughTo", "no gang is angry enough to send its best");
    this.Text("Cyberbane-Queue-NoGangIsAfterYou", "no gang is after you");
    this.Text("Cyberbane-Queue-APEXSQUAD", "APEX SQUAD");
    this.Text("Cyberbane-Queue-TheyHireKillersInsteadOfSending", "they hire killers instead of sending their own");
    this.Text("Cyberbane-Queue-ReadyToSendTheirBest", "ready to send their best");
    // {0} why
    this.Text("Cyberbane-Queue-TheirBestWaits", "their best waits: {0}");
    // {0} cred
    this.Text("Cyberbane-Queue-TheirBestComeOnceYourStreet", "their best come once your Street Cred reaches {0}");
    // {0} toApex
    this.Text("Cyberbane-Queue-ApexSquadInKills", "apex squad in {0} kills");
    // {0} toMassacre
    this.Text("Cyberbane-Queue-BeatACrewOrMoreKills", "beat a crew, or {0} more kills");
    // {0} crewLabel
    this.Text("Cyberbane-Queue-HeardYouDealtWithThatCrew", "Heard you dealt with that crew of {0}.");
    this.Text("Cyberbane-Queue-HeardYouDealtWithThatCrew-2", "Heard you dealt with that crew.");
    // {0} name
    this.Text("Cyberbane-Queue-ThatWasOurCrewNextTime", "That was our crew. Next time it is {0}, and three more like them.");
    // {0} name
    this.Text("Cyberbane-Queue-ThatWasOurCrewKeepIt", "That was our crew. Keep it up and you meet {0}.");
    // {0} CBCapFirst(CBFactionLabel(owner))
    this.Text("Cyberbane-Queue-HadSomebodyWatchingForYouNot", "{0} had somebody watching for you. Not any more.");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-Queue-AreAskingAboutYouAndNot", "{0} are asking about you, and not their usual people.");
    // {0} who
    this.Text("Cyberbane-Queue-HasBeenAskingAroundAboutYou", "{0} has been asking around about you.");
    // {0} who
    this.Text("Cyberbane-Queue-SomebodyFromWasAskingWhereYou", "Somebody from {0} was asking where you drink.");
    // {0} CBCapFirst(who)
    this.Text("Cyberbane-Queue-AreAskingQuestionsAboutYou", "{0} are asking questions about you.");
    // {0} who
    this.Text("Cyberbane-Queue-YourNameCameUpWithThey", "Your name came up with {0}. They want to know where you are.");
    this.Text("Cyberbane-Queue-CREW", "CREW");
    this.Text("Cyberbane-Queue-APEXCREW", "APEX CREW");
    this.Text("Cyberbane-Queue-HEAVYCREW", "HEAVY CREW");
    this.Text("Cyberbane-Queue-One", "One");
    this.Text("Cyberbane-Queue-Two", "Two");
    this.Text("Cyberbane-Queue-Three", "Three");
    this.Text("Cyberbane-Queue-Four", "Four");
    this.Text("Cyberbane-Queue-Five", "Five");
    this.Text("Cyberbane-Queue-Six", "Six");
    this.Text("Cyberbane-Queue-Seven", "Seven");
    this.Text("Cyberbane-Queue-Eight", "Eight");
    // {0} CBRememberModName()
    this.Text("Cyberbane-Queue-SendsTheGangs", "{0} sends the gangs");
    this.Text("Cyberbane-Queue-ApexSquadsAreOffInMod", "apex squads are off in Mod Settings");
    this.Text("Cyberbane-Queue-AnotherGangSBestGoesFirst", "another gang's best goes first");
    this.Text("Cyberbane-Queue-OneSquadIsAlreadyOut", "one squad is already out");
    // {0} CBArrivalsHeldWhy(sys, game)
    this.Text("Cyberbane-Queue-HeldWhile", "held while {0}");
    this.Text("Cyberbane-Queue-NoneLeftToday", "none left today");
  }

  // ---- RivalEncounter --------------------------------------------------------------------------------------
  protected func DefineRivalEncounter() -> Void {
    this.Text("Cyberbane-RivalEncounter-CanTStopHearingYouCan", "Can't stop hearing you. Can't stop. Coming now.");
    this.Text("Cyberbane-RivalEncounter-FoundYouAgainYouKnowHow", "Found you again. You know how this went last time.");
    this.Text("Cyberbane-RivalEncounter-YouShouldHaveFinishedItWhen", "You should have finished it when you had the chance. I'm close.");
    this.Text("Cyberbane-RivalEncounter-YouLetMeWalkICame", "You let me walk. I came back. I'm close.");
    this.Text("Cyberbane-RivalEncounter-FoundYouLookAround", "Found you. Look around.");
    this.Text("Cyberbane-RivalEncounter-RunThenIFoundYouOnce", "Run, then. I found you once and I will find you again.");
    this.Text("Cyberbane-RivalEncounter-EveryTimeYouRunIGet", "Every time you run I get better at this. Think about that.");
    this.Text("Cyberbane-RivalEncounter-LostMeForNow", "Lost me. For now.");
    this.Text("Cyberbane-RivalEncounter-KeepRunningIKnowWhereYou", "Keep running. I know where you sleep.");
    this.Text("Cyberbane-RivalEncounter-NextTimeIBringMore", "Next time I bring more.");
    this.Text("Cyberbane-RivalEncounter-SamePlaceAsLastTimeIt", "Same place as last time. It still hurts. You are going to pay for that.");
    this.Text("Cyberbane-RivalEncounter-YouLeftAMarkIWill", "You left a mark. I will remember it every time I look.");
    this.Text("Cyberbane-RivalEncounter-CloseNotCloseEnoughSeeYou", "Close. Not close enough. See you soon.");
    // {0} names, {1} who
    this.Text("Cyberbane-RivalEncounter-And", "{0} and {1}");
    // {0} names
    this.Text("Cyberbane-RivalEncounter-NotComingAloneThisTimeWanted", "Not coming alone this time. {0} wanted a piece of you too.");
  }

  // ---- Spawner ---------------------------------------------------------------------------------------------
  protected func DefineSpawner() -> Void {
    this.Text("Cyberbane-Spawner-LOSTTHEM", "LOST THEM");
    this.Text("Cyberbane-Spawner-RanDidYouEverybodyIsGoing", "Ran, did you. Everybody is going to hear about that.");
    this.Text("Cyberbane-Spawner-TheyLostYouDoNotGo", "They lost you. Do not go back the way you came.");
  }

  // ---- StreetEvents ----------------------------------------------------------------------------------------
  protected func DefineStreetEvents() -> Void {
    // {0} NameToString(a)
    this.Text("Cyberbane-StreetEvents-HaveNoStreetsHere", "{0} have no streets here");
    // {0} NameToString(district)
    this.Text("Cyberbane-StreetEvents-NoGangThatFieldsPeopleHolds", "no gang that fields people holds {0}");
    // {0} NameToString(a)
    this.Text("Cyberbane-StreetEvents-HaveNoRivalGangThatFields", "{0} have no rival gang that fields people");
    // {0} NameToString(a), {1} NameToString(b)
    this.Text("Cyberbane-StreetEvents-AndAreInATruce", "{0} and {1} are in a truce");
    // {0} NameToString(a)
    this.Text("Cyberbane-StreetEvents-NobodyToDealWith", "nobody to deal with {0}");
    this.Text("Cyberbane-StreetEvents-NoPlaceForItInThis", "no place for it in this district, clear of jobs and safe places");
    this.Text("Cyberbane-StreetEvents-Now", ", now");
    // {0} when
    this.Text("Cyberbane-StreetEvents-Around", ", around {0}");
    // {0} ev.placeName
    this.Text("Cyberbane-StreetEvents-By", "by {0}");
    this.Text("Cyberbane-StreetEvents-NearHere", "near here");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-OverMoneyOwe", "over money {0} owe {1}");
    // {0} CBPossessive(a), {1} b
    this.Text("Cyberbane-StreetEvents-OverOneOfPeopleKilled", "over one of {0} people {1} killed");
    this.Text("Cyberbane-StreetEvents-OverAStreetTheyBothWant", "over a street they both want");
    this.Text("Cyberbane-StreetEvents-AndTheTalkIsAboutYou", "and the talk is about you");
    this.Text("Cyberbane-StreetEvents-OverOldBusiness", "over old business");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-AndMadeTheirDealNobodyStopped", "{0} and {1} made their deal. Nobody stopped them.");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-PaidWhatTheyOwedTheirWar", "{0} paid {1} what they owed. Their war chest is lighter for it.");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-AndSettledTheKillingWithMoney", "{0} and {1} settled the killing with money. For now.");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-TheSitDownOverTheKilling", "The sit-down over the killing went bad. {0} and {1} bled each other on the way out.");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-AndCarvedUpTheStreetBetween", "{0} and {1} carved up the street between them.");
    // {0} a, {1} b
    this.Text("Cyberbane-StreetEvents-AndCameOutOfItWith", "{0} and {1} came out of it with a deal about you. They're working together for a while.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-AFuneral", "{0}: a funeral");
    // {0} a
    this.Text("Cyberbane-StreetEvents-Celebrating", "{0} celebrating");
    // {0} a
    this.Text("Cyberbane-StreetEvents-AnInitiation", "{0}: an initiation");
    // {0} a
    this.Text("Cyberbane-StreetEvents-Recruiting", "{0} recruiting");
    // {0} a, {1} CBFactionLabel(gangB)
    this.Text("Cyberbane-StreetEvents-AndGuns", "{0} and {1}: guns");
    // {0} a
    this.Text("Cyberbane-StreetEvents-AnExecution", "{0}: an execution");
    // {0} a, {1} CBFactionLabel(gangB)
    this.Text("Cyberbane-StreetEvents-Against", "{0} against {1}");
    // {0} a
    this.Text("Cyberbane-StreetEvents-AHunt", "{0}: a hunt");
    // {0} a
    this.Text("Cyberbane-StreetEvents-ARacket", "{0}: a racket");
    // {0} ev.placeName
    this.Text("Cyberbane-StreetEvents-Past", "past {0}");
    this.Text("Cyberbane-StreetEvents-PastHere", "past here");
    // {0} a, {1} CBFactionLabel(ev.b), {2} where, {3} when, {4} CBMeetReasonWords(ev)
    this.Text("Cyberbane-StreetEvents-AndAreSittingDownAroundCrash", "{0} and {1} are sitting down {2} around {3}, {4}. Crash it, and they both feel it.");
    this.Text("Cyberbane-StreetEvents-TheOneYouPutDown", " The one you put down.");
    // {0} a, {1} where, {2} when, {3} whose
    this.Text("Cyberbane-StreetEvents-AreBuryingOneOfTheirsAround", "{0} are burying one of theirs {1} around {2}.{3}");
    // {0} CBFactionLabel(ev.a), {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-FuneralForOneOfGoPay", "Funeral for one of {0} {1}, {2}. Go pay your respects. Or don't.");
    // {0} a, {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-AreCelebratingAroundTheyTookSome", "{0} are celebrating {1} around {2}. They took some streets and they want everybody to know.");
    // {0} where, {1} when, {2} a
    this.Text("Cyberbane-StreetEvents-PartyAreDrinkingToAWin", "Party {0}, {1}. {2} are drinking to a win.");
    // {0} a, {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-AreBloodingNewRecruitsAroundSomebody", "{0} are blooding new recruits {1} around {2}. Somebody's going to get hurt.");
    // {0} where, {1} when, {2} a
    this.Text("Cyberbane-StreetEvents-InitiationWantTheirNewKidsTo", "Initiation {0}, {1}. {2} want their new kids to prove something.");
    // {0} a, {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-AreSigningUpNewBloodAround", "{0} are signing up new blood {1} around {2}. More of them on these streets after.");
    // {0} where, {1} when, {2} a
    this.Text("Cyberbane-StreetEvents-RecruitingDriveWantBodies", "Recruiting drive {0}, {1}. {2} want bodies.");
    // {0} a, {1} CBFactionLabel(ev.b), {2} where, {3} when
    this.Text("Cyberbane-StreetEvents-AreBuyingGunsFromAroundCrash", "{0} are buying guns from {1} {2} around {3}. Crash it and the crate is yours.");
    // {0} where, {1} when, {2} a, {3} CBFactionLabel(ev.b)
    this.Text("Cyberbane-StreetEvents-ArmsDealAndHeavyCratesLight", "Arms deal {0}, {1}: {2} and {3}. Heavy crates, light guard.");
    // {0} a, {1} CBFactionLabel(ev.b), {2} where, {3} when
    this.Text("Cyberbane-StreetEvents-CaughtOneOfAndThePoor", "{0} caught one of {1}, and the poor soul gets a bullet {2} around {3}. Stop it, or don't.");
    // {0} where, {1} when, {2} a, {3} CBFactionLabel(ev.b)
    this.Text("Cyberbane-StreetEvents-ExecutionWantEverybodyToWatchOne", "Execution {0}, {1}. {2} want everybody to watch one of {3} die.");
    // {0} a, {1} CBFactionLabel(ev.b), {2} where, {3} when
    this.Text("Cyberbane-StreetEvents-AndAreGoingToWarOn", "{0} and {1} are going to war on a street {2} around {3}. Whoever wins takes ground.");
    // {0} where, {1} when, {2} a, {3} CBFactionLabel(ev.b)
    this.Text("Cyberbane-StreetEvents-StreetFightAgainstPickASide", "Street fight {0}, {1}: {2} against {3}. Pick a side, or keep your head down.");
    // {0} a, {1} CBFactionLabel(ev.b), {2} past, {3} when
    this.Text("Cyberbane-StreetEvents-AreHuntingSomebodyOfWhoCrossed", "{0} are hunting somebody of {1} who crossed them. The runner comes {2} around {3}.");
    // {0} a, {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-SomebodySRunningFromHelpThe", "Somebody's running from {0} {1}, {2}. Help the runner, or let them have their way.");
    // {0} a, {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-WordIsRunARacketCollecting", "Word is {0} run a racket {1}, collecting around {2}. Hit it and take the cash.");
    // {0} a, {1} where, {2} when
    this.Text("Cyberbane-StreetEvents-CollectTheirTakeAroundNobodyS", "{0} collect their take {1} around {2}. Nobody's ever robbed them. Yet.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-YouHearAreBuryingOneOf", "You hear {0} are burying one of theirs later? Somebody should send flowers.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-StayOffThatBlockLaterAre", "Stay off that block later. {0} are partying, and they get loud.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-SomeKidSGettingJumpedInto", "Some kid's getting jumped into {0} later. Poor bastard. Or poor whoever.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-AreLookingForNewBloodMy", "{0} are looking for new blood. My cousin's thinking about it.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-CratesCameInOffATruck", "Crates came in off a truck for {0}. Guns, people say.");
    // {0} CBPossessive(a)
    this.Text("Cyberbane-StreetEvents-DonTGoNearCollectionSpot", "Don't go near {0} collection spot later. They count the take there.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-AreExecutingSomebodyLaterInThe", "{0} are executing somebody later. In the open. To make a point.");
    // {0} CBCapFirst(a), {1} CBFactionLabel(ev.b)
    this.Text("Cyberbane-StreetEvents-StayHomeLaterAndAreGoing", "Stay home later. {0} and {1} are going to settle it in the street.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-SomebodyCrossedTheyReRunningThe", "Somebody crossed {0}. They're running the poor soul down later.");
    // {0} a, {1} CBFactionLabel(ev.b)
    this.Text("Cyberbane-StreetEvents-HeardAndAreMeetingCouldGo", "Heard {0} and {1} are meeting. Could go either way.");
    // {0} CBCapFirst(CBFactionLabel(ev.a))
    this.Text("Cyberbane-StreetEvents-WereWaitingForYouOnThe", "{0} were waiting for you on the way to your job. You walked through them.");
    // {0} a, {1} CBFactionLabel(ev.b), {2} CBCapFirst(CBFactionLabel(angrier))
    this.Text("Cyberbane-StreetEvents-YouCrashedTheSitDownBetween", "You crashed the sit-down between {0} and {1}. {2} took it worst.");
    // {0} a, {1} CBFactionLabel(ev.b)
    this.Text("Cyberbane-StreetEvents-YouCrashedTheSitDownBetween-2", "You crashed the sit-down between {0} and {1}. Neither of them will forget it.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-YouShotUpAFuneralWill", "You shot up a funeral. {0} will never forgive that. Nobody will forget it.");
    // {0} CBPossessive(a)
    this.Text("Cyberbane-StreetEvents-YouHitFuneralEvenPeopleWho", "You hit {0} funeral. Even people who hate them think that was low.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-YouTookTheGunsWereBuying", "You took the guns {0} were buying. The crate's yours, and so is their grudge.");
    // {0} take
    this.Text("Cyberbane-StreetEvents-YouTookTheirTakeEb", "you took their take: {0}eb.");
    // {0} CBPossessive(a)
    this.Text("Cyberbane-StreetEvents-YouHitRacketWordIsThey", "You hit {0} racket. Word is they're counting what's left.");
    // {0} CBPossessive(a), {1} CBEventNoun(ev.kind)
    this.Text("Cyberbane-StreetEvents-YouBrokeUpTheyFeltThat", "You broke up {0} {1}. They felt that.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-WhateverHadPlannedNearThereYou", "Whatever {0} had planned near there, you ended it.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-WhateverStartedNearThereItFizzled", "Whatever {0} started near there, it fizzled out. Nobody won.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-BuriedTheirDeadTheySaidYour", "{0} buried their dead. They said your name at the grave.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-BuriedTheirDeadQuietlyAndAmong", "{0} buried their dead. Quietly, and among their own.");
    // {0} CBCapFirst(a), {1} CBEventNoun(ev.kind)
    this.Text("Cyberbane-StreetEvents-GotTheirDoneTheyReStronger", "{0} got their {1} done. They're stronger for it.");
    // {0} CBPossessive(a), {1} CBEventNoun(ev.kind)
    this.Text("Cyberbane-StreetEvents-NobodyStoppedThereAreMoreOf", "Nobody stopped {0} {1}. There are more of them on the street now.");
    this.Text("Cyberbane-StreetEvents-Party", "party");
    this.Text("Cyberbane-StreetEvents-Initiation", "initiation");
    this.Text("Cyberbane-StreetEvents-Deal", "deal");
    this.Text("Cyberbane-StreetEvents-Collection", "collection");
    this.Text("Cyberbane-StreetEvents-Business", "business");
    this.Text("Cyberbane-StreetEvents-SideIMWithYou", "[Side] I'm with you.");
    this.Text("Cyberbane-StreetEvents-RespectsIMSorryForYour", "[Respects] I'm sorry for your loss.");
    this.Text("Cyberbane-StreetEvents-YouAlreadySaidYourPiece", "You already said your piece.");
    this.Text("Cyberbane-StreetEvents-DidnTExpectYouHereThanks", "Didn't expect you here. Thanks for coming.");
    this.Text("Cyberbane-StreetEvents-YouDidnTHaveToCome", "You didn't have to come. It's noticed.");
    this.Text("Cyberbane-StreetEvents-KindOfYouSayYourPiece", "Kind of you. Say your piece and go.");
    this.Text("Cyberbane-StreetEvents-YouVeGotSomeNerveBut", "You've got some nerve. But you came. That counts for something.");
    this.Text("Cyberbane-StreetEvents-TheyDHaveSpatAtYou", "They'd have spat at you. I won't. Not today.");
    this.Text("Cyberbane-StreetEvents-ComingHereTookGutsSayWhat", "Coming here took guts. Say what you came to say and go.");
    this.Text("Cyberbane-StreetEvents-TooLateForThatFindCover", "Too late for that. Find cover.");
    // {0} CBCapFirst(CBFactionLabel(theirs))
    this.Text("Cyberbane-StreetEvents-ThenStayCloseAreAboutTo", "Then stay close. {0} are about to find out.");
    this.Text("Cyberbane-StreetEvents-GoodWeHitThemNowDon", "Good. We hit them now. Don't miss.");
    // {0} CBCapFirst(CBFactionLabel(theirs))
    this.Text("Cyberbane-StreetEvents-WithYouOnOurSideAre", "With you on our side? {0} are done.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-YouPutDownTheOneWere", "You put down the one {0} were hunting. They'll thank you, in their way.");
    // {0} CBPossessive(a)
    this.Text("Cyberbane-StreetEvents-YouDidKillingForThem", "You did {0} killing for them.");
    // {0} CBCapFirst(a)
    this.Text("Cyberbane-StreetEvents-RanDownTheOneTheyWere", "{0} ran down the one they were after.");
    // {0} CBCapFirst(a), {1} b
    this.Text("Cyberbane-StreetEvents-ExecutedOneOfEverybodySaw", "{0} executed one of {1}. Everybody saw.");
    // {0} a, {1} CBCapFirst(b)
    this.Text("Cyberbane-StreetEvents-YouStoodBetweenAndTheOne", "You stood between {0} and the one they were hunting. {1} heard.");
    // {0} CBPossessive(a), {1} CBCapFirst(b)
    this.Text("Cyberbane-StreetEvents-YouStoppedExecutionWonTForget", "You stopped {0} execution. {1} won't forget it.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-TheOneWereHuntingFoughtThem", "The one {0} were hunting fought them off.");
    // {0} CBPossessive(CBCapFirst(a))
    this.Text("Cyberbane-StreetEvents-PrisonerTurnedTheTablesOnThem", "{0} prisoner turned the tables on them.");
    // {0} a
    this.Text("Cyberbane-StreetEvents-TheOneWereHuntingGotAway", "The one {0} were hunting got away. Not your doing.");
    // {0} CBFactionLabel(mine), {1} pay
    this.Text("Cyberbane-StreetEvents-YouStoodWithAndTheStreet", "You stood with {0}, and the street is theirs. {1}eb, and friends who saw it.");
    // {0} CBFactionLabel(mine), {1} CBCapFirst(CBFactionLabel(winner))
    this.Text("Cyberbane-StreetEvents-YouStoodWithAndTheyLost", "You stood with {0}, and they lost the street. {1} will remember whose side you were on.");
    // {0} CBCapFirst(CBFactionLabel(winner)), {1} CBFactionLabel(loser)
    this.Text("Cyberbane-StreetEvents-WonTheStreetFightAgainstThe", "{0} won the street fight against {1}. The ground is theirs.");
    this.Text("Cyberbane-StreetEvents-IOweYouIOweYou", "I owe you. I owe you my life, merc.");
    this.Text("Cyberbane-StreetEvents-DonTKnowWhyYouDid", "Don't know why you did that. Thanks.");
    this.Text("Cyberbane-StreetEvents-IWonTForgetThisMy", "I won't forget this. My people won't either.");
    // {0} CBCapFirst(CBFactionLabel(slain.faction))
    this.Text("Cyberbane-StreetEvents-YouKilledBothOfThemAre", "You killed both of them. {0} are tearing themselves apart.");
    // {0} CBCapFirst(CBFactionLabel(slain.faction))
    this.Text("Cyberbane-StreetEvents-TheChairSMineYouMade", "The chair's mine. You made that happen. {0} won't forget it, and neither will I.");
    // {0} CBFactionLabel(slain.faction), {1} rivalName
    this.Text("Cyberbane-StreetEvents-IRunNowDoesnTThink", "I run {0} now. {1} doesn't think so. Kill them and I'll remember who helped.");
    // {0} heirName, {1} CBFactionLabel(slain.faction)
    this.Text("Cyberbane-StreetEvents-TookAChairThatShouldBe", "{0} took a chair that should be mine. Kill them, and {1} are your friends.");
  }

  // ---- StreetStories ---------------------------------------------------------------------------------------
  protected func DefineStreetStories() -> Void {
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-StreetStories-IMTellingYouReComing", "I'm telling {0} you're coming!");
    this.Text("Cyberbane-StreetStories-YouLlNeverFindThemNow", "You'll never find them now!");
    // {0} CBRivalDisplayName(sys.GetContent(), r)
    this.Text("Cyberbane-StreetStories-WhoeverYouLeanedOnRanAhead", "Whoever you leaned on ran ahead. {0} moved, and not far. The pin's where they went.");
    // {0} name
    this.Text("Cyberbane-StreetStories-AskYouSawWhere", "[Ask] You saw {0}. Where?");
    // {0} price
    this.Text("Cyberbane-StreetStories-PayEbYouNeverSawMe", "[Pay {0}eb] You never saw me.");
    this.Text("Cyberbane-StreetStories-ThenIRememberEverything", "Then I remember everything.");
    this.Text("Cyberbane-StreetStories-NeverSawYouNeverSawThem", "Never saw you. Never saw them either.");
    this.Text("Cyberbane-StreetStories-WhatFaceIMBadWith", "What face? I'm bad with faces.");
    this.Text("Cyberbane-StreetStories-RoundTheBackPastTheBins", "Round the back, past the bins. Their lookouts watch the front. Go quiet and nobody sees you coming.");
    this.Text("Cyberbane-StreetStories-TheyReThereAllRightCome", "They're there, all right. Come at it from the side street: their people only watch the main way in.");
    this.Text("Cyberbane-StreetStories-NobodyCameForItTheMoney", "Nobody came for it. The money's back where it belongs.");
    this.Text("Cyberbane-StreetStories-ThereWasNeverAnyMoneyLook", "There was never any money. Look around.");
    this.Text("Cyberbane-StreetStories-YouReallyCameWeReComing", "You really came. We're coming too.");
    // {0} war.dropAmount
    this.Text("Cyberbane-StreetStories-TheBagWasWhereTheySaid", "the bag was where they said: {0}eb.");
  }

  // ---- Wannabe ---------------------------------------------------------------------------------------------
  protected func DefineWannabe() -> Void {
    this.Text("Cyberbane-Wannabe-Wannabe", "Wannabe");
    // {0} you
    this.Text("Cyberbane-Wannabe-YouReDonTLookLike", "You're {0}? Don't look like much. Put 'em up.");
    this.Text("Cyberbane-Wannabe-EverybodySaysYouReTheReal", "Everybody says you're the real thing. Let's find out. Hands only.");
    this.Text("Cyberbane-Wannabe-NoGunsNoChromeTricksJust", "No guns, no chrome tricks. Just you and me. Come on.");
    this.Text("Cyberbane-Wannabe-BeatYouAndIMSomebody", "Beat you and I'm somebody. Ready?");
    this.Text("Cyberbane-Wannabe-MyCrewSWatchingDonT", "My crew's watching. Don't make me look bad, legend.");
    this.Text("Cyberbane-Wannabe-AKidCameAtYouWith", "A kid came at you with bare fists and you shot them. People saw.");
    this.Text("Cyberbane-Wannabe-BringingAGunToAFistfight", "Bringing a gun to a fistfight. With a kid. That's going round.");
    this.Text("Cyberbane-Wannabe-WannabeSFriend", "Wannabe's friend");
    this.Text("Cyberbane-Wannabe-GetUpHeSNotGetting", "Get up! ...He's not getting up. Let's go.");
    this.Text("Cyberbane-Wannabe-ToldHimToldHimItWas", "Told him. Told him it was a bad idea.");
    this.Text("Cyberbane-Wannabe-NobodySGonnaBelieveThisI", "Nobody's gonna believe this. I barely believe it.");
    this.Text("Cyberbane-Wannabe-ThatKidWhoSquaredUpTo", "That kid who squared up to you didn't get up. Ever. Half the block saw it.");
    this.Text("Cyberbane-Wannabe-AKidWantedAFistfightWith", "A kid wanted a fistfight with you and ended up in a body bag. People are talking.");
    this.Text("Cyberbane-Wannabe-ThatKidWhoSquaredUpTo-2", "That kid who squared up to you? Out cold. Half the block saw it.");
    this.Text("Cyberbane-Wannabe-SomebodyTriedToMakeTheirName", "Somebody tried to make their name off you. Now they're famous for the wrong reason.");
    this.Text("Cyberbane-Wannabe-TheKidWantedAStoryGot", "The kid wanted a story. Got one. Lost it.");
    this.Text("Cyberbane-Wannabe-YouSeeThatYouSEEThat", "You see that? You SEE that? Wait till everybody hears.");
    this.Text("Cyberbane-Wannabe-LegendMyAssComeOnLet", "Legend my ass. Come on, let's tell the block.");
    this.Text("Cyberbane-Wannabe-ThatSItThatSThe", "That's it? That's the legend? I'm telling everybody.");
    this.Text("Cyberbane-Wannabe-StayDownIMSomebodyNow", "Stay down. I'm somebody now.");
    this.Text("Cyberbane-Wannabe-ThoughtYouDBeHarderThanks", "Thought you'd be harder. Thanks for the story.");
    this.Text("Cyberbane-Wannabe-TheKidSTellingEverybodyYou", "The kid's telling everybody you wouldn't fight. Nobody who matters believes it.");
    this.Text("Cyberbane-Wannabe-YouWalkedAwayFromSomeKid", "You walked away from some kid's fistfight. Smart, or scared, depending who's telling it.");
  }

  // ---- BossBar ---------------------------------------------------------------------------------------------
  protected func DefineBossBar() -> Void {
    this.Text("Cyberbane-BossBar-HUNTINGYOU", "HUNTING YOU");
  }

  // ---- HubTab ----------------------------------------------------------------------------------------------
  protected func DefineHubTab() -> Void {
    this.Text("Cyberbane-HubTab-CYBERBANE", "CYBERBANE");
  }

  // ---- HubWeb ----------------------------------------------------------------------------------------------
  protected func DefineHubWeb() -> Void {
    this.Text("Cyberbane-HubWeb-OPENSEASON", "OPEN SEASON");
    this.Text("Cyberbane-HubWeb-TRACKER", "TRACKER");
    this.Text("Cyberbane-HubWeb-APRICEONYOU", "A PRICE ON YOU");
    this.Text("Cyberbane-HubWeb-PAYUP", "PAY UP");
    this.Text("Cyberbane-HubWeb-BACKED", "BACKED");
    this.Text("Cyberbane-HubWeb-SAFEPASSAGE", "SAFE PASSAGE");
    this.Text("Cyberbane-HubWeb-PEACEPAID", "PEACE PAID");
    this.Text("Cyberbane-HubWeb-OFF", "OFF");
    // {0} name
    this.Text("Cyberbane-HubWeb-FoughtInTheStreetToday", "Fought {0} in the street today.");
    // {0} name
    this.Text("Cyberbane-HubWeb-AtWarWithOverADistrict", "At war with {0} over a district.");
    // {0} name, {1} left
    this.Text("Cyberbane-HubWeb-InATruceWithAgainstYou", "In a truce with {0} against you, {1} hours left.");
    // {0} name
    this.Text("Cyberbane-HubWeb-InATruceWithAgainstYou-2", "In a truce with {0} against you.");
    // {0} name
    this.Text("Cyberbane-HubWeb-SetOnByALieOf", "Set on {0} by a lie of yours.");
    this.Text("Cyberbane-HubWeb-EachCardIsAGangWhat", "Each card is a gang: what they think of you, and the bar from red (out for blood) to green (on your side). The ones after you come first.\nClick a gang to see how every other gang stands with it, what it thinks of you, and to pay it off.");
    // {0} other
    this.Text("Cyberbane-HubWeb-FoughtToday", "Fought {0} today");
    // {0} other
    this.Text("Cyberbane-HubWeb-AtWarWith", "At war with {0}");
    // {0} other
    this.Text("Cyberbane-HubWeb-TruceWithAgainstYou", "Truce with {0} against you");
    // {0} other
    this.Text("Cyberbane-HubWeb-YouSetThemOn", "You set them on {0}");
    // {0} other
    this.Text("Cyberbane-HubWeb-OldFeudWith", "Old feud with {0}");
    // {0} other
    this.Text("Cyberbane-HubWeb-NoQuarrelWith", "No quarrel with {0}");
  }

  // ---- Hud -------------------------------------------------------------------------------------------------
  protected func DefineHud() -> Void {
    this.Text("Cyberbane-Hud-AnyMoment", "any moment");
    this.Text("Cyberbane-Hud-Soon", "soon");
    this.Text("Cyberbane-Hud-BeforeLong", "before long");
    this.Text("Cyberbane-Hud-Later", "later");
    // {0} secs
    this.Text("Cyberbane-Hud-S", "{0}s");
    // {0} mins, {1} secs
    this.Text("Cyberbane-Hud-M0S", "{0}m 0{1}s");
    // {0} mins, {1} secs
    this.Text("Cyberbane-Hud-MS", "{0}m {1}s");
    this.Text("Cyberbane-Hud-STANDING", "STANDING");
    this.Text("Cyberbane-Hud-GANGS", "GANGS");
    this.Text("Cyberbane-Hud-TURF", "TURF");
    this.Text("Cyberbane-Hud-THECITY", "THE CITY");
    this.Text("Cyberbane-Hud-RIVALS", "RIVALS");
    this.Text("Cyberbane-Hud-TITLES", "TITLES");
    this.Text("Cyberbane-Hud-HISTORY", "HISTORY");
    this.Text("Cyberbane-Hud-WhoYouAreInThisCity", "Who you are in this city, and what is on its way to you.");
    this.Text("Cyberbane-Hud-WhatEachGangThinksOfYou", "What each gang thinks of you. Click one to see more, or to pay them off.");
    this.Text("Cyberbane-Hud-WhoHoldsEachDistrictHowFirmly", "Who holds each district, how firmly, and who is fighting them for it.");
    this.Text("Cyberbane-Hud-WhereInNightCityYourName", "Where in Night City your name carries, district by district.");
    this.Text("Cyberbane-Hud-ThePeopleWhoHaveSurvivedYou", "The people who have survived you and are still looking. Click one for their file.");
    this.Text("Cyberbane-Hud-ThePeopleWhoWorkForYou", "The people who work for you: who is ready, who is restless, and what they are owed.");
    this.Text("Cyberbane-Hud-WhatTheStreetCallsYouAnd", "What the street calls you and what it gets you. Click any title to read it, or go by one you have earned.");
    this.Text("Cyberbane-Hud-TheLedgerWhatYouDidWhere", "The ledger: what you did, where, and who it was.");
    this.Text("Cyberbane-Hud-Up", "Up");
    this.Text("Cyberbane-Hud-Down", "Down");
    this.Text("Cyberbane-Hud-ClickAScreenOrARow", "Click a screen or a row for more      LB / RB on a controller      Esc / B: back");
    this.Text("Cyberbane-Hud-ModSettings", "Mod Settings");
    // {0} this.m_listTop + 1, {1} last, {2} total
    this.Text("Cyberbane-Hud-Of", "{0}-{1} of {2}");
    this.Text("Cyberbane-Hud-TheLastStartOverIsUndone", "the last Start over is undone. Load a save from before it, and its reputation, Rivals, crew and titles are back. Where Rivals were last seen and how hard you had hit each gang went with the Start over.");
    this.Text("Cyberbane-Hud-AGangCrew", "A gang crew");
    this.Text("Cyberbane-Hud-AnApexSquad", "An apex squad");
    this.Text("Cyberbane-Hud-HeadingHome", "Heading home");
    // {0} out
    this.Text("Cyberbane-Hud-WithYouNow", "{0} with you now");
    // {0} ready, {1} crew.Count()
    this.Text("Cyberbane-Hud-OfReadyToCall", "{0} of {1} ready to call");
    // {0} crew.CutOwed()
    this.Text("Cyberbane-Hud-OwedEb", "owed {0}eb");
    this.Text("Cyberbane-Hud-HowWidelyNightCityKnowsYour", "How widely Night City knows your name.");
    // {0} RoundF(earned)
    this.Text("Cyberbane-Hud-HeldHereByYourStreetCred", "Held here by your Street Cred. What you have done counts {0} so far.");
    // {0} RoundF(civ)
    this.Text("Cyberbane-Hud-HowFrighteningYouAreTheStreet", "How frightening you are. The street reads it as {0}: that is what makes people back off.");
    this.Text("Cyberbane-Hud-VisibleChrome", "Visible chrome");
    this.Text("Cyberbane-Hud-Conduct", "Conduct");
    this.Text("Cyberbane-Hud-LeavingPeopleAliveRaisesItKilling", "Leaving people alive raises it. Killing bystanders, shooting someone with their hands up and gory kills in front of witnesses lower it.");
    // {0} postureText
    this.Text("Cyberbane-Hud-Set", "{0} (set)");
    this.Text("Cyberbane-Hud-Off", "Off");
    this.Text("Cyberbane-Hud-OffHostile", "Off: hostile");
    // {0} CBRememberModShort()
    this.Text("Cyberbane-Hud-Hostile", "{0}: Hostile");
    this.Text("Cyberbane-Hud-SeenHostile", "Seen hostile");
    this.Text("Cyberbane-Hud-PAYINGOFF", "PAYING OFF");
    // {0} RoundF(score.GetFactionFear(fs.id))
    this.Text("Cyberbane-Hud-Fear", "fear {0}");
    // {0} enemy
    this.Text("Cyberbane-Hud-AtWar", "at war: {0}");
    // {0} fs.kills
    this.Text("Cyberbane-Hud-Down-2", "{0} down");
    // {0} StrUpper(CBFactionLabel(id)), {1} CBPostureName(score.GetPosture(id)), {2} (StrLen(ties) > 0 ? ties + "\n" : "")
    this.Text("Cyberbane-Hud-YouHaveNeverCrossedThemAnd", "{0}   {1}\n{2}You have never crossed them, and they have no opinion of you yet.");
    // {0} (StrLen(ties) > 0 ? ties + " " : ""), {1} CBPostureName(posture), {2} RoundF(score.GetStanding(id))
    this.Text("Cyberbane-Hud-ToYou", "{0}{1} to you, {2}.\n");
    this.Text("Cyberbane-Hud-SwitchedOffUnderFactionsInMod", "Switched off under Factions in Mod Settings. Cyberbane leaves them alone: nobody of theirs\nturns on you because of Cyberbane, they send nobody, and your standing is kept for later.\n");
    // {0} CBPostureName(posture), {1} CBPostureName(CBPostureFromStanding(fs.standing))
    this.Text("Cyberbane-Hud-SetToUnderHowGangsSee", "Set to {0} under How gangs see you in Mod Settings. What you have\nearned with them is {1}, and that comes back with Earned in play.\n");
    // {0} CBRememberModName()
    this.Text("Cyberbane-Hud-DecidesWhetherTheyAreHostileAnd", "{0} decides whether they are hostile, and Cyberbane follows it.\n");
    // {0} CBRememberModName(), {1} CBTwrHostilityWhy()
    this.Text("Cyberbane-Hud-DecidesWhetherTheyAreHostileBut", "{0} decides whether they are hostile, but could not be asked ({1}),\nso Cyberbane goes by what their people do: hostile while they have lately been hostile to you on\nsight, and otherwise its own standing, until it answers.\n");
    // {0} CBRememberModName()
    this.Text("Cyberbane-Hud-HasThemHostileOnSightTheir", "{0} has them hostile on sight: their people attack you when they know you.\nThat is its own record, kept apart from your standing here, and nothing here changes it.\n");
    this.Text("Cyberbane-Hud-TheirPeopleHaveBeenHostileTo", "Their people have been hostile to you on sight, and Cyberbane did not make them so:\nThey Will Remember, Night City Remembers, another mod or the game has them that way. Nothing here changes it.\n");
    // {0} leader
    this.Text("Cyberbane-Hud-LedBy", "Led by {0}.\n");
    // {0} enemy, {1} enemy
    this.Text("Cyberbane-Hud-AtWarWithHurtingIsHow", "At war with {0}. Hurting {1} is how this gang comes to like you.\n");
    // {0} fs.kills, {1} RoundF(score.GetFactionFear(id))
    this.Text("Cyberbane-Hud-OfTheirsDownTheyFearYou", "{0} of theirs down. They fear you at {1} of 100.\n");
    this.Text("Cyberbane-Hud-TheyAreBrokenTheirPeopleFear", "They are broken. Their people fear you whatever their grudge, they only send anyone when you have just hurt them, and they would settle for less.\n");
    // {0} held
    this.Text("Cyberbane-Hud-AboutIn10OfTheirPeople", "About {0} in 10 of their people are too afraid of you to act on it. Those you can talk to.\n");
    this.Text("Cyberbane-Hud-NoneOfThemAreAfraidEnough", "None of them are afraid enough of you to hold back.\n");
    // {0} both
    this.Text("Cyberbane-Hud-RightNow", "Right now: {0}.\n");
    // {0} quote
    this.Text("Cyberbane-Hud-Eb", "{0}eb");
    this.Text("Cyberbane-Hud-WhatTheyAsk", "what they ask");
    // {0} price
    this.Text("Cyberbane-Hud-YouArePayingThemItGoes", "You are paying them {0}. It goes through in the next few seconds of play,\nand anything they had on its way to you is called off.");
    this.Text("Cyberbane-Hud-CancelThePayment", "Cancel the payment");
    // {0} quote, {1} money
    this.Text("Cyberbane-Hud-TheyWillCallItOffFor", "They will call it off for {0}eb. You have {1}eb.");
    this.Text("Cyberbane-Hud-ClickAgainToPay", "\nClick again to pay.");
    // {0} quote
    this.Text("Cyberbane-Hud-ConfirmPayEb", "Confirm: pay {0}eb");
    // {0} quote
    this.Text("Cyberbane-Hud-PayThemOffEb", "Pay them off: {0}eb");
    this.Text("Cyberbane-Hud-NotEnoughEddies", "Not enough eddies");
    // {0} quiet
    this.Text("Cyberbane-Hud-Quiet", "quiet {0}");
    this.Text("Cyberbane-Hud-NothingYet", "nothing yet");
    this.Text("Cyberbane-Hud-NOGANG", "NO GANG");
    this.Text("Cyberbane-Hud-1Rival", "1 Rival");
    // {0} n
    this.Text("Cyberbane-Hud-Rivals", "{0} Rivals");
    // {0} r.rank
    this.Text("Cyberbane-Hud-Rank", "rank {0}");
    this.Text("Cyberbane-Hud-HereNow", "here now");
    this.Text("Cyberbane-Hud-AtTheirPlace", "at their place");
    // {0} CBWhen(sys.GetLaneTicks(CBLaneRival()))
    this.Text("Cyberbane-Hud-Arrives", "arrives {0}");
    this.Text("Cyberbane-Hud-LyingLow", "lying low");
    this.Text("Cyberbane-Hud-YouKnowWhere", "you know where");
    this.Text("Cyberbane-Hud-KeepThem", "Keep them");
    this.Text("Cyberbane-Hud-BuyingAnotherLocation", "Buying another location");
    this.Text("Cyberbane-Hud-ConfirmPutTheWordOut", "Confirm: put the word out");
    // {0} price
    this.Text("Cyberbane-Hud-AskAroundAboutEb", "Ask around: about {0}eb");
    // {0} price
    this.Text("Cyberbane-Hud-AmbushThemEb", "Ambush them: {0}eb");
    this.Text("Cyberbane-Hud-HideoutsAreOff", "Hideouts are off");
    this.Text("Cyberbane-Hud-OutAfterYouNow", "Out after you now");
    this.Text("Cyberbane-Hud-YouKnowWhereTheyAre", "You know where they are");
    this.Text("Cyberbane-Hud-TheirFactionIsOff", "Their faction is off");
    this.Text("Cyberbane-Hud-KeepThisOne", "Keep this one");
    this.Text("Cyberbane-Hud-OneOfYourCrew", "One of your crew");
    this.Text("Cyberbane-Hud-OnTheirWayWait", "On their way: wait");
    this.Text("Cyberbane-Hud-ClickAgainToForget", "Click again to forget");
    this.Text("Cyberbane-Hud-ForgetThisRival", "Forget this rival");
    this.Text("Cyberbane-Hud-WordSent", "Word sent");
    this.Text("Cyberbane-Hud-SendingWord", "Sending word");
    this.Text("Cyberbane-Hud-SendWord", "Send word");
    // {0} count
    this.Text("Cyberbane-Hud-ClickAgainForgetAll", "Click again: forget all {0}");
    this.Text("Cyberbane-Hud-ForgetEveryRival", "Forget every rival");
    // {0} CBHudActiveTitle(sys)
    this.Text("Cyberbane-Hud-Automatic", "Automatic: {0}");
    this.Text("Cyberbane-Hud-Automatic-2", "Automatic");
    this.Text("Cyberbane-Hud-GOINGBY", "GOING BY");
    this.Text("Cyberbane-Hud-EARNED", "EARNED");
    this.Text("Cyberbane-Hud-LOCKED", "LOCKED");
    this.Text("Cyberbane-Hud-EMPTYCHAIR", "EMPTY CHAIR");
    // {0} StrUpper(CBHudNameNoNick(empty))
    this.Text("Cyberbane-Hud-NEXT", "NEXT: {0}");
    this.Text("Cyberbane-Hud-NOBODYYET", "NOBODY YET");
    this.Text("Cyberbane-Hud-LEFTNIGHTCITY", "LEFT NIGHT CITY");
    this.Text("Cyberbane-Hud-KILLEDNOTBYYOU", "KILLED, NOT BY YOU");
    this.Text("Cyberbane-Hud-DEADBYYOURHAND", "DEAD BY YOUR HAND");
    this.Text("Cyberbane-Hud-HuntingYou", "hunting you");
    // {0} r.rank, {1} StrUpper(hunting ? "hunting you" : CBRivalStateName(r.state))
    this.Text("Cyberbane-Hud-RANK", "RANK {0}  {1}");
    // {0} r.encounters
    this.Text("Cyberbane-Hud-YourNemesisMetTimes", "Your nemesis: met {0} times");
    // {0} r.encounters, {1} r.escapes, {2} r.sparedByV
    this.Text("Cyberbane-Hud-MetRanSpared", "Met {0}, ran {1}, spared {2}");
    this.Text("Cyberbane-Hud-NeverMetYou", "Never met you");
    this.Text("Cyberbane-Hud-NEXTGANG", "NEXT GANG");
    this.Text("Cyberbane-Hud-YOU", "YOU");
    this.Text("Cyberbane-Hud-NoRivalsYet", "No Rivals yet");
    this.Text("Cyberbane-Hud-NoGang", "No gang");
    // {0} ArrayFindFirst(gangs, gang) + 1, {1} ArraySize(gangs)
    this.Text("Cyberbane-Hud-OF", "  ({0} OF {1})");
    this.Text("Cyberbane-Hud-LIEUTENANTS", "LIEUTENANTS");
    this.Text("Cyberbane-Hud-THEREST", "THE REST");
    this.Text("Cyberbane-Hud-THEFALLEN", "THE FALLEN");
    this.Text("Cyberbane-Hud-WAR", "WAR");
    this.Text("Cyberbane-Hud-WARS", "WARS");
    // {0} wars, {1} wars == 1 ? "WAR" : "WARS"
    this.Text("Cyberbane-Hud-WON", "  /  {0} {1} WON");
    // {0} book.Count(), {1} (wars > 0 ? s"  /  \(wars) \(wars == 1 ? "WAR" : "WARS") WON" : "")
    this.Text("Cyberbane-Hud-ONTHEROSTER", "{0} ON THE ROSTER{1}");
    // {0} CBCrewStandWord(v), {1} CBPhoneGangSender(gang)
    this.Text("Cyberbane-Hud-With", "{0} with {1}");
    this.Text("Cyberbane-Hud-NoGangHoldsAGrudgeYet", "No gang holds a grudge yet");
    // {0} CBCapFirst(CBPhoneGangSender(holder)), {1} RoundF(shares[top] * 100.0)
    this.Text("Cyberbane-Hud-Hold", "{0} hold {1}%");
    this.Text("Cyberbane-Hud-NobodyHoldsIt", "Nobody holds it");
    this.Text("Cyberbane-Hud-YourStreets", "Your streets");
    // {0} rd
    this.Text("Cyberbane-Hud-Renown", "Renown {0}");
    this.Text("Cyberbane-Hud-OnePutDownHere", "One put down here");
    // {0} kills
    this.Text("Cyberbane-Hud-PutDownHere", "{0} put down here");
    this.Text("Cyberbane-Hud-NothingYet-2", "Nothing yet");
    this.Text("Cyberbane-Hud-EachCardIsADistrictAnd", "Each card is a district and the gang holding it, coloured by how they treat you: green friendly, amber hostile, red out for blood. The bar is how firmly they hold it. White frame: you are here.\nClick a district for who else wants it, and how far your name carries there.");
    this.Text("Cyberbane-Hud-EachCardIsADistrictAnd-2", "Each card is a district and how far your name carries there: red a legend, amber known, cyan heard of. The bar is your renown. White frame: you are here.\nClick a district for what you have done there.");
    this.Text("Cyberbane-Hud-YouAreHere", "   (you are here)");
    // {0} CBCapFirst(CBFactionLabel(holder))
    this.Text("Cyberbane-Hud-HoldIt", "{0} hold it. ");
    // {0} list
    this.Text("Cyberbane-Hud-WhoHasStreetsHere", "Who has streets here: {0}.\n");
    this.Text("Cyberbane-Hud-NoGangHasStreetsHere", "No gang has streets here.\n");
    this.Text("Cyberbane-Hud-NobodyRunsItButYouThe", "Nobody runs it but you. The gangs pass through on your say-so.\n");
    // {0} renown
    this.Text("Cyberbane-Hud-YourNameHereOf100", "Your name here: {0} of 100.");
    // {0} peak
    this.Text("Cyberbane-Hud-AtItsHeight", ", at its height {0}");
    // {0} renown, {1} (peak > renown ? s", at its height \(peak)" : "")
    this.Text("Cyberbane-Hud-YourRenownHereOf100", "Your renown here: {0} of 100{1}.\n");
    // {0} ds.lethalOrBrutal
    this.Text("Cyberbane-Hud-OfThemTheHardWay", ", {0} of them the hard way");
    // {0} ds.quietTakedowns
    this.Text("Cyberbane-Hud-TakenDownWithoutASound", ", {0} taken down without a sound");
    // {0} quiet
    this.Text("Cyberbane-Hud-TheLastTroubleHereWasAgo", "The last trouble here was {0} ago.");
    this.Text("Cyberbane-Hud-YouHaveNotMadeAnyTrouble", "You have not made any trouble here yet.");
    this.Text("Cyberbane-Hud-SendingThemHomeClickToTake", "Sending them home. Click to take it back");
    this.Text("Cyberbane-Hud-SendThemHome", "Send them home");
    this.Text("Cyberbane-Hud-CallingThemClickToTakeIt", "Calling them. Click to take it back");
    this.Text("Cyberbane-Hud-TheyLlAnswerOnceYouRe", "They'll answer once you're back in the game.\n");
    // {0} StrLower(StrLeft(blocked, 1)), {1} StrRight(blocked, StrLen(blocked) - 1)
    this.Text("Cyberbane-Hud-CanTCallThemNow", "Can't call them now: {0}\n");
    this.Text("Cyberbane-Hud-NothingOnYouRightNowTwo", "Nothing on you right now: two will come and walk with you until you send them home.\n");
    this.Text("Cyberbane-Hud-PayingClickToTakeItBack", "Paying. Click to take it back");
    // {0} book.CutOwed()
    this.Text("Cyberbane-Hud-PayTheCutEb", "Pay the cut: {0}eb");
    // {0} CBCrewFirst(sys, m)
    this.Text("Cyberbane-Hud-OrdersFor", "Orders for {0}");
    this.Text("Cyberbane-Hud-HiringClickToTakeItBack", "Hiring. Click to take it back");
    // {0} book.offerPrice
    this.Text("Cyberbane-Hud-HireTheSoloEb", "Hire the solo: {0}eb");
    this.Text("Cyberbane-Hud-ASoloIsOnOfferPick", "A solo is on offer: pick them to hire them.\n");
    this.Text("Cyberbane-Hud-NameColoursTheFallen", "Name, colours, the fallen");
    // {0} kbWars.WarsWon()
    this.Text("Cyberbane-Hud-WarsYourCrewStartedAndWon", "Wars your crew started and won: {0}.\n");
    this.Text("Cyberbane-Hud-SaveTheName", "Save the name");
    this.Text("Cyberbane-Hud-Cancel", "Cancel");
    this.Text("Cyberbane-Hud-TypeANameForYourCrew", "Type a name for your crew, then save it. Letters, numbers, spaces and - ' . & ! only, up to 24. Save it empty to go without one.");
    // {0} name
    this.Text("Cyberbane-Hud-PickAWeaponForItsMods", "Pick a weapon for {0}. Its mods and attachments go back in your bag. From their next call they fight the way it is used, and it adds to their damage by its quality. Take it back any time; it comes back if they leave.");
    // {0} name, {1} CBCrewChromeSlots()
    this.Text("Cyberbane-Hud-PickChromeForFromWhatYou", "Pick chrome for {0}, from what you own and do not wear. It goes in for good and does for them what it does in a fight, by the game's own numbers. Chrome that only helps you (RAM, zoom, stamina) is not listed. Up to {1}.");
    this.Text("Cyberbane-Hud-YouHaveNoSpareWeaponTo", "You have no spare weapon to give: everything is equipped, or there is nothing a person could fight with.");
    this.Text("Cyberbane-Hud-YouHaveNoSpareChromeThat", "You have no spare chrome that would help them in a fight: what you own is installed in you, or only helps you.");
    // {0} StrLower(CBCrewStandWord(stand))
    this.Text("Cyberbane-Hud-YourCrew", "your crew: {0}");
    // {0} name, {1} RoundF(CBConfig.CrewWarHours()), {2} name
    this.Text("Cyberbane-Hud-PickAGangForToStart", "Pick a gang for {0} to start a war on. Away {1} hours. Won, the gang loses ground and blames you; lost, {2} comes back hurt, or not at all. The weaker the gang, the better the odds, and a gang that already hates your crew is ready for it.");
    this.Text("Cyberbane-Hud-NoGangToGoToWar", "No gang to go to war on: every gang that fields people is friendly with you.");
    this.Text("Cyberbane-Hud-Back", "Back");
    this.Text("Cyberbane-Hud-HandingItBack", "Handing it back...");
    this.Text("Cyberbane-Hud-TakeYourWeaponBack", "Take your weapon back");
    this.Text("Cyberbane-Hud-AWeaponOnItsWay", "A weapon on its way...");
    this.Text("Cyberbane-Hud-GiveThemAWeapon", "Give them a weapon");
    this.Text("Cyberbane-Hud-NothingOfYours", "nothing of yours");
    this.Text("Cyberbane-Hud-ChromeOnItsWay", "Chrome on its way...");
    this.Text("Cyberbane-Hud-HaveChromePutIn", "Have chrome put in");
    this.Text("Cyberbane-Hud-NoRoomForMoreChrome", "No room for more chrome");
    // {0} chrome, {1} CBCrewChromeSlots()
    this.Text("Cyberbane-Hud-OfFitted", "{0} of {1} fitted");
    this.Text("Cyberbane-Hud-FullyTrained", "Fully trained");
    // {0} trained, {1} CBConfig.CrewTrainMax()
    this.Text("Cyberbane-Hud-OfDone", "{0} of {1} done");
    this.Text("Cyberbane-Hud-OffToTrain", "Off to train...");
    this.Text("Cyberbane-Hud-SendThemToTrain", "Send them to train");
    this.Text("Cyberbane-Hud-HurtNotYet", "hurt: not yet");
    // {0} RoundF(CBCrewTrainHours(k))
    this.Text("Cyberbane-Hud-AwayHours", "away {0} hours");
    // {0} cost
    this.Text("Cyberbane-Hud-EB", "{0}EB");
    this.Text("Cyberbane-Hud-SendThemToStartAWar", "Send them to start a war");
    // {0} CBCrewRankWord(CBConfig.CrewWarMinRank())
    this.Text("Cyberbane-Hud-Needs", "needs {0}");
    this.Text("Cyberbane-Hud-OffToWar", "Off to war...");
    this.Text("Cyberbane-Hud-SparringNow", "Sparring now");
    this.Text("Cyberbane-Hud-ComingToSpar", "Coming to spar...");
    this.Text("Cyberbane-Hud-SparWithThem", "Spar with them");
    this.Text("Cyberbane-Hud-PutThemToWorkEarning", "Put them to work earning");
    this.Text("Cyberbane-Hud-PutThemToRecruiting", "Put them to recruiting");
    this.Text("Cyberbane-Hud-StopTheirWork", "Stop their work");
    this.Text("Cyberbane-Hud-TellingThem", "Telling them...");
    // {0} CBCrewWorkWord(work)
    this.Text("Cyberbane-Hud-Now", "now: {0}");
    // {0} CBConfig.CrewEarnPerRank() * rank
    this.Text("Cyberbane-Hud-EBADAY", "{0}EB A DAY");
    this.Text("Cyberbane-Hud-LeavingYourCrew", "leaving your crew");
    this.Text("Cyberbane-Hud-ClickAgainToLetGo", "Click again to let go");
    this.Text("Cyberbane-Hud-LetThemGo", "Let them go");
    this.Text("Cyberbane-Hud-WithYouWait", "with you: wait");
    // {0} CBCrewFile(sys, game, book, m, false), {1} CBCrewKitLines(sys, game, m)
    this.Text("Cyberbane-Hud-OrdersHappenAsYouPickThem", "{0}\n{1}\nOrders happen as you pick them; their texts come once you are back in the game. A spar waits for the game: click it again before then to call it off. One of your crew recruits at a time.");
    // {0} text
    this.Text("Cyberbane-Hud-WithYouNowOrdersWaitUntil", "With you now: orders wait until they are home.\n{0}");
    this.Text("Cyberbane-Hud-RenameYourCrew", "Rename your crew");
    this.Text("Cyberbane-Hud-NameYourCrew", "Name your crew");
    this.Text("Cyberbane-Hud-NoNameYet", "no name yet");
    this.Text("Cyberbane-Hud-ChangeItsColours", "Change its colours");
    this.Text("Cyberbane-Hud-ClickForTheNext", "click for the next");
    this.Text("Cyberbane-Hud-RememberTheFallen", "Remember the fallen");
    this.Text("Cyberbane-Hud-NobodyYet", "nobody yet");
    this.Text("Cyberbane-Hud-YOURCREW", "YOUR CREW");
    this.Text("Cyberbane-Hud-War", "war");
    this.Text("Cyberbane-Hud-Wars", "wars");
    // {0} wars, {1} wars == 1 ? "war" : "wars"
    this.Text("Cyberbane-Hud-Won", ", {0} {1} won.");
    // {0} (StrLen(name) > 0 ? StrUpper(name) : "YOUR CREW"), {1} book.Count(), {2} fallen, {3} (wars > 0 ? s", \(wars) \(wars == 1 ? "war" : "wars") won." : ".")
    this.Text("Cyberbane-Hud-OnTheRosterFallen", "{0}\n{1} on the roster, {2} fallen{3}\n");
    this.Text("Cyberbane-Hud-NoGangThinksAnythingOfYour", "No gang thinks anything of your crew yet.\n");
    this.Text("Cyberbane-Hud-YourCrewHasItsOwnStanding", "Your crew has its own standing with the gangs, apart from yours. A war it starts sets that gang against it, more when it wins, and pleases the gang at war with them. A gang that lends you somebody warms to it; one whose people it scares into joining or kills cools, and so does one that kills one of yours. A gang that hates your crew is ready for its next war. It all eases a little every day.");
    this.Text("Cyberbane-Hud-THEFALLENTheOnesWhoDied", "THE FALLEN\nThe ones who died for your crew, and what they carried. Pick a name to read what is remembered of them.");
    this.Text("Cyberbane-Hud-THEFALLENNobodyFromYourCrew", "THE FALLEN\nNobody from your crew has died yet.");
    this.Text("Cyberbane-Hud-ASoloOnOffer", "a solo on offer");
    // {0} book.Count(), {1} CBConfig.MyCrewRoster()
    this.Text("Cyberbane-Hud-YOURCREWOF", "YOUR CREW  ({0} OF {1})");
    // {0} StrUpper(book.offerSender)
    this.Text("Cyberbane-Hud-ONOFFERFROM", "ON OFFER FROM {0}");
    // {0} StrUpper(CBCrewSeatWord(seat)), {1} book.offerPrice
    this.Text("Cyberbane-Hud-EB-2", "{0}  /  {1}EB");
    this.Text("Cyberbane-Hud-ASoloForHire", "A solo for hire");
    this.Text("Cyberbane-Hud-GONE", "GONE");
    this.Text("Cyberbane-Hud-Nobody", "Nobody");
    this.Text("Cyberbane-Hud-ShowAsAList", "Show as a list");
    this.Text("Cyberbane-Hud-PayingItOffClickToTake", "Paying it off. Click to take it back");
    // {0} payOff
    this.Text("Cyberbane-Hud-ClickAgainPayEb", "Click again: pay {0}eb");
    // {0} payOff
    this.Text("Cyberbane-Hud-PayOffThePriceOnYou", "Pay off the price on you ({0}eb)");
    this.Text("Cyberbane-Hud-ClickAgainEraseItAll", "Click again: erase it all");
    this.Text("Cyberbane-Hud-StartOver", "Start over");
    this.Text("Cyberbane-Hud-ShowTheLedger", "Show the ledger");
    this.Text("Cyberbane-Hud-TellMyStory", "Tell my story");
    this.Text("Cyberbane-Hud-ClickAgainUndoIt", "Click again: undo it");
    this.Text("Cyberbane-Hud-UndoTheLastStartOver", "Undo the last Start over");
    // {0} CBTimeText(sys.GetPendingApexTicks())
    this.Text("Cyberbane-Hud-APEXSQUADDRIVING", "APEX SQUAD DRIVING {0}");
    // {0} CBWhen(sys.GetPendingApexTicks())
    this.Text("Cyberbane-Hud-APEXSQUAD", "APEX SQUAD {0}");
    // {0} why
    this.Text("Cyberbane-Hud-HELD", "HELD: {0}");
    this.Text("Cyberbane-Hud-CREWHELDUP", "CREW HELD UP");
    // {0} CBTimeText(sys.GetPendingSquadTicks())
    this.Text("Cyberbane-Hud-CREWINBOUND", "CREW INBOUND {0}");
    // {0} CBWhen(sys.GetLaneTicks(CBLaneSquad()))
    this.Text("Cyberbane-Hud-CREW", "CREW {0}");
    this.Text("Cyberbane-Hud-SwitchedOffUnderFactionsInMod-2", "Switched off under Factions in Mod Settings: Cyberbane leaves them alone, so there is nothing to pay them for.");
    this.Text("Cyberbane-Hud-HowTheyTreatYouIsSet", "How they treat you is set under How gangs see you in Mod Settings, so money changes nothing. Set them to Earned in play to deal.");
    this.Text("Cyberbane-Hud-NobodyHereTakesMoneyToForget", "Nobody here takes money to forget you. Corporations and the law cannot be bought off.");
    this.Text("Cyberbane-Hud-TheyLikeYouFriendlyGangsCut", "They like you. Friendly gangs cut their prices on their own turf and warn you when their enemies come for you.");
    this.Text("Cyberbane-Hud-TheyAreNotHostileSoThere", "They are not hostile, so there is nothing to pay them for.");
    this.Text("Cyberbane-Hud-NoTitleYet", "No title yet");
    // {0} label, {1} CBNumberWord(together)
    this.Text("Cyberbane-Hud-HereNowOfThemTogether", "{0}   here now, {1} of them together");
    // {0} label
    this.Text("Cyberbane-Hud-HereNow-2", "{0}   here now");
    // {0} label
    this.Text("Cyberbane-Hud-Off-2", "{0}   off");
    // {0} label, {1} held
    this.Text("Cyberbane-Hud-Waiting", "{0}   waiting: {1}");
    // {0} label, {1} CBTimeText(rest)
    this.Text("Cyberbane-Hud-Breather", "{0}   breather, {1}");
    // {0} label
    this.Text("Cyberbane-Hud-EveryRivalIsLyingLow", "{0}   every Rival is lying low");
    this.Text("Cyberbane-Hud-NobodyHasEarnedIt", "   nobody has earned it");
    this.Text("Cyberbane-Hud-NobodyHoldsAGrudge", "   nobody holds a grudge");
    // {0} CBCapFirst(whose)
    this.Text("Cyberbane-Hud-IsReadyToMove", "{0} is ready to move");
    this.Text("Cyberbane-Hud-Ready", "ready");
    // {0} CBCapFirst(whose)
    this.Text("Cyberbane-Hud-Moves", "{0} moves ");
    this.Text("Cyberbane-Hud-Next", "next ");
    // {0} CBHudRealFromGameHours(inSecs / CBConfig.SecondsPerHour())
    this.Text("Cyberbane-Hud-InAbout", "in about {0}");
    // {0} label, {1} who, {2} held, {3} CBHudBudgetTail(sys, game, lane)
    this.Text("Cyberbane-Hud-Waiting-2", "{0}   {1}  waiting: {2}{3}");
    // {0} label, {1} who, {2} why, {3} tail
    this.Text("Cyberbane-Hud-Held", "{0}   {1}  held: {2}{3}");
    // {0} label, {1} who, {2} tail
    this.Text("Cyberbane-Hud-AnyMoment-2", "{0}   {1}  any moment{2}");
    // {0} RoundF(secs / 3600.0)
    this.Text("Cyberbane-Hud-H", "{0}h");
    // {0} RoundF(secs / 60.0)
    this.Text("Cyberbane-Hud-M", "{0}m");
    this.Text("Cyberbane-Hud-Off-3", "   (off)");
    this.Text("Cyberbane-Hud-RightNowCyberbaneIsSwitchedOff", "Right now: Cyberbane is switched off in Mod Settings (Enabled, under General), so nothing reacts.");
    this.Text("Cyberbane-Hud-RightNowCrowdReactionsAreSwitched", "Right now: crowd reactions are switched off in Mod Settings.");
    this.Text("Cyberbane-Hud-RightNowTheGameCallsThis", "Right now: the game calls this a safe area, so nobody here reacts. Step outside.");
    this.Text("Cyberbane-Hud-RightNowCyberbaneIsNotTracking", "Right now: Cyberbane is not tracking anybody nearby, so nobody can react yet.");
    // {0} reg.Count()
    this.Text("Cyberbane-Hud-RightNowYourFaceIsCovered", "Right now: your face is covered, so nobody can place you and nobody reacts. ({0} tracked)");
    // {0} r, {1} reg.Count()
    this.Text("Cyberbane-Hud-RightNowPeopleRunWhenYou", "Right now: people run when you come within {0} metres. ({1} tracked)");
    // {0} r, {1} reg.Count()
    this.Text("Cyberbane-Hud-RightNowPeopleFreezeWithTheir", "Right now: people freeze with their hands up within {0} metres, and step aside further out. ({1} tracked)");
    // {0} r, {1} reg.Count()
    this.Text("Cyberbane-Hud-RightNowPeopleFlinchAndStep", "Right now: people flinch and step out of your way within {0} metres. ({1} tracked)");
    // {0} r, {1} reg.Count()
    this.Text("Cyberbane-Hud-RightNowPeopleLookOverAt", "Right now: people look over at you within {0} metres. ({1} tracked)");
    // {0} need, {1} reg.Count()
    this.Text("Cyberbane-Hud-RightNowNobodyLooksTwiceYet", "Right now: nobody looks twice yet, about {0} short. ({1} tracked)");
    this.Text("Cyberbane-Hud-NothingInParticularYet", "nothing in particular yet");
    this.Text("Cyberbane-Hud-YourBodyCount", "your body count");
    this.Text("Cyberbane-Hud-ItFadesWhileYouLieLow", "It fades while you lie low.");
    this.Text("Cyberbane-Hud-AllThatChrome", "all that chrome");
    this.Text("Cyberbane-Hud-LongSleevesTrousersAndAMask", "Long sleeves, trousers and a mask hide most of it.");
    this.Text("Cyberbane-Hud-TheWayYouCarryYourself", "the way you carry yourself");
    this.Text("Cyberbane-Hud-DressDownAndItEases", "Dress down and it eases.");
    this.Text("Cyberbane-Hud-TheThingsYouHaveDone", "the things you have done");
    this.Text("Cyberbane-Hud-TheStoriesFadeWhileYouLie", "The stories fade while you lie low.");
    this.Text("Cyberbane-Hud-TheHeatYouDrawFromThe", "the heat you draw from the law");
    this.Text("Cyberbane-Hud-StayOffTheNCPDSRadar", "Stay off the NCPD's radar and it cools.");
    this.Text("Cyberbane-Hud-PeopleBarelyKnowYouMakeSome", "People barely know you. Make some noise.");
    // {0} bestLabel, {1} bestHint
    this.Text("Cyberbane-Hud-PeopleFearYouMostlyFor", "People fear you mostly for {0}. {1}");
  }

  // ---- Hud (2) -------------------------------------------------------------------------------------------------
  protected func DefineHud2() -> Void {
    this.Text("Cyberbane-Hud-NoGangHasFormedAnOpinion", "No gang has formed an opinion of you yet.\n\nWork in their territory and that changes quickly.");
    this.Text("Cyberbane-Hud-HostileGangsSendCrewsVendettaMeans", "Hostile gangs send crews. Vendetta means their people shoot on sight, all but the ones too afraid of you to. Hostile and sworn gangs are listed first.\n\n");
    this.Text("Cyberbane-Hud-ToBeThoughtWellOfHurt", "To be thought well of: hurt the gang they are at war with, put their people down\n");
    this.Text("Cyberbane-Hud-WithoutKillingThemLetTheirNames", "without killing them, let their names walk, spend time on their streets without\n");
    this.Text("Cyberbane-Hud-TroubleOrWalkUpToTheir", "trouble, or walk up to their people and greet them. Friendly gangs cut their prices on\n");
    this.Text("Cyberbane-Hud-TheirOwnTurfAndWarnYou", "their own turf and warn you when their enemies come for you. To be feared without a\n");
    this.Text("Cyberbane-Hud-BodyIntimidateTheirPeopleSomebodyAfraid", "body: intimidate their people. Somebody afraid enough gives up one of their Rivals.\n\n");
    this.Text("Cyberbane-Hud-ClickAGangToSeeMore", "Click a gang to see more about them, and to pay off one that wants you dead.");
    this.Text("Cyberbane-Hud-YourNameHasNotTravelledTo", "Your name has not travelled to any district yet.");
    this.Text("Cyberbane-Hud-WordSpreadsOutwardFromWhereThings", "Word spreads outward from where things happened, so you can be a legend in one district and a nobody in the next. The bar is how widely your name carries there.");
    this.Text("Cyberbane-Hud-WALLEDOFF", "WALLED OFF");
    // {0} CBBarFactionLabel(book.Challenger(CBDistrictIndex(district)))
    this.Text("Cyberbane-Hud-MOVINGIN", "{0} MOVING IN");
    // {0} CBBarFactionLabel(ids[second]), {1} RoundF(shares[second] * 100.0)
    this.Text("Cyberbane-Hud-VS", "VS {0} {1}%");
    this.Text("Cyberbane-Hud-MOVEDIN", "MOVED IN");
    this.Text("Cyberbane-Hud-SHARED", "SHARED");
    this.Text("Cyberbane-Hud-HELD-2", "HELD");
    this.Text("Cyberbane-Hud-TurfWarsAreOffInMod", "Turf wars are off in Mod Settings: every gang keeps its own streets whatever you do to it.");
    this.Text("Cyberbane-Hud-EveryGangIsAtFullStrength", "Every gang is at full strength. Hurt one and its grip on its streets slips; break one and the gang at war with it next door moves in.");
    // {0} out
    this.Text("Cyberbane-Hud-TheyRebuildWhileYouLeaveThem", "{0}They rebuild while you leave them alone, and your work counts double on their own streets. Break one and the gang at war with it next door moves in, and stays until somebody takes it back.");
    this.Text("Cyberbane-Hud-TheyGotAwayFromYouBleeding", "They got away from you bleeding.");
    this.Text("Cyberbane-Hud-YouBeatThemDownAndLeft", "You beat them down and left them alive.");
    this.Text("Cyberbane-Hud-TheyPutYouDownOnce", "They put you down once.");
    this.Text("Cyberbane-Hud-TheyAreAvengingSomeoneYouKilled", "They are avenging someone you killed.");
    this.Text("Cyberbane-Hud-TheyCameForYourHeadAnd", "They came for your head and lost you.");
    this.Text("Cyberbane-Hud-TheyRanWithYourCrewThen", "They ran with your crew, then turned on you.");
    this.Text("Cyberbane-Hud-TheyRememberYou", "They remember you.");
    this.Text("Cyberbane-Hud-TheyAreDead", "They are dead.");
    this.Text("Cyberbane-Hud-TheyHaveLeftNightCity", "They have left Night City.");
    this.Text("Cyberbane-Hud-TheyAreHuntingYou", "They are hunting you.");
    this.Text("Cyberbane-Hud-TheyOweYouTheirLife", "They owe you their life.");
    this.Text("Cyberbane-Hud-TheyHaveGoneQuiet", "They have gone quiet.");
    this.Text("Cyberbane-Hud-TheyAreAtLargeAndNext", "They are at large, and next in line to come for you.");
    this.Text("Cyberbane-Hud-TheyAreAtLarge", "They are at large.");
    this.Text("Cyberbane-Hud-EveryRivalIsForgottenInThe", "Every rival is forgotten in the next few seconds of play.\n\nThe ones out looking for you stop, and nobody on this list comes after you again.\nIt sticks: quitting now, or loading an older save of this playthrough, forgets them too.\nClick the button again to keep them after all.");
    this.Text("Cyberbane-Hud-NoActiveRivalsYetLeaveSomeone", "No active rivals yet.\n\nLeave someone alive after you put them down, or let a wounded\nenemy get away, and one of them will come back with your name.");
    // {0} strong
    this.Text("Cyberbane-Hud-Strengths", "Strengths: {0}.\n");
    // {0} weak
    this.Text("Cyberbane-Hud-WeakSpots", "Weak spots: {0}.\n");
    // {0} CBFlawWord(flaw)
    this.Text("Cyberbane-Hud-FatalFlawKillsThemOutright", "Fatal flaw: {0} kills them outright.\n");
    this.Text("Cyberbane-Hud-TheirPeopleMayKnowAFatal", "Their people may know a fatal flaw. Squeeze one, scan one, or ask around.\n");
    // {0} CBRivalStreetStatus(sys, game, r)
    this.Text("Cyberbane-Hud-OnTheStreet", "On the street: {0}\n");
    // {0} CBRivalCatchphrase(r)
    this.Text("Cyberbane-Hud-Says", "Says: \"{0}\"\n");
    // {0} CBRivalStory(sys, game, r)
    this.Text("Cyberbane-Hud-TheirStory", "Their story: {0}\n");
    // {0} CBRivalDisplayName(content, kinDead)
    this.Text("Cyberbane-Hud-FamilyOfWhomYouKilled", "Family of {0}, whom you killed.\n");
    // {0} scars
    this.Text("Cyberbane-Hud-CarriesYourMark", "Carries your mark: {0}.\n");
    // {0} chrome
    this.Text("Cyberbane-Hud-Chrome", "Chrome: {0}.\n");
    // {0} count, {1} cap
    this.Text("Cyberbane-Hud-OfAPossibleAreStillLooking", "{0} of a possible {1} are still looking for you. They come back a rank higher each time one escapes.");
    this.Text("Cyberbane-Hud-NobodyNewCanTakeAgainstYou", "\nNobody new can take against you until you clear some, so the ones you have come faster.");
    this.Text("Cyberbane-Hud-ForgottenAsSoonAsYouAre", "Forgotten as soon as you are back in the game, on this save and every other of this playthrough.");
    this.Text("Cyberbane-Hud-ClickAgainToForgetThemUntil", "Click again to forget them. Until you go back to the game, you can still keep them.");
    this.Text("Cyberbane-Hud-PuttingTheWordOutSomebodyTexts", "Putting the word out. Somebody texts you a price as soon as you are back in the game.");
    // {0} price
    this.Text("Cyberbane-Hud-PayingEbForWhereTheyAre", "Paying {0}eb for where they are. It goes through as soon as you are back in the game.");
    this.Text("Cyberbane-Hud-WaitingAtTheirPlaceRightNow", "Waiting at their place right now, and not expecting you.");
    this.Text("Cyberbane-Hud-TheStreet", "the street");
    // {0} ago
    this.Text("Cyberbane-Hud-Ago", ", {0} ago");
    // {0} from, {1} CBPlacePhrase(lead.district), {2} when
    this.Text("Cyberbane-Hud-WordFromSeenGoOnFoot", "Word from {0}: seen {1}{2}. Go on foot and they may not see you coming.");
    this.Text("Cyberbane-Hud-ClickAgainToPutTheWord", "Click again to put the word out for where they are hiding.");
    // {0} price, {1} CBHudEddies(game)
    this.Text("Cyberbane-Hud-PutTheWordOutAndSomebody", "Put the word out and somebody texts you a price for where they are hiding, about {0}eb. Answer in the thread: take it, push back once, or walk away. Then go there on foot and catch them unawares. You have {1}eb.");
    // {0} price
    this.Text("Cyberbane-Hud-ClickAgainToPayEbFor", "Click again to pay {0}eb for where they are hiding.");
    // {0} price, {1} CBHudEddies(game)
    this.Text("Cyberbane-Hud-EbBuysWhereTheyAreHiding", "{0}eb buys where they are hiding. Go there on foot and catch them unawares. You have {1}eb.");
    this.Text("Cyberbane-Hud-TurnOnTipsOnWhereRivals", "Turn on Tips on where Rivals are (under Rivals in Mod Settings) to buy where they are hiding.");
    this.Text("Cyberbane-Hud-TheirFactionIsSwitchedOffUnder", "Their faction is switched off under Factions in Mod Settings. Nobody of theirs is sent after you or found for you.");
    this.Text("Cyberbane-Hud-NobodySellsWhereTheyAreWhile", "Nobody sells where they are while they are out after you.");
    // {0} out
    this.Text("Cyberbane-Hud-YouGoByTheBestTitle", "{0}You go by the best title you earn. You have not earned one yet. Click any title to see what it takes and what it does.");
    // {0} CBTitleDisplayById(sys, content, worn)
    this.Text("Cyberbane-Hud-YouGoByTheBestTitle-2", "You go by the best title you have earned, which is {0}.\n");
    this.Text("Cyberbane-Hud-YouGoByThis", "You go by this.\n");
    this.Text("Cyberbane-Hud-NotEarnedYet", "Not earned yet.\n");
    // {0} need
    this.Text("Cyberbane-Hud-WHATITTAKES", "\nWHAT IT TAKES\n{0}\n");
    // {0} def.effect
    this.Text("Cyberbane-Hud-WHATITDOES", "\nWHAT IT DOES\n{0}\n");
    this.Text("Cyberbane-Hud-OnlyTheTitleYouGoBy", "\nOnly the title you go by has any effect.");
    this.Text("Cyberbane-Hud-TitleEffectsAreSwitchedOffIn", "\nTitle effects are switched off in Mod Settings.");
    // {0} RoundF(secs / 86400.0)
    this.Text("Cyberbane-Hud-D", "{0}d");
    this.Text("Cyberbane-Hud-STREETFILESUBJECTVNothingOn", "STREET FILE // SUBJECT: V\n\nNothing on file. Nobody has anything on you yet.");
    this.Text("Cyberbane-Hud-STREETFILESUBJECTV", "STREET FILE // SUBJECT: V\n");
    this.Text("Cyberbane-Hud-PutTogetherFromWhatPeopleSaw", "Put together from what people saw and passed on. Most recent first.\n");
    this.Text("Cyberbane-Hud-WorkNobodyWitnessedNeverReachesThis", "Work nobody witnessed never reaches this page.\n\n");
    // {0} stats.deaths, {1} stats.timesRecognized
    this.Text("Cyberbane-Hud-TALLYPutDownTimesRecognisedTimes", "TALLY   put down {0} times      recognised {1} times");
    // {0} stats.rivalsSpared
    this.Text("Cyberbane-Hud-RivalsSpared", "      rivals spared {0}\n");
    // {0} stats.rivalsSlain, {1} stats.apexKills
    this.Text("Cyberbane-Hud-RivalsPutDownApexEnforcersKilled", "        rivals put down {0}      apex enforcers killed {1}");
    // {0} stats.unattributed
    this.Text("Cyberbane-Hud-NeverPinnedOnYou", "      never pinned on you {0}\n");
    // {0} stats.tributeEddies, {1} spent
    this.Text("Cyberbane-Hud-TributeTakenEbPaidOutFor", "        tribute taken {0}eb      paid out for peace {1}eb\n");
    // {0} style
    this.Text("Cyberbane-Hud-Style", "        style {0}\n");
    this.Text("Cyberbane-Hud-WarmedToYou", "warmed to you");
    this.Text("Cyberbane-Hud-TookOffence", "took offence");
    this.Text("Cyberbane-Hud-FearYouMore", "fear you more");
    this.Text("Cyberbane-Hud-GaveUpARival", "gave up a Rival");
    this.Text("Cyberbane-Hud-PaidYouOff", "paid you off");
    this.Text("Cyberbane-Hud-TodayFromTalkingToTheirPeople", "Today, from talking to their people: they ");
    // {0} gang
    this.Text("Cyberbane-Hud-OneOf", "one of {0}");
    this.Text("Cyberbane-Hud-OneOfTheirOwn", "one of their own");
    // {0} who, {1} name
    this.Text("Cyberbane-Hud-YouLeanedOnUntilTheyGave", "You leaned on {0} until they gave up {1}.");
    // {0} who, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouShookDownForEb", "You shook down {0} for {1}eb.");
    // {0} gang
    this.Text("Cyberbane-Hud-TalkingToTheirPeopleWarmedTo", "Talking to their people warmed {0} to you.");
    this.Text("Cyberbane-Hud-TalkingToPeopleWarmedThemTo", "Talking to people warmed them to you.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-TookOffenceAtHowYouSpoke", "{0} took offence at how you spoke to their people.");
    this.Text("Cyberbane-Hud-PeopleTookOffenceAtHowYou", "People took offence at how you spoke to them.");
    // {0} gang
    this.Text("Cyberbane-Hud-LeaningOnTheirPeopleMadeFear", "Leaning on their people made {0} fear you more.");
    this.Text("Cyberbane-Hud-LeaningOnPeopleMadeTheStreet", "Leaning on people made the street fear you more.");
    // {0} who, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidEbForWhereA", "You paid {0} {1}eb for where a Rival was hiding.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-AFanStoodYouADrink", "A fan stood you a drink: {0}eb.");
    // {0} gang, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidEbToWalkTheir", "You paid {0} {1}eb to walk their streets in peace for a few hours.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidEbForSafePassage", "You paid {0}eb for safe passage.");
    // {0} CBPossessive(gang), {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouRobbedBagmanOfEb", "You robbed {0} bagman of {1}eb.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouRobbedABagmanOfEb", "You robbed a bagman of {0}eb.");
    // {0} gang, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouDidAFavourForEb", "You did {0} a favour, for {1}eb.");
    this.Text("Cyberbane-Hud-YouDidSomebodyAFavour", "You did somebody a favour.");
    this.Text("Cyberbane-Hud-YouCrashedASitDownBetween", "You crashed a sit-down between two gangs.");
    this.Text("Cyberbane-Hud-YouShotSomebodyWhoHadGiven", "You shot somebody who had given up.");
    this.Text("Cyberbane-Hud-YouCalledOutARivalThey", "You called out a Rival. They named a place.");
    this.Text("Cyberbane-Hud-ARivalCalledYouOutAnd", "A Rival called you out and named a place.");
    this.Text("Cyberbane-Hud-YouRanARivalOutOf", "You ran a Rival out of Night City.");
    this.Text("Cyberbane-Hud-FamilyOfARivalYouKilled", "Family of a Rival you killed swore to finish what they started.");
    // {0} who
    this.Text("Cyberbane-Hud-YouMadeTalk", "You made {0} talk.");
    // {0} name
    this.Text("Cyberbane-Hud-YouLearntSFatalFlaw", "You learnt {0}'s fatal flaw.");
    this.Text("Cyberbane-Hud-ARivalDiedOfTheFatal", "A Rival died of the fatal flaw you found.");
    // {0} who
    this.Text("Cyberbane-Hud-YouTurnedIntoAnInformant", "You turned {0} into an informant.");
    this.Text("Cyberbane-Hud-AnInformantOfYoursTextedA", "An informant of yours texted a tip.");
    // {0} who, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidEbToCallOff", "You paid {0} {1}eb to call off the crew coming for you.");
    this.Text("Cyberbane-Hud-YouPaidAWitnessToForget", "You paid a witness to forget what they saw.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidSomebodyEbToKeep", "You paid somebody {0}eb to keep watch for you.");
    this.Text("Cyberbane-Hud-AKidSquaredUpToYou", "A kid squared up to you for a name. You put them down.");
    this.Text("Cyberbane-Hud-AKidSquaredUpToYou-2", "A kid squared up to you for a name, and won.");
    this.Text("Cyberbane-Hud-AKidSquaredUpToYou-3", "A kid squared up to you for a name. You walked away.");
    this.Text("Cyberbane-Hud-YouShotAKidWhoCame", "You shot a kid who came at you with their fists.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouHurtPeopleLookAfter", "You hurt people {0} look after.");
    this.Text("Cyberbane-Hud-YouHurtPeopleSomebodyLooksAfter", "You hurt people somebody looks after.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouLetOneOfWalkWith", "You let one of {0} walk with their hands up.");
    this.Text("Cyberbane-Hud-YouLetSomebodyWalkWithTheir", "You let somebody walk with their hands up.");
    // {0} CBCapFirst(gang), {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-PutAPriceOnYourHead", "{0} put a price on your head: {1}eb.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-SomebodyPutAPriceOnYour", "Somebody put a price on your head: {0}eb.");
    this.Text("Cyberbane-Hud-YouPaidOffThePriceOn", "You paid off the price on your head.");
    this.Text("Cyberbane-Hud-WhoeverPutThePriceOnYour", "Whoever put the price on your head is dead, and the price with them.");
    this.Text("Cyberbane-Hud-ThePriceOnYourHeadCame", "The price on your head came down.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouKilledABountyHunterRanked", "You killed a bounty hunter ranked {0} on the ladder.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouBeatABountyHunterRanked", "You beat a bounty hunter ranked {0} and left them breathing.");
    this.Text("Cyberbane-Hud-YouReachedTheTopOfThe", "You reached the top of the hunters' ladder.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouClimbedToNumberOnThe", "You climbed to number {0} on the hunters' ladder.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-WarnedYouOff", "{0} warned you off.");
    this.Text("Cyberbane-Hud-ACorporationWarnedYouOff", "A corporation warned you off.");
    // {0} RoundF(e.value), {1} gang
    this.Text("Cyberbane-Hud-ACorporationOfferedYouEbTo", "A corporation offered you {0}eb to kill the leader of {1}.");
    this.Text("Cyberbane-Hud-ACorporationOfferedYouAContract", "A corporation offered you a contract.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-SentPeopleToWatchYourBack", "{0} sent people to watch your back.");
    this.Text("Cyberbane-Hud-AGangSentPeopleToWatch", "A gang sent people to watch your back.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouBecameOneOf", "You became one of {0}.");
    this.Text("Cyberbane-Hud-YouJoinedAGang", "You joined a gang.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouStoppedBeingOneOf", "You stopped being one of {0}.");
    this.Text("Cyberbane-Hud-YouLeftAGang", "You left a gang.");
    // {0} gang
    this.Text("Cyberbane-Hud-YourGangAskedYouToPut", "Your gang asked you to put down five of {0} in a week.");
    this.Text("Cyberbane-Hud-YourGangAskedAFavour", "Your gang asked a favour.");
    this.Text("Cyberbane-Hud-YouCameThroughForYourGang", "You came through for your gang.");
    this.Text("Cyberbane-Hud-YouLetYourGangDown", "You let your gang down.");
    // {0} CBCapFirst(gang), {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-PaidEbToGetOneOf", "{0} paid {1}eb to get one of theirs back.");
    this.Text("Cyberbane-Hud-AGangPaidARansom", "A gang paid a ransom.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-RefusedYourRansomAndCameFor", "{0} refused your ransom and came for their own.");
    this.Text("Cyberbane-Hud-AGangRefusedYourRansom", "A gang refused your ransom.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouHandedAPrisonerTo", "You handed a prisoner to {0}.");
    this.Text("Cyberbane-Hud-YouHandedOverAPrisoner", "You handed over a prisoner.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouFedALieThroughThe", "You fed {0} a lie through the street.");
    this.Text("Cyberbane-Hud-YouFedTheStreetALie", "You fed the street a lie.");
    // {0} gang
    this.Text("Cyberbane-Hud-SomebodySoldYourLieOutTo", "Somebody sold your lie out to {0}.");
    this.Text("Cyberbane-Hud-SomebodySoldYouOut", "Somebody sold you out.");
    this.Text("Cyberbane-Hud-YouSavedAnInformantFromTheir", "You saved an informant from their own gang.");
    this.Text("Cyberbane-Hud-AnInformantOfYoursWasRun", "An informant of yours was run down by their own gang.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouPaidACrewOfTo", "You paid a crew of {0} to say they never found you.");
    this.Text("Cyberbane-Hud-YouPaidOffACrew", "You paid off a crew.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouTalkedACrewOfInto", "You talked a crew of {0} into walking away.");
    this.Text("Cyberbane-Hud-YouTalkedACrewDown", "You talked a crew down.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouThreatenedByTextAndThey", "You threatened {0} by text, and they backed down.");
    this.Text("Cyberbane-Hud-AThreatByTextMadeA", "A threat by text made a gang back down.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouToldToComeAndTry", "You told {0} to come and try it.");
    this.Text("Cyberbane-Hud-YouDaredAGangToCome", "You dared a gang to come for you.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouStaredDownAndTheirPeople", "You stared down {0}, and their people ran.");
    // {0} CBCapFirst(rn)
    this.Text("Cyberbane-Hud-LetYouWalkAwayOnce", "{0} let you walk away, once.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouBeatOneOnOneWhile", "You beat {0} one on one while their people watched.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouAndCalledItEven", "You and {0} called it even.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouHumiliatedWhereTheyLay", "You humiliated {0} where they lay.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouTookATrophyOff", "You took a trophy off {0}.");
    // {0} CBCapFirst(rn)
    this.Text("Cyberbane-Hud-CameBackFromTheDead", "{0} came back from the dead.");
    // {0} CBCapFirst(rn)
    this.Text("Cyberbane-Hud-SworeVengeanceForSomebodyYouKilled", "{0} swore vengeance for somebody you killed.");
    // {0} CBCapFirst(rn)
    this.Text("Cyberbane-Hud-LongGoneFromNightCityGot", "{0}, long gone from Night City, got in touch.");
    // {0} CBCapFirst(rn)
    this.Text("Cyberbane-Hud-WentUnderTheKnifeForYou", "{0} went under the knife for you.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouSetARivalOn", "You set a Rival on {0}.");
    // {0} CBCapFirst(rn)
    this.Text("Cyberbane-Hud-SLookoutSawYouAndGot", "{0}'s lookout saw you and got away; they moved.");
    // {0} rn
    this.Text("Cyberbane-Hud-YouHeardWhichRipperdocWasIn", "You heard which ripperdoc {0} was in.");
    // {0} rn
    this.Text("Cyberbane-Hud-OneRivalKilledAnotherIsGone", "One Rival killed another: {0} is gone.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-WonAFightWithTheirEnemies", "{0} won a fight with their enemies in the street.");
    this.Text("Cyberbane-Hud-TwoGangsFoughtInTheStreet", "Two gangs fought in the street.");
    // {0} CBCapFirst(gang), {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-PaidYouEbForAJob", "{0} paid you {1}eb for a job.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-ACorporationPaidYouEbFor", "A corporation paid you {0}eb for a job.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-PlantedATrackerOnYou", "{0} planted a tracker on you.");
    this.Text("Cyberbane-Hud-SomebodyPlantedATrackerOnYou", "Somebody planted a tracker on you.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-DeclaredOpenSeasonOnYou", "{0} declared open season on you.");
    this.Text("Cyberbane-Hud-AGangDeclaredOpenSeasonOn", "A gang declared open season on you.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouSurvivedOpenSeason", "You survived {0} open season.");
    this.Text("Cyberbane-Hud-YouSurvivedOpenSeason-2", "You survived open season.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouEndedOpenSeasonByKilling", "You ended {0} open season by killing the one who called it.");
    this.Text("Cyberbane-Hud-YouEndedAnOpenSeasonBy", "You ended an open season by killing the one who called it.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouWalkedThroughAmbushOnThe", "You walked through {0} ambush on the way to a job.");
    this.Text("Cyberbane-Hud-YouWalkedThroughAnAmbush", "You walked through an ambush.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouPaidScoutToSayThey", "You paid {0} scout to say they never found you.");
    this.Text("Cyberbane-Hud-YouPaidAScoutToSay", "You paid a scout to say they never found you.");
    // {0} CBCapFirst(gang), {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-PaidYouYourCutEb", "{0} paid you your cut: {1}eb.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouWerePaidYourCutEb", "You were paid your cut: {0}eb.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouThrewInWith", "You threw in with {0}.");
    this.Text("Cyberbane-Hud-YouPickedASideInThe", "You picked a side in the war.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouSetOnTheirEnemiesWith", "You set {0} on their enemies with a lie.");
    this.Text("Cyberbane-Hud-YouSetTwoGangsOnEach", "You set two gangs on each other with a lie.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-MadeATruceWithTheirEnemies", "{0} made a truce with their enemies, against you.");
    this.Text("Cyberbane-Hud-TwoGangsMadeATruceAgainst", "Two gangs made a truce against you.");
    this.Text("Cyberbane-Hud-ADistrictBecameYours", "A district became yours.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-TheGangsPaidTheirWayThrough", "The gangs paid their way through your streets: {0}eb.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouDidAFavourAndThey", "You did {0} a favour, and they called it off.");
    this.Text("Cyberbane-Hud-AFavourBoughtYouPeace", "A favour bought you peace.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidTheClawsEbFor", "You paid the Claws {0}eb for protection.");
    this.Text("Cyberbane-Hud-YouDidnTPayTheClaws", "You didn't pay the Claws' protection.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-ExecutedSomebodyAndNobodyStoppedThem", "{0} executed somebody, and nobody stopped them.");
    this.Text("Cyberbane-Hud-SomebodyWasExecutedAndNobodyStopped", "Somebody was executed, and nobody stopped it.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouSavedOneOfFromAn", "You saved one of {0} from an execution.");
    this.Text("Cyberbane-Hud-YouStoppedAnExecution", "You stopped an execution.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-RanDownTheOneTheyWere", "{0} ran down the one they were hunting.");
    this.Text("Cyberbane-Hud-AGangRanSomebodyDown", "A gang ran somebody down.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouSavedOneOfFromThe", "You saved one of {0} from the people hunting them.");
    this.Text("Cyberbane-Hud-YouSavedSomebodyFromAGang", "You saved somebody from a gang's hunt.");
    // {0} CBCapFirst(gang)
    this.Text("Cyberbane-Hud-WonAStreetFightAndTook", "{0} won a street fight and took ground.");
    this.Text("Cyberbane-Hud-AStreetFightDecidedWhoHolds", "A street fight decided who holds the ground.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouStoodWithInAStreet", "You stood with {0} in a street fight, and won it with them.");
    this.Text("Cyberbane-Hud-YouPickedASideInA", "You picked a side in a street fight, and won.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouStoodWithInAStreet-2", "You stood with {0} in a street fight, and lost it with them.");
    this.Text("Cyberbane-Hud-YouPickedASideInA-2", "You picked a side in a street fight, and lost.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouDecidedWhoRuns", "You decided who runs {0}.");
    this.Text("Cyberbane-Hud-YouDecidedWhoRunsAGang", "You decided who runs a gang.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouKilledBothOfWouldBe", "You killed both of {0} would-be leaders.");
    this.Text("Cyberbane-Hud-YouKilledBothWouldBeLeaders", "You killed both would-be leaders.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouShotUpFuneral", "You shot up {0} funeral.");
    this.Text("Cyberbane-Hud-YouShotUpAFuneral", "You shot up a funeral.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouPaidYourRespectsAtFuneral", "You paid your respects at {0} funeral.");
    this.Text("Cyberbane-Hud-YouPaidYourRespectsAtA", "You paid your respects at a funeral.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouTookTheGunsWereBuying", "You took the guns {0} were buying.");
    this.Text("Cyberbane-Hud-YouHitAnArmsDeal", "You hit an arms deal.");
    // {0} CBPossessive(gang), {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouHitRacketForEb", "You hit {0} racket for {1}eb.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouHitARacketForEb", "You hit a racket for {0}eb.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouBrokeUpSomethingHadPlanned", "You broke up something {0} had planned.");
    this.Text("Cyberbane-Hud-YouBrokeUpAGangS", "You broke up a gang's plans.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouBeatApexSquadAllFour", "You beat {0} apex squad, all four.");
    this.Text("Cyberbane-Hud-YouBeatAnApexSquadAll", "You beat an apex squad, all four.");
    // {0} who, {1} gang
    this.Text("Cyberbane-Hud-OfTookItPersonally", "{0} of {1} took it personally.");
    // {0} who
    this.Text("Cyberbane-Hud-TookItPersonally", "{0} took it personally.");
    // {0} RoundF(e.value), {1} gang
    this.Text("Cyberbane-Hud-YouPutDownARankRival", "You put down a rank {0} rival from {1}.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPutDownARankRival-2", "You put down a rank {0} rival.");
    // {0} RoundF(e.value), {1} gang
    this.Text("Cyberbane-Hud-YouCaughtARankRivalFrom", "You caught a rank {0} rival from {1} where they were lying low. They never saw you.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouCaughtARankRivalWhere", "You caught a rank {0} rival where they were lying low. They never saw you.");
    this.Text("Cyberbane-Hud-AJobOfYoursMadeThe", "A job of yours made the rounds.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-PeopleAreStillTalkingAboutThe", "People are still talking about the {0} you left behind.");
    // {0} gang
    this.Text("Cyberbane-Hud-YouTookDownSomebodyWhoMattered", "You took down somebody who mattered to {0}.");
    this.Text("Cyberbane-Hud-YouTookDownSomebodyWhoMattered-2", "You took down somebody who mattered.");
    // {0} CBPossessive(gang)
    this.Text("Cyberbane-Hud-YouPutDownOneOfApex", "You put down one of {0} apex squad.");
    this.Text("Cyberbane-Hud-YouPutDownOneOfAn", "You put down one of an apex squad.");
    // {0} gangCap
    this.Text("Cyberbane-Hud-SworeAVendettaAgainstYou", "{0} swore a vendetta against you.");
    // {0} gang, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-YouPaidEbToCallIt", "You paid {0} {1}eb to call it off.");
    // {0} gangCap, {1} RoundF(e.value)
    this.Text("Cyberbane-Hud-PaidYouEbToStayOn", "{0} paid you {1}eb to stay on your good side.");
    // {0} gangCap
    this.Text("Cyberbane-Hud-PutYouDown", "{0} put you down.");
    this.Text("Cyberbane-Hud-SomebodyPutYouDown", "Somebody put you down.");
    // {0} gangCap
    this.Text("Cyberbane-Hud-DecidedYouAreAllRight", "{0} decided you are all right.");
    // {0} gangCap
    this.Text("Cyberbane-Hud-StartedTreatingYouLikeOneOf", "{0} started treating you like one of their own.");
    // {0} gangCap
    this.Text("Cyberbane-Hud-TookOverTheStreets", "{0} took over the streets.");
    // {0} gangCap
    this.Text("Cyberbane-Hud-CameBackToTakeTheirStreets", "{0} came back to take their streets.");
    // {0} gang
    this.Text("Cyberbane-Hud-OneOfYourCrewStartedA", "One of your crew started a war on {0}, and won it.");
    this.Text("Cyberbane-Hud-OneOfYourCrewStartedA-2", "One of your crew started a war, and won it.");
    // {0} gang
    this.Text("Cyberbane-Hud-OneOfYourCrewWentTo", "One of your crew went to war on {0}, and did not come back.");
    this.Text("Cyberbane-Hud-OneOfYourCrewWentTo-2", "One of your crew went to war, and did not come back.");
    // {0} RoundF(e.value), {1} gang
    this.Text("Cyberbane-Hud-ARankRivalFromDiedAnd", "A rank {0} rival from {1} died, and not by your hand.");
    // {0} RoundF(e.value)
    this.Text("Cyberbane-Hud-ARankRivalDiedAndNot", "A rank {0} rival died, and not by your hand.");
    this.Text("Cyberbane-Hud-PeopleRun", "people run");
    this.Text("Cyberbane-Hud-PeopleAreAfraid", "people are afraid");
    this.Text("Cyberbane-Hud-PeopleAreUneasy", "people are uneasy");
    this.Text("Cyberbane-Hud-PeopleNotice", "people notice");
    this.Text("Cyberbane-Hud-NobodyMinds", "nobody minds");
    this.Text("Cyberbane-Hud-Butcher", "Butcher");
    this.Text("Cyberbane-Hud-Operator", "Operator");
    this.Text("Cyberbane-Hud-Chromed", "Chromed");
    this.Text("Cyberbane-Hud-Netrunner", "Netrunner");
    this.Text("Cyberbane-Hud-Brawler", "Brawler");
    this.Text("Cyberbane-Hud-Undefined", "Undefined");
    this.Text("Cyberbane-Hud-Disciplined", "Disciplined");
    this.Text("Cyberbane-Hud-Mixed", "Mixed");
    this.Text("Cyberbane-Hud-Friendly", "Friendly");
    this.Text("Cyberbane-Hud-Vendetta", "Vendetta");
    this.Text("Cyberbane-Hud-AtLarge", "at large");
    this.Text("Cyberbane-Hud-OwesYouTheirLife", "owes you their life");
    this.Text("Cyberbane-Hud-Quiet-2", "quiet");
    this.Text("Cyberbane-Hud-ClothesAreNotReadModSettings", "Clothes are not read (Mod Settings), so all your chrome shows.");
    this.Text("Cyberbane-Hud-WhatAStrangerClocksFromAcross", "What a stranger clocks from across the street. Arms read loudest.");
    this.Text("Cyberbane-Hud-Arms", "arms");
    // {0} parts
    this.Text("Cyberbane-Hud-Legs", "{0}, legs");
    this.Text("Cyberbane-Hud-Legs-2", "legs");
    // {0} parts
    this.Text("Cyberbane-Hud-Eyes", "{0}, eyes");
    this.Text("Cyberbane-Hud-Eyes-2", "eyes");
    // {0} parts
    this.Text("Cyberbane-Hud-Covered", "Covered: {0}.");
    this.Text("Cyberbane-Hud-NothingYouWearCoversYourChrome", "Nothing you wear covers your chrome.");
    // {0} RoundF(worn.twrFace * 100.0)
    this.Text("Cyberbane-Hud-FaceHidden", " Face {0}% hidden.");
    // {0} gang, {1} RoundF(sys.GetDisguiseStrength() * 100.0)
    this.Text("Cyberbane-Hud-PassingFor", " Passing for {0}, {1}%.");
  }

  // ---- Hud (3) -------------------------------------------------------------------------------------------------
  protected func DefineHud3() -> Void {
    this.Text("Cyberbane-Hud-TheyWillRememberSReading", " (They Will Remember's reading.)");
    // {0} why
    this.Text("Cyberbane-Hud-TheyWillRememberSDisguisesCould", " They Will Remember's disguises could not be read ({0}); this is Cyberbane's own.");
    this.Text("Cyberbane-Hud-TheyWillRememberSDisguisesCould-2", " They Will Remember's disguises could not be read; this is Cyberbane's own.");
    this.Text("Cyberbane-Hud-ShowAsCards", "Show as cards");
  }

  // ---- MapPins ---------------------------------------------------------------------------------------------
  protected func DefineMapPins() -> Void {
    // {0} ago
    this.Text("Cyberbane-MapPins-Ago", "{0} ago");
    this.Text("Cyberbane-MapPins-JustNow", "just now");
    this.Text("Cyberbane-MapPins-ARival", "A Rival");
    // {0} CBCapFirst(CBFactionLabel(m.a)), {1} CBDistrictLabel(m.district)
    this.Text("Cyberbane-MapPins-Took", "{0} took {1}");
    // {0} ago
    this.Text("Cyberbane-MapPins-FellHereByYourHand", "Fell here by your hand, {0}.");
    // {0} ago
    this.Text("Cyberbane-MapPins-KilledHereAndNotByYou", "Killed here {0}, and not by you.");
    // {0} ago
    this.Text("Cyberbane-MapPins-YouBrokeItUpHereThey", "You broke it up here, {0}. They have not forgotten.");
    // {0} CBFactionLabel(m.b), {1} ago
    this.Text("Cyberbane-MapPins-TakenFrom", "Taken from {0}, {1}.");
    // {0} ago
    this.Text("Cyberbane-MapPins-ChangedHands", "Changed hands {0}.");
    // {0} ago, {1} CBRivalDisplayName(sys.GetContent(), killer)
    this.Text("Cyberbane-MapPins-DiedHereFightingForYouDid", "Died here fighting for you, {0}. {1} did it.");
    // {0} ago
    this.Text("Cyberbane-MapPins-DiedHereFightingForYou", "Died here fighting for you, {0}.");
  }

  // ---- Notify ----------------------------------------------------------------------------------------------
  protected func DefineNotify() -> Void {
    this.Text("Cyberbane-Notify-Infamous", "Infamous");
    this.Text("Cyberbane-Notify-Notorious", "Notorious");
    this.Text("Cyberbane-Notify-KnownMerc", "Known Merc");
    this.Text("Cyberbane-Notify-LocalName", "Local Name");
  }

  // ---- PhoneMessages ---------------------------------------------------------------------------------------
  protected func DefinePhoneMessages() -> Void {
    this.Text("Cyberbane-PhoneMessages-UnknownNumber", "Unknown Number");
    this.Text("Cyberbane-PhoneMessages-Salt", "Salt");
    this.Text("Cyberbane-PhoneMessages-Mira", "Mira");
    this.Text("Cyberbane-PhoneMessages-Glasswork", "Glasswork");
    this.Text("Cyberbane-PhoneMessages-TioBenny", "Tio Benny");
    this.Text("Cyberbane-PhoneMessages-LowTide", "Low Tide");
    this.Text("Cyberbane-PhoneMessages-Radiator", "Radiator");
    this.Text("Cyberbane-PhoneMessages-Dust", "Dust");
    this.Text("Cyberbane-PhoneMessages-SplitLip", "Split Lip");
    this.Text("Cyberbane-PhoneMessages-Ripperdoc", "Ripperdoc");
    this.Text("Cyberbane-PhoneMessages-NoCallerID", "No Caller ID");
    // {0} body
    this.Text("Cyberbane-PhoneMessages-Cyberbane", "Cyberbane: {0}");
  }

  // ---- RealPhone -------------------------------------------------------------------------------------------
  protected func DefineRealPhone() -> Void {
    this.Text("Cyberbane-RealPhone-ForgetIt", "Forget it");
    // {0} CBPeaceQuote(sys, game, store.ThreadOffer(thread))
    this.Text("Cyberbane-RealPhone-PayEbToCallItOff", "Pay {0}eb to call it off");
    this.Text("Cyberbane-RealPhone-GiveMeADay", "Give me a day");
    this.Text("Cyberbane-RealPhone-BackOffOrElse", "Back off, or else");
    this.Text("Cyberbane-RealPhone-ComeAndTryIt", "Come and try it");
    this.Text("Cyberbane-RealPhone-NotPaying", "Not paying");
    this.Text("Cyberbane-RealPhone-ComeAndFindMe", "Come and find me");
    this.Text("Cyberbane-RealPhone-NameThePlace", "Name the place");
    this.Text("Cyberbane-RealPhone-YouLlLoseAgain", "You'll lose again");
    this.Text("Cyberbane-RealPhone-TooMuch", "Too much.");
    this.Text("Cyberbane-RealPhone-ForThatComeOn", "For that? Come on.");
    // {0} CBPeaceQuote(sys, game, faction)
    this.Text("Cyberbane-RealPhone-FineEbAndThatSThe", "Fine. {0}eb, and that's the last time we move.");
    // {0} cost
    this.Text("Cyberbane-RealPhone-ThePriceIsEbTakeIt", "The price is {0}eb. Take it or don't.");
    // {0} cost
    this.Text("Cyberbane-RealPhone-EbCallItOff", "{0}eb. Call it off.");
    this.Text("Cyberbane-RealPhone-IDonTHaveThatOn", "I don't have that on me.");
    this.Text("Cyberbane-RealPhone-NotPayingSendWhoeverYouWant", "Not paying. Send whoever you want.");
    this.Text("Cyberbane-RealPhone-ThenWeWillBeSeeingYou", "Then we will be seeing you.");
    this.Text("Cyberbane-RealPhone-ThenGetItTheOfferWon", "Then get it. The offer won't wait forever.");
    // {0} price
    this.Text("Cyberbane-RealPhone-DealEb", "Deal. {0}eb.");
    this.Text("Cyberbane-RealPhone-ForgetIt-2", "Forget it.");
    this.Text("Cyberbane-RealPhone-SuitYourselfOfferSGone", "Suit yourself. Offer's gone.");
    // {0} lower
    this.Text("Cyberbane-RealPhone-FineEbLastOffer", "Fine. {0}eb. Last offer.");
    // {0} lower
    this.Text("Cyberbane-RealPhone-EbBecauseILikeYouDon", "{0}eb, because I like you. Don't tell anyone.");
    this.Text("Cyberbane-RealPhone-PriceIsThePriceTakeIt", "Price is the price. Take it or don't.");
    // {0} price
    this.Text("Cyberbane-RealPhone-EbNotACentLess", "{0}eb. Not a cent less.");
    this.Text("Cyberbane-RealPhone-GiveMeADayIM", "Give me a day. I'm thinking about it.");
    this.Text("Cyberbane-RealPhone-INeedTimeToGetIt", "I need time to get it together. Hold your people.");
    // {0} you
    this.Text("Cyberbane-RealPhone-AnHourThenWeStopAsking", "An hour, {0}. Then we stop asking.");
    this.Text("Cyberbane-RealPhone-YouVeGotALittleTime", "You've got a little time. Don't waste it.");
    this.Text("Cyberbane-RealPhone-CallThemOffOrIStart", "Call them off, or I start with whoever you send and work my way up.");
    this.Text("Cyberbane-RealPhone-YouVeSeenWhatIDo", "You've seen what I do to your people. Back off.");
    this.Text("Cyberbane-RealPhone-FineWeLlLeaveYouBe", "...Fine. We'll leave you be. This time.");
    this.Text("Cyberbane-RealPhone-WeLlLeaveItForNow", "We'll leave it. For now.");
    // {0} you
    this.Text("Cyberbane-RealPhone-ThreatsFromYouWeReComing", "Threats? From you? We're coming, {0}.");
    this.Text("Cyberbane-RealPhone-WrongAnswer", "Wrong answer.");
    this.Text("Cyberbane-RealPhone-ComeAndTryItBringMore", "Come and try it. Bring more than last time.");
    // {0} CBHere(sys)
    this.Text("Cyberbane-RealPhone-IMInComeAndFind", "I'm in {0}. Come and find me, if you've got the guts.");
    this.Text("Cyberbane-RealPhone-KeepYourPriceYouLlNeed", "Keep your price. You'll need it for funerals.");
    this.Text("Cyberbane-RealPhone-YouLlRegretThat", "You'll regret that.");
    this.Text("Cyberbane-RealPhone-EveryOneOfUsJustRead", "Every one of us just read that. Every one.");
    // {0} CBHere(sys)
    this.Text("Cyberbane-RealPhone-IMInStopTextingAnd", "I'm in {0}. Stop texting and come.");
    this.Text("Cyberbane-RealPhone-YouKnowWhereIAmCome", "You know where I am. Come and find me.");
    // {0} CBRivalCatchphrase(r)
    this.Text("Cyberbane-RealPhone-OnMyWay", "{0} On my way.");
    this.Text("Cyberbane-RealPhone-YouWantMePickAPlace", "You want me? Pick a place.");
    this.Text("Cyberbane-RealPhone-NotAroundHereILlFind", "Not around here. I'll find you myself.");
    // {0} r.escapes == 1 ? "once" : s"\(r.escapes) times"
    this.Text("Cyberbane-RealPhone-YouVeRunFromMeYou", "You've run from me {0}. You'll run again.");
    this.Text("Cyberbane-RealPhone-ILetYouLiveOnceI", "I let you live once. I won't make that mistake twice.");
    this.Text("Cyberbane-RealPhone-YouLlLoseSameAsEverybody", "You'll lose. Same as everybody else.");
    this.Text("Cyberbane-RealPhone-KeepTalkingItMakesThisEasier", "Keep talking. It makes this easier.");
    this.Text("Cyberbane-RealPhone-YouLlBeSayingThatWith", "You'll be saying that with a mouthful of blood.");
    this.Text("Cyberbane-RealPhone-WeLlSee", "...We'll see.");
    this.Text("Cyberbane-RealPhone-BigTalkWeLlSeeWho", "Big talk. We'll see who's right.");
  }

  // ---- RivalPin --------------------------------------------------------------------------------------------
  protected func DefineRivalPin() -> Void {
    this.Text("Cyberbane-RivalPin-GangBusinessItStartsAroundThe", "Gang business. It starts around the time on the pin. Crash it, or leave them to it.");
    this.Text("Cyberbane-RivalPin-HuntingYou", "Hunting you.");
    this.Text("Cyberbane-RivalPin-CyberbaneRivalLastSeenHere", "Cyberbane Rival. Last seen here.");
  }

  // ---- ScannerName -----------------------------------------------------------------------------------------
  protected func DefineScannerName() -> Void {
    this.Text("Cyberbane-ScannerName-HANDSUP", "HANDS UP");
    this.Text("Cyberbane-ScannerName-CREWSERGEANT", "CREW SERGEANT");
    // {0} StrUpper(CBFactionLabel(npc.cbLookoutFor))
    this.Text("Cyberbane-ScannerName-LOOKOUT", "LOOKOUT: {0}");
    // {0} StrUpper(CBBarFactionLabel(CBClassifyFaction(npc))), {1} place
    this.Text("Cyberbane-ScannerName-APEXSQUAD", "APEX SQUAD: {0}{1}");
    // {0} StrUpper(CBFactionLabel(CBClassifyFaction(npc)))
    this.Text("Cyberbane-ScannerName-SCOUT", "SCOUT: {0}");
  }

  // ---- Tracking --------------------------------------------------------------------------------------------
  // Gang homes (2.7.2, Spawn/GangHomes.reds). The places' own names come from the game, already in your language.
  protected func DefineGangHomes() -> Void {
    this.Text("Cyberbane-Settings-GangHomes", "Gang homes");
    this.Text("Cyberbane-Settings-GangHomes-Desc", "Some gangs have a place of their own: the Mox at Lizzie's Bar, Maelstrom at Totentanz, the Valentinos at El Coyote Cojo, the Tyger Claws at Wakako's pachinko parlor, the Voodoo Boys at their chapel in Pacifica and the Animals at the Grand Imperial Mall. The first time you are there, it goes on your map (hidden while that gang is hostile to you), and when you come by and none of them are about, a few of them are there to talk to, once a day. Anybody of theirs will tell you where it is.");
    // A note when V first stands at one. {0} is the place (the game's name for it), {1} the gang ("the Mox").
    this.Text("Cyberbane-GangHomes-Learned", "{0} is where {1} hang out. It's on your map now.");
    this.Text("Cyberbane-GangHomes-AskWhereDoYourPeople", "[Ask] Where do your people hang out?");
    this.Text("Cyberbane-GangHomes-NowhereYouDBeWelcome", "Nowhere you'd be welcome.");
    this.Text("Cyberbane-GangHomes-NotTellingYou", "Like I'd tell you.");
    // {0} is the place, {1} the district it is in, both the game's names.
    this.Text("Cyberbane-GangHomes-FriendlyAnswer", "{0}, in {1}. Come by, ask for anybody.");
    this.Text("Cyberbane-GangHomes-PlainAnswer", "{0}, in {1}. Mind your manners when you get there.");
    // Added after either answer when V has not been there yet; starts with a space.
    this.Text("Cyberbane-GangHomes-GoAndSee", " Go and see for yourself.");
    // The map pin: {0} is the gang's name ("Mox"), {1} the place.
    this.Text("Cyberbane-GangHomes-PinTitle", "{0}: {1}");
    // {0} is the gang ("the Mox").
    // A gang event V watched for, whose people never came: {0} is the gang ("The Mox").
    this.Text("Cyberbane-StreetEvents-SpottedYouWatching", "{0} spotted somebody watching and took it somewhere else.");
    this.Text("Cyberbane-GangHomes-PinDesc", "Where {0} hang out. Come by and some of them will be around.");
  }

  // The crew at home (2.7.2, Reactions/CrewHome.reds).
  protected func DefineCrewHome() -> Void {
    this.Text("Cyberbane-Settings-CrewGuards", "Guards at home");
    this.Text("Cyberbane-Settings-CrewGuards-Desc", "How many of your crew can take Watch the house on their Work row. While you are on home ground, they stand at the building's door and its car park (learned from where you come and go), out of your way, ready to talk and to fight anybody of Cyberbane's who starts something there. They leave once you do. 0 switches it off.");
    // The Work row, lower case like the others.
    this.Text("Cyberbane-CrewHome-WatchingTheHouse", "watching the house");
    this.Text("Cyberbane-CrewHome-IllKeepAnEyeOnTheHouse", "I'll keep an eye on the house. Door and car park.");
    this.Text("Cyberbane-CrewHome-TroubleAtTheHouse", "Trouble at the house. We've got it.");
    this.Text("Cyberbane-CrewHome-TheyGotMeAtTheDoor", "They got me at the door. I'll live. Give me a few hours.");
    // {0} is the weapon.
    this.Text("Cyberbane-CrewHome-FromTheLocker", "The {0} in your stash. I'll know where it is when I need it.");
    this.Text("Cyberbane-CrewHome-SomebodyClearedMyGun", "Somebody cleared my gun out of the locker, boss.");
    this.Text("Cyberbane-CrewHome-AskHowAreYouHoldingUp", "[Ask] How are you holding up?");
    // {0} is their old gang ("the Mox").
    this.Text("Cyberbane-CrewHome-AskTellMeAbout", "[Ask] Tell me about {0}.");
    this.Text("Cyberbane-CrewHome-AskHeardAnything", "[Ask] Heard anything?");
    this.Text("Cyberbane-CrewHome-DismissBackToIt", "[Dismiss] Back to it.");
    this.Text("Cyberbane-CrewHome-HoldingBest", "Never better. Wherever you're going, I'm going.");
    this.Text("Cyberbane-CrewHome-HoldingGood", "Good. Work's steady, the crew's solid.");
    this.Text("Cyberbane-CrewHome-HoldingFine", "Doing the job. Ask me again next week.");
    this.Text("Cyberbane-CrewHome-HoldingBad", "Honestly? I've been thinking about walking.");
    // Added after their answer; starts with a space. {0} is what last cost their loyalty ("the cut you owe them").
    this.Text("Cyberbane-CrewHome-WhatEatsAtMe", " [On their mind: {0}.]");
    // Added after their answer when the crew's cut is owed; starts with a space.
    this.Text("Cyberbane-CrewHome-AndTheCut", " And the cut's late, boss.");
    // Their old gang from the inside, one line at a time.
    this.Text("Cyberbane-CrewHome-LoreMox0", "The Mox started at Lizzie's, after one of their own was murdered and nobody did a thing about it.");
    this.Text("Cyberbane-CrewHome-LoreMox1", "We look after the dolls and the joytoys, the people nobody else looks out for. Hurt one of them and the whole bar knows by morning.");
    this.Text("Cyberbane-CrewHome-LoreMox2", "Susie Q runs Lizzie's. She's fair, right up until you cross her.");
    this.Text("Cyberbane-CrewHome-LoreMaelstrom0", "Maelstrom thinks flesh is a phase you grow out of. More chrome, louder voice.");
    this.Text("Cyberbane-CrewHome-LoreMaelstrom1", "Totentanz is where they drink. Northside is where they work: the old All Foods plant, anything with metal worth taking.");
    this.Text("Cyberbane-CrewHome-LoreMaelstrom2", "Nobody runs Maelstrom for long. There's always somebody with more chrome and fewer friends.");
    this.Text("Cyberbane-CrewHome-LoreValentinos0", "Valentinos are family first. Heywood born, Heywood buried.");
    this.Text("Cyberbane-CrewHome-LoreValentinos1", "Gold, saints and honor. Disrespect somebody's mother and you'd better be fast.");
    this.Text("Cyberbane-CrewHome-LoreValentinos2", "Even the Valentinos keep it quiet at El Coyote Cojo. That's Mama Welles' place.");
    this.Text("Cyberbane-CrewHome-LoreTygerClaws0", "The Claws run Japantown: the clubs, the dolls, the pachinko and the protection on all of it.");
    this.Text("Cyberbane-CrewHome-LoreTygerClaws1", "Bikes and blades. A Claw would rather cut you than shoot you.");
    this.Text("Cyberbane-CrewHome-LoreTygerClaws2", "Some of the money goes up the hill, to people in suits. Nobody says whose.");
    this.Text("Cyberbane-CrewHome-LoreSixthStreet0", "6th Street started as vets keeping Santo Domingo safe after the war. Then they started charging for it.");
    this.Text("Cyberbane-CrewHome-LoreSixthStreet1", "Flags, guns and rules. Everybody drills, everybody pays in.");
    this.Text("Cyberbane-CrewHome-LoreSixthStreet2", "They hate the Valentinos almost as much as they hate corpos.");
    this.Text("Cyberbane-CrewHome-LoreAnimals0", "The Animals don't trust chrome. Muscle, and whatever the doc pumps in to grow more of it.");
    this.Text("Cyberbane-CrewHome-LoreAnimals1", "You fight your way in and you fight your way up. Nothing else counts.");
    this.Text("Cyberbane-CrewHome-LoreAnimals2", "They hire out as muscle: bouncers, guards, anybody who pays.");
    this.Text("Cyberbane-CrewHome-LoreVoodooBoys0", "The Voodoo Boys are netrunners first. Pacifica is theirs because everybody else gave up on it.");
    this.Text("Cyberbane-CrewHome-LoreVoodooBoys1", "They're after something on the far side of the Blackwall. Most of them never say what out loud.");
    this.Text("Cyberbane-CrewHome-LoreVoodooBoys2", "Outsiders get nothing from them. You'd have to be family from the islands to be trusted.");
    this.Text("Cyberbane-CrewHome-LoreScavengers0", "Scavs take people apart for whatever sells: chrome, organs, anything.");
    this.Text("Cyberbane-CrewHome-LoreScavengers1", "Nobody's loyal in the Scavs. You're one bad week from being parts yourself.");
    this.Text("Cyberbane-CrewHome-LoreScavengers2", "They never stay anywhere long. Leave a place hot, find another.");
    this.Text("Cyberbane-CrewHome-LoreBarghest0", "Barghest is Kurt Hansen's army, and Dogtown is his country.");
    this.Text("Cyberbane-CrewHome-LoreBarghest1", "Checkpoints, discipline, and a toll on everything that moves.");
    this.Text("Cyberbane-CrewHome-LoreBarghest2", "Hansen deals with anybody who's buying: guns, chrome, people.");
    this.Text("Cyberbane-CrewHome-LoreScrappers0", "Scrappers live off what the war left lying in Dogtown. If it's still in one piece, somebody's selling it.");
    this.Text("Cyberbane-CrewHome-LoreScrappers1", "No flags, no boss worth the name. Just crews who got there first.");
    this.Text("Cyberbane-CrewHome-LoreScrappers2", "They stay out of Barghest's way, mostly. The ones who don't, don't last.");
    this.Text("Cyberbane-CrewHome-LoreAldecaldos0", "The Aldecaldos are family. You're in for life, and so are your kids.");
    this.Text("Cyberbane-CrewHome-LoreAldecaldos1", "Home is the convoy, and whoever's sitting next to you at the fire.");
    this.Text("Cyberbane-CrewHome-LoreAldecaldos2", "They don't love the city. They come in when there's work, and they leave.");
    this.Text("Cyberbane-CrewHome-LoreWraiths0", "The Wraiths are raffen shiv: nomads who threw out every rule the clans live by.");
    this.Text("Cyberbane-CrewHome-LoreWraiths1", "They raid the roads in the Badlands and sell whatever they catch.");
    this.Text("Cyberbane-CrewHome-LoreWraiths2", "Nobody trusts a Wraith. Not even another Wraith.");
    this.Text("Cyberbane-CrewHome-LoreNone", "Never ran with anybody. Never wanted to.");
    // Added after the lore by how they came to V; each starts with a space.
    this.Text("Cyberbane-CrewHome-TailOwed", " Anyway. You let me walk away. I don't forget that.");
    this.Text("Cyberbane-CrewHome-TailFrightened", " Don't tell them I said any of this.");
    this.Text("Cyberbane-CrewHome-TailPaid", " That's what you're paying me for, right?");
    this.Text("Cyberbane-CrewHome-TailLent", " They lent me to you. Don't make them sorry.");
    // {0} is the Rival, {1} the story of their weak spot (a sentence), {2} what finishes them ("a blade").
    this.Text("Cyberbane-CrewHome-HeardFlaw", "{0}? I know them from the old days. {1} Bring {2}.");
    // {0} is the Rival.
    this.Text("Cyberbane-CrewHome-HeardNothingOn", "{0}'s still out there. No weak spot I ever saw.");
    this.Text("Cyberbane-CrewHome-HeardNothing", "Nothing worth your time, boss.");
    // Giving one of the crew a weapon of yours. {0} is the weapon.
    this.Text("Cyberbane-CrewKit-SeriousPiece", "{0}. That's a serious piece. I'll bring it back in one piece.");
    this.Text("Cyberbane-CrewKit-PutItToWork", "{0}. I'll put it to work.");
  }

  // Crew jobs, the kitty, challenges and goods (2.7.2, Reactions/CrewJobs.reds).
  protected func DefineCrewJobs() -> Void {
    this.Text("Cyberbane-Settings-CrewJobs", "Crew jobs and the kitty");
    this.Text("Cyberbane-Settings-CrewJobs-Desc", "Send one of your crew on a job from their Orders: a hit on one of your Rivals (from Veteran up) or a gang's bag (from Soldier up). They are away a few hours and the odds decide how it goes, shown before you pick. What the crew brings in, from work and jobs, goes into the kitty: it pays their weekly cut by itself, you can take it from the Hub when you are home, and a member running the money drops it at your place every couple of days. Off: no jobs, and earnings come straight to you as before.");
    this.Text("Cyberbane-Settings-CrewDuels", "Challenges to your crew");
    this.Text("Cyberbane-Settings-CrewDuels-Desc", "Now and then the Tyger Claws or the Valentinos send a challenge: one of theirs against one of yours. Pick somebody on the Hub (Name, colours, the fallen) to win respect and fear, or turn it down and lose face with them.");
    this.Text("Cyberbane-Settings-BagGoods", "Goods in stolen bags");
    this.Text("Cyberbane-Settings-BagGoods-Desc", "Now and then a bagman's bag holds the gang's goods instead of cash. Sell them to somebody of another gang (their enemies pay best and the owners hear of it), or back to the owners for less. Goods go stale in a few days.");
    // Orders and the Hub.
    this.Text("Cyberbane-CrewJobs-SendThemOnAJob", "Send them on a job");
    this.Text("Cyberbane-CrewJobs-JobsOff", "Crew jobs are off in Mod Settings");
    this.Text("Cyberbane-CrewJobs-OnAJob", "On a job");
    this.Text("Cyberbane-CrewJobs-AHitOrABag", "A Rival's hit, or a gang's bag");
    // The card, upper case like the others. {0} is hours.
    this.Text("Cyberbane-CrewJobs-ONAJOBH", "ON A JOB, {0}H");
    this.Text("Cyberbane-CrewJobs-AHit", "A hit");
    this.Text("Cyberbane-CrewJobs-TheirBag", "Their bag");
    this.Text("Cyberbane-CrewJobs-NoTargets", "Nothing for them to go after: no Rival they can reach, and no gang whose bag they would take.");
    // {0} is the member, {1} the rank a hit needs.
    this.Text("Cyberbane-CrewJobs-PickAJob", "Pick a job for {0}. A hit on a Rival needs {1} or better; a bag needs less. The number is their chance. A hit that misses can still leave the Rival wounded and holed up for you to finish; a job gone wrong can cost you {0}.");
    this.Text("Cyberbane-CrewJobs-RunningTheMoney", "running the money");
    this.Text("Cyberbane-CrewJobs-PutThemOnTheMoney", "Put them on running the money");
    this.Text("Cyberbane-CrewHome-PutThemOnWatch", "Put them on watching the house");
    this.Text("Cyberbane-CrewJobs-TakeTheKitty", "Take the kitty");
    this.Text("Cyberbane-CrewJobs-KittyEmpty", "empty");
    this.Text("Cyberbane-CrewJobs-AtHomeOnly", "when you are home");
    // {0} is the gang's, possessive (the Valentinos').
    this.Text("Cyberbane-CrewJobs-AnswerChallenge", "Answer {0} challenge");
    this.Text("Cyberbane-CrewJobs-ChallengeHoursLeft", "{0}h to answer");
    this.Text("Cyberbane-CrewJobs-TurnItDown", "Turn it down");
    this.Text("Cyberbane-CrewJobs-TheyWillSayYouAreScared", "they'll say your crew is scared of them");
    this.Text("Cyberbane-CrewJobs-YouTookTheKitty", "you took {0} eddies out of the kitty.");
    this.Text("Cyberbane-CrewJobs-NoChallenge", "Nobody is challenging your crew right now.");
    this.Text("Cyberbane-CrewJobs-NobodyToSend", "Nobody to send: everybody is out with you, away, hurt or on watch.");
    this.Text("Cyberbane-CrewJobs-PickForTheChallenge", "Pick who fights for your crew against one of {0}. The number is their chance. A win earns respect and fear; a loss and they crow about it.");
    // Added to the crew summary; each starts with a space.
    this.Text("Cyberbane-CrewJobs-KittyLine", " The kitty holds {0} eddies.");
    this.Text("Cyberbane-CrewJobs-GoodsLine", " You are holding goods from {0} bag(s), worth about {1} eddies.");
    this.Text("Cyberbane-Hud-OneName", "1 name");
    this.Text("Cyberbane-Hud-Names", "{0} names");
    // Texts from the crew. {0} is a Rival's name.
    this.Text("Cyberbane-CrewJobs-OnMyWayToHit", "Going after {0}. Don't wait up.");
    // {0} is the gang's, possessive ("the Mox's").
    this.Text("Cyberbane-CrewJobs-GoingForTheBag", "Going for {0} bag. Back in a few hours.");
    this.Text("Cyberbane-CrewJobs-IllTakeTheirBest", "I'll take their best. Tell {0} I'm coming.");
    this.Text("Cyberbane-CrewJobs-AlreadyGone", "Got there and they were already gone. Somebody beat me to it, or they skipped town.");
    this.Text("Cyberbane-CrewJobs-HitDone", "It's done. {0} won't be coming for you again.");
    // {0} is the Rival, {1} where they are ("in Kabuki").
    this.Text("Cyberbane-CrewJobs-HitWounded", "Put a round in {0}, but they got away. Holed up {1}. It's on your map. Finish it.");
    this.Text("Cyberbane-CrewJobs-HitWoundedLost", "Put a round in {0}, but they got away. Lost them after that.");
    // Sent from the Rival. {0} is your crew member.
    this.Text("Cyberbane-CrewJobs-HitKilledMember", "Your {0} came for me. Your {0} is not coming home.");
    this.Text("Cyberbane-CrewJobs-HitFailed", "{0} was ready for me. I got out, barely. They'll be worse now.");
    // {0} is the gang's, possessive; {1} eddies; {2} the gang.
    this.Text("Cyberbane-CrewJobs-BagDoneKnown", "Took {0} bag. {1} in the kitty. Somebody saw me, so {2} know it was us.");
    this.Text("Cyberbane-CrewJobs-BagDone", "Took {0} bag. {1} in the kitty, and nobody saw a thing.");
    // Sent from the gang. {0} is your crew member.
    this.Text("Cyberbane-CrewJobs-BagKilledMember", "{0} came for our money. {0} is not coming back.");
    this.Text("Cyberbane-CrewJobs-BagFailed", "{0} were waiting. Had to run for it. I'll heal.");
    // Sent from the gang. {0} is your crew member's first name.
    this.Text("Cyberbane-CrewJobs-DuelWon", "Your {0} fought clean and won. We'll remember that.");
    this.Text("Cyberbane-CrewJobs-DuelLost", "Your {0} went down in front of everybody. Send somebody better next time.");
    // {0} is the gang's, possessive.
    this.Text("Cyberbane-CrewJobs-DuelLostMember", "Lost to {0} best. I'll live. I want a rematch.");
    this.Text("Cyberbane-CrewJobs-Challenge", "One of yours against one of ours. Send your best, and everybody will know who won. Tell us on the Hub by tomorrow.");
    this.Text("Cyberbane-CrewJobs-ChallengeRefused", "Nobody to send? We thought so.");
    this.Text("Cyberbane-CrewJobs-ChallengeIgnored", "No answer. Your crew's scared of us, and now everybody knows.");
    // {0} is eddies.
    this.Text("Cyberbane-CrewJobs-KittyPaidTheCut", "Paid the crew's cut out of the kitty: {0}. Everybody's square.");
    this.Text("Cyberbane-CrewJobs-WorkIntoTheKitty", "The crew's work brought in {0} eddies today. It's in the kitty.");
    this.Text("Cyberbane-CrewJobs-IllRunTheMoney", "I'll run the kitty to your place every couple of days.");
    // {0} is the gang, {1} eddies.
    this.Text("Cyberbane-CrewJobs-RunJumped", "{0} jumped me on the way to your place. Lost {1}. The rest is still in the kitty.");
    this.Text("Cyberbane-CrewJobs-RunDelivered", "Dropped {0} at your place. Count it if you like.");
    // A note. {0} is the gang's, possessive; {1} eddies.
    this.Text("Cyberbane-CrewJobs-BagWasGoods", "the bag isn't cash: it's {0} goods, worth about {1} eddies. Somebody of another gang will buy it.");
    this.Text("Cyberbane-CrewJobs-GoodsWentStale", "goods you were holding went stale. Nobody will touch them now.");
    // Talk.
    this.Text("Cyberbane-CrewJobs-SellBack", "[Deal] I've got something of yours. Want it back?");
    this.Text("Cyberbane-CrewJobs-SellTo", "[Deal] I've got {0} goods. Interested?");
    this.Text("Cyberbane-CrewJobs-NothingToSell", "You got nothing I want.");
    this.Text("Cyberbane-CrewJobs-BoughtBack", "That's ours. {0}, and be glad it's that much.");
    this.Text("Cyberbane-CrewJobs-BoughtGladly", "{0} stuff? With pleasure. {1}, and their faces when they hear.");
    this.Text("Cyberbane-CrewJobs-Bought", "{0} for the lot. Pleasure doing business.");
  }

  // Signature chrome and strongholds (2.7.2, Rivals/Signature.reds, Rivals/Strongholds.reds).
  protected func DefineRivalPlaces() -> Void {
    this.Text("Cyberbane-Settings-RivalSignature", "Signature chrome");
    this.Text("Cyberbane-Settings-RivalSignature-Desc", "Rivals who climb high enough come back on their gang's signature fighters: mantis blades for Maelstrom and the Mox, gorilla arms for the Tyger Claws and the Wraiths, heavy machine guns, a Voodoo Boys netrunner. The street tells you first, their file says how they fight now, they get a boss bar, and they are likelier to drop an iconic.");
    this.Text("Cyberbane-Settings-Strongholds", "Strongholds");
    this.Text("Cyberbane-Settings-Strongholds-Desc", "A gang that hates you may put one of its top Rivals in a place you cleared on a gig, with lieutenants and a full squad. The street tells you where and it goes on your map. Kill the Rival to take it down for good: the gang loses the place and ground in the district, and you get paid. Left alone, they move on after a week. Only gigs finished with Cyberbane installed count.");
    // Said on the street. {0} is the Rival, {1} what they fight with now ("mantis blades").
    this.Text("Cyberbane-Signature-WordIs", "Word is {0} is back, with {1}.");
    this.Text("Cyberbane-Signature-Mantis", "mantis blades");
    this.Text("Cyberbane-Signature-Gorilla", "gorilla arms");
    this.Text("Cyberbane-Signature-Heavy", "a heavy machine gun");
    this.Text("Cyberbane-Signature-Netrunner", "a netrunner's deck");
    this.Text("Cyberbane-Signature-Blade", "a blade, and the speed to use it");
    this.Text("Cyberbane-Signature-Pistols", "a pistol in each hand");
    this.Text("Cyberbane-Signature-Shotgun", "a shotgun");
    this.Text("Cyberbane-Signature-Juice", "bare fists and a body full of Juice");
    this.Text("Cyberbane-Signature-Sniper", "a sniper rifle");
    // On a Rival's file.
    this.Text("Cyberbane-Signature-CardMantis", "Mantis blades. Fights up close.");
    this.Text("Cyberbane-Signature-CardGorilla", "Gorilla arms. Hits hard enough to break a guard.");
    this.Text("Cyberbane-Signature-CardHeavy", "A heavy machine gun. Keep moving, keep cover.");
    this.Text("Cyberbane-Signature-CardNetrunner", "A netrunner. Expect quickhacks; get to them fast.");
    this.Text("Cyberbane-Signature-CardBlade", "A blade. Fights up close, and fast.");
    this.Text("Cyberbane-Signature-CardPistols", "A pistol in each hand. Close the distance.");
    this.Text("Cyberbane-Signature-CardShotgun", "A shotgun. Deadly up close; stay out of reach.");
    this.Text("Cyberbane-Signature-CardJuice", "Bare fists and Juice. Keep them at range.");
    this.Text("Cyberbane-Signature-CardSniper", "A sniper rifle. Close in under cover.");
    // When the journal has no title for the gig.
    this.Text("Cyberbane-Strongholds-AnOldJob", "a place from one of your old jobs");
    // {0} is the Rival, {1} the place (a gig's title), {2} the district.
    this.Text("Cyberbane-Strongholds-TookOver", "Word is {0} has taken over {1} in {2}, with half their crew. It's on your map.");
    this.Text("Cyberbane-Strongholds-PinTitle", "{0}'s stronghold");
    // {0} is the place, {1} the gang ("The Valentinos").
    this.Text("Cyberbane-Strongholds-PinDesc", "{0}, held by {1}. Kill the one running it and the place falls.");
    this.Text("Cyberbane-Strongholds-Emptied", "{0} cleared out of {1}. Whoever ran it is gone.");
    // {0} is the Rival, {1} the place.
    this.Text("Cyberbane-Strongholds-MovedOn", "Word is {0} moved on from {1}.");
    // A note. {0} is the place, {1} the gang, {2} eddies.
    this.Text("Cyberbane-Strongholds-Cleared", "you took {0} off {1}. They lost the place and the ground around it, and there were {2} eddies inside.");
    // On the Rival's file, with a line break at the end. {0} is the place.
    this.Text("Cyberbane-Strongholds-CardLine", "Holding {0} with half their crew.\n");
  }

  protected func DefineTracking() -> Void {
    this.Text("Cyberbane-Tracking-BountyHunter", "Bounty hunter");
    // {0} owed
    this.Text("Cyberbane-Tracking-OwesMoney", "Owes {0} money");
    this.Text("Cyberbane-Tracking-OwesAGangMoney", "Owes a gang money");
    this.Text("Cyberbane-Tracking-SawYourRival", "Saw your Rival");
    this.Text("Cyberbane-Tracking-Bagman", "bagman");
    this.Text("Cyberbane-Tracking-Lookout", "lookout");
    this.Text("Cyberbane-Tracking-Patrol", "patrol");
    this.Text("Cyberbane-Tracking-HangingOut", "hanging out");
    this.Text("Cyberbane-Tracking-Gathering", "gathering");
    this.Text("Cyberbane-Tracking-ApexSquad", "apex squad");
    this.Text("Cyberbane-Tracking-Crew", "crew");
    this.Text("Cyberbane-Tracking-Hunter", "hunter");
    this.Text("Cyberbane-Tracking-ADebtToCollectTalkThem", "A debt to collect: talk them into paying (Intimidate or Antagonize). If they put their fists up, beat it out of them, but leave them breathing: nobody pays from a body bag.");
    this.Text("Cyberbane-Tracking-AtTheirPlaceNotLookingFor", "At their place, not looking for you. Yet.");
    this.Text("Cyberbane-Tracking-CarryingTheTakeRobThemOr", "Carrying the take. Rob them, or let them walk.");
    this.Text("Cyberbane-Tracking-AFavourWatchingYourFriendsCorner", "A favour: watching your friends' corner. They will fight. Put them down or make them run.");
    this.Text("Cyberbane-Tracking-GangBusinessCrashItOrLeave", "Gang business. Crash it, or leave them to it.");
    this.Text("Cyberbane-Tracking-HereToWatchAndToTell", "Here to watch, and to tell everybody how it went.");
    this.Text("Cyberbane-Tracking-OutToMakeANameOff", "Out to make a name off you. Fists only.");
    this.Text("Cyberbane-Tracking-SawYourRivalAskThemPay", "Saw your Rival. Ask them, pay them, or they may run ahead and warn them.");
    this.Text("Cyberbane-Tracking-WalkingTheirTurf", "Walking their turf.");
    this.Text("Cyberbane-Tracking-HangingOutOnTheirOwnStreets", "Hanging out on their own streets. Somebody of theirs to talk to.");
  }
}

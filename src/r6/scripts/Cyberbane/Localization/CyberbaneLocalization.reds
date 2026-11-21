// Cyberbane - Localization (spec §15), via Codeware localization.
//
// This file carries a module header so it can import Codeware's localization
// types. The provider registers itself automatically (ModLocalizationProvider
// queues its registration in OnAttach). Keys follow Cyberbane-<Area>-<Id>.
//
// English is the fallback language. Translators add further packages and the
// matching language branch in GetPackage.

module Cyberbane.Localization

import Codeware.Localization.*

public class CBLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    if Equals(language, n"en-us") {
      return new CBLocalizationEnUs();
    }
    return null;
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class CBLocalizationEnUs extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
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
    this.Text("Cyberbane-Settings-HitSquadFreq-Desc", "How often gangs send people after you.");
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
    this.Text("Cyberbane-Settings-RivalFreq-Desc", "How often Rivals turn up, and how quickly they track you down.");
    this.Text("Cyberbane-Settings-Whispers-Desc", "Whether you overhear people talking about you as you pass.");
    this.Text("Cyberbane-Settings-WhisperCooldown-Desc", "The gap between overheard lines.");
    this.Text("Cyberbane-Settings-CarsOnFoot-Desc", "Lets gangs, Rivals and apex squads drive to you while you are on foot, pull up and get out. Off, they only drive while you are driving and otherwise walk in out of sight. Turning it off takes effect at once.");
    this.Text("Cyberbane-Settings-Toasts-Desc", "Whether Cyberbane says anything on screen at all: phone, cards, notices and overheard lines. Off changes nothing about the way the mod plays. The answer to a button you press on the Hub or here still shows. Two things have settings of their own: the line at the top of the screen (Hunt line on the HUD, under General) and the bars under it (Rival and apex bars, under Messages and HUD).");
    this.Text("Cyberbane-Settings-MessageHold-Desc", "How long Cyberbane's words stay on screen, as a percentage: messages, the phone's pop-ups, what you overhear, and every line of a conversation, including what people tell you. Longer lines stay longer on their own; this stretches them all. A message waits for the one before it to finish, so none is cut short.");
    this.Text("Cyberbane-Settings-RivalsPerDay-Desc", "How many Rivals can catch up with you in one in-game day, counted separately from crews and apex squads. 0 stops them coming.");
    this.Text("Cyberbane-Settings-HitSquadsPerDay-Desc", "How many gang crews can be sent after you in one in-game day. 0 stops them coming.");
    this.Text("Cyberbane-Settings-ApexPerDay-Desc", "How many apex squads can be sent after you in one in-game day. 0 stops them coming.");
    this.Text("Cyberbane-Settings-EncounterGap-Desc", "How long the city leaves you alone after a fight before arranging the next of that kind. Rivals, crews and apex squads rest separately.");
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
    this.Text("Cyberbane-Settings-Pacing-Desc", "Timetable sends trouble inside daily windows. Unpredictable: any minute might be the one. Reactive: only when you give a gang a reason. The per-day limits apply in every mode.");
    this.Text("Cyberbane-Settings-Scouts-Desc", "A gang that cannot find you sends one scout ahead of the crew. Put the scout down, pay them to keep quiet (with Pay the street on, under Street talk), or stay out of their sight until they lose you, and the crew never comes.");
    this.Text("Cyberbane-Settings-DistrictLine-Desc", "Where you stand in the district you are in, shown on the hunt line while nobody is after you. Always: it stays up. Briefly: it shows when you arrive somewhere and when your standing there changes, then clears. Off: never shown.");
    this.Text("Cyberbane-Settings-DistrictLineSeconds-Desc", "How long the district line stays up, when it is set to Briefly.");
    this.Text("Cyberbane-Settings-HudLine-Desc", "The line of text at the top of the screen. Everything: the full story, all the time. Hunts only: only while somebody is on their way or out looking. Off: hidden. The Rival and apex bars under it are a setting of their own: Rival and apex bars, under Messages and HUD.");
    this.Text("Cyberbane-Settings-ShowCountdowns-Desc", "Show exact times on the Hub and the HUD line. Off says soon, any moment or later instead.");
    this.Text("Cyberbane-Settings-Bounties-Desc", "Putting down a Rival, a crew or an apex squad earns you eddies, paid by a gang at war with theirs. This is a reward to you, not the price on your head (that is A price on your head, under Being hunted).");
    this.Text("Cyberbane-Settings-ApexTraits-Desc", "Each apex gets two traits of its own, so no two fight the same way. Stands down on its own when New Game Plus is installed.");
    this.Text("Cyberbane-Settings-TwrCompat-Desc", "Auto or On: They Will Remember decides who is hostile to you and how well a disguise works, and Cyberbane follows both: every gang it has hostile is hostile here, and crews and hostility on sight are left to it. Off: Cyberbane decides; turn hostility off in They Will Remember's own settings so the two do not disagree.");
    this.Text("Cyberbane-Settings-LogLevel-Desc", "How much Cyberbane writes to its log. Only worth raising for a bug report.");
    this.Text("Cyberbane-Settings-FreezeReputation-Desc", "Stops your reputation changing. Everything already earned keeps working.");
    this.Text("Cyberbane-Settings-HudScale-Desc", "Size of Cyberbane's own screens and bars, on top of the scaling it already does for your resolution.");
    this.Text("Cyberbane-Settings-ResetAll-Desc", "Clears everything Cyberbane recorded on this save: scores, factions, districts, Rivals, titles and log. Turn it on and hit Apply. It stays on in this menu afterwards and does nothing more; to reset again, turn it off, Apply, then on and Apply. Cannot be undone.");
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
    this.Text("Cyberbane-Settings-LieLow-Desc", "While they're still searching for you, changing clothes or slipping into another district out of sight can make them lose the trail. The Hub's gang page says when a gang is still hot about you or cooling off.");
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
    this.Text("Cyberbane-Settings-HitSquadFreq", "Hit squad frequency");

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
    this.Text("Cyberbane-Settings-FactionOn-Arasaka", "Arasaka");
    this.Text("Cyberbane-Settings-FactionOn-Militech", "Militech");
    this.Text("Cyberbane-Settings-FactionOn-KangTao", "Kang Tao");
    this.Text("Cyberbane-Settings-FactionOn-NCPD", "NCPD and MaxTac");
    this.Text("Cyberbane-Settings-FactionOn-Desc", "On: Cyberbane keeps a book on them and they act on it. Off: Cyberbane leaves them alone entirely. They never turn on you on sight because of Cyberbane, send nobody after you, make no Rivals and never text you. What you do to them still counts towards your reputation. Hostility set by the game or by another mod, such as They Will Remember, is not Cyberbane's to switch off.");
    this.Text("Cyberbane-Settings-GangViewAll", "All gangs");
    this.Text("Cyberbane-Settings-GangViewAll-Desc", "How every gang treats you. Earned in play is whatever you have earned with them. Choose anything else and every gang acts that way, whatever you do. Vendetta: every one of their people knows your face and attacks on sight, and they send crews and apex squads after you. Hostile: they know who you are and send crews when you give them a reason. A mask or their colours still hides you. How often they come still sets how many per day. Neutral: they leave you be. Friendly and Allied: lower prices on their turf, and a warning when their enemies come for you. Set a gang below to give it its own. What you earn keeps counting and comes back with Earned in play. Applies to every save.");
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
    this.Text("Cyberbane-Settings-RivalFreq", "Rival frequency");

    // ---- Settings: interface --------------------------------------------
    this.Text("Cyberbane-Settings-Whispers", "Whispers");
    this.Text("Cyberbane-Settings-WhisperCooldown", "Whisper cooldown (s)");
    this.Text("Cyberbane-Settings-Toasts", "Show messages");
    this.Text("Cyberbane-Settings-CarsOnFoot", "Cars arrive on foot too");
    this.Text("Cyberbane-Settings-CarsPerArrival", "Cars per arrival");
    this.Text("Cyberbane-Settings-CarsPerArrival-Desc", "How many cars one crew or apex squad can arrive in. A group too big for one car comes in several, one after another, each picked to seat as many as it can; past this many, the rest walk in.");

    // ---- Settings: compatibility ----------------------------------------
    this.Text("Cyberbane-Settings-TwrCompat", "They Will Remember compatibility");
    this.Text("Cyberbane-Settings-VehicleArrivals", "Arrive by car");
    this.Text("Cyberbane-Settings-CarAmbushes", "Gangs lie in wait");
    this.Text("Cyberbane-Settings-CarAmbushes-Desc", "A gang sworn against you can park a car up the road and pull out as you drive past, more often where you're known to go; the Wraiths do it on Badlands roads whatever their grudge. On foot with a job tracked far away, a crew may wait for you near it instead, outside the job itself. A lookout you paid to keep watch warns you.");
    this.Text("Cyberbane-Settings-LootDrops", "Loot from the people sent after you");
    this.Text("Cyberbane-Settings-Bounties", "Rewards for kills");
    this.Text("Cyberbane-Settings-Pacing", "When they come");
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
    this.Text("Cyberbane-Settings-RivalsPerDay", "Rivals per day");
    this.Text("Cyberbane-Settings-HitSquadsPerDay", "Hit squads per day");
    this.Text("Cyberbane-Settings-ApexPerDay", "Apex squads per day");
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
  }
}

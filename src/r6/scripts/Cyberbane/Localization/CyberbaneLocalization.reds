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
    this.Text("Cyberbane-Settings-StreetTalk-Desc", "Look at somebody up close with your hands empty and the game's own choice prompt comes up: Greet, Dismiss, Antagonize or Intimidate. Scroll and press F to choose. How they answer, and what it does to your standing, depends on whether they know you, how much they and their gang fear and respect you, and how you work.");
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
    this.Text("Cyberbane-Settings-MercyChoice-Desc", "A Rival you put down alive is spared only when you put your weapon away or walk off, or tell them so where they lie; finish them and they die. You can also make them give up another Rival, or run them out of Night City. Off, a Rival left breathing is spared as soon as the fight ends.");
    this.Text("Cyberbane-Settings-SendWord", "Calling out");
    this.Text("Cyberbane-Settings-SendWord-Desc", "Call a Rival out from their page on the Hub, and now and then a Rival calls you out instead of coming. They name a place and wait there with their people. Finishing it there pays more.");
    this.Text("Cyberbane-Settings-Category-Street", "A living street");
    this.Text("Cyberbane-Settings-Bagmen", "Bagmen");
    this.Text("Cyberbane-Settings-Bagmen-Desc", "Now and then a gang's bagman walks the week's take across its turf near you, with one lookout. Put the bagman down and the eddies are yours; the gang takes the loss and won't like you for it.");
    this.Text("Cyberbane-Settings-Favours", "Favours");
    this.Text("Cyberbane-Settings-Favours-Desc", "Ask a ganger who doesn't hate you whether they need anything done: run off a rival gang's lookout, or lean on somebody who owes them. They pay, warm to you, and sometimes pass on a lead.");
    this.Text("Cyberbane-Settings-SitDowns", "Sit-downs");
    this.Text("Cyberbane-Settings-SitDowns-Desc", "Word reaches you that two gangs at war are meeting at a place and an hour. Crash it and both gangs lose strength and fear you more.");
    this.Text("Cyberbane-Settings-SitDownSize", "People per gang at a sit-down");
    this.Text("Cyberbane-Settings-SitDownSize-Desc", "How many of each gang turn up to a sit-down. Two gangs meet, so the sit-down has twice this many people. If too many of Cyberbane's people are already out, fewer turn up.");
    this.Text("Cyberbane-Settings-WhileOut", "While you were out");
    this.Text("Cyberbane-Settings-WhileOut-Desc", "A little after you load, one line about the latest thing that changed the street.");
    this.Text("Cyberbane-Settings-Surrender", "Surrender (experimental)");
    this.Text("Cyberbane-Settings-Surrender-Desc", "Some beaten gangers give up instead of running: hands up, not fighting. Walk away and they leave; grab them and they talk; shoot them and the street hears about it.");
    this.Text("Cyberbane-Settings-ClaimHelp", "Nobody kills you but me (experimental)");
    this.Text("Cyberbane-Settings-ClaimHelp-Desc", "When one gang has you badly outnumbered, a Rival with a claim on you may turn up and fight at your side, then walk off with a promise of next time. Once a day at most.");
    this.Text("Cyberbane-Settings-Category-Gangs", "Gangs");
    this.Text("Cyberbane-Settings-Category-Rivals", "Rivals");
    this.Text("Cyberbane-Settings-Category-SafeAreas", "Safe areas and jobs");
    this.Text("Cyberbane-Settings-Preset-Desc", "Subtle, Default or Dramatic sets everything below in one go, overwriting what is there. Custom leaves your own numbers as they are.");
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
    this.Text("Cyberbane-Settings-Toasts-Desc", "Whether Cyberbane says anything on screen at all: phone, cards, notices and overheard lines. Off changes nothing about the way the mod plays. The hunt line at the top of the screen has its own setting under General, and the Rival and apex bars theirs under Messages and HUD.");
    this.Text("Cyberbane-Settings-MessageHold-Desc", "How long on-screen messages stay up, as a percentage. Never less than five seconds.");
    this.Text("Cyberbane-Settings-RivalsPerDay-Desc", "How many Rivals can catch up with you in one in-game day, counted separately from crews and apex squads. 0 stops them coming.");
    this.Text("Cyberbane-Settings-HitSquadsPerDay-Desc", "How many gang crews can be sent after you in one in-game day. 0 stops them coming.");
    this.Text("Cyberbane-Settings-ApexPerDay-Desc", "How many apex squads can be sent after you in one in-game day. 0 stops them coming.");
    this.Text("Cyberbane-Settings-EncounterGap-Desc", "How long the city leaves you alone after a fight before arranging the next of that kind. Rivals, crews and apex squads rest separately.");
    this.Text("Cyberbane-Settings-TurfWars-Desc", "Hurting a gang weakens it, most of all on its own streets. A broken gang loses its districts to its enemies next door, and they stay taken until somebody takes them back. Off keeps every gang on its own streets.");
    this.Text("Cyberbane-Settings-VendettaApexSquad-Desc", "Every crew a gang sends is led by its apex squad: a heavy, a shooter, a blade and a netrunner. Off sends the crew alone.");
    this.Text("Cyberbane-Settings-ApexArrivalSound-Desc", "Plays the game's own MaxTac descent horn when a gang sends its apex squad.");
    this.Text("Cyberbane-Settings-ApexBossBar-Desc", "The name and health bars at the top of the screen: one for a Rival, one for each apex. The line of text above them is Hunt line on the HUD.");
    this.Text("Cyberbane-Settings-VendettaSquads-Desc", "A gang at vendetta simply comes for you rather than rolling dice. The Hub shows how long until they arrive.");
    this.Text("Cyberbane-Settings-VendettaSquadSize-Desc", "How many a vendetta sends at full menace. Lower it if the frame rate dips when a crew arrives.");
    this.Text("Cyberbane-Settings-VehicleArrivals-Desc", "Rivals, crews and apex squads drive to you whenever a car can be sent, and give chase if you are driving. If a car cannot get through, they come on foot.");
    this.Text("Cyberbane-Settings-ApexStrength-Desc", "How dangerous a gang's apex squad is, as a percentage of a full boss build. 100 matches the game's own set piece enforcers; 55 is hard but fair. Your menace and the game's difficulty scale it further. Rivals have their own slider, under Rivals.");
    this.Text("Cyberbane-Settings-RivalStrength-Desc", "How dangerous a Rival is, as a percentage of a full boss build. A new Rival gets part of it and grows into the rest with every escape, mercy and kill, and running a crew adds a little. 55 is hard but fair. Your menace and the game's difficulty scale it further.");
    this.Text("Cyberbane-Settings-LootDrops-Desc", "Anyone Cyberbane sends who you put down leaves you something, straight into your inventory. The higher they ranked, the better it is.");
    this.Text("Cyberbane-Settings-Pacing-Desc", "Timetable sends trouble inside daily windows. Unpredictable: any minute might be the one. Reactive: only when you give a gang a reason. The per-day limits apply in every mode.");
    this.Text("Cyberbane-Settings-Scouts-Desc", "A gang that cannot find you sends one scout ahead of the crew. Deal with the scout, or stay out of sight, and the crew never comes.");
    this.Text("Cyberbane-Settings-DistrictLine-Desc", "Where you stand in the district you are in, shown on that same line while nobody is after you. Always leaves it up. Briefly shows it when you arrive somewhere and when your standing there changes, then clears it. Off never shows it.");
    this.Text("Cyberbane-Settings-DistrictLineSeconds-Desc", "How long the district line stays up, when it is set to Briefly.");
    this.Text("Cyberbane-Settings-HudLine-Desc", "The line of text at the top of the screen. Everything is the full story. HuntsOnly shows it only while somebody is on their way or out looking. Off hides it. The bars under it are their own setting, just below.");
    this.Text("Cyberbane-Settings-ShowCountdowns-Desc", "Show exact times on the Hub and the HUD line. Off says soon, any moment or later instead.");
    this.Text("Cyberbane-Settings-Bounties-Desc", "Putting down a Rival or an apex squad pays eddies, from a gang at war with theirs.");
    this.Text("Cyberbane-Settings-ApexTraits-Desc", "Each apex gets two traits of its own, so no two fight the same way. Stands down on its own when New Game Plus is installed.");
    this.Text("Cyberbane-Settings-TwrCompat-Desc", "Auto or On: They Will Remember decides who is hostile to you, and Cyberbane follows it (crews, hostility on sight and disguises are left to it). Off: Cyberbane decides; turn hostility off in They Will Remember's own settings so the two do not disagree.");
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
    this.Text("Cyberbane-Settings-HubPauseMenu-Desc", "The Hub has its own tab at the top of the game menu, next to Inventory and Character. Turn this on to have it in the pause menu instead.");
    this.Text("Cyberbane-Settings-Category-Factions", "Factions");
    this.Text("Cyberbane-Settings-Category-GangView", "How gangs see you");
    this.Text("Cyberbane-Settings-Category-Advanced", "Advanced");

    // ---- Settings: general ----------------------------------------------
    this.Text("Cyberbane-Settings-Enabled", "Enabled");
    this.Text("Cyberbane-Settings-Enabled-Desc", "Turns Cyberbane on or off. Off stops every reaction and reverts temporary changes; your reputation is kept.");
    this.Text("Cyberbane-Settings-Preset", "Preset");
    this.Text("Cyberbane-Settings-MessageDelivery", "Where messages go");
    this.Text("Cyberbane-Settings-PhoneSound", "Message tone");
    this.Text("Cyberbane-Settings-MapMarkers", "Mark them on the map");
    this.Text("Cyberbane-Settings-MapMarkers-Desc", "Who carries a Cyberbane marker on your map and minimap: gold for a Rival, purple for an apex squad, white for a crew. Named is the first two. Off leaves you to find them.");
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
    this.Text("Cyberbane-Settings-CarAmbushes", "Gangs lie in wait (experimental)");
    this.Text("Cyberbane-Settings-CarAmbushes-Desc", "Off by default. When a gang with a vendetta against you sends a crew while you are driving, they may wait in a parked car up the road and pull out as you go past. Turn it off and everything goes back to how it was.");
    this.Text("Cyberbane-Settings-LootDrops", "Loot from the people sent after you");
    this.Text("Cyberbane-Settings-Bounties", "Bounties");
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
    this.Text("Cyberbane-Settings-TurfPatrols-Desc", "Off by default. In a district that has changed hands, a few of the new owners walk the streets while you are around. Hostile if you are at war with them.");
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
    this.Text("Cyberbane-Settings-MessageHold", "Message hold");
    this.Text("Cyberbane-Settings-WordTravel", "Word travels (in-game minutes)");
    this.Text("Cyberbane-Settings-WordTravel-Desc", "How long it takes for news of what you did - a body, a dead Rival, a payout, a crew changing hands - to reach your phone. The same story is only told once while it gets around. 0 sends it as it happens.");
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

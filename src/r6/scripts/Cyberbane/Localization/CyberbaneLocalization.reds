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
    this.Text("Cyberbane-Settings-Category-Reputation", "Reputation");
    this.Text("Cyberbane-Settings-Category-Civilians", "Civilians");
    this.Text("Cyberbane-Settings-Category-Gangs", "Gangs");
    this.Text("Cyberbane-Settings-Category-Morale", "Morale");
    this.Text("Cyberbane-Settings-Category-Economy", "Economy");
    this.Text("Cyberbane-Settings-Category-Rivals", "Rivals");
    this.Text("Cyberbane-Settings-Category-SafeAreas", "Safe areas");
    this.Text("Cyberbane-Settings-Preset-Desc", "Subtle, Default or Dramatic. Sets everything below in one go, overwriting what is there.");
    this.Text("Cyberbane-Settings-RenownGain-Desc", "How fast your name spreads.");
    this.Text("Cyberbane-Settings-DreadGain-Desc", "How fast you become frightening. Dread is the score that makes people back off.");
    this.Text("Cyberbane-Settings-Decay-Desc", "How fast reputation fades when you stop earning it. Zero never fades.");
    this.Text("Cyberbane-Settings-RumorSpread-Desc", "How far word about you carries between districts. Lower keeps your name local.");
    this.Text("Cyberbane-Settings-StreetCredFloor-Desc", "Counts the Street Cred you already have as reputation already earned.");
    this.Text("Cyberbane-Settings-CivReactions-Desc", "Whether civilians notice you, give way, cower or run.");
    this.Text("Cyberbane-Settings-CivIntensity-Desc", "How strongly civilians react. Lower this first if the street feels jumpy.");
    this.Text("Cyberbane-Settings-MaxReactingCiv-Desc", "How many civilians may react at the same time.");
    this.Text("Cyberbane-Settings-PanicDriving-Desc", "Whether drivers pull away in a hurry when a frightening V is near.");
    this.Text("Cyberbane-Settings-GangReactions-Desc", "Whether gang members read your standing with them and act on it.");
    this.Text("Cyberbane-Settings-HostileOnSight-Desc", "Whether a gang at vendetta draws the moment they recognise you.");
    this.Text("Cyberbane-Settings-Warnings-Desc", "Whether a hostile gang gives you one spoken warning before turning on you.");
    this.Text("Cyberbane-Settings-CyberpsychoRivals-Desc", "A cyberpsycho you take alive may come back as a rival, with their own name and strength.");
    this.Text("Cyberbane-Settings-FactionDisguises-Desc", "Whether wearing a gang's colours makes that gang slower to place you.");
    this.Text("Cyberbane-Settings-Tribute-Desc", "Whether a gang that fears you sends eddies to stay on your good side.");
    this.Text("Cyberbane-Settings-TributeMult-Desc", "How much that tribute pays.");
    this.Text("Cyberbane-Settings-HitSquads-Desc", "Whether gangs send people after you. This also controls apex squads.");
    this.Text("Cyberbane-Settings-HitSquadFreq-Desc", "How often gangs send people after you.");
    this.Text("Cyberbane-Settings-Morale-Desc", "Whether wounded enemies lose their nerve, and a squad breaks when one of their own drops.");
    this.Text("Cyberbane-Settings-MoraleIntensity-Desc", "How easily enemies break. Zero means nobody runs.");
    this.Text("Cyberbane-Settings-MaxBreakFraction-Desc", "The most of one group that may break at once, so a room never routs together.");
    this.Text("Cyberbane-Settings-VendorPricing-Desc", "Whether your reputation changes what vendors charge you.");
    this.Text("Cyberbane-Settings-MaxDiscount-Desc", "The largest discount your reputation can earn you, as a percentage.");
    this.Text("Cyberbane-Settings-GigBonus-Desc", "Whether fixers pay the famous more on job payouts.");
    this.Text("Cyberbane-Settings-GigBonusMult-Desc", "How big that payout bonus is.");
    this.Text("Cyberbane-Settings-Rivals-Desc", "Whether enemies who get away from you, or who you spare, come back as named Rivals.");
    this.Text("Cyberbane-Settings-MaxRivals-Desc", "How many Rivals you carry at once. At the limit nobody new takes against you, and the ones you have close in faster.");
    this.Text("Cyberbane-Settings-DeathsRemembered-Desc", "Whether whoever kills you can come back as a Rival.");
    this.Text("Cyberbane-Settings-RivalHideouts-Desc", "Gangs and the street sometimes text you where a Rival was last seen. Go there on foot and they may be waiting, not expecting you.");
    this.Text("Cyberbane-Settings-RivalFreq-Desc", "How often Rivals turn up, and how quickly they track you down.");
    this.Text("Cyberbane-Settings-Whispers-Desc", "Whether you overhear people talking about you as you pass.");
    this.Text("Cyberbane-Settings-WhisperCooldown-Desc", "The gap between overheard lines.");
    this.Text("Cyberbane-Settings-CarsOnFoot-Desc", "Lets gangs drive to you while you are on foot, pull up and get out. Experimental: driving a crew in is the most demanding thing Cyberbane asks of the game, and it has not been proven stable. Turn it off and it stops at once.");
    this.Text("Cyberbane-Settings-Toasts-Desc", "Whether Cyberbane says anything on screen at all: phone, cards, notices and overheard lines. Off changes nothing about the way the mod plays. The line and bars at the top of the screen have their own settings, under Interface.");
    this.Text("Cyberbane-Settings-MessageHold-Desc", "How long on-screen messages stay up, as a percentage. Never less than five seconds.");
    this.Text("Cyberbane-Settings-RivalsPerDay-Desc", "How many Rivals can catch up with you in one in-game day, counted separately from crews and apex squads. 0 stops them coming.");
    this.Text("Cyberbane-Settings-HitSquadsPerDay-Desc", "How many gang crews can be sent after you in one in-game day. 0 stops them coming.");
    this.Text("Cyberbane-Settings-ApexPerDay-Desc", "How many apex squads can be sent after you in one in-game day. 0 stops them coming.");
    this.Text("Cyberbane-Settings-EncounterGap-Desc", "How long the city leaves you alone after a fight before arranging the next of that kind. Rivals, crews and apex squads rest separately.");
    this.Text("Cyberbane-Settings-TurfWars-Desc", "Hurting a gang weakens it, and a broken gang loses its districts to its enemies next door. Off keeps every gang on its own streets.");
    this.Text("Cyberbane-Settings-VendettaApexSquad-Desc", "Every crew a gang sends is led by its apex squad: a heavy, a shooter, a blade and a netrunner. Off sends the crew alone.");
    this.Text("Cyberbane-Settings-ApexArrivalSound-Desc", "Plays the game's own MaxTac descent horn when a gang sends its apex squad.");
    this.Text("Cyberbane-Settings-ApexBossBar-Desc", "The name and health bars at the top of the screen: one for a Rival, one for each apex. The line of text above them is Hunt line on the HUD.");
    this.Text("Cyberbane-Settings-VendettaSquads-Desc", "A gang at vendetta simply comes for you rather than rolling dice. The Hub shows how long until they arrive.");
    this.Text("Cyberbane-Settings-VendettaSquadSize-Desc", "How many a vendetta sends at full menace. Lower it if the frame rate dips when a crew arrives.");
    this.Text("Cyberbane-Settings-VehicleArrivals-Desc", "Crews and apex squads drive to you instead of appearing on foot, and give chase if you are driving.");
    this.Text("Cyberbane-Settings-ApexStrength-Desc", "How dangerous an apex is, as a percentage of a full boss build. 100 matches the game's own set piece enforcers; 55 is hard but fair. Your menace and the game's difficulty scale it further.");
    this.Text("Cyberbane-Settings-LootDrops-Desc", "Anyone Cyberbane sends who you put down leaves you something, straight into your inventory. The higher they ranked, the better it is.");
    this.Text("Cyberbane-Settings-Pacing-Desc", "Timetable sends trouble inside daily windows. Unpredictable: any minute might be the one. Reactive: only when you give a gang a reason. The per-day limits apply in every mode.");
    this.Text("Cyberbane-Settings-Scouts-Desc", "A gang that cannot find you sends one scout ahead of the crew. Deal with the scout, or stay out of sight, and the crew never comes.");
    this.Text("Cyberbane-Settings-DistrictLine-Desc", "Where you stand in the district you are in, shown on that same line while nobody is after you. Always leaves it up. Briefly shows it when you arrive somewhere and when your standing there changes, then clears it. Off never shows it.");
    this.Text("Cyberbane-Settings-DistrictLineSeconds-Desc", "How long the district line stays up, when it is set to Briefly.");
    this.Text("Cyberbane-Settings-HudLine-Desc", "The line of text at the top of the screen. Everything is the full story. HuntsOnly shows it only while somebody is on their way or out looking. Off hides it. The bars under it are their own setting, just below.");
    this.Text("Cyberbane-Settings-ShowCountdowns-Desc", "Show exact times on the Hub and the HUD line. Off says soon, any moment or later instead.");
    this.Text("Cyberbane-Settings-Bounties-Desc", "Putting down a Rival or an apex squad pays eddies, from a gang at war with theirs.");
    this.Text("Cyberbane-Settings-ApexTraits-Desc", "Each apex gets two traits of its own, so no two fight the same way. Stands down on its own when New Game Plus is installed.");
    this.Text("Cyberbane-Settings-TwrCompat-Desc", "Compatibility with They Will Remember and Night City Remembers. Auto spots them and stands down what would otherwise run twice.");
    this.Text("Cyberbane-Settings-LogLevel-Desc", "How much Cyberbane writes to its log. Only worth raising for a bug report.");
    this.Text("Cyberbane-Settings-FreezeReputation-Desc", "Stops your reputation changing. Everything already earned keeps working.");
    this.Text("Cyberbane-Settings-HudScale-Desc", "Size of Cyberbane's own screens and bars, on top of the scaling it already does for your resolution.");
    this.Text("Cyberbane-Settings-ResetAll-Desc", "Clears everything Cyberbane recorded on this save: scores, factions, districts, Rivals, titles and log. Turn it on and hit Apply; it switches itself off when done. Cannot be undone.");
    this.Text("Cyberbane-Settings-SafeZoneSpawns", "Allow spawns in safe areas");
    this.Text("Cyberbane-Settings-QuestAreas", "Stay out of quest areas");
    this.Text("Cyberbane-Settings-QuestAreaRadius", "Quest area size (metres)");
    this.Text("Cyberbane-Settings-QuestAreas-Desc", "Nobody is sent after you while you are on a tracked job, in a conversation or in a restricted area, and hunters already out do not follow you in. The story's own scenes are protected whatever this is set to.");
    this.Text("Cyberbane-Settings-QuestAreaRadius-Desc", "How close to the tracked objective counts as being on the job. 80 covers almost every gig site.");
    this.Text("Cyberbane-Settings-SafeZoneSpawns-Desc", "Let them turn up inside apartments, bars and clinics. Off by default, because the game disarms you there.");
    this.Text("Cyberbane-Settings-SafeZoneCombat", "Let me fight in safe areas");
    this.Text("Cyberbane-Settings-SafeZoneCombat-Desc", "Keeps your hands free in a safe area so you can fight back. Use it with the setting above.");
    this.Text("Cyberbane-Settings-Category-UI", "Interface");
    this.Text("Cyberbane-Settings-Category-Compat", "Compatibility");
    this.Text("Cyberbane-Settings-Category-Debug", "Debug");

    // ---- Settings: general ----------------------------------------------
    this.Text("Cyberbane-Settings-Enabled", "Enabled");
    this.Text("Cyberbane-Settings-Enabled-Desc", "Turns Cyberbane on or off. Off stops every reaction and reverts temporary changes; your reputation is kept.");
    this.Text("Cyberbane-Settings-Preset", "Preset");
    this.Text("Cyberbane-Settings-MessageDelivery", "Where messages go");
    this.Text("Cyberbane-Settings-PhoneSound", "Message tone");
    this.Text("Cyberbane-Settings-MapMarkers", "Mark them on the map");
    this.Text("Cyberbane-Settings-MapMarkers-Desc", "Who gets a map marker. Named is a Rival and the apex squad. Everyone adds the crews and the escorts. Off leaves you to find them.");
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

    // ---- Settings: morale -----------------------------------------------
    this.Text("Cyberbane-Settings-Morale", "Combat morale");
    this.Text("Cyberbane-Settings-MoraleIntensity", "Morale intensity");
    this.Text("Cyberbane-Settings-MaxBreakFraction", "Max fraction that can break");

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
    this.Text("Cyberbane-Settings-RivalFreq", "Rival frequency");

    // ---- Settings: interface --------------------------------------------
    this.Text("Cyberbane-Settings-Whispers", "Whispers");
    this.Text("Cyberbane-Settings-WhisperCooldown", "Whisper cooldown (s)");
    this.Text("Cyberbane-Settings-Toasts", "Show messages");
    this.Text("Cyberbane-Settings-CarsOnFoot", "Cars arrive on foot too (experimental)");

    // ---- Settings: compatibility ----------------------------------------
    this.Text("Cyberbane-Settings-TwrCompat", "They Will Remember compatibility");
    this.Text("Cyberbane-Settings-VehicleArrivals", "Arrive by car");
    this.Text("Cyberbane-Settings-LootDrops", "Loot from the people sent after you");
    this.Text("Cyberbane-Settings-Bounties", "Bounties");
    this.Text("Cyberbane-Settings-Pacing", "When they come");
    this.Text("Cyberbane-Settings-Scouts", "Scouts before crews");
    this.Text("Cyberbane-Settings-ShowCountdowns", "Show countdowns");
    this.Text("Cyberbane-Settings-HudLine", "Hunt line on the HUD");
    this.Text("Cyberbane-Settings-DistrictLine", "District line");
    this.Text("Cyberbane-Settings-DistrictLineSeconds", "District line, seconds");
    this.Text("Cyberbane-Settings-ApexStrength", "Apex strength");
    this.Text("Cyberbane-Settings-ApexTraits", "Apex traits");
    this.Text("Cyberbane-Settings-ApexBossBar", "Rival and apex bars");
    this.Text("Cyberbane-Settings-ApexArrivalSound", "Apex squad arrival horn");
    this.Text("Cyberbane-Settings-VendettaApexSquad", "Crews bring the apex squad");
    this.Text("Cyberbane-Settings-TurfWars", "Turf wars");
    this.Text("Cyberbane-Settings-UnseenDread", "How frightening unseen work is");
    this.Text("Cyberbane-Settings-UnseenDread-Desc", "How much a killing nobody witnessed still adds to how frightening you are. Zero counts only what people saw.");
    this.Text("Cyberbane-Settings-BrutalConduct", "Melee kills cost Conduct");
    this.Text("Cyberbane-Settings-BrutalConduct-Desc", "Whether killing with a blade, bare hands or a takedown counts against your Conduct. Witnessed kills only.");
    this.Text("Cyberbane-Settings-EncounterGap", "Minutes between encounters");
    this.Text("Cyberbane-Settings-RivalsPerDay", "Rivals per day");
    this.Text("Cyberbane-Settings-HitSquadsPerDay", "Hit squads per day");
    this.Text("Cyberbane-Settings-ApexPerDay", "Apex squads per day");
    this.Text("Cyberbane-Settings-MessageHold", "Message hold");
    this.Text("Cyberbane-Settings-CyberpsychoRivals", "Spared cyberpsychos come back");
    this.Text("Cyberbane-Settings-VendettaSquads", "Vendetta hit squads");
    this.Text("Cyberbane-Settings-VendettaSquadSize", "Vendetta squad size");

    // ---- Settings: debug ------------------------------------------------
    this.Text("Cyberbane-Settings-LogLevel", "Log level");
    this.Text("Cyberbane-Settings-FreezeReputation", "Freeze reputation");
    this.Text("Cyberbane-Settings-ResetAll", "Reset all Cyberbane data");
    this.Text("Cyberbane-Settings-HudScale", "Interface size");

    // ---- Core ------------------------------------------------------------
    this.Text("Cyberbane-Name", "Cyberbane");
  }
}

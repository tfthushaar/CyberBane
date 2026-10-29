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
    this.Text("Cyberbane-Settings-Category-Police", "Police");
    this.Text("Cyberbane-Settings-Category-Economy", "Economy");
    this.Text("Cyberbane-Settings-Category-Rivals", "Rivals");
    this.Text("Cyberbane-Settings-Category-SafeAreas", "Safe areas");
    this.Text("Cyberbane-Settings-Preset-Desc", "Subtle, Default or Dramatic. Sets how loud and how frequent everything is in one go. Picking one overwrites the individual settings below.");
    this.Text("Cyberbane-Settings-HubKey-Desc", "Which key opens the Hub and steps through its screens. F7 by default.");
    this.Text("Cyberbane-Settings-RenownGain-Desc", "Multiplies how fast your name spreads. Lower it for a slow climb, raise it to be known quickly.");
    this.Text("Cyberbane-Settings-DreadGain-Desc", "Multiplies how fast you become frightening. Dread is the score that actually makes people back off.");
    this.Text("Cyberbane-Settings-Decay-Desc", "How fast reputation fades when you stop earning it. Zero means it never fades.");
    this.Text("Cyberbane-Settings-RumorSpread-Desc", "How far word about you carries between districts. Lower keeps your name local to where you earned it.");
    this.Text("Cyberbane-Settings-StreetCredFloor-Desc", "Counts the Street Cred you already have as reputation you already earned, so Cyberbane does not treat a veteran V as a nobody.");
    this.Text("Cyberbane-Settings-CivReactions-Desc", "Whether civilians notice you, give way, cower or run.");
    this.Text("Cyberbane-Settings-CivIntensity-Desc", "How strongly civilians react. Lower this first if the street feels too jumpy.");
    this.Text("Cyberbane-Settings-MaxReactingCiv-Desc", "How many civilians may react at the same time. Lower it if crowds feel chaotic.");
    this.Text("Cyberbane-Settings-PanicDriving-Desc", "Whether drivers pull away in a hurry when a frightening V is nearby.");
    this.Text("Cyberbane-Settings-GangReactions-Desc", "Whether gang members read your standing with them and act on it.");
    this.Text("Cyberbane-Settings-HostileOnSight-Desc", "Whether a gang with a vendetta against you draws the moment they recognise you.");
    this.Text("Cyberbane-Settings-Warnings-Desc", "Whether a hostile gang gives you one spoken warning before turning on you.");
    this.Text("Cyberbane-Settings-FactionDisguises-Desc", "Whether wearing a gang's colours makes that gang slower to place you.");
    this.Text("Cyberbane-Settings-Tribute-Desc", "Whether a gang that fears you may quietly send eddies to stay on your good side.");
    this.Text("Cyberbane-Settings-TributeMult-Desc", "Multiplies how much that tribute pays.");
    this.Text("Cyberbane-Settings-HitSquads-Desc", "Whether gangs send people after you. This also controls apex hunters.");
    this.Text("Cyberbane-Settings-HitSquadFreq-Desc", "How often gangs send people after you.");
    this.Text("Cyberbane-Settings-Morale-Desc", "Whether wounded enemies lose their nerve and run, and whether a squad breaks when one of their own drops.");
    this.Text("Cyberbane-Settings-MoraleIntensity-Desc", "How easily enemies break. Zero means nobody ever runs.");
    this.Text("Cyberbane-Settings-MaxBreakFraction-Desc", "The most of one group that may break at once, so a whole room never routs together.");
    this.Text("Cyberbane-Settings-VendorPricing-Desc", "Whether your reputation changes what vendors charge you.");
    this.Text("Cyberbane-Settings-MaxDiscount-Desc", "The largest discount your reputation can earn you, as a percentage.");
    this.Text("Cyberbane-Settings-GigBonus-Desc", "Whether fixers pay the famous more on job payouts.");
    this.Text("Cyberbane-Settings-GigBonusMult-Desc", "Multiplies the size of that payout bonus.");
    this.Text("Cyberbane-Settings-Rivals-Desc", "Whether enemies who get away from you, or who you put down and spare, come back as named Rivals.");
    this.Text("Cyberbane-Settings-MaxRivals-Desc", "How many Rivals you can be carrying at once. At the limit nobody new takes against you, and the ones you have close in faster so you can clear them.");
    this.Text("Cyberbane-Settings-DeathsRemembered-Desc", "Whether whoever kills you can come back as a Rival.");
    this.Text("Cyberbane-Settings-RivalFreq-Desc", "How often Rivals turn up, and how quickly they track you down.");
    this.Text("Cyberbane-Settings-Whispers-Desc", "Whether you overhear people talking about you as you pass.");
    this.Text("Cyberbane-Settings-WhisperCooldown-Desc", "The gap between overheard lines, so the street does not repeat itself.");
    this.Text("Cyberbane-Settings-Toasts-Desc", "Whether Cyberbane shows its messages on screen at all.");
    this.Text("Cyberbane-Settings-VendettaSquads-Desc", "A gang at vendetta stops rolling dice over whether to come after you and simply comes. The Hub shows how long until they arrive. They will wait rather than walk in on a gig, a quiet job or a safe area, so the timer holds instead of cancelling.");
    this.Text("Cyberbane-Settings-VendettaSquadSize-Desc", "How many a gang at vendetta sends when you are at full menace. Fewer turn out if you are less of a problem to them. Large numbers are the point of a vendetta, but every one of them is a real NPC, so lower this if you see the frame rate dip when a crew arrives.");
    this.Text("Cyberbane-Settings-VehicleArrivals-Desc", "Hit squads and apex enforcers drive to you instead of appearing on foot. The car is spawned out of sight, loads its crew and comes to find you; if you are driving, it gives chase. Turned off, or indoors where a car cannot reach, they arrive on foot as before.");
    this.Text("Cyberbane-Settings-ApexStrength-Desc", "How dangerous an apex enforcer is, as a percentage of a full boss build. At 100 it is in the same class as the game's own set piece enforcers and is meant to be a serious fight. The default 70 is hard but fair. This scales health, armour, damage and crit together, and it is also scaled by your own menace, so an apex is always measured against where you are.");
    this.Text("Cyberbane-Settings-ApexTraits-Desc", "Each apex gets two traits of its own, so no two fight the same way: heavier plate, a harder hit, a better eye for the gap in your armour, a deeper health pool, or simply fighting above its level. Turns itself off automatically when New Game Plus is installed, because that mod already hands out its own.");
    this.Text("Cyberbane-Settings-TwrCompat-Desc", "Compatibility with They Will Remember and Night City Remembers. On Auto, Cyberbane spots them and stands down the systems that would otherwise run twice.");
    this.Text("Cyberbane-Settings-LogLevel-Desc", "How much Cyberbane writes to its log. Only worth raising when you are reporting a bug.");
    this.Text("Cyberbane-Settings-FreezeReputation-Desc", "Stops your reputation changing at all, while everything already earned keeps working.");
    this.Text("Cyberbane-Settings-SafeZoneSpawns", "Allow spawns in safe areas");
    this.Text("Cyberbane-Settings-SafeZoneSpawns-Desc", "Let rivals, hit squads and apex hunters turn up inside apartments, bars and clinics. Off by default, because the game disarms you in those places.");
    this.Text("Cyberbane-Settings-SafeZoneCombat", "Let me fight in safe areas");
    this.Text("Cyberbane-Settings-SafeZoneCombat-Desc", "Stops the game forcing your hands empty when you enter a safe area, so you can fight back. Turn this on with the setting above.");
    this.Text("Cyberbane-Settings-Category-UI", "Interface");
    this.Text("Cyberbane-Settings-Category-Compat", "Compatibility");
    this.Text("Cyberbane-Settings-Category-Debug", "Debug");

    // ---- Settings: general ----------------------------------------------
    this.Text("Cyberbane-Settings-Enabled", "Enabled");
    this.Text("Cyberbane-Settings-Enabled-Desc", "Turns Cyberbane on or off. Off stops every reaction and reverts temporary changes; your reputation is kept.");
    this.Text("Cyberbane-Settings-Preset", "Preset");
    this.Text("Cyberbane-Settings-HubKey", "Hub key");

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
    this.Text("Cyberbane-Settings-RivalFreq", "Rival frequency");

    // ---- Settings: interface --------------------------------------------
    this.Text("Cyberbane-Settings-Whispers", "Whispers");
    this.Text("Cyberbane-Settings-WhisperCooldown", "Whisper cooldown (s)");
    this.Text("Cyberbane-Settings-Toasts", "Toasts");

    // ---- Settings: compatibility ----------------------------------------
    this.Text("Cyberbane-Settings-TwrCompat", "They Will Remember compatibility");
    this.Text("Cyberbane-Settings-VehicleArrivals", "Arrive by car");
    this.Text("Cyberbane-Settings-ApexStrength", "Apex strength");
    this.Text("Cyberbane-Settings-ApexTraits", "Apex traits");
    this.Text("Cyberbane-Settings-VendettaSquads", "Vendetta hit squads");
    this.Text("Cyberbane-Settings-VendettaSquadSize", "Vendetta squad size");

    // ---- Settings: debug ------------------------------------------------
    this.Text("Cyberbane-Settings-LogLevel", "Log level");
    this.Text("Cyberbane-Settings-FreezeReputation", "Freeze reputation");

    // ---- Core ------------------------------------------------------------
    this.Text("Cyberbane-Name", "Cyberbane");
  }
}

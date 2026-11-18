// Cyberbane - Settings (spec §13), via Mod Settings.
//
// Mod Settings discovers this class by reflection (any field carrying the
// "ModSettings.mod" runtimeProperty). An instance is created and registered each
// session by CyberbaneSystem; other modules read the live values through
// CyberbaneRuntime.Get().GetSettings().

enum ECBPreset {
  Subtle = 0,
  Default = 1,
  Dramatic = 2,
  Custom = 3,
  Nemesis = 4,     // 2.4.6, [90]: Rivals first
  TurfWar = 5,     // gangs and districts first
  QuietLife = 6,   // the street and talk, hardly anybody hunting
}

enum ECBPronouns {
  Auto = 0,
  He = 1,
  She = 2,
  They = 3,
}

enum ECBTwrCompat {
  Auto = 0,
  On = 1,
  Off = 2,
}

// How much Cyberbane marks on the map (spec 12.3).
//
// This was a plain on/off and both answers were wrong. Off, and a player hunting for whoever
// the mod had just announced finds nothing. On, and every crew member wears a quest marker -
// which a player called "the obnoxious yellow markers", and they were right: fifteen of them,
// through walls, in the colour the game reserves for the thing you are supposed to be doing.
//
// Everyone is the default: if Cyberbane sent them, the player can see where they are. NamedOnly is
// the people who are somebody: a Rival and an apex squad (UI/Tracking.reds).
enum ECBMarkerScope {
  Off = 0,
  NamedOnly = 1,
  Everyone = 2,
}

// Where Cyberbane's messages go (spec 12.2).
//
// Phone is the default: each sender is a contact in V's own phone, a new message arrives as the
// game's incoming-SMS notification, and the thread opens in the phone's messenger. Cards is
// Cyberbane drawing the message on the left of the screen itself, and nothing of Cyberbane's
// enters the phone. It exists so that a player whose phone misbehaves has a way out that does
// not go through the phone. Notices is the old line across the middle of the screen.
//
// Off is silence, and it is here rather than only on the Toasts switch because this is the
// setting a player looking to turn messages off actually opens. A player asked for it: they
// liked the mechanics and did not want to be told their nemesis had climbed a rank or that
// somebody was tracking them - they would rather be surprised. Off files nothing, draws nothing
// and keeps Cyberbane out of the phone, and the gameplay is untouched: they still come, the
// Hub still brokers peace, and the HUD line is its own setting (ECBHudLine) for anyone who
// wants the warning without the texts.
enum ECBMessageDelivery {
  Phone = 0,
  Cards = 1,
  Notices = 2,
  Off = 3,
}

// How the city decides when to come for V. Timetable is the day split into windows (Spawn/
// Schedule.reds). Unpredictable has no windows at all: every minute carries a small chance that
// rises at night for crews and Rivals. Reactive sends crews only when V gives a gang a reason, apex
// squads only when a gang has earned one, and Rivals unpredictably.
enum ECBPacing {
  Timetable = 0,
  Unpredictable = 1,
  Reactive = 2,
}

// What the HUD line at the top of the screen shows. Everything is the full story: tracked, on
// their way, searching, spotted, found, and how it ended. Hunts only drops TRACKED and the ending.
// Off hides the line.
//
// (A Hub style setting sat here in the 1.6 work in progress, choosing between drawing the Hub on
// the menu layer and on the HUD layer. Neither is how the Hub is drawn any more - it is a page of
// the pause menu (UI/PauseMenuEntry.reds) - so the choice it offered no longer exists.)
enum ECBHudLine {
  Everything = 0,
  HuntsOnly = 1,
  Off = 2,
}

// How long the district half of that line stays up. Always is what 1.6.0 shipped and what the
// first report about it was: "the text just stays there on top of the screen". Briefly puts it up
// when V arrives somewhere and again when their standing there crosses into the next word, then
// clears it. Off never draws it and leaves the hunt warnings alone.
enum ECBDistrictLine {
  Always = 0,
  Briefly = 1,
  Off = 2,
}

enum ECBLogLevel {
  Off = 0,
  Info = 1,
  Verbose = 2,
}

// How a gang treats V (2.1.0, "How gangs see you"). A player asked for it, for a group playing Arasaka
// corpos: every gang with a vendetta against them, set by hand. Earned is what V earned in play; any other
// value is the stance the gang takes whatever V does (Data/Factions.reds, CBActingStanding). Each gang's
// own setting can follow the page's first one (AllGangs) or say for itself. The values read as their
// names in the menu, so they are single words; the two that are not get a label (displayValues).
enum ECBGangViewAll {
  Earned = 0,
  Allied = 1,
  Friendly = 2,
  Neutral = 3,
  Hostile = 4,
  Vendetta = 5,
}

enum ECBGangView {
  AllGangs = 0,
  Earned = 1,
  Allied = 2,
  Friendly = 3,
  Neutral = 4,
  Hostile = 5,
  Vendetta = 6,
}

public class CyberbaneSettings {
  // ---- General -----------------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Enabled")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Enabled-Desc")
  public let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Preset")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Preset-Desc")
  public let preset: ECBPreset = ECBPreset.Default;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MessageDelivery")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MessageDelivery-Desc")
  public let messageDelivery: ECBMessageDelivery = ECBMessageDelivery.Phone;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HudLine")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HudLine-Desc")
  public let hudLine: ECBHudLine = ECBHudLine.Everything;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MapMarkers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MapMarkers-Desc")
  public let mapMarkers: ECBMarkerScope = ECBMarkerScope.Everyone;


  // ---- How often they come -----------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Pacing")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Pacing-Desc")
  public let pacing: ECBPacing = ECBPacing.Timetable;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-EncounterGap")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-EncounterGap-Desc")
  @runtimeProperty("ModSettings.min", "2")
  @runtimeProperty("ModSettings.max", "30")
  @runtimeProperty("ModSettings.step", "1")
  public let encounterGapMinutes: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalsPerDay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalsPerDay-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20")
  @runtimeProperty("ModSettings.step", "1")
  public let rivalsPerDay: Int32 = 8;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquadsPerDay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HitSquadsPerDay-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20")
  @runtimeProperty("ModSettings.step", "1")
  public let hitSquadsPerDay: Int32 = 5;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexPerDay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexPerDay-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20")
  @runtimeProperty("ModSettings.step", "1")
  public let apexSquadsPerDay: Int32 = 4;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalFreq")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalFreq-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let rivalFrequencyMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Pacing")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquadFreq")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HitSquadFreq-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let hitSquadFrequencyMult: Float = 1.0;


  // ---- Rivals ------------------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Rivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Rivals-Desc")
  public let rivals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxRivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxRivals-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  @runtimeProperty("ModSettings.step", "1")
  public let maxRivals: Int32 = 8;

  // How strong a Rival is (1.9.2, Spawn/FactionApex.reds, CBRivalStrengthFraction). Rivals are built with
  // the apex build, and the apex slider used to set both. Same scale and default as Apex strength.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalStrength")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalStrength-Desc")
  @runtimeProperty("ModSettings.min", "20")
  @runtimeProperty("ModSettings.max", "100")
  @runtimeProperty("ModSettings.step", "5")
  public let rivalStrength: Int32 = 55;

  // Two or three Rivals of one gang coming for V together (1.9.0, Spawn/RivalEncounter.reds). On by
  // default. Named `rivalTeams`, not the `rivalTeamUps` the first 1.9.0 build had while it was an
  // experiment that shipped off: Mod Settings keeps a value by its field's name, so under the old name
  // anybody who had launched that build would have stayed off and never seen the new default.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalTeamUps")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalTeamUps-Desc")
  public let rivalTeams: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalTeamSize")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalTeamSize-Desc")
  @runtimeProperty("ModSettings.min", "2")
  @runtimeProperty("ModSettings.max", "3")
  @runtimeProperty("ModSettings.step", "1")
  public let rivalTeamSize: Int32 = 2;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DeathsRemembered")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DeathsRemembered-Desc")
  public let deathsRemembered: Bool = true;

  // Tips on where a Rival was last seen, and the Rival waiting there (Rivals/Whereabouts.reds).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalHideouts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalHideouts-Desc")
  public let rivalHideouts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SendWord")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SendWord-Desc")
  public let sendWord: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MercyChoice")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MercyChoice-Desc")
  public let mercyChoice: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Informants")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Informants-Desc")
  public let informants: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalFlaws")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalFlaws-Desc")
  public let rivalFlaws: Bool = true;

  // A Rival pushed far enough may come back a cyberpsycho (1.9.0, Rivals/RivalSystem.reds).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PsychoBreaks")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PsychoBreaks-Desc")
  public let psychoBreaks: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CyberpsychoRivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CyberpsychoRivals-Desc")
  public let cyberpsychoRivals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalChrome")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalChrome-Desc")
  @runtimeProperty("ModSettings.dependency", "rivals")
  public let rivalChrome: Bool = true;

  // ---- Rivals and you (2.4.4): what happens between V and a Rival, and what a Rival does with their life ----
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Facedown")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Facedown-Desc")
  public let facedown: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-NobodyButMe")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-NobodyButMe-Desc")
  public let nobodyButMe: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-BackFromDead")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-BackFromDead-Desc")
  public let backFromDead: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalFeuds")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalFeuds-Desc")
  public let rivalFeuds: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-RivalsYou")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Trophies")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Trophies-Desc")
  public let trophies: Bool = true;



  // ---- Crews and apex squads ---------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquads")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HitSquads-Desc")
  public let hitSquads: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendettaSquads")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendettaSquads-Desc")
  public let vendettaSquads: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendettaSquadSize")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendettaSquadSize-Desc")
  @runtimeProperty("ModSettings.min", "6")
  @runtimeProperty("ModSettings.max", "24")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "vendettaSquads")
  public let vendettaSquadSize: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Scouts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Scouts-Desc")
  public let scouts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendettaApexSquad")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendettaApexSquad-Desc")
  public let vendettaApexSquad: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexStrength")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexStrength-Desc")
  @runtimeProperty("ModSettings.min", "20")
  @runtimeProperty("ModSettings.max", "100")
  @runtimeProperty("ModSettings.step", "5")
  public let apexStrength: Int32 = 55;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexTraits")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexTraits-Desc")
  public let apexTraits: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FairVolley")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FairVolley-Desc")
  public let fairVolley: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PanicInDark")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PanicInDark-Desc")
  public let panicInDark: Bool = true;

  // A crew of V's own (Reactions/Crew.reds, 2.5.0).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-MyCrew")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MyCrew")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MyCrew-Desc")
  public let myCrew: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-MyCrew")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CrewComeOnOwn")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CrewComeOnOwn-Desc")
  @runtimeProperty("ModSettings.dependency", "myCrew")
  public let crewComeOnOwn: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-MyCrew")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CrewBetrayal")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CrewBetrayal-Desc")
  @runtimeProperty("ModSettings.dependency", "myCrew")
  public let crewBetrayal: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-MyCrew")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CrewFrightJoin")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CrewFrightJoin-Desc")
  @runtimeProperty("ModSettings.dependency", "myCrew")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let crewFrightJoin: Float = 0.3;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-MyCrew")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CrewCutMult")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CrewCutMult-Desc")
  @runtimeProperty("ModSettings.dependency", "myCrew")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.1")
  public let crewCutMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VehicleArrivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VehicleArrivals-Desc")
  public let vehicleArrivals: Bool = true;

  // On by default since 1.6.6. 1.5.2 had stopped cars arriving around a player on foot after a
  // crash that was reported but never traced. 1.6.6 found the convoy choosing its car without
  // regard to the crew and mounting people by a fixed list of four seat names, so a two-seater
  // was handed back-seat passengers it has no slots for, and reading every car's seats from a
  // field the traffic records leave empty (Spawn/Arrival.reds, CBVehicleSeatNames). Those are
  // fixed at the source, and the switch is kept so anybody can still turn it off.
  //
  // Renamed from carArrivalsOnFoot so the new default reaches installs that never touched it:
  // Mod Settings keeps values by field name, and the old one was stored as off for everybody.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CarsOnFoot")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CarsOnFoot-Desc")
  @runtimeProperty("ModSettings.dependency", "vehicleArrivals")
  public let carsWhileOnFoot: Bool = true;

  // How many cars one arrival can come in (Spawn/Arrival.reds, CBSendByCar). A crew too big for
  // one car comes in several, one after another; past this many, the rest walk in.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CarsPerArrival")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CarsPerArrival-Desc")
  @runtimeProperty("ModSettings.min", "1")
  @runtimeProperty("ModSettings.max", "5")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "vehicleArrivals")
  public let carsPerArrival: Int32 = 4;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CarAmbushes")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CarAmbushes-Desc")
  // A new name (2.4.2) so the new default, on, reaches everybody: the old carAmbushes was stored off on every install.
  public let gangsLieInWait: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Bounties")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Bounties-Desc")
  public let bounties: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LieLow")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-LieLow-Desc")
  public let lieLow: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Haunts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Haunts-Desc")
  public let haunts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Lookouts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Lookouts-Desc")
  public let lookouts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Trackers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Trackers-Desc")
  public let trackers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-OpenSeason")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-OpenSeason-Desc")
  public let openSeason: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PriceOnHead")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PriceOnHead-Desc")
  public let priceOnHead: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Hunted")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CorpContracts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CorpContracts-Desc")
  @runtimeProperty("ModSettings.dependency", "priceOnHead")
  public let corpContracts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Crews")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LootDrops")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-LootDrops-Desc")
  public let lootDrops: Bool = true;


  // ---- Gangs -------------------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangReactions")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangReactions-Desc")
  public let gangReactions: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HostileOnSight")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HostileOnSight-Desc")
  @runtimeProperty("ModSettings.dependency", "gangReactions")
  public let hostileOnSight: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangCodes")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangCodes-Desc")
  public let gangCodes: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangsAdapt")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangsAdapt-Desc")
  public let gangsAdapt: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Warnings")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Warnings-Desc")
  public let warnings: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionDisguises")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionDisguises-Desc")
  public let factionDisguises: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-KnownByCarAndGun")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-KnownByCarAndGun-Desc")
  public let knownByCarAndGun: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-BossesSeeThrough")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-BossesSeeThrough-Desc")
  public let bossesSeeThrough: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RunWithCrew")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RunWithCrew-Desc")
  public let runWithCrew: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-OneOfTheirs")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-OneOfTheirs-Desc")
  public let oneOfTheirs: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Surrender")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Surrender-Desc")
  // A new name (2.3.2) so the new default, on, reaches everybody: Mod Settings keeps values by field name, and the
  // old `surrender` was stored as off on every install from when it was experimental.
  public let gangsSurrender: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Tribute")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Tribute-Desc")
  public let tribute: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TributeMult")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TributeMult-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  @runtimeProperty("ModSettings.dependency", "tribute")
  public let tributeMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-EnemyOfEnemy")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-EnemyOfEnemy-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let enemyOfEnemyShare: Float = 0.5;

  // ---- Turf (2.3.1: off the Gangs heading) ------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TurfWars")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TurfWars-Desc")
  public let turfWars: Bool = true;

  // Whether the game's own map lists a district's new holder (UI/TurfMap.reds). For players whose
  // other mods draw their own territory on the map (1.9.3).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TurfOnMap")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TurfOnMap-Desc")
  @runtimeProperty("ModSettings.dependency", "turfWars")
  public let turfOnMap: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WarChest")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WarChest-Desc")
  @runtimeProperty("ModSettings.dependency", "turfWars")
  public let warChest: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-BackAGang")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-BackAGang-Desc")
  @runtimeProperty("ModSettings.dependency", "turfWars")
  public let backAGang: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CommonEnemy")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CommonEnemy-Desc")
  public let commonEnemy: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-OwnStreets")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-OwnStreets-Desc")
  @runtimeProperty("ModSettings.dependency", "turfWars")
  public let ownStreets: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetClashes")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetClashes-Desc")
  @runtimeProperty("ModSettings.dependency", "turfWars")
  public let streetClashes: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Turf")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TurfPatrols")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TurfPatrols-Desc")
  @runtimeProperty("ModSettings.dependency", "turfWars")
  public let turfPatrols: Bool = false;


  // ---- Crowds and morale -------------------------------------------------------------------------
  // bootstrapFromHistory was removed in 1.0 along with its settings entry. Nothing ever read
  // it, and the thing it promised - your existing Street Cred counting as reputation you had
  // already earned - is what the Street Cred floor setting above actually does.

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CivReactions")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CivReactions-Desc")
  public let civReactions: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CivIntensity")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CivIntensity-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.step", "0.05")
  @runtimeProperty("ModSettings.dependency", "civReactions")
  public let civIntensity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxReactingCiv")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxReactingCiv-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "civReactions")
  public let maxReactingCivilians: Int32 = 6;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PanicDriving")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PanicDriving-Desc")
  public let panicDriving: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetReadsMoment")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetReadsMoment-Desc")
  public let streetReadsMoment: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DistrictTempers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DistrictTempers-Desc")
  public let districtTempers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WitnessesCall")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WitnessesCall-Desc")
  public let witnessesCall: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Wannabes")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Wannabes-Desc")
  public let wannabes: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Morale")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Morale-Desc")
  public let morale: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MoraleIntensity")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MoraleIntensity-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.step", "0.05")
  @runtimeProperty("ModSettings.dependency", "morale")
  public let moraleIntensity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxBreakFraction")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxBreakFraction-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  // Renamed from maxBreakFraction so the lower default reaches everybody: Mod Settings keeps
  // values by field name, and the old one is stored as 0.6 on every install.
  @runtimeProperty("ModSettings.dependency", "morale")
  public let maxFleeFraction: Float = 0.35;

  // ---- Word on the street (2.3.1) -----------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Word")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Whispers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Whispers-Desc")
  public let whispers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Word")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WhisperCooldown")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WhisperCooldown-Desc")
  @runtimeProperty("ModSettings.min", "5")
  @runtimeProperty("ModSettings.max", "120")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "whispers")
  public let whisperCooldown: Int32 = 25;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Word")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RumorSpread")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RumorSpread-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let rumorSpreadMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Word")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PlacesRemember")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PlacesRemember-Desc")
  public let placesRemember: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Word")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-BraindanceGoesRound")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-BraindanceGoesRound-Desc")
  public let braindanceGoesRound: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Word")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WhileOut")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WhileOut-Desc")
  public let whileOut: Bool = true;


  // ---- Street talk -------------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetTalk")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetTalk-Desc")
  public let streetTalk: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkFirst")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkFirst-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkFirst: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkStopWalkers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkStopWalkers-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkStopWalkers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkShakedowns")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkShakedowns-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkShakedowns: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkLiars")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkLiars-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkLiars: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkHaggle")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkHaggle-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkHaggle: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PayTheStreet")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PayTheStreet-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let payTheStreet: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkIncite")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkIncite-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkIncite: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetIntel")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetIntel-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let streetIntel: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkBubbles")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkBubbles-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkBubbles: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkPhoneDeals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkPhoneDeals-Desc")
  public let talkPhoneDeals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Ransom")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Ransom-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let ransom: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Talk")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TalkLies")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TalkLies-Desc")
  @runtimeProperty("ModSettings.dependency", "streetTalk")
  public let talkLies: Bool = true;


  // ---- A living street ---------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Bagmen")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Bagmen-Desc")
  public let bagmen: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Favours")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Favours-Desc")
  public let favours: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SitDowns")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SitDowns-Desc")
  public let sitDowns: Bool = true;

  // How many of each gang turn up to a sit-down (Spawn/LivingStreet.reds, CBSitDownPerGang). Two
  // gangs, so the meeting is twice this: ten by default. Two each was the only size before this.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SitDownSize")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SitDownSize-Desc")
  @runtimeProperty("ModSettings.min", "1")
  @runtimeProperty("ModSettings.max", "8")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "sitDowns")
  public let sitDownSize: Int32 = 5;

  // How many of those are the gang's best, built like its apex squad (CBSitDownApexPerGang). The
  // rest are its rank and file.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SitDownApex")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SitDownApex-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "4")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "sitDowns")
  public let sitDownApex: Int32 = 2;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Gatherings")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Gatherings-Desc")
  public let gatherings: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DealsAndRackets")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DealsAndRackets-Desc")
  public let dealsAndRackets: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangFights")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangFights-Desc")
  public let gangFights: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PowerStruggles")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PowerStruggles-Desc")
  public let powerStruggles: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Street")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangLifeOften")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangLifeOften-Desc")
  @runtimeProperty("ModSettings.min", "0.25")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.25")
  public let gangLifeOften: Float = 1.0;

  // "Nobody kills you but me" moved to Rivals and you in 2.4.4 as nobodyButMe, on: a new field so the new default
  // reaches everybody (claimHelp was stored off on every install). claimHelp is no longer read.



  // ---- Reputation and money ----------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RenownGain")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RenownGain-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let renownGainMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DreadGain")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DreadGain-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let dreadGainMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-UnseenDread")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-UnseenDread-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let unseenDreadMult: Float = 0.5;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Decay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Decay-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let decayMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-BrutalConduct")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-BrutalConduct-Desc")
  public let brutalConduct: Bool = true;

  // Whether anything V wears is read at all (Signals/Concealment.reds, CBClothingCounts, 1.9.3).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ClothingCounts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ClothingCounts-Desc")
  public let clothingCounts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetCredFloor")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetCredFloor-Desc")
  public let streetCredFloor: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TitlePerks")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TitlePerks-Desc")
  public let titlePerks: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendorPricing")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendorPricing-Desc")
  public let vendorPricing: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxDiscount")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxDiscount-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "30")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.dependency", "vendorPricing")
  public let maxDiscount: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GigBonus")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GigBonus-Desc")
  public let gigBonus: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GigBonusMult")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GigBonusMult-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  @runtimeProperty("ModSettings.dependency", "gigBonus")
  public let gigBonusMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LifepathHeadStart")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-LifepathHeadStart-Desc")
  public let lifepathHeadStart: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetCredFollows")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetCredFollows-Desc")
  public let streetCredFollows: Bool = true;


  // ---- Messages and HUD --------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Toasts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Toasts-Desc")
  public let toasts: Bool = true;

  // How long word of what V did takes to reach V's phone, in in-game minutes (UI/PhoneMessages.reds,
  // CBPhone.Hearsay). Somebody passing on a body, a dead Rival, a payout or a crew changing hands
  // has to have heard about it first. 0 is the old behaviour: as it happens.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WordTravel")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WordTravel-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "240")
  @runtimeProperty("ModSettings.step", "5")
  public let wordTravelMinutes: Int32 = 30;

  // The least time between two pieces of word arriving, in real seconds.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-InboxGap")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-InboxGap-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "300")
  @runtimeProperty("ModSettings.step", "5")
  public let inboxGapSeconds: Int32 = 45;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MessageHold")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MessageHold-Desc")
  @runtimeProperty("ModSettings.min", "100")
  @runtimeProperty("ModSettings.max", "400")
  @runtimeProperty("ModSettings.step", "25")
  public let messageHold: Int32 = 175;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PhoneSound")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PhoneSound-Desc")
  public let phoneSound: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ShowCountdowns")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ShowCountdowns-Desc")
  public let showCountdowns: Bool = true;

  // The district line borrows the hunt line's widget (Spawn/Hunt.reds), so the setting above
  // still hides the whole line; this governs the district half of it. Briefly by default rather
  // than Always, because a line that never changes is one a player stops reading.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DistrictLine")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DistrictLine-Desc")
  public let districtLine: ECBDistrictLine = ECBDistrictLine.Briefly;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DistrictLineSeconds")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DistrictLineSeconds-Desc")
  @runtimeProperty("ModSettings.min", "3")
  @runtimeProperty("ModSettings.max", "60")
  @runtimeProperty("ModSettings.step", "1")
  public let districtLineSeconds: Int32 = 10;

  // The name-and-health bars at the top of the screen (UI/ThreatBar.reds). Kept beside the hunt
  // line because the two sit one above the other, and a player looking to clear the top of the
  // screen looked here for both and found only one. The field keeps its old name, because Mod
  // Settings stores values by class and field and a rename would reset everybody's choice; only
  // where it is listed and what it is called have changed.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexBossBar")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexBossBar-Desc")
  public let apexBossBar: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexArrivalSound")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexArrivalSound-Desc")
  public let apexArrivalSound: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HudScale")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HudScale-Desc")
  @runtimeProperty("ModSettings.min", "50")
  @runtimeProperty("ModSettings.max", "150")
  @runtimeProperty("ModSettings.step", "5")
  public let hudScale: Int32 = 100;

  // The Hub is a tab of the game's menu (UI/HubTab.reds) unless the player would rather have it in
  // the pause menu, where it lived until 1.7.3.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HubPauseMenu")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HubPauseMenu-Desc")

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Voices")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Voices-Desc")
  public let voices: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MorningBrief")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MorningBrief-Desc")
  public let morningBrief: Bool = true;

  public let hubInPauseMenu: Bool = false;


  // ---- Safe areas and jobs -----------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.category.order", "16")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-QuestAreas")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-QuestAreas-Desc")
  public let respectQuestAreas: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.category.order", "16")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-QuestAreaRadius")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-QuestAreaRadius-Desc")
  @runtimeProperty("ModSettings.min", "40")
  @runtimeProperty("ModSettings.max", "150")
  @runtimeProperty("ModSettings.step", "10")
  public let questAreaRadius: Int32 = 80;

  // Off by default, and they should stay that way for most players. A Rival arriving inside
  // an apartment is a fight you cannot have: the game forces your hands empty in there, so
  // you get attacked and cannot draw. These two exist for people who have decided they want
  // that fight anyway, and they are only sensible together.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.category.order", "16")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SafeZoneSpawns")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SafeZoneSpawns-Desc")
  public let allowSafeZoneSpawns: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.category.order", "16")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SafeZoneCombat")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SafeZoneCombat-Desc")
  public let allowSafeZoneCombat: Bool = false;


  // ---- Factions ----------------------------------------------------------------------------------
  // One switch per faction Cyberbane keeps a book on. Off and Cyberbane leaves that faction alone
  // entirely: its people never turn on V on sight because of Cyberbane, it sends nobody, makes no
  // Rivals, pays no tribute or bounties and never texts. What V does to them still counts towards
  // V's reputation, and their standing is still kept, so switching them back on picks up where it
  // was. Read through CBFactionOn (Data/Factions.reds).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-TygerClaws")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionTygerClaws: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Maelstrom")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionMaelstrom: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Valentinos")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionValentinos: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-SixthStreet")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionSixthStreet: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Animals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionAnimals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-VoodooBoys")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionVoodooBoys: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Scavengers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionScavengers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Mox")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionMox: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Wraiths")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionWraiths: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Aldecaldos")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionAldecaldos: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Barghest")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionBarghest: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Arasaka")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionArasaka: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Militech")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionMilitech: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-KangTao")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-Desc")
  public let factionKangTao: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Factions")
  @runtimeProperty("ModSettings.category.order", "17")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-NCPD")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionOn-NCPD-Desc")
  public let factionNCPD: Bool = true;


  // ---- How gangs see you (2.1.0) -----------------------------------------------------------------
  // Set by hand how the gangs treat V. The first one sets every gang; each gang below it can follow that
  // or say for itself. Read through CBGangView (Data/Factions.reds); acted on in one place,
  // CBActingStanding, so everything a gang does about V goes by it. The standing V earns in play keeps
  // counting underneath and is what comes back on Earned in play. Mod Settings keeps one set of values for
  // every save, like every other setting here.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangViewAll")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangViewAll-Desc")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let gangViewAll: ECBGangViewAll = ECBGangViewAll.Earned;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-TygerClaws")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewTygerClaws: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Maelstrom")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewMaelstrom: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Valentinos")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewValentinos: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-SixthStreet")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewSixthStreet: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Animals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewAnimals: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-VoodooBoys")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewVoodooBoys: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Scavengers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewScavengers: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Mox")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewMox: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Wraiths")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewWraiths: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Aldecaldos")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewAldecaldos: ECBGangView = ECBGangView.AllGangs;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-GangView")
  @runtimeProperty("ModSettings.category.order", "18")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionOn-Barghest")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangView-Desc")
  @runtimeProperty("ModSettings.displayValues.AllGangs", "Same as All gangs")
  @runtimeProperty("ModSettings.displayValues.Earned", "Earned in play")
  public let viewBarghest: ECBGangView = ECBGangView.AllGangs;


  // ---- Advanced ----------------------------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Advanced")
  @runtimeProperty("ModSettings.category.order", "19")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TwrCompat")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TwrCompat-Desc")
  public let twrCompat: ECBTwrCompat = ECBTwrCompat.Auto;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Advanced")
  @runtimeProperty("ModSettings.category.order", "19")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LogLevel")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-LogLevel-Desc")
  public let logLevel: ECBLogLevel = ECBLogLevel.Info;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Advanced")
  @runtimeProperty("ModSettings.category.order", "19")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FreezeReputation")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FreezeReputation-Desc")
  public let freezeReputation: Bool = false;

  // Start over. Turn it on, hit Apply, and everything Cyberbane has recorded on this save is
  // cleared.
  //
  // Mod Settings has no button control - the readme's options are bools, numbers, enums and
  // key bindings - so a switch is how an action is offered. The Apply step is the confirmation,
  // which is why this is not asked twice. It acts when it goes from off to on, never because it is
  // on (SwitchFlipped): Mod Settings keeps the value the player accepted, saves it, and hands it back
  // on every launch and with every later change to any setting, so this used to ask for a reset
  // again each time. It stays on in the menu once used; off and on again is another reset.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Advanced")
  @runtimeProperty("ModSettings.category.order", "19")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ResetAll")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ResetAll-Desc")
  public let resetAllData: Bool = false;

  // This save is another character (1.8.3). For two characters whose records ended up under one
  // playthrough id and could not be told apart when they loaded (same lifepath, both from before
  // 1.8.3). Gives the loaded save a playthrough of its own and keeps everything it earned. Acts on
  // the way from off to on, like the reset switch.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Advanced")
  @runtimeProperty("ModSettings.category.order", "19")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SeparateSave")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SeparateSave-Desc")
  public let separateThisSave: Bool = false;

  // Tracks the last preset we expanded, so picking a preset rewrites the intensity /
  // frequency sliders once, while later hand-tweaks to those sliders still stick.
  private let m_appliedPreset: ECBPreset = ECBPreset.Default;

  // ---- Registration & lifecycle ----------------------------------------
  public func Register() -> Void {
    ModSettings.RegisterListenerToClass(this);
    ModSettings.RegisterListenerToModifications(this);
    // What was just read back is the choice already made, along with whatever was tuned after it.
    // m_appliedPreset is not saved, so on every launch a saved Subtle or Dramatic looked newly
    // picked and wrote its numbers over the sliders the note above says are kept.
    this.m_appliedPreset = this.preset;
    this.Apply();
  }

  public func Unregister() -> Void {
    ModSettings.UnregisterListenerToClass(this);
    ModSettings.UnregisterListenerToModifications(this);
  }

  public cb func OnModSettingsChange() -> Void {
    this.Apply();
  }

  // Pushes the values that the low-level runtime needs into CyberbaneRuntime.
  // Feature modules read the rest of the fields directly off this instance.
  public func Apply() -> Void {
    // Expand a newly chosen preset into the individual sliders (spec §13 presets).
    if NotEquals(this.preset, this.m_appliedPreset) {
      this.ApplyPreset(this.preset);
      this.m_appliedPreset = this.preset;
    }
    let rt = CyberbaneRuntime.Get();
    // The action switches. Each hands its request to the runtime on the way from off to on, and the
    // tick does the work.
    let svc = CyberbaneService.Get();
    if this.SwitchFlipped(svc, this.resetAllData, true) && IsDefined(rt) {
      rt.RequestHardReset();
    }
    if this.SwitchFlipped(svc, this.separateThisSave, false) && IsDefined(rt) {
      rt.RequestSeparate();
    }
    if IsDefined(rt) {
      rt.SetEnabled(this.enabled);
      rt.SetLogLevel(this.GetLogLevelInt());
    }
  }

  // Did this switch just go from off to on (1.8.3)? What it was last seen doing is kept in the
  // service (CyberbaneService.m_resetSwitch), because the switch's own value comes back on every
  // launch. A switch found on with nothing on record was turned on before 1.8.3, when it was
  // already acted on: it is taken as done, never carried out blind. With no service to remember it
  // in, nothing happens: an action that wipes a save is never taken without knowing it is new.
  private func SwitchFlipped(svc: ref<CyberbaneService>, on: Bool, isReset: Bool) -> Bool {
    if !IsDefined(svc) {
      return false;
    }
    let last = isReset ? svc.GetResetSwitch() : svc.GetSeparateSwitch();
    let next = on ? CBSwitchActed() : CBSwitchOff();
    let act = on && last == CBSwitchOff();
    if on && last == CBSwitchUnseen() {
      CBLog.Info(n"Core", isReset
        ? "Reset all Cyberbane data was already on from an earlier session; turn it off and on again to use it."
        : "This save is another character was already on from an earlier session; turn it off and on again to use it.");
    }
    if isReset {
      svc.SetResetSwitch(next);
    } else {
      svc.SetSeparateSwitch(next);
    }
    return act;
  }

  // Subtle / Default / Dramatic scale how loud and how frequent reactions are.
  private func ApplyPreset(p: ECBPreset) -> Void {
    switch p {
      // Custom is the player's own numbers. Mod Settings lists every value of the enum, so it can be
      // picked, and it used to fall through to the default branch and write the Default preset over
      // exactly the sliders it is meant to keep.
      case ECBPreset.Custom:
        break;
      case ECBPreset.Subtle:
        this.civIntensity = 0.6;
        this.maxReactingCivilians = 3;
        this.moraleIntensity = 0.6;
        this.maxFleeFraction = 0.2;
        this.hostileOnSight = false;
        this.hitSquadFrequencyMult = 0.5;
        this.rivalFrequencyMult = 0.6;
        this.tributeMult = 0.75;
        break;
      case ECBPreset.Nemesis:
        this.civIntensity = 1.0;
        this.maxReactingCivilians = 6;
        this.moraleIntensity = 1.0;
        this.maxFleeFraction = 0.35;
        this.hostileOnSight = true;
        this.hitSquadFrequencyMult = 0.6;
        this.rivalFrequencyMult = 1.7;
        this.tributeMult = 1.0;
        break;
      case ECBPreset.TurfWar:
        this.civIntensity = 1.1;
        this.maxReactingCivilians = 6;
        this.moraleIntensity = 1.2;
        this.maxFleeFraction = 0.4;
        this.hostileOnSight = true;
        this.hitSquadFrequencyMult = 1.4;
        this.rivalFrequencyMult = 0.6;
        this.tributeMult = 1.25;
        this.gangLifeOften = 1.5;
        break;
      case ECBPreset.QuietLife:
        this.civIntensity = 1.0;
        this.maxReactingCivilians = 6;
        this.moraleIntensity = 0.8;
        this.maxFleeFraction = 0.35;
        this.hostileOnSight = false;
        this.hitSquadFrequencyMult = 0.25;
        this.rivalFrequencyMult = 0.3;
        this.tributeMult = 1.0;
        this.gangLifeOften = 1.0;
        break;
      case ECBPreset.Dramatic:
        this.civIntensity = 1.5;
        this.maxReactingCivilians = 10;
        this.moraleIntensity = 1.4;
        this.maxFleeFraction = 0.5;
        this.hostileOnSight = true;
        this.hitSquadFrequencyMult = 1.6;
        this.rivalFrequencyMult = 1.5;
        this.tributeMult = 1.25;
        break;
      default:
        this.civIntensity = 1.0;
        this.maxReactingCivilians = 6;
        this.moraleIntensity = 1.0;
        this.maxFleeFraction = 0.35;
        this.hostileOnSight = true;
        this.hitSquadFrequencyMult = 1.0;
        this.rivalFrequencyMult = 1.0;
        this.tributeMult = 1.0;
    }
  }

  public func GetLogLevelInt() -> Int32 {
    return EnumInt(this.logLevel);
  }

  // The Factions switches (1.9.1). MaxTac and anybody filed as Police go with the NCPD's. A faction
  // with no switch of its own is on.
  public func FactionOn(id: CName) -> Bool {
    if Equals(id, n"TygerClaws") { return this.factionTygerClaws; }
    if Equals(id, n"Maelstrom") { return this.factionMaelstrom; }
    if Equals(id, n"Valentinos") { return this.factionValentinos; }
    if Equals(id, n"SixthStreet") { return this.factionSixthStreet; }
    if Equals(id, n"Animals") { return this.factionAnimals; }
    if Equals(id, n"VoodooBoys") { return this.factionVoodooBoys; }
    if Equals(id, n"Scavengers") { return this.factionScavengers; }
    if Equals(id, n"Mox") { return this.factionMox; }
    if Equals(id, n"Wraiths") { return this.factionWraiths; }
    if Equals(id, n"Aldecaldos") { return this.factionAldecaldos; }
    if Equals(id, n"Barghest") { return this.factionBarghest; }
    if Equals(id, n"Arasaka") { return this.factionArasaka; }
    if Equals(id, n"Militech") { return this.factionMilitech; }
    if Equals(id, n"KangTao") { return this.factionKangTao; }
    if Equals(id, n"NCPD") || Equals(id, n"Police") || Equals(id, n"MaxTac") { return this.factionNCPD; }
    return true;
  }

  // How this gang treats V by hand (How gangs see you): 0 as earned, else 1 Allied, 2 Friendly, 3 Neutral,
  // 4 Hostile, 5 Vendetta, the order of ECBGangViewAll. Gangs only: anybody else is as earned.
  public func GangView(id: CName) -> Int32 {
    let own = ECBGangView.Earned;
    let gang = false;
    if Equals(id, n"TygerClaws") { own = this.viewTygerClaws; gang = true; }
    if Equals(id, n"Maelstrom") { own = this.viewMaelstrom; gang = true; }
    if Equals(id, n"Valentinos") { own = this.viewValentinos; gang = true; }
    if Equals(id, n"SixthStreet") { own = this.viewSixthStreet; gang = true; }
    if Equals(id, n"Animals") { own = this.viewAnimals; gang = true; }
    if Equals(id, n"VoodooBoys") { own = this.viewVoodooBoys; gang = true; }
    if Equals(id, n"Scavengers") { own = this.viewScavengers; gang = true; }
    if Equals(id, n"Mox") { own = this.viewMox; gang = true; }
    if Equals(id, n"Wraiths") { own = this.viewWraiths; gang = true; }
    if Equals(id, n"Aldecaldos") { own = this.viewAldecaldos; gang = true; }
    if Equals(id, n"Barghest") { own = this.viewBarghest; gang = true; }
    if !gang {
      return 0;
    }
    if Equals(own, ECBGangView.AllGangs) {
      return EnumInt(this.gangViewAll);
    }
    return EnumInt(own) - 1;
  }
}

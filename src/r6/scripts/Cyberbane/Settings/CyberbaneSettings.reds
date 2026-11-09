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

public class CyberbaneSettings {
  // ---- General ----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Enabled")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Enabled-Desc")
  public let enabled: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Preset")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Preset-Desc")
  public let preset: ECBPreset = ECBPreset.Default;



  // ---- Reputation -------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RenownGain")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RenownGain-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let renownGainMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DreadGain")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DreadGain-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let dreadGainMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-UnseenDread")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-UnseenDread-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let unseenDreadMult: Float = 0.5;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-BrutalConduct")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-BrutalConduct-Desc")
  public let brutalConduct: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Decay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Decay-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let decayMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RumorSpread")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RumorSpread-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let rumorSpreadMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetCredFloor")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-StreetCredFloor-Desc")
  public let streetCredFloor: Bool = true;

  // bootstrapFromHistory was removed in 1.0 along with its settings entry. Nothing ever read
  // it, and the thing it promised - your existing Street Cred counting as reputation you had
  // already earned - is what the Street Cred floor setting above actually does.

  // ---- Civilians --------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CivReactions")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CivReactions-Desc")
  public let civReactions: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CivIntensity")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CivIntensity-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let civIntensity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxReactingCiv")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxReactingCiv-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  @runtimeProperty("ModSettings.step", "1")
  public let maxReactingCivilians: Int32 = 6;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PanicDriving")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PanicDriving-Desc")
  public let panicDriving: Bool = true;

  // ---- Gangs ------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangReactions")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GangReactions-Desc")
  public let gangReactions: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HostileOnSight")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HostileOnSight-Desc")
  public let hostileOnSight: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Warnings")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Warnings-Desc")
  public let warnings: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionDisguises")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FactionDisguises-Desc")
  public let factionDisguises: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Tribute")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Tribute-Desc")
  public let tribute: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TributeMult")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TributeMult-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let tributeMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquads")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HitSquads-Desc")
  public let hitSquads: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
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
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CarsOnFoot")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CarsOnFoot-Desc")
  public let carsWhileOnFoot: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CarAmbushes")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CarAmbushes-Desc")
  public let carAmbushes: Bool = false;

  // How many cars one arrival can come in (Spawn/Arrival.reds, CBSendByCar). A crew too big for
  // one car comes in several, one after another; past this many, the rest walk in.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CarsPerArrival")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CarsPerArrival-Desc")
  @runtimeProperty("ModSettings.min", "1")
  @runtimeProperty("ModSettings.max", "5")
  @runtimeProperty("ModSettings.step", "1")
  public let carsPerArrival: Int32 = 4;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexStrength")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexStrength-Desc")
  @runtimeProperty("ModSettings.min", "20")
  @runtimeProperty("ModSettings.max", "100")
  @runtimeProperty("ModSettings.step", "5")
  public let apexStrength: Int32 = 55;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexTraits")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexTraits-Desc")
  public let apexTraits: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexArrivalSound")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexArrivalSound-Desc")
  public let apexArrivalSound: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendettaApexSquad")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendettaApexSquad-Desc")
  public let vendettaApexSquad: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TurfWars")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TurfWars-Desc")
  public let turfWars: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LootDrops")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-LootDrops-Desc")
  public let lootDrops: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Bounties")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Bounties-Desc")
  public let bounties: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Pacing")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Pacing-Desc")
  public let pacing: ECBPacing = ECBPacing.Timetable;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Scouts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Scouts-Desc")
  public let scouts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-EncounterGap")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-EncounterGap-Desc")
  @runtimeProperty("ModSettings.min", "2")
  @runtimeProperty("ModSettings.max", "30")
  @runtimeProperty("ModSettings.step", "1")
  public let encounterGapMinutes: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalsPerDay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalsPerDay-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20")
  @runtimeProperty("ModSettings.step", "1")
  public let rivalsPerDay: Int32 = 8;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquadsPerDay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HitSquadsPerDay-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20")
  @runtimeProperty("ModSettings.step", "1")
  public let hitSquadsPerDay: Int32 = 5;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexPerDay")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexPerDay-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "20")
  @runtimeProperty("ModSettings.step", "1")
  public let apexSquadsPerDay: Int32 = 4;

  // The Hub is a tab of the game's menu (UI/HubTab.reds) unless the player would rather have it in
  // the pause menu, where it lived until 1.7.3.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HubPauseMenu")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HubPauseMenu-Desc")
  public let hubInPauseMenu: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HudScale")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HudScale-Desc")
  @runtimeProperty("ModSettings.min", "50")
  @runtimeProperty("ModSettings.max", "150")
  @runtimeProperty("ModSettings.step", "5")
  public let hudScale: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MessageHold")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MessageHold-Desc")
  @runtimeProperty("ModSettings.min", "100")
  @runtimeProperty("ModSettings.max", "400")
  @runtimeProperty("ModSettings.step", "25")
  public let messageHold: Int32 = 175;

  // How long word of what V did takes to reach V's phone, in in-game minutes (UI/PhoneMessages.reds,
  // CBPhone.Hearsay). Somebody passing on a body, a dead Rival, a payout or a crew changing hands
  // has to have heard about it first. 0 is the old behaviour: as it happens.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WordTravel")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WordTravel-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "240")
  @runtimeProperty("ModSettings.step", "5")
  public let wordTravelMinutes: Int32 = 30;

  // The least time between two pieces of word arriving, in real seconds.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-InboxGap")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-InboxGap-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "300")
  @runtimeProperty("ModSettings.step", "5")
  public let inboxGapSeconds: Int32 = 45;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MessageDelivery")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MessageDelivery-Desc")
  public let messageDelivery: ECBMessageDelivery = ECBMessageDelivery.Phone;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ShowCountdowns")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ShowCountdowns-Desc")
  public let showCountdowns: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HudLine")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HudLine-Desc")
  public let hudLine: ECBHudLine = ECBHudLine.Everything;

  // The district line borrows the hunt line's widget (Spawn/Hunt.reds), so the setting above
  // still hides the whole line; this governs the district half of it. Briefly by default rather
  // than Always, because a line that never changes is one a player stops reading.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DistrictLine")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DistrictLine-Desc")
  public let districtLine: ECBDistrictLine = ECBDistrictLine.Briefly;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
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
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexBossBar")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexBossBar-Desc")
  public let apexBossBar: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PhoneSound")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-PhoneSound-Desc")
  public let phoneSound: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MapMarkers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MapMarkers-Desc")
  public let mapMarkers: ECBMarkerScope = ECBMarkerScope.Everyone;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CyberpsychoRivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-CyberpsychoRivals-Desc")
  public let cyberpsychoRivals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendettaSquads")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendettaSquads-Desc")
  public let vendettaSquads: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendettaSquadSize")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendettaSquadSize-Desc")
  @runtimeProperty("ModSettings.min", "6")
  @runtimeProperty("ModSettings.max", "24")
  @runtimeProperty("ModSettings.step", "1")
  public let vendettaSquadSize: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquadFreq")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HitSquadFreq-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let hitSquadFrequencyMult: Float = 1.0;

  // ---- Morale -----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Morale")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Morale")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Morale-Desc")
  public let morale: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Morale")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MoraleIntensity")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MoraleIntensity-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let moraleIntensity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Morale")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxBreakFraction")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxBreakFraction-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  // Renamed from maxBreakFraction so the lower default reaches everybody: Mod Settings keeps
  // values by field name, and the old one is stored as 0.6 on every install.
  public let maxFleeFraction: Float = 0.35;

  // ---- Economy ----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendorPricing")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-VendorPricing-Desc")
  public let vendorPricing: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxDiscount")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxDiscount-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "30")
  @runtimeProperty("ModSettings.step", "1")
  public let maxDiscount: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GigBonus")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GigBonus-Desc")
  public let gigBonus: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GigBonusMult")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-GigBonusMult-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let gigBonusMult: Float = 1.0;

  // ---- Rivals -----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Rivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Rivals-Desc")
  public let rivals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxRivals")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-MaxRivals-Desc")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  @runtimeProperty("ModSettings.step", "1")
  public let maxRivals: Int32 = 8;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DeathsRemembered")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-DeathsRemembered-Desc")
  public let deathsRemembered: Bool = true;

  // Tips on where a Rival was last seen, and the Rival waiting there (Rivals/Whereabouts.reds).
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalHideouts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalHideouts-Desc")
  public let rivalHideouts: Bool = true;

  // ---- Safe areas -------------------------------------------------------
  // Off by default, and they should stay that way for most players. A Rival arriving inside
  // an apartment is a fight you cannot have: the game forces your hands empty in there, so
  // you get attacked and cannot draw. These two exist for people who have decided they want
  // that fight anyway, and they are only sensible together.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SafeZoneSpawns")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SafeZoneSpawns-Desc")
  public let allowSafeZoneSpawns: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-QuestAreas")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-QuestAreas-Desc")
  public let respectQuestAreas: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-QuestAreaRadius")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-QuestAreaRadius-Desc")
  @runtimeProperty("ModSettings.min", "40")
  @runtimeProperty("ModSettings.max", "150")
  @runtimeProperty("ModSettings.step", "10")
  public let questAreaRadius: Int32 = 80;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-SafeAreas")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-SafeZoneCombat")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-SafeZoneCombat-Desc")
  public let allowSafeZoneCombat: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalFreq")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-RivalFreq-Desc")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let rivalFrequencyMult: Float = 1.0;

  // ---- UI ---------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Whispers")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Whispers-Desc")
  public let whispers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WhisperCooldown")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-WhisperCooldown-Desc")
  @runtimeProperty("ModSettings.min", "5")
  @runtimeProperty("ModSettings.max", "120")
  @runtimeProperty("ModSettings.step", "1")
  public let whisperCooldown: Int32 = 25;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Toasts")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-Toasts-Desc")
  public let toasts: Bool = true;

  // ---- Compatibility ----------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Compat")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TwrCompat")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-TwrCompat-Desc")
  public let twrCompat: ECBTwrCompat = ECBTwrCompat.Auto;

  // ---- Debug ------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Debug")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LogLevel")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-LogLevel-Desc")
  public let logLevel: ECBLogLevel = ECBLogLevel.Info;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Debug")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FreezeReputation")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-FreezeReputation-Desc")
  public let freezeReputation: Bool = false;

  // Start over. Turn it on, hit Apply, and everything Cyberbane has recorded on this save is
  // cleared; the switch turns itself back off once it is done.
  //
  // Mod Settings has no button control - the readme's options are bools, numbers, enums and
  // key bindings - so a switch that performs its action and resets itself is how an action is
  // offered. The Apply step is the confirmation, which is why this is not asked twice.
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Debug")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ResetAll")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ResetAll-Desc")
  public let resetAllData: Bool = false;

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
    // The reset switch. Hand the request to the runtime and turn the switch off again, so it
    // reads as the momentary action it is and cannot fire twice. The tick does the work.
    if this.resetAllData {
      this.resetAllData = false;
      let rrt = CyberbaneRuntime.Get();
      if IsDefined(rrt) {
        rrt.RequestHardReset();
      }
    }
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) {
      rt.SetEnabled(this.enabled);
      rt.SetLogLevel(this.GetLogLevelInt());
    }
  }

  // Subtle / Default / Dramatic scale how loud and how frequent reactions are.
  private func ApplyPreset(p: ECBPreset) -> Void {
    switch p {
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
}

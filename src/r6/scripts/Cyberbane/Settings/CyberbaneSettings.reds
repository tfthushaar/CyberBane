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

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HubKey")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-HubKey-Desc")
  public let hubKey: EInputKey = EInputKey.IK_F7;

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

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexStrength")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexStrength-Desc")
  @runtimeProperty("ModSettings.min", "20")
  @runtimeProperty("ModSettings.max", "100")
  @runtimeProperty("ModSettings.step", "5")
  public let apexStrength: Int32 = 70;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-ApexTraits")
  @runtimeProperty("ModSettings.description", "Cyberbane-Settings-ApexTraits-Desc")
  public let apexTraits: Bool = true;

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
  public let maxBreakFraction: Float = 0.6;

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

  // Tracks the last preset we expanded, so picking a preset rewrites the intensity /
  // frequency sliders once, while later hand-tweaks to those sliders still stick.
  private let m_appliedPreset: ECBPreset = ECBPreset.Default;

  // ---- Registration & lifecycle ----------------------------------------
  public func Register() -> Void {
    ModSettings.RegisterListenerToClass(this);
    ModSettings.RegisterListenerToModifications(this);
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
        this.maxBreakFraction = 0.4;
        this.hostileOnSight = false;
        this.hitSquadFrequencyMult = 0.5;
        this.rivalFrequencyMult = 0.6;
        this.tributeMult = 0.75;
        break;
      case ECBPreset.Dramatic:
        this.civIntensity = 1.5;
        this.maxReactingCivilians = 10;
        this.moraleIntensity = 1.4;
        this.maxBreakFraction = 0.75;
        this.hostileOnSight = true;
        this.hitSquadFrequencyMult = 1.6;
        this.rivalFrequencyMult = 1.5;
        this.tributeMult = 1.25;
        break;
      default:
        this.civIntensity = 1.0;
        this.maxReactingCivilians = 6;
        this.moraleIntensity = 1.0;
        this.maxBreakFraction = 0.6;
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

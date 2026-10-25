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
  public let preset: ECBPreset = ECBPreset.Default;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-General")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HubKey")
  public let hubKey: EInputKey = EInputKey.IK_F7;

  // ---- Reputation -------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RenownGain")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let renownGainMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DreadGain")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let dreadGainMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Decay")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let decayMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RumorSpread")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let rumorSpreadMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-StreetCredFloor")
  public let streetCredFloor: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Reputation")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Bootstrap")
  public let bootstrapFromHistory: Bool = true;

  // ---- Civilians --------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CivReactions")
  public let civReactions: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CivIntensity")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let civIntensity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxReactingCiv")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  @runtimeProperty("ModSettings.step", "1")
  public let maxReactingCivilians: Int32 = 6;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Civilians")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PanicDriving")
  public let panicDriving: Bool = true;

  // ---- Gangs ------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GangReactions")
  public let gangReactions: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HostileOnSight")
  public let hostileOnSight: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Warnings")
  public let warnings: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FactionDisguises")
  public let factionDisguises: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Tribute")
  public let tribute: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TributeMult")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let tributeMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquads")
  public let hitSquads: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Gangs")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-HitSquadFreq")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let hitSquadFrequencyMult: Float = 1.0;

  // ---- Morale -----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Morale")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Morale")
  public let morale: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Morale")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MoraleIntensity")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "2.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let moraleIntensity: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Morale")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxBreakFraction")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "1.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let maxBreakFraction: Float = 0.6;

  // ---- Police -----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Police")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-PoliceRecognition")
  public let policeRecognition: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Police")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-KnownOffender")
  public let knownOffender: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Police")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FriendOfForce")
  public let friendOfTheForce: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Police")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-CopMorale")
  public let copMorale: Bool = true;

  // ---- Economy ----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-VendorPricing")
  public let vendorPricing: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxDiscount")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "30")
  @runtimeProperty("ModSettings.step", "1")
  public let maxDiscount: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GigBonus")
  public let gigBonus: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Economy")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-GigBonusMult")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let gigBonusMult: Float = 1.0;

  // ---- Rivals -----------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Rivals")
  public let rivals: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-MaxRivals")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "15")
  @runtimeProperty("ModSettings.step", "1")
  public let maxRivals: Int32 = 8;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DeathsRemembered")
  public let deathsRemembered: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalFreq")
  @runtimeProperty("ModSettings.min", "0.0")
  @runtimeProperty("ModSettings.max", "3.0")
  @runtimeProperty("ModSettings.step", "0.05")
  public let rivalFrequencyMult: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Rivals")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalNameplates")
  public let rivalNameplates: Bool = true;

  // ---- UI ---------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Whispers")
  public let whispers: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-WhisperCooldown")
  @runtimeProperty("ModSettings.min", "5")
  @runtimeProperty("ModSettings.max", "120")
  @runtimeProperty("ModSettings.step", "1")
  public let whisperCooldown: Int32 = 25;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Pronouns")
  public let pronouns: ECBPronouns = ECBPronouns.Auto;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-Toasts")
  public let toasts: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-RivalCard")
  public let rivalCard: Bool = true;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-UI")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LowProfileIcon")
  public let lowProfileIcon: Bool = true;

  // ---- Compatibility ----------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Compat")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-TwrCompat")
  public let twrCompat: ECBTwrCompat = ECBTwrCompat.Auto;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Compat")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DogtownEnabled")
  public let dogtownEnabled: Bool = true;

  // ---- Debug ------------------------------------------------------------
  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Debug")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-LogLevel")
  public let logLevel: ECBLogLevel = ECBLogLevel.Info;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Debug")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-DebugOverlay")
  public let debugOverlay: Bool = false;

  @runtimeProperty("ModSettings.mod", "Cyberbane")
  @runtimeProperty("ModSettings.category", "Cyberbane-Settings-Category-Debug")
  @runtimeProperty("ModSettings.displayName", "Cyberbane-Settings-FreezeReputation")
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

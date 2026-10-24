// Cyberbane — Tunable constants (spec §8, Appendix A)
//
// Every gameplay-tuning number lives here so balance passes touch one file.
// Values that the player can scale (gain, decay, frequency, intensity) are
// multiplied by the matching Mod Settings value at the call site, not here.

public abstract class CBConfig {
  // ---- Time -------------------------------------------------------------
  // In-game time is stored as Float game-seconds (spec §6.1).
  public static func SecondsPerHour() -> Float = 3600.0
  public static func SecondsPerDay() -> Float = 86400.0

  // ---- Scheduling (spec §5.5) ------------------------------------------
  public static func FastTickSeconds() -> Float = 1.0          // real seconds
  public static func RumorSpreadHours() -> Float = 6.0         // in-game hours

  // ---- Reaction director (spec §9.1, §18) ------------------------------
  public static func NpcEvalRadius() -> Float = 30.0           // metres
  public static func NpcEvalPerTick() -> Int32 = 12
  public static func MaxSpawnedNpcs() -> Int32 = 8
  public static func PerNpcCooldownSeconds() -> Float = 30.0

  // ---- Encounter tracker (spec §7.1.3) ---------------------------------
  public static func EncounterEndTimeout() -> Float = 20.0     // real seconds
  public static func EncounterMaxRange() -> Float = 150.0      // metres
  public static func MassacreWindowKills() -> Int32 = 6
  public static func MassacreWindowSeconds() -> Float = 30.0
  public static func MassacreTotalKills() -> Int32 = 10
  public static func FlawlessMinKills() -> Int32 = 4
  public static func FlawlessHpFraction() -> Float = 0.05
  public static func WitnessCrowdRadius() -> Float = 25.0      // metres

  // ---- Renown (spec §8.1) ----------------------------------------------
  public static func RenownCurveScale() -> Float = 2500.0
  public static func RenownMax() -> Float = 1000.0
  public static func StreetCredFloorFactor() -> Float = 14.0
  public static func UnwitnessedRenownMult() -> Float = 0.25

  // Renown tier lower bounds.
  public static func TierLocalName() -> Float = 100.0
  public static func TierKnownMerc() -> Float = 250.0
  public static func TierNotorious() -> Float = 450.0
  public static func TierInfamous() -> Float = 650.0
  public static func TierLegend() -> Float = 850.0

  // ---- Dread (spec §8.2) -----------------------------------------------
  public static func DreadWeightK() -> Float = 0.35            // body count / brutality
  public static func DreadWeightC() -> Float = 0.20            // chrome
  public static func DreadWeightL() -> Float = 0.15            // look
  public static func DreadWeightX() -> Float = 0.20            // terrifying deeds
  public static func DreadWeightH() -> Float = 0.10            // police history
  public static func KillDreadCurveScale() -> Float = 600.0
  public static func DeedDreadCurveScale() -> Float = 400.0
  public static func HeatCurveScale() -> Float = 150.0
  public static func UnwitnessedDreadMult() -> Float = 0.5

  // ---- Archetypes (spec §8.3) ------------------------------------------
  public static func ArchetypeDecayPerDay() -> Float = 0.995
  public static func ArchetypeMinTotal() -> Float = 30.0
  public static func ArchetypeHysteresis() -> Float = 1.25

  // ---- Factions (spec §8.4) --------------------------------------------
  public static func PostureAllied() -> Float = 50.0
  public static func PostureFriendly() -> Float = 15.0
  public static func PostureHostile() -> Float = -30.0
  public static func PostureVendetta() -> Float = -70.0

  // ---- Districts & rumors (spec §8.5) ----------------------------------
  public static func RumorMaxHops() -> Int32 = 2
  public static func RumorLifetimeDays() -> Float = 3.0
  public static func RumorSpreadMagnitudeMult() -> Float = 0.5
  public static func RdDecayPerDay() -> Float = 1.0
  public static func RdFloorFraction() -> Float = 0.20
  public static func RfDecayPerDay() -> Float = 0.5
  public static func RfFloorFraction() -> Float = 0.10

  // ---- Aura (spec §8.6) ------------------------------------------------
  public static func AuraCap() -> Float = 40.0

  // ---- Recognition (spec §8.7) -----------------------------------------
  public static func RecognitionCap() -> Float = 0.95
  public static func RecognitionCacheSeconds() -> Float = 600.0   // 10 real minutes
  public static func RecognitionCacheMax() -> Int32 = 256

  // ---- Civilians (spec §9.2) -------------------------------------------
  public static func CivTierNotice() -> Float = 20.0
  public static func CivTierUneasy() -> Float = 40.0
  public static func CivTierAfraid() -> Float = 60.0
  public static func CivTierTerror() -> Float = 80.0

  // ---- Whispers (spec §9.10) -------------------------------------------
  public static func WhisperCooldownSeconds() -> Float = 25.0
  public static func WhisperRadius() -> Float = 10.0
  public static func WhisperChance() -> Float = 0.35
  public static func WhisperDurationSeconds() -> Float = 4.0

  // ---- Morale (spec §9.4) ----------------------------------------------
  public static func MoraleBreakThreshold() -> Float = 0.25
  public static func MoraleMaxBreakFraction() -> Float = 0.6

  // ---- Vendors (spec §9.6) ---------------------------------------------
  public static func VendorMaxDiscount() -> Float = 0.20
  public static func VendorMaxSurcharge() -> Float = 0.15

  // ---- Tribute (spec §9.8) ---------------------------------------------
  public static func TributeChance() -> Float = 0.25
  public static func TributeCooldownDays() -> Float = 7.0
  public static func TributeFearThreshold() -> Float = 75.0
  public static func TributeRenownThreshold() -> Float = 50.0

  // ---- Hit squads (spec §9.9) ------------------------------------------
  public static func HitSquadBaseChance() -> Float = 0.04
  public static func HitSquadFactionCooldownDays() -> Float = 2.0
  public static func HitSquadGlobalCooldownMinutes() -> Float = 45.0
  public static func HitSquadMinSpawnDistance() -> Float = 50.0
  public static func HitSquadDespawnMinutes() -> Float = 5.0
  public static func HitSquadDespawnDistance() -> Float = 300.0

  // ---- Rivals (spec §10.2, §10.7, Appendix A) --------------------------
  public static func RivalChanceSurvivor() -> Float = 0.15
  public static func RivalChanceSpared() -> Float = 0.20
  public static func RivalChanceAvenger() -> Float = 0.15
  public static func RivalChanceHunter() -> Float = 0.50
  public static func RivalEncounterBaseChance() -> Float = 0.10
  public static func RivalEncounterChancePerRank() -> Float = 0.05
  public static func RivalMaxActiveHardCap() -> Int32 = 15
  public static func RivalMaxPerFaction() -> Int32 = 3

  // ---- Collection caps (spec §6.5) -------------------------------------
  public static func CapRumors() -> Int32 = 64
  public static func CapLog() -> Int32 = 200
  public static func CapArchivedRivals() -> Int32 = 32
  public static func CapRivalHistory() -> Int32 = 10
  public static func CapAppliedLedgerIds() -> Int32 = 100
  public static func CapLedgerTotal() -> Int32 = 100
  public static func CapLedgerPerPlaythrough() -> Int32 = 30
  public static func CapPeaceDeals() -> Int32 = 16

  // ---- Fault isolation (spec §16.5) ------------------------------------
  public static func ModuleErrorLimit() -> Int32 = 5
}

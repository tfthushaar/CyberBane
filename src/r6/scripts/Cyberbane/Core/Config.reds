// Cyberbane - Tunable constants (spec §8, Appendix A)
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

  // ---- Runtime safety gate (crash fix, spec §16) -----------------------
  // After a plain menu / scene (no world streaming), sit out this many fast ticks before the
  // runtime touches the world again.
  public static func StreamSettleTicks() -> Int32 = 5
  // After a flood-causing transition (fast travel, time skip, ripperdoc install, load), sit
  // out this many fast ticks (~seconds at FastTickSeconds) so the resource-streaming flood has
  // fully drained before we query NPCs / entities - the flood runs on well after the UI clears.
  public static func FloodSettleTicks() -> Int32 = 30
  // A jump larger than this many in-game seconds between ticks means a time skip happened
  // (Skip Time, fast travel, a ripperdoc install), not normal play.
  public static func TimeJumpSettleSeconds() -> Float = 600.0
  // Leave a freshly-streamed-in NPC alone for this many ticks after it attaches, so its native
  // components are ready before we read its position / attitude (avoids access violations during
  // ambient streaming in dense districts and scenes).
  public static func NpcReadyTicks() -> Int32 = 3
  // How long after a spawn to wait before giving it its orders, and how many attempts. A
  // freshly attached puppet has no attitude agent and no AI controller for the first few
  // frames, and orders issued then are silently discarded.
  public static func SpawnSetupRetrySeconds() -> Float = 0.4
  public static func SpawnSetupMaxTries() -> Int32 = 12
  // If at least this many entities attached in a single tick interval, the world is streaming heavily (a flood) even
  // without a transition - stand down until it settles.
  public static func FloodAttachThreshold() -> Int32 = 60

  // ---- Reaction director (spec §9.1, §18) ------------------------------
  // Wide enough to contain the chrome-widened flee range below, and enough NPCs per tick that
  // a busy street actually reacts instead of one or two people noticing you.
  public static func NpcEvalRadius() -> Float = 35.0           // metres
  public static func NpcEvalPerTick() -> Int32 = 16
  // The most NPCs whose position the Director reads in one tick, carrying on round the registry from where the last
  // tick stopped; and how many ticks somebody who failed its checks (sitting, selling, at a job, one of ours) is passed
  // over before being asked again.
  public static func NpcLookPerTick() -> Int32 = 48
  public static func NpcGateRetryTicks() -> Int32 = 5
  // How often the Director hands back anybody it turned on V whose faction has since been switched off in Mod Settings
  // (Reactions/Director.reds, RevertNotFielding), in settled ticks.
  public static func SwitchedOffRevertTicks() -> Int32 = 5
  // How long somebody Cyberbane turned on V stays turned, out of a fight, once their gang has no vendetta left against
  // V (RevertNotFielding): a pay-off, a cooled grudge, a street fight V picked.
  public static func HostileCoolTicks() -> Int32 = 30
  // How long after being set up one of ours is watched for having slipped to neutral (Spawn/Spawner.reds, CBRearmTick),
  // in settled ticks.
  public static func RearmWatchTicks() -> Int32 = 30
  // How long a gang's warning stands before they draw (Reactions/Director.reds): long enough to walk away, or to walk
  // up and talk them down.
  public static func GangWarnGraceTicks() -> Int32 = 10
  // Upper bound on the attitude-revert list (NPCs Cyberbane turned hostile). Only live
  // NPCs ever need reverting, so this just keeps the list from growing all session.
  public static func MaxTrackedHostiles() -> Int32 = 64

  // ---- Encounter tracker (spec §7.1.3) ---------------------------------
  public static func EncounterEndTimeout() -> Float = 20.0     // real seconds
  public static func MassacreWindowKills() -> Int32 = 6
  public static func MassacreWindowSeconds() -> Float = 30.0
  public static func MassacreTotalKills() -> Int32 = 10

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
  // How fast the body count and the jobs fade while V lies low, in points of their 0..100 value
  // per in-game day, before the Decay rate setting (Model/Decay.reds).
  public static func KillDreadFadePerDay() -> Float = 6.0
  public static func DeedDreadFadePerDay() -> Float = 4.0
  // What a whole record still earns: the body count never fades below KillDreadFloorMax of its
  // value at a lifetime of kills, approached over about KillDreadFloorKills of them, and the jobs
  // never below DeedDreadFloorShare of what they and the unseen killing were worth.
  public static func KillDreadFloorMax() -> Float = 40.0
  public static func KillDreadFloorKills() -> Float = 300.0
  public static func DeedDreadFloorShare() -> Float = 0.5
  // Laying Low (spec 11.5): nobody put down, lethally or otherwise, for this many in-game days
  // and the city forgets this much faster, until the next one (Model/Decay.reds).
  public static func LayingLowDays() -> Float = 3.0
  public static func LayingLowMult() -> Float = 2.0
  public static func HeatCurveScale() -> Float = 150.0
  public static func UnwitnessedDreadMult() -> Float = 0.5
  // What the frightening things V does add to the "terrifying deeds" part of Dread, in the same points a deed's own
  // dread is counted in (Model/Encounter.reds, CBTerrorDeed).
  public static func TerrorMassacre() -> Float = 30.0
  public static func TerrorBoss() -> Float = 20.0
  public static func TerrorMaxTac() -> Float = 12.0
  public static func TerrorApexSquad() -> Float = 25.0
  public static func TerrorRival() -> Float = 10.0
  // Keeping the peace (Model/GangRivalries.reds): standing a gang gives V for each in-game hour spent on its streets
  // with no trouble between them for this long.
  public static func PeaceKeptPerHour() -> Float = 0.3
  public static func PeaceKeptQuietHours() -> Float = 24.0

  // ---- Archetypes (spec §8.3) ------------------------------------------
  public static func ArchetypeMinTotal() -> Float = 30.0
  public static func ArchetypeHysteresis() -> Float = 1.25

  // ---- Factions (spec §8.4) --------------------------------------------
  public static func PostureAllied() -> Float = 50.0
  public static func PostureFriendly() -> Float = 15.0
  public static func PostureHostile() -> Float = -30.0
  public static func PostureVendetta() -> Float = -70.0

  // ---- Districts & rumors (spec §8.5) ----------------------------------
  public static func RumorMaxHops() -> Int32 = 2
  // How often an ordinary witnessed kill becomes a story, and how loudly each kind travels.
  // Deliberately well under 1: every kill making the rounds would fill the board with noise
  // and make the whole mechanic meaningless.
  public static func RumorChanceOrdinary() -> Float = 0.15
  public static func RumorMagnitudeOrdinary() -> Float = 3.0
  public static func RumorMagnitudeNotable() -> Float = 8.0
  public static func RumorMagnitudeCivilian() -> Float = 6.0
  // Unseen kills needed, as a Ghost, for the Konpeki Ghost title.
  public static func KonpekiUnattributed() -> Int32 = 25
  // How many titles still to earn the Hub's Titles screen lists beside the earned ones.
  public static func StoryCompanionRadius() -> Float = 40.0
  // The pass that looks for a story companion walks the whole registry; once every this many settled ticks is enough.
  public static func StoryCompanionScanTicks() -> Int32 = 3
  // Settled fast ticks (about seconds) a story restriction has to hold before anybody is called
  // back. The game puts some of the same restrictions on V for a moment in ordinary play.
  public static func StoryRestrictionSettleTicks() -> Int32 = 3
  // Width of the threat bar across the top of the screen.
  // Narrower than it was, because there is a stack of these now rather than one.
  public static func ThreatBarWidth() -> Float = 520.0
  // An apex squad of four plus the Rival lane's encounter is the most that can be on you at once, since the three lanes
  // can overlap but never double up on their own kind.
  public static func ThreatBarRows() -> Int32 = 7
  public static func ThreatBarRowStride() -> Float = 34.0
  public static func ThreatBarTopMargin() -> Float = 80.0
  public static func RumorLifetimeDays() -> Float = 3.0
  public static func RumorSpreadMagnitudeMult() -> Float = 0.5
  public static func RdDecayPerDay() -> Float = 1.0
  public static func RdFloorFraction() -> Float = 0.20
  public static func RfDecayPerDay() -> Float = 0.5
  public static func RfFloorFraction() -> Float = 0.10

  // ---- Aura (spec §8.6) ------------------------------------------------
  public static func AuraCap() -> Float = 40.0
  // Ticks (about a second each) a kill still counts as fresh for Aura.
  public static func AuraKillWindowTicks() -> Int32 = 60
  // Visible chrome at which V reads as carrying something obvious, for the Aura weapon term.
  public static func AuraObviousChrome() -> Float = 45.0

  // ---- Recognition (spec §8.7) -----------------------------------------
  public static func RecognitionCap() -> Float = 0.95

  // ---- Civilians (spec §9.2) ------------------------------------------- Reaction tiers. These sat at 60/80, which a
  // mid-game V almost never reached, so the city stayed silent and the mod read as "not working".
  public static func CivTierNotice() -> Float = 18.0
  public static func CivTierUneasy() -> Float = 32.0
  public static func CivTierAfraid() -> Float = 42.0
  public static func CivTierTerror() -> Float = 68.0
  // What a passer-by does, by how frightening V reads to them. Separate from the tiers above, which also price vendors
  // and name V's standing on the Hub.
  public static func CivFearGlance() -> Float = 12.0
  public static func CivFearStartle() -> Float = 30.0
  public static func CivFearCower() -> Float = 75.0
  public static func CivFearRun() -> Float = 120.0
  public static func CivGlanceRadius() -> Float = 12.0
  public static func CivStartleRadius() -> Float = 7.0
  public static func CivCowerRadius() -> Float = 3.5
  public static func CivFleeRadius() -> Float = 6.0
  // How much V's build (level, street cred, skills) adds to how intimidating they look.
  public static func MenaceFearWeight() -> Float = 0.6
  // Ticks (about a second each) before the same civilian can be frightened again. Long enough
  // that one person does not flinch continuously, short enough that walking back down a street
  // still gets a reaction.
  public static func CivReactionCooldownTicks() -> Int32 = 45
  // How much further obvious chrome gets noticed. At full visible chrome both reaction ranges widen by this fraction,
  // so blades-for-arms reads from across the street.
  public static func FearStimRadius() -> Float = 10.0
  // How far panic driving's gunshot carries when the district has not given V a gunshot range yet: the game's gunshot
  // stimulus radius (stimpresets.tweak, GunshotStimuli).
  public static func PanicStimRadius() -> Float = 30.0
  // How far somebody running from V startles the people next to them.
  public static func FearSpreadRadius() -> Float = 6.0
  // What an apex squad landing on you does to everyone watching. The game uses 100 m for a
  // MaxTac AV coming down, and an apex squad is meant to read the same way.
  public static func ApexTerrorRadius() -> Float = 100.0
  // What a mask is worth as a disguise on its own, and how much a disguise damps what the
  // street reads off you.
  public static func MaskDisguise() -> Float = 0.60
  public static func DisguiseDreadDamp() -> Float = 0.50
  // How much of V's face They Will Remember must count hidden for Cyberbane to treat it as a mask. A full-face helmet
  // or a mask reads 80-95% there; a cap or sunglasses well under half.
  public static func TwrMaskedFace() -> Float = 0.75
  // How long after a meeting's people are placed its two sides go on being set to keep the peace while the last of them
  // come into the world (Spawn/StreetEvents.reds, CBCalmSides).
  public static func EventCalmTicks() -> Int32 = 12
  public static func ChromeNoticeRangeBonus() -> Float = 0.5

  // ---- Whispers (spec §9.10) -------------------------------------------
  // Overheard lines are the clearest sign the city has an opinion of you, so they come a little
  // more often and from a little further out.
  public static func WhisperRadius() -> Float = 13.0
  public static func WhisperChance() -> Float = 0.45
  // How often a plain whisper gives way to one about a story that has actually reached this district.
  public static func WhisperRumorChance() -> Float = 0.6
  // The line library (Narrative/Lines.reds): how many lines the street remembers saying, and what a line heard among
  // them is still worth in a weighted pick.
  public static func LineMemory() -> Int32 = 40
  public static func LineHeardWeight() -> Float = 0.15
  // The moment (Model/Moment.reds). A face is that much harder to place at night (the lanes' night, NightStartHour) and
  // in rain: recognition, the reach of a witness, and in rain a hunter's sight.
  public static func NightSight() -> Float = 0.8
  public static func HeavyRainSight() -> Float = 0.8
  public static func LightRainSight() -> Float = 0.92
  public static func WoundedHealthPercent() -> Float = 40.0
  public static func FreshFightSeconds() -> Float = 600.0
  public static func FreshFightCrowdMult() -> Float = 1.2
  public static func WoundedCrowdMult() -> Float = 1.1
  // A ganger who sees V bleeding is that much less afraid of V (CBHoldBackOdds).
  public static func WoundedEmbolden() -> Float = 0.1
  // Places that remember (Model/StreetBook.reds): up to twelve, one per corner (a deed within 30 m of a remembered one
  // replaces it).
  public static func PlaceCap() -> Int32 = 12
  public static func PlaceMergeDistance() -> Float = 30.0
  public static func PlaceReach() -> Float = 40.0
  public static func PlaceFear() -> Float = 0.1
  public static func PlaceAvoidReach() -> Float = 60.0
  public static func PlaceAvoidHours() -> Float = 12.0
  // Known by car and gun: four of each kept; a car is known after six witnessed fights in it or by it (within
  // 25 m), a gun after fifteen witnessed kills with it; forgotten after five in-game days without one.
  public static func KnownCap() -> Int32 = 4
  public static func CarKnownAfter() -> Int32 = 6
  public static func GunKnownAfter() -> Int32 = 15
  public static func KnownForDays() -> Float = 5.0
  public static func CarByReach() -> Float = 25.0
  // One sighting of the car per fight: kills within ten game minutes (a real minute and a quarter) are one fight.
  public static func CarNoteGapSeconds() -> Float = 600.0
  // Bosses see through disguises ([78]): an officer or elite within 15 m for 30 game seconds (about four real
  // seconds) of V masked or in their colours places V anyway.
  public static func EnforcerLookRange() -> Float = 15.0
  public static func EnforcerLookSeconds() -> Float = 30.0
  // Witnesses who tell the gang (Reactions/Witnesses.reds): three in four go, times the district's temper, and take
  // twelve seconds to get there.
  public static func WitnessTellChance() -> Float = 0.75
  public static func WitnessTellTicks() -> Int32 = 12
  public static func HushBasePrice() -> Float = 150.0
  public static func HushPerRenown() -> Float = 0.4
  public static func HushLeanBonus() -> Float = 0.15
  // Keeping watch (Reactions/StreetPay.reds): 250eb for six in-game hours in one district, and twenty more
  // seconds of warning on anybody coming.
  public static func WatchPrice() -> Int32 = 250
  public static func WatchHours() -> Float = 6.0
  public static func WatchExtraTicks() -> Int32 = 20
  // The braindance goes round (Model/RumorEngine.reds): a witnessed story of magnitude 8 or more (a massacre, a boss)
  // has an even chance of being recorded and reaching every district at once.
  public static func BraindanceMinMagnitude() -> Float = 8.0
  public static func BraindanceChance() -> Float = 0.5
  // Gang codes (Data/GangCodes.reds): what every other gang gives for a Scavenger down, what a guarding gang takes for
  // one of its district's people, the base of the extra grudge for shooting somebody with their hands up, and how much
  // chrome Maelstrom can tell is under clothes.
  public static func ScavengerFavour() -> Float = 0.5
  public static func GuardCivilianLoss() -> Float = 4.0
  public static func SurrenderShotStanding() -> Float = 5.0
  public static func ChromeUnderClothes() -> Float = 50.0
  // Surrender, let go (Spawn/LivingStreet.reds): standing with their gang (as a mercy, times its code) and Code.
  public static func SurrenderLetGoStanding() -> Float = 2.0
  public static func SurrenderLetGoCode() -> Float = 0.5
  // Each gang's voice (Narrative/GangVoice.reds): how often a street warning is in their own words.
  public static func GangVoiceShare() -> Float = 0.7
  // Gangs adapt (Model/Ledger.reds): a way of fighting dominates at ten weight (a body is 1, somebody left breathing
  // 0.6) and over 55% of it; the ledger keeps 80% a day.
  public static func AdaptMinWeight() -> Float = 10.0
  public static func AdaptShare() -> Float = 0.55
  public static func AdaptLiveWeight() -> Float = 0.6
  public static func AdaptDailyKeep() -> Float = 0.8
  public static func AdaptArmour() -> Float = 0.2
  public static func AdaptHealth() -> Float = 0.15
  public static func AdaptIce() -> Float = 3.0
  public static func AdaptSense() -> Float = 1.25
  // The fight read into a build ([U3]): a bled gang's people up to 12% weaker, and the terms together kept within
  // 15% weaker and 40% tougher. A crew member's build never goes past 40% health or 30% armour.
  public static func BuildStrengthWeight() -> Float = 0.12
  public static func BuildReadFloor() -> Float = 0.15
  public static func BuildReadCeiling() -> Float = 0.4
  public static func CrewBuildHealthCeiling() -> Float = 0.4
  public static func CrewBuildArmourCeiling() -> Float = 0.3
  // An apex squad's netrunner spots V from twice as far as the rest, and locates V for the squad ([U4]).
  public static func ApexNetrunnerReach() -> Float = 2.0
  // An apex squad searching as one: the spot the first of them chose holds for 20 seconds, and the rest search
  // within 6 m of it.
  public static func ApexSearchShareTicks() -> Int32 = 20
  public static func ApexSearchSpread() -> Float = 6.0
  // Gang life (Spawn/StreetEvents.reds). The sit-down keeps its own clock (MeetGapTicks, MeetChance).
  public static func EventGapTicks() -> Int32 = 1500
  public static func EventChance() -> Float = 0.7
  public static func EventLeadMinHours() -> Float = 0.5
  public static func EventLeadMaxHours() -> Float = 1.5
  public static func EventWindowSeconds() -> Float = 5400.0
  public static func FuneralAfterHours() -> Float = 8.0
  public static func CelebrationAfterHours() -> Float = 4.0
  public static func EventOwedDays() -> Float = 1.0
  // What crashing one is worth and costs, and what a missed one gives the gang.
  public static func EventRenown() -> Float = 15.0
  public static func FuneralCrashStanding() -> Float = 12.0
  public static func FuneralCrashCode() -> Float = 3.0
  public static func RacketTakeBase() -> Int32 = 350
  public static func InitiationStopCode() -> Float = 1.0
  public static func RecruitBolster() -> Float = 8.0
  public static func CelebrationBolster() -> Float = 5.0
  public static func EventBolster() -> Float = 3.0
  public static func RespectsStanding() -> Float = 6.0
  public static func RespectsCode() -> Float = 1.0
  // The fights between gangs (Spawn/StreetEvents.reds): in the draw half the time; an execution happens 25 seconds
  // after its people are in place; the hunted runs 30 m past V and is clear at 120 m from the start; a front line won
  // is 6 strength to the winner and 6 off the loser; saving a prisoner or the hunted is 6 standing with their gang and
  // 1 of Code.
  public static func GangFightShare() -> Float = 0.5
  public static func ExecutionDelayTicks() -> Int32 = 25
  public static func FugitiveRunPast() -> Float = 30.0
  public static func FugitiveEscapeDistance() -> Float = 120.0
  public static func FrontLineGain() -> Float = 6.0
  public static func FrontLineLoss() -> Float = 6.0
  // A front line squares up this many ticks before it starts, time to pick a side; V's side winning pays this and warms
  // that gang this much, and costs V this much with the other.
  public static func FrontLineStandoffTicks() -> Int32 = 40
  public static func FrontLineSidePay() -> Int32 = 1500
  public static func FrontLineSideWarmth() -> Float = 10.0
  public static func FrontLineSideCost() -> Float = 8.0
  public static func SavedStanding() -> Float = 6.0
  public static func SavedCode() -> Float = 1.0
  // Power struggles: two in-game days to back one; the one V backs is 15 standing with the gang; putting both down
  // takes it back and 12 strength off the gang.
  public static func StruggleDays() -> Float = 2.0
  public static func StruggleBackStanding() -> Float = 15.0
  public static func StruggleBothLoss() -> Float = 12.0
  // The war chest and manpower (Economy/War.reds). A gang starts with 6000eb (up to 20000), earns 300 a day plus 400
  // for each district it holds; a crew member costs it 150 and an apex squad 1500.
  public static func WarChestStart() -> Float = 6000.0
  public static func WarChestMax() -> Float = 20000.0
  public static func WarIncomeBase() -> Float = 300.0
  public static func WarIncomePerDistrict() -> Float = 400.0
  public static func WarCrewCost() -> Float = 150.0
  public static func WarApexCost() -> Float = 1500.0
  public static func WarChestBroke() -> Float = 1000.0
  public static func WarChestFlush() -> Float = 12000.0
  public static func WarBrokeCrew() -> Float = 0.6
  public static func WarFlushCrew() -> Float = 1.1
  public static func BagmanChestShare() -> Float = 2.0
  public static func WarDealValue() -> Float = 2000.0
  public static func WarMenPerDay() -> Float = 20.0
  public static func WarMenPerKill() -> Float = 1.0
  public static func WarMenMassacre() -> Float = 30.0
  public static func WarMenFloor() -> Float = 10.0
  // Backing a gang: 300eb a week for each district it holds; its enemies think 5 less of V.
  public static func BackedCutPerDistrict() -> Int32 = 300
  public static func BackedEnemyStanding() -> Float = 5.0
  // The lie: an even chance, Cool helps; believed, both lose 2 strength and a street fight between them is next.
  public static func InciteBase() -> Float = 0.5
  public static func InciteLoss() -> Float = 2.0
  // A common enemy: at Infamous, between two gangs at war that both fear V at 60 or more and are at odds with V,
  // a 15% chance a day of a day's truce; two of the other gang come with each crew.
  public static func TruceChancePerDay() -> Float = 0.15
  public static func TruceDays() -> Float = 1.0
  public static func TruceFear() -> Float = 60.0
  public static func TruceJoin() -> Int32 = 2
  // V's own streets: at Legend, district renown 75 and every gang there broken; 1000eb a week each.
  public static func OwnStreetsRenown() -> Float = 75.0
  public static func OwnStreetsToll() -> Int32 = 1000
  // Peace by text: haggled down a quarter at 35% plus fear/200; a favour has two days.
  public static func PeaceHaggleBase() -> Float = 0.35
  public static func PeaceHaggleCut() -> Float = 0.25
  public static func FavourDays() -> Float = 2.0
  // The Claws' protection: after ten game minutes of Westbrook in a week (8 game seconds a tick), 400eb plus 0.3 per
  // point of renown, two days to pay; paid, 3 standing; unpaid, 8 off and a crew.
  public static func ProtectionSeenSeconds() -> Float = 600.0
  public static func ProtectionSeenPerTick() -> Float = 8.0
  public static func ProtectionBase() -> Float = 400.0
  public static func ProtectionPerRenown() -> Float = 0.3
  public static func ProtectionDays() -> Float = 2.0
  public static func ProtectionPaidStanding() -> Float = 3.0
  public static func ProtectionUnpaidStanding() -> Float = 8.0
  // A turf patrol that walks its beat without trouble adds 2 to its gang's strength.
  public static func PatrolGrip() -> Float = 2.0
  // Being hunted (Spawn/Hunted.reds). A hunter handed V aims at 40% for 2.5 seconds. A gang is "still hot" for 2 game
  // hours after its last incident and "cooling off" until 12.
  public static func FairVolleyAim() -> Float = 0.4
  public static func FairVolleySeconds() -> Float = 2.5
  public static func HeatHotHours() -> Float = 2.0
  public static func HeatCoolHours() -> Float = 12.0
  public static func TrailLookChange() -> Float = 8.0
  public static func TrailUnseenTicks() -> Int32 = 10
  public static func TrailColdChance() -> Float = 0.35
  // Slipping the countdown (Spawn/Slip.reds): the chance they lose V before setting off, with two changes and with
  // three or more; and how much less sharp they are when they come in looking in the wrong place.
  public static func SlipLoseTwo() -> Float = 0.55
  public static func SlipLoseMore() -> Float = 0.85
  public static func SlipSenseMult() -> Float = 0.7
  // Home ground (Spawn/HomeGround.reds): how far round an apartment, flat on the map, counts as its building; how close
  // a bed must be to a home already known to be the same one; how many homes are kept.
  public static func HomeRadius() -> Float = 110.0
  public static func HomeMergeDistance() -> Float = 60.0
  public static func HomeMax() -> Int32 = 8
  // A home's door, the crew's post (2.7.9): learned where V stands on the navmesh once V has walked this far from the
  // spot V stepped out of the flat, so never inside the lift V came down in; looked for this many ticks.
  public static func HomeDoorStepOut() -> Float = 4.0
  public static func HomeDoorWatchTicks() -> Int32 = 45
  public static func HauntShare() -> Float = 0.34
  public static func HauntMinSeconds() -> Float = 7200.0
  public static func HauntSecondsPerSample() -> Float = 80.0
  public static func HauntDailyKeep() -> Float = 0.85
  public static func HauntTipMult() -> Float = 0.6
  public static func KnownSense() -> Float = 1.15
  public static func NetrunnerScoutReach() -> Float = 1.6
  public static func ScoutBribeBase() -> Float = 300.0
  public static func ScoutBribePerRenown() -> Float = 0.3
  public static func LookoutMinDistance() -> Float = 15.0
  public static func LookoutMaxDistance() -> Float = 45.0
  // The hunt grows (Spawn/HuntGrows.reds). A tracker lasts 12 game hours, or 60 real seconds somewhere safe; a tracked
  // gang's hunt starts from a tip 15% as far off.
  public static func TrackedHours() -> Float = 12.0
  public static func TrackedClearTicks() -> Int32 = 60
  public static func TrackedTipMult() -> Float = 0.15
  // A quarter of days for a gang at the top of its anger with 40 of its own dead (a tenth was about once in thirty
  // hours of play).
  public static func OpenSeasonChancePerDay() -> Float = 0.25
  public static func OpenSeasonKills() -> Int32 = 40
  public static func OpenSeasonCrewTicks() -> Int32 = 450
  public static func OpenSeasonPriceMult() -> Float = 2.5
  public static func OpenSeasonFear() -> Float = 40.0
  public static func OpenSeasonRenown() -> Float = 60.0
  public static func WraithRoadMult() -> Float = 2.5
  public static func HauntWaitMult() -> Float = 1.5
  public static func RoadChance() -> Float = 0.4
  public static func RoadMinDistance() -> Float = 300.0
  public static func RoadOffset() -> Float = 20.0
  public static func RoadMaxCrew() -> Int32 = 6
  public static func AmbushWaitSeconds() -> Float = 5400.0
  public static func AssassinChance() -> Float = 0.35
  // A price on V's head (Spawn/Bounty.reds).
  public static func BountyChancePerDay() -> Float = 0.4   // a gang posting a price, a day (from 0.3)
  public static func BountyGangKills() -> Int32 = 15
  public static func BountyMinChest() -> Float = 3000.0
  public static func BountyChestShare() -> Float = 0.4
  public static func BountyGangMin() -> Int32 = 5000
  public static func BountyGangMax() -> Int32 = 40000
  public static func BountyRivalRank() -> Int32 = 3
  public static func BountyRivalMeetings() -> Int32 = 3
  public static func BountyRivalPostPerRank() -> Int32 = 4000
  public static func BountyCorpChancePerDay() -> Float = 0.5
  public static func BountyCorpHostile() -> Int32 = 20000
  public static func BountyCorpVendetta() -> Int32 = 40000
  public static func BountyCorpDays() -> Float = 5.0
  public static func BountyCorpPayMult() -> Float = 1.5
  public static func BountyFirstHoursMin() -> Float = 2.0
  public static func BountyFirstHoursMax() -> Float = 5.0
  public static func BountyGapHours() -> Float = 9.0
  public static func BountyPairAmount() -> Int32 = 20000
  public static func BountyPairChance() -> Float = 0.33
  public static func LadderPlaces() -> Int32 = 10
  public static func LadderKeep() -> Int32 = 30
  public static func BountyLeftDistance() -> Float = 45.0
  public static func BountyLeftTicks() -> Int32 = 40
  public static func HunterRivalChance() -> Float = 0.5
  public static func HunterGradeLow() -> Float = 0.6
  public static func HunterBossBarRank() -> Int32 = 3
  public static func HunterRenownBase() -> Float = 4.0
  public static func HunterRenownPerPlace() -> Float = 1.5
  // Corporate interest ([88]): a Legend, once a week at most, 35% a day; a corporation V stands below -25 with warns V
  // off; otherwise 30000eb for a hostile gang's leader within 7 days, and 10 standing with them for it.
  public static func CorpInterestDays() -> Float = 7.0
  public static func CorpInterestChancePerDay() -> Float = 0.35
  public static func CorpWarnStanding() -> Float = -25.0
  public static func CorpContractDays() -> Float = 7.0
  public static func CorpContractPay() -> Int32 = 30000
  public static func CorpContractStanding() -> Float = 10.0
  // Street clashes ([N1], Spawn/Clashes.reds): the last four of each side the Director saw; who is at war here worked
  // out every 15 ticks; a try every two minutes at 35%, then ten minutes before the next; up to two pairs, each within
  // 35 m of each other and 15 to 70 m from V; over at three minutes or with V 140 m off; two points of strength.
  public static func ClashKeep() -> Int32 = 4
  public static func ClashPairTicks() -> Int32 = 15
  public static func ClashRollTicks() -> Int32 = 120
  public static func ClashChance() -> Float = 0.35
  public static func ClashGapTicks() -> Int32 = 600
  public static func ClashMaxPairs() -> Int32 = 2
  public static func ClashPairDistance() -> Float = 35.0
  public static func ClashMinFromV() -> Float = 15.0
  public static func ClashMaxFromV() -> Float = 70.0
  public static func ClashLeaveDistance() -> Float = 140.0
  public static func ClashMaxTicks() -> Int32 = 180
  public static func ClashGain() -> Float = 2.0
  // The Hub's web of gangs ([H1], UI/HubWeb.reds): a peace paid in the last three game days is said on V's line.
  public static func WebPeaceDays() -> Float = 3.0
  // The Rivals' moments (Rivals/RivalMoments.reds). Chrome: one implant a climb, up to four.
  public static func RivalImplantsMax() -> Int32 = 4
  public static func FacedownRange() -> Float = 24.0
  public static func FacedownEscortRange() -> Float = 40.0
  public static func FacedownTicks() -> Int32 = 15
  // A Rival owed a facedown walks up calm for at most this long before it is a fight anyway.
  public static func FacedownWaitTicks() -> Int32 = 75
  // In all, holding while V fights somebody else included.
  public static func FacedownWaitMaxTicks() -> Int32 = 240
  // A Rival at the end of their rope who breaks gives up where they stand this often, instead of running.
  public static func RivalYieldShare() -> Float = 0.5

  // ---- Kitting out the crew (Reactions/CrewKit.reds) ----
  public static func CrewNameMaxLength() -> Int32 = 24
  // How many weapons or pieces of chrome a pick list holds (60, scrolled ten at a time; it was 10 and stopped there).
  public static func CrewPickListMax() -> Int32 = 60
  // Each rank above Rookie (1 to 6): this much more health, armour and damage.
  public static func CrewRankHealthStep() -> Float = 0.12
  public static func CrewRankArmourStep() -> Float = 0.08
  public static func CrewRankDamageStep() -> Float = 0.08
  // Each training's better gear: health and armour.
  public static func CrewGearStep() -> Float = 0.1
  // A weapon handed over: damage by its quality, common 1 step to legendary 5.
  public static func CrewWeaponTierDamage() -> Float = 0.05
  // Each implant does what the game says it does (Reactions/CrewKit.reds, CBCrewChromeRead).
  public static func CrewCritBaseChance() -> Float = 5.0
  public static func CrewCritBaseDamage() -> Float = 50.0
  public static func CrewHeadshotShare() -> Float = 0.2
  public static func CrewWeakspotShare() -> Float = 0.05
  public static func CrewChromeMax() -> Int32 = 4
  public static func CrewMultCeiling() -> Float = 3.0
  // Their climb on the apex squads' scale (CBCrewApplyKit): this share of Adam Smasher at Legend (an apex member tops
  // out at ApexSmasherShareMax), and this much more for every spar with V, up to the most; this much longer under V's
  // fire than an apex member at the highest strength, at Legend; and no single hit takes more than this percent of
  // their health, from Rookie down to Legend.
  public static func CrewSmasherShareTop() -> Float = 0.45
  public static func CrewSmasherSparStep() -> Float = 0.01
  public static func CrewSmasherSparMax() -> Float = 0.08
  public static func CrewPastApex() -> Float = 1.1
  public static func CrewHitCapRookie() -> Float = 30.0
  public static func CrewHitCapLegend() -> Float = 9.0
  public static func CrewLegendEvasion() -> Float = 8.0
  // Training: the first costs this, each one after it more; away this many game hours, more each time; at most this many.
  public static func CrewTrainCostBase() -> Int32 = 2500
  public static func CrewTrainHoursBase() -> Float = 8.0
  public static func CrewTrainMax() -> Int32 = 3
  public static func CrewTrainLoyalty() -> Int32 = 5
  // A war: from this rank (Lieutenant), away this long, and how it goes.
  public static func CrewWarMinRank() -> Int32 = 4
  public static func CrewWarHours() -> Float = 18.0
  public static func CrewWarGangLoss() -> Float = 18.0
  public static func CrewWarStanding() -> Float = 12.0
  public static func CrewWarDeathShare() -> Float = 0.35
  public static func CrewWarHurtHours() -> Float = 48.0
  // War parties (Reactions/CrewWar.reds). Who may go along (a Lieutenant, CrewWarMinRank, leads), and how many.
  public static func CrewWarFollowMinRank() -> Int32 = 2
  public static func CrewWarPartyMax() -> Int32 = 6
  // A member's weight: a base, then per rank, per piece of chrome, per tier of the gun V gave them, per training, a spar's
  // edge; a party covering more seats fights better together; the crew's hold on those streets and its weight add on.
  public static func WarPowerBase() -> Float = 20.0
  public static func WarPowerPerRank() -> Float = 10.0
  public static func WarPowerPerChrome() -> Float = 6.0
  public static func WarPowerPerTier() -> Float = 5.0
  public static func WarPowerPerTrain() -> Float = 5.0
  public static func WarPowerSharp() -> Float = 5.0
  public static func WarSeatBonus() -> Float = 0.08
  public static func WarFootPower() -> Float = 25.0
  public static func WarWeightPower() -> Float = 0.15
  // A gang's weight: a base, its strength on its home streets, every district it holds; ready for a crew it hates, caught
  // out by one it respects; and less for how afraid of V it is.
  public static func GangWarBase() -> Float = 40.0
  public static func GangWarPerStrength() -> Float = 1.2
  public static func GangWarPerDistrict() -> Float = 6.0
  public static func GangWarStandWeight() -> Float = 0.15
  public static func GangWarFearWeight() -> Float = 0.2
  // How far the nights swing the ratio of the two, either way.
  public static func WarSwingLow() -> Float = 0.8
  public static func WarSwingHigh() -> Float = 1.25
  // What it does: the hold on their home streets by outcome, the spoils per member, the chance the weakest is hurt in a
  // plain win, deaths in a rout, the hidden stashes marked, a defector's price.
  public static func WarFootDecisive() -> Float = 0.45
  public static func WarFootWon() -> Float = 0.3
  public static func WarFootStalemate() -> Float = 0.1
  public static func WarFootLost() -> Float = 0.15
  public static func WarFootRouted() -> Float = 0.3
  public static func WarSpoilsPerMember() -> Float = 250.0
  public static func WarWonHurtChance() -> Float = 0.35
  public static func WarRoutDeathBase() -> Float = 0.15
  public static func WarRoutDeathSpread() -> Float = 0.35
  public static func WarStashesWon() -> Int32 = 2
  public static func WarStashesDecisive() -> Int32 = 4
  public static func WarDefectorPrice() -> Float = 0.5
  public static func SecretStashReach() -> Float = 12.0
  // The crew as a power on the street (Model/CrewTurf.reds). Its weight: per member, per rank, per war won (that many
  // counted at most).
  public static func CrewWeightPerMember() -> Float = 6.0
  public static func CrewWeightPerRank() -> Float = 3.0
  public static func CrewWeightPerWar() -> Float = 4.0
  public static func CrewWeightWarsCounted() -> Int32 = 10
  // A foothold fades after this many idle days, by this much a day; a member who lives there and a guard on V's home firm
  // it up each day; its push in the turf model; the street tax per held district a day.
  public static func CrewFootGraceDays() -> Float = 3.0
  public static func CrewFootFadePerDay() -> Float = 0.03
  public static func CrewFootLivesHere() -> Float = 0.02
  public static func CrewFootGuard() -> Float = 0.03
  public static func CrewTurfPush() -> Float = 1.0
  public static func CrewTurfTaxPerDistrict() -> Float = 250.0
  // In a district the crew holds, the gang that lost it breaks this much sooner (Reactions/Morale.reds); and the crew's
  // weight adds to V's menace up to this much (Signals/PlayerBuild.reds).
  public static func CrewHeldBreakBonus() -> Float = 0.15
  public static func CrewMenaceShare() -> Float = 15.0
  // A spar: put down this far off; a minute of fighting; stopped when either side is under this much health (percent);
  // they are this much tougher and hit this hard. Sharp for this many game hours after; every few spars a training.
  public static func CrewSparSpawnDistance() -> Float = 25.0
  public static func CrewSparArriveTicks() -> Int32 = 45
  public static func CrewSparTicks() -> Int32 = 60
  public static func CrewSparStopHealth() -> Float = 30.0
  public static func CrewSparHealthMult() -> Float = 2.5
  public static func CrewSparDamageMult() -> Float = 0.35
  public static func CrewSharpHours() -> Float = 24.0
  public static func CrewSharpDamage() -> Float = 0.1
  public static func CrewSharpCrit() -> Float = 5.0
  public static func CrewSparsPerTraining() -> Int32 = 3
  // Work: each earner brings in this much per rank each game day; now and then gets hurt for a day.
  public static func CrewEarnPerRank() -> Int32 = 150
  public static func CrewEarnHurtChance() -> Float = 0.08
  // The crew as a crew (Reactions/CrewBanner.reds): its colours, its own standing with each gang, its fallen and its
  // recruiter.
  public static func CrewColourDefault() -> Int32 = 3          // green, the colour its texts always had
  public static func CrewStandWarWon() -> Int32 = 30           // the gang a war was won on
  public static func CrewStandWarEnemy() -> Int32 = 10         // and the gang at war with them, pleased
  public static func CrewStandWarLost() -> Int32 = 15
  public static func CrewStandLent() -> Int32 = 10             // a gang lent the crew one of theirs
  public static func CrewStandFrightened() -> Int32 = 8        // one of theirs scared into joining
  public static func CrewStandOwed() -> Int32 = 5              // a Rival of theirs who joined
  public static func CrewStandMemberKilled() -> Int32 = 10     // one of the crew killed by their people
  public static func CrewStandKill() -> Int32 = 1              // one of theirs killed by the crew
  public static func CrewStandEase() -> Int32 = 2              // a game day, back towards nothing
  public static func CrewFallenKept() -> Int32 = 10            // the memorial's names (one list of the Hub's rows)
  public static func CrewRecruitChance() -> Float = 0.35       // on top of MyCrewOfferChance, a day
  public static func CrewRecruitDiscount() -> Float = 0.25     // off the solo's price
  public static func CrewRecruitLoyalty() -> Int32 = 10        // a solo a crew member vouched for
  public static func CrewRecruitWins() -> Int32 = 3            // a recruited solo comes as a Soldier...
  public static func CrewRecruitWinsSenior() -> Int32 = 7      // ...or a Veteran, found by a senior recruiter
  public static func CrewRecruitSeniorRank() -> Int32 = 4
  public static func FacedownDropSeconds() -> Float = 3.0
  public static func StareBase() -> Float = 0.3
  public static func StareCool() -> Float = 0.35
  public static func StareRenown() -> Float = 0.25
  public static func StareRank() -> Float = 0.08
  public static func StareShakenAim() -> Float = 0.6
  public static func StareBoldAim() -> Float = 1.25
  public static func StareSeconds() -> Float = 20.0
  public static func StareFear() -> Float = 6.0
  public static func DuelBase() -> Float = 0.45
  public static func DuelGangBonus() -> Float = 0.3
  public static func DuelFear() -> Float = 8.0
  // How low the Rival's health goes in a fair fight before their people break their word and step in, in percent.
  public static func DuelStepInHealth() -> Float = 15.0
  public static func CallEvenBase() -> Float = 0.3
  public static func HumiliateFear() -> Float = 10.0
  public static func HumiliateQuitChance() -> Float = 0.5
  public static func FeudDelayHours() -> Float = 18.0
  public static func FeudSetOnEdge() -> Int32 = 3
  public static func FeudChancePerDay() -> Float = 0.2
  public static func TrophyMinRank() -> Int32 = 2
  public static func BondChance() -> Float = 0.35
  public static func BondVengeanceTicks() -> Int32 = 300
  public static func BondDebtChance() -> Float = 0.35
  public static func ReturnChancePerDay() -> Float = 0.15
  public static func ReturnDays() -> Float = 5.0
  public static func EndedUpDays() -> Float = 7.0
  public static func EndedUpChancePerDay() -> Float = 0.25
  public static func TauntTicks() -> Int32 = 25
  public static func TauntRange() -> Float = 40.0
  public static func TauntChance() -> Float = 0.5
  public static func MeaningMaxDistance() -> Float = 600.0
  // Guards at a Rival's place walk somewhere 4 to 10 m round them every 20 seconds or so ([U10]).
  public static func GuardBeatTicks() -> Int32 = 20
  public static func GuardBeatMin() -> Float = 4.0
  public static func GuardBeatMax() -> Float = 10.0
  // Talk and allies (Reactions/Allies.reds). A borrowed crew: two (three at Allied), placed 22 m off, for a game hour;
  // home when V is 90 m off, off their turf for two minutes, at a job, or shoots one (6 standing).
  public static func CrewFriendly() -> Int32 = 2
  public static func CrewAllied() -> Int32 = 3
  public static func CrewSpawnDistance() -> Float = 22.0
  public static func CrewHours() -> Float = 1.0
  public static func CrewLeaveDistance() -> Float = 90.0
  public static func CrewAwayTicks() -> Int32 = 120
  public static func CrewShotStanding() -> Float = 6.0
  public static func JoinOfferChancePerDay() -> Float = 0.2
  public static func LeaveGangStanding() -> Float = 25.0
  public static func DutyDays() -> Float = 7.0
  public static func DutyKills() -> Int32 = 5
  public static func DutyStanding() -> Float = 6.0
  public static func RansomBase() -> Float = 1500.0
  public static func RansomTicks() -> Int32 = 20
  public static func RansomPayChance() -> Float = 0.6
  public static func HandOverWarm() -> Float = 8.0
  public static func HandOverSlight() -> Float = 6.0
  public static func LieBase() -> Float = 0.35
  public static func LieCool() -> Float = 0.35
  public static func LieKnown() -> Float = 0.3
  public static func LieHours() -> Float = 8.0
  public static func InformantFoundChancePerDay() -> Float = 0.06
  public static func InformantSavedTips() -> Int32 = 2
  public static func SergeantParleyRange() -> Float = 18.0
  public static func ParleyGapTicks() -> Int32 = 300
  public static func ParleyScareBase() -> Float = 0.2
  public static func ParleyScareFear() -> Float = 0.4
  public static func ParleyScareCool() -> Float = 0.25
  public static func GreetDistance() -> Float = 8.0
  public static func GreetTicks() -> Int32 = 90
  // One of theirs counts as wearing their colours at 0.8 (a good disguise); a lie sends the hunt's tip 4 times as far.
  public static func OneOfTheirsColours() -> Float = 0.8
  public static func LieTipMult() -> Float = 4.0
  // Telling it (Narrative/Telling.reds). Panic in the dark: crew within 40 m hear it; from the second unseen kill
  // somebody may run, 25% more each one. The brief covers the last 12 game hours.
  public static func PanicRange() -> Float = 40.0
  public static func PanicRunAfter() -> Int32 = 2
  public static func PanicBreakChance() -> Float = 0.25
  public static func BriefHours() -> Float = 12.0
  public static func PhoneStallTicks() -> Int32 = 300
  public static func PhoneInsultStanding() -> Float = 5.0
  public static func PhoneInsultRenown() -> Float = 2.0
  public static func PhoneComeOnTicks() -> Int32 = 60
  public static func PhoneTauntShake() -> Float = 0.4
  public static func CredRivalBase() -> Int32 = 60
  public static func CredRivalPerRank() -> Int32 = 40
  public static func CredOpenSeason() -> Int32 = 250
  public static func CredHunterPerPlace() -> Int32 = 15
  public static func CredLadderTop() -> Int32 = 400
  // A crew of V's own (Reactions/Crew.reds).
  public static func MyCrewRoster() -> Int32 = 5
  public static func MyCrewOut() -> Int32 = 3
  public static func MyCrewEscortOut() -> Int32 = 2
  public static func MyCrewSpawnReserve() -> Int32 = 3
  public static func MyCrewCallSeconds() -> Float = 900.0
  public static func MyCrewNoShowTicks() -> Int32 = 30
  // How far from V the crew takes on whoever is fighting V (CBCrewHostilityTick).
  public static func MyCrewFightRange() -> Float = 45.0
  public static func MyCrewSpawnDistance() -> Float = 24.0
  // Further out when nowhere that close will take them (CBSpawnOnSide): the middle ring, then the distance every hunter
  // is sent from (HitSquadMinSpawnDistance), where there is always somewhere out of V's sight.
  public static func MyCrewMidSpawnDistance() -> Float = 50.0
  public static func MyCrewFarSpawnDistance() -> Float = 85.0
  public static func MyCrewQuietTicks() -> Int32 = 60
  // A fight the crew stood in counts as won once it has been over this many ticks (CBCrewBattleTick): long enough that
  // a lull is not a win, short enough that sending them home straight after still finds it counted.
  public static func MyCrewWonTicks() -> Int32 = 5
  // Really in it (CBCrewBattleTick): somebody fighting V this close to one of them for this many ticks, unless one of
  // them took or landed a hit or an enemy went down near them first.
  public static func MyCrewEngageRadius() -> Float = 30.0
  public static func MyCrewEngageTicks() -> Int32 = 4
  // The crew's own lives (Reactions/CrewLife.reds). A member's story keeps its newest lines, the whole book a few
  // hundred; kit texts sent within a few ticks of each other go as one.
  public static func CrewStoryKept() -> Int32 = 12
  public static func CrewStoryBookCap() -> Int32 = 240
  public static func CrewStoryShown() -> Int32 = 7
  public static func CrewGroupReplies() -> Int32 = 2
  public static func CrewBatchTicks() -> Int32 = 3
  public static func CrewSecondLoyalty() -> Int32 = 8
  public static func CrewSecondWarBonus() -> Float = 0.15
  // Asks: a chance a day while nothing is asked, how long V has, the gap after one, what a cut asks, and what it is worth.
  public static func CrewAskChance() -> Float = 0.30
  public static func CrewAskDays() -> Float = 2.0
  public static func CrewAskGapDays() -> Float = 2.0
  public static func CrewAskCutBase() -> Int32 = 400
  public static func CrewAskCutPerRank() -> Int32 = 250
  public static func CrewAskDoneLoyalty() -> Int32 = 10
  public static func CrewAskIgnoredLoyalty() -> Int32 = 8
  // A funeral the evening after, at this hour, open this many hours; what coming and missing it are worth to the rest.
  public static func CrewFuneralHour() -> Int32 = 20
  public static func CrewFuneralWindowHours() -> Float = 4.0
  public static func CrewFuneralLoyalty() -> Int32 = 8
  public static func CrewFuneralMissLoyalty() -> Int32 = 6
  // A bed at the crew's home: time out hurt, by this much.
  public static func CrewHomeHealFactor() -> Float = 0.5
  // V in the war: each of the gang's people V puts down while the crew's war on them is on adds to the crew's side, up
  // to a ceiling; the spoils grow with it.
  public static func CrewTaxOwedCap() -> Int32 = 6000
  public static func CrewTaxShopRange() -> Float = 8.0
  public static func CrewTaxFearBonus() -> Float = 0.75
  // A counterattack on the crew's corners: told this many game hours ahead, open this long, their crew this many ticks
  // behind V's arrival, and what holding or losing it does to the crew's hold there.
  public static func CrewCounterAheadHours() -> Float = 3.0
  public static func CrewCounterWindowHours() -> Float = 3.0
  public static func CrewCounterArriveTicks() -> Int32 = 25
  public static func CrewCounterHeldFoot() -> Float = 12.0
  public static func CrewCounterLostFoot() -> Float = 10.0
  // A Rival's timeline (Rivals/RivalTimeline.reds): how much the book keeps, how much a Rival's line shows.
  public static func RivalTimelineCap() -> Int32 = 400
  public static func RivalTimelineShown() -> Int32 = 6
  // Calling cards: the chance one is left, how far away, how long it waits, how close V has to come, and what it holds.
  public static func RivalCardChance() -> Float = 0.5
  public static func RivalCardMin() -> Float = 150.0
  public static func RivalCardMax() -> Float = 450.0
  public static func RivalCardDays() -> Float = 2.0
  public static func RivalCardFindRange() -> Float = 10.0
  public static func RivalCardEddies() -> Int32 = 150
  // A humiliated Rival turning, a day; a scarring Rival meeting the member on a job, and what it costs the odds.
  public static func RivalTurnChance() -> Float = 0.2
  public static func RivalHuntsCrewChance() -> Float = 0.35
  public static func RivalHuntsCrewOdds() -> Float = 0.15
  // What the street talks about (Reactions/TalkMore.reds): things V did in the last this many game hours.
  public static func TalkNewsHours() -> Float = 48.0
  // A meeting or gang business that runs late while V waits at the place, at most this many times.
  public static func EventLateMax() -> Int32 = 2
  // A friendly gang's people stay out of fights V did not start with them (CBSidesWithV), unless V hurt one of theirs
  // this close.
  public static func AllyHurtNearRange() -> Float = 30.0
  public static func HangoutGreetDistance() -> Float = 8.0
  // The crew on its corners (Reactions/CrewLoiter.reds): at most this many, this far from V, and this long between.
  public static func CrewLoiterMax() -> Int32 = 2
  public static func CrewLoiterDistance() -> Float = 24.0
  public static func CrewLoiterGapHours() -> Float = 3.0
  // Hunters who regroup (Spawn/Regroup.reds): at least this many down first, and more sent this many ticks later.
  public static func RegroupMinDown() -> Int32 = 3
  public static func RegroupReinforceTicks() -> Int32 = 45
  // Sit-downs and crashed business (Model/GangBosses.reds): how close V has to have come to have been there, what
  // speaking for a gang is worth, what the gang V helped thinks of it, the chance of a Rival, and the ground lost.
  public static func SitDownPresentDistance() -> Float = 40.0
  public static func SitDownSpokeWarmth() -> Float = 8.0
  public static func EventHelpedWarmth() -> Float = 5.0
  public static func EventRivalChance() -> Float = 0.3
  public static func EventGroundLoss() -> Float = 6.0
  public static func WarVKillWeight() -> Float = 0.08
  public static func WarVKillCeiling() -> Float = 0.6
  public static func MyCrewDriveTicks() -> Int32 = 4
  public static func MyCrewLeaveDistance() -> Float = 120.0
  public static func MyCrewStayedDistance() -> Float = 35.0
  public static func MyCrewTurnTicks() -> Int32 = 10
  public static func MyCrewTurnFightTicks() -> Int32 = 35
  public static func MyCrewLoyaltyOwed() -> Int32 = 80
  public static func MyCrewLoyaltyLent() -> Int32 = 65
  public static func MyCrewLoyaltyPaid() -> Int32 = 60
  // Frightened recruits start at 60 and their fear wears off by 1 a day: at 35 and 3 they were under the betrayal line
  // against their old gang inside a day, and turned on V a third of the time when called.
  public static func MyCrewLoyaltyFrightened() -> Int32 = 60
  public static func MyCrewRestless() -> Int32 = 40
  public static func MyCrewBetrayLine() -> Int32 = 25
  public static func MyCrewOldGangLine() -> Int32 = 10
  public static func MyCrewOwnLoyalty() -> Int32 = 70
  public static func MyCrewWinLoyalty() -> Int32 = 3
  public static func MyCrewStayedLoyalty() -> Int32 = 5
  public static func MyCrewLeftLyingLoyalty() -> Int32 = 10
  public static func MyCrewDiedLoyalty() -> Int32 = 6
  public static func MyCrewFairCut() -> Int32 = 5
  public static func MyCrewFairCutPaid() -> Int32 = 8
  public static func MyCrewFearDrift() -> Int32 = 1
  public static func MyCrewUnpaidDrift() -> Int32 = 4
  public static func MyCrewUnpaidDriftPaid() -> Int32 = 8
  public static func MyCrewOldGangHurt() -> Int32 = 2
  public static func MyCrewHurtDays() -> Float = 0.25
  public static func MyCrewCutBase() -> Int32 = 250
  public static func MyCrewCutPaid() -> Int32 = 600
  public static func MyCrewCutPerRank() -> Int32 = 100
  public static func MyCrewMercBase() -> Int32 = 1000
  public static func MyCrewMercPerTier() -> Int32 = 400
  public static func MyCrewOfferChance() -> Float = 0.35   // a solo on offer, a day (0.15 was one in twenty hours)
  public static func MyCrewRecruitBase() -> Float = 0.8
  public static func MyCrewRenown() -> Float = 5.0
  public static func MyCrewPastKept() -> Int32 = 12
  // The map remembers (UI/MapPins.reds): a day, twelve places at most, one per 40 m of each kind.
  public static func LairSpotRange() -> Float = 25.0
  public static func LairSpotTicks() -> Int32 = 3
  public static func LairWarnTicks() -> Int32 = 8
  public static func LairMoveMin() -> Float = 100.0
  public static func LairMoveMax() -> Float = 180.0
  // [U9] A ripperdoc this close to where the search started is taken to be in the same district.
  public static func RipperdocDistrictReach() -> Float = 450.0
  // [U9] The street outside a clinic: two rings round its pin, and how many of the nearest clinics are tried.
  public static func RipperdocOutsideNear() -> Float = 15.0
  public static func RipperdocOutsideFar() -> Float = 30.0
  public static func RipperdocClinicTries() -> Int32 = 3
  public static func MapMemoryHours() -> Float = 24.0
  public static func MapMemoryKept() -> Int32 = 12
  public static func MapMemoryMerge() -> Float = 40.0
  // A head start from the lifepath (Model/Lifepath.reds): fifteen standing with the gang that is V's own, ten against
  // the one with a grudge, ten points of being known by each, and five in the home district.
  public static func HeadStartFriend() -> Float = 15.0
  public static func HeadStartGrudge() -> Float = 10.0
  public static func HeadStartKnown() -> Float = 10.0
  public static func HeadStartDistrict() -> Float = 5.0
  // They challenge within 4 m, give up walking after 90 seconds or 90 m, stand down when V is under 25% health or 35 m
  // away mid-fight, or after 150 seconds of it.
  public static func WannabeGapHours() -> Float = 6.0
  public static func WannabeChance() -> Float = 0.6
  public static func WannabeSpawnGraceTicks() -> Int32 = 20
  public static func WannabeChallengeDistance() -> Float = 4.0
  public static func WannabeApproachTicks() -> Int32 = 90
  public static func WannabeLoseInterestDistance() -> Float = 90.0
  public static func WannabeLoseHealth() -> Float = 25.0
  public static func WannabeWalkAwayDistance() -> Float = 35.0
  public static func WannabeFightTicks() -> Int32 = 150
  public static func WannabeLifeTicks() -> Int32 = 240
  public static func WannabeRenown() -> Float = 3.0
  public static func WannabeShotCode() -> Float = 2.0

  // ---- Morale (spec §9.4) ----------------------------------------------
  public static func MoraleMaxBreakFraction() -> Float = 0.35
  // What goes into the chance of somebody running (Reactions/Morale.reds, CBBreakChance). Nobody breaks on the first
  // body.
  public static func MoraleBreakMinShock() -> Float = 0.15
  public static func MoraleBreakShockWeight() -> Float = 0.5
  public static func MoraleHurtBelow() -> Float = 50.0
  public static func MoraleHurtWeight() -> Float = 0.2
  public static func MoraleAloneBonus() -> Float = 0.1
  public static func MoraleBackedUpMult() -> Float = 0.75
  public static func MoraleBackedUpAllies() -> Int32 = 3
  public static func MoraleLeaderDownBonus() -> Float = 0.08
  public static func MoraleBrutalBonus() -> Float = 0.04
  public static func MoraleSwornMult() -> Float = 0.6
  public static func MoraleBreakMaxChance() -> Float = 0.4
  // On streets they have just lost, nobody is sure what they are still fighting for.
  public static func MoraleLostGroundMult() -> Float = 1.4
  // A gang V has broken (Model/Territory.reds, GangBrokenStrength) breaks sooner still, and its vendetta no longer
  // stiffens it.
  public static func MoraleBrokenGangMult() -> Float = 1.8
  // What a broken gang asks to call off its grudge, as a share of its usual price (Economy/Peace.reds).
  public static func PeaceBrokenShare() -> Float = 0.5
  // Holding back from V on the street (Reactions/Morale.reds, CBHoldBackChance). Fear is the gang's fear of V as 0..1;
  // a broken gang adds BrokenGangFear, one that has lost ground LostGroundFear.
  public static func BrokenGangFear() -> Float = 0.35
  public static func LostGroundFear() -> Float = 0.10
  public static func HoldBackNerveWeight() -> Float = 0.6
  public static func HoldBackScale() -> Float = 1.6
  public static func HoldBackPerBacker() -> Float = 0.12
  public static func HoldBackBackerRadius() -> Float = 12.0
  public static func HoldBackMaxBackers() -> Int32 = 4
  public static func HoldBackMax() -> Float = 0.9
  // How shaken somebody at a quarter of their health counts as, with nobody having died near them.
  public static func MoraleHurtShock() -> Float = 0.5
  // The run itself. Somewhere this far off, and this much further from V than they already are.
  public static func FleeRunMin() -> Float = 30.0
  public static func FleeRunMax() -> Float = 60.0
  public static func FleeMinGain() -> Float = 15.0
  public static func FleeSpotCandidates() -> Int32 = 8
  // Reaching the spot with V still close is no reason to come back.
  public static func FleeReorderTicks() -> Int32 = 8
  public static func FleeMaxOrders() -> Int32 = 3
  public static func MoraleShockRadius() -> Float = 15.0

  // ---- Low-health combat flee / escape -> Rival (spec §10.2) -----------
  public static func FleeHealthThreshold() -> Float = 25.0   // health % below which they may run
  public static func FleeChance() -> Float = 0.5             // else they fight to the death
  public static func EscapeDistance() -> Float = 60.0        // ran this far from V = got away
  // Both of these are fast ticks, about a real second each.
  public static func EscapeTimeoutTicks() -> Int32 = 120    // give up tracking an escapee after this
  // Someone you put down and left does not run anywhere, so there is nothing to wait for. Two minutes of standing
  // around before the Rival existed is why sparing felt like it did nothing at all.
  public static func SparedResolveTicks() -> Int32 = 25
  // However the fight goes, a Rival's mercy is settled by this point. Anyone else's waits for V
  // to actually leave them (SparedLeftDistance), or for the body to stream out.
  public static func SparedResolveMaxTicks() -> Int32 = 180
  // How far V has to be from somebody left breathing before V has left them. Closer than the
  // escape distance: nobody is running, V only has to have moved on.
  public static func SparedLeftDistance() -> Float = 45.0
  // Room for a whole compound put to sleep, since a mercy now waits for V to leave. When it does
  // fill, runaways go first, and a mercy pushed out is settled rather than lost.
  public static func EscapeeCap() -> Int32 = 48

  // ---- Vendors (spec §9.6) ---------------------------------------------
  public static func VendorMaxDiscount() -> Float = 0.20
  public static func VendorMaxSurcharge() -> Float = 0.15

  // ---- Gig payout bonus (spec §9.7) ------------------------------------
  // Only payouts at or above this many eddies are treated as job money (not loot).
  public static func GigBonusMinPayout() -> Int32 = 400
  // A payout at least this large reads as a gig or a job; smaller ones read as NCPD hustle
  // work. Anything under GigBonusMinPayout is not treated as job money at all.
  public static func JobPayoutThreshold() -> Int32 = 1500
  // Max fraction added on top of a job payout at the Legend tier.
  public static func GigBonusMaxFraction() -> Float = 0.20
  // However the slider, the street's opinion and a title add up.
  public static func GigBonusCeiling() -> Float = 0.75
  // Enough for every body of ours alive at once, and the ones just gone (CBApplyApexBuild).
  public static func BuiltRecordCap() -> Int32 = 64

  // ---- Tribute (spec §9.8) --------------------------------------------- Rolled once an in-game day per gang that
  // qualifies.
  public static func TributeChance() -> Float = 0.5
  public static func TributeCooldownDays() -> Float = 7.0
  // A gang's fear is Dread scaled by how well it knows V, and Dread itself could not get past the sixties, so outside
  // the Scavs nobody ever paid.
  public static func TributeFearThreshold() -> Float = 65.0
  // What the two hardest titles ask (Model/TitleEngine.reds). They asked for Dread 90 and a gang's fear at 85, which
  // the sums could not produce for any gang but the Scavs.
  public static func TitleDreadNeeded() -> Float = 80.0
  public static func TitleFearNeeded() -> Float = 75.0
  public static func TributeRenownThreshold() -> Float = 50.0

  // ---- Hit squads (spec §9.9) ------------------------------------------
  public static func HitSquadFactionCooldownDays() -> Float = 2.0
  // The grudge clock (Spawn/Grudge.reds), in game hours and multipliers on a gang's or a Rival's patience.
  public static func GrudgeSlowHours() -> Float = 24.0       // just over the line into Hostile
  public static func GrudgeFastHours() -> Float = 3.0        // the bottom of Vendetta
  public static func GrudgeFloorHours() -> Float = 1.5
  // Before V is known (CBMercStanding): the Street Cred at which V's name carries in full, about where the Heist falls;
  // what share of renown V earns, how much longer gangs and Rivals wait, and what share of the Rivals that would be
  // made are made, at Street Cred 0, each easing to the full amount by StandingFullCred; and the Street Cred before
  // which no gang sends its best.
  public static func StandingFullCred() -> Float = 20.0
  public static func EarlyRenownShare() -> Float = 0.4
  public static func EarlyPatienceMult() -> Float = 2.0
  public static func EarlyRivalShare() -> Float = 0.5
  public static func ApexMinStreetCred() -> Float = 15.0
  public static func GrudgeFreshHours() -> Float = 6.0
  public static func GrudgeFreshMult() -> Float = 0.5
  public static func GrudgeBrokenWeight() -> Float = 3.0     // a gang with nobody left waits up to four times as long
  public static func GrudgeRegroupMult() -> Float = 1.5
  public static func GrudgeFearWeight() -> Float = 0.8
  public static func GrudgeAtWarMult() -> Float = 1.3
  public static func GrudgeOnTurfMult() -> Float = 0.6
  public static func GrudgeHopWeight() -> Float = 0.25
  public static func GrudgeMaskMult() -> Float = 1.4
  public static func GrudgeNightMult() -> Float = 0.8
  public static func GrudgeApexMinManpower() -> Float = 0.25
  public static func GrudgeRivalSlowHours() -> Float = 16.0
  public static func GrudgeRivalFastHours() -> Float = 3.0
  public static func GrudgeRivalGangShare() -> Float = 0.6
  // Further out than an ambush, out of sight, and they have to come and find V (Spawn/Hunt.reds).
  // These were 42 to 50 m, which is behind you rather than coming for you.
  public static func HitSquadMinSpawnDistance() -> Float = 85.0
  // Rivals spawn closer than hit squads so they immediately perceive V and give chase. Close enough that V meets them
  // before driving off.
  public static func RivalSpawnDistance() -> Float = 80.0

  // How many downed enemies the mercy sweep looks at per fast tick.
  public static func SparedSweepPerTick() -> Int32 = 10

  // ---- Quiet work (spec §16) --------------------------------------------- How long the "do not walk in on a stealth
  // job" hold outlives the game's Stealth state.
  public static func StealthHoldGraceTicks() -> Int32 = 25

  // ---- Archetypes (spec §8.3) ------------------------------------------- How much a plain lethal kill says about
  // you. Small on purpose: killing an armed ganger in a firefight is the job, not butchery.
  public static func ButcherPerLethalKill() -> Float = 0.2
  // Finishers, dismemberment, blades and fists. This is what Butcher is actually measuring.
  public static func ButcherPerBrutalKill() -> Float = 1.5
  // Lethal with nobody left to report it.
  public static func GhostPerUnseenKill() -> Float = 1.5
  // On top of the plain kill, for one in an open fight: going in shooting is the body count Butcher measures.
  public static func ButcherPerLoudKill() -> Float = 0.6

  // ---- Witnesses (spec §8.5) -------------------------------------------
  // How far a kill carries to someone who could report it. Wider than NpcEvalRadius: a
  // sightline across a street carries further than a crowd reaction does.
  public static func WitnessRadius() -> Float = 45.0
  // Bound the per-kill scan of the NPC registry. The registry holds up to 200.
  public static func WitnessScanCap() -> Int32 = 40
  // Stop counting once we have this many: callers need "any" and "a crowd", not a tally.
  public static func WitnessCountCap() -> Int32 = 5
  // A witness has to actually be able to see V, not merely be within the radius. Without this
  // a ganger through a warehouse wall counted, which made quiet work far harder than it looked.
  public static func WitnessRequiresLineOfSight() -> Bool = true
  // Dread from a body nobody can put a name to. The city fears what it cannot identify,
  // so no-witness work still builds something - just not a reputation that is yours.
  public static func UnattributedDeedDread() -> Float = 0.6

  // How far word carries when nobody was alive to carry it. Applied both where the rumor
  // starts and at every hop, so no-witness work stays local instead of becoming a legend.
  public static func UnwitnessedSpreadMult() -> Float = 0.3

  // ---- The grapevine (spec §8.5) ----------------------------------------
  // Chance that word reaching a district it had not touched gets back to you as a message.
  public static func GrapevineChance() -> Float = 0.5
  // In-game hours between messages, so hearing from the street stays an event.
  public static func GrapevineCooldownHours() -> Float = 8.0
  // Word has to be worth repeating before anyone passes it on.
  public static func GrapevineMinMagnitude() -> Float = 4.0

  // ---- Gang hierarchy (spec §10.1) ---------------------------------------
  // Running a crew, or standing near the top of one, makes you harder to put down. Modest
  // next to an apex hunter, which is a different kind of event entirely.
  public static func LeaderMinRank() -> Int32 = 4
  public static func LieutenantMinRank() -> Int32 = 3
  // Both were far higher (2.0 and 1.4) and both stacked on top of the full apex-grade build,
  // which is how a leader Rival became the enemy players could not kill. They are a nudge
  // now, and CBApplyApexGradeBuff clamps the result anyway.
  public static func LeaderHealthMult() -> Float = 1.25
  public static func LieutenantHealthMult() -> Float = 1.1

  // ---- Succession (spec §10.1) ------------------------------------------ The chance someone steps into a slain
  // Rival's place: the base plus this per rank of the one you put down, so a rank 1 is 40% and a rank 4 is 85% before
  // the Rival frequency setting.
  public static func SuccessionChanceBase() -> Float = 0.25
  public static func SuccessionChancePerRank() -> Float = 0.15

  // ---- Spawn ground probe (mid-air spawn fix) -------------------------- The spawn point is a flat offset behind V,
  // so the floor under it is often not at V's own height.
  public static func GroundProbeUp() -> Float = 3.0      // start the ray this far above the guess
  public static func GroundProbeDown() -> Float = 25.0   // and look this far below it
  // Minimum upward tilt of the hit surface for it to count as a floor rather than a wall or
  // a railing (the Z of a unit normal: 1.0 is flat ground, 0.0 is a vertical face).
  public static func GroundMinNormalZ() -> Float = 0.65
  // A floor further than this from V's own height is another level - a roof, the bottom of a
  // shaft - so the point is moved in toward V instead of used.
  // How far above or below V a spawn point's floor may be.
  public static func GroundMaxDrop() -> Float = 3.5
  // Set them down a hair above the floor so they never start clipped into it. Clearance above the floor a spawn is
  // placed on.
  public static func GroundSpawnLift() -> Float = 0.35
  // Only used where the navigation system cannot be asked at all.
  public static func NavFloorProbeUp() -> Float = 0.5
  // A hair of clearance over the navmesh point or the floor, whichever is higher. The game's pursuers use the point
  // exactly; this only keeps the feet out of the surface.
  public static func NavSpawnClearance() -> Float = 0.03
  // How far a raycast floor point may be from the navmesh under it and still be that point.
  public static func NavFloorSnapRadius() -> Float = 1.5
  public static func NavFloorSnapHeight() -> Float = 0.6
  // A short walk on the navmesh (CBWalkJoins, 2.7.9): how far from the navmesh either end may be, and the slack over a
  // straight line the walk may take.
  public static func WalkJoinTolerance() -> Float = 0.75
  public static func WalkJoinSlack() -> Float = 10.0
  // A floor found more than this above the navmesh point is not the floor but something standing on it, the seat of a
  // couch or a bench (2.7.9).
  public static func SpawnFurnitureRise() -> Float = 0.35
  // How far a candidate point may sit above the floor underneath it and still count as that floor's.
  public static func SpawnGroundSettle() -> Float = 2.0
  // Nobody stands inside anybody else. Enough for two people to be distinct bodies and small
  // enough that a squad still reads as a squad.
  public static func SpawnMinSeparation() -> Float = 1.6
  // Chippin' In (Reactions/ChippinIn.reds): V's health down and back up, in percent; how long V stays down at least
  // (the knockdown is 4.1 s), how long at most before getting up alone, and how close they must be to count as there.
  public static func ChipInDownHealth() -> Float = 5.0
  public static func ChipInUpHealth() -> Float = 50.0
  public static func ChipInAloneHealth() -> Float = 25.0
  public static func ChipInMinDownSeconds() -> Float = 4.5
  public static func ChipInMaxDownSeconds() -> Float = 14.0
  public static func ChipInReachDistance() -> Float = 4.0
  // V's people in V's car (Reactions/CrewCar.reds): how long a seat just given stays theirs while they walk to it, how
  // long somebody asked out of a car may sit there before being lifted out, and how slow the car must be for that.
  public static func SeatWalkSeconds() -> Float = 8.0
  public static func UnmountStuckSeconds() -> Float = 5.0
  public static func UnmountStillSpeed() -> Float = 1.0
  // How long a spawn point stays taken for every other group (CBPointIsFree), and how many are remembered.
  public static func RecentSpawnSeconds() -> Float = 12.0
  public static func RecentSpawnCap() -> Int32 = 40
  // How far the rest of a group may form up from the first one placed. Keeps a squad together
  // and means only the first point of a group needs the full reachability test.
  public static func SpawnGroupRadius() -> Float = 18.0
  // How far apart the seats of an arriving car are created before they are mounted.
  public static func ArrivalSeatSpread() -> Float = 1.4
  // A crew member's spot beside the car may move this far to reach the ground. A snap can reach much
  // further, and past a wall that is the next room.
  public static func ArrivalSeatSnap() -> Float = 3.0
  // Largest cosine of the angle between V's facing and the spawn point that is still
  // accepted. 0.342 is cos(70 degrees), the same margin They Will Remember uses, expressed in
  // a form with no unit to get wrong.
  public static func SpawnMaxFacingCosine() -> Float = 0.342
  // And the shortest distance worth queuing an out-of-view spawn at.
  public static func SpawnMinDistance() -> Float = 25.0
  // Bearings tried around V before giving up, starting directly behind and widening.
  public static func SpawnBearingTries() -> Int32 = 9
  public static func SpawnPerRank() -> Int32 = 4
  public static func SpawnRankSpacing() -> Float = 3.0
  // How far a navmesh snap may move a body from where its rank asked for it before the point
  // is refused as belonging to somewhere else entirely.
  public static func NavSnapTolerance() -> Float = 10.0
  // Where a hunter stops once it reaches V, and how much that varies across a squad.
  public static func HuntStopDistance() -> Float = 3.0
  public static func HuntStopSpread() -> Float = 8.0

  // ---- Arriving by car (spec 9.9) ---- Far enough out that the car is not seen appearing and has room to build up
  // speed.
  public static func VehicleArrivalDistance() -> Float = 110.0
  // How many of the game's pursuit points a car arrival may try when the navmesh anchor has no
  // room for a car (CBCarSpawnPoint). Each costs two overlap tests and a floor trace.
  public static func CarPointCandidates() -> Int32 = 12
  // Cars one arrival may bring before the rest walk (setting default), and how many ticks in a
  // row a convoy's next car may fail to be sent before that leg walks in instead.
  public static func CarsPerArrivalDefault() -> Int32 = 4
  public static func ConvoyCarTries() -> Int32 = 4
  // The box a car needs to be clear before one is put there, in metres.
  public static func CarFitWidth() -> Float = 1.2
  public static func CarFitLength() -> Float = 2.6
  public static func CarFitHeight() -> Float = 0.7
  // How far off the floor the bottom of that box sits: over a kerb or a camber, under a car.
  public static func CarFitClearance() -> Float = 0.5
  public static func CarMaxSeats() -> Int32 = 4
  // One beat for the mounts to settle before the driver is given orders.
  public static func CarStartDelay() -> Float = 0.3
  // A vendetta crew waiting up the road for a V who is driving (Spawn/Arrival.reds, CBAmbushSpot).
  public static func AmbushChance() -> Float = 0.5
  public static func AmbushMinSpeed() -> Float = 8.0
  public static func AmbushDistance() -> Float = 150.0
  public static func AmbushAheadCosine() -> Float = 0.6
  public static func AmbushSpringDistance() -> Float = 45.0
  // V took another road. They stop waiting and come after V like any other car.
  public static func AmbushGiveUpDistance() -> Float = 300.0
  public static func AmbushPoll() -> Float = 0.5
  public static func AmbushMaxPolls() -> Int32 = 120
  public static func ChaseDistanceMin() -> Float = 3.0
  public static func ChaseDistanceMax() -> Float = 12.0
  public static func ChaseStartSpeed() -> Float = 10.0
  // Metres a second. This was 80, nearly 290 km/h through city traffic, which is why crews arrived by driving into
  // things.
  public static func ArrivalDriveMaxSpeed() -> Float = 20.0
  public static func ArrivalDriveMinSpeed() -> Float = 10.0
  public static func ArrivalStopDistance() -> Float = 20.0
  // A car that has reached V but is still rolling is braked, for at most this long.
  public static func ArrivalBrakeSeconds() -> Float = 4.0
  // How many times a crew still in their seats is asked again, one poll apart.
  public static func ArrivalCrewOutTries() -> Int32 = 5
  // How close the car has to get before the crew is let out, how often that is checked, and
  // how many checks before they are unloaded regardless.
  public static func ArrivalDismountDistance() -> Float = 35.0
  public static func ArrivalDismountPoll() -> Float = 2.0
  public static func ArrivalDismountMaxTries() -> Int32 = 30
  // Sending a car on foot-bound V somewhere new while it drives (CBArrivalDismountCallback):
  // only once V is this far from where it was sent, at most every this many polls, this often.
  public static func ArrivalRetargetDistance() -> Float = 20.0
  public static func ArrivalRetargetEvery() -> Int32 = 3
  public static func ArrivalMaxRetargets() -> Int32 = 12
  // A car under this speed and not there yet is stuck. After this many polls in a row it is given
  // its order again, and after this many the crew get out and come on foot (CBArrivalDismountCallback).
  public static func CarStuckSpeed() -> Float = 1.0
  public static func CarStuckRetryPolls() -> Int32 = 3
  public static func CarStuckGiveUpPolls() -> Int32 = 6
  // Ticks (about a second each) before a car that never attached is written off.
  public static func ArrivalStaleTicks() -> Int32 = 30
  // How long an expired appointment may wait for a workable moment before it gives up and lets
  // the scheduler arrange a fresh one. Without this, one badly timed expiry blocks every future
  // squad and apex for the rest of the session.
  public static func PendingHoldGiveUpTicks() -> Int32 = 120

  // ---- Can a car even get here (spec 9.9) ------------------------------

  // ---- Messages on the phone (spec 12.2) -------------------------------
  //
  // The card is authored in 1080p units and scaled by the same fit the Hub uses.
  public static func PhoneCardRows() -> Int32 = 3
  public static func PhoneCardWidth() -> Float = 580.0
  public static func PhoneCardHeight() -> Float = 118.0
  public static func PhoneCardGap() -> Float = 10.0
  public static func PhoneCardLeft() -> Float = 70.0
  public static func PhoneCardTop() -> Float = 330.0
  public static func PhoneCardEdge() -> Float = 5.0
  // Long enough to read a sentence and a half without pausing the game, and the reading-speed
  // setting still multiplies it. The floor is what a message is worth at the lowest setting.
  public static func PhoneHoldSeconds() -> Float = 9.0
  public static func PhoneHoldFloor() -> Float = 5.0
  public static func PhoneSlideSeconds() -> Float = 0.22
  public static func PhoneSlideDistance() -> Float = 60.0
  public static func PhoneFadeSeconds() -> Float = 0.6
  // Three wrapped lines on a card this wide. Anything longer is a paragraph, and a message
  // that needs a paragraph is a message that needed cutting.
  public static func PhoneBodyMaxChars() -> Int32 = 180
  // The threads in the phone. Session only; see the note in UI/PhoneMessages.reds about why they are not persisted.
  public static func PhoneThreadCap() -> Int32 = 64
  public static func PhoneMessageCap() -> Int32 = 240
  // How much of one thread the phone draws. A thread longer than this shows its newest lines.
  public static func PhoneThreadShown() -> Int32 = 30
  // The quietest the phone is allowed to be busy. Messages are always filed in their thread and always mark it unread;
  // this only limits how often one of them is allowed to put a notification on screen, in real seconds.
  public static func PhoneNotifyGapSeconds() -> Float = 9.0
  // A message identical to the last one from the same contact, within this long, is the same
  // message arriving twice - the second one is filed but never announced. ("Pretty sure I'm
  // getting more than one notification per message.")
  public static func PhoneRepeatGuardSeconds() -> Float = 12.0

  // Messages waiting for a settled tick. More than this in one go is a burst, and the newest
  // are the ones worth a notification; the rest are still filed in their threads.
  public static func PhonePendingCap() -> Int32 = 6
  // In Phone mode, how long waiting messages hold their notification for a phone to attach after a load or a fast
  // travel, in real seconds. Past this they stay in their threads unannounced.
  public static func PhoneAttachWaitSeconds() -> Float = 45.0
  // Word getting around (CBPhone.Hearsay). Defaults for the two settings, used before Mod
  // Settings is up.
  public static func WordTravelMinutesDefault() -> Int32 = 180
  public static func InboxGapSecondsDefault() -> Int32 = 90
  public static func WordCalmSeconds() -> Float = 60.0
  // Word from further off takes one more travel time a district, up to this many (so at most three times as long).
  public static func WordMaxHops() -> Int32 = 2
  // How long a gang's people take to reach V, against the usual warning, by districts from their nearest streets
  // (CBArrivalTicks): on their own turf, two away, three or more.
  public static func ArrivalHomeMult() -> Float = 0.6
  public static func ArrivalFarMult() -> Float = 1.35
  public static func ArrivalAcrossCityMult() -> Float = 1.7
  // Cleared streets (Spawn/ClearedStreets.reds): this many of one gang dead in a fight clears them off this far round
  // the last body for this many in-game days; at most this many spots kept.
  public static func ClearKills() -> Int32 = 6
  public static func ClearRadius() -> Float = 70.0
  public static func ClearDays() -> Float = 3.0
  public static func ClearSpotsCap() -> Int32 = 24
  // Hangouts (Spawn/Hangouts.reds): looked for every this many ticks; on a gang's turf with none of theirs within this
  // range, this likely; this many of them, this far off; packed up past this distance or after this many hours.
  public static func HangoutLookTicks() -> Int32 = 120
  public static func HangoutScarceRange() -> Float = 120.0
  public static func HangoutChance() -> Float = 0.6
  public static func HangoutSize() -> Int32 = 3
  public static func HangoutDistance() -> Float = 60.0
  public static func HangoutLeaveDistance() -> Float = 300.0
  public static func HangoutHours() -> Float = 2.0
  // Gangs putting their price to V: one every this many in-game hours, the first this long after a load.
  public static func PeaceOfferSpacingHours() -> Float = 2.0
  public static func PeaceOfferFirstHours() -> Float = 0.5
  // The same gang's spoken warning, at most once in this many in-game hours; the warning itself still happens.
  public static func GangWarnLineHours() -> Float = 1.0
  // From this many of theirs dead, a gang's warning is about what V did to them, never its words for a stranger.
  public static func WarnKnowsYouKills() -> Int32 = 20
  // A story already told is not told again inside this many in-game hours. A cyberpsycho
  // episode is one massacre to the street, not one per lull in the shooting.
  public static func HearsayRepeatHours() -> Float = 6.0
  // Stories waiting at once, and how many recently told ones are remembered for that window.
  public static func HearsayQueueCap() -> Int32 = 24
  // Word still waiting this many in-game hours after it reached V's part of town is old news (CBPhone.ReleaseWord).
  public static func HearsayStaleHours() -> Float = 24.0
  public static func HearsayToldCap() -> Int32 = 32
  // The same contact sending the same words inside this many in-game hours is filed once.
  public static func PhoneDuplicateHours() -> Float = 1.0
  // Where Cyberbane's contacts sit in the phone's hash space.
  public static func PhoneHashBase() -> Int32 = 1128415233
  // Overheard lines: a line of the game's subtitles (UI/PhoneMessages.reds). With the game's subtitles switched off,
  // Cyberbane's own line is drawn where they would be.
  public static func OverheardSeconds() -> Float = 5.5
  public static func OverheardFloor() -> Float = 3.5
  public static func OverheardWidth() -> Float = 1100.0
  public static func OverheardBottom() -> Float = 120.0

  // ---- Keeping an arrival out of frame ---------------------------------
  //
  // There is deliberately not a second one here: the group anchor and the pursuit points are answering the same
  // question and had better answer it the same way.
  public static func SpawnInViewFarDistance() -> Float = 70.0
  // Eye height for the line-of-sight trace, so the ray clears a kerb and is stopped by a wall.
  public static func SpawnEyeHeight() -> Float = 1.5
  // Where on a standing body CBPointHiddenFrom aims its three rays, in metres above the ground
  // they stand on: shins, waist, the top of the head. All three blocked is hidden.
  public static func HiddenRayLow() -> Float = 0.4
  public static func HiddenRayMid() -> Float = 1.0
  public static func HiddenRayHigh() -> Float = 1.75

  // ---- Apex strength ----
  // Percentage of a boss-grade build, used when settings have not loaded yet.
  public static func ApexStrengthDefault() -> Int32 = 55
  // How much of its own contribution Cyberbane keeps when New Game Plus is also buffing NPCs.
  public static func ApexNgpStepDown() -> Float = 0.5
  // Size of one random trait, as a fraction added on top of the stat it touches.
  public static func ApexTraitStrength() -> Float = 0.25
  public static func ApexPowerLevelBonus() -> Float = 2.0
  // How many enforcers turn up when a gang sends its apex by car. A full car of them is the
  // set piece; the strength slider is what tunes how hard each one hits.
  public static func ApexStrikeTeamSize() -> Int32 = 4
  // How long the Hub keeps counting while an apex squad is driving to you. Longer than a drive
  // usually takes, because it is cleared the moment they actually arrive.
  public static func ApexDriveTicks() -> Int32 = 90

  // ---- Rival ladder ----
  // Escapes, mercies and ranks it takes for a Rival to reach full apex grade.
  public static func RivalLadderSteps() -> Int32 = 6
  // What a Rival is worth the first time you meet them, as a fraction of an apex.
  public static func RivalGradeFloor() -> Float = 0.45
  // How far up the ladder a Rival has to be before they get the boss bar.
  public static func RivalBossBarGrade() -> Float = 0.0

  // ---- Brokering peace (spec 11.3) ----
  public static func PeaceBaseCost() -> Int32 = 1000
  public static func PeacePerKill() -> Int32 = 50
  // Added at the bottom of the standing scale, where they hate you most.
  public static func PeacePerHate() -> Int32 = 6000
  // A vendetta is a decision already taken, so taking it back costs more.
  public static func PeaceVendettaMult() -> Float = 2.0
  public static func PeaceMaxCost() -> Int32 = 40000

  // ---- On-screen messages ----
  // Percent of the requested duration, used before settings have loaded.
  public static func MessageHoldDefault() -> Int32 = 175
  // Nothing is shown for less than this, however short the caller asked for.
  public static func MessageMinSeconds() -> Float = 5.0
  // The card on screen keeps its whole time and the next waits behind it (UI/Notify.reds): at most this many in line,
  // each dropped once it has waited this long; and no card is ever up longer than this, so a clock that reads past it
  // is from before a load.
  public static func CardQueueCap() -> Int32 = 3
  public static func CardStaleSeconds() -> Float = 20.0
  public static func MessageMaxSeconds() -> Float = 60.0
  // A card is taken down this long after the game should have faded it, if it has not (UI/Notify.reds).
  public static func MessageClearSlackSeconds() -> Float = 2.0   // past the game's fade, so a card that did go is never cut short

  // ---- Vendetta hit squads ----
  // Smallest share of the full crew that turns out, before menace scales it up.
  public static func VendettaSquadFloorFraction() -> Float = 0.6
  public static func VendettaSquadSizeDefault() -> Int32 = 20

  // ---- Who comes next (spec 9.9) ---- How much each kind of contender wants the next turn.
  public static func QueueScoreVendetta() -> Float = 100.0
  public static func QueueScoreApex() -> Float = 85.0
  public static func QueueScoreRival() -> Float = 55.0
  public static func QueueScoreHostile() -> Float = 40.0
  // Taken off a contender of the same kind as the last one, so one gang cannot monopolise you
  // while a Rival waits forever.
  public static func QueueRepeatPenalty() -> Float = 25.0
  // Nothing arrives sooner than this after being queued, whatever the frequency setting.
  public static func QueueMinTicks() -> Int32 = 60
  // How long a gang takes to put its apex squad together once they are owed one.
  public static func ApexQueueTicks() -> Int32 = 180
  // Minutes a lane rests after its encounter ends, before it looks for anybody new.
  public static func EncounterGapMinutesDefault() -> Int32 = 10
  // What one in-game day holds, per kind. Three Rivals, two crews and two apex squads is a day with a shape to it: busy
  // enough that the city is clearly after you, bounded enough that it ends.
  public static func FirstSlotMaxWaitHours() -> Float = 0.5
  public static func RivalsPerDayDefault() -> Int32 = 8
  public static func HitSquadsPerDayDefault() -> Int32 = 5
  public static func ApexSquadsPerDayDefault() -> Int32 = 4
  // How long a lane stays busy after sending somebody, to cover the gap between asking for a
  // spawn and it existing. Short, and a hard count rather than a wait on an attach.
  public static func LaneSettleTicks() -> Int32 = 8
  // Between two different kinds of arrival. Only one car can board at a time, so a second one sent
  // inside this window lost its car and walked.
  public static func LaneCrossGapTicks() -> Int32 = 45

  // ---- Keeping a chase alive ----
  // How often to remind anybody of ours who has fallen behind, and how far behind they have to be
  // before it is worth doing.
  public static func ChaseRefreshEveryTicks() -> Int32 = 6
  public static func ChaseRefreshMinDistance() -> Float = 18.0
  // Cap per pass, so a twenty-strong crew never turns one tick into twenty AI commands.
  public static func ChaseRefreshPerPass() -> Int32 = 8
  // Get this far from every one of them, and stay there this long, and they lose you. Roughly
  // what the police in this game give you, and the reason a chase is a chase and not a leash.
  public static func ChaseLoseDistance() -> Float = 120.0
  public static func ChaseLoseTicks() -> Int32 = 22
  // How long an ordinary hostile gang takes to put a crew together, at its slowest and its fastest. Scaled between the
  // two by how much they hate you and how well they know you. The warning window once a lane picks somebody.
  public static func HostileSquadTicksMin() -> Int32 = 90
  public static func HostileSquadTicksMax() -> Int32 = 240
  // How well a gang has to know you before they bother sending anyone.
  public static func HitSquadMinRenown() -> Float = 25.0

  // ---- Faction apex enforcer (spec §9.9) ------------------------------- Bodies from one gang before they stop
  // sending squads and send someone who matters.
  public static func ApexKillThreshold() -> Int32 = 20
  // Fast ticks between the warning and the apex actually walking in (~seconds), so the line lands before they do
  // instead of alongside them. Fast ticks between the warning and the apex arriving.
  public static func ApexWarningTicks() -> Int32 = 45
  public static func ApexSpawnDistance() -> Float = 90.0
  // Muscle that comes in with them. Built from the gang's rank-and-file record.
  public static func ApexEscortCount() -> Int32 = 2
  // How long, in fast ticks, an apex squad that arrived short keeps walking in its missing
  // chairs (Spawn/FactionApex.reds, CBApexMusterTick).
  public static func ApexMusterTicks() -> Int32 = 120
  // The apex is built from a gang archetype, which on its own is nowhere near a boss, so the spawned one is lifted to
  // boss grade.
  public static func ApexHealthMultBase() -> Float = 1.6
  public static func ApexHealthMultRange() -> Float = 1.4     // 1.6x .. 3x before strength
  public static func ApexArmorMultBase() -> Float = 1.2
  public static func ApexArmorMultRange() -> Float = 0.5      // 1.2x .. 1.7x
  // What they hit back with. Deliberately the gentlest of the three: a gang enforcer that one
  // shots you is not a fight either, and the player is the one with no health multiplier.
  public static func ApexDamageMultBase() -> Float = 1.15
  public static func ApexDamageMultRange() -> Float = 0.35    // 1.15x .. 1.5x
  public static func ApexCritChanceBonus() -> Float = 8.0
  public static func ApexCritDamageBonus() -> Float = 20.0

  // The ceilings. Nothing Cyberbane does to an NPC may take a stat past these, whatever the
  // slider, the menace, the traits, the ladder and the role add up to.
  public static func ApexHealthMultCeiling() -> Float = 3.0
  // Apex squads, Rivals and named hunters matched to V (Spawn/MeasureV.reds): each takes this many seconds of V's
  // steady fire at a middling strength (half again at 100, half at 0), answers this share of V's armour, and never
  // passes these ceilings.
  public static func ApexMatchSeconds() -> Float = 6.0
  public static func RivalMatchSeconds() -> Float = 10.0
  // ICE an enemy brings against a netrunner V, at a full answer.
  public static func CounterIce() -> Float = 30.0
  // Evasion (the share of hits that do nothing at all, which the game rolls for every target, damageSystem.script
  // ProcessEvasion) an enemy brings against a quick V, at a full answer.
  public static func CounterEvasion() -> Float = 8.0
  public static func ApexArmourAnswer() -> Float = 0.5
  public static func ApexMatchHealthCeiling() -> Float = 15.0
  public static func ApexMatchDamageCeiling() -> Float = 2.5
  // Adam Smasher's scaling, shared out (CBSmasherScale): an apex squad member gets this share of his health and damage
  // multipliers at the lowest and the highest Apex strength; a Rival this share, times how far up they are.
  public static func ApexSmasherShareMin() -> Float = 0.15
  public static func ApexSmasherShareMax() -> Float = 0.4
  public static func RivalSmasherShareMin() -> Float = 0.2
  public static func RivalSmasherShareMax() -> Float = 0.5
  public static func SmasherCeilingShare() -> Float = 0.6
  public static func SmasherDamageScale() -> Float = 0.7
  public static func ApexHitCapAtMin() -> Float = 25.0
  public static func ApexHitCapAtMax() -> Float = 10.0
  public static func RivalHitCapTop() -> Float = 8.0
  public static func ApexArmorMultCeiling() -> Float = 1.8
  // Nobody Cyberbane sends is beyond V's reach (Spawn/Killable.reds): the finished body carries no more effective
  // health (health, and what armour multiplies it by) than this many seconds of V's measured damage, from the lowest to
  // the highest Rival, for an apex squad, and for anybody else Cyberbane builds; KillableBlindMult times what it
  // carried before the build when V's damage cannot be read.
  public static func GangHomeReach() -> Float = 150.0
  public static func GangHomeStepOut() -> Float = 60.0
  // The crew at home (Reactions/CrewHome.reds): the stash counts as the armory within ArmoryReach of V, and the watch
  // takes up a fight of Cyberbane's within GuardDefendRange of its post.
  public static func ArmoryReach() -> Float = 25.0
  // The crew at work (Reactions/CrewJobs.reds).
  public static func CrewJobPerRank() -> Float = 0.06
  public static func CrewHitBase() -> Float = 0.30
  public static func CrewHitPerRivalRank() -> Float = 0.08
  public static func CrewHitFlawBonus() -> Float = 0.15
  public static func CrewHitMinRank() -> Int32 = 3
  public static func CrewHitHoursBase() -> Float = 4.0
  public static func CrewHitWoundShare() -> Float = 0.45
  public static func CrewJobDeathBase() -> Float = 0.40
  public static func CrewJobHurtHours() -> Float = 12.0
  public static func CrewBagBase() -> Float = 0.40
  public static func CrewBagMinRank() -> Int32 = 2
  public static func CrewBagHours() -> Float = 3.0
  public static func CrewBagTakeBase() -> Int32 = 600
  public static func CrewBagTakePerRank() -> Int32 = 250
  public static func CrewBagMemberShare() -> Float = 0.2
  public static func CrewBagKnownChance() -> Float = 0.4
  public static func CrewBagDeathChance() -> Float = 0.1
  public static func CrewDuelBase() -> Float = 0.35
  public static func CrewDuelHours() -> Float = 2.0
  public static func CrewDuelFear() -> Float = 4.0
  public static func CrewDuelStanding() -> Float = 4.0
  public static func CrewDuelStandingCeiling() -> Float = 50.0
  public static func CrewDuelChancePerDay() -> Float = 0.25
  public static func CrewDuelAnswerHours() -> Float = 24.0
  public static func CrewDuelGapDays() -> Float = 3.0
  public static func CrewDuelRefuseFear() -> Float = 3.0
  // The money run: every CrewRunDays, jumped CrewRunJumpBase of the time, more when a gang thinks CrewRunHatedBelow or
  // worse of the crew, less for each runner beyond the first.
  public static func CrewRunDays() -> Float = 2.0
  public static func CrewRunJumpBase() -> Float = 0.10
  public static func CrewRunHatedBelow() -> Int32 = -40
  public static func CrewRunJumpHated() -> Float = 0.15
  public static func CrewRunJumpPerExtra() -> Float = 0.05
  // Goods: GoodsShare of robbed bags, worth GoodsWorthMult of the cash, losing GoodsStalePerDay of it a day and gone
  // after GoodsLifeDays. Sold back to their owners for GoodsSellBackShare, to their sworn enemies for GoodsEnemyMult.
  public static func SignatureRank() -> Int32 = 3
  public static func LootIconicSignatureBonus() -> Float = 0.10
  // Strongholds (Rivals/Strongholds.reds): a Rival of StrongholdMinRank or more takes a cleared base, at most
  // StrongholdMax in the city, for StrongholdDays; the garrison is placed within StrongholdReach and goes past
  // StrongholdLeave; StrongholdSize in all, only with StrongholdMinRoom free.
  public static func StrongholdMinRank() -> Int32 = 3
  public static func StrongholdMax() -> Int32 = 2
  public static func StrongholdDays() -> Float = 7.0
  public static func StrongholdChancePerDay() -> Float = 0.25
  public static func StrongholdReach() -> Float = 150.0
  public static func StrongholdLeave() -> Float = 250.0
  public static func StrongholdMinRoom() -> Int32 = 6
  public static func StrongholdSize() -> Int32 = 8
  public static func StrongholdBaseCap() -> Int32 = 60
  public static func StrongholdGangLoss() -> Float = 8.0
  public static func StrongholdTurfLoss() -> Float = 25.0
  public static func StrongholdPay() -> Int32 = 5000
  public static func StrongholdLtGrade() -> Float = 0.8
  // A cleared stronghold's stash is laid once the fight is over and V is this close to where they kept it.
  public static func StrongholdStashReach() -> Float = 60.0
  // Two cleared gigs this close are one place: a gig played again is not a second base.
  public static func StrongholdSameSite() -> Float = 40.0
  // How near V a spot has to be for the Badlands part V stands in to name it (CBPlacePhrase).
  public static func SubDistrictNear() -> Float = 400.0
  // An add-on's convoy (API/Convoy.reds): put on the road once V is this near where it is on paper; a route point
  // counts as reached this close; escorts this far behind the lead (each further one four metres more); and the ticks
  // its crews have to board before it drives anyway.
  public static func ConvoyReach() -> Float = 300.0
  public static func ConvoyPointReach() -> Float = 25.0
  public static func ConvoyGapMin() -> Float = 6.0
  public static func ConvoyGapMax() -> Float = 18.0
  public static func ConvoyBoardTicks() -> Int32 = 20
  // A convoy in a fight that V has been out of reach of for this many ticks got away.
  public static func ConvoyGotAwayTicks() -> Int32 = 60
  // API level 2: CBListener.OnTick every this many settled ticks (about two seconds); add-on vehicles out at once;
  // how near V an add-on's loot can be laid, metres.
  public static func ApiListenerTickEvery() -> Int32 = 2
  public static func ApiVehicleMax() -> Int32 = 4
  public static func ApiLootReach() -> Float = 100.0
  // Much Better Contracts: at most this many of its completed contracts counted as jobs at one look, so a count that
  // jumps for any other reason (its own history repair) cannot pour Renown in.
  public static func MbcJobsPerLook() -> Int32 = 3
  public static func GoodsShare() -> Float = 0.3
  public static func GoodsWorthMult() -> Float = 1.4
  public static func GoodsStalePerDay() -> Float = 0.2
  public static func GoodsLifeDays() -> Float = 4.0
  public static func GoodsSellBackShare() -> Float = 0.5
  public static func GoodsEnemyMult() -> Float = 1.5
  public static func GoodsBackStanding() -> Float = 4.0
  public static func GoodsBuyerStanding() -> Float = 3.0
  public static func GoodsOwnerStanding() -> Float = 3.0
  public static func GuardDefendRange() -> Float = 40.0
  // How far apart two of the watch stand at one post (2.7.9).
  public static func GuardSpacing() -> Float = 2.5
  public static func KillableRivalSecondsLow() -> Float = 15.0
  public static func KillableRivalSecondsTop() -> Float = 30.0
  public static func KillableApexSeconds() -> Float = 24.0
  public static func KillableCrewSeconds() -> Float = 12.0
  public static func KillableBlindMult() -> Float = 4.0
  public static func KillableArmourFactor() -> Float = 4.0
  public static func KillableWatchWindow() -> Float = 0.5
  public static func KillableUndoneShare() -> Float = 0.5
  public static func KillableBurstSeconds() -> Float = 0.1
  public static func ApexDamageMultCeiling() -> Float = 1.6
  public static func ApexCritChanceCeiling() -> Float = 15.0
  public static func ApexCritDamageCeiling() -> Float = 40.0
  // Power level is the one term that moves every other stat at once, which is why ten of them
  // was a mistake rather than a tuning choice. Two keeps the "fights above its station" read
  // without hiding a multiplier inside it.
  public static func ApexPowerLevelCeiling() -> Float = 3.0

  // ---- Rivals (spec §10.2, §10.7, Appendix A) -------------------------- Rivals only land if they actually happen.
  public static func RivalChanceSurvivor() -> Float = 0.6
  public static func RivalChanceSpared() -> Float = 0.6
  public static func RivalBurstTicks() -> Int32 = 300
  public static func RivalOddsCeiling() -> Float = 0.95
  // A Rival a fight makes is made once V has been out of combat this many settled ticks (about seconds), chosen afresh
  // for each (Rivals/Births.reds). And how many may wait at once.
  public static func RivalBirthCalmMin() -> Int32 = 30
  public static func RivalBirthCalmMax() -> Int32 = 60
  public static func RivalBirthQueueCap() -> Int32 = 6
  // Hostile to V and not by Cyberbane (Reactions/Director.reds, NoteForeignHostility): how often one NPC's attitude is
  // read, how long a sighting stops the faction being read again, and how long the Gangs screen goes on saying so, all
  // in settled ticks (about seconds).
  public static func ForeignHostileReadTicks() -> Int32 = 10
  public static func ForeignHostileFreshTicks() -> Int32 = 60
  public static func ForeignHostileShowTicks() -> Int32 = 1800
  // A spared cyberpsycho is a coin flip, and nothing else about them is left to chance: they
  // come back with their own name, their own health and no multiplier on top of it.
  public static func CyberpsychoRivalChance() -> Float = 0.50
  // How far a gang's opinion of V moves when one of theirs puts V down. Standing is V's
  // footing with them, so beating V costs V footing: they have seen that it can be done.
  public static func DeathStandingDrop() -> Float = 6.0
  // Killing an Officer or Boss: somebody of theirs takes it personally. Weighed by rank like the rest, so an officer is
  // 50% and a boss 60%.
  public static func RivalChanceAvenger() -> Float = 0.40
  public static func RivalChanceHunter() -> Float = 0.50
  // How long a Rival takes to track you down, in fast ticks (roughly seconds). A higher rank has better information and
  // finds you sooner.
  public static func RivalHuntTicksBase() -> Int32 = 240
  public static func RivalHuntTicksPerRank() -> Int32 = 35
  public static func RivalHuntTicksMin() -> Int32 = 75
  // When the clock runs out but V is mid-fight or another Rival is already out, wait this
  // many ticks and try again rather than dropping the appointment.
  public static func RivalHuntRetryTicks() -> Int32 = 20
  // How long to wait before checking that a queued Rival actually appeared. Long enough for
  // an out-of-view spawn to be honoured once V has moved or turned.
  public static func RivalArrivalCheckTicks() -> Int32 = 10
  // A Rival sent by car is created once the car is in the world and boarding. This is how long
  // that may take before the car counts as a no-show; the drive itself comes after and is the
  // dismount watch's business (Spawn/Arrival.reds).
  public static func RivalCarArrivalCheckTicks() -> Int32 = 40
  // A Rival's traits: each moves one build term by this fraction (CBRivalTraitTerms), inside
  // the same ceilings as everything else. Deadeye adds this much crit chance.
  public static func RivalTraitStep() -> Float = 0.15
  public static func RivalTraitCrit() -> Float = 6.0
  // A Pack Leader brings this many of their own with them.
  public static func PackLeaderEscort() -> Int32 = 2
  // Escorts for a Rival holding a chair in their gang's crew (Spawn/RivalEncounter.reds).
  public static func LeaderEscort() -> Int32 = 2
  public static func LieutenantEscort() -> Int32 = 1
  // How far up the Rival queue a Grudge-Bearer jumps.
  public static func QueueGrudgeBonus() -> Float = 10.0
  // These are the other roads.
  public static func NonLethalStandingShare() -> Float = 0.1
  // The share of a kill's Dread that putting somebody down alive adds (Model/Reputation.reds).
  public static func NonLethalDreadShare() -> Float = 0.25
  // What each one of theirs V leaves alive is worth to them, and how far that alone can carry. At this rate Friendly
  // (15) is a long run of restraint and nothing better - mercy makes a gang tolerate V, it does not make them allies.
  public static func MercyCredit() -> Float = 0.4
  public static func MercyCeiling() -> Float = 20.0
  // Letting a named Rival of theirs walk is worth more than sparing a nobody.
  public static func MercyRivalCredit() -> Float = 3.0

  // Gangs at war (Model/GangRivalries.reds).
  public static func RivalGangShare() -> Float = 0.5
  public static func RivalGangCeiling() -> Float = 75.0
  // A gang V has killed members of can like V's enemies' enemies only so far: just short of Allied.
  public static func RivalGangCeilingBloodied() -> Float = 45.0
  // And none of it for a while after V last hurt them. Nobody thanks you with their friend's blood on you.
  public static func GangGrudgeHours() -> Float = 48.0
  // What vendors on a gang's turf do about where V stands with that gang.
  public static func TurfAlliedDiscount() -> Float = 0.08
  public static func TurfFriendlyDiscount() -> Float = 0.04
  public static func TurfHostileSurcharge() -> Float = 0.06

  // ---- The hunt (Spawn/Hunt.reds) ----------------------------------------
  // How far off the tip a hunt starts with can be, in metres.
  public static func HuntTipError() -> Float = 25.0
  // The ring closing on the last known position: wide at first, tight after HuntNarrowTicks.
  public static func HuntSearchRadiusStart() -> Float = 40.0
  public static func HuntSearchRadiusMin() -> Float = 8.0
  public static func HuntNarrowTicks() -> Int32 = 45
  // How far a searcher's point may fall outside the ring before they are sent on to a new one.
  public static func HuntRingSlack() -> Float = 10.0
  // Farther than this from the search and they cross the ground at a sprint.
  public static func HuntSprintDistance() -> Float = 30.0
  // When nowhere in the ring can be routed to from where they are, a hop this long towards it.
  public static func HuntHopDistance() -> Float = 35.0
  // How often searchers are looked at to see whether they need somewhere new to look
  // (Spawn/Hunt.reds, CBHuntNeedsNewPoint). They are not given a new point every time.
  public static func HuntSearchOrderTicks() -> Int32 = 3
  // Seeing V: close with nothing in the way, or already fighting within this range.
  public static func HuntSpotDistance() -> Float = 35.0
  public static func HuntCombatKnowsDistance() -> Float = 80.0
  // Once the hunt has found V, everybody of ours this close is told where V is and joins the
  // fight (Spawn/Hunt.reds, CBHuntEngage). The rest keep converging and join as they close in.
  public static func HuntEngageDistance() -> Float = 90.0
  // How far from V a door still counts as V's door. Big enough for the far end of a bar.
  public static func SanctuaryDoorReach() -> Float = 40.0
  // Hearing V: a kill or a firefight this close to a hunter.
  public static func HuntHearDistance() -> Float = 70.0
  // Unseen this long and they go back to searching; unseen this long while searching, they quit.
  public static func HuntLostTicks() -> Int32 = 10
  public static func HuntGiveUpTicks() -> Int32 = 150
  // Lead time between being told and them arriving.
  public static func CrewWarningTicks() -> Int32 = 45
  public static func RivalWarningTicks() -> Int32 = 40
  // A provoked gang's crew comes now; the provocation counts for this long.
  public static func ProvokeTicks() -> Int32 = 240
  // How many times a delayed callback waits for the world to settle before giving up. At the
  // retry intervals used (0.4 to 2 seconds) this covers a long load or fast travel.
  public static func CallbackStableWaits() -> Int32 = 60
  // Seconds between a car or its crew attaching and Cyberbane touching them (Spawn/Arrival.reds).
  public static func ConvoyStepDelay() -> Float = 0.6
  // A crew stays in a car going faster than this, in metres per second.
  public static func ArrivalDismountMaxSpeed() -> Float = 3.0
  // Our dead and our spent cars are cleared once V is at least this far from them, or they have
  // streamed out (Spawn/Spawner.reds, CBSweepRemains).
  public static func RemainsSweepDistance() -> Float = 70.0
  // While V is still in a fight, somebody lying there (dead, or down and breathing) stays within this many metres of V
  // whether V can see them or not (CBRemainsInReach): the fight can move across a street and back.
  public static func RemainsFightDistance() -> Float = 150.0
  public static func RemainsCap() -> Int32 = 96
  // The most of Cyberbane's people alive in the world at once (Spawn/Spawner.reds, CBSpawnGroup).
  public static func MaxLiveSpawns() -> Int32 = 18
  // Within this many metres of the tracked objective's map pins, V is on a job (Core/SafeAreas.reds).
  public static func QuestAreaRadius() -> Float = 80.0
  // Nobody is placed, and no NPC is pushed, within this many metres of a tracked objective's pin,
  // wherever V is standing (Core/SafeAreas.reds).
  public static func QuestSpawnClearance() -> Float = 60.0
  // Removals happen out of V's sight, or beyond this distance (Spawn/Spawner.reds, CBOutOfView).
  public static func VanishSafeDistance() -> Float = 150.0
  // One of ours in combat with V but farther than this and out of sight for this many seconds is
  // let go, so the fight can end (Spawn/Hunt.reds, CBCombatReleaseTick).
  public static func CombatReleaseDistance() -> Float = 45.0
  public static func CombatReleaseTicks() -> Int32 = 30
  // Metres closer since the last two-second pass that counts as still coming.
  public static func CombatReleaseClosing() -> Float = 2.0
  // Somebody cut off from V (Spawn/Hunt.reds, CBCutOffTick).
  public static func CutOffPassTicks() -> Int32 = 3
  public static func CutOffRoam() -> Float = 6.0
  public static func CutOffPathsPerPass() -> Int32 = 4
  public static func CutOffQuietTicks() -> Int32 = 21
  public static func CutOffTicks() -> Int32 = 45
  // A walking route (CBPointReachable). Further than that it is another level of the city, not a way here.
  public static func PathEndTolerance() -> Float = 5.0
  public static func PathDetourMax() -> Float = 3.0
  public static func PathDetourSlack() -> Float = 40.0
  // A ceiling (CBPointCovered): rays this far apart, from this far above the point to this far,
  // and how many of the five have to hit. High enough for a car park, a tunnel or a warehouse.
  public static func CeilingRaySpread() -> Float = 3.0
  public static func CeilingRayStart() -> Float = 2.0
  public static func CeilingRayEnd() -> Float = 10.0
  public static func CeilingRaysNeeded() -> Int32 = 4
  // How much a gang's own clothes slow that gang down, as a share of the chance they place V.
  public static func GangColoursDisguise() -> Float = 0.35

  // ---- Loot and bounties (Spawn/Loot.reds) --------------------------------
  public static func LootDelaySeconds() -> Float = 0.8
  public static func LootCrewChance() -> Float = 0.5
  public static func LootLegendaryChanceApex() -> Float = 0.25
  public static func LootLegendaryChanceTop() -> Float = 0.4
  // A small chance per apex member, and per top-ranked Rival or crew leader, of an iconic.
  public static func LootIconicChanceApex() -> Float = 0.05
  public static func LootIconicChanceRival() -> Float = 0.1
  public static func BountyRivalPerRank() -> Int32 = 1500
  public static func BountyLeaderBonus() -> Int32 = 3000
  public static func BountyApexSquad() -> Int32 = 9000
  // A bounty reaches V this many in-game hours after the deed (Spawn/Loot.reds, CBPayoutBook): word has to get round to
  // whoever wanted it done first.
  public static func PayoutHoursMin() -> Float = 2.0
  public static func PayoutHoursMax() -> Float = 4.0

  // ---- Difficulty (Spawn/FactionApex.reds, CBDifficultyStepDown) -------------
  public static func ApexHardStepDown() -> Float = 0.85
  public static func ApexVeryHardStepDown() -> Float = 0.7

  // ---- What it takes (Spawn/Queue.reds) -------------------------------------------
  // A gang sends a crew when it has a reason: a vendetta, V provoking them, V hanging around on
  // their turf, or trouble with V inside this many in-game hours.
  public static func CrewReasonHours() -> Float = 12.0
  public static func QueueTurfBonus() -> Float = 20.0
  public static func QueueRecentBonus() -> Float = 15.0
  public static func RivalTurfBonus() -> Float = 12.0
  // Seconds (ticks) on a hostile gang's turf before a lookout calls V in, and how long before
  // the next lookout can.
  public static func TurfLingerTicks() -> Int32 = 150
  public static func TurfSpotCooldownTicks() -> Int32 = 1500
  // An apex squad comes after V beats one of the gang's crews, or after this many times the
  // usual kill count with no crew in between.
  public static func ApexMassacreMultiplier() -> Int32 = 2

  // ---- Pacing without a clock (Spawn/Queue.reds) ------------------------------------
  // Countdowns and warnings vary by this fraction either way.
  public static func QueueJitterFraction() -> Float = 0.4
  public static func WarningJitterFraction() -> Float = 0.35
  // Unpredictable pacing: a lane's daily allowance spread over about this many seconds.
  public static func UnpredictableDayTicks() -> Int32 = 10800
  public static func NightPacingMult() -> Float = 1.3
  public static func DayPacingMult() -> Float = 0.85
  public static func NightStartHour() -> Float = 21.0
  public static func NightEndHour() -> Float = 5.0

  // ---- Scouts (Spawn/Hunt.reds) ----------------------------------------------------
  public static func ScoutChance() -> Float = 0.5
  // Seconds of eyes on V before the scout calls the crew in.
  public static func ScoutCallTicks() -> Int32 = 6
  // A scout is only sent when the gang has not had trouble with V for this many in-game hours.
  public static func ScoutFreshHours() -> Float = 2.0
  // How long a scout may take to appear before the crew comes anyway.
  public static func ScoutSpawnGraceTicks() -> Int32 = 25

  // ---- Cat and mouse (Spawn/Hunt.reds) ---------------------------------------------
  // Seconds a hunter has to keep V in sight before the hunt counts V as found.
  public static func SpotConfirmTicks() -> Int32 = 2
  public static func CrouchSenseMult() -> Float = 0.6
  public static func NightSenseMult() -> Float = 0.75
  public static func DisguiseSenseMult() -> Float = 0.5
  // A searcher is given a new point once this close to the one they were sent to, or once the
  // run has gone on this many seconds.
  public static func HuntSearchArrivedDistance() -> Float = 5.0
  public static func HuntSearchPointMaxTicks() -> Int32 = 12
  // Tries for a walkable search point before falling back to the middle of the search.
  public static func HuntSearchPointTries() -> Int32 = 8
  // How far above or below the middle of the search a search point's floor may be.
  public static func HuntSearchMaxDrop() -> Float = 6.0
  // Before anybody has found V, how far the tip firms up towards the street's word on V once the
  // search has fully narrowed (0 never, 1 all the way), and how often that word is refreshed.
  public static func HuntTipFirmUp() -> Float = 1.0
  public static func HuntTipWordTicks() -> Int32 = 6
  // How long after a car of ours was last seen on its way its crew still count as coming, not
  // left behind, while none of them is in the world.
  public static func CarWatchGraceTicks() -> Int32 = 15
  public static func HuntGiveUpJitter() -> Int32 = 60
  // How long the HUD line says how a hunt ended.
  public static func HuntEndLineTicks() -> Int32 = 6
  // Seconds with nobody out and nobody on the way before a hunt counts as over.
  public static func HuntIdleEndTicks() -> Int32 = 8

  // ---- Rewards and costs -----------------------------------------------------------
  // Loot counts grow by up to this fraction at level 60.
  public static func LootLevelScaleMax() -> Float = 1.0
  public static func CrewEddiesMin() -> Int32 = 40
  public static func CrewEddiesMax() -> Int32 = 120
  public static func BountyCrew() -> Int32 = 2500
  // Renown lost with a gang whose crew or apex squad V ran from.
  public static func RunRenownLoss() -> Float = 3.0

  // ---- Difficulty (per step above Easy: Hard is one, Very Hard two) ------------------
  public static func DifficultyCrewTrim() -> Int32 = 1
  public static func DifficultySpawnExtra() -> Float = 10.0
  public static func DifficultySenseStep() -> Float = 0.1
  public static func DifficultyWarningExtra() -> Int32 = 10
  // Damage bonus kept when a combat overhaul that already makes enemies deadlier is installed.
  public static func OverhaulDamageKeep() -> Float = 0.6
  public static func RivalHomeBonus() -> Float = 10.0
  // Longest name the HUD line shows before cutting it short.
  public static func HudNameMaxChars() -> Int32 = 22
  public static func HudLineMaxChars() -> Int32 = 76
  // TRACKED shows on the HUD line only in the last stretch before somebody sets off.
  public static func TrackedShowTicks() -> Int32 = 120
  // At most one "asking around" notice per lane in this many seconds.
  public static func TrackNoticeGapTicks() -> Int32 = 600
  public static func QueueProvokedBonus() -> Float = 40.0
  // Spread added to each Rival's countdown so two of the same rank do not arrive together.
  public static func RivalHuntJitterTicks() -> Int32 = 120
  // How long a Rival may stand around before Cyberbane gives up on the encounter, in in-game
  // seconds. In-game time runs far faster than real time, so this is a couple of real minutes.
  public static func RivalRetireGameSeconds() -> Float = 7200.0
  // Once you are carrying as many Rivals as the cap allows, no new ones can be made, so the
  // only way out is to put the existing ones down. They close in at this fraction of the
  // normal wait until you have cleared some room.
  public static func RivalCapHurryMult() -> Float = 0.45
  // How long a Rival you escaped takes to find you again. Long enough that getting away is a
  // real outcome rather than a pause, which is what makes sparing and escaping worth anything.
  public static func RivalAfterEscapeTicks() -> Int32 = 900
  // Bodies remembered as a Rival's after their encounter ended (CBCloseRivalEncounter). One Rival is
  // out at a time, so a handful covers anything V could still walk back to.
  public static func FormerRivalBodyCap() -> Int32 = 8
  public static func RivalMaxActiveHardCap() -> Int32 = 15
  public static func RivalMaxPerFaction() -> Int32 = 3

  // ---- Collection caps (spec §6.5) -------------------------------------
  public static func CapRumors() -> Int32 = 64
  public static func CapLog() -> Int32 = 200
  public static func CapArchivedRivals() -> Int32 = 32
  public static func CapAppliedLedgerIds() -> Int32 = 100
  public static func CapLedgerTotal() -> Int32 = 100
  public static func CapLedgerPerPlaythrough() -> Int32 = 30
  public static func CapPeaceDeals() -> Int32 = 16
  // In the global service (Core/CyberbaneService.reds), shared by every save.
  public static func CapForgetNotes() -> Int32 = 32
  public static func CapRetiredIds() -> Int32 = 64
  public static func CapSightings() -> Int32 = 48
  // Pins gathered from every active objective (CBRefreshJobPins). A full journal has a few dozen.
  public static func JobPinCap() -> Int32 = 64
  // A crew this size or bigger brings a netrunner along (Spawn/HitSquad.reds).
  public static func NetrunnerSeatMinCrew() -> Int32 = 3
  // Rivals teaming up: how often a Rival who comes brings others of their gang who are free, when the setting is on;
  // more often for one who holds a chair in the gang's crew or leads a pack.
  public static func RivalTeamUpChance() -> Float = 0.3
  public static func RivalTeamUpChanceLeader() -> Float = 0.2
  public static func RivalTeamSpacing() -> Float = 8.0
  // How many of V's clothing items the attached-clothing read looks through (Signals/Concealment.reds).
  // A wardrobe of a few hundred is common; this only bounds a pathological one.
  public static func WornScanCap() -> Int32 = 600
  // Cyberpsychotic breaks: only a rank 4 Rival, a chance on each loss to V that grows with how many there have been,
  // never more than the ceiling.
  public static func PsychoBreakBase() -> Float = 0.08
  public static func PsychoBreakPerLoss() -> Float = 0.05
  public static func PsychoBreakMax() -> Float = 0.45
  // Rivals forgotten one at a time, kept in the service for every save of their playthrough.
  public static func CapForgottenRivals() -> Int32 = 64
  public static func CapGangPower() -> Int32 = 96
  // Which V each playthrough id belongs to. One per playthrough that has loaded since.
  public static func CapBirths() -> Int32 = 128
  public static func CapTalkTallies() -> Int32 = 120

  // ---- Street talk (Reactions/StreetTalk.reds) ---- The prompt: how often it is looked at, how close and for how long
  // V has to look at somebody, how far they may drift and how long V may glance away before it goes, and how long
  // before the same person can be spoken to again (fast ticks, about a second each).
  public static func TalkTickSeconds() -> Float = 0.2
  // How long street talk's list holds through the game's clears without talk's tick renewing it. Five ticks: talk
  // renews it every tick, so this only runs out if talk itself has stopped.
  public static func TalkListHoldSeconds() -> Float = 1.0
  // How long a text takes to land (UI/PhoneMessages.reds, CBPhone.Post), in real seconds. An answer to V: a base and a
  // little more for each letter, between the two bounds. Anything else: a reaction.
  public static func TextTypingBase() -> Float = 3.0
  public static func TextTypingPerChar() -> Float = 0.06
  public static func TextTypingMin() -> Float = 4.0
  public static func TextTypingMax() -> Float = 16.0
  public static func TextReactMin() -> Float = 8.0
  public static func TextReactMax() -> Float = 25.0
  // Urgent: the crew answering a call, somebody on V right now, "they're here". They land on the next tick or two,
  // never behind the gossip already queued: "On my way" came after the crew was already fighting.
  public static func TextUrgentMin() -> Float = 0.3
  public static func TextUrgentMax() -> Float = 1.2
  public static func TextGapMin() -> Float = 3.0
  public static func TextGapMax() -> Float = 7.0
  // How far from V the people of the gang V is talking to hold their fire while the talking lasts
  // (Reactions/TalkTruce.reds): as far as a gang's people warn from and shoot from in a street.
  public static func TruceRadius() -> Float = 40.0
  public static func TalkRange() -> Float = 3.5
  public static func TalkKeepRange() -> Float = 5.5
  public static func TalkDwell() -> Float = 0.4
  public static func TalkLookGrace() -> Float = 2.0
  public static func TalkCooldownTicks() -> Int32 = 1
  // How far to the side of V's line of sight the next talkable person may be when the one in front cannot talk.
  public static func TalkNextDot() -> Float = 0.8
  // The hold-position order's length (seconds), renewed every TalkHoldRenewSeconds while the conversation lasts and
  // let go when it ends (it was one order of ninety seconds, which froze anybody whose cancel was missed).
  public static func TalkHoldSeconds() -> Float = 8.0
  public static func TalkHoldRenewSeconds() -> Float = 5.0
  // Somebody who gave up, and a Rival's people holding for a facedown, keep the long hold they always had.
  public static func SurrenderHoldSeconds() -> Float = 90.0
  public static func FacedownHoldSeconds() -> Float = 90.0
  // How long the game's interaction prompt may stay up once the person's own talk is switched off before it is taken
  // for something else's (a door, a pickup) and talk waits for it.
  public static func TalkOwnPromptWait() -> Float = 1.5
  // At most this many bystanders in front of V have their own talk on F switched off at once while one of the game's
  // prompts stands between V and the person V wants (Reactions/StreetTalk.reds, HushNear).
  public static func TalkHushNearCap() -> Int32 = 6
  // How long "Talk" offered and not pressed holds a facedown's, a parley's or a scout's clock (ticks, CBTalkEngaged).
  // With the lines up it holds for as long as V takes to choose.
  public static func TalkOfferHoldTicks() -> Int32 = 10
  // Within this of the job V is tracking, talk is words only.
  public static func TalkWordsOnlyNearJob() -> Float = 30.0
  // How many times V can push back on one price.
  public static func TalkHaggleRounds() -> Int32 = 2
  // The street talks (Reactions/StreetIntel.reds): how long a grip takes, crouching over the downed, a scan's
  // odds, turning a ganger, an informant's set-up, and the Rivals who carry a fatal flaw.
  public static func SqueezeSeconds() -> Float = 3.5
  public static func DownedTalkSeconds() -> Float = 2.0
  public static func DownedTalkRange() -> Float = 2.5
  public static func IntelScanChance() -> Float = 0.5   // a scan turns something up (from 0.35)
  public static func TurnBase() -> Float = 0.25
  public static func InformantSetupChance() -> Float = 0.15
  public static func FlawMinRank() -> Int32 = 3
  public static func FlawChance() -> Float = 0.4
  // Rivals with a life (Rivals/RivalLife.reds): the mercy choice's empty-handed moment and its shortest wait (fast
  // ticks), exile's odds, a successor being family, a Rival calling V out instead of coming, what finishing a
  // called-out Rival pays, and what each fallen bodyguard costs the Rival.
  public static func RegistryKeepRadius() -> Float = 120.0
  public static func MercyHolsterTicks() -> Int32 = 3
  // Within this of a Rival V put down, V is still deciding: empty hands do not spare them.
  public static func MercyTalkRadius() -> Float = 10.0
  public static func MercyMinTicks() -> Int32 = 4
  public static func ExileBase() -> Float = 0.7   // less 0.15 a rank above the first (from 0.6)
  public static func KinChance() -> Float = 0.5
  public static func CallOutChance() -> Float = 0.25
  public static func WordKeptRenownShare() -> Float = 0.5
  public static func WordKeptFear() -> Float = 3.0
  public static func GuardNerveLoss() -> Float = 15.0
  // A living street (Spawn/LivingStreet.reds). Ticks are fast ticks (seconds).
  public static func WhileOutDelayTicks() -> Int32 = 20
  public static func BagmanGapTicks() -> Int32 = 1200
  // A roll about every twenty minutes of free roaming. At 0.35 a bagman came about once an hour of play.
  public static func BagmanChance() -> Float = 0.5
  // How close V has to be, gun out or running, for a bagman to see V coming and bolt.
  public static func BagmanSpotDistance() -> Float = 14.0
  // Street life by the hour and the weather (CBStreetLifeMood), and hangouts by who holds the streets.
  public static func StreetNightMult() -> Float = 1.35
  public static func StreetRainMult() -> Float = 0.55
  public static func HeldDistrictHangoutMult() -> Float = 1.5
  public static func LostDistrictHangoutMult() -> Float = 0.6
  public static func BagmanLifeTicks() -> Int32 = 300
  public static func BagmanTakeBase() -> Int32 = 600
  public static func BagmanGangLoss() -> Float = 3.0
  public static func BagmanStandingLoss() -> Float = 4.0
  public static func FavourDistance() -> Float = 55.0
  public static func FavourLifeTicks() -> Int32 = 600
  public static func FavourPay() -> Int32 = 700
  // Corporate contracts (Spawn/LivingStreet.reds): looked at every five minutes or so, offered on 40% of those while no
  // job is open, a corporation resting 8 game hours after it offers.
  public static func CorpContractEveryTicks() -> Int32 = 300
  public static func CorpContractChance() -> Float = 0.4
  public static func CorpContractLifeTicks() -> Int32 = 3600
  public static func CorpContractPay() -> Int32 = 2500
  public static func CorpContractStanding() -> Float = 8.0
  public static func CorpContractMarkSlight() -> Float = 4.0
  public static func CorpContractGuards() -> Int32 = 2
  public static func CorpContractRenown() -> Float = 6.0
  public static func CorpContractRestHours() -> Float = 8.0
  public static func FavourWarmth() -> Float = 2.0
  public static func FavourTipChance() -> Float = 0.35
  // Who has work, and where the debt is (Spawn/LivingStreet.reds): the share of a friendly gang's people with a favour
  // to give, the game hours a gang has nothing more after handing one out, how long a debt waits (a trip across town),
  // how far off it is at least, the chance the one who owes pays when leaned on (more the more the street fears V,
  // never past 0.9), and the standing V loses with the gang for killing them.
  public static func FavourGiverChance() -> Float = 0.3
  // How much you hear (UI/PhoneMessages.reds): chatter let through an in-game hour on Less chatter, and the sim seconds
  // between lines overheard in passing on Less chatter and on Only what matters.
  public static func ChatterPerHour() -> Int32 = 2
  // The street's stories (Spawn/StreetStories.reds): a debtor giving up another name, how far a bagman's drop may be,
  // how long his walk may take, how near a witness is met, what they cost, a ransom's drop (reach, how long it waits,
  // the chance it is a trap), wannabes' friends, and how much a crashed sit-down angers the side it hurt most.
  public static func FavourChainChance() -> Float = 0.35
  public static func BagmanDropMin() -> Float = 100.0
  public static func BagmanDropMax() -> Float = 400.0
  public static func BagmanRouteLifeTicks() -> Int32 = 720
  public static func WitnessRange() -> Float = 170.0
  public static func WitnessPayBase() -> Float = 300.0
  public static func RansomDropReach() -> Float = 12.0
  public static func RansomDropHours() -> Float = 24.0
  public static func RansomDropTrap() -> Float = 0.25
  public static func WannabeFriends() -> Int32 = 2
  public static func MeetReasonAnger() -> Float = 4.0
  public static func OverheardGapLess() -> Float = 45.0
  public static func OverheardGapQuiet() -> Float = 150.0
  public static func FavourGangRestHours() -> Float = 3.0
  public static func FavourDebtLifeTicks() -> Int32 = 2400
  public static func FavourDebtMinDistance() -> Float = 120.0
  public static func FavourPayBase() -> Float = 0.35
  public static func FavourPayMenace() -> Float = 0.45
  public static func FavourKillStanding() -> Float = 6.0
  // A roll about every half hour of free roaming. Forty minutes at 0.3 was a sit-down every two hours or
  // more of play, before asking for a gang at war with the one holding the district.
  public static func MeetGapTicks() -> Int32 = 1800
  public static func MeetChance() -> Float = 0.5
  // 130 m, from 90: somebody watching from across the street or a roof never set a meeting off. Its people are placed
  // no further than MeetWalkInReach from V (Spawn/StreetEvents.reds, Place).
  public static func MeetSpawnDistance() -> Float = 130.0
  public static func MeetWalkInReach() -> Float = 140.0
  // Street events, made sturdier from the game's navigation: within this height of the place, its distance is read
  // along the ground; how far round a navmesh point counts as loaded; how many ticks V waits near a place whose ground
  // has not loaded before it is tried anyway; the ring of the navmesh's hidden points round the place; and the ticks
  // between tries when nowhere was out of sight.
  public static func EventSameLevel() -> Float = 30.0
  public static func NavReadyTolerance() -> Float = 6.0
  public static func EventGroundWaitTicks() -> Int32 = 20
  public static func EventPursuitMin() -> Float = 8.0
  public static func EventPursuitMax() -> Float = 45.0
  public static func EventRetryTicks() -> Int32 = 3
  // How far from a home, a guard's post or a stronghold the navmesh's hidden points may be, when the rings find none.
  public static func PlaceAroundPursuitMax() -> Float = 25.0
  // V driving faster than this (m/s): people on foot are looked for ahead of the car, this far at a crawl and this far at
  // 30 m/s and over (the game's police look 20 to 60 m ahead).
  public static func SpawnAheadMinSpeed() -> Float = 5.0
  public static func SpawnAheadNear() -> Float = 20.0
  public static func SpawnAheadFar() -> Float = 60.0
  public static func MeetWindowSeconds() -> Float = 5400.0
  // How far from V a gathering's place is (CBEventFarPlace), in metres: in V's district, a walk or a drive off.
  public static func EventPlaceMin() -> Float = 300.0
  public static func EventPlaceMax() -> Float = 1500.0
  public static func MeetGangLoss() -> Float = 4.0
  public static func MeetRenown() -> Float = 30.0
  public static func SurrenderShare() -> Float = 0.35
  public static func SurrenderShotCode() -> Float = 2.0
  public static func ClaimOutnumbered() -> Int32 = 5
  public static func ClaimCalmTicks() -> Int32 = 15
  // A conversation holds while its person is within keep range and inside this cone in front of V (cos of
  // about 60 degrees), the crosshair wherever it likes (CBTalkFacing).
  public static func TalkKeepDot() -> Float = 0.5
  // How often the person is asked to look at V again while they talk (seconds), how many lines one
  // conversation can run to, and how long somebody V sent off stays out of reach (settled ticks).
  public static func TalkGlanceEvery() -> Float = 2.5
  public static func TalkMaxExchanges() -> Int32 = 12
  // What a lead costs in the street (Reactions/TalkTopics.reds): the Hub's price times these, for one of the
  // Rival's own gang, of a gang at war with theirs, and of no gang.
  public static func TalkPriceOwnGang() -> Float = 1.8
  public static func TalkPriceEnemyGang() -> Float = 0.75
  public static func TalkPriceCivilian() -> Float = 0.5
  // How often a loyal ganger asked about one of their own warns them, haggling's odds and what it takes off.
  public static func TalkLoyalWarnChance() -> Float = 0.35
  public static func TalkHaggleBase() -> Float = 0.35
  public static func TalkHaggleCut() -> Float = 0.65
  // V's Body or Cool at or above this shows in a line and helps it (the game's attributes run 3 to 20).
  public static func TalkAttributeCheck() -> Float = 12.0
  public static func TalkAttributeBonus() -> Float = 0.25
  public static func TalkLifepathWarmth() -> Float = 1.0
  // A fan's drink: how often, how many a day across the street, and how much.
  public static func TalkFanGiftChance() -> Float = 0.45
  public static func TalkFanGiftsPerDay() -> Int32 = 2
  public static func TalkFanGiftBase() -> Float = 40.0
  public static func TalkFanGiftPerRenown() -> Float = 1.5
  // Safe passage and calling off a crew, as shares of what the gang's pay-off would cost (Economy/Peace.reds),
  // with a floor; how long passage lasts (game hours).
  public static func TalkTollShare() -> Float = 0.25
  public static func TalkTollMin() -> Float = 150.0
  public static func TalkTollHours() -> Float = 4.0
  public static func TalkCallOffShare() -> Float = 0.4
  public static func TalkCallOffMin() -> Float = 250.0
  // How long after a liar's story the street says so (real seconds).
  public static func TalkLiarRevealSeconds() -> Float = 150.0
  // The odds a seller texting a lead comes down when V says it is too much, before their standing and V's Cool.
  public static func PhoneLeadHaggleBase() -> Float = 0.4
  // half a minute, from three. Somebody V sent packing is out of reach while they go, not for minutes after.
  public static func TalkSentRestTicks() -> Int32 = 30
  // How long the prompt keeps away after V reaches for a weapon with it up.
  public static func TalkQuietAfterReach() -> Float = 1.5
  // How long V has to look at somebody with a weapon in hand before being told to put it away (once a launch).
  public static func TalkArmedHintDwell() -> Float = 1.2
  // How far round a job's marker people are left out of street talk (CBTalkWhyNot), and the cone in front
  // of V somebody has to be in when the game's look-at finds nobody (cos of about 30 degrees).
  public static func TalkJobClearance() -> Float = 8.0
  // The job V is tracking keeps a little more: its people, not the neighbourhood (CBSafetyGate.CanTalkTo).
  public static func TalkTrackedClearance() -> Float = 10.0
  // The parley (Reactions/Director.reds, TryGangHostile; Reactions/StreetTalk.reds, CBTalkOnGreet): how
  // close an empty-handed V may be to a ganger who has warned V, and for how long after the warning
  // (settled ticks), before they draw; and the odds of talking them down, from the nerve gap like
  // intimidation, held between the two bounds.
  public static func ParleyRange() -> Float = 35.0   // the whole of NpcEvalRadius, where the warning comes from (was 20)
  public static func ParleyMaxTicks() -> Int32 = 40
  public static func ParleyBase() -> Float = 0.4
  public static func ParleyScale() -> Float = 1.2
  public static func ParleyMin() -> Float = 0.1
  public static func ParleyMax() -> Float = 0.85
  // about 30 degrees, from 25: the look-at misses people the crosshair is not quite on.
  public static func TalkFacingDot() -> Float = 0.86
  // The same reason for no prompt is logged at most this often (seconds).
  public static func TalkWhyLogSeconds() -> Float = 8.0
  // How long after telling V why somebody will not talk before another is told (StreetTalk Explain).
  public static func TalkExplainGapSeconds() -> Float = 30.0
  // Cyberbane's hub id on the UIInteractions blackboard: far from the small numbers the game's use.
  public static func TalkHubId() -> Int32 = 1128415301
  // The exchange: V's line, a beat, then theirs.
  public static func TalkAnswerDelay() -> Float = 1.2
  public static func TalkLineSeconds() -> Float = 2.4
  // Reading time for a spoken line (CBTalkReadSeconds): this much, and this much a letter, before the hold.
  public static func ReadSecondsBase() -> Float = 1.5
  public static func ReadSecondsPerChar() -> Float = 0.06
  // A press on the lines counts this long after the list was last seen on screen (StreetTalk ShownJustNow): a game that
  // keeps clearing the list leaves it gone a frame at a time, and presses landing then were lost.
  public static func TalkPressGrace() -> Float = 0.6
  public static func TalkReplySeconds() -> Float = 4.0
  // Voices in a conversation (Reactions/TalkVoice.reds): a line of theirs this many real seconds after it is asked for
  // is the answer's; an answer in their words waits this long for them before Cyberbane's own go up; a crowd person's
  // voiceset lines are let through for this long, for the one line.
  public static func TalkVoiceWindow() -> Float = 5.0
  // V's lines are short (the longest of those used, by the game's length map, runs 3.2 seconds): only that long is a
  // line of V's taken as the option's.
  public static func TalkVoiceVWindow() -> Float = 3.5
  public static func TalkVoiceWait() -> Float = 1.0
  public static func TalkVoiceLinesOpen() -> Float = 2.5
  // Who is afraid: a ganger whose fear of V beats their nerve by this much, a civilian this afraid. A
  // civilian who knows V and V is this well known (or keeps a code) is glad to meet V.
  public static func TalkAfraidMargin() -> Float = 0.2
  public static func TalkCivAfraid() -> Float = 0.45
  public static func TalkCivFanRenown() -> Float = 40.0
  // What a day of talking to one gang's people can move, at most.
  public static func TalkWarmthPerDay() -> Float = 3.0
  public static func TalkSlightPerDay() -> Float = 8.0
  public static func TalkFearPerDay() -> Float = 4.0
  public static func TalkConductPerDay() -> Float = 3.0
  public static func TalkTaxesPerDay() -> Int32 = 1
  public static func TalkLeaksPerDay() -> Int32 = 2
  public static func TalkTipsPerDay() -> Int32 = 1
  // Greet.
  public static func TalkGreetWarmth() -> Float = 0.6
  public static func TalkGreetMercy() -> Float = 0.5
  public static func TalkGreetConduct() -> Float = 0.2
  public static func TalkTipChance() -> Float = 0.35
  // Dismiss.
  public static func TalkDismissFear() -> Float = 0.3
  public static func TalkDismissFriendCost() -> Float = 0.4
  // Antagonize. A ganger folds when their nerve gap is above TalkFoldGap and fights when it is below
  // minus that; one already afraid snaps now and then.
  public static func TalkFoldGap() -> Float = 0.15
  public static func TalkSnapChance() -> Float = 0.2
  public static func TalkFoldFear() -> Float = 0.5
  public static func TalkBullyConduct() -> Float = 0.5
  public static func TalkCivAntagonizeConduct() -> Float = 1.0
  public static func TalkInsultCost() -> Float = 1.5
  public static func TalkInsultFriendCost() -> Float = 2.0
  public static func TalkFightCost() -> Float = 3.0
  public static func TalkCopCost() -> Float = 1.0
  // Intimidate: the odds are the nerve gap scaled, plus a base, held between the two bounds.
  public static func TalkIntimidateScale() -> Float = 1.4
  public static func TalkIntimidateBase() -> Float = 0.45
  public static func TalkAfraidBonus() -> Float = 0.15
  public static func TalkIntimidateMin() -> Float = 0.05
  public static func TalkIntimidateMax() -> Float = 0.95
  public static func TalkLeanFear() -> Float = 1.0
  public static func TalkLeanCost() -> Float = 0.5
  public static func TalkLeanOnFriendCost() -> Float = 3.0
  public static func TalkLostFace() -> Float = 0.8
  public static func TalkCallBluffFight() -> Float = 0.4
  public static func TalkCivIntimidateConduct() -> Float = 1.0
  public static func TalkCivDread() -> Float = 0.4
  // Street tax: base plus so much a level, a little either way, never more than the cap.
  public static func TalkTaxBase() -> Float = 25.0
  public static func TalkTaxPerLevel() -> Float = 4.0
  public static func TalkTaxMax() -> Int32 = 260
  public static func TalkShakedownConduct() -> Float = 1.5
  // Draws before a new playthrough id gives up looking for one nobody has. Eight hex digits make a
  // second draw already unlikely; this only bounds the loop.
  public static func PlaythroughIdTries() -> Int32 = 32
  // A save found to be another character's drops a Killer Rival it got from the shared death ledger only when that
  // death is further ahead of the save's own clock than this.
  public static func ForeignDeathMarginSeconds() -> Float = 86400.0

  // ---- Turf wars (Model/Territory.reds) ----------------------------------- What V costs a gang: each of their people
  // put down, an officer or elite, a boss, a Rival of theirs, a crew wiped out, their apex squad wiped out.
  public static func GangLossMember() -> Float = 0.5
  public static func GangLossOfficer() -> Float = 3.0
  public static func GangLossBoss() -> Float = 8.0
  public static func GangLossRival() -> Float = 6.0
  public static func GangLossRivalPerRank() -> Float = 2.0
  public static func GangLossCrew() -> Float = 6.0
  public static func GangLossApexSquad() -> Float = 10.0
  // How fast they rebuild while V leaves them alone, and how low they can go.
  public static func GangRecoverPerDay() -> Float = 12.0
  public static func GangStrengthFloor() -> Float = 15.0
  // The words the street uses, and the texts that go with crossing them.
  public static func GangBleedingStrength() -> Float = 50.0
  public static func GangBrokenStrength() -> Float = 30.0
  // What share of its usual crew a gang at no strength at all would send (Spawn/Queue.reds, CBCrewSizeFor); in between
  // it scales with strength, so at the floor (15) about three in five.
  public static func CrewStrengthFloorShare() -> Float = 0.5
  // Below this, a gang's districts are open to a gang at war with them from next door, and the push
  // such a gang makes, against a native's strength squared.
  public static func TurfOpenStrength() -> Float = 55.0
  public static func TurfInvaderWeight() -> Float = 0.6
  // Day-to-day drift in who holds how much, as a fraction either way.
  public static func TurfDrift() -> Float = 0.2
  // A share of a district at least this large means a gang is on its own streets there.
  public static func TurfPresenceShare() -> Float = 0.2
  // Damage done on a gang's own streets counts this much again, there, and fades this fast.
  public static func TurfLocalShare() -> Float = 1.0
  public static func TurfLocalRecoverPerDay() -> Float = 4.0
  // To take a district the challenger has to lead the holder by this much, for this long.
  public static func TurfFlipMargin() -> Float = 1.6
  public static func TurfFlipHours() -> Float = 4.0
  // What a home gang is worth on streets somebody else has taken from it.
  public static func TurfLostGroundMult() -> Float = 0.4
  // The old gang coming back: how long between tries, how strong it must be, how likely each hour.
  public static func TurfPushGapDays() -> Float = 2.0
  public static func TurfPushMinStrength() -> Float = 70.0
  public static func TurfPushChance() -> Float = 0.15
  public static func TurfPushDamage() -> Float = 15.0
  // Patrols (Spawn/TurfPatrol.reds).
  public static func TurfPatrolMin() -> Int32 = 2
  public static func TurfPatrolMax() -> Int32 = 4
  public static func TurfPatrolDistance() -> Float = 55.0
  public static func TurfPatrolGapTicks() -> Int32 = 420
  public static func TurfPatrolLifeTicks() -> Int32 = 300
  public static func TurfPatrolLeaveDistance() -> Float = 110.0
  public static func TurfPatrolKeepRoom() -> Int32 = 8
  public static func TurfPatrolWalkTicks() -> Int32 = 35
  public static func TurfPatrolFirstWalkTick() -> Int32 = 5
  public static func TurfPatrolWalkCandidates() -> Int32 = 6
  public static func TurfPatrolWalkMin() -> Float = 12.0
  public static func TurfPatrolWalkMax() -> Float = 32.0

  // ---- Hunting a Rival down (Rivals/Whereabouts.reds) --------------------
  // How likely a tip is on each slow tick (one in-game hour) when one could be given.
  public static func TipChancePerHour() -> Float = 0.3
  // And how much likelier, for each in-game hour a sighting has gone untold past the minimum age.
  public static func TipChanceRisePerHour() -> Float = 0.25
  // A Rival's last seen position stands in for their body for this many fast ticks after it was
  // taken (Rivals/Whereabouts.reds, CBNoteRivalSeen).
  public static func RivalLastPosFreshTicks() -> Int32 = 180
  // In-game hours between tips, and how old a sighting must be before anybody passes it on.
  public static func TipGapHours() -> Float = 4.0
  public static func TipMinAgeHours() -> Float = 1.0
  // A lead goes stale after this many in-game hours: they have moved on.
  public static func LeadLifetimeHours() -> Float = 24.0
  // V within this distance of the place puts the Rival there, out of V's sight.
  public static func LairPlaceDistance() -> Float = 85.0
  // No closer to V than this, wherever V is standing. It was 30 m and measured from the place itself, so V standing at
  // the pin was too close for anybody ever to be put there.
  public static func LairMinDistance() -> Float = 10.0
  // Further than this from a waiting Rival who never noticed V, and they are taken back out.
  public static func LairLeaveDistance() -> Float = 160.0
  // Buying where a Rival is (the Hub's Ambush button). A rank-one name costs about a mid gig's pay, a gang's leader a
  // good deal more, and well under the bounty on any of them.
  public static func WhereaboutsPriceBase() -> Int32 = 1500
  public static func WhereaboutsPricePerRank() -> Int32 = 1000
  // When nobody has seen them anywhere usable, the seller tracks them down near V: out past the range
  // a waiting Rival is put in the world at (LairPlaceDistance), so V walks there, and inside what the
  // navigation query is good for.
  public static func WhereaboutsMinDistance() -> Float = 95.0
  public static func WhereaboutsMaxDistance() -> Float = 150.0
  public static func WhereaboutsCandidates() -> Int32 = 12
  // Ticks V must have been on foot, out of combat, in a settled world before anybody is placed.
  public static func LairCalmTicks() -> Int32 = 5
  // How far round the place to look for standing room, and how often to try while in range.
  // Two rings, so there is usually somewhere round a corner from V to put them.
  public static func LairSearchRadius() -> Float = 12.0
  public static func LairOuterSearchRadius() -> Float = 22.0
  public static func LairTryEveryTicks() -> Int32 = 3
  // How long somebody V put down at their place is given to be logged as a mercy before the place lets go of them; a
  // third ring of spots to try; and when V, standing this close to the pin with nobody placed for this many tries, is
  // told why.
  public static func LairDownWaitTicks() -> Int32 = 20
  public static func LairFarSearchRadius() -> Float = 32.0
  public static func LairHintDistance() -> Float = 45.0
  public static func LairHintTries() -> Int32 = 7
  // Extra renown for putting a Rival down before they ever knew V was there, as a fraction of
  // what the kill itself pays.
  public static func LairAmbushRenownShare() -> Float = 0.5
  // Kill timestamps kept per encounter. Only the massacre window is ever read back, so
  // this is comfortably more than the rule needs.
  public static func CapEncounterKillTicks() -> Int32 = 64
}

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
  // If at least this many entities attached in a single tick interval, the world is streaming
  // heavily (a flood) even without a transition - stand down until it settles. This catches
  // ambient floods (dense districts, scene loads) that no menu/time-jump signal would flag.
  // Puppets attached in one second that counts as the world being rebuilt around you. A busy
  // street streams people in constantly, so this has to sit well above a crowd and below a
  // load: at 25, counting every entity type, it was tripped more or less permanently.
  public static func FloodAttachThreshold() -> Int32 = 60
  // Recovery for an attach spike. Shorter than FloodSettleTicks, which is for loads.
  public static func AttachSettleTicks() -> Int32 = 6

  // ---- Reaction director (spec §9.1, §18) ------------------------------
  // Wide enough to contain the chrome-widened flee range below, and enough NPCs per tick that
  // a busy street actually reacts instead of one or two people noticing you.
  public static func NpcEvalRadius() -> Float = 35.0           // metres
  public static func NpcEvalPerTick() -> Int32 = 16
  public static func MaxSpawnedNpcs() -> Int32 = 8
  public static func PerNpcCooldownSeconds() -> Float = 30.0
  // Upper bound on the attitude-revert list (NPCs Cyberbane turned hostile). Only live
  // NPCs ever need reverting, so this just keeps the list from growing all session.
  public static func MaxTrackedHostiles() -> Int32 = 64

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
  // How often an ordinary witnessed kill becomes a story, and how loudly each kind travels.
  // Deliberately well under 1: every kill making the rounds would fill the board with noise
  // and make the whole mechanic meaningless.
  public static func RumorChanceOrdinary() -> Float = 0.15
  public static func RumorMagnitudeOrdinary() -> Float = 3.0
  public static func RumorMagnitudeNotable() -> Float = 8.0
  public static func RumorMagnitudeCivilian() -> Float = 6.0
  // Unseen kills needed, as a Ghost, for the Konpeki Ghost title.
  public static func KonpekiUnattributed() -> Int32 = 25
  // How many titles the Hub lists on the Titles screen, earned and still to earn. The screen
  // clamps its own line count, so these keep the "not yet" list from pushing the earned list
  // off the top of it.
  public static func HudTitlesEarnedShown() -> Int32 = 8
  public static func HudTitlesLockedShown() -> Int32 = 7
  // Width of the threat bar across the top of the screen.
  public static func ThreatBarWidth() -> Float = 760.0
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
  public static func RecognitionCacheSeconds() -> Float = 600.0   // 10 real minutes
  public static func RecognitionCacheMax() -> Int32 = 256

  // ---- Civilians (spec §9.2) -------------------------------------------
  // Reaction tiers. These sat at 60/80, which a mid-game V almost never reached, so the city
  // stayed silent and the mod read as "not working". Pitched so a V with obvious chrome gets
  // noticed, and a feared, heavily-built one clears a path. Still scaled by the intensity
  // slider, capped per tick, and switched off entirely inside safe areas.
  public static func CivTierNotice() -> Float = 18.0
  public static func CivTierUneasy() -> Float = 32.0
  public static func CivTierAfraid() -> Float = 42.0
  public static func CivTierTerror() -> Float = 68.0
  public static func CivCowerRadius() -> Float = 8.0    // Afraid tier (spec §9.2)
  public static func CivFleeRadius() -> Float = 18.0    // Terror tier (spec §9.2)
  // How much V's build (level, street cred, skills) adds to how intimidating they look.
  public static func MenaceFearWeight() -> Float = 0.6
  // Ticks (about a second each) before the same civilian can be frightened again. Long enough
  // that one person does not flinch continuously, short enough that walking back down a street
  // still gets a reaction.
  public static func CivReactionCooldownTicks() -> Int32 = 45
  // How much further obvious chrome gets noticed. At full visible chrome both reaction ranges
  // widen by this fraction, so blades-for-arms reads from across the street. Kept low enough
  // that the widened flee range stays inside NpcEvalRadius.
  public static func ChromeNoticeRangeBonus() -> Float = 0.5

  // ---- Whispers (spec §9.10) -------------------------------------------
  // Overheard lines are the clearest sign the city has an opinion of you, so they come a little
  // more often and from a little further out.
  public static func WhisperCooldownSeconds() -> Float = 18.0
  public static func WhisperRadius() -> Float = 13.0
  public static func WhisperChance() -> Float = 0.45
  public static func WhisperDurationSeconds() -> Float = 4.0

  // ---- Morale (spec §9.4) ----------------------------------------------
  public static func MoraleBreakThreshold() -> Float = 0.25
  public static func MoraleMaxBreakFraction() -> Float = 0.6
  public static func MoraleShockRadius() -> Float = 15.0

  // ---- Low-health combat flee / escape -> Rival (spec §10.2) -----------
  public static func FleeHealthThreshold() -> Float = 25.0   // health % below which they may run
  public static func FleeChance() -> Float = 0.5             // else they fight to the death
  public static func EscapeDistance() -> Float = 60.0        // ran this far from V = got away
  public static func EscapeTimeoutSeconds() -> Float = 120.0 // give up tracking an escapee after this
  // Someone you put down and left does not run anywhere, so there is nothing to wait for.
  // Two minutes of standing around before the Rival existed is why sparing felt like it did
  // nothing at all.
  public static func SparedResolveSeconds() -> Float = 25.0
  public static func EscapeeCap() -> Int32 = 24

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
  // Rivals spawn closer than hit squads so they immediately perceive V and give chase.
  // Close enough that V meets them before driving off. At 35 m a Rival could spawn behind
  // you, lose you to a vehicle, and be despawned before either of you noticed.
  // Far enough back that spawnInView = false has somewhere to work. At twenty metres a single
  // camera turn put the point in view, and the engine then declines the spawn without saying
  // so - which read as a Rival that was due and never came. They are told to run at V on
  // arrival (CBOrderHunt), so the extra distance costs nothing.
  public static func RivalSpawnDistance() -> Float = 42.0

  // How many downed enemies the mercy sweep looks at per fast tick. The sweep exists because
  // the hit hook alone misses anyone who drops to damage that does not raise a hit event we
  // see (a burn, a quickhack tick, an explosion, another mod's damage).
  public static func SparedSweepPerTick() -> Int32 = 10

  // ---- Quiet work (spec §16) ---------------------------------------------
  // How long the "do not walk in on a stealth job" hold outlives the game's own Stealth
  // state. The game only reports it while V is crouched, so this covers standing up to
  // cross a room without handing anyone a window to arrive in.
  public static func StealthHoldGraceTicks() -> Int32 = 25

  // ---- Archetypes (spec §8.3) -------------------------------------------
  // How much a plain lethal kill says about you. Small on purpose: killing an armed ganger
  // in a firefight is the job, not butchery. A long enough body count still gets there.
  public static func ButcherPerLethalKill() -> Float = 0.2
  // Finishers, dismemberment, blades and fists. This is what Butcher is actually measuring.
  public static func ButcherPerBrutalKill() -> Float = 1.5
  // Lethal with nobody left to report it.
  public static func GhostPerUnseenKill() -> Float = 1.5

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
  public static func GrapevineDurationSeconds() -> Float = 6.0

  // ---- Gang hierarchy (spec §10.1) ---------------------------------------
  // Running a crew, or standing near the top of one, makes you harder to put down. Modest
  // next to an apex hunter, which is a different kind of event entirely.
  public static func LeaderMinRank() -> Int32 = 4
  public static func LieutenantMinRank() -> Int32 = 3
  public static func LeaderHealthMult() -> Float = 2.0
  public static func LieutenantHealthMult() -> Float = 1.4

  // ---- Succession (spec §10.1) ------------------------------------------
  // Added to the avenger roll per rank of the Rival you just put down, so the higher the
  // one you killed, the likelier someone steps into the slot. A crew cannot be decapitated
  // in a single fight.
  public static func SuccessionChancePerRank() -> Float = 0.12

  // ---- Spawn ground probe (mid-air spawn fix) --------------------------
  // The spawn point is a flat offset behind V, so the floor under it is often not at V's own
  // height. These drive the downward trace that finds the real floor (see CBGroundAt).
  public static func GroundProbeUp() -> Float = 3.0      // start the ray this far above the guess
  public static func GroundProbeDown() -> Float = 25.0   // and look this far below it
  // Minimum upward tilt of the hit surface for it to count as a floor rather than a wall or
  // a railing (the Z of a unit normal: 1.0 is flat ground, 0.0 is a vertical face).
  public static func GroundMinNormalZ() -> Float = 0.65
  // A floor further than this from V's own height is another level - a roof, the bottom of a
  // shaft - so the point is moved in toward V instead of used.
  // How far above or below V a spawn point's floor may be.
  //
  // This was fifteen metres, which is three storeys: a billboard, an awning or a first floor
  // walkway all passed as "the same level", and the raycast is perfectly happy to find the top
  // of a sign. That is the enemy standing in mid-air next to a hoarding. Somebody arriving to
  // fight you is on your level or they are no use to anybody.
  public static func GroundMaxDrop() -> Float = 3.5
  // Set them down a hair above the floor so they never start clipped into it.
  // Clearance above the floor a spawn is placed on. A tenth of a metre left somebody
  // intersecting the surface they had just been put on, which the engine resolves by dropping
  // them into a ragdoll.
  public static func GroundSpawnLift() -> Float = 0.35
  // How many abreast a spawned group stands before starting another rank behind it.
  // First ESecurityAreaType ordinal that counts as ordinary open city. Below this the game
  // treats the area as safe or restricted, and Cyberbane sends nobody.
  public static func OpenZoneFrom() -> Int32 = 2
  // Largest cosine of the angle between V's facing and the spawn point that is still
  // accepted. 0.342 is cos(70 degrees), the same margin They Will Remember uses, expressed in
  // a form with no unit to get wrong.
  public static func SpawnMaxFacingCosine() -> Float = 0.342
  // And the shortest distance worth queuing an out-of-view spawn at.
  public static func SpawnMinDistance() -> Float = 25.0
  public static func SpawnPerRank() -> Int32 = 4
  public static func SpawnRankSpacing() -> Float = 3.0
  // How far a navmesh snap may move a body from where its rank asked for it before the point
  // is refused as belonging to somewhere else entirely.
  public static func NavSnapTolerance() -> Float = 10.0
  // Where a hunter stops once it reaches V, and how much that varies across a squad.
  public static func HuntStopDistance() -> Float = 3.0
  public static func HuntStopSpread() -> Float = 8.0

  // ---- Arriving by car (spec 9.9) ----
  // Far enough out that the car is not seen appearing and has room to build up speed.
  public static func VehicleArrivalDistance() -> Float = 70.0
  // The box a car needs to be clear before one is put there, in metres.
  public static func CarFitWidth() -> Float = 2.5
  public static func CarFitLength() -> Float = 4.5
  public static func CarFitHeight() -> Float = 1.0
  public static func CarMaxSeats() -> Int32 = 4
  // One beat for the mounts to settle before the driver is given orders.
  public static func CarStartDelay() -> Float = 0.3
  public static func ChaseDistanceMin() -> Float = 3.0
  public static func ChaseDistanceMax() -> Float = 12.0
  public static func ChaseStartSpeed() -> Float = 10.0
  public static func ArrivalDriveMaxSpeed() -> Float = 80.0
  public static func ArrivalDriveMinSpeed() -> Float = 10.0
  public static func ArrivalStopDistance() -> Float = 12.0
  // How close the car has to get before the crew is let out, how often that is checked, and
  // how many checks before they are unloaded regardless.
  public static func ArrivalDismountDistance() -> Float = 35.0
  public static func ArrivalDismountPoll() -> Float = 2.0
  public static func ArrivalDismountMaxTries() -> Int32 = 30
  // Ticks (about a second each) before a car that never attached is written off.
  public static func ArrivalStaleTicks() -> Int32 = 30
  // How long an expired appointment may wait for a workable moment before it gives up and lets
  // the scheduler arrange a fresh one. Without this, one badly timed expiry blocks every future
  // squad and apex for the rest of the session.
  public static func PendingHoldGiveUpTicks() -> Int32 = 120

  // ---- Apex strength ----
  // Percentage of a boss-grade build, used when settings have not loaded yet.
  public static func ApexStrengthDefault() -> Int32 = 70
  // How much of its own contribution Cyberbane keeps when New Game Plus is also buffing NPCs.
  public static func ApexNgpStepDown() -> Float = 0.5
  // Size of one random trait, as a fraction added on top of the stat it touches.
  public static func ApexTraitStrength() -> Float = 0.6
  public static func ApexPowerLevelBonus() -> Float = 10.0
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
  // How far up the ladder a Rival has to be before they get the boss bar. Zero means every
  // Rival gets it, which is the intent: a Rival is built to apex grade from the first meeting,
  // so the bar is not flattery, it is telling the truth about what is in front of you.
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

  // ---- Vendetta hit squads ----
  // Fast ticks between a gang deciding and the crew turning up. Long enough to read the Hub
  // and get somewhere defensible, short enough that a vendetta is felt.
  public static func VendettaSquadTicks() -> Int32 = 150
  public static func VendettaSquadMinTicks() -> Int32 = 45
  // Smallest share of the full crew that turns out, before menace scales it up.
  public static func VendettaSquadFloorFraction() -> Float = 0.6
  public static func VendettaSquadSizeDefault() -> Int32 = 20

  // ---- Who comes next (spec 9.9) ----
  // How much each kind of contender wants the next turn. A vendetta outranks an ordinary
  // grudge, a gang ready to send its best outranks an ordinary crew, and a Rival with history
  // outranks a new one once their rank and escapes are added on.
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
  // How long a lane stays busy after sending somebody, to cover the gap between asking for a
  // spawn and it existing. Short, and a hard count rather than a wait on an attach.
  public static func LaneSettleTicks() -> Int32 = 8

  // ---- Keeping a chase alive ----
  // How often to remind anybody of ours who has fallen behind, how far behind they have to be
  // before it is worth doing, and how far is far enough that they have genuinely lost you.
  public static func ChaseRefreshEveryTicks() -> Int32 = 6
  public static func ChaseRefreshMinDistance() -> Float = 18.0
  public static func ChaseRefreshMaxDistance() -> Float = 160.0
  // Cap per pass, so a twenty-strong crew never turns one tick into twenty AI commands.
  public static func ChaseRefreshPerPass() -> Int32 = 5
  // Get this far from every one of them, and stay there this long, and they lose you. Roughly
  // what the police in this game give you, and the reason a chase is a chase and not a leash.
  public static func ChaseLoseDistance() -> Float = 120.0
  public static func ChaseLoseTicks() -> Int32 = 22
  // How long an ordinary hostile gang takes to put a crew together, at its slowest and its
  // fastest. Scaled between the two by how much they hate you and how well they know you.
  // The warning window once a lane picks somebody. Short on purpose: the long wait between
  // encounters is the rest period above, and this is only how much notice you get.
  public static func HostileSquadTicksMin() -> Int32 = 90
  public static func HostileSquadTicksMax() -> Int32 = 240
  // How well a gang has to know you before they bother sending anyone.
  public static func HitSquadMinRenown() -> Float = 25.0

  // ---- Faction apex enforcer (spec §9.9) -------------------------------
  // Bodies from one gang before they stop sending squads and send someone who matters. Kept
  // deliberately reachable: a couple of serious run-ins with the same crew gets you there.
  public static func ApexKillThreshold() -> Int32 = 20
  // Fast ticks between the warning and the apex actually walking in (~seconds), so the line
  // lands before they do instead of alongside them.
  // Fast ticks between the warning and the apex arriving. Long enough to read as a countdown
  // in the Hub and to brace for, short enough that you have not driven to another district.
  public static func ApexWarningTicks() -> Int32 = 45
  public static func ApexSpawnDistance() -> Float = 45.0
  // Muscle that comes in with them. Built from the gang's rank-and-file record.
  public static func ApexEscortCount() -> Int32 = 2
  // The apex is built from a gang archetype, which on its own is nowhere near a boss, so the
  // spawned one is lifted to boss grade. The lift scales with how dangerous V actually is
  // (menace: level, Street Cred and skills), so a maxed-out merc gets a real fight instead of
  // a sponge that dies in a burst, and someone just starting out is not simply deleted.
  // Base applies at no build at all, base + range at full menace.
  // An apex is meant to read as the worst thing that gang has. These are deliberately big:
  // at full menace it is in the same conversation as the game's own set piece bosses, and it
  // hits as hard as it takes, because a pure health sponge is tedious rather than frightening.
  public static func ApexHealthMultBase() -> Float = 10.0
  public static func ApexHealthMultRange() -> Float = 15.0   // 10x .. 25x
  public static func ApexArmorMultBase() -> Float = 4.0
  public static func ApexArmorMultRange() -> Float = 6.0
  // What they hit back with.
  public static func ApexDamageMultBase() -> Float = 1.6
  public static func ApexDamageMultRange() -> Float = 1.6    // 1.6x .. 3.2x
  public static func ApexCritChanceBonus() -> Float = 25.0
  public static func ApexCritDamageBonus() -> Float = 60.0     // 2x .. 5x

  // ---- Rivals (spec §10.2, §10.7, Appendix A) --------------------------
  // Rivals only land if they actually happen. Raised so leaving people alive or breaking a
  // crew produces a nemesis often enough to notice, still bounded by the caps below.
  public static func RivalChanceSurvivor() -> Float = 0.65
  public static func RivalChanceSpared() -> Float = 0.75
  // Used both when you put a Rival down (someone steps into their place) and when you kill
  // an Officer or Boss, which is rare enough that a high chance reads as "that one mattered"
  // rather than a flood.
  public static func RivalChanceAvenger() -> Float = 0.60
  public static func RivalChanceHunter() -> Float = 0.50
  // How long a Rival takes to track you down, in fast ticks (roughly seconds). A higher
  // rank has better information and finds you sooner. This replaced a per-slow-tick dice
  // roll, which meant a Rival might show up in ten seconds or never, and nothing could be
  // shown to the player because nothing was actually scheduled.
  public static func RivalHuntTicksBase() -> Int32 = 240
  public static func RivalHuntTicksPerRank() -> Int32 = 35
  public static func RivalHuntTicksMin() -> Int32 = 75
  // When the clock runs out but V is mid-fight or another Rival is already out, wait this
  // many ticks and try again rather than dropping the appointment.
  public static func RivalHuntRetryTicks() -> Int32 = 20
  // How long to wait before checking that a queued Rival actually appeared. Long enough for
  // an out-of-view spawn to be honoured once V has moved or turned.
  public static func RivalArrivalCheckTicks() -> Int32 = 10
  // Spread added to each Rival's countdown so two of the same rank do not arrive together.
  public static func RivalHuntJitterTicks() -> Int32 = 120
  // How long a Rival may stand around before Cyberbane gives up on the encounter, in in-game
  // seconds. In-game time runs far faster than real time, so this is a couple of real minutes.
  public static func RivalRetireGameSeconds() -> Float = 7200.0
  // Once you are carrying as many Rivals as the cap allows, no new ones can be made, so the
  // only way out is to put the existing ones down. They close in at this fraction of the
  // normal wait until you have cleared some room.
  public static func RivalCapHurryMult() -> Float = 0.45
  public static func RivalEncounterBaseChance() -> Float = 0.25
  public static func RivalEncounterChancePerRank() -> Float = 0.07
  // Minimum in-game hours between Rival encounters, so one can actually catch up with you
  // during a session without turning into an ambush every few minutes.
  public static func RivalEncounterCooldownHours() -> Float = 0.6
  // How long a Rival you escaped takes to find you again. Long enough that getting away is a
  // real outcome rather than a pause, which is what makes sparing and escaping worth anything.
  public static func RivalAfterEscapeTicks() -> Int32 = 900
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
  // Kill timestamps kept per encounter. Only the massacre window is ever read back, so
  // this is comfortably more than the rule needs.
  public static func CapEncounterKillTicks() -> Int32 = 64

  // ---- Fault isolation (spec §16.5) ------------------------------------
  public static func ModuleErrorLimit() -> Int32 = 5
}

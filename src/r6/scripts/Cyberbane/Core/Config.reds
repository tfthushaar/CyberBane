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
  // How many titles still to earn the Hub's Titles screen lists beside the earned ones. Earned
  // titles are rows of their own now, every one of them, so this only limits the right-hand column:
  // nine entries of two lines each, with room left for the longer requirements to wrap. (There used
  // to be a limit of eight on the earned list too, which hid every title past the eighth.)
  public static func HudTitlesLockedShown() -> Int32 = 9
  // How close a story companion has to be for the story to have the stage (Core/StoryHold.reds).
  // Generous, because a companion leading the way or a step behind is still walking with V, and a
  // crew arriving forty metres off is arriving in the middle of their scene.
  public static func StoryCompanionRadius() -> Float = 40.0
  // Settled fast ticks (about seconds) a story restriction has to hold before anybody is called
  // back. The game puts some of the same restrictions on V for a moment in ordinary play.
  public static func StoryRestrictionSettleTicks() -> Int32 = 3
  // Width of the threat bar across the top of the screen.
  // Narrower than it was, because there is a stack of these now rather than one.
  public static func ThreatBarWidth() -> Float = 520.0
  // An apex squad of four plus a Rival is the most that can be on you at once, since the three
  // lanes can overlap but never double up on their own kind.
  public static func ThreatBarRows() -> Int32 = 5
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
  // Radius of the fear stims a frightened bystander gives off. Matched to the game's own:
  // 10 m for one person's terror, 15 m for the panic passing along a crowd.
  public static func FearStimRadius() -> Float = 10.0
  public static func FearSpreadRadius() -> Float = 15.0
  // What an apex squad landing on you does to everyone watching. The game uses 100 m for a
  // MaxTac AV coming down, and an apex squad is meant to read the same way.
  public static func ApexTerrorRadius() -> Float = 100.0
  // What a mask is worth as a disguise on its own, and how much a disguise damps what the
  // street reads off you.
  //
  // This was 0.4, which through the 0.5 damp came to a fifth off what a stranger reads. A fifth
  // is not enough to cross a tier, so a player could put a full face mask on and watch the
  // street panic exactly as before - the feature working and looking broken, which is the
  // failure this mod keeps having to fix. At 0.6 a masked V drops about thirty percent, which
  // is the difference between people running and people getting out of the way. The reputation
  // itself is still untouched: a mask changes what lands on the person in front of them, not
  // what the city knows about you.
  public static func MaskDisguise() -> Float = 0.60
  public static func DisguiseDreadDamp() -> Float = 0.50
  public static func ChromeNoticeRangeBonus() -> Float = 0.5

  // ---- Whispers (spec §9.10) -------------------------------------------
  // Overheard lines are the clearest sign the city has an opinion of you, so they come a little
  // more often and from a little further out.
  public static func WhisperCooldownSeconds() -> Float = 18.0
  public static func WhisperRadius() -> Float = 13.0
  public static func WhisperChance() -> Float = 0.45
  // How often a plain whisper gives way to one about a story that has actually reached this
  // district. High on purpose: a line about a specific thing V did somewhere else is the whole
  // point of the rumour engine, and hearing it is the only way a player knows it exists.
  public static func WhisperRumorChance() -> Float = 0.6

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
  // Further out than an ambush, out of sight, and they have to come and find V (Spawn/Hunt.reds).
  // These were 42 to 50 m, which is behind you rather than coming for you.
  public static func HitSquadMinSpawnDistance() -> Float = 85.0
  public static func HitSquadDespawnMinutes() -> Float = 5.0
  public static func HitSquadDespawnDistance() -> Float = 300.0
  // Rivals spawn closer than hit squads so they immediately perceive V and give chase.
  // Close enough that V meets them before driving off. At 35 m a Rival could spawn behind
  // you, lose you to a vehicle, and be despawned before either of you noticed.
  // Far enough back that spawnInView = false has somewhere to work. At twenty metres a single
  // camera turn put the point in view, and the engine then declines the spawn without saying
  // so - which read as a Rival that was due and never came. They are told to run at V on
  // arrival (CBOrderHunt), so the extra distance costs nothing.
  public static func RivalSpawnDistance() -> Float = 80.0

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

  // ---- Gang hierarchy (spec §10.1) ---------------------------------------
  // Running a crew, or standing near the top of one, makes you harder to put down. Modest
  // next to an apex hunter, which is a different kind of event entirely.
  public static func LeaderMinRank() -> Int32 = 4
  public static func LieutenantMinRank() -> Int32 = 3
  // Both were far higher (2.0 and 1.4) and both stacked on top of the full apex-grade build,
  // which is how a leader nemesis became the enemy players could not kill. They are a nudge
  // now, and CBApplyApexGradeBuff clamps the result anyway.
  public static func LeaderHealthMult() -> Float = 1.25
  public static func LieutenantHealthMult() -> Float = 1.1

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
  // How far a candidate point may sit above the floor underneath it and still count as that
  // floor's. Two metres covers navmesh that rides a little proud of the collision surface and a
  // kerb or a step; anything further means the point is over a drop, not on ground.
  public static func SpawnGroundSettle() -> Float = 2.0
  // Nobody stands inside anybody else. Enough for two people to be distinct bodies and small
  // enough that a squad still reads as a squad.
  public static func SpawnMinSeparation() -> Float = 1.6
  // How far the rest of a group may form up from the first one placed. Keeps a squad together
  // and means only the first point of a group needs the full reachability test.
  public static func SpawnGroupRadius() -> Float = 18.0
  // How far apart the seats of an arriving car are created before they are mounted.
  public static func ArrivalSeatSpread() -> Float = 1.4
  // Largest cosine of the angle between V's facing and the spawn point that is still
  // accepted. 0.342 is cos(70 degrees), the same margin They Will Remember uses, expressed in
  // a form with no unit to get wrong.
  public static func SpawnMaxFacingCosine() -> Float = 0.342
  // And the shortest distance worth queuing an out-of-view spawn at.
  public static func SpawnMinDistance() -> Float = 25.0
  // Bearings tried around V before giving up, starting directly behind and widening. Every
  // candidate point used to lie on the one line behind the player, so a wall, a building or a
  // drop in that direction failed all of them for the same reason and the encounter was
  // refused while perfectly good ground sat to either side.
  public static func SpawnBearingTries() -> Int32 = 9
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
  public static func VehicleArrivalDistance() -> Float = 140.0
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

  // ---- Can a car even get here (spec 9.9) ------------------------------
  //
  // Vanilla's own thresholds for this live on the prevention data table as
  // FallbackMaxDistanceToRoad / FallbackMaxHeightDifference, which are TweakDB flats with no
  // record accessor, so they cannot be read from redscript. These are the same question asked
  // with numbers of our own: a road a hundred metres of walking away is not somewhere a crew
  // can plausibly pull up from, and twelve metres of height is a different level of a car park.
  public static func ArrivalMaxRoadDistance() -> Float = 100.0
  public static func ArrivalMaxRoadHeight() -> Float = 12.0

  // ---- Messages on the phone (spec 12.2) -------------------------------
  //
  // The card is authored in 1080p units and scaled by the same fit the Hub uses. Positioned on
  // the left at a little above the middle, which is where the game's own incoming SMS appears -
  // the point is that it reads as the phone rather than as a mod.
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
  // The threads in the phone. Session only; see the note in UI/PhoneMessages.reds about why
  // they are not persisted. Senders are bounded (a handle per gang, a broker per district and a
  // few unknown numbers), so the thread cap is there for safety rather than expected to bind.
  public static func PhoneThreadCap() -> Int32 = 64
  public static func PhoneMessageCap() -> Int32 = 240
  // How much of one thread the phone draws. A thread longer than this shows its newest lines.
  public static func PhoneThreadShown() -> Int32 = 30
  // The quietest the phone is allowed to be busy. A player on 1.4.7 reported it "constantly
  // blowing up", and the mod has a sender per gang, a broker per district and a few unknown
  // numbers, so a busy few minutes really can ring repeatedly. Messages are always filed in
  // their thread and always mark it unread; this only limits how often one of them is allowed
  // to put a notification on screen, in real seconds.
  public static func PhoneNotifyGapSeconds() -> Float = 9.0
  // A message identical to the last one from the same contact, within this long, is the same
  // message arriving twice - the second one is filed but never announced. ("Pretty sure I'm
  // getting more than one notification per message.")
  public static func PhoneRepeatGuardSeconds() -> Float = 12.0

  // Messages waiting for a settled tick. More than this in one go is a burst, and the newest
  // are the ones worth a notification; the rest are still filed in their threads.
  public static func PhonePendingCap() -> Int32 = 6
  // Where Cyberbane's contacts sit in the phone's hash space. Real contacts use hashes of their
  // journal paths, spread over the whole Int32 range; a block of 64 at a fixed odd value is
  // vanishingly unlikely to meet one, and every check also confirms the thread exists.
  public static func PhoneHashBase() -> Int32 = 1128415233
  // Asking the road network for chase strategies (Spawn/VanillaChase.reds): start this many
  // ticks before a lane is due, and re-send this often while a car may be needed.
  public static func ChasePrimeLeadTicks() -> Int32 = 30
  public static func ChasePrimeRefreshTicks() -> Int32 = 8
  // A chase spawn range for when the heat table in use has none.
  public static func ChaseSpawnRangeMin() -> Float = 60.0
  public static func ChaseSpawnRangeMax() -> Float = 160.0
  // Checks a crew member the city carried gets before they are told to come on foot anyway,
  // if they turn out not to be in a car at all.
  public static func CrewWatchSettleTries() -> Int32 = 2
  // Overheard lines: a subtitle near the bottom of the screen, above the game's own subtitles.
  public static func OverheardSeconds() -> Float = 5.5
  public static func OverheardFloor() -> Float = 3.5
  public static func OverheardWidth() -> Float = 1100.0
  public static func OverheardBottom() -> Float = 250.0

  // ---- Keeping an arrival out of frame ---------------------------------
  //
  // "They pop out of nowhere like the old police spawns" is the most repeated complaint about
  // this mod, and `spawnInView = false` on the entity spec does not answer it: the flag is
  // advisory and the engine honours it by delaying rather than refusing.
  //
  // The facing threshold is SpawnMaxFacingCosine, further down, which CBNavAnchor has used
  // since 1.1.5. There is deliberately not a second one here: the group anchor and the
  // pursuit points are answering the same question and had better answer it the same way.
  //
  // In front of V, but this far away, so all the player sees is somebody walking into frame
  // rather than appearing. Deliberately generous: at this range a body is a few pixels.
  public static func SpawnInViewFarDistance() -> Float = 70.0
  // Eye height for the line-of-sight trace, so the ray clears a kerb and is stopped by a wall.
  public static func SpawnEyeHeight() -> Float = 1.5

  // ---- Apex strength ----
  // Percentage of a boss-grade build, used when settings have not loaded yet.
  public static func ApexStrengthDefault() -> Int32 = 55
  // How much of its own contribution Cyberbane keeps when New Game Plus is also buffing NPCs.
  public static func ApexNgpStepDown() -> Float = 0.5
  // Size of one random trait, as a fraction added on top of the stat it touches.
  //
  // Was 0.6, which at full strength put another 42% on health or armour on top of a
  // multiplier that was already too high. A trait is supposed to make two apexes from the same
  // gang fight differently, not to be a second difficulty slider.
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
  // Shortest gap between two on-screen messages. The channel holds one at a time, so anything
  // closer than this replaces a message the player was still reading.
  public static func MessageMinGapSeconds() -> Float = 3.5
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
  // What one in-game day holds, per kind. Three Rivals, two crews and two apex squads is a
  // day with a shape to it: busy enough that the city is clearly after you, bounded enough
  // that it ends. Each lane counts separately, so a full day of Rivals does not use up the
  // crews.
  // Set against the clock rather than by feel. An in-game day is 24 hours and the world clock
  // runs about 8.1x real time, so a day is roughly 178 minutes of actually playing. At the old
  // 3/2/2 that is one Rival every 59 real minutes and something of any kind every 25, which is
  // most of an evening spent waiting - and the Hub said so, in plain minutes.
  //
  // 8/5/4 puts something on you every 10 real minutes: Rivals every 22, crews every 36, apex
  // squads every 45. Apex stays the rare one, which is what makes it land.
  // How long you may be left waiting at the start of a session before something is pulled
  // forward. 0.5 in-game hours is about four minutes of real play.
  public static func FirstSlotMaxWaitHours() -> Float = 0.5
  public static func RivalsPerDayDefault() -> Int32 = 8
  public static func HitSquadsPerDayDefault() -> Int32 = 5
  public static func ApexSquadsPerDayDefault() -> Int32 = 4
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
  // How long after asking the city for a chase car we keep claiming matching arrivals. Short,
  // so an unrelated member of the same gang streaming in is not mistaken for one of ours.
  public static func AdoptionWindowTicks() -> Int32 = 20
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
  public static func ApexSpawnDistance() -> Float = 90.0
  // Muscle that comes in with them. Built from the gang's rank-and-file record.
  public static func ApexEscortCount() -> Int32 = 2
  // The apex is built from a gang archetype, which on its own is nowhere near a boss, so the
  // spawned one is lifted to boss grade. The lift scales with how dangerous V actually is
  // (menace: level, Street Cred and skills), so a maxed-out merc gets a real fight instead of
  // a sponge that dies in a burst, and someone just starting out is not simply deleted.
  // Base applies at no build at all, base + range at full menace.
  // An apex is meant to read as the worst thing that gang has. These are deliberately big:
  // What an apex is worth in raw survivability.
  //
  // Third pass at these numbers, and the first one driven by more than one report of the same
  // thing: enemies nothing could kill. The target is a cyberpsycho, which is a fight you have
  // to take seriously and can win with the gun you are carrying. It is not a boss with a
  // health bar measured in magazines.
  //
  // The history is worth keeping, because the arithmetic is what went wrong rather than the
  // intent. 1.2.6 had 10x..25x health behind 4x..10x armour. 1.3.0 cut that to 2.5x..5x and
  // 1.5x..3x and called it done, which still multiplied out: the stated range is only the
  // first of four terms. A random trait could add another 42% to health or armour, the
  // Overclocked trait added ten power levels (and the game derives health, armour and damage
  // from power level, so that term multiplies everything again), and a Rival who was running a
  // crew took a further 2x on top of all of it. A leader nemesis at the top of the ladder came
  // out near eleven times health behind three and a half times armour, several levels above
  // its own gang. That is the immortal enemy, and no single number in the file looked wrong.
  //
  // So two things change. The numbers below come down to a cyberpsycho's territory, and
  // CBApplyApexGradeBuff now folds the traits and the role into one multiplier per stat and
  // clamps it against the ceilings underneath, so no combination of them can compound into a
  // wall again. The tactical half of the brief is carried by the kit in ApexSquad.reds - cover,
  // advancing fire, anti-stun, reinforcements, seeing through optical camo - which is what makes
  // an apex a different fight rather than a longer one.
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
  //
  // This is the part that was missing. Every term above was individually defensible and the
  // product of them was not, and there was no single place that knew the product. There is
  // now: CBApplyApexGradeBuff combines everything and clamps it here, so the worst enemy the
  // mod can build is a known quantity rather than an emergent one.
  public static func ApexHealthMultCeiling() -> Float = 3.0
  public static func ApexArmorMultCeiling() -> Float = 1.8
  public static func ApexDamageMultCeiling() -> Float = 1.6
  public static func ApexCritChanceCeiling() -> Float = 15.0
  public static func ApexCritDamageCeiling() -> Float = 40.0
  // Power level is the one term that moves every other stat at once, which is why ten of them
  // was a mistake rather than a tuning choice. Two keeps the "fights above its station" read
  // without hiding a multiplier inside it.
  public static func ApexPowerLevelCeiling() -> Float = 3.0

  // ---- Rivals (spec §10.2, §10.7, Appendix A) --------------------------
  // Rivals only land if they actually happen. Raised so leaving people alive or breaking a
  // crew produces a nemesis often enough to notice, still bounded by the caps below.
  public static func RivalChanceSurvivor() -> Float = 0.65
  public static func RivalChanceSpared() -> Float = 0.75
  // A spared cyberpsycho is a coin flip, and nothing else about them is left to chance: they
  // come back with their own name, their own health and no multiplier on top of it.
  public static func CyberpsychoRivalChance() -> Float = 0.50
  // How far a gang's opinion of V moves when one of theirs puts V down. Standing is V's
  // footing with them, so beating V costs V footing: they have seen that it can be done.
  public static func DeathStandingDrop() -> Float = 6.0
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
  // A Rival sent by car is a body the city spawns somewhere down the road; it is confirmed once
  // the adoption window has had time to claim it.
  public static func RivalCarArrivalCheckTicks() -> Int32 = 26
  // How often a Rival drives in rather than walking, when there is a road to drive in on.
  public static func RivalCarChance() -> Float = 0.6
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
  // ---- Earning a gang's respect without killing for it -------------------
  // Before 1.5.5 the only way standing could rise was killing a gang's enemies, so the only
  // road to Friendly ran through somebody else's body. These are the other roads.
  //
  // What a gang minds about one of theirs being put down, when they are still breathing. The
  // same hit as a kill was being taken either way, which made mercy pointless.
  public static func NonLethalStandingShare() -> Float = 0.25
  // What each one of theirs V leaves alive is worth to them, and how far that alone can carry.
  // At this rate Friendly (15) is a long run of restraint and nothing better - mercy makes a
  // gang tolerate V, it does not make them allies. Only hurting their enemies does that.
  public static func MercyCredit() -> Float = 0.4
  public static func MercyCeiling() -> Float = 20.0
  // Letting a named Rival of theirs walk is worth more than sparing a nobody.
  public static func MercyRivalCredit() -> Float = 3.0

  // Gangs at war (Model/GangRivalries.reds). Hurting a gang raises its enemies' standing with V
  // by this share of what it lost, never past the ceiling: a witnessed ganger is +1 with each
  // enemy, so Friendly (15) takes a run of work and Allied (50) takes a campaign.
  public static func RivalGangShare() -> Float = 0.5
  public static func RivalGangCeiling() -> Float = 75.0
  // What vendors on a gang's turf do about where V stands with that gang.
  public static func TurfAlliedDiscount() -> Float = 0.08
  public static func TurfFriendlyDiscount() -> Float = 0.04
  public static func TurfHostileSurcharge() -> Float = 0.06

  // ---- The hunt (Spawn/Hunt.reds) ----------------------------------------
  // How far off the tip a hunt starts with can be, in metres.
  public static func HuntTipError() -> Float = 45.0
  // The search circle around the last known position: wide at first, tight after HuntNarrowTicks.
  public static func HuntSearchRadiusStart() -> Float = 55.0
  public static func HuntSearchRadiusMin() -> Float = 15.0
  public static func HuntNarrowTicks() -> Int32 = 90
  // A fresh search point this often, per hunter.
  public static func HuntSearchOrderTicks() -> Int32 = 8
  // Seeing V: close with nothing in the way, or already fighting within this range.
  public static func HuntSpotDistance() -> Float = 35.0
  public static func HuntCombatKnowsDistance() -> Float = 80.0
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
  public static func CombatReleaseTicks() -> Int32 = 20

  // ---- Loot and bounties (Spawn/Loot.reds) --------------------------------
  public static func LootDelaySeconds() -> Float = 0.8
  public static func LootCrewChance() -> Float = 0.5
  public static func LootLegendaryChanceApex() -> Float = 0.25
  public static func LootLegendaryChanceTop() -> Float = 0.4
  // A small chance per apex member, and per top-ranked Rival or crew leader, of an iconic.
  public static func LootIconicChanceApex() -> Float = 0.04
  public static func LootIconicChanceRival() -> Float = 0.03
  public static func BountyRivalPerRank() -> Int32 = 1500
  public static func BountyLeaderBonus() -> Int32 = 3000
  public static func BountyApexSquad() -> Int32 = 9000

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
  // Searchers walk once they are this close to the point they were sent to.
  public static func HuntWalkDistance() -> Float = 20.0
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
  // In the global service (Core/CyberbaneService.reds), shared by every save.
  public static func CapForgetNotes() -> Int32 = 32
  public static func CapRetiredIds() -> Int32 = 64
  public static func CapSightings() -> Int32 = 48

  // ---- Hunting a Rival down (Rivals/Whereabouts.reds) --------------------
  // How likely a tip is on each slow tick (one in-game hour) when one could be given.
  public static func TipChancePerHour() -> Float = 0.3
  // In-game hours between tips, and how old a sighting must be before anybody passes it on.
  public static func TipGapHours() -> Float = 4.0
  public static func TipMinAgeHours() -> Float = 1.0
  // A lead goes stale after this many in-game hours: they have moved on.
  public static func LeadLifetimeHours() -> Float = 24.0
  // V within this distance of the place, and no closer than the minimum, places the Rival there.
  public static func LairPlaceDistance() -> Float = 85.0
  public static func LairMinDistance() -> Float = 30.0
  // Further than this from a waiting Rival who never noticed V, and they are taken back out.
  public static func LairLeaveDistance() -> Float = 160.0
  // Ticks V must have been on foot, out of combat, in a settled world before anybody is placed.
  public static func LairCalmTicks() -> Int32 = 5
  // How far round the place to look for standing room, and how often to try while in range.
  public static func LairSearchRadius() -> Float = 12.0
  public static func LairTryEveryTicks() -> Int32 = 3
  // Extra renown for putting a Rival down before they ever knew V was there, as a fraction of
  // what the kill itself pays.
  public static func LairAmbushRenownShare() -> Float = 0.5
  // Kill timestamps kept per encounter. Only the massacre window is ever read back, so
  // this is comfortably more than the rule needs.
  public static func CapEncounterKillTicks() -> Int32 = 64

  // ---- Fault isolation (spec §16.5) ------------------------------------
  public static func ModuleErrorLimit() -> Int32 = 5
}

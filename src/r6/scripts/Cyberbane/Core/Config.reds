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

  // ---- Reaction director (spec §9.1, §18) ------------------------------
  // Wide enough to contain the chrome-widened flee range below, and enough NPCs per tick that
  // a busy street actually reacts instead of one or two people noticing you.
  public static func NpcEvalRadius() -> Float = 35.0           // metres
  public static func NpcEvalPerTick() -> Int32 = 16
  // The most NPCs whose position the Director reads in one tick, carrying on round the registry from
  // where the last tick stopped; and how many ticks somebody who failed its checks (sitting, selling,
  // at a job, one of ours) is passed over before being asked again (1.9.1). A registry of two hundred
  // is gone round about every four seconds; anybody who passes is always checked afresh.
  public static func NpcLookPerTick() -> Int32 = 48
  public static func NpcGateRetryTicks() -> Int32 = 5
  // How often the Director hands back anybody it turned on V whose faction has since been switched
  // off in Mod Settings (Reactions/Director.reds, RevertNotFielding, 1.9.1), in settled ticks.
  public static func SwitchedOffRevertTicks() -> Int32 = 5
  // How long somebody Cyberbane turned on V stays turned, out of a fight, once their gang has no vendetta
  // left against V (RevertNotFielding, 1.9.5): a pay-off, a cooled grudge, a street fight V picked.
  public static func HostileCoolTicks() -> Int32 = 30
  // How long after being set up one of ours is watched for having slipped to neutral (Spawn/Spawner.reds,
  // CBRearmTick, 1.9.6), in settled ticks.
  public static func RearmWatchTicks() -> Int32 = 30
  // How long a gang's warning stands before they draw (Reactions/Director.reds, 1.9.5): long enough to
  // walk away, or to walk up and talk them down.
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
  // What the frightening things V does add to the "terrifying deeds" part of Dread, in the same
  // points a deed's own dread is counted in (Model/Encounter.reds, CBTerrorDeed, 1.9.3).
  public static func TerrorMassacre() -> Float = 30.0
  public static func TerrorBoss() -> Float = 20.0
  public static func TerrorMaxTac() -> Float = 12.0
  public static func TerrorApexSquad() -> Float = 25.0
  public static func TerrorRival() -> Float = 10.0
  // Keeping the peace (Model/GangRivalries.reds, 1.9.3): standing a gang gives V for each in-game
  // hour spent on its streets with no trouble between them for this long.
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
  // How many titles still to earn the Hub's Titles screen lists beside the earned ones. Earned
  // titles are rows of their own now, every one of them, so this only limits the right-hand column:
  // nine entries of two lines each, with room left for the longer requirements to wrap. (There used
  // to be a limit of eight on the earned list too, which hid every title past the eighth.)
  // How close a story companion has to be for the story to have the stage (Core/StoryHold.reds).
  // Generous, because a companion leading the way or a step behind is still walking with V, and a
  // crew arriving forty metres off is arriving in the middle of their scene.
  public static func StoryCompanionRadius() -> Float = 40.0
  // The pass that looks for a story companion walks the whole registry; once every this many settled
  // ticks is enough (1.9.1).
  public static func StoryCompanionScanTicks() -> Int32 = 3
  // Settled fast ticks (about seconds) a story restriction has to hold before anybody is called
  // back. The game puts some of the same restrictions on V for a moment in ordinary play.
  public static func StoryRestrictionSettleTicks() -> Int32 = 3
  // Width of the threat bar across the top of the screen.
  // Narrower than it was, because there is a stack of these now rather than one.
  public static func ThreatBarWidth() -> Float = 520.0
  // An apex squad of four plus the Rival lane's encounter is the most that can be on you at once,
  // since the three lanes can overlap but never double up on their own kind. Since 1.9.0 that
  // encounter can be three Rivals who came together (Rivals team up), so seven: at five, a team that
  // arrived after an apex squad had its second and third names left off the stack.
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

  // ---- Civilians (spec §9.2) -------------------------------------------
  // Reaction tiers. These sat at 60/80, which a mid-game V almost never reached, so the city
  // stayed silent and the mod read as "not working". Pitched so a V with obvious chrome gets
  // noticed, and a feared, heavily-built one clears a path. Still scaled by the intensity
  // slider, capped per tick, and switched off entirely inside safe areas.
  public static func CivTierNotice() -> Float = 18.0
  public static func CivTierUneasy() -> Float = 32.0
  public static func CivTierAfraid() -> Float = 42.0
  public static func CivTierTerror() -> Float = 68.0
  // What a passer-by does, by how frightening V reads to them. Separate from the tiers above,
  // which also price vendors and name V's standing on the Hub. A V at the start of the game gets
  // looks; most of a playthrough gets people stepping aside; running is for a legend at close
  // range, or a slider turned right up. All of them scale with the intensity slider.
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
  // How much further obvious chrome gets noticed. At full visible chrome both reaction ranges
  // widen by this fraction, so blades-for-arms reads from across the street. Kept low enough
  // that the widened flee range stays inside NpcEvalRadius.
  // How far the terror of somebody breaking in a fight carries. The game's own NPC terror is 10 m.
  public static func FearStimRadius() -> Float = 10.0
  // How far panic driving's gunshot carries when the district has not given V a gunshot range yet:
  // the game's own gunshot stimulus radius (stimpresets.tweak, GunshotStimuli).
  public static func PanicStimRadius() -> Float = 30.0
  // How far somebody running from V startles the people next to them.
  public static func FearSpreadRadius() -> Float = 6.0
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
  public static func WhisperRadius() -> Float = 13.0
  public static func WhisperChance() -> Float = 0.45
  // How often a plain whisper gives way to one about a story that has actually reached this
  // district. High on purpose: a line about a specific thing V did somewhere else is the whole
  // point of the rumour engine, and hearing it is the only way a player knows it exists.
  public static func WhisperRumorChance() -> Float = 0.6

  // ---- Morale (spec §9.4) ----------------------------------------------
  public static func MoraleMaxBreakFraction() -> Float = 0.35
  // What goes into the chance of somebody running (Reactions/Morale.reds, CBBreakChance). Nobody
  // breaks on the first body. How shaken they are carries the most weight, scaled by how much
  // their gang fears V; being hurt, being alone, and what they just saw add to it; rank and a
  // sworn vendetta take away. Never more than the ceiling, however bad it gets.
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
  // A gang V has broken (Model/Territory.reds, GangBrokenStrength) breaks sooner still, and its vendetta no
  // longer stiffens it (1.9.5).
  public static func MoraleBrokenGangMult() -> Float = 1.8
  // What a broken gang asks to call off its grudge, as a share of its usual price (Economy/Peace.reds).
  public static func PeaceBrokenShare() -> Float = 0.5
  // Holding back from V on the street (Reactions/Morale.reds, CBHoldBackChance, 1.9.5). Fear is the gang's
  // fear of V as 0..1; a broken gang adds BrokenGangFear, one that has lost ground LostGroundFear. A rank-
  // and-file nerve of 0.5 takes 0.3 off; every friend within the radius takes off HoldBackPerBacker.
  // At fear 0.8 a ganger alone holds back four times in five; at 0.5, one in three; under 0.3, never.
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
  // Both of these are fast ticks, about a real second each. They were compared against the
  // in-game clock, which runs about eight times faster, so "two minutes" to get away was fifteen
  // real seconds and somebody V knocked out was declared spared three real seconds later - in the
  // middle of the fight, with a text saying they had walked away breathing, and before V had any
  // chance to finish them.
  public static func EscapeTimeoutTicks() -> Int32 = 120    // give up tracking an escapee after this
  // Someone you put down and left does not run anywhere, so there is nothing to wait for.
  // Two minutes of standing around before the Rival existed is why sparing felt like it did
  // nothing at all. It also needs V to have walked off: out of the fight, or well away.
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

  // ---- Tribute (spec §9.8) ---------------------------------------------
  // Rolled once an in-game day per gang that qualifies. A quarter left a gang that qualified about four
  // in-game days (some twelve hours of play) before it paid; a half is about two. The week between
  // payments still holds.
  public static func TributeChance() -> Float = 0.5
  public static func TributeCooldownDays() -> Float = 7.0
  // 75 until 1.9.3. A gang's fear is Dread scaled by how well it knows V, and Dread itself could
  // not get past the sixties, so outside the Scavs nobody ever paid.
  public static func TributeFearThreshold() -> Float = 65.0
  // What the two hardest titles ask (Model/TitleEngine.reds). They asked for Dread 90 and a gang's
  // fear at 85, which the sums could not produce for any gang but the Scavs (1.9.3).
  public static func TitleDreadNeeded() -> Float = 80.0
  public static func TitleFearNeeded() -> Float = 75.0
  public static func TributeRenownThreshold() -> Float = 50.0

  // ---- Hit squads (spec §9.9) ------------------------------------------
  public static func HitSquadFactionCooldownDays() -> Float = 2.0
  // Further out than an ambush, out of sight, and they have to come and find V (Spawn/Hunt.reds).
  // These were 42 to 50 m, which is behind you rather than coming for you.
  public static func HitSquadMinSpawnDistance() -> Float = 85.0
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
  // The chance someone steps into a slain Rival's place: the base plus this per rank of the one
  // you put down, so a rank 1 is 40% and a rank 4 is 85% before the Rival frequency setting. A crew
  // cannot be decapitated in a single fight, and killing a small name usually settles it. Until the
  // 1.9.0 bug pass the base was the officer-kill avenger's 60%, so even a rank 1 came back 72%.
  public static func SuccessionChanceBase() -> Float = 0.25
  public static func SuccessionChancePerRank() -> Float = 0.15

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
  // Only used where the navigation system cannot be asked at all. Every other spawn is created
  // on the navmesh point itself (CBSettleOnGround / CBStandOnNavmesh): an NPC is not dropped by
  // physics when it is created, so 0.35 m of lift was 0.35 m of hovering.
  //
  // How far above a navmesh point the floor probe starts. Just enough to catch a floor a hair
  // above the navmesh; three metres (GroundProbeUp) found awnings and ledges instead.
  public static func NavFloorProbeUp() -> Float = 0.5
  // A hair of clearance over the navmesh point or the floor, whichever is higher. The game's
  // own pursuers use the point exactly; this only keeps the feet out of the surface.
  public static func NavSpawnClearance() -> Float = 0.03
  // How far a raycast floor point may be from the navmesh under it and still be that point.
  public static func NavFloorSnapRadius() -> Float = 1.5
  public static func NavFloorSnapHeight() -> Float = 0.6
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
  // A crew member's spot beside the car may move this far to reach the ground. A snap can reach much
  // further, and past a wall that is the next room.
  public static func ArrivalSeatSnap() -> Float = 3.0
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
  // Far enough out that the car is not seen appearing and has room to build up speed. Under
  // ChaseLoseDistance on purpose, and a car on its way never counts as lost whatever the distance
  // (Spawn/Hunt.reds).
  public static func VehicleArrivalDistance() -> Float = 110.0
  // How many of the game's pursuit points a car arrival may try when the navmesh anchor has no
  // room for a car (CBCarSpawnPoint). Each costs two overlap tests and a floor trace.
  public static func CarPointCandidates() -> Int32 = 12
  // Cars one arrival may bring before the rest walk (setting default), and how many ticks in a
  // row a convoy's next car may fail to be sent before that leg walks in instead.
  public static func CarsPerArrivalDefault() -> Int32 = 4
  public static func ConvoyCarTries() -> Int32 = 4
  // The box a car needs to be clear before one is put there, in metres.
  //
  // These are half extents: SpatialQueriesSystem.Overlap takes half the box, as the game's own
  // calls do (NPCPuppet.script, queryDimensions * 0.5). They were written as the car's full size,
  // so the box asked for was five metres by nine by two, starting twenty centimetres off the
  // ground: wider than a lane, longer than a truck, and stopped by a lamp post, a kerb or a road
  // with any slope to it. Very little of Night City passes that, which is half of why a car so
  // seldom got as far as being sent.
  public static func CarFitWidth() -> Float = 1.2
  public static func CarFitLength() -> Float = 2.6
  public static func CarFitHeight() -> Float = 0.7
  // How far off the floor the bottom of that box sits: over a kerb or a camber, under a car.
  public static func CarFitClearance() -> Float = 0.5
  public static func CarMaxSeats() -> Int32 = 4
  // One beat for the mounts to settle before the driver is given orders.
  public static func CarStartDelay() -> Float = 0.3
  // A vendetta crew waiting up the road for a V who is driving (Spawn/Arrival.reds, CBAmbushSpot).
  // How often a crew does this instead of chasing, how fast V must be going for "up the road" to
  // mean anything, how far ahead they park, and how near V comes before they pull out.
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
  // Metres a second. This was 80, nearly 290 km/h through city traffic, which is why crews arrived by
  // driving into things. The game's own police send this exact order at 20 and 10, and stop 20 m
  // short (preventionSystem.script, the drive to the police strategy's destination).
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
  //

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
  // In Phone mode, how long waiting messages hold their notification for a phone to attach after a
  // load or a fast travel, in real seconds (1.9.1). Past this they stay in their threads unannounced.
  public static func PhoneAttachWaitSeconds() -> Float = 45.0
  // Word getting around (CBPhone.Hearsay). Defaults for the two settings, used before Mod
  // Settings is up.
  public static func WordTravelMinutesDefault() -> Int32 = 30
  public static func InboxGapSecondsDefault() -> Int32 = 45
  // A story already told is not told again inside this many in-game hours. A cyberpsycho
  // episode is one massacre to the street, not one per lull in the shooting.
  public static func HearsayRepeatHours() -> Float = 6.0
  // Stories waiting at once, and how many recently told ones are remembered for that window.
  public static func HearsayQueueCap() -> Int32 = 12
  public static func HearsayToldCap() -> Int32 = 32
  // The same contact sending the same words inside this many in-game hours is filed once.
  public static func PhoneDuplicateHours() -> Float = 1.0
  // Where Cyberbane's contacts sit in the phone's hash space. Real contacts use hashes of their
  // journal paths, spread over the whole Int32 range; a block of 64 at a fixed odd value is
  // vanishingly unlikely to meet one, and every check also confirms the thread exists.
  public static func PhoneHashBase() -> Int32 = 1128415233
  // Overheard lines: a line of the game's own subtitles (UI/PhoneMessages.reds, 1.9.5). With the game's
  // subtitles switched off, Cyberbane's own line is drawn where they would be.
  public static func OverheardSeconds() -> Float = 5.5
  public static func OverheardFloor() -> Float = 3.5
  public static func OverheardWidth() -> Float = 1100.0
  public static func OverheardBottom() -> Float = 120.0

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
  // How long, in fast ticks, an apex squad that arrived short keeps walking in its missing
  // chairs (Spawn/FactionApex.reds, CBApexMusterTick).
  public static func ApexMusterTicks() -> Int32 = 120
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
  // Rivals only land if they actually happen. Each of these is the base for one way of becoming a
  // Rival, for an ordinary member of a gang, before CBRivalOdds weighs it: the Rival frequency
  // setting, how much the person counted for (a lookout 0.5x up to an elite 1.4x), and how many
  // Rivals the last few minutes already made (RivalBurstTicks: the second in a fight is half as
  // likely, the third a third). The ceiling is last. So the first person who gets away from V is
  // still more likely than not to come back, an officer more so, and one fight makes one or two
  // names rather than a crowd of them.
  public static func RivalChanceSurvivor() -> Float = 0.6
  public static func RivalChanceSpared() -> Float = 0.6
  public static func RivalBurstTicks() -> Int32 = 300
  public static func RivalOddsCeiling() -> Float = 0.95
  // A Rival a fight makes is made once V has been out of combat this many settled ticks (about
  // seconds), chosen afresh for each (Rivals/Births.reds, 1.9.1). And how many may wait at once.
  public static func RivalBirthCalmMin() -> Int32 = 30
  public static func RivalBirthCalmMax() -> Int32 = 60
  public static func RivalBirthQueueCap() -> Int32 = 6
  // Hostile to V and not by Cyberbane (Reactions/Director.reds, NoteForeignHostility, 1.9.1): how
  // often one NPC's attitude is read, how long a sighting stops the faction being read again, and how
  // long the Gangs screen goes on saying so, all in settled ticks (about seconds).
  public static func ForeignHostileReadTicks() -> Int32 = 10
  public static func ForeignHostileFreshTicks() -> Int32 = 60
  public static func ForeignHostileShowTicks() -> Int32 = 1800
  // A spared cyberpsycho is a coin flip, and nothing else about them is left to chance: they
  // come back with their own name, their own health and no multiplier on top of it.
  public static func CyberpsychoRivalChance() -> Float = 0.50
  // How far a gang's opinion of V moves when one of theirs puts V down. Standing is V's
  // footing with them, so beating V costs V footing: they have seen that it can be done.
  public static func DeathStandingDrop() -> Float = 6.0
  // Killing an Officer or Boss: somebody of theirs takes it personally. Weighed by rank like the
  // rest, so an officer is 50% and a boss 60%. It used to be a flat 60% for either, and officers lead
  // most gang groups, so a fight with three of them made a Rival of nearly every one. A slain Rival's
  // successor has its own numbers now (SuccessionChanceBase).
  public static func RivalChanceAvenger() -> Float = 0.40
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
  // ---- Earning a gang's respect without killing for it -------------------
  // Before 1.5.5 the only way standing could rise was killing a gang's enemies, so the only
  // road to Friendly ran through somebody else's body. These are the other roads.
  //
  // What a gang minds about one of theirs being put down, when they are still breathing. The
  // same hit as a kill was being taken either way, which made mercy pointless.
  //
  // A quarter until 1.9.3, which against the credit below still came out as a loss for every
  // knockout (a ganger -0.1, an officer -1.1), on the road the Hub tells players to take. At a
  // tenth, leaving a ganger breathing earns a little, an elite breaks even, and putting their
  // officers and bosses on the floor still costs.
  public static func NonLethalStandingShare() -> Float = 0.1
  // The share of a kill's Dread that putting somebody down alive adds (Model/Reputation.reds).
  public static func NonLethalDreadShare() -> Float = 0.25
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
  // Somebody cut off from V (Spawn/Hunt.reds, CBCutOffTick). How often they are looked at, how far
  // they have to move to count as going somewhere, how many routes one pass may work out, when they
  // stop counting as being in the fight and when they are taken out, in seconds.
  public static func CutOffPassTicks() -> Int32 = 3
  public static func CutOffRoam() -> Float = 6.0
  public static func CutOffPathsPerPass() -> Int32 = 4
  public static func CutOffQuietTicks() -> Int32 = 21
  public static func CutOffTicks() -> Int32 = 45
  // A walking route (CBPointReachable). It may end this far from where it was asked to, for a V
  // standing off the navmesh, and is a real route up to this many times the straight line plus
  // this many metres. Further than that it is another level of the city, not a way here.
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
  // A crew this size or bigger brings a netrunner along (Spawn/HitSquad.reds, 1.8.5).
  public static func NetrunnerSeatMinCrew() -> Int32 = 3
  // Rivals teaming up (1.9.0): how often a Rival who comes brings others of their gang who are free,
  // when the setting is on; more often for one who holds a chair in the gang's crew or leads a pack.
  // Each partner walks in RivalTeamSpacing metres further back than the one before.
  public static func RivalTeamUpChance() -> Float = 0.3
  public static func RivalTeamUpChanceLeader() -> Float = 0.2
  public static func RivalTeamSpacing() -> Float = 8.0
  // How many of V's clothing items the attached-clothing read looks through (Signals/Concealment.reds).
  // A wardrobe of a few hundred is common; this only bounds a pathological one.
  public static func WornScanCap() -> Int32 = 600
  // Cyberpsychotic breaks (1.9.0): only a rank 4 Rival, a chance on each loss to V that grows with
  // how many there have been, never more than the ceiling.
  public static func PsychoBreakBase() -> Float = 0.08
  public static func PsychoBreakPerLoss() -> Float = 0.05
  public static func PsychoBreakMax() -> Float = 0.45
  // Rivals forgotten one at a time, kept in the service for every save of their playthrough.
  public static func CapForgottenRivals() -> Int32 = 64
  public static func CapGangPower() -> Int32 = 96
  // Which V each playthrough id belongs to (1.8.3). One per playthrough that has loaded since.
  public static func CapBirths() -> Int32 = 128
  public static func CapTalkTallies() -> Int32 = 120

  // ---- Street talk (Reactions/StreetTalk.reds, 1.9.5) ----
  // The prompt: how often it is looked at, how close and for how long V has to look at somebody, how
  // far they may drift and how long V may glance away before it goes, and how long before the same
  // person can be spoken to again (fast ticks, about a second each).
  public static func TalkTickSeconds() -> Float = 0.2
  public static func TalkRange() -> Float = 3.5
  public static func TalkKeepRange() -> Float = 5.5
  public static func TalkDwell() -> Float = 0.6
  public static func TalkLookGrace() -> Float = 2.0
  // After a conversation, before the same person can be spoken to again (1.9.6: it used to follow every
  // single exchange, for 45).
  public static func TalkCooldownTicks() -> Int32 = 3
  // How far to the side of V's line of sight the next talkable person may be when the one in front cannot talk.
  public static func TalkNextDot() -> Float = 0.8
  // The hold-position order's length (seconds); cancelled when the conversation ends.
  public static func TalkHoldSeconds() -> Float = 90.0
  // Within this of the job V is tracking, talk is words only.
  public static func TalkWordsOnlyNearJob() -> Float = 30.0
  // How many times V can push back on one price.
  public static func TalkHaggleRounds() -> Int32 = 2
  // The street talks (Reactions/StreetIntel.reds): how long a grip takes, crouching over the downed, a scan's
  // odds, turning a ganger, an informant's set-up, and the Rivals who carry a fatal flaw.
  public static func SqueezeSeconds() -> Float = 3.5
  public static func DownedTalkSeconds() -> Float = 2.0
  public static func DownedTalkRange() -> Float = 2.5
  public static func IntelScanChance() -> Float = 0.35
  public static func TurnBase() -> Float = 0.25
  public static func InformantSetupChance() -> Float = 0.15
  public static func FlawMinRank() -> Int32 = 3
  public static func FlawChance() -> Float = 0.4
  // Rivals with a life (Rivals/RivalLife.reds, 1.9.9): the mercy choice's empty-handed moment and its
  // shortest wait (fast ticks), exile's odds, a successor being family, a Rival calling V out instead of
  // coming, what finishing a called-out Rival pays, and what each fallen bodyguard costs the Rival.
  // Once the NPC registry is most of the way full, people farther than this from V make room (1.9.9).
  public static func RegistryKeepRadius() -> Float = 120.0
  public static func MercyHolsterTicks() -> Int32 = 3
  public static func MercyMinTicks() -> Int32 = 4
  public static func ExileBase() -> Float = 0.6
  public static func KinChance() -> Float = 0.5
  public static func CallOutChance() -> Float = 0.25
  public static func WordKeptRenownShare() -> Float = 0.5
  public static func WordKeptFear() -> Float = 3.0
  public static func GuardNerveLoss() -> Float = 15.0
  // A living street (Spawn/LivingStreet.reds, 2.0.0). Ticks are fast ticks (seconds).
  public static func WhileOutDelayTicks() -> Int32 = 20
  public static func BagmanGapTicks() -> Int32 = 1200
  // A roll about every twenty minutes of free roaming. At 0.35 a bagman came about once an hour of play.
  public static func BagmanChance() -> Float = 0.5
  public static func BagmanLifeTicks() -> Int32 = 300
  public static func BagmanTakeBase() -> Int32 = 600
  public static func BagmanGangLoss() -> Float = 3.0
  public static func BagmanStandingLoss() -> Float = 4.0
  public static func FavourDistance() -> Float = 55.0
  public static func FavourLifeTicks() -> Int32 = 600
  public static func FavourPay() -> Int32 = 700
  public static func FavourWarmth() -> Float = 2.0
  public static func FavourTipChance() -> Float = 0.35
  // A roll about every half hour of free roaming. Forty minutes at 0.3 was a sit-down every two hours or
  // more of play, before asking for a gang at war with the one holding the district.
  public static func MeetGapTicks() -> Int32 = 1800
  public static func MeetChance() -> Float = 0.5
  public static func MeetSpawnDistance() -> Float = 90.0
  public static func MeetWindowSeconds() -> Float = 5400.0
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
  public static func TalkSentRestTicks() -> Int32 = 180
  // How long the prompt keeps away after V reaches for a weapon with it up.
  public static func TalkQuietAfterReach() -> Float = 4.0
  // How long V has to look at somebody with a weapon in hand before being told to put it away (once a launch).
  public static func TalkArmedHintDwell() -> Float = 1.2
  // How far round a job's marker people are left out of street talk (CBTalkWhyNot), and the cone in front
  // of V somebody has to be in when the game's look-at finds nobody (cos of about 25 degrees).
  public static func TalkJobClearance() -> Float = 8.0
  // The job V is tracking keeps a little more: its people, not the neighbourhood (CBSafetyGate.CanTalkTo).
  public static func TalkTrackedClearance() -> Float = 10.0
  // The parley (Reactions/Director.reds, TryGangHostile; Reactions/StreetTalk.reds, CBTalkOnGreet): how
  // close an empty-handed V may be to a ganger who has warned V, and for how long after the warning
  // (settled ticks), before they draw; and the odds of talking them down, from the nerve gap like
  // intimidation, held between the two bounds.
  public static func ParleyRange() -> Float = 20.0
  public static func ParleyMaxTicks() -> Int32 = 30
  public static func ParleyBase() -> Float = 0.4
  public static func ParleyScale() -> Float = 1.2
  public static func ParleyMin() -> Float = 0.1
  public static func ParleyMax() -> Float = 0.85
  public static func TalkFacingDot() -> Float = 0.9
  // The same reason for no prompt is logged at most this often (seconds).
  public static func TalkWhyLogSeconds() -> Float = 8.0
  // How long after telling V why somebody will not talk before another is told (StreetTalk Explain, 2.1.0).
  public static func TalkExplainGapSeconds() -> Float = 30.0
  // Cyberbane's hub id on the UIInteractions blackboard: far from the small numbers the game's own use.
  public static func TalkHubId() -> Int32 = 1128415301
  // The exchange: V's line, a beat, then theirs.
  public static func TalkAnswerDelay() -> Float = 1.2
  public static func TalkLineSeconds() -> Float = 2.4
  public static func TalkReplySeconds() -> Float = 4.0
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
  // A save found to be another character's drops a Killer Rival it got from the shared death
  // ledger only when that death is further ahead of the save's own clock than this (1.8.3). A V
  // who died and reloaded is behind their own death by however long since the last save, which
  // is minutes with autosaves; another character's deaths are usually days or weeks away.
  public static func ForeignDeathMarginSeconds() -> Float = 86400.0

  // ---- Turf wars (Model/Territory.reds) -----------------------------------
  // What V costs a gang: each of their people put down, an officer or elite, a boss, a Rival of
  // theirs, a crew wiped out, their apex squad wiped out. Knocked out counts half.
  public static func GangLossMember() -> Float = 0.8
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
  // What share of its usual crew a gang at no strength at all would send (Spawn/Queue.reds,
  // CBCrewSizeFor, 1.9.5); in between it scales with strength, so at the floor (15) about three in five.
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
  // No closer to V than this, wherever V is standing. It was 30 m and measured from the place
  // itself, so V standing at the pin was too close for anybody ever to be put there (1.7.1).
  public static func LairMinDistance() -> Float = 10.0
  // Further than this from a waiting Rival who never noticed V, and they are taken back out.
  public static func LairLeaveDistance() -> Float = 160.0
  // Buying where a Rival is (the Hub's Ambush button, 1.8.2). A rank-one name costs about a mid gig's
  // pay, a gang's leader a good deal more, and well under the bounty on any of them.
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
  // 1.9.3. How long somebody V put down at their place is given to be logged as a mercy before the
  // place lets go of them; a third ring of spots to try; and when V, standing this close to the pin
  // with nobody placed for this many tries, is told why.
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

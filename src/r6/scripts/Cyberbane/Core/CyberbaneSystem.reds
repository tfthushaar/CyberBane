// Cyberbane - Per-save system (spec §6.2, §5.3)
//
// The ScriptableSystem owns all per-save state and is the entry point for the
// rest of the mod. It is fetched with CyberbaneSystem.Get(game).

public class CyberbaneSystem extends ScriptableSystem {
  private persistent let m_schemaVersion: Int32;          // starts at 1 after first init
  private persistent let m_playthroughId: CName;          // e.g. n"CB_7F3A19C2"
  private persistent let m_bootstrapped: Bool;
  private persistent let m_installedAt: Float;            // game seconds

  // Global accumulators (displayed values are derived, spec §8).
  private persistent let m_renownPoints: Float;
  private persistent let m_killDreadPoints: Float;
  private persistent let m_deedDreadPoints: Float;
  private persistent let m_heatPoints: Float;
  private persistent let m_archetype: array<Float>;       // index = ECBArchetype
  private persistent let m_primaryArchetype: Int32;       // -1 = Unknown
  private persistent let m_lastNotifiedTier: Int32;       // for rank-up notifications
  private persistent let m_code: Float;                   // -100..100 merc Code axis (Cyberpsycho <-> Professional)
  private persistent let m_lastHeatStage: Int32;          // for heat-point accrual
  private persistent let m_lastSlowTickAt: Float;         // game seconds of last slow tick

  private persistent let m_factions: array<ref<CBFactionState>>;
  private persistent let m_districts: array<ref<CBDistrictState>>;
  private persistent let m_deedsDone: array<CName>;
  private persistent let m_titles: array<CName>;
  private persistent let m_activeTitle: CName;            // n"" = auto
  private persistent let m_stats: ref<CBStats>;
  // Kill tallies by victim class. Declared here, directly on the system, rather than nested
  // inside CBStats: a persisted collection belongs on the ScriptableSystem, not inside a
  // persisted class (schema 3, see the note on CBStats).
  private persistent let m_killsByClass: array<Int32>;      // index = ECBVictimClass
  private persistent let m_rumors: array<ref<CBRumor>>;           // cap 64
  private persistent let m_nextRumorId: Int32;
  private persistent let m_rivals: array<ref<CBRival>>;           // cap 15 active + 32 archived
  private persistent let m_nextRivalId: Int32;
  private persistent let m_log: array<ref<CBLogEntry>>;           // cap 200, FIFO
  private persistent let m_appliedLedgerIds: array<Int32>;        // cap 100
  private persistent let m_cooldowns: ref<CBCooldowns>;
  private persistent let m_peaceDeals: array<ref<CBPeaceDeal>>;   // cap 16

  // Runtime-only (not persisted): derived-value engine + reaction infrastructure.
  private let m_score: ref<CBScoreEngine>;
  private let m_registry: ref<CBNpcRegistry>;
  private let m_director: ref<CBReactionDirector>;
  private let m_sessionStarted: Bool;
  private let m_tickGeneration: Int32;
  private let m_playerAttachCbId: Uint32;
  private let m_tickCount: Int32;             // monotonic ~1/second, for encounter timing
  private let m_encounter: ref<CBEncounter>;  // active combat episode
  private let m_hud: ref<CBHud>;              // the F7 reputation Hub (spec §12.1)
  private let m_threatBar: ref<CBThreatBar>;
  // One-shot clock measurement, session only. Every cooldown in the mod is in units of
  // TimeSystem.GetGameTimeStamp(), which is a native import, so no amount of reading the game's
  // scripts says whether it ticks in real seconds or in the compressed in-game clock. If it is
  // the latter, the ten minutes between encounters is nothing like ten minutes of play. This
  // measures it against the sim clock over sixty ticks and writes the ratio to the log once.
  // Last visible-chrome figure written to the log, so the line only appears when it moves.
  private let m_lastLoggedChrome: Int32;
  private let m_clockGame0: Float;
  private let m_clockSim0: Float;
  private let m_clockTicks: Int32;  // boss bar for whoever is hunting you
  private let m_disguiseFaction: CName;       // gang whose colours V is wearing (spec §9.3)
  private let m_disguiseStrength: Float;      // 0..1, how well the disguise reads
  private let m_activeSquadFaction: CName;    // faction of the hit squad currently out (for Hunter on escape)
  private let m_escapees: array<ref<CBEscapee>>;   // wounded enemies that ran (session-only, spec §10.2)
  private let m_activeRivalId: Int32;         // id of the Rival currently spawned as an encounter (0 = none)
  private let m_lastTickGameTime: Float;      // in-game seconds at the last processed tick (time-jump detector)
  private let m_streamSettleTicks: Int32;     // ticks to sit out after a transition / time jump (crash safety)
  private let m_attachCount: Int32;           // entities attached since the last tick (streaming-flood detector)
  // The car arrival in progress (spec §9.9). Session-only: a convoy half way through boarding
  // is not something that should survive a save, and the hunt timer will send another.
  private let m_pendingSquadFaction: CName;   // gang whose vendetta squad is on its way
  private let m_pendingSquadTicks: Int32;     // fast ticks until it arrives (shown in the Hub)
  private let m_pendingSquadStuck: Int32;    // ticks spent expired but unable to arrive
  // Whose turn it is next (Spawn/Queue.reds). Session-only: a queued encounter describes the
  // next few minutes, not the playthrough, and one restored from a save would fire into a
  // world that has moved on.
  // Three lanes: one Rival, one crew, one apex squad, each with its own clock. Flat scalars
  // per lane rather than an array, to match how the rest of this system stores small fixed
  // sets, and because arrays on a persisted system are the one thing that has bitten here.
  private let m_laneRivalId: Int32;
  private let m_laneRivalTicks: Int32;
  private let m_laneLastRival: Int32;
  private let m_laneSquadFaction: CName;
  private let m_laneSquadTicks: Int32;
  private let m_laneLastSquadFaction: CName;
  private let m_laneApexFaction: CName;
  private let m_laneApexTicks: Int32;
  private let m_laneLastApexFaction: CName;
  // Tick each lane last sent somebody. A spawn is queued, not instant: for a second or two
  // afterwards nothing is attached yet, so "is anyone of this kind alive" answers no and the
  // lane would cheerfully send a second one on top of the first.
  // Last tick each lane was still busy. Subtracting it from now gives how long since that
  // lane's encounter actually ended, which is what the gap between encounters is measured
  // from - the end of the last fight, not the moment the last one was sent.
  // A short window after asking the city to send a chase car, during which entities matching
  // what was asked for are claimed as ours (Spawn/VanillaChase.reds). The prevention system
  // returns a ticket and no way to ask what it spawned, so this is how they are found.
  private let m_adoptFaction: CName;
  private let m_adoptRecord: TweakDBID;
  private let m_adoptVehicle: TweakDBID;
  private let m_adoptTag: CName;
  private let m_adoptLeft: Int32;
  private let m_adoptUntilTick: Int32;
  private let m_chaseAwayTicks: Int32;   // consecutive ticks V has been clear of every hunter
  private let m_laneRivalFreed: Int32;
  private let m_laneSquadFreed: Int32;
  private let m_laneApexFreed: Int32;
  // How many encounters each lane has already sent today, and the day those counts belong to.
  // Persistent, so reloading a save does not hand the player a fresh day's worth.
  // Today's timetable. Parallel arrays directly on the system, which is the rule everywhere
  // here: an array nested inside a persisted class does not survive a save.
  // No negative default: redscript only takes plain constants here. Day 0 with an empty slot
  // list is indistinguishable from "never rolled", and CBScheduleTick rolls on an empty list
  // anyway, so this needs no sentinel.
  private persistent let m_schedDay: Int32;
  private persistent let m_slotLane: array<Int32>;
  private persistent let m_slotAt: array<Float>;     // in-game hour of day it is due
  private persistent let m_slotEnd: array<Float>;    // end of its sector; after this it is spent
  private persistent let m_slotSpent: array<Bool>;
  // Whether today's timetable has been built. Needed separately from the slot count: with every
  // per-day setting at zero a correct timetable is an empty one, and testing emptiness instead
  // would rebuild it on every tick for ever.
  private persistent let m_schedRolled: Bool;
  private persistent let m_laneDayRival: Int32;
  private persistent let m_laneDaySquad: Int32;
  private persistent let m_laneDayApex: Int32;
  private persistent let m_laneSentRival: Int32;
  private persistent let m_laneSentSquad: Int32;
  private persistent let m_laneSentApex: Int32;
  // Last tick each lane said out loud that it had nobody to send, so that stays rare.
  private let m_laneQuietRival: Int32;
  private let m_laneQuietSquad: Int32;
  private let m_laneQuietApex: Int32;
  private let m_laneRivalFired: Int32;
  private let m_laneSquadFired: Int32;
  private let m_laneApexFired: Int32;
  private let m_apexAnnounced: CName;   // gang already told about, so it is said once
  private let m_pendingApexStuck: Int32;     // same, for the apex appointment
  private let m_arrivalRecord: TweakDBID;     // which ganger to put in the seats
  private let m_arrivalCrew: Int32;           // how many were asked for
  private let m_arrivalTag: CName;            // squad tag the crew inherits
  private let m_arrivalCarId: EntityID;       // the car, once it exists
  private let m_arrivalSeats: Int32;          // seats being filled
  private let m_arrivalFilled: Int32;         // seats filled so far
  private let m_arrivalAge: Int32;            // ticks since the car was queued (stale guard)
  private let m_arrivalLeadRecord: TweakDBID; // the one who matters, if this convoy has one
  private let m_arrivalLeadTag: CName;        // and the tag that makes them matter
  private let m_arrivalFaction: CName;        // whose car this is, for picking role records
  private let m_arrivalRoleSquad: Bool;       // fill the seats by role rather than four alike
  private let m_squadAnchor: wref<ScriptedPuppet>;   // whose squad the rest of the team joins
  private let m_huntHoldReason: Int32;        // why no Rival can arrive right now (CBHold*)
  // Kills V has made recently, for Aura. Session-only: it describes the last minute, not the
  // playthrough. Counting V's own kills rather than scanning for nearby corpses is deliberate -
  // a kill V made was by definition next to V when it happened, and it needs no spatial query.
  private let m_recentKills: Int32;
  private let m_recentKillTick: Int32;
  private let m_pendingApexDriving: Bool;     // the apex clock is a drive, not a warning
  private let m_currentDistrict: CName;       // cached district, refreshed only on a stable slow sample (crash safety)
  private let m_content: ref<CyberbaneContent>;   // content service, fetched once from a stable tick then reused (crash safety)
  private let m_callbacksRegistered: Bool;    // Codeware entity + input callbacks registered; retried until it sticks
  private let m_hubKeyDown: Bool;             // Hub key debounce: some setups deliver only Press, some only Release
  private let m_pendingApexFaction: CName;    // gang whose apex has been announced and is walking in
  private let m_pendingApexTicks: Int32;      // fast ticks left on that warning (session-only)
  // Fast ticks left on the "V is working quietly" hold. The game only reports the Stealth
  // combat state while V is actually crouched, so standing up to cross a room would otherwise
  // open a window for someone to walk in. Session-only.
  private let m_stealthHoldTicks: Int32;
  private let m_pendingRivalSweep: Bool;      // a CB_Rival delete deferred out of an entity callback (crash safety)
  private let m_inSafeZone: Bool;             // player is in a game-tagged safe area: reactions stand down (spec §16)

  // ---- Access -----------------------------------------------------------
  public static func Get(game: GameInstance) -> ref<CyberbaneSystem> {
    // The systems container can be null during world transitions; never deref it then (crash safety).
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CyberbaneSystem") as CyberbaneSystem;
  }

  // ---- Lifecycle --------------------------------------------------------
  private func OnAttach() -> Void {
    CBLog.Info(n"Core", s"Cyberbane \(CyberbaneVersion()) (schema \(CyberbaneSchemaVersion())) attaching.");
    this.EnsureSettings();
    this.Initialize();
    this.RegisterPlayerAttach();
    this.EnsureCallbacks();   // so the Hub key works even if the player-attached callback is missed
  }

  // The player-puppet-attached callback is the reliable "session is ready" signal
  // (used by Codeware too). It fires on new game, load and respawn.
  private func RegisterPlayerAttach() -> Void {
    let ps = GameInstance.GetPlayerSystem(this.GetGameInstance());
    if IsDefined(ps) {
      this.m_playerAttachCbId = ps.RegisterPlayerPuppetAttachedCallback(this, n"OnCBPlayerAttached");
    }
  }

  private func OnCBPlayerAttached(player: ref<GameObject>) -> Void {
    this.StartSession();
  }

  // Register the Codeware callbacks: NPC tracking and the Hub key. Guarded and idempotent, and
  // called from OnAttach, from session start and from the tick. If the callback system is not up
  // yet at one of those points a later call still gets it, so the Hub key can never end up
  // silently unregistered (which is one way F7 appears to "do nothing").
  private func EnsureCallbacks() -> Void {
    if this.m_callbacksRegistered {
      return;
    }
    let cbs = GameInstance.GetCallbackSystem();
    if !IsDefined(cbs) {
      return;   // not available yet - a later call will register
    }
    cbs.RegisterCallback(n"Entity/Attached", this, n"OnCBEntityAttached");
    cbs.RegisterCallback(n"Input/Key", this, n"OnCBKeyInput");
    this.m_callbacksRegistered = true;
  }

  // Session start (spec §5.3): build runtime objects, register the entity callback
  // once, clean up stray Cyberbane spawns, and (re)start the fast tick.
  private func StartSession() -> Void {
    if !IsDefined(this.m_registry) {
      this.m_registry = new CBNpcRegistry();
    }
    if !IsDefined(this.m_director) {
      this.m_director = new CBReactionDirector();
    }
    this.EnsureCallbacks();
    if !this.m_sessionStarted {
      this.m_sessionStarted = true;
      let des = GameInstance.GetDynamicEntitySystem();
      if IsDefined(des) {
        des.DeleteTagged(n"Cyberbane");
      }
      // Apply any deaths recorded in the global ledger for this playthrough.
      CBApplyDeathLedger(this, this.GetGameInstance());
      // And take any story characters off the Rival roster before they can be sent again.
      CBPruneUniqueRivals(this);
    }
    // Seed chrome once up front so it is current before the first slow refresh.
    CBUpdateChrome(this, this.GetGameInstance());

    // Bump the generation so any stale tick chain stops, then start a fresh one.
    this.m_tickGeneration += 1;
    this.ScheduleFastTick();
  }

  private cb func OnCBEntityAttached(event: ref<EntityLifecycleEvent>) -> Void {
    // Count every attach (before any guard) so the fast tick can tell when the world is
    // streaming heavily - a flood - and stand down even with no menu / time-jump signal.
    // Count people, not everything.
    //
    // This counter feeds the flood detector, whose job is to notice the engine rebuilding the
    // world and stand our native queries down until it is done. It was counting every entity
    // that streamed in: pedestrians, cars, parked bikes, props, vending machines, doors. The
    // threshold was chosen thinking about NPCs, so on any populated street it was tripped
    // continuously, and the stand-down it arms skips the whole tick body - the Rival clocks,
    // the Hub refresh, and the slow tick that drives hit squads and apex squads. The result
    // was a mod that did nothing at all while you walked anywhere interesting.
    //
    // Only puppets matter here, because they are what the gated queries actually touch.
    let attachedEntity = event.GetEntity();
    if IsDefined(attachedEntity as ScriptedPuppet) {
      this.m_attachCount += 1;
    }
    // Something the city sent on our behalf. Claiming it here is what makes it ours for every
    // other purpose, and it has to happen before anything below reads its tags.
    if CBTryAdoptChaseEntity(this, this.GetGameInstance(), attachedEntity) {
      return;
    }
    if !IsDefined(this.m_registry) {
      return;
    }
    // A car we sent. Its seat count is only readable now it exists, so this is where the crew
    // is queued (see Arrival.reds).
    let car = event.GetEntity() as VehicleObject;
    if IsDefined(car) {
      let desCar = GameInstance.GetDynamicEntitySystem();
      if IsDefined(desCar) && desCar.IsTagged(car.GetEntityID(), n"CB_Car")
         && CBWorldStable(this.GetGameInstance()) {
        CBOnArrivalCarAttached(this, this.GetGameInstance(), car);
      }
    }
    let puppet = event.GetEntity() as ScriptedPuppet;
    if IsDefined(puppet) {
      // Registering is always safe and must always happen. Add() stores a weak reference and
      // checks IsPlayer; cbSeenTick is a plain field write. Neither reads a native component,
      // and CBNpcSafe holds every reader off for NpcReadyTicks afterwards anyway.
      //
      // This used to sit behind CBWorldStable, which meant any NPC that attached while the
      // world was busy was dropped and never looked at again - there is no second chance,
      // nothing re-scans. Crowds stream in constantly while you walk, so a large share of
      // them were invisible to Cyberbane for their whole life, and the city appeared to
      // ignore V no matter how frightening V was.
      this.m_registry.Add(puppet);
      puppet.cbSeenTick = this.m_tickCount;   // leave it alone until its components are ready

      // Everything below queries the dynamic entity system and writes attitude and stats on a
      // freshly attached puppet, which is the part that is genuinely unsafe mid-stream.
      if !CBWorldStable(this.GetGameInstance()) {
        return;
      }
      // Our own spawned hostiles (hit squads, Rival encounters) start aggressive toward V.
      let des = GameInstance.GetDynamicEntitySystem();
      if IsDefined(des) {
        let id = puppet.GetEntityID();
        // Crew first: they belong in a seat, not running at V on foot from where the car is.
        let riding = des.IsTagged(id, n"CB_Crew");
        if riding {
          CBOnArrivalCrewAttached(this, this.GetGameInstance(), puppet);
        }
        // Everything else about one of ours - turning it hostile, telling it to come, its
        // buffs, its kit, its squad and its health bar - is deferred rather than done here.
        //
        // This is why spawned enemies stood around doing nothing until V walked into them.
        // At the instant an entity attaches its native components do not exist yet: the
        // attitude agent and the AI controller both come back null for the first few frames.
        // Every one of those calls checks IsDefined and returns quietly when it is missing, so
        // the hostility and the order to hunt were being dropped on the floor in silence and
        // the NPC carried on as whatever it was spawned as - a neutral NCPD officer standing
        // in the street. The mod already had the rule for this and was not following it:
        // CBNpcSafe holds every other reader off for NpcReadyTicks after attach, and this path
        // ignored it.
        if des.IsTagged(id, n"CB_Squad") || des.IsTagged(id, n"CB_Rival")
           || des.IsTagged(id, n"CB_Apex") || des.IsTagged(id, n"CB_Escort") {
          CBScheduleSpawnSetup(this.GetGameInstance(), id, riding);
        }

        // Somebody who runs a crew should take more killing than the rank and file do.
        if des.IsTagged(id, n"CB_Rival") && this.GetActiveRivalId() > 0 {
          let who = this.FindRivalById(this.GetActiveRivalId());
          if IsDefined(who) {
            // Built to apex grade, scaled by how far up the ladder they have climbed: every
            // escape and every mercy makes the one who comes back harder than the one who
            // left. The chair-of-the-crew buff goes on top of that.
            CBApplyRivalApexBuff(this, this.GetGameInstance(), puppet, who);
            CBApplyRivalRoleBuff(this, this.GetGameInstance(), puppet, CBRivalRole(this, who));
            // Every Rival gets the bar, because every Rival is built to apex grade.
            if CBRivalGrade(who) >= CBConfig.RivalBossBarGrade() {
              CBShowBossBar(puppet);
            }
          }
        }
      }
    }
  }

  // ---- Car arrivals (spec §9.9) ----
  //
  // Deliberately small and blunt: a single convoy, a seat counter, and a hard clear. A missed
  // step leaves the fields set, so SetPendingArrival refuses to start a second convoy and the
  // next CBArrivalSweep tick clears a stale one rather than letting it block arrivals forever.
  public func HasPendingArrival() -> Bool {
    return TDBID.IsValid(this.m_arrivalRecord);
  }

  public func SetPendingArrival(record: TweakDBID, crew: Int32, squadTag: CName,
                               leadRecord: TweakDBID, leadTag: CName) -> Void {
    this.m_arrivalRecord = record;
    this.m_arrivalCrew = crew;
    this.m_arrivalTag = squadTag;
    this.m_arrivalLeadRecord = leadRecord;
    this.m_arrivalLeadTag = leadTag;
    let noCar: EntityID;   // a default EntityID is the undefined one; there is no None()
    this.m_arrivalCarId = noCar;
    this.m_arrivalSeats = 0;
    this.m_arrivalFilled = 0;
    this.m_arrivalAge = 0;
    this.m_arrivalFaction = n"";
    this.m_arrivalRoleSquad = false;
  }

  public func GetPendingArrivalLeadRecord() -> TweakDBID {
    return this.m_arrivalLeadRecord;
  }

  public func GetPendingArrivalLeadTag() -> CName {
    return this.m_arrivalLeadTag;
  }

  // A car asked for out of sight is not guaranteed to appear: if the point turns out to be in
  // view, or the world moves on, the engine simply never attaches it. Without this the pending
  // convoy would sit there forever and every later arrival would be refused as a double
  // booking - the one failure in this whole path that would be permanent rather than a missed
  // cycle. Age it out and let the next encounter try again.
  public func AgePendingArrival() -> Void {
    if !this.HasPendingArrival() {
      return;
    }
    this.m_arrivalAge += 1;
    if this.m_arrivalAge > CBConfig.ArrivalStaleTicks() {
      CBLog.Info(n"Spawn", "A car that was sent never turned up; clearing it.");
      this.ClearPendingArrival();
    }
  }

  public func GetPendingArrivalRecord() -> TweakDBID {
    return this.m_arrivalRecord;
  }

  public func GetPendingArrivalCrew() -> Int32 {
    return this.m_arrivalCrew;
  }

  public func GetPendingArrivalTag() -> CName {
    return this.m_arrivalTag;
  }

  public func BeginArrivalBoarding(carId: EntityID, seats: Int32) -> Void {
    this.m_arrivalCarId = carId;
    this.m_arrivalSeats = seats;
    this.m_arrivalFilled = 0;
  }

  public func GetArrivalCarId() -> EntityID {
    return this.m_arrivalCarId;
  }

  // Hand out the next seat, or -1 when the car is full.
  public func TakeArrivalSeat() -> Int32 {
    if this.m_arrivalFilled >= this.m_arrivalSeats {
      return -1;
    }
    let slot = this.m_arrivalFilled;
    this.m_arrivalFilled += 1;
    return slot;
  }

  public func IsArrivalFull() -> Bool {
    return this.m_arrivalSeats > 0 && this.m_arrivalFilled >= this.m_arrivalSeats;
  }

  // Why every Rival clock is stopped, if it is. Read by the Hub so it can say what it is
  // waiting for rather than show a number that is not moving.
  public func GetHuntHoldReason() -> Int32 {
    return this.m_huntHoldReason;
  }

  public func SetHuntHoldReason(reason: Int32) -> Void {
    this.m_huntHoldReason = reason;
  }

  // ---- Apex squad ----
  public func GetSquadAnchor() -> wref<ScriptedPuppet> {
    return this.m_squadAnchor;
  }

  public func SetSquadAnchor(puppet: wref<ScriptedPuppet>) -> Void {
    this.m_squadAnchor = puppet;
  }

  // Called when a new group is dispatched. Without it, a crew arriving later would be joined
  // into whatever squad the last survivor of the previous one is still anchoring.
  public func ClearSquadAnchor() -> Void {
    this.m_squadAnchor = null;
  }

  public func GetPendingArrivalFaction() -> CName {
    return this.m_arrivalFaction;
  }

  public func IsArrivalRoleSquad() -> Bool {
    return this.m_arrivalRoleSquad;
  }

  public func MarkArrivalRoleSquad(faction: CName) -> Void {
    this.m_arrivalFaction = faction;
    this.m_arrivalRoleSquad = true;
  }

  public func ClearPendingArrival() -> Void {
    this.m_arrivalRecord = TDBID.None();
    this.m_arrivalLeadRecord = TDBID.None();
    this.m_arrivalLeadTag = n"";
    this.m_arrivalCrew = 0;
    this.m_arrivalTag = n"";
    this.m_arrivalAge = 0;
    let noCar: EntityID;   // a default EntityID is the undefined one; there is no None()
    this.m_arrivalCarId = noCar;
    this.m_arrivalSeats = 0;
    this.m_arrivalFilled = 0;
  }

  // Hub toggle (spec §12.1). Fires on key release so a tap advances exactly one tab.
  private cb func OnCBKeyInput(event: ref<KeyInputEvent>) -> Void {
    if !Equals(event.GetKey(), this.GetHubKey()) {
      return;
    }
    // Act on the press, and fall back to the release for setups that never deliver a press for
    // this key - one reported way the Hub key appears to do nothing. The down-flag keeps a normal
    // press+release pair from advancing two tabs, and stops a held key from repeating.
    let action = event.GetAction();
    if Equals(action, EInputAction.IACT_Press) {
      if this.m_hubKeyDown {
        return;
      }
      this.m_hubKeyDown = true;
    } else {
      if !Equals(action, EInputAction.IACT_Release) {
        return;   // repeats and anything else
      }
      let pressWasSeen = this.m_hubKeyDown;
      this.m_hubKeyDown = false;
      if pressWasSeen {
        return;   // already handled on the press
      }
    }
    if !IsDefined(this.m_hud) {
      this.m_hud = new CBHud();
    }
    let game = this.GetGameInstance();
    // Shift + Hub key while the Hub is open brokers peace with the worst gang you can
    // buy off, without changing tab (spec §11.3 Hub action).
    if event.IsShiftDown() && this.m_hud.IsOpen() {
      // On the Rivals screen the same shortcut wipes your Rivals instead of brokering peace.
      // Updating the mod mid-playthrough can leave Rivals built from records that no longer
      // make sense, and there was no way to clear them without starting a new save.
      if this.m_hud.GetTab() == CBHudRivalsTab() {
        let removed = CBPurgeRivals(this, game);
        CBShowMessage(game, s"Cyberbane: cleared \(removed) rivals.", 4.0);
      } else {
        CBBrokerPeaceBest(this, game);
      }
      this.m_hud.Refresh(this, game);
      return;
    }
    // Ctrl + Hub key cycles the active title (Auto -> each earned title -> Auto).
    if event.IsControlDown() && this.m_hud.IsOpen() {
      CBCycleActiveTitle(this);
      this.m_hud.Refresh(this, game);
      // Say what just happened.
      //
      // The cycling itself always worked and persisted, but it was completely silent: unless
      // you happened to be looking at the Titles tab or the header, pressing the shortcut
      // looked exactly like pressing nothing, which makes a working feature indistinguishable
      // from a broken one.
      if CBToastsOn() {
        let picked = this.GetActiveTitle();
        if Equals(picked, n"") {
          CBShowMessage(game, "Cyberbane: title set to automatic, the best one you have earned.", 4.0);
        } else {
          let named = CBTitleDisplayById(this, this.GetContent(), picked);
          CBShowMessage(game, "Cyberbane: you are going by " + named + " now.", 4.0);
        }
      }
      return;
    }
    // Don't pop the Hub open mid-fight, but always allow closing it.
    if !this.m_hud.IsOpen() {
      let player = GetPlayer(game);
      if IsDefined(player) && player.IsInCombat() {
        return;
      }
    }
    this.m_hud.Advance(this, game);
  }

  private func GetHubKey() -> EInputKey {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      let k = rt.GetSettings().hubKey;
      // A settings store that has not filled in yet reads as IK_None, which would leave the Hub
      // with no key at all and look exactly like "F7 does nothing". Fall back to F7 instead.
      //
      // Escape is refused outright. The game owns it, and a Hub that answers to it fights the
      // pause menu over every press. It should not be reachable through the dropdown, but a
      // stored value is a stored value and this costs one comparison.
      if NotEquals(k, EInputKey.IK_None) && NotEquals(k, EInputKey.IK_Escape) {
        return k;
      }
    }
    return EInputKey.IK_F7;
  }

  // Re-render the Hub once a tick while it is open.
  //
  // The Hub drew itself once when opened and then sat there, so every countdown on it was a
  // snapshot from the moment it was opened. That is the whole of the "static time" report: the
  // numbers were right when they were drawn and then never moved. Refresh is the same call the
  // Hub already uses after an action, so this adds no new drawing path.
  private func TickHub(game: GameInstance) -> Void {
    if !IsDefined(this.m_hud) || !this.m_hud.IsOpen() {
      return;
    }
    this.m_hud.Refresh(this, game);
  }

  private func ScheduleFastTick() -> Void {
    let ds = GameInstance.GetDelaySystem(this.GetGameInstance());
    if !IsDefined(ds) {
      return;
    }
    let cb = new CBFastTickCallback();
    cb.game = this.GetGameInstance();
    cb.generation = this.m_tickGeneration;
    ds.DelayCallback(cb, CBConfig.FastTickSeconds(), false);
  }

  // Called by CBFastTickCallback. Stale generations (from a previous session) stop.
  public func OnFastTick(generation: Int32) -> Void {
    if generation != this.m_tickGeneration {
      return;
    }
    let game = this.GetGameInstance();

    // Crash safety (spec §16): stand down during loading, fast travel, time skips, ripperdoc
    // installs, menus and scripted scenes. The engine tears the world down and rebuilds it
    // across those (the resource-streaming "flood"), and running our native NPC / entity /
    // spawn queries mid-stream reads a half-built or freed native object and crashes - seen as
    // a dynamicBuffer assert and as an access violation in DelaySystem/Tick. We keep the tick
    // chain alive and arm a settle window so we resume only once the world is back and the
    // flood has drained, not the instant the loading screen clears.

    // No controllable player means a load / teleport / fast-travel is in flight - the biggest
    // floods. Cover the whole thing.
    let player = GetPlayer(game);
    if !IsDefined(player) {
      this.m_streamSettleTicks = CBConfig.FloodSettleTicks();
      this.ScheduleFastTick();
      return;
    }
    // A menu / loading screen / scripted scene (incl. the ripperdoc chair) is up: stand down,
    // and keep whatever longer flood settle is already armed.
    if !CBWorldStable(game) {
      if this.m_streamSettleTicks < CBConfig.StreamSettleTicks() {
        this.m_streamSettleTicks = CBConfig.StreamSettleTicks();
      }
      this.ScheduleFastTick();
      return;
    }

    // Heavy entity streaming since the last tick (a flood) even with no menu / time-jump signal
    // - e.g. walking a dense district or a scene loading around you. Stand down until it drains.
    // The counter is read and reset every tick.
    // Heavy streaming no longer stops the whole tick.
    //
    // This heuristic has now caused three separate rounds of "nothing in the mod happens", and
    // the last one is the clearest: arrivals landed while the player stood still talking about
    // the bug, and not while they walked around the city. That is this check, exactly.
    //
    // The reason it was wrong is that it was never the real safety gate. Loads, fast travels,
    // menus, scenes and time jumps all announce themselves properly through the player handle,
    // CBWorldStable and the game clock, and those still hard-stop the tick above. Counting
    // attaches was a guess at "something might be streaming", and it was being used to stand
    // down scheduling and timekeeping that touch no engine object at all.
    //
    // So it now does the one job it can justify: skipping the Director's walk over every
    // registered NPC, which is the genuinely heavy native work. Everything else runs. The
    // spawn path keeps its own CBWorldStable check, so an arrival still refuses to land in a
    // world that is not ready - it simply reschedules instead of the whole mod going quiet.
    let attached = this.m_attachCount;
    this.m_attachCount = 0;
    let heavyStreaming = attached >= CBConfig.FloodAttachThreshold();

    // A large jump in the in-game clock since the last processed tick means a time skip just
    // happened (Skip Time, fast travel, a ripperdoc install) - each kicks off a streaming flood
    // that runs on well after the clock moves and the UI clears, so cover it fully.
    let nowGT = CBGameSeconds(game);
    if this.m_lastTickGameTime > 0.0 && (nowGT - this.m_lastTickGameTime) > CBConfig.TimeJumpSettleSeconds() {
      this.m_streamSettleTicks = CBConfig.FloodSettleTicks();
    }
    this.m_lastTickGameTime = nowGT;
    if this.m_streamSettleTicks > 0 {
      this.m_streamSettleTicks -= 1;
      // Keep our own bookkeeping moving while the world settles.
      //
      // Standing every system down was over-broad. Counting a timer towards zero is arithmetic
      // on fields we own: it reads no native object and cannot be the thing that crashes. Only
      // the arrival itself needs a settled world, and that is gated separately inside
      // CBSpawnGroup. Freezing the clocks as well is what made a settle window indistinguishable
      // from the mod being broken, because an appointment that never approaches never arrives.
      CBTickClocksOnly(this);
      this.SetHuntHoldReason(CBHoldWorldBusy());
      this.ScheduleFastTick();
      return;
    }

    // Warm the content cache from this confirmed-stable tick: the one real service-container
    // lookup happens here, in a safe context, so the slow tick can reuse the cached reference
    // instead of re-locking a possibly-dead container (crash safety).
    this.GetContent();
    this.EnsureCallbacks();   // last-resort retry if the callback system was not up earlier

    // Carry out any entity cleanup that was deferred out of a lifecycle callback. This tick
    // is settled, so the engine is no longer mid-teardown on the entity being removed.
    if this.m_pendingRivalSweep {
      this.m_pendingRivalSweep = false;
      let des = GameInstance.GetDynamicEntitySystem();
      if IsDefined(des) {
        des.DeleteTagged(n"CB_Rival");
      }
    }

    this.m_tickCount += 1;
    // Safe-area check every tick, not on the slow sample: you can walk into a bar or a
    // clinic in well under ten seconds, and the reaction systems read this.
    this.m_inSafeZone = CBPlayerInSafeZone(game);
    // The player/world sampling (chrome, look, menace, Street Cred + Heat, current district)
    // runs only on this slow sample, and only on a stable, non-flood tick reached above - so the
    // Prevention-system district/heat queries never fire mid-stream. The director reads the
    // cached district rather than querying every tick.
    if this.m_tickCount % 10 == 0 && !heavyStreaming {
      CBRefreshLiveInputs(this, game);
      CBUpdateChrome(this, game);
      CBUpdateLook(this, game);
      CBUpdateMenace(this, game);
      this.m_currentDistrict = CBCurrentDistrict(game);
    }
    CBEncounterTick(this, game);
    CBSparedSweep(this, game);          // mercy the hit hook did not see (spec §10.2)
    CBProcessEscapees(this, game);
    CBProcessPendingApex(this, game);   // announced apex walks in a beat after the warning
    CBProcessPendingSquad(this, game);  // and a vendetta squad arrives when its timer runs out
    this.AgePendingArrival();           // forget a car that was sent and never arrived
    this.TickHub(game);                 // live countdowns while the Hub is open
    // The bar for whoever is hunting you. Cheap: it reads one stat pool and resizes one
    // rectangle, and hides itself the moment its target is gone.
    if CBThreatBarOn() {
      this.GetThreatBar().Update(this, game);
    }
    this.RefreshStealthHold(game);      // before anything that might send someone in
    CBEncounterQueueTick(this, game);   // three lanes, three clocks: who is next
    if this.m_tickCount % CBConfig.ChaseRefreshEveryTicks() == 0 {
      CBChaseRefreshTick(this, game);   // keep whoever was sent actually coming after you
    }
    CBRivalHuntTick(this, game);        // confirms a queued rival actually arrived
    CBPanicDrivingTick(this, game, this.m_tickCount);
    this.CheckSlowTick(game);
    if IsDefined(this.m_director) && !heavyStreaming {
      this.m_director.Tick(game);
    }
    this.MeasureClocks(game);
    this.ScheduleFastTick();
  }

  // Runs for the first sixty ticks of a session and then never again.
  private func MeasureClocks(game: GameInstance) -> Void {
    if this.m_clockTicks < 0 {
      return;
    }
    let ts = GameInstance.GetTimeSystem(game);
    if !IsDefined(ts) {
      return;
    }
    let g = ts.GetGameTimeStamp();
    let s = EngineTime.ToFloat(ts.GetSimTime());
    if this.m_clockTicks == 0 {
      this.m_clockGame0 = g;
      this.m_clockSim0 = s;
      this.m_clockTicks = 1;
      return;
    }
    this.m_clockTicks += 1;
    if this.m_clockTicks < 60 {
      return;
    }
    this.m_clockTicks = -1;   // done for this session
    let dg = g - this.m_clockGame0;
    let ds = s - this.m_clockSim0;
    let ratio = ds > 0.0 ? dg / ds : 0.0;
    // Kept, so anything showing a game-clock duration can state it in the player's seconds.
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) {
      rt.SetClockRatio(ratio);
    }
    CBLog.Info(n"Core", s"Clock check: game \(dg)s vs sim \(ds)s over 60 ticks (ratio \(ratio)). 1.0 means cooldowns are in real seconds.");
    // While we have a one-shot slot: what the game tags V's clothes with. The concealment
    // rules key off which slots are filled because sleeve length is not in TweakDB, and this
    // is the only way to find out whether the real visual tags could do better.
    CBLogEquippedTags(game);
  }

  public func GetLastLoggedChrome() -> Int32 {
    return this.m_lastLoggedChrome;
  }

  public func SetLastLoggedChrome(v: Int32) -> Void {
    this.m_lastLoggedChrome = v;
  }

  public func GetTickCount() -> Int32 {
    return this.m_tickCount;
  }

  public func GetThreatBar() -> ref<CBThreatBar> {
    if !IsDefined(this.m_threatBar) {
      this.m_threatBar = new CBThreatBar();
    }
    return this.m_threatBar;
  }

  // Called from CBApplyKill. The window is checked on read rather than cleared on a timer, so
  // this cannot leave a stale count behind if the tick is interrupted.
  public func NoteRecentKill() -> Void {
    if (this.m_tickCount - this.m_recentKillTick) > CBConfig.AuraKillWindowTicks() {
      this.m_recentKills = 0;
    }
    this.m_recentKills += 1;
    this.m_recentKillTick = this.m_tickCount;
  }

  public func GetRecentKills() -> Int32 {
    if (this.m_tickCount - this.m_recentKillTick) > CBConfig.AuraKillWindowTicks() {
      return 0;
    }
    return this.m_recentKills;
  }

  // Cached current district (refreshed on the slow sample). Reading this instead of querying
  // the Prevention system every tick keeps that query off the hot path during streaming.
  public func GetCurrentDistrict() -> CName {
    return this.m_currentDistrict;
  }

  // ---- Kill tallies (spec §8.2) -----------------------------------------
  public func AddKillByClass(victimClass: Int32) -> Void {
    if victimClass >= 0 && victimClass < ArraySize(this.m_killsByClass) {
      this.m_killsByClass[victimClass] += 1;
    }
  }

  public func GetKillsByClass(victimClass: Int32) -> Int32 {
    if victimClass >= 0 && victimClass < ArraySize(this.m_killsByClass) {
      return this.m_killsByClass[victimClass];
    }
    return 0;
  }

  // Total lethal kills across all victim classes (for the mercy ratio, spec §8.2).
  public func TotalKills() -> Int32 {
    let total = 0;
    let i = 0;
    while i < ArraySize(this.m_killsByClass) {
      total += this.m_killsByClass[i];
      i += 1;
    }
    return total;
  }

  public func GetApexAnnounced() -> CName {
    return this.m_apexAnnounced;
  }

  public func SetApexAnnounced(faction: CName) -> Void {
    this.m_apexAnnounced = faction;
  }

  // ---- Who is next, per lane (spec §9.9) ---------------------------------
  public func GetLaneTicks(lane: Int32) -> Int32 {
    if lane == CBLaneRival() { return this.m_laneRivalTicks; }
    if lane == CBLaneApex() { return this.m_laneApexTicks; }
    return this.m_laneSquadTicks;
  }

  // The gang this lane is bringing. Empty for a Rival lane, which carries an id instead.
  public func GetLaneTarget(lane: Int32) -> CName {
    if lane == CBLaneRival() { return n""; }
    if lane == CBLaneApex() { return this.m_laneApexFaction; }
    return this.m_laneSquadFaction;
  }

  public func GetLaneRivalId(lane: Int32) -> Int32 {
    return lane == CBLaneRival() ? this.m_laneRivalId : 0;
  }

  // ---- Adopting what the city spawns for us ----
  public func OpenAdoption(faction: CName, crewRecord: TweakDBID, vehicle: TweakDBID, tag: CName, count: Int32) -> Void {
    this.m_adoptFaction = faction;
    this.m_adoptRecord = crewRecord;
    this.m_adoptVehicle = vehicle;
    this.m_adoptTag = tag;
    this.m_adoptLeft = count;
    this.m_adoptUntilTick = this.m_tickCount + CBConfig.AdoptionWindowTicks();
  }

  public func IsAdoptionOpen() -> Bool {
    return this.m_adoptLeft > 0 && this.m_tickCount <= this.m_adoptUntilTick;
  }

  public func GetAdoptFaction() -> CName {
    return this.m_adoptFaction;
  }

  public func GetAdoptRecord() -> TweakDBID {
    return this.m_adoptRecord;
  }

  public func GetAdoptVehicle() -> TweakDBID {
    return this.m_adoptVehicle;
  }

  public func GetAdoptTag() -> CName {
    return this.m_adoptTag;
  }

  // Claim one seat, or -1 when there are none left.
  public func TakeAdoptionSlot() -> Int32 {
    if this.m_adoptLeft <= 0 {
      return -1;
    }
    this.m_adoptLeft -= 1;
    return this.m_adoptLeft;
  }

  public func BumpChaseAwayTicks() -> Int32 {
    this.m_chaseAwayTicks += 1;
    return this.m_chaseAwayTicks;
  }

  public func SetChaseAwayTicks(v: Int32) -> Void {
    this.m_chaseAwayTicks = v;
  }

  public func GetChaseAwayTicks() -> Int32 {
    return this.m_chaseAwayTicks;
  }

  public func GetLaneFreed(lane: Int32) -> Int32 {
    if lane == CBLaneRival() { return this.m_laneRivalFreed; }
    if lane == CBLaneApex() { return this.m_laneApexFreed; }
    return this.m_laneSquadFreed;
  }

  // Called every tick a lane is busy, so the stamp ends up being the last busy tick.
  public func MarkLaneBusy(lane: Int32) -> Void {
    if lane == CBLaneRival() {
      this.m_laneRivalFreed = this.m_tickCount;
    } else {
      if lane == CBLaneApex() {
        this.m_laneApexFreed = this.m_tickCount;
      } else {
        this.m_laneSquadFreed = this.m_tickCount;
      }
    }
  }

  // Roll the counter over when the calendar day changes, then report what is left.
  public func ScheduleDay() -> Int32 { return this.m_schedDay; }
  public func ScheduleRolled() -> Bool { return this.m_schedRolled; }
  public func SlotCount() -> Int32 { return ArraySize(this.m_slotLane); }
  public func SlotLane(i: Int32) -> Int32 { return this.m_slotLane[i]; }
  public func SlotAt(i: Int32) -> Float { return this.m_slotAt[i]; }
  public func SlotEnd(i: Int32) -> Float { return this.m_slotEnd[i]; }
  public func SlotSpent(i: Int32) -> Bool { return this.m_slotSpent[i]; }

  public func MoveSlot(i: Int32, at: Float) -> Void {
    if i >= 0 && i < ArraySize(this.m_slotAt) {
      this.m_slotAt[i] = at;
    }
  }

  public func SpendSlot(i: Int32) -> Void {
    if i >= 0 && i < ArraySize(this.m_slotSpent) {
      this.m_slotSpent[i] = true;
    }
  }

  public func ClearSchedule(day: Int32) -> Void {
    this.m_schedDay = day;
    this.m_schedRolled = true;
    ArrayClear(this.m_slotLane);
    ArrayClear(this.m_slotAt);
    ArrayClear(this.m_slotEnd);
    ArrayClear(this.m_slotSpent);
  }

  public func AddSlot(lane: Int32, at: Float, end: Float) -> Void {
    ArrayPush(this.m_slotLane, lane);
    ArrayPush(this.m_slotAt, at);
    ArrayPush(this.m_slotEnd, end);
    ArrayPush(this.m_slotSpent, false);
  }

  public func LaneSentToday(lane: Int32, today: Int32) -> Int32 {
    if lane == CBLaneRival() {
      if this.m_laneDayRival != today {
        this.m_laneDayRival = today;
        this.m_laneSentRival = 0;
      }
      return this.m_laneSentRival;
    }
    if lane == CBLaneApex() {
      if this.m_laneDayApex != today {
        this.m_laneDayApex = today;
        this.m_laneSentApex = 0;
      }
      return this.m_laneSentApex;
    }
    if this.m_laneDaySquad != today {
      this.m_laneDaySquad = today;
      this.m_laneSentSquad = 0;
    }
    return this.m_laneSentSquad;
  }

  public func NoteLaneSent(lane: Int32, today: Int32) -> Void {
    this.LaneSentToday(lane, today);   // rolls the day over first
    if lane == CBLaneRival() {
      this.m_laneSentRival += 1;
    } else {
      if lane == CBLaneApex() {
        this.m_laneSentApex += 1;
      } else {
        this.m_laneSentSquad += 1;
      }
    }
  }

  public func GetLaneQuietLogged(lane: Int32) -> Int32 {
    if lane == CBLaneRival() { return this.m_laneQuietRival; }
    if lane == CBLaneApex() { return this.m_laneQuietApex; }
    return this.m_laneQuietSquad;
  }

  public func SetLaneQuietLogged(lane: Int32, tick: Int32) -> Void {
    if lane == CBLaneRival() {
      this.m_laneQuietRival = tick;
    } else {
      if lane == CBLaneApex() {
        this.m_laneQuietApex = tick;
      } else {
        this.m_laneQuietSquad = tick;
      }
    }
  }

  public func GetLaneFired(lane: Int32) -> Int32 {
    if lane == CBLaneRival() { return this.m_laneRivalFired; }
    if lane == CBLaneApex() { return this.m_laneApexFired; }
    return this.m_laneSquadFired;
  }

  public func SetLaneFired(lane: Int32) -> Void {
    if lane == CBLaneRival() {
      this.m_laneRivalFired = this.m_tickCount;
    } else {
      if lane == CBLaneApex() {
        this.m_laneApexFired = this.m_tickCount;
      } else {
        this.m_laneSquadFired = this.m_tickCount;
      }
    }
  }

  public func GetLaneLastRival() -> Int32 {
    return this.m_laneLastRival;
  }

  public func SetLaneLastRival(id: Int32) -> Void {
    this.m_laneLastRival = id;
  }

  public func GetLaneLastFaction(lane: Int32) -> CName {
    return lane == CBLaneApex() ? this.m_laneLastApexFaction : this.m_laneLastSquadFaction;
  }

  public func SetLaneLastFaction(lane: Int32, faction: CName) -> Void {
    if lane == CBLaneApex() {
      this.m_laneLastApexFaction = faction;
    } else {
      this.m_laneLastSquadFaction = faction;
    }
  }

  public func SetLaneQueued(lane: Int32, faction: CName, rivalId: Int32, ticks: Int32) -> Void {
    if lane == CBLaneRival() {
      this.m_laneRivalId = rivalId;
      this.m_laneRivalTicks = ticks;
    } else {
      if lane == CBLaneApex() {
        this.m_laneApexFaction = faction;
        this.m_laneApexTicks = ticks;
      } else {
        this.m_laneSquadFaction = faction;
        this.m_laneSquadTicks = ticks;
      }
    }
  }

  public func SetLaneTicks(lane: Int32, ticks: Int32) -> Void {
    if lane == CBLaneRival() {
      this.m_laneRivalTicks = ticks;
    } else {
      if lane == CBLaneApex() {
        this.m_laneApexTicks = ticks;
      } else {
        this.m_laneSquadTicks = ticks;
      }
    }
  }

  public func TickDownLane(lane: Int32) -> Int32 {
    if lane == CBLaneRival() {
      if this.m_laneRivalTicks > 0 { this.m_laneRivalTicks -= 1; }
      return this.m_laneRivalTicks;
    }
    if lane == CBLaneApex() {
      if this.m_laneApexTicks > 0 { this.m_laneApexTicks -= 1; }
      return this.m_laneApexTicks;
    }
    if this.m_laneSquadTicks > 0 { this.m_laneSquadTicks -= 1; }
    return this.m_laneSquadTicks;
  }

  public func ClearLane(lane: Int32) -> Void {
    if lane == CBLaneRival() {
      this.m_laneRivalId = 0;
      this.m_laneRivalTicks = 0;
    } else {
      if lane == CBLaneApex() {
        this.m_laneApexFaction = n"";
        this.m_laneApexTicks = 0;
      } else {
        this.m_laneSquadFaction = n"";
        this.m_laneSquadTicks = 0;
      }
    }
  }

  // ---- Vendetta hit squads (spec §9.9) -----------------------------------
  // A gang at vendetta does not roll dice over whether to come for you; it is already coming,
  // and this is how long it takes them to get there. Session-only for the same reason as the
  // apex warning: a countdown restored from a save would fire into a world that has moved on.
  public func SetPendingSquad(faction: CName, ticks: Int32) -> Void {
    this.m_pendingSquadFaction = faction;
    this.m_pendingSquadTicks = ticks;
    this.m_pendingSquadStuck = 0;
  }

  public func GetPendingSquadFaction() -> CName {
    return this.m_pendingSquadFaction;
  }

  public func GetPendingSquadTicks() -> Int32 {
    return this.m_pendingSquadTicks;
  }

  public func TickDownPendingSquad() -> Int32 {
    if this.m_pendingSquadTicks > 0 {
      this.m_pendingSquadTicks -= 1;
    }
    return this.m_pendingSquadTicks;
  }

  public func ClearPendingSquad() -> Void {
    this.m_pendingSquadFaction = n"";
    this.m_pendingSquadTicks = 0;
    this.m_pendingSquadStuck = 0;
  }

  // An expired appointment that cannot be kept has to be able to give up.
  //
  // This is the deadlock that made hit squads stop happening for a whole session. The scheduler
  // refuses to arrange anything while one crew is pending, and the arrival holds - correctly -
  // if the moment is wrong: mid-fight, a quiet job, a safe area, a gig, or a squad still in the
  // world. But holding meant sitting at zero ticks forever, so one badly timed expiry
  // permanently blocked every future squad. Walking around City Center is exactly where that
  // bites, because a quest area there is easy to be standing in.
  //
  // Returns true when the caller should give up and let the scheduler start again.
  public func AgePendingSquadHold() -> Bool {
    this.m_pendingSquadStuck += 1;
    if this.m_pendingSquadStuck > CBConfig.PendingHoldGiveUpTicks() {
      CBLog.Info(n"Spawn", s"Crew from \(NameToString(this.m_pendingSquadFaction)) waited too long to find a moment; rescheduling.");
      this.ClearPendingSquad();
      return true;
    }
    return false;
  }

  public func AgePendingApexHold() -> Bool {
    this.m_pendingApexStuck += 1;
    if this.m_pendingApexStuck > CBConfig.PendingHoldGiveUpTicks() {
      CBLog.Info(n"Spawn", s"Apex squad from \(NameToString(this.m_pendingApexFaction)) waited too long; rescheduling.");
      this.SetPendingApex(n"", 0);
      this.m_pendingApexStuck = 0;
      return true;
    }
    return false;
  }

  // ---- Faction apex (spec §9.9) -----------------------------------------
  // Session-only: an announced apex that has not walked in yet. Nothing here is persisted, so
  // a save taken mid-warning simply forgets it rather than restoring a half-state.
  public func SetPendingApex(faction: CName, ticks: Int32) -> Void {
    this.m_pendingApexFaction = faction;
    this.m_pendingApexTicks = ticks;
    this.m_pendingApexDriving = false;
    this.m_pendingApexStuck = 0;
  }

  // The same clock, but for a squad that has already been dispatched and is on the road.
  //
  // The distinction matters more than it looks. Without it the clock running out is the signal
  // to send a squad, so re-arming it to show the drive would dispatch a second squad when it
  // expired, then a third, forever.
  public func SetPendingApexDriving(faction: CName, ticks: Int32) -> Void {
    this.m_pendingApexFaction = faction;
    this.m_pendingApexTicks = ticks;
    this.m_pendingApexDriving = true;
  }

  public func IsPendingApexDriving() -> Bool {
    return this.m_pendingApexDriving;
  }

  public func GetPendingApexFaction() -> CName {
    return this.m_pendingApexFaction;
  }

  // Counts the warning window down by one tick and reports what is left.
  // Fast ticks left before the announced apex walks in. Shown in the Hub.
  // True while V is in a stealth job, or was within the last few seconds.
  public func IsStealthHeld() -> Bool {
    return this.m_stealthHoldTicks > 0;
  }

  // Refreshed every fast tick. Seeing the Stealth state tops the window back up; losing it
  // just lets the window run down, which covers standing up to move between cover.
  public func RefreshStealthHold(game: GameInstance) -> Void {
    if CBPlayerInStealthState(game) {
      this.m_stealthHoldTicks = CBConfig.StealthHoldGraceTicks();
    } else {
      if this.m_stealthHoldTicks > 0 {
        this.m_stealthHoldTicks -= 1;
      }
    }
  }

  public func GetPendingApexTicks() -> Int32 {
    return this.m_pendingApexTicks;
  }

  public func TickDownPendingApex() -> Int32 {
    if this.m_pendingApexTicks > 0 {
      this.m_pendingApexTicks -= 1;
    }
    return this.m_pendingApexTicks;
  }

  // Player is somewhere the game treats as a safe area. The reaction systems (crowds,
  // gangs, morale, panic driving) stand down while this is true. Refreshed every tick.
  public func IsInSafeZone() -> Bool {
    return this.m_inSafeZone;
  }

  // Content service, fetched once (lazily) and cached. Everything goes through CBContent/this so
  // the tick never re-locks the global service container, which during a load or streaming can
  // return a dead-but-non-null reference that passes IsDefined and then crashes on the context
  // lock. The warm-up call lives on a confirmed-stable fast tick, so the one real lookup happens
  // in a safe context; the slow tick is held off until this is populated.
  public func GetContent() -> ref<CyberbaneContent> {
    if !IsDefined(this.m_content) {
      this.m_content = CyberbaneContent.Get();
    }
    return this.m_content;
  }

  public func HasContent() -> Bool {
    return IsDefined(this.m_content);
  }

  public func GetEncounter() -> ref<CBEncounter> {
    return this.m_encounter;
  }

  public func EnsureEncounter() -> ref<CBEncounter> {
    if !IsDefined(this.m_encounter) {
      this.m_encounter = new CBEncounter();
    }
    return this.m_encounter;
  }

  // Runs the slow tick (decay etc.) once per in-game hour, using the fast tick to
  // detect the boundary so time skips (sleep, fast travel) are handled correctly.
  private func CheckSlowTick(game: GameInstance) -> Void {
    let now = CBGameSeconds(game);
    if this.m_lastSlowTickAt <= 0.0 || now < this.m_lastSlowTickAt {
      this.m_lastSlowTickAt = now;
      return;
    }
    let elapsed = now - this.m_lastSlowTickAt;
    if elapsed >= CBConfig.SecondsPerHour() {
      this.OnSlowTick(elapsed / CBConfig.SecondsPerDay());
      this.m_lastSlowTickAt = now;
    }
  }

  // Slow tick (spec §5.5): decay now; rumor spread, tribute, title evaluation and
  // scheduling checks are added as those systems land.
  public func OnSlowTick(elapsedDays: Float) -> Void {
    // Hold the slow tick until the content cache is warm (populated by a stable fast tick). This
    // is what crashed before: the first slow tick after a load hit the global service container
    // while it was a dead-but-non-null reference. Now the slow tick only runs once the cached
    // content is in hand, and everything below reads that cache via CBContent, never the container.
    if !this.HasContent() {
      return;
    }
    let game = this.GetGameInstance();
    CBApplyDecay(this, elapsedDays);
    CBTributeTick(this, game);
    CBHitSquadTick(this, game);
    CBApexTick(this, game);
    CBEvaluateTitles(this, game);
    CBRumorTick(this, game);
    CBRivalProgressionTick(this, game);
    CBRivalEncounterTick(this, game);
    CBLog.Verbose(n"Model", s"Slow tick over \(elapsedDays) in-game days.");
  }

  public func GetRegistry() -> ref<CBNpcRegistry> {
    return this.m_registry;
  }

  // ---- Titles (spec §12.1, Appendix G) ----------------------------------
  public func HasTitle(id: CName) -> Bool {
    return ArrayContains(this.m_titles, id);
  }

  public func UnlockTitle(id: CName) -> Void {
    if !ArrayContains(this.m_titles, id) {
      ArrayPush(this.m_titles, id);
    }
  }

  public func GetUnlockedTitles() -> array<CName> {
    return this.m_titles;
  }

  public func SetActiveTitle(id: CName) -> Void {
    this.m_activeTitle = id;
  }

  // The active title: an explicit choice, else the highest-priority unlocked one.
  public func GetActiveTitle() -> CName {
    if NotEquals(this.m_activeTitle, n"") {
      return this.m_activeTitle;
    }
    let content = this.GetContent();
    let best = n"";
    let bestPriority = -1;
    for id in this.m_titles {
      let priority = 0;
      if IsDefined(content) {
        let def = content.GetTitle(id);
        if IsDefined(def) {
          priority = def.priority;
        }
      }
      if priority > bestPriority {
        bestPriority = priority;
        best = id;
      }
    }
    return best;
  }

  // ---- Legend Log (spec §6.5) -------------------------------------------
  public func AddLogEntry(entry: ref<CBLogEntry>) -> Void {
    if !IsDefined(entry) {
      return;
    }
    ArrayPush(this.m_log, entry);
    while ArraySize(this.m_log) > CBConfig.CapLog() {
      ArrayErase(this.m_log, 0);
    }
  }

  public func GetLog() -> array<ref<CBLogEntry>> {
    return this.m_log;
  }

  // ---- Rivals (spec §10) ------------------------------------------------
  public func AllocateRivalId() -> Int32 {
    let id = this.m_nextRivalId;
    this.m_nextRivalId += 1;
    return id;
  }

  public func GetRivals() -> array<ref<CBRival>> {
    return this.m_rivals;
  }

  public func AddRival(rival: ref<CBRival>) -> Void {
    if IsDefined(rival) {
      ArrayPush(this.m_rivals, rival);
      this.TrimArchivedRivals();
    }
  }

  // Rivals V has finished with (slain, retired) stay on as history, but only up to the
  // archive cap - the live cap in CBCreateRival counts Active/Hunting ones only, so
  // without this the store would grow for the whole playthrough and go into every save.
  public func TrimArchivedRivals() -> Void {
    let cap = CBConfig.CapArchivedRivals();
    let archived = 0;
    for r in this.m_rivals {
      if IsDefined(r) && this.IsArchivedRival(r) {
        archived += 1;
      }
    }
    while archived > cap {
      let i = 0;
      let removed = false;
      while i < ArraySize(this.m_rivals) && !removed {
        let r = this.m_rivals[i];
        if !IsDefined(r) || this.IsArchivedRival(r) {
          ArrayErase(this.m_rivals, i);   // oldest archived entry first
          removed = true;
        } else {
          i += 1;
        }
      }
      if !removed {
        return;   // nothing left to drop
      }
      archived -= 1;
    }
  }

  private func IsArchivedRival(r: ref<CBRival>) -> Bool {
    return r.state == EnumInt(ECBRivalState.Slain)
        || r.state == EnumInt(ECBRivalState.Retired);
  }

  // Forget every Rival. Returns how many went. Used by the Hub's clear shortcut, because an
  // update mid-playthrough can leave Rivals built from records that no longer make sense.
  public func ClearRivals() -> Int32 {
    let n = ArraySize(this.m_rivals);
    ArrayClear(this.m_rivals);
    return n;
  }

  public func FindRivalById(id: Int32) -> ref<CBRival> {
    for r in this.m_rivals {
      if IsDefined(r) && r.id == id {
        return r;
      }
    }
    return null;
  }

  // Ask for the spawned Rival to be swept away on the next settled tick. Used by code
  // running inside an entity's own lifecycle callback, where deleting it on the spot
  // would free it underneath the engine (crash safety).
  public func RequestRivalSweep() -> Void {
    this.m_pendingRivalSweep = true;
  }

  public func CountActiveRivals() -> Int32 {
    let n = 0;
    for r in this.m_rivals {
      if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        n += 1;
      }
    }
    return n;
  }

  public func CountActiveFactionRivals(faction: CName) -> Int32 {
    let n = 0;
    for r in this.m_rivals {
      if IsDefined(r) && Equals(r.faction, faction) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        n += 1;
      }
    }
    return n;
  }

  // ---- Rumors (spec §8.5) -----------------------------------------------
  public func AllocateRumorId() -> Int32 {
    let id = this.m_nextRumorId;
    this.m_nextRumorId += 1;
    return id;
  }
  // GetRumors returns the array *by value*, so callers must bind it to a local before
  // reading it. Anything that walks the store while it can also change (the slow tick's
  // expire/spread pass) must use GetRumorCount/GetRumorAt instead, which index the live
  // array - indexing the temporary that GetRumors returns hands back a handle into a copy
  // that is destroyed at the end of the statement (crash safety).
  public func GetRumors() -> array<ref<CBRumor>> {
    return this.m_rumors;
  }
  public func GetRumorCount() -> Int32 {
    return ArraySize(this.m_rumors);
  }
  public func GetRumorAt(index: Int32) -> ref<CBRumor> {
    if index >= 0 && index < ArraySize(this.m_rumors) {
      return this.m_rumors[index];
    }
    return null;
  }
  public func AddRumor(rumor: ref<CBRumor>) -> Void {
    if IsDefined(rumor) {
      ArrayPush(this.m_rumors, rumor);
    }
  }
  public func RemoveRumorAt(index: Int32) -> Void {
    if index >= 0 && index < ArraySize(this.m_rumors) {
      ArrayErase(this.m_rumors, index);
    }
  }

  // ---- Deeds (spec §7.2) ------------------------------------------------
  public func HasDeed(id: CName) -> Bool {
    return ArrayContains(this.m_deedsDone, id);
  }
  public func MarkDeed(id: CName) -> Void {
    if !ArrayContains(this.m_deedsDone, id) {
      ArrayPush(this.m_deedsDone, id);
    }
  }
  public func GetDeedsDone() -> array<CName> {
    return this.m_deedsDone;
  }

  // ---- Death Ledger application tracking (spec §10.8) -------------------
  public func HasAppliedLedgerId(id: Int32) -> Bool {
    return ArrayContains(this.m_appliedLedgerIds, id);
  }

  public func MarkAppliedLedgerId(id: Int32) -> Void {
    if !ArrayContains(this.m_appliedLedgerIds, id) {
      ArrayPush(this.m_appliedLedgerIds, id);
      while ArraySize(this.m_appliedLedgerIds) > CBConfig.CapAppliedLedgerIds() {
        ArrayErase(this.m_appliedLedgerIds, 0);
      }
    }
  }

  // Create and register the settings instance once per session, stored on the
  // (session-scoped) runtime service so every module can read live values.
  private func EnsureSettings() -> Void {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && !rt.HasSettings() {
      let settings = new CyberbaneSettings();
      settings.Register();
      rt.SetSettings(settings);
      CBLog.Verbose(n"Core", "Settings registered with Mod Settings.");
    }
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    CBLog.Verbose(n"Core", s"Restored (saveVersion=\(saveVersion), gameVersion=\(gameVersion)).");
    this.Initialize();
  }

  private func OnDetach() -> Void {
    CBLog.Verbose(n"Core", "Cyberbane detaching.");
  }

  // Idempotent: safe to call from both OnAttach and OnRestored.
  private func Initialize() -> Void {
    let fromSchema = this.m_schemaVersion;
    if fromSchema < CyberbaneSchemaVersion() {
      this.Migrate(fromSchema);
      this.m_schemaVersion = CyberbaneSchemaVersion();
    }
    this.EnsureSubObjects();
    this.EnsurePlaythroughId();
    this.Validate();

    let service = CyberbaneService.Get();
    if IsDefined(service) {
      service.EnsureSchema();
    }
  }

  // Create persistent sub-objects and size fixed-width stat arrays on first run.
  private func EnsureSubObjects() -> Void {
    if !IsDefined(this.m_stats) {
      this.m_stats = new CBStats();
    }
    if ArraySize(this.m_killsByClass) != CBVictimClassCount() {
      ArrayResize(this.m_killsByClass, CBVictimClassCount());
    }
    if !IsDefined(this.m_cooldowns) {
      this.m_cooldowns = new CBCooldowns();
    }
    if ArraySize(this.m_archetype) != CBArchetypeCount() {
      ArrayResize(this.m_archetype, CBArchetypeCount());
    }
  }

  // First run in this save line gets a random Playthrough ID (spec §10.8).
  private func EnsurePlaythroughId() -> Void {
    if Equals(this.m_playthroughId, n"") {
      this.m_playthroughId = CBGeneratePlaythroughId();
      // Say what this actually means, because the old wording read like routine housekeeping.
      //
      // This only fires when the saved state came back empty, and the usual reason is not a new
      // game: the game drops a persisted class's data whenever its field layout changes, so any
      // build that adds or removes a persistent field wipes everybody's reputation, rivals and
      // gang standing. Six of these in one afternoon of rebuilding is what sent me hunting a
      // spawn bug that did not exist - the Rival lane had nothing to send because the Rival
      // list had just been erased.
      CBLog.Info(n"Core", s"Fresh Cyberbane state: new playthrough id \(NameToString(this.m_playthroughId)). Reputation, rivals and gang standing all start from zero. If this was not a new game, a mod update changed the saved layout and the old state is gone.");
    }
  }

  // Load-time validation (spec §19.1). Runs on every attach and restore, and is
  // idempotent. Two jobs: keep the stored numbers inside their ranges, and make sure
  // every stored collection holds only entries the rest of the mod can safely walk.
  //
  // The second job is the important one. Everything below this line reads these arrays
  // without re-checking them, so a hole left by a save that did not come back intact
  // would be dereferenced somewhere deep in a tick. Dropping bad entries once, here, is
  // what keeps that from ever reaching the engine.
  private func Validate() -> Void {
    this.m_renownPoints = MaxF(this.m_renownPoints, 0.0);
    this.m_killDreadPoints = MaxF(this.m_killDreadPoints, 0.0);
    this.m_deedDreadPoints = MaxF(this.m_deedDreadPoints, 0.0);
    this.m_heatPoints = MaxF(this.m_heatPoints, 0.0);
    this.m_code = ClampF(this.m_code, -100.0, 100.0);

    let i = 0;
    while i < ArraySize(this.m_archetype) {
      this.m_archetype[i] = MaxF(this.m_archetype[i], 0.0);
      i += 1;
    }
    if this.m_primaryArchetype < -1 || this.m_primaryArchetype >= CBArchetypeCount() {
      this.m_primaryArchetype = -1;
    }

    this.ValidateFactions();
    this.ValidateDistricts();
    this.ValidateRumors();
    this.ValidateRivals();
    this.ValidateLog();
  }

  private func ValidateFactions() -> Void {
    let i = 0;
    while i < ArraySize(this.m_factions) {
      let f = this.m_factions[i];
      if !IsDefined(f) || Equals(f.id, n"") {
        ArrayErase(this.m_factions, i);
      } else {
        f.standing = ClampF(f.standing, -100.0, 100.0);
        f.renown = ClampF(f.renown, 0.0, 100.0);
        f.renownPeak = ClampF(MaxF(f.renownPeak, f.renown), 0.0, 100.0);
        f.kills = Max(f.kills, 0);
        f.brutalKills = Max(f.brutalKills, 0);
        f.officersKilled = Max(f.officersKilled, 0);
        f.bossesKilled = Max(f.bossesKilled, 0);
        f.spared = Max(f.spared, 0);
        f.tributes = Max(f.tributes, 0);
        i += 1;
      }
    }
  }

  private func ValidateDistricts() -> Void {
    let i = 0;
    while i < ArraySize(this.m_districts) {
      let d = this.m_districts[i];
      if !IsDefined(d) || Equals(d.id, n"") {
        ArrayErase(this.m_districts, i);
      } else {
        d.renown = ClampF(d.renown, 0.0, 100.0);
        d.renownPeak = ClampF(MaxF(d.renownPeak, d.renown), 0.0, 100.0);
        d.kills = Max(d.kills, 0);
        d.lethalOrBrutal = Max(d.lethalOrBrutal, 0);
        d.quietTakedowns = Max(d.quietTakedowns, 0);
        i += 1;
      }
    }
  }

  // Rumors carry a nested array<CName> (the districts the rumor has reached), which is
  // what the slow tick walks. A rumor can never have reached more districts than exist,
  // so anything longer than that is rebuilt from its origin rather than trusted.
  private func ValidateRumors() -> Void {
    let maxReached = CBDistrictCount();
    let i = 0;
    while i < ArraySize(this.m_rumors) {
      let r = this.m_rumors[i];
      if !IsDefined(r) {
        ArrayErase(this.m_rumors, i);
      } else {
        r.magnitude = ClampF(r.magnitude, 0.0, 1000.0);
        r.hops = Clamp(r.hops, 0, CBConfig.RumorMaxHops());
        r.createdAt = MaxF(r.createdAt, 0.0);
        r.lastSpreadAt = MaxF(r.lastSpreadAt, 0.0);
        // Keep only the bits that name a real district.
        let clean = 0;
        let b = 0;
        while b < maxReached {
          if CBMaskHas(r.reachedMask, b) {
            clean = CBMaskSet(clean, b);
          }
          b += 1;
        }
        r.reachedMask = clean;
        i += 1;
      }
    }
    while ArraySize(this.m_rumors) > CBConfig.CapRumors() {
      ArrayErase(this.m_rumors, 0);
    }
  }

  private func ValidateRivals() -> Void {
    let i = 0;
    while i < ArraySize(this.m_rivals) {
      let r = this.m_rivals[i];
      if !IsDefined(r) {
        ArrayErase(this.m_rivals, i);
      } else {
        r.rank = Clamp(r.rank, 1, 4);
        if r.source < 0 || r.source > EnumInt(ECBRivalSource.Hunter) {
          r.source = EnumInt(ECBRivalSource.Survivor);
        }
        if r.state < 0 || r.state > EnumInt(ECBRivalState.Debtor) {
          r.state = EnumInt(ECBRivalState.Dormant);
        }
        r.encounters = Max(r.encounters, 0);
        r.escapes = Max(r.escapes, 0);
        r.killedV = Max(r.killedV, 0);
        r.sparedByV = Max(r.sparedByV, 0);
        // Name/epithet fields are indices into content pools; the readers bounds-check
        // them, but a negative sentinel is the only value they should ever hold.
        if r.firstName < 0 { r.firstName = -1; }
        if r.lastName < 0 { r.lastName = -1; }
        if r.epithet < 0 { r.epithet = -1; }
        // Keep only the bits that name a real trait.
        let cleanT = 0;
        let cleanW = 0;
        let b = 0;
        while b < CBTraitCount() {
          if CBMaskHas(r.traitMask, b) {
            cleanT = CBMaskSet(cleanT, b);
          }
          if CBMaskHas(r.weaknessMask, b) {
            cleanW = CBMaskSet(cleanW, b);
          }
          b += 1;
        }
        r.traitMask = cleanT;
        r.weaknessMask = cleanW;
        i += 1;
      }
    }
    this.TrimArchivedRivals();
  }

  private func ValidateLog() -> Void {
    let i = 0;
    while i < ArraySize(this.m_log) {
      if !IsDefined(this.m_log[i]) {
        ArrayErase(this.m_log, i);
      } else {
        i += 1;
      }
    }
    while ArraySize(this.m_log) > CBConfig.CapLog() {
      ArrayErase(this.m_log, 0);
    }
    let p = 0;
    while p < ArraySize(this.m_peaceDeals) {
      if !IsDefined(this.m_peaceDeals[p]) {
        ArrayErase(this.m_peaceDeals, p);
      } else {
        p += 1;
      }
    }
    while ArraySize(this.m_peaceDeals) > CBConfig.CapPeaceDeals() {
      ArrayErase(this.m_peaceDeals, 0);
    }
  }

  // Step-by-step schema upgrades (spec §19.2). Each step is idempotent.
  private func Migrate(fromSchema: Int32) -> Void {
    if fromSchema == 0 {
      // Fresh install or pre-Cyberbane save: one-time field defaults that must
      // differ from the engine zero-default go here.
      this.m_primaryArchetype = -1;  // -1 = Unknown until enough signal accrues
      CBLog.Verbose(n"Core", "Initialising fresh Cyberbane state.");
    }
    if fromSchema > 0 && fromSchema < 2 {
      // Schema 2 moved the rumor "districts reached" list and the Rival trait lists off
      // nested CName arrays and onto Int32 bit sets. The old arrays no longer exist on
      // these classes, so there is nothing to read across - and reading a stored array
      // that may not have survived its save/load round trip is exactly the crash this
      // change removes.
      //
      // Rumors are short-lived by design (they expire after three in-game days and only
      // feed district renown, which is already banked), so the safe upgrade is to drop
      // the carried-over ones and let play rebuild them. Rivals keep everything that
      // identifies them - name, rank, faction, history - and start the new schema with a
      // clean trait set, which fills back in the next time each one is promoted.
      ArrayClear(this.m_rumors);
      for r in this.m_rivals {
        if IsDefined(r) {
          r.traitMask = 0;
          r.weaknessMask = 0;
        }
      }
      CBLog.Info(n"Core", "Migrated Cyberbane state to schema 2 (bit-set rumor and trait storage).");
    }
  }

  // ---- Basic accessors (expanded by the model layer) --------------------
  public func GetPlaythroughId() -> CName {
    return this.m_playthroughId;
  }

  public func IsBootstrapped() -> Bool {
    return this.m_bootstrapped;
  }

  public func GetStats() -> ref<CBStats> {
    return this.m_stats;
  }

  public func GetCooldowns() -> ref<CBCooldowns> {
    return this.m_cooldowns;
  }

  // Faction-colour disguise (spec §9.3), refreshed by the Look signal.
  public func SetDisguise(faction: CName, strength: Float) -> Void {
    this.m_disguiseFaction = faction;
    this.m_disguiseStrength = strength;
  }
  public func GetDisguiseFaction() -> CName {
    return this.m_disguiseFaction;
  }
  public func GetDisguiseStrength() -> Float {
    return this.m_disguiseStrength;
  }

  // Faction of the hit squad currently deployed (for a Hunter Rival if it loses V, §9.9).
  public func SetActiveSquadFaction(faction: CName) -> Void {
    this.m_activeSquadFaction = faction;
  }
  public func GetActiveSquadFaction() -> CName {
    return this.m_activeSquadFaction;
  }

  // The Rival currently out in the world as an encounter (0 = none), for escape escalation.
  public func SetActiveRivalId(id: Int32) -> Void {
    this.m_activeRivalId = id;
  }
  public func GetActiveRivalId() -> Int32 {
    return this.m_activeRivalId;
  }

  // Wounded runaways pending resolution (spec §10.2).
  public func AddEscapee(e: ref<CBEscapee>) -> Void {
    if !IsDefined(e) {
      return;
    }
    ArrayPush(this.m_escapees, e);
    while ArraySize(this.m_escapees) > CBConfig.EscapeeCap() {
      ArrayErase(this.m_escapees, 0);
    }
  }
  public func GetEscapees() -> array<ref<CBEscapee>> {
    return this.m_escapees;
  }
  public func RemoveEscapee(e: ref<CBEscapee>) -> Void {
    ArrayRemove(this.m_escapees, e);
  }
  // Drop a pending escapee when V catches and kills it (by entity id). This is what stops
  // someone you knocked out and then finished from still coming back as a Spared Rival.
  // Bind the element and check it before reading a field off it (crash safety).
  public func DropEscapeeByEntity(id: EntityID) -> Void {
    let i = 0;
    while i < ArraySize(this.m_escapees) {
      let e = this.m_escapees[i];
      if !IsDefined(e) || Equals(e.entityId, id) {
        ArrayErase(this.m_escapees, i);
      } else {
        i += 1;
      }
    }
  }

  // Record a brokered peace (spec §11.3), newest kept within a small cap.
  // By value, like GetRumors, and for the same reason: indexing the temporary a getter
  // returns hands back a handle into a copy. Callers bind it to a local first.
  public func GetPeaceDeals() -> array<ref<CBPeaceDeal>> {
    return this.m_peaceDeals;
  }

  public func AddPeaceDeal(deal: ref<CBPeaceDeal>) -> Void {
    if !IsDefined(deal) {
      return;
    }
    ArrayPush(this.m_peaceDeals, deal);
    while ArraySize(this.m_peaceDeals) > CBConfig.CapPeaceDeals() {
      ArrayErase(this.m_peaceDeals, 0);
    }
  }

  // ---- Accumulator accessors (read by the model layer) ------------------
  public func GetRenownPoints() -> Float { return this.m_renownPoints; }
  public func GetKillDreadPoints() -> Float { return this.m_killDreadPoints; }
  public func GetDeedDreadPoints() -> Float { return this.m_deedDreadPoints; }
  public func GetHeatPoints() -> Float { return this.m_heatPoints; }
  public func GetArchetypeAccumulators() -> array<Float> { return this.m_archetype; }
  public func GetPrimaryArchetypeIndex() -> Int32 { return this.m_primaryArchetype; }
  public func SetPrimaryArchetypeIndex(value: Int32) -> Void { this.m_primaryArchetype = value; }
  public func GetLastNotifiedTier() -> Int32 { return this.m_lastNotifiedTier; }
  public func SetLastNotifiedTier(value: Int32) -> Void { this.m_lastNotifiedTier = value; }
  public func GetLastHeatStage() -> Int32 { return this.m_lastHeatStage; }
  public func SetLastHeatStage(value: Int32) -> Void { this.m_lastHeatStage = value; }

  // Code axis (spec §8.11): how the Street reads V's conduct, from Cyberpsycho (-100,
  // reckless, civilian-killing, edging toward cyberpsychosis) to Professional
  // (+100, keeps a code, clean work, mercy). Fixers, crews and vendors read it.
  // Separate from Dread (feared) and Renown (known).
  public func GetCode() -> Float { return this.m_code; }
  public func AddCode(delta: Float) -> Void {
    this.m_code = ClampF(this.m_code + delta, -100.0, 100.0);
  }

  // Scale all archetype accumulators in place (used by decay).
  public func DecayArchetypes(factor: Float) -> Void {
    let i = 0;
    while i < ArraySize(this.m_archetype) {
      this.m_archetype[i] = this.m_archetype[i] * factor;
      i += 1;
    }
  }

  // ---- Accumulator mutators (clamped at zero; called by the model layer) -
  public func AddRenownPoints(delta: Float) -> Void {
    this.m_renownPoints = MaxF(0.0, this.m_renownPoints + delta);
    this.GetScore().MarkDirty();
  }
  public func AddKillDreadPoints(delta: Float) -> Void {
    this.m_killDreadPoints = MaxF(0.0, this.m_killDreadPoints + delta);
    this.GetScore().MarkDirty();
  }
  public func AddDeedDreadPoints(delta: Float) -> Void {
    this.m_deedDreadPoints = MaxF(0.0, this.m_deedDreadPoints + delta);
    this.GetScore().MarkDirty();
  }
  public func AddHeatPoints(delta: Float) -> Void {
    this.m_heatPoints = MaxF(0.0, this.m_heatPoints + delta);
    this.GetScore().MarkDirty();
  }
  public func AddArchetype(index: Int32, delta: Float) -> Void {
    if index >= 0 && index < ArraySize(this.m_archetype) {
      this.m_archetype[index] = MaxF(0.0, this.m_archetype[index] + delta);
    }
  }
  // Recompute the primary archetype with hysteresis (spec §8.3).
  public func RefreshPrimaryArchetype() -> Void {
    this.m_primaryArchetype = CBPrimaryArchetype(this.m_archetype, this.m_primaryArchetype);
    this.GetScore().MarkDirty();
  }

  // ---- Faction state (lazy, seeded from the content baseline) -----------
  public func FindFaction(id: CName) -> ref<CBFactionState> {
    for f in this.m_factions {
      if Equals(f.id, id) {
        return f;
      }
    }
    return null;
  }

  public func EnsureFaction(id: CName) -> ref<CBFactionState> {
    let existing = this.FindFaction(id);
    if IsDefined(existing) {
      return existing;
    }
    let st = new CBFactionState();
    st.id = id;
    let content = this.GetContent();
    if IsDefined(content) {
      let prof = content.GetFaction(id);
      if IsDefined(prof) {
        st.standing = prof.baselineStanding;
      }
    }
    ArrayPush(this.m_factions, st);
    return st;
  }

  public func GetFactionStates() -> array<ref<CBFactionState>> {
    return this.m_factions;
  }

  // ---- District state (lazy) --------------------------------------------
  public func FindDistrict(id: CName) -> ref<CBDistrictState> {
    for d in this.m_districts {
      if Equals(d.id, id) {
        return d;
      }
    }
    return null;
  }

  public func EnsureDistrict(id: CName) -> ref<CBDistrictState> {
    let existing = this.FindDistrict(id);
    if IsDefined(existing) {
      return existing;
    }
    let st = new CBDistrictState();
    st.id = id;
    ArrayPush(this.m_districts, st);
    return st;
  }

  public func GetDistrictStates() -> array<ref<CBDistrictState>> {
    return this.m_districts;
  }

  // ---- Derived-value engine ---------------------------------------------
  public func GetScore() -> ref<CBScoreEngine> {
    if !IsDefined(this.m_score) {
      this.m_score = new CBScoreEngine();
      this.m_score.Bind(this);
    }
    return this.m_score;
  }
}

// Builds a Playthrough ID of the form n"CB_XXXXXXXX" (8 hex chars).
public func CBGeneratePlaythroughId() -> CName {
  let hex = "0123456789ABCDEF";
  let id = "CB_";
  let i = 0;
  while i < 8 {
    id = id + StrMid(hex, RandRange(0, 16), 1);
    i += 1;
  }
  return StringToName(id);
}

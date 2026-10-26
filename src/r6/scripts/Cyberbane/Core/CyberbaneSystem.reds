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
  private persistent let m_code: Float;                   // -100..100 merc Code axis (Mad Dog <-> Professional)
  private persistent let m_lastHeatStage: Int32;          // for heat-point accrual
  private persistent let m_lastSlowTickAt: Float;         // game seconds of last slow tick

  private persistent let m_factions: array<ref<CBFactionState>>;
  private persistent let m_districts: array<ref<CBDistrictState>>;
  private persistent let m_deedsDone: array<CName>;
  private persistent let m_titles: array<CName>;
  private persistent let m_activeTitle: CName;            // n"" = auto
  private persistent let m_stats: ref<CBStats>;
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
  private let m_disguiseFaction: CName;       // gang whose colours V is wearing (spec §9.3)
  private let m_disguiseStrength: Float;      // 0..1, how well the disguise reads
  private let m_activeSquadFaction: CName;    // faction of the hit squad currently out (for Hunter on escape)
  private let m_escapees: array<ref<CBEscapee>>;   // wounded enemies that ran (session-only, spec §10.2)
  private let m_activeRivalId: Int32;         // id of the Rival currently spawned as an encounter (0 = none)
  private let m_lastTickGameTime: Float;      // in-game seconds at the last processed tick (time-jump detector)
  private let m_streamSettleTicks: Int32;     // ticks to sit out after a transition / time jump (crash safety)
  private let m_attachCount: Int32;           // entities attached since the last tick (streaming-flood detector)
  private let m_currentDistrict: CName;       // cached district, refreshed only on a stable slow sample (crash safety)
  private let m_content: ref<CyberbaneContent>;   // content service, fetched once from a stable tick then reused (crash safety)

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

  // Session start (spec §5.3): build runtime objects, register the entity callback
  // once, clean up stray Cyberbane spawns, and (re)start the fast tick.
  private func StartSession() -> Void {
    if !IsDefined(this.m_registry) {
      this.m_registry = new CBNpcRegistry();
    }
    if !IsDefined(this.m_director) {
      this.m_director = new CBReactionDirector();
    }
    if !this.m_sessionStarted {
      this.m_sessionStarted = true;
      GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/Attached", this, n"OnCBEntityAttached");
      GameInstance.GetCallbackSystem().RegisterCallback(n"Input/Key", this, n"OnCBKeyInput");
      let des = GameInstance.GetDynamicEntitySystem();
      if IsDefined(des) {
        des.DeleteTagged(n"Cyberbane");
      }
      // Apply any deaths recorded in the global ledger for this playthrough.
      CBApplyDeathLedger(this, this.GetGameInstance());
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
    this.m_attachCount += 1;
    if !IsDefined(this.m_registry) {
      return;
    }
    // Don't touch entities while the world is loading / fast travelling / mid-scene: during a
    // stream flood they attach by the hundreds and the world is still being rebuilt (crash safety).
    if !CBWorldStable(this.GetGameInstance()) {
      return;
    }
    let puppet = event.GetEntity() as ScriptedPuppet;
    if IsDefined(puppet) {
      this.m_registry.Add(puppet);
      puppet.cbSeenTick = this.m_tickCount;   // leave it alone until its components are ready
      // Our own spawned hostiles (hit squads, Rival encounters) start aggressive toward V.
      let des = GameInstance.GetDynamicEntitySystem();
      if IsDefined(des) {
        let id = puppet.GetEntityID();
        if des.IsTagged(id, n"CB_Squad") || des.IsTagged(id, n"CB_Rival") {
          CBMakeHostileToPlayer(this.GetGameInstance(), puppet);
        }
      }
    }
  }

  // Hub toggle (spec §12.1). Fires on key release so a tap advances exactly one tab.
  private cb func OnCBKeyInput(event: ref<KeyInputEvent>) -> Void {
    if !Equals(event.GetAction(), EInputAction.IACT_Release) {
      return;
    }
    if !Equals(event.GetKey(), this.GetHubKey()) {
      return;
    }
    if !IsDefined(this.m_hud) {
      this.m_hud = new CBHud();
    }
    let game = this.GetGameInstance();
    // Shift + Hub key while the Hub is open brokers peace with the worst gang you can
    // buy off, without changing tab (spec §11.3 Hub action).
    if event.IsShiftDown() && this.m_hud.IsOpen() {
      CBBrokerPeaceBest(this, game);
      this.m_hud.Refresh(this, game);
      return;
    }
    // Ctrl + Hub key cycles the active title (Auto -> each earned title -> Auto).
    if event.IsControlDown() && this.m_hud.IsOpen() {
      CBCycleActiveTitle(this);
      this.m_hud.Refresh(this, game);
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
      return rt.GetSettings().hubKey;
    }
    return EInputKey.IK_F7;
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
    let attached = this.m_attachCount;
    this.m_attachCount = 0;
    if attached >= CBConfig.FloodAttachThreshold() {
      this.m_streamSettleTicks = CBConfig.FloodSettleTicks();
      this.ScheduleFastTick();
      return;
    }

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
      this.ScheduleFastTick();
      return;
    }

    // Warm the content cache from this confirmed-stable tick: the one real service-container
    // lookup happens here, in a safe context, so the slow tick can reuse the cached reference
    // instead of re-locking a possibly-dead container (crash safety).
    this.GetContent();

    this.m_tickCount += 1;
    // The player/world sampling (chrome, look, menace, Street Cred + Heat, current district)
    // runs only on this slow sample, and only on a stable, non-flood tick reached above - so the
    // Prevention-system district/heat queries never fire mid-stream. The director reads the
    // cached district rather than querying every tick.
    if this.m_tickCount % 10 == 0 {
      CBRefreshLiveInputs(this, game);
      CBUpdateChrome(this, game);
      CBUpdateLook(this, game);
      CBUpdateMenace(this, game);
      this.m_currentDistrict = CBCurrentDistrict(game);
    }
    CBEncounterTick(this, game);
    CBProcessEscapees(this, game);
    CBPanicDrivingTick(this, game, this.m_tickCount);
    this.CheckSlowTick(game);
    if IsDefined(this.m_director) {
      this.m_director.Tick(game);
    }
    this.ScheduleFastTick();
  }

  public func GetTickCount() -> Int32 {
    return this.m_tickCount;
  }

  // Cached current district (refreshed on the slow sample). Reading this instead of querying
  // the Prevention system every tick keeps that query off the hot path during streaming.
  public func GetCurrentDistrict() -> CName {
    return this.m_currentDistrict;
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
    }
  }

  public func FindRivalById(id: Int32) -> ref<CBRival> {
    for r in this.m_rivals {
      if r.id == id {
        return r;
      }
    }
    return null;
  }

  public func CountActiveRivals() -> Int32 {
    let n = 0;
    for r in this.m_rivals {
      if r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting) {
        n += 1;
      }
    }
    return n;
  }

  public func CountActiveFactionRivals(faction: CName) -> Int32 {
    let n = 0;
    for r in this.m_rivals {
      if Equals(r.faction, faction) && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
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
  public func GetRumors() -> array<ref<CBRumor>> {
    return this.m_rumors;
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
    if ArraySize(this.m_stats.killsByClass) != CBVictimClassCount() {
      ArrayResize(this.m_stats.killsByClass, CBVictimClassCount());
    }
    if ArraySize(this.m_stats.killsByMethod) != CBKillMethodCount() {
      ArrayResize(this.m_stats.killsByMethod, CBKillMethodCount());
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
      CBLog.Info(n"Core", s"New playthrough id \(NameToString(this.m_playthroughId)).");
    }
  }

  // Load-time validation (spec §19.1). Full clamping/rebuild happens as the
  // model layer lands; this keeps the stored numbers inside their ranges.
  private func Validate() -> Void {
    this.m_renownPoints = MaxF(this.m_renownPoints, 0.0);
    this.m_killDreadPoints = MaxF(this.m_killDreadPoints, 0.0);
    this.m_deedDreadPoints = MaxF(this.m_deedDreadPoints, 0.0);
    this.m_heatPoints = MaxF(this.m_heatPoints, 0.0);
  }

  // Step-by-step schema upgrades (spec §19.2). Each step is idempotent.
  private func Migrate(fromSchema: Int32) -> Void {
    if fromSchema == 0 {
      // Fresh install or pre-Cyberbane save: one-time field defaults that must
      // differ from the engine zero-default go here.
      this.m_primaryArchetype = -1;  // -1 = Unknown until enough signal accrues
      CBLog.Verbose(n"Core", "Initialising fresh Cyberbane state.");
    }
    // Future: if fromSchema < 2 { ... }  etc.
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
  // Drop a pending escapee when V catches and kills it (by entity id).
  public func DropEscapeeByEntity(id: EntityID) -> Void {
    let i = 0;
    while i < ArraySize(this.m_escapees) {
      if Equals(this.m_escapees[i].entityId, id) {
        ArrayErase(this.m_escapees, i);
      } else {
        i += 1;
      }
    }
  }

  // Record a brokered peace (spec §11.3), newest kept within a small cap.
  public func AddPeaceDeal(deal: ref<CBPeaceDeal>) -> Void {
    if !IsDefined(deal) {
      return;
    }
    ArrayPush(this.m_peaceDeals, deal);
    while ArraySize(this.m_peaceDeals) > 16 {
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

  // Code axis (spec §8.11): how the Street reads V's conduct, from Mad Dog (-100,
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

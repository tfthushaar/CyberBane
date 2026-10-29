// Cyberbane - Score engine (spec §8, stateful)
//
// Binds the per-save accumulators (CyberbaneSystem) and the content registries to
// the pure ScoreMath functions, caches the derived headline values, and exposes
// them to the reaction and UI layers. Live inputs (chrome, look, heat, street
// cred) are pushed in by the Signals layer; everything else is read from state.
//
// The engine is a runtime object (not persisted); CyberbaneSystem lazily creates it.

public class CBScoreEngine {
  private let m_system: wref<CyberbaneSystem>;

  // Live inputs (set by Signals; default 0 until first update).
  private let m_chrome: Float;
  private let m_chromeVisible: Float;
  private let m_look: Float;
  private let m_disguise: Float;
  private let m_streetCred: Float;
  private let m_heatStage: Int32;
  private let m_overallocated: Bool;
  private let m_menace: Float;        // 0-100 from V's level, street cred and skills (spec §8.6)

  // Cached derived headline values.
  private let m_renown: Float;
  private let m_dread: Float;
  private let m_dreadCiv: Float;
  private let m_tier: ECBRenownTier;
  private let m_dirty: Bool;

  public func Bind(system: ref<CyberbaneSystem>) -> Void {
    this.m_system = system;
    this.m_dirty = true;
  }

  // ---- Live input setters (called by Signals) ---------------------------
  public func SetChrome(chrome: Float, chromeVisible: Float, overallocated: Bool) -> Void {
    this.m_chrome = chrome;
    this.m_chromeVisible = chromeVisible;
    this.m_overallocated = overallocated;
    this.m_dirty = true;
  }

  public func SetLook(look: Float, disguise: Float) -> Void {
    this.m_look = look;
    this.m_disguise = disguise;
    this.m_dirty = true;
  }

  public func SetStreetCred(streetCred: Float) -> Void {
    this.m_streetCred = streetCred;
    this.m_dirty = true;
  }

  public func SetHeatStage(stage: Int32) -> Void {
    this.m_heatStage = stage;
    this.m_dirty = true;
  }

  public func SetAura(aura: Float) -> Void {
    this.m_aura = aura;
  }

  public func SetMenace(menace: Float) -> Void {
    this.m_menace = menace;
  }
  public func GetMenace() -> Float {
    return this.m_menace;
  }

  public func MarkDirty() -> Void {
    this.m_dirty = true;
  }

  // ---- Live input getters -----------------------------------------------
  public func GetChrome() -> Float { return this.m_chrome; }
  private let m_aura: Float;
  public func GetChromeVisible() -> Float { return this.m_chromeVisible; }
  public func GetLook() -> Float { return this.m_look; }
  public func GetDisguise() -> Float { return this.m_disguise; }
  public func GetHeatStage() -> Int32 { return this.m_heatStage; }
  // Momentary menace (spec 8.6): what V looks like doing right now, as opposed to what V is
  // known for. Drawn weapon, running combat chrome, mid-fight, fresh bodies nearby, police
  // attention. Recomputed on the sampling tick; never persisted, because it describes a moment.
  public func GetAura() -> Float { return this.m_aura; }

  // Content via the system's cached accessor (never re-locks the global container; crash safety).
  private func Content() -> ref<CyberbaneContent> {
    let sys = this.m_system;
    if !IsDefined(sys) {
      return null;
    }
    return sys.GetContent();
  }

  // ---- Derivation -------------------------------------------------------
  private func Recompute() -> Void {
    if !this.m_dirty {
      return;
    }
    let sys = this.m_system;
    if !IsDefined(sys) {
      return;
    }
    this.m_renown = CBComputeRenown(sys.GetRenownPoints(), this.m_streetCred, this.UseStreetCredFloor());
    this.m_tier = CBRenownTier(this.m_renown);

    let k = CBKillDreadComponent(sys.GetKillDreadPoints());
    let x = CBDeedDreadComponent(sys.GetDeedDreadPoints());
    let h = CBHeatDreadComponent(sys.GetHeatPoints());
    this.m_dread = CBComputeDread(k, this.m_chrome, this.m_look, x, h);

    let stats = sys.GetStats();
    let mercy = 0.0;
    if IsDefined(stats) {
      mercy = CBMercyRatio(stats.nonLethal, sys.TotalKills());
    }
    this.m_dreadCiv = CBComputeDreadCiv(this.m_dread, sys.GetPrimaryArchetypeIndex(), mercy);

    this.m_dirty = false;
  }

  private func UseStreetCredFloor() -> Bool {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      return rt.GetSettings().streetCredFloor;
    }
    return true;
  }

  // ---- Headline getters -------------------------------------------------
  public func GetRenown() -> Float {
    this.Recompute();
    return this.m_renown;
  }

  public func GetDread() -> Float {
    this.Recompute();
    return this.m_dread;
  }

  public func GetDreadCiv() -> Float {
    this.Recompute();
    return this.m_dreadCiv;
  }

  public func GetTier() -> ECBRenownTier {
    this.Recompute();
    return this.m_tier;
  }

  public func GetPrimaryArchetype() -> Int32 {
    let sys = this.m_system;
    if IsDefined(sys) {
      return sys.GetPrimaryArchetypeIndex();
    }
    return -1;
  }

  // ---- Faction-derived values -------------------------------------------
  public func GetStanding(factionId: CName) -> Float {
    let sys = this.m_system;
    if IsDefined(sys) {
      let st = sys.FindFaction(factionId);
      if IsDefined(st) {
        return st.standing;
      }
    }
    let content = this.Content();
    if IsDefined(content) {
      let prof = content.GetFaction(factionId);
      if IsDefined(prof) {
        return prof.baselineStanding;
      }
    }
    return 0.0;
  }

  public func GetPosture(factionId: CName) -> ECBPosture {
    return CBPostureFromStanding(this.GetStanding(factionId));
  }

  public func GetFactionRenown(factionId: CName) -> Float {
    let sys = this.m_system;
    if IsDefined(sys) {
      let st = sys.FindFaction(factionId);
      if IsDefined(st) {
        return st.renown;
      }
    }
    return 0.0;
  }

  public func GetFactionFear(factionId: CName) -> Float {
    this.Recompute();
    let content = this.Content();
    let dreadSens = 1.0;
    let chromeAttitude = 0.0;
    if IsDefined(content) {
      let prof = content.GetFaction(factionId);
      if IsDefined(prof) {
        dreadSens = prof.dreadSens;
        chromeAttitude = prof.chromeAttitude;
      }
    }
    return CBFactionFear(this.m_dread, this.m_chrome, this.GetFactionRenown(factionId), dreadSens, chromeAttitude);
  }

  public func GetFactionRespect(factionId: CName) -> Float {
    this.Recompute();
    let sys = this.m_system;
    let content = this.Content();
    let chromeAttitude = 0.0;
    let respectBlend = 0.0;
    if IsDefined(content) {
      let prof = content.GetFaction(factionId);
      if IsDefined(prof) {
        chromeAttitude = prof.chromeAttitude;
        if IsDefined(sys) {
          respectBlend = prof.RespectBlend(sys.GetArchetypeAccumulators());
        }
      }
    }
    return CBFactionRespect(this.m_renown, this.m_chrome, this.GetFactionRenown(factionId), chromeAttitude, respectBlend);
  }

  // ---- Per-NPC recognition (spec §8.7) ----------------------------------
  public func RecognitionChance(districtId: CName, npcFaction: CName, npcIsNcpdHighHeat: Bool, lowProfile: Bool) -> Float {
    this.Recompute();
    let sys = this.m_system;
    let rd = 0.0;
    let rf = 0.0;
    if IsDefined(sys) {
      let d = sys.FindDistrict(districtId);
      if IsDefined(d) {
        rd = d.renown;
      }
      if NotEquals(npcFaction, n"") {
        let fs = sys.FindFaction(npcFaction);
        if IsDefined(fs) {
          rf = fs.renown;
        }
      }
    }
    return CBRecognitionChance(this.m_renown, rd, this.m_chromeVisible, this.m_look, this.m_disguise, rf, npcIsNcpdHighHeat, lowProfile);
  }
}

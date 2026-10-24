// Cyberbane — Content registries (spec §14)
//
// Content lives in redscript (compile-checked, no extra dependency). The tables
// are seeded once into the CyberbaneContent service and can be extended by
// add-on mods through CyberbaneAPI. These classes are never persisted, so String
// display keys are allowed here (unlike the save-state classes in State.reds).

// ---- Record classes -------------------------------------------------------

public class CBFactionProfile {
  public let id: CName;
  public let affiliations: array<CName>;      // game gamedataAffiliation names mapped to this id (filled in S-01)
  public let baselineStanding: Float;
  public let courageMod: Float;
  public let dreadSens: Float;
  public let chromeAttitude: Float;           // >0 chrome scares them, <0 chrome earns respect
  public let respectWeights: array<Float>;    // index = ECBArchetype, length = CBArchetypeCount()
  public let rivalFactions: array<CName>;
  public let turf: array<CName>;              // district ids
  public let isGang: Bool;                    // tribute/hit-squad eligibility
  public let canBeBought: Bool;               // broker-peace eligibility (corps cannot)
  public let displayKey: String;

  public func SetRespect(archetype: ECBArchetype, weight: Float) -> Void {
    if ArraySize(this.respectWeights) == CBArchetypeCount() {
      this.respectWeights[EnumInt(archetype)] = weight;
    }
  }

  // Σ respect[a] * share_a, where share_a = archetype_a / Σ archetype (spec §8.4).
  public func RespectBlend(archetype: array<Float>) -> Float {
    let total = 0.0;
    let i = 0;
    while i < ArraySize(archetype) {
      total += archetype[i];
      i += 1;
    }
    if total <= 0.0 {
      return 0.0;
    }
    let blend = 0.0;
    i = 0;
    let n = ArraySize(this.respectWeights);
    while i < ArraySize(archetype) && i < n {
      blend += this.respectWeights[i] * (archetype[i] / total);
      i += 1;
    }
    return blend;
  }
}

public class CBDistrictDef {
  public let id: CName;
  public let adjacency: array<CName>;
  public let displayKey: String;

  public func IsAdjacentTo(other: CName) -> Bool {
    return ArrayContains(this.adjacency, other);
  }
}

// ---- Content service ------------------------------------------------------

public class CyberbaneContent extends ScriptableService {
  private let m_factions: array<ref<CBFactionProfile>>;
  private let m_districts: array<ref<CBDistrictDef>>;
  private let m_built: Bool;

  public static func Get() -> ref<CyberbaneContent> {
    let c = GameInstance.GetScriptableServiceContainer().GetService(n"CyberbaneContent") as CyberbaneContent;
    if IsDefined(c) {
      c.EnsureBuilt();
    }
    return c;
  }

  private func EnsureBuilt() -> Void {
    if this.m_built {
      return;
    }
    this.m_built = true;   // set first so re-entrant Add* calls don't loop
    CBSeedFactions(this);
    CBSeedDistricts(this);
    CBLog.Info(n"Model", s"Content built: \(ArraySize(this.m_factions)) factions, \(ArraySize(this.m_districts)) districts.");
  }

  // ---- Factions -----------------------------------------------------------
  public func AddFaction(profile: ref<CBFactionProfile>) -> Void {
    if !IsDefined(profile) {
      return;
    }
    if ArraySize(profile.respectWeights) != CBArchetypeCount() {
      ArrayResize(profile.respectWeights, CBArchetypeCount());
    }
    ArrayPush(this.m_factions, profile);
  }

  public func GetFaction(id: CName) -> ref<CBFactionProfile> {
    for f in this.m_factions {
      if Equals(f.id, id) {
        return f;
      }
    }
    return null;
  }

  public func GetFactions() -> array<ref<CBFactionProfile>> {
    return this.m_factions;
  }

  // Maps a game affiliation record name to a Cyberbane faction id (n"" if none).
  public func FactionForAffiliation(affiliation: CName) -> CName {
    for f in this.m_factions {
      if ArrayContains(f.affiliations, affiliation) {
        return f.id;
      }
    }
    return n"";
  }

  // ---- Districts ----------------------------------------------------------
  public func AddDistrict(def: ref<CBDistrictDef>) -> Void {
    if IsDefined(def) {
      ArrayPush(this.m_districts, def);
    }
  }

  public func GetDistrict(id: CName) -> ref<CBDistrictDef> {
    for d in this.m_districts {
      if Equals(d.id, id) {
        return d;
      }
    }
    return null;
  }

  public func GetDistricts() -> array<ref<CBDistrictDef>> {
    return this.m_districts;
  }
}

// ---- Construction helpers (used by the seed files) ------------------------

public func CBMakeFaction(
    id: CName,
    baseline: Float,
    courage: Float,
    dreadSens: Float,
    chromeAttitude: Float,
    isGang: Bool,
    canBeBought: Bool,
    displayKey: String) -> ref<CBFactionProfile> {
  let f = new CBFactionProfile();
  f.id = id;
  f.baselineStanding = baseline;
  f.courageMod = courage;
  f.dreadSens = dreadSens;
  f.chromeAttitude = chromeAttitude;
  f.isGang = isGang;
  f.canBeBought = canBeBought;
  f.displayKey = displayKey;
  ArrayResize(f.respectWeights, CBArchetypeCount());
  return f;
}

public func CBMakeDistrict(id: CName, displayKey: String) -> ref<CBDistrictDef> {
  let d = new CBDistrictDef();
  d.id = id;
  d.displayKey = displayKey;
  return d;
}

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

public class CBImplantDef {
  public let family: CName;        // cyberware family key (matched to records in S-11)
  public let score: Float;         // implantScore(item)
  public let visible: Bool;
  public let archetype: Int32;     // ECBArchetype nudge, or -1 for none
}

public class CBLookTagDef {
  public let tag: CName;           // visual tag (GetVisualTags), resolved in S-10
  public let score: Float;
  public let disguise: Float;
  public let factionTag: CName;    // n"" if none
}

public class CBLookItemDef {
  public let record: TweakDBID;    // exact item record match (takes priority over tags)
  public let score: Float;
  public let disguise: Float;
  public let factionTag: CName;
}

public class CBCustomizationDef {
  public let key: CName;           // character-customization option key (resolved in S-10)
  public let score: Float;
}

public class CBTitleDef {
  public let id: CName;            // e.g. n"T_LIVING_LEGEND"
  public let display: String;      // display name (English; localized in the Hub later)
  public let priority: Int32;      // higher wins for the auto active title
  public let hidden: Bool;         // shown as ??? until unlocked
}

// ---- Content service ------------------------------------------------------

public class CyberbaneContent extends ScriptableService {
  private let m_factions: array<ref<CBFactionProfile>>;
  private let m_districts: array<ref<CBDistrictDef>>;
  private let m_implants: array<ref<CBImplantDef>>;
  private let m_lookTags: array<ref<CBLookTagDef>>;
  private let m_lookItems: array<ref<CBLookItemDef>>;
  private let m_customizations: array<ref<CBCustomizationDef>>;
  private let m_titles: array<ref<CBTitleDef>>;
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
    CBSeedImplants(this);
    CBSeedLooks(this);
    CBSeedTitles(this);
    CBLog.Info(n"Model", s"Content built: \(ArraySize(this.m_factions)) factions, \(ArraySize(this.m_districts)) districts, \(ArraySize(this.m_implants)) implants, \(ArraySize(this.m_lookTags)) look tags, \(ArraySize(this.m_titles)) titles.");
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

  // ---- Implants (spec Appendix D) -----------------------------------------
  public func AddImplant(def: ref<CBImplantDef>) -> Void {
    if IsDefined(def) {
      ArrayPush(this.m_implants, def);
    }
  }

  // Score + visibility for a cyberware family; returns the default row (family n"")
  // when no specific match exists.
  public func GetImplant(family: CName) -> ref<CBImplantDef> {
    let fallback: ref<CBImplantDef>;
    for d in this.m_implants {
      if Equals(d.family, family) {
        return d;
      }
      if Equals(d.family, n"") {
        fallback = d;
      }
    }
    return fallback;
  }

  // ---- Looks (spec Appendix E) --------------------------------------------
  public func AddLookTag(def: ref<CBLookTagDef>) -> Void {
    if IsDefined(def) {
      ArrayPush(this.m_lookTags, def);
    }
  }

  public func AddLookItem(def: ref<CBLookItemDef>) -> Void {
    if IsDefined(def) {
      ArrayPush(this.m_lookItems, def);
    }
  }

  public func GetLookTag(tag: CName) -> ref<CBLookTagDef> {
    for d in this.m_lookTags {
      if Equals(d.tag, tag) {
        return d;
      }
    }
    return null;
  }

  public func GetLookItem(record: TweakDBID) -> ref<CBLookItemDef> {
    for d in this.m_lookItems {
      if d.record == record {
        return d;
      }
    }
    return null;
  }

  public func GetLookTags() -> array<ref<CBLookTagDef>> {
    return this.m_lookTags;
  }

  // ---- Customization (spec Appendix E) ------------------------------------
  public func AddCustomization(def: ref<CBCustomizationDef>) -> Void {
    if IsDefined(def) {
      ArrayPush(this.m_customizations, def);
    }
  }

  public func GetCustomization(key: CName) -> ref<CBCustomizationDef> {
    for d in this.m_customizations {
      if Equals(d.key, key) {
        return d;
      }
    }
    return null;
  }

  // ---- Titles (spec Appendix G) -------------------------------------------
  public func AddTitle(def: ref<CBTitleDef>) -> Void {
    if IsDefined(def) {
      ArrayPush(this.m_titles, def);
    }
  }

  public func GetTitle(id: CName) -> ref<CBTitleDef> {
    for d in this.m_titles {
      if Equals(d.id, id) {
        return d;
      }
    }
    return null;
  }

  public func GetTitles() -> array<ref<CBTitleDef>> {
    return this.m_titles;
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

public func CBMakeImplant(family: CName, score: Float, visible: Bool, archetype: Int32) -> ref<CBImplantDef> {
  let d = new CBImplantDef();
  d.family = family;
  d.score = score;
  d.visible = visible;
  d.archetype = archetype;
  return d;
}

public func CBMakeLookTag(tag: CName, score: Float, disguise: Float, factionTag: CName) -> ref<CBLookTagDef> {
  let d = new CBLookTagDef();
  d.tag = tag;
  d.score = score;
  d.disguise = disguise;
  d.factionTag = factionTag;
  return d;
}

public func CBMakeCustomization(key: CName, score: Float) -> ref<CBCustomizationDef> {
  let d = new CBCustomizationDef();
  d.key = key;
  d.score = score;
  return d;
}

public func CBMakeTitle(id: CName, display: String, priority: Int32, hidden: Bool) -> ref<CBTitleDef> {
  let d = new CBTitleDef();
  d.id = id;
  d.display = display;
  d.priority = priority;
  d.hidden = hidden;
  return d;
}

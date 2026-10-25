// Cyberbane - Rival system (spec §10)
//
// Named, persistent recurring enemies. This file owns the data lifecycle:
// creation (with caps), deterministic naming, traits, history, promotion and the
// state transitions. Spawning the Rival into the world (RivalSpawner), encounter
// scheduling, the Death Ledger and hit squads build on top of this.

// Deterministic index from a seed + salt (stable naming from rival.id).
public func CBHashIndex(seed: Int32, salt: Int32, modulo: Int32) -> Int32 {
  if modulo <= 0 {
    return 0;
  }
  let h = seed * 73 + salt * 19 + 7;
  if h < 0 {
    h = -h;
  }
  return h % modulo;
}

public func CBEpithetsForSource(content: ref<CyberbaneContent>, source: Int32) -> array<String> {
  let empty: array<String>;
  if !IsDefined(content) {
    return empty;
  }
  let e = content.GetEpithets();
  if !IsDefined(e) {
    return empty;
  }
  if source == EnumInt(ECBRivalSource.Survivor) { return e.survivor; }
  if source == EnumInt(ECBRivalSource.Spared) { return e.spared; }
  if source == EnumInt(ECBRivalSource.Killer) { return e.killer; }
  if source == EnumInt(ECBRivalSource.Avenger) { return e.avenger; }
  if source == EnumInt(ECBRivalSource.Hunter) { return e.hunter; }
  return empty;
}

public func CBRivalGenerateName(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  rival.firstName = -1;
  rival.lastName = -1;
  rival.epithet = -1;
  if !IsDefined(content) {
    return;
  }
  let pool = content.GetFactionNames(rival.faction);
  if IsDefined(pool) {
    if ArraySize(pool.firstNames) > 0 {
      rival.firstName = CBHashIndex(rival.id, 1, ArraySize(pool.firstNames));
    }
    if ArraySize(pool.lastNames) > 0 {
      rival.lastName = CBHashIndex(rival.id, 2, ArraySize(pool.lastNames));
    }
  }
  let eps = CBEpithetsForSource(content, rival.source);
  if ArraySize(eps) > 0 {
    rival.epithet = CBHashIndex(rival.id, 3, ArraySize(eps));
  }
}

public func CBRivalEpithet(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> String {
  let eps = CBEpithetsForSource(content, rival.source);
  if rival.epithet >= 0 && rival.epithet < ArraySize(eps) {
    return eps[rival.epithet];
  }
  return "";
}

// Full on-screen name, e.g. Kenji "Who Ran" Morita.
public func CBRivalDisplayName(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> String {
  let first = "Unknown";
  let last = "";
  if IsDefined(content) {
    let pool = content.GetFactionNames(rival.faction);
    if IsDefined(pool) {
      if rival.firstName >= 0 && rival.firstName < ArraySize(pool.firstNames) {
        first = pool.firstNames[rival.firstName];
      }
      if rival.lastName >= 0 && rival.lastName < ArraySize(pool.lastNames) {
        last = pool.lastNames[rival.lastName];
      }
    }
  }
  let epithet = CBRivalEpithet(content, rival);
  let name = first;
  if StrLen(epithet) > 0 {
    name = name + " \"" + epithet + "\"";
  }
  if StrLen(last) > 0 {
    name = name + " " + last;
  }
  return name;
}

public func CBRivalAddEvent(rival: ref<CBRival>, kind: ECBRivalEventKind, at: Float, district: CName, detail: Int32) -> Void {
  let e = new CBRivalEvent();
  e.kind = EnumInt(kind);
  e.at = at;
  e.district = district;
  e.detail = detail;
  ArrayPush(rival.history, e);
  while ArraySize(rival.history) > CBConfig.CapRivalHistory() {
    ArrayErase(rival.history, 0);
  }
}

// Add one random non-weakness trait not already present (deterministic by id).
public func CBRivalAddTrait(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  if !IsDefined(content) {
    return;
  }
  let pool: array<CName>;
  for t in content.GetTraits() {
    if !t.isWeakness && !ArrayContains(rival.traits, t.id) {
      ArrayPush(pool, t.id);
    }
  }
  if ArraySize(pool) > 0 {
    let idx = CBHashIndex(rival.id, 11 + ArraySize(rival.traits), ArraySize(pool));
    ArrayPush(rival.traits, pool[idx]);
  }
}

// Create and register a Rival. Returns null if caps are full (spec §10.1).
public func CBCreateRival(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName,
    recordID: TweakDBID, appearance: CName, source: ECBRivalSource, origin: CName, at: Float) -> ref<CBRival> {
  if !IsDefined(sys) {
    return null;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().rivals {
    return null;
  }
  let maxRivals = CBConfig.RivalMaxActiveHardCap();
  if IsDefined(rt) && rt.HasSettings() {
    maxRivals = rt.GetSettings().maxRivals;
  }
  if sys.CountActiveRivals() >= maxRivals {
    return null;
  }
  if sys.CountActiveFactionRivals(faction) >= CBConfig.RivalMaxPerFaction() {
    return null;
  }

  let r = new CBRival();
  r.id = sys.AllocateRivalId();
  r.recordID = recordID;
  r.appearance = appearance;
  r.faction = faction;
  r.rank = 1;
  r.source = EnumInt(source);
  r.state = EnumInt(ECBRivalState.Active);
  r.origin = origin;
  r.createdAt = at;
  r.lastSeenAt = at;

  let content = CyberbaneContent.Get();
  CBRivalGenerateName(content, r);
  CBRivalAddTrait(content, r);
  if Equals(source, ECBRivalSource.Spared) {
    ArrayPush(r.traits, n"Humiliated");
  }

  sys.AddRival(r);
  CBRivalAddEvent(r, ECBRivalEventKind.Created, at, origin, 0);

  CBLogRival(sys, n"RivalCreated", at, origin, faction, Cast<Float>(r.id), r.id);
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(game, "Cyberbane: A Rival now remembers you - " + CBRivalDisplayName(content, r), 5.0);
  }
  CBLog.Info(n"Rivals", s"Rival created id=\(r.id) faction=\(NameToString(faction)).");
  return r;
}

public func CBPromoteRival(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float) -> Void {
  if rival.rank >= 4 {
    return;
  }
  rival.rank += 1;
  CBRivalAddTrait(content, rival);
  CBRivalAddEvent(rival, ECBRivalEventKind.Promoted, at, rival.origin, rival.rank);
}

// --- State transitions (spec §10.6) ------------------------------------

public func CBRivalEscaped(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName, lowHp: Bool) -> Void {
  rival.escapes += 1;
  rival.lastSeenAt = at;
  CBRivalAddEvent(rival, ECBRivalEventKind.Escaped, at, district, 0);
  CBPromoteRival(rival, content, at);
  if lowHp && !ArrayContains(rival.traits, n"Scarred") {
    ArrayPush(rival.traits, n"Scarred");
  }
}

public func CBRivalKilledV(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName) -> Void {
  rival.killedV += 1;
  ArrayRemove(rival.traits, n"Shaken");
  if !ArrayContains(rival.traits, n"Confident") {
    ArrayPush(rival.traits, n"Confident");
  }
  CBRivalAddEvent(rival, ECBRivalEventKind.KilledV, at, district, 0);
  CBPromoteRival(rival, content, at);
}

// Returns true if the Rival became a Debtor (retires via a redemption tip).
public func CBRivalSparedByV(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName) -> Bool {
  rival.sparedByV += 1;
  CBRivalAddEvent(rival, ECBRivalEventKind.SparedByV, at, district, 0);
  if rival.sparedByV >= 2 && RandF() < 0.5 {
    rival.state = EnumInt(ECBRivalState.Debtor);
    return true;
  }
  CBPromoteRival(rival, content, at);
  return false;
}

// Slay a Rival (spec §10.7): archive it, award renown, bump stats, log.
public func CBRivalSlain(sys: ref<CyberbaneSystem>, game: GameInstance, rival: ref<CBRival>, at: Float, district: CName) -> Void {
  if !IsDefined(sys) || !IsDefined(rival) {
    return;
  }
  rival.state = EnumInt(ECBRivalState.Slain);
  rival.lastSeenAt = at;
  CBRivalAddEvent(rival, ECBRivalEventKind.Slain, at, district, 0);

  let stats = sys.GetStats();
  if IsDefined(stats) {
    stats.rivalsSlain += 1;
  }
  let renownMult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    renownMult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints((25.0 + 10.0 * Cast<Float>(rival.rank)) * renownMult);

  CBLogRival(sys, n"RivalSlain", at, district, rival.faction, Cast<Float>(rival.rank), rival.id);
  let content = CyberbaneContent.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(game, "Cyberbane: Rival slain - " + CBRivalDisplayName(content, rival), 5.0);
  }

  // Blood-brother vengeance (Nemesis-inspired): a faction member may rise to
  // avenge the slain Rival, remembering them specifically (detail = slain id).
  let freq = 1.0;
  if IsDefined(rt) && rt.HasSettings() {
    freq = rt.GetSettings().rivalFrequencyMult;
  }
  if RandF() < CBConfig.RivalChanceAvenger() * freq {
    let avenger = CBCreateRival(sys, game, rival.faction, rival.recordID, rival.appearance, ECBRivalSource.Avenger, district, at);
    if IsDefined(avenger) {
      CBRivalAddEvent(avenger, ECBRivalEventKind.Created, at, district, rival.id);
      if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
        CBShowMessage(game, "Cyberbane: " + CBRivalDisplayName(content, avenger) + " is gunning for you over a dead crewmate.", 5.0);
      }
    }
  }

  CBEvaluateTitles(sys, game);
}

// Autonomous rival progression (Nemesis-inspired): Rivals V has ignored for a
// while climb the ranks on their own, at most one promotion per in-game day
// (spec §10.1). The underworld moves even when V isn't looking.
public func CBRivalProgressionTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().rivals {
    return;
  }
  let now = CBGameSeconds(game);
  let cd = sys.GetCooldowns();
  // Rivals climb often while you leave them be: at most one promotion every ~8 in-game hours.
  if IsDefined(cd) && (now - cd.lastPromotionAt) < CBConfig.SecondsPerDay() * 0.33 {
    return;
  }
  let content = CyberbaneContent.Get();
  let neglect = CBConfig.SecondsPerDay();   // left alone for a day and they get stronger
  for r in sys.GetRivals() {
    let active = r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting);
    if active && r.rank < 4 && (now - r.lastSeenAt) > neglect {
      if RandF() < 0.6 {
        CBPromoteRival(r, content, now);
        if IsDefined(cd) {
          cd.lastPromotionAt = now;
        }
        if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
          CBShowMessage(game, "Cyberbane: " + CBRivalDisplayName(content, r) + " has climbed the ranks while you were gone.", 5.0);
        }
        return;
      }
    }
  }
}

// Writes a Legend Log entry for a Rival event.
func CBLogRival(sys: ref<CyberbaneSystem>, kind: CName, at: Float, district: CName, faction: CName, value: Float, rivalId: Int32) -> Void {
  let entry = new CBLogEntry();
  entry.kind = kind;
  entry.at = at;
  entry.district = district;
  entry.faction = faction;
  entry.value = value;
  entry.refId = rivalId;
  sys.AddLogEntry(entry);
}

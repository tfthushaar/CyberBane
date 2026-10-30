// Cyberbane - Gang hierarchy (spec §10.1)
//
// A crew is not a flat list of people who dislike you. Each gang has a leader and up to three
// lieutenants, and your Rivals occupy those slots. Kill the leader and the strongest of the
// rest steps up, which means a gang can be fought but not decapitated: there is always
// somebody next in line.
//
// The slots live on CBFactionState as four plain Int32 Rival ids, 0 meaning empty. Flat
// scalars rather than an array, because an array nested inside a persisted class is the exact
// shape that crashed the game before schema 3.
//
// Crash safety: pure state. No engine calls, no entity handles, no allocation beyond what the
// Rival store already does. Every lookup is id based and returns null rather than guessing.

public func CBRoleNone() -> Int32 = 0
public func CBRoleLieutenant() -> Int32 = 1
public func CBRoleLeader() -> Int32 = 2

// Short form for the Hub, where the column is 25 characters wide and a gang name already
// takes most of it. CBRoleName stays long for messages.
public func CBRoleShort(role: Int32) -> String {
  if role == CBRoleLeader() {
    return "LEADER";
  }
  if role == CBRoleLieutenant() {
    return "LT";
  }
  return "";
}

public func CBRoleName(role: Int32) -> String {
  if role == CBRoleLeader() {
    return "LEADER";
  }
  if role == CBRoleLieutenant() {
    return "LIEUTENANT";
  }
  return "";
}

// What this Rival is to their gang right now.
public func CBRivalRole(sys: ref<CyberbaneSystem>, rival: ref<CBRival>) -> Int32 {
  if !IsDefined(sys) || !IsDefined(rival) || rival.id <= 0 {
    return CBRoleNone();
  }
  // A cyberpsycho is nobody's lieutenant. Keeping them out of the hierarchy keeps the leader
  // and lieutenant health multipliers off them as well, which is the other half of giving them
  // wits instead of padding.
  if CBRecordIsSightingCyberpsycho(rival.recordID) {
    return CBRoleNone();
  }
  let fs = sys.FindFaction(rival.faction);
  if !IsDefined(fs) {
    return CBRoleNone();
  }
  if fs.leaderRivalId == rival.id {
    return CBRoleLeader();
  }
  if fs.lt1RivalId == rival.id || fs.lt2RivalId == rival.id || fs.lt3RivalId == rival.id {
    return CBRoleLieutenant();
  }
  return CBRoleNone();
}

// Is this id still a Rival who is actually around?
func CBSlotHolderActive(sys: ref<CyberbaneSystem>, id: Int32) -> Bool {
  if id <= 0 {
    return false;
  }
  let r = sys.FindRivalById(id);
  if !IsDefined(r) {
    return false;
  }
  return r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting);
}

// Clear any slot held by a Rival who is gone, so vacancies are real.
func CBHierarchyPrune(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> Void {
  if !CBSlotHolderActive(sys, fs.leaderRivalId) {
    fs.leaderRivalId = 0;
  }
  if !CBSlotHolderActive(sys, fs.lt1RivalId) {
    fs.lt1RivalId = 0;
  }
  if !CBSlotHolderActive(sys, fs.lt2RivalId) {
    fs.lt2RivalId = 0;
  }
  if !CBSlotHolderActive(sys, fs.lt3RivalId) {
    fs.lt3RivalId = 0;
  }
}

func CBHoldsAnySlot(fs: ref<CBFactionState>, id: Int32) -> Bool {
  return fs.leaderRivalId == id || fs.lt1RivalId == id || fs.lt2RivalId == id || fs.lt3RivalId == id;
}

// Who deserves the next promotion in this gang. Rank first, then who has met V most often,
// so the one who keeps coming back is the one who rises.
func CBBestCandidate(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> ref<CBRival> {
  let best: ref<CBRival> = null;
  let bestScore = -1;
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && Equals(r.faction, fs.id) && !CBHoldsAnySlot(fs, r.id)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      let score = r.rank * 100 + r.encounters;
      if score > bestScore {
        bestScore = score;
        best = r;
      }
    }
  }
  return best;
}

// Fill whatever is empty, leader first. Called whenever the shape of a gang changes.
public func CBHierarchyFill(sys: ref<CyberbaneSystem>, faction: CName) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") {
    return;
  }
  let fs = sys.FindFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  CBHierarchyPrune(sys, fs);

  if fs.leaderRivalId <= 0 {
    let promoted = CBBestCandidate(sys, fs);
    if IsDefined(promoted) {
      fs.leaderRivalId = promoted.id;
      // Running a crew makes you harder to put down than you were.
      promoted.rank = Max(promoted.rank, CBConfig.LeaderMinRank());
    }
  }
  if fs.lt1RivalId <= 0 {
    let c = CBBestCandidate(sys, fs);
    if IsDefined(c) {
      fs.lt1RivalId = c.id;
      c.rank = Max(c.rank, CBConfig.LieutenantMinRank());
    }
  }
  if fs.lt2RivalId <= 0 {
    let c2 = CBBestCandidate(sys, fs);
    if IsDefined(c2) {
      fs.lt2RivalId = c2.id;
      c2.rank = Max(c2.rank, CBConfig.LieutenantMinRank());
    }
  }
  if fs.lt3RivalId <= 0 {
    let c3 = CBBestCandidate(sys, fs);
    if IsDefined(c3) {
      fs.lt3RivalId = c3.id;
      c3.rank = Max(c3.rank, CBConfig.LieutenantMinRank());
    }
  }
}

// A Rival is gone. Free their slot and let somebody step into it.
public func CBHierarchyOnSlain(sys: ref<CyberbaneSystem>, game: GameInstance, rival: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(rival) {
    return;
  }
  let fs = sys.FindFaction(rival.faction);
  if !IsDefined(fs) {
    return;
  }
  let wasLeader = fs.leaderRivalId == rival.id;
  CBHierarchyPrune(sys, fs);
  CBHierarchyFill(sys, rival.faction);

  // Taking the top off a crew is worth hearing about.
  if wasLeader && fs.leaderRivalId > 0 {
    let heir = sys.FindRivalById(fs.leaderRivalId);
    let rt = CyberbaneRuntime.Get();
    if IsDefined(heir) && IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
      let content = CBContent(game);
      CBShowMessage(game, "Cyberbane: " + CBRivalDisplayName(content, heir)
        + " now runs " + CBFactionLabel(rival.faction) + ".", 5.0);
    }
  }
}

// Running a crew should be felt, not just labelled. Reuses the apex buff pattern at a much
// gentler scale, applied on attach to a spawned Rival.
public func CBApplyRivalRoleBuff(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, role: Int32) -> Void {
  if !IsDefined(puppet) || role == CBRoleNone() {
    return;
  }
  // Sits on top of the apex-grade buff on purpose, and like it must never be applied twice.
  if puppet.cbRoleBuffed {
    return;
  }
  puppet.cbRoleBuffed = true;
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(stats) {
    return;
  }
  let mult = role == CBRoleLeader() ? CBConfig.LeaderHealthMult() : CBConfig.LieutenantHealthMult();
  let id = Cast<StatsObjectID>(puppet.GetEntityID());
  let hp = RPGManager.CreateStatModifier(gamedataStatType.Health, gameStatModifierType.Multiplier, mult);
  if IsDefined(hp) {
    stats.AddModifier(id, hp);
  }
}

@addField(ScriptedPuppet)
public let cbRoleBuffed: Bool;

// ---- Scars -----------------------------------------------------------------

// A short word for what V did to them, for the Hub. Worst wound wins, so this stays to one
// column and never grows with the number of scars.
public func CBScarLabel(mask: Int32) -> String {
  if mask == 0 {
    return "";
  }
  if CBMaskHas(mask, CBScarBurned()) {
    return "burned";
  }
  if CBMaskHas(mask, CBScarFried()) {
    return "fried";
  }
  if CBMaskHas(mask, CBScarCut()) {
    return "cut up";
  }
  if CBMaskHas(mask, CBScarShot()) {
    return "shot up";
  }
  return "";
}

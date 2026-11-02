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
func CBHierarchyScore(r: ref<CBRival>) -> Int32 {
  return IsDefined(r) ? r.rank * 100 + r.encounters : -1;
}

// The strongest of this gang's three lieutenants who is still standing, or null.
func CBBestLieutenant(sys: ref<CyberbaneSystem>, fs: ref<CBFactionState>) -> ref<CBRival> {
  let best: ref<CBRival> = null;
  let ids: array<Int32>;
  ArrayPush(ids, fs.lt1RivalId);
  ArrayPush(ids, fs.lt2RivalId);
  ArrayPush(ids, fs.lt3RivalId);
  let i = 0;
  while i < ArraySize(ids) {
    if CBSlotHolderActive(sys, ids[i]) {
      let r = sys.FindRivalById(ids[i]);
      if CBHierarchyScore(r) > CBHierarchyScore(best) {
        best = r;
      }
    }
    i += 1;
  }
  return best;
}

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
    // The strongest of the rest takes the crew, and "the rest" includes the lieutenants. This
    // only ever looked at Rivals holding no chair, so a gang whose survivors were all
    // lieutenants was left with nobody at the top however many of them there were.
    let promoted = CBBestCandidate(sys, fs);
    let lt = CBBestLieutenant(sys, fs);
    if IsDefined(lt) && (!IsDefined(promoted) || CBHierarchyScore(lt) >= CBHierarchyScore(promoted)) {
      if fs.lt1RivalId == lt.id { fs.lt1RivalId = 0; }
      if fs.lt2RivalId == lt.id { fs.lt2RivalId = 0; }
      if fs.lt3RivalId == lt.id { fs.lt3RivalId = 0; }
      promoted = lt;
    }
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
    if IsDefined(heir) && CBMessagesOn() {
      let content = CBContent(game);
      CBPhoneFromGang(game, rival.faction, CBRivalDisplayName(content, heir)
        + " runs us now. Nothing about you has changed.");
    }
  }
}

// Running a crew should be felt, not just labelled. Reuses the apex buff pattern at a much
// gentler scale, applied on attach to a spawned Rival.
// Gone, deliberately, and this note is here so it is not reintroduced.
//
// A Rival running a crew used to get their health multiplier from a second function applied
// straight after the apex-grade buff. Two appliers meant nothing knew the product, and the
// product is what players met: a leader nemesis at the top of the ladder came out at roughly
// eleven times health. The bonus still exists and is still worth the same thing relative to
// everything else, but it is now one term inside CBApplyApexBuild, where the ceiling can see
// it. CBRivalRole is passed to CBApplyRivalApexBuff instead.

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

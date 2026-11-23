// Cyberbane - Strongholds (2.7.2)
//
// "When a gang's Rivals run high in a district, a cleared gig base there is taken over by a named Rival boss, lieutenants
// and a full squad. Clearing it takes that Rival down for good, swings the district's turf, and pays."
//
//   - Where: the gigs V finishes. While a fixer's gig (the journal's Contract quests, never NCPD's) is active, where its
//     objective is pinned is noted; when the journal marks it done, that place is a cleared base (CBBaseBook). Only
//     gigs finished with this installed are known.
//   - When: once a game day, a gang hostile to V whose Rival is high enough (StrongholdMinRank) and free (in no fight
//     with V, at no place of their own, not V's crew's, nobody's job) may take a cleared base in a district it holds.
//     One per gang, StrongholdMax in the city; left alone, they move on after StrongholdDays.
//   - Finding it: the street says so, and it is on the map.
//   - Going there: within StrongholdReach, on foot, with the world settled and nothing else of Cyberbane's out, the
//     garrison is put round the base out of V's sight: the Rival, two lieutenants at apex grade and the rest of the
//     squad, StrongholdSize in all, under the room left. They wait there. Leave, and they are gone; the stronghold stays.
//   - Cleared: the Rival dies as Rivals do (for good), the gang loses the place and ground in the district, and it pays.
//     Spared, a Rival leaves the city as always, and the rest of them clear out.

public func CBMemStronghold() -> Int32 = 5

public func CBStrongholdsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBRivalsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().strongholds);
}

public class CBBaseBook extends ScriptableSystem {
  // Gigs under way: the quest, and where its objective was pinned.
  private persistent let m_wHash: array<Int32>;
  private persistent let m_wX: array<Float>;
  private persistent let m_wY: array<Float>;
  private persistent let m_wZ: array<Float>;
  // Cleared bases: the gig they were, where, the district, and how often they could not be used.
  private persistent let m_bHash: array<Int32>;
  private persistent let m_bX: array<Float>;
  private persistent let m_bY: array<Float>;
  private persistent let m_bZ: array<Float>;
  private persistent let m_bDistrict: array<CName>;
  private persistent let m_bFails: array<Int32>;
  // Strongholds: which base, whose Rival, which gang, until when.
  private persistent let m_sBase: array<Int32>;
  private persistent let m_sRival: array<Int32>;
  private persistent let m_sGang: array<CName>;
  private persistent let m_sUntil: array<Float>;
  private persistent let m_rollDay: Int32;
  // Session: the stronghold whose garrison is in the world now (its base's hash), 0 for none.
  public let placedBase: Int32;
  // The tick the garrison may next be tried, after a try every spot of which was in V's sight.
  public let nextTryTick: Int32;

  public static func Get(game: GameInstance) -> ref<CBBaseBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBBaseBook") as CBBaseBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.placedBase = 0;
    this.nextTryTick = 0;
  }

  public func WatchCount() -> Int32 {
    return Min(Min(ArraySize(this.m_wHash), ArraySize(this.m_wX)), Min(ArraySize(this.m_wY), ArraySize(this.m_wZ)));
  }

  public func Watching(hash: Int32) -> Bool { return ArrayContains(this.m_wHash, hash); }

  public func Watch(hash: Int32, at: Vector4) -> Void {
    if this.Watching(hash) || this.BaseIndex(hash) >= 0 {
      return;
    }
    ArrayPush(this.m_wHash, hash);
    ArrayPush(this.m_wX, at.X);
    ArrayPush(this.m_wY, at.Y);
    ArrayPush(this.m_wZ, at.Z);
    while this.WatchCount() > 30 {
      this.Unwatch(0);
    }
  }

  public func WatchHashAt(i: Int32) -> Int32 { return this.m_wHash[i]; }
  public func WatchAt(i: Int32) -> Vector4 { return new Vector4(this.m_wX[i], this.m_wY[i], this.m_wZ[i], 1.0); }

  public func Unwatch(i: Int32) -> Void {
    if i >= 0 && i < this.WatchCount() {
      ArrayErase(this.m_wHash, i);
      ArrayErase(this.m_wX, i);
      ArrayErase(this.m_wY, i);
      ArrayErase(this.m_wZ, i);
    }
  }

  public func BaseCount() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_bHash), ArraySize(this.m_bX)), Min(ArraySize(this.m_bY), ArraySize(this.m_bZ))),
               Min(ArraySize(this.m_bDistrict), ArraySize(this.m_bFails)));
  }

  public func BaseIndex(hash: Int32) -> Int32 {
    let i = 0;
    while i < this.BaseCount() {
      if this.m_bHash[i] == hash {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func AddBase(hash: Int32, at: Vector4, district: CName) -> Void {
    if this.BaseIndex(hash) >= 0 {
      return;
    }
    ArrayPush(this.m_bHash, hash);
    ArrayPush(this.m_bX, at.X);
    ArrayPush(this.m_bY, at.Y);
    ArrayPush(this.m_bZ, at.Z);
    ArrayPush(this.m_bDistrict, district);
    ArrayPush(this.m_bFails, 0);
    while this.BaseCount() > CBConfig.StrongholdBaseCap() {
      this.DropBase(0);
    }
  }

  public func BaseHashAt(i: Int32) -> Int32 { return this.m_bHash[i]; }
  public func BaseAt(i: Int32) -> Vector4 { return new Vector4(this.m_bX[i], this.m_bY[i], this.m_bZ[i], 1.0); }
  public func BaseDistrictAt(i: Int32) -> CName { return this.m_bDistrict[i]; }

  public func SetBaseAt(i: Int32, at: Vector4) -> Void {
    if i >= 0 && i < this.BaseCount() {
      this.m_bX[i] = at.X;
      this.m_bY[i] = at.Y;
      this.m_bZ[i] = at.Z;
    }
  }

  // A base that could not be used twice is dropped.
  public func BaseFailed(i: Int32) -> Bool {
    if i < 0 || i >= this.BaseCount() {
      return false;
    }
    this.m_bFails[i] += 1;
    if this.m_bFails[i] >= 2 {
      this.DropBase(i);
      return true;
    }
    return false;
  }

  // A hold on the dropped base is ended by CBStrongholdTick (its base is gone), which also takes its pin off the map.
  public func DropBase(i: Int32) -> Void {
    if i >= 0 && i < this.BaseCount() {
      ArrayErase(this.m_bHash, i);
      ArrayErase(this.m_bX, i);
      ArrayErase(this.m_bY, i);
      ArrayErase(this.m_bZ, i);
      ArrayErase(this.m_bDistrict, i);
      ArrayErase(this.m_bFails, i);
    }
  }

  public func HoldCount() -> Int32 {
    return Min(Min(ArraySize(this.m_sBase), ArraySize(this.m_sRival)), Min(ArraySize(this.m_sGang), ArraySize(this.m_sUntil)));
  }

  public func HoldIndexOfBase(hash: Int32) -> Int32 {
    let i = 0;
    while i < this.HoldCount() {
      if this.m_sBase[i] == hash {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func HoldIndexOfRival(id: Int32) -> Int32 {
    let i = 0;
    while i < this.HoldCount() {
      if this.m_sRival[i] == id {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func HoldOfGang(gang: CName) -> Bool { return ArrayContains(this.m_sGang, gang); }
  public func HoldBaseAt(i: Int32) -> Int32 { return this.m_sBase[i]; }
  public func HoldRivalAt(i: Int32) -> Int32 { return this.m_sRival[i]; }
  public func HoldGangAt(i: Int32) -> CName { return this.m_sGang[i]; }
  public func HoldUntilAt(i: Int32) -> Float { return this.m_sUntil[i]; }

  public func AddHold(base: Int32, rival: Int32, gang: CName, until: Float) -> Void {
    ArrayPush(this.m_sBase, base);
    ArrayPush(this.m_sRival, rival);
    ArrayPush(this.m_sGang, gang);
    ArrayPush(this.m_sUntil, until);
  }

  // The placed base is kept when its hold ends: whoever is still standing there leaves with the rest, by the leave check in
  // CBStrongholdTick (V walks away, or the base is gone), and nothing new is placed until they have.
  public func EndHold(i: Int32) -> Void {
    if i >= 0 && i < this.HoldCount() {
      ArrayErase(this.m_sBase, i);
      ArrayErase(this.m_sRival, i);
      ArrayErase(this.m_sGang, i);
      ArrayErase(this.m_sUntil, i);
    }
  }

  public func RollDay() -> Int32 { return this.m_rollDay; }
  public func SetRollDay(d: Int32) -> Void { this.m_rollDay = d; }

  public func Clear() -> Void {
    ArrayClear(this.m_wHash);
    ArrayClear(this.m_wX);
    ArrayClear(this.m_wY);
    ArrayClear(this.m_wZ);
    ArrayClear(this.m_bHash);
    ArrayClear(this.m_bX);
    ArrayClear(this.m_bY);
    ArrayClear(this.m_bZ);
    ArrayClear(this.m_bDistrict);
    ArrayClear(this.m_bFails);
    ArrayClear(this.m_sBase);
    ArrayClear(this.m_sRival);
    ArrayClear(this.m_sGang);
    ArrayClear(this.m_sUntil);
    this.m_rollDay = 0;
    this.placedBase = 0;
  }
}

// The gig a base was, by the journal's own title for it.
public func CBBaseName(game: GameInstance, hash: Int32) -> String {
  let journal = GameInstance.GetJournalManager(game);
  let q = IsDefined(journal) ? journal.GetEntry(Cast<Uint32>(hash)) as JournalQuest : null;
  let title = IsDefined(q) ? GetLocalizedText(q.GetTitle(journal)) : "";
  return StrLen(title) > 0 ? title : CBT(n"Cyberbane-Strongholds-AnOldJob");
}

// ---- Learning bases from finished gigs ---------------------------------------------------------------------------------

func CBBaseLearnTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBBaseBook>) -> Void {
  let journal = GameInstance.GetJournalManager(game);
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(journal) || !IsDefined(ms) || !CBWorldStable(game) {
    return;
  }
  // Gigs under way, and where they are pinned.
  let ctx: JournalRequestContext;
  ctx.stateFilter.active = true;
  let quests: array<wref<JournalEntry>>;
  journal.GetQuests(ctx, quests);
  for q in quests {
    let quest = q as JournalQuest;
    if IsDefined(quest) && Equals(quest.GetType(), gameJournalQuestType.Contract) {
      let hash = journal.GetEntryHash(q);
      if !book.Watching(hash) && book.BaseIndex(hash) < 0 {
        let found = false;
        let at: Vector4;
        let phases: array<wref<JournalEntry>>;
        journal.GetChildren(q, ctx.stateFilter, phases);
        for ph in phases {
          let objectives: array<wref<JournalEntry>>;
          journal.GetChildren(ph, ctx.stateFilter, objectives);
          for o in objectives {
            if !found && IsDefined(o as JournalQuestObjectiveBase) {
              let positions: array<Vector3>;
              if ms.GetQuestMappinPositionsByObjective(Cast<Uint32>(journal.GetEntryHash(o)), positions) && ArraySize(positions) > 0 {
                at = Vector4.Vector3To4(positions[0]);
                found = true;
              }
            }
          }
        }
        if found {
          book.Watch(hash, at);
        }
      }
    }
  }
  // Watched gigs that are over: done ones are bases, failed ones are forgotten.
  let i = book.WatchCount() - 1;
  while i >= 0 {
    let hash = book.WatchHashAt(i);
    let entry = journal.GetEntry(Cast<Uint32>(hash));
    let state = IsDefined(entry) ? journal.GetEntryState(entry) : gameJournalEntryState.Undefined;
    if Equals(state, gameJournalEntryState.Succeeded) {
      let at = book.WatchAt(i);
      book.AddBase(hash, at, CBDistrictAtPoint(sys, game, at));
      CBLog.Info(n"Rivals", "A finished gig's place is on record as a cleared base.");
      book.Unwatch(i);
    } else {
      if Equals(state, gameJournalEntryState.Failed) || Equals(state, gameJournalEntryState.Undefined) {
        book.Unwatch(i);
      }
    }
    i -= 1;
  }
}

// The district a point is in: V's own when V is near it, else the district V is in now (gigs are finished on the spot).
func CBDistrictAtPoint(sys: ref<CyberbaneSystem>, game: GameInstance, at: Vector4) -> CName {
  return sys.GetCurrentDistrict();
}

// ---- Taking one ------------------------------------------------------------------------------------------------------

// Holding a stronghold, a Rival sits there and waits for V: the Rival lane does not send them (Spawn/Queue.reds).
public func CBRivalHoldsBase(game: GameInstance, id: Int32) -> Bool {
  let book = CBBaseBook.Get(game);
  return CBStrongholdsOn() && IsDefined(book) && book.HoldIndexOfRival(id) >= 0;
}

// Their garrison is in the world right now, with them in it: a hideout (Rivals/Whereabouts.reds) does not place them twice.
public func CBRivalHoldPlaced(game: GameInstance, id: Int32) -> Bool {
  let book = CBBaseBook.Get(game);
  if !IsDefined(book) || book.placedBase == 0 {
    return false;
  }
  let h = book.HoldIndexOfBase(book.placedBase);
  return h >= 0 && book.HoldRivalAt(h) == id;
}

func CBStrongholdRivalFree(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || r.rank < CBConfig.StrongholdMinRank() {
    return false;
  }
  if r.state != EnumInt(ECBRivalState.Active) && r.state != EnumInt(ECBRivalState.Dormant)
     && r.state != EnumInt(ECBRivalState.Hunting) {
    return false;
  }
  let jb = CBCrewJobBook.Get(game);
  return r.id != sys.GetActiveRivalId() && !(sys.IsLairActive() && r.id == sys.GetLairRivalId()) && !sys.RivalKeptByCrew(r.id)
      && (!IsDefined(jb) || !jb.RivalTargeted(r.id));
}

func CBStrongholdRoll(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBBaseBook>, now: Float) -> Void {
  if book.HoldCount() >= CBConfig.StrongholdMax() || book.BaseCount() == 0 {
    return;
  }
  let score = sys.GetScore();
  let homes = CBHomeBook.Get(game);
  let taken = false;
  for r in sys.GetRivals() {
    if !taken && CBStrongholdRivalFree(sys, game, r) && !book.HoldOfGang(r.faction) && CBFactionOn(r.faction) {
      let posture = IsDefined(score) ? score.GetPosture(r.faction) : ECBPosture.Neutral;
      if (Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta)) && RandF() < CBConfig.StrongholdChancePerDay() {
        // A base in a district this gang holds, not one already taken, not round V's homes.
        let i = 0;
        while i < book.BaseCount() && !taken {
          let hash = book.BaseHashAt(i);
          let at = book.BaseAt(i);
          let d = book.BaseDistrictAt(i);
          if book.HoldIndexOfBase(hash) < 0 && NotEquals(d, n"") && Equals(CBTurfHolder(sys, game, d), r.faction)
             && (!IsDefined(homes) || homes.HomeAt(at) < 0) {
            taken = true;
            book.AddHold(hash, r.id, r.faction, now + CBConfig.StrongholdDays() * CBConfig.SecondsPerDay());
            CBStrongholdPin(sys, game, hash, at, r);
            if CBMessagesOn() {
              CBHearsayFromStreet(game, CBTf(n"Cyberbane-Strongholds-TookOver",
                                             [CBRivalDisplayName(sys.GetContent(), r), CBBaseName(game, hash), CBDistrictLabel(d)]), n"");
            }
            CBLog.Info(n"Rivals", s"Rival \(r.id) took a cleared base as a stronghold.");
          }
          i += 1;
        }
      }
    }
  }
}

func CBStrongholdPin(sys: ref<CyberbaneSystem>, game: GameInstance, hash: Int32, at: Vector4, r: ref<CBRival>) -> Void {
  let map = CBMapBook.Get(game);
  if IsDefined(map) {
    map.Add(CBMemStronghold(), at, CBGameSeconds(game), r.id, r.faction, n"", n"", sys.GetCurrentDistrict(), false);
    // The memory carries the base in its `at` slot's place: kept by the subject (the Rival) and looked up from the book.
  }
}

func CBStrongholdUnpin(game: GameInstance, rival: Int32) -> Void {
  let map = CBMapBook.Get(game);
  if !IsDefined(map) {
    return;
  }
  let k = map.Count() - 1;
  while k >= 0 {
    let m = map.At(k);
    if IsDefined(m) && m.kind == CBMemStronghold() && m.subject == rival {
      map.Forget(m);
    }
    k -= 1;
  }
}

// Shown while it is held.
public func CBStrongholdShown(game: GameInstance, rival: Int32) -> Bool {
  let book = CBBaseBook.Get(game);
  return CBStrongholdsOn() && CBMapMarkersOn() && IsDefined(book) && book.HoldIndexOfRival(rival) >= 0;
}

public func CBStrongholdPinTitle(sys: ref<CyberbaneSystem>, m: ref<CBMapMemory>) -> String {
  let r = sys.FindRivalById(m.subject);
  return CBTf(n"Cyberbane-Strongholds-PinTitle", [IsDefined(r) ? CBRivalDisplayName(sys.GetContent(), r) : CBT(n"Cyberbane-MapPins-ARival")]);
}

public func CBStrongholdPinDesc(sys: ref<CyberbaneSystem>, m: ref<CBMapMemory>) -> String {
  let book = CBBaseBook.Get(sys.GetGameInstance());
  let i = IsDefined(book) ? book.HoldIndexOfRival(m.subject) : -1;
  let place = i >= 0 ? CBBaseName(sys.GetGameInstance(), book.HoldBaseAt(i)) : "";
  return CBTf(n"Cyberbane-Strongholds-PinDesc", [place, CBCapFirst(CBFactionLabel(m.a))]);
}

// ---- The tick ----------------------------------------------------------------------------------------------------------

public func CBStrongholdTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBBaseBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) {
    return;
  }
  let tick = sys.GetTickCount();
  if tick % 30 == 7 {
    CBBaseLearnTick(sys, game, book);
  }
  if !CBStrongholdsOn() {
    if book.placedBase != 0 {
      CBStrongholdLeave(sys, game, book);
    }
    return;
  }
  let now = CBGameSeconds(game);
  // The daily roll.
  let day = CBGameDay(game) + 1;
  if book.RollDay() != day {
    let first = book.RollDay() == 0;
    book.SetRollDay(day);
    if !first {
      CBStrongholdRoll(sys, game, book, now);
    }
  }
  // Each stronghold: still held, cleared, given up, or run out.
  let score = sys.GetScore();
  let i = book.HoldCount() - 1;
  while i >= 0 {
    let rid = book.HoldRivalAt(i);
    let r = sys.FindRivalById(rid);
    let hash = book.HoldBaseAt(i);
    let gang = book.HoldGangAt(i);
    let bi = book.BaseIndex(hash);
    let place = CBBaseName(game, hash);
    if !IsDefined(r) || r.state == EnumInt(ECBRivalState.Slain) {
      let byV = book.placedBase == hash;
      if byV {
        CBStrongholdCleared(sys, game, gang, place);
      }
      CBStrongholdUnpin(game, rid);
      book.EndHold(i);
    } else {
      if r.state == EnumInt(ECBRivalState.Retired) || r.state == EnumInt(ECBRivalState.Debtor) {
        if CBMessagesOn() {
          CBHearsayFromStreet(game, CBTf(n"Cyberbane-Strongholds-Emptied", [CBCapFirst(CBFactionLabel(gang)), place]), n"");
        }
        CBStrongholdUnpin(game, rid);
        book.EndHold(i);
      } else {
        // A gang V has made peace with, or come round to, has no reason to sit in V's old job waiting for V.
        let posture = IsDefined(score) ? score.GetPosture(gang) : ECBPosture.Neutral;
        let stillAgainst = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
        if (now > book.HoldUntilAt(i) || !stillAgainst) && book.placedBase != hash {
          if CBMessagesOn() {
            CBHearsayFromStreet(game, CBTf(n"Cyberbane-Strongholds-MovedOn", [CBRivalDisplayName(sys.GetContent(), r), place]), n"");
          }
          CBStrongholdUnpin(game, rid);
          book.EndHold(i);
        } else {
          if bi < 0 {
            CBStrongholdUnpin(game, rid);
            book.EndHold(i);
          }
        }
      }
    }
    i -= 1;
  }
  // The garrison: put in the world when V comes, taken away when V goes.
  let ppos = player.GetWorldPosition();
  if book.placedBase != 0 {
    let pb = book.BaseIndex(book.placedBase);
    if pb < 0 || Vector4.Distance(ppos, book.BaseAt(pb)) > CBConfig.StrongholdLeave() {
      CBStrongholdLeave(sys, game, book);
    }
    return;
  }
  if tick % 2 != 0 || tick < book.nextTryTick || !CBWorldStable(game) || sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) || sys.IsOnJob()
     || IsDefined(player.GetMountedVehicle()) || sys.GetActiveRivalId() > 0 || sys.IsLairActive()
     || CBSpawnRoom(game) - CBCrewRoomKept(game) < CBConfig.StrongholdMinRoom() {
    return;
  }
  let h = 0;
  while h < book.HoldCount() {
    let hb = book.BaseIndex(book.HoldBaseAt(h));
    if hb >= 0 && Vector4.Distance(ppos, book.BaseAt(hb)) <= CBConfig.StrongholdReach() {
      CBStrongholdPlace(sys, game, book, h, hb);
      return;
    }
    h += 1;
  }
}

// The garrison round the base, out of V's sight: the Rival first, then two lieutenants, then the squad.
func CBStrongholdPlace(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBBaseBook>, h: Int32, bi: Int32) -> Void {
  let r = sys.FindRivalById(book.HoldRivalAt(h));
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(r) || !IsDefined(des) || !IsDefined(player) {
    return;
  }
  let base = book.BaseAt(bi);
  CBRivalTakeSignature(sys, game, r);
  // Onto walkable ground near the pin, the first time (a gig's pin can be on a desk or a rooftop).
  let ground: Vector4;
  let snapped: Vector4;
  if !CBNavSnap(game, base.X, base.Y, base.Z, snapped) || !CBSettleOnGround(game, snapped, ground)
     || !CBLairPointUsable(sys, game, ground) || sys.NearQuestPins(ground, CBConfig.QuestSpawnClearance()) {
    if book.BaseFailed(bi) {
      CBStrongholdUnpin(game, r.id);
      CBLog.Info(n"Rivals", "A stronghold's base could not be used twice; dropped.");
    }
    return;
  }
  book.SetBaseAt(bi, ground);
  let body: EntityID;
  if !CBPlaceOneAt(sys, game, r.recordID, r.appearance, ground, n"CB_Hold", body) {
    // Every spot was in V's sight: the place is fine, so try again shortly rather than count it against the base.
    book.nextTryTick = sys.GetTickCount() + 6;
    CBLog.Info(n"Rivals", "A stronghold's Rival could not be placed out of V's sight yet.");
    return;
  }
  r.spawnedEntityId = body;
  book.placedBase = book.HoldBaseAt(h);
  let want = Min(CBConfig.StrongholdSize() - 1, CBSpawnRoom(game) - CBCrewRoomKept(game));
  let placed = 0;
  let lt = 0;
  while lt < 2 && placed < want {
    let rec = CBApexRosterRecord(r.faction, lt);
    let ltBody: EntityID;
    if TDBID.IsValid(rec) && CBPlaceOneAt(sys, game, rec, n"", ground, n"CB_Hold", ltBody) {
      des.AssignTag(ltBody, n"CB_HoldLt");
      placed += 1;
    }
    lt += 1;
  }
  let grunt = CBGangTemplate(sys, r.faction);
  if TDBID.IsValid(grunt) && placed < want {
    placed += CBPlaceAround(sys, game, grunt, ground, want - placed, n"CB_Hold");
  }
  CBLog.Info(n"Rivals", s"A stronghold's garrison is in place: Rival \(r.id) and \(placed) more.");
}

// V left: the garrison goes, out of sight. The stronghold stays.
func CBStrongholdLeave(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBBaseBook>) -> Void {
  let h = book.HoldIndexOfBase(book.placedBase);
  if h >= 0 {
    let r = sys.FindRivalById(book.HoldRivalAt(h));
    if IsDefined(r) {
      let none: EntityID;
      r.spawnedEntityId = none;
    }
  }
  CBUntrackTagged(game, n"CB_Hold");
  CBDeleteTaggedSafe(game, n"CB_Hold", true, true);
  book.placedBase = 0;
}

// Its Rival dead with V there: the gang loses the place and ground in the district, and it pays.
func CBStrongholdCleared(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, place: String) -> Void {
  CBWeakenGang(sys, game, gang, CBConfig.StrongholdGangLoss());
  CBTurfNoteLocalLoss(sys, game, gang, CBConfig.StrongholdTurfLoss());
  CBStreetGiveMoney(game, CBConfig.StrongholdPay());
  CBFileLog(sys, n"StrongholdCleared", CBGameSeconds(game), CBEventDistrict(sys, game), gang, Cast<Float>(CBConfig.StrongholdPay()));
  CBSystemNote(game, CBTf(n"Cyberbane-Strongholds-Cleared", [place, CBFactionLabel(gang), s"\(CBConfig.StrongholdPay())"]), 8.0);
  CBLog.Info(n"Rivals", s"V cleared a stronghold of \(NameToString(gang)).");
}

// Set up as they come into the world (Spawn/Spawner.reds): hostile, waiting at the base, built by what they are.
public func CBSetUpHold(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(des) || !IsDefined(puppet) || !CBStillStanding(puppet) {
    return;
  }
  let id = puppet.GetEntityID();
  CBSetUpStreet(sys, game, puppet, true);
  let r = CBFindRivalByBody(sys, id);
  if IsDefined(r) {
    CBMarkRivalBody(puppet, r);
    CBRivalNoteBody(game, r, puppet);
    CBKitApexMember(puppet);
    CBKitRivalTraits(puppet as NPCPuppet, r);
    CBApplyRivalApexBuff(sys, game, puppet, r, CBRoleLeader());
    CBShowBossBar(puppet);
    return;
  }
  if des.IsTagged(id, n"CB_HoldLt") {
    CBKitApexMember(puppet);
    CBApplyApexBuild(sys, game, puppet, CBConfig.StrongholdLtGrade(), CBApexStrengthFraction(), 1.0);
    return;
  }
  CBKitSquadMember(puppet);
  CBApplyCrewBuild(sys, game, puppet);
}

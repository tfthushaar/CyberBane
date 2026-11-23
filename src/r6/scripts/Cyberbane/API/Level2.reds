// Cyberbane - extension API level 2 (2.7.5)
//
// What building the nomad expansion on level 1 asked for: two groups set against each other (or kept from each other's
// throats), a vehicle with nobody in it, loot laid in the world, places near V, Rivals to read, a History line of an
// add-on's own, and a pin that moves. Each goes through the gates Cyberbane's own go through, the same as level 1. The
// statics are on CyberbaneAPI; an add-on guards each call with `@if(ModuleExists("Cyberbane.Api2"))` (API/Api2Module.reds).

// ---- Two sides set to an attitude towards each other (SetGroupsHostile and the rest) --------------------------------
//
// Pairwise, body to body, the way Cyberbane sets two gangs against each other on the street (CBSetPairAttitude): never a
// change to how one whole attitude group sees another, which would reach every NPC of that gang in the city. Kept on the
// tick, so somebody who walks into the world after the call is set too, and taken back to how their groups stand when
// either side is released.

public func CBApiSideGroup() -> Int32 = 0
public func CBApiSideConvoy() -> Int32 = 1

public class CBApiPairs extends ScriptableSystem {
  private let m_aKind: array<Int32>;
  private let m_a: array<Int32>;
  private let m_bKind: array<Int32>;
  private let m_b: array<Int32>;
  private let m_hostile: array<Bool>;

  public static func Get(game: GameInstance) -> ref<CBApiPairs> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiPairs") as CBApiPairs : null;
  }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_aKind), ArraySize(this.m_a)), Min(Min(ArraySize(this.m_bKind), ArraySize(this.m_b)), ArraySize(this.m_hostile)));
  }

  public func AKind(i: Int32) -> Int32 { return this.m_aKind[i]; }
  public func A(i: Int32) -> Int32 { return this.m_a[i]; }
  public func BKind(i: Int32) -> Int32 { return this.m_bKind[i]; }
  public func B(i: Int32) -> Int32 { return this.m_b[i]; }
  public func Hostile(i: Int32) -> Bool { return this.m_hostile[i]; }

  public func Involves(i: Int32, kind: Int32, handle: Int32) -> Bool {
    return (this.m_aKind[i] == kind && this.m_a[i] == handle) || (this.m_bKind[i] == kind && this.m_b[i] == handle);
  }

  // One pair of sides holds one attitude: asked again, the newer answer stands.
  public func Set(aKind: Int32, a: Int32, bKind: Int32, b: Int32, hostile: Bool) -> Void {
    let i = 0;
    while i < this.Count() {
      if (this.m_aKind[i] == aKind && this.m_a[i] == a && this.m_bKind[i] == bKind && this.m_b[i] == b)
         || (this.m_aKind[i] == bKind && this.m_a[i] == b && this.m_bKind[i] == aKind && this.m_b[i] == a) {
        this.m_hostile[i] = hostile;
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_aKind, aKind);
    ArrayPush(this.m_a, a);
    ArrayPush(this.m_bKind, bKind);
    ArrayPush(this.m_b, b);
    ArrayPush(this.m_hostile, hostile);
  }

  public func Erase(i: Int32) -> Void {
    if i < 0 || i >= this.Count() {
      return;
    }
    ArrayErase(this.m_aKind, i);
    ArrayErase(this.m_a, i);
    ArrayErase(this.m_bKind, i);
    ArrayErase(this.m_b, i);
    ArrayErase(this.m_hostile, i);
  }
}

// A side's people still standing, behind the NPC gate. False when the side itself is gone: the group released, the convoy
// off the road.
func CBApiSidePuppets(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32, handle: Int32,
                      out people: array<ref<ScriptedPuppet>>) -> Bool {
  ArrayClear(people);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || handle <= 0 {
    return false;
  }
  let ids: array<EntityID>;
  if kind == CBApiSideConvoy() {
    let convoys = CBApiConvoys.Get(game);
    let run = IsDefined(convoys) ? convoys.Find(handle) : null;
    if !IsDefined(run) {
      return false;
    }
    ids = run.crewIds;
  } else {
    let reqs = CBApiRequests.Get(game);
    if !IsDefined(reqs) || !reqs.Known(handle) {
      return false;
    }
    ids = des.GetTaggedIDs(CBApiGroupTag(handle));
  }
  for id in ids {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) && IsDefined(p.GetAttitudeAgent()) {
      ArrayPush(people, p);
    }
  }
  return true;
}

// Both sides there, and not one side twice: the pair is kept, and set on the next tick.
public func CBApiSetSides(game: GameInstance, aKind: Int32, a: Int32, bKind: Int32, b: Int32, hostile: Bool) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let pairs = CBApiPairs.Get(game);
  if !IsDefined(sys) || !IsDefined(pairs) || (aKind == bKind && a == b) {
    return false;
  }
  let sideA: array<ref<ScriptedPuppet>>;
  let sideB: array<ref<ScriptedPuppet>>;
  if !CBApiSidePuppets(sys, game, aKind, a, sideA) || !CBApiSidePuppets(sys, game, bKind, b, sideB) {
    return false;
  }
  pairs.Set(aKind, a, bKind, b, hostile);
  return true;
}

// Set only where it differs, so the tick asks the engine nothing once everybody is set.
func CBApiKeepPairAttitude(sys: ref<CyberbaneSystem>, x: ref<ScriptedPuppet>, y: ref<ScriptedPuppet>, att: EAIAttitude) -> Void {
  let xa = x.GetAttitudeAgent();
  let ya = y.GetAttitudeAgent();
  if !IsDefined(xa) || !IsDefined(ya) || Equals(x.GetEntityID(), y.GetEntityID()) {
    return;
  }
  if NotEquals(xa.GetAttitudeTowards(ya), att) || NotEquals(ya.GetAttitudeTowards(xa), att) {
    CBSetPairAttitude(sys, x, y, att);
  }
}

public func CBApiPairsTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let pairs = CBApiPairs.Get(game);
  if !IsDefined(pairs) || pairs.Count() == 0 || !CBWorldStable(game) {
    return;
  }
  let i = pairs.Count() - 1;
  while i >= 0 {
    let sideA: array<ref<ScriptedPuppet>>;
    let sideB: array<ref<ScriptedPuppet>>;
    if !CBApiSidePuppets(sys, game, pairs.AKind(i), pairs.A(i), sideA) || !CBApiSidePuppets(sys, game, pairs.BKind(i), pairs.B(i), sideB) {
      pairs.Erase(i);
    } else {
      let att = pairs.Hostile(i) ? EAIAttitude.AIA_Hostile : EAIAttitude.AIA_Neutral;
      for x in sideA {
        for y in sideB {
          CBApiKeepPairAttitude(sys, x, y, att);
        }
      }
    }
    i -= 1;
  }
}

// A side is being released: every pair it is in is taken back to how the two people's attitude groups stand (the game's
// own relation, AttitudeSystem.GetAttitudeRelation), before its people lose their tags on the way out.
public func CBApiPairsRelease(game: GameInstance, kind: Int32, handle: Int32) -> Void {
  let sys = CyberbaneSystem.Get(game);
  let pairs = CBApiPairs.Get(game);
  let attSys = GameInstance.GetAttitudeSystem(game);
  if !IsDefined(sys) || !IsDefined(pairs) {
    return;
  }
  let i = pairs.Count() - 1;
  while i >= 0 {
    if pairs.Involves(i, kind, handle) {
      let sideA: array<ref<ScriptedPuppet>>;
      let sideB: array<ref<ScriptedPuppet>>;
      if CBApiSidePuppets(sys, game, pairs.AKind(i), pairs.A(i), sideA) && CBApiSidePuppets(sys, game, pairs.BKind(i), pairs.B(i), sideB) {
        for x in sideA {
          for y in sideB {
            let xa = x.GetAttitudeAgent();
            let ya = y.GetAttitudeAgent();
            if IsDefined(xa) && IsDefined(ya) {
              let rel = IsDefined(attSys) ? attSys.GetAttitudeRelation(xa.GetAttitudeGroup(), ya.GetAttitudeGroup()) : EAIAttitude.AIA_Neutral;
              CBSetPairAttitude(sys, x, y, rel);
            }
          }
        }
      }
      pairs.Erase(i);
    }
    i -= 1;
  }
}

// ---- People on V's side (R6) ------------------------------------------------------------------------------------------
//
// An add-on's group asked for on V's side, standing: they are paired against whoever is after V with V's own crew
// (CBCrewHostilityTick). Friendly to V alone, a group watched V's enemies shoot V: in the game's attitude table the
// Aldecaldos and the Wraiths are both plain children of the neutral group, with nothing between them.
public func CBApiSideBodies(sys: ref<CyberbaneSystem>, game: GameInstance, out friends: array<ref<ScriptedPuppet>>) -> Void {
  let reqs = CBApiRequests.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reqs) || !IsDefined(des) || !reqs.AnySide() {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Api");
  for id in ids {
    if reqs.SideOf(reqs.HandleOf(des, id)) {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if CBNpcSafe(sys, p) && CBStillStanding(p) && IsDefined(p.GetAttitudeAgent()) && !ArrayContains(friends, p) {
        ArrayPush(friends, p);
      }
    }
  }
}

// ---- A vehicle with nobody in it (RequestVehicle) ---------------------------------------------------------------------

public class CBApiVehicles extends ScriptableSystem {
  private let m_next: Int32;
  private let m_handles: array<Int32>;
  private let m_ids: array<EntityID>;
  private let m_wrecked: array<Bool>;
  private let m_dressed: array<Bool>;
  private let m_lastWhy: String;

  public static func Get(game: GameInstance) -> ref<CBApiVehicles> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiVehicles") as CBApiVehicles : null;
  }

  public func LastWhy() -> String { return this.m_lastWhy; }
  public func SetWhy(why: String) -> Void { this.m_lastWhy = why; }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_handles), ArraySize(this.m_ids)), Min(ArraySize(this.m_wrecked), ArraySize(this.m_dressed)));
  }

  public func Add(id: EntityID, wrecked: Bool) -> Int32 {
    this.m_next += 1;
    ArrayPush(this.m_handles, this.m_next);
    ArrayPush(this.m_ids, id);
    ArrayPush(this.m_wrecked, wrecked);
    ArrayPush(this.m_dressed, !wrecked);
    return this.m_next;
  }

  public func IndexOf(handle: Int32) -> Int32 {
    let i = ArrayFindFirst(this.m_handles, handle);
    return i >= 0 && i < this.Count() ? i : -1;
  }

  public func IdAt(i: Int32) -> EntityID { return this.m_ids[i]; }
  public func Undressed(i: Int32) -> Bool { return !this.m_dressed[i]; }
  public func Dressed(i: Int32) -> Void { this.m_dressed[i] = true; }

  public func Drop(handle: Int32) -> Void {
    let i = this.IndexOf(handle);
    if i >= 0 {
      ArrayErase(this.m_handles, i);
      ArrayErase(this.m_ids, i);
      ArrayErase(this.m_wrecked, i);
      ArrayErase(this.m_dressed, i);
    }
  }

  // Still in the world, or on its way into it.
  public func Live(game: GameInstance, des: ref<DynamicEntitySystem>) -> Int32 {
    let n = 0;
    let i = 0;
    while i < this.Count() {
      if des.IsSpawning(this.m_ids[i]) || IsDefined(GameInstance.FindEntityByID(game, this.m_ids[i])) {
        n += 1;
      }
      i += 1;
    }
    return n;
  }
}

public func CBApiVehicleTag(handle: Int32) -> CName {
  return StringToName("CB_ApiCar" + IntToString(handle));
}

// Placed out of V's sight, never during the story's scenes, and never more than a few at once. Tagged so Start over and
// switching Cyberbane off take it away with the rest, and removed only the safe way (never from under V).
public func CBApiRequestVehicle(game: GameInstance, record: TweakDBID, at: Vector4, wrecked: Bool) -> Int32 {
  let reg = CBApiVehicles.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(reg) || !IsDefined(des) {
    return 0;
  }
  if !IsDefined(rt) || !rt.IsEnabled() {
    reg.SetWhy("Cyberbane is switched off");
    return 0;
  }
  if !CBWorldStable(game) || CBStoryHoldNow(game) {
    reg.SetWhy(!CBWorldStable(game) ? "the world has not settled" : "the story has the stage");
    return 0;
  }
  if !TDBID.IsValid(record) || !IsDefined(TweakDBInterface.GetVehicleRecord(record)) {
    reg.SetWhy("that record is not a vehicle");
    return 0;
  }
  if reg.Live(game, des) >= CBConfig.ApiVehicleMax() {
    reg.SetWhy("no room: as many add-on vehicles are out as Cyberbane allows");
    return 0;
  }
  if !CBOutOfView(game, at) {
    reg.SetWhy("V would see it appear");
    return 0;
  }
  let spec = new DynamicEntitySpec();
  spec.recordID = record;
  spec.position = at;
  spec.orientation = Quaternion.BuildFromDirectionVector(new Vector4(1.0, 0.0, 0.0, 0.0));
  spec.persistState = false;
  spec.persistSpawn = false;
  spec.alwaysSpawned = false;
  spec.spawnInView = false;
  spec.active = true;
  CBTrace("vehicle: creating an add-on's vehicle");
  let id = des.CreateEntity(spec);
  if !EntityID.IsDefined(id) {
    reg.SetWhy("the game would not make it");
    return 0;
  }
  let handle = reg.Add(id, wrecked);
  des.AssignTag(id, n"Cyberbane");
  des.AssignTag(id, n"CB_ApiCar");
  des.AssignTag(id, CBApiVehicleTag(handle));
  CBLog.Info(n"Spawn", s"An add-on's vehicle placed (handle \(handle))" + (wrecked ? ", a wreck." : "."));
  return handle;
}

// A wreck is laid down a tick after it is in the world, never inside its attach: the game's own quest event for a
// vehicle's visual damage (VehicleQuestVisualDestructionEvent, which VehicleComponent turns into the destruction grid).
public func CBApiVehiclesTick(game: GameInstance) -> Void {
  let reg = CBApiVehicles.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reg) || !IsDefined(des) || reg.Count() == 0 || !CBWorldStable(game) {
    return;
  }
  let i = 0;
  while i < reg.Count() {
    if reg.Undressed(i) && !des.IsSpawning(reg.IdAt(i)) {
      let car = GameInstance.FindEntityByID(game, reg.IdAt(i)) as VehicleObject;
      if IsDefined(car) && car.IsAttached() {
        let evt = new VehicleQuestVisualDestructionEvent();
        evt.accumulate = false;
        evt.frontLeft = 1.0;
        evt.frontRight = 1.0;
        evt.front = 1.0;
        evt.right = 1.0;
        evt.left = 1.0;
        evt.backLeft = 1.0;
        evt.backRight = 1.0;
        evt.back = 1.0;
        evt.roof = 1.0;
        CBTrace("vehicle: an add-on's wreck dressed");
        car.QueueEvent(evt);
        reg.Dressed(i);
      }
    }
    i += 1;
  }
}

public func CBApiReleaseVehicle(game: GameInstance, handle: Int32) -> Void {
  let reg = CBApiVehicles.Get(game);
  if handle <= 0 || !IsDefined(reg) || reg.IndexOf(handle) < 0 {
    return;
  }
  CBDeleteTaggedSafe(game, CBApiVehicleTag(handle), false, true);
  reg.Drop(handle);
}

// ---- Loot laid in the world (DropLoot) ---------------------------------------------------------------------------------
//
// The stronghold stash's path (CBLootBagAt): the game's own drop bag, V its owner, the tier's loot scaled to V's level.
// Near V only: a bag laid where the world is not streamed in may never be there.
public func CBApiDropLoot(game: GameInstance, pos: Vector4, tier: Int32) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let player = GetPlayer(game);
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(rt) || !rt.IsEnabled() || !CBWorldStable(game) || CBStoryHoldNow(game)
     || Vector4.Distance(player.GetWorldPosition(), pos) > CBConfig.ApiLootReach() {
    return false;
  }
  let tiers: array<Int32> = [Clamp(tier, CBLootTierCrew(), CBLootTierApex() + 1)];
  return CBLootBagAt(sys, game, player, pos, tiers) > 0;
}

// ---- A pin that moves (MovePin) ----------------------------------------------------------------------------------------
public func CBApiMovePin(game: GameInstance, id: Int32, pos: Vector4) -> Bool {
  let reg = CBApiRequests.Get(game);
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(reg) || !IsDefined(ms) {
    return false;
  }
  return reg.MovePin(ms, id, pos);
}

// ---- Places near V (FindPlaces) ----------------------------------------------------------------------------------------
// The fast-travel points of a district (n"" for V's own) between two distances from V, where somebody can stand: what the
// street's events are placed at (CBFastTravelPlaces).
public func CBApiFindPlaces(game: GameInstance, district: CName, minDistance: Float, maxDistance: Float,
                            out positions: array<Vector4>, out names: array<String>) -> Int32 {
  ArrayClear(positions);
  ArrayClear(names);
  let sys = CyberbaneSystem.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) {
    return 0;
  }
  let d = IsNameValid(district) ? district : sys.GetCurrentDistrict();
  return CBFastTravelPlaces(sys, game, d, player.GetWorldPosition(), MaxF(minDistance, 0.0), MaxF(maxDistance, minDistance),
                            positions, names);
}

// ---- Rivals, read only -------------------------------------------------------------------------------------------------
public func CBApiRival(game: GameInstance, id: Int32) -> ref<CBRival> {
  let sys = CyberbaneSystem.Get(game);
  return IsDefined(sys) && id > 0 ? sys.FindRivalById(id) : null;
}

public func CBApiRivalIds(game: GameInstance) -> array<Int32> {
  let out: array<Int32>;
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return out;
  }
  let rivals = sys.GetRivals();
  for r in rivals {
    if IsDefined(r) && r.id > 0 {
      ArrayPush(out, r.id);
    }
  }
  return out;
}

public func CBApiRivalName(game: GameInstance, id: Int32) -> String {
  let r = CBApiRival(game, id);
  let content = CBContent(game);
  return IsDefined(r) && IsDefined(content) ? CBRivalDisplayName(content, r) : "";
}

// ---- A History line of the add-on's own (FileHistory), and the rule for its key ----------------------------------------
//
// The History shows an add-on's key as its own text, and tells it from Cyberbane's own kinds by the dash every
// localization key carries (UI/Hud.reds). A key without one would be read as one of Cyberbane's kinds, or as a blank line.
public func CBApiReasonKeyOk(key: CName) -> Bool {
  return IsNameValid(key) && StrContains(NameToString(key), "-");
}

public func CBApiFileHistory(game: GameInstance, faction: CName, reasonKey: CName) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) || !CBApiReasonKeyOk(reasonKey) || (IsNameValid(faction) && !CBFactionOn(faction)) {
    return false;
  }
  CBFileLog(sys, reasonKey, CBGameSeconds(game), CBEventDistrict(sys, game), faction, 0.0);
  return true;
}

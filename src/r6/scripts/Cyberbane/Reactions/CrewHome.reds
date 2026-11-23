// Cyberbane - The crew at home (2.7.2)
//
// "From rookie to enforcer", "one by the parking lot and another by the entrance"; "a crew stash for the legendary guns";
// spared Rivals who joined should "talk about the gang they ran with, and pass on what they know".
//
//   - Watch the house: a fourth kind of work on the crew's Work row. Up to Guards at home members take it. When V is on
//     home ground (Spawn/HomeGround.reds) they are at their posts: the building's door and the car park, both learned
//     from where V comes and goes. They are placed out of V's sight, stand their post, can be talked to, and fight anybody
//     of Cyberbane's who starts something there. They go, out of sight, once V leaves. One who goes down is hurt, as a
//     crew member knocked down on a call is.
//   - The armory is V's stash: near it, the Hub's weapon list shows the stash's guns as well as V's own. One given from the
//     stash stays in it; the member fights with its kind and tier, so nothing is carried and no mod comes off. If it is
//     gone from the stash the next time V is at it, it is gone from them.
//   - Talking to your own: how they are holding up, what their old gang was like from the inside, and whether they have
//     heard anything about a Rival from that gang.

public func CBTalkActCrewHolding() -> Int32 = 62
public func CBTalkActCrewGang() -> Int32 = 63
public func CBTalkActCrewHeard() -> Int32 = 64

public func CBCrewWorkGuard() -> Int32 = 3

public func CBGuardsMax() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? Clamp(rt.GetSettings().crewGuards, 0, 3) : 2;
}

public func CBGuardsOn() -> Bool {
  return CBMyCrewOn() && CBGuardsMax() > 0;
}

// ---- Who watches the house -----------------------------------------------------------------------------------------

public class CBGuardBook extends ScriptableSystem {
  private persistent let m_members: array<Int32>;   // on house watch, in the order they took it
  // Session only: who is standing a post now, and at which home (one up, 0 for none).
  private let m_body: array<EntityID>;
  private let m_bodyMember: array<Int32>;
  public let home: Int32;
  public let warned: Bool;

  public static func Get(game: GameInstance) -> ref<CBGuardBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBGuardBook") as CBGuardBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    ArrayClear(this.m_body);
    ArrayClear(this.m_bodyMember);
    this.home = 0;
    this.warned = false;
  }

  public func IsGuard(id: Int32) -> Bool { return id > 0 && ArrayContains(this.m_members, id); }
  public func Count() -> Int32 { return ArraySize(this.m_members); }
  public func MemberAt(i: Int32) -> Int32 { return i >= 0 && i < ArraySize(this.m_members) ? this.m_members[i] : 0; }

  public func Add(id: Int32) -> Void {
    if id > 0 && !ArrayContains(this.m_members, id) {
      ArrayPush(this.m_members, id);
    }
  }

  public func Remove(id: Int32) -> Void {
    ArrayRemove(this.m_members, id);
  }

  public func BodyCount() -> Int32 { return Min(ArraySize(this.m_body), ArraySize(this.m_bodyMember)); }
  public func BodyAt(i: Int32) -> EntityID { return this.m_body[i]; }

  public func BodyIndexOfMember(id: Int32) -> Int32 {
    let i = 0;
    while i < this.BodyCount() {
      if this.m_bodyMember[i] == id {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func MemberOfBody(body: EntityID) -> Int32 {
    let i = 0;
    while i < this.BodyCount() {
      if Equals(this.m_body[i], body) {
        return this.m_bodyMember[i];
      }
      i += 1;
    }
    return 0;
  }

  public func Placed(body: EntityID, id: Int32) -> Void {
    ArrayPush(this.m_body, body);
    ArrayPush(this.m_bodyMember, id);
  }

  public func DropBody(i: Int32) -> Void {
    if i >= 0 && i < this.BodyCount() {
      ArrayErase(this.m_body, i);
      ArrayErase(this.m_bodyMember, i);
    }
  }

  // Start over (Core/CyberbaneSystem.reds, HardReset).
  public func Clear() -> Void {
    ArrayClear(this.m_members);
    ArrayClear(this.m_body);
    ArrayClear(this.m_bodyMember);
    this.home = 0;
    this.warned = false;
  }
}

// Standing a post right now, so a call does not send a second of them.
public func CBGuardPosted(game: GameInstance, id: Int32) -> Bool {
  let gb = CBGuardBook.Get(game);
  return IsDefined(gb) && gb.BodyIndexOfMember(id) >= 0;
}

// Off house watch (the Work row moved on, they left the roster, or a hard reset), and off their post.
public func CBGuardStandDown(game: GameInstance, id: Int32) -> Void {
  let gb = CBGuardBook.Get(game);
  if !IsDefined(gb) {
    return;
  }
  gb.Remove(id);
  let k = gb.BodyIndexOfMember(id);
  if k >= 0 {
    let des = GameInstance.GetDynamicEntitySystem();
    if IsDefined(des) {
      des.DeleteEntity(gb.BodyAt(k));
    }
    gb.DropBody(k);
  }
}

// ---- At their posts --------------------------------------------------------------------------------------------------

// A post at home: the door, then the car park, then the door again a few metres over; nothing until one is learned.
func CBGuardPost(homes: ref<CBHomeBook>, home: Int32, slot: Int32) -> Vector4 {
  let door = homes.DoorAt(home);
  let park = homes.ParkAt(home);
  let hasDoor = door.X != 0.0 || door.Y != 0.0;
  let hasPark = park.X != 0.0 || park.Y != 0.0;
  if slot == 1 && hasPark {
    return park;
  }
  if hasDoor {
    return slot == 0 ? door : new Vector4(door.X + 3.0, door.Y + 3.0, door.Z, 1.0);
  }
  return hasPark ? park : new Vector4(0.0, 0.0, 0.0, 0.0);
}

// One body near a post, out of V's sight, the way a gathering's people are placed.
func CBPlaceOneAt(sys: ref<CyberbaneSystem>, game: GameInstance, record: TweakDBID, look: CName, at: Vector4, tag: CName,
                  out body: EntityID) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(des) || !IsDefined(player) || !TDBID.IsValid(record) || !CBRecordIsPerson(record) || CBSpawnRoom(game) <= 0 {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let fwd = player.GetWorldForward();
  let ring = 0;
  while ring < 3 {
    let radius = 1.5 + Cast<Float>(ring) * 2.0;
    let slots = 8;
    let k = 0;
    while k < slots {
      let ang = Cast<Float>(k) * 6.28318 / Cast<Float>(slots);
      k += 1;
      let snapped: Vector4;
      let spot: Vector4;
      if CBNavSnap(game, at.X + CosF(ang) * radius, at.Y + SinF(ang) * radius, at.Z, snapped)
         && CBSettleOnGround(game, snapped, spot) && CBPointHiddenFrom(game, ppos, fwd, spot)
         && CBStandsWith(game, spot, at, CBConfig.GroundMaxDrop()) {
        let facing = Quaternion.BuildFromDirectionVector(new Vector4(CosF(ang), SinF(ang), 0.0, 0.0));
        if CBCreateSpawn(des, record, look, spot, facing, tag, body) {
          return true;
        }
      }
    }
    ring += 1;
  }
  // Nowhere hidden that close: the navmesh's own hidden points near the spot, one query (2.7.3, Spawn/Spawner.reds).
  let pts: array<Vector4>;
  if CBPursuitPointsAround(game, ppos, at, 2, 3.0, CBConfig.PlaceAroundPursuitMax(), pts) {
    for p in pts {
      if CBPointHiddenFrom(game, ppos, fwd, p) && CBStandsWith(game, p, at, CBConfig.GroundMaxDrop()) {
        let toward = new Vector4(at.X - p.X, at.Y - p.Y, 0.0, 0.0);
        let face = Quaternion.BuildFromDirectionVector(Vector4.Length(toward) > 0.1 ? Vector4.Normalize(toward) : fwd);
        if CBCreateSpawn(des, record, look, p, face, tag, body) {
          return true;
        }
      }
    }
  }
  return false;
}

// On the crew's tick: on home ground, the watch is at its posts; anywhere else, it goes.
public func CBGuardTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let gb = CBGuardBook.Get(game);
  let homes = CBHomeBook.Get(game);
  let book = CBCrewBook.Get(game);
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(gb) || !IsDefined(homes) || !IsDefined(book) || !IsDefined(player) || !IsDefined(des) {
    return;
  }
  // Bodies the world no longer has: streamed out, deleted, or dead (CBGuardBodyDied has already seen to the hurt).
  let b = gb.BodyCount() - 1;
  while b >= 0 {
    let body = gb.BodyAt(b);
    let p = GameInstance.FindEntityByID(game, body) as ScriptedPuppet;
    if !des.IsSpawning(body) && (!IsDefined(p) || p.IsDead()) {
      gb.DropBody(b);
    }
    b -= 1;
  }
  let here = homes.HereIndex();
  if !CBGuardsOn() || here < 0 || (gb.home > 0 && gb.home != here + 1) {
    if gb.BodyCount() > 0 {
      CBDeleteTaggedSafe(game, n"CB_Guard", false, true);
    } else {
      // The last home's watch is gone: the home V is at now posts its own.
      gb.home = 0;
    }
    if here < 0 {
      gb.home = 0;
      gb.warned = false;
    }
    return;
  }
  gb.home = here + 1;
  CBGuardsDefend(sys, game, gb, des);
  if !CBWorldStable(game) || sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) || player.IsInCombat() {
    return;
  }
  let now = CBGameSeconds(game);
  let slot = 0;
  let i = 0;
  while i < gb.Count() && slot < CBGuardsMax() {
    let id = gb.MemberAt(i);
    i += 1;
    let m = book.Find(id);
    if IsDefined(m) {
      if gb.BodyIndexOfMember(id) >= 0 {
        slot += 1;
      } else {
        let free = !CBCrewHurt(m, now) && !book.IsOut(id) && !CBCrewAway(game, id, now) && !CBCrewSparring(game, id);
        let post = CBGuardPost(homes, here, slot);
        // Nothing until a post is learned at this home.
        if free && (post.X != 0.0 || post.Y != 0.0) {
          let record = m.record;
          if (!TDBID.IsValid(record) || !CBRecordIsPerson(record)) && NotEquals(m.faction, n"") {
            record = CBGangTemplate(sys, m.faction);
          }
          let made: EntityID;
          if CBPlaceOneAt(sys, game, record, m.look, post, n"CB_Guard", made) {
            gb.Placed(made, id);
            CBLog.Info(n"Crew", s"One of the crew took a post at home (slot \(slot + 1)).");
          }
          return;   // one a tick
        }
      }
    }
  }
}

// Set up as they come into the world (Spawn/Spawner.reds): their kit, on V's side, standing where they were put.
public func CBSetUpGuard(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let gb = CBGuardBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(puppet) || !IsDefined(gb) || !IsDefined(book) || !CBStillStanding(puppet) {
    return;
  }
  let m = book.Find(gb.MemberOfBody(puppet.GetEntityID()));
  CBDisarmGodMode(game, puppet);
  CBCrewKeepLook(sys, m, puppet);
  if IsDefined(m) {
    CBKitApexSeat(puppet, m.seat);
    CBCrewApplyKit(sys, game, puppet, m);
  }
  CBCrewFriendlyToV(game, puppet);
}

// Anybody of Cyberbane's in a fight near a post is the watch's fight too. Told to V once a visit.
func CBGuardsDefend(sys: ref<CyberbaneSystem>, game: GameInstance, gb: ref<CBGuardBook>, des: ref<DynamicEntitySystem>) -> Void {
  let reg = sys.GetRegistry();
  if gb.BodyCount() == 0 || !IsDefined(reg) {
    return;
  }
  let i = 0;
  while i < gb.BodyCount() {
    let guard = GameInstance.FindEntityByID(game, gb.BodyAt(i)) as ScriptedPuppet;
    i += 1;
    let gAgent = IsDefined(guard) && guard.IsAttached() && !guard.IsDead() ? guard.GetAttitudeAgent() : null;
    let gpos = IsDefined(gAgent) ? guard.GetWorldPosition() : new Vector4(0.0, 0.0, 0.0, 0.0);
    let looked: array<wref<ScriptedPuppet>>;
    if IsDefined(gAgent) {
      looked = reg.GetAll();
    }
    for p in looked {
      if CBNpcSafe(sys, p) && !p.IsDead() && des.IsTagged(p.GetEntityID(), n"Cyberbane") && !CBKillableFriend(p)
         && CBNpcInCombat(p) && Vector4.Distance(gpos, p.GetWorldPosition()) <= CBConfig.GuardDefendRange() {
        let pAgent = p.GetAttitudeAgent();
        if IsDefined(gAgent) && IsDefined(pAgent) && NotEquals(gAgent.GetAttitudeTowards(pAgent), EAIAttitude.AIA_Hostile) {
          gAgent.SetAttitudeTowards(pAgent, EAIAttitude.AIA_Hostile);
          if !gb.warned {
            gb.warned = true;
            let book = CBCrewBook.Get(game);
            CBCrewText(sys, game, IsDefined(book) ? book.Find(gb.MemberOfBody(guard.GetEntityID())) : null,
                       CBT(n"Cyberbane-CrewHome-TroubleAtTheHouse"));
          }
        }
      }
    }
  }
}

// One of the watch went down (Signals/CombatSignals.reds): hurt for a while, as a crew member knocked down on a call is.
public func CBGuardBodyDied(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  let gb = CBGuardBook.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(gb) || !IsDefined(book) || !IsDefined(puppet) {
    return false;
  }
  let id = gb.MemberOfBody(puppet.GetEntityID());
  let m = book.Find(id);
  if !IsDefined(m) {
    return false;
  }
  m.hurtUntil = CBGameSeconds(game) + CBConfig.MyCrewHurtDays() * CBConfig.SecondsPerDay();
  gb.DropBody(gb.BodyIndexOfMember(id));
  CBCrewText(sys, game, m, CBT(n"Cyberbane-CrewHome-TheyGotMeAtTheDoor"));
  CBLog.Info(n"Crew", "One of the watch went down at home: hurt, not lost.");
  return true;
}

// ---- The armory is V's stash ------------------------------------------------------------------------------------

public class CBArmoryBook extends ScriptableSystem {
  private persistent let m_member: array<Int32>;
  private persistent let m_item: array<ItemID>;
  private let m_stash: wref<GameObject>;   // the last stash V came up to, while it is in the world

  public static func Get(game: GameInstance) -> ref<CBArmoryBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBArmoryBook") as CBArmoryBook : null;
  }

  public func NoteStash(s: wref<GameObject>) -> Void { this.m_stash = s; }

  // The stash, when it is still in the world and V is at it.
  public func StashNear(game: GameInstance) -> wref<GameObject> {
    let player = GetPlayer(game);
    let s = this.m_stash;
    if !IsDefined(s) || !s.IsAttached() || !IsDefined(player)
       || Vector4.Distance(player.GetWorldPosition(), s.GetWorldPosition()) > CBConfig.ArmoryReach() {
      return null;
    }
    return s;
  }

  // The stash while it is in the world, wherever V is in it.
  public func StashLoaded() -> wref<GameObject> {
    let s = this.m_stash;
    return IsDefined(s) && s.IsAttached() ? s : null;
  }

  private func IndexOf(id: Int32) -> Int32 {
    let i = 0;
    while i < Min(ArraySize(this.m_member), ArraySize(this.m_item)) {
      if this.m_member[i] == id {
        return i;
      }
      i += 1;
    }
    return -1;
  }

  public func Has(id: Int32) -> Bool { return this.IndexOf(id) >= 0; }

  public func ItemOf(id: Int32) -> ItemID {
    let k = this.IndexOf(id);
    let none: ItemID;
    return k >= 0 ? this.m_item[k] : none;
  }

  public func Assigned(item: ItemID) -> Bool {
    let i = 0;
    while i < Min(ArraySize(this.m_member), ArraySize(this.m_item)) {
      if this.m_item[i] == item {
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func Assign(id: Int32, item: ItemID) -> Void {
    this.Release(id);
    ArrayPush(this.m_member, id);
    ArrayPush(this.m_item, item);
  }

  public func Release(id: Int32) -> Void {
    let k = this.IndexOf(id);
    if k >= 0 {
      ArrayErase(this.m_member, k);
      ArrayErase(this.m_item, k);
    }
  }

  public func Count() -> Int32 { return Min(ArraySize(this.m_member), ArraySize(this.m_item)); }
  public func MemberAt(i: Int32) -> Int32 { return this.m_member[i]; }

  public func Clear() -> Void {
    ArrayClear(this.m_member);
    ArrayClear(this.m_item);
  }
}

// V came up to a stash: it is the armory for as long as it stays in the world, and anything given from it that is gone
// from it now is gone from whoever had it.
@wrapMethod(Stash)
protected cb func OnInteractionActivated(evt: ref<InteractionActivationEvent>) -> Bool {
  wrappedMethod(evt);
  if IsDefined(evt) && Equals(evt.eventType, gameinteractionsEInteractionEventType.EIET_activate) {
    let game = this.GetGame();
    let ab = CBArmoryBook.Get(game);
    if IsDefined(ab) {
      ab.NoteStash(this);
      CBArmoryLook(CyberbaneSystem.Get(game), game);
    }
  }
  return true;
}

// Weapons in the stash V is at, for the Hub's list: the kinds the crew can use, none already given.
public func CBArmoryChoices(game: GameInstance) -> array<ItemID> {
  let out: array<ItemID>;
  let ab = CBArmoryBook.Get(game);
  let ts = GameInstance.GetTransactionSystem(game);
  let s = IsDefined(ab) ? ab.StashNear(game) : null;
  if !IsDefined(s) || !IsDefined(ts) {
    return out;
  }
  let items: array<wref<gameItemData>>;
  ts.GetItemList(s, items);
  for d in items {
    if IsDefined(d) && d.HasTag(n"Weapon") && !d.HasTag(n"Quest") && CBCrewSeatForWeapon(d.GetItemType()) >= 0
       && !ab.Assigned(d.GetID()) && ArraySize(out) < CBConfig.CrewPickListMax() {
      ArrayPush(out, d.GetID());
    }
  }
  return out;
}

// An item's data from V's own pockets, or from the stash V is at.
public func CBCrewItemData(game: GameInstance, item: ItemID) -> wref<gameItemData> {
  let ts = GameInstance.GetTransactionSystem(game);
  let player = GetPlayer(game);
  if !IsDefined(ts) || !IsDefined(player) {
    return null;
  }
  let data = ts.GetItemData(player, item);
  if IsDefined(data) {
    return data;
  }
  let ab = CBArmoryBook.Get(game);
  let s = IsDefined(ab) ? ab.StashNear(game) : null;
  return IsDefined(s) && Stash.IsInStash(s, item) ? ts.GetItemData(s, item) : null;
}

// Whether a weapon is one from the stash, not V's pockets.
public func CBArmoryFromStash(game: GameInstance, item: ItemID) -> Bool {
  let ts = GameInstance.GetTransactionSystem(game);
  let player = GetPlayer(game);
  if !IsDefined(ts) || !IsDefined(player) || IsDefined(ts.GetItemData(player, item)) {
    return false;
  }
  let ab = CBArmoryBook.Get(game);
  let s = IsDefined(ab) ? ab.StashNear(game) : null;
  return IsDefined(s) && Stash.IsInStash(s, item);
}

// Given from the stash: the member carries its kind and tier, and the gun stays where it is.
public func CBArmoryGive(sys: ref<CyberbaneSystem>, game: GameInstance, kb: ref<CBCrewKitBook>, m: ref<CBCrewMember>,
                         item: ItemID) -> Bool {
  let ab = CBArmoryBook.Get(game);
  let data = CBCrewItemData(game, item);
  if !IsDefined(ab) || !IsDefined(data) || !IsDefined(m) {
    return false;
  }
  let seat = CBCrewSeatForWeapon(data.GetItemType());
  if seat < 0 {
    return false;
  }
  let k = kb.Kit(m.id);
  CBCrewReturnWeapon(game, k);
  let tier = CBCrewTierOf(RPGManager.GetItemQuality(data));
  k.hasWeapon = true;
  k.weapon = item;
  k.weaponType = EnumInt(data.GetItemType());
  k.weaponTier = tier;
  ab.Assign(m.id, item);
  if seat != m.seat {
    m.seat = seat;
    if m.rival == 0 && NotEquals(m.faction, n"") {
      let rec = CBApexRosterRecord(m.faction, seat, m.seed);
      if TDBID.IsValid(rec) && CBRecordIsPerson(rec) {
        m.record = rec;
        m.look = n"";
      }
    }
  }
  CBCrewText(sys, game, m, CBTf(n"Cyberbane-CrewHome-FromTheLocker", [CBCrewItemName(ItemID.GetTDBID(item))]));
  CBLog.Info(n"Crew", s"V gave one of the crew a weapon from the stash (\(CBCrewSeatWord(seat)), tier \(tier)); it stays there.");
  return true;
}

// Back from a member who had one from the stash: nothing to hand over, it never left.
public func CBArmoryReturn(game: GameInstance, k: ref<CBCrewKit>) -> Bool {
  let ab = CBArmoryBook.Get(game);
  if !IsDefined(ab) || !IsDefined(k) || !ab.Has(k.id) {
    return false;
  }
  ab.Release(k.id);
  k.hasWeapon = false;
  k.weaponTier = 0;
  return true;
}

// At the stash: anything given from it and no longer in it is gone from whoever had it.
public func CBArmoryLook(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let ab = CBArmoryBook.Get(game);
  let kb = CBCrewKitBook.Get(game);
  let book = CBCrewBook.Get(game);
  let s = IsDefined(ab) ? ab.StashLoaded() : null;
  if !IsDefined(s) || !IsDefined(kb) || !IsDefined(book) {
    return;
  }
  let i = ab.Count() - 1;
  while i >= 0 {
    let id = ab.MemberAt(i);
    i -= 1;
    if !Stash.IsInStash(s, ab.ItemOf(id)) {
      let k = kb.Find(id);
      ab.Release(id);
      if IsDefined(k) {
        k.hasWeapon = false;
        k.weaponTier = 0;
      }
      CBCrewText(sys, game, book.Find(id), CBT(n"Cyberbane-CrewHome-SomebodyClearedMyGun"));
      CBLog.Info(n"Crew", "A gun given from the stash was gone from it; gone from them too.");
    }
  }
}

// ---- Talking to your own -----------------------------------------------------------------------------------------------

// The crew member a talk is with: one out with V or one at a post; null for anybody else.
public func CBCrewOfTalk(game: GameInstance, npc: wref<ScriptedPuppet>) -> ref<CBCrewMember> {
  let book = CBCrewBook.Get(game);
  let gb = CBGuardBook.Get(game);
  if !IsDefined(book) || !IsDefined(npc) {
    return null;
  }
  let m = book.MemberOfBody(npc.GetEntityID());
  if !IsDefined(m) && IsDefined(gb) {
    m = book.Find(gb.MemberOfBody(npc.GetEntityID()));
  }
  return m;
}

public func CBCrewTalkLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let m = CBCrewOfTalk(game, t.npc);
  if !IsDefined(m) {
    return out;
  }
  let h = CBTalkMakeLine(CBT(n"Cyberbane-CrewHome-AskHowAreYouHoldingUp"), CBTalkActCrewHolding(), t"ChoiceCaptionParts.TalkIcon");
  h.said = CBTalkDid(t.npc, CBTalkActCrewHolding());
  ArrayPush(out, h);
  if StrLen(CBFactionLabel(m.faction)) > 0 {
    let g = CBTalkMakeLine(CBTf(n"Cyberbane-CrewHome-AskTellMeAbout", [CBFactionLabel(m.faction)]), CBTalkActCrewGang(),
                           t"ChoiceCaptionParts.GangWatchIcon");
    g.said = CBTalkDid(t.npc, CBTalkActCrewGang());
    ArrayPush(out, g);
    let w = CBTalkMakeLine(CBT(n"Cyberbane-CrewHome-AskHeardAnything"), CBTalkActCrewHeard(), t"ChoiceCaptionParts.BountyHuntIcon");
    w.said = CBTalkDid(t.npc, CBTalkActCrewHeard());
    ArrayPush(out, w);
  }
  let d = CBTalkMakeLine(CBT(n"Cyberbane-CrewHome-DismissBackToIt"), CBTalkDismiss(), t"ChoiceCaptionParts.BackOutIcon");
  ArrayPush(out, d);
  return out;
}

public func CBCrewTalkAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, choice: Int32,
                             again: Bool) -> ref<CBTalkAnswer> {
  let m = CBCrewOfTalk(game, t.npc);
  if !IsDefined(m) {
    return null;
  }
  if choice == CBTalkActCrewHolding() {
    return CBTalkSay(CBCrewHoldingLine(game, m), n"");
  }
  if choice == CBTalkActCrewGang() {
    return CBTalkSay(CBCrewGangLore(m.faction, m.seed + (again ? 1 : 0)) + CBCrewLoreTail(m), n"");
  }
  if choice == CBTalkActCrewHeard() {
    // One weak spot per talk: asking again straight away does not empty their head of every one they know.
    return CBTalkSay(again ? CBT(n"Cyberbane-TalkTopics-SameAsFiveMinutesAgo") : CBCrewHeardLine(sys, game, m), n"");
  }
  return null;
}

// Loyalty in their own words, what last cost it, and the cut.
func CBCrewHoldingLine(game: GameInstance, m: ref<CBCrewMember>) -> String {
  let line = "";
  if m.loyalty >= 80 {
    line = CBT(n"Cyberbane-CrewHome-HoldingBest");
  } else {
    if m.loyalty >= 60 {
      line = CBT(n"Cyberbane-CrewHome-HoldingGood");
    } else {
      if m.loyalty >= CBConfig.MyCrewRestless() {
        line = CBT(n"Cyberbane-CrewHome-HoldingFine");
      } else {
        line = CBT(n"Cyberbane-CrewHome-HoldingBad");
      }
    }
  }
  let worry = CBCrewWorry(m);
  if StrLen(worry) > 0 && m.loyalty < 80 {
    line += CBTf(n"Cyberbane-CrewHome-WhatEatsAtMe", [worry]);
  }
  let book = CBCrewBook.Get(game);
  if IsDefined(book) && book.CutOwed() > 0 {
    line += CBT(n"Cyberbane-CrewHome-AndTheCut");
  }
  return line;
}

// What they say about the gang they came from: three things true of it, one a time.
public func CBCrewGangLore(gang: CName, seed: Int32) -> String {
  let n = Abs(seed) % 3;
  if Equals(gang, n"Mox") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreMox0", n"Cyberbane-CrewHome-LoreMox1", n"Cyberbane-CrewHome-LoreMox2"); }
  if Equals(gang, n"Maelstrom") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreMaelstrom0", n"Cyberbane-CrewHome-LoreMaelstrom1", n"Cyberbane-CrewHome-LoreMaelstrom2"); }
  if Equals(gang, n"Valentinos") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreValentinos0", n"Cyberbane-CrewHome-LoreValentinos1", n"Cyberbane-CrewHome-LoreValentinos2"); }
  if Equals(gang, n"TygerClaws") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreTygerClaws0", n"Cyberbane-CrewHome-LoreTygerClaws1", n"Cyberbane-CrewHome-LoreTygerClaws2"); }
  if Equals(gang, n"SixthStreet") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreSixthStreet0", n"Cyberbane-CrewHome-LoreSixthStreet1", n"Cyberbane-CrewHome-LoreSixthStreet2"); }
  if Equals(gang, n"Animals") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreAnimals0", n"Cyberbane-CrewHome-LoreAnimals1", n"Cyberbane-CrewHome-LoreAnimals2"); }
  if Equals(gang, n"VoodooBoys") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreVoodooBoys0", n"Cyberbane-CrewHome-LoreVoodooBoys1", n"Cyberbane-CrewHome-LoreVoodooBoys2"); }
  if Equals(gang, n"Scavengers") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreScavengers0", n"Cyberbane-CrewHome-LoreScavengers1", n"Cyberbane-CrewHome-LoreScavengers2"); }
  if Equals(gang, n"Barghest") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreBarghest0", n"Cyberbane-CrewHome-LoreBarghest1", n"Cyberbane-CrewHome-LoreBarghest2"); }
  if Equals(gang, n"Scrappers") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreScrappers0", n"Cyberbane-CrewHome-LoreScrappers1", n"Cyberbane-CrewHome-LoreScrappers2"); }
  if Equals(gang, n"Aldecaldos") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreAldecaldos0", n"Cyberbane-CrewHome-LoreAldecaldos1", n"Cyberbane-CrewHome-LoreAldecaldos2"); }
  if Equals(gang, n"Wraiths") { return CBPickOf(n, n"Cyberbane-CrewHome-LoreWraiths0", n"Cyberbane-CrewHome-LoreWraiths1", n"Cyberbane-CrewHome-LoreWraiths2"); }
  return CBT(n"Cyberbane-CrewHome-LoreNone");
}

func CBPickOf(n: Int32, a: CName, b: CName, c: CName) -> String {
  if n == 0 { return CBT(a); }
  if n == 1 { return CBT(b); }
  return CBT(c);
}

// How they came to V colours how they tell it.
func CBCrewLoreTail(m: ref<CBCrewMember>) -> String {
  if m.kind == CBCrewOwed() { return CBT(n"Cyberbane-CrewHome-TailOwed"); }
  if m.kind == CBCrewFrightened() { return CBT(n"Cyberbane-CrewHome-TailFrightened"); }
  if m.kind == CBCrewPaid() { return CBT(n"Cyberbane-CrewHome-TailPaid"); }
  if m.kind == CBCrewLent() { return CBT(n"Cyberbane-CrewHome-TailLent"); }
  return "";
}

// A Rival from their old gang whose weak spot they know, once; else what they make of the ones still out there.
func CBCrewHeardLine(sys: ref<CyberbaneSystem>, game: GameInstance, m: ref<CBCrewMember>) -> String {
  let intel = CBIntelBook.Get(game);
  let content = sys.GetContent();
  let tough: ref<CBRival>;
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, m.faction) && r.id != m.rival && r.state != EnumInt(ECBRivalState.Slain)
       && r.state != EnumInt(ECBRivalState.Retired) {
      let flaw = CBRivalFlaw(r);
      if flaw != 0 && IsDefined(intel) && !intel.KnowsFlaw(r.id) {
        intel.LearnFlaw(r.id);
        CBLog.Info(n"Crew", "One of the crew gave up a Rival's weak spot.");
        return CBTf(n"Cyberbane-CrewHome-HeardFlaw", [CBRivalDisplayName(content, r), CBFlawStory(flaw), CBFlawWord(flaw)]);
      }
      if !IsDefined(tough) {
        tough = r;
      }
    }
  }
  if IsDefined(tough) {
    return CBTf(n"Cyberbane-CrewHome-HeardNothingOn", [CBRivalDisplayName(content, tough)]);
  }
  return CBT(n"Cyberbane-CrewHome-HeardNothing");
}

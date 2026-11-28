// Cyberbane - V in the crew's war
//
// Every order, and every move of theirs the crew hears of, has a place and a deadline. V reaching the place before it
// makes it a fight there and then: the gang's people placed through the street events' spawner, in waves while V holds
// the place, the crew called in, and a few of the squads' own people at V's side. A lieutenant is the Rival met where
// they were last seen, as any lead is. Won when their last wave breaks or their lieutenant falls, and what they had on
// them is V's.

public func CBEvWarFight() -> CName = n"WarFight"

// One fight at a time, for the session: whose war, an order or their move, a rescue, the waves, and the squads' people
// who came. The squads' people outlive the fight until they have walked off (CBWarSquadsLeave).
public class CBWarFightBook extends ScriptableSystem {
  public let gang: CName;
  public let isOrder: Bool;
  public let order: Int32;         // the order fought, kept for the spoils once the war has moved on
  public let rescue: Int32;        // the member being rescued, 0 for none
  public let counter: Bool;        // a counterattack on the crew's corners (Reactions/CrewLife.reds)
  public let on: Bool;
  public let markedTick: Int32;
  public let cuttersUsed: Bool;
  public let wave: Int32;
  public let waves: Int32;
  public let size: Int32;
  public let apex: Int32;
  public let at: Vector4;
  public let downTotal: Int32;     // their people down in the waves before this one
  public let byVTotal: Int32;      // and how many of them by V's hand
  public let squadIds: array<EntityID>;

  public static func Get(game: GameInstance) -> ref<CBWarFightBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBWarFightBook") as CBWarFightBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.Reset();
    ArrayClear(this.squadIds);
  }

  public func Reset() -> Void {
    this.gang = n"";
    this.isOrder = false;
    this.order = 0;
    this.rescue = 0;
    this.counter = false;
    this.on = false;
    this.markedTick = 0;
    this.cuttersUsed = false;
    this.wave = 0;
    this.waves = 0;
    this.size = 0;
    this.apex = 0;
    this.downTotal = 0;
    this.byVTotal = 0;
  }
}

func CBWarSpotKnown(at: Vector4) -> Bool {
  return AbsF(at.X) > 0.5 || AbsF(at.Y) > 0.5;
}

func CBWarDistTo(player: ref<PlayerPuppet>, at: Vector4) -> Float {
  let ppos = player.GetWorldPosition();
  return AbsF(ppos.Z - at.Z) <= CBConfig.EventSameLevel() ? Vector4.Distance2D(ppos, at) : Vector4.Distance(ppos, at);
}

// Is this war's order (isOrder) or move being fought on screen right now?
public func CBWarFightOnFor(game: GameInstance, gang: CName, isOrder: Bool) -> Bool {
  let wf = CBWarFightBook.Get(game);
  return IsDefined(wf) && wf.on && !wf.counter && wf.rescue == 0 && Equals(wf.gang, gang) && Equals(wf.isOrder, isOrder);
}

// Is V there for the order (isOrder) or their move? True while a fight on screen is under way or waiting on the story,
// so the war does not settle it off screen meanwhile. V reaching the place before the deadline starts it at once.
public func CBWarFightNear(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, isOrder: Bool, now: Float) -> Bool {
  let wf = CBWarFightBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(wf) || !IsDefined(player) || !IsDefined(f) {
    return false;
  }
  if CBWarFightOnFor(game, f.gang, isOrder) {
    return CBWarFightWatch(sys, game, wf, f, now);
  }
  let at = isOrder ? f.OrderPlace() : f.MovePlace();
  let deadline = isOrder ? f.orderAt : f.moveAt;
  if wf.on || !CBWarSpotKnown(at) || deadline <= 0.0 || now > deadline {
    return false;
  }
  let dist = CBWarDistTo(player, at);
  // A lieutenant seen somewhere is the Rival at that place: the lead brings them, and the war waits on how that meeting
  // goes. One nobody has seen is fought for like any order, among their people.
  if isOrder && f.order == CBWarOrderLieutenant() && CBWarLieutenantSeen(sys, f) {
    return CBWarLieutenantWatch(sys, game, f, dist);
  }
  if dist > CBConfig.WarFightReach() {
    return false;
  }
  if !CBWorldStable(game) || sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) {
    return true;   // the story has the stage: it waits until its deadline
  }
  return CBWarFightStart(sys, game, wf, f, isOrder, at);
}

func CBWarFightStart(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>, f: ref<CBWarFront>, isOrder: Bool, at: Vector4) -> Bool {
  let life = CBStreetLifeFor(game);
  if !IsDefined(life) {
    return false;
  }
  let engine = life.Events();
  // The war comes before the street's own business: an event still waiting for its people gives way.
  let live = engine.Live();
  if IsDefined(live) {
    if live.placed || !CBEventKindIsOwn(live.kind) {
      return false;   // something placed, or an add-on's: it happens off screen
    }
    engine.End(game);
  }
  let waves = CBWarWaves(f, isOrder);
  let size = CBWarFightSize(game, f, isOrder);
  let apex = isOrder && f.order == CBWarOrderStorm() ? CBConfig.WarStormApex() : (CBSquadKindOn(game, CBSquadKnives()) ? 0 : 1);
  // Their best come with the last wave.
  if !engine.StartWarFight(sys, game, f.gang, at, size, waves > 1 ? 0 : apex) {
    return false;
  }
  wf.Reset();
  wf.gang = f.gang;
  wf.isOrder = isOrder;
  wf.order = isOrder ? f.order : 0;
  wf.on = true;
  wf.wave = 1;
  wf.waves = waves;
  wf.size = size;
  wf.apex = apex;
  wf.at = at;
  CBSkipTimeWithdraw(game, n"War");
  // The crew comes: everybody free, and the party on this war's streets; then the squads' own, then a friend gang's.
  if StrLen(CBCrewCallBlocked(sys, game, true)) == 0 {
    CBCrewCall(sys, game, true);
  }
  CBWarSquadsJoin(sys, game, wf, isOrder ? f.order : 0, f.gang, size);
  if IsNameValid(f.ally) {
    CBWarAllyComes(sys, game, f.ally);
  }
  if CBMessagesOn() {
    let label = CBFactionLabel(f.gang);
    CBCrewText(sys, game, CBCrewSecond(game), waves > 1 ? CBTf(n"Cyberbane-GangWar-FightHereWaves", [label]) : CBTf(n"Cyberbane-GangWar-FightHere", [label]), true, true);
  }
  CBLog.Info(n"War", s"V is there: the fight with \(NameToString(f.gang)) is on screen (\(size) of theirs in the first of \(waves) waves, order \(isOrder), \(ArraySize(wf.squadIds)) of the squads with V).");
  return true;
}

// How many waves of theirs: two for their corners, a stash or a hit on the crew's own streets or home, three for their
// boss, one for anything else.
func CBWarWaves(f: ref<CBWarFront>, isOrder: Bool) -> Int32 {
  if isOrder {
    if f.order == CBWarOrderStorm() { return 3; }
    if f.order == CBWarOrderCorners() || f.order == CBWarOrderStash() { return 2; }
    return 1;
  }
  return f.move == CBWarMoveCorner() || f.move == CBWarMoveRaid() ? 2 : 1;
}

// How many of theirs in the first wave: by the order and their manpower, fewer when the fighters hit the flank first (S6).
func CBWarFightSize(game: GameInstance, f: ref<CBWarFront>, isOrder: Bool) -> Int32 {
  let base = CBConfig.WarFightSize();
  if isOrder && f.order == CBWarOrderStorm() {
    base = CBConfig.WarStormSize();
  }
  if isOrder && f.order == CBWarOrderStash() {
    base -= 1;
  }
  let wb = CBWarBook.Get(game);
  let men = IsDefined(wb) ? wb.Men(f.gang) : 100.0;
  let n = Cast<Float>(base) * (0.5 + 0.5 * ClampF(men / 100.0, 0.0, 1.0));
  if CBSquadKindOn(game, CBSquadGuns()) {
    n *= 0.75;
  }
  return Clamp(RoundF(n), 2, CBConfig.WarStormSize());
}

// While the fight is on: a wave broken brings the next, the last broken is a win; V down or gone is a loss.
func CBWarFightWatch(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>, f: ref<CBWarFront>, now: Float) -> Bool {
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  let player = GetPlayer(game);
  if !IsDefined(ev) || !Equals(ev.kind, CBEvWarFight()) || !IsDefined(player) {
    // The engine let it go (out of time, never placed): settled off screen.
    CBWarFightOver(sys, game, wf);
    return false;
  }
  CBWarFightMarks(sys, game, wf, ev);
  let up: Int32;
  let byV: Int32;
  CBSideCount(game, ev, 0, up, byV);
  let far = CBWarDistTo(player, ev.at) > CBConfig.WarFightLeave();
  // Their side broken: down, fled or given up, whoever's hand it was. Nobody else is in a war fight.
  let broken = ev.placed && ArraySize(ev.ids) > 0 && up == 0;
  let lost = CBVDown(game) || far;
  if !broken && !lost {
    return true;
  }
  if broken && !lost && wf.wave < wf.waves && CBWarNextWave(sys, game, wf, life, ev, byV) {
    return true;
  }
  let down = wf.downTotal + ArraySize(ev.ids);
  let mine = wf.byVTotal + byV;
  let outcome = lost ? CBWarOutcomeLost() : (mine * 2 >= down ? CBWarOutcomeDecisive() : CBWarOutcomeWon());
  let isOrder = wf.isOrder;
  let order = wf.order;
  let at = ev.at;
  CBWarFightOver(sys, game, wf);
  life.Events().End(game);
  if isOrder {
    CBWarResolveOrder(sys, game, f, outcome + 10);
  } else {
    CBWarResolveMove(sys, game, f, !lost);
    if !lost && CBSquadKindOn(game, CBSquadWatch()) {
      f.heldBehind = true;   // the guards hold the place after
    }
  }
  if !lost {
    CBWarFightSpoils(sys, game, isOrder, order, at);
  }
  CBLog.Info(n"War", s"The fight with \(NameToString(f.gang)) is over: \(lost ? "V lost it" : "their side broke") (\(down) of theirs down, \(mine) by V).");
  return true;
}

// Their wave broken and more of them coming: the next, at the same place, a little smaller, their best with the last.
// False when nobody more could be sent; then it is won as it stands.
func CBWarNextWave(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>, life: ref<CBStreetLife>, ev: ref<CBStreetEvent>, byV: Int32) -> Bool {
  let count = ArraySize(ev.ids);
  let next = Max(2, RoundF(Cast<Float>(wf.size) * CBConfig.WarWaveShare()));
  let last = wf.wave + 1 >= wf.waves;
  life.Events().End(game);
  if !life.Events().StartWarFight(sys, game, wf.gang, wf.at, next, last ? wf.apex : 0) {
    return false;   // counted with the last wave by the caller
  }
  wf.downTotal += count;
  wf.byVTotal += byV;
  wf.wave += 1;
  wf.size = next;
  if CBMessagesOn() {
    let label = CBFactionLabel(wf.gang);
    CBCrewText(sys, game, CBCrewSecond(game), last ? CBTf(n"Cyberbane-GangWar-WaveLast", [label]) : CBTf(n"Cyberbane-GangWar-WaveMore", [label]), true, true);
  }
  CBLog.Info(n"War", s"Wave \(wf.wave) of \(wf.waves) from \(NameToString(wf.gang)): \(next) more.");
  return true;
}

// Every way a war fight ends comes here: the book cleared, and the squads' people sent home.
func CBWarFightOver(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>) -> Void {
  CBWarSquadsLeave(sys, game, wf);
  wf.Reset();
}

// A fight won on screen leaves what they had on them: a bag at the place, as a stronghold's stash does, better for a
// bigger fight.
func CBWarFightSpoils(sys: ref<CyberbaneSystem>, game: GameInstance, isOrder: Bool, order: Int32, at: Vector4) -> Void {
  let tiers: array<Int32>;
  if isOrder && order == CBWarOrderStorm() {
    ArrayPush(tiers, 3);
    ArrayPush(tiers, 4);
  } else {
    if isOrder && order == CBWarOrderStash() {
      ArrayPush(tiers, 2);
      ArrayPush(tiers, 3);
    } else {
      ArrayPush(tiers, 2);
    }
  }
  if CBLootBagAt(sys, game, GetPlayer(game), at, tiers) > 0 && CBMessagesOn() {
    CBSystemNote(game, CBT(n"Cyberbane-GangWar-FightSpoils"), 5.0);
  }
}

// Lookouts marked their people (S6): on the map and over their heads, as hunters are.
func CBWarFightMarks(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>, ev: ref<CBStreetEvent>) -> Void {
  if !ev.placed || !CBSquadKindOn(game, CBSquadEyes()) || sys.GetTickCount() - wf.markedTick < 5 {
    return;
  }
  wf.markedTick = sys.GetTickCount();
  for id in ev.ids {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) && !p.cbMapped {
      CBTrackOnMap(game, p);
    }
  }
}

func CBWarLieutenantSeen(sys: ref<CyberbaneSystem>, f: ref<CBWarFront>) -> Bool {
  let r = sys.FindRivalById(f.orderTarget);
  return IsDefined(r) && IsDefined(CBSightingFor(sys, r));
}

// A lieutenant on screen: V near the lead's place, and the Rival still out there. Their fall while the order is on, by
// whoever's hand, settles it as won.
func CBWarLieutenantWatch(sys: ref<CyberbaneSystem>, game: GameInstance, f: ref<CBWarFront>, dist: Float) -> Bool {
  let r = sys.FindRivalById(f.orderTarget);
  if !IsDefined(r) {
    return false;
  }
  if r.state != EnumInt(ECBRivalState.Active) && r.state != EnumInt(ECBRivalState.Hunting) {
    f.ltGone = true;
    f.theirWeary = ClampF(f.theirWeary + 10.0, 0.0, 100.0);
    CBWarResolveOrder(sys, game, f, CBWarOutcomeWon() + 10);
    return true;
  }
  return dist <= CBConfig.LairLeaveDistance();
}

// A friend gang in the war sends a few of its people to the fight (W5), the way an allied gang lends a crew.
func CBWarAllyComes(sys: ref<CyberbaneSystem>, game: GameInstance, ally: CName) -> Void {
  let war = CBWarBook.Get(game);
  let base = CBGangTemplate(sys, ally);
  if !IsDefined(war) || !TDBID.IsValid(base) || ArraySize(war.crewIds) > 0 || CBSpawnRoom(game) < 4 {
    return;
  }
  let body: EntityID;
  let ring = 0;
  let k = 0;
  while k < CBConfig.WarAllyFighters() {
    if CBSpawnOnSide(game, base, n"", n"CB_Ally", CBConfig.CrewSpawnDistance(), body, ring, n"CB_Follower") > 0 {
      ArrayPush(war.crewIds, body);
    }
    k += 1;
  }
  if ArraySize(war.crewIds) > 0 {
    let now = CBGameSeconds(game);
    war.crewGang = ally;
    war.crewUntil = now + 2.0 * CBConfig.SecondsPerHour();
    war.crewAway = 0;
    war.crewLeaving = false;
  }
}

// ---- The squads' own people in the fight -----------------------------------------------------------------------------

// A few of every squad's people come to V's fight: two from a squad on the order's own work (or the fighters and the
// guards when the crew's own streets are hit), one from any other. Followers of V, as a friend gang's lent people are,
// placed only in the room their wave leaves.
public func CBWarSquadsJoin(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>, order: Int32, enemy: CName, enemies: Int32) -> Void {
  let sb = CBSquadBook.Get(game);
  let book = CBCrewBook.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sb) || !IsDefined(book) || !IsDefined(des) || !CBMyCrewOn() {
    return;
  }
  let room = Min(CBConfig.WarSquadFightersMax(), CBSpawnRoom(game) - enemies - CBConfig.WarFightRoomKept());
  let sent = 0;
  let i = 0;
  while i < sb.Count() && sent < room {
    let s = sb.At(i);
    i += 1;
    if IsDefined(s) && s.heads >= 2 {
      let record = CBSquadFighterRecord(sys, game, book, s, enemy);
      let mainWork = order > 0 ? CBSquadOrderWork(s.kind, order) : (s.kind == CBSquadGuns() || s.kind == CBSquadWatch());
      let want = Min(mainWork ? 2 : 1, s.heads);
      let k = 0;
      while k < want && sent < room && TDBID.IsValid(record) {
        let body: EntityID;
        let ring = 0;
        if CBSpawnOnSide(game, record, n"", n"CB_Ally", CBConfig.CrewSpawnDistance(), body, ring, n"CB_Follower") > 0 {
          des.AssignTag(body, n"CB_WarSide");
          ArrayPush(wf.squadIds, body);
          sent += 1;
          k += 1;
        } else {
          k = want;   // nowhere to put them: nobody else from this squad either
        }
      }
    }
  }
  if sent > 0 {
    CBLog.Info(n"War", s"\(sent) of the squads' people came to V's fight.");
  } else {
    CBLog.Info(n"War", s"None of the squads' people came: room for \(room) beside \(enemies) of theirs (\(CBSpawnRoomNote(game))), \(sb.Count()) squads.");
  }
}

// What a squad's people look like: their leader's old gang's people, else their leader's own kind; never the gang being
// fought, so nobody on V's side wears the enemy's colours.
func CBSquadFighterRecord(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBCrewBook>, s: ref<CBSquad>, enemy: CName) -> TweakDBID {
  let m = book.Find(s.leader);
  if IsDefined(m) && IsNameValid(m.faction) && NotEquals(m.faction, enemy) {
    let t = CBGangTemplate(sys, m.faction);
    if TDBID.IsValid(t) {
      return t;
    }
  }
  if IsDefined(m) && TDBID.IsValid(m.record) && CBRecordIsPerson(m.record) && (!IsNameValid(m.faction) || NotEquals(m.faction, enemy)) {
    return m.record;
  }
  // Somebody else on the roster from a gang that is not this one.
  let j = 0;
  while j < book.Count() {
    let o = book.At(j);
    j += 1;
    if IsDefined(o) && IsNameValid(o.faction) && NotEquals(o.faction, enemy) {
      let t2 = CBGangTemplate(sys, o.faction);
      if TDBID.IsValid(t2) {
        return t2;
      }
    }
  }
  return TDBID.None();
}

// The fight is over: the squads' people stop following V and walk off, and are taken out of the world once V can't see
// them (CBDeleteTaggedSafe hands anybody still in view to the orphan sweep). The fallen stay where they fell.
func CBWarSquadsLeave(sys: ref<CyberbaneSystem>, game: GameInstance, wf: ref<CBWarFightBook>) -> Void {
  if ArraySize(wf.squadIds) == 0 {
    return;
  }
  for id in wf.squadIds {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      CBEndFollower(p);
      CBOrderFlee(game, p, true);
    }
  }
  ArrayClear(wf.squadIds);
  CBDeleteTaggedSafe(game, n"CB_WarSide", true, true);
}

// The medics get one of the crew back up once in a war fight (S6): their first fall is a knock-down, not a death.
public func CBWarCuttersSaveOnce(game: GameInstance) -> Bool {
  let wf = CBWarFightBook.Get(game);
  if !IsDefined(wf) || !wf.on || wf.cuttersUsed || !CBSquadKindOn(game, CBSquadCutters()) {
    return false;
  }
  wf.cuttersUsed = true;
  return true;
}

// ---- A rescue (W6) ---------------------------------------------------------------------------------------------------

// V at the place where one of the crew is held, with the rescue on: their guards come, and beating them frees them.
public func CBWarRescueTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let fb = CBWarFrontBook.Get(game);
  let wf = CBWarFightBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(fb) || !IsDefined(wf) || !IsDefined(player) || fb.CaptiveCount() == 0 {
    return;
  }
  let life = CBStreetLifeFor(game);
  if wf.on && wf.rescue > 0 {
    let ev = IsDefined(life) ? life.Events().Live() : null;
    let c = fb.FindCaptive(wf.rescue);
    if !IsDefined(ev) || !Equals(ev.kind, CBEvWarFight()) || !IsDefined(c) {
      CBWarFightOver(sys, game, wf);
      return;
    }
    let up: Int32;
    let byV: Int32;
    CBSideCount(game, ev, 0, up, byV);
    if ev.placed && ArraySize(ev.ids) > 0 && up == 0 {
      let at = ev.at;
      CBWarFightOver(sys, game, wf);
      life.Events().End(game);
      CBWarFreeCaptive(sys, game, c, 3);
      CBWarFightSpoils(sys, game, false, 0, at);
      return;
    }
    if CBVDown(game) || CBWarDistTo(player, ev.at) > CBConfig.WarFightLeave() {
      CBWarFightOver(sys, game, wf);
      life.Events().End(game);
    }
    return;
  }
  if wf.on || !CBWorldStable(game) || sys.GetStoryHold() != CBStoryNone() || player.IsInCombat() || !IsDefined(life) {
    return;
  }
  let i = 0;
  while i < fb.CaptiveCount() {
    let c = fb.CaptiveAt(i);
    i += 1;
    if IsDefined(c) && c.rescue && CBWarSpotKnown(c.Place()) && CBWarDistTo(player, c.Place()) <= CBConfig.WarFightReach() {
      let live = life.Events().Live();
      if IsDefined(live) && (live.placed || !CBEventKindIsOwn(live.kind)) {
        return;
      }
      if IsDefined(live) {
        life.Events().End(game);
      }
      if life.Events().StartWarFight(sys, game, c.gang, c.Place(), CBConfig.WarRescueSize(), 1) {
        wf.Reset();
        wf.gang = c.gang;
        wf.rescue = c.member;
        wf.on = true;
        wf.wave = 1;
        wf.waves = 1;
        wf.at = c.Place();
        if StrLen(CBCrewCallBlocked(sys, game, true)) == 0 {
          CBCrewCall(sys, game, true);
        }
        CBWarSquadsJoin(sys, game, wf, CBWarOrderLieutenant(), c.gang, CBConfig.WarRescueSize());
        CBLog.Info(n"War", s"V came for member \(c.member), held by \(NameToString(c.gang)).");
      }
      return;
    }
  }
}

// Cyberbane - Gang life: events with a time and a place (2.3.3)
//
// A gang does things whether or not V is there: sits down with a rival, buries its dead, celebrates a win, tests a
// recruit, signs up new blood, runs guns, works a racket. Each is an event: a kind, one gang or two, a place near V,
// a time, a window, a pin, the people placed out of V's sight when it starts, and an outcome whether V comes or not.
//
// The sit-down (2.0.0) was the first of these, built on its own in Spawn/LivingStreet.reds. It is the engine's first
// kind now, with no change in how it plays: the same clock and chance, the same two gangs, the same spot, time and
// window, the same words, the same pin, the same rings of people with each gang's best nearest the middle, the same
// crash rule and the same ending. The other kinds are table entries on the same machinery:
//
//   announce   word of what's coming ([32]): the street says what and when, and the place is pinned
//   place      when the time has come and V is on the way in (25 m to MeetSpawnDistance), the people stand on rings
//              round the spot, every one out of V's sight (CBPointHiddenFrom), under the live ceiling (CBSpawnRoom)
//   watch      taken out by V (CBTakenOutByV): all but one of them, and V has crashed it
//   end        the window closes: missed, and the gang has what it came for
//   remove     the pin comes down and the people go the safe way (CBDeleteTaggedSafe)
//
// One event at a time, so two can never stack past the live ceiling. People of every kind but the sit-down are
// tagged CB_Event, one of the street's own (CBStreetTags), so the combat release, the sanctuary hold and the re-arm
// watch reach them, and they are set up as street people. The sit-down keeps CB_Meet.
//
// Session state only: a load drops a planned event, and the world drops its people with it.

public func CBEvSitDown() -> CName = n"SitDown"
public func CBEvFuneral() -> CName = n"Funeral"
public func CBEvCelebration() -> CName = n"Celebration"
public func CBEvInitiation() -> CName = n"Initiation"
public func CBEvRecruitment() -> CName = n"Recruitment"
public func CBEvArmsDeal() -> CName = n"ArmsDeal"
public func CBEvRacket() -> CName = n"Racket"
// The fights between gangs (2.3.4).
public func CBEvExecution() -> CName = n"Execution"
public func CBEvFrontLine() -> CName = n"FrontLine"
public func CBEvFugitive() -> CName = n"Fugitive"

public func CBTalkActRespects() -> Int32 = 34

public func CBGatheringsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().gatherings);
}

public func CBDealsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().dealsAndRackets);
}

public func CBGangFightsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().gangFights);
}

public func CBIsFightKind(kind: CName) -> Bool {
  return Equals(kind, CBEvExecution()) || Equals(kind, CBEvFrontLine()) || Equals(kind, CBEvFugitive());
}

func CBGangLifeOften() -> Float {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? ClampF(rt.GetSettings().gangLifeOften, 0.1, 5.0) : 1.0;
}

public func CBEventKindOn(kind: CName) -> Bool {
  if Equals(kind, CBEvSitDown()) {
    return CBStreetLifeOn(n"sitDowns");
  }
  if Equals(kind, CBEvArmsDeal()) || Equals(kind, CBEvRacket()) {
    return CBDealsOn();
  }
  if CBIsFightKind(kind) {
    return CBGangFightsOn();
  }
  return CBGatheringsOn();
}

public class CBStreetEvent {
  public let kind: CName;
  public let a: CName;
  public let b: CName;
  public let at: Vector4;
  public let from: Float;              // game seconds
  public let until: Float;
  public let pin: NewMappinID;
  public let pinned: Bool;
  public let placed: Bool;
  public let ids: array<EntityID>;
  public let approached: Bool;         // V paid their respects at a funeral
  public let district: CName;
  public let placedTick: Int32;
  public let started: Bool;            // a fight: the two sides set against each other (2.3.4)

  public func Tag() -> CName {
    return Equals(this.kind, CBEvSitDown()) ? n"CB_Meet" : n"CB_Event";
  }

  public func Sides() -> Int32 {
    return Equals(this.kind, CBEvSitDown()) || Equals(this.kind, CBEvArmsDeal()) || CBIsFightKind(this.kind) ? 2 : 1;
  }

  // How many of the second gang stand alone at the start: the prisoner at an execution, the one being hunted.
  public func Lone() -> Int32 {
    return Equals(this.kind, CBEvExecution()) || Equals(this.kind, CBEvFugitive()) ? 1 : 0;
  }

  // Which side the i-th body placed is on: 0 the first gang, 1 the second.
  public func SideOf(i: Int32) -> Int32 {
    if this.Lone() > 0 {
      return i < this.Lone() ? 1 : 0;
    }
    return i % this.Sides();
  }
}

public class CBEventEngine {
  private let m_ev: ref<CBStreetEvent>;
  private let m_meetNext: Int32;       // the sit-down's own clock, as it always had
  private let m_next: Int32;           // everything else's
  // A gang owed a funeral (a Rival or a boss of theirs killed) or a celebration (a district taken), and from when.
  private let m_funeralFor: CName;
  private let m_funeralAt: Float;
  private let m_partyFor: CName;
  private let m_partyAt: Float;

  public func Live() -> ref<CBStreetEvent> {
    return this.m_ev;
  }

  public func OweFuneral(gang: CName, now: Float) -> Void {
    if CBFactionFieldsSquads(gang) {
      this.m_funeralFor = gang;
      this.m_funeralAt = now + CBConfig.FuneralAfterHours() * CBConfig.SecondsPerHour();
    }
  }

  public func OweCelebration(gang: CName, now: Float) -> Void {
    if CBFactionFieldsSquads(gang) {
      this.m_partyFor = gang;
      this.m_partyAt = now + CBConfig.CelebrationAfterHours() * CBConfig.SecondsPerHour();
    }
  }

  public func Tick(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>,
                   busy: Bool) -> Void {
    if IsDefined(this.m_ev) {
      this.Run(sys, game, des, player);
      return;
    }
    let nowT = sys.GetTickCount();
    let now = CBGameSeconds(game);
    // A debt that has waited past its use is forgotten: a funeral is a day after, never a week.
    if NotEquals(this.m_funeralFor, n"") && now > this.m_funeralAt + CBConfig.EventOwedDays() * CBConfig.SecondsPerDay() {
      this.m_funeralFor = n"";
    }
    if NotEquals(this.m_partyFor, n"") && now > this.m_partyAt + CBConfig.EventOwedDays() * CBConfig.SecondsPerDay() {
      this.m_partyFor = n"";
    }
    if busy || player.IsInCombat() {
      return;
    }
    // The sit-down, on its own clock and chance, as before.
    if nowT >= this.m_meetNext && CBStreetLifeOn(n"sitDowns") {
      this.m_meetNext = nowT + CBJitter(CBConfig.MeetGapTicks(), 0.4);
      if RandF() < CBConfig.MeetChance() && this.Start(sys, game, player, CBEvSitDown()) {
        return;
      }
    }
    // Everything else.
    if nowT < this.m_next || !(CBGatheringsOn() || CBDealsOn()) {
      return;
    }
    this.m_next = nowT + CBJitter(RoundF(Cast<Float>(CBConfig.EventGapTicks()) / CBGangLifeOften()), 0.4);
    if RandF() >= CBConfig.EventChance() {
      return;
    }
    let kind = this.Choose(sys, now);
    if IsNameValid(kind) {
      this.Start(sys, game, player, kind);
    }
  }

  // What happens next: a debt first, then whatever the switches allow.
  private func Choose(sys: ref<CyberbaneSystem>, now: Float) -> CName {
    if CBGatheringsOn() && NotEquals(this.m_funeralFor, n"") && now >= this.m_funeralAt {
      return CBEvFuneral();
    }
    if CBGatheringsOn() && NotEquals(this.m_partyFor, n"") && now >= this.m_partyAt {
      return CBEvCelebration();
    }
    let kinds: array<CName>;
    if CBGatheringsOn() {
      ArrayPush(kinds, CBEvInitiation());
      ArrayPush(kinds, CBEvRecruitment());
    }
    if CBDealsOn() {
      ArrayPush(kinds, CBEvArmsDeal());
      ArrayPush(kinds, CBEvRacket());
    }
    // The fights come at a gentler pace than the rest: in the draw half the time.
    // Two gangs V set on each other meet in the street first (Economy/War.reds, [70]).
    let war = CBWarBook.Get(GetGameInstance());
    if CBGangFightsOn() && IsDefined(war) && now < war.InciteUntil() {
      return CBEvFrontLine();
    }
    if CBGangFightsOn() && RandF() < CBConfig.GangFightShare() {
      ArrayPush(kinds, CBEvExecution());
      ArrayPush(kinds, CBEvFrontLine());
      ArrayPush(kinds, CBEvFugitive());
    }
    return ArraySize(kinds) > 0 ? kinds[RandRange(0, ArraySize(kinds))] : n"";
  }

  private func Start(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, kind: CName) -> Bool {
    let district = sys.GetCurrentDistrict();
    let a = n"";
    let b = n"";
    if Equals(kind, CBEvFuneral()) || Equals(kind, CBEvCelebration()) {
      a = Equals(kind, CBEvFuneral()) ? this.m_funeralFor : this.m_partyFor;
      // On their own streets: only where they are, near V.
      if !ArrayContains(CBTurfGangsHere(sys), a) {
        return false;
      }
    } else {
      a = CBTurfHolder(sys, game, district);
    }
    if Equals(a, n"") || !CBFactionFieldsSquads(a) || !CBFactionOn(a) {
      return false;
    }
    if Equals(kind, CBEvSitDown()) || CBIsFightKind(kind) {
      // The pair V set on each other, when the holder here is one of them.
      let war = CBWarBook.Get(game);
      if Equals(kind, CBEvFrontLine()) && IsDefined(war) && CBGameSeconds(game) < war.InciteUntil() {
        if Equals(a, war.InciteA()) { b = war.InciteB(); }
        if Equals(a, war.InciteB()) { b = war.InciteA(); }
      }
      for g in CBGangRivalsOf(sys.GetContent(), a) {
        if Equals(b, n"") && CBFactionFieldsSquads(g) && CBFactionOn(g) && IsDefined(sys.FindFaction(g)) {
          b = g;
        }
      }
      if Equals(b, n"") {
        return false;
      }
      // Two gangs in a truce against V do not fight each other (Economy/War.reds, [36]).
      if CBIsFightKind(kind) && Equals(CBTrucePartner(game, a), b) {
        return false;
      }
    }
    if Equals(kind, CBEvArmsDeal()) {
      b = CBDealPartner(sys, a);
      if Equals(b, n"") {
        return false;
      }
    }
    let spot: Vector4;
    if !CBWhereaboutsSpot(sys, game, player, spot) {
      return false;
    }
    let now = CBGameSeconds(game);
    let ev = new CBStreetEvent();
    ev.kind = kind;
    ev.a = a;
    ev.b = b;
    ev.at = spot;
    ev.district = district;
    if Equals(kind, CBEvSitDown()) {
      ev.from = now + RandRangeF(1.0, 2.0) * 3600.0;
      ev.until = ev.from + CBConfig.MeetWindowSeconds();
    } else {
      ev.from = now + RandRangeF(CBConfig.EventLeadMinHours(), CBConfig.EventLeadMaxHours()) * 3600.0;
      ev.until = ev.from + CBConfig.EventWindowSeconds();
    }
    this.m_ev = ev;
    if Equals(kind, CBEvFuneral()) {
      this.m_funeralFor = n"";
    }
    if Equals(kind, CBEvCelebration()) {
      this.m_partyFor = n"";
    }
    this.KeepPin(game);
    if CBMessagesOn() {
      CBHearsayFromDistrict(game, district, CBEventWordLine(ev), n"");
    }
    CBLog.Info(n"Street", s"A \(NameToString(kind)) is set: \(NameToString(a)) \(NameToString(b)).");
    return true;
  }

  private func Run(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>) -> Void {
    let ev = this.m_ev;
    let now = CBGameSeconds(game);
    this.KeepPin(game);
    let dist = Vector4.Distance(player.GetWorldPosition(), ev.at);
    // Their time has come and V is on the way in, not yet looking: put them there.
    if !ev.placed && now >= ev.from && dist <= CBConfig.MeetSpawnDistance() && dist >= 25.0 {
      ev.placed = this.Place(sys, game, des, player, ev);
      ev.placedTick = sys.GetTickCount();
    }
    // A fight: once its people are in the world, the sides are set against each other, and it ends its own way.
    if ev.placed && CBIsFightKind(ev.kind) {
      if !ev.started && sys.GetTickCount() - ev.placedTick >= CBEventStartTicks(ev.kind) {
        ev.started = true;
        CBStartFight(sys, game, player, ev);
      }
      if ev.started && CBFightOver(sys, game, ev) {
        this.End(game);
        return;
      }
    }
    if ev.placed && !CBIsFightKind(ev.kind) {
      let down = 0;
      for id in ev.ids {
        if CBTakenOutByV(GameInstance.FindEntityByID(game, id) as ScriptedPuppet) {
          down += 1;
        }
      }
      if down >= Max(2, ArraySize(ev.ids) - 1) {
        CBEventCrashed(sys, game, ev);
        this.End(game);
        return;
      }
    }
    if now >= ev.until || !CBEventKindOn(ev.kind) {
      if CBEventKindOn(ev.kind) {
        CBEventMissed(sys, game, ev);
      }
      this.End(game);
    }
  }

  // The pin on the place, in step with the map markers setting (as the sit-down's always was).
  private func KeepPin(game: GameInstance) -> Void {
    let ev = this.m_ev;
    if !IsDefined(ev) {
      return;
    }
    let want = CBMapMarkersOn();
    if Equals(want, ev.pinned) {
      return;
    }
    let ms = GameInstance.GetMappinSystem(game);
    if !IsDefined(ms) {
      return;
    }
    if !want {
      ms.UnregisterMappin(ev.pin);
      ev.pinned = false;
      return;
    }
    let data: MappinData;
    data.mappinType = t"Mappins.DefaultStaticMappin";
    data.variant = gamedataMappinVariant.ApartmentVariant;
    data.active = true;
    data.visibleThroughWalls = true;
    data.debugCaption = CBRivalPinCaption(CBEventCaption(ev));
    ev.pin = ms.RegisterMappin(data, ev.at);
    ev.pinned = true;
  }

  // Each side's people, out of V's sight round the place, on rings: the first holds eight, a bigger gathering
  // stands further out. Short of room under the live ceiling, as many as fit, shared evenly between the sides, and
  // never fewer than two in all. Each side's first few are its best (one per apex chair, where the kind has them),
  // nearest the middle with their people round them, facing the middle the way people meeting stand.
  private func Place(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>,
                     ev: ref<CBStreetEvent>) -> Bool {
    let sides = ev.Sides();
    let lone = ev.Lone();
    let fa = sys.FindFaction(ev.a);
    let fb = sides == 2 ? sys.FindFaction(ev.b) : fa;
    let perSide = CBEventPerSide(ev.kind);
    let full = lone > 0 ? lone + perSide : sides * perSide;
    let want = Min(full, CBSpawnRoom(game));
    if lone == 0 {
      want -= want % sides;
    }
    if !IsDefined(fa) || !IsDefined(fb) || !TDBID.IsValid(fa.sampleRecord) || !TDBID.IsValid(fb.sampleRecord) || want < 2 {
      return false;
    }
    let apexPerSide = CBEventApexPerSide(ev.kind);
    let ppos = player.GetWorldPosition();
    let fwd = player.GetWorldForward();
    let tag = ev.Tag();
    let ring = 0;
    while ring < 3 && ArraySize(ev.ids) < want {
      let radius = 2.2 + Cast<Float>(ring) * 1.6;
      let slots = 8 + ring * 4;
      // Each ring turned half a step against the one inside it, so nobody stands right behind somebody.
      let turn = Cast<Float>(ring) * 3.14159 / Cast<Float>(slots);
      let k = 0;
      while k < slots && ArraySize(ev.ids) < want {
        let ang = turn + Cast<Float>(k) * 6.28318 / Cast<Float>(slots);
        k += 1;
        let snapped: Vector4;
        let at: Vector4;
        if CBNavSnap(game, ev.at.X + CosF(ang) * radius, ev.at.Y + SinF(ang) * radius, ev.at.Z, snapped)
           && CBSettleOnGround(game, snapped, at) && CBPointHiddenFrom(game, ppos, fwd, at) {
          let facing = Quaternion.BuildFromDirectionVector(new Vector4(-CosF(ang), -SinF(ang), 0.0, 0.0));
          let n = ArraySize(ev.ids);
          let side = ev.SideOf(n) == 0 ? fa : fb;
          let chair = lone > 0 ? (n < lone ? apexPerSide : n - lone) : n / sides;
          let rec = side.sampleRecord;
          let role = n"";
          if chair < apexPerSide {
            let best = CBApexRosterRecord(side.id, chair);
            if TDBID.IsValid(best) {
              rec = best;
              role = CBApexRoleTag(chair);
            }
          }
          let id: EntityID;
          if CBCreateSpawn(des, rec, n"", at, facing, tag, id, role) {
            ArrayPush(ev.ids, id);
          }
        }
      }
      ring += 1;
    }
    let placed = ArraySize(ev.ids);
    // Said once, when it is in place: a try that placed nobody is tried again next tick.
    if placed >= 2 && placed < full {
      CBLog.Info(n"Street", s"A \(NameToString(ev.kind)) placed \(placed) of \(full) people.");
    }
    return placed >= Max(2, lone + 1);
  }

  public func End(game: GameInstance) -> Void {
    let ev = this.m_ev;
    if !IsDefined(ev) {
      return;
    }
    if ev.pinned {
      let ms = GameInstance.GetMappinSystem(game);
      if IsDefined(ms) {
        ms.UnregisterMappin(ev.pin);
      }
      ev.pinned = false;
    }
    let tag = ev.Tag();
    this.m_ev = null;
    CBDeleteTaggedSafe(game, tag, true, true);
  }

  // Start over: whatever was planned belonged to the old playthrough.
  public func Reset(game: GameInstance) -> Void {
    this.End(game);
    this.m_funeralFor = n"";
    this.m_partyFor = n"";
  }
}

// ---- The table ---------------------------------------------------------------------------------------

public func CBEventPerSide(kind: CName) -> Int32 {
  if Equals(kind, CBEvSitDown()) { return CBSitDownPerGang(); }
  if Equals(kind, CBEvFuneral()) { return 6; }
  if Equals(kind, CBEvCelebration()) { return 6; }
  if Equals(kind, CBEvInitiation()) { return 4; }
  if Equals(kind, CBEvRecruitment()) { return 5; }
  if Equals(kind, CBEvArmsDeal()) { return 3; }
  if Equals(kind, CBEvExecution()) { return 3; }   // the executioner and two guards, round the prisoner
  if Equals(kind, CBEvFrontLine()) { return 4; }
  if Equals(kind, CBEvFugitive()) { return 3; }    // the hunters, behind the one they hunt
  return 4;   // a racket
}

public func CBEventApexPerSide(kind: CName) -> Int32 {
  if Equals(kind, CBEvSitDown()) { return CBSitDownApexPerGang(); }
  if Equals(kind, CBEvArmsDeal()) { return 1; }   // somebody to guard the goods
  if Equals(kind, CBEvExecution()) { return 1; }  // the one who does it
  return 0;
}

// Somebody to buy guns from this gang: a gang it is not at war with.
func CBDealPartner(sys: ref<CyberbaneSystem>, a: CName) -> CName {
  let content = sys.GetContent();
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && NotEquals(fs.id, a) && CBFactionFieldsSquads(fs.id) && CBFactionOn(fs.id)
       && !CBIsCorpFaction(fs.id) && TDBID.IsValid(fs.sampleRecord)
       && !CBGangsAreRivals(content, a, fs.id) && !CBGangsAreRivals(content, fs.id, a) {
      return fs.id;
    }
  }
  return n"";
}

public func CBEventCaption(ev: ref<CBStreetEvent>) -> String {
  let a = CBCapFirst(CBFactionLabel(ev.a));
  if Equals(ev.kind, CBEvSitDown()) { return a + " and " + CBFactionLabel(ev.b); }
  if Equals(ev.kind, CBEvFuneral()) { return a + ": a funeral"; }
  if Equals(ev.kind, CBEvCelebration()) { return a + " celebrating"; }
  if Equals(ev.kind, CBEvInitiation()) { return a + ": an initiation"; }
  if Equals(ev.kind, CBEvRecruitment()) { return a + " recruiting"; }
  if Equals(ev.kind, CBEvArmsDeal()) { return a + " and " + CBFactionLabel(ev.b) + ": guns"; }
  if Equals(ev.kind, CBEvExecution()) { return a + ": an execution"; }
  if Equals(ev.kind, CBEvFrontLine()) { return a + " against " + CBFactionLabel(ev.b); }
  if Equals(ev.kind, CBEvFugitive()) { return a + ": a hunt"; }
  return a + ": a racket";
}

// Word of what's coming ([32]): what, who, and when.
public func CBEventWordLine(ev: ref<CBStreetEvent>) -> String {
  let a = CBCapFirst(CBFactionLabel(ev.a));
  let when = CBClockWord(ev.from);
  if Equals(ev.kind, CBEvSitDown()) {
    return s"\(a) and \(CBFactionLabel(ev.b)) are sitting down near here around \(when). Crash it, and they both feel it.";
  }
  if Equals(ev.kind, CBEvFuneral()) {
    return CBLineOf([s"\(a) are burying one of theirs near here around \(when). The one you put down.",
                     s"Funeral for one of \(CBFactionLabel(ev.a)) near here, \(when). Go pay your respects. Or don't."]);
  }
  if Equals(ev.kind, CBEvCelebration()) {
    return CBLineOf([s"\(a) are celebrating near here around \(when). They took some streets and they want everybody to know.",
                     s"Party near here, \(when). \(a) are drinking to a win."]);
  }
  if Equals(ev.kind, CBEvInitiation()) {
    return CBLineOf([s"\(a) are blooding new recruits near here around \(when). Somebody's going to get hurt.",
                     s"Initiation near here, \(when). \(a) want their new kids to prove something."]);
  }
  if Equals(ev.kind, CBEvRecruitment()) {
    return CBLineOf([s"\(a) are signing up new blood near here around \(when). More of them on these streets after.",
                     s"Recruiting drive near here, \(when). \(a) want bodies."]);
  }
  if Equals(ev.kind, CBEvArmsDeal()) {
    return CBLineOf([s"\(a) are buying guns from \(CBFactionLabel(ev.b)) near here around \(when). Crash it and the crate is yours.",
                     s"Arms deal near here, \(when): \(a) and \(CBFactionLabel(ev.b)). Heavy crates, light guard."]);
  }
  if Equals(ev.kind, CBEvExecution()) {
    return CBLineOf([s"\(a) caught one of \(CBFactionLabel(ev.b)) and they're putting a bullet in him near here around \(when). Stop it, or don't.",
                     s"Execution near here, \(when). \(a) want everybody to watch one of \(CBFactionLabel(ev.b)) die."]);
  }
  if Equals(ev.kind, CBEvFrontLine()) {
    return CBLineOf([s"\(a) and \(CBFactionLabel(ev.b)) are going to war on a street near here around \(when). Whoever wins takes ground.",
                     s"Street fight near here, \(when): \(a) against \(CBFactionLabel(ev.b)). Pick a side, or keep your head down."]);
  }
  if Equals(ev.kind, CBEvFugitive()) {
    return CBLineOf([s"\(a) are hunting somebody of \(CBFactionLabel(ev.b)) who crossed them. He'll be running past here around \(when).",
                     s"Somebody's running from \(a) near here, \(when). Help him or let them have him."]);
  }
  return CBLineOf([s"Word is \(a) run a racket near here, collecting around \(when). Hit it and take the cash.",
                   s"\(a) collect their take near here around \(when). Nobody's ever robbed them. Yet."]);
}

// A line for an overheard conversation while an event is coming and V is in its district ([32]).
public func CBEventWhisper(game: GameInstance) -> String {
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(ev) || ev.placed || !IsDefined(sys) || NotEquals(ev.district, sys.GetCurrentDistrict()) {
    return "";
  }
  let a = CBFactionLabel(ev.a);
  if Equals(ev.kind, CBEvFuneral()) { return "You hear " + a + " are burying one of theirs tonight? Somebody should send flowers."; }
  if Equals(ev.kind, CBEvCelebration()) { return "Stay off that block later. " + CBCapFirst(a) + " are partying, and they get loud."; }
  if Equals(ev.kind, CBEvInitiation()) { return "Some kid's getting jumped into " + a + " tonight. Poor bastard. Or poor whoever."; }
  if Equals(ev.kind, CBEvRecruitment()) { return CBCapFirst(a) + " are looking for new blood. My cousin's thinking about it."; }
  if Equals(ev.kind, CBEvArmsDeal()) { return "Crates came in off a truck for " + a + ". Guns, people say."; }
  if Equals(ev.kind, CBEvRacket()) { return "Don't go near " + CBPossessive(a) + " collection spot later. They count the take there."; }
  if Equals(ev.kind, CBEvExecution()) { return CBCapFirst(a) + " are executing somebody tonight. In the open. To make a point."; }
  if Equals(ev.kind, CBEvFrontLine()) { return "Stay home later. " + CBCapFirst(a) + " and " + CBFactionLabel(ev.b) + " are going to settle it in the street."; }
  if Equals(ev.kind, CBEvFugitive()) { return "Some guy crossed " + a + ". They're going to run him down tonight."; }
  return "Heard " + a + " and " + CBFactionLabel(ev.b) + " are meeting. Could go either way.";
}

// ---- Outcomes ------------------------------------------------------------------------------------------

// V broke it up.
public func CBEventCrashed(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  CBWarEventCrashed(sys, game, ev);   // a favour asked for peace (Economy/War.reds, 2.4.0)
  let now = CBGameSeconds(game);
  let where = CBEventDistrict(sys, game);
  let a = CBFactionLabel(ev.a);
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  if Equals(ev.kind, CBEvSitDown()) {
    CBWeakenGang(sys, game, ev.a, CBConfig.MeetGangLoss());
    CBWeakenGang(sys, game, ev.b, CBConfig.MeetGangLoss());
    CBTalkFear(sys, game, ev.a, CBConfig.WordKeptFear());
    CBTalkFear(sys, game, ev.b, CBConfig.WordKeptFear());
    sys.AddRenownPoints(CBConfig.MeetRenown() * mult);
    CBFileLog(sys, n"MeetCrashed", now, where, ev.a, 0.0);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"You crashed the sit-down between \(a) and \(CBFactionLabel(ev.b)). Neither of them will forget it.", n"");
    }
    CBLog.Info(n"Street", "V crashed a sit-down.");
    return;
  }
  CBWeakenGang(sys, game, ev.a, CBConfig.MeetGangLoss());
  CBTalkFear(sys, game, ev.a, CBConfig.WordKeptFear());
  sys.AddRenownPoints(CBConfig.EventRenown() * mult);
  if Equals(ev.kind, CBEvFuneral()) {
    // Never forgiven, and by some never twice over (the Valentinos, Data/GangCodes.reds).
    if !CBReputationFrozen() {
      let fs = sys.EnsureFaction(ev.a);
      fs.standing = ClampF(fs.standing - CBConfig.FuneralCrashStanding() * CBCodeShotHands(ev.a), -100.0, 100.0);
    }
    sys.AddCode(-CBConfig.FuneralCrashCode());
    CBFileLog(sys, n"FuneralCrashed", now, where, ev.a, 0.0);
    CBEventSay(game, CBLineOf([s"You shot up a funeral. \(CBCapFirst(a)) will never forgive that. Nobody will forget it.",
                               s"You hit \(CBPossessive(a)) funeral. Even people who hate them think that was low."]));
    return;
  }
  if Equals(ev.kind, CBEvArmsDeal()) {
    CBWeakenGang(sys, game, ev.b, CBConfig.MeetGangLoss() * 0.5);
    CBWarSpend(game, ev.a, CBConfig.WarDealValue());
    let crate = ArraySize(ev.ids) > 0 ? GameInstance.FindEntityByID(game, ev.ids[0]) as ScriptedPuppet : null;
    if IsDefined(crate) {
      CBScheduleLoot(sys, game, crate, CBLootTierApex(), CBConfig.LootIconicChanceApex());
    }
    CBFileLog(sys, n"DealCrashed", now, where, ev.a, 0.0);
    CBEventSay(game, s"You took the guns \(a) were buying. The crate's yours, and so is their grudge.");
    return;
  }
  if Equals(ev.kind, CBEvRacket()) {
    let take = CBConfig.RacketTakeBase() + RandRange(0, CBConfig.RacketTakeBase() + 1);
    CBStreetGiveMoney(game, take);
    CBWarSpend(game, ev.a, Cast<Float>(take) * CBConfig.BagmanChestShare());
    CBTalkSlight(sys, game, ev.a, CBConfig.BagmanStandingLoss());
    CBFileLog(sys, n"RacketHit", now, where, ev.a, Cast<Float>(take));
    CBSystemNote(game, s"you took their take: \(take)eb.", 5.0);
    CBEventSay(game, s"You hit \(CBPossessive(a)) racket. Word is they're counting what's left.");
    return;
  }
  if Equals(ev.kind, CBEvInitiation()) {
    sys.AddCode(CBConfig.InitiationStopCode());
  }
  CBFileLog(sys, n"EventCrashed", now, where, ev.a, 0.0);
  CBEventSay(game, CBLineOf([s"You broke up \(CBPossessive(a)) \(CBEventNoun(ev.kind)). They felt that.",
                             s"Whatever \(a) had planned near there, you ended it."]));
}

// The window closed without V: the gang had what it came for.
public func CBEventMissed(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  let a = CBFactionLabel(ev.a);
  if CBIsFightKind(ev.kind) {
    if ev.placed {
      CBEventSay(game, s"Whatever \(a) started near there, it fizzled out. Nobody won.");
    }
    return;
  }
  if Equals(ev.kind, CBEvSitDown()) {
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"\(CBCapFirst(a)) and \(CBFactionLabel(ev.b)) made their deal. Nobody stopped them.", n"");
    }
    return;
  }
  if Equals(ev.kind, CBEvFuneral()) {
    if !ev.approached {
      CBEventSay(game, s"\(CBCapFirst(a)) buried their dead. They said your name at the grave.");
    }
    return;
  }
  CBBolsterGang(sys, game, ev.a, CBEventBolster(ev.kind));
  if Equals(ev.kind, CBEvArmsDeal()) {
    CBBolsterGang(sys, game, ev.b, CBEventBolster(ev.kind) * 0.5);
    CBWarEarn(game, ev.b, CBConfig.WarDealValue());
  }
  if Equals(ev.kind, CBEvRacket()) {
    CBWarEarn(game, ev.a, Cast<Float>(CBConfig.RacketTakeBase()) * 3.0);
  }
  CBEventSay(game, CBLineOf([s"\(CBCapFirst(a)) got their \(CBEventNoun(ev.kind)) done. They're stronger for it.",
                             s"Nobody stopped \(CBPossessive(a)) \(CBEventNoun(ev.kind)). There are more of them on the street now."]));
}

func CBEventNoun(kind: CName) -> String {
  if Equals(kind, CBEvCelebration()) { return "party"; }
  if Equals(kind, CBEvInitiation()) { return "initiation"; }
  if Equals(kind, CBEvRecruitment()) { return "recruiting"; }
  if Equals(kind, CBEvArmsDeal()) { return "deal"; }
  if Equals(kind, CBEvRacket()) { return "collection"; }
  return "business";
}

func CBEventBolster(kind: CName) -> Float {
  if Equals(kind, CBEvRecruitment()) { return CBConfig.RecruitBolster(); }
  if Equals(kind, CBEvCelebration()) { return CBConfig.CelebrationBolster(); }
  return CBConfig.EventBolster();
}

func CBEventSay(game: GameInstance, line: String) -> Void {
  if CBMessagesOn() && StrLen(line) > 0 {
    CBHearsayFromStreet(game, line, n"");
  }
}

// A gang's strength, up: the other side of CBWeakenGang (Model/Territory.reds), through the same record of it.
public func CBBolsterGang(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") || amount <= 0.0 || !CBTurfWarsOn() || !CBGangHoldsTurf(sys, faction) {
    return;
  }
  let svc = sys.GetPlayService();
  let pid = sys.GetPlaythroughId();
  if !IsDefined(svc) || !IsNameValid(pid) {
    return;
  }
  svc.NoteGangPower(pid, faction, MinF(100.0, CBGangStrength(sys, faction) + amount), CBGameSeconds(game));
}

// ---- Talk: paying respects at a funeral ---------------------------------------------------------------

public func CBEventTalkLines(game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(ev) || !ev.placed || ev.approached || !Equals(ev.kind, CBEvFuneral()) || !IsDefined(t.npc) || !IsDefined(des)
     || !des.IsTagged(t.npc.GetEntityID(), n"CB_Event") {
    return out;
  }
  let l = CBTalkMakeLine("[Respects] I'm sorry for your loss.", CBTalkActRespects(), t"ChoiceCaptionParts.HandshakeIcon");
  l.important = true;
  ArrayPush(out, l);
  return out;
}

public func CBEventTalkAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  if !IsDefined(ev) || ev.approached {
    return CBTalkSay("You already said your piece.", n"");
  }
  ev.approached = true;
  CBCreditMercy(sys, ev.a, CBConfig.RespectsStanding());
  sys.AddCode(CBConfig.RespectsCode());
  CBFileLog(sys, n"PaidRespects", CBGameSeconds(game), CBEventDistrict(sys, game), ev.a, 0.0);
  return CBTalkSay(CBLineOf(["You've got some nerve. But you came. That counts for something.",
                             "He'd have spat at you. I won't. Not today.",
                             "Coming here took guts. Say what you came to say and go."]), n"");
}

// A gang owes a funeral (a Rival of theirs slain, or a boss) or a celebration (a district taken). From the death
// handler and the turf book's change of hands.
public func CBOweFuneral(game: GameInstance, gang: CName) -> Void {
  let life = CBStreetLifeFor(game);
  if IsDefined(life) && CBGatheringsOn() {
    life.Events().OweFuneral(gang, CBGameSeconds(game));
  }
}

public func CBOweCelebration(game: GameInstance, gang: CName) -> Void {
  let life = CBStreetLifeFor(game);
  if IsDefined(life) && CBGatheringsOn() {
    life.Events().OweCelebration(gang, CBGameSeconds(game));
  }
}

// ---- The fights between gangs (2.3.4) ------------------------------------------------------------------
//
// Two groups of people set against each other, the way V's companions and Cyberbane's crews already are (pairwise
// attitudes through each one's attitude agent, behind the NPC gate): an execution (the executioner and guards
// turn on their prisoner a moment after they are placed), a front line (two gangs' people, at once), a hunt (the
// hunters turn on the one they are hunting, who runs past V). V can step in or leave them to it; each ends its own
// way. Nothing is changed towards V by any of it.

public func CBEventStartTicks(kind: CName) -> Int32 {
  if Equals(kind, CBEvExecution()) { return CBConfig.ExecutionDelayTicks(); }
  return 3;
}

public func CBStartFight(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, ev: ref<CBStreetEvent>) -> Void {
  let i = 0;
  while i < ArraySize(ev.ids) {
    let pa = GameInstance.FindEntityByID(game, ev.ids[i]) as ScriptedPuppet;
    let j = i + 1;
    while j < ArraySize(ev.ids) {
      if ev.SideOf(i) != ev.SideOf(j) {
        CBSetPairHostile(sys, pa, GameInstance.FindEntityByID(game, ev.ids[j]) as ScriptedPuppet);
      }
      j += 1;
    }
    i += 1;
  }
  // The one being hunted runs, past V: one order (CBIssueMove), and the hunters follow by themselves.
  if Equals(ev.kind, CBEvFugitive()) && ArraySize(ev.ids) > 0 {
    let f = GameInstance.FindEntityByID(game, ev.ids[0]) as ScriptedPuppet;
    let ppos = player.GetWorldPosition();
    let dx = ppos.X - ev.at.X;
    let dy = ppos.Y - ev.at.Y;
    let d = MaxF(SqrtF(dx * dx + dy * dy), 1.0);
    let past: Vector4;
    if IsDefined(f) && CBNpcSafe(sys, f)
       && CBNavSnap(game, ppos.X + dx / d * CBConfig.FugitiveRunPast(), ppos.Y + dy / d * CBConfig.FugitiveRunPast(), ppos.Z, past) {
      CBEventRunTo(f, past);
    }
  }
  CBLog.Info(n"Street", s"A \(NameToString(ev.kind)) has started.");
}

func CBSetPairHostile(sys: ref<CyberbaneSystem>, a: ref<ScriptedPuppet>, b: ref<ScriptedPuppet>) -> Void {
  if !CBNpcSafe(sys, a) || !CBNpcSafe(sys, b) || !CBStillStanding(a) || !CBStillStanding(b) {
    return;
  }
  let aa = a.GetAttitudeAgent();
  let ba = b.GetAttitudeAgent();
  if IsDefined(aa) && IsDefined(ba) {
    CBTrace("attitude: two gangs' people set against each other");
    aa.SetAttitudeTowards(ba, EAIAttitude.AIA_Hostile);
    ba.SetAttitudeTowards(aa, EAIAttitude.AIA_Hostile);
  }
}

func CBEventRunTo(p: ref<ScriptedPuppet>, to: Vector4) -> Void {
  let ai = p.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  let cmd = new AIMoveToCommand();
  let dest: AIPositionSpec;
  let wp: WorldPosition;
  WorldPosition.SetVector4(wp, to);
  AIPositionSpec.SetWorldPosition(dest, wp);
  cmd.movementTarget = dest;
  cmd.movementType = moveMovementType.Sprint;
  cmd.ignoreInCombat = false;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 2.0;
  CBIssueMove(p, ai, cmd);
}

// How a side stands: how many are still up, and how many V took out.
func CBSideCount(game: GameInstance, ev: ref<CBStreetEvent>, side: Int32, out standing: Int32, out byV: Int32) -> Void {
  standing = 0;
  byV = 0;
  let i = 0;
  while i < ArraySize(ev.ids) {
    if ev.SideOf(i) == side {
      let p = GameInstance.FindEntityByID(game, ev.ids[i]) as ScriptedPuppet;
      if CBStillStanding(p) && !p.cbMoraleBroken && !p.cbSurrendered {
        standing += 1;
      }
      if CBTakenOutByV(p) {
        byV += 1;
      }
    }
    i += 1;
  }
}

// True when the fight has ended, its outcome said.
public func CBFightOver(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Bool {
  let aUp: Int32;
  let aByV: Int32;
  let bUp: Int32;
  let bByV: Int32;
  CBSideCount(game, ev, 0, aUp, aByV);
  CBSideCount(game, ev, 1, bUp, bByV);
  let now = CBGameSeconds(game);
  let where = CBEventDistrict(sys, game);
  let a = CBFactionLabel(ev.a);
  let b = CBFactionLabel(ev.b);
  let lone = ArraySize(ev.ids) > 0 ? GameInstance.FindEntityByID(game, ev.ids[0]) as ScriptedPuppet : null;
  if Equals(ev.kind, CBEvExecution()) || Equals(ev.kind, CBEvFugitive()) {
    let hunt = Equals(ev.kind, CBEvFugitive());
    // The one alone is up while standing at all: running in fear is what the hunted and the condemned do.
    if !IsDefined(lone) || !CBStillStanding(lone) {
      if CBTakenOutByV(lone) {
        CBEventSay(game, hunt ? s"You put down the one \(a) were hunting. They'll thank you, in their way." : s"You did \(CBPossessive(a)) killing for them.");
        return true;
      }
      CBBolsterGang(sys, game, ev.a, CBConfig.EventBolster());
      CBTalkFear(sys, game, ev.b, CBConfig.WordKeptFear());
      CBFileLog(sys, hunt ? n"FugitiveCaught" : n"Executed", now, where, ev.a, 0.0);
      CBEventSay(game, hunt ? s"\(CBCapFirst(a)) ran down the one they were after." : s"\(CBCapFirst(a)) executed one of \(b). Everybody saw.");
      return true;
    }
    if aUp == 0 && aByV > 0 {
      CBCreditMercy(sys, ev.b, CBConfig.SavedStanding());
      CBWeakenGang(sys, game, ev.a, CBConfig.MeetGangLoss());
      sys.AddCode(CBConfig.SavedCode());
      if IsDefined(lone) && CBStillStanding(lone) {
        CBOrderFlee(game, lone);
        CBEventLoneThanks(game, ev);
      }
      CBFileLog(sys, hunt ? n"FugitiveSheltered" : n"PrisonerSaved", now, where, ev.b, 0.0);
      CBEventSay(game, hunt ? s"You stood between \(a) and the one they were hunting. \(CBCapFirst(b)) heard." : s"You stopped \(CBPossessive(a)) execution. \(CBCapFirst(b)) won't forget it.");
      return true;
    }
    if aUp == 0 {
      // Their own fight, won by the one they meant to kill: nothing of V's in it.
      CBEventSay(game, hunt ? s"The one \(a) were hunting fought them off." : s"\(CBPossessive(CBCapFirst(a))) prisoner turned the tables on them.");
      return true;
    }
    if hunt && IsDefined(lone) && CBStillStanding(lone) && Vector4.Distance(lone.GetWorldPosition(), ev.at) > CBConfig.FugitiveEscapeDistance() {
      CBEventSay(game, s"The one \(a) were hunting got away. Not your doing.");
      return true;
    }
    return false;
  }
  // A front line: whichever side is left standing takes the street.
  if aUp == 0 || bUp == 0 {
    let winner = aUp > 0 ? ev.a : ev.b;
    let loser = aUp > 0 ? ev.b : ev.a;
    CBBolsterGang(sys, game, winner, CBConfig.FrontLineGain());
    CBWeakenGang(sys, game, loser, CBConfig.FrontLineLoss());
    CBFileLog(sys, n"FrontLine", now, where, winner, 0.0);
    CBEventSay(game, s"\(CBCapFirst(CBFactionLabel(winner))) won the street fight against \(CBFactionLabel(loser)). The ground is theirs.");
    return true;
  }
  return false;
}

// The one V saved says so, in a subtitle.
func CBEventLoneThanks(game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  if !CBMessagesOn() {
    return;
  }
  CBOverheard(game, CBWhisperSpeaker(ev.b), CBLineOf(["I owe you. I owe you my life, merc.",
                                                      "Don't know why you did that. Thanks.",
                                                      "I won't forget this. My people won't either."]));
}

// ---- Power struggles ([31]) -----------------------------------------------------------------------------
//
// When a gang's leader falls and the one who takes the chair has a lieutenant who wants it too, both text V for
// help. V backs one by putting the other down: the one V backed takes the chair for good and the gang thinks well of
// V. Kill both, and the gang tears itself apart. Nobody backed within two in-game days, and it settles itself. Kept
// in a book of its own (CBGangLifeBook), because it outlasts a session.

public func CBPowerStrugglesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().powerStruggles);
}

public class CBGangLifeBook extends ScriptableSystem {
  private persistent let m_gang: CName;
  private persistent let m_heir: Int32;
  private persistent let m_rival: Int32;
  private persistent let m_until: Float;
  private persistent let m_winner: Int32;      // after V backed one: who won, until m_until

  public static func Get(game: GameInstance) -> ref<CBGangLifeBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBGangLifeBook") as CBGangLifeBook;
  }

  public func Gang() -> CName { return this.m_gang; }
  public func Heir() -> Int32 { return this.m_heir; }
  public func Rival() -> Int32 { return this.m_rival; }
  public func Until() -> Float { return this.m_until; }
  public func Winner() -> Int32 { return this.m_winner; }

  public func Begin(gang: CName, heir: Int32, rival: Int32, until: Float) -> Void {
    this.m_gang = gang;
    this.m_heir = heir;
    this.m_rival = rival;
    this.m_until = until;
    this.m_winner = 0;
  }

  public func Won(winner: Int32) -> Void {
    this.m_winner = winner;
  }

  public func Clear() -> Void {
    this.m_gang = n"";
    this.m_heir = 0;
    this.m_rival = 0;
    this.m_until = 0.0;
    this.m_winner = 0;
  }
}

// From the hierarchy, after a Rival's slot is freed and filled again (CBHierarchyOnSlain).
public func CBPowerStruggleOnSlain(sys: ref<CyberbaneSystem>, game: GameInstance, slain: ref<CBRival>, wasLeader: Bool) -> Void {
  let book = CBGangLifeBook.Get(game);
  if !IsDefined(sys) || !IsDefined(slain) || !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  let content = CBContent(game);
  let fs = sys.FindFaction(slain.faction);
  // One under way for this gang: who just fell decides it, if V put them down. Somebody else's doing settles it
  // without V.
  if Equals(book.Gang(), slain.faction) && IsDefined(fs) {
    if now > book.Until() {
      book.Clear();
    } else {
      if !sys.RivalDeathByV() && (slain.id == book.Heir() || slain.id == book.Rival() || slain.id == book.Winner()) {
        book.Clear();
        return;
      }
      if book.Winner() > 0 {
        // V backed one, then put the winner down too: the gang tears itself apart.
        if slain.id == book.Winner() {
          CBWeakenGang(sys, game, slain.faction, CBConfig.StruggleBothLoss());
          if !CBReputationFrozen() {
            fs.standing = ClampF(fs.standing - CBConfig.StruggleBackStanding(), -100.0, 100.0);
          }
          CBFileLog(sys, n"StruggleBoth", now, CBEventDistrict(sys, game), slain.faction, 0.0);
          CBEventSay(game, s"You put down both of them. \(CBCapFirst(CBFactionLabel(slain.faction))) are tearing themselves apart.");
          book.Clear();
        }
        return;
      }
      let winner = slain.id == book.Rival() ? book.Heir() : (slain.id == book.Heir() ? book.Rival() : 0);
      let w = winner > 0 ? sys.FindRivalById(winner) : null;
      if IsDefined(w) && CBRivalStillAround(w) {
        // The one V backed takes the chair.
        if fs.leaderRivalId != w.id {
          if fs.lt1RivalId == w.id { fs.lt1RivalId = 0; }
          if fs.lt2RivalId == w.id { fs.lt2RivalId = 0; }
          if fs.lt3RivalId == w.id { fs.lt3RivalId = 0; }
          fs.leaderRivalId = w.id;
          w.rank = Max(w.rank, CBConfig.LeaderMinRank());
        }
        if !CBReputationFrozen() {
          fs.standing = ClampF(fs.standing + CBConfig.StruggleBackStanding(), -100.0, 100.0);
        }
        book.Won(w.id);
        CBFileLog(sys, n"StruggleBacked", now, CBEventDistrict(sys, game), slain.faction, 0.0);
        if CBMessagesOn() {
          CBPhoneSendTinted(game, CBRivalDisplayName(content, w), "The chair's mine. You made that happen. " + CBCapFirst(CBFactionLabel(slain.faction)) + " won't forget it, and neither will I.", CBHudCyan());
        }
      }
      return;
    }
  }
  // A new one: the leader fell, an heir took the chair, and a lieutenant wants it.
  if !wasLeader || !CBPowerStrugglesOn() || !IsDefined(fs) || fs.leaderRivalId <= 0 {
    return;
  }
  let heir = sys.FindRivalById(fs.leaderRivalId);
  let rivalId = fs.lt1RivalId > 0 ? fs.lt1RivalId : (fs.lt2RivalId > 0 ? fs.lt2RivalId : fs.lt3RivalId);
  let rival = rivalId > 0 ? sys.FindRivalById(rivalId) : null;
  if !IsDefined(heir) || !IsDefined(rival) || !CBRivalStillAround(heir) || !CBRivalStillAround(rival) {
    return;
  }
  book.Begin(slain.faction, heir.id, rival.id, now + CBConfig.StruggleDays() * CBConfig.SecondsPerDay());
  CBLog.Info(n"Rivals", s"A power struggle in \(NameToString(slain.faction)).");
  if CBMessagesOn() {
    let heirName = CBRivalDisplayName(content, heir);
    let rivalName = CBRivalDisplayName(content, rival);
    CBPhoneSendTinted(game, heirName, s"I run \(CBFactionLabel(slain.faction)) now. \(rivalName) doesn't think so. Put them down and I'll remember who helped.", CBHudCyan());
    CBPhoneSendTinted(game, rivalName, s"\(heirName) took a chair that should be mine. Deal with them, and \(CBFactionLabel(slain.faction)) are your friends.", CBHudCyan());
  }
}

func CBRivalStillAround(r: ref<CBRival>) -> Bool {
  return IsDefined(r) && r.state != EnumInt(ECBRivalState.Slain) && r.state != EnumInt(ECBRivalState.Retired);
}

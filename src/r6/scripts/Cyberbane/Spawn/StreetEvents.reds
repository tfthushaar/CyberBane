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

public func CBTalkActRespects() -> Int32 = 34

public func CBGatheringsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().gatherings);
}

public func CBDealsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().dealsAndRackets);
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

  public func Tag() -> CName {
    return Equals(this.kind, CBEvSitDown()) ? n"CB_Meet" : n"CB_Event";
  }

  public func Sides() -> Int32 {
    return Equals(this.kind, CBEvSitDown()) || Equals(this.kind, CBEvArmsDeal()) ? 2 : 1;
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
    if Equals(kind, CBEvSitDown()) {
      for g in CBGangRivalsOf(sys.GetContent(), a) {
        if Equals(b, n"") && CBFactionFieldsSquads(g) && CBFactionOn(g) && IsDefined(sys.FindFaction(g)) {
          b = g;
        }
      }
      if Equals(b, n"") {
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
    }
    if ev.placed {
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
    let fa = sys.FindFaction(ev.a);
    let fb = sides == 2 ? sys.FindFaction(ev.b) : fa;
    let perSide = CBEventPerSide(ev.kind);
    let want = Min(sides * perSide, CBSpawnRoom(game));
    want -= want % sides;
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
          let side = n % sides == 0 ? fa : fb;
          let chair = n / sides;
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
    if placed >= 2 && placed < sides * perSide {
      CBLog.Info(n"Street", s"A \(NameToString(ev.kind)) placed \(placed) of \(sides * perSide) people.");
    }
    return placed >= 2;
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
  return 4;   // a racket
}

public func CBEventApexPerSide(kind: CName) -> Int32 {
  if Equals(kind, CBEvSitDown()) { return CBSitDownApexPerGang(); }
  if Equals(kind, CBEvArmsDeal()) { return 1; }   // somebody to guard the goods
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
  return "Heard " + a + " and " + CBFactionLabel(ev.b) + " are meeting. Could go either way.";
}

// ---- Outcomes ------------------------------------------------------------------------------------------

// V broke it up.
public func CBEventCrashed(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
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

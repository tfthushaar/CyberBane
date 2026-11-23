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
// V's road (Spawn/HuntGrows.reds, 2.4.2): never announced, never pinned.
public func CBEvAmbush() -> CName = n"Ambush"

public func CBTalkActRespects() -> Int32 = 34
public func CBTalkActStandWith() -> Int32 = 60

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
  if Equals(kind, CBEvAmbush()) {
    return CBLieInWaitOn();
  }
  return CBGatheringsOn();
}

public class CBStreetEvent {
  public let informant: Bool;            // the one hunted is V's informant (2.4.5, [U12])
  public let informantRival: Int32;
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
  public let started: Bool;            // the two sides set against each other (a fight, 2.3.4) or at peace (a meeting, 2.4.2)
  public let size: Int32;              // an ambush's crew (2.4.2)
  public let byV: Bool;                // a funeral for somebody V put down, rather than somebody else's dead
  public let vSide: Int32;             // a front line V stood with one side of (2.6.1): 0 neither, 1 the first gang, 2 the second
  public let pinWhen: String;          // the time its pin says, so the pin is redrawn when "tomorrow" becomes "today"
  // Where each of `ids` walks to once in the world (2.6.3), beside `ids`: the zero vector for one placed on the spot.
  // Somebody placed further out, out of V's sight, walks in, because V was standing at the place or looking at it.
  public let walkAt: array<Vector4>;
  // What a sit-down is about (2.6.5): 1 money the first gang owes the second, 2 a killing, 3 a street both work, 4 V.
  public let reason: Int32;
  // The place settled onto the street once V is near enough for it to be in the world (2.6.8, CBEventSettlePlace), and
  // whether its being held back has been said in the log.
  public let anchored: Bool;
  public let heldSaid: Bool;
  // The name of the place, when it is a data terminal's (2.6.8): what the word on it calls it. "" for one near V.
  public let placeName: String;
  // V was close enough to see it, after its time, while its people could not yet be put in the world (2.7.2).
  public let watched: Bool;
  // V came to the place before its time and was told when it starts (2.7.3).
  public let earlySaid: Bool;
  // The closest V came to the place, for the log when it ends without happening (2.7.3).
  public let nearest: Float;
  // Ticks spent waiting for the ground at the place to load, V near and its time come (2.7.3).
  public let groundWait: Int32;
  // The tick its people may next be tried, after a try that found nowhere out of V's sight (2.7.3).
  public let nextTry: Int32;

  public func Tag() -> CName {
    if Equals(this.kind, CBEvAmbush()) {
      return n"CB_Ambush";
    }
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
  private let m_funeralByV: Bool;        // whoever they bury, V put them there (CBOweFuneral)
  private let m_huntFor: CName;          // an informant's gang, owed a hunt for them (Reactions/Allies.reds, 2.4.5)
  private let m_huntRival: Int32;
  private let m_huntAt: Float;
  private let m_funeralAt: Float;
  private let m_partyFor: CName;
  private let m_partyAt: Float;

  public func Live() -> ref<CBStreetEvent> {
    return this.m_ev;
  }

  // A crew waiting for V near V's tracked job (Spawn/HuntGrows.reds, [47]): placed when V comes near, hostile from
  // the start, unannounced.
  public func StartAmbush(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, at: Vector4, size: Int32) -> Bool {
    if IsDefined(this.m_ev) {
      return false;
    }
    let now = CBGameSeconds(game);
    let ev = new CBStreetEvent();
    ev.kind = CBEvAmbush();
    ev.a = gang;
    ev.at = at;
    ev.district = sys.GetCurrentDistrict();
    ev.from = now;
    ev.until = now + CBConfig.AmbushWaitSeconds();
    ev.size = size;
    this.m_ev = ev;
    return true;
  }

  public func OweFuneral(gang: CName, now: Float, byV: Bool) -> Void {
    if CBFactionFieldsSquads(gang) {
      this.m_funeralFor = gang;
      this.m_funeralByV = byV;
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
      if nowT >= this.m_next && (CBGatheringsOn() || CBDealsOn() || CBGangFightsOn()) {
        CBStreetWhyNot(game, "gang life", busy ? "V is somewhere the story, a job, a safe place or home ground keeps quiet" : "V is in a fight");
      }
      return;
    }
    // Not before V's district is known (2.6.3): every roll in the first minutes after a load found nobody holding
    // "None" and spent its clock on it, so a short session saw no gang life at all.
    if Equals(sys.GetCurrentDistrict(), n"") {
      if nowT >= this.m_next && (CBGatheringsOn() || CBDealsOn() || CBGangFightsOn()) {
        CBStreetWhyNot(game, "gang life", "V's district is not known yet");
      }
      return;
    }
    // The sit-down, on its own clock and chance, as before.
    if nowT >= this.m_meetNext && CBStreetLifeOn(n"sitDowns") {
      this.m_meetNext = nowT + CBJitter(CBConfig.MeetGapTicks(), 0.4);
      if RandF() < CBConfig.MeetChance() {
        if this.Start(sys, game, player, CBEvSitDown()) {
          return;
        }
        CBStreetWhyNot(game, "sit-down", this.m_why);
      }
    }
    // Everything else. The fights between gangs have their own switch (2.4.2): with gatherings and deals both off
    // this used to stop here, so no fight ever came, and two gangs V had set on each other never met.
    if nowT < this.m_next || !(CBGatheringsOn() || CBDealsOn() || CBGangFightsOn()) {
      return;
    }
    this.m_next = nowT + CBJitter(RoundF(Cast<Float>(CBConfig.EventGapTicks()) / CBGangLifeOften()), 0.4);
    if RandF() >= CBConfig.EventChance() {
      return;
    }
    let kind = this.Choose(sys, now);
    if IsNameValid(kind) && !this.Start(sys, game, player, kind) {
      CBStreetWhyNot(game, NameToString(kind), this.m_why);
    }
  }

  // Why the last Start came to nothing (2.5.7), for CBStreetWhyNot.
  private let m_why: String;

  public func OweInformantHunt(gang: CName, rivalId: Int32, now: Float) -> Void {
    this.m_huntFor = gang;
    this.m_huntRival = rivalId;
    this.m_huntAt = now + CBConfig.SecondsPerHour();
  }

  // What happens next: a debt first, then whatever the switches allow.
  private func Choose(sys: ref<CyberbaneSystem>, now: Float) -> CName {
    // Owed no longer than a funeral is: a hunt that could never be placed must not stand in front of everything else.
    if NotEquals(this.m_huntFor, n"") && now > this.m_huntAt + CBConfig.EventOwedDays() * CBConfig.SecondsPerDay() {
      this.m_huntFor = n"";
    }
    if CBGangFightsOn() && NotEquals(this.m_huntFor, n"") && now >= this.m_huntAt {
      return CBEvFugitive();
    }
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
    this.m_why = "";
    if Equals(kind, CBEvFuneral()) || Equals(kind, CBEvCelebration()) {
      a = Equals(kind, CBEvFuneral()) ? this.m_funeralFor : this.m_partyFor;
      // On their own streets: only where they are, near V.
      let gangsHere = CBTurfGangsHere(sys);   // a local, never a temporary (UI/HubWeb.reds, CBWebPair)
      if !ArrayContains(gangsHere, a) {
        this.m_why = CBTf(n"Cyberbane-StreetEvents-HaveNoStreetsHere", [s"\(NameToString(a))"]);
        return false;
      }
    } else {
      a = CBTurfHolder(sys, game, district);
    }
    if Equals(a, n"") || !CBFactionFieldsSquads(a) || !CBFactionOn(a) {
      this.m_why = CBTf(n"Cyberbane-StreetEvents-NoGangThatFieldsPeopleHolds", [s"\(NameToString(district))"]);
      return false;
    }
    // An informant's own gang runs them down: one of theirs, the hunters theirs too (2.4.5, [U12]).
    let informantHunt = Equals(kind, CBEvFugitive()) && NotEquals(this.m_huntFor, n"") && CBGameSeconds(game) >= this.m_huntAt;
    if informantHunt {
      a = this.m_huntFor;
      b = this.m_huntFor;
    }
    if !informantHunt && (Equals(kind, CBEvSitDown()) || CBIsFightKind(kind)) {
      // The pair V set on each other, when the holder here is one of them.
      let war = CBWarBook.Get(game);
      if Equals(kind, CBEvFrontLine()) && IsDefined(war) && CBGameSeconds(game) < war.InciteUntil() {
        if Equals(a, war.InciteA()) { b = war.InciteB(); }
        if Equals(a, war.InciteB()) { b = war.InciteA(); }
      }
      // Any gang at war with theirs that can field people, whether or not V has crossed it (2.5.0): asking for its
      // record left a district whose holder's enemies V had never fought without sit-downs or fights at all.
      for g in CBGangRivalsOf(sys.GetContent(), a) {
        if Equals(b, n"") && CBFactionFieldsSquads(g) && CBFactionOn(g) {
          b = g;
        }
      }
      if Equals(b, n"") {
        this.m_why = CBTf(n"Cyberbane-StreetEvents-HaveNoRivalGangThatFields", [s"\(NameToString(a))"]);
        return false;
      }
      // Two gangs in a truce against V do not fight each other (Economy/War.reds, [36]).
      if CBIsFightKind(kind) && Equals(CBTrucePartner(game, a), b) {
        this.m_why = CBTf(n"Cyberbane-StreetEvents-AndAreInATruce", [s"\(NameToString(a))", s"\(NameToString(b))"]);
        return false;
      }
    }
    if Equals(kind, CBEvArmsDeal()) {
      b = CBDealPartner(sys, a);
      if Equals(b, n"") {
        this.m_why = CBTf(n"Cyberbane-StreetEvents-NobodyToDealWith", [s"\(NameToString(a))"]);
        return false;
      }
    }
    // Somewhere to go to (2.6.8): "the places of street events are still close to me, it can be in the same district but I
    // want to travel". One of the data terminals V has found in V's district, a walk or a drive off; failing that, as
    // before, somewhere near V.
    let spot: Vector4;
    let placeName = "";
    if !CBEventFarPlace(sys, game, player, spot, placeName) && !CBWhereaboutsSpot(sys, game, player, spot) {
      this.m_why = CBT(n"Cyberbane-StreetEvents-NoPlaceForItInThis");
      return false;
    }
    let now = CBGameSeconds(game);
    let ev = new CBStreetEvent();
    ev.kind = kind;
    ev.a = a;
    ev.b = b;
    if informantHunt {
      ev.informant = true;
      ev.informantRival = this.m_huntRival;
      this.m_huntFor = n"";
    }
    ev.at = spot;
    ev.placeName = placeName;
    ev.district = district;
    if Equals(kind, CBEvSitDown()) {
      ev.from = CBQuarterUp(now + RandRangeF(1.0, 2.0) * 3600.0);
      ev.until = ev.from + CBConfig.MeetWindowSeconds();
      ev.reason = CBMeetReasonFor(sys, a, b);
    } else {
      ev.from = CBQuarterUp(now + RandRangeF(CBConfig.EventLeadMinHours(), CBConfig.EventLeadMaxHours()) * 3600.0);
      ev.until = ev.from + CBConfig.EventWindowSeconds();
    }
    this.m_ev = ev;
    if Equals(kind, CBEvFuneral()) {
      ev.byV = this.m_funeralByV;
      this.m_funeralFor = n"";
    }
    if Equals(kind, CBEvCelebration()) {
      this.m_partyFor = n"";
    }
    this.KeepPin(game);
    // A message, not word going round (2.6.5): something V can go to is never held back as chatter.
    if CBMessagesOn() {
      CBPhoneFromDistrict(game, district, CBEventWordLine(ev));
    }
    CBLog.Info(n"Street", s"A \(NameToString(kind)) is set: \(NameToString(a)) \(NameToString(b)).");
    CBEmit(StringToName("Cyberbane/StreetEvent/" + NameToString(kind)), a, 0.0);   // [91], 2.4.6
    return true;
  }

  private func Run(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>) -> Void {
    let ev = this.m_ev;
    let now = CBGameSeconds(game);
    this.KeepPin(game);
    // How far V is from the place, along the ground (2.7.3): a meeting under an overpass or beside a tower block is near
    // V on the walkway above it too. Straight-line distance only once the levels are a building apart.
    let ppos = player.GetWorldPosition();
    let dist = AbsF(ppos.Z - ev.at.Z) <= CBConfig.EventSameLevel() ? Vector4.Distance2D(ppos, ev.at) : Vector4.Distance(ppos, ev.at);
    if ev.nearest <= 0.0 || dist < ev.nearest {
      ev.nearest = dist;
    }
    // Early (2.7.3): V at the place before its time is told when it starts, once, and that keeping out of sight works.
    if !ev.placed && !ev.earlySaid && now < ev.from && dist <= CBConfig.MeetSpawnDistance() && !Equals(ev.kind, CBEvAmbush()) {
      ev.earlySaid = true;
      CBLog.Info(n"Street", s"V is at the \(NameToString(ev.kind)) place \(RoundF((ev.from - now) / 60.0)) game minutes early.");
      if CBMessagesOn() {
        CBSystemNote(game, CBTf(n"Cyberbane-StreetEvents-YouAreEarly", [CBClockWord(ev.from)]), 6.0);
      }
    }
    // Their time has come and V is on the way in, not yet looking: put them there. Never while the story has the
    // stage, V is in a scene or at the job V is tracking, or a job has come up at the place since (2.4.2): an event
    // already planned placed its people whatever V was doing, and a crew lying in wait near V's job (an ambush) walked in on
    // the job itself.
    //
    // About the place, not about V's ground (2.6.8): "I went to the meeting between Barghest and Militech at 3:10, it was
    // supposed to be at 3:00, and there was nothing there." It asked whether V stood on a gang's restricted or hostile
    // ground (IsInQuestArea), which is where a gang meets, and whether V was within eighty metres of any job (IsOnJob),
    // while the place had been chosen only sixty metres clear of one: a meeting on Barghest's own streets could never be
    // put there, and nothing said why.
    let storyBusy = sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) || CBAtTrackedJob(sys, game)
                 || sys.NearQuestPins(ev.at, CBConfig.QuestSpawnClearance());
    if storyBusy && !ev.placed && now >= ev.from && dist <= CBConfig.MeetSpawnDistance() && !ev.heldSaid {
      ev.heldSaid = true;
      CBStreetWhyNot(game, NameToString(ev.kind), sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game)
        ? "the story has the stage" : "a job is at the place, or V is at the job V is tracking");
    }
    // The place onto the street it stands on, once it is in the world: a data terminal stands against a wall.
    if !ev.anchored && dist <= CBConfig.MeetSpawnDistance() {
      ev.anchored = CBEventSettlePlace(game, ev);
    }
    // V already at the place counts too (2.6.3): it asked for V to be 25 m off at least, so a V waiting on the spot for
    // the time on the pin was never given anybody ("I went there and there's nothing"). Whoever cannot be put there out
    // of V's sight comes from further off and walks in (Place).
    // The ground there has to be loaded before anybody can stand on it (2.7.3, the game's own NavigationSystem asks it
    // before a path): until it is, wait, and say so once, rather than fail to place and count it.
    // A place already settled onto the street has its ground; the wait is bounded, so a place the question gets wrong
    // is still tried as before.
    // Asked only when it matters: V near, its time come, nobody placed yet.
    let due = !ev.placed && !storyBusy && now >= ev.from && dist <= CBConfig.MeetSpawnDistance();
    let groundReady = !due || ev.anchored || ev.groundWait >= CBConfig.EventGroundWaitTicks() || CBNavmeshReady(game, ev.at);
    if due && !groundReady {
      ev.groundWait += 1;
      CBStreetWhyNot(game, NameToString(ev.kind), "the ground at the place has not loaded yet");
    }
    // A try that found nowhere hidden is tried again a few ticks later, not every tick: each try asks the navmesh and
    // casts rays for a hundred and more spots, and V a few steps on sees the place differently (2.7.3).
    if !ev.placed && !storyBusy && groundReady && now >= ev.from && dist <= CBConfig.MeetSpawnDistance()
       && sys.GetTickCount() >= ev.nextTry {
      ev.watched = true;
      ev.placed = this.Place(sys, game, des, player, ev);
      ev.placedTick = sys.GetTickCount();
      ev.nextTry = sys.GetTickCount() + CBConfig.EventRetryTicks();
      if !ev.placed {
        CBStreetWhyNot(game, NameToString(ev.kind), "nowhere near the place out of V's sight to put its people yet");
      }
    }
    if ev.placed {
      CBEventWalkIns(game, ev);
    }
    // A fight: once its people are in the world, the sides are set against each other, and it ends its own way.
    if ev.placed && CBIsFightKind(ev.kind) {
      // A front line's standoff: the two sides held off each other, as at a meeting, until it starts.
      let opened = false;
      if !ev.started && Equals(ev.kind, CBEvFrontLine()) {
        CBCalmSides(sys, game, ev);
        opened = CBEventHurtByV(game, ev);   // V opened fire: it starts now, whoever V shot at
      }
      if !ev.started && (sys.GetTickCount() - ev.placedTick >= CBEventStartTicks(ev.kind) || ev.vSide > 0 || opened) {
        ev.started = true;
        CBStartFight(sys, game, player, ev);
      }
      if ev.started && CBFightOver(sys, game, ev) {
        this.End(game);
        return;
      }
    }
    // Two gangs meeting keep the peace between themselves (2.4.2): each side's people are set neutral to the
    // other's, pair by pair, as they come into the world, the reverse of what a fight does. Nothing set them
    // either way before, so gangs the game's own data has at odds (Night City Alive makes many more of them
    // so) could open fire on each other as they appeared, and a meeting whose people killed each other could
    // never be crashed by V, since only V's work counts. Only between these people, and gone with them.
    if ev.placed && !ev.started && ev.Sides() == 2 && !CBIsFightKind(ev.kind) {
      if CBCalmSides(sys, game, ev) || sys.GetTickCount() - ev.placedTick > CBConfig.EventCalmTicks() {
        ev.started = true;
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
        if !ev.placed {
          CBLog.Info(n"Street", s"The \(NameToString(ev.kind)) ended without its people placed: the closest V came was \(RoundF(ev.nearest)) m (they come within \(RoundF(CBConfig.MeetSpawnDistance())) m, from \(CBClockWord(ev.from))).");
        }
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
    // An ambush is not on anybody's map.
    let want = CBMapMarkersOn() && !Equals(ev.kind, CBEvAmbush());
    // The time it says, with the day (2.6.1): redrawn when that changes, so "tomorrow" turns into "today" at midnight.
    let when = CBWhenWord(game, ev.from);
    if Equals(want, ev.pinned) && (!want || Equals(when, ev.pinWhen)) {
      return;
    }
    let ms = GameInstance.GetMappinSystem(game);
    if !IsDefined(ms) {
      return;
    }
    if ev.pinned {
      ms.UnregisterMappin(ev.pin);
      ev.pinned = false;
    }
    if !want {
      return;
    }
    // Cyberbane's own pin with TweakXL (UI/MapPins.reds, 2.5.0), and a gathering's own mark (UI/RivalPin.reds).
    // With the hour it starts (2.5.5): the pin goes up when the street hears of it, often an hour before.
    let around = CBWhenIsNow(game, ev.from) ? CBT(n"Cyberbane-StreetEvents-Now") : CBTf(n"Cyberbane-StreetEvents-Around", [when]);
    ev.pin = ms.RegisterMappin(CBPlacePinData(CBEventPinCaption(CBEventCaption(ev) + around)), ev.at);
    ev.pinWhen = when;
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
    // Each side's people from the gang itself (Data/ApexRoster.reds, CBGangTemplate), so an event planned for a gang V
    // has never fought takes place: it was announced, then never put in the world, for want of a record (2.5.0).
    let gangA = ev.a;
    let gangB = sides == 2 ? ev.b : ev.a;
    let recA = CBGangTemplate(sys, gangA);
    let recB = CBGangTemplate(sys, gangB);
    let perSide = Equals(ev.kind, CBEvAmbush()) ? Max(ev.size, 2) : CBEventPerSide(ev.kind);
    let full = lone > 0 ? lone + perSide : sides * perSide;
    let want = Min(full, CBSpawnRoom(game));
    if lone == 0 {
      want -= want % sides;
    }
    if !TDBID.IsValid(recA) || !TDBID.IsValid(recB) || want < 2 {
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
           && CBSettleOnGround(game, snapped, at) && CBPointHiddenFrom(game, ppos, fwd, at)
           && CBStandsWith(game, at, ev.at, CBConfig.GroundMaxDrop()) && CBLairPointUsable(sys, game, at) {
          let facing = Quaternion.BuildFromDirectionVector(new Vector4(-CosF(ang), -SinF(ang), 0.0, 0.0));
          let n = ArraySize(ev.ids);
          let sideGang = ev.SideOf(n) == 0 ? gangA : gangB;
          let chair = lone > 0 ? (n < lone ? apexPerSide : n - lone) : n / sides;
          let rec = ev.SideOf(n) == 0 ? recA : recB;
          let role = n"";
          if chair < apexPerSide {
            let best = CBApexRosterRecord(sideGang, chair);
            if TDBID.IsValid(best) {
              rec = best;
              role = CBApexRoleTag(chair);
            }
          }
          let id: EntityID;
          if CBCreateSpawn(des, rec, n"", at, facing, tag, id, role) {
            ArrayPush(ev.ids, id);
            ArrayPush(ev.walkAt, new Vector4(0.0, 0.0, 0.0, 0.0));
          }
        }
      }
      ring += 1;
    }
    // V at the place, or looking at it (2.6.3): the rest come from further out, out of sight, and walk to their spot.
    // Out to 70 m (2.7.2): a player watching the place from across the street had every point within 30 m of it in
    // view, so nobody could be put in the world, the time came and went, and the word said later it had happened. Points
    // that far out are behind something, and the people placed there walk in while V watches. Never further from V
    // than MeetWalkInReach, which is as far as the world round V is sure to be loaded.
    let rings: array<Float> = [12.0, 18.0, 24.0, 30.0, 42.0, 56.0, 70.0];
    let outer = 0;
    while outer < ArraySize(rings) && ArraySize(ev.ids) < want {
      let far = rings[outer];
      let slotsOut = Min(10 + outer * 2, 18);
      outer += 1;
      let o = 0;
      while o < slotsOut && ArraySize(ev.ids) < want {
        let angOut = Cast<Float>(o) * 6.28318 / Cast<Float>(slotsOut);
        o += 1;
        let snappedOut: Vector4;
        let atOut: Vector4;
        if CBNavSnap(game, ev.at.X + CosF(angOut) * far, ev.at.Y + SinF(angOut) * far, ev.at.Z, snappedOut)
           && Vector4.Distance(ppos, snappedOut) <= CBConfig.MeetWalkInReach()
           && CBSettleOnGround(game, snappedOut, atOut) && CBPointHiddenFrom(game, ppos, fwd, atOut)
           && CBStandsWith(game, atOut, ev.at, CBConfig.GroundMaxDrop()) && CBLairPointUsable(sys, game, atOut) {
          let n2 = ArraySize(ev.ids);
          let sideGang2 = ev.SideOf(n2) == 0 ? gangA : gangB;
          let chair2 = lone > 0 ? (n2 < lone ? apexPerSide : n2 - lone) : n2 / sides;
          let rec2 = ev.SideOf(n2) == 0 ? recA : recB;
          let role2 = n"";
          if chair2 < apexPerSide {
            let best2 = CBApexRosterRecord(sideGang2, chair2);
            if TDBID.IsValid(best2) {
              rec2 = best2;
              role2 = CBApexRoleTag(chair2);
            }
          }
          let facingOut = Quaternion.BuildFromDirectionVector(new Vector4(-CosF(angOut), -SinF(angOut), 0.0, 0.0));
          let id2: EntityID;
          if CBCreateSpawn(des, rec2, n"", atOut, facingOut, tag, id2, role2) {
            ArrayPush(ev.ids, id2);
            let spot = 2.2 + Cast<Float>(n2 % 3) * 1.6;
            ArrayPush(ev.walkAt, new Vector4(ev.at.X + CosF(angOut) * spot, ev.at.Y + SinF(angOut) * spot, ev.at.Z, 1.0));
          }
        }
      }
    }
    // Third (2.7.3): the navmesh's own hidden points round the place, the question the game asks for a pursuit, when
    // the rings found too few out of V's sight (tight streets, a place below a walkway). One query, only when needed.
    if ArraySize(ev.ids) < want {
      let pts: array<Vector4>;
      if CBPursuitPointsAround(game, ppos, ev.at, want - ArraySize(ev.ids), CBConfig.EventPursuitMin(), CBConfig.EventPursuitMax(), pts) {
        for p in pts {
          if ArraySize(ev.ids) < want && Vector4.Distance(ppos, p) <= CBConfig.MeetWalkInReach()
             && CBPointHiddenFrom(game, ppos, fwd, p) && CBStandsWith(game, p, ev.at, CBConfig.GroundMaxDrop())
             && CBLairPointUsable(sys, game, p) {
            this.PutOne(des, ev, p, tag, gangA, gangB, recA, recB, lone, sides, apexPerSide);
          }
        }
      }
    }
    let placed = ArraySize(ev.ids);
    // Said once, when it is in place: a try that placed nobody is tried again next tick.
    if placed >= 2 && placed < full {
      CBLog.Info(n"Street", s"A \(NameToString(ev.kind)) placed \(placed) of \(full) people.");
    }
    return placed >= Max(2, lone + 1);
  }

  // One of the event's people at a point away from the place, facing it, walking in to a spot by it (2.7.3, for the
  // pursuit points; the rings above do the same inline).
  private func PutOne(des: ref<DynamicEntitySystem>, ev: ref<CBStreetEvent>, at: Vector4, tag: CName, gangA: CName, gangB: CName,
                      recA: TweakDBID, recB: TweakDBID, lone: Int32, sides: Int32, apexPerSide: Int32) -> Bool {
    let n = ArraySize(ev.ids);
    let sideGang = ev.SideOf(n) == 0 ? gangA : gangB;
    let chair = lone > 0 ? (n < lone ? apexPerSide : n - lone) : n / Max(sides, 1);
    let rec = ev.SideOf(n) == 0 ? recA : recB;
    let role = n"";
    if chair < apexPerSide {
      let best = CBApexRosterRecord(sideGang, chair);
      if TDBID.IsValid(best) {
        rec = best;
        role = CBApexRoleTag(chair);
      }
    }
    let toward = new Vector4(ev.at.X - at.X, ev.at.Y - at.Y, 0.0, 0.0);
    let facing = Quaternion.BuildFromDirectionVector(Vector4.Length(toward) > 0.1 ? Vector4.Normalize(toward) : new Vector4(1.0, 0.0, 0.0, 0.0));
    let id: EntityID;
    if !CBCreateSpawn(des, rec, n"", at, facing, tag, id, role) {
      return false;
    }
    ArrayPush(ev.ids, id);
    let outward = new Vector4(at.X - ev.at.X, at.Y - ev.at.Y, 0.0, 0.0);
    let unit = Vector4.Length(outward) > 0.1 ? Vector4.Normalize(outward) : new Vector4(1.0, 0.0, 0.0, 0.0);
    let spot = 2.2 + Cast<Float>(n % 3) * 1.6;
    ArrayPush(ev.walkAt, new Vector4(ev.at.X + unit.X * spot, ev.at.Y + unit.Y * spot, ev.at.Z, 1.0));
    return true;
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

// A place to go to for a gathering (2.6.8): one of the data terminals V has found, in V's own district, between
// EventPlaceMin and EventPlaceMax away, clear of jobs and safe places (CBLairPointUsable). Each terminal is a named place
// on a street, its district the game's own (FastTravelPoint_Record), and its pin's position is the terminal's.
func CBEventFarPlace(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, out spot: Vector4,
                     out name: String) -> Bool {
  // Never while a load or a fast travel is under way (2.7.0): the crash came during a quickload, with the travel points and
  // their records being put back.
  if !CBWorldStable(game) {
    return false;
  }
  let district = sys.GetCurrentDistrict();
  let container = GameInstance.GetScriptableSystemsContainer(game);
  let fts = IsDefined(container) ? container.Get(n"FastTravelSystem") as FastTravelSystem : null;
  let ms = GameInstance.GetMappinSystem(game);
  if Equals(district, n"") || !IsDefined(fts) || !IsDefined(ms) || !IsDefined(player) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let points = fts.GetFastTravelPoints();
  let picks: array<Vector4>;
  let names: array<String>;
  for pt in points {
    if IsDefined(pt) {
      let pointId = pt.GetPointRecord();
      let rec = TDBID.IsValid(pointId) ? TweakDBInterface.GetFastTravelPointRecord(pointId) : null;
      // Its district read as an id and looked up by the null-safe getter, never through the record's own District()
      // (2.7.0): that one dereferences whatever its link resolves to, and a point whose district is missing (added by a
      // mod such as FastTravelFromAnywhereToAnyFastTravelPoint, or not ready during a load) took the game down inside it,
      // before any check here could run. Not a metro station's either: its point can be on the platform, under the street.
      let dRec: ref<District_Record>;
      if IsDefined(rec) && !rec.SubwayStation() {
        let flat = pointId;
        TDBID.Append(flat, t".district");   // the point's own district link, as an id
        let districtId = TweakDBInterface.GetForeignKey(flat, TDBID.None());
        if TDBID.IsValid(districtId) {
          dRec = TweakDBInterface.GetDistrictRecord(districtId);
        }
      }
      if IsDefined(dRec) && Equals(CBMapGameDistrict(dRec.EnumName()), district) {
        let pin = ms.GetMappin(pt.mappinID);
        if IsDefined(pin) {
          let at = pin.GetWorldPosition();
          let away = Vector4.Distance(ppos, at);
          if away >= CBConfig.EventPlaceMin() && away <= CBConfig.EventPlaceMax() && CBLairPointUsable(sys, game, at) {
            ArrayPush(picks, at);
            ArrayPush(names, GetLocalizedText(rec.DisplayName()));
          }
        }
      }
    }
  }
  let n = ArraySize(picks);
  if n == 0 {
    return false;
  }
  let k = RandRange(0, n);
  spot = picks[k];
  name = names[k];
  return true;
}

// Where it is, in the word on it (2.6.8): by the place's name when it has one, else near here.
public func CBEventWhere(ev: ref<CBStreetEvent>) -> String {
  return IsDefined(ev) && StrLen(ev.placeName) > 0 ? CBTf(n"Cyberbane-StreetEvents-By", [ev.placeName]) : CBT(n"Cyberbane-StreetEvents-NearHere");
}

// The place onto the street beside it (2.6.8): the nearest walkable ground within a few metres. Asked once V is near
// enough for the street to be in the world; until it answers, the place is where its pin is.
func CBEventSettlePlace(game: GameInstance, ev: ref<CBStreetEvent>) -> Bool {
  let ring = 0;
  while ring < 4 {
    let radius = Cast<Float>(ring) * 1.5;
    let slots = ring == 0 ? 1 : 8;
    let k = 0;
    while k < slots {
      let ang = Cast<Float>(k) * 6.28318 / Cast<Float>(slots);
      let snapped: Vector4;
      let ground: Vector4;
      if CBNavSnap(game, ev.at.X + CosF(ang) * radius, ev.at.Y + SinF(ang) * radius, ev.at.Z, snapped)
         && CBSettleOnGround(game, snapped, ground) {
        ev.at = ground;
        return true;
      }
      k += 1;
    }
    ring += 1;
  }
  return false;
}

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

// Somebody to buy guns from this gang: a gang it is not at war with, any of them. The first in the book was taken
// every time until 2.4.2, so every arms deal in a playthrough was with the same gang.
func CBDealPartner(sys: ref<CyberbaneSystem>, a: CName) -> CName {
  let content = sys.GetContent();
  let fit: array<CName>;
  if !IsDefined(content) {
    return n"";
  }
  // Every gang in the city, not only those V has crossed (2.5.0): the deal's buyers were only ever gangs V had killed.
  for prof in content.GetFactions() {
    if IsDefined(prof) && prof.isGang && NotEquals(prof.id, a) && CBFactionFieldsSquads(prof.id) && CBFactionOn(prof.id)
       && !CBIsCorpFaction(prof.id) && TDBID.IsValid(CBGangTemplate(sys, prof.id))
       && !CBGangsAreRivals(content, a, prof.id) && !CBGangsAreRivals(content, prof.id, a) {
      ArrayPush(fit, prof.id);
    }
  }
  return ArraySize(fit) > 0 ? fit[RandRange(0, ArraySize(fit))] : n"";
}

public func CBEventCaption(ev: ref<CBStreetEvent>) -> String {
  return CBEventCaptionOf(ev.kind, ev.a, ev.b);
}

// What a sit-down is about (2.6.5): two gangs both after V talk about V half the time; otherwise money, a killing or a street.
func CBMeetReasonFor(sys: ref<CyberbaneSystem>, a: CName, b: CName) -> Int32 {
  let score = sys.GetScore();
  if IsDefined(score) {
    let pa = score.GetPosture(a);
    let pb = score.GetPosture(b);
    let aAfter = Equals(pa, ECBPosture.Hostile) || Equals(pa, ECBPosture.Vendetta);
    let bAfter = Equals(pb, ECBPosture.Hostile) || Equals(pb, ECBPosture.Vendetta);
    if aAfter && bAfter && RandF() < 0.5 {
      return 4;
    }
  }
  return RandRange(1, 4);
}

func CBMeetReasonWords(ev: ref<CBStreetEvent>) -> String {
  let a = CBFactionLabel(ev.a);
  let b = CBFactionLabel(ev.b);
  switch ev.reason {
    case 1: return CBTf(n"Cyberbane-StreetEvents-OverMoneyOwe", [s"\(a)", s"\(b)"]);
    case 2: return CBTf(n"Cyberbane-StreetEvents-OverOneOfPeopleKilled", [s"\(CBPossessive(a))", s"\(b)"]);
    case 3: return CBT(n"Cyberbane-StreetEvents-OverAStreetTheyBothWant");
    case 4: return CBT(n"Cyberbane-StreetEvents-AndTheTalkIsAboutYou");
    default: return CBT(n"Cyberbane-StreetEvents-OverOldBusiness");
  }
}

// Crashed: who it hurt most. The money owed, the blood owed, the street's holder; talk about V hurts both, and is off.
func CBMeetCrashAngrier(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> CName {
  if ev.reason == 1 {
    return ev.b;
  }
  if ev.reason == 2 {
    return ev.a;
  }
  if ev.reason == 3 {
    return Equals(CBTurfHolder(sys, game, ev.district), ev.b) ? ev.b : ev.a;
  }
  if ev.reason == 4 {
    CBTalkSlight(sys, game, ev.b, CBConfig.MeetReasonAnger());
    return ev.a;
  }
  return n"";
}

// Left alone: they made their deal, and what it was decides what changed.
func CBMeetSettled(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  let a = CBCapFirst(CBFactionLabel(ev.a));
  let b = CBFactionLabel(ev.b);
  let line = CBTf(n"Cyberbane-StreetEvents-AndMadeTheirDealNobodyStopped", [s"\(a)", s"\(b)"]);
  if ev.reason == 1 {
    CBWarSpend(game, ev.a, CBConfig.WarDealValue());
    CBWarEarn(game, ev.b, CBConfig.WarDealValue());
    line = CBTf(n"Cyberbane-StreetEvents-PaidWhatTheyOwedTheirWar", [s"\(a)", s"\(b)"]);
  }
  if ev.reason == 2 {
    if RandF() < 0.5 {
      line = CBTf(n"Cyberbane-StreetEvents-AndSettledTheKillingWithMoney", [s"\(a)", s"\(b)"]);
    } else {
      CBWeakenGang(sys, game, ev.a, CBConfig.MeetGangLoss() * 0.5);
      CBWeakenGang(sys, game, ev.b, CBConfig.MeetGangLoss() * 0.5);
      line = CBTf(n"Cyberbane-StreetEvents-TheSitDownOverTheKilling", [s"\(a)", s"\(b)"]);
    }
  }
  if ev.reason == 3 {
    CBBolsterGang(sys, game, RandF() < 0.5 ? ev.a : ev.b, CBEventBolster(CBEvRecruitment()) * 0.5);
    line = CBTf(n"Cyberbane-StreetEvents-AndCarvedUpTheStreetBetween", [s"\(a)", s"\(b)"]);
  }
  if ev.reason == 4 {
    let war = CBWarBook.Get(game);
    if CBCommonEnemyOn() && IsDefined(war) {
      let now = CBGameSeconds(game);
      war.SetTruce(ev.a, ev.b, now + CBConfig.SecondsPerDay());
      line = CBTf(n"Cyberbane-StreetEvents-AndCameOutOfItWith", [s"\(a)", s"\(b)"]);
    }
  }
  if CBMessagesOn() {
    CBHearsayFromStreet(game, line, n"");
  }
}

// The same from what is kept of it, for a place the map remembers (UI/MapPins.reds, 2.5.0).
public func CBEventCaptionOf(kind: CName, gangA: CName, gangB: CName) -> String {
  let a = CBCapFirst(CBFactionLabel(gangA));
  if Equals(kind, CBEvSitDown()) { return CBTf(n"Cyberbane-RivalEncounter-And", [a, CBFactionLabel(gangB)]); }
  if Equals(kind, CBEvFuneral()) { return CBTf(n"Cyberbane-StreetEvents-AFuneral", [a]); }
  if Equals(kind, CBEvCelebration()) { return CBTf(n"Cyberbane-StreetEvents-Celebrating", [a]); }
  if Equals(kind, CBEvInitiation()) { return CBTf(n"Cyberbane-StreetEvents-AnInitiation", [a]); }
  if Equals(kind, CBEvRecruitment()) { return CBTf(n"Cyberbane-StreetEvents-Recruiting", [a]); }
  if Equals(kind, CBEvArmsDeal()) { return CBTf(n"Cyberbane-StreetEvents-AndGuns", [a, CBFactionLabel(gangB)]); }
  if Equals(kind, CBEvExecution()) { return CBTf(n"Cyberbane-StreetEvents-AnExecution", [a]); }
  if Equals(kind, CBEvFrontLine()) { return CBTf(n"Cyberbane-StreetEvents-Against", [a, CBFactionLabel(gangB)]); }
  if Equals(kind, CBEvFugitive()) { return CBTf(n"Cyberbane-StreetEvents-AHunt", [a]); }
  return CBTf(n"Cyberbane-StreetEvents-ARacket", [a]);
}

// Word of what's coming ([32]): what, who, and when.
public func CBEventWordLine(ev: ref<CBStreetEvent>) -> String {
  let a = CBCapFirst(CBFactionLabel(ev.a));
  let when = CBWhenWord(GetGameInstance(), ev.from);
  let where = CBEventWhere(ev);
  let past = StrLen(ev.placeName) > 0 ? CBTf(n"Cyberbane-StreetEvents-Past", [ev.placeName]) : CBT(n"Cyberbane-StreetEvents-PastHere");
  if Equals(ev.kind, CBEvSitDown()) {
    return CBTf(n"Cyberbane-StreetEvents-AndAreSittingDownAroundCrash", [s"\(a)", s"\(CBFactionLabel(ev.b))", s"\(where)", s"\(when)", s"\(CBMeetReasonWords(ev))"]);
  }
  if Equals(ev.kind, CBEvFuneral()) {
    // "The one you put down" only when V did (2.6.0): a funeral is also owed for one of theirs killed by somebody else, a
    // Rival another Rival finished off screen, or one of V's own crew who came from them.
    let whose = ev.byV ? CBT(n"Cyberbane-StreetEvents-TheOneYouPutDown") : "";
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AreBuryingOneOfTheirsAround", [s"\(a)", s"\(where)", s"\(when)", s"\(whose)"]),
                     CBTf(n"Cyberbane-StreetEvents-FuneralForOneOfGoPay", [s"\(CBFactionLabel(ev.a))", s"\(where)", s"\(when)"])]);
  }
  if Equals(ev.kind, CBEvCelebration()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AreCelebratingAroundTheyTookSome", [s"\(a)", s"\(where)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-PartyAreDrinkingToAWin", [s"\(where)", s"\(when)", s"\(a)"])]);
  }
  if Equals(ev.kind, CBEvInitiation()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AreBloodingNewRecruitsAroundSomebody", [s"\(a)", s"\(where)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-InitiationWantTheirNewKidsTo", [s"\(where)", s"\(when)", s"\(a)"])]);
  }
  if Equals(ev.kind, CBEvRecruitment()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AreSigningUpNewBloodAround", [s"\(a)", s"\(where)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-RecruitingDriveWantBodies", [s"\(where)", s"\(when)", s"\(a)"])]);
  }
  if Equals(ev.kind, CBEvArmsDeal()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AreBuyingGunsFromAroundCrash", [s"\(a)", s"\(CBFactionLabel(ev.b))", s"\(where)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-ArmsDealAndHeavyCratesLight", [s"\(where)", s"\(when)", s"\(a)", s"\(CBFactionLabel(ev.b))"])]);
  }
  if Equals(ev.kind, CBEvExecution()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-CaughtOneOfAndThePoor", [s"\(a)", s"\(CBFactionLabel(ev.b))", s"\(where)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-ExecutionWantEverybodyToWatchOne", [s"\(where)", s"\(when)", s"\(a)", s"\(CBFactionLabel(ev.b))"])]);
  }
  if Equals(ev.kind, CBEvFrontLine()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AndAreGoingToWarOn", [s"\(a)", s"\(CBFactionLabel(ev.b))", s"\(where)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-StreetFightAgainstPickASide", [s"\(where)", s"\(when)", s"\(a)", s"\(CBFactionLabel(ev.b))"])]);
  }
  if Equals(ev.kind, CBEvFugitive()) {
    return CBLineOf([CBTf(n"Cyberbane-StreetEvents-AreHuntingSomebodyOfWhoCrossed", [s"\(a)", s"\(CBFactionLabel(ev.b))", s"\(past)", s"\(when)"]),
                     CBTf(n"Cyberbane-StreetEvents-SomebodySRunningFromHelpThe", [s"\(a)", s"\(where)", s"\(when)"])]);
  }
  return CBLineOf([CBTf(n"Cyberbane-StreetEvents-WordIsRunARacketCollecting", [s"\(a)", s"\(where)", s"\(when)"]),
                   CBTf(n"Cyberbane-StreetEvents-CollectTheirTakeAroundNobodyS", [s"\(a)", s"\(where)", s"\(when)"])]);
}

// A line for an overheard conversation while an event is coming and V is in its district ([32]).
public func CBEventWhisper(game: GameInstance) -> String {
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(ev) || ev.placed || !IsDefined(sys) || NotEquals(ev.district, sys.GetCurrentDistrict())
     || Equals(ev.kind, CBEvAmbush()) {
    return "";
  }
  let a = CBFactionLabel(ev.a);
  if Equals(ev.kind, CBEvFuneral()) { return CBTf(n"Cyberbane-StreetEvents-YouHearAreBuryingOneOf", [a]); }
  if Equals(ev.kind, CBEvCelebration()) { return CBTf(n"Cyberbane-StreetEvents-StayOffThatBlockLaterAre", [CBCapFirst(a)]); }
  if Equals(ev.kind, CBEvInitiation()) { return CBTf(n"Cyberbane-StreetEvents-SomeKidSGettingJumpedInto", [a]); }
  if Equals(ev.kind, CBEvRecruitment()) { return CBTf(n"Cyberbane-StreetEvents-AreLookingForNewBloodMy", [CBCapFirst(a)]); }
  if Equals(ev.kind, CBEvArmsDeal()) { return CBTf(n"Cyberbane-StreetEvents-CratesCameInOffATruck", [a]); }
  if Equals(ev.kind, CBEvRacket()) { return CBTf(n"Cyberbane-StreetEvents-DonTGoNearCollectionSpot", [CBPossessive(a)]); }
  if Equals(ev.kind, CBEvExecution()) { return CBTf(n"Cyberbane-StreetEvents-AreExecutingSomebodyLaterInThe", [CBCapFirst(a)]); }
  if Equals(ev.kind, CBEvFrontLine()) { return CBTf(n"Cyberbane-StreetEvents-StayHomeLaterAndAreGoing", [CBCapFirst(a), CBFactionLabel(ev.b)]); }
  if Equals(ev.kind, CBEvFugitive()) { return CBTf(n"Cyberbane-StreetEvents-SomebodyCrossedTheyReRunningThe", [a]); }
  return CBTf(n"Cyberbane-StreetEvents-HeardAndAreMeetingCouldGo", [a, CBFactionLabel(ev.b)]);
}

// ---- Outcomes ------------------------------------------------------------------------------------------

// V broke it up.
public func CBEventCrashed(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  // The map remembers where (UI/MapPins.reds, 2.5.0); not an ambush, which nobody else knew was there.
  if !Equals(ev.kind, CBEvAmbush()) {
    CBMapRemember(sys, game, CBMemEventCrashed(), ev.at, 0, ev.a, ev.b, ev.kind, true);
  }
  if Equals(ev.kind, CBEvAmbush()) {
    CBFileLog(sys, n"AmbushBeaten", CBGameSeconds(game), CBEventDistrict(sys, game), ev.a, 0.0);
    CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-WereWaitingForYouOnThe", [s"\(CBCapFirst(CBFactionLabel(ev.a)))"]));
    return;
  }
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
    // Who walks out angrier, by what it was about (2.6.5).
    let angrier = CBMeetCrashAngrier(sys, game, ev);
    if NotEquals(angrier, n"") {
      CBTalkSlight(sys, game, angrier, CBConfig.MeetReasonAnger());
    }
    if CBMessagesOn() {
      CBHearsayFromStreet(game, NotEquals(angrier, n"")
        ? CBTf(n"Cyberbane-StreetEvents-YouCrashedTheSitDownBetween", [s"\(a)", s"\(CBFactionLabel(ev.b))", s"\(CBCapFirst(CBFactionLabel(angrier)))"])
        : CBTf(n"Cyberbane-StreetEvents-YouCrashedTheSitDownBetween-2", [s"\(a)", s"\(CBFactionLabel(ev.b))"]), n"");
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
    CBEventSay(game, CBLineOf([CBTf(n"Cyberbane-StreetEvents-YouShotUpAFuneralWill", [s"\(CBCapFirst(a))"]),
                               CBTf(n"Cyberbane-StreetEvents-YouHitFuneralEvenPeopleWho", [s"\(CBPossessive(a))"])]));
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
    CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-YouTookTheGunsWereBuying", [s"\(a)"]));
    return;
  }
  if Equals(ev.kind, CBEvRacket()) {
    let take = CBConfig.RacketTakeBase() + RandRange(0, CBConfig.RacketTakeBase() + 1);
    CBStreetGiveMoney(game, take);
    CBWarSpend(game, ev.a, Cast<Float>(take) * CBConfig.BagmanChestShare());
    CBTalkSlight(sys, game, ev.a, CBConfig.BagmanStandingLoss());
    CBFileLog(sys, n"RacketHit", now, where, ev.a, Cast<Float>(take));
    CBSystemNote(game, CBTf(n"Cyberbane-StreetEvents-YouTookTheirTakeEb", [s"\(take)"]), 5.0);
    CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-YouHitRacketWordIsThey", [s"\(CBPossessive(a))"]));
    return;
  }
  if Equals(ev.kind, CBEvInitiation()) {
    sys.AddCode(CBConfig.InitiationStopCode());
  }
  CBFileLog(sys, n"EventCrashed", now, where, ev.a, 0.0);
  CBEventSay(game, CBLineOf([CBTf(n"Cyberbane-StreetEvents-YouBrokeUpTheyFeltThat", [s"\(CBPossessive(a))", s"\(CBEventNoun(ev.kind))"]),
                             CBTf(n"Cyberbane-StreetEvents-WhateverHadPlannedNearThereYou", [s"\(a)"])]));
}

// The window closed without V: the gang had what it came for.
public func CBEventMissed(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  let a = CBFactionLabel(ev.a);
  if Equals(ev.kind, CBEvAmbush()) {
    return;   // they gave up waiting; nobody tells V about an ambush that never sprang
  }
  if CBIsFightKind(ev.kind) {
    if ev.placed {
      CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-WhateverStartedNearThereItFizzled", [s"\(a)"]));
    }
    return;
  }
  // V was watching the place and its people could never be put in the world unseen: they saw V first and took it
  // somewhere else, which is what V saw happen (2.7.2).
  if ev.watched && !ev.placed {
    CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-SpottedYouWatching", [s"\(CBCapFirst(a))"]));
  }
  if Equals(ev.kind, CBEvSitDown()) {
    CBMeetSettled(sys, game, ev);   // what the deal was, and what came of it (2.6.5)
    return;
  }
  if Equals(ev.kind, CBEvFuneral()) {
    if !ev.approached {
      CBEventSay(game, ev.byV ? CBTf(n"Cyberbane-StreetEvents-BuriedTheirDeadTheySaidYour", [s"\(CBCapFirst(a))"])
                              : CBTf(n"Cyberbane-StreetEvents-BuriedTheirDeadQuietlyAndAmong", [s"\(CBCapFirst(a))"]));
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
  CBEventSay(game, CBLineOf([CBTf(n"Cyberbane-StreetEvents-GotTheirDoneTheyReStronger", [s"\(CBCapFirst(a))", s"\(CBEventNoun(ev.kind))"]),
                             CBTf(n"Cyberbane-StreetEvents-NobodyStoppedThereAreMoreOf", [s"\(CBPossessive(a))", s"\(CBEventNoun(ev.kind))"])]));
}

func CBEventNoun(kind: CName) -> String {
  if Equals(kind, CBEvCelebration()) { return CBT(n"Cyberbane-StreetEvents-Party"); }
  if Equals(kind, CBEvInitiation()) { return CBT(n"Cyberbane-StreetEvents-Initiation"); }
  if Equals(kind, CBEvRecruitment()) { return CBT(n"Cyberbane-CrewBanner-Recruiting"); }
  if Equals(kind, CBEvArmsDeal()) { return CBT(n"Cyberbane-StreetEvents-Deal"); }
  if Equals(kind, CBEvRacket()) { return CBT(n"Cyberbane-StreetEvents-Collection"); }
  return CBT(n"Cyberbane-StreetEvents-Business");
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
  if !IsDefined(ev) || !ev.placed || !IsDefined(t.npc) || !IsDefined(des) || !des.IsTagged(t.npc.GetEntityID(), n"CB_Event") {
    return out;
  }
  // A front line squaring up (2.6.1): either side will take a gun on their side.
  if Equals(ev.kind, CBEvFrontLine()) && !ev.started && ev.vSide == 0 && CBEventSideOf(ev, t.npc) >= 0 {
    let side = CBTalkMakeLine(CBT(n"Cyberbane-StreetEvents-SideIMWithYou"), CBTalkActStandWith(), t"ChoiceCaptionParts.ReinforcementIcon");
    side.important = true;
    ArrayPush(out, side);
    return out;
  }
  if ev.approached || !Equals(ev.kind, CBEvFuneral()) {
    return out;
  }
  let l = CBTalkMakeLine(CBT(n"Cyberbane-StreetEvents-RespectsIMSorryForYour"), CBTalkActRespects(), t"ChoiceCaptionParts.HandshakeIcon");
  l.important = true;
  ArrayPush(out, l);
  return out;
}

public func CBEventTalkAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  if !IsDefined(ev) || ev.approached {
    return CBTalkSay(CBT(n"Cyberbane-StreetEvents-YouAlreadySaidYourPiece"), n"");
  }
  ev.approached = true;
  CBCreditMercy(sys, ev.a, CBConfig.RespectsStanding());
  sys.AddCode(CBConfig.RespectsCode());
  CBFileLog(sys, n"PaidRespects", CBGameSeconds(game), CBEventDistrict(sys, game), ev.a, 0.0);
  // Nerve only when it was V who put them in the ground (2.6.0).
  if !ev.byV {
    return CBTalkSay(CBLineOf([CBT(n"Cyberbane-StreetEvents-DidnTExpectYouHereThanks"),
                               CBT(n"Cyberbane-StreetEvents-YouDidnTHaveToCome"),
                               CBT(n"Cyberbane-StreetEvents-KindOfYouSayYourPiece")]), n"");
  }
  return CBTalkSay(CBLineOf([CBT(n"Cyberbane-StreetEvents-YouVeGotSomeNerveBut"),
                             CBT(n"Cyberbane-StreetEvents-TheyDHaveSpatAtYou"),
                             CBT(n"Cyberbane-StreetEvents-ComingHereTookGutsSayWhat")]), n"");
}

// Has V hurt any of this event's people?
public func CBEventHurtByV(game: GameInstance, ev: ref<CBStreetEvent>) -> Bool {
  for id in ev.ids {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.cbDamagedByPlayer {
      return true;
    }
  }
  return false;
}

// Which side of this event somebody is on, 0 or 1, or -1 for somebody who is not one of its people.
public func CBEventSideOf(ev: ref<CBStreetEvent>, p: wref<ScriptedPuppet>) -> Int32 {
  if !IsDefined(ev) || !IsDefined(p) {
    return -1;
  }
  let id = p.GetEntityID();
  let i = 0;
  while i < ArraySize(ev.ids) {
    if Equals(ev.ids[i], id) {
      return ev.SideOf(i);
    }
    i += 1;
  }
  return -1;
}

// V picks a side at a front line (2.6.1): that side takes V as one of theirs, the other turns on V, and it starts.
public func CBEventStandWith(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let life = CBStreetLifeFor(game);
  let ev = IsDefined(life) ? life.Events().Live() : null;
  let side = CBEventSideOf(ev, t.npc);
  let player = GetPlayer(game);
  if !IsDefined(ev) || ev.started || ev.vSide > 0 || side < 0 || !IsDefined(player) {
    return CBTalkSay(CBT(n"Cyberbane-StreetEvents-TooLateForThatFindCover"), n"");
  }
  ev.vSide = side + 1;
  let pagent = player.GetAttitudeAgent();
  let i = 0;
  while i < ArraySize(ev.ids) {
    let p = GameInstance.FindEntityByID(game, ev.ids[i]) as ScriptedPuppet;
    if CBNpcSafe(sys, p) && CBStillStanding(p) {
      if ev.SideOf(i) == side {
        let agent = p.GetAttitudeAgent();
        if IsDefined(agent) && IsDefined(pagent) {
          CBTrace("attitude: a front line's side takes V in");
          agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Friendly);
        }
        CBCalmTowardCompanions(sys, p);
      } else {
        CBMakeHostileToPlayer(game, p);
      }
    }
    i += 1;
  }
  let mine = side == 0 ? ev.a : ev.b;
  let theirs = side == 0 ? ev.b : ev.a;
  CBLog.Info(n"Street", s"V stood with \(NameToString(mine)) at a front line against \(NameToString(theirs)).");
  return CBTalkSay(CBLineOf([CBTf(n"Cyberbane-StreetEvents-ThenStayCloseAreAboutTo", [s"\(CBCapFirst(CBFactionLabel(theirs)))"]),
                             CBT(n"Cyberbane-StreetEvents-GoodWeHitThemNowDon"),
                             CBTf(n"Cyberbane-StreetEvents-WithYouOnOurSideAre", [s"\(CBCapFirst(CBFactionLabel(theirs)))"])]), n"");
}

// A gang owes a funeral (a Rival of theirs slain, or a boss) or a celebration (a district taken). From the death
// handler and the turf book's change of hands.
// `byV`: the one they bury is somebody V put down, which is what the street then says.
public func CBOweFuneral(game: GameInstance, gang: CName, opt byV: Bool) -> Void {
  let life = CBStreetLifeFor(game);
  if IsDefined(life) && CBGatheringsOn() {
    life.Events().OweFuneral(gang, CBGameSeconds(game), byV);
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
  // A front line squares up first (2.6.1): time for V to walk up and pick a side (CBEventStandWith).
  if Equals(kind, CBEvFrontLine()) { return CBConfig.FrontLineStandoffTicks(); }
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
  CBSetPairAttitude(sys, a, b, EAIAttitude.AIA_Hostile);
}

// Two people set to this attitude towards each other, behind the NPC gate. True when it was set.
func CBSetPairAttitude(sys: ref<CyberbaneSystem>, a: ref<ScriptedPuppet>, b: ref<ScriptedPuppet>, att: EAIAttitude) -> Bool {
  if !CBNpcSafe(sys, a) || !CBNpcSafe(sys, b) || !CBStillStanding(a) || !CBStillStanding(b) {
    return false;
  }
  let aa = a.GetAttitudeAgent();
  let ba = b.GetAttitudeAgent();
  if !IsDefined(aa) || !IsDefined(ba) {
    return false;
  }
  CBTrace(Equals(att, EAIAttitude.AIA_Hostile) ? "attitude: two gangs' people set against each other"
                                               : "attitude: two gangs' people keep the peace");
  aa.SetAttitudeTowards(ba, att);
  ba.SetAttitudeTowards(aa, att);
  return true;
}

// The two sides of a meeting, neutral to each other. True once every pair of them has been set.
func CBCalmSides(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Bool {
  let all = true;
  let i = 0;
  while i < ArraySize(ev.ids) {
    let pa = GameInstance.FindEntityByID(game, ev.ids[i]) as ScriptedPuppet;
    let j = i + 1;
    while j < ArraySize(ev.ids) {
      if ev.SideOf(i) != ev.SideOf(j) {
        let pb = GameInstance.FindEntityByID(game, ev.ids[j]) as ScriptedPuppet;
        if !CBSetPairAttitude(sys, pa, pb, EAIAttitude.AIA_Neutral) {
          all = false;
        }
      }
      j += 1;
    }
    i += 1;
  }
  return all;
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

// The same, at a walk: somebody arriving at a meeting or a front line (2.6.3).
func CBEventWalkTo(p: ref<ScriptedPuppet>, to: Vector4) -> Void {
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
  cmd.movementType = moveMovementType.Walk;
  cmd.ignoreInCombat = false;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 1.5;
  CBIssueMove(p, ai, cmd);
}

@addField(ScriptedPuppet)
public let cbEventWalked: Bool;

// Whoever was placed further out walks to their spot, once, as soon as they are standing in the world (2.6.3): the move
// order is the one order they get, and never while the fight they came for is on.
func CBEventWalkIns(game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  if ev.started {
    return;
  }
  let n = Min(ArraySize(ev.ids), ArraySize(ev.walkAt));
  let i = 0;
  while i < n {
    let to = ev.walkAt[i];
    if to.W > 0.0 {
      let p = GameInstance.FindEntityByID(game, ev.ids[i]) as ScriptedPuppet;
      if CBStillStanding(p) && !p.cbEventWalked && !CBNpcInCombat(p) {
        p.cbEventWalked = true;
        CBEventWalkTo(p, to);
      }
    }
    i += 1;
  }
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
        CBEventSay(game, hunt ? CBTf(n"Cyberbane-StreetEvents-YouPutDownTheOneWere", [s"\(a)"]) : CBTf(n"Cyberbane-StreetEvents-YouDidKillingForThem", [s"\(CBPossessive(a))"]));
        return true;
      }
      CBBolsterGang(sys, game, ev.a, CBConfig.EventBolster());
      CBTalkFear(sys, game, ev.b, CBConfig.WordKeptFear());
      CBFileLog(sys, hunt ? n"FugitiveCaught" : n"Executed", now, where, ev.a, 0.0);
      if ev.informant {
        CBInformantHuntOver(sys, game, ev.a, ev.informantRival, false);
      }
      CBEventSay(game, hunt ? CBTf(n"Cyberbane-StreetEvents-RanDownTheOneTheyWere", [s"\(CBCapFirst(a))"]) : CBTf(n"Cyberbane-StreetEvents-ExecutedOneOfEverybodySaw", [s"\(CBCapFirst(a))", s"\(b)"]));
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
      if ev.informant {
        CBInformantHuntOver(sys, game, ev.a, ev.informantRival, true);
      }
      CBEventSay(game, hunt ? CBTf(n"Cyberbane-StreetEvents-YouStoodBetweenAndTheOne", [s"\(a)", s"\(CBCapFirst(b))"]) : CBTf(n"Cyberbane-StreetEvents-YouStoppedExecutionWonTForget", [s"\(CBPossessive(a))", s"\(CBCapFirst(b))"]));
      return true;
    }
    if aUp == 0 {
      // Their own fight, won by the one they meant to kill: nothing of V's in it.
      CBEventSay(game, hunt ? CBTf(n"Cyberbane-StreetEvents-TheOneWereHuntingFoughtThem", [s"\(a)"]) : CBTf(n"Cyberbane-StreetEvents-PrisonerTurnedTheTablesOnThem", [s"\(CBPossessive(CBCapFirst(a)))"]));
      return true;
    }
    if hunt && IsDefined(lone) && CBStillStanding(lone) && Vector4.Distance(lone.GetWorldPosition(), ev.at) > CBConfig.FugitiveEscapeDistance() {
      CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-TheOneWereHuntingGotAway", [s"\(a)"]));
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
    // V stood with one side (2.6.1): they remember it, and so does the other.
    if ev.vSide > 0 {
      let mine = ev.vSide == 1 ? ev.a : ev.b;
      if Equals(mine, winner) {
        let pay = CBConfig.FrontLineSidePay();
        CBStreetGiveMoney(game, pay);
        CBTalkWarm(sys, game, mine, CBConfig.FrontLineSideWarmth(), CBConfig.PostureAllied() + 1.0);
        CBTalkSlight(sys, game, loser, CBConfig.FrontLineSideCost());
        CBFileLog(sys, n"StoodWith", now, where, mine, Cast<Float>(pay));
        CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-YouStoodWithAndTheStreet", [s"\(CBFactionLabel(mine))", s"\(pay)"]));
      } else {
        CBTalkSlight(sys, game, winner, CBConfig.FrontLineSideCost());
        CBFileLog(sys, n"StoodWithLost", now, where, mine, 0.0);
        CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-YouStoodWithAndTheyLost", [s"\(CBFactionLabel(mine))", s"\(CBCapFirst(CBFactionLabel(winner)))"]));
      }
      return true;
    }
    CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-WonTheStreetFightAgainstThe", [s"\(CBCapFirst(CBFactionLabel(winner)))", s"\(CBFactionLabel(loser))"]));
    return true;
  }
  return false;
}

// The one V saved says so, in a subtitle.
func CBEventLoneThanks(game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  if !CBMessagesOn() {
    return;
  }
  CBOverheard(game, CBWhisperSpeaker(ev.b), CBLineOf([CBT(n"Cyberbane-StreetEvents-IOweYouIOweYou"),
                                                      CBT(n"Cyberbane-StreetEvents-DonTKnowWhyYouDid"),
                                                      CBT(n"Cyberbane-StreetEvents-IWonTForgetThisMy")]));
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
          CBEventSay(game, CBTf(n"Cyberbane-StreetEvents-YouKilledBothOfThemAre", [s"\(CBCapFirst(CBFactionLabel(slain.faction)))"]));
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
          // Whoever the hierarchy had just put in the chair, and the lieutenant's place the winner left, are
          // filled again (2.4.2): the one bumped from the chair was left holding no place at all.
          CBHierarchyFill(sys, slain.faction);
        }
        if !CBReputationFrozen() {
          fs.standing = ClampF(fs.standing + CBConfig.StruggleBackStanding(), -100.0, 100.0);
        }
        book.Won(w.id);
        CBFileLog(sys, n"StruggleBacked", now, CBEventDistrict(sys, game), slain.faction, 0.0);
        if CBMessagesOn() {
          CBPhoneSendAside(game, CBRivalDisplayName(content, w), CBTf(n"Cyberbane-StreetEvents-TheChairSMineYouMade", [CBCapFirst(CBFactionLabel(slain.faction))]), CBHudCyan());
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
    // Offers, not threats (2.5.6): nothing to answer by text; killing the other one is the answer.
    CBPhoneSendAside(game, heirName, CBTf(n"Cyberbane-StreetEvents-IRunNowDoesnTThink", [s"\(CBFactionLabel(slain.faction))", s"\(rivalName)"]), CBHudCyan());
    CBPhoneSendAside(game, rivalName, CBTf(n"Cyberbane-StreetEvents-TookAChairThatShouldBe", [s"\(heirName)", s"\(CBFactionLabel(slain.faction))"]), CBHudCyan());
  }
}

func CBRivalStillAround(r: ref<CBRival>) -> Bool {
  return IsDefined(r) && r.state != EnumInt(ECBRivalState.Slain) && r.state != EnumInt(ECBRivalState.Retired);
}

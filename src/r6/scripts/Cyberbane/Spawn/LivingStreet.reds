// Cyberbane - A living street (2.0.0)
//
// The city does things on its own that V can step into:
//
//   Bagmen        now and then a gang's bagman walks the week's take across its turf near V, with one
//                 lookout. Rob them (put the bagman down) and the eddies are V's; the gang takes the loss.
//   Favours       a friendly or wary ganger asked "Need anything done?" gives V a small job: run off a lookout
//                 of a gang at war with theirs, or lean on somebody who owes them. Done, they pay, warm to V
//                 and sometimes pass on a lead.
//   The sit-down  two gangs at war meet at a place and an hour V hears about. Crash it and both lose.
//   While you were out   a little after a load, one line: the latest thing that mattered.
//   Surrender     (experimental, off) a beaten ganger may give up instead of running: hands up, not
//                 fighting. Walk away and they go; grab them and they talk; shoot them and the street hears.
//   "Nobody kills you but me"   (experimental, off) outnumbered by one gang, V may be helped by a Rival
//                 with a claim on them, who walks off afterwards with a promise.
//
// Placement is CBSpawnGroup or, at a named place, CBCreateSpawn on a spot V cannot see; one order per
// person through CBIssueMove; removal through CBDeleteTaggedSafe, never in V's sight. Session state only:
// a load ends whatever was going on, the way it ends a fight.

public func CBStreetLifeOn(flag: CName) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  if !rt.HasSettings() {
    return !Equals(flag, n"surrender") && !Equals(flag, n"claimHelp");
  }
  let s = rt.GetSettings();
  if Equals(flag, n"bagmen") { return s.bagmen; }
  if Equals(flag, n"favours") { return s.favours; }
  if Equals(flag, n"sitDowns") { return s.sitDowns; }
  if Equals(flag, n"whileOut") { return s.whileOut; }
  if Equals(flag, n"surrender") { return s.surrender; }
  if Equals(flag, n"claimHelp") { return s.claimHelp; }
  return false;
}

public func CBTalkActFavour() -> Int32 = 30

@addField(ScriptedPuppet)
public let cbFavourMark: Bool;

@addField(ScriptedPuppet)
public let cbSurrendered: Bool;

// Set up a moment after attaching, like everybody else of ours (Spawn/Spawner.reds, CBApplySpawnSetup).
// A favour's lookout is hostile; a bagman, their lookout and the people at a sit-down leave V be unless their
// gang is at war with V.
public func CBSetUpStreet(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, hostile: Bool) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(player) || !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(CBClassifyFaction(puppet)) : ECBPosture.Neutral;
  if hostile || Equals(posture, ECBPosture.Vendetta) {
    CBGrantAbility(puppet as NPCPuppet, t"Ability.IsAggressive");
    CBMakeHostileToPlayer(game, puppet);
  } else {
    let agent = puppet.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if IsDefined(agent) && IsDefined(pagent) {
      if !IsNameValid(agent.GetAttitudeGroup()) {
        let group = CBRecordAttitudeGroup(puppet.GetRecordID());
        if IsNameValid(group) {
          agent.SetAttitudeGroupUnsavable(group);
        }
      }
      agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
    }
  }
  CBTrackOnMap(game, puppet);
}

// Somebody with a claim on V, come to help: V's friend for now, the enemy's enemy.
public func CBSetUpAlly(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  let life = CBStreetLifeFor(game);
  if !IsDefined(player) || !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() || !IsDefined(life) {
    return;
  }
  let agent = puppet.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if !IsDefined(agent) || !IsDefined(pagent) {
    return;
  }
  if !IsNameValid(agent.GetAttitudeGroup()) {
    let group = CBRecordAttitudeGroup(puppet.GetRecordID());
    if IsNameValid(group) {
      agent.SetAttitudeGroupUnsavable(group);
    }
  }
  agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Friendly);
  life.TurnOnEnemy(sys, game, puppet);
}

public func CBStreetLifeFor(game: GameInstance) -> ref<CBStreetLife> {
  let sys = CyberbaneSystem.Get(game);
  let talk = IsDefined(sys) ? sys.GetStreetTalk() : null;
  return IsDefined(talk) ? talk.GetLife() : null;
}

func CBStreetGiveMoney(game: GameInstance, amount: Int32) -> Void {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if IsDefined(player) && IsDefined(ts) && amount > 0 {
    ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  }
}

func CBClockWord(gameSeconds: Float) -> String {
  let h = (Cast<Int32>(gameSeconds / 3600.0)) % 24;
  return h < 10 ? s"0\(h):00" : s"\(h):00";
}

public class CBStreetLife {
  // The bagman.
  private let m_bagFaction: CName;
  private let m_bagBody: EntityID;
  private let m_bagTick: Int32;
  private let m_bagNext: Int32;
  private let m_bagDone: Bool;
  // A favour.
  private let m_favFaction: CName;
  private let m_favKind: Int32;        // 1 a lookout to run off, 2 somebody to lean on
  private let m_favTarget: wref<ScriptedPuppet>;
  private let m_favBody: EntityID;
  private let m_favUntil: Int32;
  private let m_favLeaned: Bool;
  // The sit-down.
  private let m_meetA: CName;
  private let m_meetB: CName;
  private let m_meetAt: Vector4;
  private let m_meetFrom: Float;       // game seconds
  private let m_meetPin: NewMappinID;
  private let m_meetPinned: Bool;
  private let m_meetSpawned: Bool;
  private let m_meetIds: array<EntityID>;
  private let m_meetNext: Int32;
  // While you were out.
  private let m_toldOut: Bool;
  private let m_settled: Int32;
  // Surrendered people, and when they gave up.
  private let m_gaveUp: array<wref<ScriptedPuppet>>;
  private let m_gaveUpTick: array<Int32>;
  // The Rival with a claim on V.
  private let m_allyOut: Bool;
  private let m_allyEnemy: CName;
  private let m_allyCalm: Int32;
  private let m_allyDay: Int32;

  public func Tick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let player = GetPlayer(game);
    let des = GameInstance.GetDynamicEntitySystem();
    if !IsDefined(sys) || !IsDefined(player) || !IsDefined(des) || !CBWorldStable(game) {
      return;
    }
    let now = sys.GetTickCount();
    // V got somewhere safe: whoever of the street's people is fighting V loses V at the door, the way the
    // people sent after V do (Spawn/Sanctuary.reds). The hunt holds only its own, and patrols hold theirs.
    if sys.IsInSanctuary() {
      for tag in CBStreetTags() {
        CBSanctuaryHoldTag(sys, game, des, player, tag, false, true);
      }
    }
    let busy = sys.GetStoryHold() != CBStoryNone() || sys.IsInQuestArea() || sys.IsOnJob() || sys.IsInSanctuary()
            || sys.IsInSafeZone() || CBPlayerInScene(game);
    this.WhileOut(sys, game, player, busy);
    this.Bagman(sys, game, des, player, now, busy);
    this.Favour(sys, game, des, player, now);
    this.SitDown(sys, game, des, player, busy);
    this.Surrenders(sys, game, player, now);
    this.Claim(sys, game, des, player, now, busy);
  }

  // Start over (CyberbaneSystem.HardReset): whatever the street had going belonged to the old playthrough.
  // The people themselves go with everything else of ours; this lets go of what they were part of - the
  // favour and its marker, the sit-down and its pin - and of anybody still held with their hands up.
  public func Reset(game: GameInstance) -> Void {
    this.m_bagFaction = n"";
    this.m_bagDone = false;
    this.FavourEnd(game);
    this.m_favLeaned = false;
    this.EndMeet(game);
    let i = 0;
    while i < ArraySize(this.m_gaveUp) {
      let p = this.m_gaveUp[i];
      if IsDefined(p) && p.IsAttached() && !p.IsDead() {
        CBTalkReleaseHold(p);
        CBOrderFlee(game, p);
        p.cbSurrendered = false;
      }
      i += 1;
    }
    ArrayClear(this.m_gaveUp);
    ArrayClear(this.m_gaveUpTick);
    this.m_allyOut = false;
    this.m_allyEnemy = n"";
    this.m_allyCalm = 0;
  }

  // ---- While you were out ---------------------------------------------------------------------------------

  private func WhileOut(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, busy: Bool) -> Void {
    if this.m_toldOut {
      return;
    }
    if busy || player.IsInCombat() || !CBStreetLifeOn(n"whileOut") {
      this.m_settled = 0;
      return;
    }
    this.m_settled += 1;
    if this.m_settled < CBConfig.WhileOutDelayTicks() {
      return;
    }
    this.m_toldOut = true;
    let log = sys.GetLog();
    let now = CBGameSeconds(game);
    let i = ArraySize(log) - 1;
    while i >= 0 && i >= ArraySize(log) - 40 {
      let e = log[i];
      i -= 1;
      if IsDefined(e) && now - e.at <= CBConfig.SecondsPerDay() && CBWhileOutWorthIt(e.kind) {
        CBSystemNote(game, "Last you heard: " + CBHudLogLine(sys, e, now), 9.0);
        return;
      }
    }
  }

  // ---- Bagmen ----------------------------------------------------------------------------------------------

  private func Bagman(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>,
                      now: Int32, busy: Bool) -> Void {
    if NotEquals(this.m_bagFaction, n"") {
      let p = GameInstance.FindEntityByID(game, this.m_bagBody) as ScriptedPuppet;
      if !this.m_bagDone && IsDefined(p) && p.cbDamagedByPlayer && (p.IsDead() || !CBStillStanding(p)) {
        this.m_bagDone = true;
        this.Robbed(sys, game);
      }
      let age = now - this.m_bagTick;
      if age == 4 {
        CBPatrolWalk(sys, game, des, player, n"CB_Bagman");
      }
      let near = IsDefined(p) && Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition()) <= CBConfig.TurfPatrolLeaveDistance();
      if age >= CBConfig.BagmanLifeTicks() || (age > 10 && !near && !des.IsSpawning(this.m_bagBody)) || !CBStreetLifeOn(n"bagmen") {
        CBDeleteTaggedSafe(game, n"CB_Bagman", true, true);
        this.m_bagFaction = n"";
      }
      return;
    }
    if busy || now < this.m_bagNext || !CBStreetLifeOn(n"bagmen") || player.IsInCombat() || IsDefined(player.GetMountedVehicle())
       || CBPlayerIndoors(game) || CBHuntersOut(sys, game) || CBHuntPending(sys) {
      return;
    }
    this.m_bagNext = now + CBJitter(CBConfig.BagmanGapTicks(), 0.4);
    if RandF() >= CBConfig.BagmanChance() {
      return;
    }
    let holder = CBTurfHolder(sys, game, sys.GetCurrentDistrict());
    let fs = sys.FindFaction(holder);
    if Equals(holder, n"") || !IsDefined(fs) || !CBFactionFieldsSquads(holder) || !TDBID.IsValid(fs.sampleRecord)
       || CBSpawnRoom(game) < 2 + CBConfig.TurfPatrolKeepRoom() {
      return;
    }
    let body: EntityID;
    if CBSpawnGroup(game, fs.sampleRecord, n"", 2, n"CB_Bagman", CBConfig.TurfPatrolDistance(), body) > 0 {
      this.m_bagFaction = holder;
      this.m_bagBody = body;
      this.m_bagTick = now;
      this.m_bagDone = false;
      if CBMessagesOn() {
        CBHearsayFromDistrict(game, sys.GetCurrentDistrict(),
          s"\(CBCapFirst(CBFactionLabel(holder)))' bagman is doing the rounds near you with the week's take. One lookout. Heavy pockets.", n"");
      }
      CBLog.Info(n"Street", s"A \(NameToString(holder)) bagman is out near V.");
    }
  }

  private func Robbed(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let take = CBConfig.BagmanTakeBase() + RandRange(0, CBConfig.BagmanTakeBase() + 1);
    CBStreetGiveMoney(game, take);
    CBWeakenGang(sys, game, this.m_bagFaction, CBConfig.BagmanGangLoss());
    CBTalkSlight(sys, game, this.m_bagFaction, CBConfig.BagmanStandingLoss());
    let now = CBGameSeconds(game);
    CBFileLog(sys, n"BagmanRobbed", now, CBEventDistrict(sys, game), this.m_bagFaction, Cast<Float>(take));
    CBSystemNote(game, s"you took the bag: \(take)eb.", 5.0);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"Somebody hit \(CBFactionLabel(this.m_bagFaction))' bagman. Word is it was you.", n"");
    }
    CBLog.Info(n"Street", s"V robbed a bagman for \(take)eb.");
  }

  // ---- Favours ---------------------------------------------------------------------------------------------

  public func FavourOpen() -> Bool {
    return NotEquals(this.m_favFaction, n"");
  }

  // Asked in a conversation (Reactions/StreetTalk.reds). Starts one and says what it is, or says no.
  public func OfferFavour(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
    if this.FavourOpen() || !CBStreetLifeOn(n"favours") {
      return CBTalkSay("Not right now. Come back another time.", n"");
    }
    let now = sys.GetTickCount();
    // A lookout of a gang at war with theirs, first.
    let enemies = CBGangRivalsOf(sys.GetContent(), t.faction);
    for g in enemies {
      let fs = sys.FindFaction(g);
      if IsDefined(fs) && CBFactionOn(g) && CBFactionFieldsSquads(g) && TDBID.IsValid(fs.sampleRecord) && RandF() < 0.6
         && CBSpawnRoom(game) > CBConfig.TurfPatrolKeepRoom() {
        let body: EntityID;
        if CBSpawnGroup(game, fs.sampleRecord, n"", 1, n"CB_Favour", CBConfig.FavourDistance(), body) > 0 {
          this.m_favFaction = t.faction;
          this.m_favKind = 1;
          this.m_favBody = body;
          this.m_favUntil = now + CBConfig.FavourLifeTicks();
          CBLog.Info(n"Street", s"A favour for \(NameToString(t.faction)): run off a \(NameToString(g)) lookout.");
          return CBTalkSay(s"One of \(CBFactionLabel(g))' lookouts is watching our corner, a couple of streets over. Run them off. Marked it for you.", n"");
        }
      }
    }
    // Somebody near who owes them.
    let reg = sys.GetRegistry();
    let ppos = player.GetWorldPosition();
    if IsDefined(reg) {
      for p in reg.GetAll() {
        if IsDefined(p) && p.IsCrowd() && p.IsAttached() && !p.IsDead() && p.cbTalkTimes == 0 {
          let d = Vector4.Distance(ppos, p.GetWorldPosition());
          if d >= 15.0 && d <= 60.0 && CBSafetyGate.CanTalkTo(p) {
            p.cbFavourMark = true;
            CBTrackOnMap(game, p);
            this.m_favFaction = t.faction;
            this.m_favKind = 2;
            this.m_favTarget = p;
            this.m_favLeaned = false;
            this.m_favUntil = now + CBConfig.FavourLifeTicks();
            CBLog.Info(n"Street", s"A favour for \(NameToString(t.faction)): lean on somebody who owes them.");
            return CBTalkSay("Somebody round here owes us and keeps forgetting. Remind them. Hard. I marked them for you.", n"");
          }
        }
      }
    }
    return CBTalkSay("Nothing that needs you today. Ask me again sometime.", n"");
  }

  // V leaned on somebody (Reactions/StreetTalk.reds, Intimidate and Antagonize): was it the one who owes?
  public func NoteLeaned(npc: ref<ScriptedPuppet>) -> Void {
    let target = this.m_favTarget;
    if this.m_favKind == 2 && IsDefined(npc) && IsDefined(target) && Equals(npc.GetEntityID(), target.GetEntityID()) {
      this.m_favLeaned = true;
    }
  }

  private func Favour(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>, now: Int32) -> Void {
    if !this.FavourOpen() {
      return;
    }
    let done = false;
    if this.m_favKind == 1 {
      // Run off by V: put down, or broken and running or giving up, after V hurt them. Somebody else
      // putting the lookout down is not V doing the favour, which is the rule the bagman and the
      // sit-down already keep.
      let p = GameInstance.FindEntityByID(game, this.m_favBody) as ScriptedPuppet;
      done = IsDefined(p) && p.cbDamagedByPlayer && (p.IsDead() || !CBStillStanding(p) || p.cbMoraleBroken);
    } else {
      done = this.m_favLeaned;
    }
    if done {
      this.FavourDone(sys, game, player);
      return;
    }
    if now >= this.m_favUntil {
      if CBMessagesOn() {
        CBPhoneFromAlly(game, this.m_favFaction, "Forget it. Somebody else handled it.");
      }
      this.FavourEnd(game);
    }
  }

  private func FavourDone(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let faction = this.m_favFaction;
    let pay = CBConfig.FavourPay() + RandRange(0, CBConfig.FavourPay() / 2 + 1);
    if this.m_favKind == 2 {
      pay += CBConfig.FavourPay() / 2;   // the debt, less their cut
    }
    CBStreetGiveMoney(game, pay);
    CBTalkWarm(sys, game, faction, CBConfig.FavourWarmth(), CBConfig.PostureAllied() - 1.0);
    let tip = "";
    if RandF() < CBConfig.FavourTipChance() {
      let i = CBIntelGive(sys, game, player, faction, true);
      if i.kind != CBIntelNone() {
        tip = " And something extra: " + CBIntelWritten(i);
      }
    }
    CBFileLog(sys, n"Favour", CBGameSeconds(game), CBEventDistrict(sys, game), faction, Cast<Float>(pay));
    if CBMessagesOn() {
      CBPhoneFromAlly(game, faction, s"Saw what you did. \(pay)eb, and you've got friends here.\(tip)");
    }
    CBLog.Info(n"Street", s"A favour for \(NameToString(faction)) done; \(pay)eb.");
    this.FavourEnd(game);
  }

  private func FavourEnd(game: GameInstance) -> Void {
    let target = this.m_favTarget;
    if IsDefined(target) {
      target.cbFavourMark = false;
      CBUntrackOnMap(game, target);
    }
    this.m_favFaction = n"";
    this.m_favKind = 0;
    this.m_favTarget = null;
    CBDeleteTaggedSafe(game, n"CB_Favour", true, true);
  }

  // ---- The sit-down ----------------------------------------------------------------------------------------

  private func SitDown(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>, busy: Bool) -> Void {
    let nowT = sys.GetTickCount();
    let now = CBGameSeconds(game);
    if NotEquals(this.m_meetA, n"") {
      this.KeepMeetPin(game);
      let ppos = player.GetWorldPosition();
      let dist = Vector4.Distance(ppos, this.m_meetAt);
      // Their time has come and V is on the way in, not yet looking: put them there.
      if !this.m_meetSpawned && now >= this.m_meetFrom && dist <= CBConfig.MeetSpawnDistance() && dist >= 25.0 {
        this.m_meetSpawned = this.PlaceMeet(sys, game, des, player);
      }
      if this.m_meetSpawned {
        let down = 0;
        for id in this.m_meetIds {
          let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
          if IsDefined(p) && p.cbDamagedByPlayer && (p.IsDead() || !CBStillStanding(p)) {
            down += 1;
          }
        }
        if down >= Max(2, ArraySize(this.m_meetIds) - 1) {
          this.Crashed(sys, game);
          return;
        }
      }
      if now >= this.m_meetFrom + CBConfig.MeetWindowSeconds() || !CBStreetLifeOn(n"sitDowns") {
        if CBMessagesOn() && CBStreetLifeOn(n"sitDowns") {
          CBHearsayFromStreet(game, s"\(CBCapFirst(CBFactionLabel(this.m_meetA))) and \(CBFactionLabel(this.m_meetB)) made their deal. Nobody stopped them.", n"");
        }
        this.EndMeet(game);
      }
      return;
    }
    if busy || nowT < this.m_meetNext || !CBStreetLifeOn(n"sitDowns") || player.IsInCombat() {
      return;
    }
    this.m_meetNext = nowT + CBJitter(CBConfig.MeetGapTicks(), 0.4);
    if RandF() >= CBConfig.MeetChance() {
      return;
    }
    let a = CBTurfHolder(sys, game, sys.GetCurrentDistrict());
    if Equals(a, n"") || !CBFactionFieldsSquads(a) || !CBFactionOn(a) {
      return;
    }
    let b = n"";
    for g in CBGangRivalsOf(sys.GetContent(), a) {
      if Equals(b, n"") && CBFactionFieldsSquads(g) && CBFactionOn(g) && IsDefined(sys.FindFaction(g)) {
        b = g;
      }
    }
    let spot: Vector4;
    if Equals(b, n"") || !CBWhereaboutsSpot(sys, game, player, spot) {
      return;
    }
    this.m_meetA = a;
    this.m_meetB = b;
    this.m_meetAt = spot;
    this.m_meetFrom = now + RandRangeF(1.0, 2.0) * 3600.0;
    this.m_meetSpawned = false;
    ArrayClear(this.m_meetIds);
    this.KeepMeetPin(game);
    if CBMessagesOn() {
      CBHearsayFromDistrict(game, sys.GetCurrentDistrict(),
        s"\(CBCapFirst(CBFactionLabel(a))) and \(CBFactionLabel(b)) are sitting down near here around \(CBClockWord(this.m_meetFrom)). Crash it, and they both feel it.", n"");
    }
    CBLog.Info(n"Street", s"A sit-down between \(NameToString(a)) and \(NameToString(b)) is set.");
  }

  // The pin on the place, in step with the map markers setting, the way the pin on a Rival's place is
  // (Rivals/Whereabouts.reds, CBLeadPinTick). It was only ever put up when the sit-down was set, so
  // switching markers off left it on the map, and switching them on never put it up.
  private func KeepMeetPin(game: GameInstance) -> Void {
    let want = CBMapMarkersOn();
    if Equals(want, this.m_meetPinned) {
      return;
    }
    let ms = GameInstance.GetMappinSystem(game);
    if !IsDefined(ms) {
      return;
    }
    if !want {
      ms.UnregisterMappin(this.m_meetPin);
      this.m_meetPinned = false;
      return;
    }
    let data: MappinData;
    data.mappinType = t"Mappins.DefaultStaticMappin";
    data.variant = gamedataMappinVariant.ApartmentVariant;
    data.active = true;
    data.visibleThroughWalls = true;
    data.debugCaption = CBRivalPinCaption(CBCapFirst(CBFactionLabel(this.m_meetA)) + " and " + CBFactionLabel(this.m_meetB));
    this.m_meetPin = ms.RegisterMappin(data, this.m_meetAt);
    this.m_meetPinned = true;
  }

  // Two of each, out of V's sight round the place.
  private func PlaceMeet(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>) -> Bool {
    let fa = sys.FindFaction(this.m_meetA);
    let fb = sys.FindFaction(this.m_meetB);
    if !IsDefined(fa) || !IsDefined(fb) || !TDBID.IsValid(fa.sampleRecord) || !TDBID.IsValid(fb.sampleRecord) || CBSpawnRoom(game) < 4 {
      return false;
    }
    let ppos = player.GetWorldPosition();
    let fwd = player.GetWorldForward();
    let k = 0;
    while k < 8 && ArraySize(this.m_meetIds) < 4 {
      let ang = Cast<Float>(k) * 0.7854;
      k += 1;
      let snapped: Vector4;
      let at: Vector4;
      if CBNavSnap(game, this.m_meetAt.X + CosF(ang) * 2.2, this.m_meetAt.Y + SinF(ang) * 2.2, this.m_meetAt.Z, snapped)
         && CBSettleOnGround(game, snapped, at) && CBPointHiddenFrom(game, ppos, fwd, at) {
        // Facing the middle, the way people meeting stand.
        let facing = Quaternion.BuildFromDirectionVector(new Vector4(-CosF(ang), -SinF(ang), 0.0, 0.0));
        let rec = ArraySize(this.m_meetIds) % 2 == 0 ? fa.sampleRecord : fb.sampleRecord;
        let id: EntityID;
        if CBCreateSpawn(des, rec, n"", at, facing, n"CB_Meet", id) {
          ArrayPush(this.m_meetIds, id);
        }
      }
    }
    return ArraySize(this.m_meetIds) >= 2;
  }

  private func Crashed(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    CBWeakenGang(sys, game, this.m_meetA, CBConfig.MeetGangLoss());
    CBWeakenGang(sys, game, this.m_meetB, CBConfig.MeetGangLoss());
    CBTalkFear(sys, game, this.m_meetA, CBConfig.WordKeptFear());
    CBTalkFear(sys, game, this.m_meetB, CBConfig.WordKeptFear());
    let mult = 1.0;
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      mult = rt.GetSettings().renownGainMult;
    }
    sys.AddRenownPoints(CBConfig.MeetRenown() * mult);
    CBFileLog(sys, n"MeetCrashed", CBGameSeconds(game), CBEventDistrict(sys, game), this.m_meetA, 0.0);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"You crashed the sit-down between \(CBFactionLabel(this.m_meetA)) and \(CBFactionLabel(this.m_meetB)). Neither of them will forget it.", n"");
    }
    CBLog.Info(n"Street", "V crashed a sit-down.");
    this.EndMeet(game);
  }

  private func EndMeet(game: GameInstance) -> Void {
    if this.m_meetPinned {
      let ms = GameInstance.GetMappinSystem(game);
      if IsDefined(ms) {
        ms.UnregisterMappin(this.m_meetPin);
      }
      this.m_meetPinned = false;
    }
    this.m_meetA = n"";
    this.m_meetB = n"";
    ArrayClear(this.m_meetIds);
    CBDeleteTaggedSafe(game, n"CB_Meet", true, true);
  }

  // ---- Surrender (experimental) ----------------------------------------------------------------------------

  // Instead of running (Reactions/Morale.reds, CBMoraleBreak): hands up, not fighting, held where they are.
  public func TrySurrender(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>) -> Bool {
    let player = GetPlayer(game);
    if !CBStreetLifeOn(n"surrender") || !IsDefined(npc) || !IsDefined(player) || npc.IsCrowd() || npc.IsBoss()
       || RandF() >= CBConfig.SurrenderShare() || ArraySize(this.m_gaveUp) >= 4 {
      return false;
    }
    // Never a Rival. A Rival who runs has an ending of their own (Reactions/CombatFlee.reds); one with
    // their hands up had none, and stood there with their encounter open for good.
    let des = GameInstance.GetDynamicEntitySystem();
    let nid = npc.GetEntityID();
    if IsDefined(des) && (des.IsTagged(nid, n"CB_Rival") || des.IsTagged(nid, n"CB_Lair")) {
      return false;
    }
    let agent = npc.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(agent) || !IsDefined(pagent) {
      return false;
    }
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
    let data: stimInvestigateData;
    data.fearPhase = 2;
    StimBroadcasterComponent.SendStimDirectly(player, gamedataStimType.SpreadFear, npc, data);
    CBTalkHold(npc);
    npc.cbSurrendered = true;
    ArrayPush(this.m_gaveUp, npc);
    ArrayPush(this.m_gaveUpTick, sys.GetTickCount());
    this.HandOffSurrendered(sys, game, des, npc);
    CBIntelSay(game, 3, CBIntelSpeaker(CBClassifyFaction(npc)), CBWhisperPick3("Okay! Okay! I'm done!", "Don't shoot! I give up!", "Enough! It's over, I'm out!"), 3.5);
    CBLog.Info(n"Street", "An enemy gave up instead of running.");
    return true;
  }

  // One of ours with their hands up is out of the fight, as one who ran clear is (Reactions/CombatFlee.reds,
  // CBRunnerGotAway). Their encounter lets go of them: a crew whose last one standing had given up was never
  // beaten, its lane stayed busy, and the hunt ended by telling V that V had run. Left where they stand, not
  // removed, because V is looking at them; the orphan sweep takes them once nobody is.
  private func HandOffSurrendered(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                                  npc: wref<ScriptedPuppet>) -> Void {
    if !IsDefined(des) || !IsDefined(npc) {
      return;
    }
    let id = npc.GetEntityID();
    let wasSquad = des.IsTagged(id, n"CB_Squad");
    let handed = false;
    let tags: array<CName> = [n"CB_Squad", n"CB_Escort", n"CB_Scout", n"CB_Apex"];
    for tag in tags {
      if des.IsTagged(id, tag) {
        des.UnassignTag(id, tag);
        handed = true;
      }
    }
    if !handed {
      return;
    }
    if !des.IsTagged(id, n"CB_Orphan") {
      des.AssignTag(id, n"CB_Orphan");
    }
    if EntityID.IsDefined(sys.GetScoutId()) && Equals(id, sys.GetScoutId()) {
      CBScoutSilenced(sys, game, sys.GetScoutFaction());
    }
    if wasSquad {
      CBCrewBeatenIfLast(sys, game, id);
    }
  }

  private func Surrenders(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, now: Int32) -> Void {
    let i = ArraySize(this.m_gaveUp) - 1;
    while i >= 0 {
      let p = this.m_gaveUp[i];
      let gone = !IsDefined(p) || !p.IsAttached() || p.IsDead();
      let far = !gone && Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition()) > 25.0;
      if gone || far || now - this.m_gaveUpTick[i] >= 60 {
        if !gone {
          CBTalkReleaseHold(p);
          CBOrderFlee(game, p);
          // Let go is let go: shot later, it is somebody running off, not somebody with their hands up.
          p.cbSurrendered = false;
        }
        ArrayErase(this.m_gaveUp, i);
        ArrayErase(this.m_gaveUpTick, i);
      }
      i -= 1;
    }
  }

  // ---- "Nobody kills you but me" (experimental) ------------------------------------------------------------

  private func Claim(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>,
                     now: Int32, busy: Bool) -> Void {
    if this.m_allyOut {
      this.m_allyCalm = player.IsInCombat() ? 0 : this.m_allyCalm + 1;
      if this.m_allyCalm == CBConfig.ClaimCalmTicks() {
        for id in des.GetTaggedIDs(n"CB_Ally") {
          let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
          if IsDefined(p) && CBStillStanding(p) {
            CBOrderFlee(game, p);
          }
        }
      }
      if this.m_allyCalm >= CBConfig.ClaimCalmTicks() + 30 {
        CBDeleteTaggedSafe(game, n"CB_Ally", true, true);
        if !CBLiveTaggedPresent(game, n"CB_Ally") {
          this.m_allyOut = false;
        }
      }
      return;
    }
    if busy || !CBStreetLifeOn(n"claimHelp") || !player.IsInCombat() || now % 3 != 0 || CBGameDay(game) == this.m_allyDay {
      return;
    }
    // Outnumbered by one gang?
    let reg = sys.GetRegistry();
    if !IsDefined(reg) {
      return;
    }
    let ppos = player.GetWorldPosition();
    let pagent = player.GetAttitudeAgent();
    let counts: array<Int32>;
    let gangs: array<CName>;
    let enemy = n"";
    for p in reg.GetAll() {
      if IsDefined(p) && p.IsAttached() && !p.IsDead() && CBStillStanding(p) && CBNpcInCombat(p)
         && Vector4.Distance(ppos, p.GetWorldPosition()) <= 45.0 {
        let agent = p.GetAttitudeAgent();
        if IsDefined(agent) && IsDefined(pagent) && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
          let f = CBClassifyFaction(p);
          let k = ArrayFindFirst(gangs, f);
          if k < 0 {
            ArrayPush(gangs, f);
            ArrayPush(counts, 1);
          } else {
            counts[k] += 1;
            if counts[k] >= CBConfig.ClaimOutnumbered() && NotEquals(f, n"") {
              enemy = f;
            }
          }
        }
      }
    }
    if Equals(enemy, n"") || !CBFactionFieldsSquads(enemy) {
      return;
    }
    // A Rival of another gang with a claim on V: they beat V, got away from V, or were let go by V.
    for r in sys.GetRivals() {
      if IsDefined(r) && NotEquals(r.faction, enemy) && r.rank >= 2 && TDBID.IsValid(r.recordID)
         && (r.killedV > 0 || r.escapes > 0 || r.sparedByV > 0) && CBFactionFieldsSquads(r.faction)
         && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Dormant))
         && r.id != sys.GetActiveRivalId() && r.id != sys.GetLaneRivalId(CBLaneRival())
         && !CBRivalBodyPresent(game, r) && CBSpawnRoom(game) >= 2 {
        let body: EntityID;
        if CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Ally", 30.0, body) > 0 {
          let fs = sys.FindFaction(r.faction);
          if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
            let second: EntityID;
            CBSpawnGroup(game, fs.sampleRecord, n"", 1, n"CB_Ally", 32.0, second);
          }
          // On their cooldown while they are out helping, as after any fight of theirs: the Rival lane
          // picking them meanwhile put a second of them in the street, after V.
          r.huntTicks = Max(r.huntTicks, CBConfig.RivalAfterEscapeTicks());
          this.m_allyOut = true;
          this.m_allyEnemy = enemy;
          this.m_allyCalm = 0;
          this.m_allyDay = CBGameDay(game);
          CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), "Nobody kills you but me. Keep your head down.", CBHudRed());
          CBLog.Info(n"Street", s"Rival \(r.id) came to help V against \(NameToString(enemy)).");
          return;
        }
      }
    }
  }

  // An ally against whoever V is fighting: hostile to each of them near, and they to it.
  public func TurnOnEnemy(sys: ref<CyberbaneSystem>, game: GameInstance, ally: ref<ScriptedPuppet>) -> Void {
    let agent = ally.GetAttitudeAgent();
    let reg = sys.GetRegistry();
    if !IsDefined(agent) || !IsDefined(reg) {
      return;
    }
    let apos = ally.GetWorldPosition();
    for p in reg.GetAll() {
      if IsDefined(p) && p.IsAttached() && !p.IsDead() && Equals(CBClassifyFaction(p), this.m_allyEnemy)
         && Vector4.Distance(apos, p.GetWorldPosition()) <= 80.0 {
        let other = p.GetAttitudeAgent();
        if IsDefined(other) {
          agent.SetAttitudeTowards(other, EAIAttitude.AIA_Hostile);
          other.SetAttitudeTowards(agent, EAIAttitude.AIA_Hostile);
        }
      }
    }
  }
}

// What is worth telling after a load: what changed the street, not the small stuff.
func CBWhileOutWorthIt(kind: CName) -> Bool {
  return Equals(kind, n"RivalCreated") || Equals(kind, n"RivalSlain") || Equals(kind, n"TurfTaken") || Equals(kind, n"TurfPush")
      || Equals(kind, n"KinSworn") || Equals(kind, n"CalledOut") || Equals(kind, n"Allied") || Equals(kind, n"Peace")
      || Equals(kind, n"RivalExiled") || Equals(kind, n"MeetCrashed") || Equals(kind, n"BagmanRobbed");
}

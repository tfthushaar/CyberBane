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
    return true;   // surrender is on by default from 2.3.2, and "Nobody kills you but me" from 2.4.4
  }
  let s = rt.GetSettings();
  if Equals(flag, n"bagmen") { return s.bagmen; }
  if Equals(flag, n"favours") { return s.favours; }
  if Equals(flag, n"sitDowns") { return s.sitDowns; }
  if Equals(flag, n"whileOut") { return s.whileOut; }
  if Equals(flag, n"surrender") { return s.gangsSurrender; }
  // A new field in 2.4.4 so its new default, on, reaches every install: the old claimHelp was stored off on all of them.
  if Equals(flag, n"claimHelp") { return s.nobodyButMe && CBRivalsOn(); }
  return false;
}

// How many of each gang come to a sit-down (People per gang at a sit-down): five each, ten in all.
public func CBSitDownPerGang() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return 5;
  }
  return Clamp(rt.GetSettings().sitDownSize, 1, 8);
}

// How many of each gang's people there are its best (Apex fighters per gang at a sit-down): one per chair
// of its apex squad, so four at most, and never more than came.
public func CBSitDownApexPerGang() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  let n = 2;
  if IsDefined(rt) && rt.HasSettings() {
    n = rt.GetSettings().sitDownApex;
  }
  return Clamp(n, 0, Min(4, CBSitDownPerGang()));
}

// One of a gang's best at a sit-down: spawned from the record of their apex squad's chair and carrying that
// chair's tag (CBApexRoleTag), but never CB_Apex, which is the apex squad itself, with its muster, its bounty
// and its one-at-a-time lane.
public func CBIsMeetApex(des: ref<DynamicEntitySystem>, id: EntityID) -> Bool {
  return IsDefined(des) && des.IsTagged(id, n"CB_Meet") && CBTaggedApexSeat(des, id) >= 0;
}

// Built and kitted as a member of the gang's apex squad is (Spawn/Spawner.reds, the CB_Apex setup): the same
// build under the apex strength slider, the same chair's kit. What they are to V is the street's call, made
// by CBSetUpStreet first like everybody else at the sit-down. No boss bar: up to eight of them, standing
// about before anybody is fighting, would fill the screen with bars for people who may never draw.
public func CBSetUpMeetApex(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, seat: Int32) -> Void {
  if !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  CBApplyApexBuff(sys, game, puppet);
  CBKitApexSeat(puppet, seat);
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

// Taken out of what they were there for by V (2.1.0): put down, broken and running, or giving up after V hurt
// them, or sent on their way by V's words (CBTalkSendOff). The one rule for a favour's lookout and the people at
// a sit-down. Somebody else putting them down is not V doing it. Words count from 2.1.0, when the street's own
// people became people V can talk to: a lookout V threatens off the corner has been run off.
func CBTakenOutByV(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) {
    return false;
  }
  if p.cbTalkSentTick > 0 {
    return true;
  }
  return p.cbDamagedByPlayer && (CBIsDown(p) || p.cbMoraleBroken || p.cbSurrendered);
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
  // The sit-down and the rest of gang life's events (Spawn/StreetEvents.reds, 2.3.3).
  private let m_events: ref<CBEventEngine>;
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
  private let m_allyRival: Int32;   // who came ([E4], 2.4.4), for their parting words

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
    this.Events().Tick(sys, game, des, player, busy);
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
    this.Events().Reset(game);
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
      if !this.m_bagDone && IsDefined(p) && p.cbDamagedByPlayer && CBIsDown(p) {
        this.m_bagDone = true;
        this.Robbed(sys, game);
      }
      let age = now - this.m_bagTick;
      // Their round, and again after V has stopped one of them for a word (2.1.0): the conversation's hold
      // took the place of the walk (CBTalkHold).
      if age == 4 || (age > 4 && CBTalkWalkOnDue(game, des, n"CB_Bagman")) {
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
    CBWarSpend(game, this.m_bagFaction, Cast<Float>(take) * CBConfig.BagmanChestShare());   // the week's take (2.4.0)
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
      // The per-NPC gate before IsCrowd, which reads their record (2.2.1): the registry still holds
      // people who have streamed out until its next prune, and the same order in the talk bubbles crashed.
      for p in reg.GetAll() {
        if IsDefined(p) && p.cbTalkTimes == 0 && CBNpcSafe(sys, p) && !p.IsDead() && p.IsCrowd() {
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
      // Run off by V (CBTakenOutByV). Somebody else putting the lookout down is not V doing the favour.
      let p = GameInstance.FindEntityByID(game, this.m_favBody) as ScriptedPuppet;
      done = CBTakenOutByV(p);
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

  // The sit-down and gang life's other events, one at a time (Spawn/StreetEvents.reds, 2.3.3).
  public func Events() -> ref<CBEventEngine> {
    if !IsDefined(this.m_events) {
      this.m_events = new CBEventEngine();
    }
    return this.m_events;
  }

  // ---- Surrender (experimental) ----------------------------------------------------------------------------

  // Instead of running (Reactions/Morale.reds, CBMoraleBreak): hands up, not fighting, held where they are.
  public func TrySurrender(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>) -> Bool {
    let player = GetPlayer(game);
    if !CBStreetLifeOn(n"surrender") || !IsDefined(npc) || !IsDefined(player) || npc.IsCrowd() || npc.IsBoss()
       || RandF() >= CBConfig.SurrenderShare() * CBCodeSurrender(CBClassifyFaction(npc)) || ArraySize(this.m_gaveUp) >= 4 {
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
    npc.SetScannerDirty(true);   // the scanner says so (UI/ScannerName.reds)
    ArrayPush(this.m_gaveUp, npc);
    ArrayPush(this.m_gaveUpTick, sys.GetTickCount());
    this.HandOffSurrendered(sys, game, des, npc);
    CBIntelSay(game, 3, CBIntelSpeaker(CBClassifyFaction(npc)), CBGangSurrenderLine(CBClassifyFaction(npc)), 3.5);
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
          p.SetScannerDirty(true);
          // Let go with their life (2.3.2): their gang hears that V let one walk, the way a mercy is heard, and
          // V's name for restraint grows. Not for somebody V grabbed and questioned, who was let go already.
          if !p.cbIntelGiven {
            let gave = CBClassifyFaction(p);
            CBCreditMercy(sys, gave, CBConfig.SurrenderLetGoStanding());
            sys.AddCode(CBConfig.SurrenderLetGoCode());
            CBFileLog(sys, n"LetGo", CBGameSeconds(game), CBEventDistrict(sys, game), gave, 0.0);
            CBLog.Info(n"Street", "V let somebody with their hands up walk.");
          }
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
        // They leave with a line that sets up their next fight with V, and they will come for it ([E4], 2.4.4).
        let ally = sys.FindRivalById(this.m_allyRival);
        if IsDefined(ally) && CBMessagesOn() {
          CBIntelSay(game, 3, CBRivalDisplayName(sys.GetContent(), ally), CBPick3("We're square for today. Next time it's you and me.",
            "Don't thank me. Nobody else gets to kill you. That's mine.", "Enjoy it. The next fight's ours, and I won't be on your side."), 4.0);
          ally.huntTicks = Max(ally.huntTicks, CBConfig.RivalAfterEscapeTicks());
          CBRivalGiveTrait(ally, n"GrudgeBearer");
        }
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
    // Not while V has a borrowed crew along (Reactions/Allies.reds, 2.4.5): both are CB_Ally, and this one's clean-up is by tag.
    if busy || !CBStreetLifeOn(n"claimHelp") || !player.IsInCombat() || now % 3 != 0 || CBGameDay(game) == this.m_allyDay
       || CBLiveTaggedPresent(game, n"CB_Follower") {
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
      if CBNpcSafe(sys, p) && !p.IsDead() && CBStillStanding(p) && CBNpcInCombat(p)
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
          this.m_allyRival = r.id;
          this.m_allyEnemy = enemy;
          this.m_allyCalm = 0;
          this.m_allyDay = CBGameDay(game);
          CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r), "Nobody kills you but me. Keep your head down.", CBHudRed());
          // And they say so as they arrive, in the street ([E4], 2.4.4).
          CBAnnounceLater(game, CBRivalDisplayName(sys.GetContent(), r), CBPick2("Nobody kills this one but me!", "Back off! This merc's mine!"), 2.5);
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
      if CBNpcSafe(sys, p) && !p.IsDead() && Equals(CBClassifyFaction(p), this.m_allyEnemy)
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

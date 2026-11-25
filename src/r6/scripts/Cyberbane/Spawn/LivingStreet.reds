// Cyberbane - A living street
//
// Bagmen, favours from friendly gangers, news while V was away, and surrender.

// Why one of the street's features did not happen when its turn came, in the log at most once a game hour for each
// feature and reason.
public func CBStreetWhyNot(game: GameInstance, feature: String, why: String) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.ShouldNoteWhy(feature + "|" + why, CBGameSeconds(game), CBConfig.SecondsPerHour()) {
    return;
  }
  CBLog.Info(n"Street", s"No \(feature) this time: \(why).");
}

// Work for the corporations: contracts offered to V. Not CBCorpContractsOn (Spawn/Bounty.reds), the corporations'
// contracts on V.
public func CBCorpWorkOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  return !rt.HasSettings() || rt.GetSettings().corpWork;
}

public func CBStreetLifeOn(flag: CName) -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  if !rt.HasSettings() {
    return true;   // surrender and "Nobody kills you but me" are on by default
  }
  let s = rt.GetSettings();
  if Equals(flag, n"bagmen") { return s.bagmen; }
  if Equals(flag, n"favours") { return s.favours; }
  if Equals(flag, n"sitDowns") { return s.sitDowns; }
  if Equals(flag, n"whileOut") { return s.whileOut; }
  if Equals(flag, n"surrender") { return s.gangsSurrender; }
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

// Built and kitted as a member of the gang's apex squad is (Spawn/Spawner.reds, the CB_Apex setup): the same build
// under the apex strength slider, the same chair's kit.
public func CBSetUpMeetApex(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, seat: Int32) -> Void {
  if !IsDefined(puppet) || !puppet.IsAttached() || puppet.IsDead() {
    return;
  }
  CBApplyApexBuff(sys, game, puppet);
  CBKitApexSeat(puppet, seat);
}

public func CBTalkActFavour() -> Int32 = 30

// Whether this person has a favour for V (CBStreetLife.HasWorkFor): 0 not asked yet, 1 yes, 2 no.
@addField(ScriptedPuppet)
public let cbFavourRoll: Int32;

// Who owes: one of the district's own who fights with fists (the wannabes' records), never one of the gang that is
// owed. Only a record this install has, a person nobody wrote.
func CBDebtorRecord(sys: ref<CyberbaneSystem>, district: CName, owed: CName) -> TweakDBID {
  let content = IsDefined(sys) ? sys.GetContent() : null;
  let picks: array<TweakDBID>;
  ArrayPush(picks, CBWannabeRecord(district));
  ArrayPush(picks, t"Character.valentinos_grunt4_hmelee2_fists_mb_rare");
  ArrayPush(picks, t"Character.tyger_claws_gangster1_melee1_fists_ma");
  ArrayPush(picks, t"Character.animals_grunt1_melee1_fists_mb");
  ArrayPush(picks, t"Character.tyger_claws_biker1_melee1_fists_wa");
  for id in picks {
    if TDBID.IsValid(id) && CBRecordIsPerson(id) && !CBRecordUnfitTemplate(id) {
      let rec = TweakDBInterface.GetCharacterRecord(id);
      let aff = IsDefined(rec) ? rec.Affiliation() : null;
      let gang = IsDefined(aff) && IsDefined(content) ? content.FactionForAffiliation(aff.EnumName()) : n"";
      if IsDefined(rec) && NotEquals(gang, owed) {
        return id;
      }
    }
  }
  return TDBID.None();
}

@addField(ScriptedPuppet)
public let cbFavourMark: Bool;

@addField(ScriptedPuppet)
public let cbSurrendered: Bool;

// Gave up to V, and kept when they are let go. cbSurrendered ends when the hold does, and with it everything that kept
// them out of the fight: a Scav who said "I'm done" and was let walk was turned on V again by the vendetta's hostility
// on sight the moment V came close to talk.
@addField(ScriptedPuppet)
public let cbGaveUp: Bool;

// Set up a moment after attaching, like everybody else of ours (Spawn/Spawner.reds, CBApplySpawnSetup).
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
  CBWakeStep(puppet);
}

// A step where they stand: the street's people are put in the world with nothing to do, and a body nothing asks
// anything of could stand in the default pose until it was hit ("they won't react until I damage them, then the
// animations load in").
public func CBWakeStep(p: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(p) || !p.IsAttached() || p.IsDead() || IsDefined(p.cbMoveCmd) {
    return;
  }
  let pos = p.GetWorldPosition();
  let fwd = p.GetWorldForward();
  CBStreetWalkNear(p, new Vector4(pos.X + fwd.X * 0.9, pos.Y + fwd.Y * 0.9, pos.Z, 1.0), 0.3);
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

// Taken out of what they were there for by V: put down, broken and running, or giving up after V hurt them, or sent on
// their way by V's words (CBTalkSendOff). The one rule for a favour's lookout and the people at a sit-down.
func CBTakenOutByV(p: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(p) {
    return false;
  }
  if p.cbTalkSentTick > 0 {
    return true;
  }
  return p.cbDamagedByPlayer && (CBIsDown(p) || p.cbMoraleBroken || p.cbSurrendered);
}

// One of a gang's own people on the street: at a gathering, hanging out, a bagman, a debtor, a witness, a favour's
// lookout, a wannabe. There to be talked to or dealt with; nobody of V's starts a fight with them.
public func CBStreetPersonTag(des: ref<DynamicEntitySystem>, id: EntityID) -> Bool {
  return IsDefined(des) && (des.IsTagged(id, n"CB_Meet") || des.IsTagged(id, n"CB_Event") || des.IsTagged(id, n"CB_Hangout")
      || des.IsTagged(id, n"CB_Bagman") || des.IsTagged(id, n"CB_Debtor") || des.IsTagged(id, n"CB_Witness")
      || des.IsTagged(id, n"CB_Favour") || des.IsTagged(id, n"CB_Wannabe") || des.IsTagged(id, n"CB_Mark"));
}

// Taken out by V or by somebody fighting on V's side (CBOnVsSide: V's crew, a gang's people with V, a companion): a
// meeting V's crew cut down was crashed by V's side, as a fight won with V's crew counts.
func CBTakenOutByVSide(game: GameInstance, p: wref<ScriptedPuppet>) -> Bool {
  if CBTakenOutByV(p) {
    return true;
  }
  return IsDefined(p) && CBIsDown(p) && p.cbLastHitByOther && !EntityID.IsDefined(p.cbLastHitVehicle)
      && CBOnVsSide(game, p.cbLastAttacker);
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

// The time on the clock, to the minute. It gave the hour alone, so a meeting due at 04:50 was "around 04:00": V turned
// up at four, and nothing came for fifty minutes.
func CBClockWord(gameSeconds: Float) -> String {
  let total = Cast<Int32>(gameSeconds / 60.0);
  let h = (total / 60) % 24;
  let m = total % 60;
  return (h < 10 ? "0" : "") + IntToString(h) + ":" + (m < 10 ? "0" : "") + IntToString(m);
}

// A start time on the quarter hour, the way people name one, so the time V is told is the time it starts.
public func CBQuarterUp(gameSeconds: Float) -> Float {
  return Cast<Float>(CeilF(gameSeconds / 900.0)) * 900.0;
}

// The hour and which day: "21:00 today", "03:00 tomorrow", "now" once it has started. Is that moment now or already
// past, the way CBWhenWord says "now"? For code to ask instead of reading the word.
public func CBWhenIsNow(game: GameInstance, at: Float) -> Bool {
  let now = CBGameSeconds(game);
  return now > 0.0 && at <= now;
}

public func CBWhenWord(game: GameInstance, at: Float) -> String {
  let now = CBGameSeconds(game);
  if now <= 0.0 {
    return CBClockWord(at);
  }
  if at <= now {
    return CBT(n"Cyberbane-LivingStreet-Now");
  }
  let dayNow = Cast<Int32>(now / 86400.0);
  let dayAt = Cast<Int32>(at / 86400.0);
  if dayAt == dayNow {
    return CBTf(n"Cyberbane-LivingStreet-Today", [CBClockWord(at)]);
  }
  if dayAt == dayNow + 1 {
    return CBTf(n"Cyberbane-LivingStreet-Tomorrow", [CBClockWord(at)]);
  }
  return CBClockWord(at);
}

public class CBStreetLife {
  // The bagman.
  private let m_bagFaction: CName;
  private let m_bagBody: EntityID;
  private let m_bagTick: Int32;
  private let m_bagNext: Int32;
  private let m_bagDone: Bool;
  private let m_bagRan: Bool;   // he saw V coming and ran
  // Where he is walking the take: his gang's drop, pinned.
  private let m_bagDrop: Vector4;
  private let m_bagHasDrop: Bool;
  private let m_bagDropPin: NewMappinID;
  private let m_bagDropPinned: Bool;
  // A favour.
  private let m_favFaction: CName;
  private let m_favKind: Int32;        // 1 a lookout to run off, 2 somebody to lean on
  private let m_favTarget: wref<ScriptedPuppet>;
  private let m_favBody: EntityID;
  private let m_favUntil: Int32;
  private let m_favLeaned: Bool;
  // Where it is, on the map from the moment it is asked: the person's own marker came only once they were in the world,
  // so a lookout who never streamed in, or somebody the map would not mark, left "I marked it for you" with nothing on
  // the map.
  private let m_favPin: NewMappinID;
  private let m_favPinned: Bool;
  // And comes back whenever that marker is not showing (FavourKeepPin): what it says and where it goes, the place, or
  // where a lookout was last seen.
  private let m_favPinText: String;
  private let m_favPinAt: Vector4;
  // A debt to collect somewhere else: where the one who owes is, which district, whether they are in the world yet, and
  // whether they would sooner fight than pay (0 no, 1 once the talk is over, 2 fighting).
  private let m_favAt: Vector4;
  private let m_favDistrict: CName;
  private let m_favPlaced: Bool;
  private let m_favFight: Int32;
  private let m_favFightTick: Int32;
  // A gang that has just handed out a favour has no more for a while. Session only, like the favour.
  private let m_favRestGang: array<CName>;
  private let m_favRestUntil: array<Float>;
  // How many names down a chain of debts this one is: a debtor who pays may give up somebody else who owes.
  private let m_favChain: Int32;
  // A corporation's contract (favour kind 3): whose people the mark is, what it pays, and the next tick one may be
  // offered.
  private let m_favMark: CName;
  private let m_contractPay: Int32;
  private let m_contractNext: Int32;
  // The sit-down and the rest of gang life's events (Spawn/StreetEvents.reds).
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
  private let m_allyRival: Int32;   // who came ([E4]), for their parting words

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
    // Nor on home ground (Spawn/HomeGround.reds).
    let busy = sys.GetStoryHold() != CBStoryNone() || sys.IsInQuestArea() || sys.IsOnJob() || sys.IsInSanctuary()
            || sys.IsInSafeZone() || CBPlayerInScene(game) || CBHomeKeepsOut(sys);
    // The shared room nearly gone: what is holding it, once a game hour.
    if CBSpawnRoom(game) <= 2 {
      let rtRoom = CyberbaneRuntime.Get();
      if IsDefined(rtRoom) && rtRoom.ShouldNoteWhy("room", CBGameSeconds(game), CBConfig.SecondsPerHour()) {
        CBLog.Info(n"Spawn", s"Room for Cyberbane's people nearly gone: \(CBSpawnRoomNote(game)).");
      }
    }
    this.WhileOut(sys, game, player, busy);
    this.Bagman(sys, game, des, player, now, busy);
    this.ContractOffer(sys, game, player, now, busy);
    this.Favour(sys, game, des, player, now);
    this.Events().Tick(sys, game, des, player, busy);
    this.Surrenders(sys, game, player, now);
    this.Claim(sys, game, des, player, now, busy);
  }

  // Start over (CyberbaneSystem.HardReset): whatever the street had going belonged to the old playthrough.
  public func Reset(game: GameInstance) -> Void {
    this.m_bagFaction = n"";
    this.m_bagDone = false;
    this.BagUnpin(game);
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
        CBSystemNote(game, CBTf(n"Cyberbane-LivingStreet-LastYouHeard", [CBHudLogLine(sys, e, now, true)]), 9.0);
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
      // Their round, and again after V has stopped one of them for a word: the conversation's hold took the place of
      // the walk (CBTalkHold).
      if age == 4 || (age > 4 && CBTalkWalkOnDue(game, des, n"CB_Bagman")) {
        if this.m_bagHasDrop {
          // To the drop, he and whoever watches his back.
          for bid in des.GetTaggedIDs(n"CB_Bagman") {
            let walker = GameInstance.FindEntityByID(game, bid) as ScriptedPuppet;
            if CBNpcSafe(sys, walker) && CBStillStanding(walker) && !CBNpcInCombat(walker) {
              CBStreetWalkNear(walker, this.m_bagDrop, 2.5);
            }
          }
        } else {
          CBPatrolWalk(sys, game, des, player, n"CB_Bagman");
        }
      }
      // V coming at him, gun out or at a run: he bolts with the take, says so in his own voice, and his gang hears.
      if !this.m_bagDone && !this.m_bagRan && IsDefined(p) && CBNpcSafe(sys, p) && CBStillStanding(p) && !CBNpcInCombat(p)
         && !p.cbDamagedByPlayer && CBBagmanSeesVComing(game, player, p) {
        this.m_bagRan = true;
        CBVoice(sys, game, p, n"fear_run", n"BagmanRuns", 20.0, n"danger");
        CBOrderFlee(game, p);
        if CBMessagesOn() {
          CBPhoneFromGang(game, this.m_bagFaction, CBT(n"Cyberbane-LivingStreet-BagmanRanWarning"));
        }
        CBLog.Info(n"Street", "A bagman saw V coming and ran.");
      }
      // The take reached the drop: gone where V cannot follow it.
      if this.m_bagHasDrop && !this.m_bagDone && IsDefined(p) && CBStillStanding(p)
         && Vector4.Distance(p.GetWorldPosition(), this.m_bagDrop) <= 8.0 {
        this.m_bagDone = true;
        if CBMessagesOn() {
          CBPhoneFromDistrict(game, sys.GetCurrentDistrict(), CBTf(n"Cyberbane-LivingStreet-TakeMadeItToTheDrop", [s"\(CBCapFirst(CBPossessive(CBFactionLabel(this.m_bagFaction))))"]));
        }
        CBLog.Info(n"Street", "A bagman reached his drop.");
      }
      let near = IsDefined(p) && Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition()) <= CBConfig.TurfPatrolLeaveDistance();
      let life = this.m_bagHasDrop ? Max(CBConfig.BagmanLifeTicks(), CBConfig.BagmanRouteLifeTicks()) : CBConfig.BagmanLifeTicks();
      if age >= life || (age > 10 && !near && !des.IsSpawning(this.m_bagBody)) || !CBStreetLifeOn(n"bagmen")
         || (this.m_bagDone && this.m_bagHasDrop) {
        CBDeleteTaggedSafe(game, n"CB_Bagman", true, true);
        this.m_bagFaction = n"";
        this.BagUnpin(game);
      }
      return;
    }
    if now < this.m_bagNext || !CBStreetLifeOn(n"bagmen") {
      return;
    }
    let bagWhy = "";
    if busy { bagWhy = CBT(n"Cyberbane-LivingStreet-VIsSomewhereTheStoryA"); }
    else { if player.IsInCombat() { bagWhy = CBT(n"Cyberbane-LivingStreet-VIsInAFight"); }
    else { if IsDefined(player.GetMountedVehicle()) { bagWhy = CBT(n"Cyberbane-LivingStreet-VIsInACar"); }
    else { if CBPlayerIndoors(game) { bagWhy = CBT(n"Cyberbane-LivingStreet-VIsIndoors"); }
    else { if CBHuntersOut(sys, game) { bagWhy = CBT(n"Cyberbane-LivingStreet-SomebodyIsOutHuntingV"); }
    else { if CBHuntPending(sys) { bagWhy = CBT(n"Cyberbane-LivingStreet-SomebodyIsOnTheirWayFor"); } } } } } }
    // Nor before V's district is known: the roll found nobody holding "None" and spent its clock.
    if StrLen(bagWhy) == 0 && Equals(sys.GetCurrentDistrict(), n"") {
      bagWhy = CBT(n"Cyberbane-LivingStreet-VSDistrictIsNotKnown");
    }
    if StrLen(bagWhy) > 0 {
      CBStreetWhyNot(game, "bagman", bagWhy);
      return;
    }
    this.m_bagNext = now + CBJitter(CBConfig.BagmanGapTicks(), 0.4);
    if RandF() >= CBConfig.BagmanChance() {
      return;
    }
    let holder = CBTurfHolder(sys, game, sys.GetCurrentDistrict());
    let bagRecord = CBGangTemplate(sys, holder);   // a gang V has never fought has bagmen too
    if Equals(holder, n"") || !CBFactionFieldsSquads(holder) || !TDBID.IsValid(bagRecord) {
      CBStreetWhyNot(game, "bagman", s"no gang that fields people holds \(NameToString(sys.GetCurrentDistrict()))");
      return;
    }
    if CBSpawnRoom(game) < 2 + CBConfig.TurfPatrolKeepRoom() {
      CBStreetWhyNot(game, "bagman", s"too many of Cyberbane's people are out already: \(CBSpawnRoomNote(game))");
      return;
    }
    let body: EntityID;
    let placed = CBSpawnGroup(game, bagRecord, n"", 2, n"CB_Bagman", CBConfig.TurfPatrolDistance(), body);
    if placed == 0 {
      CBStreetWhyNot(game, "bagman", "nowhere to put them out of V's sight");
    }
    if placed > 0 {
      this.m_bagFaction = holder;
      this.m_bagBody = body;
      this.m_bagTick = now;
      this.m_bagDone = false;
      this.m_bagRan = false;
      // Where he is taking it: his gang's drop, a place of theirs further off, pinned, so robbing him is a plan.
      let drop: Vector4;
      let dropDistrict: CName;
      this.BagUnpin(game);
      this.m_bagHasDrop = CBGangDropPlace(sys, game, player, holder, CBConfig.BagmanDropMin(), CBConfig.BagmanDropMax(), drop, dropDistrict);
      if this.m_bagHasDrop {
        this.m_bagDrop = drop;
        this.m_bagDropPinned = CBPinPlace(game, drop, CBTf(n"Cyberbane-LivingStreet-DropTheTakeIsHeadedHere", [s"\(CBCapFirst(CBPossessive(CBFactionLabel(holder))))"]), this.m_bagDropPin);
      }
      // A message, not word going round: something V can act on is never held back as chatter.
      if CBMessagesOn() {
        let watch = placed > 1 ? CBT(n"Cyberbane-LivingStreet-OneLookout") : CBT(n"Cyberbane-LivingStreet-NobodyWatchingHisBack");   // only when one came
        CBPhoneFromDistrict(game, sys.GetCurrentDistrict(), this.m_bagHasDrop
          ? CBTf(n"Cyberbane-LivingStreet-BagmanIsWalkingTheWeekS", [s"\(CBCapFirst(CBPossessive(CBFactionLabel(holder))))", s"\(watch)"])
          : CBTf(n"Cyberbane-LivingStreet-BagmanIsDoingTheRoundsNear", [s"\(CBCapFirst(CBPossessive(CBFactionLabel(holder))))", s"\(watch)"]));
      }
      CBLog.Info(n"Street", s"A \(NameToString(holder)) bagman is out near V\(this.m_bagHasDrop ? ", walking to their drop" : "").");
    }
  }

  private func BagUnpin(game: GameInstance) -> Void {
    if this.m_bagDropPinned {
      CBUnpinPlace(game, this.m_bagDropPin);
    }
    this.m_bagDropPinned = false;
  }

  private func Robbed(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let take = CBConfig.BagmanTakeBase() + RandRange(0, CBConfig.BagmanTakeBase() + 1);
    // Now and then it is the gang's goods instead of cash (Reactions/CrewJobs.reds). Taken quietly (the bagman only
    // knocked out, and no fight on) the gang has to hear of it first.
    let bagman = GameInstance.FindEntityByID(game, this.m_bagBody) as ScriptedPuppet;
    let player = GetPlayer(game);
    let quiet = IsDefined(bagman) && !bagman.IsDead() && IsDefined(player) && !player.IsInCombat();
    if CBGoodsFromBag(sys, game, this.m_bagFaction, take, quiet) {
      if !quiet || RandF() < CBConfig.CrewBagKnownChance() {
        CBTalkSlight(sys, game, this.m_bagFaction, CBConfig.BagmanStandingLoss());
      }
      CBWeakenGang(sys, game, this.m_bagFaction, CBConfig.BagmanGangLoss());
      CBFileLog(sys, n"BagmanRobbed", CBGameSeconds(game), CBEventDistrict(sys, game), this.m_bagFaction, 0.0);
      return;
    }
    CBStreetGiveMoney(game, take);
    CBWarSpend(game, this.m_bagFaction, Cast<Float>(take) * CBConfig.BagmanChestShare());   // the week's take
    CBWeakenGang(sys, game, this.m_bagFaction, CBConfig.BagmanGangLoss());
    CBTalkSlight(sys, game, this.m_bagFaction, CBConfig.BagmanStandingLoss());
    let now = CBGameSeconds(game);
    CBFileLog(sys, n"BagmanRobbed", now, CBEventDistrict(sys, game), this.m_bagFaction, Cast<Float>(take));
    CBSystemNote(game, CBTf(n"Cyberbane-LivingStreet-YouTookTheBagEb", [s"\(take)"]), 5.0);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-LivingStreet-SomebodyRobbedBagmanWordIsIt", [s"\(CBPossessive(CBFactionLabel(this.m_bagFaction)))"]), n"");
    }
    CBLog.Info(n"Street", s"V robbed a bagman for \(take)eb.");
  }

  // ---- Favours ---------------------------------------------------------------------------------------------

  public func FavourOpen() -> Bool {
    return NotEquals(this.m_favFaction, n"");
  }

  // Whose favour it is, for the map's marker on the one who owes them (UI/Tracking.reds).
  public func FavourFaction() -> CName {
    return this.m_favFaction;
  }

  // Has this one got work for V? "Three Tyger Claws on one corner and all of them had a favour for me": any friendly
  // ganger had one, every time, while none was open.
  public func HasWorkFor(game: GameInstance, npc: ref<ScriptedPuppet>, faction: CName) -> Bool {
    if this.FavourOpen() || !IsDefined(npc) || Equals(faction, n"") || this.GangResting(game, faction) {
      return false;
    }
    if npc.cbFavourRoll == 0 {
      npc.cbFavourRoll = RandF() < CBConfig.FavourGiverChance() ? 1 : 2;
    }
    return npc.cbFavourRoll == 1;
  }

  private func GangResting(game: GameInstance, faction: CName) -> Bool {
    let i = ArrayFindFirst(this.m_favRestGang, faction);
    return i >= 0 && i < ArraySize(this.m_favRestUntil) && CBGameSeconds(game) < this.m_favRestUntil[i];
  }

  private func RestGang(game: GameInstance, faction: CName) -> Void {
    let hours = CBIsCorpFaction(faction) ? CBConfig.CorpContractRestHours() : CBConfig.FavourGangRestHours();
    let until = CBGameSeconds(game) + hours * CBConfig.SecondsPerHour();
    let i = ArrayFindFirst(this.m_favRestGang, faction);
    if i >= 0 && i < ArraySize(this.m_favRestUntil) {
      this.m_favRestUntil[i] = until;
      return;
    }
    ArrayPush(this.m_favRestGang, faction);
    ArrayPush(this.m_favRestUntil, until);
  }

  // Where the one who owes them is. "The victims spawn 20 metres away from them": the debtor was whoever of the crowd
  // stood 15 to 60 metres from V.
  private func DebtPlace(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, out at: Vector4,
                         out where: CName) -> Bool {
    let here = sys.GetCurrentDistrict();
    let ppos = player.GetWorldPosition();
    let content = sys.GetContent();
    let def = IsDefined(content) && NotEquals(here, n"") ? content.GetDistrict(here) : null;
    let minD = CBConfig.FavourDebtMinDistance();
    let found = false;
    let bestNext = false;
    let bestAt = -1.0;
    let book = CBStreetBook.Get(game);
    if IsDefined(book) {
      let i = 0;
      while i < book.PlaceCount() {
        let d = book.PlaceDistrict(i);
        let p = book.PlacePos(i);
        if NotEquals(d, n"") && NotEquals(d, here) && CBDistrictIndex(d) >= 0 && Vector4.Distance(p, ppos) >= minD
           && CBLairPointUsable(sys, game, p) {
          let next = IsDefined(def) && def.IsAdjacentTo(d);
          // Next door before further off, the newest memory before an older one.
          if !found || (next && !bestNext) || (Equals(next, bestNext) && book.PlaceAt(i) > bestAt) {
            found = true;
            bestNext = next;
            bestAt = book.PlaceAt(i);
            at = p;
            where = d;
          }
        }
        i += 1;
      }
    }
    if found {
      return true;
    }
    let svc = sys.GetPlayService();
    if IsDefined(svc) {
      for s in svc.GetSightings() {
        if !found && IsDefined(s) && NotEquals(s.district, n"") && NotEquals(s.district, here) && CBDistrictIndex(s.district) >= 0 {
          let sp = new Vector4(s.x, s.y, s.z, 1.0);
          if Vector4.Distance(sp, ppos) >= minD && CBLairPointUsable(sys, game, sp) {
            found = true;
            at = sp;
            where = s.district;
          }
        }
      }
    }
    if found {
      return true;
    }
    let spot: Vector4;
    if CBWhereaboutsSpot(sys, game, player, spot) {
      at = spot;
      where = here;
      return true;
    }
    return false;
  }

  // Asked in a conversation (Reactions/StreetTalk.reds). Starts one and says what it is, or says no.
  public func OfferFavour(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
    if this.FavourOpen() || !CBStreetLifeOn(n"favours") {
      return CBTalkSay(CBT(n"Cyberbane-LivingStreet-NotRightNowComeBackAnother"), n"");
    }
    let now = sys.GetTickCount();
    // A lookout of a gang at war with theirs, first.
    let enemies = CBGangRivalsOf(sys.GetContent(), t.faction);
    for g in enemies {
      let lookout = CBGangTemplate(sys, g);   // whether or not V has fought them
      if CBFactionOn(g) && CBFactionFieldsSquads(g) && TDBID.IsValid(lookout) && RandF() < 0.6
         && CBSpawnRoom(game) > CBConfig.TurfPatrolKeepRoom() {
        let body: EntityID;
        if CBSpawnGroup(game, lookout, n"", 1, n"CB_Favour", CBConfig.FavourDistance(), body) > 0 {
          this.m_favFaction = t.faction;
          this.m_favKind = 1;
          this.m_favBody = body;
          this.m_favUntil = now + CBConfig.FavourLifeTicks();
          let rt = CyberbaneRuntime.Get();
          if IsDefined(rt) {
            this.FavourPin(game, rt.lastSpawnAt, CBTf(n"Cyberbane-LivingStreet-AFavourForRunOffThe", [s"\(CBFactionLabel(t.faction))", s"\(CBFactionLabel(g))"]));
          }
          CBLog.Info(n"Street", s"A favour for \(NameToString(t.faction)): run off a \(NameToString(g)) lookout.");
          this.RestGang(game, t.faction);
          if IsDefined(t.npc) {
            t.npc.cbFavourRoll = 2;
          }
          return CBTalkSay(CBTf(n"Cyberbane-LivingStreet-OneOfLookoutsIsWatchingOur", [s"\(CBPossessive(CBFactionLabel(g)))"]), n"");
        }
      }
    }
    // Somebody somewhere else who owes them: a place, a pin, and the one who owes put there when V arrives.
    let place = this.StartDebt(sys, game, player, t.faction, now);
    if StrLen(place) > 0 {
      this.m_favChain = 0;
      if IsDefined(t.npc) {
        t.npc.cbFavourRoll = 2;
      }
      return CBTalkSay(CBTf(n"Cyberbane-LivingStreet-SomebodyInOwesUsAndKeeps", [s"\(place)"]), n"");
    }
    return CBTalkSay(CBT(n"Cyberbane-LivingStreet-NothingThatNeedsYouTodayAsk"), n"");
  }

  // V leaned on somebody (Reactions/StreetTalk.reds, Intimidate and Antagonize): was it the one who owes? A debt to
  // collect, for this gang, somewhere else; the place's name, or "" when there was nowhere.
  private func StartDebt(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, faction: CName, now: Int32) -> String {
    let at: Vector4;
    let where: CName;
    if !this.DebtPlace(sys, game, player, at, where) {
      return "";
    }
    this.m_favFaction = faction;
    this.m_favKind = 2;
    this.m_favAt = at;
    this.m_favDistrict = where;
    this.m_favPlaced = false;
    this.m_favFight = 0;
    this.m_favLeaned = false;
    this.m_favTarget = null;
    this.m_favUntil = now + CBConfig.FavourDebtLifeTicks();
    let place = NotEquals(where, n"") && NotEquals(where, sys.GetCurrentDistrict()) ? CBDistrictLabel(where) : CBT(n"Cyberbane-Allies-AFewBlocksOver");
    this.FavourPin(game, at, CBTf(n"Cyberbane-LivingStreet-AFavourForCollectADebt", [s"\(CBFactionLabel(faction))", s"\(place)"]));
    this.RestGang(game, faction);
    CBLog.Info(n"Street", s"A favour for \(NameToString(faction)): collect a debt in \(NameToString(where)).");
    return place;
  }

  // Frightened enough of V and they pay; otherwise they would sooner find out with their fists. The more the street
  // fears V, the likelier the first.
  public func NoteLeaned(npc: ref<ScriptedPuppet>) -> Void {
    let target = this.m_favTarget;
    if this.m_favKind == 2 && IsDefined(npc) && IsDefined(target) && Equals(npc.GetEntityID(), target.GetEntityID())
       && this.m_favFight == 0 && !this.m_favLeaned {
      let menace = CBMenaceScale(CyberbaneSystem.Get(npc.GetGame()));
      if RandF() < ClampF(CBConfig.FavourPayBase() + menace * CBConfig.FavourPayMenace(), 0.0, 0.9) {
        this.m_favLeaned = true;
      } else {
        this.m_favFight = 1;
      }
    }
  }

  // The one who owes is put at the place once V is close: somewhere round it V cannot see, as a Rival at their place is
  // (Rivals/Whereabouts.reds, CBLairTryPlace), minding their own business. On foot and calm, every third tick.
  private func DebtorArrive(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>, now: Int32) -> Void {
    let ppos = player.GetWorldPosition();
    let center = this.m_favAt;
    if this.m_favPlaced || now % 3 != 0 || Vector4.Distance(ppos, center) > CBConfig.LairPlaceDistance()
       || player.IsInCombat() || IsDefined(player.GetMountedVehicle()) || CBStoryHoldNow(game) || CBSpawnRoom(game) <= 0 {
      return;
    }
    let record = CBDebtorRecord(sys, this.m_favDistrict, this.m_favFaction);
    if !TDBID.IsValid(record) {
      return;
    }
    // No way in to the place any more (2.7.10, Spawn/StreetStories.reds, CBDropWayIn): they wait just outside instead,
    // and the pin moves with them. Placed only where V can walk, they were never placed at all, and the favour ran out.
    let outside: Vector4;
    if CBDropWayIn(sys, game, player, center, outside) {
      center = outside;
      this.m_favAt = outside;
      if StrLen(this.m_favPinText) > 0 {
        this.FavourPin(game, outside, this.m_favPinText);
      }
      CBLog.Info(n"Street", "The debtor's place had no way in; they wait just outside.");
    }
    let fwd = player.GetWorldForward();
    let k = 0;
    while k < 13 {
      let px = center.X;
      let py = center.Y;
      if k > 0 && k <= 6 {
        let angIn = Cast<Float>(k - 1) * 1.0472;
        px = center.X + CosF(angIn) * CBConfig.LairSearchRadius();
        py = center.Y + SinF(angIn) * CBConfig.LairSearchRadius();
      }
      if k > 6 {
        let angOut = Cast<Float>(k - 7) * 1.0472 + 0.5236;
        px = center.X + CosF(angOut) * CBConfig.LairOuterSearchRadius();
        py = center.Y + SinF(angOut) * CBConfig.LairOuterSearchRadius();
      }
      k += 1;
      let snapped: Vector4;
      let spot: Vector4;
      if CBNavSnap(game, px, py, center.Z, snapped) && CBSettleOnGround(game, snapped, spot)
         && Vector4.Distance(spot, ppos) >= CBConfig.LairMinDistance() && !CBSafeAreaBlocksSpawn(game, spot)
         && CBPointHiddenFrom(game, ppos, fwd, spot) && CBStandsWith(game, spot, center, 8.0) && CBPointReachable(game, spot, ppos) {
        let yaw = RandRangeF(0.0, 6.2831);
        let facing = Quaternion.BuildFromDirectionVector(new Vector4(CosF(yaw), SinF(yaw), 0.0, 0.0));
        let body: EntityID;
        if CBCreateSpawn(des, record, n"", spot, facing, n"CB_Debtor", body) {
          this.m_favBody = body;
          this.m_favPlaced = true;
          CBLog.Info(n"Street", "The one who owes is at the place.");
        }
        return;
      }
    }
  }

  // They put their fists up: hostile to V alone, the way a wannabe squares up (Spawn/Wannabe.reds).
  private func DebtorSwings(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
    CBCancelMove(p);
    CBGrantAbility(p as NPCPuppet, t"Ability.IsAggressive");
    CBMakeHostileToPlayer(game, p);
    if CBMessagesOn() {
      CBOverheard(game, CBT(n"Cyberbane-LivingStreet-OwesMoney"), CBLineOf([CBT(n"Cyberbane-LivingStreet-PayThoseThievesComeAndTake"),
                                                CBT(n"Cyberbane-LivingStreet-IMNotPayingYouWant"),
                                                CBT(n"Cyberbane-LivingStreet-FistsThenWinnerKeepsTheMoney")]), true);
    }
  }

  private func Favour(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>, now: Int32) -> Void {
    if !this.FavourOpen() {
      return;
    }
    // Gone from the world by something else of ours (FavourTargetGone): the job is over, said so, and it does not count
    // as the gang's favour given.
    if this.FavourTargetGone(des) {
      CBLog.Info(n"Street", "A favour's person was taken out of the world by something else; the favour is off.");
      this.FavourLost(game, this.m_favKind == 1 ? CBT(n"Cyberbane-LivingStreet-ForgetItTheLookoutSGone")
                            : (this.m_favKind == 2 ? CBT(n"Cyberbane-LivingStreet-ForgetItTheyPaidUpBefore")
                                                   : CBT(n"Cyberbane-Contracts-Lost")));
      return;
    }
    this.FavourKeepPin(sys, game);
    if this.m_favKind == 3 {
      this.ContractStep(sys, game, des, player, now);
      return;
    }
    let done = false;
    if this.m_favKind == 1 {
      // Run off by V or V's side (CBTakenOutByVSide). Somebody else putting the lookout down is not V doing the favour.
      let p = GameInstance.FindEntityByID(game, this.m_favBody) as ScriptedPuppet;
      done = CBTakenOutByVSide(game, p);
      // And it is over: it waited out its clock with nobody left to run off and nothing on the map, holding every other
      // favour back, as the one who owes and a contract's mark never did.
      if !done && IsDefined(p) && CBIsDown(p) {
        CBLog.Info(n"Street", "A favour's lookout was put down by somebody else; the favour is off.");
        this.FavourLost(game, CBT(n"Cyberbane-LivingStreet-ForgetItTheLookoutSGone"));
        return;
      }
    } else {
      this.DebtorArrive(sys, game, des, player, now);
      let debtor = this.m_favTarget;
      if this.m_favPlaced && !IsDefined(debtor) {
        let body = GameInstance.FindEntityByID(game, this.m_favBody) as ScriptedPuppet;
        if CBNpcSafe(sys, body) {
          body.cbFavourMark = true;
          this.m_favTarget = body;
          debtor = body;
          CBTrackOnMap(game, body);
        }
      }
      done = this.m_favLeaned;
      if IsDefined(debtor) {
        // Dead: nobody pays from a body bag. By V's hand, the gang thinks less of V for it; by somebody else's, it is
        // just over.
        if debtor.IsDead() {
          let byV = debtor.cbDamagedByPlayer && !CBLastHitWasOthers(game, debtor);
          if byV {
            let fs = sys.EnsureFaction(this.m_favFaction);
            if IsDefined(fs) && !CBReputationFrozen() {
              fs.standing = ClampF(fs.standing - CBConfig.FavourKillStanding(), -100.0, 100.0);
            }
            CBFileLog(sys, n"FavourKilled", CBGameSeconds(game), CBEventDistrict(sys, game), this.m_favFaction, 0.0);
          }
          if !byV {
            this.FavourLost(game, CBT(n"Cyberbane-LivingStreet-ForgetItSomebodyGotToThem"));
            return;
          }
          if CBMessagesOn() {
            CBPhoneFromAlly(game, this.m_favFaction, CBT(n"Cyberbane-LivingStreet-YouKilledThemNobodyPaysFrom"));
          }
          this.FavourEnd(game);
          return;
        }
        // Hurt by V before a word was said: that is the fight. It used to end the favour on the spot.
        if this.m_favFight == 0 && !done && debtor.cbDamagedByPlayer {
          this.m_favFight = 1;
        }
        if this.m_favFight == 1 && !debtor.cbTalkPartner && CBStillStanding(debtor) {
          this.DebtorSwings(game, debtor);
          this.m_favFight = 2;
          this.m_favFightTick = now;
        }
        if this.m_favFight == 2 {
          if CBIsDown(debtor) || !CBStillStanding(debtor) {
            done = true;   // beaten, and breathing: they pay
          } else {
            let hp = CBSamplePlayerHp(game, player);
            if hp >= 0.0 && hp < CBConfig.WannabeLoseHealth() {
              CBWannabeStandDown(game, debtor);
              if CBMessagesOn() {
                CBPhoneFromAlly(game, this.m_favFaction, CBT(n"Cyberbane-LivingStreet-HeardTheyPutYouOnThe"));
              }
              this.FavourEnd(game);
              return;
            }
            if now - this.m_favFightTick > 3
               && Vector4.Distance(player.GetWorldPosition(), debtor.GetWorldPosition()) > CBConfig.WannabeWalkAwayDistance() {
              CBWannabeStandDown(game, debtor);
              if CBMessagesOn() {
                CBPhoneFromAlly(game, this.m_favFaction, CBT(n"Cyberbane-LivingStreet-TheyReStillNotPayingForget"));
              }
              this.FavourEnd(game);
              return;
            }
          }
        }
      }
    }
    if done {
      this.FavourDone(sys, game, player);
      return;
    }
    if now >= this.m_favUntil {
      if CBMessagesOn() {
        // What happened, for each kind: "somebody else handled it" fit neither a debt nor a lookout plainly.
        CBPhoneFromAlly(game, this.m_favFaction, this.m_favKind == 2 ? CBT(n"Cyberbane-LivingStreet-ForgetItTheyPaidUpBefore")
                                                                     : CBT(n"Cyberbane-LivingStreet-ForgetItTheLookoutSGone"));
      }
      this.FavourEnd(game);
    }
  }

  private func FavourDone(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let faction = this.m_favFaction;
    let pay = CBConfig.FavourPay() + RandRange(0, CBConfig.FavourPay() / 2 + 1);
    if this.m_favKind == 2 {
      pay += CBConfig.FavourPay();   // the debt, less their cut, for a trip across town
    }
    let beaten = this.m_favKind == 2 && this.m_favFight == 2;
    CBStreetGiveMoney(game, pay);
    CBTalkWarm(sys, game, faction, CBConfig.FavourWarmth(), CBConfig.PostureAllied() - 1.0);
    let tip = "";
    if RandF() < CBConfig.FavourTipChance() {
      let i = CBIntelGive(sys, game, player, faction, true);
      if i.kind != CBIntelNone() {
        tip = CBTf(n"Cyberbane-LivingStreet-AndSomethingExtra", [CBIntelWritten(i)]);
      }
    }
    CBFileLog(sys, n"Favour", CBGameSeconds(game), CBEventDistrict(sys, game), faction, Cast<Float>(pay));
    if CBMessagesOn() {
      CBPhoneFromAlly(game, faction, beaten ? CBTf(n"Cyberbane-LivingStreet-HeardYouHadToPutThem", [s"\(pay)", s"\(tip)"])
                                            : CBTf(n"Cyberbane-LivingStreet-SawWhatYouDidEbAnd", [s"\(pay)", s"\(tip)"]));
    }
    CBLog.Info(n"Street", s"A favour for \(NameToString(faction)) done; \(pay)eb.");
    let chainable = this.m_favKind == 2 && this.m_favChain < 2;
    this.FavourEnd(game);
    // A name given up: somebody else who owes them, somewhere else, two links at most.
    if chainable && RandF() < CBConfig.FavourChainChance() {
      let next = this.StartDebt(sys, game, player, faction, sys.GetTickCount());
      if StrLen(next) > 0 {
        this.m_favChain += 1;
        if CBMessagesOn() {
          CBPhoneFromAlly(game, faction, CBTf(n"Cyberbane-LivingStreet-TheyGaveUpANameBefore", [s"\(next)"]));
        }
      }
    }
  }

  // ---- Corporate contracts ----------------------------------------------------------------------------
  //
  // A corporation's people are almost never on the street to be helped, spared or fought beside, and Kang Tao's only
  // rival, Arasaka, almost never comes out either.

  private func ContractOffer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, now: Int32, busy: Bool) -> Void {
    if this.m_contractNext == 0 {
      this.m_contractNext = now + CBConfig.CorpContractEveryTicks();   // never the moment a save loads
      return;
    }
    if this.FavourOpen() || busy || now < this.m_contractNext || !CBCorpWorkOn() || !CBMessagesOn() {
      return;
    }
    this.m_contractNext = now + CBConfig.CorpContractEveryTicks();
    if player.IsInCombat() || RandF() >= CBConfig.CorpContractChance() {
      return;
    }
    let client = this.ContractClient(sys, game);
    let mark = IsNameValid(client) ? this.ContractMarkGang(sys, client) : n"";
    if !IsNameValid(mark) {
      return;
    }
    let at: Vector4;
    let where: CName;
    if !this.DebtPlace(sys, game, player, at, where) {
      CBLog.Info(n"Street", "No contract this time: nowhere to put the mark.");
      return;
    }
    this.m_favFaction = client;
    this.m_favKind = 3;
    this.m_favMark = mark;
    this.m_favAt = at;
    this.m_favDistrict = where;
    this.m_favPlaced = false;
    this.m_favFight = 0;
    this.m_favLeaned = false;
    this.m_favTarget = null;
    this.m_favChain = 0;
    this.m_favUntil = now + CBConfig.CorpContractLifeTicks();
    this.m_contractPay = CBConfig.CorpContractPay() + RandRange(0, CBConfig.CorpContractPay() / 2 + 1);
    let place = NotEquals(where, n"") && NotEquals(where, sys.GetCurrentDistrict()) ? CBDistrictLabel(where) : CBT(n"Cyberbane-Allies-AFewBlocksOver");
    this.FavourPin(game, at, CBTf(n"Cyberbane-Contracts-Pin", [CBFactionLabel(client), CBFactionLabel(mark)]));
    this.RestGang(game, client);
    CBPhoneFromAlly(game, client, CBTf(n"Cyberbane-Contracts-Offer", [CBFactionLabel(mark), place, s"\(this.m_contractPay)"]));
    CBLog.Info(n"Street", s"A contract from \(NameToString(client)): one of \(NameToString(mark))'s people in \(NameToString(where)), \(this.m_contractPay)eb.");
  }

  // Who offers: a corporation that is on, doesn't hate V and has a rival to send V after, more often the better it
  // thinks of V, so the one V works for is the one that keeps calling.
  private func ContractClient(sys: ref<CyberbaneSystem>, game: GameInstance) -> CName {
    let score = sys.GetScore();
    if !IsDefined(score) {
      return n"";
    }
    let corps: array<CName> = [n"Arasaka", n"Militech", n"KangTao"];
    let names: array<CName>;
    let weights: array<Float>;
    let total = 0.0;
    for c in corps {
      let posture = score.GetPosture(c);
      if CBFactionOn(c) && !this.GangResting(game, c) && IsNameValid(this.ContractMarkGang(sys, c))
         && (Equals(posture, ECBPosture.Neutral) || Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied)) {
        let fs = sys.FindFaction(c);
        let w = MaxF(1.0, (IsDefined(fs) ? fs.standing : 0.0) + 30.0);
        ArrayPush(names, c);
        ArrayPush(weights, w);
        total += w;
      }
    }
    if ArraySize(names) == 0 {
      return n"";
    }
    let roll = RandRangeF(0.0, total);
    let i = 0;
    while i < ArraySize(names) && i < ArraySize(weights) {
      roll -= weights[i];
      if roll <= 0.0 {
        return names[i];
      }
      i += 1;
    }
    return names[ArraySize(names) - 1];
  }

  // Whose people the mark is: one of the client's rivals that is on and has people of its own to put there.
  private func ContractMarkGang(sys: ref<CyberbaneSystem>, client: CName) -> CName {
    let out: array<CName>;
    for g in CBGangRivalsOf(sys.GetContent(), client) {
      if CBFactionOn(g) && TDBID.IsValid(this.ContractRecord(sys, g, true)) {
        ArrayPush(out, g);
      }
    }
    return ArraySize(out) > 0 ? out[RandRange(0, ArraySize(out))] : n"";
  }

  // The mark is one of their best; the guards their rank and file. Only people (CBHunterRecordFit).
  private func ContractRecord(sys: ref<CyberbaneSystem>, gang: CName, mark: Bool) -> TweakDBID {
    let rec = mark ? CBApexRosterRecord(gang, 0) : CBGangTemplate(sys, gang);
    if !CBHunterRecordFit(rec) {
      rec = mark ? CBGangTemplate(sys, gang) : CBApexRosterRecord(gang, RandRange(1, 4));
    }
    return CBHunterRecordFit(rec) ? rec : TDBID.None();
  }

  // The mark and their guards put round the place once V is close, out of V's sight, the way the one who owes is
  // (DebtorArrive): on foot and calm, every third tick, all of them in one go.
  private func ContractArrive(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                              player: ref<PlayerPuppet>, now: Int32) -> Void {
    let ppos = player.GetWorldPosition();
    let center = this.m_favAt;
    let want = 1 + CBConfig.CorpContractGuards();
    if this.m_favPlaced || now % 3 != 0 || Vector4.Distance(ppos, center) > CBConfig.LairPlaceDistance()
       || player.IsInCombat() || IsDefined(player.GetMountedVehicle()) || CBStoryHoldNow(game) || CBSpawnRoom(game) < want {
      return;
    }
    let markRec = this.ContractRecord(sys, this.m_favMark, true);
    let guardRec = this.ContractRecord(sys, this.m_favMark, false);
    if !TDBID.IsValid(markRec) {
      return;
    }
    let fwd = player.GetWorldForward();
    let placed = 0;
    let k = 0;
    while k < 13 && placed < want {
      let px = center.X;
      let py = center.Y;
      if k > 0 && k <= 6 {
        let angIn = Cast<Float>(k - 1) * 1.0472;
        px = center.X + CosF(angIn) * CBConfig.LairSearchRadius();
        py = center.Y + SinF(angIn) * CBConfig.LairSearchRadius();
      }
      if k > 6 {
        let angOut = Cast<Float>(k - 7) * 1.0472 + 0.5236;
        px = center.X + CosF(angOut) * CBConfig.LairOuterSearchRadius();
        py = center.Y + SinF(angOut) * CBConfig.LairOuterSearchRadius();
      }
      k += 1;
      let snapped: Vector4;
      let spot: Vector4;
      if CBNavSnap(game, px, py, center.Z, snapped) && CBSettleOnGround(game, snapped, spot)
         && Vector4.Distance(spot, ppos) >= CBConfig.LairMinDistance() && !CBSafeAreaBlocksSpawn(game, spot)
         && CBPointHiddenFrom(game, ppos, fwd, spot) && CBStandsWith(game, spot, center, 8.0) && CBPointReachable(game, spot, ppos) {
        let yaw = RandRangeF(0.0, 6.2831);
        let facing = Quaternion.BuildFromDirectionVector(new Vector4(CosF(yaw), SinF(yaw), 0.0, 0.0));
        let rec = placed == 0 || !TDBID.IsValid(guardRec) ? markRec : guardRec;
        let body: EntityID;
        if CBCreateSpawn(des, rec, n"", spot, facing, n"CB_Mark", body) {
          if placed == 0 {
            this.m_favBody = body;
          }
          placed += 1;
        }
      }
    }
    if placed > 0 {
      this.m_favPlaced = true;
      CBLog.Info(n"Street", s"The contract's mark is at the place, with \(placed - 1) guards.");
    }
  }

  private func ContractStep(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>,
                            player: ref<PlayerPuppet>, now: Int32) -> Void {
    this.ContractArrive(sys, game, des, player, now);
    let mark = this.m_favTarget;
    if this.m_favPlaced && !IsDefined(mark) {
      let body = GameInstance.FindEntityByID(game, this.m_favBody) as ScriptedPuppet;
      if CBNpcSafe(sys, body) {
        body.cbFavourMark = true;
        this.m_favTarget = body;
        mark = body;
        CBTrackOnMap(game, body);
      }
    }
    if IsDefined(mark) {
      if CBTakenOutByVSide(game, mark) {
        this.ContractDone(sys, game);
        return;
      }
      // Somebody else got there first: the file is closed, nothing owed either way.
      if CBIsDown(mark) {
        CBLog.Info(n"Street", "A contract's mark was put down by somebody else.");
        this.FavourLost(game, CBT(n"Cyberbane-Contracts-Lost"));
        return;
      }
    }
    if now >= this.m_favUntil {
      if CBMessagesOn() {
        CBPhoneFromAlly(game, this.m_favFaction, CBT(n"Cyberbane-Contracts-Expired"));
      }
      this.FavourEnd(game);
    }
  }

  private func ContractDone(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let client = this.m_favFaction;
    let pay = this.m_contractPay;
    CBStreetGiveMoney(game, pay);
    CBCreditContract(sys, client, CBConfig.CorpContractStanding());
    CBTalkSlight(sys, game, this.m_favMark, CBConfig.CorpContractMarkSlight());
    let mult = 1.0;
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      mult = rt.GetSettings().renownGainMult;
    }
    sys.AddRenownPoints(CBConfig.CorpContractRenown() * mult);
    CBFileLog(sys, n"Contract", CBGameSeconds(game), CBEventDistrict(sys, game), client, Cast<Float>(pay));
    if CBMessagesOn() {
      CBPhoneFromAlly(game, client, CBTf(n"Cyberbane-Contracts-Done", [s"\(pay)"]));
    }
    CBLog.Info(n"Street", s"A contract for \(NameToString(client)) done; \(pay)eb.");
    this.FavourEnd(game);
  }

  // An open favour is always on the map.
  private func FavourKeepPin(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let who: ref<ScriptedPuppet> = this.m_favTarget;
    if this.m_favKind == 1 {
      who = GameInstance.FindEntityByID(game, this.m_favBody) as ScriptedPuppet;
      if CBNpcSafe(sys, who) && CBStillStanding(who) {
        this.m_favPinAt = who.GetWorldPosition();
      }
    }
    if IsDefined(who) && who.IsAttached() && who.cbMapped {
      this.FavourUnpin(game);
      return;
    }
    if !this.m_favPinned && StrLen(this.m_favPinText) > 0 {
      this.FavourPin(game, this.m_favPinAt, this.m_favPinText);
    }
  }

  // Taken out of the world by something else of ours: no longer wearing the tag they were put out with, and not still
  // being made.
  private func FavourTargetGone(des: ref<DynamicEntitySystem>) -> Bool {
    if !IsDefined(des) || !EntityID.IsDefined(this.m_favBody) || (this.m_favKind != 1 && !this.m_favPlaced) {
      return false;
    }
    let tag = this.m_favKind == 1 ? n"CB_Favour" : (this.m_favKind == 2 ? n"CB_Debtor" : n"CB_Mark");
    return !des.IsTagged(this.m_favBody, tag) && !des.IsSpawning(this.m_favBody);
  }

  // Over through nobody's fault of V's: said, and the gang can be asked again straight away. Its rest is for a favour
  // given, and this one was taken away.
  private func FavourLost(game: GameInstance, line: String) -> Void {
    if CBMessagesOn() && StrLen(line) > 0 {
      CBPhoneFromAlly(game, this.m_favFaction, line);
    }
    let i = ArrayFindFirst(this.m_favRestGang, this.m_favFaction);
    if i >= 0 {
      ArrayErase(this.m_favRestGang, i);
      if i < ArraySize(this.m_favRestUntil) {
        ArrayErase(this.m_favRestUntil, i);
      }
    }
    this.FavourEnd(game);
  }

  private func FavourPin(game: GameInstance, at: Vector4, text: String) -> Void {
    this.FavourUnpin(game);
    this.m_favPinText = text;
    this.m_favPinAt = at;
    let ms = GameInstance.GetMappinSystem(game);
    if !IsDefined(ms) || !CBMapMarkersOn() || (at.X == 0.0 && at.Y == 0.0) {
      return;
    }
    this.m_favPin = ms.RegisterMappin(CBPlacePinData(CBEventPinCaption(text)), at);
    this.m_favPinned = true;
  }

  private func FavourUnpin(game: GameInstance) -> Void {
    if !this.m_favPinned {
      return;
    }
    let ms = GameInstance.GetMappinSystem(game);
    if IsDefined(ms) {
      ms.UnregisterMappin(this.m_favPin);
    }
    this.m_favPinned = false;
  }

  private func FavourEnd(game: GameInstance) -> Void {
    this.FavourUnpin(game);
    let target = this.m_favTarget;
    if IsDefined(target) {
      target.cbFavourMark = false;
      CBUntrackOnMap(game, target);
    }
    this.m_favFaction = n"";
    this.m_favKind = 0;
    this.m_favTarget = null;
    // Nobody's any more: a debt or a contract only sets it once its person is put at the place, and an old id left here
    // read as their person gone (FavourTargetGone).
    let none: EntityID;
    this.m_favBody = none;
    this.m_favPinText = "";
    this.m_favPlaced = false;
    this.m_favFight = 0;
    this.m_favDistrict = n"";
    this.m_favMark = n"";
    this.m_contractPay = 0;
    CBDeleteTaggedSafe(game, n"CB_Favour", true, true);
    CBDeleteTaggedSafe(game, n"CB_Debtor", true, true);
    CBDeleteTaggedSafe(game, n"CB_Mark", true, true);
  }

  // ---- The sit-down ----------------------------------------------------------------------------------------

  // The sit-down and gang life's other events, one at a time (Spawn/StreetEvents.reds).
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
    // Held where they kneel for as long as a hold always was here: the conversation's own holds are short now.
    CBTalkHold(npc, CBConfig.SurrenderHoldSeconds());
    npc.cbSurrendered = true;
    npc.cbGaveUp = true;
    CBSayVoiced(sys, npc, n"fear_beg");   // in their own voice (Narrative/Telling.reds, [79])
    npc.SetScannerDirty(true);   // the scanner says so (UI/ScannerName.reds)
    ArrayPush(this.m_gaveUp, npc);
    ArrayPush(this.m_gaveUpTick, sys.GetTickCount());
    this.HandOffSurrendered(sys, game, des, npc);
    CBIntelSay(game, 3, CBIntelSpeaker(CBClassifyFaction(npc)), CBGangSurrenderLine(CBClassifyFaction(npc)), 3.5);
    CBLog.Info(n"Street", "An enemy gave up instead of running.");
    return true;
  }

  // One of ours with their hands up is out of the fight, as one who ran clear is (Reactions/CombatFlee.reds,
  // CBRunnerGotAway).
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
          // Let go with their life: their gang hears that V let one walk, the way a mercy is heard, and V's name for
          // restraint grows. Not for somebody V grabbed and questioned, who was let go already.
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
        // They leave with a line that sets up their next fight with V, and they will come for it ([E4]).
        let ally = sys.FindRivalById(this.m_allyRival);
        // What it does to them, whatever the message setting: with messages off they went on the lane at once and never
        // took up the grudge, since both sat inside the line's own test.
        if IsDefined(ally) {
          ally.huntTicks = Max(ally.huntTicks, CBConfig.RivalAfterEscapeTicks());
          CBRivalGiveTrait(ally, n"GrudgeBearer");
        }
        if IsDefined(ally) && CBMessagesOn() {
          CBIntelSay(game, 3, CBRivalDisplayName(sys.GetContent(), ally), CBPick3(CBT(n"Cyberbane-LivingStreet-WeReSquareForTodayNext"),
            CBT(n"Cyberbane-LivingStreet-DonTThankMeNobodyElse"), CBT(n"Cyberbane-LivingStreet-EnjoyItTheNextFightS")), 4.0);
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
    // Not while V has a borrowed crew along (Reactions/Allies.reds): both are CB_Ally, and this one's clean-up is by
    // tag.
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
          let withThem = CBGangTemplate(sys, r.faction);
          if TDBID.IsValid(withThem) {
            let second: EntityID;
            CBSpawnGroup(game, withThem, n"", 1, n"CB_Ally", 32.0, second);
          }
          // On their cooldown while they are out helping, as after any fight of theirs: the Rival lane
          // picking them meanwhile put a second of them in the street, after V.
          r.huntTicks = Max(r.huntTicks, CBConfig.RivalAfterEscapeTicks());
          this.m_allyOut = true;
          this.m_allyRival = r.id;
          this.m_allyEnemy = enemy;
          this.m_allyCalm = 0;
          this.m_allyDay = CBGameDay(game);
          // On V's side for once: no taunts to send back under it.
          CBPhoneSendAside(game, CBRivalDisplayName(sys.GetContent(), r), CBT(n"Cyberbane-LivingStreet-NobodyKillsYouButMeKeep"), CBHudRed());
          // And they say so as they arrive, in the street ([E4]).
          CBAnnounceLater(game, CBRivalDisplayName(sys.GetContent(), r), CBPick2(CBT(n"Cyberbane-LivingStreet-NobodyKillsThisOneButMe"), CBT(n"Cyberbane-LivingStreet-BackOffThisMercSMine")), 2.5);
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
  return Equals(kind, n"RivalCreated") || Equals(kind, n"RivalSlain") || Equals(kind, n"RivalDied") || Equals(kind, n"TurfTaken") || Equals(kind, n"TurfPush")
      || Equals(kind, n"KinSworn") || Equals(kind, n"CalledOut") || Equals(kind, n"Allied") || Equals(kind, n"Peace")
      || Equals(kind, n"RivalExiled") || Equals(kind, n"MeetCrashed") || Equals(kind, n"BagmanRobbed");
}

// A bagman sees V coming for him: close, and either with a weapon out or at a sprint.
func CBBagmanSeesVComing(game: GameInstance, player: ref<PlayerPuppet>, bagman: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(player) || !IsDefined(bagman) {
    return false;
  }
  let d = Vector4.Distance(player.GetWorldPosition(), bagman.GetWorldPosition());
  if d > CBConfig.BagmanSpotDistance() {
    return false;
  }
  if IsDefined(GameObject.GetActiveWeapon(player)) {
    return true;
  }
  let psm = CBPlayerPSM(game);
  return IsDefined(psm) && psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion) == EnumInt(gamePSMLocomotionStates.Sprint);
}

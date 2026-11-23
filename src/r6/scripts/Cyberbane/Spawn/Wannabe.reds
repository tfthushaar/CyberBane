// Cyberbane - Wannabes ([1], 2.3.1)
//
// Once V's name means something, a kid out to make theirs walks up and squares up, fists only. Win, walk away
// or lose, and the street hears how it went.
//
// One at a time, out of sight to start with, never in a safe area, a quest area, on a job, in a scene or with a
// hunt on. Spawned from a record the game itself arms with fists (Character.*_melee1_fists_* and the like), by
// the district: a Tyger Claws hopeful in Watson, a Valentino in Heywood, an Animal in Santo Domingo and
// Pacifica, a scav out past the walls. Nothing is given or taken from anybody; no gun ever enters it, unless V
// brings one, and the street notices that too.
//
//   approach  they walk up (one move order at a time, CBIssueMove), and within a few metres say their piece and
//             turn hostile to V alone
//   the fight V puts them down (a win), V's health drops too far (they stand down and gloat: a loss), or V walks
//             off (the kid tells everybody V would not fight)
//   after     they stand down if still up, and are removed once V is not looking (CBDeleteTaggedSafe)
//
// Tagged CB_Wannabe, one of the street's own (CBStreetTags), so the combat release, the sanctuary hold and the
// re-arm watch reach them. Set up as a street person (CBSetUpStreet, Spawn/Spawner.reds). Session state only,
// in the street book: a load drops whoever was out, and the world drops them with it.

public func CBWannabesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().wannabes;
}

public func CBWannabeNone() -> Int32 = 0
public func CBWannabeWalking() -> Int32 = 1
public func CBWannabeFighting() -> Int32 = 2
public func CBWannabeDone() -> Int32 = 3

// A record the game arms with fists, for whoever would have kids on this district's corners.
func CBWannabeRecord(district: CName) -> TweakDBID {
  let i = CBDistrictIndex(district);
  let id: TweakDBID;
  if i == 3 {
    id = t"Character.valentinos_grunt4_hmelee2_fists_mb_rare";
  } else {
    if i == 4 || i == 5 {
      id = t"Character.animals_grunt1_melee1_fists_mb";
    } else {
      if i == 6 || i == 7 {
        id = RandF() < 0.5 ? t"Character.scavenger_grunt1_melee1_fists_ma" : t"Character.scavenger_grunt1_melee1_fists_wa";
      } else {
        id = RandF() < 0.5 ? t"Character.tyger_claws_gangster1_melee1_fists_ma" : t"Character.tyger_claws_biker1_melee1_fists_wa";
      }
    }
  }
  // Only a record that is really there and is a person nobody wrote.
  if !IsDefined(TweakDBInterface.GetCharacterRecord(id)) || !CBRecordIsPerson(id) || CBRecordUnfitTemplate(id) {
    return TDBID.None();
  }
  return id;
}

// Once a tick from the fast tick.
public func CBWannabeTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBStreetBook.Get(game);
  let player = GetPlayer(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) || !IsDefined(des) || !CBWorldStable(game) {
    return;
  }
  let busy = sys.GetStoryHold() != CBStoryNone() || sys.IsInQuestArea() || sys.IsOnJob() || sys.IsInSanctuary()
          || sys.IsInSafeZone() || CBPlayerInScene(game);
  if book.wannabeStage == CBWannabeNone() {
    // Not on home ground, nor in the quiet a night at home bought (2.7.1, Spawn/HomeGround.reds).
    if !busy && !CBHomeKeepsOut(sys) && !CBSleepPeace(game) && sys.GetTickCount() % 5 == 0 {
      CBWannabeMaybe(sys, game, book, player);
    }
    return;
  }
  let p = GameInstance.FindEntityByID(game, book.wannabeId) as ScriptedPuppet;
  let age = sys.GetTickCount() - book.wannabeTick;
  if !CBWannabesOn() || busy || age < 0 {
    CBWannabeEnd(game, book);
    return;
  }
  if !IsDefined(p) || !p.IsAttached() {
    if age > CBConfig.WannabeSpawnGraceTicks() && !des.IsSpawning(book.wannabeId) {
      CBWannabeEnd(game, book);
    }
    return;
  }
  let d = Vector4.Distance(p.GetWorldPosition(), player.GetWorldPosition());
  if book.wannabeStage == CBWannabeWalking() {
    if !CBStillStanding(p) {
      CBWannabeWon(sys, game, book, p);   // V got to them first
      return;
    }
    if !CBNpcSafe(sys, p) {
      return;
    }
    if d <= CBConfig.WannabeChallengeDistance() || CBNpcInCombat(p) {
      CBWannabeChallenge(sys, game, book, p);
      return;
    }
    if age > CBConfig.WannabeApproachTicks() || d > CBConfig.WannabeLoseInterestDistance() {
      CBWannabeEnd(game, book);   // never reached V: nothing happened, nothing is said
      return;
    }
    if age % 4 == 1 && !p.cbTalkPartner {
      CBWannabeWalkTo(p, player.GetWorldPosition());
      CBWannabeFriendsWalk(sys, game, des, player);
    }
    return;
  }
  if book.wannabeStage == CBWannabeFighting() {
    let inFight = sys.GetTickCount() - book.wannabeStageTick;
    if !CBStillStanding(p) {
      CBWannabeWon(sys, game, book, p);
      return;
    }
    let hp = CBSamplePlayerHp(game, player);
    if hp >= 0.0 && hp < CBConfig.WannabeLoseHealth() {
      CBWannabeLost(sys, game, book, p);
      return;
    }
    if d > CBConfig.WannabeWalkAwayDistance() && inFight > 3 {
      CBWannabeWalked(sys, game, book, p);
      return;
    }
    if inFight > CBConfig.WannabeFightTicks() {
      book.wannabeStage = CBWannabeDone();
      CBWannabeStandDown(game, p);
    }
    return;
  }
  // Done: gone once V is not looking, or the body is swept like any of ours.
  if age > CBConfig.WannabeLifeTicks() || d > CBConfig.TurfPatrolLeaveDistance() {
    CBWannabeEnd(game, book);
  }
}

func CBWannabeMaybe(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, player: ref<PlayerPuppet>) -> Void {
  let now = CBGameSeconds(game);
  if !CBWannabesOn() || now < book.wannabeNext || player.IsInCombat() || IsDefined(player.GetMountedVehicle())
     || CBPlayerIndoors(game) || CBPlayerMasked(game) || CBHuntersOut(sys, game) || CBHuntPending(sys) || CBPoliceOnV(sys)
     || CBSpawnRoom(game) < 1 + CBConfig.TurfPatrolKeepRoom() {
    return;
  }
  let score = sys.GetScore();
  if !IsDefined(score) || EnumInt(score.GetTier()) < EnumInt(ECBRenownTier.KnownMerc) {
    return;
  }
  book.wannabeNext = now + CBConfig.WannabeGapHours() * CBConfig.SecondsPerHour() * (0.75 + RandF() * 0.5);
  let district = sys.GetCurrentDistrict();
  // Where V's name is newest (2.6.5): talked about but not yet a legend, the kids want it most; where nobody knows V
  // there is nothing to win, and where V is a legend few dare.
  if RandF() >= CBConfig.WannabeChance() * CBWannabeDistrictPull(sys, district) {
    return;
  }
  let record = CBWannabeRecord(district);
  if !TDBID.IsValid(record) {
    return;
  }
  let body: EntityID;
  if CBSpawnGroup(game, record, n"", 1, n"CB_Wannabe", CBConfig.TurfPatrolDistance(), body) > 0 {
    book.wannabeId = body;
    book.wannabeTick = sys.GetTickCount();
    book.wannabeStage = CBWannabeWalking();
    book.wannabeDistrict = district;
    // Friends to watch (2.6.5), who carry the story whichever way it goes. Only with room to spare.
    let friends = 0;
    if CBSpawnRoom(game) > CBConfig.WannabeFriends() + CBConfig.TurfPatrolKeepRoom() {
      let friendBody: EntityID;
      friends = CBSpawnGroup(game, record, n"", CBConfig.WannabeFriends(), n"CB_Wannabe", CBConfig.TurfPatrolDistance(), friendBody, n"CB_WannabeFriend");
    }
    CBLog.Info(n"Street", s"A wannabe is coming to make a name off V\(friends > 0 ? s", with \(friends) friends to watch" : "").");
  }
}

// How much more likely a wannabe is here (2.6.5), by how V's name stands in the district.
func CBWannabeDistrictPull(sys: ref<CyberbaneSystem>, district: CName) -> Float {
  let ds = IsDefined(sys) && NotEquals(district, n"") ? sys.FindDistrict(district) : null;
  let renown = IsDefined(ds) ? ds.renown : 0.0;
  if renown < 10.0 {
    return 0.5;
  }
  if renown < 55.0 {
    return 1.6;
  }
  return renown < 80.0 ? 1.0 : 0.4;
}

// The friends keep up, and stop where they can see (2.6.5).
func CBWannabeFriendsWalk(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>) -> Void {
  for id in des.GetTaggedIDs(n"CB_WannabeFriend") {
    let f = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, f) && CBStillStanding(f) && !CBNpcInCombat(f) && !f.cbTalkPartner {
      CBStreetWalkNear(f, player.GetWorldPosition(), 9.0);
    }
  }
}

// How many friends are still watching, and send them off with what they saw.
func CBWannabeFriendsLeave(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return 0;
  }
  let n = 0;
  for id in des.GetTaggedIDs(n"CB_WannabeFriend") {
    let f = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if CBNpcSafe(sys, f) && CBStillStanding(f) {
      n += 1;
      CBWannabeStandDown(game, f);
    }
  }
  return n;
}

func CBWannabeWalkTo(p: ref<ScriptedPuppet>, to: Vector4) -> Void {
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
  cmd.ignoreInCombat = true;
  cmd.alwaysUseStealth = false;
  cmd.ignoreNavigation = false;
  cmd.finishWhenDestinationReached = true;
  cmd.desiredDistanceFromTarget = 2.5;
  CBIssueMove(p, ai, cmd);
}

func CBWannabeChallenge(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeFighting();
  book.wannabeStageTick = sys.GetTickCount();
  CBCancelMove(p);
  CBGrantAbility(p as NPCPuppet, t"Ability.IsAggressive");
  CBMakeHostileToPlayer(game, p);
  if CBMessagesOn() {
    let st = CBReadStreet(sys, game, n"");
    let you = StrLen(st.title) > 0 ? st.title : CBT(n"Cyberbane-Telling-TheMercEverybodySTalkingAbout");
    CBOverheard(game, CBT(n"Cyberbane-Wannabe-Wannabe"), CBLineOf([
      CBTf(n"Cyberbane-Wannabe-YouReDonTLookLike", [you]),
      CBT(n"Cyberbane-Wannabe-EverybodySaysYouReTheReal"),
      CBT(n"Cyberbane-Wannabe-NoGunsNoChromeTricksJust"),
      CBT(n"Cyberbane-Wannabe-BeatYouAndIMSomebody"),
      CBT(n"Cyberbane-Wannabe-MyCrewSWatchingDonT")]), true);
  }
}

func CBWannabeWon(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeDone();
  let now = CBGameSeconds(game);
  // Shot a kid who came with bare hands: the street calls that what it is.
  let shot = IsDefined(p) && p.IsDead() && CBMethodHas(p.cbLastMethodMask, CBMethodFirearm());
  if shot {
    sys.AddCode(-CBConfig.WannabeShotCode());
    CBFileLog(sys, n"WannabeShot", now, CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBPick2(CBT(n"Cyberbane-Wannabe-AKidCameAtYouWith"),
                                        CBT(n"Cyberbane-Wannabe-BringingAGunToAFistfight")), n"");
    }
    return;
  }
  // Friends who watched carry it further (2.6.5).
  let watched = CBWannabeFriendsLeave(sys, game);
  CBApplyDistrictRenown(sys, book.wannabeDistrict, CBConfig.WannabeRenown() * (watched > 0 ? 1.5 : 1.0));
  CBFileLog(sys, n"WannabeBeaten", now, CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
  if watched > 0 && CBMessagesOn() && IsDefined(p) && !p.IsDead() {
    CBOverheard(game, CBT(n"Cyberbane-Wannabe-WannabeSFriend"), CBPick3(CBT(n"Cyberbane-Wannabe-GetUpHeSNotGetting"), CBT(n"Cyberbane-Wannabe-ToldHimToldHimItWas"),
                                                  CBT(n"Cyberbane-Wannabe-NobodySGonnaBelieveThisI")), true);
  }
  // Dead, said as dead (2.5.5): a kid V beat to death with fists or a blade was told as "out cold".
  if CBMessagesOn() && IsDefined(p) && p.IsDead() {
    CBHearsayFromStreet(game, CBPick2(CBT(n"Cyberbane-Wannabe-ThatKidWhoSquaredUpTo"),
                                      CBT(n"Cyberbane-Wannabe-AKidWantedAFistfightWith")), n"");
    return;
  }
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBPick3(CBT(n"Cyberbane-Wannabe-ThatKidWhoSquaredUpTo-2"),
                                      CBT(n"Cyberbane-Wannabe-SomebodyTriedToMakeTheirName"),
                                      CBT(n"Cyberbane-Wannabe-TheKidWantedAStoryGot")), n"");
  }
}

func CBWannabeLost(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeDone();
  CBWannabeStandDown(game, p);
  if CBWannabeFriendsLeave(sys, game) > 0 && CBMessagesOn() {
    CBOverheard(game, CBT(n"Cyberbane-Wannabe-WannabeSFriend"), CBPick2(CBT(n"Cyberbane-Wannabe-YouSeeThatYouSEEThat"), CBT(n"Cyberbane-Wannabe-LegendMyAssComeOnLet")), true);
  }
  CBWannabeDent(sys, book.wannabeDistrict, CBConfig.WannabeRenown());
  CBFileLog(sys, n"WannabeLost", CBGameSeconds(game), CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
  if CBMessagesOn() {
    CBOverheard(game, CBT(n"Cyberbane-Wannabe-Wannabe"), CBPick3(CBT(n"Cyberbane-Wannabe-ThatSItThatSThe"),
                                         CBT(n"Cyberbane-Wannabe-StayDownIMSomebodyNow"),
                                         CBT(n"Cyberbane-Wannabe-ThoughtYouDBeHarderThanks")));
  }
}

func CBWannabeWalked(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeDone();
  CBWannabeStandDown(game, p);
  CBWannabeFriendsLeave(sys, game);
  CBWannabeDent(sys, book.wannabeDistrict, CBConfig.WannabeRenown() * 0.34);
  CBFileLog(sys, n"WannabeWalked", CBGameSeconds(game), CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBPick2(CBT(n"Cyberbane-Wannabe-TheKidSTellingEverybodyYou"),
                                      CBT(n"Cyberbane-Wannabe-YouWalkedAwayFromSomeKid")), n"");
  }
}

// They stop fighting V and walk off. The re-arm watch is told this is on purpose (cbArmTick).
func CBWannabeStandDown(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(p) || !IsDefined(player) || !p.IsAttached() || !CBStillStanding(p) {
    return;
  }
  p.cbArmTick = 0;
  let agent = p.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    CBTrace("attitude: a wannabe stands down");
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
  }
  CBOrderFlee(game, p);
}

func CBWannabeDent(sys: ref<CyberbaneSystem>, district: CName, amount: Float) -> Void {
  if Equals(district, n"") || CBReputationFrozen() {
    return;
  }
  let ds = sys.EnsureDistrict(district);
  if IsDefined(ds) {
    ds.renown = MaxF(0.0, ds.renown - amount);
    sys.GetScore().MarkDirty();
  }
}

// Whoever is left goes the safe way: out of V's sight, or to the orphan sweep if V is watching; a body stays for
// the remains sweep.
func CBWannabeEnd(game: GameInstance, book: ref<CBStreetBook>) -> Void {
  CBDeleteTaggedSafe(game, n"CB_Wannabe", true, true);
  let none: EntityID;
  book.wannabeId = none;
  book.wannabeStage = CBWannabeNone();
  book.wannabeTick = 0;
}

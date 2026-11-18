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
    if !busy && sys.GetTickCount() % 5 == 0 {
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
     || CBPlayerIndoors(game) || CBPlayerMasked(game) || CBHuntersOut(sys, game) || CBHuntPending(sys)
     || CBSpawnRoom(game) < 1 + CBConfig.TurfPatrolKeepRoom() {
    return;
  }
  let score = sys.GetScore();
  if !IsDefined(score) || EnumInt(score.GetTier()) < EnumInt(ECBRenownTier.KnownMerc) {
    return;
  }
  book.wannabeNext = now + CBConfig.WannabeGapHours() * CBConfig.SecondsPerHour() * (0.75 + RandF() * 0.5);
  if RandF() >= CBConfig.WannabeChance() {
    return;
  }
  let district = sys.GetCurrentDistrict();
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
    CBLog.Info(n"Street", "A wannabe is coming to make a name off V.");
  }
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
    let you = StrLen(st.title) > 0 ? st.title : "the merc everybody's talking about";
    CBOverheard(game, "Wannabe", CBLineOf([
      "You're " + you + "? Don't look like much. Put 'em up.",
      "Everybody says you're the real thing. Let's find out. Hands only.",
      "No guns, no chrome tricks. Just you and me. Come on.",
      "Beat you and I'm somebody. Ready?",
      "My crew's watching. Don't make me look bad, legend."]));
  }
}

func CBWannabeWon(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeDone();
  let now = CBGameSeconds(game);
  // Shot a kid who came with bare hands: the street calls that what it is.
  let shot = IsDefined(p) && p.IsDead() && CBMaskHas(p.cbLastMethodMask, CBMethodFirearm());
  if shot {
    sys.AddCode(-CBConfig.WannabeShotCode());
    CBFileLog(sys, n"WannabeShot", now, CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBPick2("A kid came at you with his fists and you shot him. People saw.",
                                        "Bringing a gun to a fistfight. With a kid. That's going round."), n"");
    }
    return;
  }
  CBApplyDistrictRenown(sys, book.wannabeDistrict, CBConfig.WannabeRenown());
  CBFileLog(sys, n"WannabeBeaten", now, CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBPick3("That kid who squared up to you? Out cold. Half the block saw it.",
                                      "Somebody tried to make their name off you. Now they're famous for the wrong reason.",
                                      "The kid wanted a story. Got one. Lost it."), n"");
  }
}

func CBWannabeLost(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeDone();
  CBWannabeStandDown(game, p);
  CBWannabeDent(sys, book.wannabeDistrict, CBConfig.WannabeRenown());
  CBFileLog(sys, n"WannabeLost", CBGameSeconds(game), CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
  if CBMessagesOn() {
    CBOverheard(game, "Wannabe", CBPick3("That's it? That's the legend? I'm telling everybody.",
                                         "Stay down. I'm somebody now.",
                                         "Thought you'd be harder. Thanks for the story."));
  }
}

func CBWannabeWalked(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBStreetBook>, p: ref<ScriptedPuppet>) -> Void {
  book.wannabeStage = CBWannabeDone();
  CBWannabeStandDown(game, p);
  CBWannabeDent(sys, book.wannabeDistrict, CBConfig.WannabeRenown() * 0.34);
  CBFileLog(sys, n"WannabeWalked", CBGameSeconds(game), CBEventDistrict(sys, game), CBClassifyFaction(p), 0.0);
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBPick2("The kid's telling everybody you wouldn't fight him. Nobody who matters believes it.",
                                      "You walked away from some kid's fistfight. Smart, or scared, depending who's telling it."), n"");
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

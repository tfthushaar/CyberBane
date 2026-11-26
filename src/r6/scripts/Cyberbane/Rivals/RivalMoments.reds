// Cyberbane - The Rivals' moments
//
// Facedowns, Rivals back on their feet, humiliation, coming back from the dead, Rivals at war with each other, bonds,
// trophies, where they ended up, places with meaning, last words, Rival chrome and tactics by kind.

public func CBRivalChromeOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().rivalChrome;
}

public func CBFacedownOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBRivalsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().facedown);
}

public func CBBackFromDeadOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBRivalsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().backFromDead);
}

public func CBRivalFeudsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBRivalsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().rivalFeuds);
}

public func CBTrophiesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().trophies;
}

public func CBTalkActStare() -> Int32 = 40
public func CBTalkActDraw() -> Int32 = 41
public func CBTalkActWalkAway() -> Int32 = 42
public func CBTalkActOneOnOne() -> Int32 = 43
public func CBTalkActHumiliate() -> Int32 = 44
public func CBTalkActSetOn() -> Int32 = 45
public func CBTalkActCallEven() -> Int32 = 46
public func CBTalkActWhereIs() -> Int32 = 47
public func CBTalkActLeaveTown() -> Int32 = 48

public func CBTalkActIsFacedown(act: Int32) -> Bool {
  return (act >= CBTalkActStare() && act <= CBTalkActOneOnOne()) || (act >= CBTalkActCallEven() && act <= CBTalkActLeaveTown());
}

// ---- [U9] Rival chrome ---------------------------------------------------------------------------------------------

// Implant bits: 0 subdermal armour (shot), 1 dermal plating (cut), 2 a firewall (hacked), 3 reinforced tendons
// (outrun), 4 smoke-filter optics (burned). Derived from what the Rival already has, so nothing is saved for it.
public func CBRivalImplants(r: ref<CBRival>) -> Int32 {
  if !IsDefined(r) || !CBRivalChromeOn() || CBRivalHasTrait(r, n"Broken") {
    return 0;
  }
  let climbs = Clamp(r.rank - 1 + r.escapes + r.sparedByV + r.killedV, 0, CBConfig.RivalImplantsMax());
  let mask = 0;
  let got = 0;
  if got < climbs && CBMaskHas(r.scarMask, CBScarShot()) {
    mask = CBMaskSet(mask, 0);
    got += 1;
  }
  if got < climbs && CBMaskHas(r.scarMask, CBScarCut()) {
    mask = CBMaskSet(mask, 1);
    got += 1;
  }
  if got < climbs && CBMaskHas(r.scarMask, CBScarFried()) {
    mask = CBMaskSet(mask, 2);
    got += 1;
  }
  if got < climbs && r.escapes > 0 {
    mask = CBMaskSet(mask, 3);
    got += 1;
  }
  if got < climbs && CBMaskHas(r.scarMask, CBScarBurned()) {
    mask = CBMaskSet(mask, 4);
    got += 1;
  }
  // Climbs left over: what their kind of person buys, by their id, so the same Rival always buys the same.
  let k = 0;
  while got < climbs && k < 5 {
    let bit = (CBHashIndex(r.id, 71, 5) + k) % 5;
    if !CBMaskHas(mask, bit) {
      mask = CBMaskSet(mask, bit);
      got += 1;
    }
    k += 1;
  }
  return mask;
}

public func CBImplantName(bit: Int32) -> String {
  switch bit {
    case 0: return CBT(n"Cyberbane-RivalMoments-SubdermalArmour");
    case 1: return CBT(n"Cyberbane-RivalMoments-DermalPlating");
    case 2: return CBT(n"Cyberbane-RivalMoments-AFirewall");
    case 3: return CBT(n"Cyberbane-RivalMoments-ReinforcedTendons");
    default: return CBT(n"Cyberbane-RivalMoments-SmokeFilterOptics");
  }
}

public func CBRivalChromeWords(r: ref<CBRival>) -> String {
  let mask = CBRivalImplants(r);
  let out = "";
  let bit = 0;
  while bit < 5 {
    if CBMaskHas(mask, bit) {
      out += (StrLen(out) > 0 ? ", " : "") + CBImplantName(bit);
    }
    bit += 1;
  }
  return out;
}

public func CBRivalChromeCount(r: ref<CBRival>) -> Int32 {
  let mask = CBRivalImplants(r);
  let n = 0;
  let bit = 0;
  while bit < 5 {
    if CBMaskHas(mask, bit) {
      n += 1;
    }
    bit += 1;
  }
  return n;
}

// The terms an implant adds to the build (Spawn/FactionApex.reds, CBRivalTraitTerms), under the same ceilings.
public func CBRivalImplantTerms(r: ref<CBRival>, out health: Float, out armour: Float, out damage: Float, out crit: Float) -> Void {
  let mask = CBRivalImplants(r);
  let step = CBConfig.RivalTraitStep();
  if CBMaskHas(mask, 0) { armour += step * 0.8; }
  if CBMaskHas(mask, 1) { health += step * 0.5; armour += step * 0.3; }
  if CBMaskHas(mask, 2) { armour += step * 0.3; }
  if CBMaskHas(mask, 4) { crit += CBConfig.RivalTraitCrit() * 0.5; }
}

// And the game's behaviour abilities, where an implant has one ([U9]), with how their kind fights ([U11]).
public func CBKitRivalImplants(npc: ref<NPCPuppet>, r: ref<CBRival>) -> Void {
  if !IsDefined(npc) || !IsDefined(r) || CBAiKitOwner() {
    return;
  }
  let mask = CBRivalImplants(r);
  if CBMaskHas(mask, 0) {
    CBGrantAbility(npc, t"Ability.HasSubdermalArmorHigh");
  }
  if CBMaskHas(mask, 1) {
    CBGrantAbility(npc, t"Ability.CanBlock");
  }
  if CBMaskHas(mask, 3) {
    CBGrantAbility(npc, t"Ability.CanCatchUp");
    CBGrantAbility(npc, t"Ability.CanSprint");
  }
  if CBMaskHas(mask, 4) {
    CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
  }
  // [U11] How they fight, by how they came to be V's Rival. Movement and sight only: never a style ability that
  // could sit against the aggression every one of ours needs to turn on V.
  if r.source == EnumInt(ECBRivalSource.Survivor) || r.source == EnumInt(ECBRivalSource.Spared) {
    CBGrantAbility(npc, t"Ability.HasDodge");
    CBGrantAbility(npc, t"Ability.CanSprint");
  }
  if r.source == EnumInt(ECBRivalSource.Killer) {
    CBGrantAbility(npc, t"Ability.CanCatchUp");
    CBGrantAbility(npc, t"Ability.CanShootWhileMoving");
  }
  if r.source == EnumInt(ECBRivalSource.Avenger) {
    CBGrantAbility(npc, t"Ability.CanCatchUp");
    CBGrantAbility(npc, t"Ability.HasDodge");
  }
  if r.source == EnumInt(ECBRivalSource.Hunter) {
    CBGrantAbility(npc, t"Ability.CanSeeThroughOpticalCamos");
    CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
  }
  // One of V's own who turned has fought beside V and knows how V moves (Reactions/Crew.reds).
  if r.source == EnumInt(ECBRivalSource.Betrayer) {
    CBGrantAbility(npc, t"Ability.CanCatchUp");
    CBGrantAbility(npc, t"Ability.CanSeeThroughSmoke");
  }
}

// For the scanner, under their name: what they are carrying in them, briefly.
public func CBRivalChromeShort(r: ref<CBRival>) -> String {
  let n = CBRivalChromeCount(r);
  if n == 0 {
    return "";
  }
  let mask = CBRivalImplants(r);
  let first = "";
  let bit = 0;
  while bit < 5 && StrLen(first) == 0 {
    if CBMaskHas(mask, bit) {
      first = CBImplantName(bit);
    }
    bit += 1;
  }
  return n > 1 ? StrUpper(first) + s" +\(n - 1)" : StrUpper(first);
}

// ---- [63] [L4] What they say ---------------------------------------------------------------------------------------

public func CBRivalLastWords(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) && intel.KinOf(r.id) > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-CouldnTFinishItForThem"), CBT(n"Cyberbane-RivalMoments-TellMyFamilyITried"), CBT(n"Cyberbane-RivalMoments-SameAsThemSameAsThem"));
  }
  if r.killedV > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-BeatYouOnceNobodyCanTake"), CBT(n"Cyberbane-RivalMoments-ShouldVeStayedDownTheFirst"), CBT(n"Cyberbane-RivalMoments-LuckyYouGotLucky"));
  }
  if r.escapes >= 2 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-RanOutOfRoad"), CBT(n"Cyberbane-RivalMoments-ThoughtIDAlwaysGetAway"), CBT(n"Cyberbane-RivalMoments-EveryTimeButThisOne"));
  }
  if r.sparedByV > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-YouLetMeLiveShouldVe"), CBT(n"Cyberbane-RivalMoments-SecondChanceWastedIt"), CBT(n"Cyberbane-RivalMoments-MercyAndThenThis"));
  }
  if CBRivalHasTrait(r, n"Humiliated") {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-AtLeastNobodySLaughingNow"), CBT(n"Cyberbane-RivalMoments-WorthItToSeeYourFace"), CBT(n"Cyberbane-RivalMoments-ToldYouIDComeBack"));
  }
  return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-NightCityRemembersMe"), CBT(n"Cyberbane-RivalMoments-NotLikeThis"), CBT(n"Cyberbane-RivalMoments-YouLlSeeMeAgain"));
}

// Mid-fight, now and then: what they remember of V.
public func CBRivalTaunt(r: ref<CBRival>) -> String {
  if CBMaskHas(r.scarMask, CBScarBurned()) {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-IStillSmellTheSmokeBecause"), CBT(n"Cyberbane-RivalMoments-YouBurnedMeIDonT"), CBT(n"Cyberbane-RivalMoments-RememberTheFireIDo"));
  }
  if CBMaskHas(r.scarMask, CBScarCut()) {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-StillGotYourBladeMarksCome"), CBT(n"Cyberbane-RivalMoments-CutMeOnceNotAgain"), CBT(n"Cyberbane-RivalMoments-IWearYourScarsYouLl"));
  }
  if CBMaskHas(r.scarMask, CBScarFried()) {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-StayOutOfMyHeadThis"), CBT(n"Cyberbane-RivalMoments-FryMeAgainTryIt"), CBT(n"Cyberbane-RivalMoments-IPaidForAFirewallBecause"));
  }
  if r.killedV > 0 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-YouRememberHowThisEnds"), CBT(n"Cyberbane-RivalMoments-DownYouGoAgain"), CBT(n"Cyberbane-RivalMoments-SameAsLastTimeMerc"));
  }
  if r.escapes >= 2 {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-CaughtYouThisTime"), CBT(n"Cyberbane-RivalMoments-NoRunningToday"), CBT(n"Cyberbane-RivalMoments-YouCanTLoseMe"));
  }
  if CBRivalHasTrait(r, n"Humiliated") {
    return CBRivalPhrase(r, CBT(n"Cyberbane-RivalMoments-NobodyLaughsAtMeNobody"), CBT(n"Cyberbane-RivalMoments-WhoSCrawlingNow"), CBT(n"Cyberbane-RivalMoments-SayItAgainSayIt"));
  }
  return CBRivalCatchphrase(r);
}

// What their texts remember, added to the line they send when they find V ([L4]).
public func CBRivalRemembers(game: GameInstance, r: ref<CBRival>) -> String {
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) && intel.KinOf(r.id) > 0 {
    return CBT(n"Cyberbane-RivalMoments-ThisIsForMyFamily");
  }
  if r.sparedByV > 0 {
    return CBT(n"Cyberbane-RivalMoments-YouLetMeWalkLastTime");
  }
  if r.escapes > 0 {
    return CBTf(n"Cyberbane-RivalMoments-GotAwayFromYouNotRunning", [r.escapes == 1 ? CBT(n"Cyberbane-RivalMoments-Once") : CBTf(n"Cyberbane-RivalMoments-Times", [s"\(r.escapes)"])]);
  }
  if CBMaskHas(r.scarMask, CBScarBurned()) || CBMaskHas(r.scarMask, CBScarCut()) || CBMaskHas(r.scarMask, CBScarShot()) {
    return CBT(n"Cyberbane-RivalMoments-IStillHaveTheScarsYou");
  }
  return "";
}

// ---- [53] [54] [64] The facedown ---------------------------------------------------------------------------------

@addField(ScriptedPuppet)
public let cbFacedownOpen: Bool;

// Held for a facedown, or standing back from a fight one on one: the hunt neither orders nor engages them meanwhile.
@addField(ScriptedPuppet)
public let cbFacedownHeld: Bool;

public func CBRivalMomentsTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBRivalBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) {
    return;
  }
  CBFacedownTick(sys, game, book, player);
  CBRivalTauntTick(sys, game, book, player);
}

// The facedown is owed: the active Rival has not had one this time, and nothing else is calling the shots.
public func CBFacedownAwaits(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  return CBFacedownAwaitsFor(sys, game, sys.FindRivalById(sys.GetActiveRivalId()));
}

// The same for one Rival in particular: the one waiting at their place, who is nobody's active Rival yet.
public func CBFacedownAwaitsFor(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !CBFacedownOn() || !IsDefined(sys) || !IsDefined(r) {
    return false;
  }
  let book = CBRivalBook.Get(game);
  if !IsDefined(book) || book.fdState != 0 || NotEquals(sys.GetApexMusterFaction(), n"") {
    return false;
  }
  return r.id * 64 + Min(r.encounters, 63) != book.fdDoneKey;
}

// Those walking up calm (CBFacedownAwaits) turn hostile when the facedown is not going to happen: V hit one of them,
// it has been too long, or the switch went off. Returns true when it let them go.
func CBFacedownWaitTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>) -> Bool {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return false;
  }
  let tick = sys.GetTickCount();
  let tags: array<CName> = [n"CB_Rival", n"CB_Escort"];
  let waiting = 0;
  let over = !CBFacedownOn() || book.fdState != 0;
  // V in a fight that is not theirs: they are calm, so whoever V is fighting is somebody else.
  let player = GetPlayer(game);
  let busy = IsDefined(player) && player.IsInCombat();
  for tag in tags {
    for id in des.GetTaggedIDs(tag) {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if IsDefined(p) && p.cbFacedownWait {
        waiting += 1;
        if busy && p.cbFacedownWaitSeen > 0 {
          p.cbFacedownWaitHeld += Max(0, tick - p.cbFacedownWaitSeen);
        }
        p.cbFacedownWaitSeen = tick;
        let waited = tick - p.cbFacedownWaitTick - p.cbFacedownWaitHeld;
        if p.cbDamagedByPlayer || waited > CBConfig.FacedownWaitTicks()
           || tick - p.cbFacedownWaitTick > CBConfig.FacedownWaitMaxTicks() {
          over = true;
        }
      }
    }
  }
  if waiting == 0 || !over || book.fdState != 0 {
    return false;
  }
  for tag in tags {
    for id in des.GetTaggedIDs(tag) {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if IsDefined(p) && p.cbFacedownWait {
        p.cbFacedownWait = false;
        CBFacedownHostile(sys, game, p);
      }
    }
  }
  // Not this encounter, then: the facedown does not open later on people already fighting.
  let r = sys.FindRivalById(sys.GetActiveRivalId());
  if IsDefined(r) {
    book.fdDoneKey = r.id * 64 + Min(r.encounters, 63);
  }
  CBLog.Info(n"Rivals", "A Rival who came for a facedown did not get one; they and theirs are hostile now.");
  return true;
}

func CBFacedownTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, player: ref<PlayerPuppet>) -> Void {
  let tick = sys.GetTickCount();
  if book.fdState == 0 && sys.GetActiveRivalId() > 0 && CBFacedownWaitTick(sys, game, book) {
    return;
  }
  if book.fdState != 0 {
    let r = sys.FindRivalById(book.fdRival);
    let body = GameInstance.FindEntityByID(game, book.fdBody) as ScriptedPuppet;
    if !IsDefined(r) || !CBFacedownOn() || !CBWorldStable(game) || CBWordsHeld(sys, game) {
      CBFacedownRelease(sys, game, book, true);
      return;
    }
    if book.fdState == 1 {
      if !CBNpcSafe(sys, body) || !CBStillStanding(body) {
        CBFacedownRelease(sys, game, book, true);
        return;
      }
      // V fired first, hit one of them, or took too long: it is a fight. Not too long while V is talking to them
      // (CBTalkEngaged): the clock holds while the words go back and forth.
      if CBTalkEngaged(sys, body) {
        book.fdTick = tick;
      }
      if body.cbDamagedByPlayer || CBFacedownEscortHit(game, book) || sys.GetTruce().Broken()
         || tick - book.fdTick > CBConfig.FacedownTicks() {
        CBFacedownFight(sys, game, book, r, body, false);
      }
      return;
    }
    // Just you and me: over when the Rival is down or gone; their people step in if V breaks the terms, or when the
    // Rival is all but beaten: They were held neutral, and the game turned them anyway the moment their boss was hurt
    // in front of them (AIActionHelper.TryChangingAttitudeToHostile, squad mate in danger), which now leaves alone
    // anybody held out of a fight (CBHeldOutOfFight).
    if !CBNpcSafe(sys, body) || !CBStillStanding(body) {
      CBFacedownDuelOver(sys, game, book, r, IsDefined(body) && CBIsDown(body));
      return;
    }
    if CBFacedownEscortHit(game, book) || sys.GetTruce().Broken() || CBMethodHas(body.cbLastMethodMask, CBMethodExplosive())
       || CBMethodHas(body.cbLastMethodMask, CBMethodQuickhack()) {
      CBFacedownTermsBroken(sys, game, book, r);
      return;
    }
    if CBHealthPercent(game, body) <= CBConfig.DuelStepInHealth() {
      CBFacedownStepIn(sys, game, book, r);
    }
    return;
  }
  if !CBFacedownOn() || player.IsInCombat() || CBWordsHeld(sys, game) || sys.IsInSafeZone()
     || IsDefined(player.GetMountedVehicle()) || tick % 2 != 0 {
    return;
  }
  let r = sys.FindRivalById(sys.GetActiveRivalId());
  if !IsDefined(r) || !EntityID.IsDefined(r.spawnedEntityId) {
    return;
  }
  let key = r.id * 64 + Min(r.encounters, 63);
  if key == book.fdDoneKey {
    return;
  }
  let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
  if !CBNpcSafe(sys, body) || !CBStillStanding(body) || CBNpcInCombat(body) || body.cbDamagedByPlayer
     || VehicleComponent.IsMountedToVehicle(game, body) {
    return;
  }
  let d = Vector4.Distance(body.GetWorldPosition(), player.GetWorldPosition());
  if d > CBConfig.FacedownRange() || d < 2.5 {
    return;
  }
  CBFacedownOpen(sys, game, book, r, body, key);
}

func CBFacedownOpen(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>,
                    body: ref<ScriptedPuppet>, key: Int32) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  book.fdState = 1;
  book.fdRival = r.id;
  book.fdBody = body.GetEntityID();
  book.fdTick = sys.GetTickCount();
  book.fdDoneKey = key;
  ArrayClear(book.fdEscorts);
  CBFacedownCalm(game, body);
  if IsDefined(des) {
    for id in des.GetTaggedIDs(n"CB_Escort") {
      let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
      if CBNpcSafe(sys, p) && CBStillStanding(p) && !CBNpcInCombat(p)
         && Vector4.Distance(p.GetWorldPosition(), body.GetWorldPosition()) <= CBConfig.FacedownEscortRange() {
        ArrayPush(book.fdEscorts, id);
        CBFacedownCalm(game, p);
      }
    }
  }
  body.cbFacedownOpen = true;
  // Everybody else of theirs nearby holds too, the ones walking up included (Reactions/TalkTruce.reds): "a Rival was
  // offering to talk but his bodyguards started shooting". Only the escorts standing close at the start held.
  sys.GetTruce().Begin(sys, game, CBTruceFacedown(), r.faction, body);
  let name = CBRivalDisplayName(sys.GetContent(), r);
  CBIntelSay(game, 3, name, CBFacedownOpener(sys, game, r), 4.0);
  CBVoice(sys, game, body, n"start_combat", n"RivalFacedown", 30.0);   // their own voice first
  if CBToastsOn() && !book.fdHinted {
    book.fdHinted = true;
    CBSystemNote(game, CBTf(n"Cyberbane-RivalMoments-WantsALookAtYouFirst", [s"\(name)"]), 5.0);
  }
  CBLog.Info(n"Rivals", s"Facedown with Rival \(r.id), \(ArraySize(book.fdEscorts)) of their people holding.");
}

// The first thing they say, from what they have been through with V.
func CBFacedownOpener(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  let you = CBYou(sys, game);
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) && intel.KinOf(r.id) > 0 {
    let dead = sys.FindRivalById(intel.KinOf(r.id));
    let who = IsDefined(dead) ? CBRivalDisplayName(sys.GetContent(), dead) : CBT(n"Cyberbane-RivalMoments-MyFamily");
    return CBTf(n"Cyberbane-RivalMoments-EverybodyStopIWantToLook", [s"\(who)"]);
  }
  if r.killedV > 0 {
    return CBTf(n"Cyberbane-RivalMoments-AgainYouRememberHowThisEnded", [s"\(you)"]);
  }
  if r.sparedByV > 0 {
    return CBT(n"Cyberbane-RivalMoments-YouLetMeWalkOnceHold");
  }
  if r.escapes > 0 {
    return CBTf(n"Cyberbane-RivalMoments-NobodyMoveLastTimeIRan", [s"\(you)"]);
  }
  if r.encounters == 0 {
    return CBTf(n"Cyberbane-RivalMoments-SoYouReDonTReach", [s"\(you)"]);
  }
  return CBRivalPhrase(r, CBTf(n"Cyberbane-RivalMoments-YouAndMeHandsWhereI", [s"\(CBCapFirst(CBHere(sys)))"]), CBT(n"Cyberbane-RivalMoments-DonTReachForItYet"),
                       CBT(n"Cyberbane-RivalMoments-EverybodyStopIWantToSee"));
}

// Somebody stops where they are and holds off V for a moment: their attitude to V alone, and one hold order. Walking up
// calm for a facedown (Spawn/Spawner.reds, CBApplySpawnSetup), and since when.
@addField(ScriptedPuppet)
public let cbFacedownWait: Bool;
@addField(ScriptedPuppet)
public let cbFacedownWaitTick: Int32;
// How much of that wait was held while V fought somebody else, and when it was last looked at.
@addField(ScriptedPuppet)
public let cbFacedownWaitHeld: Int32;
@addField(ScriptedPuppet)
public let cbFacedownWaitSeen: Int32;

func CBFacedownCalm(game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(p) || !IsDefined(player) {
    return;
  }
  let agent = p.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) {
    CBTrace("attitude: a Rival and their people hold for a facedown");
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
  }
  // And V's companions, or they open fire on people holding still. Hostile again with V (CBFacedownHostile).
  CBCalmTowardCompanions(CyberbaneSystem.Get(game), p);
  p.cbFacedownHeld = true;
  p.cbFacedownWait = false;
  CBCancelMove(p);
  // As long as a facedown can wait for V, as the hold always was: a conversation's own holds are short now.
  CBTalkHold(p, CBConfig.FacedownHoldSeconds());
}

// Back to the fight: hostile to V again and after V, through the same door as when they arrived.
func CBFacedownHostile(sys: ref<CyberbaneSystem>, game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  if !CBNpcSafe(sys, p) || !CBStillStanding(p) {
    return;
  }
  p.cbFacedownHeld = false;
  p.cbFacedownWait = false;
  CBTalkReleaseHold(p);
  CBMakeHostileToPlayer(game, p);
  CBOrderPursue(sys, game, p);
}

func CBFacedownEscortHit(game: GameInstance, book: ref<CBRivalBook>) -> Bool {
  for id in book.fdEscorts {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.cbDamagedByPlayer {
      return true;
    }
  }
  return false;
}

// The Rival's people still walking up calm who were not close enough to be held when it opened.
func CBFacedownStragglers(game: GameInstance, book: ref<CBRivalBook>) -> array<EntityID> {
  let out: array<EntityID>;
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return out;
  }
  for id in des.GetTaggedIDs(n"CB_Escort") {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.cbFacedownWait && !ArrayContains(book.fdEscorts, id) {
      ArrayPush(out, id);
    }
  }
  return out;
}

// A fight after all: everybody hostile again. `drop` gives V the first shots (the Rival's aim off for a moment).
func CBFacedownFight(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>,
                     body: ref<ScriptedPuppet>, drop: Bool) -> Void {
  CBFacedownHostile(sys, game, body);
  for id in book.fdEscorts {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  for id in CBFacedownStragglers(game, book) {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  if drop && IsDefined(body) {
    CBAimFor(game, body, CBConfig.FairVolleyAim(), CBConfig.FacedownDropSeconds());
  }
  CBFacedownRelease(sys, game, book, false);
}

// The facedown is over; `restore` makes anybody still held hostile again first.
func CBFacedownRelease(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, restore: Bool) -> Void {
  let body = GameInstance.FindEntityByID(game, book.fdBody) as ScriptedPuppet;
  if IsDefined(body) {
    body.cbFacedownOpen = false;
  }
  if restore {
    CBFacedownHostile(sys, game, body);
    for id in book.fdEscorts {
      CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
    }
  }
  book.fdState = 0;
  book.fdRival = 0;
  ArrayClear(book.fdEscorts);
  sys.GetTruce().End(sys, game, CBTruceFacedown());
}

// They let V go, once: everybody walks off and the encounter is closed, the way a crew called off is.
func CBFacedownLetGo(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>,
                     body: ref<ScriptedPuppet>) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  for id in book.fdEscorts {
    CBFacedownStandDown(sys, game, des, id);
  }
  for id in CBFacedownStragglers(game, book) {
    CBFacedownStandDown(sys, game, des, id);
  }
  if IsDefined(body) {
    body.cbFacedownOpen = false;
    CBTalkReleaseHold(body);
  }
  r.encounters += 1;
  r.huntTicks = Max(r.huntTicks, CBConfig.RivalAfterEscapeTicks());
  CBCloseRivalEncounter(sys, game, r, body);
  if CBNpcSafe(sys, body) && CBStillStanding(body) {
    CBOrderFlee(game, body);
  }
  book.fdState = 0;
  book.fdRival = 0;
  ArrayClear(book.fdEscorts);
  sys.GetTruce().End(sys, game, CBTruceFacedown());
}

// One of their people stands down for good, the way a crew called off does (CBCallOffGang): no longer a hunter by tag,
// so the hunt neither orders them nor counts them as left behind, and an orphan the sweep clears once V cannot see
// them; walking off, neutral to V.
func CBFacedownStandDown(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, id: EntityID) -> Void {
  if !IsDefined(des) {
    return;
  }
  let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
  if des.IsTagged(id, n"CB_Escort") {
    des.UnassignTag(id, n"CB_Escort");
  }
  if des.IsTagged(id, n"Cyberbane") && !des.IsTagged(id, n"CB_Orphan") {
    des.AssignTag(id, n"CB_Orphan");
  }
  if CBNpcSafe(sys, p) && CBStillStanding(p) {
    CBUntrackOnMap(game, p);
    CBTalkReleaseHold(p);
    CBCalmTowardCompanions(sys, p);
    p.cbFacedownHeld = false;
    p.cbFacedownWait = false;
    CBOrderFlee(game, p);
  }
}

// The Rival is nearly finished in a fair fight: their people break their word and come in, all of them at once, the
// ones standing further off included, and say so.
func CBFacedownStepIn(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>) -> Void {
  let stragglers = CBFacedownStragglers(game, book);
  let stepping = ArraySize(book.fdEscorts) + ArraySize(stragglers);
  for id in book.fdEscorts {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  for id in stragglers {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  ArrayClear(book.fdEscorts);
  book.fdState = 0;
  book.fdRival = 0;
  sys.GetTruce().End(sys, game, CBTruceFacedown());
  if stepping > 0 {
    let name = CBRivalDisplayName(sys.GetContent(), r);
    CBIntelSay(game, 3, CBIntelSpeaker(r.faction), CBLineOf([
      CBT(n"Cyberbane-RivalMoments-BossIsGoingDownForgetThe"),
      CBTf(n"Cyberbane-RivalMoments-NobodyPutsInTheGroundLight", [s"\(name)"]),
      CBT(n"Cyberbane-RivalMoments-ThatSEnoughFairSOver"),
      CBT(n"Cyberbane-RivalMoments-WeSaidWeDStayOut")]), 3.0);
  }
  CBLog.Info(n"Rivals", s"Rival \(r.id) was nearly beaten one on one; \(stepping) of their people stepped in.");
}

func CBFacedownTermsBroken(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>) -> Void {
  for id in book.fdEscorts {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  for id in CBFacedownStragglers(game, book) {
    CBFacedownHostile(sys, game, GameInstance.FindEntityByID(game, id) as ScriptedPuppet);
  }
  ArrayClear(book.fdEscorts);
  book.fdState = 0;
  book.fdRival = 0;
  sys.GetTruce().End(sys, game, CBTruceFacedown());
  CBIntelSay(game, 3, CBIntelSpeaker(r.faction), CBPick2(CBT(n"Cyberbane-RivalMoments-ThatSNotHowThisWorks"), CBT(n"Cyberbane-RivalMoments-NoRulesThenLightThemUp")), 3.0);
}

// The Rival is down or gone: their people saw it, and they go.
func CBFacedownDuelOver(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>, won: Bool) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  for id in book.fdEscorts {
    CBFacedownStandDown(sys, game, des, id);
  }
  for id in CBFacedownStragglers(game, book) {
    CBFacedownStandDown(sys, game, des, id);
  }
  book.fdState = 0;
  book.fdRival = 0;
  ArrayClear(book.fdEscorts);
  sys.GetTruce().End(sys, game, CBTruceFacedown());
  if won {
    CBTalkFear(sys, game, r.faction, CBConfig.DuelFear());
    CBFileLog(sys, n"DuelWon", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalMoments-AskedForAFairFightAnd", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]), n"");
    }
  }
}

// What V can say at the facedown.
public func CBRivalFacedownLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let r = sys.FindRivalById(t.rivalId);
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalMoments-StareThemDownLookAtMe"), CBTalkActStare(), t"ChoiceCaptionParts.GrappleIcon"));
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalMoments-DrawLetSGo"), CBTalkActDraw(), TDBID.None()));
  ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalMoments-WalkAwayNotToday"), CBTalkActWalkAway(), t"ChoiceCaptionParts.BackOutIcon"));
  let escorts = CBRivalBookEscorts(game);
  if ArraySize(escorts) > 0 {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalMoments-JustYouAndMeTellYour"), CBTalkActOneOnOne(), TDBID.None()));
  }
  // [64] One who owes V, or is afraid of V, can be talked out of it.
  if IsDefined(r) && (r.sparedByV > 0 || CBRivalHasTrait(r, n"Shaken") || CBRivalHasTrait(r, n"Humiliated")) {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalMoments-CallItEvenILetYou"), CBTalkActCallEven(), t"ChoiceCaptionParts.HandshakeIcon"));
    let other = CBTalkRivalForFaction(sys, game, n"", r.id);
    if IsDefined(other) {
      let w = CBTalkMakeLine(CBTf(n"Cyberbane-RivalMoments-AskWhereSThenWeRe", [CBRivalDisplayName(sys.GetContent(), other)]),
                             CBTalkActWhereIs(), t"ChoiceCaptionParts.BountyHuntIcon");
      w.important = true;
      ArrayPush(out, w);
    }
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-RivalMoments-ExileGetOutOfNightCity"), CBTalkActLeaveTown(), t"ChoiceCaptionParts.BackOutIcon"));
  }
  return out;
}

public func CBRivalBookEscorts(game: GameInstance) -> array<EntityID> {
  let book = CBRivalBook.Get(game);
  let none: array<EntityID>;
  return IsDefined(book) ? book.fdEscorts : none;
}

// What the Rival says back, and what it does.
public func CBRivalFacedownAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                                  t: ref<CBTalkTarget>, choice: Int32) -> ref<CBTalkAnswer> {
  let book = CBRivalBook.Get(game);
  let r = sys.FindRivalById(t.rivalId);
  let body: ref<ScriptedPuppet> = t.npc;
  if !IsDefined(book) || !IsDefined(r) || book.fdState != 1 || !IsDefined(body) || NotEquals(body.GetEntityID(), book.fdBody) {
    return CBTalkSay("...", n"");
  }
  CBTalkMarkSent(game, body);   // it is over, whatever was said
  body.cbFacedownOpen = false;
  let now = CBGameSeconds(game);
  let district = CBEventDistrict(sys, game);
  if choice == CBTalkActStare() {
    if RandF() < CBStareChance(sys, game, player, r) {
      // Some of their people break and run; the Rival fights shaken.
      let k = 0;
      for id in book.fdEscorts {
        let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
        if k % 2 == 0 && CBNpcSafe(sys, p) && CBStillStanding(p) {
          p.cbMoraleBroken = true;
          CBTalkReleaseHold(p);
          CBOrderFlee(game, p);
        }
        k += 1;
      }
      let kept: array<EntityID>;
      k = 0;
      for id2 in book.fdEscorts {
        if k % 2 == 1 {
          ArrayPush(kept, id2);
        }
        k += 1;
      }
      book.fdEscorts = kept;
      CBAimFor(game, body, CBConfig.StareShakenAim(), CBConfig.StareSeconds());
      CBTalkFear(sys, game, r.faction, CBConfig.StareFear());
      CBFileLog(sys, n"StaredDown", now, district, r.faction, Cast<Float>(r.id));
      CBFacedownFight(sys, game, book, r, body, false);
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-FineFINELetSGetThis"), CBT(n"Cyberbane-RivalMoments-DonTDonTLookAt")), n"");
    }
    for id3 in book.fdEscorts {
      let pe = GameInstance.FindEntityByID(game, id3) as ScriptedPuppet;
      if IsDefined(pe) {
        CBAimFor(game, pe, CBConfig.StareBoldAim(), CBConfig.StareSeconds());
      }
    }
    CBAimFor(game, body, CBConfig.StareBoldAim(), CBConfig.StareSeconds());
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-ThatSItThatSThe"), CBT(n"Cyberbane-RivalMoments-YouBlinkedTakeThem")), n"");
  }
  if choice == CBTalkActWalkAway() {
    CBFacedownLetGo(sys, game, book, r, body);
    CBFileLog(sys, n"FacedownWalked", now, district, r.faction, Cast<Float>(r.id));
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalMoments-HadYouAndLetYouWalk", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]), n"");
    }
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-GoOnThenThisOnceNext"), CBT(n"Cyberbane-RivalMoments-WalkIWantEverybodyToSee")), n"");
  }
  if choice == CBTalkActOneOnOne() {
    let accept = CBConfig.DuelBase() + (CBRivalHasTrait(r, n"Confident") ? 0.15 : 0.0) - (CBRivalHasTrait(r, n"PackLeader") ? 0.2 : 0.0);
    if Equals(r.faction, n"Valentinos") || Equals(r.faction, n"Animals") {
      accept += CBConfig.DuelGangBonus();
    }
    if RandF() < accept {
      book.fdState = 2;
      CBFacedownHostile(sys, game, body);
      CBIntelSay(game, 4, CBIntelSpeaker(r.faction), CBT(n"Cyberbane-RivalMoments-NobodyTouchesThisOneItS"), 3.0);
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-JustYouAndMeThenNobody"), CBT(n"Cyberbane-RivalMoments-FairEnoughBackOffAllOf")), n"");
    }
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-FairFightsAreForPeopleWho"), CBT(n"Cyberbane-RivalMoments-WhyWouldIDoThatGet")), n"");
  }
  if choice == CBTalkActCallEven() {
    let chance = CBConfig.CallEvenBase() + 0.25 * Cast<Float>(r.sparedByV) + (CBRivalHasTrait(r, n"Shaken") ? 0.15 : 0.0)
               - 0.08 * Cast<Float>(r.rank - 1);
    if RandF() < chance {
      r.state = EnumInt(ECBRivalState.Dormant);
      CBFacedownLetGo(sys, game, book, r, body);
      CBFileLog(sys, n"CalledEven", now, district, r.faction, Cast<Float>(r.id));
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-EvenFineDonTComeLooking"), CBT(n"Cyberbane-RivalMoments-WeReSquareIMDone")), n"");
    }
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay(CBT(n"Cyberbane-RivalMoments-EvenYouDonTGetTo"), n"");
  }
  if choice == CBTalkActWhereIs() {
    let i = CBIntelGive(sys, game, player, n"", true, r.id);
    CBFacedownLetGo(sys, game, book, r, body);
    if i.kind == CBIntelNone() {
      return CBTalkSay(CBT(n"Cyberbane-RivalMoments-IDonTKnowAnythingI"), n"fear_beg");
    }
    return CBTalkSay(CBTf(n"Cyberbane-RivalMoments-NowWeReDone", [CBIntelSpoken(i)]), n"");
  }
  if choice == CBTalkActLeaveTown() {
    let chance = CBConfig.ExileBase() - 0.15 * Cast<Float>(r.rank - 1) + (CBRivalHasTrait(r, n"Shaken") ? 0.2 : 0.0);
    if CBRivalHasTrait(r, n"HardToScare") || CBRivalHasTrait(r, n"Broken") {
      chance = 0.0;
    }
    if RandF() < chance {
      r.state = EnumInt(ECBRivalState.Retired);
      book.SetEnding(r.id, CBEndingRetired(), now);
      CBFacedownLetGo(sys, game, book, r, body);
      CBFileLog(sys, n"RivalExiled", now, district, r.faction, Cast<Float>(r.id));
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-OkayIMGoneYouLl"), CBT(n"Cyberbane-RivalMoments-NightCitySYoursIM")), n"");
    }
    CBRivalGiveTrait(r, n"Humiliated");
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay(CBT(n"Cyberbane-RivalLife-RunFromYouNever"), n"");
  }
  // Draw, and anything else.
  CBFacedownFight(sys, game, book, r, body, true);
  return CBTalkSay(CBPick2(CBT(n"Cyberbane-RivalMoments-YourFuneral"), CBT(n"Cyberbane-RivalMoments-Finally")), n"");
}

func CBStareChance(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, r: ref<CBRival>) -> Float {
  let stats = GameInstance.GetStatsSystem(game);
  let cool = IsDefined(stats) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Cool) : 3.0;
  let score = sys.GetScore();
  let renown = IsDefined(score) ? score.GetRenown() : 0.0;
  let chance = CBConfig.StareBase() + ClampF((cool - 3.0) / 17.0, 0.0, 1.0) * CBConfig.StareCool()
             + ClampF(renown / 100.0, 0.0, 1.0) * CBConfig.StareRenown() - Cast<Float>(r.rank - 1) * CBConfig.StareRank();
  if CBRivalHasTrait(r, n"HardToScare") {
    chance -= 0.25;
  }
  if CBRivalHasTrait(r, n"Shaken") {
    chance += 0.15;
  }
  return ClampF(chance, 0.05, 0.9);
}

// An aim modifier for a while, added and taken off with the same data (the game's effector pattern; [44]).
public func CBAimFor(game: GameInstance, puppet: ref<ScriptedPuppet>, mult: Float, seconds: Float) -> Void {
  let stats = GameInstance.GetStatsSystem(game);
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(puppet) || !puppet.IsAttached() || !IsDefined(stats) || !IsDefined(ds) {
    return;
  }
  let id = puppet.GetEntityID();
  let mod = RPGManager.CreateStatModifier(gamedataStatType.Accuracy, gameStatModifierType.Multiplier, mult);
  if !IsDefined(mod) || !stats.AddModifier(Cast<StatsObjectID>(id), mod) {
    return;
  }
  let cb = new CBVolleyEndCallback();
  cb.game = game;
  cb.id = id;
  cb.mod = mod;
  ds.DelayCallback(cb, seconds, false);
}

func CBRivalTauntTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, player: ref<PlayerPuppet>) -> Void {
  let tick = sys.GetTickCount();
  if !CBMessagesOn() || !player.IsInCombat() || tick - book.tauntTick < CBConfig.TauntTicks() || tick % 5 != 0 {
    return;
  }
  let r = sys.FindRivalById(sys.GetActiveRivalId());
  if !IsDefined(r) || !EntityID.IsDefined(r.spawnedEntityId) {
    return;
  }
  let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
  if !CBNpcSafe(sys, body) || !CBStillStanding(body) || !CBNpcInCombat(body)
     || Vector4.Distance(body.GetWorldPosition(), player.GetWorldPosition()) > CBConfig.TauntRange() {
    return;
  }
  book.tauntTick = tick;
  if RandF() < CBConfig.TauntChance() {
    CBIntelSay(game, 3, CBRivalDisplayName(sys.GetContent(), r), CBRivalTaunt(r), 3.0);
    // And in their own voice: a battle cry from the body in the fight.
    if IsDefined(body) {
      CBVoice(sys, game, body, n"battlecry_curse", n"RivalTaunt", 25.0, n"start_combat");
    }
  }
}

// ---- [55] Humiliation and [57] setting them on each other, at mercy ---------------------------------------------------

public func CBRivalWasHumiliated(r: ref<CBRival>) -> Bool {
  let book = CBRivalBook.Get(GetGameInstance());
  return IsDefined(book) && IsDefined(r) && book.HasFlag(r.id, CBRivalFlagHumiliated());
}

// A rank down, a mocking name, and then they either quit the gang or come back obsessed. Their gang fears V more.
public func CBRivalHumiliate(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, e: ref<CBEscapee>) -> String {
  let book = CBRivalBook.Get(game);
  CBRivalGiveTrait(r, n"Humiliated");
  if IsDefined(book) {
    book.SetFlag(r.id, CBRivalFlagHumiliated());
  }
  CBTalkFear(sys, game, r.faction, CBConfig.HumiliateFear());
  CBFileLog(sys, n"Humiliated", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
  if RandF() < CBConfig.HumiliateQuitChance() {
    r.rank = Max(1, r.rank - 1);
    e.exiled = true;
    return CBPick2(CBT(n"Cyberbane-RivalMoments-IMDoneIMDone"), CBT(n"Cyberbane-RivalMoments-NobodyWillEverLookAtMe"));
  }
  CBRivalGiveTrait(r, n"GrudgeBearer");
  // Obsessed enough to go under the knife, asked while they still stand at the top: a break is for the top of the ladder
  // (CBRivalMaybeBreak), and asked after the rank they lose for this, it could never happen.
  CBRivalMaybeBreak(sys, game, r);
  r.rank = Max(1, r.rank - 1);
  return CBPick2(CBT(n"Cyberbane-RivalMoments-LaughGoOnILlRemember"), CBT(n"Cyberbane-RivalMoments-YouLlPayForThisEvery"));
}

// The mocking names a humiliated Rival is known by, from their id.
public func CBHumiliatedEpithet(r: ref<CBRival>) -> String {
  let names = [CBT(n"Cyberbane-RivalMoments-Kneeler"), CBT(n"Cyberbane-RivalMoments-Doormat"), CBT(n"Cyberbane-RivalMoments-SecondPlace"), CBT(n"Cyberbane-RivalMoments-TheFloor"), CBT(n"Cyberbane-RivalMoments-DustEater"), CBT(n"Cyberbane-RivalMoments-LapDog"), CBT(n"Cyberbane-RivalMoments-GlassJaw"), CBT(n"Cyberbane-RivalMoments-Crawler"), CBT(n"Cyberbane-RivalMoments-Pushover")];
  return names[CBHashIndex(r.id, 83, ArraySize(names))];
}

// Who V could set this Rival on: one of a gang at war with theirs, not out now.
public func CBFeudTargetFor(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> ref<CBRival> {
  if !CBRivalFeudsOn() || !IsDefined(r) {
    return null;
  }
  let content = sys.GetContent();
  let enemies: array<CName>;
  if IsDefined(content) {
    enemies = CBGangRivalsOf(content, r.faction);
  }
  for o in sys.GetRivals() {
    if IsDefined(o) && o.id != r.id && ArrayContains(enemies, o.faction) && CBRivalStillAround(o)
       && o.id != sys.GetActiveRivalId() && !CBRivalBodyPresent(game, o) {
      return o;
    }
  }
  return null;
}

public func CBRivalSetOn(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  let book = CBRivalBook.Get(game);
  let other = CBFeudTargetFor(sys, game, r);
  if !IsDefined(book) || !IsDefined(other) {
    return CBT(n"Cyberbane-RivalMoments-IDonTKnowWhoYou");
  }
  book.SetFeud(r.id, other.id, CBGameSeconds(game) + CBConfig.FeudDelayHours() * CBConfig.SecondsPerHour());
  CBFileLog(sys, n"FeudSet", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(other.id));
  return CBTf(n"Cyberbane-RivalMoments-YeahIVeWantedThatOne", [s"\(CBRivalDisplayName(sys.GetContent(), other))"]);
}

// ---- When a Rival falls: [63] last words, [60] a trophy, [58] the bond, and how it ended -------------------------------

// From the death path (Signals/CombatSignals.reds), once CBRivalSlain has run.
public func CBRivalFell(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, r: ref<CBRival>, byV: Bool) -> Void {
  let book = CBRivalBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !IsDefined(puppet) {
    return;
  }
  let now = CBGameSeconds(game);
  let how = CBEndingNotByV();
  if byV {
    how = CBEndingByV();
    if CBMethodHas(puppet.cbLastMethodMask, CBMethodFinisher()) {
      how = CBEndingFinisher();
    }
    if puppet.cbFlawStruck {
      how = CBEndingFlaw();
    }
  }
  book.SetEnding(r.id, how, now);
  book.KeepPlace(r.id, puppet.GetWorldPosition(), CBEventDistrict(sys, game));
  if byV && CBMessagesOn() {
    CBIntelSay(game, 3, CBRivalDisplayName(sys.GetContent(), r), CBRivalLastWords(sys, game, r), 3.5);
  }
  if byV {
    CBRivalTrophy(sys, game, book, puppet, r);
    CBGiveStreetCred(game, CBConfig.CredRivalBase() + CBConfig.CredRivalPerRank() * r.rank);   // [87]
  }
  CBBondOnDeath(sys, game, book, r, byV);
  CBEmit(n"Cyberbane/RivalSlain", r.faction, Cast<Float>(r.rank));   // [91]
}

// The weapon their record carries, the way the game itself works out what an NPC holds.
func CBRivalTrophy(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, puppet: ref<ScriptedPuppet>, r: ref<CBRival>) -> Void {
  if !CBTrophiesOn() || book.HasFlag(r.id, CBRivalFlagTrophy()) || r.rank < CBConfig.TrophyMinRank() || !CBGameHasVHere(game) {
    return;
  }
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return;
  }
  let items: array<wref<NPCEquipmentItem_Record>>;
  AIActionTransactionSystem.CalculateEquipmentItems(puppet, n"PrimaryEquipment", items, -1);
  for it in items {
    let rec = IsDefined(it) ? it.Item() : null;
    if IsDefined(rec) && IsDefined(TweakDBInterface.GetWeaponItemRecord(rec.GetID())) {
      book.SetFlag(r.id, CBRivalFlagTrophy());
      ts.GiveItem(player, ItemID.FromTDBID(rec.GetID()), 1);
      CBFileLog(sys, n"Trophy", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
      if CBToastsOn() {
        let what = GetLocalizedTextByKey(rec.DisplayName());
        CBSystemNote(game, CBTf(n"Cyberbane-RivalMoments-YouTookOffSomethingToRemember", [StrLen(what) > 0 ? what : CBT(n"Cyberbane-RivalMoments-TheirGun"), s"\(CBRivalDisplayName(sys.GetContent(), r))"]), 5.0);
      }
      return;
    }
  }
}

// One of a bond is dead: the other answers it, by what they were to them. `byV`: only a death V caused is avenged on V.
func CBBondOnDeath(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, dead: ref<CBRival>, byV: Bool) -> Void {
  let otherId = book.BondWith(dead.id);
  let other = otherId > 0 ? sys.FindRivalById(otherId) : null;
  if !IsDefined(other) || !CBRivalStillAround(other) || book.HasFlag(other.id, CBRivalFlagBondSettled()) {
    return;
  }
  book.SetFlag(other.id, CBRivalFlagBondSettled());
  let kind = book.BondKind(other.id);   // what the living one was to the dead one
  let name = CBRivalDisplayName(sys.GetContent(), other);
  let deadName = CBRivalDisplayName(sys.GetContent(), dead);
  let now = CBGameSeconds(game);
  if !byV {
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalMoments-BuriedWhoeverDidItItWasn", [s"\(name)", s"\(deadName)", s"\(name)"]), n"");
    }
    return;
  }
  // A mentor who lost a protégé may be frightened off; a lover may just leave; the rest come for V.
  if kind == CBBondMentor() && RandF() < 0.5 {
    CBRivalGiveTrait(other, n"Shaken");
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalMoments-TrainedWordIsTheyVeGone", [s"\(name)", s"\(deadName)"]), n"");
    }
    return;
  }
  // Not one out in the world or after V right now: their encounter is theirs to finish first.
  if kind == CBBondLover() && RandF() < 0.3 && !CBRivalBodyPresent(game, other) && other.id != sys.GetActiveRivalId() {
    other.state = EnumInt(ECBRivalState.Retired);
    book.SetEnding(other.id, CBEndingRetired(), now);
    CBHierarchyFill(sys, other.faction);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalMoments-PackedABagTheNightDied", [s"\(name)", s"\(deadName)"]), n"");
    }
    return;
  }
  CBRivalGiveTrait(other, n"GrudgeBearer");
  other.huntTicks = Min(other.huntTicks, CBConfig.BondVengeanceTicks());
  CBFileLog(sys, n"BondVengeance", now, CBEventDistrict(sys, game), other.faction, Cast<Float>(other.id));
  if CBMessagesOn() {
    CBPhoneSendTinted(game, name, CBTf(n"Cyberbane-RivalMoments-YouKilled", [s"\(deadName)", s"\(CBBondLossLine(kind))"]), CBHudRed());
  }
}

func CBBondLossLine(kind: Int32) -> String {
  if kind == CBBondProtege() {
    return CBT(n"Cyberbane-RivalMoments-TheyTaughtMeEverythingIM");
  }
  if kind == CBBondMentor() {
    return CBT(n"Cyberbane-RivalMoments-IMadeThemWhatTheyWere");
  }
  if kind == CBBondLover() {
    return CBT(n"Cyberbane-RivalMoments-ThereSNothingLeftOfMe");
  }
  return CBT(n"Cyberbane-RivalMoments-WeWerePartnersNowIM");
}

// Spared, from the mercy path (Reactions/CombatFlee.reds): where V first beat them, and the bond may put the other in
// V's debt.
public func CBRivalSparedMoment(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, body: wref<ScriptedPuppet>) -> Void {
  let book = CBRivalBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) {
    return;
  }
  // Where they lay, while the body can still say; where V stands otherwise, a few steps off at most.
  let player = GetPlayer(game);
  if CBNpcSafe(sys, body) {
    book.KeepPlace(r.id, body.GetWorldPosition(), CBEventDistrict(sys, game));
  } else {
    if IsDefined(player) {
      book.KeepPlace(r.id, player.GetWorldPosition(), CBEventDistrict(sys, game));
    }
  }
  let otherId = book.BondWith(r.id);
  let other = otherId > 0 ? sys.FindRivalById(otherId) : null;
  if !IsDefined(other) || other.state != EnumInt(ECBRivalState.Active) || book.HasFlag(other.id, CBRivalFlagBondSettled())
     || CBRivalBodyPresent(game, other) || other.id == sys.GetActiveRivalId() || RandF() >= CBConfig.BondDebtChance() {
    return;
  }
  book.SetFlag(other.id, CBRivalFlagBondSettled());
  other.state = EnumInt(ECBRivalState.Debtor);
  CBHierarchyFill(sys, other.faction);
  if CBMessagesOn() {
    CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), other),
      CBTf(n"Cyberbane-RivalMoments-YouLetLiveIWonT", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]), CBHudCyan());
  }
}

// ---- Once a game day (the slow tick): bonds, feuds, returns, letters, and chrome the street hears about ----------------

public func CBRivalLivesDaily(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let book = CBRivalBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !CBRivalsOn() || days <= 0.0 {
    return;
  }
  let now = CBGameSeconds(game);
  CBRivalBondsTick(sys, game, book);
  CBRivalFeudTick(sys, game, book, now, days);
  CBRivalReturnTick(sys, game, book, now, days);
  CBRivalEndedUpTick(sys, game, book, now, days);
  CBRivalChromeTick(sys, game, book);
}

// [58] Two of a gang without a bond may form one, once each.
func CBRivalBondsTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>) -> Void {
  let rivals = sys.GetRivals();
  for a in rivals {
    if IsDefined(a) && CBRivalStillAround(a) && book.BondKind(a.id) == CBBondNone() && !book.HasFlag(a.id, CBRivalFlagBondTried()) {
      book.SetFlag(a.id, CBRivalFlagBondTried());
      if RandF() < CBConfig.BondChance() {
        for b in rivals {
          if IsDefined(b) && b.id != a.id && Equals(b.faction, a.faction) && CBRivalStillAround(b) && book.BondWith(b.id) == 0
             && book.BondWith(a.id) == 0 {
            let kind = CBHashIndex(a.id + b.id, 29, 3) + 1;   // mentor, protégé (as the other end), lover or partner
            if kind == CBBondProtege() {
              kind = CBBondPartner();
            }
            // The higher rank is the mentor.
            if kind == CBBondMentor() && b.rank > a.rank {
              book.SetBond(b.id, a.id, kind);
            } else {
              book.SetBond(a.id, b.id, kind);
            }
          }
        }
      }
    }
  }
}

public func CBBondWord(kind: Int32) -> String {
  switch kind {
    case 1: return CBT(n"Cyberbane-RivalMoments-MentorTo");
    case 2: return CBT(n"Cyberbane-RivalMoments-ProtGOf");
    case 3: return CBT(n"Cyberbane-RivalMoments-InLoveWith");
    case 4: return CBT(n"Cyberbane-RivalMoments-PartnersWith");
    default: return "";
  }
}

// [57] Rivals of gangs at war go after each other now and then; and the one V set going is settled when its time comes.
func CBRivalFeudTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, now: Float, days: Float) -> Void {
  if !CBRivalFeudsOn() {
    return;
  }
  if book.FeudA() > 0 {
    if now >= book.FeudAt() {
      let a = sys.FindRivalById(book.FeudA());
      let b = sys.FindRivalById(book.FeudB());
      book.SetFeud(0, 0, 0.0);
      if IsDefined(a) && IsDefined(b) && CBRivalStillAround(a) && CBRivalStillAround(b) {
        // Never with either of them out in the world, or the one after V now: it waits for them to be off the street.
        if CBRivalBodyPresent(game, a) || CBRivalBodyPresent(game, b) || a.id == sys.GetActiveRivalId()
           || b.id == sys.GetActiveRivalId() {
          book.SetFeud(a.id, b.id, now + CBConfig.SecondsPerHour());
          return;
        }
        CBRivalFeudFight(sys, game, book, a, b, CBConfig.FeudSetOnEdge(), true);
      }
    }
    return;
  }
  if RandF() >= CBConfig.FeudChancePerDay() * days {
    return;
  }
  let content = sys.GetContent();
  let rivals = sys.GetRivals();
  for a in rivals {
    if IsDefined(a) && CBRivalStillAround(a) && a.id != sys.GetActiveRivalId() && !CBRivalBodyPresent(game, a) {
      let enemies: array<CName>;
      if IsDefined(content) {
        enemies = CBGangRivalsOf(content, a.faction);
      }
      for b in rivals {
        if IsDefined(b) && b.id != a.id && ArrayContains(enemies, b.faction) && CBRivalStillAround(b)
           && b.id != sys.GetActiveRivalId() && !CBRivalBodyPresent(game, b) {
          CBRivalFeudFight(sys, game, book, a, b, 0, false);
          return;
        }
      }
    }
  }
}

// Off screen: the stronger usually wins. The loser dies, not by V; the winner climbs.
func CBRivalFeudFight(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, a: ref<CBRival>, b: ref<CBRival>,
                      edgeA: Int32, setByV: Bool) -> Void {
  let sa = a.rank * 2 + a.escapes + edgeA + RandRange(0, 4);
  let sb = b.rank * 2 + b.escapes + RandRange(0, 4);
  let winner = sa >= sb ? a : b;
  let loser = sa >= sb ? b : a;
  let now = CBGameSeconds(game);
  loser.state = EnumInt(ECBRivalState.Slain);
  loser.lastSeenAt = now;
  book.SetEnding(loser.id, CBEndingNotByV(), now);
  CBHierarchyOnSlain(sys, game, loser);
  CBOweFuneral(game, loser.faction);
  CBPromoteRival(winner, sys.GetContent(), now);
  CBFileLog(sys, n"RivalFeud", now, CBEventDistrict(sys, game), winner.faction, Cast<Float>(loser.id));
  CBLog.Info(n"Rivals", s"Rival \(winner.id) killed Rival \(loser.id) off screen (set by V: \(setByV)).");
  if CBMessagesOn() {
    let w = CBRivalDisplayName(sys.GetContent(), winner);
    let l = CBRivalDisplayName(sys.GetContent(), loser);
    CBHearsayFromStreet(game, setByV ? CBTf(n"Cyberbane-RivalMoments-YouPointedAtWalkedAwayFrom", [s"\(CBRivalDisplayName(sys.GetContent(), a))", s"\(CBRivalDisplayName(sys.GetContent(), b))", s"\(w)", s"\(l)"])
                                     : CBTf(n"Cyberbane-RivalMoments-CaughtUpWithOnlyOneOf", [s"\(w)", s"\(l)"]), n"");
  }
}

// [56] Rarely, one V killed comes back weeks later, rebuilt. Never one finished with a finisher or a fatal flaw.
func CBRivalReturnTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, now: Float, days: Float) -> Void {
  if !CBBackFromDeadOn() || RandF() >= CBConfig.ReturnChancePerDay() * days {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let maxRivals = IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().maxRivals : CBConfig.RivalMaxActiveHardCap();
  if sys.CountActiveRivals() >= maxRivals {
    return;
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Slain) && book.Ending(r.id) == CBEndingByV()
       && !book.HasFlag(r.id, CBRivalFlagReturned()) && now - book.EndedAt(r.id) >= CBConfig.ReturnDays() * CBConfig.SecondsPerDay()
       && CBFactionOn(r.faction) && CBRecordIsPerson(r.recordID) && !CBRecordIsSightingCyberpsycho(r.recordID) {
      book.SetFlag(r.id, CBRivalFlagReturned());
      r.state = EnumInt(ECBRivalState.Active);
      r.rank = Min(4, r.rank + 1);
      r.huntTicks = CBConfig.RivalAfterEscapeTicks();
      CBRivalGiveTrait(r, n"ChromedOut");
      CBRivalGiveTrait(r, n"Scarred");
      CBRivalGiveTrait(r, n"GrudgeBearer");
      CBHierarchyFill(sys, r.faction);
      CBFileLog(sys, n"RivalReturned", now, CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
      if CBMessagesOn() {
        CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), r),
          CBT(n"Cyberbane-RivalMoments-MissMeSomeBackAlleyRipperdoc"), CBHudRed());
      }
      return;
    }
  }
}

public func CBRivalReturned(r: ref<CBRival>) -> Bool {
  let book = CBRivalBook.Get(GetGameInstance());
  return IsDefined(book) && IsDefined(r) && book.HasFlag(r.id, CBRivalFlagReturned());
}

public func CBReturnedEpithet(r: ref<CBRival>) -> String {
  let names = [CBT(n"Cyberbane-RivalMoments-Lazarus"), CBT(n"Cyberbane-RivalMoments-SecondLife"), CBT(n"Cyberbane-RivalMoments-Stitched"), CBT(n"Cyberbane-RivalMoments-TheRevenant"), CBT(n"Cyberbane-RivalMoments-BackAgain"), CBT(n"Cyberbane-RivalMoments-Patchwork"), CBT(n"Cyberbane-RivalMoments-Rebuilt")];
  return names[CBHashIndex(r.id, 89, ArraySize(names))];
}

// [61] One who left Night City is heard from again, once, weeks later.
func CBRivalEndedUpTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, now: Float, days: Float) -> Void {
  for r in sys.GetRivals() {
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Retired) && !book.HasFlag(r.id, CBRivalFlagEndedUp()) {
      // Retired before the book knew: from now.
      if book.EndedAt(r.id) <= 0.0 {
        book.SetEnding(r.id, CBEndingRetired(), now);
      } else {
        // Not held back by the messages setting: coming back to Night City is a Rival's life, not a text, and with
        // messages off a retired Rival never came back at all. What is only said is still only said with them on.
        if now - book.EndedAt(r.id) >= CBConfig.EndedUpDays() * CBConfig.SecondsPerDay() && RandF() < CBConfig.EndedUpChancePerDay() * days
           && CBFactionOn(r.faction) {
          book.SetFlag(r.id, CBRivalFlagEndedUp());
          CBRivalEndedUp(sys, game, r, now);
          return;
        }
      }
    }
  }
}

func CBRivalEndedUp(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Void {
  let name = CBRivalDisplayName(sys.GetContent(), r);
  CBFileLog(sys, n"RivalEndedUp", now, CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
  let roll = CBHashIndex(r.id, 97, 3);
  if roll == 0 && !CBMessagesOn() {
    return;   // what they would have told V, by text; nobody to tell it to
  }
  if roll == 0 {
    let player = GetPlayer(game);
    let i = IsDefined(player) ? CBIntelGive(sys, game, player, n"", true, r.id) : null;
    if IsDefined(i) && i.kind != CBIntelNone() {
      CBPhoneSendTinted(game, name, CBTf(n"Cyberbane-RivalMoments-RememberMeIMOutOf", [CBIntelSpoken(i)]), CBHudCyan());
      return;
    }
  }
  // The warning: theirs by the roll, or by a tip with nothing in it, or a comeback with no room for one. A tip with
  // nothing to tell fell through to the comeback, and a comeback took no notice of the Max rivals setting.
  let rt = CyberbaneRuntime.Get();
  let maxRivals = IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().maxRivals : CBConfig.RivalMaxActiveHardCap();
  if roll <= 1 || sys.CountActiveRivals() >= maxRivals || sys.CountActiveFactionRivals(r.faction) >= CBConfig.RivalMaxPerFaction() {
    if CBMessagesOn() {
      CBPhoneSendTinted(game, name, CBTf(n"Cyberbane-RivalMoments-HeadsUpForOldTimesSake", [s"\(CBCapFirst(CBFactionLabel(r.faction)))"]), CBHudAmber());
    }
    return;
  }
  // An invitation to finish it: they come back, and may take a chair that stood empty.
  r.state = EnumInt(ECBRivalState.Active);
  r.huntTicks = CBConfig.RivalAfterEscapeTicks();
  CBRivalGiveTrait(r, n"GrudgeBearer");
  CBHierarchyFill(sys, r.faction);
  if CBMessagesOn() {
    CBPhoneSendTinted(game, name, CBT(n"Cyberbane-RivalMoments-ThoughtICouldLeaveItI"), CBHudRed());
  }
}

// [U9] A climb that came with chrome is something the street hears about.
func CBRivalChromeTick(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>) -> Void {
  if !CBRivalChromeOn() {
    return;
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && CBRivalStillAround(r) {
      let mask = CBRivalImplants(r);
      let said = book.Chrome(r.id);
      if mask != said {
        book.SetChrome(r.id, mask);
        // Only a new implant is news; one lost to a rank taken away is not.
        let bit = 0;
        let fresh = "";
        while bit < 5 {
          if CBMaskHas(mask, bit) && !CBMaskHas(said, bit) {
            fresh = CBImplantName(bit);
          }
          bit += 1;
        }
        if StrLen(fresh) > 0 {
          CBFileLog(sys, n"UnderTheKnife", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
          // Still in the chair, and somebody knows which (Rivals/Whereabouts.reds, [U9]); or only the news.
          if !CBRipperdocLead(sys, game, r, fresh) && CBMessagesOn() {
            CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalMoments-WentUnderTheKnifeAndThey", [s"\(CBRivalDisplayName(sys.GetContent(), r))", s"\(CBCapFirst(fresh))"]), n"");
          }
          return;   // one a day is plenty
        }
      }
    }
  }
}

// ---- [U10] Places that are lived in -----------------------------------------------------------------------------------

// Somebody with a chair keeps hours, unless they named the place for V themselves (send word, a call-out).
public func CBRivalKeepsHours(game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || r.rank < CBConfig.LieutenantMinRank() {
    return false;
  }
  let intel = CBIntelBook.Get(game);
  return !IsDefined(intel) || !intel.WordSent(r.id);
}

// ---- [62] Places with meaning ---------------------------------------------------------------------------------------

// Somewhere that matters for a Rival calling V out: where their kin fell, or where V first beat them, when it is still
// a place a Rival can be put and close enough to go to.
public func CBRivalMeaningfulPlace(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, r: ref<CBRival>,
                                   out why: String) -> ref<CBSighting> {
  let book = CBRivalBook.Get(game);
  let svc = sys.GetPlayService();
  if !IsDefined(book) || !IsDefined(svc) || !IsDefined(r) || !IsDefined(player) {
    return null;
  }
  let intel = CBIntelBook.Get(game);
  let kin = IsDefined(intel) ? intel.KinOf(r.id) : 0;
  let use = 0;
  if kin > 0 && book.HasPlace(kin) {
    use = kin;
    why = CBT(n"Cyberbane-RivalMoments-WhereYouPutMyFamilyIn");
  } else {
    if book.HasPlace(r.id) {
      use = r.id;
      why = CBT(n"Cyberbane-RivalMoments-WhereYouLeftMeLying");
    }
  }
  if use == 0 {
    return null;
  }
  let at = book.Place(use);
  if Vector4.Distance(at, player.GetWorldPosition()) > CBConfig.MeaningMaxDistance() || !CBLairPointUsable(sys, game, at) {
    why = "";
    return null;
  }
  svc.NoteSighting(sys.GetPlaythroughId(), r.id, r.recordID, at, book.PlaceDistrict(use), CBGameSeconds(game));
  return svc.FindSighting(sys.GetPlaythroughId(), r.id);
}

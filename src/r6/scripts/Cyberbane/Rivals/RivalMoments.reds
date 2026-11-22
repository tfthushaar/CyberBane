// Cyberbane - The Rivals' moments (2.4.4)
//
//   [53] [54] the facedown    when a Rival comes close and nobody has fired yet, everyone stops: the Rival and their
//                             people hold, and V can talk to the Rival. [Stare them down] (Cool and renown against
//                             their rank and nerve: win and some of their people run and the Rival fights shaken,
//                             lose and they are emboldened), [Draw] (V gets the drop), [Walk away] (they let V go,
//                             once, and the street hears), [Just you and me] (their people hold back while the Rival
//                             fights alone, until V breaks the terms with a grenade, a hack or a shot at them)
//   [64] on their feet        a Rival who owes V or is afraid gets three more lines there: [Call it even], [Where's
//                             (another Rival)?] and [Get out of Night City]
//   [55] humiliation          a fourth line at mercy: they lose a rank and get a mocking name, and either quit or come
//                             back obsessed; their gang fears V more
//   [56] back from the dead   rarely, a Rival V killed comes back weeks later, rebuilt: never one finished with a
//                             finisher or a fatal flaw
//   [57] Rivals at war        Rivals of gangs at war go after each other between V's fights, and one can kill the
//                             other off screen; V can set one on another from mercy, with the other's whereabouts
//   [58] bonds                two Rivals of a gang can be bound (a mentor and a protégé, lovers, partners): killing
//                             one moves the other, sparing one can put the other in V's debt
//   [60] trophies             a named Rival killed by V gives up the weapon their record carries, into V's pockets
//   [61] where they ended up  a Rival who left Night City is heard from again, weeks later: a tip, a warning, or an
//                             invitation to finish it
//   [62] places with meaning  a Rival calling V out names the place V first beat them, or where their kin fell
//   [63] last words           a dying Rival says something of their own, from their history with V
//   [U9] Rival chrome         every climb can come with an implant, answering how V hurt them: stats and the game's
//                             own behaviour abilities, said on their page and in the scanner, and by the street
//   [U11] tactics by kind     a Survivor keeps their distance, a Killer pushes, an Avenger closes, a Hunter sees
//                             through smoke and camo
//   [L4] Rivals' lines        taunts mid-fight, and texts that remember the scars, the escapes and the kin
//
// Saved in the Rival book (Rivals/RivalBook.reds); the facedown is session state on it. Every order goes through the
// helpers the rest of the mod uses (CBTalkHold, CBOrderFlee, CBOrderPursue), every attitude change through the
// player's own agent, and every native read of a body behind CBNpcSafe.

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
    case 0: return "subdermal armour";
    case 1: return "dermal plating";
    case 2: return "a firewall";
    case 3: return "reinforced tendons";
    default: return "smoke-filter optics";
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

// And the game's own behaviour abilities, where an implant has one ([U9]), with how their kind fights ([U11]).
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
  // One of V's own who turned has fought beside V and knows how V moves (Reactions/Crew.reds, 2.5.0).
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
    return CBRivalPhrase(r, "Couldn't... finish it. For them.", "Tell my family... I tried.", "Same as them. Same... as them.");
  }
  if r.killedV > 0 {
    return CBRivalPhrase(r, "Beat you once. Nobody... can take that.", "Should've stayed down... the first time.", "Lucky. You got... lucky.");
  }
  if r.escapes >= 2 {
    return CBRivalPhrase(r, "Ran out of road.", "Thought I'd always... get away.", "Every time... but this one.");
  }
  if r.sparedByV > 0 {
    return CBRivalPhrase(r, "You let me live... should've left it there.", "Second chance... wasted it.", "Mercy... and then this.");
  }
  if CBRivalHasTrait(r, n"Humiliated") {
    return CBRivalPhrase(r, "At least... nobody's laughing now.", "Worth it... to see your face.", "Told you... I'd come back.");
  }
  return CBRivalPhrase(r, "Night City... remembers me.", "Not like this...", "You'll... see me again.");
}

// Mid-fight, now and then: what they remember of V.
public func CBRivalTaunt(r: ref<CBRival>) -> String {
  if CBMaskHas(r.scarMask, CBScarBurned()) {
    return CBRivalPhrase(r, "I still smell the smoke because of you!", "You burned me. I don't burn twice!", "Remember the fire? I do!");
  }
  if CBMaskHas(r.scarMask, CBScarCut()) {
    return CBRivalPhrase(r, "Still got your blade marks. Come add some!", "Cut me once. Not again!", "I wear your scars. You'll wear mine!");
  }
  if CBMaskHas(r.scarMask, CBScarFried()) {
    return CBRivalPhrase(r, "Stay out of my head this time!", "Fry me again? Try it!", "I paid for a firewall because of you!");
  }
  if r.killedV > 0 {
    return CBRivalPhrase(r, "You remember how this ends!", "Down you go. Again.", "Same as last time, merc!");
  }
  if r.escapes >= 2 {
    return CBRivalPhrase(r, "Caught you this time!", "No running today!", "You can't lose me!");
  }
  if CBRivalHasTrait(r, n"Humiliated") {
    return CBRivalPhrase(r, "Nobody laughs at me! Nobody!", "Who's crawling now?!", "Say it again! Say it!");
  }
  return CBRivalCatchphrase(r);
}

// What their texts remember, added to the line they send when they find V ([L4]).
public func CBRivalRemembers(game: GameInstance, r: ref<CBRival>) -> String {
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) && intel.KinOf(r.id) > 0 {
    return "This is for my family.";
  }
  if r.sparedByV > 0 {
    return "You let me walk last time. Big mistake.";
  }
  if r.escapes > 0 {
    return s"Got away from you \(r.escapes == 1 ? "once" : s"\(r.escapes) times"). Not running today.";
  }
  if CBMaskHas(r.scarMask, CBScarBurned()) || CBMaskHas(r.scarMask, CBScarCut()) || CBMaskHas(r.scarMask, CBScarShot()) {
    return "I still have the scars you gave me.";
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

// The same for one Rival in particular (2.5.7): the one waiting at their place, who is nobody's active Rival yet.
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
  // V in a fight that is not theirs (2.5.7): they are calm, so whoever V is fighting is somebody else. The facedown
  // cannot open in the middle of it, and its wait ran on regardless, so a Rival who walked up while V was busy turned
  // hostile without a word. The wait holds while V is busy, up to FacedownWaitMaxTicks in all.
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
      // (2.5.1, CBTalkEngaged): the clock holds while the words go back and forth.
      if CBTalkEngaged(sys, body) {
        book.fdTick = tick;
      }
      if body.cbDamagedByPlayer || CBFacedownEscortHit(game, book) || sys.GetTruce().Broken()
         || tick - book.fdTick > CBConfig.FacedownTicks() {
        CBFacedownFight(sys, game, book, r, body, false);
      }
      return;
    }
    // Just you and me: over when the Rival is down or gone; their people step in if V breaks the terms, or when the Rival is
    // all but beaten (2.6.7): "I told him to leave his people out of it, he said okay, and his bodyguards still started
    // shooting." They were held neutral, and the game turned them anyway the moment their boss was hurt in front of them
    // (AIActionHelper.TryChangingAttitudeToHostile, squad mate in danger), which now leaves alone anybody held out of a
    // fight (CBHeldOutOfFight). Their word holds until the Rival is nearly finished; then they cannot stand and watch.
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
  // Everybody else of theirs nearby holds too, the ones walking up included (2.6.7, Reactions/TalkTruce.reds): "a Rival
  // was offering to talk but his bodyguards started shooting". Only the escorts standing close at the start held.
  sys.GetTruce().Begin(sys, game, CBTruceFacedown(), r.faction, body);
  let name = CBRivalDisplayName(sys.GetContent(), r);
  CBIntelSay(game, 3, name, CBFacedownOpener(sys, game, r), 4.0);
  if CBToastsOn() && !book.fdHinted {
    book.fdHinted = true;
    CBSystemNote(game, s"\(name) wants a look at you first. Talk to them to face them down, or draw.", 5.0);
  }
  CBLog.Info(n"Rivals", s"Facedown with Rival \(r.id), \(ArraySize(book.fdEscorts)) of their people holding.");
}

// The first thing they say, from what they have been through with V.
func CBFacedownOpener(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  let you = CBYou(sys, game);
  let intel = CBIntelBook.Get(game);
  if IsDefined(intel) && intel.KinOf(r.id) > 0 {
    let dead = sys.FindRivalById(intel.KinOf(r.id));
    let who = IsDefined(dead) ? CBRivalDisplayName(sys.GetContent(), dead) : "my family";
    return s"Everybody stop. I want to look at the one who killed \(who) before I do this.";
  }
  if r.killedV > 0 {
    return s"Again, \(you)? You remember how this ended last time. Look at me first.";
  }
  if r.sparedByV > 0 {
    return "You let me walk once. Hold it, everybody. I want to see if that was mercy or a mistake.";
  }
  if r.escapes > 0 {
    return s"Nobody move. Last time I ran from \(you). Not today. Today we talk first.";
  }
  if r.encounters == 0 {
    return s"So you're \(you). Don't reach for it yet. I want a look at you first.";
  }
  return CBRivalPhrase(r, s"\(CBCapFirst(CBHere(sys))), you and me. Hands where I can see them.", "Don't reach for it yet. Look at me first.",
                       "Everybody stop. I want to see this one's face.");
}

// Somebody stops where they are and holds off V for a moment: their attitude to V alone, and one hold order.
// Walking up calm for a facedown (Spawn/Spawner.reds, CBApplySpawnSetup), and since when (2.5.0).
@addField(ScriptedPuppet)
public let cbFacedownWait: Bool;
@addField(ScriptedPuppet)
public let cbFacedownWaitTick: Int32;
// How much of that wait was held while V fought somebody else, and when it was last looked at (2.5.7).
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
  // And V's companions, or they open fire on people holding still (2.5.0). Hostile again with V (CBFacedownHostile).
  CBCalmTowardCompanions(CyberbaneSystem.Get(game), p);
  p.cbFacedownHeld = true;
  p.cbFacedownWait = false;
  CBCancelMove(p);
  // As long as a facedown can wait for V, as the hold always was: a conversation's own holds are short now (2.5.1).
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

// The Rival's people still walking up calm who were not close enough to be held when it opened (2.6.7). Whatever the
// facedown does with the people it holds, it does with them too: they turned on V once their wait ran out, which in a
// fight held for as long as V was fighting (CBFacedownWaitTick), so they stood calm through it, and after V was let go
// or won the duel they turned hostile later on their own.
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

// The Rival is nearly finished in a fair fight (2.6.7): their people break their word and come in, all of them at once, the
// ones standing further off included, and say so.
func CBFacedownStepIn(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBRivalBook>, r: ref<CBRival>) -> Void {
  let stepping = ArraySize(book.fdEscorts) + ArraySize(CBFacedownStragglers(game, book));
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
  if stepping > 0 {
    let name = CBRivalDisplayName(sys.GetContent(), r);
    CBIntelSay(game, 3, CBIntelSpeaker(r.faction), CBLineOf([
      "Boss is going down! Forget the deal, take them!",
      s"Nobody puts \(name) in the ground. Light them up!",
      "That's enough. Fair's over. Get them!",
      "We said we'd stay out. We lied. Drop them!"]), 3.0);
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
  CBIntelSay(game, 3, CBIntelSpeaker(r.faction), CBPick2("That's not how this works! Get them!", "No rules then. Light them up!"), 3.0);
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
      CBHearsayFromStreet(game, s"\(CBRivalDisplayName(sys.GetContent(), r)) asked for a fair fight and got one. Their people watched them lose.", n"");
    }
  }
}

// What V can say at the facedown.
public func CBRivalFacedownLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let r = sys.FindRivalById(t.rivalId);
  ArrayPush(out, CBTalkMakeLine("[Stare them down] Look at me. Think hard about this.", CBTalkActStare(), t"ChoiceCaptionParts.GrappleIcon"));
  ArrayPush(out, CBTalkMakeLine("[Draw] Let's go.", CBTalkActDraw(), TDBID.None()));
  ArrayPush(out, CBTalkMakeLine("[Walk away] Not today.", CBTalkActWalkAway(), t"ChoiceCaptionParts.BackOutIcon"));
  if ArraySize(CBRivalBookEscorts(game)) > 0 {
    ArrayPush(out, CBTalkMakeLine("[Just you and me] Tell your people to stay out of it.", CBTalkActOneOnOne(), TDBID.None()));
  }
  // [64] One who owes V, or is afraid of V, can be talked out of it.
  if IsDefined(r) && (r.sparedByV > 0 || CBRivalHasTrait(r, n"Shaken") || CBRivalHasTrait(r, n"Humiliated")) {
    ArrayPush(out, CBTalkMakeLine("[Call it even] I let you live once. We're even.", CBTalkActCallEven(), t"ChoiceCaptionParts.HandshakeIcon"));
    let other = CBTalkRivalForFaction(sys, game, n"", r.id);
    if IsDefined(other) {
      let w = CBTalkMakeLine("[Ask] Where's " + CBRivalDisplayName(sys.GetContent(), other) + "? Then we're done.",
                             CBTalkActWhereIs(), t"ChoiceCaptionParts.BountyHuntIcon");
      w.important = true;
      ArrayPush(out, w);
    }
    ArrayPush(out, CBTalkMakeLine("[Exile] Get out of Night City. Tonight.", CBTalkActLeaveTown(), t"ChoiceCaptionParts.BackOutIcon"));
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
      return CBTalkSay(CBPick2("...Fine. FINE. Let's get this over with.", "Don't... don't look at me like that."), n"");
    }
    for id3 in book.fdEscorts {
      let pe = GameInstance.FindEntityByID(game, id3) as ScriptedPuppet;
      if IsDefined(pe) {
        CBAimFor(game, pe, CBConfig.StareBoldAim(), CBConfig.StareSeconds());
      }
    }
    CBAimFor(game, body, CBConfig.StareBoldAim(), CBConfig.StareSeconds());
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay(CBPick2("That's it? That's the look everybody's scared of?", "You blinked. Take them!"), n"");
  }
  if choice == CBTalkActWalkAway() {
    CBFacedownLetGo(sys, game, book, r, body);
    CBFileLog(sys, n"FacedownWalked", now, district, r.faction, Cast<Float>(r.id));
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"\(CBRivalDisplayName(sys.GetContent(), r)) had you and let you walk. Once. The street's talking about why.", n"");
    }
    return CBTalkSay(CBPick2("Go on, then. This once. Next time there's no talking.", "Walk. I want everybody to see you walk away from me."), n"");
  }
  if choice == CBTalkActOneOnOne() {
    let accept = CBConfig.DuelBase() + (CBRivalHasTrait(r, n"Confident") ? 0.15 : 0.0) - (CBRivalHasTrait(r, n"PackLeader") ? 0.2 : 0.0);
    if Equals(r.faction, n"Valentinos") || Equals(r.faction, n"Animals") {
      accept += CBConfig.DuelGangBonus();
    }
    if RandF() < accept {
      book.fdState = 2;
      CBFacedownHostile(sys, game, body);
      CBIntelSay(game, 4, CBIntelSpeaker(r.faction), "Nobody touches this one. It's between them.", 3.0);
      return CBTalkSay(CBPick2("Just you and me, then. Nobody else.", "Fair enough. Back off, all of you. This one's mine."), n"");
    }
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay(CBPick2("Fair fights are for people who can afford to lose.", "Why would I do that? Get them!"), n"");
  }
  if choice == CBTalkActCallEven() {
    let chance = CBConfig.CallEvenBase() + 0.25 * Cast<Float>(r.sparedByV) + (CBRivalHasTrait(r, n"Shaken") ? 0.15 : 0.0)
               - 0.08 * Cast<Float>(r.rank - 1);
    if RandF() < chance {
      r.state = EnumInt(ECBRivalState.Dormant);
      CBFacedownLetGo(sys, game, book, r, body);
      CBFileLog(sys, n"CalledEven", now, district, r.faction, Cast<Float>(r.id));
      return CBTalkSay(CBPick2("...Even. Fine. Don't come looking for me.", "We're square. I'm done with you."), n"");
    }
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay("Even? You don't get to decide that.", n"");
  }
  if choice == CBTalkActWhereIs() {
    let i = CBIntelGive(sys, game, player, n"", true, r.id);
    CBFacedownLetGo(sys, game, book, r, body);
    if i.kind == CBIntelNone() {
      return CBTalkSay("I don't know anything. I swear. Just... let me go.", n"");
    }
    return CBTalkSay(CBIntelSpoken(i) + " Now we're done.", n"");
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
      return CBTalkSay(CBPick2("Okay. I'm gone. You'll never see me again.", "Night City's yours. I'm out."), n"");
    }
    CBRivalGiveTrait(r, n"Humiliated");
    CBFacedownFight(sys, game, book, r, body, false);
    return CBTalkSay("Run? From you? Never.", n"");
  }
  // Draw, and anything else.
  CBFacedownFight(sys, game, book, r, body, true);
  return CBTalkSay(CBPick2("Your funeral.", "Finally."), n"");
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

// An aim modifier for a while, added and taken off with the same data (the game's own effector pattern; [44]).
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
    return CBPick2("...I'm done. I'm done with all of it.", "Nobody will ever look at me the same. I'm out.");
  }
  CBRivalGiveTrait(r, n"GrudgeBearer");
  // Obsessed enough to go under the knife, asked while they still stand at the top: a break is for the top of the ladder
  // (CBRivalMaybeBreak), and asked after the rank they lose for this, it could never happen.
  CBRivalMaybeBreak(sys, game, r);
  r.rank = Max(1, r.rank - 1);
  return CBPick2("Laugh. Go on. I'll remember every second of this.", "You'll pay for this. Every word of it.");
}

// The mocking names a humiliated Rival is known by, from their id.
public func CBHumiliatedEpithet(r: ref<CBRival>) -> String {
  let names = ["Kneeler", "Doormat", "Second Place", "the Floor", "Dust Eater", "Lap Dog", "Glass Jaw", "Crawler", "Pushover"];
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
    return "I don't know who you mean.";
  }
  book.SetFeud(r.id, other.id, CBGameSeconds(game) + CBConfig.FeudDelayHours() * CBConfig.SecondsPerHour());
  CBFileLog(sys, n"FeudSet", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(other.id));
  return s"\(CBRivalDisplayName(sys.GetContent(), other))? ...Yeah. I've wanted that one for a long time.";
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
    CBGiveStreetCred(game, CBConfig.CredRivalBase() + CBConfig.CredRivalPerRank() * r.rank);   // [87], 2.4.6
  }
  CBBondOnDeath(sys, game, book, r, byV);
  CBEmit(n"Cyberbane/RivalSlain", r.faction, Cast<Float>(r.rank));   // [91], 2.4.6
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
        CBSystemNote(game, s"you took \(StrLen(what) > 0 ? what : "their gun") off \(CBRivalDisplayName(sys.GetContent(), r)). Something to remember them by.", 5.0);
      }
      return;
    }
  }
}

// One of a bond is dead: the other answers it, by what they were to them.
// `byV` (2.5.6): only a death V caused is avenged on V. The one bound to them texted "You killed [name]" and came for V
// whoever had killed them, the NCPD or another gang included.
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
      CBHearsayFromStreet(game, s"\(name) buried \(deadName). Whoever did it, it wasn't you, and \(name) knows it.", n"");
    }
    return;
  }
  // A mentor who lost a protégé may be frightened off; a lover may just leave; the rest come for V.
  if kind == CBBondMentor() && RandF() < 0.5 {
    CBRivalGiveTrait(other, n"Shaken");
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"\(name) trained \(deadName). Word is they've gone very quiet since.", n"");
    }
    return;
  }
  // Not one out in the world or after V right now: their encounter is theirs to finish first.
  if kind == CBBondLover() && RandF() < 0.3 && !CBRivalBodyPresent(game, other) && other.id != sys.GetActiveRivalId() {
    other.state = EnumInt(ECBRivalState.Retired);
    book.SetEnding(other.id, CBEndingRetired(), now);
    CBHierarchyFill(sys, other.faction);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"\(name) packed a bag the night \(deadName) died and left Night City.", n"");
    }
    return;
  }
  CBRivalGiveTrait(other, n"GrudgeBearer");
  other.huntTicks = Min(other.huntTicks, CBConfig.BondVengeanceTicks());
  CBFileLog(sys, n"BondVengeance", now, CBEventDistrict(sys, game), other.faction, Cast<Float>(other.id));
  if CBMessagesOn() {
    CBPhoneSendTinted(game, name, s"You killed \(deadName). \(CBBondLossLine(kind))", CBHudRed());
  }
}

func CBBondLossLine(kind: Int32) -> String {
  if kind == CBBondProtege() {
    return "They taught me everything. I'm going to use all of it on you.";
  }
  if kind == CBBondMentor() {
    return "I made them what they were. Now I'll make you nothing.";
  }
  if kind == CBBondLover() {
    return "There's nothing left of me but this. I'm coming.";
  }
  return "We were partners. Now I'm going to finish what we started.";
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
      s"You let \(CBRivalDisplayName(sys.GetContent(), r)) live. I won't forget that. I owe you.", CBHudCyan());
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
    case 1: return "mentor to";
    case 2: return "protégé of";
    case 3: return "in love with";
    case 4: return "partners with";
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
    CBHearsayFromStreet(game, setByV ? s"You pointed \(CBRivalDisplayName(sys.GetContent(), a)) at \(CBRivalDisplayName(sys.GetContent(), b)). \(w) walked away from it; \(l) didn't."
                                     : s"\(w) caught up with \(l). Only one of them walked away. One less name after you, and one bigger.", n"");
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
          "Miss me? Some back-alley ripperdoc put me back together. More chrome than meat now. I remember everything.", CBHudRed());
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
  let names = ["Lazarus", "Second Life", "Stitched", "the Revenant", "Back Again", "Patchwork", "Rebuilt"];
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
        if now - book.EndedAt(r.id) >= CBConfig.EndedUpDays() * CBConfig.SecondsPerDay() && RandF() < CBConfig.EndedUpChancePerDay() * days
           && CBMessagesOn() && CBFactionOn(r.faction) {
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
  if roll == 0 {
    let player = GetPlayer(game);
    let i = IsDefined(player) ? CBIntelGive(sys, game, player, n"", true, r.id) : null;
    if IsDefined(i) && i.kind != CBIntelNone() {
      CBPhoneSendTinted(game, name, "Remember me? I'm out of the life, but I still hear things. " + CBIntelSpoken(i) + " Call it a favour.", CBHudCyan());
      return;
    }
  }
  // The warning: theirs by the roll, or by a tip with nothing in it, or a comeback with no room for one. A tip with
  // nothing to tell fell through to the comeback, and a comeback took no notice of the Max rivals setting.
  let rt = CyberbaneRuntime.Get();
  let maxRivals = IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().maxRivals : CBConfig.RivalMaxActiveHardCap();
  if roll <= 1 || sys.CountActiveRivals() >= maxRivals || sys.CountActiveFactionRivals(r.faction) >= CBConfig.RivalMaxPerFaction() {
    CBPhoneSendTinted(game, name, s"Heads up, for old times' sake. \(CBCapFirst(CBFactionLabel(r.faction))) still talk about you. They haven't forgotten. Neither have I, but I'm not coming.", CBHudAmber());
    return;
  }
  // An invitation to finish it: they come back, and may take a chair that stood empty.
  r.state = EnumInt(ECBRivalState.Active);
  r.huntTicks = CBConfig.RivalAfterEscapeTicks();
  CBRivalGiveTrait(r, n"GrudgeBearer");
  CBHierarchyFill(sys, r.faction);
  CBPhoneSendTinted(game, name, "Thought I could leave it. I can't. I'm back in Night City, and we're going to finish this.", CBHudRed());
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
          // Still in the chair, and somebody knows which (Rivals/Whereabouts.reds, [U9], 2.5.0); or only the news.
          if !CBRipperdocLead(sys, game, r, fresh) && CBMessagesOn() {
            CBHearsayFromStreet(game, s"\(CBRivalDisplayName(sys.GetContent(), r)) went under the knife. \(CBCapFirst(fresh)), and they're telling everybody it's for you.", n"");
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

// Somewhere that matters for a Rival calling V out: where their kin fell, or where V first beat them, when it is
// still a place a Rival can be put and close enough to go to. Noted as their sighting there, which the hideout
// machinery then uses as it would any other; and why it matters, for their text.
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
    why = "Where you put my family in the ground.";
  } else {
    if book.HasPlace(r.id) {
      use = r.id;
      why = "Where you left me lying.";
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

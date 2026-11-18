// Cyberbane - Rival gangers clash on contested streets ([N1], 2.4.3)
//
// The idea is Night City Alive's (gangs that fight gangs); the way of doing it is Cyberbane's own. That mod edits the
// game's attitude groups for good, so every member of two gangs fights every other, everywhere, quest scenes included.
// Here it is scoped and put back: on a contested street (a challenger for the district in the turf book, or two gangs
// at war both on the streets V is on), now and then a pair or two of the world's own gangers of the two gangs, who
// the Director's walk has already seen and passed through the Safety Gate, are set hostile to each other through
// their own attitude agents, the way 2.3.4's fights are (CBSetPairAttitude). What each thought of the other before
// is read first and put back when it is over or V has gone. The side left standing moves the turf a little, the way
// a front line does.
//
// Never a story NPC or anybody at a job (only people the walk passed through the gate), never while V is on a job,
// in a scene, somewhere safe or in a fight, never between gangs in a truce, never a switched-off faction; one clash
// at a time, minutes apart. No new scan: the Director keeps the last few of each side it saw (CBClashNote), and the
// clash is chosen from those. Session only, on the war book.

public func CBStreetClashesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBTurfWarsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().streetClashes);
}

// The two gangs at war on the streets V is on, worked out every so often and kept on the book.
func CBClashPair(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>) -> Void {
  book.clashA = n"";
  book.clashB = n"";
  let district = sys.GetCurrentDistrict();
  if Equals(district, n"") {
    return;
  }
  let now = CBGameSeconds(game);
  // A challenger for this district, against whoever holds it.
  let turf = CBTurfBook.Get(game);
  let i = CBDistrictIndex(district);
  if IsDefined(turf) && i >= 0 {
    let holder = turf.Holder(i);
    let challenger = turf.Challenger(i);
    if CBClashFit(game, book, holder, challenger, now) {
      book.clashA = holder;
      book.clashB = challenger;
      return;
    }
  }
  // Or two gangs at war, both on these streets.
  let here = CBTurfGangsHere(sys);
  let content = sys.GetContent();
  for g in here {
    if Equals(book.clashA, n"") {
      let enemies = CBGangRivalsOf(content, g);
      for enemy in enemies {
        if Equals(book.clashA, n"") && ArrayContains(here, enemy) && CBClashFit(game, book, g, enemy, now) {
          book.clashA = g;
          book.clashB = enemy;
        }
      }
    }
  }
}

func CBClashFit(game: GameInstance, book: ref<CBWarBook>, a: CName, b: CName, now: Float) -> Bool {
  return NotEquals(a, n"") && NotEquals(b, n"") && NotEquals(a, b) && CBFactionFieldsSquads(a) && CBFactionFieldsSquads(b)
      && !CBIsCorpFaction(a) && !CBIsCorpFaction(b)
      && !Equals(book.TruceWith(a, now), b) && !Equals(book.TruceWith(b, now), a);
}

// From the Director's walk, for somebody who has passed the Safety Gate: one of the two sides, kept for a moment.
public func CBClashNote(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, faction: CName) -> Void {
  if Equals(faction, n"") || !IsDefined(npc) {
    return;
  }
  let book = CBWarBook.Get(sys.GetGameInstance());
  if !IsDefined(book) || Equals(book.clashA, n"") || ArraySize(book.fightA) > 0 {
    return;
  }
  let id = npc.GetEntityID();
  if Equals(faction, book.clashA) {
    book.KeepClashCandidate(true, id);
  } else {
    if Equals(faction, book.clashB) {
      book.KeepClashCandidate(false, id);
    }
  }
}

// Every few ticks, from the fast tick.
public func CBClashTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBWarBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(player) {
    return;
  }
  let tick = sys.GetTickCount();
  let busy = !CBStreetClashesOn() || !CBWorldStable(game) || sys.IsInSafeZone() || sys.IsInSanctuary()
          || CBArrivalsHeld(sys, game) || CBVDown(game);
  if ArraySize(book.fightA) > 0 {
    CBClashWatch(sys, game, book, player, busy, tick);
    return;
  }
  if busy {
    ArrayClear(book.candA);
    ArrayClear(book.candB);
    return;
  }
  if tick - book.clashPairTick >= CBConfig.ClashPairTicks() || book.clashPairTick == 0 {
    book.clashPairTick = Max(tick, 1);
    let wasA = book.clashA;
    let wasB = book.clashB;
    CBClashPair(sys, game, book);
    if NotEquals(wasA, book.clashA) || NotEquals(wasB, book.clashB) {
      ArrayClear(book.candA);
      ArrayClear(book.candB);
    }
  }
  if Equals(book.clashA, n"") || tick < book.clashNextTick || player.IsInCombat()
     || ArraySize(book.candA) == 0 || ArraySize(book.candB) == 0 {
    return;
  }
  // Tried for at most once a gap, whether or not anybody was found: a street is not searched every tick.
  book.clashNextTick = tick + CBConfig.ClashRollTicks();
  if RandF() >= CBConfig.ClashChance() {
    return;
  }
  CBClashStart(sys, game, book, player, tick);
}

// A pair or two who are close enough to each other, and not too close to V or too far.
func CBClashStart(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, player: ref<PlayerPuppet>, tick: Int32) -> Void {
  let ppos = player.GetWorldPosition();
  let usedB: array<EntityID>;
  for ida in book.candA {
    if ArraySize(book.fightA) < CBConfig.ClashMaxPairs() {
      let a = GameInstance.FindEntityByID(game, ida) as ScriptedPuppet;
      if CBClashCandidate(sys, a, ppos) {
        let found = false;
        for idb in book.candB {
          if !found && !ArrayContains(usedB, idb) {
            let b = GameInstance.FindEntityByID(game, idb) as ScriptedPuppet;
            if CBClashCandidate(sys, b, ppos)
               && Vector4.Distance(a.GetWorldPosition(), b.GetWorldPosition()) <= CBConfig.ClashPairDistance() {
              let was = CBClashAttitudeOf(a, b);
              if was >= 0 && CBSetPairAttitude(sys, a, b, EAIAttitude.AIA_Hostile) {
                ArrayPush(book.fightA, ida);
                ArrayPush(book.fightB, idb);
                ArrayPush(book.fightWas, was);
                ArrayPush(usedB, idb);
                found = true;
              }
            }
          }
        }
      }
    }
  }
  ArrayClear(book.candA);
  ArrayClear(book.candB);
  if ArraySize(book.fightA) == 0 {
    return;
  }
  book.fightGangA = book.clashA;
  book.fightGangB = book.clashB;
  book.fightTick = Max(tick, 1);
  let first = GameInstance.FindEntityByID(game, book.fightA[0]) as ScriptedPuppet;
  book.fightAt = IsDefined(first) ? first.GetWorldPosition() : ppos;
  book.clashNextTick = tick + CBConfig.ClashGapTicks();
  CBLog.Info(n"Street", s"A street clash: \(ArraySize(book.fightA)) of \(NameToString(book.fightGangA)) against as many of \(NameToString(book.fightGangB)).");
}

func CBClashCandidate(sys: ref<CyberbaneSystem>, p: ref<ScriptedPuppet>, ppos: Vector4) -> Bool {
  if !CBNpcSafe(sys, p) || !CBStillStanding(p) || p.IsCrowd() || CBNpcInCombat(p) || p.cbTalkPartner
     || p.cbHostileByCyberbane || !CBSafetyGate.CanAffect(p) {
    return false;
  }
  let d = Vector4.Distance(p.GetWorldPosition(), ppos);
  return d >= CBConfig.ClashMinFromV() && d <= CBConfig.ClashMaxFromV();
}

// What a thinks of b now, as a number to put back later (0 friendly, 1 neutral, 2 hostile), or -1 if it cannot be read.
func CBClashAttitudeOf(a: ref<ScriptedPuppet>, b: ref<ScriptedPuppet>) -> Int32 {
  let aa = a.GetAttitudeAgent();
  let ba = b.GetAttitudeAgent();
  if !IsDefined(aa) || !IsDefined(ba) {
    return -1;
  }
  let att = aa.GetAttitudeTowards(ba);
  if Equals(att, EAIAttitude.AIA_Friendly) {
    return 0;
  }
  return Equals(att, EAIAttitude.AIA_Hostile) ? 2 : 1;
}

func CBClashAttitude(v: Int32) -> EAIAttitude {
  if v == 0 {
    return EAIAttitude.AIA_Friendly;
  }
  return v == 2 ? EAIAttitude.AIA_Hostile : EAIAttitude.AIA_Neutral;
}

// While it goes on: a side down, V gone, too long, or a moment the street must not fight in.
func CBClashWatch(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, player: ref<PlayerPuppet>,
                  busy: Bool, tick: Int32) -> Void {
  let n = Min(ArraySize(book.fightA), Min(ArraySize(book.fightB), ArraySize(book.fightWas)));
  let upA = 0;
  let upB = 0;
  let downA = 0;
  let downB = 0;
  let k = 0;
  while k < n {
    let a = GameInstance.FindEntityByID(game, book.fightA[k]) as ScriptedPuppet;
    let b = GameInstance.FindEntityByID(game, book.fightB[k]) as ScriptedPuppet;
    if CBStillStanding(a) {
      upA += 1;
    } else {
      if CBIsDown(a) {
        downA += 1;
      }
    }
    if CBStillStanding(b) {
      upB += 1;
    } else {
      if CBIsDown(b) {
        downB += 1;
      }
    }
    k += 1;
  }
  let far = Vector4.Distance(player.GetWorldPosition(), book.fightAt) > CBConfig.ClashLeaveDistance();
  let tooLong = tick - book.fightTick > CBConfig.ClashMaxTicks();
  if upA > 0 && upB == 0 && downB > 0 {
    CBClashEnd(sys, game, book, book.fightGangA, book.fightGangB);
    return;
  }
  if upB > 0 && upA == 0 && downA > 0 {
    CBClashEnd(sys, game, book, book.fightGangB, book.fightGangA);
    return;
  }
  if busy || far || tooLong || (upA == 0 && upB == 0) {
    CBClashEnd(sys, game, book, n"", n"");
  }
}

// Over: whoever is still standing is put back how they were towards the other, and the winner, if there was one,
// takes a little ground.
func CBClashEnd(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, winner: CName, loser: CName) -> Void {
  let n = Min(ArraySize(book.fightA), Min(ArraySize(book.fightB), ArraySize(book.fightWas)));
  let k = 0;
  while k < n {
    let a = GameInstance.FindEntityByID(game, book.fightA[k]) as ScriptedPuppet;
    let b = GameInstance.FindEntityByID(game, book.fightB[k]) as ScriptedPuppet;
    CBSetPairAttitude(sys, a, b, CBClashAttitude(book.fightWas[k]));
    k += 1;
  }
  ArrayClear(book.fightA);
  ArrayClear(book.fightB);
  ArrayClear(book.fightWas);
  book.lastClashA = book.fightGangA;
  book.lastClashB = book.fightGangB;
  book.lastClashAt = CBGameSeconds(game);
  book.fightTick = 0;
  if Equals(winner, n"") {
    CBLog.Info(n"Street", "A street clash broke up with nobody winning.");
    return;
  }
  CBBolsterGang(sys, game, winner, CBConfig.ClashGain());
  CBWeakenGang(sys, game, loser, CBConfig.ClashGain());
  CBFileLog(sys, n"StreetClash", CBGameSeconds(game), CBEventDistrict(sys, game), winner, 0.0);
  CBLog.Info(n"Street", s"A street clash: \(NameToString(winner)) won over \(NameToString(loser)).");
  CBEventSay(game, CBPick3(s"Did you see that? \(CBCapFirst(CBFactionLabel(winner))) and \(CBFactionLabel(loser)) went at it in the street. \(CBCapFirst(CBFactionLabel(winner))) walked away.",
                           s"\(CBCapFirst(CBFactionLabel(loser))) lost a couple on the corner just now. \(CBCapFirst(CBFactionLabel(winner))) are pushing.",
                           s"Gang trouble round here. \(CBCapFirst(CBFactionLabel(winner))) came out of it on top."));
}

// For the Hub's web of gangs: a clash between these two lately.
public func CBRecentClash(game: GameInstance, a: CName, b: CName) -> Bool {
  let book = CBWarBook.Get(game);
  if !IsDefined(book) || book.lastClashAt <= 0.0
     || CBGameSeconds(game) - book.lastClashAt > CBConfig.SecondsPerDay() {
    return false;
  }
  return (Equals(book.lastClashA, a) && Equals(book.lastClashB, b)) || (Equals(book.lastClashA, b) && Equals(book.lastClashB, a));
}

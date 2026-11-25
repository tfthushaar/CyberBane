// Cyberbane - Witnesses who tell the gang ([2])
//
// Killing a hostile gang's people where somebody sees it sends their next crew (CBProvoke, Spawn/Hunt.reds). Now, when
// the only people who saw it are ordinary people on the street, one of them has to carry the word to the gang, and that
// takes a few seconds V can use: talk them out of it (Reactions/StreetPay.reds), or put them down.

public func CBWitnessesCallOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHitSquadsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().witnessesCall);
}

@addField(ScriptedPuppet)
public let cbWitnessHushed: Bool;

// A witnessed kill of one of this gang's people. True when a witness has the word and the provocation waits
// on them (or nobody on the street cared to tell); false when it goes ahead now, as it always did.
public func CBWitnessCarries(sys: ref<CyberbaneSystem>, game: GameInstance, info: ref<CBKillInfo>) -> Bool {
  if !CBWitnessesCallOn() || !IsDefined(sys) || !IsDefined(info) || Equals(info.faction, n"")
     || !CBFactionFieldsSquads(info.faction) {
    return false;
  }
  // Only where it would send anybody: a gang at odds with V (the same test CBProvoke makes).
  let score = sys.GetScore();
  let posture = IsDefined(score) ? score.GetPosture(info.faction) : ECBPosture.Neutral;
  if !Equals(posture, ECBPosture.Hostile) && !Equals(posture, ECBPosture.Vendetta) {
    return false;
  }
  let book = CBStreetBook.Get(game);
  if !IsDefined(book) {
    return false;
  }
  // Somebody already on their way to this gang carries this one too.
  if EntityID.IsDefined(book.tellerId) {
    return Equals(book.tellerFaction, info.faction);
  }
  let reg = sys.GetRegistry();
  let player = GetPlayer(game);
  if !IsDefined(reg) || !IsDefined(player) {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  let radius = CBConfig.WitnessRadius() * CBSightMult(game);
  let npcs = reg.GetAll();
  let best: wref<ScriptedPuppet>;
  let bestD = radius;
  let scanned = 0;
  let i = 0;
  while i < ArraySize(npcs) && scanned < CBConfig.WitnessScanCap() {
    let npc = npcs[i];
    i += 1;
    // The gate before anything is read off them (crash rules).
    if CBNpcSafe(sys, npc) {
      let d = Vector4.Distance(info.position, npc.GetWorldPosition());
      if d <= radius && NotEquals(npc.GetEntityID(), info.victimEntityId) && CBStillStanding(npc)
         && !ScriptedPuppet.IsPlayerCompanion(npc) && CBWitnessCanSee(npc, player) {
        scanned += 1;
        let theirs = CBClassifyFaction(npc);
        if Equals(theirs, info.faction) {
          return false;   // their own people saw it: nobody needs telling
        }
        if Equals(theirs, n"") && !CBSentByUs(des, npc) && !CBNpcInCombat(npc) && d < bestD {
          best = npc;
          bestD = d;
        }
      }
    }
  }
  if !IsDefined(best) {
    return false;   // seen only by people of another gang, or by nobody who could be asked: as before
  }
  if RandF() >= CBConfig.WitnessTellChance() * CBTemperTells(info.district) {
    CBLog.Info(n"Model", s"Nobody on the street ran to \(NameToString(info.faction)) about that one.");
    return true;
  }
  book.tellerId = best.GetEntityID();
  book.tellerFaction = info.faction;
  book.tellerTick = sys.GetTickCount();
  book.tellerDistrict = info.district;
  best.cbWitnessHushed = false;
  CBLog.Info(n"Model", s"A witness is on their way to \(NameToString(info.faction)).");
  if CBToastsOn() {
    let gang = CBFactionLabel(info.faction);
    if StrLen(gang) == 0 {
      gang = CBT(n"Cyberbane-Witnesses-Them");
    }
    CBOverheard(game, CBT(n"Cyberbane-Witnesses-Witness"), CBPick4(
      CBTf(n"Cyberbane-Witnesses-OhThatWasOneOfThey", [gang]),
      CBTf(n"Cyberbane-Witnesses-ISawThatISawYour", [CBCapFirst(gang)]),
      CBTf(n"Cyberbane-Witnesses-SomebodySGotToTellMight", [gang]),
      CBTf(n"Cyberbane-Witnesses-NobodySawNothingRightWrongI", [gang])));
  }
  return true;
}

// Once a tick. The witness gets there, or does not.
public func CBWitnessTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBStreetBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !EntityID.IsDefined(book.tellerId) {
    return;
  }
  let faction = book.tellerFaction;
  // Switched off, or the story has the stage: the word goes nowhere.
  if !CBWitnessesCallOn() || sys.GetStoryHold() != CBStoryNone() {
    CBWitnessForget(book);
    return;
  }
  let age = sys.GetTickCount() - book.tellerTick;
  if age < 0 {
    CBWitnessForget(book);
    return;
  }
  let who = GameInstance.FindEntityByID(game, book.tellerId) as ScriptedPuppet;
  if IsDefined(who) && who.IsAttached() {
    if who.cbWitnessHushed {
      CBWitnessForget(book);
      CBLog.Info(n"Model", "The witness was talked out of it.");
      return;
    }
    if !CBStillStanding(who) {
      CBWitnessForget(book);
      CBLog.Info(n"Model", "The witness went down before telling anybody.");
      return;
    }
  }
  // Out of the world or still going: either way, once enough time has passed, they have told them.
  if age < CBConfig.WitnessTellTicks() {
    return;
  }
  CBWitnessForget(book);
  CBProvoke(sys, game, faction);
  CBLog.Info(n"Model", s"A witness told \(NameToString(faction)).");
  if CBToastsOn() {
    let gang = CBFactionLabel(faction);
    let where = CBDistrictLabel(book.tellerDistrict);
    if StrLen(gang) > 0 {
      CBHearsayFromStreet(game, StrLen(where) > 0
        ? CBTf(n"Cyberbane-Witnesses-SomebodyRanToTheyKnowYou", [gang, where])
        : CBTf(n"Cyberbane-Witnesses-SomebodyRanToTheyKnowIt", [gang]), n"");
    }
  }
}

func CBWitnessForget(book: ref<CBStreetBook>) -> Void {
  let none: EntityID;
  book.tellerId = none;
  book.tellerFaction = n"";
  book.tellerTick = 0;
}

// Is this the witness on their way to a gang right now? For talk (Reactions/StreetPay.reds).
public func CBIsTeller(game: GameInstance, npc: wref<ScriptedPuppet>) -> Bool {
  let book = CBStreetBook.Get(game);
  return IsDefined(book) && IsDefined(npc) && EntityID.IsDefined(book.tellerId)
      && Equals(npc.GetEntityID(), book.tellerId);
}

// For the HUD line: "" when nobody is, otherwise who they are running to and how long they have left.
public func CBWitnessHudLine(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let book = CBStreetBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) || !EntityID.IsDefined(book.tellerId) {
    return "";
  }
  let left = CBConfig.WitnessTellTicks() - (sys.GetTickCount() - book.tellerTick);
  if left <= 0 {
    return "";
  }
  let who = CBClip(CBBarFactionLabel(book.tellerFaction), CBConfig.HudNameMaxChars());
  return CBTf(n"Cyberbane-Witnesses-AWITNESSISRUNNINGTO", [(StrLen(who) > 0 ? who : CBT(n"Cyberbane-Witnesses-THEM")), StrUpper(CBTimeText(left))]);
}

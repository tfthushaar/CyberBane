// Cyberbane - The street's stories
//
// Bagmen, debt trips, ransom drops and sit-downs, each with a reason, a place somewhere else, a person who can say no
// and a consequence that fits.

// A place of this gang's own: one the street remembers where they did business or that lies in a district they hold,
// between `minD` and `maxD` from V, the newest first; else a spot well away from V. Never at a job or in a safe area.
public func CBGangDropPlace(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, gang: CName,
                            minD: Float, maxD: Float, out at: Vector4, out district: CName) -> Bool {
  if !IsDefined(sys) || !IsDefined(player) {
    return false;
  }
  let book = CBStreetBook.Get(game);
  let ppos = player.GetWorldPosition();
  let content = sys.GetContent();
  let prof = IsDefined(content) ? content.GetFaction(gang) : null;
  let found = false;
  let best = -1.0;
  if IsDefined(book) {
    let i = 0;
    while i < book.PlaceCount() {
      let p = book.PlacePos(i);
      let d = book.PlaceDistrict(i);
      let theirs = Equals(book.PlaceGang(i), gang);
      if !theirs && IsDefined(prof) {
        theirs = ArrayContains(prof.turf, d);
      }
      if !theirs && NotEquals(d, n"") {
        theirs = Equals(CBTurfHolder(sys, game, d), gang);
      }
      let dist = Vector4.Distance(p, ppos);
      if theirs && dist >= minD && dist <= maxD && book.PlaceAt(i) > best && CBLairPointUsable(sys, game, p) {
        best = book.PlaceAt(i);
        at = p;
        district = d;
        found = true;
      }
      i += 1;
    }
  }
  if found {
    return true;
  }
  let spot: Vector4;
  if CBWhereaboutsSpot(sys, game, player, spot) {
    at = spot;
    district = sys.GetCurrentDistrict();
    return true;
  }
  return false;
}

// A place V was sent to and cannot walk into (2.7.10): a place the street remembers can be inside a building the game has
// locked since (a gig's, once the gig is done), and the debtor, the ransom or the calling card waited there for a V who
// could never reach it. Asked once V is within DropWayInCheck of it, where a walk can be trusted (Rivals/Strongholds.reds
// tests the same way). True, with `moved`, when there is no way in from where V stands and a spot just outside is open
// ground V can walk to; false when the place is fine, V is still far, off the walkable ground, or nowhere better is found.
public func CBDropWayIn(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, at: Vector4,
                        out moved: Vector4) -> Bool {
  if !IsDefined(sys) || !IsDefined(player) || (at.X == 0.0 && at.Y == 0.0) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  if Vector4.Distance(ppos, at) > CBConfig.DropWayInCheck() || IsDefined(player.GetMountedVehicle()) {
    return false;
  }
  let vGround: Vector4;
  if !CBNavPointUnder(game, ppos, vGround) {
    return false;
  }
  let target = at;
  let onMesh: Vector4;
  if CBNavPointUnder(game, at, onMesh) {
    target = onMesh;
  }
  if CBPointReachable(game, vGround, target) {
    return false;
  }
  // Rings round the place, nearest first: the first spot of open ground V can walk to, usable as any Rival's place is.
  let ring = 1;
  while ring <= 4 {
    let radius = 6.0 + Cast<Float>(ring - 1) * 8.0;
    let k = 0;
    while k < 8 {
      let ang = Cast<Float>(k) * 0.7854;
      k += 1;
      let snapped: Vector4;
      let spot: Vector4;
      if CBNavSnap(game, at.X + CosF(ang) * radius, at.Y + SinF(ang) * radius, at.Z, snapped)
         && CBSettleOnGround(game, snapped, spot) && !CBPointCovered(game, spot)
         && CBLairPointUsable(sys, game, spot) && CBPointReachable(game, vGround, spot) {
        moved = spot;
        return true;
      }
    }
    ring += 1;
  }
  return false;
}

// A pin on a place, as the favour's and the sit-down's.
public func CBPinPlace(game: GameInstance, at: Vector4, text: String, out id: NewMappinID) -> Bool {
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(ms) || !CBMapMarkersOn() || (at.X == 0.0 && at.Y == 0.0) {
    return false;
  }
  id = ms.RegisterMappin(CBPlacePinData(CBEventPinCaption(text)), at);
  CBUiSound(game, n"ui_menu_map_pin_created", n"PinMade", 4.0);
  return true;
}

public func CBUnpinPlace(game: GameInstance, id: NewMappinID) -> Void {
  let ms = GameInstance.GetMappinSystem(game);
  if IsDefined(ms) {
    ms.UnregisterMappin(id);
  }
}

// One walk order to a spot, stopping `near` metres short: the wannabes' walk, with its distance.
public func CBStreetWalkNear(p: ref<ScriptedPuppet>, to: Vector4, near: Float) -> Void {
  if !IsDefined(p) {
    return;
  }
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
  cmd.desiredDistanceFromTarget = near;
  CBIssueMove(p, ai, cmd);
}

// Somebody put round `center` where V cannot see them, minding their own business: the debtor's and the lair's hidden
// placement, for a witness. True when they were queued.
public func CBPlaceHiddenNear(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, player: ref<PlayerPuppet>,
                              center: Vector4, record: TweakDBID, tag: CName, out body: EntityID) -> Bool {
  let ppos = player.GetWorldPosition();
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
      return CBCreateSpawn(des, record, n"", spot, facing, tag, body);
    }
  }
  return false;
}

// ---- The witness ---------------------------------------------------------------------------------------------------

// Their own numbers.
public func CBTalkActLeadWitnessAsk() -> Int32 = 68
public func CBTalkActLeadWitnessPay() -> Int32 = 69

// Which Rival this person saw, 0 for nobody; and whether V leaned on them.
@addField(ScriptedPuppet)
public let cbLeadWitnessFor: Int32;
@addField(ScriptedPuppet)
public let cbLeadWitnessScared: Bool;

// What a witness costs to forget V: a little, by the street's prices.
public func CBLeadWitnessPrice(game: GameInstance) -> Int32 {
  return Max(100, RoundF(CBConfig.WitnessPayBase() * CBLootLevelScale(game) / 100.0) * 10);
}

// Every few ticks from the whereabouts tick: the lead's witness put on the way there, watched, and their warning carried.
public func CBLeadWitnessTick(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
  let book = CBRivalBook.Get(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(des) || !IsDefined(player) {
    return;
  }
  let lead = CBCurrentLead(sys, game);
  let rid = IsDefined(lead) ? lead.rivalId : 0;
  // A new lead, or none: whoever saw the last one is let go.
  if rid != book.witnessFor {
    let none: EntityID;
    book.witnessFor = rid;
    book.witnessId = none;
    book.witnessPlaced = false;
    book.witnessWarned = false;
    book.witnessDone = false;
    book.lairQuiet = false;
    CBDeleteTaggedSafe(game, n"CB_Witness", true, true);
  }
  if rid == 0 || !CBHideoutsOn() {
    return;
  }
  let r = sys.FindRivalById(rid);
  if !IsDefined(r) {
    return;
  }
  let tick = sys.GetTickCount();
  let center = new Vector4(lead.x, lead.y, lead.z, 1.0);
  let ppos = player.GetWorldPosition();
  let d = Vector4.Distance(ppos, center);
  // On the way there: between V and the place, before V is close enough for the Rival to be put there.
  if !book.witnessPlaced && !sys.IsLairActive() && d <= CBConfig.WitnessRange() && d > CBConfig.LairPlaceDistance() + 15.0
     && tick % 3 == 0 && !player.IsInCombat() && !IsDefined(player.GetMountedVehicle()) && CBWorldStable(game)
     && !CBStoryHoldNow(game) && CBSpawnRoom(game) > 0 {
    let dir = Vector4.Normalize2D(new Vector4(ppos.X - center.X, ppos.Y - center.Y, 0.0, 0.0));
    let mid = new Vector4(center.X + dir.X * (CBConfig.LairPlaceDistance() + 25.0), center.Y + dir.Y * (CBConfig.LairPlaceDistance() + 25.0),
                          center.Z, 1.0);
    // One of the gang that passed the word on, or somebody of the street who fights with fists.
    let record = IsNameValid(lead.tipFaction) ? CBGangTemplate(sys, lead.tipFaction) : TDBID.None();
    if !TDBID.IsValid(record) || !CBRecordIsPerson(record) {
      record = CBDebtorRecord(sys, sys.GetCurrentDistrict(), r.faction);
    }
    let body: EntityID;
    if TDBID.IsValid(record) && CBPlaceHiddenNear(sys, game, des, player, mid, record, n"CB_Witness", body) {
      book.witnessId = body;
      book.witnessPlaced = true;
      CBLog.Info(n"Rivals", s"Somebody who saw Rival \(rid) is on the way there.");
    }
  }
  let w = GameInstance.FindEntityByID(game, book.witnessId) as ScriptedPuppet;
  if IsDefined(w) && CBNpcSafe(sys, w) && w.cbLeadWitnessFor == 0 {
    w.cbLeadWitnessFor = rid;
    CBTrackOnMap(game, w);
  }
  // Leaned on or hurt before they talked: they run ahead to warn.
  if IsDefined(w) && !book.witnessWarned && !book.lairQuiet && CBStillStanding(w) && (w.cbDamagedByPlayer || w.cbLeadWitnessScared) {
    book.witnessWarned = true;
    book.witnessWarnTick = Max(tick, 1);
    CBTalkReleaseHold(w);
    CBOrderFlee(game, w);
    if CBMessagesOn() {
      CBIntelSay(game, 3, CBT(n"Cyberbane-Witnesses-Witness"), CBLineOf([CBTf(n"Cyberbane-StreetStories-IMTellingYouReComing", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]),
                                               CBT(n"Cyberbane-StreetStories-YouLlNeverFindThemNow")]), 3.0);
    }
  }
  if book.witnessWarned && !book.witnessDone {
    if IsDefined(w) && CBIsDown(w) {
      book.witnessDone = true;
      CBLog.Info(n"Rivals", "The witness was stopped before they could warn anybody.");
    } else {
      if tick - book.witnessWarnTick >= CBConfig.LairWarnTicks() * 2 && !sys.IsLairActive() {
        book.witnessDone = true;
        CBLeadWitnessMoveLead(sys, game, lead, r);
      }
    }
  }
}

// The warning got through before V got there: the Rival is somewhere else, and the lead says so.
func CBLeadWitnessMoveLead(sys: ref<CyberbaneSystem>, game: GameInstance, lead: ref<CBSighting>, r: ref<CBRival>) -> Void {
  let svc = sys.GetPlayService();
  let to: Vector4;
  if !IsDefined(svc) || !CBLairSecondPlace(sys, game, new Vector4(lead.x, lead.y, lead.z, 1.0), to) {
    return;
  }
  let now = CBGameSeconds(game);
  let tipster = lead.tipFaction;
  svc.NoteSighting(sys.GetPlaythroughId(), r.id, r.recordID, to, lead.district, now);
  let s = svc.FindSighting(sys.GetPlaythroughId(), r.id);
  if IsDefined(s) {
    CBMarkLeadTold(sys, s, tipster, now);
  }
  CBDropLead(sys, game);   // the pin goes up again where they went
  if CBMessagesOn() {
    CBPhoneFromStreet(game, CBTf(n"Cyberbane-StreetStories-WhoeverYouLeanedOnRanAhead", [s"\(CBRivalDisplayName(sys.GetContent(), r))"]));
  }
  CBLog.Info(n"Rivals", s"A witness warned Rival \(r.id); the lead moved.");
}

public func CBLeadWitnessTalkLines(game: GameInstance, t: ref<CBTalkTarget>, out lines: array<ref<CBTalkLine>>) -> Bool {
  if !IsDefined(t) || !IsDefined(t.npc) || t.npc.cbLeadWitnessFor <= 0 {
    return false;
  }
  let sys = CyberbaneSystem.Get(game);
  let r = IsDefined(sys) ? sys.FindRivalById(t.npc.cbLeadWitnessFor) : null;
  if !IsDefined(r) {
    return false;
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let ask = CBTalkMakeLine(CBTf(n"Cyberbane-StreetStories-AskYouSawWhere", [s"\(name)"]), CBTalkActLeadWitnessAsk(), t"ChoiceCaptionParts.GangWatchIcon");
  ask.important = true;
  ArrayPush(lines, ask);
  let price = CBLeadWitnessPrice(game);
  let pay = CBTalkMakeLine(CBTf(n"Cyberbane-StreetStories-PayEbYouNeverSawMe", [s"\(price)"]), CBTalkActLeadWitnessPay(), t"ChoiceCaptionParts.PayIcon");
  pay.inactive = CBPlayerMoney(game) < price;
  ArrayPush(lines, pay);
  return true;
}

public func CBLeadWitnessAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>,
                            choice: Int32) -> ref<CBTalkAnswer> {
  let book = CBRivalBook.Get(game);
  if !IsDefined(book) || !IsDefined(t) || !IsDefined(t.npc) {
    return CBTalkSay("...", n"");
  }
  let lead = CBCurrentLead(sys, game);
  if choice == CBTalkActLeadWitnessPay() {
    let price = CBLeadWitnessPrice(game);
    let ts = GameInstance.GetTransactionSystem(game);
    if !IsDefined(ts) || CBPlayerMoney(game) < price {
      return CBTalkSay(CBT(n"Cyberbane-StreetStories-ThenIRememberEverything"), n"");
    }
    ts.RemoveItem(player, ItemID.FromTDBID(t"Items.money"), price);
    book.lairQuiet = true;
    t.npc.cbLeadWitnessFor = 0;
    CBTalkMarkSent(game, t.npc);
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetStories-NeverSawYouNeverSawThem"), CBT(n"Cyberbane-StreetStories-WhatFaceIMBadWith")), n"");
  }
  // Asked: the way in nobody watches, and the lead holds a while longer.
  book.lairQuiet = true;
  if IsDefined(lead) {
    CBMarkLeadTold(sys, lead, lead.tipFaction, CBGameSeconds(game));
  }
  return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetStories-RoundTheBackPastTheBins"),
                           CBT(n"Cyberbane-StreetStories-TheyReThereAllRightCome")), n"");
}

// V's money, for a price shown greyed when it is more than V has.
public func CBPlayerMoney(game: GameInstance) -> Int32 {
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  return IsDefined(player) && IsDefined(ts) ? ts.GetItemQuantity(player, ItemID.FromTDBID(t"Items.money")) : 0;
}

// ---- The ransom's drop ---------------------------------------------------------------------------------------------

// Every tick from the allies tick (Reactions/Allies.reds): V at the drop, or the drop gone cold.
public func CBRansomDropTick(sys: ref<CyberbaneSystem>, game: GameInstance, war: ref<CBWarBook>, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(war) || !IsNameValid(war.dropGang) || !IsDefined(player) {
    return;
  }
  let now = CBGameSeconds(game);
  let gang = war.dropGang;
  if now > war.dropUntil {
    if CBMessagesOn() {
      CBPhoneFromGang(game, gang, CBT(n"Cyberbane-StreetStories-NobodyCameForItTheMoney"));
    }
    CBRansomDropEnd(game, war);
    return;
  }
  // No way in to the drop any more (2.7.10, CBDropWayIn): the bag is left just outside, and the pin moves with it.
  let outside: Vector4;
  if CBDropWayIn(sys, game, player, war.dropAt, outside) {
    war.dropAt = outside;
    if war.dropPinned {
      CBUnpinPlace(game, war.dropPin);
    }
    war.dropPinned = CBPinPlace(game, outside, CBTf(n"Cyberbane-Allies-DropTheRansom", [s"\(CBCapFirst(CBPossessive(CBFactionLabel(gang))))"]), war.dropPin);
    CBSystemNote(game, CBT(n"Cyberbane-StreetStories-DropMovedOutside"), 5.0);
    CBLog.Info(n"Street", "The ransom drop had no way in; moved just outside.");
  }
  if Vector4.Distance(player.GetWorldPosition(), war.dropAt) > CBConfig.RansomDropReach() || player.IsInCombat() {
    return;
  }
  if war.dropBetray {
    CBProvoke(sys, game, gang);
    CBFileLog(sys, n"RansomBetrayed", now, CBEventDistrict(sys, game), gang, 0.0);
    if CBMessagesOn() {
      CBPhoneFromGang(game, gang, CBPick2(CBT(n"Cyberbane-StreetStories-ThereWasNeverAnyMoneyLook"), CBT(n"Cyberbane-StreetStories-YouReallyCameWeReComing")));
    }
  } else {
    CBStreetGiveMoney(game, war.dropAmount);
    CBFileLog(sys, n"RansomPaid", now, CBEventDistrict(sys, game), gang, Cast<Float>(war.dropAmount));
    CBSystemNote(game, CBTf(n"Cyberbane-StreetStories-TheBagWasWhereTheySaid", [s"\(war.dropAmount)"]), 5.0);
  }
  CBRansomDropEnd(game, war);
}

public func CBRansomDropEnd(game: GameInstance, war: ref<CBWarBook>) -> Void {
  if war.dropPinned {
    CBUnpinPlace(game, war.dropPin);
  }
  war.dropPinned = false;
  war.dropGang = n"";
  war.dropAmount = 0;
  war.dropBetray = false;
}

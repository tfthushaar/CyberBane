// Cyberbane - The hunt grows (2.4.2)
//
//   [49] tracked        a quickhack on V from one of Cyberbane's people plants a tracker: for half a game day, or until
//                       V has spent a minute somewhere safe (a ripperdoc's chair, home, a clinic), that gang knows
//                       where V is: no scout, a hunt that starts on V, always a reason to send. The HUD says so.
//   [48] open season    the top of a gang's anger: sworn against V, many of theirs dead, a leader to declare it. For a
//                       game day every one of theirs knows V's face and a crew comes every game hour. Survive it, kill
//                       their leader, or pay a crippling price; surviving leaves them afraid.
//   [E2] lying in wait  on by default now: a crew parks up the road from a driving V; the Wraiths do it on Badlands
//                       roads whatever their grudge; more often where V is known to go; and a watcher V paid warns V.
//   [47] V's road       on foot with a job tracked far away, a vendetta crew may wait near it instead, outside the
//                       job's own ground, and spring when V arrives (the event engine, kind Ambush).
//   [11] the assassin   at night, the Tyger Claws sometimes send one killer with a blade instead of a crew.
//
// The tracker is kept in the hunt book (CBHuntBook) and open season in the war book (CBWarBook), both laid out for it.

public func CBTrackersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHitSquadsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().trackers);
}

public func CBOpenSeasonOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHitSquadsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().openSeason);
}

public func CBLieInWaitOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().gangsLieInWait;
}

// ---- [49] Tracked -------------------------------------------------------------------------------------

// A quickhack from one of ours, noted on V in the hit event and taken up a tick later (CBHuntGrowsTick).
@addField(ScriptedPuppet)
public let cbHackedBy: CName;
@addField(ScriptedPuppet)
public let cbHackedFrom: EntityID;

public func CBTrackerGang(game: GameInstance) -> CName {
  let book = CBHuntBook.Get(game);
  return CBTrackersOn() && IsDefined(book) && CBGameSeconds(game) < book.TrackedUntil() ? book.TrackedBy() : n"";
}

// ---- [48] Open season ----------------------------------------------------------------------------------

public func CBOpenSeasonGang(game: GameInstance) -> CName {
  let book = CBWarBook.Get(game);
  return CBOpenSeasonOn() && IsDefined(book) && CBGameSeconds(game) < book.OpenUntil() ? book.OpenGang() : n"";
}

public func CBOpenSeasonFor(game: GameInstance, gang: CName) -> Bool {
  return NotEquals(gang, n"") && Equals(CBOpenSeasonGang(game), gang);
}

func CBOpenSeasonEnd(sys: ref<CyberbaneSystem>, game: GameInstance, book: ref<CBWarBook>, how: CName) -> Void {
  let gang = book.OpenGang();
  book.SetOpen(n"", 0.0);
  if Equals(gang, n"") {
    return;
  }
  let now = CBGameSeconds(game);
  if Equals(how, n"survived") {
    CBTalkFear(sys, game, gang, CBConfig.OpenSeasonFear());
    let mult = 1.0;
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      mult = rt.GetSettings().renownGainMult;
    }
    sys.AddRenownPoints(CBConfig.OpenSeasonRenown() * mult);
    CBFileLog(sys, n"OpenSeasonSurvived", now, CBEventDistrict(sys, game), gang, 0.0);
    CBEventSay(game, s"You survived \(CBPossessive(CBFactionLabel(gang))) open season. A whole day of their best, and you're still standing. They're scared now.");
    return;
  }
  if Equals(how, n"leader") {
    CBTalkFear(sys, game, gang, CBConfig.OpenSeasonFear());
    CBFileLog(sys, n"OpenSeasonEnded", now, CBEventDistrict(sys, game), gang, 0.0);
    CBEventSay(game, s"You killed the one who called it. \(CBCapFirst(CBFactionLabel(gang)))' open season is over.");
    return;
  }
  CBLog.Info(n"Spawn", s"Open season on V by \(NameToString(gang)) is over (\(NameToString(how))).");
}

// The price of ending it with money: crippling.
public func CBOpenSeasonPriceMult(game: GameInstance, gang: CName) -> Float {
  return CBOpenSeasonFor(game, gang) ? CBConfig.OpenSeasonPriceMult() : 1.0;
}

// ---- Every tick ----------------------------------------------------------------------------------------

public func CBHuntGrowsTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let hunt = CBHuntBook.Get(game);
  let war = CBWarBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(hunt) || !IsDefined(war) || !IsDefined(player) {
    return;
  }
  let now = CBGameSeconds(game);
  // Whoever quickhacked V: one of Cyberbane's people plants a tracker for their gang.
  if EntityID.IsDefined(player.cbHackedFrom) {
    let from = GameInstance.FindEntityByID(game, player.cbHackedFrom) as ScriptedPuppet;
    let none: EntityID;
    player.cbHackedFrom = none;
    let des = GameInstance.GetDynamicEntitySystem();
    if CBNpcSafe(sys, from) && IsDefined(des) && des.IsTagged(from.GetEntityID(), n"Cyberbane") {
      player.cbHackedBy = CBClassifyFaction(from);
    }
  }
  // A tracker planted: kept fresh by each new hack, said the first time.
  let hacker = player.cbHackedBy;
  if NotEquals(hacker, n"") {
    player.cbHackedBy = n"";
    if CBTrackersOn() && CBFactionFieldsSquads(hacker) {
      let fresh = NotEquals(hunt.TrackedBy(), hacker) || now >= hunt.TrackedUntil();
      hunt.SetTracked(hacker, now + CBConfig.TrackedHours() * CBConfig.SecondsPerHour());
      if fresh {
        CBFileLog(sys, n"Tracked", now, CBEventDistrict(sys, game), hacker, 0.0);
        if CBToastsOn() {
          CBSystemNote(game, s"something just pinged in your cyberdeck: \(CBFactionLabel(hacker)) planted a tracker. Spend a minute somewhere safe to dig it out.", 7.0);
        }
      }
    }
  }
  // Dug out: a minute somewhere safe (home, a clinic, a ripperdoc's chair), counted in real seconds.
  if NotEquals(hunt.TrackedBy(), n"") {
    if now >= hunt.TrackedUntil() {
      hunt.SetTracked(n"", 0.0);
    } else {
      if sys.IsInSafeZone() {
        hunt.safeTicks += 1;
        if hunt.safeTicks >= CBConfig.TrackedClearTicks() {
          hunt.SetTracked(n"", 0.0);
          if CBToastsOn() {
            CBSystemNote(game, "the tracker's gone. Nobody knows where you are.", 5.0);
          }
        }
      } else {
        hunt.safeTicks = 0;
      }
    }
  }
  // Open season: a crew every game hour, and its endings.
  let open = war.OpenGang();
  if NotEquals(open, n"") {
    let score = sys.GetScore();
    if !CBOpenSeasonOn() || !IsDefined(score) || !Equals(score.GetPosture(open), ECBPosture.Vendetta) {
      CBOpenSeasonEnd(sys, game, war, n"called off");   // paid, or no longer sworn
    } else {
      if now >= war.OpenUntil() {
        CBOpenSeasonEnd(sys, game, war, n"survived");
      } else {
        if sys.GetTickCount() % CBConfig.OpenSeasonCrewTicks() == 0 {
          CBProvoke(sys, game, open);
        }
      }
    }
  }
}

// From the slow tick: a gang at the top of its anger may declare it.
public func CBOpenSeasonRoll(sys: ref<CyberbaneSystem>, game: GameInstance, days: Float) -> Void {
  let war = CBWarBook.Get(game);
  let score = sys.GetScore();
  if !CBOpenSeasonOn() || !IsDefined(war) || !IsDefined(score) || NotEquals(war.OpenGang(), n"")
     || RandF() >= CBConfig.OpenSeasonChancePerDay() * days {
    return;
  }
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) && CBFactionFieldsSquads(fs.id) && !CBIsCorpFaction(fs.id) && fs.kills >= CBConfig.OpenSeasonKills()
       && Equals(score.GetPosture(fs.id), ECBPosture.Vendetta) && !CBGangBroken(sys, fs.id) && fs.leaderRivalId > 0 {
      let leader = sys.FindRivalById(fs.leaderRivalId);
      if IsDefined(leader) && CBRivalStillAround(leader) {
        let now = CBGameSeconds(game);
        war.SetOpen(fs.id, now + CBConfig.SecondsPerDay());
        CBFileLog(sys, n"OpenSeason", now, CBEventDistrict(sys, game), fs.id, 0.0);
        if CBMessagesOn() {
          CBPhoneSendTinted(game, CBRivalDisplayName(CBContent(game), leader),
            s"Open season. Every one of \(CBFactionLabel(fs.id)) knows your face, and we're coming every hour until the sun comes up tomorrow. Run.", CBHudRed());
        }
        return;
      }
    }
  }
}

// From the hierarchy: the one who declared it is dead.
public func CBOpenSeasonLeaderDown(sys: ref<CyberbaneSystem>, game: GameInstance, slain: ref<CBRival>, wasLeader: Bool) -> Void {
  let war = CBWarBook.Get(game);
  if wasLeader && IsDefined(war) && IsDefined(slain) && Equals(war.OpenGang(), slain.faction) && sys.RivalDeathByV() {
    CBOpenSeasonEnd(sys, game, war, n"leader");
  }
}

// ---- [E2] Lying in wait, and [47] V's road ----------------------------------------------------------------

// How much likelier a crew is to lie in wait here: the Wraiths on their road, and wherever V is known to go.
public func CBLieInWaitMult(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Float {
  let m = 1.0;
  if CBGangCodesOn() && Equals(gang, n"Wraiths") && Equals(sys.GetCurrentDistrict(), n"Badlands") {
    m *= CBConfig.WraithRoadMult();
  }
  if CBHauntTipMult(sys, game) < 1.0 {
    m *= CBConfig.HauntWaitMult();
  }
  return m;
}

// A crew waiting up the road: a watcher V paid saw them park.
public func CBWarnOfWaiting(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Void {
  if !CBToastsOn() || !CBWatchedHere(sys, game) {
    return;
  }
  let book = CBStreetBook.Get(game);
  let name = IsDefined(book) && StrLen(book.WatchName()) > 0 ? book.WatchName() : "Lookout";
  CBPhoneSend(game, name, s"Car full of \(CBFactionLabel(gang)) just parked up the road, engine running. They're waiting for you.");
}

// V on foot, a job tracked far away, a gang sworn against V: they may wait for V there. True when they will.
public func CBTryWaitOnRoad(sys: ref<CyberbaneSystem>, game: GameInstance, fs: ref<CBFactionState>, size: Int32) -> Bool {
  let player = GetPlayer(game);
  let life = CBStreetLifeFor(game);
  let score = sys.GetScore();
  if !CBLieInWaitOn() || !IsDefined(player) || !IsDefined(life) || !IsDefined(score) || IsDefined(life.Events().Live())
     || IsDefined(player.GetMountedVehicle()) || !Equals(score.GetPosture(fs.id), ECBPosture.Vendetta)
     || RandF() >= CBConfig.RoadChance() {
    return false;
  }
  let ppos = player.GetWorldPosition();
  for pin in sys.GetTrackedPins() {
    if Vector4.Distance(pin, ppos) >= CBConfig.RoadMinDistance() {
      // Outside the job's own ground, on the near side of it.
      let dx = ppos.X - pin.X;
      let dy = ppos.Y - pin.Y;
      let d = MaxF(SqrtF(dx * dx + dy * dy), 1.0);
      let off = CBConfig.QuestSpawnClearance() + CBConfig.RoadOffset();
      let at: Vector4;
      if CBHuntStandAt(game, pin.X + dx / d * off, pin.Y + dy / d * off, pin.Z, at) && !sys.NearQuestPins(at, CBConfig.QuestSpawnClearance()) {
        return life.Events().StartAmbush(sys, game, fs.id, at, Clamp(size, 2, CBConfig.RoadMaxCrew()));
      }
    }
  }
  return false;
}

// ---- [11] The Claws' assassin -----------------------------------------------------------------------------

// Tonight the Claws send one killer, not a crew. The same answer all night, so the warning and the arrival agree.
public func CBClawsAssassin(game: GameInstance, gang: CName) -> Bool {
  return CBGangCodesOn() && Equals(gang, n"TygerClaws") && CBIsNight(game)
      && (CBGameDay(game) * 37 + 11) % 100 < RoundF(CBConfig.AssassinChance() * 100.0);
}

public func CBAssassinRecord() -> TweakDBID {
  let id = t"Character.tyger_claws_kunoichi_fmelee3_katana_wa_elite";
  if IsDefined(TweakDBInterface.GetCharacterRecord(id)) && CBRecordIsPerson(id) && !CBRecordUnfitTemplate(id) {
    return id;
  }
  return CBApexRosterRecord(n"TygerClaws", 2);   // their blade chair
}

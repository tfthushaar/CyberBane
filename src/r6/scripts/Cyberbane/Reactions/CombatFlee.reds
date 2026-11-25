// Cyberbane - Combat flee and escape -> Rival (spec §10.2)
//
// A wounded enemy can lose its nerve and run. If it gets away it becomes a Survivor Rival that will come for you later;
// if it was already the Rival hunting you, it climbs a rank and returns harder (and gains the Scarred trait).

@addField(ScriptedPuppet)
public let cbLowHealthFled: Bool;

@addField(ScriptedPuppet)
public let cbSparedLogged: Bool;

// The mercy for this one has been settled and scored (CBSettleMercy). Only then is there
// anything to take back if V comes back later and kills them.
@addField(ScriptedPuppet)
public let cbMercyScored: Bool;

// What that settled mercy was scored from, so taking it back undoes the same things.
@addField(ScriptedPuppet)
public let cbMercyInfo: ref<CBKillInfo>;

@addField(ScriptedPuppet)
public let cbMercyPsycho: Bool;

// Called from OnHit when V has just damaged this puppet. If that blow put them down without killing them - a knockout,
// a non-lethal takedown, a defeat - log it.
public func CBSparedCheck(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) || puppet.cbSparedLogged {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  // The Rivals setting used to bail out right here, which quietly took Conduct with it.
  let rivalsOn = true;
  if IsDefined(rt) && rt.HasSettings() {
    rivalsOn = rt.GetSettings().rivals;
  }
  if sys.IsInSafeZone() {
    return;   // not in a safe area (spec §16)
  }
  // Down, but still breathing - that is what makes it mercy rather than a kill.
  if !ScriptedPuppet.IsDefeated(puppet) && !puppet.IsIncapacitated() {
    return;
  }
  // CanAffect rules out dead, quest, companion, vendor and in-scene puppets.
  if !CBSafetyGate.CanAffect(puppet) {
    return;
  }
  let faction = CBClassifyFaction(puppet);
  if Equals(faction, n"") || Equals(faction, n"MaxTac") {
    return;   // unaffiliated nobodies and MaxTac are neither scored nor remembered
  }

  puppet.cbSparedLogged = true;
  // Classified now, scored later.
  let mercy: ref<CBKillInfo>;
  if puppet.cbDamagedByPlayer {
    mercy = CBBuildKillInfo(sys, game, puppet, false);
    // The fight you are in does count it now: somebody down is out of the fight either way, and a non-lethal
    // playthrough has to be able to end an encounter.
    CBEncounterRecordKill(sys, mercy);
  }
  if !rivalsOn && !IsDefined(mercy) {
    return;   // nothing to score and no Rival to make of it
  }
  let e = new CBEscapee();
  e.puppet = puppet;
  e.entityId = puppet.GetEntityID();
  e.faction = faction;
  e.record = puppet.GetRecordID();
  e.at = CBGameSeconds(game);
  e.tick = sys.GetTickCount();
  e.spared = true;
  e.scarMask = puppet.cbScarMask;   // what V did on the way down, before the puppet is gone
  e.mercy = mercy;
  e.psycho = CBIsCyberpsycho(puppet);
  // One of the Rivals, sent after V or waiting at their place. Their mercy keeps the timing it
  // has always had, because settling it is also what closes their encounter (CBHandleSpared).
  let desS = GameInstance.GetDynamicEntitySystem();
  e.wasRival = IsDefined(desS)
               && (desS.IsTagged(e.entityId, n"CB_Rival") || desS.IsTagged(e.entityId, n"CB_Lair"));
  sys.AddEscapee(e);
}

// V left them breathing: score the takedown that put them down.
public func CBSettleMercy(sys: ref<CyberbaneSystem>, e: ref<CBEscapee>, alive: Bool) -> Void {
  if !IsDefined(sys) || !IsDefined(e) || !IsDefined(e.mercy) || !alive {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  let info = e.mercy;
  e.mercy = null;   // once, however this was reached
  CBApplyKill(sys, info);
  // Talking one down rather than putting them in the ground is its own kind of reputation.
  if e.psycho {
    let st = sys.GetStats();
    if IsDefined(st) {
      st.psychosPacified += 1;
    }
  }
  if IsDefined(e.puppet) {
    e.puppet.cbMercyScored = true;
    e.puppet.cbMercyInfo = info;
    e.puppet.cbMercyPsycho = e.psycho;
  }
}

// Called from OnHit when V has just damaged this puppet. How steady this one is under fire: the chance it holds its
// ground rather than breaking.
public func CBNerve(puppet: ref<ScriptedPuppet>) -> Float {
  let base = 1.0 - CBConfig.FleeChance();   // rank and file
  let rec = puppet.GetRecord();
  if IsDefined(rec) {
    let rarity = rec.Rarity();
    if IsDefined(rarity) {
      let t = rarity.Type();
      if Equals(t, gamedataNPCRarity.Boss) {
        return 1.0;    // never runs, whoever they are with
      }
      if Equals(t, gamedataNPCRarity.Elite) {
        base = 0.75;
      }
      if Equals(t, gamedataNPCRarity.Officer) {
        base = 0.60;
      }
    }
  }
  // Crews differ. courageMod has been sitting in the faction table since the beginning
  // without anything ever reading it; this is where it belongs - the Animals hold, the
  // Scavs do not.
  let content = CBContent(puppet.GetGame());
  if IsDefined(content) {
    let prof = content.GetFaction(CBClassifyFaction(puppet));
    if IsDefined(prof) {
      base += prof.courageMod;
    }
  }
  return ClampF(base, 0.0, 1.0);
}

public func CBCombatFleeCheck(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) || puppet.cbLowHealthFled {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  let intensity = 1.0;
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    // Morale off means nobody breaks. It used to return here, which also meant nobody wounded was
    // ever remembered, so turning Morale off quietly took the wounded-and-got-away Rivals with it.
    if rt.HasSettings() {
      intensity = rt.GetSettings().morale ? rt.GetSettings().moraleIntensity : 0.0;
    }
  }
  if sys.IsInSafeZone() {
    return;   // not in a safe area (spec §16)
  }
  // How hurt, first: one stat read, and it turns away nearly every hit.
  let sps = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(sps) {
    return;
  }
  // A percentage, which is what the threshold is.
  let hp = sps.GetStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health, true);
  if hp > CBConfig.FleeHealthThreshold() {
    return;
  }
  // Knocked out by this very hit, or already down: that is CBSparedCheck's business. Read as a
  // quarter of their health, they were logged as a runner and even given an order to run.
  if !CBStillStanding(puppet) {
    return;
  }
  // Bosses and MaxTac never run; the Safety Gate protects quest/companion/scene NPCs.
  // Rivals can run - that is the whole point.
  if !CBSafetyGate.CanAffect(puppet) || puppet.IsBoss() {
    return;
  }
  let faction = CBClassifyFaction(puppet);
  if Equals(faction, n"MaxTac") {
    return;
  }

  // Decided once, at low health.
  puppet.cbLowHealthFled = true;

  // Track them whether or not they run.
  CBAddEscapee(sys, game, puppet, faction);

  // Whether they actually break and run. Steadier ranks hold their ground (CBNerve), and an apex squad member or a
  // Rival who is Hard to Scare never does. When a mod like Much Better AI owns morale, it decides who breaks and runs.
  if intensity <= 0.0 || CBHoldsGround(puppet) || CBExternalMoraleOwner() {
    return;
  }
  let shaken = MaxF(CBConfig.MoraleHurtShock(), puppet.cbMorale > 0.0 ? 1.0 - puppet.cbMorale : 0.0);
  let chance = CBBreakChance(sys, puppet, faction, shaken, CBAlliesNear(sys, puppet), false, false, intensity);
  if RandF() < chance {
    if CBRivalYields(sys, game, puppet) {
      return;
    }
    if CBRoomToBreak(sys, puppet) {
      CBMoraleBreak(sys, game, puppet, faction, chance);
      // A Rival V knows, breaking: they beg as they go, in their own voice.
      let desBreak = GameInstance.GetDynamicEntitySystem();
      if IsDefined(desBreak) && desBreak.IsTagged(puppet.GetEntityID(), n"CB_Rival") {
        CBVoice(sys, game, puppet, n"fear_beg", n"RivalFlees", 20.0);
      }
    }
  }
}

// A Rival at the end of their rope, who breaks, may give up where they stand instead of running: down, in the game's
// defeated state (NPCPuppet.script, OnPotentialDeath: Defeated, and the moment of invulnerability after it), with V as
// the one who put them there.
func CBRivalYields(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Bool {
  if !CBMercyChoiceOn() || !puppet.cbDamagedByPlayer || puppet.cbLastHitByOther
     || RandF() >= CBConfig.RivalYieldShare() {
    return false;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !des.IsTagged(puppet.GetEntityID(), n"CB_Rival") || !IsDefined(CBFindRivalByBody(sys, puppet.GetEntityID())) {
    return false;
  }
  if CBMoraleHeldAtJob(sys, game, puppet) {
    return false;
  }
  let player = GetPlayer(game);
  let by: EntityID;
  if IsDefined(player) {
    by = player.GetEntityID();
  }
  StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.Defeated", by);
  StatusEffectHelper.ApplyStatusEffect(puppet, t"BaseStatusEffect.InvulnerableAfterDefeated", by);
  CBLog.Info(n"Rivals", "A Rival at the end of their rope gave up: down, and V's to decide.");
  return true;
}

// Resolve pending escapees on the fast tick. Deaths already dropped the ones V caught, so
// anything left that despawned alive or outran V counts as having gotten away.
// Catch a mercy the hit hook missed.
public func CBSparedSweep(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  // Not gated on the Rival setting: this is also how a mercy the hit hook missed gets scored,
  // and Conduct does not answer to that setting (see CBSparedCheck).
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  let reg = sys.GetRegistry();
  if !IsDefined(reg) {
    return;
  }
  let npcs = reg.GetAll();
  let looked = 0;
  let i = 0;
  while i < ArraySize(npcs) && looked < CBConfig.SparedSweepPerTick() {
    let npc = npcs[i];
    i += 1;
    // cbSparedLogged keeps this to one look per enemy; CBSparedCheck sets it when it logs.
    if IsDefined(npc) && npc.cbDamagedByPlayer && !npc.cbSparedLogged && CBNpcSafe(sys, npc)
       && (ScriptedPuppet.IsDefeated(npc) || npc.IsIncapacitated()) {
      looked += 1;
      // Put down by somebody else after V had hurt them: not V's mercy to give, as their death would not be V's kill
      // (Signals/CombatSignals.reds, the killing blow): no Conduct, no standing for sparing them, no Spared Rival.
      if CBLastHitWasOthers(game, npc) {
        npc.cbSparedLogged = true;
      } else {
        CBSparedCheck(sys, game, npc);
      }
    }
  }
}

public func CBProcessEscapees(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let list = sys.GetEscapees();
  if ArraySize(list) == 0 {
    return;
  }
  let player = GetPlayer(game);
  let ppos: Vector4;
  if IsDefined(player) {
    ppos = player.GetWorldPosition();
  }
  let now = CBGameSeconds(game);
  let i = 0;
  while i < ArraySize(list) {
    let e = list[i];
    i += 1;
    if IsDefined(e) {
      // CBNpcSafe, not a bare IsAttached: during a mass despawn an entity can still report
      // as attached while its components are being torn down, and reading its position
      // then is exactly the kind of query that takes the game down (crash safety).
      let gone = !CBNpcSafe(sys, e.puppet);   // despawned / streamed out = got away
      let age = sys.GetTickCount() - e.tick;
      if !gone {
        e.lastPos = e.puppet.GetWorldPosition();
        e.hasPos = true;
      }
      if e.spared {
        // Someone V put down and did not finish. They do not run, so "left alive" means either
        // they streamed away still breathing, or V walked away from them.
        let distance = !gone ? Vector4.Distance(ppos, e.puppet.GetWorldPosition()) : 0.0;
        // While V is still fighting, walking off from them is following the fight, not leaving them: V has left them
        // only beyond the reach they are kept in until then (CBRemainsInReach), so nobody is booked as spared, or a
        // Rival's encounter closed, for V chasing the rest of the crew forty-five metres down the street.
        let fighting = IsDefined(player) && player.IsInCombat();
        let leftThem = !IsDefined(player)
                    || (!gone && distance > (fighting ? CBConfig.RemainsFightDistance() : CBConfig.SparedLeftDistance()));
        // A Rival's encounter is closed by this resolution, and holding it open for as long as V stays near the body
        // would leave the Rival lane reading as free (CBLiveRivalPresent asks for somebody standing) - the re-queued,
        // "teleporting" Rival.
        let ready = age >= CBConfig.SparedResolveTicks();
        if e.wasRival {
          if CBMercyChoiceOn() {
            // V's choice: told once; spared when V stands with empty hands for a moment out of the fight, walks away,
            // or says so where they lie. Killing them is the other answer, and the death handler has that.
            if !gone && !e.announced && IsDefined(player) {
              e.announced = true;
              e.puppet.cbMercyOpen = true;
              let fallen = CBFindRivalByBody(sys, e.entityId);
              if IsDefined(fallen) {
                CBSystemNote(game, CBTf(n"Cyberbane-CombatFlee-IsDownFinishThemWalkOff", [s"\(CBRivalDisplayName(sys.GetContent(), fallen))"]), 8.0);
              }
            }
            // Empty hands spare them only from a distance.
            let deciding = !gone && (e.puppet.cbTalkPartner || distance <= CBConfig.MercyTalkRadius());
            let empty = IsDefined(player) && !player.IsInCombat() && !IsDefined(GameObject.GetActiveWeapon(player)) && !deciding;
            e.holsterTicks = empty ? e.holsterTicks + 1 : 0;
            leftThem = leftThem || e.holsterTicks >= CBConfig.MercyHolsterTicks() || e.mercyChosen
                    || (!gone && !fighting && distance > CBConfig.EscapeDistance());
            ready = e.mercyChosen || age >= CBConfig.MercyMinTicks();
          } else {
            // Out of the fight; or, still in it, beyond the reach they are kept in (above).
            leftThem = leftThem || !fighting;
          }
        }
        // The backstop for V staying near them without choosing, never while V is still fighting.
        let backstop = e.wasRival && age >= CBConfig.SparedResolveMaxTicks() && !fighting;
        if gone || (ready && leftThem) || backstop {
          if !gone && IsDefined(e.puppet) {
            e.puppet.cbMercyOpen = false;
          }
          // Gone is gone, not dead: one that streamed out was still breathing when last seen.
          // Only a body still in the world can say it died, and CBNpcSafe has just said it is.
          CBSettleMercy(sys, e, gone || !e.puppet.IsDead());
          CBHandleSpared(sys, game, e, now);
          sys.RemoveEscapee(e);
        }
      } else {
        // Far away is only away for somebody who is running, or who has stopped fighting. A wounded
        // shooter sixty metres off and still firing has not escaped anything, and made a Rival of
        // somebody V then killed.
        let far = !gone && IsDefined(player)
               && Vector4.Distance(ppos, e.puppet.GetWorldPosition()) > CBConfig.EscapeDistance()
               && (e.fleeing || !CBNpcInCombat(e.puppet));
        if gone || far {
          CBHandleEscape(sys, game, e, now);
          if e.fleeing {
            CBRunnerGotAway(sys, game, e);
          }
          sys.RemoveEscapee(e);
        } else {
          // Reached where they were running to and V is still on them: they keep going.
          if e.fleeing && !gone && age > 0 && age % CBConfig.FleeReorderTicks() == 0
             && e.fleeOrders < CBConfig.FleeMaxOrders() {
            e.fleeOrders += 1;
            CBOrderFlee(game, e.puppet);
          }
          if age > CBConfig.EscapeTimeoutTicks() {
            if e.fleeing && !gone {
              CBRally(e.puppet);
            }
            sys.RemoveEscapee(e);
          }
        }
      }
    }
  }
}

// V beat someone down and left them breathing. Some of them take that worse than dying: they
// come back as a Spared Rival carrying the Humiliated trait (spec §10.2).
func CBHandleSpared(sys: ref<CyberbaneSystem>, game: GameInstance, e: ref<CBEscapee>, now: Float) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().rivals {
    return;
  }
  if Equals(e.faction, n"") || !TDBID.IsValid(e.record) {
    return;
  }
  // They were down and breathing when this was logged. If they are still here and dead now, something finished them
  // afterwards - a bleed-out, a stray round, another mod's damage - and a corpse does not come back as a Rival.
  if IsDefined(e.puppet) && e.puppet.IsDead() {
    return;
  }
  let content = CBContent(game);
  let district = CBEventDistrict(sys, game);

  // Was this somebody who is already a Rival?
  if EntityID.IsDefined(e.entityId) {
    let already = CBFindRivalByBody(sys, e.entityId);
    if IsDefined(already) {
      let st = sys.GetStats();
      if IsDefined(st) {
        st.rivalsSpared += 1;   // the counter existed and nothing ever incremented it
      }
      // Asked to work for V where they lay, and said yes (Reactions/Crew.reds, [C1]): off the board, on the crew.
      if e.recruited {
        CBCrewTakeRival(sys, game, already, e);
        CBCreditMercy(sys, already.faction, CBConfig.MercyRivalCredit());
        return;
      }
      // Told to leave Night City where they lay, and they went (Rivals/RivalLife.reds).
      if e.exiled {
        already.state = EnumInt(ECBRivalState.Retired);
        CBHierarchyFill(sys, already.faction);   // their chair is somebody else's now
        CBCloseRivalEncounter(sys, game, already, e.puppet);
        CBFileLog(sys, n"RivalExiled", now, district, already.faction, Cast<Float>(already.id));
        let exiledBook = CBRivalBook.Get(game);
        if IsDefined(exiledBook) {
          exiledBook.SetEnding(already.id, CBEndingRetired(), now);   // for where they end up ([61])
        }
        if CBMessagesOn() {
          CBHearsayFromStreet(game, CBTf(n"Cyberbane-CombatFlee-LeftNightCityInTheBack", [s"\(CBRivalDisplayName(content, already))"]), n"");
        }
        CBLog.Info(n"Rivals", s"Rival \(already.id) was run out of Night City.");
        return;
      }
      let indebted = CBRivalSparedByV(already, content, now, district);
      // Where V first beat them, and a bond's debt (Rivals/RivalMoments.reds).
      CBRivalSparedMoment(sys, game, already, e.puppet);
      // Spared once too often at the top of the ladder, and not grateful for it.
      if !indebted {
        CBRivalMaybeBreak(sys, game, already);
      } else {
        // Grateful instead: they owe V, and pay it back in tips (Reactions/StreetIntel.reds). Out of the fight for
        // good, so out of their chair too.
        CBIntelDebtor(sys, game, already);
        CBHierarchyFill(sys, already.faction);
      }
      // Their gang hears that V had one of their names cold and let them walk. Done here
      // rather than inside CBRivalSparedByV, which has no system handle to credit against.
      CBCreditMercy(sys, already.faction, CBConfig.MercyRivalCredit());
      already.scarMask = already.scarMask | e.scarMask;
      // Left lying here, alive. Somebody will have seen it (Rivals/Whereabouts.reds).
      CBNoteEscapeeSeen(sys, game, already, e);
      // The encounter is over, so close it the way every other ending does.
      CBCloseRivalEncounter(sys, game, already, e.puppet);
      if CBMessagesOn() {
        let name = CBRivalDisplayName(content, already);
        if indebted {
          CBHearsayFromStreet(game, CBTf(n"Cyberbane-CombatFlee-OwesYouOneNowPeopleLike", [s"\(name)"]), n"");
        } else {
          CBHearsayFromStreet(game, CBTf(n"Cyberbane-CombatFlee-YouLetWalkAgainTheyCame", [s"\(name)"]), n"");
        }
      }
      return;
    }
  }

  // A cyberpsycho carries their own fifty-fifty inside CBCreateRival. Letting the generic roll
  // run first as well would compound the two and turn a coin flip into three chances in eight.
  if !CBRecordIsSightingCyberpsycho(e.record)
     && !CBRivalRoll(sys, "spared", CBConfig.RivalChanceSpared(), e.record, true, e.faction) {
    return;   // not everyone you spare makes it personal (Rivals/RivalSystem.reds, CBRivalOdds)
  }
  // Made once the fight is over, not with them still lying at V's feet (Rivals/Births.reds).
  CBRivalAfterFight(sys, game, e.faction, e.record, n"", ECBRivalSource.Spared, district, now, e, 0, "");
}

func CBHandleEscape(sys: ref<CyberbaneSystem>, game: GameInstance, e: ref<CBEscapee>, now: Float) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().rivals {
    return;
  }
  let content = CBContent(game);
  let district = CBEventDistrict(sys, game);
  let toasts = CBMessagesOn();

  // The Rival that was hunting you got away again: it ranks up and comes back meaner.
  let fled: ref<CBRival>;
  if e.wasRival {
    fled = CBFindRivalByBody(sys, e.entityId);
    if !IsDefined(fled) && sys.GetActiveRivalId() > 0 {
      fled = sys.FindRivalById(sys.GetActiveRivalId());
    }
  }
  if e.wasRival && IsDefined(fled) {
    let r = fled;
    if IsDefined(r) {
      // Where they were when V last saw them, for whoever passes it on (Rivals/Whereabouts.reds).
      CBNoteEscapeeSeen(sys, game, r, e);
      CBRivalEscaped(r, content, now, district, true);
      r.state = EnumInt(ECBRivalState.Hunting);
      if toasts && IsDefined(content) {
        CBPhoneSendTinted(game, CBRivalDisplayName(content, r), CBRivalGotAwayLine(r), CBHudRed());
      }
      // The one ending that still cleared its own subset: the active id, but never the body, so the
      // record went on naming a body that could still be standing, and CBLiveRivalPresent read the
      // Rival lane as busy until it was swept.
      CBCloseRivalEncounter(sys, game, r, e.puppet);
    } else {
      sys.SetActiveRivalId(0);
    }
    // They got away, so let them be seen getting away. Their body was handed off when the encounter
    // closed; this only clears Rival bodies nobody owns, never one of a team still fighting.
    CBSweepStrayRivalBodies(sys, game);
    CBRivalMaybeBreak(sys, game, r);
    return;
  }

  // A regular enemy got away: it may become a Survivor Rival already on your trail. The same chance a morale break has.
  if Equals(e.faction, n"") || !TDBID.IsValid(e.record)
     || !CBRivalRoll(sys, "got away", CBConfig.RivalChanceSurvivor(), e.record, true, e.faction) {
    return;
  }
  // Made once the fight is over (Rivals/Births.reds).
  CBRivalAfterFight(sys, game, e.faction, e.record, n"", ECBRivalSource.Survivor, district, now, e, 0, "");
}

// Somebody who has turned to run. Whether they turn into a Rival is settled once they have really got
// away (CBHandleEscape); if V catches them first, their death takes them off the list.
func CBAddEscapee(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>, faction: CName) -> Void {
  let e = new CBEscapee();
  e.puppet = puppet;
  e.entityId = puppet.GetEntityID();
  e.faction = faction;
  e.record = puppet.GetRecordID();
  e.at = CBGameSeconds(game);
  e.tick = sys.GetTickCount();
  e.scarMask = puppet.cbScarMask;
  let des = GameInstance.GetDynamicEntitySystem();
  e.wasRival = IsDefined(des)
            && (des.IsTagged(e.entityId, n"CB_Rival") || des.IsTagged(e.entityId, n"CB_Lair"));
  sys.AddEscapee(e);
}

// One of a crew has run for it and is gone. They count as out of the fight: a crew with one survivor halfway across the
// district used to be a crew V could never finish, so no "crew beaten", no bounty, and the lane stayed busy.
func CBRunnerGotAway(sys: ref<CyberbaneSystem>, game: GameInstance, e: ref<CBEscapee>) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) || !IsDefined(e) {
    return;
  }
  let id = e.entityId;
  let squad = des.IsTagged(id, n"CB_Squad");
  let tag = squad ? n"CB_Squad" : n"CB_Escort";
  if !squad && !des.IsTagged(id, n"CB_Escort") {
    return;
  }
  if !CBRemoveOne(game, des, id, false, true) {
    des.UnassignTag(id, tag);
    des.AssignTag(id, n"CB_Orphan");
  }
  if squad {
    CBCrewBeatenIfLast(sys, game, id);
  }
}

// One of a crew has left the fight without being put down (ran clear, or gave up: Spawn/LivingStreet.reds).
// If nobody of the crew is left standing but them, the crew is beaten.
func CBCrewBeatenIfLast(sys: ref<CyberbaneSystem>, game: GameInstance, gone: EntityID) -> Void {
  if NotEquals(sys.GetActiveSquadFaction(), n"")
     && CBCountLiveOrSpawningExcept(game, n"CB_Squad", gone, n"CB_Bounty") == 0
     && (!sys.ActiveSquadHasApex() || CBCountLiveOrSpawningExcept(game, n"CB_Apex", gone) == 0) {
    CBOnCrewBeaten(sys, game, sys.GetActiveSquadFaction());
  }
}

// Ran, and could not get clear. They turn and fight again.
func CBRally(npc: wref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) || !npc.cbMoraleBroken {
    return;
  }
  npc.cbMoraleBroken = false;
  npc.cbLowHealthFled = false;   // hurt again later, they are judged again
  CBCancelMove(npc);
  CBLog.Info(n"Reactions", "A runner who could not get away turned to fight again.");
}

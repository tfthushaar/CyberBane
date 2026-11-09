// Cyberbane - Combat flee and escape -> Rival (spec §10.2)
//
// A wounded enemy can lose its nerve and run. If it gets away it becomes a Survivor Rival
// that will come for you later; if it was already the Rival hunting you, it climbs a rank
// and returns harder (and gains the Scarred trait). Detection: a fleeing enemy is logged
// as a pending escapee; any death cancels it (the death handler drops it), and anything
// left that despawns alive or outruns V counts as escaped. Uses the game's own fear path
// (a Terror stim), so it is reversible and needs no custom audio.

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

// Called from OnHit when V has just damaged this puppet. If that blow put them down without
// killing them - a knockout, a non-lethal takedown, a defeat - log it. If V then walks away and
// leaves them breathing, CBProcessEscapees turns them into a Spared Rival who remembers being
// beaten and left there. Killing them afterwards drops the entry (the death handler clears it),
// so this only ever fires for someone you genuinely spared.
public func CBSparedCheck(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(puppet) || puppet.cbSparedLogged {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return;
  }
  // The Rivals setting used to bail out right here, which quietly took Conduct with it.
  // Putting somebody down alive is how Conduct is earned, and it is also how a Spared Rival
  // is created, but only the second of those is what that setting is about. A player who
  // turned Rivals off lost every point of Conduct they earned and had no way to know. The
  // check now sits on the Rival itself, at the bottom, and nothing else answers to it.
  let rivalsOn = true;
  if IsDefined(rt) && rt.HasSettings() {
    rivalsOn = rt.GetSettings().rivals;
  }
  if sys.IsInSafeZone() {
    return;   // not in a safe area (spec §16)
  }
  // CanAffect already rules out dead, quest, companion, vendor and in-scene puppets.
  if !CBSafetyGate.CanAffect(puppet) {
    return;
  }
  // Down, but still breathing - that is what makes it mercy rather than a kill.
  if !ScriptedPuppet.IsDefeated(puppet) && !puppet.IsIncapacitated() {
    return;
  }
  let faction = CBClassifyFaction(puppet);
  if Equals(faction, n"") || Equals(faction, n"MaxTac") {
    return;   // unaffiliated nobodies and MaxTac are neither scored nor remembered
  }

  puppet.cbSparedLogged = true;
  // Classified now, scored later.
  //
  // This used to be scored the moment they dropped: +Conduct, the nonLethal tally, fs.spared,
  // the mercy credit with their rivals, the quiet-takedown count, all of it. Being down is not
  // being spared, though. Put a room to sleep with Pax, walk round scanning them and put a round
  // through each head, and every one of them had already been booked as mercy - the kill path
  // tried to take it back with CBRevokeMercy, which only knew about three of those axes, and the
  // escapee resolve below could settle the mercy while V was still standing over the body, so
  // the Spared Rival and the message were out before the shot was fired.
  //
  // So the incident is classified here, while who saw it and how it was done are still true,
  // and held on the escapee. CBSettleMercy scores it once V has really left them breathing; if
  // V finishes them first, the death handler drops the escapee and the mercy never existed.
  // Only V's own work counts, the same rule the kill path uses.
  let mercy: ref<CBKillInfo>;
  if puppet.cbDamagedByPlayer {
    mercy = CBBuildKillInfo(sys, game, puppet, false);
    // The fight you are in does count it now: somebody down is out of the fight either way, and
    // a non-lethal playthrough has to be able to end an encounter. If V finishes them, the death
    // handler turns this down into a body instead of counting them twice.
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
//
// `alive` is the caller's answer to whether they still are; a body V or anything else finished
// in the meantime is not mercy. The Rival setting has no say here - Conduct is earned whether or
// not Rivals are on (see CBSparedCheck).
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

// Called from OnHit when V has just damaged this puppet.
// How steady this one is under fire: the chance it holds its ground rather than breaking.
// A flat coin flip made every enemy behave the same, which read as random rather than as
// character. Rank decides it, so bosses never run and rank and file break often.
//
// The idea of giving each NPC a temperament instead of one global flee chance comes from
// Much Better AI (Nexus 31402) by cshiai. The implementation here is our own.
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
  // Bosses and MaxTac never run; the Safety Gate protects quest/companion/scene NPCs.
  // Rivals can run - that is the whole point.
  if !CBSafetyGate.CanAffect(puppet) || puppet.IsBoss() {
    return;
  }
  // Knocked out by this very hit, or already down: that is CBSparedCheck's business. Read as a
  // quarter of their health, they were logged as a runner and even given an order to run.
  if !CBStillStanding(puppet) {
    return;
  }
  let faction = CBClassifyFaction(puppet);
  if Equals(faction, n"MaxTac") {
    return;
  }

  let sps = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(sps) {
    return;
  }
  // A percentage, which is what the threshold is. The last argument is `perc`: false is hit points
  // (the game compares it with GetStatPoolMaxPointValue, damageSystem.script:2938), so this read
  // "25 hit points left" and nearly nobody survived to that, which is why wounded enemies never ran.
  let hp = sps.GetStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health, true);
  if hp > CBConfig.FleeHealthThreshold() {
    return;
  }

  // Decided once, at low health.
  puppet.cbLowHealthFled = true;

  // Track them whether or not they run. Leaving a wounded enemy standing is the player
  // sparing them just as much as letting one escape is, and tying this record to the flee
  // roll meant half of everyone you wounded and walked away from was never even considered
  // for a Rival. Tracking costs nothing: the escapee list is session-only and self-pruning.
  CBAddEscapee(sys, game, puppet, faction);

  // Whether they actually break and run. Steadier ranks hold their ground (CBNerve), and an
  // apex squad member or a Rival who is Hard to Scare never does.
  // When a mod like Much Better AI owns morale, it decides who breaks and runs. Cyberbane still
  // recorded that this one is hurt, above, so Rivals keep coming from people who got away.
  if intensity <= 0.0 || CBHoldsGround(puppet) || CBExternalMoraleOwner() {
    return;
  }
  let shaken = MaxF(CBConfig.MoraleHurtShock(), puppet.cbMorale > 0.0 ? 1.0 - puppet.cbMorale : 0.0);
  let chance = CBBreakChance(sys, puppet, faction, shaken, CBAlliesNear(sys, puppet), false, false, intensity);
  if RandF() < chance && CBRoomToBreak(sys, puppet) {
    CBMoraleBreak(sys, game, puppet, faction, chance);
  }
}

// Resolve pending escapees on the fast tick. Deaths already dropped the ones V caught, so
// anything left that despawned alive or outran V counts as having gotten away.
// Catch a mercy the hit hook missed.
//
// CBSparedCheck runs from OnHit, so it only ever sees an enemy that goes down on a blow V
// landed that raised a hit event we are hooked to. Anyone who drops to a burn, a quickhack
// tick, an explosion, or another mod's damage can end up defeated and breathing with nothing
// logged, and a player who walked away believing they showed mercy gets no Rival out of it.
// This sweeps the live NPC registry so the mercy is noticed however they went down.
//
// Crash safety: no new engine API. Same registry and same CBNpcSafe gate the Director uses,
// bounded per tick, and CBSparedCheck re-runs every one of its own guards (enabled, the rivals
// setting, safe zones, CanAffect, defeated-and-alive, faction), so this is only another way in.
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
    if CBNpcSafe(sys, npc) && npc.cbDamagedByPlayer && !npc.cbSparedLogged {
      looked += 1;
      CBSparedCheck(sys, game, npc);
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
        //
        // It used to also be enough for V to be out of combat for twenty-five seconds, with a
        // three-minute backstop. After a quiet takedown V is out of combat the whole time, so
        // walking round a sleeping room with a scanner settled every one of them as spared
        // while V stood there, and the headshots that followed a minute later were kills of
        // people already booked as mercy. Being near them is the question now: V has to have
        // actually gone. The escapee cap still settles the oldest if a long stay fills it.
        let distance = !gone ? Vector4.Distance(ppos, e.puppet.GetWorldPosition()) : 0.0;
        let leftThem = !IsDefined(player) || (!gone && distance > CBConfig.SparedLeftDistance());
        // A Rival's encounter is closed by this resolution, and holding it open for as long as V
        // stays near the body would leave the Rival lane reading as free (CBLiveRivalPresent asks
        // for somebody standing) - the re-queued, "teleporting" Rival. They keep the old timing.
        if e.wasRival {
          leftThem = leftThem || !player.IsInCombat()
                  || (!gone && distance > CBConfig.EscapeDistance());
        }
        let backstop = e.wasRival && age >= CBConfig.SparedResolveMaxTicks();
        if gone || (age >= CBConfig.SparedResolveTicks() && leftThem) || backstop {
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
  // They were down and breathing when this was logged. If they are still here and dead now,
  // something finished them afterwards - a bleed-out, a stray round, another mod's damage -
  // and a corpse does not come back as a Rival. A puppet that simply streamed out is gone
  // rather than dead, and still counts as left alive.
  if IsDefined(e.puppet) && e.puppet.IsDead() {
    return;
  }
  let content = CBContent(game);
  let district = CBEventDistrict(sys, game);

  // Was this somebody who is already a Rival?
  //
  // This path did not exist: every mercy created a brand new Rival, so sparing the same person
  // twice was never recorded. CBRivalSparedByV - the function that counts it, can turn them
  // into a Debtor and promotes them - was never called from anywhere in the mod. That also
  // left the mercy term of the nemesis ladder permanently zero, so a Rival only ever got
  // harder from escaping, never from being let go.
  //
  // Asked of the entity id the escapee was logged with, not of the puppet. The puppet is only a
  // weak reference, and it is gone by the time this runs whenever the body streamed out or was
  // cleared away first - which is one of the two ways this resolves at all. Asking the puppet
  // took every such Rival for a stranger and made a second Rival of the same person.
  if EntityID.IsDefined(e.entityId) {
    let already = CBFindRivalByBody(sys, e.entityId);
    if IsDefined(already) {
      let st = sys.GetStats();
      if IsDefined(st) {
        st.rivalsSpared += 1;   // the counter existed and nothing ever incremented it
      }
      let indebted = CBRivalSparedByV(already, content, now, district);
      // Their gang hears that V had one of their names cold and let them walk. Done here
      // rather than inside CBRivalSparedByV, which has no system handle to credit against.
      CBCreditMercy(sys, already.faction, CBConfig.MercyRivalCredit());
      already.scarMask = already.scarMask | e.scarMask;
      // Left lying here, alive. Somebody will have seen it (Rivals/Whereabouts.reds).
      CBNoteEscapeeSeen(sys, game, already, e);
      // The encounter is over, so close it the way every other ending does.
      //
      // This was the one way out of a Rival fight that tidied nothing up. Beating one to death
      // goes through OnDeath, and outrunning one goes through CBHandleEscape, and both clear
      // the marker, the active id and the body. Leaving one breathing did none of it, which
      // produced two bugs that looked unrelated and were the same omission:
      //
      //   - The map pin is registered against the puppet and only ever removed on death, so a
      //     Rival put down alive kept their marker for the rest of the save. Anyone raising
      //     Conduct by going non-lethal collected one per Rival and had no way to clear them.
      //   - CBLiveRivalPresent asks CBStillStanding, which is false for somebody
      //     unconscious, so the "one Rival encounter at a time" gate read as clear while the
      //     body was still lying there. The same Rival was then queued again and given a
      //     fresh body behind V - on a rooftop if V had climbed one. That is the Rival who
      //     "teleported": it was never the same body moving, it was a second one.
      CBCloseRivalEncounter(sys, game, already, e.puppet);
      if CBMessagesOn() {
        let name = CBRivalDisplayName(content, already);
        if indebted {
          CBHearsayFromStreet(game, s"\(name) owes you one now. People like that remember both ways.", n"");
        } else {
          CBHearsayFromStreet(game, s"You let \(name) walk again. They came back worse for it.", n"");
        }
      }
      return;
    }
  }

  // A cyberpsycho carries their own fifty-fifty inside CBCreateRival. Letting the generic roll
  // run first as well would compound the two and turn a coin flip into three chances in eight.
  if !CBRecordIsSightingCyberpsycho(e.record) && RandF() > CBConfig.RivalChanceSpared() {
    return;   // not everyone you spare makes it personal
  }
  let nr = CBCreateRival(sys, game, e.faction, e.record, n"", ECBRivalSource.Spared, district, now);
  if IsDefined(nr) {
    nr.scarMask = e.scarMask;   // they remember how it went
    CBNoteEscapeeSeen(sys, game, nr, e);
    nr.state = EnumInt(ECBRivalState.Hunting);
    if CBMessagesOn() {
      CBHearsayFromStreet(game, s"\(CBRivalDisplayName(content, nr)) walked away from you breathing. They will not forget it.", n"");
    }
  }
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
  if e.wasRival && sys.GetActiveRivalId() > 0 {
    let r = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(r) {
      // Where they were when V last saw them, for whoever passes it on (Rivals/Whereabouts.reds).
      CBNoteEscapeeSeen(sys, game, r, e);
      CBRivalEscaped(r, content, now, district, true);
      r.state = EnumInt(ECBRivalState.Hunting);
      if toasts && IsDefined(content) {
        CBPhoneSendTinted(game, CBRivalDisplayName(content, r), CBRivalGotAwayLine(r), CBHudRed());
      }
    }
    sys.SetActiveRivalId(0);
    // They got away, so let them be seen getting away.
    CBDeleteTaggedSafe(game, n"CB_Rival", false, true);
    return;
  }

  // A regular enemy got away: it may become a Survivor Rival already on your trail. The same chance
  // a morale break has. There was no roll here because this door was all but shut (see the health
  // check in CBCombatFleeCheck), and now that it opens at a quarter health, everybody V walked away
  // from wounded would otherwise come back with a name.
  let survivorOdds = CBConfig.RivalChanceSurvivor();
  if IsDefined(rt) && rt.HasSettings() {
    survivorOdds *= rt.GetSettings().rivalFrequencyMult;
  }
  if RandF() >= survivorOdds {
    return;
  }
  if NotEquals(e.faction, n"") && TDBID.IsValid(e.record) {
    let nr = CBCreateRival(sys, game, e.faction, e.record, n"", ECBRivalSource.Survivor, district, now);
    if IsDefined(nr) {
      nr.scarMask = e.scarMask;
      CBNoteEscapeeSeen(sys, game, nr, e);
    }
    if IsDefined(nr) {
      nr.state = EnumInt(ECBRivalState.Hunting);
      if toasts {
        CBHearsayFromStreet(game, s"\(CBRivalDisplayName(content, nr)) got clear of you. You have not seen the last of them.", n"");
      }
    }
  }
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

// One of a crew has run for it and is gone. They count as out of the fight: a crew with one survivor
// halfway across the district used to be a crew V could never finish, so no "crew beaten", no bounty,
// and the lane stayed busy. Removed out of sight, or handed to the orphan sweep if V is looking.
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
  if squad && NotEquals(sys.GetActiveSquadFaction(), n"")
     && CBCountLiveOrSpawningExcept(game, n"CB_Squad", id) == 0
     && (!sys.ActiveSquadHasApex() || CBCountLiveOrSpawningExcept(game, n"CB_Apex", id) == 0) {
    CBOnCrewBeaten(sys, game, sys.GetActiveSquadFaction());
  }
}

// Ran, and could not get clear. They turn and fight again. Left broken, nothing would ever give them
// an order (the hunt skips anybody broken), so one of a crew stood about for good: the crew could not
// be beaten, its lane stayed busy, and the hunt ended by telling V that V had run.
func CBRally(npc: wref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) || !npc.cbMoraleBroken {
    return;
  }
  npc.cbMoraleBroken = false;
  npc.cbLowHealthFled = false;   // hurt again later, they are judged again
  CBCancelMove(npc);
  CBLog.Info(n"Reactions", "A runner who could not get away turned to fight again.");
}

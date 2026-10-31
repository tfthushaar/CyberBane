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
  // Score it. This is the line that was missing: the spared path recorded an escapee and
  // stopped, so nothing non-lethal ever reached CBApplyKill and the +1 conduct, the nonLethal
  // tally, fs.spared and the quiet-takedown count were all unreachable. Only V's own work
  // counts, the same rule the kill path uses.
  if puppet.cbDamagedByPlayer {
    let info = CBBuildKillInfo(sys, game, puppet, false);
    CBApplyKill(sys, info);
    // And it counts toward the fight you are in. Clearing a room without killing anybody was
    // not registering as clearing a room at all, so a non-lethal playthrough could never end
    // an encounter, which is what the flawless and massacre tests are measured against.
    CBEncounterRecordKill(sys, info);
  }
  // Talking one down rather than putting them in the ground is its own kind of reputation.
  if CBIsCyberpsycho(puppet) {
    let st = sys.GetStats();
    if IsDefined(st) {
      st.psychosPacified += 1;
    }
  }
  if !rivalsOn {
    return;   // scored above; only the Rival that would come of it is switched off
  }
  let e = new CBEscapee();
  e.puppet = puppet;
  e.entityId = puppet.GetEntityID();
  e.faction = faction;
  e.record = puppet.GetRecordID();
  e.at = CBGameSeconds(game);
  e.spared = true;
  e.scarMask = puppet.cbScarMask;   // what V did on the way down, before the puppet is gone
  sys.AddEscapee(e);
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
    if rt.HasSettings() {
      if !rt.GetSettings().morale {
        return;
      }
      intensity = rt.GetSettings().moraleIntensity;
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
  let faction = CBClassifyFaction(puppet);
  if Equals(faction, n"MaxTac") {
    return;
  }

  let sps = GameInstance.GetStatPoolsSystem(game);
  if !IsDefined(sps) {
    return;
  }
  let hp = sps.GetStatPoolValue(Cast<StatsObjectID>(puppet.GetEntityID()), gamedataStatPoolType.Health, false);
  if hp > CBConfig.FleeHealthThreshold() {
    return;
  }

  // Decided once, at low health.
  puppet.cbLowHealthFled = true;

  // Track them whether or not they run. Leaving a wounded enemy standing is the player
  // sparing them just as much as letting one escape is, and tying this record to the flee
  // roll meant half of everyone you wounded and walked away from was never even considered
  // for a Rival. Tracking costs nothing: the escapee list is session-only and self-pruning.
  let e = new CBEscapee();
  e.puppet = puppet;
  e.entityId = puppet.GetEntityID();
  e.faction = faction;
  e.record = puppet.GetRecordID();
  e.at = CBGameSeconds(game);
  e.scarMask = puppet.cbScarMask;
  let des = GameInstance.GetDynamicEntitySystem();
  e.wasRival = IsDefined(des) && des.IsTagged(e.entityId, n"CB_Rival");
  sys.AddEscapee(e);

  // Whether they actually break and run. Steadier ranks hold their ground (CBNerve).
  if intensity <= 0.0 || RandF() < CBNerve(puppet) {
    return;
  }

  // When a mod like Much Better AI owns morale, it decides who breaks and runs. Cyberbane
  // still records that this one is running, so Rivals keep coming from people who got away,
  // but it does not broadcast its own terror on top of theirs (Core/Compat.reds).
  if !CBExternalMoraleOwner() {
    let b = puppet.GetStimBroadcasterComponent();
    if IsDefined(b) {
      b.TriggerSingleBroadcast(puppet, gamedataStimType.Terror);
    }
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
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() && !rt.GetSettings().rivals {
      return;
    }
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
      if e.spared {
        // Someone V put down and did not finish. They do not run, so "left alive" means either
        // they streamed away still breathing, or enough time passed that V clearly walked off.
        if gone || (now - e.at) > CBConfig.SparedResolveSeconds() {
          CBHandleSpared(sys, game, e, now);
          sys.RemoveEscapee(e);
        }
      } else {
        let far = !gone && IsDefined(player)
               && Vector4.Distance(ppos, e.puppet.GetWorldPosition()) > CBConfig.EscapeDistance();
        if gone || far {
          CBHandleEscape(sys, game, e, now);
          sys.RemoveEscapee(e);
        } else {
          if (now - e.at) > CBConfig.EscapeTimeoutSeconds() {
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
  if IsDefined(e.puppet) {
    let already = CBFindRivalByBody(sys, e.puppet.GetEntityID());
    if IsDefined(already) {
      let st = sys.GetStats();
      if IsDefined(st) {
        st.rivalsSpared += 1;   // the counter existed and nothing ever incremented it
      }
      let indebted = CBRivalSparedByV(already, content, now, district);
      already.scarMask = already.scarMask | e.scarMask;
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
      if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
        let name = CBRivalDisplayName(content, already);
        if indebted {
          CBShowMessage(game, s"Cyberbane: \(name) owes you one. They will remember that too.", 4.0);
        } else {
          CBShowMessage(game, s"Cyberbane: You let \(name) walk again. They came back worse.", 4.0);
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
    nr.state = EnumInt(ECBRivalState.Hunting);
    if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
      CBShowMessage(game, s"Cyberbane: You left \(CBRivalDisplayName(content, nr)) alive. They will not forget it.", 4.0);
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
  let toasts = IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts;

  // The Rival that was hunting you got away again: it ranks up and comes back meaner.
  if e.wasRival && sys.GetActiveRivalId() > 0 {
    let r = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(r) {
      CBRivalEscaped(r, content, now, district, true);
      r.state = EnumInt(ECBRivalState.Hunting);
      if toasts {
        CBShowMessage(game, s"Cyberbane: \(CBRivalDisplayName(content, r)) slipped away and came back meaner.", 4.0);
      }
    }
    sys.SetActiveRivalId(0);
    let des = GameInstance.GetDynamicEntitySystem();
    if IsDefined(des) {
      des.DeleteTagged(n"CB_Rival");
    }
    return;
  }

  // A regular enemy got away: it becomes a Survivor Rival already on your trail.
  if NotEquals(e.faction, n"") && TDBID.IsValid(e.record) {
    let nr = CBCreateRival(sys, game, e.faction, e.record, n"", ECBRivalSource.Survivor, district, now);
    if IsDefined(nr) {
      nr.scarMask = e.scarMask;
    }
    if IsDefined(nr) {
      nr.state = EnumInt(ECBRivalState.Hunting);
      if toasts {
        CBShowMessage(game, s"Cyberbane: \(CBRivalDisplayName(content, nr)) got away. You have not seen the last of them.", 4.0);
      }
    }
  }
}

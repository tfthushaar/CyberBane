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
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      return;
    }
    if rt.HasSettings() && !rt.GetSettings().rivals {
      return;
    }
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
    return;   // unaffiliated nobodies and MaxTac do not become Rivals
  }

  puppet.cbSparedLogged = true;
  let e = new CBEscapee();
  e.puppet = puppet;
  e.entityId = puppet.GetEntityID();
  e.faction = faction;
  e.record = puppet.GetRecordID();
  e.at = CBGameSeconds(game);
  e.spared = true;
  sys.AddEscapee(e);
}

// Called from OnHit when V has just damaged this puppet.
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

  // Decided once, at low health: some break and run, some fight to the death.
  puppet.cbLowHealthFled = true;
  if intensity <= 0.0 || RandF() > CBConfig.FleeChance() {
    return;
  }

  let b = puppet.GetStimBroadcasterComponent();
  if IsDefined(b) {
    b.TriggerSingleBroadcast(puppet, gamedataStimType.Terror);
  }

  let e = new CBEscapee();
  e.puppet = puppet;
  e.entityId = puppet.GetEntityID();
  e.faction = faction;
  e.record = puppet.GetRecordID();
  e.at = CBGameSeconds(game);
  let des = GameInstance.GetDynamicEntitySystem();
  e.wasRival = IsDefined(des) && des.IsTagged(e.entityId, n"CB_Rival");
  sys.AddEscapee(e);
}

// Resolve pending escapees on the fast tick. Deaths already dropped the ones V caught, so
// anything left that despawned alive or outran V counts as having gotten away.
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
        if gone || (now - e.at) > CBConfig.EscapeTimeoutSeconds() {
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
  if RandF() > CBConfig.RivalChanceSpared() {
    return;   // not everyone you spare makes it personal
  }
  let content = CBContent(game);
  let district = CBEventDistrict(sys, game);
  let nr = CBCreateRival(sys, game, e.faction, e.record, n"", ECBRivalSource.Spared, district, now);
  if IsDefined(nr) {
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
      nr.state = EnumInt(ECBRivalState.Hunting);
      if toasts {
        CBShowMessage(game, s"Cyberbane: \(CBRivalDisplayName(content, nr)) got away. You have not seen the last of them.", 4.0);
      }
    }
  }
}

// Cyberbane - Rival encounters (spec §10, §9.9; spike S-08)
//
// A Rival who is hunting you can actually turn up. On the slow tick, if one of your
// hunting Rivals is off cooldown and you are not already fighting, there is a chance it
// spawns near you (behind, out of view) wearing its captured record and appearance,
// tagged CB_Rival so it starts hostile and can be swept away. One Rival at a time; it is
// time-despawned if you never engage. Encounter outcomes (killed V / escaped / slain) are
// handled by the existing Rival transitions when the fight actually happens.

public func CBRivalEncounterTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
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

  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let now = CBGameSeconds(game);
  let cd = sys.GetCooldowns();

  // Retire a Rival who has been left standing around too long (twice a squad's patience).
  if IsDefined(cd) && des.IsPopulated(n"CB_Rival")
     && (now - cd.lastRivalEncounterAt) > CBConfig.HitSquadDespawnMinutes() * 120.0 {
    des.DeleteTagged(n"CB_Rival");
    sys.SetActiveRivalId(0);
  }

  if des.IsPopulated(n"CB_Rival") {
    return;   // one Rival encounter at a time
  }
  // Leave a gap between encounters so a Rival catching up stays an event, not an ambush loop.
  if IsDefined(cd) && cd.lastRivalEncounterAt > 0.0
     && (now - cd.lastRivalEncounterAt) < CBConfig.SecondsPerHour() * CBConfig.RivalEncounterCooldownHours() {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || player.IsInCombat() {
    return;
  }

}

// How many Rivals you are allowed to be carrying at once.
public func CBRivalCap() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    return rt.GetSettings().maxRivals;
  }
  return CBConfig.RivalMaxActiveHardCap();
}

public func CBRivalsAtCap(sys: ref<CyberbaneSystem>) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  return sys.CountActiveRivals() >= CBRivalCap();
}

// How long this Rival takes to find you, in fast ticks. Higher rank, better information.
//
// At the cap no new Rival can be created, so the queue would otherwise just sit there: the
// only way to make room is to put the existing ones down, and they have to turn up for that
// to be possible. So they come at you faster until you have cleared some.
public func CBRivalHuntTicksFor(rank: Int32, atCap: Bool) -> Int32 {
  let t = Max(CBConfig.RivalHuntTicksMin(),
              CBConfig.RivalHuntTicksBase() - rank * CBConfig.RivalHuntTicksPerRank());
  if atCap {
    t = Max(CBConfig.RivalHuntTicksMin() / 2, RoundF(Cast<Float>(t) * CBConfig.RivalCapHurryMult()));
  }
  return t;
}

// Ticks until this Rival turns up, or 0 when it is not counting down.
public func CBRivalHuntRemaining(r: ref<CBRival>) -> Int32 {
  if !IsDefined(r) {
    return 0;
  }
  return r.huntTicks;
}

// Drive the hunt countdown, once per fast tick.
//
// Rivals used to arrive on a dice roll taken every slow tick, which meant one might appear in
// seconds or never, and there was nothing to show the player because nothing was actually
// scheduled. Each hunting Rival now has a real countdown, the Hub shows it, and the spawn
// lands the moment it reaches zero.
//
// Crash safety: this only reads and writes our own persisted state and calls CBSpawnGroup,
// which already refuses while the world is unsettled. It is bounded by the Rival cap (15).
public func CBRivalHuntTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
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
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  // One Rival in the world at a time, and never on top of a fight already in progress.
  let busy = des.IsPopulated(n"CB_Rival");
  let player = GetPlayer(game);
  let inCombat = !IsDefined(player) || player.IsInCombat();

  let now = CBGameSeconds(game);
  let atCap = CBRivalsAtCap(sys);
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && TDBID.IsValid(r.recordID)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      if r.huntTicks <= 0 {
        r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);   // start the clock
      } else {
        r.huntTicks -= 1;
        if r.huntTicks <= 0 {
          if busy || inCombat {
            // Hold at the door rather than losing the appointment entirely.
            r.huntTicks = CBConfig.RivalHuntRetryTicks();
          } else {
            CBSpawnRival(sys, game, r, now);
            r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);
            return;   // one arrival per tick
          }
        }
      }
    }
  }
}

func CBSpawnRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Void {
  // Spawn close and behind so the Rival perceives V right away and gives chase.
  let spawned = CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival", CBConfig.RivalSpawnDistance());
  if spawned <= 0 {
    return;
  }
  r.state = EnumInt(ECBRivalState.Hunting);   // it is actively hunting you now
  r.lastSeenAt = now;
  sys.SetActiveRivalId(r.id);                 // track it for escape / slain handling
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastRivalEncounterAt = now;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    let content = CBContent(game);
    let name = IsDefined(content) ? CBRivalDisplayName(content, r) : "A rival";
    CBShowMessage(game, s"Cyberbane: \(name) has caught up with you.", 4.0);
  }
  CBLog.Info(n"Spawn", s"Rival encounter spawned (id \(r.id)).");
}

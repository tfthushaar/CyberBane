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
  let player = GetPlayer(game);

  // Retire a Rival who has been left standing around too long.
  //
  // This used to run at HitSquadDespawnMinutes * 120 in-game seconds, which is about ten real
  // seconds: a Rival was being untagged almost as soon as they arrived. If the engine then
  // could not destroy the puppet because V was fighting it, the body stayed in the world with
  // no tag, the kill was never attributed, and the same Rival returned forever.
  //
  // Now it is a sensible stretch, and it never fires while V is in a fight.
  let fighting = IsDefined(player) && player.IsInCombat();
  if IsDefined(cd) && !fighting && des.IsPopulated(n"CB_Rival")
     && (now - cd.lastRivalEncounterAt) > CBConfig.RivalRetireGameSeconds() {
    // You got away from them, and that has to count.
    //
    // Retiring simply deleted the Rival and said nothing, so running from one was worth
    // exactly nothing: they vanished, their hunt clock restarted, and a short while later the
    // same person reappeared behind you. With no way to escape, the only way to resolve a
    // Rival was to kill them, which is the one outcome that stops them ever being promoted -
    // the nemesis system quietly reduced to a respawning nuisance.
    //
    // Losing them now promotes them and buys real time before they find you again.
    let got = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(got) {
      got.encounters += 1;
      CBPromoteRival(got, CBContent(game), now);
      got.huntTicks = CBConfig.RivalAfterEscapeTicks();
      let rtEsc = CyberbaneRuntime.Get();
      if IsDefined(rtEsc) && rtEsc.HasSettings() && rtEsc.GetSettings().toasts {
        let whoName = CBRivalDisplayName(CBContent(game), got);
        CBShowMessage(game, s"Cyberbane: you lost \(whoName). They will be better prepared next time.", 4.0);
      }
      CBLog.Info(n"Rivals", s"Player escaped rival id=\(got.id); promoted to rank \(got.rank).");
    }
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
  // Spread them out. This was purely a function of rank, so every Rival of the same rank got
  // the same countdown to the second and they all queued up to arrive together, which reads
  // as a scripted wave rather than as separate people with separate grudges. The jitter is
  // generous on purpose: being hunted should feel irregular.
  let jitter = CBConfig.RivalHuntJitterTicks();
  if jitter > 0 {
    t += RandRange(0, jitter);
  }
  return t;
}

// Advance the countdowns without touching the world.
//
// Called from the settle window, when the engine is busy and no native query is safe. Every
// line here reads or writes Cyberbane's own fields and nothing else - no entity handles, no
// systems, no spawn. A clock that reaches zero in here simply waits at zero, and the first
// settled tick does the arriving.
public func CBTickClocksOnly(sys: ref<CyberbaneSystem>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  sys.TickDownPendingApex();
  sys.TickDownPendingSquad();
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && (r.state == EnumInt(ECBRivalState.Active)
                        || r.state == EnumInt(ECBRivalState.Hunting)) {
      if r.huntTicks <= 0 {
        // Start it here too, or a Rival created during a busy stretch would sit at zero and
        // the Hub would read "any moment" for the rest of the session.
        r.huntTicks = CBRivalHuntTicksFor(r.rank, false);
      } else {
        r.huntTicks -= 1;
      }
    }
  }
}

// Is the body we queued for this Rival actually in the world?
//
// Deliberately asks the world rather than trusting the spawn call's return value, which only
// ever meant "the request was accepted".
public func CBRivalBodyPresent(game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || !EntityID.IsDefined(r.spawnedEntityId) {
    return false;
  }
  return IsDefined(GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet);
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
  // Never walk into a stealth job. Arriving mid-infiltration starts a fight the player was
  // deliberately avoiding, and the arrival alerts the guards being slipped past.
  let quietWork = CBStealthEncounterNearby(sys, game);

  let now = CBGameSeconds(game);
  let atCap = CBRivalsAtCap(sys);
  let rivals = sys.GetRivals();
  // Why nobody can arrive right now, if that is the case. Recorded so the Hub can say so
  // instead of showing a countdown that is not counting.
  //
  // This is the fix for the frozen timer. The clock used to keep running while an arrival was
  // impossible, hit zero, get reset to the retry interval, run down again and reset again -
  // for every Rival at once, because all three blockers are global. The Hub, sampling that at
  // render time, showed every Rival pinned at the same small number forever. A held clock has
  // to actually stop.
  let hold = CBHoldNone();
  if quietWork {
    hold = CBHoldQuietWork();
  } else {
    if busy {
      hold = CBHoldOneAlreadyOut();
    } else {
      if inCombat {
        hold = CBHoldInCombat();
      }
    }
  }
  if hold != CBHoldNone() {
    sys.SetHuntHoldReason(hold);
    return;   // everybody waits, and every clock stays where it is
  }

  // Written once, at the end, rather than up here. Setting it before the loop overwrote any
  // "nowhere to put them" recorded by the previous tick's spawn attempt, so that reason never
  // survived long enough for the Hub to draw it and an unplaceable arrival looked like an
  // ordinary countdown.
  let failedToPlace = false;
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && TDBID.IsValid(r.recordID)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      // Waiting to see whether the one we queued actually turned up.
      //
      // This is the gap the reference mods both close and Cyberbane did not: CreateEntity
      // hands back a valid EntityID even when the engine goes on to decline the spawn, so
      // "queued" was being treated as "arrived". A Rival that never materialised stayed
      // marked as Hunting, held the active slot, and blocked every other Rival behind the
      // one-at-a-time rule - which is exactly a Hub full of people who are due and never come.
      if r.arrivalCheckTicks > 0 {
        r.arrivalCheckTicks -= 1;
        if r.arrivalCheckTicks <= 0 {
          if CBRivalBodyPresent(game, r) {
            r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);   // they are really here
          } else {
            CBLog.Info(n"Spawn", s"Rival \(r.id) was queued but never arrived; trying again.");
            r.state = EnumInt(ECBRivalState.Active);
            if sys.GetActiveRivalId() == r.id {
              sys.SetActiveRivalId(0);
            }
            r.huntTicks = CBConfig.RivalHuntRetryTicks();
            failedToPlace = true;
          }
        }
      } else {
        if r.huntTicks <= 0 {
          r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);   // start the clock
        } else {
          r.huntTicks -= 1;
          if r.huntTicks <= 0 {
            if CBSpawnRival(sys, game, r, now) {
              r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);
              sys.SetHuntHoldReason(CBHoldNone());
              return;   // one arrival per tick
            }
            // The timer ran out and they still could not be put down: V is somewhere with no
            // room for them, no navmesh, or the world is still streaming. The appointment is
            // kept and retried shortly, but the Hub is told, because a fresh twenty second
            // countdown here would be a lie - nothing is counting down, it is retrying.
            failedToPlace = true;
            r.huntTicks = CBConfig.RivalHuntRetryTicks();
          }
        }
      }
    }
  }
  sys.SetHuntHoldReason(failedToPlace ? CBHoldNoRoom() : CBHoldNone());
}

func CBSpawnRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Bool {
  // Spawn close and behind so the Rival perceives V right away and gives chase.
  let body: EntityID;
  let spawned = CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival", CBConfig.RivalSpawnDistance(), body);
  if spawned <= 0 {
    return false;   // refused: unsettled world, or nowhere outside a safe area to stand
  }
  // Remember which body is theirs. The CB_Rival tag can be cleared out from under us by the
  // retire sweep, and when that happened the kill stopped counting: the Rival was never marked
  // slain, never replaced, and came back again and again.
  r.spawnedEntityId = body;
  r.arrivalCheckTicks = CBConfig.RivalArrivalCheckTicks();   // confirm they really showed up
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
  return true;
}

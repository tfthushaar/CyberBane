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
  // This used to run at the old crew despawn time * 120 in-game seconds, which is about ten real
  // seconds: a Rival was being untagged almost as soon as they arrived. If the engine then
  // could not destroy the puppet because V was fighting it, the body stayed in the world with
  // no tag, the kill was never attributed, and the same Rival returned forever.
  //
  // Now it is a sensible stretch, and it never fires while V is in a fight.
  //
  // Nor while the hunt has eyes on V. V being out of combat for one moment - reloading behind a
  // wall, sneaking round to flank - is not the encounter having gone stale, and the hunt is what
  // knows whether the Rival is still on V (Spawn/Hunt.reds). This is the backstop for a Rival
  // nobody is engaging, which is exactly when the hunt is not Located.
  let fighting = (IsDefined(player) && player.IsInCombat()) || sys.GetHuntState() == CBHuntLocated();
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
    CBRivalEscapedByPlayer(sys, game);
    CBDeleteTaggedSafe(game, n"CB_Rival", false, true);
    sys.SetActiveRivalId(0);
  }

  // One Rival encounter at a time, counting only a Rival still able to hunt. Same reasoning
  // as the busy test further down: a body, or somebody unconscious, is not an encounter.
  if des.IsPopulated(n"CB_Rival") && CBLiveRivalPresent(sys, game) {
    return;
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
      // Only ever counted down. huntTicks is a cooldown now, not a countdown to arrival, so
      // zero means "eligible" and setting it here would quietly make an escaped Rival wait
      // all over again every time the world streamed.
      if r.huntTicks > 0 {
        r.huntTicks -= 1;
      }
    }
  }
}

// You got away from the Rival who was after you, and that has to count.
//
// Retiring used to delete them and say nothing, so running was worth exactly nothing: they
// vanished, their clock restarted, and the same person turned up again shortly after. With no
// way to escape, the only way to resolve a Rival was to kill them - the one outcome that stops
// them ever being promoted, which hollowed the whole nemesis idea out.
//
// Called from two places now: the retire sweep, and the moment the hunters give up because you
// outran them. Both mean the same thing to the person doing the hunting.
public func CBRivalEscapedByPlayer(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let got = sys.FindRivalById(sys.GetActiveRivalId());
  if !IsDefined(got) {
    return;
  }
  let content = CBContent(game);
  // Where they were standing when V shook them off: both callers run this before the body is
  // removed, so it is still there to read if it is still in the world at all, and where it was
  // last seen standing if it is not (Rivals/Whereabouts.reds).
  let lostBody: ref<ScriptedPuppet>;
  if EntityID.IsDefined(got.spawnedEntityId) {
    lostBody = GameInstance.FindEntityByID(game, got.spawnedEntityId) as ScriptedPuppet;
  }
  CBNoteRivalSeen(sys, game, got, lostBody);
  got.encounters += 1;
  CBPromoteRival(got, content, CBGameSeconds(game));
  got.huntTicks = CBConfig.RivalAfterEscapeTicks();
  // From them, not about them: the person you just lost is the one who should be telling you
  // it is not over.
  if CBToastsOn() && IsDefined(content) {
    CBPhoneSendTinted(game, CBRivalDisplayName(content, got), CBRivalLostLine(got), CBHudRed());
  }
  CBLog.Info(n"Rivals", s"Player escaped rival id=\(got.id); promoted to rank \(got.rank).");
}

// Is any Rival actually alive and in the world right now?
//
// Walks only our own recorded bodies, so it cannot be fooled by a tag left on a corpse or by
// anything else in the world carrying the same tag.
public func CBLiveRivalPresent(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && r.state == EnumInt(ECBRivalState.Hunting)
       && EntityID.IsDefined(r.spawnedEntityId) {
      let body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
      if CBStillStanding(body) {
        return true;
      }
    }
  }
  return false;
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
  // "Is a Rival out?" means a living one.
  //
  // This was `des.IsPopulated(n"CB_Rival")`, which counts tagged entities - and the tag stays
  // on the body after death until the retire sweep clears it, which is a couple of minutes
  // away and never runs during combat. So putting a Rival down blocked every other Rival
  // behind it, and the Hub showed the whole list stuck on "waiting their turn" with nothing
  // actually out there. A corpse is not somebody hunting you.
  let busy = des.IsPopulated(n"CB_Rival") && CBLiveRivalPresent(sys, game);
  let player = GetPlayer(game);
  let inCombat = !IsDefined(player) || player.IsInCombat();
  // Never walk into a stealth job. Arriving mid-infiltration starts a fight the player was
  // deliberately avoiding, and the arrival alerts the guards being slipped past.
  let quietWork = CBStealthEncounterNearby(sys, game);

  let now = CBGameSeconds(game);
  let atCap = CBRivalsAtCap(sys);
  let rivals = sys.GetRivals();
  // NOTE: the scheduling that used to live here now belongs to Spawn/Queue.reds. Every Rival
  // running its own countdown meant several clocks for encounters that could never all happen,
  // and no way to say which one was actually next. What remains here is confirming that a
  // Rival the queue sent was really placed, which is about one specific spawn rather than
  // about whose turn it is.
  //
  // Why nobody can arrive right now, if that is the case. Recorded so the Hub can say so
  // instead of showing a countdown that is not counting.
  //
  // This is the fix for the frozen timer. The clock used to keep running while an arrival was
  // impossible, hit zero, get reset to the retry interval, run down again and reset again -
  // for every Rival at once, because all three blockers are global. The Hub, sampling that at
  // render time, showed every Rival pinned at the same small number forever. A held clock has
  // to actually stop.
  let hold = CBHoldNone();
  if sys.GetStoryHold() != CBStoryNone() {
    hold = CBHoldStory();   // the story has the stage (Core/StoryHold.reds)
  } else {
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
          let byCar = sys.GetRivalCarPending() == r.id;
          if byCar {
            sys.SetRivalCarPending(0);
          }
          if CBRivalBodyPresent(game, r) {
            r.huntTicks = CBRivalHuntTicksFor(r.rank, atCap);   // they are really here
          } else {
            // A car that never delivered them: they walk in next time rather than waiting on
            // the same road again.
            if byCar {
              sys.SetRivalCarFailed(r.id);
            }
            CBLog.Info(n"Spawn", s"Rival \(r.id) was queued but never arrived; trying again.");
            r.state = EnumInt(ECBRivalState.Active);
            if sys.GetActiveRivalId() == r.id {
              sys.SetActiveRivalId(0);
            }
            r.huntTicks = CBConfig.RivalHuntRetryTicks();
            failedToPlace = true;
          }
        }
      }
    }
  }
  sys.SetHuntHoldReason(failedToPlace ? CBHoldNoRoom() : CBHoldNone());
}

func CBSpawnRival(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float) -> Bool {
  // By car, when there is a road and the dice say so: the city's own chase drives them at V,
  // and they get out when the car reaches V or keep chasing if V is driving.
  if CBRivalByCar(sys, game, r) {
    let noBody: EntityID;   // the body is filled in when the city's spawn is adopted
    r.spawnedEntityId = noBody;
    r.arrivalCheckTicks = CBConfig.RivalCarArrivalCheckTicks();
    CBRivalOnTheirWay(sys, game, r, now, true);   // their people are in the car with them
    CBLog.Info(n"Spawn", s"Rival encounter on its way by car (id \(r.id)).");
    return true;
  }
  // Closer than a crew, behind V and out of sight. They start from the tip their warning gave and
  // search; the fight starts when they find V (Spawn/Hunt.reds), not the moment they are placed.
  let body: EntityID;
  let spawned = CBSpawnGroup(game, r.recordID, r.appearance, 1, n"CB_Rival", CBConfig.RivalSpawnDistance(), body);
  if spawned <= 0 {
    // Say why. This path was silent, so a Rival that could not be placed produced a Hub
    // reading "any moment" for as long as the player stood somewhere unsuitable and nothing
    // anywhere said what was wrong. A refusal that names itself is the difference between a
    // one-line answer and another evening of guessing.
    let why = CBBlockLabel(CBLastSpawnBlock());
    if StrLen(why) == 0 {
      why = "no reason recorded";
    }
    CBLog.Info(n"Spawn", s"Rival \(r.id) could not be placed: \(why).");
    return false;
  }
  // Remember which body is theirs. The CB_Rival tag can be cleared out from under us by the
  // retire sweep, and when that happened the kill stopped counting: the Rival was never marked
  // slain, never replaced, and came back again and again.
  r.spawnedEntityId = body;
  r.arrivalCheckTicks = CBConfig.RivalArrivalCheckTicks();   // confirm they really showed up
  CBRivalOnTheirWay(sys, game, r, now);
  CBLog.Info(n"Spawn", s"Rival encounter spawned (id \(r.id)).");
  return true;
}

// Should this Rival drive in, and if so, has the city taken the request?
//
// Only through the city's chase: it is the path that hands the body back to Cyberbane through
// adoption, which is what ties the body to the Rival so their death and their escape count. A
// Rival whose last car never delivered them walks in this time, so a road that looks usable and
// is not cannot keep a Rival away.
func CBRivalByCar(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(sys) || !IsDefined(r) {
    return false;
  }
  if sys.GetRivalCarFailed() == r.id {
    sys.SetRivalCarFailed(0);
    return false;
  }
  if !CBVehicleArrivalAllowed(game) || RandF() >= CBConfig.RivalCarChance() {
    return false;
  }
  if sys.HasPendingArrival() || sys.IsAdoptionOpen() || sys.GetTopUpWanted() > 0 {
    return false;
  }
  // Active and pending before the car is sent, so the seat that is created for them knows
  // whose body it is (Spawn/Arrival.reds, CBOnArrivalCarAttached).
  let previous = sys.GetActiveRivalId();
  sys.SetActiveRivalId(r.id);
  sys.SetRivalCarPending(r.id);
  // Their own people ride with them. They used to be walked in the moment the car set off, so a
  // Rival "coming by car" turned up as a group on foot first and a car later, if at all - and if
  // the car never delivered, the walk-in that followed brought a second set. The Rival takes the
  // first seat, their people the rest, and whoever the car cannot seat walks in now.
  let escorts = CBRivalEscortCount(sys, r);
  let fs = sys.FindFaction(r.faction);
  let sent = false;
  if escorts > 0 && IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
    sent = CBSpawnVehicleArrival(sys, game, r.faction, fs.sampleRecord, 1 + escorts, n"CB_Escort",
                                 r.recordID, n"CB_Rival");
  } else {
    escorts = 0;
    sent = CBSpawnVehicleArrival(sys, game, r.faction, r.recordID, 1, n"CB_Rival", TDBID.None(), n"");
  }
  if !sent {
    sys.SetRivalCarPending(0);
    sys.SetActiveRivalId(previous);
    return false;
  }
  let seated = Max(0, Min(sys.GetLastCarSeats(), 1 + escorts) - 1);
  if escorts > seated {
    let walker: EntityID;
    CBSpawnGroup(game, fs.sampleRecord, n"", escorts - seated, n"CB_Escort",
                 CBConfig.RivalSpawnDistance() + 4.0, walker);
  }
  return true;
}

// How many of their own people a Rival brings. Somebody who runs people does not come alone: a
// Pack Leader brings their own, and so does whoever holds a chair in the gang's crew - the leader
// brings two, a lieutenant one.
func CBRivalEscortCount(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> Int32 {
  let escorts = CBRivalHasTrait(r, n"PackLeader") ? CBConfig.PackLeaderEscort() : 0;
  let role = CBRivalRole(sys, r);
  if role == CBRoleLeader() {
    escorts = Max(escorts, CBConfig.LeaderEscort());
  } else {
    if role == CBRoleLieutenant() {
      escorts = Max(escorts, CBConfig.LieutenantEscort());
    }
  }
  return escorts;
}

// Everything that is true of a Rival the moment they set off, whichever way they are coming.
//
// `byCar`: their people are already in the car with them (CBRivalByCar), so nobody walks in here.
func CBRivalOnTheirWay(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, now: Float,
                       opt byCar: Bool) -> Void {
  // Their people walk in as escorts, so they fight, chase and give up with the encounter and
  // never hold up the crew lane. Only as many as are not already out: a Rival whose car never
  // delivered them walks in on the next try, and whoever of theirs did get here is still here.
  //
  // Counted with CBCountLiveOrSpawning, which includes anybody the engine has been asked for and
  // has not finished building. The standing-only count misses exactly the people this test is
  // about: an escort queued a moment ago by this same path is not standing yet, so it read as
  // absent and a second one was sent for it - the group arriving over strength and eating room
  // under MaxLiveSpawns. Same reason CBSpawnGroup shares its room by the or-spawning count.
  let escorts = 0;
  if !byCar {
    escorts = CBRivalEscortCount(sys, r) - CBCountLiveOrSpawning(game, n"CB_Escort");
  }
  if escorts > 0 {
    let fs = sys.FindFaction(r.faction);
    if IsDefined(fs) && TDBID.IsValid(fs.sampleRecord) {
      let escort: EntityID;
      CBSpawnGroup(game, fs.sampleRecord, n"", escorts, n"CB_Escort",
                   CBConfig.RivalSpawnDistance() + 4.0, escort);
    }
  }
  r.state = EnumInt(ECBRivalState.Hunting);   // it is actively hunting you now
  r.lastSeenAt = now;
  sys.SetActiveRivalId(r.id);                 // track it for escape / slain handling
  let cd = sys.GetCooldowns();
  if IsDefined(cd) {
    cd.lastRivalEncounterAt = now;
  }
  // No text here. They already said they were coming (CBRivalWarning), and they say they have
  // found you when they actually lay eyes on you (Spawn/Hunt.reds, CBHuntOnLocated). A third
  // message on arrival said "found you" before anybody had.
}

// What a Rival texts when they have found you. Chosen by how they came to be one, so the one
// you let go sounds different from the one who put you down.
func CBRivalArrivalLine(r: ref<CBRival>) -> String {
  if r.killedV > 0 {
    return "Found you again. You know how this went last time.";
  }
  if r.sparedByV > 0 {
    return "You should have finished it when you had the chance. I'm close.";
  }
  if r.escapes > 0 {
    return "You let me walk. I came back. I'm close.";
  }
  return "Found you. Look around.";
}

// What a Rival texts when V has given them the slip.
func CBRivalLostLine(r: ref<CBRival>) -> String {
  if r.killedV > 0 {
    return "Run, then. I found you once and I will find you again.";
  }
  if r.rank >= 4 {
    return "Every time you run I get better at this. Think about that.";
  }
  switch RandRange(0, 3) {
    case 0: return "Lost me. For now.";
    case 1: return "Keep running. I know where you sleep.";
    default: return "Next time I bring more.";
  }
}

// What a Rival texts after getting away from V.
func CBRivalGotAwayLine(r: ref<CBRival>) -> String {
  if CBRivalHasTrait(r, n"OldWound") {
    return "Same place as last time. It still hurts. You are going to pay for that.";
  }
  if CBRivalHasTrait(r, n"Scarred") {
    return "You left a mark. I will remember it every time I look.";
  }
  return "Close. Not close enough. See you soon.";
}

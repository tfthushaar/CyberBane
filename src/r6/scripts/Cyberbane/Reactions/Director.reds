// Cyberbane - Reaction Director (spec §9.1)
//
// Runs on the fast tick: prunes the registry, then evaluates up to NpcEvalPerTick
// nearby NPCs. For each it runs the Safety Gate, a per-spawn recognition roll, and
// (first reaction output) an overheard whisper when V is notable and not fighting.
// Gang behaviour, civilian fear and morale layer onto this evaluation next.

// Per-puppet reaction scratch state (per spawn).
@addField(ScriptedPuppet)
public let cbRecoState: Int32;   // 0 = unrolled, 1 = recognized, 2 = not recognized

@addField(ScriptedPuppet)
public let cbWhispered: Bool;

// Set true when Cyberbane made this NPC hostile-on-sight (for revert, spec §16.4).
@addField(ScriptedPuppet)
public let cbHostileByCyberbane: Bool;

// The settled tick Cyberbane turned this NPC on V (TrackHostile), so a grudge that has since cooled can put them back
// once their fight is over.
@addField(ScriptedPuppet)
public let cbHostileTick: Int32;

// Set true once a Vendetta gang member has given V a spoken warning (spec §9.3).
@addField(ScriptedPuppet)
public let cbGangWarned: Bool;

// The settled tick this NPC warned V, so the warning is a beat V can use, not a formality.
@addField(ScriptedPuppet)
public let cbGangWarnTick: Int32;

// The tick this NPC's attitude towards V was last read for NoteForeignHostility.
@addField(ScriptedPuppet)
public let cbAttitudeReadTick: Int32;

// Whether this NPC is too afraid of V to act on their gang's vendetta: 0 not decided yet, 1 holds back, 2 stands and
// fights. Decided once, the first time it matters (CBHoldBackChance).
@addField(ScriptedPuppet)
public let cbHoldState: Int32;

// Whether Cyberbane has calmed this NPC towards V when the game had them hostile (CBCalmTowardsV): 0 not, 1 they stood
// down to V or struck a deal with V (for as long as they are about), 2 V's toll with their gang (until it runs out).
@addField(ScriptedPuppet)
public let cbCalmedBy: Int32;

// Somebody who has stood down to V does not draw on V, by the game's rules as well as Cyberbane's.
public func CBCalmTowardsV(game: GameInstance, npc: wref<ScriptedPuppet>, how: Int32) -> Bool {
  if !IsDefined(npc) || !npc.IsAttached() || npc.IsDead() || npc.cbDamagedByPlayer || CBNpcInCombat(npc)
     || CBPlayerInHostileZone(game) {
    return false;
  }
  let faction = CBClassifyFaction(npc);
  if Equals(faction, n"NCPD") || Equals(faction, n"MaxTac") || Equals(faction, n"Police") {
    return false;
  }
  let player = GetPlayer(game);
  let agent = npc.GetAttitudeAgent();
  let pagent = IsDefined(player) ? player.GetAttitudeAgent() : null;
  if !IsDefined(agent) || !IsDefined(pagent) {
    return false;
  }
  // A stand-down is kept from now on, whatever they are to V this moment: should the game turn them later (their
  // squad's attitude, another mod), the Director calms them again (KeepCalm). A deal for good outlasts a toll.
  if how == 1 {
    npc.cbCalmedBy = 1;
  }
  if !Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
    return false;
  }
  // The toll marks only somebody whose hostility it lifted: they get it back when the toll runs out, nobody else does.
  if how == 2 && npc.cbCalmedBy == 0 {
    npc.cbCalmedBy = 2;
  }
  CBTrace("attitude: stood down to V; neutral, and what they saw forgotten");
  agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
  let senses = npc.GetSensesComponent();
  if IsDefined(senses) {
    senses.ResetDetection(player.GetEntityID());
  }
  npc.cbHostileByCyberbane = false;   // whatever Cyberbane set is undone by this as well
  CBCalmTowardCompanions(CyberbaneSystem.Get(game), npc);
  return true;
}

// Talked down, leaned on until they folded, frightened into V's crew or into informing: they hold back from V from now
// on (cbHoldState 1, CBHoldsBackFromV), and stand down by the game's rules too.
public func CBStandDownFromV(game: GameInstance, npc: wref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) {
    return;
  }
  npc.cbHoldState = 1;
  if CBCalmTowardsV(game, npc, 1) {
    CBLog.Info(n"Talk", "Somebody the game had hostile to V stood down: neutral to V now, and what they had seen of V forgotten.");
  }
}


// The tick this NPC last failed the Director's checks (the Safety Gate, a job site, one of ours), so it is passed over
// for a few ticks rather than asked again every second. 0 = never failed.
@addField(ScriptedPuppet)
public let cbGateFailTick: Int32;

func CBWarningsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().warnings;
}

// One of the people Cyberbane sent. Every spawn carries this tag (Spawn/Spawner.reds, Arrival.reds).
func CBSentByUs(des: ref<DynamicEntitySystem>, npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(des) && des.IsTagged(npc.GetEntityID(), n"Cyberbane");
}

// One of Cyberbane's people who is here for V: a crew, an apex squad, a Rival and their people, a scout, a convoy.
func CBSentAfterV(des: ref<DynamicEntitySystem>, npc: wref<ScriptedPuppet>) -> Bool {
  if !CBSentByUs(des, npc) {
    return false;
  }
  let id = npc.GetEntityID();
  if des.IsTagged(id, n"CB_Patrol") {
    return false;
  }
  // A crew lying in wait (Spawn/HuntGrows.reds) shares the street's rules for being released from a fight, so it is on
  // that list, but it is a crew sent after V like any other: one waiting by V's job could be walked up to and chatted
  // with like a passer-by.
  if des.IsTagged(id, n"CB_Ambush") {
    return true;
  }
  for tag in CBStreetTags() {
    if des.IsTagged(id, tag) {
      return false;
    }
  }
  return true;
}

public class CBReactionDirector {
  private let m_whisperCooldownTicks: Int32;
  // When each gang's spoken warning was last said (game seconds), so the same gang does not say it to V every minute
  // (CBConfig.GangWarnLineHours). Session only.
  private let m_warnSaidFaction: array<CName>;
  private let m_warnSaidAt: array<Float>;
  // Street Sense detection, resolved once and kept: 0 unknown, 1 present, 2 absent. The
  // scan allocates, and whispers are decided every tick, so it must not run every tick.
  private let m_streetSense: Int32;
  // NPCs whose attitude Cyberbane overrode, tracked so the kill switch can revert them.
  private let m_hostileNpcs: array<wref<ScriptedPuppet>>;
  // Where in the registry the last tick's walk stopped, so the next one carries on from there.
  private let m_cursor: Int32;

  public func Tick(game: GameInstance) -> Void {
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return;
    }
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && !rt.IsEnabled() {
      this.RevertAllHostile(game);   // kill switch: undo attitude overrides (§16.3/§16.4)
      return;
    }
    let reg = sys.GetRegistry();
    if !IsDefined(reg) {
      return;
    }
    reg.Prune();
    // Cleared streets (Spawn/ClearedStreets.reds): every few ticks.
    if sys.GetTickCount() % 3 == 0 {
      CBClearedStreetsTick(sys, game);
    }
    // Hangouts (Spawn/Hangouts.reds): a gang's people somewhere to be found on its own streets. A gang's home is
    // learned when V stands in it (Spawn/GangHomes.reds).
    if sys.GetTickCount() % 2 == 0 {
      CBGangHomeTick(sys, game);
    }
    if sys.GetTickCount() % 5 == 0 {
      CBHangoutTick(sys, game);
    }
    let pruneFrom = GetPlayer(game);
    if IsDefined(pruneFrom) {
      reg.PruneFar(pruneFrom.GetWorldPosition(), CBConfig.RegistryKeepRadius());
    }

    // Somewhere the game calls a safe area - an apartment, a clinic, a bar, a memorial.
    // Nobody there reacts to V, however frightening V is (spec §16).
    if sys.IsInSafeZone() {
      return;
    }
    // Never during a conversation or a scene, never while the story has the stage (a companion at V's side, a fight the
    // story is staging), and never on a job when V has asked Cyberbane to stay out of quest areas.
    if CBPlayerInScene(game) || sys.IsInQuestArea() || sys.GetStoryHold() != CBStoryNone() {
      // Anybody Cyberbane already turned hostile who is standing at the job, or who turns out to be
      // somebody the story wrote, goes back to how the game had them. Hostility set before V took
      // the job must not carry into it.
      this.RevertHostileAtJob(game, sys);
      // And while the story has the stage, everybody Cyberbane turned who is not already fighting: a ganger set off a
      // minute ago must not walk into River's scene.
      if sys.GetStoryHold() != CBStoryNone() {
        this.RevertHostileNotFighting(game);
      }
      return;
    }
    // Near an objective V is not tracking the street goes on reacting: the quest area above is the tracked job's, and
    // every NPC standing at any job site is kept out of the loop below by its own check.
    if sys.IsOnJob() {
      this.RevertHostileAtJob(game, sys);
    }
    // The NCPD after V (CBPoliceOnV): the gangs lie low. Whoever Cyberbane turned on V and is not fighting stands down,
    // and nobody is turned below until the stars are gone.
    let policeOnV = CBPoliceOnV(sys);
    // Nor while Adam Smasher is after V (Compat/SmasherEncounters.reds): one fight at a time.
    let smasherOut = CBSmasherEventOn(game);
    if policeOnV {
      this.RevertHostileNotFighting(game);
    }

    if this.m_whisperCooldownTicks > 0 {
      this.m_whisperCooldownTicks -= 1;
    }
    // Anybody Cyberbane turned on V whose faction it may not turn any more: switched off in Mod Settings since, or the
    // law. Every few ticks, from a list of at most MaxTrackedHostiles.
    if sys.GetTickCount() % CBConfig.SwitchedOffRevertTicks() == 0 {
      this.RevertNotFielding(game, sys);
    }

    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let whispersOn = true;
    let gangOn = true;
    let hostileOnSight = true;
    let civOn = true;
    let civIntensity = 1.0;
    let maxCiv = 6;
    if IsDefined(rt) && rt.HasSettings() {
      let s = rt.GetSettings();
      whispersOn = s.whispers;
      // Street Sense gives crowds their own spoken reactions to V. Ours would talk over
      // them, so it owns being noticed and Cyberbane sticks to being feared.
      if this.m_streetSense == 0 {
        this.m_streetSense = CBDetectStreetSense() ? 1 : 2;
        if this.m_streetSense == 1 {
          CBLog.Info(n"Core", "Street Sense detected; standing Cyberbane's whispers down so the street does not talk over itself.");
        }
      }
      if this.m_streetSense == 1 {
        whispersOn = false;
      }
      gangOn = s.gangReactions;
      hostileOnSight = s.hostileOnSight;
      civOn = s.civReactions;
      civIntensity = s.civIntensity;
      maxCiv = s.maxReactingCivilians;
    }
    // The district's temper, the blood on V, a fight just over (Model/Moment.reds).
    civIntensity *= CBCrowdMomentMult(sys, game);
    let civReacted = 0;
    let playerInCombat = player.IsInCombat();
    // An exchange V is having (Reactions/StreetTalk.reds) is not talked over by the street.
    let talkSys = sys.GetStreetTalk();
    let talking = IsDefined(talkSys) && talkSys.Busy();
    let ppos = player.GetWorldPosition();
    let score = sys.GetScore();
    let dread = score.GetDread();
    // Whether V's face is covered, asked once a tick rather than once for every person looked at: the
    // fear and the whispers below both turn on it, and it cannot change inside the walk.
    let masked = CBPlayerMasked(game);
    let district = sys.GetCurrentDistrict();   // cached; kept off the hot path (crash safety)

    let des = GameInstance.GetDynamicEntitySystem();
    let npcs = reg.GetAll();
    let count = ArraySize(npcs);
    let evaluated = 0;
    // Round the registry, from where the last tick stopped, and only so far each tick.
    let start = this.m_cursor;
    if start < 0 || start >= count {
      start = 0;
    }
    let looked = 0;
    let tick = sys.GetTickCount();
    let now = CBGameSeconds(game);
    let k = 0;
    while k < count && evaluated < CBConfig.NpcEvalPerTick() && looked < CBConfig.NpcLookPerTick() {
      let npc = npcs[(start + k) % count];
      k += 1;
      // Only touch an NPC that is attached and past its warm-up ticks (crash safety during streaming). Cheap distance
      // gate first: the Safety Gate queries the workspot system, so only run it for NPCs actually in range.
      let resting = false;
      if IsDefined(npc) && npc.cbGateFailTick > 0 {
        let failedAgo = tick - npc.cbGateFailTick;
        resting = failedAgo >= 0 && failedAgo < CBConfig.NpcGateRetryTicks();
      }
      if !resting && CBNpcSafe(sys, npc) {
        looked += 1;
        let dist = Vector4.Distance(ppos, npc.GetWorldPosition());
        // Nobody standing at any job site, tracked or not: turning a gig's people hostile or sending them running is
        // the story's business.
        let passes = false;
        if dist <= CBConfig.NpcEvalRadius() {
          passes = !CBSentByUs(des, npc) && CBSafetyGate.CanAffect(npc)
                && !sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.QuestSpawnClearance());
          npc.cbGateFailTick = passes ? 0 : Max(tick, 1);
        }
        if passes {
          evaluated += 1;
          let faction = CBClassifyFaction(npc);
          // One of two gangs at war here, kept for a street clash (Spawn/Clashes.reds). Their own fields only.
          if !npc.IsCrowd() && NotEquals(faction, n"") {
            CBClashNote(sys, npc, faction);
            CBOneOfTheirsGreet(sys, game, faction, dist, tick);   // V is one of theirs
          }

          // Whoever stood down to V stays stood down, and a toll V bought holds for their gang.
          if !npc.IsCrowd() && NotEquals(faction, n"") {
            this.KeepCalm(sys, game, npc, faction, now);
          }

          // Recognition, rolled once per spawn and cached on the puppet (spec §8.7).
          let recognized = CBRecognizes(sys, score, npc, faction, district);

          // Vendetta gangs that recognise V attack on sight (spec §9.3); that overrides
          // any fear. Everyone else - civilians, gangers, cops - can read how dangerous V
          // looks and flee (spec §9.2), capped per tick.
          let turnedHostile = false;
          if !npc.IsCrowd() && gangOn && hostileOnSight && recognized && !policeOnV && !smasherOut {
            turnedHostile = this.TryGangHostile(score, player, npc, faction, tick, dist);
          }
          // Somebody of a gang hostile to V who Cyberbane did not turn, read now and then.
          if !playerInCombat && !turnedHostile && !npc.IsCrowd() && NotEquals(faction, n"")
             && !npc.cbHostileByCyberbane
             && (sys.GetTickCount() - npc.cbAttitudeReadTick) >= CBConfig.ForeignHostileReadTicks() {
            npc.cbAttitudeReadTick = sys.GetTickCount();
            this.NoteForeignHostility(sys, score, player, npc, faction);
          }
          // Never whoever V is talking to or settling on.
          let inTalk = npc.cbTalkHeldTick > 0 && tick - npc.cbTalkHeldTick <= 2;
          if !turnedHostile && civOn && civReacted < maxCiv && !inTalk {
            if CBFearReact(game, score, npc, dist, civIntensity, faction, sys.GetTickCount(),
                           sys.GetContent(), masked, player) {
              civReacted += 1;
            }
          }
          // Behind a mask V is somebody nobody can place, and people talk about that too.
          if whispersOn && !playerInCombat && !talking && (recognized || masked) {
            this.TryWhisper(game, sys, score, npc, dread, dist, faction, recognized);
          }
        }
      }
    }
    this.m_cursor = count > 0 ? (start + k) % count : 0;
  }

  // The stand-down kept (CBCalmTowardsV).
  private func KeepCalm(sys: ref<CyberbaneSystem>, game: GameInstance, npc: wref<ScriptedPuppet>, faction: CName,
                        now: Float) -> Void {
    if npc.cbDamagedByPlayer {
      if npc.cbCalmedBy > 0 || npc.cbHoldState == 1 {
        npc.cbCalmedBy = 0;
        npc.cbHoldState = 2;
      }
      return;
    }
    let toll = sys.TollActive(faction, now);
    if npc.cbCalmedBy == 2 && !toll {
      npc.cbCalmedBy = 0;
      let player = GetPlayer(game);
      let agent = npc.GetAttitudeAgent();
      let pagent = IsDefined(player) ? player.GetAttitudeAgent() : null;
      if IsDefined(agent) && IsDefined(pagent) && !CBNpcInCombat(npc) && npc.cbHoldState != 1 && !npc.cbTruceHeld
         && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Neutral) {
        CBTrace("attitude: the toll ran out; back to how the game had them");
        agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
      }
      return;
    }
    if npc.cbHoldState == 1 || npc.cbCalmedBy == 1 {
      CBCalmTowardsV(game, npc, 1);
      return;
    }
    if toll {
      CBCalmTowardsV(game, npc, 2);
    }
  }

  // Vendetta gangs attack a recognized V on sight (spec §9.3). Tracked for revert.
  // Returns true when this NPC is engaging V (hostile or being warned), so the Director
  // knows not to let it flee from fear instead.
  private func TryGangHostile(score: ref<CBScoreEngine>, player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, faction: CName,
                              tick: Int32, dist: Float) -> Bool {
    if Equals(faction, n"") {
      return false;
    }
    // Never the law, and never a faction switched off in Mod Settings.
    if !CBFactionFieldsSquads(faction) {
      return false;
    }
    // Never somebody out of it: hands up, down for V's mercy, in a conversation with V, or standing for a facedown.
    // Asked every pass, a vendetta gang's ganger who had just given up was turned on V again by this.
    if npc.cbSurrendered || npc.cbGaveUp || npc.cbMercyOpen || npc.cbFacedownOpen || npc.cbFacedownHeld || npc.cbFacedownWait
       || npc.cbTruceHeld || (npc.cbTalkPartner && !npc.cbHostileByCyberbane) {
      return false;
    }
    if CBTwrActive() {
      return false;   // They Will Remember owns hostility-on-sight in compat mode (spec §17)
    }
    if !Equals(score.GetPosture(faction), ECBPosture.Vendetta) {
      return false;   // not at war with you - they can still be scared off
    }
    if npc.cbHostileByCyberbane {
      return true;
    }
    // Safe passage bought from one of theirs (Reactions/TalkTopics.reds): their street people let V walk for a few
    // hours.
    let tollSys = CyberbaneSystem.Get(player.GetGame());
    if IsDefined(tollSys) && tollSys.TollActive(faction, CBGameSeconds(player.GetGame())) {
      return false;
    }
    // Afraid of V more than they hate V.
    if CBHoldsBackFromV(CyberbaneSystem.Get(player.GetGame()), npc, faction) {
      return false;
    }
    // They give you one warning before they open fire (spec §9.3), if enabled. The flip
    // to hostile lands on the next evaluation, which reads as a beat of hesitation.
    if CBWarningsOn() && !npc.cbGangWarned {
      npc.cbGangWarned = true;
      npc.cbGangWarnTick = Max(tick, 1);
      // One warning, not one per head.
      if this.m_whisperCooldownTicks <= 0 && this.WarnLineDue(faction, CBGameSeconds(player.GetGame())) {
        this.m_whisperCooldownTicks = this.WhisperCooldownTicks();
        CBShowWhisper(CyberbaneSystem.Get(player.GetGame()), player.GetGame(),
                      faction, n"hate", n"warning");
      }
      return true;
    }
    // And then they wait a few seconds before drawing.
    if CBWarningsOn() && npc.cbGangWarnTick > 0 && tick - npc.cbGangWarnTick < CBConfig.GangWarnGraceTicks() {
      return true;
    }
    // Never mid-conversation: V has the prompt up on them, or is waiting on their answer.
    if npc.cbTalkHeldTick > 0 && tick - npc.cbTalkHeldTick <= 2 {
      return true;
    }
    // The parley: after the warning, an unarmed V walking up or standing within ParleyRange gets up to ParleyMaxTicks to
    // talk before they draw.
    if CBWarningsOn() && npc.cbGangWarnTick > 0 && dist <= CBConfig.ParleyRange()
       && !IsDefined(GameObject.GetActiveWeapon(player)) && !player.IsInCombat()
       && tick - npc.cbGangWarnTick < CBConfig.ParleyMaxTicks() {
      return true;
    }
    let agent = npc.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(agent) || !IsDefined(pagent) {
      return true;
    }
    // Somebody the game has made friendly towards V (a job contact, a quest ally) stays that way.
    if Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Friendly) {
      return false;
    }
    CBTrace("attitude: world NPC hostile on sight");
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
    npc.cbHostileByCyberbane = true;
    this.TrackHostile(npc);
    return true;
  }

  // Their people are hostile to V, and not because of Cyberbane.
  private func NoteForeignHostility(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>,
                                    player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, faction: CName) -> Void {
    if sys.SeenHostileFresh(faction) {
      return;   // already seen this minute; one look is enough
    }
    // Asked here as well as through the quest area, which leaves hostile zones out when "Stay out of
    // quest areas" is switched off: everybody in a gang's own compound is hostile to an intruder.
    if CBPlayerInHostileZone(player.GetGame()) {
      return;
    }
    if (Equals(faction, n"NCPD") || Equals(faction, n"MaxTac") || Equals(faction, n"Police"))
       && IsDefined(score) && score.GetHeatStage() > 0 {
      return;
    }
    let agent = npc.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(agent) || !IsDefined(pagent) {
      return;
    }
    if !Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) || CBNpcInCombat(npc) {
      return;
    }
    if sys.NoteSeenHostile(faction) {
      CBLog.Info(n"Model", s"\(NameToString(faction)): their people are hostile to you, and not by Cyberbane's doing (They Will Remember, Night City Remembers, another mod or the game).");
    }
  }

  // Somebody V has just picked a fight with to their face (Reactions/StreetTalk.reds).
  public func TurnHostileFromTalk(player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, faction: CName) -> Bool {
    if !IsDefined(player) || !IsDefined(npc) || !npc.IsAttached() || npc.IsDead()
       || !CBFactionFieldsSquads(faction) || CBTwrActive() {
      return false;
    }
    let agent = npc.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(agent) || !IsDefined(pagent)
       || Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Friendly) {
      return false;
    }
    CBTrace("attitude: world NPC hostile after V picked a fight");
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
    npc.cbHostileByCyberbane = true;
    npc.cbHoldState = 2;
    this.TrackHostile(npc);
    return true;
  }

  // The revert list only has to cover NPCs that still exist, so drop the ones that have despawned before adding.
  private func TrackHostile(npc: wref<ScriptedPuppet>) -> Void {
    if ArraySize(this.m_hostileNpcs) >= CBConfig.MaxTrackedHostiles() {
      let i = 0;
      while i < ArraySize(this.m_hostileNpcs) {
        if !IsDefined(this.m_hostileNpcs[i]) || !this.m_hostileNpcs[i].IsAttached() {
          ArrayErase(this.m_hostileNpcs, i);
        } else {
          i += 1;
        }
      }
      // Still full of live NPCs: drop the oldest so the list stays bounded.
      if ArraySize(this.m_hostileNpcs) >= CBConfig.MaxTrackedHostiles() {
        ArrayErase(this.m_hostileNpcs, 0);
      }
    }
    ArrayPush(this.m_hostileNpcs, npc);
    let sys = IsDefined(npc) ? CyberbaneSystem.Get(npc.GetGame()) : null;
    if IsDefined(npc) && IsDefined(sys) {
      npc.cbHostileTick = Max(sys.GetTickCount(), 1);
    }
  }

  private func RevertHostileAtJob(game: GameInstance, sys: ref<CyberbaneSystem>) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) || !IsDefined(sys) {
      return;
    }
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(pagent) {
      return;
    }
    let i = 0;
    while i < ArraySize(this.m_hostileNpcs) {
      let npc = this.m_hostileNpcs[i];
      i += 1;
      if IsDefined(npc) && npc.IsAttached() && !npc.IsDead() && npc.cbHostileByCyberbane
         && (sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.QuestSpawnClearance())
             || CBRecordIsUniqueCharacter(npc.GetRecordID())) {
        let agent = npc.GetAttitudeAgent();
        if IsDefined(agent) {
          CBTrace("attitude: world NPC back to neutral at a job");
          agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
        }
        npc.cbHostileByCyberbane = false;
      }
    }
  }

  private func RevertHostileNotFighting(game: GameInstance) -> Void {
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(pagent) {
      return;
    }
    for npc in this.m_hostileNpcs {
      if IsDefined(npc) && npc.IsAttached() && !npc.IsDead() && npc.cbHostileByCyberbane
         && !CBNpcInCombat(npc) {
        let agent = npc.GetAttitudeAgent();
        if IsDefined(agent) {
          CBTrace("attitude: world NPC back to neutral while the story has the stage");
          agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
        }
        npc.cbHostileByCyberbane = false;
      }
    }
  }

  // Back to how the game had them: everybody Cyberbane turned on V whose faction does not go to war with V any more
  // (CBFactionFieldsSquads) - switched off under Factions since, or the police - and who is not in the middle of a
  // fight.
  private func RevertNotFielding(game: GameInstance, sys: ref<CyberbaneSystem>) -> Void {
    if ArraySize(this.m_hostileNpcs) == 0 {
      return;
    }
    let score = IsDefined(sys) ? sys.GetScore() : null;
    let tick = IsDefined(sys) ? sys.GetTickCount() : 0;
    let player = GetPlayer(game);
    if !IsDefined(player) {
      return;
    }
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(pagent) {
      return;
    }
    let now = CBGameSeconds(game);
    for npc in this.m_hostileNpcs {
      if IsDefined(npc) && npc.IsAttached() && !npc.IsDead() && npc.cbHostileByCyberbane
         && !CBNpcInCombat(npc) {
        let faction = CBClassifyFaction(npc);
        let off = !CBFactionFieldsSquads(faction);
        let quiet = tick - npc.cbHostileTick >= CBConfig.HostileCoolTicks();
        let cooled = !off && quiet
                     && (IsDefined(score) && !Equals(score.GetPosture(faction), ECBPosture.Vendetta)
                         || IsDefined(sys) && sys.TollActive(faction, now));
        if off || cooled {
          let agent = npc.GetAttitudeAgent();
          if IsDefined(agent) {
            CBTrace("attitude: world NPC back to neutral, no grudge left");
            agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
          }
          npc.cbHostileByCyberbane = false;
        }
      }
    }
  }

  private func RevertAllHostile(game: GameInstance) -> Void {
    let player = GetPlayer(game);
    let pagent: ref<AttitudeAgent>;
    if IsDefined(player) {
      pagent = player.GetAttitudeAgent();
    }
    for npc in this.m_hostileNpcs {
      if IsDefined(npc) && npc.IsAttached() && npc.cbHostileByCyberbane {
        let agent = npc.GetAttitudeAgent();
        if IsDefined(agent) && IsDefined(pagent) {
          agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
        }
        npc.cbHostileByCyberbane = false;
      }
    }
    ArrayClear(this.m_hostileNpcs);
  }

  private func TryWhisper(game: GameInstance, sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dread: Float, dist: Float, faction: CName, recognized: Bool) -> Void {
    if this.m_whisperCooldownTicks > 0 || npc.cbWhispered || dist > CBConfig.WhisperRadius() {
      return;
    }
    // A faction switched off in Mod Settings talks like anybody else on the street: no grudge, no lost boss, no warning
    // in their voice.
    if !CBFactionOn(faction) {
      faction = n"";
    }

    let mood = n"fear";
    if NotEquals(faction, n"") {
      let posture = score.GetPosture(faction);
      if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
        mood = n"hate";
      } else {
        if Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly) {
          mood = n"respect";
        }
      }
    }

    // The Street's read on V's Code shifts tone: a merc known for clean, pro work
    // earns respect from onlookers; someone edging toward cyberpsychosis earns
    // dread even where respect was due.
    let code = sys.GetCode();
    if code >= 40.0 && Equals(mood, n"fear") {
      mood = n"respect";
    }
    if code <= -40.0 && Equals(mood, n"respect") {
      mood = n"fear";
    }

    // Topic: the city remembers notable kills. If this NPC's gang has lost a boss
    // to V, or V has MaxTac kills and this is NCPD, the whisper calls it out.
    let topic = n"";
    let fs = sys.FindFaction(faction);
    if IsDefined(fs) && fs.bossesKilled > 0 {
      topic = n"bossloss";
      mood = n"hate";
    } else {
      let stats = sys.GetStats();
      if Equals(faction, n"NCPD") && IsDefined(stats) && CBKillsByClass(sys, EnumInt(ECBVictimClass.MaxTac)) > 0 {
        topic = n"maxtac";
        mood = n"fear";
      }
    }

    // Somebody of a gang V has broken, or who is holding back from V out of fear, is afraid out loud, whatever their
    // gang's grudge.
    if NotEquals(faction, n"") && (npc.cbHoldState == 1 || CBGangBroken(sys, faction))
       && (Equals(mood, n"hate") || Equals(mood, n"fear")) {
      mood = CBGangBroken(sys, faction) ? n"broken" : n"fear";
      topic = n"";
    }
    // Nobody can say who V is: no grudge and no story, only somebody they cannot place.
    if !recognized {
      mood = n"fear";
      topic = n"";
    }

    // A generic fearful whisper needs V to be at least mildly notable; topical
    // whispers (boss / MaxTac) are always eligible.
    if Equals(topic, n"") && Equals(mood, n"fear") && dread < CBConfig.CivTierNotice() && recognized {
      return;
    }
    if RandF() > CBConfig.WhisperChance() {
      return;
    }

    npc.cbWhispered = true;
    this.m_whisperCooldownTicks = this.WhisperCooldownTicks();
    CBShowWhisper(sys, game, faction, mood, topic);
  }

  // Has this gang said its warning to V lately? Marks it said when not.
  private func WarnLineDue(faction: CName, now: Float) -> Bool {
    let i = ArrayFindFirst(this.m_warnSaidFaction, faction);
    if i >= 0 && now >= this.m_warnSaidAt[i] && now - this.m_warnSaidAt[i] < CBConfig.GangWarnLineHours() * CBConfig.SecondsPerHour() {
      return false;
    }
    if i >= 0 {
      this.m_warnSaidAt[i] = now;
    } else {
      ArrayPush(this.m_warnSaidFaction, faction);
      ArrayPush(this.m_warnSaidAt, now);
    }
    return true;
  }

  private func WhisperCooldownTicks() -> Int32 {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      return rt.GetSettings().whisperCooldown;
    }
    return 40;
  }
}

// Does this person know who V is? Rolled once per spawn and kept on the puppet (spec §8.7), so the Director and street
// talk (Reactions/StreetTalk.reds) always agree about the same face.
public func CBRecognizes(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>,
                         faction: CName, district: CName) -> Bool {
  if !IsDefined(sys) || !IsDefined(score) || !IsDefined(npc) {
    return false;
  }
  // Set by hand to come for V (How gangs see you): they know V's face, unless it is covered or V is wearing their
  // colours well. Asked fresh each time and never rolled or counted, so Earned in play rolls as it always has.
  if (CBGangViewHunts(faction) || CBOpenSeasonFor(sys.GetGameInstance(), faction)) && !CBPlayerMasked(sys.GetGameInstance())
     && !(Equals(faction, sys.GetDisguiseFaction()) && sys.GetDisguiseStrength() >= 0.5) {
    return true;
  }
  // One of theirs (Reactions/Allies.reds, [66]): the gang's enemies know V for one of them.
  if CBKnownAsOneOfTheirEnemies(sys, faction) {
    return true;
  }
  // The car they know V by, or the gun (Model/StreetBook.reds): a gang's people place V by it whatever V has over their
  // face. Nobody of the law, and only a gang that fields people.
  if NotEquals(faction, n"") && CBFactionFieldsSquads(faction) && CBVGivenAway(sys, sys.GetGameInstance()) > 0 {
    return true;
  }
  if npc.cbRecoState == 0 {
    // Harder to make out a face at night and in the rain (Model/Moment.reds).
    let p = score.RecognitionChance(district, faction, false, false) * CBSightMult(sys.GetGameInstance());
    // Maelstrom can tell what is under a jacket (Data/GangCodes.reds).
    if score.GetChrome() >= CBConfig.ChromeUnderClothes() {
      p += CBCodeSeesChrome(faction);
    }
    // Wearing this gang's colours makes them slower to place you (spec §9.3).
    if NotEquals(faction, n"") && Equals(faction, sys.GetDisguiseFaction()) {
      p *= (1.0 - sys.GetDisguiseStrength());
    }
    npc.cbRecoState = RandF() <= p ? 1 : 2;
    if npc.cbRecoState == 1 {
      let st = sys.GetStats();
      if IsDefined(st) {
        st.timesRecognized += 1;
      }
    }
  }
  // A boss who looks closer: somebody the roll did not let place V, an officer or an elite, close to a V who is masked
  // or in their colours, for long enough.
  if npc.cbRecoState == 2 && CBSeesThroughDisguise(sys, npc, faction) {
    npc.cbRecoState = 1;
  }
  return npc.cbRecoState == 1;
}

public func CBBossesSeeThroughOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().bossesSeeThrough;
}

// Whether they are somebody who would look closer: an officer, an elite or a boss, read once and kept.
@addField(ScriptedPuppet)
public let cbEnforcer: Int32;        // 0 unread, 1 yes, 2 no
// The one who leads a crew ([U2]; Spawn/Spawner.reds).
@addField(ScriptedPuppet)
public let cbSergeant: Bool;
@addField(ScriptedPuppet)
public let cbLookSince: Float;       // game seconds V has been close and covered, 0 when not

func CBSeesThroughDisguise(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>, faction: CName) -> Bool {
  if !CBBossesSeeThroughOn() || Equals(faction, n"") || !CBFactionFieldsSquads(faction) {
    return false;
  }
  let game = sys.GetGameInstance();
  let covered = CBPlayerMasked(game) || (Equals(faction, sys.GetDisguiseFaction()) && sys.GetDisguiseStrength() > 0.0);
  if !covered {
    npc.cbLookSince = 0.0;
    return false;
  }
  // The record's rarity is a native read: only for somebody the gate has already passed (every caller has).
  if npc.cbEnforcer == 0 {
    if !npc.IsAttached() {
      return false;
    }
    let r = npc.GetNPCRarity();
    npc.cbEnforcer = Equals(r, gamedataNPCRarity.Officer) || Equals(r, gamedataNPCRarity.Elite)
                     || Equals(r, gamedataNPCRarity.Boss) ? 1 : 2;
  }
  if npc.cbEnforcer != 1 {
    return false;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > CBConfig.EnforcerLookRange()
     || !CBWitnessCanSee(npc, player) {
    npc.cbLookSince = 0.0;
    return false;
  }
  let now = CBGameSeconds(game);
  if npc.cbLookSince <= 0.0 || now < npc.cbLookSince {
    npc.cbLookSince = MaxF(now, 1.0);
    return false;
  }
  if now - npc.cbLookSince < CBConfig.EnforcerLookSeconds() {
    return false;
  }
  CBLog.Info(n"Model", s"One of \(NameToString(faction))'s officers saw through the disguise.");
  if CBToastsOn() {
    // What they saw through: the mask, or their own colours on V (either may be what covered V).
    let masked = CBPlayerMasked(game);
    CBOverheard(game, CBWhisperSpeaker(faction), masked
      ? CBPick3(CBT(n"Cyberbane-Director-NiceMaskIDKnowThat"), CBT(n"Cyberbane-Director-YouThinkAScrapOfCloth"),
                CBT(n"Cyberbane-Director-TookMeASecondNotTwo"))
      : CBPick3(CBT(n"Cyberbane-Director-WearingOurColoursDoesnTMake"), CBT(n"Cyberbane-Director-NiceJacketShameAboutWhoS"),
                CBT(n"Cyberbane-Director-TookMeASecondNotTwo")));
  }
  return true;
}

// Fast-tick driver (spec §5.5). Carries a generation token so stale tick chains
// from a previous session/load stop instead of stacking.
public class CBFastTickCallback extends DelayCallback {
  public let game: GameInstance;
  public let generation: Int32;

  public func Call() -> Void {
    let sys = CyberbaneSystem.Get(this.game);
    if IsDefined(sys) {
      sys.OnFastTick(this.generation);
    }
  }
}

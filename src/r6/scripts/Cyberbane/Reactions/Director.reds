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

// The settled tick Cyberbane turned this NPC on V (TrackHostile, 1.9.5), so a grudge that has since
// cooled can put them back once their fight is over.
@addField(ScriptedPuppet)
public let cbHostileTick: Int32;

// Set true once a Vendetta gang member has given V a spoken warning (spec §9.3).
@addField(ScriptedPuppet)
public let cbGangWarned: Bool;

// The settled tick this NPC warned V (1.9.5), so the warning is a beat V can use, not a formality.
@addField(ScriptedPuppet)
public let cbGangWarnTick: Int32;

// The tick this NPC's attitude towards V was last read for NoteForeignHostility (1.9.1).
@addField(ScriptedPuppet)
public let cbAttitudeReadTick: Int32;

// Whether this NPC is too afraid of V to act on their gang's vendetta (1.9.5): 0 not decided yet, 1 holds
// back, 2 stands and fights. Decided once, the first time it matters (CBHoldBackChance).
@addField(ScriptedPuppet)
public let cbHoldState: Int32;

// The tick this NPC last failed the Director's checks (the Safety Gate, a job site, one of ours), so it
// is passed over for a few ticks rather than asked again every second (1.9.1). 0 = never failed.
@addField(ScriptedPuppet)
public let cbGateFailTick: Int32;

func CBWarningsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().warnings;
}

// One of the people Cyberbane sent. Every spawn carries this tag (Spawn/Spawner.reds, Arrival.reds).
//
// Nothing kept them out of the Director, so a Rival or a crew closing on a frightening V was read as
// one more ganger on the street who might back off: rolled for recognition, overheard, and above all
// made to broadcast Terror and SpreadFear ten metres around themselves, which reached the rest of
// their own crew. People sent to find V were being frightened out of looking for V, on the very
// ticks they were getting close. Whether they break is morale's question (Reactions/Morale.reds).
func CBSentByUs(des: ref<DynamicEntitySystem>, npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(des) && des.IsTagged(npc.GetEntityID(), n"Cyberbane");
}

// One of Cyberbane's people who is here for V: a crew, an apex squad, a Rival and their people, a scout, a
// convoy. The street's own (a bagman and their lookout, a favour's lookout, the people at a sit-down) and a
// turf patrol are Cyberbane's too, but they are a gang's people going about the gang's business, and to V
// they are anybody else on the street (2.1.0). Talk asked CBSentByUs, so none of them could be spoken to: a
// player found a Voodoo Boy who would not talk while the civilian beside him would.
func CBSentAfterV(des: ref<DynamicEntitySystem>, npc: wref<ScriptedPuppet>) -> Bool {
  if !CBSentByUs(des, npc) {
    return false;
  }
  let id = npc.GetEntityID();
  if des.IsTagged(id, n"CB_Patrol") {
    return false;
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
  // Street Sense detection, resolved once and kept: 0 unknown, 1 present, 2 absent. The
  // scan allocates, and whispers are decided every tick, so it must not run every tick.
  private let m_streetSense: Int32;
  // NPCs whose attitude Cyberbane overrode, tracked so the kill switch can revert them.
  private let m_hostileNpcs: array<wref<ScriptedPuppet>>;
  // Where in the registry the last tick's walk stopped (1.9.1), so the next one carries on from there.
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
    let pruneFrom = GetPlayer(game);
    if IsDefined(pruneFrom) {
      reg.PruneFar(pruneFrom.GetWorldPosition(), CBConfig.RegistryKeepRadius());
    }

    // Somewhere the game calls a safe area - an apartment, a clinic, a bar, a memorial.
    // Nobody there reacts to V, however frightening V is (spec §16).
    if sys.IsInSafeZone() {
      return;
    }
    // Never during a conversation or a scene, never while the story has the stage (a companion at
    // V's side, a fight the story is staging), and never on a job when V has asked Cyberbane to
    // stay out of quest areas. Turning somebody hostile mid-dialogue is how a gig contact ended up
    // attacking V in the middle of Treating Symptoms.
    if CBPlayerInScene(game) || sys.IsInQuestArea() || sys.GetStoryHold() != CBStoryNone() {
      // Anybody Cyberbane already turned hostile who is standing at the job, or who turns out to be
      // somebody the story wrote, goes back to how the game had them. Hostility set before V took
      // the job must not carry into it.
      this.RevertHostileAtJob(game, sys);
      // And while the story has the stage, everybody Cyberbane turned who is not already fighting:
      // a ganger set off a minute ago must not walk into River's scene. Anybody mid-fight is left
      // as they are; flipping somebody neutral in the middle of a swing helps nobody.
      if sys.GetStoryHold() != CBStoryNone() {
        this.RevertHostileNotFighting(game);
      }
      return;
    }
    // Near an objective V is not tracking (1.8.4) the street goes on reacting: the quest area above is
    // the tracked job's, and every NPC standing at any job site is kept out of the loop below by its
    // own check. Anybody already turned who is standing at one still goes back to how the game had
    // them.
    if sys.IsOnJob() {
      this.RevertHostileAtJob(game, sys);
    }

    if this.m_whisperCooldownTicks > 0 {
      this.m_whisperCooldownTicks -= 1;
    }
    // Anybody Cyberbane turned on V whose faction it may not turn any more (1.9.1): switched off in
    // Mod Settings since, or the law. Every few ticks, from a list of at most MaxTrackedHostiles.
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
    // The district's temper, the blood on V, a fight just over (Model/Moment.reds, 2.3.1).
    civIntensity *= CBCrowdMomentMult(sys, game);
    let civReacted = 0;
    let playerInCombat = player.IsInCombat();
    // An exchange V is having (Reactions/StreetTalk.reds) is not talked over by the street (1.9.5).
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
    // Round the registry, from where the last tick stopped, and only so far each tick (1.9.1).
    //
    // "The mod lowers my fps a bit in high density regions." The walk started from the first NPC
    // every tick and went on until sixteen had passed every check, so on a crowded street it read the
    // position of every NPC ahead of those sixteen, every second, and ran the whole Safety Gate - a
    // workspot query, a safe-area query, a pin scan - on every one in range who failed it: everybody
    // sitting, leaning, selling or queueing, again and again, and in a crowd that is most of them. And
    // the same sixteen at the front were the only ones the street ever had react. Now the walk carries
    // on where it stopped, reads at most NpcLookPerTick positions, and passes over anybody who failed
    // the checks a moment ago (NpcGateRetryTicks). Anybody who passes is always checked afresh.
    let start = this.m_cursor;
    if start < 0 || start >= count {
      start = 0;
    }
    let looked = 0;
    let tick = sys.GetTickCount();
    let k = 0;
    while k < count && evaluated < CBConfig.NpcEvalPerTick() && looked < CBConfig.NpcLookPerTick() {
      let npc = npcs[(start + k) % count];
      k += 1;
      // Only touch an NPC that is attached and past its warm-up ticks (crash safety during
      // streaming). Cheap distance gate first: the Safety Gate queries the workspot system, so
      // only run it for NPCs actually in range. A dense registry then stays cheap per tick.
      let resting = false;
      if IsDefined(npc) && npc.cbGateFailTick > 0 {
        let failedAgo = tick - npc.cbGateFailTick;
        resting = failedAgo >= 0 && failedAgo < CBConfig.NpcGateRetryTicks();
      }
      if !resting && CBNpcSafe(sys, npc) {
        looked += 1;
        let dist = Vector4.Distance(ppos, npc.GetWorldPosition());
        // Nobody standing at any job site, tracked or not (1.8.4): turning a gig's people hostile
        // or sending them running is the story's business. The Safety Gate itself only asks about
        // the tracked job, so a fight's own consequences - morale, running, mercy - count anywhere.
        let passes = false;
        if dist <= CBConfig.NpcEvalRadius() {
          passes = !CBSentByUs(des, npc) && CBSafetyGate.CanAffect(npc)
                && !sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.QuestSpawnClearance());
          npc.cbGateFailTick = passes ? 0 : Max(tick, 1);
        }
        if passes {
          evaluated += 1;
          let faction = CBClassifyFaction(npc);

          // Recognition, rolled once per spawn and cached on the puppet (spec §8.7).
          let recognized = CBRecognizes(sys, score, npc, faction, district);

          // Vendetta gangs that recognise V attack on sight (spec §9.3); that overrides
          // any fear. Everyone else - civilians, gangers, cops - can read how dangerous V
          // looks and flee (spec §9.2), capped per tick.
          let turnedHostile = false;
          if !npc.IsCrowd() && gangOn && hostileOnSight && recognized {
            turnedHostile = this.TryGangHostile(score, player, npc, faction, tick, dist);
          }
          // Somebody of a gang hostile to V who Cyberbane did not turn (1.9.1), read now and then.
          if !playerInCombat && !turnedHostile && !npc.IsCrowd() && NotEquals(faction, n"")
             && !npc.cbHostileByCyberbane
             && (sys.GetTickCount() - npc.cbAttitudeReadTick) >= CBConfig.ForeignHostileReadTicks() {
            npc.cbAttitudeReadTick = sys.GetTickCount();
            this.NoteForeignHostility(sys, score, player, npc, faction);
          }
          // Never whoever V is talking to or settling on (1.9.5).
          let inTalk = npc.cbTalkHeldTick > 0 && tick - npc.cbTalkHeldTick <= 2;
          if !turnedHostile && civOn && civReacted < maxCiv && !inTalk {
            if CBFearReact(game, score, npc, dist, civIntensity, faction, sys.GetTickCount(),
                           sys.GetContent(), masked, player) {
              civReacted += 1;
            }
          }
          // Behind a mask V is somebody nobody can place, and people talk about that too (1.9.5).
          if whispersOn && !playerInCombat && !talking && (recognized || masked) {
            this.TryWhisper(game, sys, score, npc, dread, dist, faction, recognized);
          }
        }
      }
    }
    this.m_cursor = count > 0 ? (start + k) % count : 0;
  }

  // Vendetta gangs attack a recognized V on sight (spec §9.3). Tracked for revert.
  // Returns true when this NPC is engaging V (hostile or being warned), so the Director
  // knows not to let it flee from fear instead.
  private func TryGangHostile(score: ref<CBScoreEngine>, player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, faction: CName,
                              tick: Int32, dist: Float) -> Bool {
    if Equals(faction, n"") {
      return false;
    }
    // Never the law, and never a faction switched off in Mod Settings (1.9.1). The NCPD has heat and
    // stars, and CBFactionFieldsSquads has always said Cyberbane bolts no second escalation onto them,
    // but this path never asked it: a V who had killed enough cops to put the NCPD at Vendetta was
    // drawn on by every officer who recognised them, with no stars showing. "Almost every cop will
    // slowly get sus of me and eventually combat."
    if !CBFactionFieldsSquads(faction) {
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
    // Safe passage bought from one of theirs (Reactions/TalkTopics.reds, 1.9.7): their street people let V
    // walk for a few hours.
    let tollSys = CyberbaneSystem.Get(player.GetGame());
    if IsDefined(tollSys) && tollSys.TollActive(faction, CBGameSeconds(player.GetGame())) {
      return false;
    }
    // Afraid of V more than they hate V (1.9.5). A vendetta used to turn every one of a gang's people
    // V walked past, so the more of them V had killed - which is what makes a gang afraid - the fewer
    // of them V could ever do anything with but fight, and nobody of a gang V had broken was ever
    // anything but a target. Each of them weighs it now, once: their own nerve, the friends standing
    // with them, against how much their gang fears V and whether V has broken it. Whoever holds back
    // does not draw on V: they watch V, they mutter, and V can walk up and talk to them
    // (Reactions/StreetTalk.reds). Whoever does not is coming for V, as before.
    if CBHoldsBackFromV(CyberbaneSystem.Get(player.GetGame()), npc, faction) {
      return false;
    }
    // They give you one warning before they open fire (spec §9.3), if enabled. The flip
    // to hostile lands on the next evaluation, which reads as a beat of hesitation.
    if CBWarningsOn() && !npc.cbGangWarned {
      npc.cbGangWarned = true;
      npc.cbGangWarnTick = Max(tick, 1);
      // One warning, not one per head.
      //
      // The flag above is per NPC, which is right for deciding who has had their warning, and
      // wrong for deciding whether to put a line on screen. A gang arriving in numbers meant
      // every single one of them announced itself: a thirteen-strong vendetta crew produced
      // thirteen popups on top of each other in the middle of the fight. The ambient whisper
      // path right below already shares one cooldown across the whole street for exactly this
      // reason; the warning was simply not using it.
      //
      // They still flip hostile either way. Only the line is rationed.
      if this.m_whisperCooldownTicks <= 0 {
        this.m_whisperCooldownTicks = this.WhisperCooldownTicks();
        CBShowWhisper(CyberbaneSystem.Get(player.GetGame()), player.GetGame(),
                      faction, n"hate", n"warning");
      }
      return true;
    }
    // And then they wait a few seconds before drawing (1.9.5). The flip used to land on the very next
    // look, about a second after the warning, so there was no time to do anything about it: walk off,
    // or walk up and talk them down (Reactions/StreetTalk.reds). Somebody V leans on until they back
    // down holds back from then on (cbHoldState, CBHoldsBackFromV above), and is never turned.
    if CBWarningsOn() && npc.cbGangWarnTick > 0 && tick - npc.cbGangWarnTick < CBConfig.GangWarnGraceTicks() {
      return true;
    }
    // Never mid-conversation: V has the prompt up on them, or is waiting on their answer.
    if npc.cbTalkHeldTick > 0 && tick - npc.cbTalkHeldTick <= 2 {
      return true;
    }
    // The parley (1.9.6). A gang that shoots V on sight made talking to its people impossible: they drew
    // before V could reach them. After the warning, a V with empty hands, coming their way or standing
    // within ParleyRange, gets the benefit of the doubt for up to ParleyMaxTicks: time to walk up and talk.
    // A weapon in V's hands, or lingering past it, and they draw. What V says decides the rest
    // (Reactions/StreetTalk.reds, the [Parley] line): talked down, they and their crew back off for good;
    // not, and the fight starts the moment the talk is over.
    if CBWarningsOn() && npc.cbGangWarnTick > 0 && dist <= CBConfig.ParleyRange()
       && !IsDefined(GameObject.GetActiveWeapon(player))
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

  // Their people are hostile to V, and not because of Cyberbane (1.9.1).
  //
  // "They Will Remember says the Tyger Claws are hostile for my kills, but Cyberbane says neutral."
  // And: "almost every cop and Barghest will slowly get sus of me and eventually combat. I can't tell
  // what is causing this." Cyberbane's standing is its own book, and with They Will Remember installed
  // it does not turn anybody on V at all; but the Gangs screen could only say what Cyberbane thought,
  // so a gang shooting V on sight read as neutral and nobody could tell whose doing it was. The 1.9.0
  // answer asked They Will Remember through reflection, which depends on how that mod is built inside.
  // This asks the world: somebody of theirs, out of combat, out of any hostile zone and away from any
  // job (the Director stands down in all of those), whose attitude to V is already hostile though
  // Cyberbane never touched it. That is "hostile on sight", by whoever's hand - They Will Remember,
  // another mod or the game - and the Gangs screen says so.
  //
  // The police are hostile to anybody with stars, so they are not read while V has any.
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
      CBLog.Info(n"Model", s"\(NameToString(faction)): their people are hostile to you, and not by Cyberbane's doing (They Will Remember, another mod or the game).");
    }
  }

  // Somebody V has just picked a fight with to their face (Reactions/StreetTalk.reds, 1.9.5). The same
  // attitude change hostility on sight makes, tracked the same way, so every revert above - a job, the
  // story, a faction switched off, the kill switch - puts them back too. Never the law, never somebody
  // the game made V's friend.
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

  // The revert list only has to cover NPCs that still exist, so drop the ones that have
  // despawned before adding. Without this it grows for the whole session - every gang
  // member ever turned hostile stays in it until the kill switch clears it.
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

  // Back to how the game had them: everybody Cyberbane turned on V whose faction does not go to war
  // with V any more (CBFactionFieldsSquads) - switched off under Factions since, or the police - and who
  // is not in the middle of a fight. Without this, switching a gang off left whoever it had already set
  // on V hostile until they streamed out (1.9.1).
  //
  // And anybody whose gang no longer has a vendetta against V (1.9.5): paid off on the phone or the Hub,
  // or cooled down on its own, or somebody V picked a fight with to their face (TurnHostileFromTalk) at
  // a posture that does not shoot on sight. Only once their fight is over and HostileCoolTicks have
  // passed since they were turned. Before this, a gang V had just paid off went on shooting V on sight
  // through every one of its people Cyberbane had already turned, until they streamed out.
  //
  // And anybody whose gang V has bought safe passage from (Reactions/TalkTopics.reds, the toll): the toll
  // only kept the next of them from being turned, so the ones already turned went on shooting on sight
  // through the hours V had paid for.
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
    // A faction switched off in Mod Settings talks like anybody else on the street (1.9.1): no grudge,
    // no lost boss, no warning in their voice.
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

    // Somebody of a gang V has broken, or who is holding back from V out of fear, is afraid out loud,
    // whatever their gang's grudge (1.9.5).
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

  private func WhisperCooldownTicks() -> Int32 {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      return rt.GetSettings().whisperCooldown;
    }
    return 25;
  }
}

// Does this person know who V is? Rolled once per spawn and kept on the puppet (spec §8.7), so the
// Director and street talk (Reactions/StreetTalk.reds, 1.9.5) always agree about the same face.
public func CBRecognizes(sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>,
                         faction: CName, district: CName) -> Bool {
  if !IsDefined(sys) || !IsDefined(score) || !IsDefined(npc) {
    return false;
  }
  // Set by hand to come for V (How gangs see you, 2.1.0): they know V's face, unless it is covered or V is
  // wearing their colours well. Asked fresh each time and never rolled or counted, so Earned in play rolls as it
  // always has.
  if CBGangViewHunts(faction) && !CBPlayerMasked(sys.GetGameInstance())
     && !(Equals(faction, sys.GetDisguiseFaction()) && sys.GetDisguiseStrength() >= 0.5) {
    return true;
  }
  // The car they know V by, or the gun (Model/StreetBook.reds, 2.3.1): a gang's people place V by it whatever
  // V has over their face. Nobody of the law, and only a gang that fields people.
  if NotEquals(faction, n"") && CBFactionFieldsSquads(faction) && CBVGivenAway(sys, sys.GetGameInstance()) > 0 {
    return true;
  }
  if npc.cbRecoState == 0 {
    // Harder to make out a face at night and in the rain (Model/Moment.reds, 2.3.1).
    let p = score.RecognitionChance(district, faction, false, false) * CBSightMult(sys.GetGameInstance());
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
  // A boss who looks closer (2.3.1): somebody the roll did not let place V, an officer or an elite, close to a V
  // who is masked or in their colours, for long enough.
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
    CBOverheard(game, CBWhisperSpeaker(faction), CBPick4(
      "Nice mask. I'd know that walk anywhere.",
      "You think a scrap of cloth fools me? I know who you are.",
      "Wearing our colours doesn't make you one of us. I see you.",
      "Took me a second. Not two. Hello, merc."));
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

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

public class CBReactionDirector {
  private let m_whisperCooldownTicks: Int32;
  // NPCs whose attitude Cyberbane overrode, tracked so the kill switch can revert them.
  private let m_hostileNpcs: array<wref<ScriptedPuppet>>;

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

    if this.m_whisperCooldownTicks > 0 {
      this.m_whisperCooldownTicks -= 1;
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
      gangOn = s.gangReactions;
      hostileOnSight = s.hostileOnSight;
      civOn = s.civReactions;
      civIntensity = s.civIntensity;
      maxCiv = s.maxReactingCivilians;
    }
    let civReacted = 0;
    let playerInCombat = player.IsInCombat();
    let ppos = player.GetWorldPosition();
    let score = sys.GetScore();
    let dread = score.GetDread();
    let district = CBCurrentDistrict(game);

    let npcs = reg.GetAll();
    let evaluated = 0;
    let i = 0;
    while i < ArraySize(npcs) && evaluated < CBConfig.NpcEvalPerTick() {
      let npc = npcs[i];
      i += 1;
      if CBSafetyGate.CanAffect(npc) {
        let dist = Vector4.Distance(ppos, npc.GetWorldPosition());
        if dist <= CBConfig.NpcEvalRadius() {
          evaluated += 1;
          let faction = CBClassifyFaction(npc);

          // Recognition, rolled once per spawn and cached on the puppet (spec §8.7).
          if npc.cbRecoState == 0 {
            let p = score.RecognitionChance(district, faction, false, false);
            npc.cbRecoState = RandF() <= p ? 1 : 2;
          }
          let recognized = npc.cbRecoState == 1;

          // Pedestrians react to how frightening V is (spec §9.2), capped per tick.
          if npc.IsCrowd() {
            if civOn && civReacted < maxCiv {
              if CBCrowdReact(game, score, npc, dist, civIntensity) {
                civReacted += 1;
              }
            }
          } else {
            if gangOn && hostileOnSight && recognized {
              this.TryGangHostile(score, player, npc, faction);
            }
          }
          if whispersOn && !playerInCombat && recognized {
            this.TryWhisper(game, sys, score, npc, dread, dist, faction);
          }
        }
      }
    }
  }

  // Vendetta gangs attack a recognized V on sight (spec §9.3). Tracked for revert.
  private func TryGangHostile(score: ref<CBScoreEngine>, player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, faction: CName) -> Void {
    if npc.cbHostileByCyberbane || Equals(faction, n"") {
      return;
    }
    if CBTwrActive() {
      return;   // They Will Remember owns hostility-on-sight in compat mode (spec §17)
    }
    if !Equals(score.GetPosture(faction), ECBPosture.Vendetta) {
      return;
    }
    let agent = npc.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(agent) || !IsDefined(pagent) {
      return;
    }
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
    npc.cbHostileByCyberbane = true;
    ArrayPush(this.m_hostileNpcs, npc);
  }

  private func RevertAllHostile(game: GameInstance) -> Void {
    let player = GetPlayer(game);
    let pagent: ref<AttitudeAgent>;
    if IsDefined(player) {
      pagent = player.GetAttitudeAgent();
    }
    for npc in this.m_hostileNpcs {
      if IsDefined(npc) && npc.cbHostileByCyberbane {
        let agent = npc.GetAttitudeAgent();
        if IsDefined(agent) && IsDefined(pagent) {
          agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
        }
        npc.cbHostileByCyberbane = false;
      }
    }
    ArrayClear(this.m_hostileNpcs);
  }

  private func TryWhisper(game: GameInstance, sys: ref<CyberbaneSystem>, score: ref<CBScoreEngine>, npc: wref<ScriptedPuppet>, dread: Float, dist: Float, faction: CName) -> Void {
    if this.m_whisperCooldownTicks > 0 || npc.cbWhispered || dist > CBConfig.WhisperRadius() {
      return;
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
    // earns respect from onlookers; a mad dog edging toward cyberpsychosis earns
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
      if Equals(faction, n"NCPD") && IsDefined(stats) && CBKillsByClass(stats, EnumInt(ECBVictimClass.MaxTac)) > 0 {
        topic = n"maxtac";
        mood = n"fear";
      }
    }

    // A generic fearful whisper needs V to be at least mildly notable; topical
    // whispers (boss / MaxTac) are always eligible.
    if Equals(topic, n"") && Equals(mood, n"fear") && dread < CBConfig.CivTierNotice() {
      return;
    }
    if RandF() > CBConfig.WhisperChance() {
      return;
    }

    npc.cbWhispered = true;
    this.m_whisperCooldownTicks = this.WhisperCooldownTicks();
    CBShowWhisper(game, faction, mood, topic);
  }

  private func WhisperCooldownTicks() -> Int32 {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.HasSettings() {
      return rt.GetSettings().whisperCooldown;
    }
    return 25;
  }
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

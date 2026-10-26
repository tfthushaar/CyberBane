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

// Set true once a Vendetta gang member has given V a spoken warning (spec §9.3).
@addField(ScriptedPuppet)
public let cbGangWarned: Bool;

func CBWarningsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().warnings;
}

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

    // Somewhere the game calls a safe area - an apartment, a clinic, a bar, a memorial.
    // Nobody there reacts to V, however frightening V is (spec §16).
    if sys.IsInSafeZone() {
      return;
    }

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
    let district = sys.GetCurrentDistrict();   // cached; kept off the hot path (crash safety)

    let npcs = reg.GetAll();
    let evaluated = 0;
    let i = 0;
    while i < ArraySize(npcs) && evaluated < CBConfig.NpcEvalPerTick() {
      let npc = npcs[i];
      i += 1;
      // Only touch an NPC that is attached and past its warm-up ticks (crash safety during
      // streaming). Cheap distance gate first: the Safety Gate queries the workspot system, so
      // only run it for NPCs actually in range. A dense registry then stays cheap per tick.
      if CBNpcSafe(sys, npc) {
        let dist = Vector4.Distance(ppos, npc.GetWorldPosition());
        if dist <= CBConfig.NpcEvalRadius() && CBSafetyGate.CanAffect(npc) {
          evaluated += 1;
          let faction = CBClassifyFaction(npc);

          // Recognition, rolled once per spawn and cached on the puppet (spec §8.7).
          if npc.cbRecoState == 0 {
            let p = score.RecognitionChance(district, faction, false, false);
            // Wearing this gang's colours makes them slower to place you (spec §9.3).
            if NotEquals(faction, n"") && Equals(faction, sys.GetDisguiseFaction()) {
              p *= (1.0 - sys.GetDisguiseStrength());
            }
            npc.cbRecoState = RandF() <= p ? 1 : 2;
          }
          let recognized = npc.cbRecoState == 1;

          // Vendetta gangs that recognise V attack on sight (spec §9.3); that overrides
          // any fear. Everyone else - civilians, gangers, cops - can read how dangerous V
          // looks and flee (spec §9.2), capped per tick.
          let turnedHostile = false;
          if !npc.IsCrowd() && gangOn && hostileOnSight && recognized {
            turnedHostile = this.TryGangHostile(score, player, npc, faction);
          }
          if !turnedHostile && civOn && civReacted < maxCiv {
            if CBFearReact(game, score, npc, dist, civIntensity, faction) {
              civReacted += 1;
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
  // Returns true when this NPC is engaging V (hostile or being warned), so the Director
  // knows not to let it flee from fear instead.
  private func TryGangHostile(score: ref<CBScoreEngine>, player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>, faction: CName) -> Bool {
    if Equals(faction, n"") {
      return false;
    }
    if CBTwrActive() {
      return false;   // They Will Remember owns hostility-on-sight in compat mode (spec §17)
    }
    if !Equals(score.GetPosture(faction), ECBPosture.Vendetta) {
      return false;   // not at war with you - they can still be scared off
    }
    // From here it is a Vendetta gang member: it is coming for you, not running.
    if npc.cbHostileByCyberbane {
      return true;
    }
    // They give you one warning before they open fire (spec §9.3), if enabled. The flip
    // to hostile lands on the next evaluation, which reads as a beat of hesitation.
    if CBWarningsOn() && !npc.cbGangWarned {
      npc.cbGangWarned = true;
      CBShowWhisper(player.GetGame(), faction, n"hate", n"warning");
      return true;
    }
    let agent = npc.GetAttitudeAgent();
    let pagent = player.GetAttitudeAgent();
    if !IsDefined(agent) || !IsDefined(pagent) {
      return true;
    }
    agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Hostile);
    npc.cbHostileByCyberbane = true;
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
      if Equals(faction, n"NCPD") && IsDefined(stats) && CBKillsByClass(sys, EnumInt(ECBVictimClass.MaxTac)) > 0 {
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

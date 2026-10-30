// Cyberbane - Runtime service (non-persistent global flags)
//
// Codeware ScriptableService. Holds session-only runtime state that must be
// reachable without a GameInstance (the service container accessor is static),
// so low-level helpers such as CBLog can read it. It stores nothing in saves.
//
// Settings pushes updates here; the kill switch (spec §16.3) and per-module
// error counters (spec §16.5) also live here.

public class CyberbaneRuntime extends ScriptableService {
  private let m_enabled: Bool = true;
  private let m_logLevel: Int32 = 1;   // CBLogLevelInfo
  private let m_settings: ref<CyberbaneSettings>;
  private let m_rewardDepth: Int32;    // nesting depth of the reward hook (see GigBonus)
  private let m_twrDetected: Int32;    // 0 = not scanned yet, 1 = present, 2 = absent
  private let m_ngpDetected: Int32;    // same three states, for New Game Plus
  private let m_securityZone: Int32 = 9;   // last zone the game reported; 9 = not heard yet
  // Why the last arrival was refused (CBBlock*). Diagnostic only, session-only.
  //
  // This exists because three releases in a row shipped with a different gate silently
  // refusing every spawn, and each one was found by reading code rather than by the mod
  // saying anything. A refusal that names itself turns a week of guessing into one sentence
  // from whoever is playing.
  private let m_lastSpawnBlock: Int32;
  // Which whisper line was used last, so the next one is never the same. Session only: it is
  // about what you just heard, and nothing about it is worth carrying into a save.
  private let m_lastWhisperIdx: Int32;

  public static func Get() -> ref<CyberbaneRuntime> {
    // The service container is null during world transitions (sleep, fast travel, Skip Time,
    // braindance entry). Calling GetService on a null container reads a null context and crashes,
    // so bail out and let callers treat the runtime as not-yet-available (crash safety).
    let container = GameInstance.GetScriptableServiceContainer();
    if !IsDefined(container) {
      return null;
    }
    return container.GetService(n"CyberbaneRuntime") as CyberbaneRuntime;
  }

  public func GetSettings() -> ref<CyberbaneSettings> {
    return this.m_settings;
  }

  public func SetSettings(settings: ref<CyberbaneSettings>) -> Void {
    this.m_settings = settings;
  }

  public func HasSettings() -> Bool {
    return IsDefined(this.m_settings);
  }

  public func IsEnabled() -> Bool {
    return this.m_enabled;
  }

  public func SetEnabled(value: Bool) -> Void {
    this.m_enabled = value;
  }

  // Reward-hook nesting. Granting a reward can grant another one (a job payout that pushes
  // Street Cred over a level hands out the level reward inside the same call), so the gig
  // bonus must only ever be worked out by the outermost call - otherwise the inner payout
  // and its bonus are both counted again by the outer one.
  public func EnterReward() -> Int32 {
    this.m_rewardDepth += 1;
    return this.m_rewardDepth;
  }

  public func ExitReward() -> Void {
    if this.m_rewardDepth > 0 {
      this.m_rewardDepth -= 1;
    }
  }

  // Cached result of the They Will Remember scan. The compat check is read per NPC per
  // tick, so the scan itself must happen once. Installed mods do not change while the
  // game is running, so caching it for the session is safe.
  public func GetTwrDetected() -> Int32 {
    return this.m_twrDetected;
  }

  public func SetTwrDetected(present: Bool) -> Void {
    this.m_twrDetected = present ? 1 : 2;
  }

  // New Game Plus rebuilds every NPC in the game to be harder. Stacking Cyberbane's own apex
  // multipliers on top of that produces something that cannot be killed, so the apex scales
  // itself back when New Game Plus is running.
  public func GetNgpDetected() -> Int32 {
    return this.m_ngpDetected;
  }

  public func SetNgpDetected(present: Bool) -> Void {
    this.m_ngpDetected = present ? 1 : 2;
  }

  // Last security area the game reported, as an ESecurityAreaType ordinal.
  public func GetSecurityZone() -> Int32 {
    return this.m_securityZone;
  }

  public func SetSecurityZone(value: Int32) -> Void {
    this.m_securityZone = value;
  }

  public func GetLastWhisperIndex() -> Int32 {
    return this.m_lastWhisperIdx;
  }

  public func SetLastWhisperIndex(idx: Int32) -> Void {
    this.m_lastWhisperIdx = idx;
  }

  public func GetLastSpawnBlock() -> Int32 {
    return this.m_lastSpawnBlock;
  }

  public func SetLastSpawnBlock(reason: Int32) -> Void {
    this.m_lastSpawnBlock = reason;
  }

  public func GetLogLevel() -> Int32 {
    return this.m_logLevel;
  }

  public func SetLogLevel(value: Int32) -> Void {
    this.m_logLevel = value;
  }
}

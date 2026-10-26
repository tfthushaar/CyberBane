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

  public func GetLogLevel() -> Int32 {
    return this.m_logLevel;
  }

  public func SetLogLevel(value: Int32) -> Void {
    this.m_logLevel = value;
  }
}

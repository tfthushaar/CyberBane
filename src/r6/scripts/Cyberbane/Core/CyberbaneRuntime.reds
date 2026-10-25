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

  public static func Get() -> ref<CyberbaneRuntime> {
    return GameInstance.GetScriptableServiceContainer().GetService(n"CyberbaneRuntime") as CyberbaneRuntime;
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

  public func GetLogLevel() -> Int32 {
    return this.m_logLevel;
  }

  public func SetLogLevel(value: Int32) -> Void {
    this.m_logLevel = value;
  }
}

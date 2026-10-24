// Cyberbane — Logging (spec §20)
//
// All logging goes through CBLog so the underlying call site is isolated in one
// place. If the game's log function name/signature needs adjusting after a compile
// against the target game version, only CBWriteLog below changes.
//
// Categories (CName): Core, Signals, Model, Director, Crowd, Gang, Morale,
// Police, Vendor, Rivals, Ledger, UI, Safety.

public func CBLogLevelOff() -> Int32 = 0
public func CBLogLevelInfo() -> Int32 = 1
public func CBLogLevelVerbose() -> Int32 = 2

public abstract class CBLog {
  public static func Info(category: CName, message: String) -> Void {
    CBWriteLog(CBLogLevelInfo(), category, message);
  }

  public static func Warn(category: CName, message: String) -> Void {
    CBWriteLog(CBLogLevelInfo(), category, s"[WARN] \(message)");
  }

  public static func Error(category: CName, message: String) -> Void {
    // Errors are always surfaced, regardless of configured level.
    CBEmitLogLine(category, s"[ERROR] \(message)");
  }

  public static func Verbose(category: CName, message: String) -> Void {
    CBWriteLog(CBLogLevelVerbose(), category, message);
  }
}

// Returns the configured log level, defaulting to Info before the runtime service
// is available (e.g. during very early script init).
func CBCurrentLogLevel() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    return rt.GetLogLevel();
  }
  return CBLogLevelInfo();
}

func CBWriteLog(level: Int32, category: CName, message: String) -> Void {
  if level > CBCurrentLogLevel() {
    return;
  }
  CBEmitLogLine(category, message);
}

func CBEmitLogLine(category: CName, message: String) -> Void {
  FTLog(s"[Cyberbane][\(NameToString(category))] \(message)");
}

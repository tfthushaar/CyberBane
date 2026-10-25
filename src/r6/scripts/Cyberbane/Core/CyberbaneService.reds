// Cyberbane - Global service (spec §6.3)
//
// Codeware ScriptableService. Persistent fields are stored globally (shared by
// all saves), which is what the Death Ledger needs so a killer can become a
// Rival across the reload that follows V's death (spec §10.8).
//
// The service must never hold references to game objects (Codeware guidance).

public class CBLedgerEntry {
  public persistent let id: Int32;
  public persistent let playthroughId: CName;
  public persistent let at: Float;                 // game seconds at death
  public persistent let district: CName;
  public persistent let killerRecordID: TweakDBID;
  public persistent let killerAppearance: CName;
  public persistent let killerFaction: CName;
  public persistent let killerRivalId: Int32;      // -1 if the killer was not a Rival
  public persistent let method: Int32;             // ECBKillMethod used on V
}

public class CyberbaneService extends ScriptableService {
  private persistent let m_schemaVersion: Int32;
  private persistent let m_nextLedgerId: Int32;
  private persistent let m_ledger: array<ref<CBLedgerEntry>>;   // cap 100 total, 30 per playthrough, FIFO

  public static func Get() -> ref<CyberbaneService> {
    return GameInstance.GetScriptableServiceContainer().GetService(n"CyberbaneService") as CyberbaneService;
  }

  // Bump the global schema version to the current build. (Global migrations, if
  // ever needed, run from here.)
  public func EnsureSchema() -> Void {
    if this.m_schemaVersion < CyberbaneSchemaVersion() {
      this.m_schemaVersion = CyberbaneSchemaVersion();
    }
  }

  public func GetLedger() -> array<ref<CBLedgerEntry>> {
    return this.m_ledger;
  }

  public func AllocateLedgerId() -> Int32 {
    let id = this.m_nextLedgerId;
    this.m_nextLedgerId += 1;
    return id;
  }

  // Records a death. The caller fills every field except `id`, which is assigned
  // here. Enforces the per-playthrough and global FIFO caps (spec §6.5).
  public func AppendLedgerEntry(entry: ref<CBLedgerEntry>) -> Void {
    if !IsDefined(entry) {
      return;
    }
    entry.id = this.AllocateLedgerId();
    ArrayPush(this.m_ledger, entry);
    this.TrimPlaythrough(entry.playthroughId);
    this.TrimTotal();
    CBLog.Info(n"Ledger", s"Recorded death id=\(entry.id) playthrough=\(NameToString(entry.playthroughId))");
  }

  private func TrimPlaythrough(playthroughId: CName) -> Void {
    let cap = CBConfig.CapLedgerPerPlaythrough();
    let count = 0;
    let i = ArraySize(this.m_ledger) - 1;
    // Count newest-first; drop the oldest matching entries beyond the cap.
    while i >= 0 {
      if Equals(this.m_ledger[i].playthroughId, playthroughId) {
        count += 1;
      }
      i -= 1;
    }
    while count > cap {
      let j = 0;
      while j < ArraySize(this.m_ledger) {
        if Equals(this.m_ledger[j].playthroughId, playthroughId) {
          ArrayErase(this.m_ledger, j);
          count -= 1;
          break;
        }
        j += 1;
      }
    }
  }

  private func TrimTotal() -> Void {
    let cap = CBConfig.CapLedgerTotal();
    while ArraySize(this.m_ledger) > cap {
      ArrayErase(this.m_ledger, 0);
    }
  }
}

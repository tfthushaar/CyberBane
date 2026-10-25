// Cyberbane — Death Ledger (spec §10.8)
//
// When V dies the game reloads an earlier save, so per-save state rolls back and a
// "Killer" Rival would never exist. The ledger lives in the global service, so a
// death is recorded immediately and re-applied on every later load of the same
// playthrough: the killer becomes (or is promoted to) a Rival.

public func CBWriteDeathLedger(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().deathsRemembered {
    return;
  }
  let service = CyberbaneService.Get();
  if !IsDefined(service) {
    return;
  }

  let entry = new CBLedgerEntry();
  entry.playthroughId = sys.GetPlaythroughId();
  entry.at = CBGameSeconds(game);
  entry.district = CBCurrentDistrict(game);
  entry.killerRivalId = -1;
  entry.method = 0;

  let killer: wref<ScriptedPuppet>;
  let sp = player as ScriptedPuppet;
  if IsDefined(sp) {
    killer = sp.cbLastAttacker;
  }
  if IsDefined(killer) {
    entry.killerRecordID = killer.GetRecordID();
    entry.killerFaction = CBClassifyFaction(killer);
    entry.killerAppearance = n"";   // appearance snapshot: S-01
  }

  service.AppendLedgerEntry(entry);
}

// Applied on session start (spec §10.8 step 2).
public func CBApplyDeathLedger(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().deathsRemembered {
    return;
  }
  let service = CyberbaneService.Get();
  if !IsDefined(service) {
    return;
  }
  let myId = sys.GetPlaythroughId();
  let content = CyberbaneContent.Get();

  for entry in service.GetLedger() {
    if Equals(entry.playthroughId, myId) && !sys.HasAppliedLedgerId(entry.id) {
      if entry.killerRivalId >= 0 {
        let existing = sys.FindRivalById(entry.killerRivalId);
        if IsDefined(existing) {
          CBRivalKilledV(existing, content, entry.at, entry.district);
        }
      } else {
        if NotEquals(entry.killerFaction, n"") && entry.killerRecordID != TDBID.None() {
          let created = CBCreateRival(sys, game, entry.killerFaction, entry.killerRecordID, entry.killerAppearance, ECBRivalSource.Killer, entry.district, entry.at);
          if IsDefined(created) {
            CBRivalKilledV(created, content, entry.at, entry.district);
            if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
              CBShowMessage(game, "Cyberbane: You died in this city. " + CBRivalDisplayName(content, created) + " remembers.", 5.0);
            }
          }
        }
      }
      sys.MarkAppliedLedgerId(entry.id);
    }
  }
}

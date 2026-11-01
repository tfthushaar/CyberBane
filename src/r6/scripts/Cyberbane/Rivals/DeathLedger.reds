// Cyberbane - Death Ledger (spec §10.8)
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
  entry.district = CBEventDistrict(sys, game);
  entry.killerRivalId = -1;
  entry.method = 0;

  // PlayerPuppet is already a ScriptedPuppet, so the attacker field reads straight off it.
  let killer: wref<ScriptedPuppet>;
  if IsDefined(player) {
    killer = player.cbLastAttacker;
  }
  if IsDefined(killer) {
    entry.killerRecordID = killer.GetRecordID();
    entry.killerFaction = CBClassifyFaction(killer);
    entry.killerAppearance = n"";   // appearance snapshot: S-01
  }

  service.AppendLedgerEntry(entry);

  // And promote them right now, rather than only on the next load.
  //
  // The ledger is applied at session start, which is the only moment that exists when dying
  // means reloading a save. It is not the only moment any more. Death alternatives such as
  // Fenix Rebirth put V back on their feet and the session carries on, so the killer was never
  // promoted at all for anybody running one, and the part of a nemesis system that makes it a
  // nemesis system was missing for them.
  //
  // Doing it here needs nothing from any other mod, which is the point. Cyberbane already
  // knows V died and already knows who did it: `cbLastAttacker` is set by the hit hook a few
  // lines up in CombatSignals.reds. Hooking a particular death-alternative mod to be told the
  // same thing added a hard dependency on that mod's own API, and a version of it that did not
  // carry that API broke redscript compilation for everyone who had it. Never reach into
  // another mod for something this mod already has.
  //
  // If the player does reload instead, none of this survives, because it is save state and the
  // save is about to be replaced by an older one. Marking the entry applied stops the ledger
  // promoting the same death a second time on a later load of a session that carried on.
  if IsDefined(killer) && CBPromoteKiller(game, entry.killerFaction, entry.killerRecordID, n"") {
    sys.MarkAppliedLedgerId(entry.id);
  }
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
  let content = CBContent(game);

  for entry in service.GetLedger() {
    if IsDefined(entry) && Equals(entry.playthroughId, myId) && !sys.HasAppliedLedgerId(entry.id) {
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
              CBPhoneFromGang(game, entry.killerFaction,
                CBRivalDisplayName(content, created) + " put you in the ground once. Remember that next time.");
            }
          }
        }
      }
      sys.MarkAppliedLedgerId(entry.id);
    }
  }
}

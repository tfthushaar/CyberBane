// Cyberbane - Death Ledger (spec §10.8)
//
// When V dies the game reloads an earlier save, so per-save state rolls back and a
// "Killer" Rival would never exist. The ledger lives in the global service, so a
// death is recorded immediately and re-applied on every later load of the same
// playthrough: the killer becomes (or is promoted to) a Rival.

// Called from V's death event (Signals/CombatSignals.reds), so it does only what has to happen there: the death goes
// into the ledger, which lives in the global service and which nothing else writes during play.
public func CBWriteDeathLedger(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> ref<CBLedgerEntry> {
  if !IsDefined(sys) {
    return null;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().deathsRemembered {
    return null;
  }
  let service = CyberbaneService.Get();
  if !IsDefined(service) {
    return null;
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
  let killerBody: EntityID;
  // Still in the world before their record is read.
  if IsDefined(killer) && killer.IsAttached() {
    entry.killerRecordID = killer.GetRecordID();
    entry.killerFaction = CBClassifyFaction(killer);
    entry.killerAppearance = killer.GetCurrentAppearanceName();
    killerBody = killer.GetEntityID();
    // Was it one of V's Rivals?
    let known = CBFindRivalByBody(sys, killerBody);
    if IsDefined(known) {
      entry.killerRivalId = known.id;
    }
  }

  service.AppendLedgerEntry(entry);
  return entry;
}

// The rest of V's death, on the frame after it (queued by CBOnPlayerDeath, Signals/CombatSignals.reds).
public class CBPlayerDeathCallback extends DelayCallback {
  public let entry: ref<CBLedgerEntry>;
  public let killerBody: EntityID;

  public func Call() -> Void {
    let game = GetGameInstance();
    let sys = CyberbaneSystem.Get(game);
    if !IsDefined(sys) {
      return;
    }
    let stats = sys.GetStats();
    if IsDefined(stats) {
      stats.deaths += 1;
    }
    let e = this.entry;
    if !IsDefined(e) {
      return;   // deaths are not remembered: the count is all there is
    }
    // In the file too. If V reloads this goes with the save it was written to; if a death
    // alternative carries V on, it stays, which is the right record either way.
    CBFileLog(sys, n"Death", e.at, e.district, e.killerFaction, 0.0);

    // And promote them right now, rather than only on the next load.
    if TDBID.IsValid(e.killerRecordID)
       && CBPromoteKiller(game, e.killerFaction, e.killerRecordID, n"", this.killerBody, e.killerAppearance) {
      sys.MarkAppliedLedgerId(e.id);
    }
  }
}

// The Killer Rivals this save got from deaths in `oldId`'s ledger that were another character's, for a save that turns
// out not to be the character its id is on record for (CyberbaneSystem.MoveToOwnPlaythrough).
public func CBForeignKillers(sys: ref<CyberbaneSystem>, svc: ref<CyberbaneService>, oldId: CName, now: Float) -> array<Int32> {
  let ids: array<Int32>;
  if !IsDefined(sys) || !IsDefined(svc) || !IsNameValid(oldId) {
    return ids;
  }
  let killer = EnumInt(ECBRivalSource.Killer);
  let ahead = now + CBConfig.ForeignDeathMarginSeconds();
  for e in svc.GetLedger() {
    if IsDefined(e) && Equals(e.playthroughId, oldId) && e.killerRivalId < 0 && e.at > ahead
       && sys.HasAppliedLedgerId(e.id) {
      for r in sys.GetRivals() {
        if IsDefined(r) && r.source == killer && r.recordID == e.killerRecordID && r.createdAt == e.at
           && Equals(r.origin, e.district) && !ArrayContains(ids, r.id) {
          ArrayPush(ids, r.id);
        }
      }
    }
  }
  return ids;
}

// A Killer Rival still out after V who looks exactly like this: the same gang, the same record and the same appearance.
public func CBKillerRivalLike(sys: ref<CyberbaneSystem>, faction: CName, record: TweakDBID,
                              look: CName) -> ref<CBRival> {
  if !IsDefined(sys) || Equals(faction, n"") || !TDBID.IsValid(record) {
    return null;
  }
  let killer = EnumInt(ECBRivalSource.Killer);
  for r in sys.GetRivals() {
    if IsDefined(r) && r.source == killer && r.recordID == record && Equals(r.faction, faction)
       && Equals(r.appearance, look)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
      return r;
    }
  }
  return null;
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
  // Deaths from before "Forget every rival" was chosen on any save of this playthrough make
  // nobody a Rival: forgetting them has to cover the ones a reload would otherwise bring back.
  let forgottenUpTo = -1;
  let note = service.GetForgetNote(myId);
  if IsDefined(note) {
    forgottenUpTo = note.ledgerUpTo;
  }

  for entry in service.GetLedger() {
    if IsDefined(entry) && Equals(entry.playthroughId, myId) && !sys.HasAppliedLedgerId(entry.id)
       && entry.id <= forgottenUpTo {
      sys.MarkAppliedLedgerId(entry.id);
    }
    if IsDefined(entry) && Equals(entry.playthroughId, myId) && !sys.HasAppliedLedgerId(entry.id) {
      // Said in the log, so a Rival that seems to come from nowhere can be traced to the death that made it, and to the
      // playthrough it was recorded in.
      CBLog.Info(n"Ledger", s"Applying death id=\(entry.id) of \(NameToString(myId)) from game time \(RoundF(entry.at)) in \(NameToString(entry.district)), killer \(NameToString(entry.killerFaction)).");
      if entry.killerRivalId >= 0 {
        let existing = sys.FindRivalById(entry.killerRivalId);
        if IsDefined(existing) {
          CBRivalKilledV(existing, content, entry.at, entry.district);
        }
      } else {
        if NotEquals(entry.killerFaction, n"") && entry.killerRecordID != TDBID.None() {
          // The same face as a Killer Rival this save already has: the same person, again.
          let again = CBKillerRivalLike(sys, entry.killerFaction, entry.killerRecordID, entry.killerAppearance);
          if IsDefined(again) {
            CBRivalKilledV(again, content, entry.at, entry.district);
            CBLog.Info(n"Ledger", s"Death id=\(entry.id) was by the same face as rival \(again.id); promoted them rather than making another.");
          } else {
            // Quiet: the line below is the one message this death is worth. CBCreateRival's own
            // "has your name now" on top of it made two texts out of one event.
            let created = CBCreateRival(sys, game, entry.killerFaction, entry.killerRecordID, entry.killerAppearance, ECBRivalSource.Killer, entry.district, entry.at, true);
            if IsDefined(created) {
              CBRivalKilledV(created, content, entry.at, entry.district);
              if CBMessagesOn() {
                CBPhoneFromGang(game, entry.killerFaction,
                  CBTf(n"Cyberbane-DeathLedger-PutYouInTheGroundOnce", [CBRivalDisplayName(content, created)]));
              }
            }
          }
        }
      }
      sys.MarkAppliedLedgerId(entry.id);
    }
  }
}

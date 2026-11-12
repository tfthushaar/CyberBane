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
  let killerBody: EntityID;
  if IsDefined(killer) {
    entry.killerRecordID = killer.GetRecordID();
    entry.killerFaction = CBClassifyFaction(killer);
    entry.killerAppearance = killer.GetCurrentAppearanceName();
    killerBody = killer.GetEntityID();
    // Was it one of V's Rivals? Asked of the body, never the record: Rivals are built from the
    // gang's ordinary records, which dozens of their people share, so matching on the record
    // credited any ganger who happened to share one with a Rival. Writing the Rival's id into
    // the entry also means a reload of an older save promotes that Rival instead of minting a
    // duplicate of them.
    let known = CBFindRivalByBody(sys, killerBody);
    if IsDefined(known) {
      entry.killerRivalId = known.id;
    }
  }

  service.AppendLedgerEntry(entry);
  // In the file too. If V reloads this goes with the save it was written to; if a death
  // alternative carries V on, it stays, which is the right record either way.
  CBFileLog(sys, n"Death", entry.at, entry.district, entry.killerFaction, 0.0);

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
  if IsDefined(killer) && CBPromoteKiller(game, entry.killerFaction, entry.killerRecordID, n"", killerBody, entry.killerAppearance) {
    sys.MarkAppliedLedgerId(entry.id);
  }
}

// The Killer Rivals this save got from deaths in `oldId`'s ledger that were another character's
// (1.8.3), for a save that turns out not to be the character its id is on record for
// (CyberbaneSystem.MoveToOwnPlaythrough).
//
// Matched exactly to the death that made each one: CBApplyDeathLedger hands CBCreateRival the
// death's record, place and time, and those stay as they were. Only deaths further ahead of this
// save's clock than ForeignDeathMarginSeconds count, because this V's own deaths under the shared
// id look exactly the same, and a V who died and reloaded is behind their death only by however
// long it was since the last save. A death that made nobody new (it promoted a Rival that already
// existed) is left alone: nothing in this save was made from it.
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

// A Killer Rival still out after V who looks exactly like this: the same gang, the same record and the
// same appearance (1.9.1). Two of them would wear the same face, which nobody could tell apart, so a
// second death by that face is the same person getting better at it. An appearance nobody wrote down
// only matches another nobody wrote down.
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
      // Said in the log, so a Rival that seems to come from nowhere can be traced to the death that
      // made it, and to the playthrough it was recorded in (1.8.3).
      CBLog.Info(n"Ledger", s"Applying death id=\(entry.id) of \(NameToString(myId)) from game time \(RoundF(entry.at)) in \(NameToString(entry.district)), killer \(NameToString(entry.killerFaction)).");
      if entry.killerRivalId >= 0 {
        let existing = sys.FindRivalById(entry.killerRivalId);
        if IsDefined(existing) {
          CBRivalKilledV(existing, content, entry.at, entry.district);
        }
      } else {
        if NotEquals(entry.killerFaction, n"") && entry.killerRecordID != TDBID.None() {
          // The same face as a Killer Rival this save already has: the same person, again (1.9.1).
          //
          // Dying to one fight and reloading the save before it, over and over, leaves a death in
          // the ledger for every try, and none of them is in that save's applied list, so each load
          // applied every one: the second load made the killer a Rival, the third made two Rivals of
          // them with two names, and every one of them texted "has your name now". The body that
          // killed V each time was the game's own NPC, never the Rival's, so the ledger had no id to
          // match them by. What it does have is how they looked.
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
                  CBRivalDisplayName(content, created) + " put you in the ground once. Remember that next time.");
              }
            }
          }
        }
      }
      sys.MarkAppliedLedgerId(entry.id);
    }
  }
}

// Cyberbane - Rivals made once the fight is over (1.9.1)
//
// "One small change I would suggest is that a rival be made maybe 30s - 60s after the fight ends.
// I just had a gun fight where I was told a rival had my name as he lay there knocked out by me."
//
// Every Rival a fight makes was made on the spot: somebody left breathing, somebody who got clear,
// the gang-mate who takes an officer's death personally, the one who steps into a slain Rival's
// place. Each was rolled, created and texted in the same second, so the phone said "has your name
// now" with the shooting still going on and the person it named lying at V's feet.
//
// The roll still happens on the spot, so the odds and the log read exactly as before, and it still
// counts towards the burst damping at once (CBRivalOdds), so the rest of the same fight is weighed
// against it. What waits is the Rival: they are made, and the street hears about them, once V has
// been out of combat for between half a minute and a minute, chosen afresh for each. Back into
// combat and the wait starts over. Somebody who was to come back but dies in the meantime - V goes
// back and finishes them - does not come back at all.
//
// Session only, like the escapees they come from: a load drops anybody still waiting, the same way it
// drops a fight that was still going on. The death ledger's Killer Rivals are not held: V's death ends
// the session anyway, and they are made on the next load, after the fight by definition.
//
// Crash safety: the queue is our own objects. The one engine read is the escapee's own body, behind
// CBNpcSafe, on a settled tick; everything else is what CBCreateRival already did where it was called.

public class CBPendingBirth {
  public let faction: CName;
  public let record: TweakDBID;
  public let appearance: CName;
  public let source: Int32;          // ECBRivalSource
  public let origin: CName;          // district
  public let at: Float;              // game seconds it was earned, the Rival's own record
  public let escapee: ref<CBEscapee>;   // somebody left breathing or who got clear; null for a successor
  public let inheritRank: Int32;     // a successor's rank; 0 starts them at the bottom
  public let predecessor: String;    // the slain Rival a successor picks up from
  public let calmNeeded: Int32;      // settled ticks out of combat before they are made
}

// Hold a Rival until the fight is over. The roll has already been made and won.
public func CBRivalAfterFight(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName,
                              record: TweakDBID, appearance: CName, source: ECBRivalSource,
                              origin: CName, at: Float, escapee: ref<CBEscapee>,
                              inheritRank: Int32, predecessor: String) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") || !TDBID.IsValid(record) {
    return;
  }
  let b = new CBPendingBirth();
  b.faction = faction;
  b.record = record;
  b.appearance = appearance;
  b.source = EnumInt(source);
  b.origin = origin;
  b.at = at;
  b.escapee = escapee;
  b.inheritRank = inheritRank;
  b.predecessor = predecessor;
  b.calmNeeded = RandRange(CBConfig.RivalBirthCalmMin(), CBConfig.RivalBirthCalmMax() + 1);
  // Counted now, so the rest of this fight's rolls are weighed against it (CBRivalOdds).
  sys.NoteRivalMade();
  // A queue this full is a long fight that never stops: the oldest is made now rather than lost.
  if sys.CountPendingBirths() >= CBConfig.RivalBirthQueueCap() {
    let oldest = sys.TakePendingBirth(0);
    if IsDefined(oldest) {
      CBRivalBirth(sys, game, oldest);
    }
  }
  sys.AddPendingBirth(b);
  CBLog.Info(n"Rivals", s"A Rival from \(NameToString(faction)) is made once the fight has been over for \(b.calmNeeded)s.");
}

// Once a settled tick: how long V has been out of combat, and at most one Rival made.
public func CBRivalBirthTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) {
    return;
  }
  if player.IsInCombat() {
    sys.SetCalmTicks(0);
  } else {
    sys.SetCalmTicks(Min(sys.GetCalmTicks() + 1, 100000));
  }
  let count = sys.CountPendingBirths();
  if count == 0 {
    return;
  }
  // One a tick: two names landing in the same second read as a list, not as two people.
  let calm = sys.GetCalmTicks();
  let i = 0;
  while i < count {
    let b = sys.PeekPendingBirth(i);
    if IsDefined(b) && calm >= b.calmNeeded {
      sys.TakePendingBirth(i);
      CBRivalBirth(sys, game, b);
      return;
    }
    i += 1;
  }
}

// Make the Rival now, and let the street hear about it.
func CBRivalBirth(sys: ref<CyberbaneSystem>, game: GameInstance, b: ref<CBPendingBirth>) -> Void {
  if !IsDefined(sys) || !IsDefined(b) {
    return;
  }
  let e = b.escapee;
  // Left breathing, or got clear, and dead since where they lay: a corpse does not come back. Only a
  // body still in the world can say so; one that streamed out was breathing when last seen.
  if IsDefined(e) && CBNpcSafe(sys, e.puppet) && e.puppet.IsDead() {
    CBLog.Info(n"Rivals", s"A Rival from \(NameToString(b.faction)) died before the fight was over; nobody comes back.");
    return;
  }
  let r = CBCreateRival(sys, game, b.faction, b.record, b.appearance, IntEnum<ECBRivalSource>(b.source),
                        b.origin, b.at, false, true);
  if !IsDefined(r) {
    return;   // refused: the roster is full, the faction is switched off, a story record
  }
  if IsDefined(e) {
    r.scarMask = e.scarMask;   // they remember how it went
    CBNoteEscapeeSeen(sys, game, r, e);
  }
  let spared = b.source == EnumInt(ECBRivalSource.Spared);
  let survivor = b.source == EnumInt(ECBRivalSource.Survivor);
  if spared || survivor {
    r.state = EnumInt(ECBRivalState.Hunting);
  }
  // A successor inherits the slain Rival's standing, one rung down (CBRivalSlain).
  if b.inheritRank > 1 {
    r.rank = Min(b.inheritRank, 4);
  }
  if !CBMessagesOn() {
    return;
  }
  let name = CBRivalDisplayName(CBContent(game), r);
  if spared {
    CBHearsayFromStreet(game, s"\(name) walked away from you breathing. They will not forget it.", n"");
  } else {
    if survivor {
      CBHearsayFromStreet(game, s"\(name) got clear of you. You have not seen the last of them.", n"");
    } else {
      if StrLen(b.predecessor) > 0 {
        CBHearsayFromGang(game, b.faction, name + " picks up where " + b.predecessor + " left off.", n"");
      }
    }
  }
}

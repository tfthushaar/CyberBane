// Cyberbane - Rivals made once the fight is over
//
// New Rivals from a fight (survivors, escapees, an officer's avenger, a fallen Rival's successor) are queued and made
// after the fight ends instead of in the middle of it.

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
  public let kinOf: Int32;           // the slain Rival a successor is family of; 0 none
}

// Hold a Rival until the fight is over. The roll has already been made and won.
public func CBRivalAfterFight(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName,
                              record: TweakDBID, appearance: CName, source: ECBRivalSource,
                              origin: CName, at: Float, escapee: ref<CBEscapee>,
                              inheritRank: Int32, predecessor: String, opt kinOf: Int32) -> Void {
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
  b.kinOf = kinOf;
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
  // Family is announced after it has the family's name: the gang texted "Tomas Castillo has your name now" and a moment
  // later Tomas Morales, the same Rival under the slain one's surname, texted V.
  let kinDead = b.kinOf > 0 ? sys.FindRivalById(b.kinOf) : null;
  let r = CBCreateRival(sys, game, b.faction, b.record, b.appearance, IntEnum<ECBRivalSource>(b.source),
                        b.origin, b.at, IsDefined(kinDead), true);
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
  // A successor inherits the slain Rival's standing, one rung down (CBRivalSlain), climbed the way every Rival climbs
  // (CBPromoteRival), so a rank three successor carries a rank three Rival's traits rather than a newcomer's one.
  let climb = Min(b.inheritRank, 4);
  let contentB = CBContent(game);
  while r.rank < climb {
    CBPromoteRival(r, contentB, b.at);
  }
  // Family: the slain Rival's surname, geared against what killed them, and they say why.
  let dead = b.kinOf > 0 ? sys.FindRivalById(b.kinOf) : null;
  if IsDefined(dead) {
    r.lastName = dead.lastName;
    CBRivalGiveTrait(r, CBKinTrait(dead.scarMask));
    let book = CBIntelBook.Get(game);
    if IsDefined(book) {
      book.AddKin(r.id, dead.id);
    }
    CBFileLog(sys, n"KinSworn", CBGameSeconds(game), b.origin, b.faction, Cast<Float>(r.id));
  }
  if !CBMessagesOn() {
    return;
  }
  let name = CBRivalDisplayName(CBContent(game), r);
  if IsDefined(dead) {
    CBPhoneFromGang(game, b.faction, CBTf(n"Cyberbane-Births-HasYourNameNowThatIs", [name]));
    CBPhoneSendTinted(game, name, CBTf(n"Cyberbane-Births-YouPutInTheGroundFamily", [s"\(b.predecessor)"]), CBHudRed());
    return;
  }
  if spared {
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-Births-WalkedAwayFromYouBreathingThey", [s"\(name)"]), n"");
  } else {
    if survivor {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-Births-GotClearOfYouYouHave", [s"\(name)"]), n"");
    } else {
      if StrLen(b.predecessor) > 0 {
        CBHearsayFromGangFinal(game, b.faction, CBTf(n"Cyberbane-Births-PicksUpWhereLeftOff", [name, b.predecessor]), n"");
      }
    }
  }
}

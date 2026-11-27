// Cyberbane - Into the crew from another mod
//
// A character another mod keeps (one of Night City Allies' companions, or anybody an add-on hands over) joins V's crew as
// one of Cyberbane's own members: called, kitted, ranked, paid and buried like the rest. Cyberbane spawns its own body for
// them when they are called, so the other mod has to send its copy away; Cyberbane's entry in Night City Allies' menu
// (bin/x64/plugins/cyber_engine_tweaks/mods/NightCityAllies/Interactions/cyberbane_crew.lua) does that in the same click.

// Why this one cannot come over now; "" when they can.
public func CBCrewJoinBlocked(game: GameInstance, record: TweakDBID) -> String {
  let book = CBCrewBook.Get(game);
  if !CBMyCrewOn() || !IsDefined(book) {
    return CBT(n"Cyberbane-CrewDoor-YourCrewIsSwitchedOff");
  }
  if !TDBID.IsValid(record) || !IsDefined(TweakDBInterface.GetCharacterRecord(record)) {
    return CBT(n"Cyberbane-CrewDoor-NobodyToBring");
  }
  if !book.HasRoom() {
    return CBT(n"Cyberbane-Crew-YourCrewSFull");
  }
  if CBCrewHasRecord(book, record) {
    return CBT(n"Cyberbane-CrewDoor-AlreadyOneOfYours");
  }
  return "";
}

// Somebody of this record already on the roster: the same person twice would be two of them at one call.
public func CBCrewHasRecord(book: ref<CBCrewBook>, record: TweakDBID) -> Bool {
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    if IsDefined(m) && m.record == record {
      return true;
    }
    i += 1;
  }
  return false;
}

// The name the game gives a character record, "" when it has none to show.
public func CBCharacterRecordName(record: TweakDBID) -> String {
  let rec = TweakDBInterface.GetCharacterRecord(record);
  if !IsDefined(rec) {
    return "";
  }
  let text = GetLocalizedTextByKey(rec.DisplayName());
  return StrLen(text) > 0 ? text : "";
}

// They join. `look` is the appearance they wear in the other mod, `name` what it calls them (their record's own name
// when empty), `source` the mod they come from, for the log, and `loyalty` how much they think of V there (0..100; at
// least what an ally starts on here). The new member's id, or 0 when they could not come.
public func CBCrewJoinFrom(game: GameInstance, record: TweakDBID, look: CName, name: String, source: CName, loyalty: Int32) -> Int32 {
  if StrLen(CBCrewJoinBlocked(game, record)) > 0 {
    return 0;
  }
  let sys = CyberbaneSystem.Get(game);
  let book = CBCrewBook.Get(game);
  if !IsDefined(sys) || !IsDefined(book) {
    return 0;
  }
  let now = CBGameSeconds(game);
  let m = book.Add(CBCrewAlly(), record, look, n"", 0, Max(Clamp(loyalty, 0, 100), CBConfig.MyCrewLoyaltyAlly()),
                   CBEventDistrict(sys, game), now, 0);
  if !IsDefined(m) {
    return 0;
  }
  let given = StrLen(name) > 0 ? name : CBCharacterRecordName(record);
  let names = CBCrewNameBook.Get(game);
  if StrLen(given) > 0 && IsDefined(names) {
    names.SetName(m.id, given);
  }
  CBCrewJoined(sys, game, m, CBLineOf([CBT(n"Cyberbane-CrewDoor-SoThisIsYourCrew"), CBT(n"Cyberbane-CrewDoor-YouWantMeIMIn")]));
  CBLog.Info(n"Crew", s"Somebody came over to V's crew from \(NameToString(source)).");
  return m.id;
}

// The door CET scripts open: Cyberbane's entry in Night City Allies' menu reaches it the way its own scripts reach theirs,
// GetScriptableSystemsContainer():Get("CBCrewDoor").
public class CBCrewDoor extends ScriptableSystem {
  public func CanJoin(record: TweakDBID) -> Bool {
    return StrLen(CBCrewJoinBlocked(this.GetGameInstance(), record)) == 0;
  }

  public func WhyNot(record: TweakDBID) -> String {
    return CBCrewJoinBlocked(this.GetGameInstance(), record);
  }

  public func Join(record: TweakDBID, look: CName, name: String, source: CName, loyalty: Int32) -> Int32 {
    return CBCrewJoinFrom(this.GetGameInstance(), record, look, name, source, loyalty);
  }

  // The words on the choice, in the language Cyberbane speaks.
  public func JoinLabel() -> String {
    return CBT(n"Cyberbane-CrewDoor-JoinMyCrew");
  }
}

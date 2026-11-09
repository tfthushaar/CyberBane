// Cyberbane - The game's own map, telling the truth about who runs a district
//
// The world map lists a district's gangs from its fixed record, so it would say Barghest over Dogtown
// for ever. Each entry is handed to its row as a record once the row exists, and that is the only
// thing changed here: when the listed gang has lost the district to somebody the record has never
// heard of, the row is given the new owners instead. No widget is touched.

@wrapMethod(WorldMapMenuGameController)
protected cb func OnGangListItemSpawned(gangWidget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
  let moved = CBMapGangInstead(GetGameInstance(), this.m_currentHoveredDistrict, userData as Affiliation_Record);
  if IsDefined(moved) {
    return wrappedMethod(gangWidget, moved);
  }
  return wrappedMethod(gangWidget, userData);
}

func CBMapGangInstead(game: GameInstance, hovered: gamedataDistrict, listed: ref<Affiliation_Record>) -> ref<Affiliation_Record> {
  if !IsDefined(listed) || !CBTurfWarsOn() {
    return null;
  }
  let sys = CyberbaneSystem.Get(game);
  let book = CBTurfBook.Get(game);
  let record = MappinUtils.GetDistrictRecord(hovered);
  if !IsDefined(sys) || !IsDefined(book) || !IsDefined(record) {
    return null;
  }
  let content = sys.GetContent();
  let index = CBDistrictIndex(CBMapGameDistrict(record.EnumName()));
  if !IsDefined(content) || index < 0 {
    return null;
  }
  let from = book.From(index);
  let holder = book.Holder(index);
  if Equals(from, n"") || !Equals(content.FactionForAffiliation(listed.EnumName()), from) {
    return null;
  }
  let prof = content.GetFaction(holder);
  // Somebody already at home in the district has a row of their own.
  if !IsDefined(prof) || ArraySize(prof.affiliations) == 0 || ArrayContains(prof.turf, CBDistrictAt(index)) {
    return null;
  }
  return TweakDBInterface.GetAffiliationRecord(TDBID.Create("Factions." + NameToString(prof.affiliations[0])));
}

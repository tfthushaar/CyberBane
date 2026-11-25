// Cyberbane - Who runs a district, on the game's map
//
// The world map lists a district's gangs from a fixed record. This swaps in who actually holds it now.

@wrapMethod(WorldMapMenuGameController)
protected cb func OnGangListItemSpawned(gangWidget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
  let moved = CBMapGangInstead(GetGameInstance(), this.m_currentHoveredDistrict, userData as Affiliation_Record);
  if IsDefined(moved) {
    wrappedMethod(gangWidget, moved);
    return true;
  }
  wrappedMethod(gangWidget, userData);
  return true;
}

func CBMapGangInstead(game: GameInstance, hovered: gamedataDistrict, listed: ref<Affiliation_Record>) -> ref<Affiliation_Record> {
  if !IsDefined(listed) || !CBTurfWarsOn() {
    return null;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().turfOnMap {
    return null;   // another mod has the map
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

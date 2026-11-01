// Cyberbane - Public add-on API (spec §14)
//
// Stable surface for third-party mods to extend the content registries and to
// read Cyberbane's live reputation values. Content registration goes through the
// global content service (no GameInstance needed); read queries take a
// GameInstance because reputation is per-save.
//
// RegisterDeed / RegisterTitle are added alongside the deed and title registries.

// Which wound this weapon leaves on the Rival who dealt it.
//
// Fenix Rebirth reports the weapon's `gamedataItemType` as a name, which is the same vocabulary
// Cyberbane's own scars use, so the mapping is a read and not a guess. Anything unrecognised
// counts as shot, which is what the overwhelming majority of deaths are.
public func CBScarForWeaponCategory(category: CName) -> Int32 {
  let c = NameToString(category);
  if StrContains(c, "Katana") || StrContains(c, "Knife") || StrContains(c, "Sword")
     || StrContains(c, "Blade") || StrContains(c, "Machete") || StrContains(c, "Axe") {
    return CBScarCut();
  }
  if StrContains(c, "Grenade") || StrContains(c, "Launcher") || StrContains(c, "Rocket") {
    return CBScarBurned();
  }
  if StrContains(c, "Cyberdeck") || StrContains(c, "Hack") || StrContains(c, "Program") {
    return CBScarFried();
  }
  return CBScarShot();
}

public abstract class CyberbaneAPI {
  // ---- Dying, for mods that let V get back up ----------------------------
  //
  // V was killed and did not reload. Hand over who did it and Cyberbane makes them the Rival
  // who did, or promotes the one who already was.
  //
  // Cyberbane has had this mechanic since the beginning, through the cross-save Death Ledger
  // (spec §10.8), and the ledger only ever applies at session start. That is the right place
  // for it when dying means reloading, and the wrong place when it does not: a death
  // alternative brings V back in the same session, so nothing in Cyberbane ever noticed. This
  // is the same promotion, applied now.
  //
  // `killerAffiliation` is the game's own affiliation enum name, the value of
  // `Character_Record.Affiliation().EnumName()`, which is what Cyberbane maps its own factions
  // from. `weaponCategory` is the `gamedataItemType` name and may be left empty. Returns true
  // if a Rival was created or promoted.
  //
  // Safe to call at any time and from any mod: everything it touches is checked, the player's
  // settings are honoured, and the Rival cap and the story-character guard both still apply,
  // so this can never conjure a Rival the player's own settings forbid.
  public static func ReportPlayerKilledBy(game: GameInstance, killerRecordID: TweakDBID,
                                          killerAffiliation: CName, weaponCategory: CName) -> Bool {
    let rt = CyberbaneRuntime.Get();
    if !IsDefined(rt) || !rt.IsEnabled() {
      return false;
    }
    if rt.HasSettings() && !rt.GetSettings().deathsRemembered {
      return false;
    }
    let sys = CyberbaneSystem.Get(game);
    let content = CBContent(game);
    if !IsDefined(sys) || !IsDefined(content) || !TDBID.IsValid(killerRecordID) {
      return false;
    }
    let faction = content.FactionForAffiliation(killerAffiliation);
    if Equals(faction, n"") {
      return false;   // not a gang Cyberbane tracks; nothing to pin this on
    }
    let now = CBGameSeconds(game);
    let district = CBEventDistrict(sys, game);

    // The one who did it may already be on the books. Promoting the existing Rival rather than
    // adding a second from the same record is what keeps a nemesis a nemesis.
    let who: ref<CBRival>;
    for r in sys.GetRivals() {
      if IsDefined(r) && r.recordID == killerRecordID
         && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)) {
        who = r;
      }
    }
    let isNew = false;
    if !IsDefined(who) {
      who = CBCreateRival(sys, game, faction, killerRecordID, n"", ECBRivalSource.Killer,
                          district, now);
      isNew = true;
    }
    if !IsDefined(who) {
      return false;   // refused: the roster is full, or this is somebody the story owns
    }
    CBRivalKilledV(who, content, now, district);
    who.scarMask = who.scarMask | CBScarForWeaponCategory(weaponCategory);

    // The gang saw it done. Standing is V's footing with them, and somebody who has put V down
    // is harder to frighten.
    let fs = sys.FindFaction(faction);
    if IsDefined(fs) {
      fs.standing = ClampF(fs.standing - CBConfig.DeathStandingDrop(), -100.0, 100.0);
    }
    if rt.HasSettings() && rt.GetSettings().toasts {
      let name = CBRivalDisplayName(content, who);
      if isNew {
        CBShowMessage(game, s"Cyberbane: \(name) put you down. They will be looking for you.", 5.0);
      } else {
        CBShowMessage(game, s"Cyberbane: \(name) put you down again. They are getting better at it.", 5.0);
      }
    }
    CBLog.Info(n"Rivals", s"Killed by \(NameToString(faction)) (\(TDBID.ToStringDEBUG(killerRecordID))); rival \(who.id) is now rank \(who.rank).");
    return true;
  }

  // ---- Content extension ------------------------------------------------
  public static func RegisterImplant(family: CName, score: Float, visible: Bool, archetype: ECBArchetype) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddImplant(CBMakeImplant(family, score, visible, EnumInt(archetype)));
    }
  }

  public static func RegisterLookTag(tag: CName, score: Float, disguise: Float, factionTag: CName) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddLookTag(CBMakeLookTag(tag, score, disguise, factionTag));
    }
  }

  public static func RegisterLookItem(record: TweakDBID, score: Float, disguise: Float, factionTag: CName) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      let item = new CBLookItemDef();
      item.record = record;
      item.score = score;
      item.disguise = disguise;
      item.factionTag = factionTag;
      content.AddLookItem(item);
    }
  }

  public static func RegisterDeed(def: ref<CBDeedDef>) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddDeed(def);
    }
  }

  public static func RegisterTitle(def: ref<CBTitleDef>) -> Void {
    let content = CyberbaneContent.Get();
    if IsDefined(content) {
      content.AddTitle(def);
    }
  }

  // ---- Read queries -----------------------------------------------------
  public static func GetRenown(game: GameInstance) -> Float {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return sys.GetScore().GetRenown();
    }
    return 0.0;
  }

  public static func GetDread(game: GameInstance) -> Float {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return sys.GetScore().GetDread();
    }
    return 0.0;
  }

  public static func GetStanding(game: GameInstance, faction: CName) -> Float {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return sys.GetScore().GetStanding(faction);
    }
    return 0.0;
  }

  public static func GetVersion() -> String {
    return CyberbaneVersion();
  }

  // ---- Actions ----------------------------------------------------------
  // Pay a gang you can buy off to drop a hostility / vendetta. Returns true on success.
  public static func BrokerPeace(game: GameInstance, faction: CName) -> Bool {
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(sys) {
      return CBBrokerPeace(sys, game, faction);
    }
    return false;
  }
}

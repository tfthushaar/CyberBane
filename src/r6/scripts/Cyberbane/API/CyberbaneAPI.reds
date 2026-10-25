// Cyberbane — Public add-on API (spec §14)
//
// Stable surface for third-party mods to extend the content registries and to
// read Cyberbane's live reputation values. Content registration goes through the
// global content service (no GameInstance needed); read queries take a
// GameInstance because reputation is per-save.
//
// RegisterDeed / RegisterTitle are added alongside the deed and title registries.

public abstract class CyberbaneAPI {
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
}

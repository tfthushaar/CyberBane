// Cyberbane - Every Rival name this save has ever used
//
// A Rival's name is two positions in the name lists, and the Rival it belongs to does not last: the roster keeps 32 of
// the fallen and drops the oldest, and "Forget every rival" empties it. The name has to outlive the person, because
// meeting somebody called the same as a Rival you already finished reads as that Rival coming back.

public class CBRivalNameBook extends ScriptableSystem {
  private persistent let m_names: array<CName>;

  public static func Get(game: GameInstance) -> ref<CBRivalNameBook> {
    // The systems container can be null during world transitions; never deref it then.
    let container = GameInstance.GetScriptableSystemsContainer(game);
    if !IsDefined(container) {
      return null;
    }
    return container.Get(n"CBRivalNameBook") as CBRivalNameBook;
  }

  public func Has(name: CName) -> Bool {
    return ArrayContains(this.m_names, name);
  }

  public func Remember(name: CName) -> Void {
    if !this.Has(name) {
      ArrayPush(this.m_names, name);
    }
  }
}

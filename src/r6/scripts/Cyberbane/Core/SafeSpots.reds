// Cyberbane - Safe places the engine's own test cannot see
//
// The game makes a place safe two ways: an engine safe area, which SafeAreaManager.IsPointInSafeArea knows, and a zone
// the story sets by a fact (PlayerPuppet.GetCurrentZoneType), which it does not. The Voodoo Boys' chapel in Pacifica is
// the second kind: V's hands are forced empty in there, and the point test said nobody was in a safe place, so people
// were sent into it. V's own zone is read as the game sets it (OnEnterSafeZone and OnExitSafeZone), and every spot V
// stands in such a zone is remembered, so nobody is placed there again.

@addField(PlayerPuppet)
public let cbZoneSafe: Bool;

@wrapMethod(PlayerPuppet)
private final func OnExitSafeZone() -> Void {
  wrappedMethod();
  this.cbZoneSafe = false;
}

// Spots V found safe that the engine's test does not know, kept with the save.
public class CBSafeSpotBook extends ScriptableSystem {
  private persistent let m_x: array<Float>;
  private persistent let m_y: array<Float>;
  private persistent let m_z: array<Float>;

  public static func Get(game: GameInstance) -> ref<CBSafeSpotBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBSafeSpotBook") as CBSafeSpotBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    let n = this.Count();
    ArrayResize(this.m_x, n);
    ArrayResize(this.m_y, n);
    ArrayResize(this.m_z, n);
  }

  public func Count() -> Int32 {
    return Min(ArraySize(this.m_x), Min(ArraySize(this.m_y), ArraySize(this.m_z)));
  }

  public func Near(at: Vector4, radius: Float) -> Bool {
    let i = 0;
    while i < this.Count() {
      if Vector4.Distance(at, new Vector4(this.m_x[i], this.m_y[i], this.m_z[i], 1.0)) <= radius {
        return true;
      }
      i += 1;
    }
    return false;
  }

  // A spot more, unless one is already this close; the oldest goes once the list is full.
  public func Learn(at: Vector4) -> Bool {
    if this.Near(at, CBConfig.SafeSpotSpacing()) {
      return false;
    }
    ArrayPush(this.m_x, at.X);
    ArrayPush(this.m_y, at.Y);
    ArrayPush(this.m_z, at.Z);
    while this.Count() > CBConfig.SafeSpotsKept() {
      ArrayErase(this.m_x, 0);
      ArrayErase(this.m_y, 0);
      ArrayErase(this.m_z, 0);
    }
    return true;
  }
}

// Is V in a zone the game made safe, whichever way it did?
public func CBPlayerZoneSafe(game: GameInstance) -> Bool {
  let player = GetPlayer(game);
  return IsDefined(player) && player.cbZoneSafe;
}

// Is this point somewhere the game keeps safe: an engine safe area, or a spot V found safe. Every check of a place for
// Cyberbane's people asks this.
public func CBPointInSafeArea(game: GameInstance, at: Vector4) -> Bool {
  let sam = GameInstance.GetSafeAreaManager(game);
  if IsDefined(sam) && sam.IsPointInSafeArea(at) {
    return true;
  }
  let book = CBSafeSpotBook.Get(game);
  return IsDefined(book) && book.Near(at, CBConfig.SafeSpotRadius());
}

// Every tick: V standing in a safe zone the engine's test does not know is a spot to remember.
public func CBSafeSpotTick(game: GameInstance) -> Void {
  let player = GetPlayer(game);
  if !IsDefined(player) || !player.cbZoneSafe || !CBWorldStable(game) {
    return;
  }
  let at = player.GetWorldPosition();
  let sam = GameInstance.GetSafeAreaManager(game);
  if !IsDefined(sam) || sam.IsPointInSafeArea(at) {
    return;
  }
  let book = CBSafeSpotBook.Get(game);
  if IsDefined(book) && book.Learn(at) {
    CBLog.Info(n"Spawn", s"A safe place the game's own test does not know, now kept clear: \(CBSubDistrictLabel(game)) (\(book.Count()) kept).");
  }
}

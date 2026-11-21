// Cyberbane - Cleared streets (2.6.1, experimental, off by default)
//
// "An option to actually clear out gangs when you kill them, like they don't respawn."
//
// The game's own people come from its spawners, and no script can switch a spawner off. What the game itself does
// with somebody it wants gone is let them run and mark them a despawn candidate (reactionComponent.script: a frightened
// passer-by flees and is taken out of the world once nobody can see them; ReactionSystem.MarkDespawnCandidate). That is
// what this uses, and nothing else: no body is deleted and nobody is removed where V can see it.
//
// When V wipes out a gang somewhere (ClearKills of theirs dead in one fight, and none of theirs left standing near the
// last body), that spot is theirs no more for ClearDays in-game days. Anybody of that gang who turns up within
// ClearRadius of it walks off, and the game takes them out of the world once out of sight. A quest's people, a
// vendor, anybody the Safety Gate keeps out, Cyberbane's own and anybody already fighting are never touched. Kept in
// its own book, so nothing already saved changes shape; switching the setting off stops it at once.

public class CBClearBook extends ScriptableSystem {
  private persistent let m_x: array<Float>;
  private persistent let m_y: array<Float>;
  private persistent let m_z: array<Float>;
  private persistent let m_gang: array<CName>;
  private persistent let m_until: array<Float>;   // game seconds

  public static func Get(game: GameInstance) -> ref<CBClearBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBClearBook") as CBClearBook : null;
  }

  public func Count() -> Int32 {
    return Min(ArraySize(this.m_gang), Min(ArraySize(this.m_until), Min(ArraySize(this.m_x), Min(ArraySize(this.m_y), ArraySize(this.m_z)))));
  }

  public func At(i: Int32) -> Vector4 {
    return new Vector4(this.m_x[i], this.m_y[i], this.m_z[i], 1.0);
  }

  public func Gang(i: Int32) -> CName {
    return this.m_gang[i];
  }

  public func Until(i: Int32) -> Float {
    return this.m_until[i];
  }

  // A spot of this gang's already near: its clock starts again rather than a second spot on top of it.
  public func Add(at: Vector4, gang: CName, until: Float) -> Void {
    let i = 0;
    while i < this.Count() {
      if Equals(this.m_gang[i], gang) && Vector4.Distance(this.At(i), at) <= CBConfig.ClearRadius() {
        this.m_until[i] = MaxF(this.m_until[i], until);
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_x, at.X);
    ArrayPush(this.m_y, at.Y);
    ArrayPush(this.m_z, at.Z);
    ArrayPush(this.m_gang, gang);
    ArrayPush(this.m_until, until);
    while this.Count() > CBConfig.ClearSpotsCap() {
      this.RemoveAt(0);
    }
  }

  public func Expire(now: Float) -> Void {
    let i = this.Count() - 1;
    while i >= 0 {
      if now > this.m_until[i] || this.m_until[i] - now > CBConfig.ClearDays() * CBConfig.SecondsPerDay() * 2.0 {
        this.RemoveAt(i);   // run out, or a clock from another save's future
      }
      i -= 1;
    }
  }

  private func RemoveAt(i: Int32) -> Void {
    ArrayErase(this.m_x, i);
    ArrayErase(this.m_y, i);
    ArrayErase(this.m_z, i);
    ArrayErase(this.m_gang, i);
    ArrayErase(this.m_until, i);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_x);
    ArrayClear(this.m_y);
    ArrayClear(this.m_z);
    ArrayClear(this.m_gang);
    ArrayClear(this.m_until);
  }
}

public func CBClearedStreetsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.IsEnabled() && rt.GetSettings().clearedStreets;
}

// At the end of a fight (Model/Encounter.reds): did V wipe a gang out of this spot? `gangBodies` is how many of the last
// gang V killed in it.
public func CBNoteWipedOut(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, at: Vector4, gangBodies: Int32) -> Void {
  if !CBClearedStreetsOn() || !IsDefined(sys) || Equals(gang, n"") || gangBodies < CBConfig.ClearKills()
     || !CBFactionFieldsSquads(gang) || (at.X == 0.0 && at.Y == 0.0) {
    return;
  }
  // None of theirs left standing near the last body: a gang that still holds the corner has not been cleared off it.
  let reg = sys.GetRegistry();
  if IsDefined(reg) {
    for p in reg.GetAll() {
      if CBNpcSafe(sys, p) && !p.IsDead() && CBStillStanding(p)
         && Vector4.Distance(p.GetWorldPosition(), at) <= CBConfig.ClearRadius() && Equals(CBClassifyFaction(p), gang) {
        return;
      }
    }
  }
  let book = CBClearBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  book.Add(at, gang, now + CBConfig.ClearDays() * CBConfig.SecondsPerDay());
  CBLog.Info(n"Street", s"V cleared \(NameToString(gang)) off a spot (\(gangBodies) of theirs). They stay away for \(CBConfig.ClearDays()) days.");
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBLineOf([s"Nobody from \(CBFactionLabel(gang)) will stand on that corner for a while. Not after what you did there.",
                                        s"\(CBCapFirst(CBFactionLabel(gang))) are giving that block a wide berth. Can't say I blame them."]), n"Cleared");
  }
}

// Now and then (Reactions/Director.reds): anybody of a cleared gang turning up at their old spot walks off, and the game
// takes them out of the world once out of sight. Once per person.
@addField(ScriptedPuppet)
public let cbClearedOff: Bool;

public func CBClearedStreetsTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBClearBook.Get(game);
  if !IsDefined(book) || !IsDefined(sys) {
    return;
  }
  book.Expire(CBGameSeconds(game));
  if !CBClearedStreetsOn() || book.Count() == 0 {
    return;
  }
  let reg = sys.GetRegistry();
  let reactions = GameInstance.GetReactionSystem(game);
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(reg) || !IsDefined(reactions) {
    return;
  }
  for p in reg.GetAll() {
    if IsDefined(p) && !p.cbClearedOff && CBNpcSafe(sys, p) && !p.IsDead() && CBStillStanding(p) && !p.IsCrowd()
       && !CBNpcInCombat(p) && !CBSentByUs(des, p) && CBSafetyGate.CanAffect(p) {
      let gang = CBClassifyFaction(p);
      let pos = p.GetWorldPosition();
      let i = 0;
      while i < book.Count() {
        if Equals(book.Gang(i), gang) && Vector4.Distance(pos, book.At(i)) <= CBConfig.ClearRadius() {
          p.cbClearedOff = true;
          CBOrderFlee(game, p, true);   // walking, not running: they are keeping clear, not fleeing a fight
          reactions.MarkDespawnCandidate(p.GetEntityID());
          CBLog.Verbose(n"Street", s"One of \(NameToString(gang)) kept clear of a spot V cleared.");
          break;
        }
        i += 1;
      }
    }
  }
}

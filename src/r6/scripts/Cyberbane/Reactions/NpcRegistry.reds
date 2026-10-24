// Cyberbane — NPC registry (spec §9.1)
//
// Holds weak references to attached NPC puppets, populated by the Entity/Attached
// Codeware callback. Despawned puppets' weak refs go undefined and are dropped by
// Prune() on the fast tick, so no detach bookkeeping is required.

public class CBNpcRegistry {
  private let m_npcs: array<wref<ScriptedPuppet>>;

  public func Add(puppet: ref<ScriptedPuppet>) -> Void {
    if !IsDefined(puppet) {
      return;
    }
    if puppet.IsPlayer() {
      return;
    }
    ArrayPush(this.m_npcs, puppet);
  }

  // Drop weak refs that have gone undefined (despawned / detached).
  public func Prune() -> Void {
    let i = 0;
    while i < ArraySize(this.m_npcs) {
      if !IsDefined(this.m_npcs[i]) {
        ArrayErase(this.m_npcs, i);
      } else {
        i += 1;
      }
    }
  }

  public func Count() -> Int32 {
    return ArraySize(this.m_npcs);
  }

  public func GetAll() -> array<wref<ScriptedPuppet>> {
    return this.m_npcs;
  }
}

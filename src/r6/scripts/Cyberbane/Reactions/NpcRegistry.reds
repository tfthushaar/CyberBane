// Cyberbane - NPC registry (spec §9.1)
//
// Holds weak references to attached NPC puppets, populated by the Entity/Attached
// Codeware callback. Despawned puppets' weak refs go undefined and are dropped by
// Prune() on the fast tick, so no detach bookkeeping is required.

// Upper bound on tracked NPCs. The director only evaluates the nearest handful per tick,
// so this just protects against pathological growth; live NPCs near V always fit.
public func CBRegistryCap() -> Int32 = 200

public class CBNpcRegistry {
  private let m_npcs: array<wref<ScriptedPuppet>>;
  // Whether Add may prune once more before the next tick's own prune (1.9.1).
  private let m_addPruneArmed: Bool;

  public func Add(puppet: ref<ScriptedPuppet>) -> Void {
    if !IsDefined(puppet) {
      return;
    }
    if puppet.IsPlayer() {
      return;
    }
    // Nor anything standing in for V: the photo mode's posed copy, a VR stand-in, the inventory
    // paperdoll. They are not people in the street, and the photo mode's copy, taken for one, had its
    // head turned by the crowd reactions. Photo mode is also when its copy attaches, so nothing that
    // attaches then is registered at all.
    if puppet.IsReplacer() || puppet.IsVRReplacer() || puppet.IsPaperdoll() {
      return;
    }
    let pms = GameInstance.GetPhotoModeSystem(puppet.GetGame());
    if IsDefined(pms) && pms.IsPhotoModeActive() {
      return;
    }
    // Hard cap so the registry can never grow without bound in dense crowds. If it is
    // full, prune despawned entries first; only skip the add if it is still full.
    //
    // Once between ticks, not on every add (1.9.1). Full is where a crowded street lives, and every
    // person streaming in then walked all two hundred entries asking each whether it was still
    // attached, to find, nearly always, that it was. The tick prunes every second anyway.
    if ArraySize(this.m_npcs) >= CBRegistryCap() {
      if this.m_addPruneArmed {
        this.m_addPruneArmed = false;
        this.PruneNow();
      }
      if ArraySize(this.m_npcs) >= CBRegistryCap() {
        return;
      }
    }
    ArrayPush(this.m_npcs, puppet);
  }

  // Drop weak refs that have gone undefined or detached (despawned / streamed out), so the
  // registry only ever yields NPCs that are still attached to the world. Called once a tick.
  public func Prune() -> Void {
    this.PruneNow();
    this.m_addPruneArmed = true;
  }

  // Let Add prune once more. The fast tick calls this every second, including the busy ones on which
  // the Director (and its prune) is skipped, so a full registry still makes room while the world streams.
  public func ArmPrune() -> Void {
    this.m_addPruneArmed = true;
  }

  private func PruneNow() -> Void {
    let i = 0;
    while i < ArraySize(this.m_npcs) {
      if !IsDefined(this.m_npcs[i]) || !this.m_npcs[i].IsAttached() {
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

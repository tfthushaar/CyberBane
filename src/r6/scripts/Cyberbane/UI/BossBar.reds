// Cyberbane - The boss health bar (spec §12)
//
// When the game fights a boss it puts a long red bar across the top of the screen with the
// name above it. An apex squad should get that treatment, because that bar is how the game
// tells you this one is different.
//
// Getting there took some finding out. The bar belongs to `BossHealthBarGameController`, and
// the obvious routes are all closed:
//   - NPC rarity is what the game keys the bar off, and there is no setter for it: a puppet's
//     rarity comes from its character record and cannot be changed on a live NPC.
//   - The record cannot be cloned and edited either; `TweakDBManager` is a RED4ext API and is
//     not reachable from redscript.
// What is reachable is the controller's own `AddBoss(ref<NPCPuppet>)`. So Cyberbane keeps hold
// of the controller when the HUD builds it, and hands it each apex as they arrive.
//
// Crash safety: the reference is weak and re-checked on every use, because the controller is
// rebuilt on load, fast travel and every HUD teardown. A missing controller means no bar, and
// no bar means the fight is slightly less dramatic, which is the correct way for this to fail.

// Catch the controller as the HUD builds it.
@wrapMethod(BossHealthBarGameController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    rt.SetBossBar(this);
  }
  return result;
}

// And let go of it when the HUD tears it down, so nothing holds a stale controller.
@wrapMethod(BossHealthBarGameController)
protected cb func OnUninitialize() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    rt.SetBossBar(null);
  }
  return wrappedMethod();
}

// Put this one on the bar.
//
// Declining is normal and quiet: the setting is off, the HUD has not built the bar yet, or the
// puppet is already boss grade and the game is going to do this by itself.
public func CBShowBossBar(npc: ref<ScriptedPuppet>) -> Void {
  let asNpc = npc as NPCPuppet;
  if !IsDefined(asNpc) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() || !rt.HasSettings() {
    return;
  }
  if !rt.GetSettings().apexBossBar {
    return;
  }
  // Already a boss or MaxTac by record: the game handles its own.
  let rarity = npc.GetNPCRarity();
  if Equals(rarity, gamedataNPCRarity.Boss) || Equals(rarity, gamedataNPCRarity.MaxTac) {
    return;
  }
  let bar = rt.GetBossBar();
  if !IsDefined(bar) {
    return;
  }
  bar.AddBoss(asNpc);
}

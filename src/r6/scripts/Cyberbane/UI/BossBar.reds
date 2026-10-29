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
// Tries the game's own boss bar first, because when it is available it is the real thing, and
// falls back to Cyberbane's own (UI/ThreatBar.reds) when it is not - which, on this patch, is
// essentially always. See the note at the top of ThreatBar.reds for everything that was tried.
public func CBShowBossBar(npc: ref<ScriptedPuppet>) -> Void {
  let asNpc = npc as NPCPuppet;
  if !IsDefined(asNpc) || !CBThreatBarOn() {
    return;
  }
  // Already a boss or MaxTac by record: the game draws its own and ours would double up.
  let rarity = npc.GetNPCRarity();
  if Equals(rarity, gamedataNPCRarity.Boss) || Equals(rarity, gamedataNPCRarity.MaxTac) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    let bar = rt.GetBossBar();
    if IsDefined(bar) {
      bar.AddBoss(asNpc);
      return;
    }
  }
  CBShowThreatBar(npc);
}

// Our own bar, pointed at this one.
public func CBShowThreatBar(npc: ref<ScriptedPuppet>) -> Void {
  let game = GetGameInstance();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) || !IsDefined(npc) {
    return;
  }
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(des) {
    return;
  }
  let id = npc.GetEntityID();
  let label = "HUNTING YOU";
  let name = "";
  if des.IsTagged(id, n"CB_Apex") {
    label = "APEX SQUAD";
  }
  if des.IsTagged(id, n"CB_Rival") {
    label = "RIVAL";
    let who = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(who) {
      name = CBRivalDisplayName(sys.GetContent(), who);
    }
  }
  if StrLen(name) == 0 {
    name = npc.GetDisplayName();
  }
  sys.GetThreatBar().Track(npc, label, name);
}

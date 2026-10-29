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

// Put this one on the bar.
//
// This used to hand the puppet to the game's own `BossHealthBarGameController.AddBoss` whenever
// that controller was reachable, and only fall back to Cyberbane's own bar when it was not.
// The controller is reachable essentially always, and `AddBoss` opens by rejecting anybody who
// is not a boss by record, so the call did nothing and the fallback never ran. That is the
// whole reason no bar was ever seen. The plumbing that held the controller is gone with it.
public func CBShowBossBar(npc: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc as NPCPuppet) || !CBThreatBarOn() {
    return;
  }
  // Already a boss or MaxTac by record: the game draws its own and ours would double up.
  let rarity = npc.GetNPCRarity();
  if Equals(rarity, gamedataNPCRarity.Boss) || Equals(rarity, gamedataNPCRarity.MaxTac) {
    return;
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
  // A Rival is a person, so they get their name. An apex squad member is one of four, so what
  // matters is which one - the same way a MaxTac drop is legible as a heavy, a blade, a
  // netrunner and a shooter rather than four interchangeable enemies.
  let label = "HUNTING YOU";
  // The gang, always. Three lanes can fire for three different gangs, so without this a Scav
  // apex squad arriving while a Valentinos crew is still on you reads as one mixed squad.
  let name = CBBarFactionLabel(CBClassifyFaction(npc));
  if StrLen(name) == 0 {
    name = npc.GetDisplayName();
  }
  if des.IsTagged(id, n"CB_Apex") {
    let role: ECBApexRole;
    if !CBArchetypeRole(CBRecordArchetype(npc.GetRecordID()), role) {
      role = ECBApexRole.Assault;
    }
    label = StrUpper(CBRoleName(role));
  }
  if des.IsTagged(id, n"CB_Rival") {
    label = "RIVAL";
    let who = sys.FindRivalById(sys.GetActiveRivalId());
    if IsDefined(who) {
      name = CBRivalDisplayName(sys.GetContent(), who);
    }
  }
  sys.GetThreatBar().Track(npc, label + "   -   " + name);
}

// The gang's name, as a bar wants it: no article, upper case. CBFactionLabel is written for
// prose ("the Valentinos"), which does not belong on a health bar.
func CBBarFactionLabel(id: CName) -> String {
  let label = CBFactionLabel(id);
  if StrLen(label) == 0 {
    return "";
  }
  return StrUpper(StrReplace(label, "the ", ""));
}

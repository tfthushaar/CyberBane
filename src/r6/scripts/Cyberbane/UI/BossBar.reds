// Cyberbane - The boss health bar (spec §12)
//
// When the game fights a boss it puts a long red bar across the top of the screen with the
// name above it. An apex squad should get that treatment, because that bar is how the game
// tells you this one is different.

// Put this one on the bar.
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
  // A Rival is a person, so they get their name.
  let label = CBT(n"Cyberbane-BossBar-HUNTINGYOU");
  // The gang, always. Three lanes can fire for three different gangs, so without this a Scav
  // apex squad arriving while a Valentinos crew is still on you reads as one mixed squad.
  let name = CBBarFactionLabel(CBClassifyFaction(npc));
  if StrLen(name) == 0 {
    name = npc.GetDisplayName();
  }
  if des.IsTagged(id, n"CB_Apex") {
    let role: ECBApexRole;
    // The chair they were actually given, which is what their kit came from. Falling back to the record's own archetype
    // only when there is no seat on file.
    if !CBApexSeatRole(npc, role) {
      if !CBArchetypeRole(CBRecordArchetype(npc.GetRecordID()), role) {
        role = ECBApexRole.Assault;
      }
    }
    label = StrUpper(CBRoleName(role));
  }
  // One of the hunters' ladder by what they are and their own name: the bar read "HUNTING YOU" over the game's name for
  // their record, a stranger's, when the HUD line and the scanner already called them by theirs.
  if des.IsTagged(id, n"CB_Bounty") {
    label = CBT(n"Cyberbane-Bounty-BOUNTYHUNTER");
    let hunter = CBBountyScannerName(npc);
    if StrLen(hunter) > 0 {
      name = StrUpper(hunter);
    }
  }
  if des.IsTagged(id, n"CB_Rival") {
    label = CBT(n"Cyberbane-Whereabouts-RIVAL");
    // Whose body it is, first: a Rival who came with the active one carries their own name.
    let who = CBFindRivalByBody(sys, id);
    if !IsDefined(who) {
      who = sys.FindRivalById(sys.GetActiveRivalId());
    }
    if IsDefined(who) {
      name = CBRivalDisplayName(sys.GetContent(), who);
    }
  }
  sys.GetThreatBar().Track(npc, label + "   -   " + name);
}

// The gang's name, as a bar wants it: no article, upper case. CBFactionLabel is written for
// prose ("the Valentinos"), which does not belong on a health bar.
func CBBarFactionLabel(id: CName) -> String {
  return StrUpper(CBFactionName(id));
}

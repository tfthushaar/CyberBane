// Cyberbane - A Rival's name in the scanner
//
// Scan somebody the game wrote, an NCPD target say, and the scanner gives you their name over
// their class: "Jotaro Shobo" above "Thug". Scan a Rival and it gave you the class alone, or
// whatever name happened to be on the character record they were respawned from - never the one
// they go by everywhere else in Cyberbane. A player put it plainly: the person whose texts you
// have been reading for an hour turns up and the scanner calls them a Racketeer.
//
// How the scanner gets a name. `NPCPuppet.CompileScannerChunks` builds a `ScannerName` chunk and
// writes it to the UI_ScannerModules blackboard, where `ScannerNPCHeaderGameController` picks it
// up. When the NPC has an archetype the chunk carries text params, TEXT_PRIMARY for the name and
// TEXT_SECONDARY for the archetype, which is the two-line header named NCPD targets get. So the
// hook below lets the game build everything exactly as it always does and then, for a Rival's
// body only, writes that same chunk again with the Rival's name in TEXT_PRIMARY. Every other
// module the scanner shows (level, health, faction, weaknesses, bounty) is the game's own.
//
// Checked line by line against the game's script source for both supported patches: 2.31 and
// 2.5 build the name chunk with identical code, and every call used here - the wrapped method's
// signature, ScannerName's setters, the record accessors, the preset lookup and
// ScriptedPuppetPS.GetForcedScannerPreset - exists with the same shape on both.
//
// Crash safety:
//   - The game's own method always runs first and its result is returned untouched, so a
//     failure in anything below can only ever cost the name, never the scan.
//   - Nothing here touches a native component of the NPC. It reads TweakDB records, walks
//     Cyberbane's own Rival list, and writes one blackboard value the game writes in the same
//     place on every scan.
//   - Anybody who is not a Rival's body costs one field read, one system lookup and a walk of
//     Cyberbane's own Rival list (at most 47 entries), and the scanner only recompiles when the
//     target's data has changed, not every frame.
//   - Every step is null-checked, and the name is only replaced when the game itself would show
//     one (the same scanner preset test the game uses), so a quest that hides somebody's name
//     cannot be overridden by this.

// Which Rival this body belongs to, once Cyberbane knows. Set when the body is set up
// (Spawn/Spawner.reds, CBApplySpawnSetup) and never persisted: the bodies are not saved either.
// Kept on the body rather than looked up from the encounter because the encounter forgets the
// body the moment the fight ends, and somebody you just put down should still read as
// themselves when you scan the corpse.
//
// A separate flag rather than "id above zero", because the first Rival on older saves has id 0.
@addField(ScriptedPuppet)
public let cbRivalId: Int32;

@addField(ScriptedPuppet)
public let cbIsRivalBody: Bool;

@wrapMethod(NPCPuppet)
public const func CompileScannerChunks() -> Bool {
  let compiled = wrappedMethod();
  let rival = CBScannerRival(this);
  if IsDefined(rival) {
    // A quest can force a different scanner preset on an NPC, and the game honours it before the
    // record's own. Read here because GetPS is protected and this is the one place it is in
    // reach. A Rival is spawned by Cyberbane, so in practice nothing ever forces one, but the
    // test costs nothing and keeps this to exactly the game's own rule.
    let forced: TweakDBID;
    let ps = this.GetPS();
    if IsDefined(ps) {
      forced = ps.GetForcedScannerPreset();
    }
    CBScannerShowRivalName(this, rival, forced);
  }
  return compiled;
}

// Mark a body as a Rival's. Called once the body is set up; also flags the scanner data stale so
// a scan that already ran on this body before set-up picks the name up next time it is looked at.
public func CBMarkRivalBody(puppet: ref<ScriptedPuppet>, r: ref<CBRival>) -> Void {
  if !IsDefined(puppet) || !IsDefined(r) {
    return;
  }
  puppet.cbRivalId = r.id;
  puppet.cbIsRivalBody = true;
  puppet.SetScannerDirty(true);
}

// The Rival this scanned body is, or null for everybody else.
//
// Only ever an exact answer: the id stamped on the body at set-up, or before set-up has run, the
// body Cyberbane recorded at spawn. Never the faction or "whoever is active" guesses that the kill
// attribution falls back on, because a wrong name in the scanner is worse than no name.
public func CBScannerRival(npc: ref<NPCPuppet>) -> ref<CBRival> {
  if !IsDefined(npc) {
    return null;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return null;   // the kill switch puts the scanner back to vanilla too
  }
  let sys = CyberbaneSystem.Get(npc.GetGame());
  if !IsDefined(sys) {
    return null;
  }
  let r: ref<CBRival>;
  if npc.cbIsRivalBody {
    r = sys.FindRivalById(npc.cbRivalId);
  } else {
    r = CBFindRivalByBody(sys, npc.GetEntityID());
  }
  // The body has to be built from this Rival's own record. Always true for a body Cyberbane made
  // for them; checked anyway so a stale id can never put one Rival's name on somebody else.
  if !IsDefined(r) || !TDBID.IsValid(r.recordID) || r.recordID != npc.GetRecordID() {
    return null;
  }
  return r;
}

// Write the name chunk again, the game's way, with the Rival's name in it.
public func CBScannerShowRivalName(npc: ref<NPCPuppet>, r: ref<CBRival>, forcedPreset: TweakDBID) -> Void {
  if !IsDefined(npc) || !IsDefined(r) {
    return;
  }
  let rec = TweakDBInterface.GetCharacterRecord(npc.GetRecordID());
  if !IsDefined(rec) {
    return;
  }
  // Would the game show a name for this NPC at all? Same preset, same precedence.
  let showName = false;
  if TDBID.IsValid(forcedPreset) {
    let forced = TweakDBInterface.GetScannerModuleVisibilityPresetRecord(forcedPreset);
    showName = IsDefined(forced) && forced.ShoulShowName();
  } else {
    let own = rec.ScannerModulePreset();
    showName = IsDefined(own) && own.ShoulShowName();
  }
  if !showName {
    return;
  }
  let game = npc.GetGame();
  let name = CBRivalDisplayName(CBContent(game), r);
  if StrLen(name) == 0 {
    return;
  }
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let bb = bbs.Get(GetAllBlackboardDefs().UI_ScannerModules);
  if !IsDefined(bb) {
    return;
  }
  // Their class stays underneath, the way the game shows it for named NPCs: Netrunner or Sniper
  // is worth knowing about somebody who has come to kill you. Those are the game's own archetype
  // names, read off the record, not Cyberbane's.
  let archetype: CName = n"";
  let data = rec.ArchetypeData();
  if IsDefined(data) && !rec.SkipDisplayArchetype() {
    let kind = data.Type();
    if IsDefined(kind) {
      archetype = kind.LocalizedName();
    }
  }
  let chunk = new ScannerName();
  if IsNameValid(archetype) {
    chunk.SetArchetype(true);
    let params = new inkTextParams();
    params.AddLocalizedString("TEXT_PRIMARY", name);
    params.AddLocalizedString("TEXT_SECONDARY", NameToString(archetype));
    chunk.SetTextParams(params);
  } else {
    chunk.Set(name);
  }
  bb.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerName, ToVariant(chunk));
}

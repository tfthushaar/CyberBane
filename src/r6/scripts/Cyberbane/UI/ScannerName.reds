// Cyberbane - A Rival's name in the scanner
//
// Scanning a Rival shows the name they go by in Cyberbane above their class, the way the game shows named NPCs.

// Which Rival this body belongs to, once Cyberbane knows. Set when the body is set up (Spawn/Spawner.reds,
// CBApplySpawnSetup) and never persisted: the bodies are not saved either.
@addField(ScriptedPuppet)
public let cbRivalId: Int32;

@addField(ScriptedPuppet)
public let cbIsRivalBody: Bool;

@wrapMethod(NPCPuppet)
public const func CompileScannerChunks() -> Bool {
  let compiled = wrappedMethod();
  let rival = CBScannerRival(this);
  // Somebody with a note of their own: their hands up. Their name stays the game's; the note goes beside it. One of the
  // hunters' ladder has a name of their own, and their place on the ladder under it.
  let note = IsDefined(rival) ? "" : CBScannerNote(this);
  if StrLen(note) > 0 {
    let forcedN: TweakDBID;
    let psN = this.GetPS();
    if IsDefined(psN) {
      forcedN = psN.GetForcedScannerPreset();
    }
    let named = CBBountyScannerName(this);
    if StrLen(named) == 0 {
      named = CBCrewScannerName(this);   // one of V's own crew (Reactions/Crew.reds)
    }
    if StrLen(named) == 0 && !this.IsDead() {
      named = this.cbApexName;          // an apex squad's people by name (Spawn/ApexSquad.reds)
    }
    CBScannerShowNote(this, note, forcedN, named);
  }
  if IsDefined(rival) {
    // A quest can force a different scanner preset on an NPC, and the game honours it before the record's own. Read
    // here because GetPS is protected and this is the one place it is in reach.
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

// What the scanner says beside somebody's own name, or "" for nothing: one with their hands up.
public func CBScannerNote(npc: ref<NPCPuppet>) -> String {
  if !IsDefined(npc) {
    return "";
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return "";
  }
  if npc.cbSurrendered {
    return CBT(n"Cyberbane-ScannerName-HANDSUP");
  }
  if npc.cbSergeant && !npc.IsDead() {
    return CBT(n"Cyberbane-ScannerName-CREWSERGEANT");
  }
  if NotEquals(npc.cbLookoutFor, n"") && !npc.IsDead() {
    return CBTf(n"Cyberbane-ScannerName-LOOKOUT", [StrUpper(CBFactionLabel(npc.cbLookoutFor))]);
  }
  // V's own crew, and whoever killed one of them (Reactions/Crew.reds).
  let crew = CBCrewScannerNote(npc);
  if StrLen(crew) > 0 {
    return crew;
  }
  let bounty = CBBountyScannerNote(npc);
  if StrLen(bounty) > 0 {
    return bounty;
  }
  // One of a gang's apex squad: their gang's best, and their place in the squad.
  if StrLen(npc.cbApexName) > 0 {
    let role: ECBApexRole;
    let place = CBApexSeatRole(npc, role) ? "  /  " + StrUpper(CBRoleName(role)) : "";
    return CBTf(n"Cyberbane-ScannerName-APEXSQUAD", [StrUpper(CBBarFactionLabel(CBClassifyFaction(npc))), place]);
  }
  // A scout's job ([U14]).
  let sys = CyberbaneSystem.Get(npc.GetGame());
  if IsDefined(sys) && CBIsScoutBody(sys, npc) && !npc.IsDead() {
    return CBTf(n"Cyberbane-ScannerName-SCOUT", [StrUpper(CBFactionLabel(CBClassifyFaction(npc)))]);
  }
  // How their gang sees V, beside their class ([U14]).
  let stance = CBScannerStance(npc);
  if StrLen(stance) > 0 {
    let rec = TweakDBInterface.GetCharacterRecord(npc.GetRecordID());
    let data = IsDefined(rec) ? rec.ArchetypeData() : null;
    let kind = IsDefined(data) ? data.Type() : null;
    let cls = IsDefined(kind) && !rec.SkipDisplayArchetype() ? GetLocalizedText(NameToString(kind.LocalizedName())) : "";
    return StrLen(cls) > 0 ? cls + "  /  " + stance : stance;
  }
  return "";
}

// The name chunk again, the game's way: their own name from their record (or the one given), the note as the line
// under it.
public func CBScannerShowNote(npc: ref<NPCPuppet>, note: String, forcedPreset: TweakDBID, opt named: String) -> Void {
  let rec = TweakDBInterface.GetCharacterRecord(npc.GetRecordID());
  if !IsDefined(rec) {
    return;
  }
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
  let name = StrLen(named) > 0 ? named : GetLocalizedTextByKey(rec.DisplayName());
  if StrLen(name) == 0 {
    return;
  }
  let bbs = GameInstance.GetBlackboardSystem(npc.GetGame());
  let bb = IsDefined(bbs) ? bbs.Get(GetAllBlackboardDefs().UI_ScannerModules) : null;
  if !IsDefined(bb) {
    return;
  }
  let chunk = new ScannerName();
  chunk.SetArchetype(true);
  let params = new inkTextParams();
  params.AddLocalizedString("TEXT_PRIMARY", name);
  params.AddLocalizedString("TEXT_SECONDARY", note);
  chunk.SetTextParams(params);
  bb.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerName, ToVariant(chunk));
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
  // Their class stays underneath, the way the game shows it for named NPCs: Netrunner or Sniper is worth knowing about
  // somebody who has come to kill you. Those are the game's archetype names, read off the record, not Cyberbane's.
  let archetype: CName = n"";
  let data = rec.ArchetypeData();
  if IsDefined(data) && !rec.SkipDisplayArchetype() {
    let kind = data.Type();
    if IsDefined(kind) {
      archetype = kind.LocalizedName();
    }
  }
  // And what they carry in them (Rivals/RivalMoments.reds, [U9]), beside their class.
  let chrome = CBRivalChromeShort(r);
  let chunk = new ScannerName();
  if IsNameValid(archetype) || StrLen(chrome) > 0 {
    chunk.SetArchetype(true);
    let params = new inkTextParams();
    params.AddLocalizedString("TEXT_PRIMARY", name);
    let under = IsNameValid(archetype) ? GetLocalizedText(NameToString(archetype)) : "";
    if StrLen(chrome) > 0 {
      under = StrLen(under) > 0 ? under + "  /  " + chrome : chrome;
    }
    params.AddString("TEXT_SECONDARY", under);
    chunk.SetTextParams(params);
  } else {
    chunk.Set(name);
  }
  bb.SetVariant(GetAllBlackboardDefs().UI_ScannerModules.ScannerName, ToVariant(chunk));
}

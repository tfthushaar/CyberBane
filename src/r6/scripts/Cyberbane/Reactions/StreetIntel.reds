// Cyberbane - The street talks (1.9.8)
//
// What V can learn about the Rivals comes from the street itself, in the ways V already deals with people:
//
//   Squeeze     grab a ganger (the game's own grab) and hold them. A few seconds and they talk: a Rival's
//               fatal flaw, where one is lying low, or who is coming for V. The loyal say nothing, the greedy
//               hold out longer, the scared give it up at once. Aiming (a human shield) or letting go ends
//               it unsaid. No new key: holding them is the question.
//   The downed  crouch over a ganger V put down alive and look at them: they give one thing up. A Rival's
//               body carries something about another of their gang.
//   Scans       a full scan of a ganger now and then turns up the same in their files. Once per person.
//   Informants  a Rival V spared twice (the Debtor) owes V, and texts two or three tips over the next days
//               before they call it square; now and then the last is a set-up. A ganger V has frightened
//               enough can be turned in a conversation ("You work for me now") and texts tips the same way.
//   The bubble  the game's talk icon over people nearby who really have word of a Rival: at most two.
//   Flaws       a rare high-rank Rival has one fatal flaw (a blade, something heavy, a bare fist, a quickhack,
//               an explosive). Meeting it kills them outright. The street is how V finds out which.
//
// Saves: what V has learnt and who owes V tips is the playthrough's, in its own system (CBIntelBook, the
// CBTurfBook pattern), so nothing already saved changes shape. A flaw itself is never stored: it follows
// from the Rival's id. Everything that happens here happens on the talk tick, never inside a game event:
// the hooks below only note who was grabbed or scanned.

// ---- What V knows ---------------------------------------------------------------------------------------

public class CBIntelBook extends ScriptableSystem {
  private persistent let m_flawKnown: array<Int32>;
  // Informants: the Rival who owes V (0 for a turned ganger), their gang, tips left, when the next is due
  // (game seconds), and whether the last is a set-up. The name they text as follows from the first two.
  private persistent let m_infRival: array<Int32>;
  private persistent let m_infFaction: array<CName>;
  private persistent let m_infTips: array<Int32>;
  private persistent let m_infNextAt: array<Float>;
  private persistent let m_infSetup: array<Bool>;
  // Rivals waiting for V at a place they named (Rivals/RivalLife.reds, 1.9.9), and kin: a Rival and the
  // slain Rival they are family of.
  private persistent let m_word: array<Int32>;
  private persistent let m_kinRival: array<Int32>;
  private persistent let m_kinOf: array<Int32>;

  public static func Get(game: GameInstance) -> ref<CBIntelBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBIntelBook") as CBIntelBook : null;
  }

  public func KnowsFlaw(id: Int32) -> Bool {
    return ArrayContains(this.m_flawKnown, id);
  }

  public func LearnFlaw(id: Int32) -> Void {
    if id > 0 && !ArrayContains(this.m_flawKnown, id) {
      ArrayPush(this.m_flawKnown, id);
    }
  }

  // The five informant arrays are saved, and read back by index. A save that holds them at different
  // lengths (cut short, or written by a build that pushed to one and not another) put every read past
  // the shortest one out of bounds, which is a crash, not an error. So the count is the shortest of them
  // (the SlotCount model), every read is checked, and anything past the shortest is trimmed before the
  // arrays are changed, so they stay in step from then on.
  private func AlignInformants() -> Void {
    let n = this.InformantCount();
    if ArraySize(this.m_infRival) > n { ArrayResize(this.m_infRival, n); }
    if ArraySize(this.m_infFaction) > n { ArrayResize(this.m_infFaction, n); }
    if ArraySize(this.m_infTips) > n { ArrayResize(this.m_infTips, n); }
    if ArraySize(this.m_infNextAt) > n { ArrayResize(this.m_infNextAt, n); }
    if ArraySize(this.m_infSetup) > n { ArrayResize(this.m_infSetup, n); }
  }

  public func AddInformant(rivalId: Int32, faction: CName, tips: Int32, firstAt: Float, setup: Bool) -> Void {
    this.AlignInformants();
    if rivalId > 0 && ArrayContains(this.m_infRival, rivalId) {
      return;
    }
    if ArraySize(this.m_infRival) >= 6 {
      this.RemoveInformant(0);
    }
    ArrayPush(this.m_infRival, rivalId);
    ArrayPush(this.m_infFaction, faction);
    ArrayPush(this.m_infTips, tips);
    ArrayPush(this.m_infNextAt, firstAt);
    ArrayPush(this.m_infSetup, setup);
  }

  public func InformantCount() -> Int32 {
    return Min(Min(Min(ArraySize(this.m_infRival), ArraySize(this.m_infFaction)), Min(ArraySize(this.m_infTips), ArraySize(this.m_infNextAt))),
               ArraySize(this.m_infSetup));
  }
  public func InformantRival(i: Int32) -> Int32 { return i >= 0 && i < this.InformantCount() ? this.m_infRival[i] : 0; }
  public func InformantFaction(i: Int32) -> CName { return i >= 0 && i < this.InformantCount() ? this.m_infFaction[i] : n""; }
  public func InformantTips(i: Int32) -> Int32 { return i >= 0 && i < this.InformantCount() ? this.m_infTips[i] : 0; }
  public func InformantDue(i: Int32) -> Float { return i >= 0 && i < this.InformantCount() ? this.m_infNextAt[i] : 0.0; }
  public func InformantSetup(i: Int32) -> Bool { return i >= 0 && i < this.InformantCount() && this.m_infSetup[i]; }

  public func SpendTip(i: Int32, nextAt: Float) -> Void {
    if i < 0 || i >= this.InformantCount() {
      return;
    }
    this.m_infTips[i] -= 1;
    this.m_infNextAt[i] = nextAt;
  }

  // Saved from their own gang: they have more to tell (Reactions/Allies.reds, [U12], 2.4.5).
  public func GiveTips(i: Int32, n: Int32) -> Void {
    if i < 0 || i >= this.InformantCount() {
      return;
    }
    this.m_infTips[i] += n;
  }

  public func RemoveInformant(i: Int32) -> Void {
    this.AlignInformants();
    if i < 0 || i >= this.InformantCount() {
      return;
    }
    ArrayErase(this.m_infRival, i);
    ArrayErase(this.m_infFaction, i);
    ArrayErase(this.m_infTips, i);
    ArrayErase(this.m_infNextAt, i);
    ArrayErase(this.m_infSetup, i);
  }

  public func SendWord(id: Int32) -> Void {
    if id > 0 && !ArrayContains(this.m_word, id) {
      ArrayPush(this.m_word, id);
    }
  }

  public func WordSent(id: Int32) -> Bool {
    return ArrayContains(this.m_word, id);
  }

  public func ClearWord(id: Int32) -> Void {
    ArrayRemove(this.m_word, id);
  }

  public func ClearWords() -> Void {
    ArrayClear(this.m_word);
  }

  public func AddKin(id: Int32, of: Int32) -> Void {
    // In step first, for the reason given above AlignInformants.
    let n = Min(ArraySize(this.m_kinRival), ArraySize(this.m_kinOf));
    if ArraySize(this.m_kinRival) > n { ArrayResize(this.m_kinRival, n); }
    if ArraySize(this.m_kinOf) > n { ArrayResize(this.m_kinOf, n); }
    if ArraySize(this.m_kinRival) >= 32 {
      ArrayErase(this.m_kinRival, 0);
      ArrayErase(this.m_kinOf, 0);
    }
    ArrayPush(this.m_kinRival, id);
    ArrayPush(this.m_kinOf, of);
  }

  public func KinOf(id: Int32) -> Int32 {
    let i = ArrayFindFirst(this.m_kinRival, id);
    return i >= 0 && i < ArraySize(this.m_kinOf) ? this.m_kinOf[i] : 0;
  }

  // Starting over: nothing learnt, nobody owes V.
  public func Clear() -> Void {
    ArrayClear(this.m_word);
    ArrayClear(this.m_kinRival);
    ArrayClear(this.m_kinOf);
    ArrayClear(this.m_flawKnown);
    ArrayClear(this.m_infRival);
    ArrayClear(this.m_infFaction);
    ArrayClear(this.m_infTips);
    ArrayClear(this.m_infNextAt);
    ArrayClear(this.m_infSetup);
  }
}

// ---- Settings ---------------------------------------------------------------------------------------------

public func CBIntelOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBStreetTalkOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().streetIntel);
}

public func CBFlawsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().rivalFlaws;
}

public func CBBubblesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBStreetTalkOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkBubbles);
}

public func CBInformantsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().informants;
}

// ---- Fatal flaws ------------------------------------------------------------------------------------------

// 0 none; 1 a blade, 2 something heavy, 3 a bare fist, 4 a quickhack, 5 an explosive. From the Rival's id,
// so it is the same every time and needs no saving.
public func CBRivalFlaw(r: ref<CBRival>) -> Int32 {
  if !IsDefined(r) || !CBFlawsOn() || r.rank < CBConfig.FlawMinRank() || r.id <= 0 {
    return 0;
  }
  let h = (r.id * 7919 + 1237) % 1000;
  if Cast<Float>(h % 100) >= CBConfig.FlawChance() * 100.0 {
    return 0;
  }
  return 1 + (h / 100) % 5;
}

public func CBFlawMethod(kind: Int32) -> Int32 {
  switch kind {
    case 1: return CBMethodBlade();
    case 2: return CBMethodBlunt();
    case 3: return CBMethodFists();
    case 4: return CBMethodQuickhack();
    case 5: return CBMethodExplosive();
  }
  return 0;
}

public func CBFlawWord(kind: Int32) -> String {
  switch kind {
    case 1: return "a blade";
    case 2: return "something heavy";
    case 3: return "a bare fist";
    case 4: return "a quickhack";
    case 5: return "explosives";
  }
  return "";
}

// The flaw as a person says it.
func CBFlawStory(kind: Int32) -> String {
  switch kind {
    case 1: return "Old knife wound that never closed right. One good cut and they bleed out.";
    case 2: return "Got a plate in their skull. Hit them with something heavy and that's it.";
    case 3: return "Glass jaw. Everybody knows. One clean punch and they don't get up.";
    case 4: return "Cheap chrome, never firewalled. Any netrunner could cook them.";
    case 5: return "Half their body's scars from the last blast that caught them. One more explosion and they're done.";
  }
  return "";
}

// The flaw as a file or a note has it.
func CBFlawFile(kind: Int32) -> String {
  switch kind {
    case 1: return "an open knife wound; a blade will finish them";
    case 2: return "a cracked skull plate; something heavy will finish them";
    case 3: return "a glass jaw; a clean punch will finish them";
    case 4: return "unshielded chrome; a quickhack will finish them";
    case 5: return "old burns; explosives will finish them";
  }
  return "";
}

// A blow that meets a Rival's flaw kills them, from the hit's follow-up on the next frame
// (Signals/CombatSignals.reds, CBHitFollowUpCallback): never on the hit thread itself.
public func CBFlawCheck(sys: ref<CyberbaneSystem>, game: GameInstance, p: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) || !IsDefined(p) || p.cbFlawStruck || p.IsDead() || !p.cbDamagedByPlayer {
    return;
  }
  let r = CBFindRivalByBody(sys, p.GetEntityID());
  let kind = CBRivalFlaw(r);
  if kind == 0 || (p.cbLastMethodMask & CBFlawMethod(kind)) == 0 {
    return;
  }
  let pools = GameInstance.GetStatPoolsSystem(game);
  let player = GetPlayer(game);
  if !IsDefined(pools) || !IsDefined(player) {
    return;
  }
  p.cbFlawStruck = true;
  pools.RequestSettingStatPoolValue(Cast<StatsObjectID>(p.GetEntityID()), gamedataStatPoolType.Health, 0.0, player);
  let book = CBIntelBook.Get(game);
  if IsDefined(book) {
    book.LearnFlaw(r.id);
  }
  CBFileLog(sys, n"FlawKill", CBGameSeconds(game), CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
  CBSystemNote(game, s"\(CBRivalDisplayName(sys.GetContent(), r)) had a fatal flaw: \(CBFlawWord(kind)). You found it.", 6.0);
  CBLog.Info(n"Intel", s"Rival \(r.id) killed by their fatal flaw (\(CBFlawWord(kind))).");
}

@addField(ScriptedPuppet)
public let cbFlawStruck: Bool;

// ---- What somebody gives up ---------------------------------------------------------------------------------

public func CBIntelNone() -> Int32 = 0
public func CBIntelFlaw() -> Int32 = 1
public func CBIntelLead() -> Int32 = 2
public func CBIntelComing() -> Int32 = 3

public class CBIntel {
  public let kind: Int32;
  public let name: String;
  public let flaw: Int32;
  public let place: String;
  public let pin: String;
  public let coming: String;
}

// One of this gang's Rivals with a flaw V does not know yet (any Rival, for somebody of no gang).
func CBIntelFlawRival(sys: ref<CyberbaneSystem>, book: ref<CBIntelBook>, faction: CName, exclude: Int32) -> ref<CBRival> {
  if !IsDefined(book) || !CBFlawsOn() {
    return null;
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && r.id != exclude && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting))
       && (Equals(faction, n"") || Equals(r.faction, faction)) && CBRivalFlaw(r) > 0 && !book.KnowsFlaw(r.id) {
      return r;
    }
  }
  return null;
}

// Who of this gang is on their way to V, in their words. "" when nobody is.
func CBIntelComingLine(sys: ref<CyberbaneSystem>, faction: CName) -> String {
  if Equals(faction, n"") {
    return "";
  }
  if Equals(sys.GetPendingSquadFaction(), faction) {
    return "Ours are already on their way to you. Minutes.";
  }
  if Equals(sys.GetPendingApexFaction(), faction) {
    return "They're sending their best after you. Soon.";
  }
  if Equals(sys.GetLaneTarget(CBLaneSquad()), faction) {
    return "Ours are putting a crew together for you. Won't be long.";
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, faction) && r.state == EnumInt(ECBRivalState.Hunting) {
      return s"\(CBRivalDisplayName(sys.GetContent(), r))'s out looking for you. Asking everybody.";
    }
  }
  return "";
}

// What somebody of this gang gives up, done (a flaw learnt, a lead marked), for the caller to put in words.
// A flaw or a lead, whichever there is (a coin between them when both are); otherwise who is coming.
public func CBIntelGive(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, faction: CName,
                        opt noComing: Bool, opt exclude: Int32) -> ref<CBIntel> {
  let out = new CBIntel();
  let content = sys.GetContent();
  let book = CBIntelBook.Get(game);
  let flawRival = CBIntelFlawRival(sys, book, faction, exclude);
  let lead = CBTalkRivalForFaction(sys, game, faction, exclude);
  let tally = CBTalkTallyFor(sys, game, faction);
  if IsDefined(lead) && (!IsDefined(tally) || tally.leaks >= CBConfig.TalkLeaksPerDay()) {
    lead = null;
  }
  if IsDefined(flawRival) && (!IsDefined(lead) || RandF() < 0.5) {
    out.kind = CBIntelFlaw();
    out.name = CBRivalDisplayName(content, flawRival);
    out.flaw = CBRivalFlaw(flawRival);
    book.LearnFlaw(flawRival.id);
    CBFileLog(sys, n"FlawLearned", CBGameSeconds(game), CBEventDistrict(sys, game), flawRival.faction, Cast<Float>(flawRival.id));
    CBLog.Info(n"Intel", s"V learnt rival \(flawRival.id)'s fatal flaw.");
    return out;
  }
  if IsDefined(lead) {
    let s = CBRivalHideout(sys, game, player, lead);
    if IsDefined(s) {
      let now = CBGameSeconds(game);
      CBMarkLeadTold(sys, s, faction, now);
      tally.leaks += 1;
      CBFileLog(sys, n"Informant", now, CBEventDistrict(sys, game), faction, Cast<Float>(lead.id));
      out.kind = CBIntelLead();
      out.name = CBRivalDisplayName(content, lead);
      out.place = CBPlacePhrase(s.district);
      out.pin = CBMapMarkersOn() ? " It's on your map." : "";
      CBLog.Info(n"Intel", s"Rival \(lead.id) given up by the street.");
      return out;
    }
  }
  if !noComing {
    out.coming = CBIntelComingLine(sys, faction);
    if StrLen(out.coming) > 0 {
      out.kind = CBIntelComing();
    }
  }
  return out;
}

// Said by somebody V has hold of, or standing over.
func CBIntelSpoken(i: ref<CBIntel>) -> String {
  if i.kind == CBIntelFlaw() {
    return s"\(i.name)? \(CBFlawStory(i.flaw))";
  }
  if i.kind == CBIntelLead() {
    return CBPick3(s"\(i.name)'s lying low \(i.place). That's all I know!\(i.pin)",
                          s"Okay! \(i.name), \(i.place). Let go!\(i.pin)",
                          s"\(i.name) is holed up \(i.place). Please.\(i.pin)");
  }
  if i.kind == CBIntelComing() {
    return i.coming;
  }
  return CBPick3("I don't know anything! I swear!", "Nothing! I got nothing!", "I'm nobody, I don't hear anything!");
}

// As a file, a note or a text has it.
func CBIntelWritten(i: ref<CBIntel>) -> String {
  if i.kind == CBIntelFlaw() {
    return s"\(i.name): \(CBFlawFile(i.flaw)).";
  }
  if i.kind == CBIntelLead() {
    return s"\(i.name) is lying low \(i.place).\(i.pin)";
  }
  return i.coming;
}

// The Rival someone of this gang could give up: one of their own, then one of a gang at war with theirs;
// for somebody of no gang, anybody's. Whereabouts the Hub could sell, so the two never disagree.
public func CBTalkRivalForFaction(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, opt exclude: Int32) -> ref<CBRival> {
  if !IsDefined(sys) || !CBHideoutsOn() {
    return null;
  }
  let enemies: array<CName>;
  if NotEquals(faction, n"") {
    let own = CBTalkLeadFor(sys, game, faction);
    if IsDefined(own) && own.id != exclude {
      return own;
    }
    enemies = CBGangRivalsOf(sys.GetContent(), faction);
  }
  for r in sys.GetRivals() {
    if IsDefined(r) && r.id != exclude && CBWhereaboutsForSale(sys, game, r) == 0 && (Equals(faction, n"") || ArrayContains(enemies, r.faction)) {
      return r;
    }
  }
  return null;
}

// ---- Turning a ganger (asked in a conversation, Reactions/TalkTopics.reds) ------------------------------------

public func CBIntelTurn(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) || Equals(t.faction, n"") {
    return CBTalkSay("Work for you? No.", n"");
  }
  let temper = CBTalkTemper(t.npc);
  let chance = CBTalkNerveGap(t) * 1.2 + CBConfig.TurnBase();
  if t.mood == CBTalkAfraid() {
    chance += 0.2;
  }
  if temper == CBTalkTemperGreedy() {
    chance += 0.1;
  }
  if temper != CBTalkTemperLoyal() && RandF() < ClampF(chance, 0.05, 0.8) {
    // Frightened enough, they join V instead of informing (Reactions/Crew.reds, [C2], 2.5.0).
    let joined = CBCrewFrightenedJoins(sys, game, t);
    if IsDefined(joined) {
      return joined;
    }
    // The question is there for the crew alone when the informants are off (Reactions/StreetTalk.reds, 2.5.0).
    if !CBInformantsOn() {
      CBStandDownFromV(game, t.npc);
      return CBTalkSay(CBPick2("Work for you? I... no. But I'll stay out of your way. Swear.",
                               "Not that. Anything but that. I never saw you, alright?"), n"fear_beg");
    }
    let now = CBGameSeconds(game);
    book.AddInformant(0, t.faction, 2, now + RandRangeF(3.0, 6.0) * 3600.0, RandF() < CBConfig.InformantSetupChance());
    CBFileLog(sys, n"Turned", now, CBEventDistrict(sys, game), t.faction, 0.0);
    CBLog.Info(n"Intel", s"V turned one of \(NameToString(t.faction)) into an informant.");
    CBStandDownFromV(game, t.npc);
    return CBTalkSay(CBPick2("Okay. Okay. I hear things, I'll text you. Just don't tell anyone.",
                                    "Fine. I'll keep my ears open. Now get away from me before somebody sees."), n"");
  }
  // They tell their own instead.
  CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost() * CBCodeInsult(t.faction) * 0.5);
  let lead = CBTalkLeadFor(sys, game, t.faction);
  if IsDefined(lead) && lead.state != EnumInt(ECBRivalState.Hunting) {
    lead.state = EnumInt(ECBRivalState.Hunting);
    CBPhoneSendTinted(game, CBRivalDisplayName(sys.GetContent(), lead),
                      "Heard you're trying to buy my people. Come buy me.", CBHudRed());
  }
  CBLog.Info(n"Intel", s"One of \(NameToString(t.faction)) would not be turned, and told their own.");
  return CBTalkSay(CBPick2("Rat on my own? I'm telling them you asked.", "You picked the wrong one. Everybody's going to hear about this."), n"bump");
}

// ---- The hooks: who was grabbed, who was scanned ---------------------------------------------------------------

// The game's grab (locomotionTakedown.script): noted, nothing more. The talk tick does the rest.
@wrapMethod(GrappleStandEvents)
public func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let target = this.stateMachineInitData.target as ScriptedPuppet;
  if IsDefined(target) && IsDefined(scriptInterface.executionOwner) {
    let intel = CBStreetIntelFor(scriptInterface.executionOwner.GetGame());
    if IsDefined(intel) {
      intel.NoteGrab(target);
    }
  }
}

@wrapMethod(GrappleStandEvents)
public func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if IsDefined(scriptInterface.executionOwner) {
    let intel = CBStreetIntelFor(scriptInterface.executionOwner.GetGame());
    if IsDefined(intel) {
      intel.NoteRelease();
    }
  }
}

@wrapMethod(ScriptedPuppet)
protected cb func OnScanningEvent(evt: ref<ScanningEvent>) -> Bool {
  let result = wrappedMethod(evt);
  if IsDefined(evt) && Equals(evt.state, gameScanningState.Complete) && !this.cbIntelScanned {
    let intel = CBStreetIntelFor(this.GetGame());
    if IsDefined(intel) {
      intel.NoteScan(this);
    }
  }
  return result;
}

@addField(ScriptedPuppet)
public let cbIntelGiven: Bool;

@addField(ScriptedPuppet)
public let cbIntelScanned: Bool;

public func CBStreetIntelFor(game: GameInstance) -> ref<CBStreetIntel> {
  let sys = CyberbaneSystem.Get(game);
  let talk = IsDefined(sys) ? sys.GetStreetTalk() : null;
  return IsDefined(talk) ? talk.GetIntel() : null;
}

func CBPlayerAiming(game: GameInstance) -> Bool {
  let psm = CBPlayerPSM(game);
  return IsDefined(psm) && psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody) == EnumInt(gamePSMUpperBodyStates.Aim);
}

func CBIntelSay(game: GameInstance, slot: Int32, speaker: String, line: String, seconds: Float) -> Void {
  if CBGameSubtitlesOn(game) {
    CBShowGameSubtitle(game, slot, speaker, line, seconds);
  } else {
    CBOverheard(game, speaker, line);
  }
}

func CBIntelSpeaker(faction: CName) -> String {
  let w = CBFactionMemberWord(faction);
  return StrLen(w) > 0 ? w : "Ganger";
}

// ---- The street, on the talk tick -------------------------------------------------------------------------------

public class CBStreetIntel {
  private let m_grab: wref<ScriptedPuppet>;
  private let m_grabFor: Float;
  private let m_grabNeed: Float;
  private let m_grabShown: Int32;
  private let m_down: wref<ScriptedPuppet>;
  private let m_downFor: Float;
  private let m_scans: array<wref<ScriptedPuppet>>;
  private let m_bubbleIn: Float;
  private let m_bubbleOwner: array<wref<ScriptedPuppet>>;
  private let m_bubblePin: array<NewMappinID>;
  private let m_informIn: Float;
  // A Rival's people at their place (Rivals/RivalLife.reds, CBLairGuards), and which have fallen.
  private let m_guardIds: array<EntityID>;
  private let m_guardDown: array<Bool>;
  private let m_guardRival: Int32;
  private let m_guardIn: Float;

  public func NoteGuard(id: EntityID, rivalId: Int32) -> Void {
    ArrayPush(this.m_guardIds, id);
    ArrayPush(this.m_guardDown, false);
    this.m_guardRival = rivalId;
  }

  // The Rival's people at their place, for the alarm (Rivals/Whereabouts.reds, [U10]).
  public func GuardIds() -> array<EntityID> {
    return this.m_guardIds;
  }

  public func ClearGuards() -> Void {
    ArrayClear(this.m_guardIds);
    ArrayClear(this.m_guardDown);
    this.m_guardRival = 0;
  }

  // Each of a Rival's people who falls while the Rival is still up costs the Rival some nerve (health),
  // and the Rival says so.
  private func Guards(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    if this.m_guardRival == 0 {
      return;
    }
    let r = sys.FindRivalById(this.m_guardRival);
    let body = IsDefined(r) ? GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet : null;
    if !IsDefined(body) || CBIsDown(body) {
      this.ClearGuards();
      return;
    }
    if !body.IsAttached() {
      return;   // on their way in or out of the world: asked again next pass (2.4.2)
    }
    let i = 0;
    while i < ArraySize(this.m_guardIds) {
      if !this.m_guardDown[i] {
        let g = GameInstance.FindEntityByID(game, this.m_guardIds[i]) as ScriptedPuppet;
        if CBIsDown(g) {
          this.m_guardDown[i] = true;
          let pools = GameInstance.GetStatPoolsSystem(game);
          let sid = Cast<StatsObjectID>(body.GetEntityID());
          if IsDefined(pools) {
            let cur = pools.GetStatPoolValue(sid, gamedataStatPoolType.Health, true);
            // Read as a percentage, so written as one (the last flag): without it this set that many hit
            // points, and a Rival at 80% dropped to 65 hit points the moment one of their people fell.
            pools.RequestSettingStatPoolValue(sid, gamedataStatPoolType.Health, MaxF(cur - CBConfig.GuardNerveLoss(), 10.0), GetPlayer(game), true);
          }
          CBIntelSay(game, 3, CBRivalDisplayName(sys.GetContent(), r),
                     CBPick3("You'll pay for that!", "No! Get them, get them!", "That's it. Now it's personal."), 3.0);
        }
      }
      i += 1;
    }
  }

  // A Rival's people at their place walk a short beat round it, now and then, one order each (2.4.4, [U10]). Only
  // while nobody is fighting: a guard who has seen V is the fight's.
  private let m_guardBeatTick: Int32;

  private func GuardBeat(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
    let tick = sys.GetTickCount();
    if this.m_guardRival == 0 || tick - this.m_guardBeatTick < CBConfig.GuardBeatTicks() {
      return;
    }
    this.m_guardBeatTick = tick;
    let r = sys.FindRivalById(this.m_guardRival);
    let body = IsDefined(r) ? GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet : null;
    if !CBNpcSafe(sys, body) || CBNpcInCombat(body) {
      return;
    }
    let anchor = body.GetWorldPosition();
    let i = 0;
    while i < ArraySize(this.m_guardIds) {
      let g = GameInstance.FindEntityByID(game, this.m_guardIds[i]) as ScriptedPuppet;
      i += 1;
      if CBNpcSafe(sys, g) && CBStillStanding(g) && !CBNpcInCombat(g) && !g.cbTalkPartner && !g.cbMoraleBroken {
        let ang = RandRangeF(0.0, 6.28318);
        let reach = RandRangeF(CBConfig.GuardBeatMin(), CBConfig.GuardBeatMax());
        let spot: Vector4;
        if CBNavSnap(game, anchor.X + CosF(ang) * reach, anchor.Y + SinF(ang) * reach, anchor.Z, spot)
           && CBPointReachable(game, g.GetWorldPosition(), spot) && !CBPointIsSafeArea(game, spot) {
          let ai = g.GetAIControllerComponent();
          if IsDefined(ai) {
            let cmd = new AIMoveToCommand();
            let dest: AIPositionSpec;
            let wp: WorldPosition;
            WorldPosition.SetVector4(wp, spot);
            AIPositionSpec.SetWorldPosition(dest, wp);
            cmd.movementTarget = dest;
            cmd.movementType = moveMovementType.Walk;
            cmd.ignoreInCombat = true;
            cmd.alwaysUseStealth = false;
            cmd.ignoreNavigation = false;
            cmd.finishWhenDestinationReached = true;
            cmd.desiredDistanceFromTarget = 1.5;
            CBIssueMove(g, ai, cmd);
          }
        }
      }
    }
  }

  public func NoteGrab(npc: ref<ScriptedPuppet>) -> Void {
    this.m_grab = npc;
    this.m_grabFor = 0.0;
    this.m_grabNeed = 0.0;
    this.m_grabShown = -1;
  }

  public func NoteRelease() -> Void {
    this.m_grab = null;
  }

  public func NoteScan(npc: ref<ScriptedPuppet>) -> Void {
    if ArraySize(this.m_scans) < 8 {
      ArrayPush(this.m_scans, npc);
    }
  }

  public func Tick(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, dt: Float) -> Void {
    if !CBWorldStable(game) || CBPlayerInScene(game) {
      return;
    }
    if CBIntelOn() {
      this.Squeeze(sys, game, player, dt);
      this.Downed(sys, game, player, dt);
      this.Scans(sys, game, player);
    } else {
      this.m_grab = null;
      ArrayClear(this.m_scans);
    }
    this.m_bubbleIn -= dt;
    if this.m_bubbleIn <= 0.0 {
      this.m_bubbleIn = 1.5;
      this.Bubbles(sys, game, player);
    }
    this.m_informIn -= dt;
    if this.m_informIn <= 0.0 {
      this.m_informIn = 5.0;
      this.Informants(sys, game, player);
    }
    this.m_guardIn -= dt;
    if this.m_guardIn <= 0.0 {
      this.m_guardIn = 1.0;
      this.Guards(sys, game);
      this.GuardBeat(sys, game);
    }
  }

  // A ganger in V's grip.
  private func Squeeze(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, dt: Float) -> Void {
    let npc = this.m_grab;
    if !IsDefined(npc) {
      return;
    }
    // Still in the world before their record is read for their gang (2.2.1).
    if npc.cbIntelGiven || !npc.IsAttached() || npc.IsDead() {
      this.m_grab = null;
      return;
    }
    let faction = CBClassifyFaction(npc);
    if Equals(faction, n"") || Equals(faction, n"NCPD")
       || Equals(faction, n"MaxTac") || !CBFactionOn(faction) || !CBSafetyGate.CanTalkTo(npc) {
      this.m_grab = null;
      return;
    }
    // A human shield is not a conversation.
    if CBPlayerAiming(game) {
      this.m_grab = null;
      return;
    }
    let temper = CBTalkTemper(npc);
    if this.m_grabNeed <= 0.0 {
      this.m_grabNeed = CBConfig.SqueezeSeconds();
      if temper == CBTalkTemperGreedy() {
        this.m_grabNeed *= 1.7;
      } else {
        if temper == CBTalkTemperChatty() || CBNerve(npc) < 0.35 {
          this.m_grabNeed *= 0.5;
        }
      }
    }
    this.m_grabFor += dt;
    let left = Max(0, CeilF(this.m_grabNeed - this.m_grabFor));
    if left > 0 && left != this.m_grabShown {
      this.m_grabShown = left;
      CBIntelSay(game, 2, "V", s"Talk. Where are your people hiding? (\(left))", 1.3);
      return;
    }
    if this.m_grabFor < this.m_grabNeed {
      return;
    }
    npc.cbIntelGiven = true;
    this.m_grab = null;
    let speaker = CBIntelSpeaker(faction);
    if temper == CBTalkTemperLoyal() {
      CBIntelSay(game, 3, speaker, CBPick2("Go to hell. I'm not telling you anything.", "Do it, then. I'm not talking."), 5.0);
      CBLog.Info(n"Intel", "A loyal ganger said nothing in V's grip.");
      return;
    }
    let i = CBIntelGive(sys, game, player, faction);
    CBIntelSay(game, 3, speaker, CBIntelSpoken(i), 6.0);
    if i.kind != CBIntelNone() {
      CBFileLog(sys, n"Squeezed", CBGameSeconds(game), CBEventDistrict(sys, game), faction, 0.0);
    }
  }

  // Crouched over somebody on the ground: a ganger down and alive talks; a Rival's body carries something.
  private func Downed(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, dt: Float) -> Void {
    if !CBPlayerCrouched(game) || player.IsInCombat() {   // crouched over them, as the feature says (2.5.1)
      this.m_down = null;
      this.m_downFor = 0.0;
      return;
    }
    let p = this.Lying(game, player);
    if !IsDefined(p) {
      this.m_down = null;
      this.m_downFor = 0.0;
      return;
    }
    let cur = this.m_down;
    if !IsDefined(cur) || !Equals(cur.GetEntityID(), p.GetEntityID()) {
      this.m_down = p;
      this.m_downFor = 0.0;
      if !p.IsDead() {
        CBIntelSay(game, 2, "V", "Who sent you? Talk, and I call you a trauma team.", 3.0);
      }
      return;
    }
    this.m_downFor += dt;
    if this.m_downFor < CBConfig.DownedTalkSeconds() {
      return;
    }
    p.cbIntelGiven = true;
    this.m_down = null;
    let faction = CBClassifyFaction(p);
    if p.IsDead() {
      // Only a Rival's body has anything on it worth finding.
      let i = CBIntelGive(sys, game, player, faction, true);
      if i.kind == CBIntelNone() {
        CBSystemNote(game, "Nothing on the body worth having.", 4.0);
        return;
      }
      CBSystemNote(game, "On the body, a burner phone: " + CBIntelWritten(i), 8.0);
      CBLog.Info(n"Intel", "A Rival's body carried word of another.");
      return;
    }
    if CBTalkTemper(p) == CBTalkTemperLoyal() {
      CBIntelSay(game, 3, CBIntelSpeaker(faction), "...go to hell...", 4.0);
      return;
    }
    let i = CBIntelGive(sys, game, player, faction);
    CBIntelSay(game, 3, CBIntelSpeaker(faction), CBIntelSpoken(i), 6.0);
    if i.kind != CBIntelNone() {
      CBFileLog(sys, n"Squeezed", CBGameSeconds(game), CBEventDistrict(sys, game), faction, 0.0);
    }
  }

  // Somebody on the ground in front of crouched V, close: a ganger down and alive, or a Rival's body.
  private func Lying(game: GameInstance, player: ref<PlayerPuppet>) -> ref<ScriptedPuppet> {
    let ppos = player.GetWorldPosition();
    let fwd = Vector4.Normalize2D(player.GetWorldForward());
    let des = GameInstance.GetDynamicEntitySystem();
    let targeting = GameInstance.GetTargetingSystem(game);
    let sys = CyberbaneSystem.Get(game);
    if IsDefined(targeting) {
      let hit = targeting.GetLookAtObject(player, true, true) as ScriptedPuppet;
      if this.LyingHere(sys, hit, ppos, fwd, des) {
        return hit;
      }
    }
    let reg = IsDefined(sys) ? sys.GetRegistry() : null;
    if IsDefined(reg) {
      for p in reg.GetAll() {
        if this.LyingHere(sys, p, ppos, fwd, des) {
          return p;
        }
      }
    }
    return null;
  }

  // Cheapest tests first: our own flag, then distance, then the angle, then the engine's questions.
  // CBNpcSafe, not a bare IsAttached (2.2.1): what follows reads their record and tags, and the registry
  // can hand back somebody who has just streamed in or is on their way out.
  private func LyingHere(sys: ref<CyberbaneSystem>, p: ref<ScriptedPuppet>, ppos: Vector4, fwd: Vector4,
                         des: ref<DynamicEntitySystem>) -> Bool {
    if !IsDefined(p) || p.cbIntelGiven || !CBNpcSafe(sys, p) || p.IsPlayer() {
      return false;
    }
    let pos = p.GetWorldPosition();
    if Vector4.Distance(ppos, pos) > CBConfig.DownedTalkRange() {
      return false;
    }
    let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
    if fwd.X * dir.X + fwd.Y * dir.Y < 0.6 || !p.IsHuman() {
      return false;
    }
    let faction = CBClassifyFaction(p);
    if Equals(faction, n"") || Equals(faction, n"NCPD") || Equals(faction, n"MaxTac") || !CBFactionOn(faction) {
      return false;
    }
    if p.IsDead() {
      return IsDefined(des) && des.IsTagged(p.GetEntityID(), n"CB_Rival");
    }
    return ScriptedPuppet.IsDefeated(p) && CBSafetyGate.CanTalkTo(p);
  }

  // A full scan, once per person: now and then their files say something.
  private func Scans(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    if ArraySize(this.m_scans) == 0 {
      return;
    }
    let list = this.m_scans;
    ArrayClear(this.m_scans);
    for p in list {
      if IsDefined(p) && p.IsAttached() && !p.cbIntelScanned {
        p.cbIntelScanned = true;
        let faction = CBClassifyFaction(p);
        let gang = NotEquals(faction, n"") && !Equals(faction, n"NCPD") && !Equals(faction, n"MaxTac") && CBFactionOn(faction);
        if gang && RandF() < CBConfig.IntelScanChance() {
          let i = CBIntelGive(sys, game, player, faction, true);
          if i.kind != CBIntelNone() {
            CBSystemNote(game, "Scan: their messages mention " + CBIntelWritten(i), 8.0);
            CBLog.Info(n"Intel", "A scan turned something up.");
          }
        }
      }
    }
  }

  // The talk icon over at most two people nearby with word of a Rival.
  private func Bubbles(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let ms = GameInstance.GetMappinSystem(game);
    if !IsDefined(ms) {
      return;
    }
    let ppos = player.GetWorldPosition();
    let on = CBBubblesOn() && !player.IsInCombat() && !VehicleComponent.IsMountedToVehicle(game, player.GetEntityID());
    // Down for whoever is gone, far, talked to, or no longer has anything.
    let i = ArraySize(this.m_bubbleOwner) - 1;
    while i >= 0 {
      let o = this.m_bubbleOwner[i];
      let keep = on && CBNpcSafe(sys, o) && !o.IsDead() && CBStillStanding(o)
                 && Vector4.Distance(ppos, o.GetWorldPosition()) <= 40.0 && o.cbTalkTimes == 0
                 && IsDefined(CBTalkRivalForFaction(sys, game, CBClassifyFaction(o)));
      if !keep {
        ms.UnregisterMappin(this.m_bubblePin[i]);
        ArrayErase(this.m_bubblePin, i);
        ArrayErase(this.m_bubbleOwner, i);
      }
      i -= 1;
    }
    if !on || ArraySize(this.m_bubbleOwner) >= 2 {
      return;
    }
    let reg = sys.GetRegistry();
    if !IsDefined(reg) {
      return;
    }
    // Whether a gang has word of a Rival is asked once per gang a pass, and at most six people are put
    // through the full talk checks: a dense street has dozens of gangers in the registry.
    //
    // The per-NPC gate (CBNpcSafe) comes before anything is read from them (2.2.1). This asked IsCrowd,
    // which reads the person's character record, first, and whether they were attached only after: so
    // every registry entry, near or far, still in the world or already streamed out, had its record read
    // every pass and a half. The registry is only pruned once a tick, and not on the busy ones, so a
    // streamed-out puppet is still in it, and reading its record took the game down (CTD in
    // ScriptedPuppet.IsCrowd > GetRecord). The Director has always read the same things in this order:
    // the gate, then the distance, then the record.
    let asked: array<CName>;
    let answers: array<Bool>;
    let checks = 0;
    for p in reg.GetAll() {
      if ArraySize(this.m_bubbleOwner) >= 2 || checks >= 6 {
        return;
      }
      if IsDefined(p) && p.cbTalkTimes == 0 && CBNpcSafe(sys, p) && !p.IsPlayer()
         && Vector4.Distance(ppos, p.GetWorldPosition()) <= 25.0 && !p.IsCrowd() && !this.HasBubble(p) {
        let faction = CBClassifyFaction(p);
        if NotEquals(faction, n"") && !Equals(faction, n"NCPD") && !Equals(faction, n"MaxTac") {
          let k = ArrayFindFirst(asked, faction);
          if k < 0 {
            let tally = CBTalkTallyFor(sys, game, faction);
            ArrayPush(asked, faction);
            ArrayPush(answers, IsDefined(tally) && tally.leaks < CBConfig.TalkLeaksPerDay()
                               && IsDefined(CBTalkRivalForFaction(sys, game, faction)));
            k = ArraySize(asked) - 1;
          }
          if answers[k] {
            checks += 1;
            if StrLen(CBTalkWhyNot(sys, game, player, p, 25.0, true)) == 0 {
              this.AddBubble(ms, p);
            }
          }
        }
      }
    }
  }

  private func HasBubble(p: ref<ScriptedPuppet>) -> Bool {
    for o in this.m_bubbleOwner {
      if IsDefined(o) && Equals(o.GetEntityID(), p.GetEntityID()) {
        return true;
      }
    }
    return false;
  }

  private func AddBubble(ms: ref<MappinSystem>, p: ref<ScriptedPuppet>) -> Void {
    let look = new GameplayRoleMappinData();
    look.m_textureID = CBTalkBubbleIcon();
    look.m_showOnMiniMap = true;
    look.m_visibleThroughWalls = false;
    let data: MappinData;
    data.mappinType = t"Mappins.DeviceMappinDefinition";
    data.variant = gamedataMappinVariant.ConversationVariant;
    data.active = true;
    data.visibleThroughWalls = false;
    data.scriptData = look;
    let id = ms.RegisterMappinWithObject(data, p, p.GetRoleMappinSlotName());
    ArrayPush(this.m_bubbleOwner, p);
    ArrayPush(this.m_bubblePin, id);
  }

  // Every bubble down: talk switched off, the session ending.
  public func ClearBubbles(game: GameInstance) -> Void {
    let ms = GameInstance.GetMappinSystem(game);
    if IsDefined(ms) {
      for id in this.m_bubblePin {
        ms.UnregisterMappin(id);
      }
    }
    ArrayClear(this.m_bubblePin);
    ArrayClear(this.m_bubbleOwner);
  }

  // Somebody who owes V texts a tip when one is due.
  private func Informants(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let book = CBIntelBook.Get(game);
    if !IsDefined(book) || !CBInformantsOn() || player.IsInCombat() || !CBToastsOn() {
      return;
    }
    let now = CBGameSeconds(game);
    let k = book.InformantCount() - 1;
    while k >= 0 {
      // A Rival who owed V and is no longer anybody to text from: put down since, run out of the city,
      // or forgotten. They went on texting tips under their own name from the grave.
      let owed = book.InformantRival(k);
      let who = owed > 0 ? sys.FindRivalById(owed) : null;
      if owed > 0 && (!IsDefined(who) || who.state == EnumInt(ECBRivalState.Slain) || who.state == EnumInt(ECBRivalState.Retired)) {
        book.RemoveInformant(k);
        return;   // one change a pass, so the walk never runs on past the end
      }
      if now >= book.InformantDue(k) {
        this.InformantTip(sys, game, player, book, k, now);
        return;   // one text a pass
      }
      k -= 1;
    }
  }

  private func InformantTip(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, book: ref<CBIntelBook>,
                            k: Int32, now: Float) -> Void {
    let faction = book.InformantFaction(k);
    let rivalId = book.InformantRival(k);
    let sender = CBInformantSender(sys, rivalId, faction);
    let last = book.InformantTips(k) <= 1;
    // A spared Rival tells on the others, of any gang; a turned ganger on their own.
    let about = rivalId > 0 ? n"" : faction;
    // The set-up sends a crew, so only from a gang that may still send one (CBGangMaySend): not one V
    // has bought peace from, come round to V, or switched off. Otherwise the last tip is a real one.
    if last && book.InformantSetup(k) && CBGangMaySend(sys, faction) && Equals(sys.GetPendingSquadFaction(), n"") {
      let fake = CBDistrictAt(RandRange(0, CBDistrictCount()));
      CBPhoneSendTinted(game, sender, s"Last one, then we're square. Somebody you want is waiting \(CBPlacePhrase(fake)). Go now.", CBHudCyan());
      CBHuntBegin(sys, game, faction);
      sys.SetPendingSquad(faction, CBWarningTicks(CBConfig.CrewWarningTicks()));
      sys.SetHuntGrade(CBCrewGrade(sys, faction));
      CBHearsayFromStreet(game, s"That informant of yours? Sold you to \(CBFactionLabel(faction)). They're coming.", n"");
      CBLog.Info(n"Intel", "An informant's last tip was a set-up.");
      book.RemoveInformant(k);
      return;
    }
    let i = CBIntelGive(sys, game, player, about);
    let body = i.kind == CBIntelNone() ? "Quiet out there. Nothing worth your time yet." : CBIntelWritten(i);
    if last {
      body += " That's it. We're square.";
      book.RemoveInformant(k);
    } else {
      book.SpendTip(k, now + RandRangeF(10.0, 24.0) * 3600.0);
    }
    CBPhoneSendTinted(game, sender, body, CBHudCyan());
    CBFileLog(sys, n"InformantTip", now, CBEventDistrict(sys, game), faction, 0.0);
    CBLog.Info(n"Intel", s"An informant texted a tip (\(i.kind)).");
  }
}

// Who an informant texts as: the Rival by name, or "<gang member> on the inside" for a turned ganger.
func CBInformantSender(sys: ref<CyberbaneSystem>, rivalId: Int32, faction: CName) -> String {
  if rivalId > 0 {
    let r = sys.FindRivalById(rivalId);
    if IsDefined(r) {
      return CBRivalDisplayName(sys.GetContent(), r);
    }
  }
  return CBIntelSpeaker(faction) + " on the inside";
}

func CBTalkBubbleIcon() -> TweakDBID {
  if IsDefined(TweakDBInterface.GetUIIconRecord(t"ChoiceIcons.TalkIcon")) {
    return t"ChoiceIcons.TalkIcon";
  }
  return CBMarkerIcon();
}

// A Rival spared twice (Reactions/CombatFlee.reds, the Debtor) owes V: two or three tips over the next
// days, and now and then the last is a set-up.
public func CBIntelDebtor(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !CBInformantsOn() {
    return;
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let now = CBGameSeconds(game);
  book.AddInformant(r.id, r.faction, RandRange(2, 4), now + RandRangeF(4.0, 8.0) * 3600.0,
                    RandF() < CBConfig.InformantSetupChance());
  if CBToastsOn() {
    CBPhoneSendTinted(game, name, "You let me walk. Twice. I don't forget that. I hear things, and you'll hear them too.", CBHudCyan());
  }
  CBLog.Info(n"Intel", s"Rival \(r.id) owes V and will text tips.");
}

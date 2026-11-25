// Cyberbane - Street talk
//
// Walk up to somebody, look at them, and the game's choice prompt comes up, the one it shows when V can talk to
// somebody: Greet, Dismiss, Antagonize, Intimidate. Scroll (the D-pad on a controller) to pick and press F (A) to say
// it, the way the game's choices work.

// When V last spoke to this person, in fast ticks (0 never), what V has done (CBTalk* bits), and whether
// they have already been sent on their way (one move order each).
@addField(ScriptedPuppet)
public let cbTalkTick: Int32;

@addField(ScriptedPuppet)
public let cbTalkDone: Int32;

// The lines numbered 31 and up.
@addField(ScriptedPuppet)
public let cbTalkDoneHigh: Int32;

// And 62 to 92: the crew's own lines start at 62, one past what the second could hold.
@addField(ScriptedPuppet)
public let cbTalkDoneHigher: Int32;

public func CBTalkDid(npc: wref<ScriptedPuppet>, act: Int32) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  if act <= 30 {
    return CBMaskHas(npc.cbTalkDone, act);
  }
  return act <= 61 ? CBMaskHas(npc.cbTalkDoneHigh, act - 31) : CBMaskHas(npc.cbTalkDoneHigher, act - 62);
}

public func CBTalkSetDid(npc: wref<ScriptedPuppet>, act: Int32) -> Void {
  if !IsDefined(npc) {
    return;
  }
  if act <= 30 {
    npc.cbTalkDone = CBMaskSet(npc.cbTalkDone, act);
  } else {
    if act <= 61 {
      npc.cbTalkDoneHigh = CBMaskSet(npc.cbTalkDoneHigh, act - 31);
    } else {
      npc.cbTalkDoneHigher = CBMaskSet(npc.cbTalkDoneHigher, act - 62);
    }
  }
}

@addField(ScriptedPuppet)
public let cbTalkSent: Bool;

// When they were sent on their way (settled ticks), so it wears off: every state needs an exit.
@addField(ScriptedPuppet)
public let cbTalkSentTick: Int32;

// Whether they have already told V they will not talk. Once per person.
@addField(ScriptedPuppet)
public let cbTalkRefused: Bool;

// A passer-by V stopped in their tracks to talk to, to be sent on their way again after.
@addField(ScriptedPuppet)
public let cbTalkStopped: Bool;

// Whoever V is in a conversation with: they do not take fright from the street around them, and the game's voice lines
// for them wait, so nothing talks over the conversation.
@addField(ScriptedPuppet)
public let cbTalkPartner: Bool;

// The hold-position order that keeps them standing while V talks, cancelled when it is over.
@addField(ScriptedPuppet)
public let cbTalkHold: ref<AIHoldPositionCommand>;

// The hold took the place of a walk Cyberbane had them on (a bagman or a patrol), so the walk is taken up again once
// the conversation is over (CBTalkWalkOnDue).
@addField(ScriptedPuppet)
public let cbTalkTookWalk: Bool;

// V has been told why this person will not talk (CBStreetTalk.Explain), so it is not said again.
@addField(ScriptedPuppet)
public let cbTalkExplained: Bool;

// Their own voice, quiet for the length of a conversation (CBTalkHush): the game's talk on F switched off, and for
// somebody of the crowd their voiceset lines too. Each is put back only if it was switched off here.
@addField(ScriptedPuppet)
public let cbTalkHushedTalk: Bool;

@addField(ScriptedPuppet)
public let cbTalkHushedLines: Bool;

// Whether the game's rule gives this person its own talk on F (the GenericTalk interaction: a random line in their own
// voice, with its subtitle), read the way it sets the layer up (scriptedPuppet.script, ToggleInteractionLayers), busy
// or not.
func CBGenericTalkByRule(npc: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  let rec = npc.GetRecord();
  if !IsDefined(rec) {
    return false;
  }
  if npc.IsCrowd() {
    return rec.CanHaveGenericTalk();
  }
  if npc.IsCharacterCivilian() && !TDB.GetBool(t"player.grapple.canGrappleCivilian", true) {
    return false;
  }
  if npc.IsBoss() || npc.IsMassive() {
    return false;
  }
  return rec.ForceCanHaveGenericTalk();
}

// The person V is talking to answers V through Cyberbane alone.
func CBTalkHush(npc: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) || !npc.IsAttached() {
    return;
  }
  CBTalkHushTalk(npc);
  if !npc.cbTalkHushedLines && npc.IsCrowd() {
    let quiet = new entChangeVoicesetStateEvent();
    quiet.enableVoicesetLines = false;
    quiet.enableVoicesetGrunts = true;
    npc.QueueEvent(quiet);
    npc.cbTalkHushedLines = true;
  }
}

// Only the game's talk on F switched off, for whoever V is settling on, before "Talk" is offered.
func CBTalkHushTalk(npc: ref<ScriptedPuppet>, opt again: Bool) -> Bool {
  if !IsDefined(npc) || !npc.IsAttached() {
    return false;
  }
  // Their other talk on F: every NPC carries GenericInteraction.ReturnTalk beside Talk, on its own layer and on Choice1
  // too, and only GenericTalk was ever switched off, so a person with it live kept the game's talk armed under
  // Cyberbane's: F set off the game's, and the game kept Cyberbane's lines hidden until V walked away.
  let returnOff = false;
  if npc.cbOwnReturnLive && !npc.cbReturnHushed && !CBTalkOwnBusiness(npc) {
    npc.EnableInteraction(n"ReturnTalk", false);
    npc.cbReturnHushed = true;
    CBLog.Info(n"Talk", "Their own ReturnTalk was live: switched off for the conversation.");
  }
  returnOff = npc.cbReturnHushed;
  // Switched off once more only when the game has put it back on and it is live for V again.
  if npc.cbTalkHushedTalk && (!again || !npc.cbOwnTalkLive) {
    return true;
  }
  if !npc.cbTalkHushedTalk && !npc.cbOwnTalkLive && !CBGenericTalkByRule(npc) && returnOff {
    return true;
  }
  if !npc.cbTalkHushedTalk {
    // Never somebody with business of their own.
    let live = npc.cbOwnTalkLive;
    if (!live && !CBGenericTalkByRule(npc)) || CBTalkOwnBusiness(npc) {
      return false;
    }
    npc.cbTalkHushWasOn = true;
  }
  npc.EnableInteraction(n"GenericTalk", false);
  npc.cbTalkHushedTalk = true;
  return true;
}

// The game says their own "Talk" is live for V: its interaction layer activated for the player, which it only does
// while the layer is switched on.
@addField(ScriptedPuppet)
public let cbOwnTalkLive: Bool;
@addField(ScriptedPuppet)
public let cbTalkHushWasOn: Bool;
// The same for their ReturnTalk layer.
@addField(ScriptedPuppet)
public let cbOwnReturnLive: Bool;
@addField(ScriptedPuppet)
public let cbReturnHushed: Bool;

@wrapMethod(ScriptedPuppet)
protected cb func OnInteractionActivated(evt: ref<InteractionActivationEvent>) -> Bool {
  wrappedMethod(evt);   // as a statement: never typed off what the game's event returns
  if IsDefined(evt) && IsDefined(evt.activator) && evt.activator.IsPlayer() {
    let on = Equals(evt.eventType, gameinteractionsEInteractionEventType.EIET_activate);
    if Equals(evt.layerData.tag, n"GenericTalk") {
      this.cbOwnTalkLive = on;
    }
    if Equals(evt.layerData.tag, n"ReturnTalk") {
      this.cbOwnReturnLive = on;
    }
    if this.cbTalkPartner || this.cbTalkHushedTalk || this.cbReturnHushed {
      CBLog.Info(n"Talk", s"Their prompt layer \(NameToString(evt.layerData.tag)) \(on ? "came up" : "went down").");
    }
  }
  return true;
}

// Whether a bystander's own talk on F may be switched off while V settles on somebody beside them: only somebody ready
// to be read (CBNpcSafe, before anything native), a person, and never the story's, a vendor, a companion or anybody at
// the job V is tracking (the Safety Gate), nor anybody standing at one of V's jobs.
func CBTalkMayHush(sys: ref<CyberbaneSystem>, npc: ref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || npc.IsPlayer() || !CBNpcSafe(sys, npc) || npc.IsDead() {
    return false;
  }
  if !npc.IsHuman() || npc.IsMechanical() || !CBSafetyGate.CanTalkTo(npc) || CBTalkOwnBusiness(npc) {
    return false;
  }
  return !IsDefined(sys) || !sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.TalkJobClearance());
}

// Somebody whose own conversation is the point of them: a vendor, a joytoy, a fixer, a ripperdoc.
public func CBTalkOwnBusiness(npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) {
    return false;
  }
  return npc.IsVendor() || npc.MatchVisualTag(n"Prostitute") || npc.MatchVisualTag(n"Vendor")
      || npc.MatchVisualTag(n"Ripperdoc") || npc.MatchVisualTag(n"Fixer");
}

public func CBTalkWhyOwnBusiness() -> String = "they have business of their own (a vendor, a joytoy, a fixer or a ripperdoc)"

// Somebody V could talk to at all, by who they are rather than what they are doing this minute: a person, whom the
// Safety Gate lets V speak to (nobody the story wrote, nobody in a quest, no vendor, nobody of V's own), with no
// business of their own.
public func CBTalkableByWho(npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(npc) && npc.IsHuman() && !npc.IsMechanical() && CBSafetyGate.CanTalkTo(npc) && !CBTalkOwnBusiness(npc);
}

// Their own voice back, as the game would have it now.
func CBTalkUnhush(npc: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) {
    return;
  }
  if npc.cbReturnHushed {
    npc.cbReturnHushed = false;
    if npc.IsAttached() {
      npc.EnableInteraction(n"ReturnTalk", true);
    }
  }
  if npc.cbTalkHushedTalk {
    npc.cbTalkHushedTalk = false;
    let wasOn = npc.cbTalkHushWasOn;
    npc.cbTalkHushWasOn = false;
    if npc.IsAttached() && wasOn {
      npc.EnableInteraction(n"GenericTalk", !StatusEffectSystem.ObjectHasStatusEffectWithTag(npc, n"Busy"));
    }
  }
  if npc.cbTalkHushedLines {
    npc.cbTalkHushedLines = false;
    if npc.IsAttached() {
      let voice = new entChangeVoicesetStateEvent();
      voice.enableVoicesetLines = true;
      voice.enableVoicesetGrunts = true;
      npc.QueueEvent(voice);
    }
  }
}

// Somebody a favour asked V to lean on (Spawn/LivingStreet.reds): squaring up to them or threatening them both count,
// as the favour says.
func CBTalkNoteLeaned(game: GameInstance, npc: ref<ScriptedPuppet>) -> Void {
  // A Rival's witness leaned on runs ahead to warn them (Spawn/StreetStories.reds).
  if IsDefined(npc) && npc.cbLeadWitnessFor > 0 {
    npc.cbLeadWitnessScared = true;
  }
  if !IsDefined(npc) || !npc.cbFavourMark {
    return;
  }
  let life = CBStreetLifeFor(game);
  if IsDefined(life) {
    life.NoteLeaned(npc);
  }
}

// Keep somebody where they are while V talks to them: the game's hold-position order (aiCommand.script,
// AIHoldPositionCommand, what the police's arrest flow uses).
func CBTalkHold(npc: ref<ScriptedPuppet>, opt seconds: Float) -> Void {
  if !IsDefined(npc) || IsDefined(npc.cbTalkHold) || !npc.IsAttached() {
    return;
  }
  let ai = npc.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  if IsDefined(npc.cbMoveCmd) {
    CBCancelMove(npc);
    npc.cbTalkTookWalk = true;
  }
  let cmd = new AIHoldPositionCommand();
  // A short order, renewed while the conversation lasts (CBTalkRenewHold), never one that outlives it.
  cmd.duration = seconds > 0.0 ? seconds : CBConfig.TalkHoldSeconds();
  // Dropped the moment they are in a fight (aiComponent.script, OnCommandStateChanged: ignoreInCombatMoveCommand).
  cmd.ignoreInCombat = true;
  npc.cbTalkHold = cmd;
  npc.cbTalkHeld = true;
  ai.SendCommand(cmd);
}

// The conversation is still on: a fresh short hold in place of the one about to run out.
func CBTalkRenewHold(npc: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) || !IsDefined(npc.cbTalkHold) || !npc.IsAttached() {
    return;
  }
  CBTalkReleaseHold(npc);
  CBTalkHold(npc);
}

// A hold-position order ended the way the game ends one that has run its time (aiIdleCommand.script,
// HoldPositionCommandTask): stopped if it is executing, and cancelled.
public func CBEndHold(npc: ref<ScriptedPuppet>, cmd: ref<AIHoldPositionCommand>) -> Void {
  if !IsDefined(npc) || !IsDefined(cmd) || !npc.IsAttached() {
    return;
  }
  let ai = npc.GetAIControllerComponent();
  if !IsDefined(ai) {
    return;
  }
  let executing = Equals(cmd.state, AICommandState.Executing);
  if executing {
    ai.StopExecutingCommand(cmd, true);
  }
  ai.CancelCommand(cmd);
}

// Whether a conversation has held this person in place since it began: one of the crowd held, moving or not, is put
// back into the crowd's foot traffic when it ends (CBStreetTalk.End).
@addField(ScriptedPuppet)
public let cbTalkHeld: Bool;

// Sent on their way by a conversation, and when, so it wears off (every place that sends somebody off goes through
// here; four of them set the flag alone, and somebody sent off without the time never came back to talk).
public func CBTalkMarkSent(game: GameInstance, npc: wref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) {
    return;
  }
  npc.cbTalkSent = true;
  let sys = CyberbaneSystem.Get(game);
  npc.cbTalkSentTick = IsDefined(sys) ? Max(sys.GetTickCount(), 1) : 1;
}

// Somebody of this tag whose walk a conversation took the place of, and whose conversation is over: the walk
// is due again. Read once: the mark comes off whether or not the walk then finds somewhere to go.
func CBTalkWalkOnDue(game: GameInstance, des: ref<DynamicEntitySystem>, tag: CName) -> Bool {
  if !IsDefined(des) {
    return false;
  }
  let due = false;
  for id in des.GetTaggedIDs(tag) {
    let p = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(p) && p.cbTalkTookWalk && !p.cbTalkPartner {
      p.cbTalkTookWalk = false;
      if CBStillStanding(p) {
        due = true;
      }
    }
  }
  return due;
}

func CBTalkReleaseHold(npc: ref<ScriptedPuppet>) -> Void {
  if !IsDefined(npc) || !IsDefined(npc.cbTalkHold) {
    return;
  }
  CBEndHold(npc, npc.cbTalkHold);
  npc.cbTalkHold = null;
}

// The game's voice lines for the person V is talking to wait until it is over: a greeting, a mutter or a frightened
// plea in their own voice, with its own subtitle, talked over every answer.
@wrapMethod(GameObject)
public static func PlayVoiceOver(self: ref<GameObject>, voName: CName, debugInitialContext: CName, opt delay: Float,
                                 opt answeringEntityID: EntityID, opt canPlayInVehicle: Bool) -> DelayID {
  let p = self as ScriptedPuppet;
  if IsDefined(p) && p.cbTalkPartner && NotEquals(debugInitialContext, n"Scripts:CBStreetTalk") {
    let none: DelayID;
    return none;
  }
  return wrappedMethod(self, voName, debugInitialContext, delay, answeringEntityID, canPlayInVehicle);
}

// Nor do they take fright from what the street around them does while V talks to them: somebody bolting past, a scream,
// the fear the crowd passes on (SpreadFear, Terror, Scream). Everybody else still feels it.
@wrapMethod(ReactionManagerComponent)
protected cb func OnEventReceived(stimEvent: ref<StimuliEvent>) -> Bool {
  let owner = this.GetOwner() as ScriptedPuppet;
  if IsDefined(owner) && owner.cbTalkPartner && IsDefined(stimEvent) {
    let kind = stimEvent.GetStimType();
    if Equals(kind, gamedataStimType.SpreadFear) || Equals(kind, gamedataStimType.Terror) || Equals(kind, gamedataStimType.Scream) {
      return false;
    }
  }
  wrappedMethod(stimEvent);
  return true;
}

// The settled tick V last had the prompt up on this person, or was waiting on their answer. The Director does not turn
// somebody on V mid-conversation (Reactions/Director.reds, TryGangHostile).
@addField(ScriptedPuppet)
public let cbTalkHeldTick: Int32;

// V is talking to them, or settling on them to talk.
public func CBTalkEngaged(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(npc) || !IsDefined(sys) {
    return false;
  }
  // The lines are up, or an answer is coming: as long as V takes to choose, as the game's dialogues wait.
  if npc.cbTalkPartner && npc.cbTalkLinesUp {
    return true;
  }
  // "Talk" offered and not pressed holds the clock for a few seconds, no longer: a Rival V only stands and stares at
  // with empty hands would otherwise have waited for ever.
  if npc.cbTalkPartner {
    return npc.cbTalkOfferedTick > 0 && sys.GetTickCount() - npc.cbTalkOfferedTick <= CBConfig.TalkOfferHoldTicks();
  }
  // Settling with a gun in hand is not walking up to talk: a Rival V stares down a barrel at does not wait for ever.
  let player = GetPlayer(npc.GetGame());
  if !IsDefined(player) || IsDefined(GameObject.GetActiveWeapon(player)) {
    return false;
  }
  return npc.cbTalkHeldTick > 0 && sys.GetTickCount() - npc.cbTalkHeldTick <= 2;
}

// The conversation's lines are up for them (Engage) and when "Talk" was offered to them (Begin), for CBTalkEngaged.
@addField(ScriptedPuppet)
public let cbTalkLinesUp: Bool;
@addField(ScriptedPuppet)
public let cbTalkOfferedTick: Int32;

// The four choices, in the order they are shown.
public func CBTalkGreet() -> Int32 = 0
public func CBTalkDismiss() -> Int32 = 1
public func CBTalkAntagonize() -> Int32 = 2
public func CBTalkIntimidate() -> Int32 = 3

// How the person stands with V, decided as the prompt goes up.
public func CBTalkFriendly() -> Int32 = 0
public func CBTalkWary() -> Int32 = 1
public func CBTalkAfraid() -> Int32 = 2
public func CBTalkHostile() -> Int32 = 3

public func CBStreetTalkOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().streetTalk);
}

public func CBShakedownsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkShakedowns;
}

// The person V is talking to, as they stood when the prompt went up.
public class CBTalkTarget {
  public let npc: wref<ScriptedPuppet>;
  public let id: EntityID;
  public let faction: CName;     // n"" for somebody of no gang
  public let cop: Bool;
  public let recognized: Bool;
  public let mood: Int32;        // CBTalkFriendly .. CBTalkHostile
  public let fear: Float;        // how afraid of V, about 0..1 (more for a broken gang)
  public let nerve: Float;       // CBNerve
  public let backers: Int32;     // their own people standing with them
  public let speaker: String;    // how the subtitles name them
  public let leadId: Int32;      // a Rival of their gang whose hiding place they could give up; 0 none
  public let leadName: String;
  public let first: Bool;        // the first time V has said this to them
  public let safe: Bool;         // a safe place (V in one, or they are indoors in one): words only
  public let atWork: Bool;       // at a workspot: never a move order, the game walks them off
  public let rivalId: Int32;     // a Rival V has put down, talked to where they lie; 0 otherwise
  public let facedown: Bool;     // ...or one standing in front of V at a facedown (Rivals/RivalMoments.reds)
  public let parley: Bool;       // a crew's sergeant stopped to talk (Reactions/Allies.reds)
}

// What they say back.
public class CBTalkAnswer {
  public let line: String;
  // Under their words unless `voMode` says the game's line is the answer (CBTalkSayTheirs).
  public let vo: CName;
  public let voMode: Int32;
}

// Hands the keys on to the talk, while its prompt is up.
public class CBTalkInput extends IScriptable {
  public let owner: wref<CBStreetTalk>;

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let talk = this.owner;
    if IsDefined(talk) {
      talk.OnInput(action);
    }
    return false;
  }
}

// Its own tick, a few times a second: the prompt has to follow where V is looking. A generation token, as the fast tick
// has, so a chain from an earlier session stops.
public class CBTalkFrameCallback extends DelayCallback {
  public let game: GameInstance;
  public let generation: Int32;

  public func Call() -> Void {
    let sys = CyberbaneSystem.Get(this.game);
    if IsDefined(sys) {
      let talk = sys.GetStreetTalk();
      if IsDefined(talk) {
        talk.OnFrame(this.game, this.generation);
      }
    }
  }
}

public class CBTalkTickCallback extends DelayCallback {
  public let game: GameInstance;
  public let generation: Int32;

  public func Call() -> Void {
    let sys = CyberbaneSystem.Get(this.game);
    if IsDefined(sys) {
      let talk = sys.GetStreetTalk();
      if IsDefined(talk) {
        talk.OnTick(this.game, this.generation);
      }
    }
  }
}

// ---- The conversation ------------------------------------------------------------------------
//
// A short conversation in the game's rhythm.

public func CBTalkStageIdle() -> Int32 = 0
public func CBTalkStageOffered() -> Int32 = 1   // "Talk" on screen
public func CBTalkStageOpen() -> Int32 = 2      // the lines on screen
public func CBTalkStageWaiting() -> Int32 = 3   // a line said, the answer due

// What a line does beyond the four choices.
public func CBTalkActTalk() -> Int32 = 10
public func CBTalkActLeave() -> Int32 = 11

// One line of the list: its words, what it does, and how the game should show it (dialogUI.script reads an
// icon from the caption parts and dims, greys or highlights by the choice type, as for its own lines).
public class CBTalkLine {
  public let text: String;
  public let act: Int32;
  public let icon: TweakDBID;
  public let important: Bool;    // highlighted: this one leads somewhere
  public let said: Bool;         // dimmed: V has said it to them before
  public let inactive: Bool;     // greyed: shown, but V cannot take it
  public let illegal: Bool;      // a crime
}

func CBTalkMakeLine(text: String, act: Int32, icon: TweakDBID) -> ref<CBTalkLine> {
  let l = new CBTalkLine();
  l.text = text;
  l.act = act;
  l.icon = icon;
  return l;
}

public func CBTalkStopWalkersOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkStopWalkers;
}

public func CBTalkFirstOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().talkFirst;
}

public class CBStreetTalk {
  private let m_game: GameInstance;
  private let m_generation: Int32;
  private let m_input: ref<CBTalkInput>;
  private let m_listening: wref<PlayerPuppet>;

  // The conversation, if any.
  private let m_stage: Int32;
  private let m_index: Int32;
  private let m_target: ref<CBTalkTarget>;
  private let m_lines: array<ref<CBTalkLine>>;
  private let m_exchanges: Int32;   // lines said in this conversation
  private let m_lostFor: Float;
  private let m_glanceIn: Float;
  private let m_handsHeld: Bool;
  // Whether the conversation has started (Engage): the person stopped and turned to V. "Talk" only offered
  // is not a conversation.
  private let m_engaged: Bool;
  // A confirm press acted on, whose release is still to come as Choice1 (see OnInput).
  private let m_applyPressed: Bool;
  // Whether this session has made sure the lock is off (see OnTick).
  private let m_handsChecked: Bool;

  // Which list is up (the main lines, the questions, a deal) and the deal on the table.
  private let m_menu: Int32;
  private let m_dealRival: Int32;
  private let m_dealPrice: Int32;
  private let m_dealHaggles: Int32;
  private let m_dealKind: Int32;
  // Keeping the list on screen (OnFrame): the chain's token, and how often the game wiped it.
  private let m_frameGen: Int32;
  private let m_wipes: Int32;
  // When the list was last on screen (sim time): a press within TalkPressGrace of it counts, because a game that keeps
  // clearing the list leaves it gone for a frame at a time, and a press landing in one of those frames was dropped.
  private let m_shownAt: Float;

  // What the keys asked for, carried out on the next tick, never inside the key callback.
  private let m_wantOpen: Bool;
  private let m_wantSay: Bool;
  private let m_wantIndex: Int32;

  // Somebody V is looking at and how long for, before "Talk" comes up.
  private let m_candidate: wref<ScriptedPuppet>;
  private let m_dwell: Float;
  // Whose own talk on F is switched off while V settles on them (HushCandidate), and how long the game's prompt has
  // stayed up since, for whom.
  private let m_hushed: wref<ScriptedPuppet>;
  private let m_promptWait: Float;
  private let m_promptWaitFor: EntityID;
  // Bystanders whose own talk on F is off because one of the game's prompts stood between V and the person V wanted
  // (HushNear), each put back once V has moved on from them (RestoreNear).
  private let m_hushedNear: array<wref<ScriptedPuppet>>;
  // How long the current hold-position order has run (CBTalkRenewHold).
  private let m_holdAge: Float;
  // The on-screen note while the lines are up and unanswered.
  private let m_diagLeft: Float;
  private let m_diagCount: Int32;

  // A line said, waiting for the answer.
  private let m_pending: Int32;
  private let m_pendingIn: Float;

  // The two subtitle lines of an exchange: V's, then theirs (UI/PhoneMessages.reds slots 2 and 3).
  private let m_vLineLeft: Float;
  private let m_replyLeft: Float;

  // After V reached for a weapon with the prompt up, how long before it may come up again (seconds).
  private let m_quietLeft: Float;
  private let m_whyLogged: String;
  private let m_whyFor: Float;
  // The greyed prompt saying why somebody will not talk (ShowNote): up or not, for whom, and its words.
  private let m_noteUp: Bool;
  private let m_noteFor: EntityID;
  private let m_noteText: String;
  private let m_whyLogAt: Float;
  // When V was last told why somebody would not talk (Explain), in game time. 0 = not yet this session.
  private let m_explainedAt: Float;

  // When the targeting query may next be asked (LookedAt).
  private let m_queryIn: Float;
  // The street's other ways of talking (Reactions/StreetIntel.reds), on this tick.
  private let m_intel: ref<CBStreetIntel>;
  // The street's own events (Spawn/LivingStreet.reds), ticked with the fast tick.
  private let m_life: ref<CBStreetLife>;

  // Keeping one notch of the wheel to one step (see Scroll).
  private let m_lastScrollAt: Float;
  private let m_lastScrollStep: Int32;
  private let m_lastScrollByWeapon: Bool;
  private let m_choiceScrollSeen: Bool;

  public func GetLife() -> ref<CBStreetLife> {
    if !IsDefined(this.m_life) {
      this.m_life = new CBStreetLife();
    }
    return this.m_life;
  }

  public func GetIntel() -> ref<CBStreetIntel> {
    if !IsDefined(this.m_intel) {
      this.m_intel = new CBStreetIntel();
    }
    return this.m_intel;
  }

  public func Start(game: GameInstance) -> Void {
    this.m_game = game;
    this.m_generation += 1;
    this.m_stage = CBTalkStageIdle();
    this.m_target = null;
    ArrayClear(this.m_lines);
    this.m_candidate = null;
    this.m_hushed = null;
    // The old world's people: nobody in it is there to switch back on.
    ArrayClear(this.m_hushedNear);
    this.m_promptWait = 0.0;
    this.m_dwell = 0.0;
    this.m_wantOpen = false;
    this.m_wantSay = false;
    this.m_handsHeld = false;
    this.m_handsChecked = false;
    this.m_listening = null;
    this.m_quietLeft = 0.0;
    // Stamped in the sim clock, which starts again with a session while this object may not: a stamp from the last
    // session would have held back the log line and V's explanations for that long.
    this.m_whyLogged = "";
    this.m_whyLogAt = 0.0;
    this.m_explainedAt = 0.0;
    // Talk bubbles from before a load are the old world's (Reactions/StreetIntel.reds).
    this.GetIntel().ClearBubbles(game);
    // Nor is a list held through the game's clears.
    CBTalkDropList();
    this.Schedule(game);
  }

  private func Schedule(game: GameInstance) -> Void {
    let ds = GameInstance.GetDelaySystem(game);
    if !IsDefined(ds) {
      return;
    }
    let cb = new CBTalkTickCallback();
    cb.game = game;
    cb.generation = this.m_generation;
    ds.DelayCallback(cb, CBConfig.TalkTickSeconds(), false);
  }

  // V pressed Talk and the conversation is still on (the truce's owner check).
  public func InConversation() -> Bool {
    return this.m_engaged && this.m_stage != CBTalkStageIdle();
  }

  public func IsShown() -> Bool {
    return this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen();
  }

  // Mid-exchange: a conversation is on, or a line of one is still on screen. The street's overheard lines
  // and the phone wait (Reactions/Director.reds, UI/PhoneMessages.reds), so they do not talk over it.
  public func Busy() -> Bool {
    return this.m_stage != CBTalkStageIdle() || this.m_vLineLeft > 0.0 || this.m_replyLeft > 0.0;
  }

  public func HoldsHands() -> Bool {
    return this.m_handsHeld;
  }

  public func OnTick(game: GameInstance, generation: Int32) -> Void {
    if generation != this.m_generation {
      return;
    }
    this.m_game = game;
    this.Schedule(game);
    let dt = CBConfig.TalkTickSeconds();
    this.AgeLines(game, dt);
    // An answer waiting for their own words (Reactions/TalkVoice.reds): theirs once the subtitles have seen them,
    // Cyberbane's after a moment without. On every tick, the conversation over or not: an answer often ends it.
    let late = CBTalkVoiceTick(game);
    if StrLen(late) > 0 {
      let vNow = CBTalkVoiceState();
      this.ShowReply(game, IsDefined(vNow) ? vNow.speaker : "", late);
    }
    if this.m_quietLeft > 0.0 {
      this.m_quietLeft -= dt;
    }
    let sys = CyberbaneSystem.Get(game);
    let player = GetPlayer(game);
    if !IsDefined(sys) || !IsDefined(player) {
      this.StandDown(game, "the world is changing");
      return;
    }
    let tick = Max(sys.GetTickCount(), 1);
    // Bystanders V has moved on from get their own talk back. Returns at once when there are none.
    this.RestoreNear(player, false);
    // Their people holding their fire while V talks: the ones walking up are held as they come.
    sys.GetTruce().Tick(sys, game);
    this.GetIntel().Tick(sys, game, player, dt);
    // A line said: the answer comes after a beat, only with the world settled.
    if this.m_stage == CBTalkStageWaiting() {
      if IsDefined(this.m_target) && IsDefined(this.m_target.npc) {
        this.m_target.npc.cbTalkHeldTick = tick;
      }
      this.KeepHolding(dt);
      this.m_pendingIn -= dt;
      if this.m_pendingIn <= 0.0 {
        if CBWorldStable(game) && CBStreetTalkOn() {
          this.Answer(sys, game, player);
        } else {
          this.End(game, "the moment passed");
        }
      }
      return;
    }
    let notNow = this.AllowedWhyNot(sys, game, player);
    // Mid-fight, words still reach whoever the fight is for: a Rival down at V's feet, somebody with their hands up, a
    // Rival or a sergeant standing for a facedown or a parley.
    if Equals(notNow, CBTalkWhyVInCombat()) && this.MidFightTalk(sys, game, player) {
      notNow = "";
    }
    // Crouched beside somebody down at V's feet: a Rival V put down, or somebody with their hands up, is talked to
    // wherever V's knees are. Crouching only keeps talk off everybody else (it is how V questions a downed ganger).
    if Equals(notNow, CBTalkWhyCrouched()) {
      let atFeet = this.LookedAt(game, player);
      if IsDefined(atFeet) && CBTalkDownAtFeet(atFeet) {
        notNow = "";
      }
    }
    if StrLen(notNow) > 0 {
      this.StandDown(game, notNow);
      // Said in the log when V is facing somebody; not looked for at all while talk is off, the world
      // is loading or V is driving.
      let facing: ref<ScriptedPuppet>;
      if CBStreetTalkOn() && CBWorldStable(game) && !VehicleComponent.IsMountedToVehicle(game, player.GetEntityID()) {
        // In a fight only with empty hands and no aim.
        if !player.IsInCombat() || (!IsDefined(GameObject.GetActiveWeapon(player)) && !CBPlayerAiming(game)) {
          facing = this.LookedAt(game, player);
        }
        this.NoteWhyNot(game, dt, facing, notNow);
      }
      // The greyed reason when it is one V can act on or wait out, else nothing (whatever it said is not the reason now).
      this.ShowNote(game, player, facing, notNow, this.m_whyFor >= CBConfig.TalkDwell() * 2.0);
      return;
    }
    // Once a session, on its first settled tick: the hands lock is a state-machine setting, and one left on by a prompt
    // that was up when the game was saved must not follow V into the next session.
    if !this.m_handsChecked {
      this.m_handsChecked = true;
      if !CBPlayerInSafeZone(game) {
        CBQueueZoneArmsLock(player, false);
      }
    }
    // The keys are let go on a tick, never inside their own callback.
    if this.m_stage == CBTalkStageIdle() {
      this.StopListening();
    }
    let npc = this.LookedAt(game, player, true);
    if this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen() {
      this.Keep(sys, game, player, npc, dt, tick);
      return;
    }
    this.Settle(sys, game, player, npc, dt, tick);
  }

  // A conversation on screen: act on the keys, keep it, or end it and say why.
  private func Keep(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                    npc: ref<ScriptedPuppet>, dt: Float, tick: Int32) -> Void {
    let t = this.m_target;
    if !IsDefined(t) || !IsDefined(t.npc) {
      this.End(game, "they are gone");
      return;
    }
    let why = CBTalkWhyNot(sys, game, player, t.npc, CBConfig.TalkKeepRange(), true);
    if StrLen(why) > 0 {
      this.End(game, why);
      return;
    }
    // A dialogue or a loot list of the game's ends it.
    CBTalkHushTalk(t.npc, true);
    let kind = CBNativePromptKind(game);
    if kind == CBPromptDialogue() {
      this.End(game, "one of the game's own dialogues came up");
      return;
    }
    let foreign = kind == CBPromptInteraction() && !CBTalkDownAtFeet(t.npc);
    if foreign {
      // And that of anybody standing by them in front of V: with one person's own "Talk" off, the game shows the next
      // person's.
      this.HushNear(sys, player, t.npc);
      this.m_promptWait += dt;
      if this.m_promptWait > CBConfig.TalkOwnPromptWait() {
        let gone = t.id;
        this.End(game, "one of the game's own prompts came up");
        this.GiveUpOn(player, gone);
        return;
      }
    } else {
      this.m_promptWait = 0.0;
    }
    this.KeepHolding(dt);
    // With only "Talk" up V's hands are free: drawing a weapon ends it.
    if !this.m_handsHeld && IsDefined(GameObject.GetActiveWeapon(player)) {
      this.End(game, "V drew a weapon");
      return;
    }
    t.npc.cbTalkHeldTick = tick;
    if this.m_wantOpen {
      this.m_wantOpen = false;
      if this.m_stage == CBTalkStageOffered() {
        this.OpenLines(sys, game, player);
        return;
      }
    }
    if this.m_wantSay {
      this.m_wantSay = false;
      if this.m_stage == CBTalkStageOpen() {
        this.Say(game, this.m_wantIndex);
        return;
      }
    }
    // Still on screen? Counted for the log. Never over a prompt of the game's: that is not a wipe but something else on
    // F, waited out above.
    if !foreign && !this.Shown(game) {
      this.NoteWipe(game);
      this.Push(game);
    } else {
      if !foreign {
        this.m_shownAt = CBTalkNow(game);
      }
    }
    if this.m_stage == CBTalkStageOpen() {
      CBTalkKeepList(game);
    }
    // The lines up and nothing said yet: what the game's interface holds, three times.
    if this.m_stage == CBTalkStageOpen() && this.m_exchanges == 0 && this.m_diagCount < 3 {
      this.m_diagLeft -= dt;
      if this.m_diagLeft <= 0.0 {
        this.m_diagLeft = 2.0;
        this.m_diagCount += 1;
        CBLog.Info(n"Talk", s"On screen: \(CBTalkScreenNote(game)); their own talk live \(t.npc.cbOwnTalkLive), off \(t.npc.cbTalkHushedTalk); ReturnTalk live \(t.npc.cbOwnReturnLive), off \(t.npc.cbReturnHushed); wiped \(this.m_wipes).");
      }
    }
    // They keep their eyes on V, the way a scene turns the game's characters to face V: once V has started talking to
    // them, never for an offer alone (Engage).
    this.m_glanceIn -= dt;
    if this.m_engaged && this.m_glanceIn <= 0.0 {
      this.m_glanceIn = CBConfig.TalkGlanceEvery();
      let reactions = t.npc.GetStimReactionComponent();
      if IsDefined(reactions) {
        reactions.CBGlanceAt(player);
      }
    }
    // Whoever V chose, while they are close and in front of V; the crosshair sliding onto the man beside
    // them changes nothing. A glance away is not walking off: a moment's grace before it goes.
    let facing = (IsDefined(npc) && Equals(npc.GetEntityID(), t.id)) || CBTalkFacing(player, t.npc);
    this.m_lostFor = facing ? 0.0 : this.m_lostFor + dt;
    if this.m_lostFor > CBConfig.TalkLookGrace() {
      this.End(game, "V looked away");
    }
  }

  // The person V is talking to held where they stand by a short order, renewed while it lasts (CBTalkHold).
  private func KeepHolding(dt: Float) -> Void {
    let t = this.m_target;
    if !this.m_engaged || !IsDefined(t) || !IsDefined(t.npc) || !IsDefined(t.npc.cbTalkHold) {
      return;
    }
    this.m_holdAge += dt;
    if this.m_holdAge >= CBConfig.TalkHoldRenewSeconds() {
      this.m_holdAge = 0.0;
      CBTalkRenewHold(t.npc);
    }
  }

  // Every frame while the list is up: put it back the moment something wipes it.
  public func OnFrame(game: GameInstance, generation: Int32) -> Void {
    if generation != this.m_frameGen || this.m_stage == CBTalkStageIdle() {
      return;
    }
    // Waiting for an answer, nothing is up on purpose; the chain only keeps going.
    if (this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen())
       && !this.Shown(game) && !CBGameDialogueUp(game) && !this.YieldsToGamePrompt(game) {
      this.NoteWipe(game);
      this.Push(game);
    }
    this.NextFrame(game);
  }

  // "Talk" gives way to a prompt of the game's that has taken its place.
  private func YieldsToGamePrompt(game: GameInstance) -> Bool {
    return this.m_stage == CBTalkStageOffered() && IsDefined(this.m_target) && !CBTalkDownAtFeet(this.m_target.npc)
        && CBNativePromptKind(game) == CBPromptInteraction();
  }

  private func NextFrame(game: GameInstance) -> Void {
    let ds = GameInstance.GetDelaySystem(game);
    if !IsDefined(ds) {
      return;
    }
    let cb = new CBTalkFrameCallback();
    cb.game = game;
    cb.generation = this.m_frameGen;
    ds.DelayCallbackNextFrame(cb);
  }

  // Nothing up: is V settling on somebody?
  private func Settle(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                      npc: ref<ScriptedPuppet>, dt: Float, tick: Int32) -> Void {
    // A weapon in hand keeps the prompt away (the wheel would switch guns instead of lines), and is said once a launch.
    let armed = IsDefined(GameObject.GetActiveWeapon(player));
    let why = "";
    if this.m_quietLeft > 0.0 {
      why = CBT(n"Cyberbane-StreetTalk-VReachedForAWeaponA");
    } else {
      if IsDefined(npc) {
        why = CBTalkWhyNot(sys, game, player, npc, CBConfig.TalkRange());
      }
    }
    // Whoever the game's look-at hands back may be somebody who cannot talk right now (V just spoke to them, say) while
    // the person beside them can: "I can't talk to more than one of them" was the look-at sticking to the last one.
    if StrLen(why) > 0 && this.m_quietLeft <= 0.0 {
      let other = this.NextTalkable(sys, game, player, npc);
      if IsDefined(other) {
        npc = other;
        why = "";
      }
    }
    // The game's prompt.
    if StrLen(why) == 0 && IsDefined(npc) && player.IsInCombat() && !CBTalkMidFight(npc) {
      why = CBTalkWhyVInCombat();
    }
    let waitPrompt = false;
    if StrLen(why) == 0 && IsDefined(npc) {
      let kind = CBNativePromptKind(game);
      if kind == CBPromptDialogue() {
        why = CBTalkWhyGamePrompt();
      } else {
        if kind == CBPromptInteraction() && !CBTalkDownAtFeet(npc) {
          // Waited out once per person: a prompt still up a moment after their own talk went off is not theirs (a
          // door, a pickup behind them), and they are left as they were rather than switched on and off every tick.
          if !Equals(this.m_promptWaitFor, npc.GetEntityID()) {
            this.m_promptWaitFor = npc.GetEntityID();
            this.m_promptWait = 0.0;
          }
          this.m_promptWait += dt;
          // Whose prompt it can be: theirs, put back by the game after they were busy, or somebody's beside them, whose
          // own "Talk" the game shows the moment theirs goes off (two people chatting, a passer-by behind).
          if this.m_promptWait > CBConfig.TalkOwnPromptWait() {
            this.GiveUpOn(player, npc.GetEntityID());
            why = CBTalkWhyGamePrompt();
          } else {
            this.HushCandidate(npc, true);
            this.HushNear(sys, player, npc);
            waitPrompt = true;
          }
        } else {
          this.m_promptWait = 0.0;
        }
      }
    }
    if !IsDefined(npc) || StrLen(why) > 0 {
      this.SetCandidate(null);
      this.m_dwell = 0.0;
      this.NoteWhyNot(game, dt, npc, why);
      this.ShowNote(game, player, npc, why, this.m_whyFor >= CBConfig.TalkDwell() * 2.0);
      this.Explain(game, npc, why);
      // A ganger or a cop who will not talk says so, once, instead of nothing.
      if IsDefined(npc) && (Equals(why, CBTalkWhyHostile()) || Equals(why, CBTalkWhyGrudge()))
         && this.m_whyFor >= CBConfig.TalkDwell() * 2.0 {
        this.Refuse(game, npc);
      }
      return;
    }
    this.m_whyFor = 0.0;
    let cand = this.m_candidate;
    if IsDefined(cand) && Equals(cand.GetEntityID(), npc.GetEntityID()) {
      this.m_dwell += dt;
    } else {
      this.SetCandidate(npc);
      this.m_dwell = 0.0;
    }
    // Whoever V is settling on is left alone meanwhile: the crowd reactions sent a frightened passer-by running, and a
    // warned ganger drew, in the moment before the prompt came up.
    npc.cbTalkHeldTick = tick;
    if armed {
      this.NoteWhyNot(game, dt, npc, "a weapon is in V's hands");
      // Every time now, in the prompt itself: the hint below came once a launch, and after it a gun in hand meant
      // nothing on F and no word why, which is most of the times "the dialogue doesn't show up" with a ganger.
      this.ShowNote(game, player, npc, "a weapon is in V's hands", this.m_dwell >= CBConfig.TalkArmedHintDwell());
      let rt = CyberbaneRuntime.Get();
      if this.m_dwell >= CBConfig.TalkArmedHintDwell() && IsDefined(rt) && !rt.GetTalkHolsterHinted() {
        rt.SetTalkHolsterHinted(true);
        CBSystemNote(game, CBT(n"Cyberbane-StreetTalk-PutYourWeaponAwayToTalk"), 7.0);
      }
      return;
    }
    // Talkable now: whatever the greyed prompt said is no longer so.
    this.HideNote(game);
    // Their own talk off from the moment V settles on them with empty hands, so the game's prompt never comes up over
    // the offer.
    this.HushCandidate(npc);
    // Not while the game's prompt is still on its way down: the offer would go up under it and be ended by it.
    if this.m_dwell >= CBConfig.TalkDwell() && !waitPrompt {
      this.Begin(sys, game, player, npc);
    }
  }

  // The fight's own people can be spoken to in it (CBTalkMidFight): the one V is already talking to, or the one V is
  // looking at. The game's look-at only, as in a fight: no walk of the registry five times a second.
  private func MidFightTalk(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Bool {
    if (this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen()) && IsDefined(this.m_target)
       && CBTalkMidFight(this.m_target.npc) {
      return true;
    }
    let targeting = GameInstance.GetTargetingSystem(game);
    if !IsDefined(targeting) {
      return false;
    }
    let hit = targeting.GetLookAtObject(player, true, true) as ScriptedPuppet;
    if !IsDefined(hit) {
      hit = targeting.GetLookAtObject(player, false, false) as ScriptedPuppet;
    }
    return IsDefined(hit) && !hit.IsPlayer() && CBNpcSafe(sys, hit) && CBTalkMidFight(hit)
        && Vector4.Distance(player.GetWorldPosition(), hit.GetWorldPosition()) <= CBConfig.TalkKeepRange();
  }

  // Whoever V is settling on, and the person whose own talk was switched off for it: switched back on the moment V
  // settles on somebody else, unless a conversation with them has begun (the conversation puts it back, End).
  private func SetCandidate(npc: ref<ScriptedPuppet>) -> Void {
    let was = this.m_hushed;
    if IsDefined(was) && (!IsDefined(npc) || NotEquals(was.GetEntityID(), npc.GetEntityID())) && !was.cbTalkPartner {
      this.Unhushed(was);
    }
    this.m_candidate = npc;
  }

  // Their own talk back on, and the wait for the game's prompt starts afresh for them: the prompt V sees next on them
  // is their own again.
  private func Unhushed(was: ref<ScriptedPuppet>) -> Void {
    CBTalkUnhush(was);
    this.m_hushed = null;
    if Equals(this.m_promptWaitFor, was.GetEntityID()) {
      let none: EntityID;
      this.m_promptWaitFor = none;
      this.m_promptWait = 0.0;
    }
  }

  // A prompt that would not go: everything switched off for it is put back (their own talk and their neighbours'), and
  // the wait is left spent for this person, so nothing is switched off again until V settles on somebody else.
  private func GiveUpOn(player: ref<PlayerPuppet>, id: EntityID) -> Void {
    let was = this.m_hushed;
    if IsDefined(was) && !was.cbTalkPartner {
      CBTalkUnhush(was);
    }
    this.m_hushed = null;
    this.RestoreNear(player, true);
    this.m_promptWaitFor = id;
    this.m_promptWait = MaxF(this.m_promptWait, CBConfig.TalkOwnPromptWait() + CBConfig.TalkTickSeconds());
  }

  // Their own talk on F off while V settles on them (CBTalkHushTalk), when the game's rule gave it to them. True when
  // it is off now. With `again`, switched off once more in case the game put it back.
  private func HushCandidate(npc: ref<ScriptedPuppet>, opt again: Bool) -> Bool {
    if !IsDefined(npc) {
      return false;
    }
    let was = this.m_hushed;
    if IsDefined(was) && NotEquals(was.GetEntityID(), npc.GetEntityID()) && !was.cbTalkPartner {
      this.Unhushed(was);
    }
    if !CBTalkHushTalk(npc, again) {
      return false;
    }
    if !npc.cbTalkPartner {
      this.m_hushed = npc;
    }
    return true;
  }

  // The game's talk off for everybody standing close in front of V besides `skip`, while one of the game's prompts
  // stands between V and the person V wants: switching off one person's own "Talk" only made the game show the next
  // one's.
  private func HushNear(sys: ref<CyberbaneSystem>, player: ref<PlayerPuppet>, skip: ref<ScriptedPuppet>) -> Void {
    for held in this.m_hushedNear {
      if IsDefined(held) && held.IsAttached() && held.cbTalkHushedTalk && !held.cbTalkPartner {
        CBTalkHushTalk(held, true);
      }
    }
    let reg = IsDefined(sys) ? sys.GetRegistry() : null;
    if !IsDefined(reg) || !IsDefined(player) || ArraySize(this.m_hushedNear) >= CBConfig.TalkHushNearCap() {
      return;
    }
    let ppos = player.GetWorldPosition();
    let fwd = Vector4.Normalize2D(player.GetWorldForward());
    let skipSet = IsDefined(skip);
    let skipId: EntityID;
    if skipSet {
      skipId = skip.GetEntityID();
    }
    for p in reg.GetAll() {
      // Our own field first, then the per-NPC gate before anything native is read (CBTalkMayHush asks CBNpcSafe).
      if ArraySize(this.m_hushedNear) < CBConfig.TalkHushNearCap() && IsDefined(p) && !p.cbTalkHushedTalk
         && !p.cbTalkPartner && (!skipSet || NotEquals(p.GetEntityID(), skipId)) && CBNpcSafe(sys, p) && !p.IsPlayer() {
        let pos = p.GetWorldPosition();
        if Vector4.Distance(ppos, pos) <= CBConfig.TalkKeepRange() && AbsF(pos.Z - ppos.Z) <= 1.5 {
          let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
          if fwd.X * dir.X + fwd.Y * dir.Y >= CBConfig.TalkKeepDot() && CBTalkMayHush(sys, p) && CBTalkHushTalk(p) {
            ArrayPush(this.m_hushedNear, p);
          }
        }
      }
    }
  }

  // Bystanders get their own talk back once V has moved on from them: out of reach or behind V, or with `all` (talk
  // standing down), every one.
  private func RestoreNear(player: ref<PlayerPuppet>, all: Bool) -> Void {
    if ArraySize(this.m_hushedNear) == 0 {
      return;
    }
    let keep: array<wref<ScriptedPuppet>>;
    let ppos: Vector4;
    let fwd: Vector4;
    let placed = IsDefined(player);
    if placed {
      ppos = player.GetWorldPosition();
      fwd = Vector4.Normalize2D(player.GetWorldForward());
    }
    for p in this.m_hushedNear {
      if IsDefined(p) && p.IsAttached() && p.cbTalkHushedTalk {
        let owned = p.cbTalkPartner || (IsDefined(this.m_hushed) && Equals(this.m_hushed.GetEntityID(), p.GetEntityID()));
        if !owned {
          let stay = false;
          if !all && placed {
            let pos = p.GetWorldPosition();
            let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
            stay = Vector4.Distance(ppos, pos) <= CBConfig.TalkKeepRange() + 1.0 && fwd.X * dir.X + fwd.Y * dir.Y >= 0.0;
          }
          if stay {
            ArrayPush(keep, p);
          } else {
            CBTalkUnhush(p);
          }
        }
      }
    }
    this.m_hushedNear = keep;
  }

  private func Begin(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                     npc: ref<ScriptedPuppet>) -> Void {
    let t = CBTalkRead(sys, game, npc);
    if !IsDefined(t) {
      return;
    }
    this.m_noteUp = false;   // the offer goes up in the greyed prompt's place
    this.m_target = t;
    this.m_exchanges = 0;
    this.m_lostFor = 0.0;
    this.m_glanceIn = CBConfig.TalkGlanceEvery();
    this.m_dwell = 0.0;
    this.m_candidate = null;
    this.m_whyFor = 0.0;
    this.m_wantOpen = false;
    this.m_wantSay = false;
    this.m_menu = CBTalkMenuMain();
    this.m_dealRival = 0;
    this.m_dealPrice = 0;
    this.m_dealKind = CBTalkDealLead();
    this.m_wipes = 0;
    this.m_shownAt = 0.0;
    this.m_frameGen += 1;
    this.m_engaged = false;
    this.m_applyPressed = false;
    CBTalkTemper(npc);
    this.Listen(player);
    // While "Talk" is only offered, nothing about them changes that anybody can see: they walk on and go about their
    // day, and only V pressing Talk stops them and turns them to V (Engage).
    npc.cbTalkPartner = true;
    npc.cbTalkLinesUp = false;
    npc.cbTalkOfferedTick = Max(sys.GetTickCount(), 1);
    CBTalkHush(npc);
    // Their own talk is the conversation's to put back now (End), not the settling's.
    this.m_hushed = null;
    this.m_promptWait = 0.0;
    this.NextFrame(game);
    // Somebody down at V's feet gets the lines at once: the game keeps its own "Carry body" prompt up over them, in the
    // same place "Talk" would go, and the two took the prompt off each other every frame.
    if CBTalkFirstOn() && !CBTalkDownAtFeet(npc) {
      ArrayClear(this.m_lines);
      ArrayPush(this.m_lines, CBTalkMakeLine(CBT(n"Cyberbane-StreetTalk-Talk"), CBTalkActTalk(), t"ChoiceCaptionParts.TalkIcon"));
      this.m_index = 0;
      this.m_stage = CBTalkStageOffered();
      this.Push(game);
      CBLog.Info(n"Talk", s"Talk offered: \(CBTalkTitle(t)).");
      return;
    }
    this.OpenLines(sys, game, player);
  }

  // The lines go up, read again from how the person stands with V now: a ganger V has just leaned on may
  // be afraid by the second exchange, and the title says so.
  private func OpenLines(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let t = this.m_target;
    if !IsDefined(t) || !IsDefined(t.npc) {
      this.End(game, "they are gone");
      return;
    }
    if this.m_exchanges > 0 {
      let fresh = CBTalkRead(sys, game, t.npc);
      if IsDefined(fresh) {
        this.m_target = fresh;
        t = fresh;
      }
    }
    if this.m_menu == CBTalkMenuAsk() {
      this.m_lines = CBTalkQuestionLines(sys, game, t);
    } else {
      if this.m_menu == CBTalkMenuDeal() {
        this.m_lines = CBTalkDealLines(game, t, this.m_dealPrice, this.m_dealHaggles >= CBConfig.TalkHaggleRounds(), this.m_dealKind);
      } else {
        if this.m_menu == CBTalkMenuBusiness() {
          this.m_lines = CBTalkBusinessLines(sys, game, t);
        } else {
          this.m_lines = CBTalkChoices(sys, game, t, this.m_exchanges > 0);
        }
      }
    }
    this.m_index = 0;
    this.m_stage = CBTalkStageOpen();
    this.m_lostFor = 0.0;
    this.Engage(player);
    this.Push(game);
    // Hands stay empty while the lines are up, so the wheel picks a line instead of drawing a gun.
    if !this.m_handsHeld {
      CBQueueZoneArmsLock(player, true);
      this.m_handsHeld = true;
    }
    if this.m_exchanges == 0 {
      CBLog.Info(n"Talk", s"Prompt up: \(CBTalkTitle(t)).");
      // A word in their own voice as the talk opens: a greeting, or a scared one's plea.
      if IsDefined(t.npc) {
        CBVoice(sys, game, t.npc, t.mood == CBTalkAfraid() ? n"fear_beg" : n"greeting", n"TalkOpens", 10.0);
      }
      this.m_diagLeft = 1.0;
      this.m_diagCount = 0;
      // A ganger afraid of V, spoken to, does not go on sizing V up: one the game has hostile to V watched V through
      // the whole conversation with their detection rising.
      if t.mood == CBTalkAfraid() && NotEquals(t.faction, n"") && !t.cop && t.npc.cbHoldState != 2 {
        CBStandDownFromV(game, t.npc);
      }
    }
  }

  // The conversation has started: V pressed Talk, or with Ask first off, the lines came straight up. Once per
  // conversation. With Passers-by stop to talk off they keep walking, and the conversation ends when they are out of
  // reach.
  private func Engage(player: ref<PlayerPuppet>) -> Void {
    let t = this.m_target;
    if this.m_engaged || !IsDefined(t) || !IsDefined(t.npc) || !t.npc.IsAttached() {
      return;
    }
    this.m_engaged = true;
    this.m_holdAge = 0.0;
    let npc = t.npc;
    npc.cbTalkLinesUp = true;
    // Their people hold their fire while V talks to one of them (Reactions/TalkTruce.reds).
    let sysTruce = CyberbaneSystem.Get(player.GetGame());
    if IsDefined(sysTruce) && !t.cop {
      sysTruce.GetTruce().Begin(sysTruce, player.GetGame(), CBTruceTalk(), t.faction, npc);
    }
    if CBTalkStopWalkersOn() && !t.atWork && t.rivalId == 0 {
      if npc.IsCrowd() {
        let crowd = npc.GetCrowdMemberComponent();
        if IsDefined(crowd) && crowd.IsInCrowd() && crowd.CheckIsMoving() {
          crowd.TryStopTrafficMovement();
          npc.cbTalkStopped = true;
        }
      }
      CBTalkHold(npc);
    }
    this.m_glanceIn = CBConfig.TalkGlanceEvery();
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) {
      reactions.CBGlanceAt(player);
    }
  }

  // "Talk" alone is the game's small interaction prompt, the one a door or a pickup shows; the lines are the dialogue
  // list.
  private func Push(game: GameInstance) -> Void {
    if !IsDefined(this.m_target) {
      return;
    }
    this.m_shownAt = CBTalkNow(game);
    if this.m_stage == CBTalkStageOffered() {
      CBTalkPushOffer(game, CBTalkTitle(this.m_target));
      return;
    }
    CBTalkClearOffer(game);
    CBTalkPushHub(game, CBTalkTitle(this.m_target), this.m_lines, this.m_index);
  }

  // The game took the list off the screen: counted, and what it put there instead said in the log, at the 5th and the
  // 30th time in one conversation.
  private func NoteWipe(game: GameInstance) -> Void {
    this.m_wipes += 1;
    if this.m_wipes == 5 || this.m_wipes == 30 {
      let player = GetPlayer(game);
      let fighting = IsDefined(player) && player.IsInCombat();
      CBLog.Info(n"Talk", s"Wiped (\(this.m_wipes)): \(CBTalkScreenNote(game)); \(CBNativePromptWords(game)); V in combat \(fighting); stage \(this.m_stage).");
    }
  }

  private func ShownJustNow(game: GameInstance) -> Bool {
    let now = CBTalkNow(game);
    return this.m_shownAt > 0.0 && now >= this.m_shownAt && now - this.m_shownAt <= CBConfig.TalkPressGrace();
  }

  private func Shown(game: GameInstance) -> Bool {
    return this.m_stage == CBTalkStageOffered() ? CBTalkOfferShown(game) : CBTalkHubShown(game);
  }

  // V says it. The words go up at once; the answer and everything it does come after a beat.
  private func Say(game: GameInstance, index: Int32) -> Void {
    if index < 0 || index >= ArraySize(this.m_lines) || !IsDefined(this.m_target) {
      return;
    }
    let line = this.m_lines[index];
    // A greyed line (a price V cannot cover) cannot be chosen, as in the game's lists.
    if line.inactive {
      return;
    }
    // In V's own voice where V has recorded the words (Reactions/TalkVoice.reds). The answer waits for V to finish
    // (below), and V's subtitle stays up as long as V speaks.
    let sysV = CyberbaneSystem.Get(game);
    let vSays = IsDefined(sysV) ? CBTalkVoiceSayV(sysV, game, line) : 0.0;
    let vWords = CBTalkWords(line.text);
    let vSecs = MaxF(CBTalkReadSeconds(vWords, CBConfig.TalkLineSeconds()), vSays);
    if CBGameSubtitlesOn(game) && CBShowGameSubtitle(game, 2, "V", vWords, vSecs) {
      this.m_vLineLeft = vSecs;
    }
    if line.act == CBTalkActLeave() {
      this.End(game, "V left it there");
      return;
    }
    // Back to the main lines: no answer needed.
    if line.act == CBTalkActMenuBack() {
      this.m_menu = CBTalkMenuMain();
      let sys = CyberbaneSystem.Get(game);
      let player = GetPlayer(game);
      if IsDefined(sys) && IsDefined(player) {
        this.OpenLines(sys, game, player);
      }
      return;
    }
    CBTalkClearHub(game);
    this.m_pending = line.act;
    this.m_pendingIn = MaxF(CBConfig.TalkAnswerDelay(), vSays + 0.25);
    this.m_stage = CBTalkStageWaiting();
    this.m_exchanges += 1;
  }

  // ---- The answer ----------------------------------------------------------------------------------

  private func Answer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> Void {
    let t = this.m_target;
    let choice = this.m_pending;
    let npc = IsDefined(t) ? t.npc : null;
    // Gone, down or already fighting by now: nobody left to answer.
    let downAtFeet = IsDefined(npc) && (npc.cbMercyOpen || npc.cbFacedownOpen || npc.cbSurrendered);
    if !IsDefined(npc) || !npc.IsAttached() || npc.IsDead()
       || (!downAtFeet && (ScriptedPuppet.IsDefeated(npc) || CBNpcInCombat(npc))) {
      this.End(game, "they are gone");
      return;
    }
    t.first = !CBTalkDid(npc, choice);
    CBTalkSetDid(npc, choice);
    let again = !t.first;
    let a: ref<CBTalkAnswer>;
    if choice == CBTalkGreet() {
      a = CBTalkOnGreet(sys, game, player, t);
    } else {
      if choice == CBTalkDismiss() {
        a = CBTalkOnDismiss(sys, game, player, t);
      } else {
        if choice == CBTalkAntagonize() {
          a = CBTalkOnAntagonize(sys, game, player, t);
          CBTalkNoteLeaned(game, npc);
        } else {
          if choice == CBTalkIntimidate() {
            a = CBTalkOnIntimidate(sys, game, player, t);
            CBTalkNoteLeaned(game, npc);
          } else {
            a = this.AnswerTopic(sys, game, player, t, choice, again);
          }
        }
      }
    }
    // Somebody who knows where a Rival is lying low says so when V first says hello, so the price is something V hears
    // about rather than has to go looking for.
    if choice == CBTalkGreet() && t.first && IsDefined(a) && t.mood != CBTalkHostile() && !npc.cbTalkSent {
      let hint = CBTalkTipHint(sys, game, t);
      if StrLen(hint) > 0 {
        a.line += " " + hint;
      }
    }
    // In their own voice (Reactions/TalkVoice.reds): the voiceset line the answer names, and a hello for a greeting
    // that names none.
    let waitTheirs = false;
    if IsDefined(a) && StrLen(a.line) > 0 {
      let vo = a.vo;
      let mode = a.voMode > 0 ? a.voMode : CBTalkVoiceUnder();
      if !IsNameValid(vo) && choice == CBTalkGreet() {
        vo = n"greeting";
        mode = CBTalkVoiceUnder();
      }
      waitTheirs = CBTalkVoiceSay(sys, game, npc, vo, mode, a.line, t.speaker) && mode == CBTalkVoiceTheirs();
    }
    // In the game's subtitles; with those switched off, on Cyberbane's own line, so the answer is
    // never lost (UI/PhoneMessages.reds, CBOverheard).
    if IsDefined(a) && StrLen(a.line) > 0 && !waitTheirs {
      this.ShowReply(game, t.speaker, a.line);
    }
    if waitTheirs {
      this.m_replyLeft = CBConfig.TalkVoiceWait() + 0.4;   // nothing else talks over the answer while it waits for them
    }
    // No voice line of the game's under the answer: a random line in their voice, with its own subtitle, never matched
    // what the answer said.
    let reactions = npc.GetStimReactionComponent();
    if IsDefined(reactions) && npc.IsAttached() && !npc.cbTalkSent {
      reactions.CBGlanceAt(player);
    }
    sys.GetScore().MarkDirty();
    // On, or over? Over when V brushed them off, they have gone, the talk turned to a fight, or it has
    // gone on long enough; otherwise the lines come back for more.
    let over = choice == CBTalkDismiss() || npc.cbTalkSent || this.m_exchanges >= CBConfig.TalkMaxExchanges()
               || StrLen(CBTalkWhyNot(sys, game, player, npc, CBConfig.TalkKeepRange(), true)) > 0;
    if over {
      this.End(game, "the conversation is over");
      return;
    }
    this.OpenLines(sys, game, player);
  }

  // The questions and the deal (Reactions/TalkTopics.reds); this keeps which list comes next.
  private func AnswerTopic(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                           t: ref<CBTalkTarget>, choice: Int32, again: Bool) -> ref<CBTalkAnswer> {
    if choice == CBTalkActMenuAsk() {
      this.m_menu = CBTalkMenuAsk();
      return CBTalkAnswerMenuAsk(t);
    }
    if choice == CBTalkActAskWord() {
      return CBTalkAnswerWord(sys, game, t, again);
    }
    if choice == CBTalkActAskTurf() {
      return CBTalkAnswerTurf(sys, game, t, again);
    }
    if choice == CBTalkActAskComing() {
      return CBTalkAnswerComing(sys, game, t, again);
    }
    if choice == CBTalkActAskHome() {
      return CBTalkAnswerHome(sys, game, t, again);
    }
    if choice == CBTalkActAskWorth() {
      return CBTalkAnswerWorth(sys, game, t, again);
    }
    if choice == CBTalkActCrewOther() {
      return CBCrewOtherAnswer(sys, game, t, CBCrewOfTalk(game, t.npc));
    }
    if choice == CBTalkActSellGoods() {
      return CBGoodsSell(sys, game, t);
    }
    if choice == CBTalkActCrewHolding() || choice == CBTalkActCrewGang() || choice == CBTalkActCrewHeard() {
      return CBCrewTalkAnswer(sys, game, t, choice, again);
    }
    if choice == CBTalkActAskRival() {
      return this.Offer(CBTalkAskRival(sys, game, player, t, again), CBTalkDealLead());
    }
    if choice == CBTalkActBusiness() {
      this.m_menu = CBTalkMenuBusiness();
      return CBTalkAnswerBusiness(t);
    }
    if choice == CBTalkActDealToll() {
      return this.Offer(CBTalkAskToll(sys, game, t), CBTalkDealToll());
    }
    if choice == CBTalkActDealCallOff() {
      return this.Offer(CBTalkAskCallOff(sys, game, t), CBTalkDealCallOff());
    }
    if choice == CBTalkActLifepath() {
      return CBTalkAnswerLifepath(sys, game, t);
    }
    if choice == CBTalkActDealPay() {
      let paid = CBTalkMoney(game) >= this.m_dealPrice;
      let pay: ref<CBTalkAnswer>;
      if this.m_dealKind == CBTalkDealToll() {
        pay = CBTalkDealPayToll(sys, game, player, t, this.m_dealPrice);
      } else {
        if this.m_dealKind == CBTalkDealCallOff() {
          pay = CBTalkDealPayCallOff(sys, game, player, t, this.m_dealPrice);
        } else {
          pay = CBTalkDealPay(sys, game, player, t, this.m_dealRival, this.m_dealPrice);
        }
      }
      if paid {
        this.m_menu = CBTalkMenuMain();
      }
      return pay;
    }
    if choice == CBTalkActDealHaggle() {
      let h = CBTalkDealHaggle(sys, game, t, this.m_dealPrice, this.m_dealHaggles);
      this.m_dealPrice = h.price;
      this.m_dealHaggles += 1;
      if h.walked {
        this.m_menu = CBTalkMenuMain();
      }
      return h.answer;
    }
    if choice == CBTalkActTurn() {
      return CBIntelTurn(sys, game, t);
    }
    if choice == CBTalkActFavour() {
      let life = CBStreetLifeFor(game);
      return IsDefined(life) ? life.OfferFavour(sys, game, player, t) : CBTalkSay(CBT(n"Cyberbane-War-NotNow"), n"");
    }
    if choice == CBTalkActSpare() || choice == CBTalkActCollect() || choice == CBTalkActExile()
       || choice == CBTalkActHumiliate() || choice == CBTalkActSetOn() || choice == CBTalkActRecruit() {
      return CBRivalMercyAnswer(sys, game, player, t, choice);
    }
    if CBTalkActIsFacedown(choice) {
      return CBRivalFacedownAnswer(sys, game, player, t, choice);
    }
    if choice == CBTalkActLeadWitnessAsk() || choice == CBTalkActLeadWitnessPay() {
      return CBLeadWitnessAnswer(sys, game, player, t, choice);   // Spawn/StreetStories.reds
    }
    if CBTalkActIsAlly(choice) {
      return CBAllyTalkAnswer(sys, game, player, t, choice);
    }
    if choice == CBTalkActLendOne() {
      return CBCrewLendAnswer(sys, game, t);   // Reactions/Crew.reds, [C4]
    }
    if CBTalkActIsParley(choice) {
      return CBParleyAnswer(sys, game, player, t, choice);
    }
    if choice == CBTalkActBack() || choice == CBTalkActIncite() || choice == CBTalkActProtection() || choice == CBTalkActTerms() {
      return CBWarTalkAnswer(sys, game, player, t, choice);
    }
    if choice == CBTalkActBribeScout() {
      return CBScoutTalkAnswer(sys, game, player, t);
    }
    if choice == CBTalkActStandWith() {
      return CBEventStandWith(sys, game, t);   // a front line's side (Spawn/StreetEvents.reds)
    }
    if choice == CBTalkActRespects() {
      return CBEventTalkAnswer(sys, game, t);
    }
    if choice == CBTalkActHushPay() || choice == CBTalkActHushLean() || choice == CBTalkActWatch() {
      return CBStreetPayAnswer(sys, game, player, t, choice);
    }
    if choice == CBTalkActDealLean() {
      this.m_menu = CBTalkMenuMain();
      return CBTalkDealLean(sys, game, player, t, this.m_dealRival);
    }
    if choice == CBTalkActDealForget() {
      this.m_menu = CBTalkMenuMain();
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-YourLoss"), CBT(n"Cyberbane-StreetTalk-SuitYourself")), n"");
    }
    return null;
  }

  // A price named: the deal goes up as the next list.
  private func Offer(o: ref<CBTalkOffer>, kind: Int32) -> ref<CBTalkAnswer> {
    if o.price > 0 {
      this.m_menu = CBTalkMenuDeal();
      this.m_dealKind = kind;
      this.m_dealRival = o.rivalId;
      this.m_dealPrice = o.price;
      this.m_dealHaggles = CBTalkHaggleOn() ? 0 : CBConfig.TalkHaggleRounds();
    }
    return o.answer;
  }

  // A ganger or a cop who is hostile to V and will not talk says so. Once per person.
  private func Refuse(game: GameInstance, npc: ref<ScriptedPuppet>) -> Void {
    if !IsDefined(npc) || npc.cbTalkRefused {
      return;
    }
    let faction = CBClassifyFaction(npc);
    let line = "";
    if Equals(faction, n"NCPD") {
      line = CBPick2(CBT(n"Cyberbane-StreetTalk-MoveAlong"), CBT(n"Cyberbane-StreetTalk-NotNowKeepWalking"));
    } else {
      if NotEquals(faction, n"") && NotEquals(faction, n"MaxTac") {
        line = CBGangRefuseLine(faction);
        if StrLen(line) == 0 {
          line = CBPick3(CBT(n"Cyberbane-StreetTalk-KeepWalkingMerc"), CBT(n"Cyberbane-StreetTalk-NotTalkingToYouMove"), CBT(n"Cyberbane-StreetTalk-WrongStreetToStopOn"));
        }
      }
    }
    if StrLen(line) == 0 {
      return;
    }
    npc.cbTalkRefused = true;
    let speaker = CBFactionMemberWord(faction);
    if StrLen(speaker) == 0 {
      speaker = CBT(n"Cyberbane-Whispers-Ganger");
    }
    if CBGameSubtitlesOn(game) {
      let rSecs = CBTalkReadSeconds(line, CBConfig.TalkReplySeconds());
      if CBShowGameSubtitle(game, 3, speaker, line, rSecs) {
        this.m_replyLeft = rSecs;
      }
    } else {
      CBOverheard(game, speaker, line);
    }
    CBLog.Info(n"Talk", s"A \(speaker) would not talk: hostile to V.");
  }

  // The conversation is over, whatever ended it. The person cannot be spoken to again for a moment once
  // something was said (TalkCooldownTicks), and the log says why it ended.
  private func End(game: GameInstance, why: String) -> Void {
    let wasOn = this.m_stage != CBTalkStageIdle();
    let sysTruce = CyberbaneSystem.Get(game);
    if IsDefined(sysTruce) {
      sysTruce.GetTruce().End(sysTruce, game, CBTruceTalk());
    }
    if this.m_stage == CBTalkStageOffered() || this.m_stage == CBTalkStageOpen() {
      CBTalkClearHub(game);
      CBTalkClearOffer(game);
    }
    if wasOn && this.m_exchanges > 0 && IsDefined(this.m_target) && IsDefined(this.m_target.npc) {
      let sys = CyberbaneSystem.Get(game);
      this.m_target.npc.cbTalkTick = IsDefined(sys) ? Max(sys.GetTickCount(), 1) : 1;
      this.m_target.npc.cbTalkTimes += 1;
    }
    // Their own voice and their own fears again, and the hold let go.
    if IsDefined(this.m_target) && IsDefined(this.m_target.npc) {
      this.m_target.npc.cbTalkPartner = false;
      this.m_target.npc.cbTalkLinesUp = false;
      CBTalkReleaseHold(this.m_target.npc);
      CBTalkUnhush(this.m_target.npc);
    }
    // A passer-by V held walks on: back into the crowd's foot traffic, the way the game puts somebody on foot back into
    // it (reactionSystem.script, TryAndJoinTraffic, away from V), or failing that, a walk away from V.
    if IsDefined(this.m_target) && IsDefined(this.m_target.npc) && (this.m_target.npc.cbTalkStopped || this.m_target.npc.cbTalkHeld) {
      let walker = this.m_target.npc;
      let stopped = walker.cbTalkStopped;
      walker.cbTalkStopped = false;
      walker.cbTalkHeld = false;
      let you = GetPlayer(game);
      if walker.IsAttached() && IsDefined(you) && !walker.cbTalkSent && CBStillStanding(walker) && !CBNpcInCombat(walker)
         && (stopped || walker.IsCrowd()) {
        let reactions = GameInstance.GetReactionSystem(game);
        let rejoined = IsDefined(reactions)
                    && reactions.TryAndJoinTraffic(walker, Vector4.Vector4To3(you.GetWorldPosition()), false);
        if !rejoined && stopped {
          CBOrderFlee(game, walker, true);
        }
      }
    }
    // Somebody with their hands up stays where they kneel: the conversation's own short holds replaced the long one
    // they gave up with, and its end let them go, so a hostage V had just asked a ransom for wandered off before their
    // gang could answer.
    if IsDefined(this.m_target) && IsDefined(this.m_target.npc) && this.m_target.npc.cbSurrendered
       && !this.m_target.npc.cbTalkSent && CBStillStanding(this.m_target.npc) {
      CBTalkHold(this.m_target.npc, CBConfig.SurrenderHoldSeconds());
    }
    // So does a Rival standing for a facedown V walked away from without an answer: the conversation's short holds
    // took the place of theirs, and the facedown's own clock, not a lapsed order, decides what happens next.
    if IsDefined(this.m_target) && IsDefined(this.m_target.npc) && this.m_target.npc.cbFacedownHeld
       && !this.m_target.npc.cbTalkSent && CBStillStanding(this.m_target.npc) {
      CBTalkHold(this.m_target.npc, CBConfig.FacedownHoldSeconds());
    }
    // The street leaves them be for a moment as they go: standing right beside V, the crowd's fear reached them the
    // second the conversation let go, and somebody V had just chatted with cowered on the spot, hands up, frozen.
    if wasOn && this.m_engaged && IsDefined(this.m_target) && IsDefined(this.m_target.npc) {
      let sysCalm = CyberbaneSystem.Get(game);
      if IsDefined(sysCalm) {
        this.m_target.npc.cbCrowdReactedTick = Max(sysCalm.GetTickCount(), 1);
        this.m_target.npc.cbCrowdLastFear = Max(this.m_target.npc.cbCrowdLastFear, 2);
      }
    }
    if wasOn {
      if this.m_wipes > 0 {
        CBLog.Info(n"Talk", s"Prompt down: \(why) (the game took the prompt off the screen \(this.m_wipes) times).");
      } else {
        CBLog.Info(n"Talk", s"Prompt down: \(why).");
      }
    }
    this.m_frameGen += 1;
    this.m_stage = CBTalkStageIdle();
    this.m_target = null;
    ArrayClear(this.m_lines);
    this.m_lostFor = 0.0;
    this.m_promptWait = 0.0;
    this.m_holdAge = 0.0;
    this.m_wantOpen = false;
    this.m_wantSay = false;
    this.m_engaged = false;
    this.ReleaseHands(game);
  }

  private func StandDown(game: GameInstance, why: String) -> Void {
    this.End(game, why);
    this.StopListening();
    this.SetCandidate(null);
    this.m_dwell = 0.0;
    // Talk is off for now (a fight, a car, a scene): every bystander's own talk back.
    this.RestoreNear(GetPlayer(game), true);
  }

  // Everything that has to be true for anybody to be talked to at all, as the first reason it fails
  // ("" when it does not), for the log.
  private func AllowedWhyNot(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>) -> String {
    if !CBStreetTalkOn() {
      return "Talk to people is off in Mod Settings, or Cyberbane is off";
    }
    if !CBWorldStable(game) {
      // Which of its tests it was: a grapple read as "loading". Without its full stop: the log adds its own.
      let unready = StrLower(CBWorldStableWhy(game));
      return StrEndsWith(unready, ".") ? StrLeft(unready, StrLen(unready) - 1) : unready;
    }
    if CBPlayerInScene(game) {
      return "V is in a scene";
    }
    if sys.GetStoryHold() != CBStoryNone() {
      return "the story has the stage";
    }
    // A safe area, a job nearby and a gang's own turf used to switch talk off outright: the Director's rules for when
    // it may turn or scatter people, borrowed whole.
    if CBPlayerNoCombatTag(game) {
      return "the story has quieted things here";
    }
    if !sys.WornReady() {
      return "the session has only just started";
    }
    if player.IsInCombat() {
      return CBTalkWhyVInCombat();
    }
    if VehicleComponent.IsMountedToVehicle(game, player.GetEntityID()) {
      return "V is in a vehicle";
    }
    // Nobody sneaks up on somebody to say hello. Crouched behind a ganger for a takedown, the prompt came up instead,
    // and V's hands were held while it was up.
    if CBPlayerCrouched(game) {
      return CBTalkWhyCrouched();
    }
    return "";
  }

  // V has been facing somebody close for a moment and the prompt did not come up: say why, once per
  // reason, at most every few seconds. Only for somebody in talking range, so it never fills the log.
  private func NoteWhyNot(game: GameInstance, dt: Float, npc: ref<ScriptedPuppet>, why: String) -> Void {
    let player = GetPlayer(game);
    // Within the keep range: somebody a step too far was refused with nothing in the log.
    if !IsDefined(npc) || !IsDefined(player) || StrLen(why) == 0
       || Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > CBConfig.TalkKeepRange() {
      this.m_whyFor = 0.0;
      return;
    }
    this.m_whyFor += dt;
    if this.m_whyFor < CBConfig.TalkDwell() * 2.0 {
      return;
    }
    let ts = GameInstance.GetTimeSystem(game);
    let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
    if Equals(why, this.m_whyLogged) && now >= this.m_whyLogAt && now - this.m_whyLogAt < CBConfig.TalkWhyLogSeconds() {
      return;
    }
    this.m_whyLogged = why;
    this.m_whyLogAt = now;
    let words = Equals(why, CBTalkWhyGamePrompt()) ? CBNativePromptWords(game) : "";
    if StrLen(words) > 0 {
      CBLog.Info(n"Talk", s"No prompt for the person in front of V: \(why) (\(words)).");
    } else {
      CBLog.Info(n"Talk", s"No prompt for the person in front of V: \(why).");
    }
  }

  // V has stood in front of somebody with empty hands, plainly wanting a word, and the reason they will not talk is not
  // one V can see (CBTalkWhyHint). Said once per person, and never more often than every TalkExplainGapSeconds.
  private func ShowNote(game: GameInstance, player: ref<PlayerPuppet>, npc: ref<ScriptedPuppet>, why: String, dwelled: Bool) -> Void {
    let words = CBTalkNoteWords(why);
    if !IsDefined(npc) || !IsDefined(player) || StrLen(words) == 0 || !dwelled || CBPlayerAiming(game)
       || (player.IsInCombat() && !Equals(why, CBTalkWhyVInCombat()))
       || Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > CBConfig.TalkRange()
       || (!this.m_noteUp && CBNativePromptKind(game) != CBPromptNone()) {
      this.HideNote(game);
      return;
    }
    if this.m_noteUp && Equals(this.m_noteFor, npc.GetEntityID()) && Equals(this.m_noteText, words) && CBTalkOfferShown(game) {
      return;   // still up, as it was
    }
    // Something of the game's took the place since: it has the screen, and ours does not go back over it.
    if this.m_noteUp && !CBTalkOfferShown(game) && CBNativePromptKind(game) != CBPromptNone() {
      this.m_noteUp = false;
      return;
    }
    CBTalkPushNote(game, words);
    this.m_noteUp = true;
    this.m_noteFor = npc.GetEntityID();
    this.m_noteText = words;
  }

  private func HideNote(game: GameInstance) -> Void {
    if this.m_noteUp {
      this.m_noteUp = false;
      CBTalkClearOffer(game);
    }
  }

  private func Explain(game: GameInstance, npc: ref<ScriptedPuppet>, why: String) -> Void {
    // Where messages go set to Off is silence, and this is a message. Nor when the greyed prompt says it already.
    if !IsDefined(npc) || npc.cbTalkExplained || this.m_whyFor < CBConfig.TalkDwell() * 2.0 || !CBMessagesOn() || this.m_noteUp {
      return;
    }
    let line = CBTalkWhyHint(why);
    let player = GetPlayer(game);
    if StrLen(line) == 0 || !IsDefined(player) || IsDefined(GameObject.GetActiveWeapon(player))
       || Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > CBConfig.TalkRange() {
      return;
    }
    let ts = GameInstance.GetTimeSystem(game);
    let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
    if this.m_explainedAt > 0.0 && now >= this.m_explainedAt && now - this.m_explainedAt < CBConfig.TalkExplainGapSeconds() {
      return;
    }
    npc.cbTalkExplained = true;
    this.m_explainedAt = MaxF(now, 1.0);
    CBSystemNote(game, line, 5.0);
  }

  // Who V is facing, up close.
  private func LookedAt(game: GameInstance, player: ref<PlayerPuppet>, opt query: Bool) -> ref<ScriptedPuppet> {
    let ppos = player.GetWorldPosition();
    let targeting = GameInstance.GetTargetingSystem(game);
    if IsDefined(targeting) {
      let hit = targeting.GetLookAtObject(player, true, true) as ScriptedPuppet;
      if !IsDefined(hit) {
        hit = targeting.GetLookAtObject(player, false, false) as ScriptedPuppet;
      }
      if IsDefined(hit) && !hit.IsPlayer() && Vector4.Distance(ppos, hit.GetWorldPosition()) <= CBConfig.TalkKeepRange() {
        return hit;
      }
    }
    let sys = CyberbaneSystem.Get(game);
    let reg = IsDefined(sys) ? sys.GetRegistry() : null;
    if !IsDefined(reg) {
      return null;
    }
    let fwd = Vector4.Normalize2D(player.GetWorldForward());
    let best: ref<ScriptedPuppet>;
    let bestDot = CBConfig.TalkFacingDot();
    // The per-NPC gate first (Reactions/NpcRegistry.reds): the registry still holds people who are streaming in or out.
    for p in reg.GetAll() {
      if CBNpcSafe(sys, p) && !p.IsPlayer() && !p.IsDead() {
        let pos = p.GetWorldPosition();
        if Vector4.Distance(ppos, pos) <= CBConfig.TalkRange() && AbsF(pos.Z - ppos.Z) <= 1.5 {
          let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
          let dot = fwd.X * dir.X + fwd.Y * dir.Y;
          if dot >= bestDot {
            best = p;
            bestDot = dot;
          }
        }
      }
    }
    // The registry can miss somebody who streamed in beside V on a crowded street; the game's targeting query does not
    // ("I was in their face and nothing came up", and nothing logged).
    if !IsDefined(best) && query && !player.IsInCombat() {
      this.m_queryIn -= CBConfig.TalkTickSeconds();
      if this.m_queryIn <= 0.0 {
        this.m_queryIn = 0.5;
        best = CBTalkFacingNear(game, player, null);
      }
    }
    return best;
  }

  // The person in talking range nearest V's line of sight who can be talked to now, other than `skip`.
  private func NextTalkable(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                            skip: ref<ScriptedPuppet>) -> ref<ScriptedPuppet> {
    let reg = sys.GetRegistry();
    if !IsDefined(reg) {
      return null;
    }
    let ppos = player.GetWorldPosition();
    let fwd = Vector4.Normalize2D(player.GetWorldForward());
    let best: ref<ScriptedPuppet>;
    let bestDot = CBConfig.TalkNextDot();
    for p in reg.GetAll() {
      if CBNpcSafe(sys, p) && !p.IsPlayer() && !p.IsDead()
         && (!IsDefined(skip) || !Equals(p.GetEntityID(), skip.GetEntityID())) {
        let pos = p.GetWorldPosition();
        if Vector4.Distance(ppos, pos) <= CBConfig.TalkRange() && AbsF(pos.Z - ppos.Z) <= 1.5 {
          let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
          let dot = fwd.X * dir.X + fwd.Y * dir.Y;
          if dot >= bestDot && StrLen(CBTalkWhyNot(sys, game, player, p, CBConfig.TalkRange())) == 0 {
            best = p;
            bestDot = dot;
          }
        }
      }
    }
    if !IsDefined(best) {
      let near = CBTalkFacingNear(game, player, skip);
      if IsDefined(near) && StrLen(CBTalkWhyNot(sys, game, player, near, CBConfig.TalkRange())) == 0 {
        best = near;
      }
    }
    return best;
  }

  // The lock comes off unless V is now somewhere the game itself keeps V's hands empty: a safe area
  // keeps its own lock, and lifting it there would be lifting the game's.
  private func ReleaseHands(game: GameInstance) -> Void {
    if !this.m_handsHeld {
      return;
    }
    this.m_handsHeld = false;
    let player = GetPlayer(game);
    if IsDefined(player) && !CBPlayerInSafeZone(game) {
      CBQueueZoneArmsLock(player, false);
    }
  }

  private func Listen(player: ref<PlayerPuppet>) -> Void {
    if IsDefined(this.m_listening) {
      return;
    }
    if !IsDefined(this.m_input) {
      this.m_input = new CBTalkInput();
      this.m_input.owner = this;
    }
    player.RegisterInputListener(this.m_input, n"ChoiceScrollUp");
    player.RegisterInputListener(this.m_input, n"ChoiceScrollDown");
    player.RegisterInputListener(this.m_input, n"ChoiceApply");
    player.RegisterInputListener(this.m_input, n"Choice1");
    player.RegisterInputListener(this.m_input, n"NextWeapon");
    player.RegisterInputListener(this.m_input, n"PreviousWeapon");
    // Reaching for a weapon ends it. V's hands are held while the lines are up, so the scroll wheel picks a line
    // instead of a gun; a weapon key used to do nothing at all until V looked away.
    player.RegisterInputListener(this.m_input, n"SwitchItem");
    player.RegisterInputListener(this.m_input, n"WeaponSlot1");
    player.RegisterInputListener(this.m_input, n"WeaponSlot2");
    player.RegisterInputListener(this.m_input, n"WeaponSlot3");
    player.RegisterInputListener(this.m_input, n"WeaponSlot4");
    player.RegisterInputListener(this.m_input, n"WeaponWheel");
    player.RegisterInputListener(this.m_input, n"QuickMelee");
    player.RegisterInputListener(this.m_input, n"UseCombatGadget");
    this.m_listening = player;
  }

  private func StopListening() -> Void {
    let player = this.m_listening;
    if IsDefined(player) && IsDefined(this.m_input) {
      player.UnregisterInputListener(this.m_input);
    }
    this.m_listening = null;
  }

  // ---- The keys ------------------------------------------------------------------------------------
  // Only requests are made here; the tick carries them out.

  public func OnInput(action: ListenerAction) -> Void {
    if this.m_stage == CBTalkStageIdle() {
      return;
    }
    let name = ListenerAction.GetName(action);
    let kind = ListenerAction.GetType(action);
    let pressed = Equals(kind, gameinputActionType.BUTTON_PRESSED);
    // Reaching for a weapon ends it at any point, an answer on its way included: V's hands are held
    // from the moment the lines go up until the conversation is over.
    if CBTalkReachKey(name) {
      if pressed || Equals(kind, gameinputActionType.BUTTON_HOLD_COMPLETE) {
        this.End(this.m_game, "V reached for a weapon");
        this.m_quietLeft = CBConfig.TalkQuietAfterReach();
      }
      return;
    }
    // ChoiceApply (the dialogue list's confirm) arrives as BUTTON_PRESSED, Choice1 (the interaction prompt's F) only as
    // BUTTON_RELEASED (r6/config/inputContexts.xml).
    let confirm = Equals(name, n"ChoiceApply") || Equals(name, n"Choice1");
    let push = false;
    if Equals(name, n"ChoiceApply") {
      push = pressed;
      if push {
        this.m_applyPressed = true;
      }
    } else {
      if Equals(name, n"Choice1") && Equals(kind, gameinputActionType.BUTTON_RELEASED) {
        push = !this.m_applyPressed;
        this.m_applyPressed = false;
      }
    }
    if this.m_stage != CBTalkStageOffered() && this.m_stage != CBTalkStageOpen() {
      return;
    }
    if confirm {
      // Only a list V can see can be answered. F pressed at somebody whose list the game had wiped said a line V never
      // saw.
      if push && (this.Shown(this.m_game) || this.ShownJustNow(this.m_game)) {
        if this.m_stage == CBTalkStageOffered() {
          this.m_wantOpen = true;
        } else {
          this.m_wantSay = true;
          this.m_wantIndex = this.m_index;
        }
      }
      return;
    }
    // Nothing to scroll with only "Talk" up; with V's hands free, the wheel is the game's.
    if this.m_stage != CBTalkStageOpen() {
      return;
    }
    // A D-pad press, its repeat, or a notch of the mouse wheel, which can come as a relative change.
    let notch = Equals(kind, gameinputActionType.RELATIVE_CHANGE) && AbsF(ListenerAction.GetValue(action)) > 0.0;
    if !pressed && !notch && !Equals(kind, gameinputActionType.REPEAT) {
      return;
    }
    if Equals(name, n"ChoiceScrollUp") {
      this.Scroll(-1, false);
    } else {
      if Equals(name, n"ChoiceScrollDown") {
        this.Scroll(1, false);
      } else {
        if Equals(name, n"PreviousWeapon") {
          this.Scroll(-1, true);
        } else {
          if Equals(name, n"NextWeapon") {
            this.Scroll(1, true);
          }
        }
      }
    }
  }

  // One notch of the wheel can arrive as both a choice action and a weapon action.
  private func Scroll(step: Int32, byWeapon: Bool) -> Void {
    let count = ArraySize(this.m_lines);
    if count == 0 {
      return;
    }
    let ts = GameInstance.GetTimeSystem(this.m_game);
    let now = IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
    let sameFrame = this.m_lastScrollAt > 0.0 && now == this.m_lastScrollAt;
    if byWeapon {
      if this.m_choiceScrollSeen || sameFrame {
        return;
      }
    } else {
      this.m_choiceScrollSeen = true;
      if sameFrame {
        if !this.m_lastScrollByWeapon {
          return;
        }
        this.m_index = (this.m_index - this.m_lastScrollStep + count) % count;
      }
    }
    this.m_index = (this.m_index + step + count) % count;
    this.m_lastScrollAt = now;
    this.m_lastScrollStep = step;
    this.m_lastScrollByWeapon = byWeapon;
    CBTalkSelect(this.m_game, this.m_index);
  }

  // The answer, up: in the game's subtitles, or with those switched off on Cyberbane's own line, so it is never lost.
  private func ShowReply(game: GameInstance, speaker: String, line: String) -> Void {
    if CBGameSubtitlesOn(game) {
      let aSecs = CBTalkReadSeconds(line, CBConfig.TalkReplySeconds());
      if CBShowGameSubtitle(game, 3, speaker, line, aSecs) {
        this.m_replyLeft = aSecs;
      }
    } else {
      CBOverheard(game, speaker, line);
    }
  }

  // How long V's line and the answer are still up, so nothing else talks over them (Busy).
  private func AgeLines(game: GameInstance, dt: Float) -> Void {
    if this.m_vLineLeft > 0.0 {
      this.m_vLineLeft -= dt;
    }
    if this.m_replyLeft > 0.0 {
      this.m_replyLeft -= dt;
    }
  }
}

// The person nearest V's line of sight in talking range, by the game's targeting query (the one its melee and leap use:
// TSQ_NPC, gameObject.script GetEntitiesAroundObject), other than `skip`.
func CBTalkFacingNear(game: GameInstance, player: ref<PlayerPuppet>, skip: ref<ScriptedPuppet>) -> ref<ScriptedPuppet> {
  let targeting = GameInstance.GetTargetingSystem(game);
  if !IsDefined(targeting) {
    return null;
  }
  let q: TargetSearchQuery;
  q.testedSet = TargetingSet.Complete;
  q.searchFilter = TSF_NPC();
  q.maxDistance = CBConfig.TalkRange();
  q.filterObjectByDistance = true;
  q.includeSecondaryTargets = false;
  q.ignoreInstigator = true;
  let parts: array<TS_TargetPartInfo>;
  targeting.GetTargetParts(player, q, parts);
  let ppos = player.GetWorldPosition();
  let fwd = Vector4.Normalize2D(player.GetWorldForward());
  let best: ref<ScriptedPuppet>;
  let bestDot = CBConfig.TalkFacingDot();
  for part in parts {
    let comp = TS_TargetPartInfo.GetComponent(part);
    let p = IsDefined(comp) ? comp.GetEntity() as ScriptedPuppet : null;
    if IsDefined(p) && !p.IsPlayer() && !p.IsDead() && (!IsDefined(skip) || !Equals(p.GetEntityID(), skip.GetEntityID())) {
      let pos = p.GetWorldPosition();
      if AbsF(pos.Z - ppos.Z) <= 1.5 {
        let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
        let dot = fwd.X * dir.X + fwd.Y * dir.Y;
        if dot >= bestDot {
          best = p;
          bestDot = dot;
        }
      }
    }
  }
  return best;
}

// Is this person still close and in front of V? Wide enough that a conversation survives V's eyes moving
// across the group, narrow enough that turning away ends it.
func CBTalkFacing(player: ref<PlayerPuppet>, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(player) || !IsDefined(npc) {
    return false;
  }
  let ppos = player.GetWorldPosition();
  let pos = npc.GetWorldPosition();
  if Vector4.Distance(ppos, pos) > CBConfig.TalkKeepRange() {
    return false;
  }
  let fwd = Vector4.Normalize2D(player.GetWorldForward());
  let dir = Vector4.Normalize2D(new Vector4(pos.X - ppos.X, pos.Y - ppos.Y, 0.0, 0.0));
  return fwd.X * dir.X + fwd.Y * dir.Y >= CBConfig.TalkKeepDot();
}

// A key V reaches for a weapon or a gadget with (CBStreetTalk.Listen).
func CBTalkReachKey(name: CName) -> Bool {
  return Equals(name, n"SwitchItem") || Equals(name, n"WeaponSlot1") || Equals(name, n"WeaponSlot2")
      || Equals(name, n"WeaponSlot3") || Equals(name, n"WeaponSlot4") || Equals(name, n"WeaponWheel")
      || Equals(name, n"QuickMelee") || Equals(name, n"UseCombatGadget");
}

// Crouched, and only that.
public func CBPlayerCrouched(game: GameInstance) -> Bool {
  let psm = CBPlayerPSM(game);
  return IsDefined(psm)
      && psm.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion) == EnumInt(gamePSMLocomotionStates.Crouch);
}

// The parley held: this one, and everybody of their gang standing with them who has not already been
// turned on V, hold back from V from now on. How many of the crew went with them.
func CBTalkParleyCrew(sys: ref<CyberbaneSystem>, t: ref<CBTalkTarget>) -> Int32 {
  let npc = t.npc;
  if !IsDefined(npc) {
    return 0;
  }
  CBStandDownFromV(npc.GetGame(), npc);
  let reg = IsDefined(sys) ? sys.GetRegistry() : null;
  if !IsDefined(reg) {
    return 0;
  }
  let here = npc.GetWorldPosition();
  let id = npc.GetEntityID();
  let count = 0;
  for other in reg.GetAll() {
    if CBNpcSafe(sys, other) && NotEquals(other.GetEntityID(), id) && !other.IsDead() && !other.cbHostileByCyberbane
       && Vector4.Distance(here, other.GetWorldPosition()) <= CBConfig.HoldBackBackerRadius()
       && Equals(CBClassifyFaction(other), t.faction) {
      CBStandDownFromV(other.GetGame(), other);
      count += 1;
    }
  }
  return count;
}

// ---- Who can be talked to ------------------------------------------------------------------------------

// The reason a hostile person gives, kept as one string so the refusal line can recognise it.
public func CBTalkWhyHostile() -> String = "they are hostile to V"
public func CBTalkWhyTurf() -> String = "V is on their hostile ground, where the game turns them on V on sight"

// Their gang hostile to V on sight in the other mod's record.
public func CBTalkWhyGrudge() -> String {
  return CBRememberModName() + " has their gang hostile to V on sight";
}

// Standing with V: V's crew, a follower, an ally lent by a gang.
func CBTalkOnVsSide(des: ref<DynamicEntitySystem>, npc: wref<ScriptedPuppet>) -> Bool {
  if !IsDefined(des) || !IsDefined(npc) {
    return false;
  }
  let id = npc.GetEntityID();
  return des.IsTagged(id, n"CB_Own") || des.IsTagged(id, n"CB_Ally") || des.IsTagged(id, n"CB_Follower") || des.IsTagged(id, n"CB_Guard")
      || des.IsTagged(id, n"CB_Loiter");   // V's crew on a corner
}

// The reasons V is told about (CBTalkWhyHint), each kept as one string for the same reason.
public func CBTalkWhySentAfterV() -> String = "one of Cyberbane's own, here for V (a crew, a Rival or a hunter)"
public func CBTalkWhyJob() -> String = "they are at one of V's jobs"
public func CBTalkWhyStory() -> String = "part of a story or a job (a quest character)"
public func CBTalkWhyTracked() -> String = "at the job V is tracking"
public func CBTalkWhyLair() -> String = "a Rival at their place, or one of their people"
public func CBTalkWhyGamePrompt() -> String = "one of the game's own prompts is up"
public func CBTalkWhyCrouched() -> String = "V is crouched"
// Down and breathing, and not a Rival at V's mercy: questioned by crouching beside them (Reactions/StreetIntel.reds).
public func CBTalkWhyDowned() -> String = "they are down: questioned by crouching beside them"
public func CBTalkWhyVInCombat() -> String = "V is in combat"

// Somebody a fight is for, who can be spoken to in the middle of it: down at V's feet for the mercy choice, hands up,
// or standing for a facedown or a parley. Our own fields only.
public func CBTalkMidFight(npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(npc) && (npc.cbMercyOpen || npc.cbSurrendered || npc.cbGaveUp || npc.cbFacedownOpen);
}

// What V is told when somebody will not talk for a reason V cannot see, "" for the rest: a fight, a weapon, a car,
// somebody running or too far off speak for themselves, a vendor and a companion have the game's prompts, and the
// passing ones (V spoke to them a moment ago, they have only just appeared) are over before a note could be read.
public func CBTalkWhyHint(why: String) -> String {
  if Equals(why, CBTalkWhySentAfterV()) {
    return CBT(n"Cyberbane-StreetTalk-TheyAreHereForYouThere");
  }
  if Equals(why, CBTalkWhyLair()) {
    return CBT(n"Cyberbane-StreetTalk-TheyAreARivalSPeople");
  }
  if Equals(why, CBTalkWhyJob()) || Equals(why, CBTalkWhyTracked()) {
    return CBT(n"Cyberbane-StreetTalk-TheyArePartOfAJob");
  }
  if Equals(why, CBTalkWhyStory()) {
    return CBT(n"Cyberbane-StreetTalk-TheyBelongToAStorySo");
  }
  if Equals(why, "MaxTac") {
    return CBT(n"Cyberbane-StreetTalk-MaxTacDoesNotTalk");
  }
  if Equals(why, CBTalkWhyGamePrompt()) {
    return CBT(n"Cyberbane-StreetTalk-TheyOrSomethingBesideThemHave");
  }
  if Equals(why, CBTalkWhyDowned()) {
    return CBT(n"Cyberbane-StreetTalk-DownCrouchToQuestion");
  }
  return "";
}

// The first reason this person cannot be talked to, "" when they can (the log says which). With `talking`, V is already
// in a conversation with them, and the wait between conversations does not apply.
public func CBTalkWhyNot(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                         npc: wref<ScriptedPuppet>, range: Float, opt talking: Bool) -> String {
  if !IsDefined(npc) || !IsDefined(player) || !npc.IsAttached() {
    return "they are down or gone";
  }
  // The per-NPC gate before anything else is read from them: what follows asks for their status effects, their record
  // (IsHuman) and their position, and this is handed people straight from the targeting system and the registry, some
  // of whom have only just streamed in.
  if !CBNpcSafe(sys, npc) {
    return "they have only just appeared";
  }
  if npc.IsDead() {
    return "they are down or gone";
  }
  if CBTalkOwnBusiness(npc) {
    return CBTalkWhyOwnBusiness();
  }
  // A Rival V has put down can be talked to where they lie (Rivals/RivalLife.reds).
  let mercy = npc.cbMercyOpen;
  if !mercy && (ScriptedPuppet.IsDefeated(npc) || !CBStillStanding(npc)) {
    // A downed ganger who is still breathing is questioned, not talked to: said so, since nothing on screen did.
    return ScriptedPuppet.IsDefeated(npc) && !npc.IsDead() && npc.IsHuman() ? CBTalkWhyDowned() : "they are down or gone";
  }
  if !npc.IsHuman() || npc.IsMechanical() {
    return "not a person";
  }
  // Somebody V sent on their way can be spoken to again a few minutes later; before that they stayed out of reach until
  // they streamed out.
  if npc.cbTalkSent && npc.cbTalkSentTick > 0 && sys.GetTickCount() - npc.cbTalkSentTick >= CBConfig.TalkSentRestTicks() {
    npc.cbTalkSent = false;
  }
  // Broken and running, unless they ran out of road: somebody who gave up is marked broken by the same break that made
  // them give up (Reactions/Morale.reds, CBMoraleBreak), and a Rival who ran and was put down after is down at V's
  // feet.
  if npc.cbTalkSent || (npc.cbMoraleBroken && !mercy && !npc.cbSurrendered && !npc.cbGaveUp) {
    return "they are running from V";
  }
  if Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) > range {
    return "too far";
  }
  if !talking && npc.cbTalkTick > 0 && (sys.GetTickCount() - npc.cbTalkTick) < CBConfig.TalkCooldownTicks() {
    return "V spoke to them a moment ago";
  }
  if !CBSafetyGate.CanTalkTo(npc) {
    return CBTalkGateReason(sys, npc);
  }
  if mercy {
    return Vector4.Distance(player.GetWorldPosition(), npc.GetWorldPosition()) <= range ? "" : "too far";
  }
  // A Rival who has stopped to look at V first (Rivals/RivalMoments.reds): sent after V, and the one time they will
  // talk.
  if npc.cbFacedownOpen {
    return "";
  }
  // Somebody with their hands up can be talked to, ours or not (a ransom).
  if npc.cbSurrendered {
    return "";
  }
  let desT = GameInstance.GetDynamicEntitySystem();
  // A scout who has not called it in yet can be talked to (Spawn/Hunted.reds, [68]). Nor one of ours who gave up to V:
  // out of it, and theirs to talk to.
  if CBSentAfterV(desT, npc) && !CBIsScoutBody(sys, npc) && !npc.cbGaveUp {
    // Called off, or let go with their hands up (CB_Orphan): no longer here for V, and on their way out.
    if desT.IsTagged(npc.GetEntityID(), n"CB_Orphan") {
      return "stood down and on their way out";
    }
    // A Rival at their place, or one of their people there: told "they are here for you" when it is V who came.
    if desT.IsTagged(npc.GetEntityID(), n"CB_Lair") {
      return CBTalkWhyLair();
    }
    return CBTalkWhySentAfterV();
  }
  // Somebody down at V's feet or with their hands up is out of it, whatever the game still has them down as: mercy now
  // opens the moment a Rival goes down, while the rest of the fight goes on around them.
  if CBNpcInCombat(npc) && !CBTalkDownAtFeet(npc) && !npc.cbGaveUp {
    return "they are in a fight";
  }
  // Somebody standing at a job of V's: a gig's target, a contact. Close to the marker only: sixty metres round every
  // active objective on the map left whole streets with nobody to talk to.
  if sys.NearQuestPins(npc.GetWorldPosition(), CBConfig.TalkJobClearance()) {
    return CBTalkWhyJob();
  }
  if VehicleComponent.IsMountedToVehicle(game, npc.GetEntityID()) {
    return "they are in a vehicle";
  }
  if Equals(CBClassifyFaction(npc), n"MaxTac") {
    return "MaxTac";
  }
  // On a gang's restricted ground, whoever is not one of the crowd belongs to it, and the game's trespass rules turn
  // them on V however a conversation goes: the list came up, the game cleared it over and over ("the game took the
  // prompt off the screen 35 times"), and they opened fire eight seconds in.
  if CBPlayerInDangerZone(game) && !npc.IsCrowd() && !CBTalkDownAtFeet(npc) && !npc.cbGaveUp {
    return CBTalkWhyTurf();
  }
  // Their gang hostile to V on sight by They Will Remember's or Night City Remembers' record (CBTwrGangHostile, asked
  // whenever either is installed, whatever the compatibility setting).
  if !npc.IsCrowd() && !CBTalkDownAtFeet(npc) && !npc.cbGaveUp && !CBTalkOnVsSide(desT, npc) {
    let gang = CBClassifyFaction(npc);
    if NotEquals(gang, n"") && CBTwrGangHostile(game, gang) == 1 {
      return CBTalkWhyGrudge();
    }
  }
  // Hostile to V by the game's say (its gangs' own compounds, another mod) and not fighting: words are still possible
  // outside a compound, and the conversation ends the moment a fight starts.
  let agent = npc.GetAttitudeAgent();
  let pagent = player.GetAttitudeAgent();
  if IsDefined(agent) && IsDefined(pagent) && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile)
     && CBPlayerInDangerZone(game) {
    return CBTalkWhyHostile();
  }
  return "";
}

// Which of the Safety Gate's rules keeps this person out of it, in words. For the log only.
func CBTalkGateReason(sys: ref<CyberbaneSystem>, npc: wref<ScriptedPuppet>) -> String {
  if npc.IsQuest() || npc.cbAuthoredState == 1 {
    return CBTalkWhyStory();
  }
  if npc.IsVendor() {
    return "a vendor";
  }
  if npc.IsPlayerCompanion() {
    return "V's companion";
  }
  if IsDefined(sys) && sys.NearTrackedPins(npc.GetWorldPosition(), CBConfig.TalkTrackedClearance()) {
    return CBTalkWhyTracked();
  }
  return "the game protects them (a stand-in, or not fully in the world)";
}

// Is Cyberbane's hub what the game's dialog list is showing?
public func CBTalkHubShown(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return false;
  }
  let hubs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in hubs.choiceHubs {
    if hub.id == CBConfig.TalkHubId() {
      return true;
    }
  }
  return false;
}

// Who they are to V, read once as the prompt goes up.
public func CBTalkRead(sys: ref<CyberbaneSystem>, game: GameInstance, npc: ref<ScriptedPuppet>) -> ref<CBTalkTarget> {
  let score = sys.GetScore();
  if !IsDefined(score) || !IsDefined(npc) {
    return null;
  }
  let t = new CBTalkTarget();
  t.npc = npc;
  t.id = npc.GetEntityID();
  let faction = CBClassifyFaction(npc);
  t.cop = Equals(faction, n"NCPD");
  if !CBFactionOn(faction) {
    faction = n"";
  }
  t.faction = faction;
  t.recognized = CBRecognizes(sys, score, npc, faction, sys.GetCurrentDistrict());
  // Near the job V is tracking it is words only, the way it is in a safe place: thirty metres round it used to keep
  // everybody out of reach, which on a busy street was everybody.
  t.safe = sys.IsInSafeZone() || CBNpcInSafeInterior(npc) || sys.NearTrackedPins(npc.GetWorldPosition(), CBConfig.TalkWordsOnlyNearJob());
  let ws = GameInstance.GetWorkspotSystem(game);
  t.atWork = IsDefined(ws) && ws.IsActorInWorkspot(npc);
  t.nerve = CBNerve(npc);
  let gang = NotEquals(faction, n"") && !t.cop;
  if gang {
    t.backers = CBSameGangNear(sys, npc, faction, CBConfig.HoldBackBackerRadius(), CBConfig.HoldBackMaxBackers());
  }
  // How afraid: what anybody can see, and for somebody who knows who V is, what V is known for. A gang V
  // has broken is afraid on top of that.
  let looks = (CBAppearanceThreat(score.GetLook(), score.GetChromeVisible()) + score.GetAura()) / 100.0;
  let fear = looks;
  if t.recognized {
    if gang {
      fear = MaxF(score.GetFactionFear(faction) / 100.0, looks);
    } else {
      fear = MaxF(CBCrowdFear(score, CBCrowdMomentMult(sys, game)) / 100.0, looks);
    }
  }
  if gang && CBGangBroken(sys, faction) {
    fear += CBConfig.BrokenGangFear();
  }
  t.fear = fear;
  // How they stand with V.
  if t.cop {
    t.mood = CBTalkWary();
  } else {
    if gang {
      let posture = score.GetPosture(faction);
      if Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly) {
        t.mood = CBTalkFriendly();
      } else {
        if npc.cbHoldState == 1 || fear - t.nerve * CBConfig.HoldBackNerveWeight() >= CBConfig.TalkAfraidMargin() {
          t.mood = CBTalkAfraid();
        } else {
          if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
            t.mood = CBTalkHostile();
          } else {
            t.mood = CBTalkWary();
          }
        }
      }
    } else {
      if fear >= CBConfig.TalkCivAfraid() {
        t.mood = CBTalkAfraid();
      } else {
        if t.recognized && (score.GetRenown() >= CBConfig.TalkCivFanRenown() || sys.GetCode() >= 40.0) {
          t.mood = CBTalkFriendly();
        } else {
          t.mood = CBTalkWary();
        }
      }
    }
  }
  // Hostile to V by the game's say, and not afraid: hostile, whatever Cyberbane's standing says.
  let agentR = npc.GetAttitudeAgent();
  let playerR = GetPlayer(game);
  let pagentR = IsDefined(playerR) ? playerR.GetAttitudeAgent() : null;
  if gang && t.mood != CBTalkAfraid() && IsDefined(agentR) && IsDefined(pagentR)
     && Equals(agentR.GetAttitudeTowards(pagentR), EAIAttitude.AIA_Hostile) {
    t.mood = CBTalkHostile();
  }
  if gang || t.cop {
    t.speaker = CBFactionMemberWord(t.cop ? n"NCPD" : faction);
  }
  if StrLen(t.speaker) == 0 {
    t.speaker = gang ? CBT(n"Cyberbane-Whispers-Ganger") : CBT(n"Cyberbane-Whispers-PasserBy");
  }
  // A crew's sergeant stopped to talk (Reactions/Allies.reds, [U2]).
  if npc.cbFacedownOpen && npc.cbSergeant {
    t.parley = true;
    t.mood = CBTalkHostile();
    t.speaker = CBT(n"Cyberbane-Allies-CrewSergeant");
    return t;
  }
  // A Rival at a facedown: who they are, and not afraid of anything yet (Rivals/RivalMoments.reds).
  if npc.cbFacedownOpen {
    let facing = CBFindRivalByBody(sys, npc.GetEntityID());
    if IsDefined(facing) {
      t.rivalId = facing.id;
      t.facedown = true;
      t.mood = CBTalkHostile();
      t.speaker = CBRivalDisplayName(sys.GetContent(), facing);
      return t;
    }
  }
  // A Rival V has put down: who they are, and afraid (Rivals/RivalLife.reds).
  if npc.cbMercyOpen {
    let fallen = CBFindRivalByBody(sys, npc.GetEntityID());
    if IsDefined(fallen) {
      t.rivalId = fallen.id;
      t.mood = CBTalkAfraid();
      t.speaker = CBRivalDisplayName(sys.GetContent(), fallen);
      return t;
    }
  }
  // One of their own V could make them give up.
  if gang && t.mood != CBTalkFriendly() {
    let lead = CBTalkLeadFor(sys, game, faction);
    if IsDefined(lead) {
      t.leadId = lead.id;
      t.leadName = CBRivalDisplayName(sys.GetContent(), lead);
    }
  }
  return t;
}

// A Rival of this gang whose hiding place is there to be told (Rivals/Whereabouts.reds), if any.
public func CBTalkLeadFor(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> ref<CBRival> {
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, faction) && CBWhereaboutsForSale(sys, game, r) == 0 {
      return r;
    }
  }
  return null;
}

// ---- The prompt ----------------------------------------------------------------------------------------

// What of the game's is on screen, because the two kinds are not the same to talk. A dialogue or a loot list is
// somebody else's moment, and talk waits for it.
public func CBPromptNone() -> Int32 = 0
public func CBPromptInteraction() -> Int32 = 1
public func CBPromptDialogue() -> Int32 = 2

public func CBNativePromptKind(game: GameInstance) -> Int32 {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return CBPromptDialogue();
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return CBPromptDialogue();
  }
  // Only what the game draws: an entry with nothing to choose shows nothing (interactionsUI.script lists its choices),
  // and one left behind on the blackboard by a mod held talk off for good.
  let dialogs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in dialogs.choiceHubs {
    if hub.id != CBConfig.TalkHubId() && ArraySize(hub.choices) > 0 {
      return CBPromptDialogue();
    }
  }
  let loot = FromVariant<LootData>(bb.GetVariant(defs.LootData));
  if loot.isActive {
    return CBPromptDialogue();
  }
  let prompt = FromVariant<InteractionChoiceHubData>(bb.GetVariant(defs.InteractionChoiceHub));
  if prompt.active && prompt.id != CBConfig.TalkHubId() && ArraySize(prompt.choices) > 0 {
    return CBPromptInteraction();
  }
  return CBPromptNone();
}

// What the game's interaction prompt on screen says, for the log alone: its title and its first choice, as the
// blackboard holds them. "" when there is none, or it is street talk's.
public func CBNativePromptWords(game: GameInstance) -> String {
  let bbs = GameInstance.GetBlackboardSystem(game);
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = IsDefined(bbs) ? bbs.Get(defs) : null;
  if !IsDefined(bb) {
    return "";
  }
  let prompt = FromVariant<InteractionChoiceHubData>(bb.GetVariant(defs.InteractionChoiceHub));
  if !prompt.active || prompt.id == CBConfig.TalkHubId() {
    return "";
  }
  let first = ArraySize(prompt.choices) > 0 ? prompt.choices[0].localizedName : "";
  return CBTf(n"Cyberbane-StreetTalk-ChoiceS", [s"\(prompt.title)", s"\(first)", s"\(ArraySize(prompt.choices))"]);
}

// Somebody talked to where they lie or kneel: a Rival V put down, or somebody with their hands up. The game offers to
// carry their body, which is an interaction prompt that never goes away while V stands over them.
public func CBTalkDownAtFeet(npc: wref<ScriptedPuppet>) -> Bool {
  return IsDefined(npc) && (npc.cbMercyOpen || npc.cbSurrendered);
}

// What the game's interface holds right now, in a line for the log: every list and how many lines each, which list is
// active, the game's prompt and its first caption, and a loot list.
public func CBTalkScreenNote(game: GameInstance) -> String {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return "no blackboard";
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return "no blackboard";
  }
  let lists = "";
  let dialogs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in dialogs.choiceHubs {
    lists += (StrLen(lists) > 0 ? ", " : "") + s"\(hub.id)\(hub.id == CBConfig.TalkHubId() ? " (ours)" : "") with \(ArraySize(hub.choices))";
  }
  let prompt = FromVariant<InteractionChoiceHubData>(bb.GetVariant(defs.InteractionChoiceHub));
  let first = ArraySize(prompt.choices) > 0 ? prompt.choices[0].localizedName : "";
  let loot = FromVariant<LootData>(bb.GetVariant(defs.LootData));
  return s"lists [\(lists)], active list \(bb.GetInt(defs.ActiveChoiceHubID)); game prompt \(prompt.active ? "up" : "down") id \(prompt.id) with \(ArraySize(prompt.choices)) \"\(first)\"; loot \(loot.isActive)";
}

// Is one of the game's dialogues on screen (a hub that is not street talk's)? Texts wait for it.
public func CBGameDialogueUp(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return false;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return false;
  }
  let dialogs = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  for hub in dialogs.choiceHubs {
    if hub.id != CBConfig.TalkHubId() && ArraySize(hub.choices) > 0 {
      return true;
    }
  }
  return false;
}

public func CBTalkPushHub(game: GameInstance, title: String, lines: array<ref<CBTalkLine>>, index: Int32) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return;
  }
  // Each line the way the game shows its own: an icon from the game's choice icons, and the choice type that
  // highlights, dims or greys it (ChoiceTypeWrapper, as doors and terminals set it).
  let choices: array<ListChoiceData>;
  for line in lines {
    if IsDefined(line) {
      let c: ListChoiceData;
      c.localizedName = line.text;
      if TDBID.IsValid(line.icon) {
        // The record itself, as the game's devices hand it over (baseDeviceActions.script); a missing one
        // is simply no icon.
        let icon = TweakDBInterface.GetChoiceCaptionIconPartRecord(line.icon);
        if IsDefined(icon) {
          InteractionChoiceCaption.AddPartFromRecord(c.captionParts, icon);
        }
      }
      if line.important {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.QuestImportant);
      }
      if line.said {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.AlreadyRead);
      }
      if line.inactive {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.Inactive);
      }
      if line.illegal {
        ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.Illegal);
      }
      ArrayPush(choices, c);
    }
  }
  let hub: ListChoiceHubData;
  hub.id = CBConfig.TalkHubId();
  hub.activityState = EVisualizerActivityState.Active;
  hub.title = title;
  hub.choices = choices;
  let list: array<ListChoiceHubData>;
  ArrayPush(list, hub);
  let hubs: DialogChoiceHubs;
  hubs.choiceHubs = list;
  CBTalkHoldList(game, hubs, index);
  bb.SetVariant(defs.DialogChoiceHubs, ToVariant(hubs), true);
  bb.SetInt(defs.ActiveChoiceHubID, hub.id, true);
  bb.SetInt(defs.SelectedIndex, index, true);
}

public func CBTalkSelect(game: GameInstance, index: Int32) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if IsDefined(bb) {
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.talkListHeld {
      rt.talkListIndex = index;
    }
    bb.SetInt(defs.SelectedIndex, index, true);
  }
}

// "Talk", as the game shows "Open" on a door: its interaction prompt, with the talk icon.
public func CBTalkPushOffer(game: GameInstance, title: String) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = IsDefined(bbs) ? bbs.Get(defs) : null;
  if !IsDefined(bb) {
    return;
  }
  let c: InteractionChoiceData;
  c.inputAction = n"Choice1";
  c.localizedName = CBT(n"Cyberbane-StreetTalk-Talk");
  let icon = TweakDBInterface.GetChoiceCaptionIconPartRecord(t"ChoiceCaptionParts.TalkIcon");
  if IsDefined(icon) {
    InteractionChoiceCaption.AddPartFromRecord(c.captionParts, icon);
  }
  let hub: InteractionChoiceHubData;
  hub.id = CBConfig.TalkHubId();
  hub.active = true;
  hub.title = title;
  ArrayPush(hub.choices, c);
  bb.SetVariant(defs.InteractionChoiceHub, ToVariant(hub), true);
  let vis: VisualizersInfo;
  vis.activeVisId = hub.id;
  ArrayPush(vis.visIds, hub.id);
  bb.SetVariant(defs.VisualizersInfo, ToVariant(vis), true);
}

// What the greyed prompt says for a reason somebody will not talk (ShowNote), "" for a reason it keeps quiet about:
// only the ones V can do something about, or wait out. Story people, vendors and the game's business never get one.
public func CBTalkNoteWords(why: String) -> String {
  if Equals(why, "a weapon is in V's hands") { return CBT(n"Cyberbane-StreetTalk-HolsterToTalk"); }
  if Equals(why, "V spoke to them a moment ago") { return CBT(n"Cyberbane-StreetTalk-JustSpokeToThem"); }
  if Equals(why, "they are in a fight") { return CBT(n"Cyberbane-StreetTalk-BusyFighting"); }
  if Equals(why, CBTalkWhyVInCombat()) { return CBT(n"Cyberbane-StreetTalk-NotWhileYouReInA"); }
  if Equals(why, "they are running from V") { return CBT(n"Cyberbane-StreetTalk-RunningFromYou"); }
  if Equals(why, CBTalkWhyJob()) || Equals(why, CBTalkWhyTracked()) { return CBT(n"Cyberbane-StreetTalk-PartOfAJob"); }
  if Equals(why, CBTalkWhyTurf()) { return CBT(n"Cyberbane-StreetTalk-HostileGroundStepOutFirst"); }
  if Equals(why, CBTalkWhyGrudge()) { return CBT(n"Cyberbane-StreetTalk-HostileToYou"); }
  return "";
}

// The greyed prompt itself: "Talk"'s place, one inactive choice, the way the game greys a device's prompt V cannot use
// (baseDeviceActions.script). Taken down by CBTalkClearOffer like the offer, since it is the same hub.
public func CBTalkPushNote(game: GameInstance, words: String) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = IsDefined(bbs) ? bbs.Get(defs) : null;
  if !IsDefined(bb) {
    return;
  }
  let c: InteractionChoiceData;
  c.inputAction = n"Choice1";
  c.localizedName = words;
  ChoiceTypeWrapper.SetType(c.type, gameinteractionsChoiceType.Inactive);   // greyed by interactionsUIChoiceItem.script
  let icon = TweakDBInterface.GetChoiceCaptionIconPartRecord(t"ChoiceCaptionParts.TalkIcon");
  if IsDefined(icon) {
    InteractionChoiceCaption.AddPartFromRecord(c.captionParts, icon);
  }
  let hub: InteractionChoiceHubData;
  hub.id = CBConfig.TalkHubId();
  hub.active = true;
  ArrayPush(hub.choices, c);
  bb.SetVariant(defs.InteractionChoiceHub, ToVariant(hub), true);
  let vis: VisualizersInfo;
  vis.activeVisId = hub.id;
  ArrayPush(vis.visIds, hub.id);
  bb.SetVariant(defs.VisualizersInfo, ToVariant(vis), true);
}

// Sim seconds, for talk's own short clocks.
public func CBTalkNow(game: GameInstance) -> Float {
  let ts = GameInstance.GetTimeSystem(game);
  return IsDefined(ts) ? EngineTime.ToFloat(ts.GetSimTime()) : 0.0;
}

public func CBTalkOfferShown(game: GameInstance) -> Bool {
  let bbs = GameInstance.GetBlackboardSystem(game);
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = IsDefined(bbs) ? bbs.Get(defs) : null;
  if !IsDefined(bb) {
    return false;
  }
  let hub = FromVariant<InteractionChoiceHubData>(bb.GetVariant(defs.InteractionChoiceHub));
  if !hub.active || hub.id != CBConfig.TalkHubId() {
    return false;
  }
  // The prompt widget shows the hub VisualizersInfo names; something else named there hides ours.
  let vis = FromVariant<VisualizersInfo>(bb.GetVariant(defs.VisualizersInfo));
  return vis.activeVisId == CBConfig.TalkHubId() || vis.activeVisId == -1;
}

// Down, only if it is still Cyberbane's.
public func CBTalkClearOffer(game: GameInstance) -> Void {
  let bbs = GameInstance.GetBlackboardSystem(game);
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = IsDefined(bbs) ? bbs.Get(defs) : null;
  if !IsDefined(bb) {
    return;
  }
  let hub = FromVariant<InteractionChoiceHubData>(bb.GetVariant(defs.InteractionChoiceHub));
  if hub.id == CBConfig.TalkHubId() {
    let none: InteractionChoiceHubData;
    bb.SetVariant(defs.InteractionChoiceHub, ToVariant(none), true);
  }
  let vis = FromVariant<VisualizersInfo>(bb.GetVariant(defs.VisualizersInfo));
  if vis.activeVisId == CBConfig.TalkHubId() {
    let novis: VisualizersInfo;
    novis.activeVisId = -1;
    bb.SetVariant(defs.VisualizersInfo, ToVariant(novis), true);
  }
}

// Down again, only if what is up is still Cyberbane's: anything of the game's that replaced it stays.
public func CBTalkClearHub(game: GameInstance) -> Void {
  let wasHeld = CBTalkDropList();
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let defs = GetAllBlackboardDefs().UIInteractions;
  let bb = bbs.Get(defs);
  if !IsDefined(bb) {
    return;
  }
  let current = FromVariant<DialogChoiceHubs>(bb.GetVariant(defs.DialogChoiceHubs));
  let ours = ArraySize(current.choiceHubs) == 1 && current.choiceHubs[0].id == CBConfig.TalkHubId();
  if ours || (wasHeld && ArraySize(current.choiceHubs) == 0) {
    let empty: DialogChoiceHubs;
    bb.SetVariant(defs.DialogChoiceHubs, ToVariant(empty), true);
  }
  let active = bb.GetInt(defs.ActiveChoiceHubID);
  if active == CBConfig.TalkHubId() || (wasHeld && active == -1) {
    bb.SetInt(defs.ActiveChoiceHubID, -1, true);
  }
}

// ---- The list through the game's clears ------------------------------------------------------
//
// While V stands at somebody, the game writes out its whole dialog state several times a second, an empty list among
// it, with nothing of its own to show (the log: "Wiped (30): lists [], active list -1; game prompt down id -1").

// Held from the moment it is written (CBTalkPushHub).
public func CBTalkHoldList(game: GameInstance, hubs: DialogChoiceHubs, index: Int32) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) {
    return;
  }
  rt.talkList = hubs;
  rt.talkListIndex = index;
  rt.talkListHeld = true;
  rt.talkListUntil = CBTalkNow(game) + CBConfig.TalkListHoldSeconds();
}

// Still up: held a while longer (talk's tick, Keep).
public func CBTalkKeepList(game: GameInstance) -> Void {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.talkListHeld {
    rt.talkListUntil = CBTalkNow(game) + CBConfig.TalkListHoldSeconds();
  }
}

// Let go. True when it was held.
public func CBTalkDropList() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.talkListHeld {
    return false;
  }
  let none: DialogChoiceHubs;
  rt.talkList = none;
  rt.talkListHeld = false;
  rt.talkListUntil = 0.0;
  return true;
}

// Is talk's list held right now? Not past its time, and not stamped from another session's clock: the sim clock starts again
// with a session, and this service outlives it, so a stamp far ahead of now is an old one.
public func CBTalkListHeldNow() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.talkListHeld {
    return false;
  }
  let left = rt.talkListUntil - CBTalkNow(GetGameInstance());
  if left < 0.0 || left > CBConfig.TalkListHoldSeconds() + 0.5 {
    CBTalkDropList();
    return false;
  }
  return true;
}

public func CBTalkHeldList(out hubs: DialogChoiceHubs) -> Bool {
  if !CBTalkListHeldNow() {
    return false;
  }
  hubs = CyberbaneRuntime.Get().talkList;
  return ArraySize(hubs.choiceHubs) > 0;
}

public func CBTalkHeldIndex() -> Int32 {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) ? rt.talkListIndex : 0;
}

// The game's dialog widgets, and the interaction prompt beside them, read the list here (interactionUIBase.script).
@wrapMethod(InteractionUIBase)
protected cb func OnDialogsData(value: Variant) -> Bool {
  let data = FromVariant<DialogChoiceHubs>(value);
  if ArraySize(data.choiceHubs) == 0 {
    let held: DialogChoiceHubs;
    if CBTalkHeldList(held) {
      wrappedMethod(ToVariant(held));
      return true;
    }
  }
  wrappedMethod(value);
  return true;
}

// Which list is the live one: the game clears it to none with the rest.
@wrapMethod(dialogWidgetGameController)
protected cb func OnDialogsActivateHub(activeHubId: Int32) -> Bool {
  if activeHubId == -1 && CBTalkListHeldNow() {
    wrappedMethod(CBConfig.TalkHubId());
    return true;
  }
  wrappedMethod(activeHubId);
  return true;
}

// The line picked, while talk's list is the live one.
@wrapMethod(dialogWidgetGameController)
protected cb func OnDialogsSelectIndex(index: Int32) -> Bool {
  if this.m_activeHubID == CBConfig.TalkHubId() && CBTalkListHeldNow() {
    wrappedMethod(CBTalkHeldIndex());
    return true;
  }
  wrappedMethod(index);
  return true;
}

// Who they are, and how they take V, over the choices.
public func CBTalkTitle(t: ref<CBTalkTarget>) -> String {
  let how = "";
  if t.mood == CBTalkFriendly() {
    how = CBT(n"Cyberbane-StreetTalk-Friendly");
  } else {
    if t.mood == CBTalkAfraid() {
      how = CBT(n"Cyberbane-StreetTalk-AfraidOfYou");
    } else {
      if t.mood == CBTalkHostile() {
        how = CBT(n"Cyberbane-StreetTalk-Hostile");
      } else {
        how = t.recognized ? CBT(n"Cyberbane-StreetTalk-KnowsYou") : CBT(n"Cyberbane-StreetTalk-Wary");
      }
    }
  }
  return t.speaker + " - " + how;
}

// What V can say, as "[Tag] words": the game shows the tag the way it shows its own. Each line carries what it does and
// how it is shown: an icon, dimmed once said to this person, the Rival question highlighted.
public func CBTalkChoices(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, followUp: Bool) -> array<ref<CBTalkLine>> {
  if t.parley {
    return CBParleyLines(sys, game, t);
  }
  if t.rivalId > 0 {
    return t.facedown ? CBRivalFacedownLines(sys, game, t) : CBRivalMercyLines(sys, game, t);
  }
  // One of V's own (Reactions/CrewHome.reds).
  let crewLines = CBCrewTalkLines(sys, game, t);
  if ArraySize(crewLines) > 0 {
    return crewLines;
  }
  let out: array<ref<CBTalkLine>>;
  let gang = NotEquals(t.faction, n"") && !t.cop;
  let m = t.mood;
  let done = IsDefined(t.npc) ? t.npc.cbTalkDone : 0;
  // Greet.
  let greet = "";
  if m == CBTalkFriendly() {
    greet = gang ? CBT(n"Cyberbane-StreetTalk-GreetGoodToSeeYouHow") : CBT(n"Cyberbane-StreetTalk-GreetHeyThere");
  } else {
    if m == CBTalkAfraid() {
      greet = CBT(n"Cyberbane-StreetTalk-GreetEasyIMJustSaying");
    } else {
      if m == CBTalkHostile() {
        if gang && CBTalkStat(game, gamedataStatType.Cool) >= CBConfig.TalkAttributeCheck() {
          greet = CBT(n"Cyberbane-StreetTalk-CoolEasyNobodyNeedsToBleed");
        } else {
          greet = gang ? CBT(n"Cyberbane-StreetTalk-ParleyEasyIMNotHere") : CBT(n"Cyberbane-StreetTalk-GreetRelaxNotHereForTrouble");
        }
      } else {
        greet = t.cop ? CBT(n"Cyberbane-StreetTalk-GreetEveningOfficer") : CBT(n"Cyberbane-StreetTalk-GreetHeyChoom");
      }
    }
  }
  let parley = gang && m == CBTalkHostile();
  let g = CBTalkMakeLine(greet, CBTalkGreet(),
                         m == CBTalkFriendly() || parley ? t"ChoiceCaptionParts.HandshakeIcon" : t"ChoiceCaptionParts.TalkIcon");
  g.important = parley && !CBMaskHas(done, CBTalkGreet());
  g.said = CBMaskHas(done, CBTalkGreet());
  ArrayPush(out, g);
  // Questions: the list of what they might know.
  let ask = CBTalkMakeLine(t.cop ? CBT(n"Cyberbane-StreetTalk-AskQuickQuestionOfficer") : CBT(n"Cyberbane-StreetTalk-AskGotAMinute"), CBTalkActMenuAsk(),
                           t"ChoiceCaptionParts.ClueIcon");
  ArrayPush(out, ask);
  // A Rival's hiding place for a price, right there on the first list when they have it: it was a question under [Ask],
  // and played, nobody found it.
  let tipRival = t.cop ? null : CBTalkRivalFor(sys, game, t);
  if IsDefined(tipRival) {
    let tl = CBTalkMakeLine(CBTf(n"Cyberbane-StreetTalk-AmbushTipWhereSLyingLow", [CBRivalDisplayName(sys.GetContent(), tipRival)]),
                            CBTalkActAskRival(), t"ChoiceCaptionParts.BountyHuntIcon");
    tl.said = CBMaskHas(done, CBTalkActAskRival());
    tl.important = !tl.said;
    ArrayPush(out, tl);
  }
  // Turning them: somebody of a gang frightened enough of V may agree to pass V word.
  if gang && (CBInformantsOn() || CBCrewTakesFrightened(game)) && IsDefined(t.npc) && (t.npc.cbHoldState == 1 || m == CBTalkAfraid())
     && !CBMaskHas(done, CBTalkActTurn()) {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-StreetTalk-IntimidateYouWorkForMeNow"), CBTalkActTurn(), t"ChoiceCaptionParts.GrappleIcon"));
  }
  // A favour (Spawn/LivingStreet.reds): a gang that does not hate V may have a small job.
  let lifeC = CBStreetLifeFor(game);
  if gang && (m == CBTalkFriendly() || m == CBTalkWary()) && CBStreetLifeOn(n"favours") && IsDefined(lifeC)
     && lifeC.HasWorkFor(game, t.npc, t.faction) && !CBMaskHas(done, CBTalkActFavour()) {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-StreetTalk-AskNeedAnythingDone"), CBTalkActFavour(), t"ChoiceCaptionParts.GangWatchIcon"));
  }
  // A scout's price (Spawn/Hunted.reds, [68]).
  for sl in CBScoutTalkLines(sys, game, t) {
    ArrayPush(out, sl);
  }
  // The war (Economy/War.reds): backing a gang, a lie, protection money, terms.
  for wl in CBWarTalkLines(sys, game, t) {
    ArrayPush(out, wl);
  }
  // Allies, ransom and the lie (Reactions/Allies.reds). Somebody who saw a Rival V is after.
  let witnessLines: array<ref<CBTalkLine>>;
  if CBLeadWitnessTalkLines(game, t, witnessLines) {
    for wl in witnessLines {
      ArrayPush(out, wl);
    }
  }
  for al in CBAllyTalkLines(sys, game, t) {
    ArrayPush(out, al);
  }
  // A funeral's mourners (Spawn/StreetEvents.reds).
  for el in CBEventTalkLines(game, t) {
    ArrayPush(out, el);
  }
  // Paying the street (Reactions/StreetPay.reds): hush a witness, or have somebody keep watch.
  for pl in CBStreetPayLines(sys, game, t) {
    ArrayPush(out, pl);
  }
  // Business: what a gang at war with V will sell. Only when there is something to sell.
  if gang && CBTalkHasBusiness(sys, game, t) {
    ArrayPush(out, CBTalkMakeLine(CBT(n"Cyberbane-StreetTalk-DealLetSTalkBusiness"), CBTalkActBusiness(), t"ChoiceCaptionParts.PayIcon"));
  }
  // Goods from a robbed bag, to sell (Reactions/CrewJobs.reds).
  let goodsLine = gang ? CBGoodsTalkLine(sys, game, t) : null;
  if IsDefined(goodsLine) {
    ArrayPush(out, goodsLine);
  }
  // The line only this V has with them.
  let life = CBTalkLifepathLine(game, t);
  if IsDefined(life) {
    ArrayPush(out, life);
  }
  // Dismiss.
  let dismiss = "";
  if m == CBTalkFriendly() {
    dismiss = CBT(n"Cyberbane-StreetTalk-DismissCatchYouLater");
  } else {
    if m == CBTalkAfraid() {
      dismiss = CBT(n"Cyberbane-StreetTalk-DismissGetLost");
    } else {
      dismiss = m == CBTalkHostile() ? CBT(n"Cyberbane-StreetTalk-DismissOutOfMyWay") : CBT(n"Cyberbane-StreetTalk-DismissNotNow");
    }
  }
  // In a follow-up, Leave (below) ends it without the brush-off.
  if !followUp {
    let d = CBTalkMakeLine(dismiss, CBTalkDismiss(), t"ChoiceCaptionParts.BackOutIcon");
    d.said = CBMaskHas(done, CBTalkDismiss());
    ArrayPush(out, d);
  }
  // Antagonize.
  let antagonize = "";
  if t.cop {
    antagonize = CBT(n"Cyberbane-StreetTalk-AntagonizeShouldnTYouBeEating");
  } else {
    if !gang {
      antagonize = CBT(n"Cyberbane-StreetTalk-AntagonizeWhatAreYouLookingAt");
    } else {
      if m == CBTalkFriendly() {
        antagonize = CBT(n"Cyberbane-StreetTalk-AntagonizeYourBossKnowYouRe");
      } else {
        if m == CBTalkAfraid() {
          antagonize = CBT(n"Cyberbane-StreetTalk-AntagonizeBoo");
        } else {
          antagonize = m == CBTalkHostile() ? CBT(n"Cyberbane-StreetTalk-AntagonizeYourCrewSAJoke") : CBT(n"Cyberbane-StreetTalk-AntagonizeGotAProblem");
        }
      }
    }
  }
  let an = CBTalkMakeLine(antagonize, CBTalkAntagonize(), t"ChoiceCaptionParts.HitIcon");
  an.said = CBMaskHas(done, CBTalkAntagonize());
  ArrayPush(out, an);
  // Intimidate: what V leans with is how V works, and a name when there is one to get.
  let intimidate = "";
  let asks = false;
  if t.cop {
    intimidate = CBT(n"Cyberbane-StreetTalk-IntimidateBackOffBadge");
  } else {
    if t.leadId > 0 {
      intimidate = CBTf(n"Cyberbane-StreetTalk-IntimidateWhereSHidingTalk", [t.leadName]);
      asks = true;
    } else {
      // V's Body shows in the threat, the way the game shows an attribute line.
      let body = CBTalkStat(game, gamedataStatType.Strength) >= CBConfig.TalkAttributeCheck();
      intimidate = (body ? CBT(n"Cyberbane-StreetPay-Body") : CBT(n"Cyberbane-StreetPay-Intimidate")) + CBTalkThreat(sys.GetPrimaryArchetypeIndex());
    }
  }
  let it = CBTalkMakeLine(intimidate, CBTalkIntimidate(),
                          asks ? t"ChoiceCaptionParts.BountyHuntIcon" : t"ChoiceCaptionParts.GrappleIcon");
  it.important = asks;
  it.said = CBMaskHas(done, CBTalkIntimidate());
  ArrayPush(out, it);
  // Leave it there, once something has been said.
  if followUp {
    let leave = m == CBTalkHostile() ? CBT(n"Cyberbane-StreetTalk-LeaveNotWorthIt") : (m == CBTalkFriendly() ? CBT(n"Cyberbane-StreetTalk-LeaveTakeItEasy") : CBT(n"Cyberbane-StreetTalk-LeaveForgetIt"));
    ArrayPush(out, CBTalkMakeLine(leave, CBTalkActLeave(), TDBID.None()));
  }
  return out;
}

func CBTalkThreat(archetype: Int32) -> String {
  if archetype == EnumInt(ECBArchetype.Butcher) { return CBT(n"Cyberbane-StreetTalk-WantToEndUpLikeThe"); }
  if archetype == EnumInt(ECBArchetype.Ghost) { return CBT(n"Cyberbane-StreetTalk-YouNeverSawMeKeepIt"); }
  if archetype == EnumInt(ECBArchetype.Professional) { return CBT(n"Cyberbane-StreetTalk-ThisDoesnTHaveToGet"); }
  if archetype == EnumInt(ECBArchetype.Chromed) { return CBT(n"Cyberbane-StreetTalk-SeeTheseWalkAway"); }
  if archetype == EnumInt(ECBArchetype.Netrunner) { return CBT(n"Cyberbane-StreetTalk-ICouldCookYourImplantsFrom"); }
  if archetype == EnumInt(ECBArchetype.Brawler) { return CBT(n"Cyberbane-StreetTalk-IDonTNeedAGun"); }
  return CBT(n"Cyberbane-StreetTalk-WalkAwayNow");
}

// The words of a "[Tag] words" line.
public func CBTalkWords(line: String) -> String {
  if StrBeginsWith(line, "[") {
    let tag: String;
    let rest: String;
    if StrSplitFirst(line, "] ", tag, rest) {
      return rest;
    }
  }
  return line;
}

func CBTalkSay(line: String, vo: CName) -> ref<CBTalkAnswer> {
  let a = new CBTalkAnswer();
  a.line = line;
  a.vo = vo;
  return a;
}

// An answer the game's line says as well as Cyberbane's words would: their line of that name, in their voice and words,
// with `line` kept for when they have none (Reactions/TalkVoice.reds).
func CBTalkSayTheirs(line: String, vo: CName) -> ref<CBTalkAnswer> {
  let a = CBTalkSay(line, vo);
  a.voMode = CBTalkVoiceTheirs();
  return a;
}

// ---- What talking does to a reputation, a little at a time ----------------------------------------------
//
// Every change goes through these, which hold it to its ceiling for the day and gang (CBTalkTally in the
// play service) and do nothing at all while reputation is frozen.

func CBTalkTallyFor(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> ref<CBTalkTally> {
  let svc = sys.GetPlayService();
  if !IsDefined(svc) {
    return null;
  }
  let day = FloorF(CBGameSeconds(game) / CBConfig.SecondsPerDay());
  return svc.TalkTally(sys.GetPlaythroughId(), faction, day);
}

// Standing gained, up to `ceiling`.
func CBTalkWarm(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float, ceiling: Float) -> Float {
  if CBReputationFrozen() || Equals(faction, n"") || amount <= 0.0 {
    return 0.0;
  }
  let tally = CBTalkTallyFor(sys, game, faction);
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(tally) || !IsDefined(fs) || fs.standing >= ceiling {
    return 0.0;
  }
  let gain = MinF(MinF(amount, CBConfig.TalkWarmthPerDay() - tally.warmth), ceiling - fs.standing);
  if gain <= 0.0 {
    return 0.0;
  }
  fs.standing = ClampF(fs.standing + gain, -100.0, 100.0);
  // The first warmth of the day with this gang goes in the History, so V can see it worked.
  if tally.warmth <= 0.0 {
    CBFileLog(sys, n"TalkWarm", CBGameSeconds(game), CBEventDistrict(sys, game), faction, gain);
  }
  tally.warmth += gain;
  return gain;
}

// Standing lost.
func CBTalkSlight(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Float {
  if CBReputationFrozen() || Equals(faction, n"") || amount <= 0.0 {
    return 0.0;
  }
  let tally = CBTalkTallyFor(sys, game, faction);
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(tally) || !IsDefined(fs) {
    return 0.0;
  }
  let loss = MinF(amount, CBConfig.TalkSlightPerDay() - tally.slight);
  if loss <= 0.0 {
    return 0.0;
  }
  fs.standing = ClampF(fs.standing - loss, -100.0, 100.0);
  // The first offence of the day; a friend's first brush-off only marks the tally (0.01) and is not one.
  if tally.slight < 0.05 {
    CBFileLog(sys, n"TalkSlight", CBGameSeconds(game), CBEventDistrict(sys, game), faction, loss);
  }
  tally.slight += loss;
  return loss;
}

// How much their gang fears V: the gang's renown of V, which faction fear is built on (CBFactionFear). A
// gain is held to its daily ceiling; losing face is not.
func CBTalkFear(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, amount: Float) -> Void {
  if CBReputationFrozen() || Equals(faction, n"") || amount == 0.0 {
    return;
  }
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  if amount > 0.0 {
    let tally = CBTalkTallyFor(sys, game, faction);
    if !IsDefined(tally) {
      return;
    }
    let gain = MinF(amount, CBConfig.TalkFearPerDay() - tally.fear);
    if gain <= 0.0 {
      return;
    }
    if tally.fear <= 0.0 {
      CBFileLog(sys, n"TalkFear", CBGameSeconds(game), CBEventDistrict(sys, game), faction, gain);
    }
    tally.fear += gain;
    fs.renown = ClampF(fs.renown + gain, 0.0, 100.0);
    fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
    return;
  }
  fs.renown = ClampF(fs.renown + amount, 0.0, 100.0);
}

// Conduct, either way, held to a daily total per gang (n"" for people with no gang).
func CBTalkConduct(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, delta: Float) -> Void {
  if CBReputationFrozen() || delta == 0.0 {
    return;
  }
  let tally = CBTalkTallyFor(sys, game, faction);
  if !IsDefined(tally) {
    return;
  }
  let room = CBConfig.TalkConductPerDay() - tally.conduct;
  if room <= 0.0 {
    return;
  }
  let step = delta > 0.0 ? MinF(delta, room) : MaxF(delta, -room);
  tally.conduct += AbsF(step);
  sys.AddCode(step);
}

// A ganger's odds against V's fear: above zero they fold, below it they stand.
func CBTalkNerveGap(t: ref<CBTalkTarget>) -> Float {
  return t.fear - t.nerve * CBConfig.HoldBackNerveWeight() - Cast<Float>(t.backers) * CBConfig.HoldBackPerBacker();
}

// Sent on their way: one move order, never more (Reactions/Morale.reds, CBOrderFlee). Somebody at a workspot is never
// given one (S-03): the fear stim lets the game take them out of it its own way.
func CBTalkSendOff(game: GameInstance, t: ref<CBTalkTarget>) -> Bool {
  let npc = IsDefined(t) ? t.npc : null;
  if !IsDefined(npc) || npc.cbTalkSent {
    return false;
  }
  CBTalkMarkSent(game, npc);
  // Whoever V has sent packing holds back from V from now on: a vendetta ganger talked down in their warning was
  // otherwise turned on V by the Director a second later, mid-retreat.
  CBStandDownFromV(game, npc);
  npc.cbTalkPartner = false;
  CBTalkReleaseHold(npc);
  if t.safe {
    return false;
  }
  if t.atWork {
    CBTalkScare(GetPlayer(game), t, 1);
    return true;
  }
  return CBOrderFlee(game, npc);
}

// A civilian frightened by V, the way the crowd reactions frighten them (Reactions/Crowd.reds): the one
// stim the game lets a sender choose the stage of, from V, and it stops with them.
func CBTalkScare(player: ref<PlayerPuppet>, t: ref<CBTalkTarget>, stage: Int32) -> Void {
  let npc = IsDefined(t) ? t.npc : null;
  if !IsDefined(player) || !IsDefined(npc) || !npc.IsAttached() || t.safe {
    return;   // nobody is sent screaming out of a bar
  }
  // Out of the conversation first.
  npc.cbTalkPartner = false;
  CBTalkReleaseHold(npc);
  if stage >= 2 {
    CBTalkMarkSent(player.GetGame(), npc);
  }
  let data: stimInvestigateData;
  data.fearPhase = stage;
  StimBroadcasterComponent.SendStimDirectly(player, gamedataStimType.SpreadFear, npc, data);
}

// Picking a fight: the Director turns them, so it is tracked and reverted like every attitude Cyberbane
// sets, and the gangs at war with theirs hear about it.
func CBTalkFight(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> Bool {
  if t.safe {
    return false;   // not in here: the answer is words ("Not here. Not now. But soon.")
  }
  let director = sys.GetDirector();
  if !IsDefined(director) || !director.TurnHostileFromTalk(player, t.npc, t.faction) {
    return false;
  }
  // No longer talking, nor held to talk: the fight is theirs to have now.
  if IsDefined(t.npc) {
    t.npc.cbTalkPartner = false;
    CBTalkReleaseHold(t.npc);
  }
  let lost = CBTalkSlight(sys, game, t.faction, CBConfig.TalkFightCost());
  if lost > 0.0 {
    CBCreditRivalGangs(sys, game, t.faction, -lost);
  }
  return true;
}

// ---- Greet ---------------------------------------------------------------------------------------------

func CBTalkOnGreet(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  // Credit for saying hello once to each person; saying it again is just being friendly.
  let first = t.first;
  if t.cop {
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-MoveAlongCitizen"), CBT(n"Cyberbane-StreetTalk-KeepItCleanTonight"), CBT(n"Cyberbane-StreetTalk-MhmDonTMakeMeRun")), n"");
  }
  if !gang {
    if t.mood == CBTalkAfraid() {
      return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-HHiIDonTWant"), CBT(n"Cyberbane-StreetTalk-PleaseIMJustGoingHome"), CBT(n"Cyberbane-StreetTalk-OkayOkayHi")), n"fear_beg");
    }
    if first {
      CBTalkConduct(sys, game, n"", CBConfig.TalkGreetConduct());
    }
    if t.mood == CBTalkFriendly() {
      // A fan may stand V a drink.
      if first {
        let gift = CBTalkFanGift(sys, game, player);
        if gift > 0 {
          return CBTalkSay(CBPick3(CBTf(n"Cyberbane-StreetTalk-NoWayItSYouHere", [s"\(gift)"]),
                                          CBTf(n"Cyberbane-StreetTalk-WaitTillITellEveryoneTake", [s"\(gift)"]),
                                          CBTf(n"Cyberbane-StreetTalk-YouReTheRealThingHere", [s"\(gift)"])), n"greeting");
        }
      }
      let title = CBWhisperTitle(sys);
      if StrLen(title) > 0 {
        return CBTalkSay(CBPick3(CBTf(n"Cyberbane-StreetTalk-NoWaySayingHiToMe", [title]), CBTf(n"Cyberbane-StreetTalk-WaitTillITellEveryone", [title]), CBT(n"Cyberbane-StreetTalk-HeyBigFanSeriously")), n"greeting");
      }
      return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-HeyGoodToSeeYouAround"), CBT(n"Cyberbane-StreetTalk-EveningStaySafeOutThere"), CBT(n"Cyberbane-StreetTalk-HeardGoodThingsAboutYou")), n"greeting");
    }
    // They remember V while they are around.
    if IsDefined(t.npc) && t.npc.cbTalkTimes > 0 {
      return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-YouAgain"), CBT(n"Cyberbane-StreetTalk-BackAlreadyWhatNow"), CBT(n"Cyberbane-StreetTalk-WeJustTalked")), n"");
    }
    // Every line here translatable ("Hey." and "Evening." were written into the code), and twice as many: this is the
    // line a stranger says most.
    return CBTalkSay(CBLineOf([CBT(n"Cyberbane-StreetTalk-Hey"), CBT(n"Cyberbane-StreetTalk-Evening"), CBT(n"Cyberbane-StreetTalk-UhHi"),
                               CBT(n"Cyberbane-StreetTalk-DoIKnowYou"), CBT(n"Cyberbane-StreetTalk-YeahCanIHelpYou"),
                               CBT(n"Cyberbane-StreetTalk-MakeItFastImLate"), CBT(n"Cyberbane-StreetTalk-YouLostChoom"),
                               CBT(n"Cyberbane-StreetTalk-NotBuyingWhateverItIs")]), n"greeting");
  }
  let label = StrLen(CBFactionLabel(t.faction)) > 0 ? CBFactionLabel(t.faction) : CBT(n"Cyberbane-StreetTalk-TheCrew");
  if t.mood == CBTalkFriendly() {
    if first {
      CBTalkWarm(sys, game, t.faction, CBConfig.TalkGreetWarmth(), CBConfig.PostureAllied() - 1.0);
    }
    // A friend may have word on their enemies.
    let tip = CBTalkFriendTip(sys, game, player, t);
    if StrLen(tip) > 0 {
      return CBTalkSay(tip, n"greeting");
    }
    return CBTalkSay(CBPick4(CBT(n"Cyberbane-StreetTalk-GoodToSeeYouChoom"), CBT(n"Cyberbane-StreetTalk-AlwaysWelcomeHere"), CBTf(n"Cyberbane-StreetTalk-YouNeedAnythingYouAsk", [label]), CBT(n"Cyberbane-StreetTalk-TheBossSaysHi")), n"greeting");
  }
  if t.mood == CBTalkAfraid() {
    // Saying hello to somebody who expected worse: mercy, in a small way, and the way back from a
    // grudge that does not cost eddies (CBCreditMercy keeps it under MercyCeiling).
    if first && !CBReputationFrozen() {
      let tally = CBTalkTallyFor(sys, game, t.faction);
      if IsDefined(tally) && tally.warmth < CBConfig.TalkWarmthPerDay() {
        let fs = sys.EnsureFaction(t.faction);
        let before = IsDefined(fs) ? fs.standing : 0.0;
        CBCreditMercy(sys, t.faction, CBConfig.TalkGreetMercy());
        if IsDefined(fs) {
          tally.warmth += MaxF(0.0, fs.standing - before);
        }
      }
    }
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-WeGoodWeReGoodRight"), CBT(n"Cyberbane-StreetTalk-HeyYeahHiIMNot"), CBT(n"Cyberbane-StreetTalk-DidnTSeeYouWhateverYou")), n"fear_beg");
  }
  if t.mood == CBTalkHostile() {
    // The parley, once per person: talked down, they and the crew standing with them back off for good (they hold back
    // from V, as the frightened do, CBHoldsBackFromV); not, and they are as they were, which for a gang at war with V
    // means the fight starts once the talk is over.
    if first && !CBReputationFrozen() {
      let cool = CBTalkStat(game, gamedataStatType.Cool) >= CBConfig.TalkAttributeCheck() ? CBConfig.TalkAttributeBonus() : 0.0;
      let chance = ClampF(CBTalkNerveGap(t) * CBConfig.ParleyScale() + CBConfig.ParleyBase() + cool,
                          CBConfig.ParleyMin(), CBConfig.ParleyMax());
      if RandF() < chance * sys.WornPerk().breakMult {
        let calmed = CBTalkParleyCrew(sys, t);
        CBLog.Info(n"Talk", s"Parley held with one of \(NameToString(t.faction)); \(calmed) of their crew back off with them.");
        return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-FineWalkAwayThisTime"), CBT(n"Cyberbane-StreetTalk-YouVeGotNerveGoOn"), CBT(n"Cyberbane-StreetTalk-AlrightNobodyHereSawYou")), n"");
      }
      CBLog.Info(n"Talk", s"Parley refused by one of \(NameToString(t.faction)).");
    }
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-YouVeGotNerveWalkingUp"), CBT(n"Cyberbane-StreetTalk-KeepWalkingBeforeIChangeMy"), CBT(n"Cyberbane-StreetTalk-NotYourStreetNotYourFriend")), n"bump");
  }
  if first {
    CBTalkWarm(sys, game, t.faction, CBConfig.TalkGreetWarmth(), CBConfig.MercyCeiling());
  }
  if IsDefined(t.npc) && t.npc.cbTalkTimes > 0 {
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-BackAgainWhatIsItNow"), CBT(n"Cyberbane-StreetTalk-YouAgainMakeItQuick"), CBT(n"Cyberbane-StreetTalk-ThoughtWeWereDone")), n"");
  }
  return CBTalkSay(CBLineOf([CBT(n"Cyberbane-StreetTalk-HeyYouReAllRightI"), CBT(n"Cyberbane-StreetTalk-Choom"),
                             CBT(n"Cyberbane-StreetTalk-EveningKeepItFriendly"), CBT(n"Cyberbane-StreetTalk-YouLookLikeTrouble"),
                             CBT(n"Cyberbane-StreetTalk-WhatsTheWord"), CBT(n"Cyberbane-StreetTalk-QuietNightSoFar")]), n"greeting");
}

// A friend of V's passing on where one of their enemies' Rivals is: once a day per gang.
func CBTalkFriendTip(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> String {
  if !CBHideoutsOn() || IsDefined(CBCurrentLead(sys, game)) {
    return "";
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if !IsDefined(tally) || tally.tips >= CBConfig.TalkTipsPerDay() || RandF() > CBConfig.TalkTipChance() {
    return "";
  }
  let enemies = CBGangRivalsOf(sys.GetContent(), t.faction);
  for r in sys.GetRivals() {
    if IsDefined(r) && ArrayContains(enemies, r.faction) && CBWhereaboutsForSale(sys, game, r) == 0 {
      let s = CBRivalHideout(sys, game, player, r);
      if IsDefined(s) {
        CBMarkLeadTold(sys, s, t.faction, CBGameSeconds(game));
        tally.tips += 1;
        let name = CBRivalDisplayName(sys.GetContent(), r);
        let pin = CBMapMarkersOn() ? CBT(n"Cyberbane-StreetTalk-PutItOnYourMap") : "";
        CBLog.Info(n"Talk", s"A friend of \(NameToString(t.faction)) gave up rival \(r.id).");
        return CBTf(n"Cyberbane-StreetTalk-SinceYouReHereHasBeen", [s"\(name)", s"\(CBPlacePhrase(s.district, CBSightingPos(s)))", s"\(pin)"]);
      }
    }
  }
  return "";
}

// ---- Dismiss -------------------------------------------------------------------------------------------

func CBTalkOnDismiss(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  if t.cop {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-WatchTheAttitude"), CBT(n"Cyberbane-StreetTalk-SureMoveAlong")), n"");
  }
  if t.mood == CBTalkAfraid() {
    if gang {
      CBTalkFear(sys, game, t.faction, CBConfig.TalkDismissFear());
      CBTalkSendOff(game, t);
    } else {
      CBTalkScare(player, t, 1);
    }
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-GoingIMGoing"), CBT(n"Cyberbane-StreetTalk-SorrySorry"), CBT(n"Cyberbane-StreetTalk-YouGotIt")), n"fear_beg");
  }
  if gang && t.mood == CBTalkFriendly() {
    // Blanking friends once is nothing. Doing it all day is noticed.
    let tally = CBTalkTallyFor(sys, game, t.faction);
    if IsDefined(tally) && tally.slight > 0.0 {
      CBTalkSlight(sys, game, t.faction, CBConfig.TalkDismissFriendCost());
    } else {
      if IsDefined(tally) {
        tally.slight += 0.01;
      }
    }
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-WhateverChoom"), CBT(n"Cyberbane-StreetTalk-BusyHuhFine")), n"");
  }
  if t.mood == CBTalkHostile() {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-WatchYourself"), CBT(n"Cyberbane-StreetTalk-WalkWhileYouCan")), n"bump");
  }
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-Fine"), CBT(n"Cyberbane-StreetTalk-YeahYeah"), CBT(n"Cyberbane-StreetTalk-YourLoss")), n"");
}

// ---- Antagonize ----------------------------------------------------------------------------------------

func CBTalkOnAntagonize(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  // The law answers in words, always.
  if t.cop {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkCopCost());
    CBTalkConduct(sys, game, n"", -CBConfig.TalkBullyConduct());
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-RealFunnyMoveItBeforeI"), CBT(n"Cyberbane-StreetTalk-KeepTalkingAndSeeWhereIt"), CBT(n"Cyberbane-StreetTalk-IVeGotYourFaceNow")), n"bump");
  }
  if !gang {
    CBTalkConduct(sys, game, n"", -CBConfig.TalkCivAntagonizeConduct());
    if t.mood == CBTalkAfraid() || RandF() < t.fear {
      CBTalkScare(player, t, t.fear >= CBConfig.TalkCivAfraid() ? 3 : 2);
      return CBTalkSayTheirs(CBPick3(CBT(n"Cyberbane-StreetTalk-LeaveMeAlone"), CBT(n"Cyberbane-StreetTalk-IDonTWantTrouble"), CBT(n"Cyberbane-StreetTalk-Psycho")), n"fear_foll");
    }
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-TheHellSYourProblem"), CBT(n"Cyberbane-StreetTalk-GetOutOfMyFace"), CBT(n"Cyberbane-StreetTalk-RealToughGoBotherSomeoneElse")), n"bump");
  }
  if t.mood == CBTalkFriendly() {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultFriendCost());
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-NotFunnyChoomNotFunnyAt"), CBT(n"Cyberbane-StreetTalk-CarefulFriendsHaveLimits"), CBT(n"Cyberbane-StreetTalk-SayThatAgainAndWeRe")), n"bump");
  }
  if t.mood == CBTalkHostile() {
    if CBTalkFight(sys, game, player, t) {
      return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-YouReDead"), CBT(n"Cyberbane-StreetTalk-BigMistake"), CBT(n"Cyberbane-StreetTalk-BeenWaitingForThis")), n"");
    }
    return CBTalkSayTheirs(CBT(n"Cyberbane-StreetTalk-NotHereNotNowButSoon"), n"rep_final_warning");
  }
  let gap = CBTalkNerveGap(t) + RandRangeF(-0.15, 0.15);
  if t.mood == CBTalkAfraid() || gap > CBConfig.TalkFoldGap() {
    // Most fold. A few snap.
    if t.mood == CBTalkAfraid() && RandF() < CBConfig.TalkSnapChance() && CBTalkFight(sys, game, player, t) {
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-IMNotRunningFromYou"), CBT(n"Cyberbane-StreetTalk-EnoughENOUGH")), n"");
    }
    CBTalkFear(sys, game, t.faction, CBConfig.TalkFoldFear());
    CBTalkConduct(sys, game, t.faction, -CBConfig.TalkBullyConduct());
    CBTalkSendOff(game, t);
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-OkayOkayForgetIt"), CBT(n"Cyberbane-StreetTalk-NotWorthItNotWorthIt"), CBT(n"Cyberbane-StreetTalk-WhateverYouSay")), n"fear_beg");
  }
  if gap < -CBConfig.TalkFoldGap() && CBTalkFight(sys, game, player, t) {
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-AlrightLetSDance"), CBT(n"Cyberbane-StreetTalk-YouPickedTheWrongOne"), CBT(n"Cyberbane-StreetTalk-SayThatToMyFaceOh")), n"");
  }
  CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost() * CBCodeInsult(t.faction));
  return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-KeepRunningYourMouthSeeWhat"), CBT(n"Cyberbane-StreetTalk-BigTalkWalkAway"), CBT(n"Cyberbane-StreetTalk-AnotherWordAndYouReBleeding")), n"bump");
}

// ---- Intimidate ----------------------------------------------------------------------------------------

func CBTalkOnIntimidate(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> ref<CBTalkAnswer> {
  let gang = NotEquals(t.faction, n"") && !t.cop;
  if t.cop {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkCopCost() * 2.0);
    CBTalkConduct(sys, game, n"", -CBConfig.TalkBullyConduct());
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-ThreateningAnOfficerBold"), CBT(n"Cyberbane-StreetTalk-TryThatAgainIDareYou")), n"bump");
  }
  let npc = t.npc;
  let immovable = npc.IsBoss() || CBHoldsGround(npc);
  // What V leans with: their fear, and what V looks like doing it.
  let chance = CBTalkNerveGap(t) * CBConfig.TalkIntimidateScale() + CBConfig.TalkIntimidateBase();
  if t.mood == CBTalkAfraid() {
    chance += CBConfig.TalkAfraidBonus();
  }
  // A V built like a wall does not have to raise their voice.
  if CBTalkStat(game, gamedataStatType.Strength) >= CBConfig.TalkAttributeCheck() {
    chance += CBConfig.TalkAttributeBonus();
  }
  chance = ClampF(chance * sys.WornPerk().breakMult, CBConfig.TalkIntimidateMin(), CBConfig.TalkIntimidateMax());
  if !gang {
    if !immovable && RandF() < chance {
      CBTalkScare(player, t, 3);
      CBTalkConduct(sys, game, n"", -CBConfig.TalkCivIntimidateConduct());
      if !CBReputationFrozen() {
        let tally = CBTalkTallyFor(sys, game, n"");
        if IsDefined(tally) && tally.fear < CBConfig.TalkFearPerDay() {
          tally.fear += CBConfig.TalkCivDread();
          sys.AddDeedDreadPoints(CBConfig.TalkCivDread());
        }
      }
      return CBTalkSayTheirs(CBPick3(CBT(n"Cyberbane-StreetTalk-OkayIMGoing"), CBT(n"Cyberbane-StreetTalk-PleaseIDidnTSeeAnything"), CBT(n"Cyberbane-StreetTalk-DonTHurtMe")), n"fear_beg");
    }
    return CBTalkSay(CBPick3(CBT(n"Cyberbane-StreetTalk-YeahWhateverPoser"), CBT(n"Cyberbane-StreetTalk-IsThatSupposedToScareMe"), CBT(n"Cyberbane-StreetTalk-GoPractiseOnSomeoneElse")), n"bump");
  }
  if t.mood == CBTalkFriendly() {
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkLeanOnFriendCost());
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-WhoaOkayNoNeedForThat"), CBT(n"Cyberbane-StreetTalk-ThatSHowYouTreatFriends")), n"bump");
  }
  if immovable || RandF() >= chance {
    // Lost face. And somebody with the nerve, or the grudge, takes it further.
    CBTalkFear(sys, game, t.faction, -CBConfig.TalkLostFace());
    CBTalkSlight(sys, game, t.faction, CBConfig.TalkInsultCost() * CBCodeInsult(t.faction) * 0.5);
    if (t.mood == CBTalkHostile() || CBTalkNerveGap(t) < -CBConfig.TalkFoldGap()) && RandF() < CBConfig.TalkCallBluffFight()
       && CBTalkFight(sys, game, player, t) {
      return CBTalkSay(CBPick2(CBT(n"Cyberbane-StreetTalk-LetSSeeYouBackThat"), CBT(n"Cyberbane-StreetTalk-WrongOneToPush")), n"");
    }
    return CBTalkSayTheirs(CBPick3(CBT(n"Cyberbane-StreetTalk-ThatSupposedToScareMe"), CBT(n"Cyberbane-StreetTalk-HeardOfYouThoughtYouD"), CBT(n"Cyberbane-StreetTalk-WalkAwayWhileIMFeeling")), n"rep_final_warning");
  }
  // It worked. What they give up depends on what they have.
  CBTalkFear(sys, game, t.faction, CBConfig.TalkLeanFear());
  CBTalkSlight(sys, game, t.faction, CBConfig.TalkLeanCost());
  CBStandDownFromV(game, npc);   // leaned on and folded: they will not draw on V after this, by the game's rules too
  // Frightened badly enough, they offer themselves to V's crew (Reactions/Crew.reds, [C2]).
  let joined = CBCrewFrightenedJoins(sys, game, t);
  if IsDefined(joined) {
    CBTalkSendOff(game, t);
    return joined;
  }
  let told = CBTalkInform(sys, game, player, t);
  if StrLen(told) > 0 {
    CBTalkSendOff(game, t);
    return CBTalkSay(told, n"fear_beg");
  }
  let paid = CBTalkShakedown(sys, game, player, t);
  if paid > 0 {
    return CBTalkSay(CBPick3(CBTf(n"Cyberbane-StreetTalk-HereTakeItAndGo", [s"\(paid)"]), CBTf(n"Cyberbane-StreetTalk-EddiesThatSAllIGot", [s"\(paid)"]), CBTf(n"Cyberbane-StreetTalk-FineWeReSquareRight", [s"\(paid)"])), n"fear_beg");
  }
  CBTalkSendOff(game, t);
  return CBTalkSayTheirs(CBPick3(CBT(n"Cyberbane-StreetTalk-AlrightAlrightIMGone"), CBT(n"Cyberbane-StreetTalk-IMLeavingLookIM"), CBT(n"Cyberbane-StreetTalk-DidnTMeanAnythingByIt")), n"fear_beg");
}

// Somebody leaned on hard enough gives up where one of their own gang's Rivals is lying low: the same
// lead the Hub sells, free, once per gang a day. "" when there was nothing to give up.
func CBTalkInform(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> String {
  if t.leadId <= 0 || !CBHideoutsOn() {
    return "";
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  if !IsDefined(tally) || tally.leaks >= CBConfig.TalkLeaksPerDay() {
    return "";
  }
  let r = sys.FindRivalById(t.leadId);
  if !IsDefined(r) || CBWhereaboutsForSale(sys, game, r) != 0 {
    return "";
  }
  let s = CBRivalHideout(sys, game, player, r);
  if !IsDefined(s) {
    return "";
  }
  let now = CBGameSeconds(game);
  CBMarkLeadTold(sys, s, n"", now);
  tally.leaks += 1;
  CBFileLog(sys, n"Informant", now, CBEventDistrict(sys, game), t.faction, Cast<Float>(r.id));
  CBLog.Info(n"Talk", s"Leaned on one of \(NameToString(t.faction)): rival \(r.id) is \(NameToString(s.district)).");
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let place = CBPlacePhrase(s.district, CBSightingPos(s));
  let pin = CBMapMarkersOn() ? CBT(n"Cyberbane-StreetIntel-ItSOnYourMap") : "";
  return CBPick3(
    CBTf(n"Cyberbane-StreetTalk-FineSLyingLowYouDidn", [s"\(name)", s"\(place)", s"\(pin)"]),
    CBTf(n"Cyberbane-StreetTalk-HoledUpPleaseJustGo", [s"\(name)", s"\(place)", s"\(pin)"]),
    CBTf(n"Cyberbane-StreetTalk-OkayLastIHeardThatS", [s"\(name)", s"\(place)", s"\(pin)"]));
}

// Paying V to go away: street tax, scaled to V's level, once per gang a day. 0 when nothing was paid.
func CBTalkShakedown(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>, t: ref<CBTalkTarget>) -> Int32 {
  if !CBShakedownsOn() || CBReputationFrozen() {
    return 0;
  }
  let tally = CBTalkTallyFor(sys, game, t.faction);
  let ts = GameInstance.GetTransactionSystem(game);
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(tally) || !IsDefined(ts) || tally.taxes >= CBConfig.TalkTaxesPerDay() {
    return 0;
  }
  let level = IsDefined(stats) ? stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level) : 1.0;
  let amount = Min(CBConfig.TalkTaxMax(), RoundF(CBConfig.TalkTaxBase() + level * CBConfig.TalkTaxPerLevel()
                                                * RandRangeF(0.7, 1.3)));
  if amount <= 0 {
    return 0;
  }
  ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  tally.taxes += 1;
  // Extortion is not how a professional works.
  CBTalkConduct(sys, game, t.faction, -CBConfig.TalkShakedownConduct());
  CBFileLog(sys, n"ShakeDown", CBGameSeconds(game), CBEventDistrict(sys, game), t.faction, Cast<Float>(amount));
  CBLog.Info(n"Talk", s"Shook down one of \(NameToString(t.faction)) for \(amount)eb.");
  return amount;
}

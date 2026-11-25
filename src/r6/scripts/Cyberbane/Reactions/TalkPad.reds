// Cyberbane - The D-pad belongs to a conversation while its lines are up
//
// Up and down on the pad scroll the lines (ChoiceScrollUp/Down), and the same two buttons are the healing item
// (UseConsumable) and the phone (PhoneInteract) (r6/config/inputContexts.xml). The game keeps the healing item out of a
// dialogue by asking whether a list is on the UIInteractions board (DefaultTransition.AreChoiceHubsActive, read by every
// consumable path of the upper-body state machine), and never keeps the phone out at all: its own dialogues are scenes,
// and a scene locks the phone by itself. Street talk is not a scene. Its list is on that board, but the game clears the
// board now and then and the list goes back up a moment later (CBTalkHoldList), so a press in that moment used a MaxDoc,
// and holding D-pad down to scroll opened the phone (NewHudPhoneGameController.OnAction, BUTTON_HOLD_COMPLETE).
//
// From the moment the lines go up until the conversation is over (CBStreetTalk.HoldsHands, the same window V's hands are
// held for), both buttons answer to the conversation only.

public func CBTalkHoldsPad(game: GameInstance) -> Bool {
  let sys = CyberbaneSystem.Get(game);
  let talk = IsDefined(sys) ? sys.GetStreetTalk() : null;
  return IsDefined(talk) && talk.HoldsHands();
}

// The healing item, the combat gadget and the body-carry hints all ask this one question before they act.
@wrapMethod(DefaultTransition)
protected final const func AreChoiceHubsActive(const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if wrappedMethod(scriptInterface) {
    return true;
  }
  let owner = scriptInterface.executionOwner;
  return IsDefined(owner) && owner.IsPlayer() && CBTalkHoldsPad(owner.GetGame());
}

// The phone: D-pad down, a press and a hold. Swallowed whole while the lines are up, an incoming call's pick-up
// included: scrolling down a conversation used to answer it. The call keeps ringing for V to pick up after.
@wrapMethod(NewHudPhoneGameController)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  if Equals(ListenerAction.GetName(action), n"PhoneInteract") && CBTalkHoldsPad(GetGameInstance()) {
    return false;
  }
  return wrappedMethod(action, consumer);
}

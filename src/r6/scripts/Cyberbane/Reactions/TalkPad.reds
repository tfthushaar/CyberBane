// Cyberbane - The D-pad belongs to a conversation while its lines are up
//
// Up and down on the D-pad scroll the lines, but the same buttons are the healing item and the phone. Street talk isn't
// a scene, so the game doesn't lock either of them; from the moment the lines go up until the talk is over
// (CBStreetTalk.HoldsHands) both answer to the conversation only.

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
  wrappedMethod(action, consumer);   // as a statement, like every wrapped event here
  return true;
}

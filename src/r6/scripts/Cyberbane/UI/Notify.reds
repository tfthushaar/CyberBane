// Cyberbane - On-screen messages (spec §12.2)
//
// Minimal notification helper using the game's UI_Notifications blackboard
// (the centre-screen message channel). This is the interim presenter for toasts
// and messages; the stacked top-right toast widget (Codeware UI) lands in M6.
// Signatures compile-verified against 2.31.

// How long an on-screen message stays, as a multiple of what the caller asked for.
func CBMessageHold() -> Float {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return Cast<Float>(CBConfig.MessageHoldDefault()) / 100.0;
  }
  return ClampF(Cast<Float>(rt.GetSettings().messageHold) / 100.0, 0.5, 5.0);
}

// One card at a time, each kept for its whole time.
public func CBShowMessage(game: GameInstance, text: String, duration: Float, opt urgent: Bool) -> Void {
  let rt = CyberbaneRuntime.Get();
  let ts = GameInstance.GetTimeSystem(game);
  if !IsDefined(rt) || !IsDefined(ts) {
    CBPutCard(game, text, duration, -1.0);
    return;
  }
  let now = EngineTime.ToFloat(ts.GetSimTime());
  // The service outlasts a load and the sim clock need not: a card "up" past any card's length, or a line of cards asked
  // for in the future, is from another session.
  if rt.cardUntil > now + CBConfig.MessageMaxSeconds() {
    rt.ClearCards();
  }
  CBDropStaleCards(rt, now);
  if now >= rt.cardUntil {
    CBShowCardNow(game, rt, text, duration, now);
    return;
  }
  // Waiting behind the one up. Room for three: the oldest that is not a menu's answer makes way.
  if rt.CardCount() >= CBConfig.CardQueueCap() {
    let i = 0;
    let dropped = false;
    while i < rt.CardCount() && !dropped {
      if !rt.cardUrgent[i] {
        rt.DropCard(i);
        dropped = true;
      }
      i += 1;
    }
    if !dropped && !urgent {
      return;
    }
  }
  let at = urgent ? 0 : rt.CardCount();
  if urgent {
    while at < rt.CardCount() && rt.cardUrgent[at] {
      at += 1;   // behind the menu answers already waiting, in the order they came
    }
  }
  ArrayInsert(rt.cardText, at, text);
  ArrayInsert(rt.cardSeconds, at, duration);
  ArrayInsert(rt.cardAt, at, now);
  ArrayInsert(rt.cardUrgent, at, urgent);
  CBCardPumpAt(game, rt, rt.cardUntil, now);
}

func CBDropStaleCards(rt: ref<CyberbaneRuntime>, now: Float) -> Void {
  let i = rt.CardCount() - 1;
  while i >= 0 {
    let age = now - rt.cardAt[i];
    if age < 0.0 || (!rt.cardUrgent[i] && age > CBConfig.CardStaleSeconds()) {
      rt.DropCard(i);
    }
    i -= 1;
  }
}

func CBShowCardNow(game: GameInstance, rt: ref<CyberbaneRuntime>, text: String, duration: Float, now: Float) -> Void {
  rt.SetLastMessageAt(now);
  let shown = CBPutCard(game, text, duration, now);
  if shown <= 0.0 {
    return;
  }
  rt.cardUntil = now + shown;
  if rt.CardCount() > 0 {
    CBCardPumpAt(game, rt, rt.cardUntil, now);
  }
}

// The next card in line once the one up has had its time. One pump per end time.
func CBCardPumpAt(game: GameInstance, rt: ref<CyberbaneRuntime>, until: Float, now: Float) -> Void {
  if rt.cardPumpAt >= until && rt.cardPumpAt <= until + 0.01 {
    return;   // already due then
  }
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return;
  }
  rt.cardPumpAt = until;
  let cb = new CBCardPumpCallback();
  ds.DelayCallback(cb, MaxF(until - now, 0.1) + 0.1, false);
}

public class CBCardPumpCallback extends DelayCallback {
  public func Call() -> Void {
    let game = GetGameInstance();
    let rt = CyberbaneRuntime.Get();
    let ts = GameInstance.GetTimeSystem(game);
    if !IsDefined(rt) || !IsDefined(ts) {
      return;
    }
    let now = EngineTime.ToFloat(ts.GetSimTime());
    if now + 0.05 < rt.cardUntil {
      return;   // a card went up since, and its own pump comes after it
    }
    CBDropStaleCards(rt, now);
    if rt.CardCount() == 0 {
      return;
    }
    let text = rt.cardText[0];
    let seconds = rt.cardSeconds[0];
    rt.DropCard(0);
    CBShowCardNow(game, rt, text, seconds, now);
  }
}

// The card on the screen, and its clear (CBCardClearCallback). How long it stays, in seconds; 0 when it could not be
// shown. `stamp` is the sim time it went up, -1 when unknown.
func CBPutCard(game: GameInstance, text: String, duration: Float, stamp: Float) -> Float {
  // The blackboard system is null during world transitions; dereferencing it then crashes.
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return 0.0;
  }
  let bb = bbs.Get(GetAllBlackboardDefs().UI_Notifications);
  if !IsDefined(bb) {
    return 0.0;
  }
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = MaxF(duration * CBMessageHold(), CBConfig.MessageMinSeconds());
  msg.message = text;
  bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
  // And taken down when its time is up, if the game has not already done it (CBCardClearCallback).
  let ds = GameInstance.GetDelaySystem(game);
  if IsDefined(ds) {
    let cb = new CBCardClearCallback();
    cb.text = text;
    cb.stamp = stamp;
    ds.DelayCallback(cb, msg.duration + CBConfig.MessageClearSlackSeconds(), false);
  }
  return msg.duration;
}

// The card put away when its time is up.
public class CBCardClearCallback extends DelayCallback {
  public let text: String;
  public let stamp: Float;

  public func Call() -> Void {
    let game = GetGameInstance();
    let rt = CyberbaneRuntime.Get();
    if this.stamp >= 0.0 && IsDefined(rt) && (rt.GetLastMessageAt() > this.stamp || rt.GetLastMessageAt() < this.stamp) {
      return;   // a newer card of ours is up, with its own clock
    }
    let bbs = GameInstance.GetBlackboardSystem(game);
    if !IsDefined(bbs) {
      return;
    }
    let bb = bbs.Get(GetAllBlackboardDefs().UI_Notifications);
    if !IsDefined(bb) {
      return;
    }
    let shown = FromVariant<SimpleScreenMessage>(bb.GetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage));
    if !shown.isShown || !Equals(shown.message, this.text) {
      return;   // already gone, or somebody else's message is up now
    }
    let off: SimpleScreenMessage;
    off.isShown = false;
    off.duration = 0.0;
    off.message = "";
    bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(off), true);
  }
}

// English Renown-tier labels for interim messages. Full localization arrives with
// the toast/Hub UI (loc keys Cyberbane-Tier-*).
public func CBTierName(tier: Int32) -> String {
  if tier == EnumInt(ECBRenownTier.Legend) { return CBT(n"Cyberbane-CrewKit-Legend"); }
  if tier == EnumInt(ECBRenownTier.Infamous) { return CBT(n"Cyberbane-Notify-Infamous"); }
  if tier == EnumInt(ECBRenownTier.Notorious) { return CBT(n"Cyberbane-Notify-Notorious"); }
  if tier == EnumInt(ECBRenownTier.KnownMerc) { return CBT(n"Cyberbane-Notify-KnownMerc"); }
  if tier == EnumInt(ECBRenownTier.LocalName) { return CBT(n"Cyberbane-Notify-LocalName"); }
  return CBT(n"Cyberbane-Hud-Nobody");
}

// Cyberbane - On-screen messages (spec §12.2)
//
// Minimal notification helper using the game's UI_Notifications blackboard
// (the centre-screen message channel). This is the interim presenter for toasts
// and messages; the stacked top-right toast widget (Codeware UI) lands in M6.
// Signatures compile-verified against 2.31.

// How long an on-screen message stays, as a multiple of what the caller asked for.
//
// Applied here rather than at the twenty-odd call sites, so there is one place that decides and
// no chance of a message being missed. The call sites ask for what the message is worth
// relative to the others; this is the player saying how long they need to read one.
func CBMessageHold() -> Float {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return Cast<Float>(CBConfig.MessageHoldDefault()) / 100.0;
  }
  return ClampF(Cast<Float>(rt.GetSettings().messageHold) / 100.0, 0.5, 5.0);
}

public func CBShowMessage(game: GameInstance, text: String, duration: Float) -> Void {
  // One at a time.
  //
  // This channel shows a single message, so two sent together means the first is replaced
  // before it can be read and the player sees a flicker and half a sentence. Three or four in
  // a row happens easily: a Rival arriving, a crew being sent and a gang turning hostile are
  // separate events that can land in the same second. A short floor between them means each
  // one is actually readable. Dropped rather than queued, because a queue would still be
  // showing the first message long after the thing it describes has happened.
  let rt = CyberbaneRuntime.Get();
  let ts = GameInstance.GetTimeSystem(game);
  let stamp = -1.0;
  if IsDefined(rt) && IsDefined(ts) {
    let now = EngineTime.ToFloat(ts.GetSimTime());
    stamp = now;
    // The stamp lives on a service, which outlasts a load, and the sim clock need not. Read without
    // the first test, a clock behind the stamp is a gap that looks negative and so always too small.
    if now >= rt.GetLastMessageAt() && now - rt.GetLastMessageAt() < CBConfig.MessageMinGapSeconds() {
      return;
    }
    rt.SetLastMessageAt(now);
  }
  // The blackboard system is null during world transitions; dereferencing it then crashes.
  let bbs = GameInstance.GetBlackboardSystem(game);
  if !IsDefined(bbs) {
    return;
  }
  let bb = bbs.Get(GetAllBlackboardDefs().UI_Notifications);
  if !IsDefined(bb) {
    return;
  }
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = MaxF(duration * CBMessageHold(), CBConfig.MessageMinSeconds());
  msg.message = text;
  bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
  // And taken down when its time is up, if the game has not already done it (2.5.6, CBCardClearCallback).
  let ds = GameInstance.GetDelaySystem(game);
  if IsDefined(ds) {
    let cb = new CBCardClearCallback();
    cb.text = text;
    cb.stamp = stamp;
    ds.DelayCallback(cb, msg.duration + CBConfig.MessageClearSlackSeconds(), false);
  }
}

// The card put away when its time is up (2.5.6). The game's own on-screen message is meant to fade by itself after
// its duration, and now and then it did not: with messages going to cards, one stayed up until the next message came,
// five minutes or half an hour later. Cyberbane now takes it down itself, a moment after the game should have, and
// only while it is still the card Cyberbane put up: nothing of Cyberbane's has replaced it since (the stamp), and no
// message of the game's or another mod's either (the text).
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
  if tier == EnumInt(ECBRenownTier.Legend) { return "Legend"; }
  if tier == EnumInt(ECBRenownTier.Infamous) { return "Infamous"; }
  if tier == EnumInt(ECBRenownTier.Notorious) { return "Notorious"; }
  if tier == EnumInt(ECBRenownTier.KnownMerc) { return "Known Merc"; }
  if tier == EnumInt(ECBRenownTier.LocalName) { return "Local Name"; }
  return "Nobody";
}

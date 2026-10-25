// Cyberbane - On-screen messages (spec §12.2)
//
// Minimal notification helper using the game's UI_Notifications blackboard
// (the centre-screen message channel). This is the interim presenter for toasts
// and messages; the stacked top-right toast widget (Codeware UI) lands in M6.
// Signatures compile-verified against 2.31.

public func CBShowMessage(game: GameInstance, text: String, duration: Float) -> Void {
  let bb = GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_Notifications);
  if !IsDefined(bb) {
    return;
  }
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = duration;
  msg.message = text;
  bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
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

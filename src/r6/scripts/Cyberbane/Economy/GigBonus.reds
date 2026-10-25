// Cyberbane - Gig payout bonus (spec §9.7)
//
// Fixers pay the famous more. This wraps the game's reward grant, measures how many
// eddies a reward actually handed over, and if it was a real job payout (not loose
// loot money) it tops it up by a fraction that grows with your Renown tier. It reads
// the money granted rather than guessing which reward is a gig, so it stays correct
// across quests, gigs and NCPD work without any hardcoded reward ids. The bonus is paid
// as ordinary eddies, so it is harmless if a reward turns out not to be job money.

@wrapMethod(RPGManager)
public final static func GiveReward(gameInstance: GameInstance, rewardID: TweakDBID, opt entityID: StatsObjectID, opt quantityMultiplier: Float) -> Void {
  let rt = CyberbaneRuntime.Get();
  let on = true;
  let mult = 1.0;
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      on = false;
    }
    if rt.HasSettings() {
      let s = rt.GetSettings();
      if !s.gigBonus {
        on = false;
      }
      mult = s.gigBonusMult;
    }
  }

  let player = GetPlayer(gameInstance);
  let ts = GameInstance.GetTransactionSystem(gameInstance);
  if !on || !IsDefined(player) || !IsDefined(ts) {
    wrappedMethod(gameInstance, rewardID, entityID, quantityMultiplier);
    return;
  }

  let money = ItemID.FromTDBID(t"Items.money");
  let before = ts.GetItemQuantity(player, money);
  wrappedMethod(gameInstance, rewardID, entityID, quantityMultiplier);
  let delta = ts.GetItemQuantity(player, money) - before;
  if delta < CBConfig.GigBonusMinPayout() {
    return;   // not a job payout (loot money or no money) - leave it alone
  }

  let sys = CyberbaneSystem.Get(gameInstance);
  if !IsDefined(sys) {
    return;
  }
  let frac = CBGigBonusFraction(sys) * mult;
  if frac <= 0.0 {
    return;
  }
  let bonus = RoundF(Cast<Float>(delta) * frac / 50.0) * 50;   // nearest 50 eddies
  if bonus <= 0 {
    return;
  }
  ts.GiveItem(player, money, bonus);
  if IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts {
    CBShowMessage(gameInstance, s"Cyberbane: your rep earned a \(bonus)eb bonus on that payout.", 4.0);
  }
}

// Bonus fraction by Renown tier (spec §9.7): unknowns get nothing, legends get the most.
func CBGigBonusFraction(sys: ref<CyberbaneSystem>) -> Float {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return 0.0;
  }
  let maxFrac = CBConfig.GigBonusMaxFraction();
  switch score.GetTier() {
    case ECBRenownTier.Legend: return maxFrac;
    case ECBRenownTier.Infamous: return maxFrac * 0.75;
    case ECBRenownTier.Notorious: return maxFrac * 0.5;
    case ECBRenownTier.KnownMerc: return maxFrac * 0.25;
    case ECBRenownTier.LocalName: return maxFrac * 0.1;
    default: return 0.0;
  }
}

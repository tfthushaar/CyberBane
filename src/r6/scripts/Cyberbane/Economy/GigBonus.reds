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
  // `modOn` decides whether we measure the payout at all, which is what tells Cyberbane a job
  // was finished. `bonusOn` only decides whether to top the payout up. They used to be one
  // flag, so turning the eddie bonus off would also have stopped jobs counting.
  let modOn = true;
  let bonusOn = true;
  let mult = 1.0;
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      modOn = false;
    }
    if rt.HasSettings() {
      let s = rt.GetSettings();
      if !s.gigBonus {
        bonusOn = false;
      }
      mult = s.gigBonusMult;
    }
  }

  // Rewards are also handed out while the world is mid-transition (a load, a fade, a
  // scripted beat). Stand down then rather than read the player's inventory, the same way
  // every other Cyberbane hook does (crash safety).
  if !CBWorldStable(gameInstance) {
    modOn = false;
  }

  let player = GetPlayer(gameInstance);
  let ts = GameInstance.GetTransactionSystem(gameInstance);
  if !modOn || !IsDefined(player) || !IsDefined(ts) {
    wrappedMethod(gameInstance, rewardID, entityID, quantityMultiplier);
    return;
  }

  // Granting a reward can grant another one - an NCPD hustle payout that tips Street Cred
  // over a level hands out the level reward from inside this very call. Only the outermost
  // call measures and pays, so a nested payout (and its bonus) is never counted twice.
  let outermost = true;
  if IsDefined(rt) {
    outermost = rt.EnterReward() == 1;
  }

  let money = ItemID.FromTDBID(t"Items.money");
  let before = ts.GetItemQuantity(player, money);
  wrappedMethod(gameInstance, rewardID, entityID, quantityMultiplier);
  let delta = ts.GetItemQuantity(player, money) - before;

  if IsDefined(rt) {
    rt.ExitReward();
  }
  if !outermost {
    return;   // an inner grant; the call that started this will settle the bonus
  }
  if delta < CBConfig.GigBonusMinPayout() {
    return;   // not a job payout (loot money or no money) - leave it alone
  }

  let sys = CyberbaneSystem.Get(gameInstance);
  if !IsDefined(sys) {
    return;
  }

  // A measured job payout is Cyberbane's signal that V finished a job (spec §7.2.3).
  //
  // Nothing ever called the deed system: it had entry points and no detection layer, so
  // quests, gigs and hustles contributed nothing to your reputation even though the readme
  // led with "finish jobs". This is the detection layer, and it reuses the measurement this
  // hook already does rather than adding any new engine call: `delta` is real eddies the
  // game just handed over, `outermost` has already excluded nested rewards, and
  // CBWorldStable has already excluded payouts handed out mid-transition.
  //
  // Payout size separates the two kinds of work. NCPD hustles pay small; gigs and jobs pay
  // considerably more. This deliberately does not try to name the specific quest - that
  // needs journal tracking this mod does not do - so every job of a given size scores the
  // same.
  if delta >= CBConfig.JobPayoutThreshold() {
    CBApplyGig(sys, gameInstance);
  } else {
    CBApplyHustle(sys, gameInstance);
  }
  CBEvaluateTitles(sys, gameInstance);

  if !bonusOn {
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

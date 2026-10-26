// Cyberbane - Vendor pricing (spec §9.6)
//
// Night City charges the famous and the feared differently. This wraps the game's
// buy-price function and nudges the result by V's reputation: the more the city dreads
// you, the better your prices ("no trouble here, choom"); a clean Professional
// reputation earns goodwill, while a mad-dog reputation pays a danger tax. The whole
// adjustment is clamped to the Mod Settings range and only ever touches buy prices, so
// turning the system off (or the kill switch) restores vanilla pricing immediately.

@wrapMethod(MarketSystem)
public final static func GetBuyPrice(owner: wref<GameObject>, itemID: ItemID) -> Int32 {
  let base = wrappedMethod(owner, itemID);
  if !IsDefined(owner) {
    return base;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && !rt.IsEnabled() {
    return base;
  }
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().vendorPricing {
    return base;
  }
  let sys = CyberbaneSystem.Get(owner.GetGame());
  if !IsDefined(sys) {
    return base;
  }
  let m = CBVendorBuyModifier(sys);
  return RoundF(Cast<Float>(base) * (1.0 + m));
}

// Signed buy-price modifier (negative = discount), clamped to the configured range.
func CBVendorBuyModifier(sys: ref<CyberbaneSystem>) -> Float {
  let score = sys.GetScore();
  if !IsDefined(score) {
    return 0.0;
  }
  let m = 0.0;

  // Fear discount: feared mercs get "no trouble here" prices (spec §9.6).
  let dread = score.GetDread();
  if dread >= CBConfig.CivTierAfraid() {
    m -= (dread - CBConfig.CivTierAfraid()) / 40.0 * 0.12;
  }

  // Legend discount: being a household name is worth a little off the top (spec §9.6).
  if Equals(score.GetTier(), ECBRenownTier.Legend) {
    m -= 0.03;
  }

  // Code: a clean professional reputation earns goodwill; a cyberpsycho reputation pays a danger tax.
  let code = sys.GetCode();
  if code >= 40.0 {
    m -= 0.05;
  } else {
    if code <= -40.0 {
      m += 0.10;
    }
  }

  let maxDisc = CBConfig.VendorMaxDiscount();
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    maxDisc = Cast<Float>(rt.GetSettings().maxDiscount) / 100.0;
  }
  return ClampF(m, -maxDisc, CBConfig.VendorMaxSurcharge());
}

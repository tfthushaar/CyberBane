// Cyberbane - A head start from the lifepath ([72], 2.3.1)
//
// V has a past before Cyberbane starts counting. A Nomad is known to the Aldecaldos, and the Wraiths know
// the colours of a clan; a Street Kid grew up in Heywood, under the Valentinos; a Corpo was Arasaka, and
// Arasaka has not forgotten how that ended. Each is a little standing and a little of being known, with
// the gang and in the district it belongs to, given once.
//
// Only where Cyberbane starts a playthrough: a game it has never seen (VerifyPlaythroughOwner's new birth)
// or Start over (HardReset). A playthrough it already knows is never touched, so no existing save's
// numbers move. Standing decays toward neutral as it always does, so it is a head start and no more.

public func CBLifepathHeadStartOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().lifepathHeadStart;
}

public func CBLifepathHeadStart(sys: ref<CyberbaneSystem>, lifepath: Int32) -> Void {
  if !CBLifepathHeadStartOn() || !IsDefined(sys) || lifepath < 0 {
    return;
  }
  if lifepath == EnumInt(gamedataLifePath.Nomad) {
    CBHeadStartWith(sys, n"Aldecaldos", CBConfig.HeadStartFriend(), CBConfig.HeadStartKnown());
    CBHeadStartWith(sys, n"Wraiths", -CBConfig.HeadStartGrudge(), CBConfig.HeadStartKnown());
    CBApplyDistrictRenown(sys, n"Badlands", CBConfig.HeadStartDistrict());
  } else {
    if lifepath == EnumInt(gamedataLifePath.StreetKid) {
      CBHeadStartWith(sys, n"Valentinos", CBConfig.HeadStartFriend(), CBConfig.HeadStartKnown());
      CBApplyDistrictRenown(sys, n"Heywood", CBConfig.HeadStartDistrict());
    } else {
      if lifepath == EnumInt(gamedataLifePath.Corporate) {
        CBHeadStartWith(sys, n"Arasaka", -CBConfig.HeadStartGrudge(), CBConfig.HeadStartKnown());
        CBApplyDistrictRenown(sys, n"CityCenter", CBConfig.HeadStartDistrict());
      } else {
        return;
      }
    }
  }
  CBLog.Info(n"Model", s"A head start from the lifepath (\(lifepath)).");
}

func CBHeadStartWith(sys: ref<CyberbaneSystem>, faction: CName, standing: Float, renown: Float) -> Void {
  if !CBFactionOn(faction) {
    return;
  }
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(fs) {
    return;
  }
  fs.standing = ClampF(fs.standing + standing, -100.0, 100.0);
  fs.renown = ClampF(fs.renown + renown, 0.0, 100.0);
  fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
}

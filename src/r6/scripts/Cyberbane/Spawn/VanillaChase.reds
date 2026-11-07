// Cyberbane - Retired file. Empty on purpose: do not delete it.
//
// This held the old police-chase path until 1.5.0. Installing a new version over an old one does
// not remove files, so the old copy stayed on every install that updated by hand, and went on being
// compiled. It called CBChaseVehicle, so when that was removed in 1.7.0 the old copy stopped
// compiling, and a failed compile stops every script mod a player has. This file exists so that
// installing over the top replaces the old copy. tools/check_removed.ps1 fails the build if a
// script the mod has ever shipped goes missing.

public func CBRetiredVanillaChase() -> Bool = false

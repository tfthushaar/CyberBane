// Cyberbane - Retired file. Empty on purpose: do not delete it.
//
// This held a bridge to Fenix Rebirth until 1.4.6, including a wrap on PlayerPuppet. Installing a new
// version over an old one does not remove files, so the old copy stayed on every install that
// updated by hand, and went on being compiled. This file exists so that installing over the top
// replaces it. tools/check_removed.ps1 fails the build if a script the mod has ever shipped goes
// missing.

public func CBRetiredFenixRebirth() -> Bool = false

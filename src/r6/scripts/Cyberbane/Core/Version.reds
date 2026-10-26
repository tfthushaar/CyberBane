// Cyberbane - Version
//
// Single source of truth for the mod version. tools/build.ps1 rewrites this file
// at release time. Do not hand-edit the numbers during a release build.
// Kept ASCII-only because the build script rewrites it programmatically.
//
// Global scope (no module); every symbol is prefixed to avoid collisions.

public func CyberbaneVersion() -> String = "0.1.9"

// Numeric form: major*10000 + minor*100 + patch. Used for logging and gating.
public func CyberbaneVersionCode() -> Int32 = 109

// Current persistent-state schema version (see spec section 19.2). Bump and add a
// Migrate() step whenever the shape of persistent data changes.
//
// 2: rumor "districts reached" and Rival traits/weaknesses moved from nested CName
//    arrays to Int32 bit sets, so no persisted class holds a dynamic array of values.
public func CyberbaneSchemaVersion() -> Int32 = 2

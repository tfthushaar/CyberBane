// Cyberbane - Version
//
// Single source of truth for the mod version. tools/build.ps1 rewrites this file
// at release time. Do not hand-edit the numbers during a release build.
// Kept ASCII-only because the build script rewrites it programmatically.

public func CyberbaneVersion() -> String = "2.8.0"

// Numeric form: major*10000 + minor*100 + patch. Used for logging and gating.
public func CyberbaneVersionCode() -> Int32 = 20800

// Current persistent-state schema version (see spec section 19.2). Bump and add a Migrate step whenever the shape of
// persistent data changes.
public func CyberbaneSchemaVersion() -> Int32 = 4

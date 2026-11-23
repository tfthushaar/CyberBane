module Cyberbane.Api

// Cyberbane's extension API, level 1 (2.7.4).
//
// redscript compiles every installed mod together, and an add-on can only guard a call at compile time with
// `@if(ModuleExists("..."))`, which sees module names alone. This module is the promise: while it exists, the functions
// of API level 1 on `CyberbaneAPI` exist, with the same names and arguments. A later level adds its own empty marker
// module (`Cyberbane.Api2`, `Cyberbane.Api3`), so an add-on guards each newer call with that level's module, and a
// player on an older Cyberbane gets that feature switched off, never a failed compile.
//
// Never removed or renamed: a retired API function stays and does nothing, the same rule as a shipped .reds file.

public func CyberbaneApiLevel() -> Int32 {
  return CBApiLevel();
}

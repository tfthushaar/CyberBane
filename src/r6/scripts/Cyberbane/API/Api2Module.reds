module Cyberbane.Api2

// Cyberbane's extension API, level 2 (2.7.5).
//
// The marker for level 2, as Cyberbane.Api is for level 1 (API/ApiModule.reds): while this module exists, the functions of
// API level 2 on `CyberbaneAPI` exist, with the same names and arguments. An add-on guards each level 2 call, or a class
// that makes them, with `@if(ModuleExists("Cyberbane.Api2"))`, so on 2.7.4 that feature is switched off instead of the
// scripts failing to compile.
//
// Never removed or renamed: a retired API function stays and does nothing, the same rule as a shipped .reds file.

public func CyberbaneApi2Present() -> Bool {
  return CBApiLevel() >= 2;
}

module Cyberbane.Api3

// Cyberbane's extension API, level 3.
//
// The marker for level 3: while this module exists, every level 3 function on `CyberbaneAPI` and `CBListener` exists, with
// the names and arguments in README's "For mod authors". An add-on guards each level 3 call, or a class that makes them,
// with `@if(ModuleExists("Cyberbane.Api3"))`, so on a Cyberbane without level 3 that feature is off instead of the scripts
// failing to compile.

public func CyberbaneApi3Present() -> Bool {
  return CBApiLevel() >= 3;
}

module Cyberbane.Api4

// Cyberbane's extension API, level 4.
//
// The marker for level 4: while this module exists, CyberbaneAPI.JoinCrew and CrewJoinBlocked exist, with the names and
// arguments in README's "For mod authors". Guard calls to them with `@if(ModuleExists("Cyberbane.Api4"))`.

public func CyberbaneApi4Present() -> Bool {
  return CBApiLevel() >= 4;
}

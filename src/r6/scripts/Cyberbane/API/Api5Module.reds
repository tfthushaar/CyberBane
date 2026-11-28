module Cyberbane.Api5

// Cyberbane's extension API, level 5.
//
// The marker for level 5: while this module exists, WithdrawAsk, SetFactionListed, RequestEscort, EscortActive,
// ReleaseEscort, RequestPost, ReleasePost, AddTalkTopic, RemoveTalkTopic and CBTalkTopicListener exist, with the names
// and arguments in README's "For mod authors". Guard calls to them with `@if(ModuleExists("Cyberbane.Api5"))`.

public func CyberbaneApi5Present() -> Bool {
  return CBApiLevel() >= 5;
}

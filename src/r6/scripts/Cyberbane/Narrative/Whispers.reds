// Cyberbane - Whispers (spec §9.10)
//
// Text-only overheard lines shown when a recognized NPC is near and V is notable.
// Seed set of English lines; the full (speaker, mood, tier, topic) pool from
// Appendix H and its localization land with the whisper data table. Display
// reuses the interim on-screen message channel (UI/Notify.reds) until the
// lower-centre whisper overlay (Codeware UI) is built in M6.
//
// Topics let the city react to specific notable deeds the mod remembers, such as
// a gang boss V killed or V's MaxTac kills.

public func CBWhisperSpeaker(faction: CName) -> String {
  if Equals(faction, n"NCPD") {
    return "NCPD Officer";
  }
  if Equals(faction, n"") {
    return "Passerby";
  }
  return "Ganger";
}

public func CBWhisperLine(mood: CName, topic: CName) -> String {
  // Topic-specific lines take priority (spec §9.10 topic weighting).
  if Equals(topic, n"bossloss") {
    return "You put down one of our bosses. The crew doesn't forget that.";
  }
  if Equals(topic, n"maxtac") {
    return "That's the merc who went up against MaxTac and walked away.";
  }
  if Equals(topic, n"warning") {
    return "You've got a lot of nerve showing up here. Walk away while you still can.";
  }
  if Equals(mood, n"respect") {
    return "Now that's a merc worth knowing. Preem.";
  }
  if Equals(mood, n"hate") {
    return "You've got some nerve showing your face around here.";
  }
  // fear (default)
  return "Don't stare, choom. Just keep walking.";
}

public func CBShowWhisper(game: GameInstance, faction: CName, mood: CName, topic: CName) -> Void {
  CBShowMessage(game, CBWhisperSpeaker(faction) + ": " + CBWhisperLine(mood, topic), CBConfig.WhisperDurationSeconds());
}

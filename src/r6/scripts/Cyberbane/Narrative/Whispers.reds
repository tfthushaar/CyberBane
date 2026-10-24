// Cyberbane — Whispers (spec §9.10)
//
// Text-only overheard lines shown when a recognized NPC is near and V is notable.
// This is a seed set of English lines; the full (speaker, mood, tier, topic) pool
// from Appendix H and its localization land with the whisper data table. Display
// reuses the interim on-screen message channel (UI/Notify.reds) until the
// lower-centre whisper overlay (Codeware UI) is built in M6.

public func CBWhisperSpeaker(faction: CName) -> String {
  if Equals(faction, n"NCPD") {
    return "NCPD Officer";
  }
  if Equals(faction, n"") {
    return "Passerby";
  }
  return "Ganger";
}

public func CBWhisperLine(mood: CName) -> String {
  if Equals(mood, n"respect") {
    return "Now that's a merc worth knowing. Preem.";
  }
  if Equals(mood, n"hate") {
    return "You've got some nerve showing your face around here.";
  }
  // fear (default)
  return "Don't stare, choom. Just keep walking.";
}

public func CBShowWhisper(game: GameInstance, faction: CName, mood: CName) -> Void {
  CBShowMessage(game, CBWhisperSpeaker(faction) + ": " + CBWhisperLine(mood), CBConfig.WhisperDurationSeconds());
}

// Cyberbane - The words the player reads, looked up by key (2.7.1)
//
// "Could you please move all text-based UI elements into a localization file? That way, other developers would be able to
// localize your mod into other languages." Every line Cyberbane shows the player is a key now, with its English in
// Localization/en-us/English.reds and any other language in a package of the translator's own (Localization/CyberbaneLocalization.reds
// finds it by name). Log lines are not: they are for bug reports.
//
// Codeware puts every provider's texts into the game's own lookup, so the game's GetLocalizedTextByKey answers for ours from
// anywhere, with no game instance to hand: that is how Mod Settings has always shown Cyberbane's settings page. A key nobody
// defined comes back empty from the game; it is shown as the key itself, so a missed one is easy to see and to report. The
// English defines every key (tools/check_loc.py fails the build otherwise), and a translation is laid over the English key by
// key, so in play a key only shows if something is badly wrong.
//
// Slots are numbered, {0} {1} and on, in the order the code passes them, and a translation may put them in any order or use
// one twice. Whatever fills a slot (a gang's name, a district, a number) is itself looked up where it comes from.

public func CBT(key: CName) -> String {
  let s = GetLocalizedTextByKey(key);
  if StrLen(s) > 0 {
    return s;
  }
  return NameToString(key);
}

// Text worked out once and kept (a title's name, a trait's), shown now: still a key if it was kept before the game's
// localization had loaded, so it is looked up again (2.7.2).
public func CBDisplay(kept: String) -> String {
  return StrBeginsWith(kept, "Cyberbane-") ? CBT(StringToName(kept)) : kept;
}

public func CBTf(key: CName, slots: array<String>) -> String {
  let out = CBT(key);
  let i = 0;
  let n = ArraySize(slots);
  while i < n {
    out = StrReplaceAll(out, "{" + IntToString(i) + "}", slots[i]);
    i += 1;
  }
  return out;
}

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

// A slot that opens a sentence starts it with a capital (2.7.7): "Heads up. the Tyger Claws just sent people your way."
// 207 English lines put a name or a gang straight after a full stop, and the gang's name carries its article in lower
// case, so it is done here, where every line is filled in, never line by line. Only a slot after a full stop, a question
// or an exclamation mark (a closing quote too) or a line break; the very start of a line is left alone, because notes
// start small on purpose ("Cyberbane: " goes in front of them). An ellipsis is a pause, not an end. Only a plain a to z
// is raised (CBCapFirst), so a language without capitals is left as it is.
public func CBTf(key: CName, slots: array<String>) -> String {
  let out = CBT(key);
  let i = 0;
  let n = ArraySize(slots);
  while i < n {
    let mark = "{" + IntToString(i) + "}";
    if StrContains(out, mark) {
      let capped = CBCapFirst(slots[i]);
      if NotEquals(capped, slots[i]) {
        out = CBTfCapAfter(out, mark, capped);
      }
      out = StrReplaceAll(out, mark, slots[i]);
    }
    i += 1;
  }
  return out;
}

func CBTfCapAfter(text: String, mark: String, capped: String) -> String {
  let out = text;
  // The ellipsis first, kept as it is under a marker no line uses, so ". " below never sees its last dot.
  out = StrReplaceAll(out, "... " + mark, "<CBEllipsis>" + mark);
  out = StrReplaceAll(out, ". " + mark, ". " + capped);
  out = StrReplaceAll(out, ".  " + mark, ".  " + capped);
  out = StrReplaceAll(out, "! " + mark, "! " + capped);
  out = StrReplaceAll(out, "? " + mark, "? " + capped);
  out = StrReplaceAll(out, ".\" " + mark, ".\" " + capped);
  out = StrReplaceAll(out, "!\" " + mark, "!\" " + capped);
  out = StrReplaceAll(out, "?\" " + mark, "?\" " + capped);
  out = StrReplaceAll(out, "\n" + mark, "\n" + capped);
  out = StrReplaceAll(out, "<CBEllipsis>" + mark, "... " + mark);
  return out;
}

// Cyberbane - The words the player reads, looked up by key
//
// Every line Cyberbane shows the player is a key now, with its English in Localization/en-us/English.reds and any other
// language in a package of the translator's own (Localization/CyberbaneLocalization.reds finds it by name). Log lines
// are not: they are for bug reports.

public func CBT(key: CName) -> String {
  let s = GetLocalizedTextByKey(key);
  if StrLen(s) > 0 {
    return s;
  }
  return NameToString(key);
}

// Text worked out once and kept (a title's name, a trait's), shown now: still a key if it was kept before the game's
// localization had loaded, so it is looked up again.
public func CBDisplay(kept: String) -> String {
  return StrBeginsWith(kept, "Cyberbane-") ? CBT(StringToName(kept)) : kept;
}

// A slot that opens a sentence starts it with a capital: "Heads up. the Tyger Claws just sent people your way." 207
// English lines put a name or a gang straight after a full stop, and the gang's name carries its article in lower case,
// so it is done here, where every line is filled in, never line by line.
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

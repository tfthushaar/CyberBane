// Cyberbane - Crew names and threads
//
// Names V gives crew members, stored as positions in CBCrewNameAlphabet like the crew's own name; an empty name gives
// back the one they came with. Also which phone thread each member texts from.

public class CBCrewGivenName {
  public persistent let member: Int32;
  public persistent let letters: array<Int32>;   // places in CBCrewNameAlphabet, one up
}

public class CBCrewNameBook extends ScriptableSystem {
  private persistent let m_names: array<ref<CBCrewGivenName>>;

  public static func Get(game: GameInstance) -> ref<CBCrewNameBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBCrewNameBook") as CBCrewNameBook : null;
  }

  // The name V gave them, or "" when V has not.
  public func NameOf(member: Int32) -> String {
    if member <= 0 {
      return "";
    }
    let a = CBCrewNameAlphabet();
    for n in this.m_names {
      if IsDefined(n) && n.member == member {
        let out = "";
        for c in n.letters {
          if c > 0 && c <= StrLen(a) {
            out += StrMid(a, c - 1, 1);
          }
        }
        return out;
      }
    }
    return "";
  }

  // Letters from the set only, at most CrewNameMaxLength, spaces at the ends trimmed. "" gives them back their own.
  public func SetName(member: Int32, text: String) -> Void {
    if member <= 0 {
      return;
    }
    let keep: array<ref<CBCrewGivenName>>;
    for n in this.m_names {
      if IsDefined(n) && n.member != member {
        ArrayPush(keep, n);
      }
    }
    let a = CBCrewNameAlphabet();
    let trimmed = CBCrewNameTrim(text);
    let given = new CBCrewGivenName();
    given.member = member;
    let i = 0;
    while i < StrLen(trimmed) && ArraySize(given.letters) < CBConfig.CrewNameMaxLength() {
      let at = StrFindFirst(a, StrMid(trimmed, i, 1));
      if at >= 0 {
        ArrayPush(given.letters, at + 1);
      }
      i += 1;
    }
    if ArraySize(given.letters) > 0 {
      ArrayPush(keep, given);
    }
    this.m_names = keep;
  }

  public func Clear() -> Void {
    ArrayClear(this.m_names);
  }
}

// The name V gave this member, or "".
public func CBCrewGivenNameOf(id: Int32) -> String {
  let nb = CBCrewNameBook.Get(GetGameInstance());
  return IsDefined(nb) ? nb.NameOf(id) : "";
}

// The first word of a name.
public func CBFirstWord(name: String) -> String {
  let space = StrFindFirst(name, " ");
  return space > 0 ? StrLeft(name, space) : name;
}

// Their name without a nickname, the one their own thread goes by for the whole session.
public func CBCrewThreadName(sys: ref<CyberbaneSystem>, m: ref<CBCrewMember>) -> String {
  if !IsDefined(m) {
    return CBCrewGroupSender(GetGameInstance());
  }
  let given = CBCrewGivenNameOf(m.id);
  return StrLen(given) > 0 ? given : CBCrewFullNameNicked(sys, m.kind, m.faction, m.rival, m.seed, false, m.seat);
}

// The crew's group chat: under the crew's name once V has given it one.
public func CBCrewGroupSender(game: GameInstance) -> String {
  let name = CBCrewNameOf(game);
  return StrLen(name) > 0 ? name : CBCrewSender();
}

// Whose own thread this is, or null.
public func CBCrewMemberOfThread(sys: ref<CyberbaneSystem>, book: ref<CBCrewBook>, name: String) -> ref<CBCrewMember> {
  if !IsDefined(book) || StrLen(name) == 0 {
    return null;
  }
  let i = 0;
  while i < book.Count() {
    let m = book.At(i);
    i += 1;
    if IsDefined(m) && Equals(CBCrewThreadName(sys, m), name) {
      return m;
    }
  }
  return null;
}

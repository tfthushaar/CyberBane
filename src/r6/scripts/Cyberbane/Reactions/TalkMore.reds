// Cyberbane - More to talk about
//
// The street knows what V is worth and who is paying for it (the bounty board, asked of anybody who talks), and it talks
// about what V has done lately: the crew's last war, a district the crew took, a Rival V put down. At home, one of V's
// crew has opinions about the others, by who each of them is.

public func CBTalkActAskWorth() -> Int32 = 66
public func CBTalkActCrewOther() -> Int32 = 67

// ---- What V is worth ----------------------------------------------------------------------------------------------

public func CBTalkWorthLine(t: ref<CBTalkTarget>) -> ref<CBTalkLine> {
  let l = CBTalkMakeLine(CBT(n"Cyberbane-TalkMore-AskWhatAmIWorth"), CBTalkActAskWorth(), t"ChoiceCaptionParts.BountyHuntIcon");
  l.said = IsDefined(t) && IsDefined(t.npc) && CBTalkDid(t.npc, CBTalkActAskWorth());
  return l;
}

public func CBTalkAnswerWorth(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, again: Bool) -> ref<CBTalkAnswer> {
  if again {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-ToldYouAlreadyThatSAll"), n"");
  }
  let price = CBBountyUp(game);
  if price <= 0 {
    return CBTalkSay(CBPick2(CBT(n"Cyberbane-TalkMore-WorthNothing1"), CBT(n"Cyberbane-TalkMore-WorthNothing2")), n"");
  }
  let hb = CBHuntBook.Get(game);
  let poster = IsDefined(hb) ? CBBountyPosterName(sys, game, hb.BountyBy()) : "";
  if StrLen(poster) == 0 {
    return CBTalkSay(CBTf(n"Cyberbane-TalkMore-WorthNoName", [s"\(price)"]), n"");
  }
  return CBTalkSay(CBPick2(CBTf(n"Cyberbane-TalkMore-Worth1", [s"\(price)", poster]), CBTf(n"Cyberbane-TalkMore-Worth2", [poster, s"\(price)"])), n"");
}

// ---- What happened lately ------------------------------------------------------------------------------------------

// The newest thing worth talking about from the last couple of game days, as somebody on the street says it; "" for none.
public func CBTalkRecentNews(sys: ref<CyberbaneSystem>, game: GameInstance) -> String {
  let now = CBGameSeconds(game);
  let best: ref<CBLogEntry>;
  for e in sys.GetLog() {
    if IsDefined(e) && now - e.at <= CBConfig.TalkNewsHours() * CBConfig.SecondsPerHour() && CBTalkNewsKind(e.kind)
       && (!IsDefined(best) || e.at > best.at) {
      best = e;
    }
  }
  if !IsDefined(best) {
    return "";
  }
  let line = CBHudLogLine(sys, best, now, true);
  return StrLen(line) > 0 ? CBTf(n"Cyberbane-TalkMore-Heard", [CBLowFirst(line)]) : "";
}

func CBTalkNewsKind(kind: CName) -> Bool {
  return Equals(kind, n"CrewWarWon") || Equals(kind, n"CrewWarLost") || Equals(kind, n"TurfTaken") || Equals(kind, n"RivalSlain")
      || Equals(kind, n"CrewFell") || Equals(kind, n"CrewJoined") || Equals(kind, n"Massacre") || Equals(kind, n"BossKill");
}

// ---- One of the crew on another ------------------------------------------------------------------------------------

// The member at home V is talking to, asked about one of the others: the one after the last asked about.
public func CBCrewOtherLine(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, m: ref<CBCrewMember>) -> ref<CBTalkLine> {
  let other = CBCrewOtherOf(game, m, IsDefined(t) && IsDefined(t.npc) ? t.npc.cbCrewAskTurn : 0);
  if !IsDefined(other) {
    return null;
  }
  return CBTalkMakeLine(CBTf(n"Cyberbane-TalkMore-AskAbout", [CBCrewFirst(sys, other)]), CBTalkActCrewOther(), t"ChoiceCaptionParts.TalkIcon");
}

func CBCrewOtherOf(game: GameInstance, m: ref<CBCrewMember>, turn: Int32) -> ref<CBCrewMember> {
  let book = CBCrewBook.Get(game);
  if !IsDefined(book) || !IsDefined(m) || book.Count() < 2 {
    return null;
  }
  let others: array<ref<CBCrewMember>>;
  let i = 0;
  while i < book.Count() {
    let o = book.At(i);
    if IsDefined(o) && o.id != m.id {
      ArrayPush(others, o);
    }
    i += 1;
  }
  return ArraySize(others) > 0 ? others[Abs(turn) % ArraySize(others)] : null;
}

// What they think of them, by who each of them is: two hotheads get on, the careful one does not trust a hothead, the old
// loyalties of a member from a gang the other's old gang hates show, money talks to money.
public func CBCrewOtherAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, m: ref<CBCrewMember>) -> ref<CBTalkAnswer> {
  let other = CBCrewOtherOf(game, m, IsDefined(t) && IsDefined(t.npc) ? t.npc.cbCrewAskTurn : 0);
  if !IsDefined(other) {
    return CBTalkSay("...", n"");
  }
  if IsDefined(t) && IsDefined(t.npc) {
    t.npc.cbCrewAskTurn += 1;
  }
  let name = CBCrewFirst(sys, other);
  let mine = CBCrewTemper(m);
  let theirs = CBCrewTemper(other);
  let line = "";
  if mine == theirs {
    line = CBTf(n"Cyberbane-TalkMore-OtherSame", [name]);
  } else {
    if mine == CBTemperCareful() && theirs == CBTemperHothead() {
      line = CBTf(n"Cyberbane-TalkMore-OtherCarefulOnHot", [name]);
    } else {
      if mine == CBTemperHothead() && theirs == CBTemperCareful() {
        line = CBTf(n"Cyberbane-TalkMore-OtherHotOnCareful", [name]);
      } else {
        if theirs == CBTemperMoney() {
          line = CBTf(n"Cyberbane-TalkMore-OtherOnMoney", [name]);
        } else {
          if theirs == CBTemperOldGang() && NotEquals(other.faction, n"") {
            line = CBTf(n"Cyberbane-TalkMore-OtherOnOldGang", [name, CBFactionLabel(other.faction)]);
          } else {
            line = CBTf(n"Cyberbane-TalkMore-OtherFine", [name]);
          }
        }
      }
    }
  }
  // What they have seen of them in a fight.
  if other.wins > m.wins + 3 {
    line += CBT(n"Cyberbane-TalkMore-OtherBetter");
  } else {
    if other.scars > 2 {
      line += CBT(n"Cyberbane-TalkMore-OtherScarred");
    }
  }
  return CBTalkSay(line, n"");
}

// Which of the others a member at home was last asked about: the next ask is about the next one.
@addField(ScriptedPuppet)
public let cbCrewAskTurn: Int32;

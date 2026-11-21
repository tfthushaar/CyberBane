// Cyberbane - Paying the street ([8], and the witness's end of [2], 2.3.1)
//
// Two things V can do with eddies or a hard look, in street talk, on top of what talk already sells:
//
//   Hush a witness. Somebody on their way to tell a gang (Reactions/Witnesses.reds) can be paid to forget
//   it, or leaned on. Lean wrong and they run straight there.
//
//   Pay somebody to keep watch. An ordinary person on the street, for a few in-game hours, in this district:
//   while V is here, anybody coming for V (a crew, an apex squad, a Rival) is seen sooner, so the warning
//   comes earlier (CBWarningTicks), and the watcher texts V when they spot them.
//
// Both go through talk's own lines and money (CBTalkTakeMoney), and the watch is kept in the street book so a
// save keeps it.

// Above 30, so talk's said-mask cannot mark them (CBBitValue gives no bit past 30). None of these needs it: the
// hush lines show only while that person is on their way to a gang, and the watch line only while no watch is on.
public func CBTalkActHushPay() -> Int32 = 31
public func CBTalkActHushLean() -> Int32 = 32
public func CBTalkActWatch() -> Int32 = 33

public func CBPayTheStreetOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBStreetTalkOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().payTheStreet);
}

func CBHushPrice(sys: ref<CyberbaneSystem>) -> Int32 {
  let score = IsDefined(sys) ? sys.GetScore() : null;
  let renown = IsDefined(score) ? score.GetRenown() : 0.0;
  // The more V's name is worth to a gang, the more the witness asks.
  return RoundF(CBConfig.HushBasePrice() + CBConfig.HushPerRenown() * renown);
}

func CBWatchPrice() -> Int32 {
  return CBConfig.WatchPrice();
}

// Is a watch on in this district right now?
public func CBWatchedHere(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  let book = CBStreetBook.Get(game);
  if !CBPayTheStreetOn() || !IsDefined(sys) || !IsDefined(book) {
    return false;
  }
  let here = sys.GetCurrentDistrict();
  let now = CBGameSeconds(game);
  return NotEquals(here, n"") && Equals(book.WatchDistrict(), here) && now < book.WatchUntil();
}

// The lines this person adds to the first list, if any.
public func CBStreetPayLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  if !CBPayTheStreetOn() || !IsDefined(t) || !IsDefined(t.npc) || t.cop {
    return out;
  }
  if (CBIsTeller(game, t.npc) || CBIsLookout(t.npc)) && !t.npc.cbWitnessHushed {
    let price = CBHushPrice(sys);
    let pay = CBTalkMakeLine(s"[Pay] \(price)eb. You didn't see anything.", CBTalkActHushPay(), t"ChoiceCaptionParts.PayIcon");
    pay.inactive = CBTalkMoney(game) < price;
    pay.important = true;
    ArrayPush(out, pay);
    let body = CBTalkStat(game, gamedataStatType.Strength) >= CBConfig.TalkAttributeCheck();
    ArrayPush(out, CBTalkMakeLine((body ? "[Body] " : "[Intimidate] ") + "Nobody hears about this. Understand?",
                                  CBTalkActHushLean(), t"ChoiceCaptionParts.GrappleIcon"));
    return out;
  }
  // A watcher is somebody off the street with no gang to answer to.
  if Equals(t.faction, n"") && t.mood != CBTalkHostile() && !CBWatchedHere(sys, game)
     && !CBTalkDid(t.npc, CBTalkActWatch()) {
    let price = CBWatchPrice();
    let w = CBTalkMakeLine(s"[Pay] \(price)eb. Keep an eye out for me.", CBTalkActWatch(), t"ChoiceCaptionParts.PayIcon");
    w.inactive = CBTalkMoney(game) < price;
    ArrayPush(out, w);
  }
  return out;
}

// What they say, and what it does.
public func CBStreetPayAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                              t: ref<CBTalkTarget>, choice: Int32) -> ref<CBTalkAnswer> {
  let npc = t.npc;
  if choice == CBTalkActHushPay() {
    if !CBIsTeller(game, npc) && !CBIsLookout(npc) {
      return CBTalkSay("Already told you. I saw nothing.", n"");
    }
    if !CBTalkTakeMoney(game, player, CBHushPrice(sys)) {
      return CBTalkSay(CBPick2("That's not enough to forget a face.", "Come back with the eddies. Or don't."), n"");
    }
    npc.cbWitnessHushed = true;
    CBFileLog(sys, n"WitnessHushed", CBGameSeconds(game), CBEventDistrict(sys, game), n"", 0.0);
    return CBTalkSay(CBPick4("Saw what? I was looking at my phone.", "Never seen you before in my life.",
                             "Eddies spend the same as gang money. Better, even.", "I've got a bad memory. Always have."), n"");
  }
  if choice == CBTalkActHushLean() {
    if !CBIsTeller(game, npc) && !CBIsLookout(npc) {
      return CBTalkSay("I'm not saying anything to anybody!", n"fear_beg");
    }
    let chance = CBTalkNerveGap(t) * CBConfig.TalkIntimidateScale() + CBConfig.TalkIntimidateBase() + CBConfig.HushLeanBonus();
    if CBTalkStat(game, gamedataStatType.Strength) >= CBConfig.TalkAttributeCheck() {
      chance += CBConfig.TalkAttributeBonus();
    }
    chance = ClampF(chance * sys.WornPerk().breakMult, CBConfig.TalkIntimidateMin(), CBConfig.TalkIntimidateMax());
    if RandF() < chance {
      npc.cbWitnessHushed = true;
      return CBTalkSay(CBPick4("Okay! Okay. I didn't see a thing.", "I swear, I'm not telling anybody.",
                               "Please. I've got kids. I saw nothing.", "Understood. Understood!"), n"fear_beg");
    }
    // They bolt: whoever they were going to tell hears now.
    let book = CBStreetBook.Get(game);
    if IsDefined(book) && CBIsTeller(game, npc) {
      book.tellerTick = sys.GetTickCount() - CBConfig.WitnessTellTicks();
    }
    // A lookout runs to report V straight away (Spawn/Hunted.reds, [50]).
    if CBIsLookout(npc) {
      sys.SetTurfWatch(npc.cbLookoutFor, sys.GetTickCount() - CBConfig.TurfLingerTicks());
    }
    return CBTalkSay(CBPick3("Get away from me! They'll hear about this!", "You don't scare me. They will.",
                             "Touch me and everybody hears it twice as fast."), n"bump");
  }
  if choice == CBTalkActWatch() {
    let price = CBWatchPrice();
    let book = CBStreetBook.Get(game);
    if !IsDefined(book) || !CBTalkTakeMoney(game, player, price) {
      return CBTalkSay(CBPick2("Eyes cost money, choom.", "Come back when you can pay."), n"");
    }
    let now = CBGameSeconds(game);
    book.SetWatch(sys.GetCurrentDistrict(), now + CBConfig.WatchHours() * CBConfig.SecondsPerHour(), CBTalkSpeakerName(t));
    CBFileLog(sys, n"KeepWatch", now, CBEventDistrict(sys, game), n"", Cast<Float>(price));
    let hours = RoundF(CBConfig.WatchHours());
    return CBTalkSay(CBPick3(s"Deal. Anybody comes looking for you round here in the next \(hours) hours, you'll hear it from me first.",
                             "I see everything on this block anyway. Now you'll see it too.",
                             "You got it. I'll text you the second somebody bad turns the corner."), n"");
  }
  return null;
}

// Who V paid, as their messages will be signed.
func CBTalkSpeakerName(t: ref<CBTalkTarget>) -> String {
  return StrLen(t.speaker) > 0 ? t.speaker : "Lookout";
}

// More warning when somebody is watching for V here.
public func CBWatchExtraTicks() -> Int32 {
  let game = GetGameInstance();
  return CBWatchedHere(CyberbaneSystem.Get(game), game) ? CBConfig.WatchExtraTicks() : 0;
}

// The watcher saw them coming. Beside the gang's own warning and the ally's (CBCrewWarning, CBApexOnTheWay,
// CBRivalWarning in Spawn/Hunt.reds).
public func CBWatcherTipOff(sys: ref<CyberbaneSystem>, game: GameInstance, who: String) -> Bool {
  if !CBToastsOn() || !CBWatchedHere(sys, game) {
    return false;
  }
  let book = CBStreetBook.Get(game);
  let name = StrLen(book.WatchName()) > 0 ? book.WatchName() : "Lookout";
  let coming = StrLen(who) > 0 ? who : "Trouble";
  CBPhoneSend(game, name, CBPick4(
    coming + " just turned onto the block. Looking for you.",
    "Heads up. " + coming + ", headed your way.",
    "You paid me to watch. I'm watching " + coming + " walk right up to you. Move.",
    "Saw " + coming + " asking about you two minutes ago. Thought you'd want to know."));
  return true;
}

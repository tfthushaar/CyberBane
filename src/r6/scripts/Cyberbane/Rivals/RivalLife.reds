// Cyberbane - Rivals with a life (1.9.9)
//
// A Rival is a person with a history with V, and this is what makes them act like one:
//
//   A catchphrase   one line of their own, from how they came to be V's Rival and what they are like,
//                   said when they arrive, in their texts and on their page. Derived from the id.
//   The street's word on them   their page says where they are the way the street would.
//   The announcement   when a Rival's people find V, somebody names them in the subtitles first: who
//                   they are, what they survived, and the Rival's own line.
//   Mercy           V decides. A Rival put down alive is spared when V holsters or walks away; killed if
//                   V finishes them; and can be talked to where they lie: let them go, make them pay with
//                   a name, or run them out of Night City (Reactions/CombatFlee.reds, Reactions/StreetTalk.reds).
//   Kin             the one who steps into a slain Rival's place is sometimes family: the same surname,
//                   geared against what killed them, and they say so.
//   Send word       a Rival can be called out from the Hub, and a Rival may call V out instead of hunting:
//                   they name a place and wait there, ready, with more of their people. Finishing it there
//                   pays more.
//   Bodyguards      a lieutenant or leader waiting at their place has their people with them. Each one V
//                   drops before them costs the Rival some of their nerve, and they say so.
//
// Saves: kin links and words sent are the playthrough's (CBIntelBook, Reactions/StreetIntel.reds); the
// rest is derived or session.

public func CBMercyChoiceOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().mercyChoice;
}

public func CBSendWordOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return CBHideoutsOn() && (!IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().sendWord);
}

// ---- A catchphrase ---------------------------------------------------------------------------------------

public func CBRivalCatchphrase(r: ref<CBRival>) -> String {
  if !IsDefined(r) {
    return "";
  }
  if CBRivalHasTrait(r, n"Broken") {
    return CBRivalPhrase(r, "The voices know your name.", "Can't stop. Won't stop. Hear it?", "Everything's so loud. You first.");
  }
  if r.source == EnumInt(ECBRivalSource.Avenger) {
    return CBRivalPhrase(r, "Blood pays for blood.", "I carry them with me. Every step.", "You took one of ours. I'm taking you.");
  }
  if r.source == EnumInt(ECBRivalSource.Spared) || r.sparedByV > 0 {
    return CBRivalPhrase(r, "You should have finished it.", "Mercy's the last mistake you'll make.", "I woke up. You won't.");
  }
  if r.killedV > 0 {
    return CBRivalPhrase(r, "Lie down. You know how this goes.", "Again? Fine. Same ending.", "I've done this before.");
  }
  if CBRivalHasTrait(r, n"Confident") || CBRivalHasTrait(r, n"PackLeader") {
    return CBRivalPhrase(r, "Nobody walks away from me twice.", "My street. My rules. My kill.", "You're just a story they tell. I'm the ending.");
  }
  if CBRivalHasTrait(r, n"Scarred") || r.escapes > 0 {
    return CBRivalPhrase(r, "Still breathing. Bet that bugs you.", "Every scar's a promise.", "I keep coming back. You keep running out of luck.");
  }
  return CBRivalPhrase(r, "Nothing personal. Just business.", "Night City's too small for both of us.", "You made it personal.");
}

func CBRivalPhrase(r: ref<CBRival>, a: String, b: String, c: String) -> String {
  let k = CBHashIndex(r.id, 61, 3);
  if k == 0 {
    return a;
  }
  return k == 1 ? b : c;
}

// ---- The street's word on them ---------------------------------------------------------------------------

public func CBRivalStreetStatus(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> String {
  if !IsDefined(r) {
    return "";
  }
  let book = CBIntelBook.Get(game);
  if IsDefined(book) && book.WordSent(r.id) {
    return "Waiting for you at their place, ready. The street knows you called them out.";
  }
  if r.state == EnumInt(ECBRivalState.Debtor) {
    return "Owes you their life, and knows it. Keeps their head down.";
  }
  if r.state == EnumInt(ECBRivalState.Retired) {
    return "Left Night City. Nobody expects them back.";
  }
  if r.state == EnumInt(ECBRivalState.Slain) {
    return "Dead. People still talk about how.";
  }
  if r.state == EnumInt(ECBRivalState.Dormant) {
    return "Gone quiet. Nobody's seen them in a while.";
  }
  if r.id == sys.GetActiveRivalId() || r.state == EnumInt(ECBRivalState.Hunting) {
    return "Out looking for you. Asking everybody where you sleep.";
  }
  if r.id == sys.GetLaneRivalId(CBLaneRival()) {
    return "Getting their people together. You'll hear from them soon.";
  }
  if r.huntTicks > 0 {
    let hours = Max(1, r.huntTicks / 150);
    return s"Licking their wounds. Back in maybe \(hours) hours.";
  }
  return "Around. Keeping their ears open for your name.";
}

// ---- The announcement -------------------------------------------------------------------------------------

public class CBAnnounceCallback extends DelayCallback {
  public let game: GameInstance;
  public let speaker: String;
  public let line: String;

  public func Call() -> Void {
    if CBWorldStable(this.game) {
      CBIntelSay(this.game, 3, this.speaker, this.line, 3.5);
    }
  }
}

func CBAnnounceLater(game: GameInstance, speaker: String, line: String, delay: Float) -> Void {
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) || StrLen(line) == 0 {
    return;
  }
  let cb = new CBAnnounceCallback();
  cb.game = game;
  cb.speaker = speaker;
  cb.line = line;
  ds.DelayCallback(cb, delay, false);
}

// When the Rival's people find V: one of them names the Rival, then the Rival says their line. Words only,
// in the game's subtitles; the fight is whatever it already is.
public func CBRivalAnnounce(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  if !IsDefined(r) || !CBMessagesOn() {
    return;
  }
  let content = sys.GetContent();
  let name = CBRivalDisplayName(content, r);
  let crew = CBIntelSpeaker(r.faction);
  let who = "That's them!";
  if r.killedV > 0 {
    who = s"That's the one \(name) put down before!";
  } else {
    if r.escapes > 0 || r.sparedByV > 0 {
      who = s"That's them. The one \(name) walked away from.";
    } else {
      if r.source == EnumInt(ECBRivalSource.Avenger) {
        who = s"That's who did it. \(name) wants them.";
      }
    }
  }
  CBAnnounceLater(game, crew, who, 0.3);
  CBAnnounceLater(game, name, CBRivalCatchphrase(r), 3.2);
}

// ---- Kin ------------------------------------------------------------------------------------------------

// What a relative brings against how their family member died (the marks V left on them).
public func CBKinTrait(scarMask: Int32) -> CName {
  if CBMaskHas(scarMask, CBScarFried()) {
    return n"ChromedOut";
  }
  if CBMaskHas(scarMask, CBScarBurned()) {
    return n"Tough";
  }
  if CBMaskHas(scarMask, CBScarCut()) {
    return n"Quick";
  }
  return n"Armored";
}

// ---- Send word, and the call-out --------------------------------------------------------------------------

// They name a place near V and wait there, ready (the hideout machinery, Rivals/Whereabouts.reds). V
// called them out from the Hub, or they called V out instead of coming. False when they cannot be put
// anywhere or are out already.
public func CBSendWord(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, calledOut: Bool) -> Bool {
  let book = CBIntelBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(r) || !IsDefined(book) || !IsDefined(player) || !CBSendWordOn() || CBWhereaboutsForSale(sys, game, r) != 0 {
    return false;
  }
  let s = CBRivalHideout(sys, game, player, r);
  if !IsDefined(s) {
    if !calledOut {
      CBSystemNote(game, "nowhere near here they would agree to meet. Try somewhere else.", 5.0);
    }
    return false;
  }
  let now = CBGameSeconds(game);
  CBMarkLeadTold(sys, s, n"", now);
  book.SendWord(r.id);
  if sys.GetLaneRivalId(CBLaneRival()) == r.id {
    sys.ClearLane(CBLaneRival());
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let place = CBPlacePhrase(s.district);
  let pin = CBMapMarkersOn() ? " It's on your map." : "";
  let line = calledOut ? s"You and me. \(CBCapFirst(place)). I'll be waiting.\(pin) \(CBRivalCatchphrase(r))"
                       : s"Got your message. \(CBCapFirst(place)). Come and try.\(pin) \(CBRivalCatchphrase(r))";
  CBPhoneSendTinted(game, name, line, CBHudRed());
  CBFileLog(sys, calledOut ? n"CalledOut" : n"WordSent", now, CBEventDistrict(sys, game), r.faction, Cast<Float>(r.id));
  CBLog.Info(n"Rivals", s"Rival \(r.id) is waiting at their place (\(calledOut ? "they called V out" : "V sent word")).");
  return true;
}

// A Rival taking their turn calls V out instead, now and then: never the first time they come, and only
// somebody with a name to defend.
public func CBRivalMayCallOut(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(r) || !CBSendWordOn() || r.rank < 2 || r.encounters == 0 || RandF() >= CBConfig.CallOutChance() {
    return false;
  }
  return CBSendWord(sys, game, r, true);
}

// Finished it at the place they named: the street hears it, and it pays more.
public func CBWordKept(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  let book = CBIntelBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !book.WordSent(r.id) {
    return;
  }
  book.ClearWord(r.id);
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints((25.0 + 10.0 * Cast<Float>(r.rank)) * CBConfig.WordKeptRenownShare() * mult);
  CBTalkFear(sys, game, r.faction, CBConfig.WordKeptFear());
  if CBMessagesOn() {
    CBHearsayFromStreet(game, s"They named the place, and you went. \(CBRivalDisplayName(sys.GetContent(), r)) didn't walk away from it.", n"");
  }
}

// ---- Bodyguards ------------------------------------------------------------------------------------------

// Somebody senior waiting at their place has their people round them: one for a lieutenant, two for a
// leader, one more when they are expecting V. Put near them the way the Rival was put, and set up the same
// (CB_Lair: hostile, no orders, cleared with the place).
public func CBLairGuards(sys: ref<CyberbaneSystem>, game: GameInstance, des: ref<DynamicEntitySystem>, r: ref<CBRival>, at: Vector4) -> Void {
  let book = CBIntelBook.Get(game);
  let count = 0;
  if r.rank >= CBConfig.LeaderMinRank() {
    count = 2;
  } else {
    if r.rank >= CBConfig.LieutenantMinRank() {
      count = 1;
    }
  }
  if IsDefined(book) && book.WordSent(r.id) {
    count += 1;
  }
  count = Min(count, CBSpawnRoom(game) - 1);
  let fs = sys.FindFaction(r.faction);
  let intel = CBStreetIntelFor(game);
  if count <= 0 || !IsDefined(fs) || !TDBID.IsValid(fs.sampleRecord) || !IsDefined(intel) {
    return;
  }
  intel.ClearGuards();
  let k = 0;
  let placed = 0;
  while k < 6 && placed < count {
    let ang = Cast<Float>(k) * 1.0472 + 0.3;
    k += 1;
    let snapped: Vector4;
    let spot: Vector4;
    if CBNavSnap(game, at.X + CosF(ang) * 2.6, at.Y + SinF(ang) * 2.6, at.Z, snapped) && CBSettleOnGround(game, snapped, spot) {
      let facing = Quaternion.BuildFromDirectionVector(new Vector4(CosF(ang), SinF(ang), 0.0, 0.0));
      let gid: EntityID;
      if CBCreateSpawn(des, fs.sampleRecord, n"", spot, facing, n"CB_Lair", gid) {
        intel.NoteGuard(gid, r.id);
        placed += 1;
      }
    }
  }
  if placed > 0 {
    CBLog.Info(n"Rivals", s"Rival \(r.id) has \(placed) of their people with them.");
  }
}

// ---- Mercy, where they lie (the lines; Reactions/StreetTalk.reds carries the conversation) -------------------

public func CBTalkActSpare() -> Int32 = 27
public func CBTalkActCollect() -> Int32 = 28
public func CBTalkActExile() -> Int32 = 29

@addField(ScriptedPuppet)
public let cbMercyOpen: Bool;

public func CBRivalMercyLines(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>) -> array<ref<CBTalkLine>> {
  let out: array<ref<CBTalkLine>>;
  let s = CBTalkMakeLine("[Spare] Walk away. Next time I won't stop.", CBTalkActSpare(), t"ChoiceCaptionParts.HandshakeIcon");
  ArrayPush(out, s);
  let other = CBTalkRivalForFaction(sys, game, n"", t.rivalId);
  if IsDefined(other) {
    let c = CBTalkMakeLine("[Collect] You owe me your life. Where's " + CBRivalDisplayName(sys.GetContent(), other) + "?",
                           CBTalkActCollect(), t"ChoiceCaptionParts.BountyHuntIcon");
    c.important = true;
    ArrayPush(out, c);
  }
  ArrayPush(out, CBTalkMakeLine("[Exile] Leave Night City. Tonight. Don't come back.", CBTalkActExile(), t"ChoiceCaptionParts.BackOutIcon"));
  ArrayPush(out, CBTalkMakeLine("[Leave] Think about it.", CBTalkActLeave(), TDBID.None()));
  return out;
}

// What they say, and the mercy decided: the escapee record is settled by the mercy path on its next pass.
public func CBRivalMercyAnswer(sys: ref<CyberbaneSystem>, game: GameInstance, player: ref<PlayerPuppet>,
                               t: ref<CBTalkTarget>, choice: Int32) -> ref<CBTalkAnswer> {
  let r = sys.FindRivalById(t.rivalId);
  let e = IsDefined(t.npc) ? sys.FindEscapee(t.npc.GetEntityID()) : null;
  if !IsDefined(r) || !IsDefined(e) {
    return CBTalkSay("...", n"");
  }
  if IsDefined(t.npc) {
    t.npc.cbTalkSent = true;   // it is over, whatever was said
    t.npc.cbMercyOpen = false;
  }
  if choice == CBTalkActExile() {
    let chance = CBConfig.ExileBase() - 0.15 * Cast<Float>(r.rank - 1);
    if CBRivalHasTrait(r, n"Shaken") {
      chance += 0.2;
    }
    if CBRivalHasTrait(r, n"HardToScare") || CBRivalHasTrait(r, n"Broken") {
      chance = 0.0;
    }
    e.mercyChosen = true;
    if RandF() < chance {
      e.exiled = true;
      return CBTalkSay(CBWhisperPick2("Okay. Okay. I'm gone. You'll never see me again.", "Fine. Night City's yours. I'm done."), n"");
    }
    CBRivalGiveTrait(r, n"Humiliated");
    return CBTalkSay(CBWhisperPick2("This is my city. I'll crawl back if I have to.", "Run? From you? Never."), n"");
  }
  e.mercyChosen = true;
  if choice == CBTalkActCollect() {
    let i = CBIntelGive(sys, game, player, n"", true, r.id);
    if i.kind == CBIntelNone() {
      return CBTalkSay("I don't know anything worth my life. I swear.", n"");
    }
    return CBTalkSay(CBIntelSpoken(i) + " We're even.", n"");
  }
  return CBTalkSay(CBWhisperPick2(s"...I won't forget this. \(CBRivalCatchphrase(r))", "Why? ...Doesn't matter. I owe you."), n"");
}

// Cyberbane - The web of gangs ([H1], 2.4.3)
//
// The Factions page as a picture: V in the middle, the eleven gangs round V placed roughly where they live, so the
// ring reads as a rough Night City (Maelstrom and the Claws at the top for Watson and Westbrook, the Valentinos and
// 6th Street lower middle for Heywood and Santo Domingo, the Animals, the Voodoo Boys and Barghest lower left for
// Pacifica and Dogtown, the Wraiths and the Aldecaldos to the right for the Badlands), the corporations and the NCPD
// in a small row beneath with V's lines only. A switch on the page goes between this and the list; the Hub remembers
// which for the session.
//
//   V's line to a gang   by how they treat V: thick green Allied, green Friendly, thin grey Neutral, amber Hostile,
//                        thick red Vendetta; with a word for what is live on it (OPEN SEASON, TRACKER, BACKED, PEACE
//                        PAID, SAFE PASSAGE, PAY UP, A PRICE ON YOU)
//   between two gangs    red at war now (a challenger for a district the other holds), dim red the standing feud,
//                        cyan a truce against V, amber where V set one on the other, bright red a clash in the street
//                        today
//   a gang's box         name, how they treat V and the standing, streets held, the leader, and two bars: manpower
//                        and the war chest
//
// Drawn in the Hub's own canvas (UI/Hud.reds, BuildWeb and RenderWeb): nothing is put into the game's menus, so the
// crash rule for UI stands. A line is a thin rectangle turned about its left end (SetRenderTransformPivot,
// SetRotation in degrees, clockwise on screen, as the game's own photo-mode stickers turn), both on 2.31 and 2.5.
// Everything here is a read of a book that already exists; no saved data, no per-frame work.

public func CBWebSlotCount() -> Int32 = 16
public func CBWebLinePool() -> Int32 = 64
public func CBWebWordPool() -> Int32 = 14
public func CBWebHeight() -> Float = 440.0
// The web and the two maps are drawn taller: each has one button at most, and it moves down beside the words under
// the picture (CBHud.PlaceActions). The tree and the crew keep 440, so their four buttons stay above the footer.
public func CBWebTallHeight() -> Float = 500.0
// Boxes and type sized to read from a sofa (2.5.0): the first pictures were 16 to 20 px names and 11 px lines at 1080p.
public func CBWebGangW() -> Float = 220.0
public func CBWebGangH() -> Float = 92.0
public func CBWebSmallW() -> Float = 190.0
public func CBWebSmallH() -> Float = 56.0
public func CBWebVW() -> Float = 150.0
public func CBWebVH() -> Float = 80.0
// The pictures' type: a box's name, its line, its third line, V's own, the words on lines; and the least each may be
// drawn at before it is shortened (CBHud.BoxText).
public func CBPicName() -> Int32 = 26
public func CBPicLine() -> Int32 = 21
public func CBPicLead() -> Int32 = 18
public func CBPicV() -> Int32 = 34
public func CBPicSmallName() -> Int32 = 21
public func CBPicSmallLine() -> Int32 = 17
public func CBPicWord() -> Int32 = 18
public func CBPicNameLeast() -> Int32 = 17
public func CBPicLineLeast() -> Int32 = 16
public func CBPicLeadLeast() -> Int32 = 15
public func CBHudWebToggleName() -> CName = n"cbHubWebToggle"

// Who is in each place: 0 is V, 1 to 11 the gangs, 12 to 15 the corporations and the law.
public func CBWebSlotGang(i: Int32) -> CName {
  switch i {
    case 1: return n"Maelstrom";
    case 2: return n"TygerClaws";
    case 3: return n"Mox";
    case 4: return n"Scavengers";
    case 5: return n"VoodooBoys";
    case 6: return n"Animals";
    case 7: return n"Barghest";
    case 8: return n"Valentinos";
    case 9: return n"SixthStreet";
    case 10: return n"Wraiths";
    case 11: return n"Aldecaldos";
    case 12: return n"Arasaka";
    case 13: return n"Militech";
    case 14: return n"KangTao";
    case 15: return n"NCPD";
    default: return n"";
  }
}

public func CBWebSlotIsGang(i: Int32) -> Bool = i >= 1 && i <= 11

// Top left of each place, in the page's design units, inside the web's own area.
public func CBWebSlotX(i: Int32) -> Float {
  switch i {
    case 0: return 585.0;
    case 1: return 300.0;
    case 2: return 550.0;
    case 3: return 800.0;
    case 4: return 40.0;
    case 5: return 40.0;
    case 6: return 300.0;
    case 7: return 40.0;
    case 8: return 550.0;
    case 9: return 800.0;
    case 10: return 1060.0;
    case 11: return 1060.0;
    case 12: return 275.0;
    case 13: return 485.0;
    case 14: return 695.0;
    case 15: return 905.0;
    default: return 0.0;
  }
}

public func CBWebSlotY(i: Int32) -> Float {
  switch i {
    case 0: return 170.0;
    case 1: return 0.0;
    case 2: return 0.0;
    case 3: return 0.0;
    case 4: return 120.0;
    case 5: return 230.0;
    case 6: return 340.0;
    case 7: return 340.0;
    case 8: return 340.0;
    case 9: return 340.0;
    case 10: return 140.0;
    case 11: return 290.0;
    default: return 444.0;
  }
}

public func CBWebSlotW(i: Int32) -> Float {
  if i == 0 {
    return CBWebVW();
  }
  return CBWebSlotIsGang(i) ? CBWebGangW() : CBWebSmallW();
}

public func CBWebSlotH(i: Int32) -> Float {
  if i == 0 {
    return CBWebVH();
  }
  return CBWebSlotIsGang(i) ? CBWebGangH() : CBWebSmallH();
}

public func CBWebCentreX(i: Int32) -> Float = CBWebSlotX(i) + CBWebSlotW(i) / 2.0
public func CBWebCentreY(i: Int32) -> Float = CBWebSlotY(i) + CBWebSlotH(i) / 2.0

// Round the ring for keys and the pad: the eleven gangs in order, then the four below.
public func CBWebNextSlot(i: Int32, step: Int32) -> Int32 {
  let n = CBWebSlotCount() - 1;
  let at = i < 1 ? 0 : i - 1;
  return ((at + step) % n + n) % n + 1;
}

public func CBWebSlotOf(gang: CName) -> Int32 {
  let i = 1;
  while i < CBWebSlotCount() {
    if Equals(CBWebSlotGang(i), gang) {
      return i;
    }
    i += 1;
  }
  return -1;
}

// ---- V's lines -------------------------------------------------------------------------------------------------

public func CBWebPostureColour(posture: ECBPosture) -> HDRColor {
  if Equals(posture, ECBPosture.Vendetta) {
    return CBHudRed();
  }
  if Equals(posture, ECBPosture.Hostile) {
    return CBHudAmber();
  }
  if Equals(posture, ECBPosture.Friendly) || Equals(posture, ECBPosture.Allied) {
    return CBHudGreen();
  }
  return CBHudGrey();
}

public func CBWebPostureThickness(posture: ECBPosture) -> Float {
  if Equals(posture, ECBPosture.Vendetta) || Equals(posture, ECBPosture.Allied) {
    return 6.0;
  }
  if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Friendly) {
    return 4.0;
  }
  return 2.0;
}

// The word on V's line to this gang: what is live between them, the most pressing first, or "".
public func CBWebVWord(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  if CBOpenSeasonFor(game, gang) {
    return "OPEN SEASON";
  }
  if Equals(CBTrackerGang(game), gang) {
    return "TRACKER";
  }
  let book = CBHuntBook.Get(game);
  if IsDefined(book) && CBBountyUp(game) > 0 && Equals(CBBountyGang(sys, book.BountyBy()), gang) {
    return "A PRICE ON YOU";
  }
  let war = CBWarBook.Get(game);
  let now = CBGameSeconds(game);
  if IsDefined(war) && Equals(gang, n"TygerClaws") && war.ProtectDue() > now {
    return "PAY UP";
  }
  if IsDefined(war) && CBBackingOn() && Equals(war.Backed(), gang) {
    return "BACKED";
  }
  if sys.TollActive(gang, now) {
    return "SAFE PASSAGE";
  }
  let fs = sys.FindFaction(gang);
  if IsDefined(fs) && fs.lastPeaceAt > 0.0 && now - fs.lastPeaceAt < CBConfig.WebPeaceDays() * CBConfig.SecondsPerDay() {
    return "PEACE PAID";
  }
  return "";
}

// ---- Between two gangs -------------------------------------------------------------------------------------------

public func CBWebPairNone() -> Int32 = 0
public func CBWebPairFeud() -> Int32 = 1
public func CBWebPairWar() -> Int32 = 2
public func CBWebPairTruce() -> Int32 = 3
public func CBWebPairIncite() -> Int32 = 4
public func CBWebPairClash() -> Int32 = 5

// What is between two gangs now, the liveliest first.
public func CBWebPair(sys: ref<CyberbaneSystem>, game: GameInstance, a: CName, b: CName) -> Int32 {
  let now = CBGameSeconds(game);
  let war = CBWarBook.Get(game);
  if CBRecentClash(game, a, b) {
    return CBWebPairClash();
  }
  if IsDefined(war) && CBCommonEnemyOn() && (Equals(war.TruceWith(a, now), b) || Equals(war.TruceWith(b, now), a)) {
    return CBWebPairTruce();
  }
  if IsDefined(war) && now < war.InciteUntil()
     && ((Equals(war.InciteA(), a) && Equals(war.InciteB(), b)) || (Equals(war.InciteA(), b) && Equals(war.InciteB(), a))) {
    return CBWebPairIncite();
  }
  if CBWebAtWar(sys, game, a, b) {
    return CBWebPairWar();
  }
  // Each list in a local of its own before it is searched: ArrayContains handed a function's result, inside ||, took
  // the gang's name for an address and crashed the game as the Gangs page opened (2.5.0). Never a temporary.
  let content = sys.GetContent();
  if !IsDefined(content) {
    return CBWebPairNone();
  }
  let rivalsOfA = CBGangRivalsOf(content, a);
  let rivalsOfB = CBGangRivalsOf(content, b);
  let feud = ArrayContains(rivalsOfA, b);
  if !feud {
    feud = ArrayContains(rivalsOfB, a);
  }
  return feud ? CBWebPairFeud() : CBWebPairNone();
}

// One of them is challenging for a district the other holds.
public func CBWebAtWar(sys: ref<CyberbaneSystem>, game: GameInstance, a: CName, b: CName) -> Bool {
  let turf = CBTurfBook.Get(game);
  if !IsDefined(turf) || !CBTurfWarsOn() {
    return false;
  }
  let i = 0;
  while i < CBDistrictCount() {
    let holder = CBTurfHolder(sys, game, CBDistrictAt(i));
    let challenger = turf.Challenger(i);
    if (Equals(holder, a) && Equals(challenger, b)) || (Equals(holder, b) && Equals(challenger, a)) {
      return true;
    }
    i += 1;
  }
  return false;
}

public func CBWebPairColour(kind: Int32) -> HDRColor {
  if kind == CBWebPairClash() {
    return new HDRColor(1.0, 0.36, 0.36, 1.0);
  }
  if kind == CBWebPairTruce() {
    return CBHudCyan();
  }
  if kind == CBWebPairIncite() {
    return CBHudAmber();
  }
  return CBHudRed();
}

public func CBWebPairOpacity(kind: Int32) -> Float {
  return kind == CBWebPairFeud() ? 0.3 : 1.0;
}

public func CBWebPairThickness(kind: Int32) -> Float {
  if kind == CBWebPairFeud() {
    return 2.0;
  }
  return kind == CBWebPairClash() ? 5.0 : 4.0;
}

public func CBWebPairWord(kind: Int32) -> String {
  if kind == CBWebPairClash() {
    return "CLASHED";
  }
  if kind == CBWebPairTruce() {
    return "TRUCE";
  }
  if kind == CBWebPairIncite() {
    return "SET ON";
  }
  return kind == CBWebPairWar() ? "AT WAR" : "";
}

// ---- What a gang's box and the page below say --------------------------------------------------------------------

public func CBWebBoxLine(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  if !CBFactionOn(gang) {
    return "OFF";
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return "";
  }
  // One word (2.5.0): the standing's number, the streets held and the leader are in the panel under the picture,
  // where the gang's box sent them as three lines of 11 px text.
  let out = StrUpper(CBPostureName(score.GetPosture(gang)));
  return out;
}

public func CBWebLeader(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  let fs = sys.FindFaction(gang);
  let r = IsDefined(fs) && fs.leaderRivalId > 0 ? sys.FindRivalById(fs.leaderRivalId) : null;
  return IsDefined(r) && CBRivalStillAround(r) ? CBRivalDisplayName(CBContent(game), r) : "";
}

public func CBWebMen(game: GameInstance, gang: CName) -> Float {
  let war = CBWarBook.Get(game);
  return IsDefined(war) && CBWarChestOn() ? ClampF(war.Men(gang) / 100.0, 0.0, 1.0) : 1.0;
}

public func CBWebChest(game: GameInstance, gang: CName) -> Float {
  let war = CBWarBook.Get(game);
  return IsDefined(war) && CBWarChestOn() ? ClampF(war.Chest(gang) / CBConfig.WarChestFlush(), 0.0, 1.0) : 1.0;
}

// The relations of one gang, in words, for the page below the web: the same things the lines say.
public func CBWebRelationWords(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  let now = CBGameSeconds(game);
  let out = "";
  let i = 1;
  while i <= 11 {
    let other = CBWebSlotGang(i);
    if NotEquals(other, gang) {
      let kind = CBWebPair(sys, game, gang, other);
      let name = CBFactionLabel(other);
      let said = "";
      if kind == CBWebPairClash() {
        said = s"Fought \(name) in the street today.";
      }
      if kind == CBWebPairWar() {
        said = s"At war with \(name) over a district.";
      }
      if kind == CBWebPairTruce() {
        let war = CBWarBook.Get(game);
        let left = IsDefined(war) ? CBWebTruceHours(war, gang, other, now) : 0;
        said = left > 0 ? s"In a truce with \(name) against you, \(left) hours left." : s"In a truce with \(name) against you.";
      }
      if kind == CBWebPairIncite() {
        said = s"Set on \(name) by a lie of yours.";
      }
      if StrLen(said) > 0 {
        out += (StrLen(out) > 0 ? " " : "") + said;
      }
    }
    i += 1;
  }
  return out;
}

func CBWebTruceHours(war: ref<CBWarBook>, a: CName, b: CName, now: Float) -> Int32 {
  // The truce is kept on one side or the other; read whichever has it.
  if Equals(war.TruceWith(a, now), b) || Equals(war.TruceWith(b, now), a) {
    return Max(0, RoundF((war.TruceUntilFor(a, b, now) - now) / CBConfig.SecondsPerHour()));
  }
  return 0;
}

public func CBWebLegend() -> String {
  return "Lines from you: green friendly, amber hostile, red out for blood; no line, neutral. Between two gangs: red at war, cyan a truce against you, amber one you set on the other.\nClick a gang for its old feuds, what it thinks of you, and to pay it off.";
}

// The word under a gang's name in its box, what is live between them and V (CBWebVWord), coloured by whether it is
// trouble or help.
public func CBWebVWordTint(word: String) -> HDRColor {
  if Equals(word, "OPEN SEASON") || Equals(word, "TRACKER") || Equals(word, "A PRICE ON YOU") || Equals(word, "PAY UP") {
    return CBHudRed();
  }
  return CBHudGreen();
}

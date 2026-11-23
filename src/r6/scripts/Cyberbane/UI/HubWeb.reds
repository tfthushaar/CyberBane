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

public func CBWebSlotCount() -> Int32 = 17
// The gangs' places, 1 to this; the corporations and the law after them (2.6.4: twelve, with the Scrappers).
public func CBWebGangSlots() -> Int32 = 12
public func CBWebLinePool() -> Int32 = 64
public func CBWebWordPool() -> Int32 = 14
public func CBWebHeight() -> Float = 440.0
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

// Who is in each place: 0 is V, 1 to 12 the gangs, 13 to 16 the corporations and the law.
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
    case 12: return n"Scrappers";
    case 13: return n"Arasaka";
    case 14: return n"Militech";
    case 15: return n"KangTao";
    case 16: return n"NCPD";
    default: return n"";
  }
}

public func CBWebSlotIsGang(i: Int32) -> Bool = i >= 1 && i <= CBWebGangSlots()

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
    case 12: return 1060.0;
    case 13: return 275.0;
    case 14: return 485.0;
    case 15: return 695.0;
    case 16: return 905.0;
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
    case 12: return 0.0;
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

// The word on V's line to this gang: what is live between them, the most pressing first, or "".
// The words that mean trouble, one function each so the tint below asks the same words the box shows (2.7.1).
func CBWebWordOpenSeason() -> String {
  return CBT(n"Cyberbane-HubWeb-OPENSEASON");
}

func CBWebWordTracker() -> String {
  return CBT(n"Cyberbane-HubWeb-TRACKER");
}

func CBWebWordPrice() -> String {
  return CBT(n"Cyberbane-HubWeb-APRICEONYOU");
}

func CBWebWordPayUp() -> String {
  return CBT(n"Cyberbane-HubWeb-PAYUP");
}

public func CBWebVWord(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  if CBOpenSeasonFor(game, gang) {
    return CBWebWordOpenSeason();
  }
  if Equals(CBTrackerGang(game), gang) {
    return CBWebWordTracker();
  }
  let book = CBHuntBook.Get(game);
  if IsDefined(book) && CBBountyUp(game) > 0 && Equals(CBBountyGang(sys, book.BountyBy()), gang) {
    return CBWebWordPrice();
  }
  let war = CBWarBook.Get(game);
  let now = CBGameSeconds(game);
  if IsDefined(war) && Equals(gang, n"TygerClaws") && war.ProtectDue() > now {
    return CBWebWordPayUp();
  }
  if IsDefined(war) && CBBackingOn() && Equals(war.Backed(), gang) {
    return CBT(n"Cyberbane-HubWeb-BACKED");
  }
  if sys.TollActive(gang, now) {
    return CBT(n"Cyberbane-HubWeb-SAFEPASSAGE");
  }
  let fs = sys.FindFaction(gang);
  if IsDefined(fs) && fs.lastPeaceAt > 0.0 && now - fs.lastPeaceAt < CBConfig.WebPeaceDays() * CBConfig.SecondsPerDay() {
    return CBT(n"Cyberbane-HubWeb-PEACEPAID");
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

// ---- What a gang's box and the page below say --------------------------------------------------------------------

public func CBWebBoxLine(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  if !CBFactionOn(gang) {
    return CBT(n"Cyberbane-HubWeb-OFF");
  }
  let score = sys.GetScore();
  if !IsDefined(score) {
    return "";
  }
  // One word (2.5.0): the standing's number, the streets held and the leader are in the panel under the picture,
  // where the gang's box sent them as three lines of 11 px text.
  let out = StrUpper(CBPostureName(score.GetPosture(gang)));
  // A clan or raffen says so (2.7.4): "CLAN  ·  HOSTILE".
  let label = CBFactionCardLabel(gang);
  return StrLen(label) > 0 ? StrUpper(label) + "  ·  " + out : out;
}

public func CBWebLeader(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  let fs = sys.FindFaction(gang);
  let r = IsDefined(fs) && fs.leaderRivalId > 0 ? sys.FindRivalById(fs.leaderRivalId) : null;
  return IsDefined(r) && CBRivalStillAround(r) ? CBRivalDisplayName(CBContent(game), r) : "";
}


// The relations of one gang, in words, for the page below the web: the same things the lines say.
public func CBWebRelationWords(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> String {
  let now = CBGameSeconds(game);
  let out = "";
  let i = 1;
  while i <= CBWebGangSlots() {
    let other = CBWebSlotGang(i);
    if NotEquals(other, gang) {
      let kind = CBWebPair(sys, game, gang, other);
      let name = CBFactionLabel(other);
      let said = "";
      if kind == CBWebPairClash() {
        said = CBTf(n"Cyberbane-HubWeb-FoughtInTheStreetToday", [s"\(name)"]);
      }
      if kind == CBWebPairWar() {
        said = CBTf(n"Cyberbane-HubWeb-AtWarWithOverADistrict", [s"\(name)"]);
      }
      if kind == CBWebPairTruce() {
        let war = CBWarBook.Get(game);
        let left = IsDefined(war) ? CBWebTruceHours(war, gang, other, now) : 0;
        said = left > 0 ? CBTf(n"Cyberbane-HubWeb-InATruceWithAgainstYou", [s"\(name)", s"\(left)"]) : CBTf(n"Cyberbane-HubWeb-InATruceWithAgainstYou-2", [s"\(name)"]);
      }
      if kind == CBWebPairIncite() {
        said = CBTf(n"Cyberbane-HubWeb-SetOnByALieOf", [s"\(name)"]);
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
  return CBT(n"Cyberbane-HubWeb-EachCardIsAGangWhat");
}

// How a gang stands with the one picked, on its card (2.5.0).
public func CBCardPairWords(kind: Int32, other: String) -> String {
  if kind == CBWebPairClash() { return CBTf(n"Cyberbane-HubWeb-FoughtToday", [other]); }
  if kind == CBWebPairWar() { return CBTf(n"Cyberbane-HubWeb-AtWarWith", [other]); }
  if kind == CBWebPairTruce() { return CBTf(n"Cyberbane-HubWeb-TruceWithAgainstYou", [other]); }
  if kind == CBWebPairIncite() { return CBTf(n"Cyberbane-HubWeb-YouSetThemOn", [other]); }
  if kind == CBWebPairFeud() { return CBTf(n"Cyberbane-HubWeb-OldFeudWith", [other]); }
  return CBTf(n"Cyberbane-HubWeb-NoQuarrelWith", [other]);
}

public func CBCardPairTint(kind: Int32) -> HDRColor {
  if kind == CBWebPairClash() || kind == CBWebPairWar() { return CBHudRed(); }
  if kind == CBWebPairTruce() { return CBHudCyan(); }
  if kind == CBWebPairIncite() { return CBHudAmber(); }
  if kind == CBWebPairFeud() { return new HDRColor(0.75, 0.38, 0.38, 1.0); }
  return CBHudDim();
}

// Where a gang's card goes among the rest: out for blood first, then hostile, neutral, friendly, allied, and within each
// the worst standing first; a gang switched off goes last (2.5.0).
public func CBCardRank(score: ref<CBScoreEngine>, gang: CName) -> Float {
  if !CBFactionOn(gang) || !IsDefined(score) {
    return 10000.0;
  }
  let p = score.GetPosture(gang);
  let band = 4.0;
  if Equals(p, ECBPosture.Vendetta) { band = 0.0; }
  if Equals(p, ECBPosture.Hostile) { band = 1.0; }
  if Equals(p, ECBPosture.Neutral) { band = 2.0; }
  if Equals(p, ECBPosture.Friendly) { band = 3.0; }
  return band * 1000.0 + score.GetStanding(gang);
}

// The word under a gang's name in its box, what is live between them and V (CBWebVWord), coloured by whether it is
// trouble or help.
public func CBWebVWordTint(word: String) -> HDRColor {
  if Equals(word, CBWebWordOpenSeason()) || Equals(word, CBWebWordTracker()) || Equals(word, CBWebWordPrice())
     || Equals(word, CBWebWordPayUp()) {
    return CBHudRed();
  }
  return CBHudGreen();
}

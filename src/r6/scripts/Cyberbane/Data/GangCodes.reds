// Cyberbane - A code for each gang ([10]-[19], 2.3.2)
//
// The gangs differed in numbers and colours. Each now has a code: what it respects, what it never forgives,
// how it fights and how it makes peace. Every part of it is a number one of the existing systems already
// uses, so nothing is kept twice and every switch that already governs a system still governs it:
//
//   mercy      standing a gang gives for one of theirs left breathing (CBCreditMercy)
//   grudge     standing a gang takes for one of theirs put down, by how (CBApplyKill); the Animals despise a
//              gun and respect fists, the Aldecaldos are one family
//   shotHands  more taken for shooting one with their hands up (the Valentinos never forget it)
//   nerve      how easily their people break, run or hold back from V (Reactions/Morale.reds): Barghest
//              never, the Animals barely, the Scavengers easily
//   surrender  how often a beaten one gives up (Spawn/LivingStreet.reds): Barghest never, the Mox often
//   peace      their price to call it off (Economy/Peace.reds): the Claws are business, Barghest an army
//   insult     what a slight in talk costs (CBTalkSlight): the Claws' face, the Valentinos' honour
//   crew       how many they send (CBCrewSizeFor): the Mox and the Voodoo Boys send few, Barghest more
//   apex       whether they send their best at all (the Mox never)
//   forgive    how fast a grudge fades (Model/Decay.reds): the Aldecaldos remember
//   toughness  extra health on their crews (Spawn/FactionApex.reds, the crew build): the Animals
//   kin        how often a fallen Rival's family takes their place (the Valentinos)
//   home       the districts their grudge stays in (Barghest and the Scrappers: Dogtown; the Wraiths: the
//              Badlands and where the city meets it, 2.7.4)
//   guards     a district whose ordinary people they guard (6th Street: Santo Domingo; the Mox: Westbrook,
//              Jig-Jig Street)
//   everybody  killing them is a favour to every other gang (the Scavengers), who also make no Rivals
//   chrome     how well they see chrome under clothes (Maelstrom)
//
// Off (Mod Settings, Gangs: Gang codes), every number is 1.0 and every flag is off: the gangs behave as they
// did before 2.3.2. The Hub's gang page says what each code is, a line at a time as V learns it (CBCodeLines).

public func CBGangCodesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().gangCodes;
}

// Since 2.7.4 every number below is read from the faction's profile (Data/FactionProfiles.reds, generated from the
// chains of names these functions used to be, and checked against them faction by faction), so a new faction, or an
// add-on's, is one block of data. Each function still answers with the neutral value when Gang codes is off.

// A faction's code, from its profile; nothing for a faction without one.
public func CBCodeOf(f: CName) -> ref<CBGangCode> {
  let content = CyberbaneContent.Get();
  let p = IsDefined(content) && NotEquals(f, n"") ? content.GetFaction(f) : null;
  return IsDefined(p) ? p.code : null;
}

// What one group's people are called (2.7.4), as a key for CBT: "gang" for most, "clan" for the Aldecaldos, "raffen" for
// the Wraiths, "corporation", "law", "army". For lines that name a group's own people; rule lines that speak of gangs in
// general stay as they are.
public func CBFactionNoun(f: CName) -> CName {
  let content = CyberbaneContent.Get();
  let p = IsDefined(content) && NotEquals(f, n"") ? content.GetFaction(f) : null;
  return IsDefined(p) && IsNameValid(p.nounKey) ? p.nounKey : n"Cyberbane-Faction-NounGang";
}

// The label a faction's Hub card wears, "" for none (Clan on the Aldecaldos', Raffen on the Wraiths').
public func CBFactionCardLabel(f: CName) -> String {
  let content = CyberbaneContent.Get();
  let p = IsDefined(content) && NotEquals(f, n"") ? content.GetFaction(f) : null;
  return IsDefined(p) && IsNameValid(p.cardLabelKey) ? CBT(p.cardLabelKey) : "";
}

public func CBCodeMercy(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.mercy : 1.0;
}

// Standing lost for one of theirs, by how V did it.
public func CBCodeGrudge(f: CName, info: ref<CBKillInfo>) -> Float {
  let c = CBCodeOf(f);
  if !CBGangCodesOn() || !IsDefined(info) || !IsDefined(c) { return 1.0; }
  if (info.mFists || info.mBlunt || info.mFinisher) && c.grudgeClose != 1.0 { return c.grudgeClose; }
  if info.mFirearm && c.grudgeGun != 1.0 { return c.grudgeGun; }
  if c.grudgeAll != 1.0 { return c.grudgeAll; }
  if info.mFinisher && c.grudgeFinisher != 1.0 { return c.grudgeFinisher; }
  return 1.0;
}

public func CBCodeShotHands(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.shotHands : 1.0;
}

// Multiplies how likely their people are to break, run, or hold back from V.
public func CBCodeNerve(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.nerve : 1.0;
}

public func CBCodeSurrender(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.surrender : 1.0;
}

public func CBCodePeace(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.peace : 1.0;
}

public func CBCodeInsult(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.insult : 1.0;
}

public func CBCodeCrew(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.crew : 1.0;
}

public func CBCodeSendsApex(f: CName) -> Bool {
  let c = CBCodeOf(f);
  return !CBGangCodesOn() || !IsDefined(c) || c.sendsApex;
}

// How fast a grudge against V fades: 1.0 as it always did, lower is longer.
public func CBCodeForgive(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.forgive : 1.0;
}

// Extra health on their crews, as a fraction (the crew build, Spawn/FactionApex.reds).
public func CBCodeToughness(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.toughness : 0.0;
}

public func CBCodeKin(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.kin : 1.0;
}

// The districts their grudge keeps to (2.7.4: more than one; the Wraiths keep to the Badlands and the city's edge), empty
// for a gang that comes anywhere.
public func CBCodeHomes(f: CName) -> array<CName> {
  let none: array<CName>;
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.homes : none;
}

// The first of them, n"" for none (kept for anything that names one home).
public func CBCodeHome(f: CName) -> CName {
  let homes = CBCodeHomes(f);
  return ArraySize(homes) > 0 ? homes[0] : n"";
}

// V is somewhere their grudge reaches: anywhere for most, one of their homes for a gang that keeps to them.
public func CBCodeAtHome(sys: ref<CyberbaneSystem>, f: CName) -> Bool {
  let homes = CBCodeHomes(f);
  return ArraySize(homes) == 0 || !IsDefined(sys) || ArrayContains(homes, sys.GetCurrentDistrict());
}

// They guard this district's ordinary people.
public func CBCodeGuards(f: CName, district: CName) -> Bool {
  let c = CBCodeOf(f);
  if !CBGangCodesOn() || Equals(district, n"") || !IsDefined(c) || Equals(c.guards, n"") { return false; }
  return Equals(district, c.guards);
}

public func CBCodeSoldiers(f: CName) -> Bool {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) && c.soldiers;
}

public func CBCodeEverybodysEnemy(f: CName) -> Bool {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) && c.everybodysEnemy;
}

public func CBCodeSeesChrome(f: CName) -> Float {
  let c = CBCodeOf(f);
  return CBGangCodesOn() && IsDefined(c) ? c.seesChrome : 0.0;
}

// The Hub's gang page: what V has learnt of their code, a line at a time (respect from the start; the rest once V has
// killed one of theirs, beaten a crew, or made peace).
public func CBCodeLines(sys: ref<CyberbaneSystem>, f: CName) -> String {
  if !CBGangCodesOn() || !IsDefined(sys) {
    return "";
  }
  let respect = CBCodeRespectShort(f);
  if StrLen(respect) == 0 {
    return "";
  }
  let out = CBTf(n"Cyberbane-GangCodes-TheirCodeTheyRespect", [respect]);
  let fs = sys.FindFaction(f);
  let learnt = "";
  if IsDefined(fs) && fs.kills > 0 {
    learnt += CBTf(n"Cyberbane-GangCodes-NeverForgive", [CBCodeNeverShort(f)]);
    let c = CBCodeOf(f);
    if IsDefined(c) && IsNameValid(c.homeKey) {
      learnt += CBT(c.homeKey) + " ";
    }
  }
  if IsDefined(fs) && (fs.kills >= 5 || sys.CrewBeaten(f)) {
    learnt += CBTf(n"Cyberbane-GangCodes-Fight", [CBCodeFightShort(f)]);
  }
  if IsDefined(fs) && (fs.lastPeaceAt > 0.0 || fs.tributes > 0 || fs.spared > 0) {
    learnt += CBTf(n"Cyberbane-GangCodes-Peace", [CBCodePeaceShort(f)]);
  }
  return StrLen(learnt) > 0 ? out + "\n" + learnt : out;
}

func CBCodeWords(key: CName) -> String {
  return IsNameValid(key) ? CBT(key) : "";
}

func CBCodeRespectShort(f: CName) -> String {
  let c = CBCodeOf(f);
  return IsDefined(c) ? CBCodeWords(c.respectKey) : "";
}

func CBCodeNeverShort(f: CName) -> String {
  let c = CBCodeOf(f);
  return IsDefined(c) ? CBCodeWords(c.neverKey) : "";
}

func CBCodeFightShort(f: CName) -> String {
  let c = CBCodeOf(f);
  return IsDefined(c) ? CBCodeWords(c.fightKey) : "";
}

func CBCodePeaceShort(f: CName) -> String {
  let c = CBCodeOf(f);
  return IsDefined(c) ? CBCodeWords(c.peaceKey) : "";
}

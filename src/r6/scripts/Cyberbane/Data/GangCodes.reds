// Cyberbane - A code for each gang
//
// What each gang respects, what it never forgives, how it fights and how it makes peace. Every value feeds a system
// that already exists, so a code is just numbers on the gang's profile.

public func CBGangCodesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().gangCodes;
}

// Each function still answers with the neutral value when Gang codes is off.

// A faction's code, from its profile; nothing for a faction without one.
public func CBCodeOf(f: CName) -> ref<CBGangCode> {
  let content = CyberbaneContent.Get();
  let p = IsDefined(content) && NotEquals(f, n"") ? content.GetFaction(f) : null;
  return IsDefined(p) ? p.code : null;
}

// What one group's people are called, as a key for CBT: "gang" for most, "clan" for the Aldecaldos, "raffen" for the
// Wraiths, "corporation", "law", "army".
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
  // The most particular first (2.7.9): a finisher is also close work, so asked after the close grudge it was never
  // reached for a gang that had both.
  if info.mFinisher && c.grudgeFinisher != 1.0 { return c.grudgeFinisher; }
  if (info.mFists || info.mBlunt || info.mFinisher) && c.grudgeClose != 1.0 { return c.grudgeClose; }
  if info.mFirearm && c.grudgeGun != 1.0 { return c.grudgeGun; }
  if c.grudgeAll != 1.0 { return c.grudgeAll; }
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

// The districts their grudge keeps to (more than one; the Wraiths keep to the Badlands and the city's edge), empty for
// a gang that comes anywhere.
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

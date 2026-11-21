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
//   home       a district their grudge stays in (Barghest and the Scrappers: Dogtown)
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

public func CBCodeMercy(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Valentinos") { return 1.6; }
  if Equals(f, n"Mox") { return 1.4; }
  if Equals(f, n"Aldecaldos") { return 1.3; }
  if Equals(f, n"Animals") { return 0.7; }
  if Equals(f, n"Barghest") { return 0.6; }
  if Equals(f, n"Maelstrom") { return 0.7; }
  if Equals(f, n"Scrappers") { return 1.3; }
  return 1.0;
}

// Standing lost for one of theirs, by how V did it.
public func CBCodeGrudge(f: CName, info: ref<CBKillInfo>) -> Float {
  if !CBGangCodesOn() || !IsDefined(info) { return 1.0; }
  if Equals(f, n"Animals") {
    if info.mFists || info.mBlunt || info.mFinisher { return 0.6; }
    if info.mFirearm { return 1.25; }
  }
  if Equals(f, n"Aldecaldos") { return 1.3; }
  if Equals(f, n"Valentinos") && info.mFinisher { return 0.9; }   // face to face is still a fair fight
  return 1.0;
}

public func CBCodeShotHands(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Valentinos") { return 2.0; }
  if Equals(f, n"Aldecaldos") || Equals(f, n"Mox") || Equals(f, n"Scrappers") { return 1.5; }
  return 1.0;
}

// Multiplies how likely their people are to break, run, or hold back from V.
public func CBCodeNerve(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Barghest") { return 0.0; }
  if Equals(f, n"Animals") { return 0.5; }
  if Equals(f, n"SixthStreet") { return 0.8; }
  if Equals(f, n"Scavengers") { return 1.4; }
  if Equals(f, n"Mox") { return 1.2; }
  if Equals(f, n"Scrappers") { return 1.3; }
  return 1.0;
}

public func CBCodeSurrender(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Barghest") { return 0.0; }
  if Equals(f, n"Animals") { return 0.3; }
  if Equals(f, n"Maelstrom") { return 0.6; }
  if Equals(f, n"SixthStreet") { return 0.7; }
  if Equals(f, n"Valentinos") || Equals(f, n"Wraiths") || Equals(f, n"Aldecaldos") { return 0.8; }
  if Equals(f, n"Mox") { return 1.6; }
  if Equals(f, n"Scavengers") { return 1.5; }
  if Equals(f, n"Scrappers") { return 1.4; }
  return 1.0;
}

public func CBCodePeace(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"TygerClaws") { return 0.75; }
  if Equals(f, n"Barghest") { return 1.4; }
  if Equals(f, n"Valentinos") { return 1.15; }
  if Equals(f, n"Scavengers") || Equals(f, n"Scrappers") { return 0.8; }
  return 1.0;
}

public func CBCodeInsult(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"TygerClaws") { return 1.6; }
  if Equals(f, n"Valentinos") { return 1.3; }
  if Equals(f, n"Scavengers") { return 0.7; }
  return 1.0;
}

public func CBCodeCrew(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Mox") { return 0.7; }
  if Equals(f, n"VoodooBoys") { return 0.75; }
  if Equals(f, n"Barghest") { return 1.2; }
  return 1.0;
}

public func CBCodeSendsApex(f: CName) -> Bool {
  return !CBGangCodesOn() || !Equals(f, n"Mox");
}

// How fast a grudge against V fades: 1.0 as it always did, lower is longer.
public func CBCodeForgive(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Aldecaldos") { return 0.5; }
  if Equals(f, n"Valentinos") { return 0.7; }
  if Equals(f, n"Scavengers") { return 1.5; }
  if Equals(f, n"Scrappers") { return 1.3; }
  return 1.0;
}

// Extra health on their crews, as a fraction (the crew build, Spawn/FactionApex.reds).
public func CBCodeToughness(f: CName) -> Float {
  if !CBGangCodesOn() { return 0.0; }
  if Equals(f, n"Animals") { return 0.25; }
  if Equals(f, n"Barghest") { return 0.15; }
  return 0.0;
}

public func CBCodeKin(f: CName) -> Float {
  if !CBGangCodesOn() { return 1.0; }
  if Equals(f, n"Valentinos") { return 1.5; }
  if Equals(f, n"Aldecaldos") { return 1.3; }
  return 1.0;
}

// The one district this gang's grudge reaches, or n"" for anywhere.
public func CBCodeHome(f: CName) -> CName {
  if CBGangCodesOn() && (Equals(f, n"Barghest") || Equals(f, n"Scrappers")) { return n"Dogtown"; }
  return n"";
}

// Is V where this gang's grudge reaches? Always, for a gang with no home of its own.
public func CBCodeAtHome(sys: ref<CyberbaneSystem>, f: CName) -> Bool {
  let home = CBCodeHome(f);
  return Equals(home, n"") || !IsDefined(sys) || Equals(sys.GetCurrentDistrict(), home);
}

// Does this gang guard the ordinary people of this district?
public func CBCodeGuards(f: CName, district: CName) -> Bool {
  if !CBGangCodesOn() || Equals(district, n"") { return false; }
  if Equals(f, n"SixthStreet") { return Equals(district, n"SantoDomingo"); }
  if Equals(f, n"Mox") { return Equals(district, n"Westbrook"); }
  return false;
}

// They fight like soldiers: the corps' crew kit (Spawn/ApexSquad.reds, CBKitSquadMember).
public func CBCodeSoldiers(f: CName) -> Bool {
  return CBGangCodesOn() && (Equals(f, n"SixthStreet") || Equals(f, n"Barghest"));
}

// Killing them is a favour to every other gang, and they make no Rivals (they run).
public func CBCodeEverybodysEnemy(f: CName) -> Bool {
  return CBGangCodesOn() && Equals(f, n"Scavengers");
}

// How much more easily they place V by chrome under clothes, as a chance added to recognition.
public func CBCodeSeesChrome(f: CName) -> Float {
  if CBGangCodesOn() && Equals(f, n"Maelstrom") { return 0.15; }
  return 0.0;
}

// ---- What the Hub says ([21]) -----------------------------------------------------------------------
//
// Two short lines under a gang's price on the Hub: what they respect, which the street says from the start, and
// what V has learnt the hard way: what they never forgive once V has hurt them, how they fight once V has beaten
// a crew of theirs or killed a few, how to make peace once there has been a peace, a tribute or a mercy.

public func CBCodeLines(sys: ref<CyberbaneSystem>, f: CName) -> String {
  if !CBGangCodesOn() || !IsDefined(sys) {
    return "";
  }
  let respect = CBCodeRespectShort(f);
  if StrLen(respect) == 0 {
    return "";
  }
  let out = "Their code: they respect " + respect + ".";
  let fs = sys.FindFaction(f);
  let learnt = "";
  if IsDefined(fs) && fs.kills > 0 {
    learnt += "Never forgive " + CBCodeNeverShort(f) + ". ";
  }
  if IsDefined(fs) && (fs.kills >= 5 || sys.CrewBeaten(f)) {
    learnt += "Fight " + CBCodeFightShort(f) + ". ";
  }
  if IsDefined(fs) && (fs.lastPeaceAt > 0.0 || fs.tributes > 0 || fs.spared > 0) {
    learnt += "Peace: " + CBCodePeaceShort(f) + ".";
  }
  return StrLen(learnt) > 0 ? out + "\n" + learnt : out;
}

func CBCodeRespectShort(f: CName) -> String {
  if Equals(f, n"Valentinos") { return "honour, family and a fair fight, and mercy most of all"; }
  if Equals(f, n"TygerClaws") { return "business and face"; }
  if Equals(f, n"Maelstrom") { return "chrome, the more on show the better"; }
  if Equals(f, n"SixthStreet") { return "the neighbourhood and its people"; }
  if Equals(f, n"Animals") { return "strength: fists over guns"; }
  if Equals(f, n"VoodooBoys") { return "information"; }
  if Equals(f, n"Mox") { return "looking after their own"; }
  if Equals(f, n"Scavengers") { return "nothing, and nobody misses them"; }
  if Equals(f, n"Wraiths") { return "the road"; }
  if Equals(f, n"Aldecaldos") { return "family: a favour repaid, a harm remembered"; }
  if Equals(f, n"Barghest") { return "discipline"; }
  if Equals(f, n"Scrappers") { return "a good haul, and a chance to walk away"; }
  return "";
}

func CBCodeNeverShort(f: CName) -> String {
  if Equals(f, n"Valentinos") { return "a shot surrender (double)"; }
  if Equals(f, n"TygerClaws") { return "an insult"; }
  if Equals(f, n"Maelstrom") { return "hidden chrome"; }
  if Equals(f, n"SixthStreet") { return "hurting Santo Domingo's people"; }
  if Equals(f, n"Animals") { return "a coward with a gun"; }
  if Equals(f, n"VoodooBoys") { return "anyone they can't trace"; }
  if Equals(f, n"Mox") { return "hurting Jig-Jig Street's people"; }
  if Equals(f, n"Scavengers") { return "much: they run, and never come back as Rivals"; }
  if Equals(f, n"Wraiths") { return "anyone on their road"; }
  if Equals(f, n"Aldecaldos") { return "harm to family, twice as long"; }
  if Equals(f, n"Barghest") { return "anything, but only in Dogtown"; }
  if Equals(f, n"Scrappers") { return "a shot surrender, but only in Dogtown"; }
  return "";
}

func CBCodeFightShort(f: CName) -> String {
  if Equals(f, n"Valentinos") { return "together, and kin take a fallen Rival's place"; }
  if Equals(f, n"TygerClaws") { return "fast, and they'd rather pay than lose"; }
  if Equals(f, n"Maelstrom") { return "for your chrome"; }
  if Equals(f, n"SixthStreet") { return "like soldiers"; }
  if Equals(f, n"Animals") { return "juiced, and barely afraid"; }
  if Equals(f, n"VoodooBoys") { return "through the Net, few in person"; }
  if Equals(f, n"Mox") { return "in small crews, never their best"; }
  if Equals(f, n"Scavengers") { return "when you're hurt; they break when you're not"; }
  if Equals(f, n"Wraiths") { return "on the road"; }
  if Equals(f, n"Aldecaldos") { return "as one family"; }
  if Equals(f, n"Barghest") { return "in numbers, never breaking or surrendering"; }
  if Equals(f, n"Scrappers") { return "in the ruins they know, and break when it turns"; }
  return "";
}

func CBCodePeaceShort(f: CName) -> String {
  if Equals(f, n"Valentinos") { return "spare theirs, it counts more than eddies"; }
  if Equals(f, n"TygerClaws") { return "pay, they're cheapest"; }
  if Equals(f, n"Maelstrom") { return "pay"; }
  if Equals(f, n"SixthStreet") { return "pay, and leave their neighbourhood alone"; }
  if Equals(f, n"Animals") { return "pay"; }
  if Equals(f, n"VoodooBoys") { return "pay"; }
  if Equals(f, n"Mox") { return "leave their people alone, spare the ones who give up"; }
  if Equals(f, n"Scavengers") { return "cheap, and nobody else minds"; }
  if Equals(f, n"Wraiths") { return "pay, and stay off their road"; }
  if Equals(f, n"Aldecaldos") { return "spare the family"; }
  if Equals(f, n"Barghest") { return "pay a lot, or stay out of Dogtown"; }
  if Equals(f, n"Scrappers") { return "cheap, and spare the ones who give up"; }
  return "";
}

// Cyberbane - Rivals worth their names: signature chrome (2.7.2)
//
// "Rivals are named but do not stand out from elites and apex crews; give them cyberware from the game." How a body
// fights is its character record, so a Rival who climbs high enough (SignatureRank, which a rank or an escape brings)
// comes back on one of their gang's own signature records: mantis blades for Maelstrom and the Mox, gorilla arms for the
// Tyger Claws, the Wraiths, Militech and Barghest, a heavy machine gun, a netrunner's deck for the Voodoo Boys. The same
// swap Rivals already get when their record would draw the police (Rivals/RivalSystem.reds), done the moment they next
// set out, so the street can say so first. Each record is checked when it is used: it exists (Barghest's needs Phantom
// Liberty), it is a person, nobody in the story owns it, and its body is the same sex as the one V has seen them in.
//
// What is not done, and why: Berserk, Sandevistan or Kerenzikov on an NPC (crash rule 5); blades put onto a body whose
// record never had them (rule 6); Royce's suit or Sasquatch, whose records belong to their quests.

public func CBRivalSignatureOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().rivalSignature;
}

// What a signature is: 1 mantis blades, 2 gorilla arms, 3 a heavy machine gun, 4 a netrunner's deck, 5 a blade,
// 6 two pistols, 7 a shotgun, 8 fists and Juice, 9 a sniper rifle.
public func CBSigMantis() -> Int32 = 1
public func CBSigGorilla() -> Int32 = 2
public func CBSigHeavy() -> Int32 = 3
public func CBSigNetrunner() -> Int32 = 4

// A gang's signature records, each with its kind and whether the body is a woman's.
func CBRivalSignatureTable(gang: CName, out recs: array<TweakDBID>, out kinds: array<Int32>, out female: array<Bool>) -> Void {
  if Equals(gang, n"Maelstrom") {
    recs = [t"Character.maelstrom_fast_fmelee3_mantis_wa_elite", t"Character.maelstrom_strong_gunner2_defender_mb_rare"];
    kinds = [1, 3];
    female = [true, false];
    return;
  }
  if Equals(gang, n"Mox") {
    recs = [t"Character.the_mox_elite3_fmelee3_mantis_wa_elite"];
    kinds = [1];
    female = [true];
    return;
  }
  if Equals(gang, n"TygerClaws") {
    recs = [t"Character.tyger_claws_martial_hmelee3_StrongArms_mb", t"Character.tyger_claws_kunoichi_fmelee3_katana_wa_elite"];
    kinds = [2, 5];
    female = [false, true];
    return;
  }
  if Equals(gang, n"Valentinos") {
    recs = [t"Character.valentinos_elite3_ranged3_dual_ma_elite", t"Character.valentinos_machete_hmelee3_machete_mb_elite",
            t"Character.valentinos_sniper_sniper3_grad_wa_elite"];
    kinds = [6, 5, 9];
    female = [false, false, true];
    return;
  }
  if Equals(gang, n"SixthStreet") {
    recs = [t"Character.sixthstreet_patrol2_shotgun3_satara_ma_elite"];
    kinds = [7];
    female = [false];
    return;
  }
  if Equals(gang, n"Animals") {
    recs = [t"Character.animals_elite3_hmelee3_fists_mba_elite", t"Character.animals_elite2_shotgun3_carnage_wba_elite"];
    kinds = [8, 7];
    female = [false, true];
    return;
  }
  if Equals(gang, n"VoodooBoys") {
    recs = [t"Character.voodooboys_netrunner3_netrunner3_quasar_wa_elite"];
    kinds = [4];
    female = [true];
    return;
  }
  if Equals(gang, n"Scavengers") {
    recs = [t"Character.scavenger_fast3_fmelee3_machete_wa_elite"];
    kinds = [5];
    female = [true];
    return;
  }
  if Equals(gang, n"Wraiths") {
    recs = [t"Character.wraiths_strongarms_hmelee3_fists_mb_elite", t"Character.wraiths_strong_gunner3_hmg_mb_elite"];
    kinds = [2, 3];
    female = [false, false];
    return;
  }
  if Equals(gang, n"Barghest") {
    recs = [t"Character.kurtz_strongarms_hmelee3_fists_mb_elite"];
    kinds = [2];
    female = [false];
    return;
  }
  if Equals(gang, n"Arasaka") {
    recs = [t"Character.arasaka_ninja_fmelee3_mantis_ma_elite", t"Character.arasaka_ninja_fmelee3_mantis_wa_elite"];
    kinds = [1, 1];
    female = [false, true];
    return;
  }
  if Equals(gang, n"Militech") {
    recs = [t"Character.militech_strongarms_hmelee3_fists_mb_elite", t"Character.militech_enforcer3_gunner3_HMG_mb_elite"];
    kinds = [2, 3];
    female = [false, false];
    return;
  }
}

// The kind of signature this Rival's record is, 0 for none.
public func CBRivalSignatureKind(r: ref<CBRival>) -> Int32 {
  if !IsDefined(r) {
    return 0;
  }
  let recs: array<TweakDBID>;
  let kinds: array<Int32>;
  let female: array<Bool>;
  CBRivalSignatureTable(r.faction, recs, kinds, female);
  let i = 0;
  while i < ArraySize(recs) && i < ArraySize(kinds) {
    if recs[i] == r.recordID {
      return kinds[i];
    }
    i += 1;
  }
  return 0;
}

// Which sex a Rival's body was the last time it was in the world: 1 a man, 2 a woman, 0 never seen.
public class CBRivalBodyBook extends ScriptableSystem {
  private persistent let m_rival: array<Int32>;
  private persistent let m_sex: array<Int32>;

  public static func Get(game: GameInstance) -> ref<CBRivalBodyBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBRivalBodyBook") as CBRivalBodyBook : null;
  }

  public func SexOf(id: Int32) -> Int32 {
    let i = 0;
    while i < Min(ArraySize(this.m_rival), ArraySize(this.m_sex)) {
      if this.m_rival[i] == id {
        return this.m_sex[i];
      }
      i += 1;
    }
    return 0;
  }

  public func Note(id: Int32, sex: Int32) -> Void {
    if id <= 0 || sex <= 0 {
      return;
    }
    let i = 0;
    while i < Min(ArraySize(this.m_rival), ArraySize(this.m_sex)) {
      if this.m_rival[i] == id {
        this.m_sex[i] = sex;
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_rival, id);
    ArrayPush(this.m_sex, sex);
    while ArraySize(this.m_rival) > 200 {
      ArrayErase(this.m_rival, 0);
      ArrayErase(this.m_sex, 0);
    }
  }

  public func Clear() -> Void {
    ArrayClear(this.m_rival);
    ArrayClear(this.m_sex);
  }
}

// A Rival's body is in the world (Spawn/Spawner.reds): which sex it is, for the next record it may be given.
public func CBRivalNoteBody(game: GameInstance, r: ref<CBRival>, puppet: ref<ScriptedPuppet>) -> Void {
  let book = CBRivalBodyBook.Get(game);
  if !IsDefined(book) || !IsDefined(r) || !IsDefined(puppet) {
    return;
  }
  let g = puppet.GetResolvedGenderName();
  if Equals(g, n"Female") {
    book.Note(r.id, 2);
  } else {
    if Equals(g, n"Male") {
      book.Note(r.id, 1);
    }
  }
}

// About to set out (Spawn/RivalEncounter.reds): high enough, and not chromed yet, they come back chromed, and the street
// says so first.
public func CBRivalTakeSignature(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Void {
  if !IsDefined(r) || !CBRivalSignatureOn() || r.rank < CBConfig.SignatureRank() || CBRivalSignatureKind(r) > 0
     || CBRecordIsSightingCyberpsycho(r.recordID) || CBRivalHasTrait(r, n"Broken") {
    return;
  }
  let recs: array<TweakDBID>;
  let kinds: array<Int32>;
  let female: array<Bool>;
  CBRivalSignatureTable(r.faction, recs, kinds, female);
  let n = Min(Min(ArraySize(recs), ArraySize(kinds)), ArraySize(female));
  if n == 0 {
    return;
  }
  let book = CBRivalBodyBook.Get(game);
  let sex = IsDefined(book) ? book.SexOf(r.id) : 0;
  let start = Abs(r.id * 31 + 7) % n;
  let k = 0;
  let picked = -1;
  while k < n && picked < 0 {
    let i = (start + k) % n;
    k += 1;
    let fits = sex == 0 || Equals(sex == 2, female[i]);
    if fits && TDBID.IsValid(recs[i]) && IsDefined(TweakDBInterface.GetCharacterRecord(recs[i])) && CBRecordIsPerson(recs[i])
       && !CBRecordIsUniqueCharacter(recs[i]) && !CBRecordDrawsPolice(recs[i]) {
      picked = i;
    }
  }
  if picked < 0 {
    return;
  }
  r.recordID = recs[picked];
  r.appearance = n"";
  CBLog.Info(n"Rivals", s"Rival \(r.id) came back chromed (signature \(kinds[picked])).");
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-Signature-WordIs", [CBRivalDisplayName(sys.GetContent(), r), CBSignatureWord(kinds[picked])]), n"");
  }
}

// In a sentence: "mantis blades put in".
public func CBSignatureWord(kind: Int32) -> String {
  switch kind {
    case 1: return CBT(n"Cyberbane-Signature-Mantis");
    case 2: return CBT(n"Cyberbane-Signature-Gorilla");
    case 3: return CBT(n"Cyberbane-Signature-Heavy");
    case 4: return CBT(n"Cyberbane-Signature-Netrunner");
    case 5: return CBT(n"Cyberbane-Signature-Blade");
    case 6: return CBT(n"Cyberbane-Signature-Pistols");
    case 7: return CBT(n"Cyberbane-Signature-Shotgun");
    case 8: return CBT(n"Cyberbane-Signature-Juice");
    default: return CBT(n"Cyberbane-Signature-Sniper");
  }
}

// On their file: what they fight with now.
public func CBSignatureCardLine(kind: Int32) -> String {
  switch kind {
    case 1: return CBT(n"Cyberbane-Signature-CardMantis");
    case 2: return CBT(n"Cyberbane-Signature-CardGorilla");
    case 3: return CBT(n"Cyberbane-Signature-CardHeavy");
    case 4: return CBT(n"Cyberbane-Signature-CardNetrunner");
    case 5: return CBT(n"Cyberbane-Signature-CardBlade");
    case 6: return CBT(n"Cyberbane-Signature-CardPistols");
    case 7: return CBT(n"Cyberbane-Signature-CardShotgun");
    case 8: return CBT(n"Cyberbane-Signature-CardJuice");
    default: return CBT(n"Cyberbane-Signature-CardSniper");
  }
}

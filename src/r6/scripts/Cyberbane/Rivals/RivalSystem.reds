// Cyberbane - Rival system (spec §10)
//
// Named, persistent recurring enemies. This file owns the data lifecycle:
// creation (with caps), deterministic naming, traits, history, promotion and the
// state transitions. Spawning the Rival into the world (RivalSpawner), encounter
// scheduling, the Death Ledger and hit squads build on top of this.

// Deterministic index from a seed + salt (stable naming from rival.id).
public func CBHashIndex(seed: Int32, salt: Int32, modulo: Int32) -> Int32 {
  if modulo <= 0 {
    return 0;
  }
  // Take the remainder first, then lift it into range. Negating before the modulo leaves
  // the most negative Int32 negative (it has no positive counterpart), which would hand
  // back a negative index and read off the front of the pool array.
  let h = (seed * 73 + salt * 19 + 7) % modulo;
  if h < 0 {
    h += modulo;
  }
  return h;
}

public func CBEpithetsForSource(content: ref<CyberbaneContent>, source: Int32) -> array<String> {
  let empty: array<String>;
  if !IsDefined(content) {
    return empty;
  }
  let e = content.GetEpithets();
  if !IsDefined(e) {
    return empty;
  }
  if source == EnumInt(ECBRivalSource.Survivor) { return e.survivor; }
  if source == EnumInt(ECBRivalSource.Spared) { return e.spared; }
  if source == EnumInt(ECBRivalSource.Killer) { return e.killer; }
  if source == EnumInt(ECBRivalSource.Avenger) { return e.avenger; }
  if source == EnumInt(ECBRivalSource.Hunter) { return e.hunter; }
  return empty;
}

public func CBRivalGenerateName(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  if !IsDefined(rival) {
    return;
  }
  rival.firstName = -1;
  rival.lastName = -1;
  rival.epithet = -1;
  if !IsDefined(content) {
    return;
  }
  let pool = content.GetFactionNames(rival.faction);
  if IsDefined(pool) {
    if ArraySize(pool.firstNames) > 0 {
      rival.firstName = CBHashIndex(rival.id, 1, ArraySize(pool.firstNames));
    }
    if ArraySize(pool.lastNames) > 0 {
      rival.lastName = CBHashIndex(rival.id, 2, ArraySize(pool.lastNames));
    }
  }
  let eps = CBEpithetsForSource(content, rival.source);
  if ArraySize(eps) > 0 {
    rival.epithet = CBHashIndex(rival.id, 3, ArraySize(eps));
  }
}

// A name nobody in this save has ever had. The pick above is arithmetic on the Rival's id, and nothing
// ever asked whether the answer was taken: with four first names and three surnames it came round
// every twelve Rivals, and players met the same person twice.
//
// Looks through every combination the gang's lists can make, starting from that pick, so a name is
// only refused when it has really been used. First for one whose first name nobody else of this gang
// on the roster has, then, if a long roster has used those up, for any name that is still new.
public func CBRivalPickFreeName(game: GameInstance, sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(rival) {
    return;
  }
  let pool = content.GetFactionNames(rival.faction);
  if !IsDefined(pool) || ArraySize(pool.firstNames) == 0 || rival.firstName < 0 {
    return;
  }
  let book = CBRivalNameBook.Get(game);
  if !IsDefined(book) {
    return;
  }
  CBRivalRosterIntoBook(book, sys, content);

  let firsts = ArraySize(pool.firstNames);
  let lasts = ArraySize(pool.lastNames);
  let startFirst = rival.firstName;
  let startLast = rival.lastName;
  // A gang of handles has no second list to walk, so its inner loop runs once.
  let surnames = 1;
  if lasts > 0 && startLast >= 0 {
    surnames = lasts;
  }
  let pass = 0;
  while pass < 2 {
    let f = 0;
    while f < firsts {
      rival.firstName = (startFirst + f) % firsts;
      if pass == 1 || !CBRivalGangHasFirstName(sys, rival) {
        let l = 0;
        while l < surnames {
          if lasts > 0 && startLast >= 0 {
            rival.lastName = (startLast + l) % lasts;
          }
          if CBRivalNameIsNew(book, content, pool, rival) {
            book.Remember(StringToName(CBRivalBareName(content, rival)));
            return;
          }
          l += 1;
        }
      }
      f += 1;
    }
    pass += 1;
  }
  // Every name this gang's lists can make has been used. They need to be called something.
  rival.firstName = startFirst;
  rival.lastName = startLast;
  CBLog.Warn(n"Rivals", s"Every name for \(NameToString(rival.faction)) has been used; one is being repeated.");
}

// The part in quotes, the same way: nobody on the roster shares it while another is free. There are
// a dozen or so of these for each way of becoming a Rival, so unlike a name they can run out, and
// then the first pick stands. An avenger took the same one as the Rival they were avenging.
func CBRivalPickFreeEpithet(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(rival) || rival.epithet < 0 {
    return;
  }
  let n = ArraySize(CBEpithetsForSource(content, rival.source));
  let start = rival.epithet;
  // First one nobody on this save has ever had (1.8.5), written down in the same book as the names;
  // then, once a long playthrough has used those up, one nobody on the roster has now.
  let book = CBRivalNameBook.Get(sys.GetGameInstance());
  let pass = IsDefined(book) ? 0 : 1;
  while pass < 2 {
    let step = 0;
    while step < n {
      rival.epithet = (start + step) % n;
      if !CBRivalEpithetTaken(sys, content, rival)
         && (pass == 1 || !book.Has(CBEpithetBookKey(CBRivalEpithet(content, rival)))) {
        if IsDefined(book) {
          book.Remember(CBEpithetBookKey(CBRivalEpithet(content, rival)));
        }
        return;
      }
      step += 1;
    }
    pass += 1;
  }
  rival.epithet = start;
}

// Nicknames share the name book's list (Rivals/NameBook.reds), marked so they can never be mistaken for
// a name: the list is data, so the save keeps its shape.
func CBEpithetBookKey(epithet: String) -> CName {
  return StringToName("E|" + epithet);
}

func CBRivalEpithetTaken(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Bool {
  let mine = CBRivalEpithet(content, rival);
  for other in sys.GetRivals() {
    if IsDefined(other) && other.id != rival.id && Equals(CBRivalEpithet(content, other), mine) {
      return true;
    }
  }
  return false;
}

// Rivals named before the book existed, and any the book has not seen, are written down while they
// are still on the roster to be read.
func CBRivalRosterIntoBook(book: ref<CBRivalNameBook>, sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>) -> Void {
  for other in sys.GetRivals() {
    if IsDefined(other) {
      let name = CBRivalBareName(content, other);
      if StrLen(name) > 0 {
        book.Remember(StringToName(name));
      }
      let epithet = CBRivalEpithet(content, other);
      if StrLen(epithet) > 0 {
        book.Remember(CBEpithetBookKey(epithet));
      }
    }
  }
}

func CBRivalGangHasFirstName(sys: ref<CyberbaneSystem>, rival: ref<CBRival>) -> Bool {
  for other in sys.GetRivals() {
    if IsDefined(other) && other.id != rival.id && Equals(other.faction, rival.faction)
       && other.firstName == rival.firstName {
      return true;
    }
  }
  return false;
}

// Anything the lists could make before 1.7.7 may have been somebody already, and that somebody may
// have been forgotten or trimmed off the roster long before the book was there to write them down.
// Those combinations are simply never handed out again. Everything since is in the book.
func CBRivalNameIsNew(book: ref<CBRivalNameBook>, content: ref<CyberbaneContent>, pool: ref<CBFactionNames>, rival: ref<CBRival>) -> Bool {
  if rival.firstName < pool.oldFirsts && (ArraySize(pool.lastNames) == 0 || rival.lastName < pool.oldLasts) {
    return false;
  }
  return !book.Has(StringToName(CBRivalBareName(content, rival)));
}

// The name without the part in quotes.
func CBRivalBareName(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> String {
  let pool = content.GetFactionNames(rival.faction);
  if !IsDefined(pool) {
    return "";
  }
  let name = "";
  if rival.firstName >= 0 && rival.firstName < ArraySize(pool.firstNames) {
    name = pool.firstNames[rival.firstName];
  }
  if rival.lastName >= 0 && rival.lastName < ArraySize(pool.lastNames) {
    name = name + " " + pool.lastNames[rival.lastName];
  }
  return name;
}

public func CBRivalEpithet(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> String {
  if !IsDefined(rival) {
    return "";
  }
  // After a break they are known for that, and nothing else (1.9.0). The one picked when they broke
  // (CBRivalPickBrokenEpithet), stored past CBBrokenEpithetBase in the same field.
  if CBRivalHasTrait(rival, n"Broken") && IsDefined(content) {
    let e = content.GetEpithets();
    if IsDefined(e) && ArraySize(e.broken) > 0 {
      let picked = rival.epithet - CBBrokenEpithetBase();
      if picked >= 0 && picked < ArraySize(e.broken) {
        return e.broken[picked];
      }
      return e.broken[CBHashIndex(rival.id, 9, ArraySize(e.broken))];
    }
  }
  let eps = CBEpithetsForSource(content, rival.source);
  if rival.epithet >= 0 && rival.epithet < ArraySize(eps) {
    return eps[rival.epithet];
  }
  return "";
}

// Full on-screen name, e.g. Kenji "Who Ran" Morita.
// A last-resort handle so nobody is ever called "Unknown". Keyed off the Rival id, so the
// same Rival always reads the same way.
public func CBRivalEarnedNickname(rival: ref<CBRival>) -> Bool {
  return IsDefined(rival) && (rival.rank >= 2 || rival.killedV > 0 || CBRivalHasTrait(rival, n"Broken"));
}

// Cyberpsychotic breaks (1.9.0).
//
// "Rivals who reach a breaking point keep pushing augments to get revenge on you, turning them into a
// roided-out Cyberpsycho." A Rival at the top of the ladder who loses to V again - gets away hurt, is
// spared, is shaken off - may break, with a chance that grows with every loss and never passes the
// ceiling. A break is the Broken trait, which fits a bit the trait mask already had spare, so no save
// changes shape. What it changes: the cyberpsycho's fighting kit instead of the Rival's own, holding
// their ground rather than ever breaking and running, a nickname for it, and different words. Not one
// point of health or armour on top of the build every Rival of that rank already gets, which is capped
// against stacking (CBApplyApexBuild): hard to put down, never impossible. No MaxTac, no police.
public func CBPsychoBreaksOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.IsEnabled() {
    return false;
  }
  return !rt.HasSettings() || rt.GetSettings().psychoBreaks;
}

public func CBRivalMaybeBreak(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>) -> Bool {
  if !IsDefined(sys) || !IsDefined(r) || !CBPsychoBreaksOn() || r.rank < 4
     || CBRivalHasTrait(r, n"Broken") || CBRecordIsSightingCyberpsycho(r.recordID)
     || CBRecordIsUniqueCharacter(r.recordID)
     || (r.state != EnumInt(ECBRivalState.Active) && r.state != EnumInt(ECBRivalState.Hunting)) {
    return false;
  }
  let losses = Cast<Float>(r.escapes + r.sparedByV);
  let chance = ClampF(CBConfig.PsychoBreakBase() + CBConfig.PsychoBreakPerLoss() * losses, 0.0, CBConfig.PsychoBreakMax());
  if RandF() >= chance {
    return false;
  }
  let content = CBContent(game);
  CBRivalPickBrokenEpithet(sys, content, r);
  CBRivalGiveTrait(r, n"Broken");
  if CBMessagesOn() && IsDefined(content) {
    CBHearsayFromStreet(game, s"Word is \(CBRivalDisplayName(content, r)) went back under the knife after you and came out wrong. Cyberpsycho now. Watch yourself.", n"");
  }
  CBLog.Info(n"Rivals", s"Rival \(r.id) broke: cyberpsycho (chance \(RoundF(chance * 100.0))%).");
  return true;
}

// A Rival's nickname after a break lives in the same field as the one they had (`epithet`), past this
// number, so no save changes shape and a value below it still reads as the old pool.
public func CBBrokenEpithetBase() -> Int32 = 1000

// One nobody else has: not another cyberpsycho on the roster, and not one this save has used before
// (the name book, as every nickname is since 1.8.5). Picked as they break. The first build hashed the
// id instead, so two who broke could carry the same one, which nicknames never do.
func CBRivalPickBrokenEpithet(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, r: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(r) {
    return;
  }
  let e = content.GetEpithets();
  if !IsDefined(e) || ArraySize(e.broken) == 0 {
    return;
  }
  let n = ArraySize(e.broken);
  let start = CBHashIndex(r.id, 9, n);
  let book = CBRivalNameBook.Get(sys.GetGameInstance());
  let pass = IsDefined(book) ? 0 : 1;
  while pass < 2 {
    let step = 0;
    while step < n {
      let idx = (start + step) % n;
      let word = e.broken[idx];
      let taken = false;
      for other in sys.GetRivals() {
        if IsDefined(other) && other.id != r.id && CBRivalHasTrait(other, n"Broken")
           && Equals(CBRivalEpithet(content, other), word) {
          taken = true;
        }
      }
      if !taken && (pass == 1 || !book.Has(CBEpithetBookKey(word))) {
        r.epithet = CBBrokenEpithetBase() + idx;
        if IsDefined(book) {
          book.Remember(CBEpithetBookKey(word));
        }
        return;
      }
      step += 1;
    }
    pass += 1;
  }
  r.epithet = CBBrokenEpithetBase() + start;
}

func CBFallbackHandle(id: Int32) -> String {
  switch CBHashIndex(id, 7, 8) {
    case 0: return "Nomad";
    case 1: return "Stray";
    case 2: return "Shade";
    case 3: return "Quill";
    case 4: return "Bishop";
    case 5: return "Crow";
    case 6: return "Vance";
    default: return "Dex";
  }
}

public func CBRivalDisplayName(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> String {
  if !IsDefined(rival) {
    return "A rival";
  }
  // Somebody the city already has a name for keeps it.
  let known = CBCyberpsychoName(rival.recordID);
  if StrLen(known) > 0 {
    return known;
  }
  // Falls back to a generic street handle rather than the literal word "Unknown", which is
  // what every Rival from an unpooled faction used to be called.
  let first = CBFallbackHandle(rival.id);
  let last = "";
  if IsDefined(content) {
    let pool = content.GetFactionNames(rival.faction);
    if IsDefined(pool) {
      if rival.firstName >= 0 && rival.firstName < ArraySize(pool.firstNames) {
        first = pool.firstNames[rival.firstName];
      }
      if rival.lastName >= 0 && rival.lastName < ArraySize(pool.lastNames) {
        last = pool.lastNames[rival.lastName];
      }
    }
  }
  // A nickname is earned (1.8.5): by moving up a rank, or by putting V down. A rank one Rival is
  // just their name, so the ones who have done something stand out, and the same few nicknames are
  // not on everybody.
  let epithet = CBRivalEarnedNickname(rival) ? CBRivalEpithet(content, rival) : "";
  let name = first;
  if StrLen(epithet) > 0 {
    name = name + " \"" + epithet + "\"";
  }
  if StrLen(last) > 0 {
    name = name + " " + last;
  }
  return name;
}

// Does this Rival carry the named trait? Traits live in a bit set on the Rival rather
// than a stored list (see CBRival.traitMask), so this is a plain integer test.
public func CBRivalHasTrait(rival: ref<CBRival>, id: CName) -> Bool {
  if !IsDefined(rival) {
    return false;
  }
  return CBMaskHas(rival.traitMask, CBTraitBit(id));
}

public func CBRivalGiveTrait(rival: ref<CBRival>, id: CName) -> Void {
  if !IsDefined(rival) {
    return;
  }
  let bit = CBTraitBit(id);
  if bit >= 0 {
    rival.traitMask = CBMaskSet(rival.traitMask, bit);
  }
}

public func CBRivalTakeTrait(rival: ref<CBRival>, id: CName) -> Void {
  if !IsDefined(rival) {
    return;
  }
  let bit = CBTraitBit(id);
  if bit >= 0 {
    rival.traitMask = CBMaskClear(rival.traitMask, bit);
  }
}

public func CBRivalTraitCount(rival: ref<CBRival>) -> Int32 {
  if !IsDefined(rival) {
    return 0;
  }
  return CBMaskCount(rival.traitMask, CBTraitCount());
}

// Add one random non-weakness trait not already present (deterministic by id).
public func CBRivalAddTrait(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  if !IsDefined(content) || !IsDefined(rival) {
    return;
  }
  let pool: array<CName>;
  for t in content.GetTraits() {
    if IsDefined(t) && !t.isWeakness && !CBRivalHasTrait(rival, t.id) && CBTraitBit(t.id) >= 0
       && NotEquals(t.id, n"Broken") {
      ArrayPush(pool, t.id);
    }
  }
  if ArraySize(pool) > 0 {
    let idx = CBHashIndex(rival.id, 11 + CBRivalTraitCount(rival), ArraySize(pool));
    CBRivalGiveTrait(rival, pool[idx]);
  }
}

// Create and register a Rival. Returns null if caps are full (spec §10.1).
// Is this somebody the game wrote, rather than a face in a crowd?
//
// A Rival is built by respawning a character record, which is fine for a generic ganger and
// wrong for anybody the story owns: respawning them puts a named individual the player has
// already dealt with back on the street, and does it with Rival buffs on top. A player
// reported exactly that - LT Mower, a cyberpsycho they had just killed, waiting outside their
// apartment and effectively unkillable, because a cyberpsycho's own health is enormous before
// the apex-grade buff a Rival gets is applied to it.
//
// The game marks these in the character record itself: cyberpsycho records carry
// `tags += [ "Cyberpsycho" ]`. That is the reliable test, and it is read here rather than
// guessed from the record's name. Boss and MaxTac rarity are refused for the same reason, and
// the name check stays as a backstop for anything tagged inconsistently.
public func CBRecordIsUniqueCharacter(recordID: TweakDBID) -> Bool {
  if !TDBID.IsValid(recordID) {
    return true;   // nothing to spawn from; refusing is the safe answer
  }
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if IsDefined(rec) {
    if rec.TagsContains(n"Cyberpsycho") || rec.TagsContains(n"Boss") {
      return true;
    }
    let rarity = rec.Rarity();
    if IsDefined(rarity) {
      let t = rarity.Type();
      if Equals(t, gamedataNPCRarity.Boss) || Equals(t, gamedataNPCRarity.MaxTac) {
        return true;
      }
    }
    // Does the story own this person?
    //
    // This is the test that was missing, and the report that found it could not be clearer:
    // "I got the rival is hunting you prompt, only instead of the rival, an immortal Panam
    // spawns in with a sniper rifle." Panam carries no Boss tag and is not Boss rarity, her
    // record id contains none of the words below, and `ScriptedPuppet.IsQuest` - which the
    // capture path does check - is a property of a live puppet in a quest, not of the record,
    // so a record that reached the roster by any other door walked straight through.
    //
    // `Character_Record.Quest()` is the record's own quest affiliation, and it is exactly the
    // right question: `MainQuest`, `SideQuest`, `MinorQuest` and `StreetStory` are people the
    // game has written and placed, while generic gangers are `General`. `MinorActivity` is the
    // deliberate exception and the narrower CBRecordIsSightingCyberpsycho test below is built
    // on it - a cyberpsycho from a sighting is the one person the story does not come back for.
    let quest = rec.Quest();
    if IsDefined(quest) {
      let affiliation = quest.Type();
      if Equals(affiliation, gamedataNPCQuestAffiliation.MainQuest)
         || Equals(affiliation, gamedataNPCQuestAffiliation.SideQuest)
         || Equals(affiliation, gamedataNPCQuestAffiliation.MinorQuest)
         || Equals(affiliation, gamedataNPCQuestAffiliation.StreetStory) {
        return true;
      }
    }
    // Authored to have a boss health bar. `bossHealthBarThresholds` is only filled in on
    // records the game intends to put a bar across the top of the screen for, which is a
    // statement that this is a set piece rather than a kind of enemy. Cheap, structural, and it
    // catches anyone the affiliation test misses.
    if rec.GetBossHealthBarThresholdsCount() > 0 {
      return true;
    }
  }
  let id = TDBID.ToStringDEBUG(recordID);
  return StrContains(id, "cyberpsycho") || StrContains(id, "Cyberpsycho")
      || StrContains(id, "_psycho") || StrContains(id, "boss");
}

// Take anybody the game owns off the roster.
//
// CBCreateRival refuses unique characters now, but a roster written before that guard existed
// still holds them, and they are the worst case it was added for: a cyberpsycho's own health is
// enormous before a Rival's apex-grade multiplier goes on top of it, so what turns up is
// something the player empties magazines into for nothing. That has now been reported twice, as
// an unkillable enemy nobody could name. Refusing new ones does not clear the ones already
// written down, so they are cleared here, once a session, by the same test.
// Is this record a person? Drones, mechs, spiderbots, androids and the rest are not, and none of
// them may become a Rival or a gang's spawn template. A Maelstrom drone that got away was being
// made a Rival, given a boss-grade build and sent back again and again: the near-immortal
// missile drone a player reported being stuck in a loop with.
public func CBRecordIsPerson(recordID: TweakDBID) -> Bool {
  if !TDBID.IsValid(recordID) {
    return false;
  }
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if !IsDefined(rec) {
    return false;
  }
  let kind = rec.CharacterType();
  if IsDefined(kind) {
    let t = kind.Type();
    if Equals(t, gamedataNPCType.Drone) || Equals(t, gamedataNPCType.Mech)
       || Equals(t, gamedataNPCType.Spiderbot) || Equals(t, gamedataNPCType.Android)
       || Equals(t, gamedataNPCType.Cerberus) || Equals(t, gamedataNPCType.Chimera)
       || Equals(t, gamedataNPCType.Device) {
      return false;
    }
  }
  // A record without a type is judged by its name, so a drone filed without one is still caught.
  let id = StrLower(TDBID.ToStringDEBUG(recordID));
  return !StrContains(id, "drone") && !StrContains(id, "android") && !StrContains(id, "mech_")
      && !StrContains(id, "robot") && !StrContains(id, "spiderbot") && !StrContains(id, "turret");
}

// Not fit to be a gang's template: somebody the story owns, or not a person at all.
public func CBRecordUnfitTemplate(recordID: TweakDBID) -> Bool {
  return CBRecordIsUniqueCharacter(recordID) || !CBRecordIsPerson(recordID)
      || CBRecordDrawsPolice(recordID);
}

// Would shooting this person bring the law down on V?
//
// "When Barghest ambushes you, it gives you wanted stars immediately, even when you are out of
// Dogtown." In Dogtown the Barghest are the police. The game's prevention_dogtown_ records wear
// their colours and carry the Barghest affiliation, but they descend from prevention_unit_base and
// use a Police reaction preset, so anything that hurts one is a crime
// (PreventionSystem.ShouldPreventionSystemReactToDamageDealt: IsPrevention, or the
// TriggerPrevention tag). Cyberbane files spawn templates from whoever V fights, sorted by
// affiliation, so one such kill made every crew and Rival that gang sent afterwards a police unit,
// and the first shot at them anywhere the law operates raised the stars. Dogtown has no prevention
// of its own to raise, which is why it only ever happened outside it. The same is true of the
// other prevention_ uniforms (Aldecaldos, Militech) and of anybody NCPD.
//
// This is the game's own test, made on the record instead of a live body: IsPrevention is
// IsCharacterPolice, which is a Police reaction group (ScriptedPuppet.RefreshCachedReactionPresetData).
public func CBRecordDrawsPolice(recordID: TweakDBID) -> Bool {
  if !TDBID.IsValid(recordID) {
    return false;
  }
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if !IsDefined(rec) {
    return false;
  }
  if rec.TagsContains(n"TriggerPrevention") || rec.TagsContains(n"InActivePoliceChase") {
    return true;
  }
  let preset = rec.ReactionPreset();
  return IsDefined(preset) && Equals(preset.ReactionGroup(), "Police");
}

public func CBPruneUniqueRivals(sys: ref<CyberbaneSystem>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  // The spawn templates each gang has on file, for the same reason and by the same test. These
  // are what crews and apex squads are built from, so one bad record here is not one bad enemy,
  // it is every enemy that gang sends from now on.
  let wiped = 0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) {
      if TDBID.IsValid(fs.sampleRecord) && CBRecordUnfitTemplate(fs.sampleRecord) {
        fs.sampleRecord = TDBID.None(); wiped += 1;
      }
      if TDBID.IsValid(fs.eliteRecord) && CBRecordUnfitTemplate(fs.eliteRecord) {
        fs.eliteRecord = TDBID.None(); wiped += 1;
      }
      if TDBID.IsValid(fs.roleTankRecord) && CBRecordUnfitTemplate(fs.roleTankRecord) {
        fs.roleTankRecord = TDBID.None(); wiped += 1;
      }
      if TDBID.IsValid(fs.roleAssaultRecord) && CBRecordUnfitTemplate(fs.roleAssaultRecord) {
        fs.roleAssaultRecord = TDBID.None(); wiped += 1;
      }
      if TDBID.IsValid(fs.roleBladeRecord) && CBRecordUnfitTemplate(fs.roleBladeRecord) {
        fs.roleBladeRecord = TDBID.None(); wiped += 1;
      }
      if TDBID.IsValid(fs.roleNetrunnerRecord) && CBRecordUnfitTemplate(fs.roleNetrunnerRecord) {
        fs.roleNetrunnerRecord = TDBID.None(); wiped += 1;
      }
      // A netrunner filed as the crew template before 1.8.5 moves to the netrunner's chair, and the
      // crew is built from a fighter again.
      if TDBID.IsValid(fs.sampleRecord) && CBRecordIsNetrunner(fs.sampleRecord) {
        if !TDBID.IsValid(fs.roleNetrunnerRecord) {
          fs.roleNetrunnerRecord = fs.sampleRecord;
        }
        fs.sampleRecord = TDBID.IsValid(fs.roleAssaultRecord) ? fs.roleAssaultRecord : fs.roleBladeRecord;
      }
      if TDBID.IsValid(fs.eliteRecord) && CBRecordIsNetrunner(fs.eliteRecord) {
        fs.eliteRecord = TDBID.None();
      }
      // A gang left with no crew template would stop sending anybody until V next killed one of
      // theirs, so it falls back on its own rank and file.
      if !TDBID.IsValid(fs.sampleRecord) && CBFactionFieldsSquads(fs.id) {
        fs.sampleRecord = CBApexRosterRecord(fs.id, 1);
      }
    }
  }
  if wiped > 0 {
    CBLog.Info(n"Rivals", s"Dropped \(wiped) spawn template(s) built from story characters; the gangs will file new ones from their next losses.");
  }
  let dropped = 0;
  let enlisted = 0;
  for r in sys.GetRivals() {
    // A Rival built from a police record keeps their name, rank and grudge and comes back as one
    // of their gang's own people, so fighting them is a fight rather than a crime. Anybody who
    // really is the law has no gang to fall back on and is retired below.
    if IsDefined(r) && CBRecordDrawsPolice(r.recordID) {
      let swap = CBApexRosterRecord(r.faction, 1);
      if TDBID.IsValid(swap) {
        r.recordID = swap;
        r.appearance = n"";
        enlisted += 1;
      }
    }
    if IsDefined(r)
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting)
           || r.state == EnumInt(ECBRivalState.Dormant))
       && (!CBRecordIsPerson(r.recordID) || CBRecordDrawsPolice(r.recordID)
           || CBRecordIsUniqueCharacter(r.recordID)
              && !(r.source == EnumInt(ECBRivalSource.Spared)
                   && CBRecordIsSightingCyberpsycho(r.recordID))) {
      r.state = EnumInt(ECBRivalState.Retired);
      dropped += 1;
    }
  }
  if dropped > 0 {
    CBLog.Info(n"Rivals", s"Retired \(dropped) rival(s) built from story characters or the police; they will not come back.");
  }
  if enlisted > 0 {
    CBLog.Info(n"Rivals", s"\(enlisted) rival(s) built from police records are their gang's own people now, so fighting them draws no heat.");
  }
  // Worth knowing: this prune is what clears a story character already written into a save.
  // CBRecordIsUniqueCharacter got the quest-affiliation test in 1.4.7, so the sweep that has
  // run once a session since 1.4.0 now catches the ones it used to walk past - which is how a
  // Panam on somebody's roster goes away without them starting a new game.
}

// Is this one of Regina's cyberpsychos?
//
// Deliberately narrower than CBRecordIsUniqueCharacter, and the narrowing is the whole point.
// The broad test refuses everybody the story owns, which is right for a gang's spawn template
// and right for anyone the main quest needs where it left them. A cyberpsycho you chose to
// leave breathing is the one exception worth making: the game asks you to take them alive and
// then never follows it up, and somebody who survived you is exactly what a Rival is.
//
// The Cyberpsycho tag on its own is not enough, and this is worth writing down because it is a
// trap that looks safe. `main_boss_adam_smasher` carries that tag. So do Placide and Woodman.
// Rarity cannot separate them either: the sighting psychos are NPCRarity.Boss as well. What
// does separate them is the quest affiliation. Every record under
// characters/npcs/records/quest/minor_activities carries
// `quest = "NPCQuestAffiliation.MinorActivity"`, and no story boss does.
public func CBRecordIsSightingCyberpsycho(recordID: TweakDBID) -> Bool {
  if !TDBID.IsValid(recordID) {
    return false;
  }
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if !IsDefined(rec) || !rec.TagsContains(n"Cyberpsycho") {
    return false;
  }
  let q = rec.Quest();
  return IsDefined(q) && Equals(q.Type(), gamedataNPCQuestAffiliation.MinorActivity);
}

// Their own name, because everyone knows it.
//
// The generated handles are for gangers nobody has heard of. Calling the person from the
// sighting anything other than what the game called them reads as a different character, which
// throws away the only thing that makes this worth doing.
public func CBCyberpsychoName(recordID: TweakDBID) -> String {
  if !CBRecordIsSightingCyberpsycho(recordID) {
    return "";
  }
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if !IsDefined(rec) {
    return "";
  }
  let key = rec.DisplayName();
  if Equals(key, n"") {
    return "";
  }
  return GetLocalizedTextByKey(key);
}

// May this one come back, and does the coin say so?
//
// Only on a spare, because that is the choice that earns it. Killing one ends it, and nothing
// here should quietly undo a fight the player won. Half the time, so leaving one alive is a
// risk you take rather than a sequel you have booked. And only while the Rival list has room,
// which the cap below already enforces for everybody.
func CBCyberpsychoMayReturn(recordID: TweakDBID, source: ECBRivalSource) -> Bool {
  if NotEquals(source, ECBRivalSource.Spared) || !CBRecordIsSightingCyberpsycho(recordID) {
    return false;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().cyberpsychoRivals {
    return false;
  }
  return RandF() < CBConfig.CyberpsychoRivalChance();
}

// ---- How likely somebody is to come back as a Rival (the 1.9.0 bug pass) ----------------------
//
// Every way of becoming a Rival rolled one flat number, whoever the person was and however many had
// just been made. Two things followed. A grunt who ran was as likely to swear revenge as the officer
// leading them, so a name meant nothing about who it was. And one fight could make a crowd: a room put
// to sleep turned a Rival out of three bodies in four until the gang's limit stopped it, with a text and
// a rumour for each, so the roster filled in a minute and the next new name was nobody in particular.
// The Rival frequency setting also reached only two of the five rolls.
//
// Now one function answers for every roll: the base for that way of becoming one, times the frequency
// setting, times how much the person counted for (CBRivalRarityWeight), divided by one more than the
// number of Rivals already made in the last few minutes, so the second name a fight makes is half as
// likely and the third a third. The ceiling goes last. A death (the Killer) is not a roll and is not
// touched, and neither is the empty roster's first name (CBSeedRivalFromFactions).
public func CBRivalRarityWeight(recordID: TweakDBID) -> Float {
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if !IsDefined(rec) {
    return 1.0;
  }
  let rarity = rec.Rarity();
  if !IsDefined(rarity) {
    return 1.0;
  }
  let t = rarity.Type();
  if Equals(t, gamedataNPCRarity.Trash) { return 0.5; }
  if Equals(t, gamedataNPCRarity.Weak) { return 0.7; }
  if Equals(t, gamedataNPCRarity.Rare) { return 1.1; }
  if Equals(t, gamedataNPCRarity.Officer) { return 1.25; }
  if Equals(t, gamedataNPCRarity.Elite) { return 1.4; }
  if Equals(t, gamedataNPCRarity.Boss) { return 1.5; }
  if Equals(t, gamedataNPCRarity.MaxTac) { return 0.0; }
  return 1.0;
}

public func CBRivalOdds(sys: ref<CyberbaneSystem>, base: Float, recordID: TweakDBID, byRank: Bool) -> Float {
  let odds = base;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    odds *= rt.GetSettings().rivalFrequencyMult;
  }
  if byRank {
    odds *= CBRivalRarityWeight(recordID);
  }
  if IsDefined(sys) {
    odds = odds / (1.0 + Cast<Float>(sys.RecentRivalsMade(CBConfig.RivalBurstTicks())));
  }
  return ClampF(odds, 0.0, CBConfig.RivalOddsCeiling());
}

// Roll it, and say what the odds were: "harder to make Rivals" has been reported before, and the
// log is the only place the number can be read.
public func CBRivalRoll(sys: ref<CyberbaneSystem>, what: String, base: Float, recordID: TweakDBID, byRank: Bool) -> Bool {
  let odds = CBRivalOdds(sys, base, recordID, byRank);
  let hit = RandF() < odds;
  let outcome = hit ? "a Rival" : "not this time";
  CBLog.Info(n"Rivals", s"Rival roll, \(what): \(RoundF(odds * 100.0))%, \(outcome).");
  return hit;
}

// `quiet` leaves out the "has your name now" text, for a caller that sends its own line about the same
// moment (a death). `counted` says the roll already counted this Rival towards the burst damping in
// CBRivalOdds, as a birth held until the fight is over does (Rivals/Births.reds), so it is not counted
// twice. Both 1.9.1.
public func CBCreateRival(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName,
    recordID: TweakDBID, appearance: CName, source: ECBRivalSource, origin: CName, at: Float,
    opt quiet: Bool, opt counted: Bool) -> ref<CBRival> {
  if !IsDefined(sys) {
    return null;
  }
  // A faction the player switched off under Factions in Mod Settings keeps no Rivals (1.9.1).
  if !CBFactionOn(faction) {
    CBLog.Info(n"Rivals", s"No new Rival from \(NameToString(faction)): switched off in Mod Settings.");
    return null;
  }
  // One gate, here, because eight different places create Rivals and several hand over a
  // record straight off a puppet. Guarding each of them would mean missing one. The single
  // exception is a spared cyberpsycho, on a coin flip; see CBCyberpsychoMayReturn.
  if CBRecordIsUniqueCharacter(recordID) && !CBCyberpsychoMayReturn(recordID, source) {
    return null;
  }
  // People only: never a drone, mech or robot (CBRecordIsPerson).
  if !CBRecordIsPerson(recordID) {
    return null;
  }
  // Never the police. Somebody in a police uniform who survives V comes back as one of their
  // gang's own people; the law itself keeps no Rivals (CBRecordDrawsPolice).
  if CBRecordDrawsPolice(recordID) {
    recordID = CBApexRosterRecord(faction, 1);
    appearance = n"";
    if !TDBID.IsValid(recordID) {
      return null;
    }
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().rivals {
    return null;
  }
  let maxRivals = CBConfig.RivalMaxActiveHardCap();
  if IsDefined(rt) && rt.HasSettings() {
    maxRivals = rt.GetSettings().maxRivals;
  }
  // Both limits used to refuse in silence, so "no new Rivals" could not be told apart from a fault.
  if sys.CountActiveRivals() >= maxRivals {
    if sys.TakeRivalCapLog() {
      CBLog.Info(n"Rivals", s"No new Rival: you already have \(maxRivals), the Max rivals setting.");
    }
    return null;
  }
  if sys.CountActiveFactionRivals(faction) >= CBConfig.RivalMaxPerFaction() {
    if sys.TakeRivalCapLog() {
      CBLog.Info(n"Rivals", s"No new Rival from \(NameToString(faction)): they already have \(CBConfig.RivalMaxPerFaction()) after you.");
    }
    return null;
  }

  let r = new CBRival();
  r.id = sys.AllocateRivalId();
  r.recordID = recordID;
  r.appearance = appearance;
  r.faction = faction;
  r.rank = 1;
  r.source = EnumInt(source);
  r.state = EnumInt(ECBRivalState.Active);
  r.origin = origin;
  r.createdAt = at;
  r.lastSeenAt = at;

  let content = CBContent(game);
  CBRivalGenerateName(content, r);
  CBRivalPickFreeName(game, sys, content, r);
  CBRivalPickFreeEpithet(sys, content, r);
  CBRivalAddTrait(content, r);
  if Equals(source, ECBRivalSource.Spared) {
    CBRivalGiveTrait(r, n"Humiliated");
  }
  // Somebody out for revenge is not thinking about their own skin.
  if Equals(source, ECBRivalSource.Avenger) {
    CBRivalGiveTrait(r, n"Reckless");
  }

  sys.AddRival(r);
  if !counted {
    sys.NoteRivalMade();   // so the next roll in the same fight is less likely (CBRivalOdds)
  }
  // A new name in a crew may be the only one left standing in it (spec §10.1).
  CBHierarchyFill(sys, faction);

  CBLogRival(sys, n"RivalCreated", at, origin, faction, Cast<Float>(r.id), r.id);
  if CBMessagesOn() && !quiet {
    CBPhoneFromGang(game, faction, CBRivalDisplayName(content, r) + " has your name now. That is on you.");
  }
  CBLog.Info(n"Rivals", s"Rival created id=\(r.id) faction=\(NameToString(faction)).");
  return r;
}

public func CBPromoteRival(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float) -> Void {
  if !IsDefined(rival) || rival.rank >= 4 {
    return;
  }
  rival.rank += 1;
  CBRivalAddTrait(content, rival);
}

// --- State transitions (spec §10.6) ------------------------------------

public func CBRivalEscaped(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName, lowHp: Bool) -> Void {
  if !IsDefined(rival) {
    return;
  }
  rival.escapes += 1;
  rival.lastSeenAt = at;
  CBPromoteRival(rival, content, at);
  // Getting away half dead leaves a mark, and getting away half dead twice leaves one that does
  // not heal right.
  if lowHp {
    if CBRivalHasTrait(rival, n"Scarred") {
      CBRivalGiveTrait(rival, n"OldWound");
    }
    CBRivalGiveTrait(rival, n"Scarred");
  }
}

public func CBRivalKilledV(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName) -> Void {
  if !IsDefined(rival) {
    return;
  }
  rival.killedV += 1;
  CBRivalTakeTrait(rival, n"Shaken");
  CBRivalGiveTrait(rival, n"Confident");
  CBPromoteRival(rival, content, at);
}

// Returns true if the Rival became a Debtor (retires via a redemption tip).
public func CBRivalSparedByV(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName) -> Bool {
  if !IsDefined(rival) {
    return false;
  }
  rival.sparedByV += 1;
  // Being let go by the person you came to kill stays with you.
  CBRivalGiveTrait(rival, n"Shaken");
  if rival.sparedByV >= 2 && RandF() < 0.5 {
    rival.state = EnumInt(ECBRivalState.Debtor);
    return true;
  }
  CBPromoteRival(rival, content, at);
  return false;
}

// Slay a Rival (spec §10.7): archive it, award renown, bump stats, log.
// Work out which Rival a dead CB_Rival puppet was.
//
// This used to rely solely on CyberbaneSystem's "active rival id". That id is cleared
// whenever an encounter is retired, so a Rival who was spawned, left alone long enough to be
// retired, and then killed anyway counted for nothing - which is what players hit when they
// killed one and the Hub never registered it. Falling back to a hunting Rival of the same
// faction catches those, and returns null rather than guessing when there is no match.
// Which Rival, if any, Cyberbane spawned as this exact body.
//
// The surest match there is: the entity was recorded at spawn, and unlike the CB_Rival tag
// nothing can clear it out from under us. Safe to use even on an untagged corpse, because it
// only ever matches a body we created ourselves.
public func CBFindRivalByBody(sys: ref<CyberbaneSystem>, body: EntityID) -> ref<CBRival> {
  if !IsDefined(sys) || !EntityID.IsDefined(body) {
    return null;
  }
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && EntityID.IsDefined(r.spawnedEntityId) && Equals(r.spawnedEntityId, body) {
      return r;
    }
  }
  return null;
}

public func CBResolveSlainRival(sys: ref<CyberbaneSystem>, puppet: ref<ScriptedPuppet>) -> ref<CBRival> {
  if !IsDefined(sys) || !IsDefined(puppet) {
    return null;
  }
  let byBody = CBFindRivalByBody(sys, puppet.GetEntityID());
  if IsDefined(byBody) {
    return byBody;
  }
  let activeId = sys.GetActiveRivalId();
  if activeId > 0 {
    let byId = sys.FindRivalById(activeId);
    if IsDefined(byId) {
      return byId;
    }
  }
  let faction = CBClassifyFaction(puppet);
  if Equals(faction, n"") {
    return null;
  }
  let rivals = sys.GetRivals();
  let i = 0;
  while i < ArraySize(rivals) {
    let r = rivals[i];
    i += 1;
    if IsDefined(r) && Equals(r.faction, faction)
       && (r.state == EnumInt(ECBRivalState.Hunting) || r.state == EnumInt(ECBRivalState.Active)) {
      return r;
    }
  }
  return null;
}

// The fight with this Rival is over, however it ended. Tidy up after it.
//
// Three things have to happen when a Rival stops being a live encounter, and before this
// existed each caller remembered its own subset. The lethal path did all three through
// OnDeath, the escape path did two, and the mercy path did none, which is where the stuck
// markers and the apparently teleporting Rivals came from. One function, called from all of
// them, so a new ending cannot miss a step.
//
// `body` is optional: pass the puppet when the caller has it so the marker comes off the
// right one, or leave it null and the tagged sweep handles it.
public func CBCloseRivalEncounter(sys: ref<CyberbaneSystem>, game: GameInstance,
                                  rival: ref<CBRival>, body: wref<ScriptedPuppet>) -> Void {
  if !IsDefined(sys) {
    return;
  }
  // 1. The marker. Registered against the puppet, so it outlives the encounter unless it is
  //    explicitly unregistered - a body that never dies never loses its pin. Their own body, by the
  //    puppet when the caller has it and by the id on record when not; then any Rival body nobody
  //    owns. Never every CB_Rival: with Rivals out together that took the markers off the living.
  if IsDefined(body) {
    CBUntrackOnMap(game, body);
  }
  if IsDefined(rival) && EntityID.IsDefined(rival.spawnedEntityId) {
    let recorded = GameInstance.FindEntityByID(game, rival.spawnedEntityId) as ScriptedPuppet;
    if IsDefined(recorded) {
      CBUntrackOnMap(game, recorded);
    }
  }

  // 1b. A body still in the world - lying there breathing, or walking off - is nobody's encounter
  //     any more, and must stop reading as one. It kept the CB_Rival tag, so when it streamed back
  //     in it was set up again as the active Rival (CBApplySpawnSetup falls back to them for a body
  //     it cannot place), given that Rival's name and a fresh marker that nothing ever took down,
  //     because the body never died and never left. And if it did die, the death handler fell back
  //     the same way and could put the wrong Rival in the ground. The dead are the death handler's.
  if IsDefined(body) && !body.IsDead() {
    CBRetireRivalBody(sys, game, body, rival);
  }

  // 2. The encounter slot, so the lanes know nothing is out and the next one can be queued.
  if IsDefined(rival) {
    let wasLead = sys.GetActiveRivalId() == rival.id;
    if wasLead {
      sys.SetActiveRivalId(0);
    }
    // Forget which body was theirs. Keeping it would leave CBFindRivalByBody matching an
    // entity that is no longer part of an encounter.
    let none: EntityID;
    rival.spawnedEntityId = none;
    sys.RemovePackRival(rival.id);   // no longer one of a team that came together (1.9.0)
    // 3. And a cooldown, so they do not walk straight back into the fight they just lost.
    //    Without this the gate clears the moment they go down and they are re-queued at once.
    if rival.huntTicks < CBConfig.RivalAfterEscapeTicks() {
      rival.huntTicks = CBConfig.RivalAfterEscapeTicks();
    }
    // 4. Whoever came with them carries the encounter on (Spawn/RivalEncounter.reds). Thirty-odd
    //    readers ask "the active Rival" one question or another; with the lead down and nobody
    //    active, a partner still fighting V was nobody's encounter to any of them.
    if wasLead {
      CBPackHandOffLead(sys);
    }
  } else {
    sys.SetActiveRivalId(0);
    CBPackHandOffLead(sys);
  }
  CBUntrackStrayRivalBodies(sys, game);
}

// Is this Rival body somebody's encounter right now? Their body on record, or - while a Rival's car
// is still being adopted (Spawn/Arrival.reds), when the body is not on record yet - any Rival body,
// so nothing arriving is mistaken for a stray.
public func CBRivalBodyIsLive(sys: ref<CyberbaneSystem>, id: EntityID) -> Bool {
  if !IsDefined(sys) {
    return true;
  }
  let owner = CBFindRivalByBody(sys, id);
  if IsDefined(owner)
     && (owner.state == EnumInt(ECBRivalState.Active) || owner.state == EnumInt(ECBRivalState.Hunting)) {
    return true;
  }
  if sys.GetRivalCarPending() > 0 {
    return true;
  }
  let active = sys.FindRivalById(sys.GetActiveRivalId());
  return IsDefined(active) && !EntityID.IsDefined(active.spawnedEntityId);
}

// Living Rival bodies that are nobody's encounter, removed once V cannot see them (1.9.0). What the
// deferred sweep after a death and the escape ending used to do to every CB_Rival; anybody still a
// live Rival's is left alone. One that cannot go now is handed to the orphan sweep, the way
// CBDeleteTaggedSafe hands one over. The dead are the remains sweep's.
public func CBSweepStrayRivalBodies(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(des) || !des.IsPopulated(n"CB_Rival") {
    return;
  }
  let crewSeated = CBAnyCrewSeated(game, des);
  let ids = des.GetTaggedIDs(n"CB_Rival");
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    let body = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if !CBRivalBodyIsLive(sys, id) && !(IsDefined(body) && body.IsDead())
       && !CBRemoveOne(game, des, id, crewSeated, true) {
      des.UnassignTag(id, n"CB_Rival");
      des.AssignTag(id, n"CB_Orphan");
    }
  }
}

// The markers on the same strays.
public func CBUntrackStrayRivalBodies(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(des) || !des.IsPopulated(n"CB_Rival") {
    return;
  }
  let ids = des.GetTaggedIDs(n"CB_Rival");
  let i = 0;
  while i < ArraySize(ids) {
    let id = ids[i];
    i += 1;
    let body = GameInstance.FindEntityByID(game, id) as ScriptedPuppet;
    if IsDefined(body) && !CBRivalBodyIsLive(sys, id) {
      CBUntrackOnMap(game, body);
    }
  }
}

// The tags that make a body a Rival's come off, and it joins the bodies the orphan sweep clears once
// V cannot see them (CBSweepOrphans), which is where CBDeleteTaggedSafe has always put one it could
// not take. Who it belonged to is remembered for the rest of the session, so V finishing them later
// still finishes that Rival (CBOnPuppetDeath). The same tag calls CBLairPromote moves a body with.
func CBRetireRivalBody(sys: ref<CyberbaneSystem>, game: GameInstance, body: wref<ScriptedPuppet>, rival: ref<CBRival>) -> Void {
  let des = GameInstance.GetDynamicEntitySystem();
  if !IsDefined(sys) || !IsDefined(des) || !IsDefined(body) {
    return;
  }
  let id = body.GetEntityID();
  if des.IsTagged(id, n"CB_Rival") {
    des.UnassignTag(id, n"CB_Rival");
  }
  if des.IsTagged(id, n"CB_Lair") {
    des.UnassignTag(id, n"CB_Lair");
  }
  if des.IsTagged(id, n"Cyberbane") && !des.IsTagged(id, n"CB_Orphan") {
    des.AssignTag(id, n"CB_Orphan");
  }
  if IsDefined(rival) {
    sys.NoteFormerRivalBody(id, rival.id);
  }
}

// Forget every Rival on this save. Offered because a mod update mid-playthrough can leave
// Rivals that no longer line up with the records they were built from, and there was no way
// to clear them short of starting over.
public func CBPurgeRivals(sys: ref<CyberbaneSystem>, game: GameInstance) -> Int32 {
  if !IsDefined(sys) {
    return 0;
  }
  // Where they were seen, and the pin on anybody's place, go with them (Rivals/Whereabouts.reds).
  let svc = sys.GetPlayService();
  if IsDefined(svc) {
    svc.DropSightingsUpTo(sys.GetPlaythroughId(), sys.HighestRivalId());
  }
  CBDropLead(sys, game);
  CBLairStandDown(sys, game);
  let removed = sys.ClearRivals();
  sys.SetActiveRivalId(0);
  sys.ClearPack();
  sys.ClearPendingBirths();   // nor anybody still waiting for a fight to be over (1.9.1)
  CBDeleteTaggedSafe(game, n"CB_Rival");
  CBLog.Info(n"Rivals", s"Purged \(removed) rivals at the player's request.");
  return removed;
}

// Can this one be forgotten right now? Not while a car is bringing them: their body arrives as a
// Rival's and is adopted as one, and with nobody left to adopt it as, it would be a nameless hunter.
public func CBRivalForgettable(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> Bool {
  return IsDefined(sys) && IsDefined(r) && sys.GetRivalCarPending() != r.id;
}

// Forget one Rival (the Hub, 1.8.2). Everything "Forget every rival" does (CBPurgeRivals), for one of
// them, from the settled tick (CyberbaneSystem.ServiceHubActions). Their place, the pin on it and the
// waiting body go; one out after V ends the way every encounter does, and the body leaves once V
// cannot see it; their chair is filled. Returns their name, or "" when there was nobody to forget.
public func CBForgetRival(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let r = sys.FindRivalById(id);
  if !IsDefined(r) {
    return "";
  }
  if !CBRivalForgettable(sys, r) {
    CBLog.Info(n"Rivals", s"Rival \(id) is on their way in a car; not forgotten.");
    return "";
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let svc = sys.GetPlayService();
  if IsDefined(svc) {
    // Noted when it was chosen; again here in case the menu could not reach the service.
    svc.NoteForgetRival(sys.GetPlaythroughId(), id, r.recordID);
    svc.DropSighting(sys.GetPlaythroughId(), id);
  }
  if sys.IsLeadPinned() && sys.GetLeadPinRival() == id {
    CBDropLead(sys, game);
  }
  if sys.IsLairActive() && sys.GetLairRivalId() == id {
    CBLairStandDown(sys, game);
  }
  if sys.GetActiveRivalId() == id || EntityID.IsDefined(r.spawnedEntityId) {
    let body: wref<ScriptedPuppet>;
    if EntityID.IsDefined(r.spawnedEntityId) {
      body = GameInstance.FindEntityByID(game, r.spawnedEntityId) as ScriptedPuppet;
    }
    CBCloseRivalEncounter(sys, game, r, body);
    // Nobody's at all now, not even a Rival's that was (CBRetireRivalBody).
    if IsDefined(body) {
      sys.TakeFormerRivalBody(body.GetEntityID());
    }
  }
  if sys.GetRivalWarned() == id {
    sys.SetRivalWarned(0);
  }
  let faction = r.faction;
  sys.RemoveRivalById(id);
  CBHierarchyFill(sys, faction);
  CBLog.Info(n"Rivals", s"Forgot rival \(id) at the player's request.");
  return name;
}

public func CBRivalSlain(sys: ref<CyberbaneSystem>, game: GameInstance, rival: ref<CBRival>, at: Float, district: CName) -> Void {
  if !IsDefined(sys) || !IsDefined(rival) {
    return;
  }
  rival.state = EnumInt(ECBRivalState.Slain);
  rival.lastSeenAt = at;

  let stats = sys.GetStats();
  if IsDefined(stats) {
    stats.rivalsSlain += 1;
  }
  let renownMult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    renownMult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints((25.0 + 10.0 * Cast<Float>(rival.rank)) * renownMult);

  CBLogRival(sys, n"RivalSlain", at, district, rival.faction, Cast<Float>(rival.rank), rival.id);
  // A name of theirs in the ground costs a gang more than a body does (Model/Territory.reds).
  CBWeakenGang(sys, game, rival.faction,
               CBConfig.GangLossRival() + CBConfig.GangLossRivalPerRank() * Cast<Float>(rival.rank));
  // Their chair does not stay empty (spec §10.1).
  CBHierarchyOnSlain(sys, game, rival);
  let content = CBContent(game);
  if CBMessagesOn() {
    CBHearsayFromStreet(game, CBRivalDisplayName(content, rival) + " is dead and everybody knows who did it.", n"");
  }

  // Succession (Nemesis-inspired): a crew does not simply lose its best and move on.
  // Someone steps into the dead Rival's place carrying the same grudge, and the higher the
  // one you put down, the likelier that is - so a faction cannot be decapitated in one
  // fight. The successor inherits the slain one's standing, one rung down, rather than
  // restarting at the bottom (spec §10.1).
  //
  // How likely rests on how high they stood. It started at sixty percent for anybody, so putting down
  // a rank one Rival was nearly always answered by another rank one Rival and killing one settled
  // nothing; now a small name usually ends with them, and a big one usually does not.
  let succeedChance = CBConfig.SuccessionChanceBase()
    + Cast<Float>(rival.rank) * CBConfig.SuccessionChancePerRank();
  if CBRivalRoll(sys, "succession", succeedChance, rival.recordID, false) {
    // Inherit the slain Rival's rank, one step down. CBCreateRival starts everyone at 1, which is
    // what made every nemesis you killed a clean reset. Made once the fight is over, with the street
    // saying who picked up where they left off (Rivals/Births.reds, 1.9.1).
    CBRivalAfterFight(sys, game, rival.faction, rival.recordID, rival.appearance, ECBRivalSource.Avenger,
                      district, at, null, Max(1, rival.rank - 1), CBRivalDisplayName(content, rival));
  }

  CBEvaluateTitles(sys, game);
}

// Autonomous rival progression (Nemesis-inspired): Rivals V has ignored for a
// while climb the ranks on their own, at most one promotion per in-game day
// (spec §10.1). The underworld moves even when V isn't looking.
public func CBRivalProgressionTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().rivals {
    return;
  }
  let now = CBGameSeconds(game);
  let cd = sys.GetCooldowns();
  // Rivals climb often while you leave them be: at most one promotion every ~8 in-game hours.
  if IsDefined(cd) && (now - cd.lastPromotionAt) < CBConfig.SecondsPerDay() * 0.33 {
    return;
  }
  let content = CBContent(game);
  let neglect = CBConfig.SecondsPerDay();   // left alone for a day and they get stronger
  for r in sys.GetRivals() {
    let active = IsDefined(r)
      && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting));
    if active && r.rank < 4 && (now - r.lastSeenAt) > neglect {
      if RandF() < 0.6 {
        CBPromoteRival(r, content, now);
        if IsDefined(cd) {
          cd.lastPromotionAt = now;
        }
        if CBMessagesOn() {
          CBHearsayFromStreet(game, CBRivalDisplayName(content, r) + " has moved up while you were busy elsewhere.", n"");
        }
        return;
      }
    }
  }
}

// Writes a Legend Log entry for a Rival event.
func CBLogRival(sys: ref<CyberbaneSystem>, kind: CName, at: Float, district: CName, faction: CName, value: Float, rivalId: Int32) -> Void {
  let entry = new CBLogEntry();
  entry.kind = kind;
  entry.at = at;
  entry.district = district;
  entry.faction = faction;
  entry.value = value;
  sys.AddLogEntry(entry);
}

// One entry in the street's file on V (the Hub's History screen). Every kind written here has a
// sentence in CBHudLogLine; a kind without one still shows, just less gracefully.
public func CBFileLog(sys: ref<CyberbaneSystem>, kind: CName, at: Float, district: CName,
                      faction: CName, value: Float) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let entry = new CBLogEntry();
  entry.kind = kind;
  entry.at = at;
  entry.district = district;
  entry.faction = faction;
  entry.value = value;
  sys.AddLogEntry(entry);
}

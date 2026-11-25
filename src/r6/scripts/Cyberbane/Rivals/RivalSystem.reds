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
  // Take the remainder first, then lift it into range.
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
  if source == EnumInt(ECBRivalSource.Betrayer) { return ArraySize(e.betrayer) > 0 ? e.betrayer : e.survivor; }
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

// A name nobody in this save has ever had.
func CBNameSkipped(faction: CName, name: String) -> Bool {
  if Equals(name, "Santiago") {
    return Equals(faction, n"Aldecaldos") || Equals(faction, n"Valentinos");
  }
  if Equals(name, "Nash") {
    return Equals(faction, n"Militech");
  }
  return false;
}

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
      if !CBNameSkipped(rival.faction, pool.firstNames[rival.firstName]) && (pass == 1 || !CBRivalGangHasFirstName(sys, rival)) {
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

// The part in quotes, the same way: nobody on the roster shares it while another is free. There are a dozen or so of
// these for each way of becoming a Rival, so unlike a name they can run out, and then the first pick stands.
func CBRivalPickFreeEpithet(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, rival: ref<CBRival>) -> Void {
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(rival) || rival.epithet < 0 {
    return;
  }
  let epithets = CBEpithetsForSource(content, rival.source);
  let n = ArraySize(epithets);
  let start = rival.epithet;
  // First one nobody on this save has ever had, written down in the same book as the names;
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

// An epithet as the player reads it: its translation when one is installed, the English otherwise.
public func CBEpithetText(english: String) -> String {
  if StrLen(english) == 0 {
    return english;
  }
  let s = GetLocalizedTextByKey(StringToName("Cyberbane-Epithet-" + CBEpithetSlug(english)));
  return StrLen(s) > 0 ? s : english;
}

public func CBEpithetSlug(english: String) -> String {
  let keep = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  let i = 0;
  while i < StrLen(english) {
    let c = StrMid(english, i, 1);
    if StrFindFirst(keep, c) >= 0 {
      out += c;
    }
    i += 1;
  }
  return out;
}

public func CBRivalEpithet(content: ref<CyberbaneContent>, rival: ref<CBRival>) -> String {
  if !IsDefined(rival) {
    return "";
  }
  // After a break they are known for that, and nothing else. The one picked when they broke (CBRivalPickBrokenEpithet),
  // stored past CBBrokenEpithetBase in the same field.
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
  // Back from the dead, or humiliated (Rivals/RivalMoments.reds): known for that now.
  if CBRivalReturned(rival) {
    return CBReturnedEpithet(rival);
  }
  if CBRivalWasHumiliated(rival) {
    return CBHumiliatedEpithet(rival);
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

// Cyberpsychotic breaks.
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
    CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalSystem-WordIsWentBackUnderThe", [s"\(CBRivalDisplayName(content, r))"]), n"");
  }
  CBLog.Info(n"Rivals", s"Rival \(r.id) broke: cyberpsycho (chance \(RoundF(chance * 100.0))%).");
  return true;
}

// A Rival's nickname after a break lives in the same field as the one they had (`epithet`), past this
// number, so no save changes shape and a value below it still reads as the old pool.
public func CBBrokenEpithetBase() -> Int32 = 1000

// Picked as they break. The first build hashed the id instead, so two who broke could carry the same one, which
// nicknames never do.
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
    return CBT(n"Cyberbane-RivalSystem-ARival");
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
  // A nickname is earned: by moving up a rank, or by putting V down. A rank one Rival is just their name, so the ones
  // who have done something stand out, and the same few nicknames are not on everybody.
  let epithet = CBRivalEarnedNickname(rival) ? CBEpithetText(CBRivalEpithet(content, rival)) : "";   // translated
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
public func CBRecordIsUniqueCharacter(recordID: TweakDBID) -> Bool {
  if !TDBID.IsValid(recordID) {
    return true;   // nothing to spawn from; refusing is the safe answer
  }
  let rec = TweakDBInterface.GetCharacterRecord(recordID);
  if IsDefined(rec) {
    if rec.TagsContains(n"Cyberpsycho") || rec.TagsContains(n"Boss") {
      return true;
    }
    // Written by the game not to die. Street-story extras, quest walk-ons and the like carry an Immortal or
    // Invulnerable tag, and the engine makes anybody spawned from such a record shrug off every bullet.
    if rec.TagsContains(n"Immortal") || rec.TagsContains(n"Invulnerable") {
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
    // Authored to have a boss health bar. `bossHealthBarThresholds` is only filled in on records the game intends to
    // put a bar across the top of the screen for, which is a statement that this is a set piece rather than a kind of
    // enemy.
    if rec.GetBossHealthBarThresholdsCount() > 0 {
      return true;
    }
  }
  let id = TDBID.ToStringDEBUG(recordID);
  return StrContains(id, "cyberpsycho") || StrContains(id, "Cyberpsycho")
      || StrContains(id, "_psycho") || StrContains(id, "boss");
}

// Take anybody the game owns off the roster.
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
    // A Rival built from a police record keeps their name, rank and grudge and comes back as one of their gang's own
    // people, so fighting them is a fight rather than a crime.
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
  // Every gang's chairs put right, once a session: somebody retired just now, made a Debtor, or run out of the city in
  // an earlier build kept their chair until the gang next changed shape, and open season, the Hub and the street all
  // took them for the one in charge.
  for gang in sys.GetFactionStates() {
    if IsDefined(gang) {
      CBHierarchyFill(sys, gang.id);
    }
  }
  if enlisted > 0 {
    CBLog.Info(n"Rivals", s"\(enlisted) rival(s) built from police records are their gang's own people now, so fighting them draws no heat.");
  }
  // Worth knowing: this prune is what clears a story character already written into a save.
}

// Is this one of Regina's cyberpsychos?
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

// ---- How likely somebody is to come back as a Rival ----------------------
//
// Every way of becoming a Rival rolled one flat number, whoever the person was and however many had just been made. Two
// things followed.
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
    // Fewer swear to get even with a merc nobody has heard of.
    odds *= CBStandingScale(sys.GetGameInstance(), CBConfig.EarlyRivalShare());
  }
  return ClampF(odds, 0.0, CBConfig.RivalOddsCeiling());
}

// Not rolled at all for a gang that keeps no Rivals (switched off under Factions, or the Scavengers, who run): the log
// said "a Rival" and, a line later, that none was made.
public func CBRivalRoll(sys: ref<CyberbaneSystem>, what: String, base: Float, recordID: TweakDBID, byRank: Bool,
                        faction: CName) -> Bool {
  if NotEquals(faction, n"") && (!CBFactionOn(faction) || CBCodeEverybodysEnemy(faction)) {
    return false;
  }
  let odds = CBRivalOdds(sys, base, recordID, byRank);
  let hit = RandF() < odds;
  let outcome = hit ? CBT(n"Cyberbane-RivalSystem-ARival-2") : CBT(n"Cyberbane-RivalSystem-NotThisTime");
  CBLog.Info(n"Rivals", s"Rival roll, \(what): \(RoundF(odds * 100.0))%, \(outcome).");
  return hit;
}

// `quiet` leaves out the "has your name now" text, for a caller that sends its own line about the same moment (a
// death). `counted` says the roll already counted this Rival towards the burst damping in CBRivalOdds, as a birth held
// until the fight is over does (Rivals/Births.reds), so it is not counted twice.
public func CBCreateRival(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName,
    recordID: TweakDBID, appearance: CName, source: ECBRivalSource, origin: CName, at: Float,
    opt quiet: Bool, opt counted: Bool) -> ref<CBRival> {
  if !IsDefined(sys) {
    return null;
  }
  // A faction the player switched off under Factions in Mod Settings keeps no Rivals.
  if !CBFactionOn(faction) {
    CBLog.Info(n"Rivals", s"No new Rival from \(NameToString(faction)): switched off in Mod Settings.");
    return null;
  }
  // Nor a gang whose people run rather than come back (the Scavengers, Data/GangCodes.reds).
  if CBCodeEverybodysEnemy(faction) {
    CBLog.Info(n"Rivals", s"No new Rival from \(NameToString(faction)): they run, and do not come back.");
    return null;
  }
  // One gate, here, because eight different places create Rivals and several hand over a record straight off a puppet.
  // Guarding each of them would mean missing one.
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
  if NotEquals(faction, n"") {
    sys.EnsureFaction(faction);
  }
  CBHierarchyFill(sys, faction);

  CBLogRival(sys, n"RivalCreated", at, origin, faction, Cast<Float>(r.id), r.id);
  if CBMessagesOn() && !quiet {
    CBPhoneFromGang(game, faction, CBTf(n"Cyberbane-Births-HasYourNameNowThatIs", [CBRivalDisplayName(content, r)]));
  }
  CBLog.Info(n"Rivals", s"Rival created id=\(r.id) faction=\(NameToString(faction)).");
  CBApiRivalEvent(r, n"Made");   // extension API
  return r;
}

public func CBPromoteRival(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float) -> Void {
  if !IsDefined(rival) || rival.rank >= 4 {
    return;
  }
  rival.rank += 1;
  CBRivalAddTrait(content, rival);
  CBApiRivalEvent(rival, n"Climbed");
}

// --- State transitions (spec §10.6) ------------------------------------

public func CBRivalEscaped(rival: ref<CBRival>, content: ref<CyberbaneContent>, at: Float, district: CName, lowHp: Bool) -> Void {
  if !IsDefined(rival) {
    return;
  }
  rival.escapes += 1;
  rival.lastSeenAt = at;
  CBApiRivalEvent(rival, n"Escaped");
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
  CBApiRivalEvent(rival, n"KilledV");
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
  CBApiRivalEvent(rival, n"Spared");
  // Being let go by the person you came to kill stays with you.
  CBRivalGiveTrait(rival, n"Shaken");
  if rival.sparedByV >= 2 && RandF() < 0.5 {
    rival.state = EnumInt(ECBRivalState.Debtor);
    return true;
  }
  // Humiliated ([55]): they lost a rank for it, and being spared again is no climb.
  if !CBRivalWasHumiliated(rival) {
    CBPromoteRival(rival, content, at);
  }
  return false;
}

// Slay a Rival (spec §10.7): archive it, award renown, bump stats, log.
// Work out which Rival a dead CB_Rival puppet was.
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
    // Any word sent for a meeting is spent with the encounter. A kill has paid it out already
    // (CBRivalSlain runs before this); every other ending means the meeting came to nothing.
    CBWithdrawWord(game, rival.id);
    let wasLead = sys.GetActiveRivalId() == rival.id;
    if wasLead {
      sys.SetActiveRivalId(0);
    }
    // Forget which body was theirs. Keeping it would leave CBFindRivalByBody matching an
    // entity that is no longer part of an encounter.
    let none: EntityID;
    rival.spawnedEntityId = none;
    sys.RemovePackRival(rival.id);   // no longer one of a team that came together
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

// Is this Rival body somebody's encounter right now?
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

// Living Rival bodies that are nobody's encounter, removed once V cannot see them. What the deferred sweep after a
// death and the escape ending used to do to every CB_Rival; anybody still a live Rival's is left alone.
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

// The tags that make a body a Rival's come off, and it joins the bodies the orphan sweep clears once V cannot see them
// (CBSweepOrphans), which is where CBDeleteTaggedSafe has always put one it could not take.
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
  // Alive and their encounter over: they are out of it, and leave.
  if CBNpcSafe(sys, body) && CBStillStanding(body) && !body.IsDead() {
    let player = GetPlayer(game);
    let agent = body.GetAttitudeAgent();
    let pagent = IsDefined(player) ? player.GetAttitudeAgent() : null;
    if IsDefined(agent) && IsDefined(pagent) && Equals(agent.GetAttitudeTowards(pagent), EAIAttitude.AIA_Hostile) {
      CBTrace("attitude: a Rival whose encounter is over stands down and leaves");
      agent.SetAttitudeTowards(pagent, EAIAttitude.AIA_Neutral);
      let senses = body.GetSensesComponent();
      if IsDefined(senses) {
        senses.ResetDetection(player.GetEntityID());
      }
    }
    CBCalmTowardCompanions(sys, body);
    body.cbFacedownHeld = false;
    body.cbFacedownWait = false;
    CBCancelMove(body);
    CBOrderFlee(game, body, true);
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
  let bookP = CBIntelBook.Get(game);
  if IsDefined(bookP) {
    bookP.ClearWords();   // nobody is waiting anywhere for V now
  }
  // V's own crew, and the ones who were, stay (CyberbaneSystem.RivalKeptByCrew): the crew member is that Rival, and
  // forgetting every Rival renamed them.
  let kept: array<Int32>;
  for k in sys.GetRivals() {
    if IsDefined(k) && sys.RivalKeptByCrew(k.id) {
      ArrayPush(kept, k.id);
    }
  }
  let rivalBook = CBRivalBook.Get(game);
  if IsDefined(rivalBook) {
    rivalBook.ClearExcept(kept);    // and no bond, ending or place is kept for anybody else
  }
  let removed = sys.ClearRivals();
  sys.SetActiveRivalId(0);
  sys.ClearPack();
  sys.ClearPendingBirths();   // nor anybody still waiting for a fight to be over
  CBDeleteTaggedSafe(game, n"CB_Rival");
  CBLog.Info(n"Rivals", s"Purged \(removed) rivals at the player's request.");
  return removed;
}

// Can this one be forgotten right now? Not while a car is bringing them: their body arrives as a Rival's and is adopted
// as one, and with nobody left to adopt it as, it would be a nameless hunter.
public func CBRivalForgettable(sys: ref<CyberbaneSystem>, r: ref<CBRival>) -> Bool {
  return IsDefined(sys) && IsDefined(r) && sys.GetRivalCarPending() != r.id && !sys.RivalKeptByCrew(r.id);
}

// Forget one Rival (the Hub). Everything "Forget every rival" does (CBPurgeRivals), for one of them, from the settled
// tick (CyberbaneSystem.ServiceHubActions).
public func CBForgetRival(sys: ref<CyberbaneSystem>, game: GameInstance, id: Int32) -> String {
  if !IsDefined(sys) {
    return "";
  }
  let r = sys.FindRivalById(id);
  if !IsDefined(r) {
    return "";
  }
  if !CBRivalForgettable(sys, r) {
    CBLog.Info(n"Rivals", s"Rival \(id) is on their way in a car, or one of V's crew; not forgotten.");
    return "";
  }
  let name = CBRivalDisplayName(sys.GetContent(), r);
  let svc = sys.GetPlayService();
  if IsDefined(svc) {
    // Noted when it was chosen; again here in case the menu could not reach the service.
    svc.NoteForgetRival(sys.GetPlaythroughId(), id, r.recordID);
    svc.DropSighting(sys.GetPlaythroughId(), id);
  }
  CBWithdrawWord(game, id);
  CBRivalBookForget(game, id);   // their bond, ending and places (Rivals/RivalBook.reds)
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

// `byV`: V landed the killing blow, or V's side did (CBLastHitWasOthers). Dead either way, and their chair filled
// either way; only what V did is V's.
public func CBRivalSlain(sys: ref<CyberbaneSystem>, game: GameInstance, rival: ref<CBRival>, at: Float, district: CName,
                         byV: Bool) -> Void {
  if !IsDefined(sys) || !IsDefined(rival) {
    return;
  }
  rival.state = EnumInt(ECBRivalState.Slain);
  rival.lastSeenAt = at;
  CBApiRivalEvent(rival, n"Slain");
  CBCrewLifeRivalDied(game, rival.id);   // revenge one of V's crew asked for (Reactions/CrewLife.reds)

  if byV {
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
  }

  CBLogRival(sys, byV ? n"RivalSlain" : n"RivalDied", at, district, rival.faction, Cast<Float>(rival.rank), rival.id);
  // A name of theirs in the ground costs a gang more than a body does (Model/Territory.reds).
  CBWeakenGang(sys, game, rival.faction,
               CBConfig.GangLossRival() + CBConfig.GangLossRivalPerRank() * Cast<Float>(rival.rank));
  // Their chair does not stay empty (spec §10.1).
  CBHierarchyOnSlain(sys, game, rival);
  let content = CBContent(game);
  if CBMessagesOn() {
    if byV {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalSystem-IsDeadAndEverybodyKnowsWho", [CBRivalDisplayName(content, rival)]), n"");
    } else {
      CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalSystem-IsDeadSomebodyGotToThem", [CBRivalDisplayName(content, rival)]), n"");
    }
  }
  if !byV {
    // Nobody to avenge them on V, and no meeting V kept.
    CBEvaluateTitles(sys, game);
    return;
  }

  // Succession: a crew does not simply lose its best and move on.
  let succeedChance = CBConfig.SuccessionChanceBase()
    + Cast<Float>(rival.rank) * CBConfig.SuccessionChancePerRank();
  if CBRivalRoll(sys, "succession", succeedChance, rival.recordID, false, rival.faction) {
    // Inherit the slain Rival's rank, one step down. CBCreateRival starts everyone at 1, which is what made every Rival
    // you killed a clean reset.
    let kin = RandF() < ClampF(CBConfig.KinChance() * CBCodeKin(rival.faction), 0.0, 0.9) ? rival.id : 0;
    CBRivalAfterFight(sys, game, rival.faction, rival.recordID, rival.appearance, ECBRivalSource.Avenger,
                      district, at, null, Max(1, rival.rank - 1), CBRivalDisplayName(content, rival), kin);
  }

  // Called out, and finished at the place they named (Rivals/RivalLife.reds).
  CBWordKept(sys, game, rival);
  CBEvaluateTitles(sys, game);
}

// Autonomous rival progression: Rivals V has ignored for a
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
          CBHearsayFromStreet(game, CBTf(n"Cyberbane-RivalSystem-HasMovedUpWhileYouWere", [CBRivalDisplayName(content, r)]), n"");
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

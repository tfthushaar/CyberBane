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
  let step = 0;
  while step < n {
    rival.epithet = (start + step) % n;
    if !CBRivalEpithetTaken(sys, content, rival) {
      return;
    }
    step += 1;
  }
  rival.epithet = start;
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
  let eps = CBEpithetsForSource(content, rival.source);
  if rival.epithet >= 0 && rival.epithet < ArraySize(eps) {
    return eps[rival.epithet];
  }
  return "";
}

// Full on-screen name, e.g. Kenji "Who Ran" Morita.
// A last-resort handle so nobody is ever called "Unknown". Keyed off the Rival id, so the
// same Rival always reads the same way.
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
  let epithet = CBRivalEpithet(content, rival);
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
    if IsDefined(t) && !t.isWeakness && !CBRivalHasTrait(rival, t.id) && CBTraitBit(t.id) >= 0 {
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

public func CBCreateRival(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName,
    recordID: TweakDBID, appearance: CName, source: ECBRivalSource, origin: CName, at: Float) -> ref<CBRival> {
  if !IsDefined(sys) {
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
  if sys.CountActiveRivals() >= maxRivals {
    return null;
  }
  if sys.CountActiveFactionRivals(faction) >= CBConfig.RivalMaxPerFaction() {
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
  // A new name in a crew may be the only one left standing in it (spec §10.1).
  CBHierarchyFill(sys, faction);

  CBLogRival(sys, n"RivalCreated", at, origin, faction, Cast<Float>(r.id), r.id);
  if CBMessagesOn() {
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
  //    explicitly unregistered - a body that never dies never loses its pin.
  if IsDefined(body) {
    CBUntrackOnMap(game, body);
  }
  CBUntrackTagged(game, n"CB_Rival");

  // 2. The encounter slot, so the lanes know nothing is out and the next one can be queued.
  if IsDefined(rival) {
    if sys.GetActiveRivalId() == rival.id {
      sys.SetActiveRivalId(0);
    }
    // Forget which body was theirs. Keeping it would leave CBFindRivalByBody matching an
    // entity that is no longer part of an encounter.
    let none: EntityID;
    rival.spawnedEntityId = none;
    // 3. And a cooldown, so they do not walk straight back into the fight they just lost.
    //    Without this the gate clears the moment they go down and they are re-queued at once.
    if rival.huntTicks < CBConfig.RivalAfterEscapeTicks() {
      rival.huntTicks = CBConfig.RivalAfterEscapeTicks();
    }
  } else {
    sys.SetActiveRivalId(0);
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
  CBDeleteTaggedSafe(game, n"CB_Rival");
  CBLog.Info(n"Rivals", s"Purged \(removed) rivals at the player's request.");
  return removed;
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
  let freq = 1.0;
  if IsDefined(rt) && rt.HasSettings() {
    freq = rt.GetSettings().rivalFrequencyMult;
  }
  let succeedChance = CBConfig.RivalChanceAvenger()
    + Cast<Float>(rival.rank) * CBConfig.SuccessionChancePerRank();
  if RandF() < ClampF(succeedChance * freq, 0.0, 0.9) {
    let avenger = CBCreateRival(sys, game, rival.faction, rival.recordID, rival.appearance, ECBRivalSource.Avenger, district, at);
    if IsDefined(avenger) {
      // Inherit the slain Rival's rank, one step down. CBCreateRival starts everyone at 1,
      // which is what made every nemesis you killed a clean reset.
      avenger.rank = Max(1, rival.rank - 1);
      if CBMessagesOn() {
        CBHearsayFromGang(game, rival.faction, CBRivalDisplayName(content, avenger)
          + " picks up where " + CBRivalDisplayName(content, rival) + " left off.", n"");
      }
    }
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

// Cyberbane - Global service (spec §6.3)
//
// Codeware ScriptableService. Persistent fields are stored globally (shared by
// all saves), which is what the Death Ledger needs so a killer can become a
// Rival across the reload that follows V's death (spec §10.8).
//
// The service must never hold references to game objects (Codeware guidance).

public class CBLedgerEntry {
  public persistent let id: Int32;
  public persistent let playthroughId: CName;
  public persistent let at: Float;                 // game seconds at death
  public persistent let district: CName;
  public persistent let killerRecordID: TweakDBID;
  public persistent let killerAppearance: CName;
  public persistent let killerFaction: CName;
  public persistent let killerRivalId: Int32;      // -1 if the killer was not a Rival
  public persistent let method: Int32;             // ECBKillMethod used on V
}

// "Forget every rival", remembered for a playthrough (1.6.2).
//
// Every Rival id up to `rivalUpTo` is gone for good on every save of this playthrough, and every
// death in the ledger up to `ledgerUpTo` no longer makes or promotes a Rival there.
public class CBForgetNote {
  public persistent let playthroughId: CName;
  public persistent let rivalUpTo: Int32;
  public persistent let ledgerUpTo: Int32;
}

// One Rival forgotten on the Hub (1.8.2). Kept here, beside "Forget every rival", for the same reason:
// it is an instruction about a playthrough, and loading an older save must not bring them back. The
// record is checked as well as the id, because another branch of the playthrough can have given that
// id to somebody else.
public class CBForgottenRival {
  public persistent let playthroughId: CName;
  public persistent let rivalId: Int32;
  public persistent let recordID: TweakDBID;
}

// Where a Rival was last seen standing, and whether anybody has passed it on to V (1.6.2,
// Rivals/Whereabouts.reds). Kept here rather than in the save because nothing may be added to a
// class the save holds without wiping everybody's progress, and because it is street knowledge:
// the city is the same city in every save. Every read checks it against the Rival in the save it
// is read from.
public class CBSighting {
  public persistent let playthroughId: CName;
  public persistent let rivalId: Int32;
  public persistent let recordID: TweakDBID;   // the Rival's record, so a stale id cannot match
  public persistent let x: Float;
  public persistent let y: Float;
  public persistent let z: Float;
  public persistent let district: CName;
  public persistent let seenAt: Float;         // game seconds
  public persistent let tippedAt: Float;       // game seconds V was told; 0 = not yet
  public persistent let tipFaction: CName;     // the gang that told V; n"" = the street
}

// How strong a gang is in one playthrough, and when that was last written (1.6.3,
// Model/Territory.reds). Here for the same reason as CBSighting: nothing may be added to a class
// the save holds. What it was rebuilt since `at` is worked out on reading, never stored.
public class CBGangPower {
  public persistent let playthroughId: CName;
  public persistent let faction: CName;
  public persistent let strength: Float;
  public persistent let at: Float;             // game seconds
}

// Which V a playthrough id belongs to (1.8.3).
//
// Everything this service keeps is tied to a playthrough by its id, and that id was the only thing
// keeping two characters apart. Nothing ever checked that a new one was not already taken, so two
// different characters could end up answering to the same id, and then each one read the other's
// deaths, gang strength and forget notes as its own. A player reported exactly that: a brand-new V
// texted by three Tyger Claws within minutes of loading, which were another character's deaths at
// the Ho-Oh, replayed by the death ledger as Killer Rivals.
//
// `bornAt` is the game time the playthrough first met Cyberbane. It is written into every save of
// that playthrough too (CyberbaneSystem.m_installedAt, a saved field that already existed and was
// never written, so the save keeps its shape), so a save that carries this id but a different
// birth is another character. `lifepath` is the V it belongs to, which can never change inside a
// playthrough; it tells saves from before 1.8.3 apart, which carry no birth of their own.
//
// A playthrough split off from a shared id remembers where it came from (`splitFrom`, and the birth
// its saves carried there, `formerBornAt`, 0 for a save from before 1.8.3), so the other saves of
// the same character join it when they load, rather than each one becoming a playthrough of its own.
public class CBPlaythroughBirth {
  public persistent let playthroughId: CName;
  public persistent let bornAt: Float;         // game seconds; always above zero once written
  public persistent let lifepath: Int32;       // EnumInt(gamedataLifePath); -1 = not known yet
  public persistent let splitFrom: CName;      // n"" = not split off from anything
  public persistent let formerBornAt: Float;
}

public class CyberbaneService extends ScriptableService {
  private persistent let m_schemaVersion: Int32;
  private persistent let m_nextLedgerId: Int32;
  private persistent let m_ledger: array<ref<CBLedgerEntry>>;   // cap 100 total, 30 per playthrough, FIFO
  // ---- Instructions about a playthrough (1.6.2) --------------------------------------------
  //
  // "Forget every rival" and "Start over" used to change only the save's own data, and only once
  // the game was unpaused. Quitting from the pause menu threw them away, and loading any save
  // written before them brought everything back, which is what a player reported: Rivals cleared
  // on the Hub, the game closed, the save loaded, every Rival back in the list. They are
  // instructions about a playthrough rather than events inside one, so they are kept here, where
  // the death ledger already lives: outside every save, read back on every load.
  private persistent let m_forgetNotes: array<ref<CBForgetNote>>;   // cap CapForgetNotes, FIFO
  private persistent let m_retiredIds: array<CName>;                // started over; cap CapRetiredIds
  // Where Rivals were last seen (Rivals/Whereabouts.reds). Cap CapSightings, oldest first.
  private persistent let m_sightings: array<ref<CBSighting>>;
  // How strong each gang is, per playthrough (Model/Territory.reds). Cap CapGangPower, oldest first.
  private persistent let m_gangPower: array<ref<CBGangPower>>;
  // Rivals forgotten one at a time (1.8.2). Cap CapForgottenRivals, oldest first.
  private persistent let m_forgottenRivals: array<ref<CBForgottenRival>>;
  // Which V each playthrough id belongs to (1.8.3). Cap CapBirths, oldest first.
  private persistent let m_births: array<ref<CBPlaythroughBirth>>;
  // The two action switches in Mod Settings, as last seen (1.8.3): CBSwitchUnseen, CBSwitchOff, or
  // CBSwitchActed (on, and already carried out). Mod Settings keeps a switch's accepted value and
  // writes it to its file, and hands it back on every launch and with every later change to any
  // setting; turning the field off in script never reached it. So "Reset all Cyberbane data", once
  // used, asked for another reset each time any setting was applied and on every launch after. A
  // switch now acts only on the way from off to on, and this is where "off" is remembered, because
  // it has to outlive the game being closed.
  private persistent let m_resetSwitch: Int32;
  private persistent let m_separateSwitch: Int32;

  public static func Get() -> ref<CyberbaneService> {
    // The service container is null during world transitions; calling GetService on a null
    // container crashes, so bail out until it is back (crash safety).
    let container = GameInstance.GetScriptableServiceContainer();
    if !IsDefined(container) {
      return null;
    }
    return container.GetService(n"CyberbaneService") as CyberbaneService;
  }

  // Bump the global schema version to the current build. (Global migrations, if
  // ever needed, run from here.)
  public func EnsureSchema() -> Void {
    if this.m_schemaVersion < CyberbaneSchemaVersion() {
      this.m_schemaVersion = CyberbaneSchemaVersion();
    }
  }

  public func GetLedger() -> array<ref<CBLedgerEntry>> {
    return this.m_ledger;
  }

  public func AllocateLedgerId() -> Int32 {
    let id = this.m_nextLedgerId;
    this.m_nextLedgerId += 1;
    return id;
  }

  // Records a death. The caller fills every field except `id`, which is assigned
  // here. Enforces the per-playthrough and global FIFO caps (spec §6.5).
  public func AppendLedgerEntry(entry: ref<CBLedgerEntry>) -> Void {
    if !IsDefined(entry) {
      return;
    }
    entry.id = this.AllocateLedgerId();
    ArrayPush(this.m_ledger, entry);
    this.TrimPlaythrough(entry.playthroughId);
    this.TrimTotal();
    CBLog.Info(n"Ledger", s"Recorded death id=\(entry.id) playthrough=\(NameToString(entry.playthroughId))");
  }

  private func TrimPlaythrough(playthroughId: CName) -> Void {
    let cap = CBConfig.CapLedgerPerPlaythrough();
    let count = 0;
    let i = ArraySize(this.m_ledger) - 1;
    // Count newest-first; drop the oldest matching entries beyond the cap.
    while i >= 0 {
      if IsDefined(this.m_ledger[i]) && Equals(this.m_ledger[i].playthroughId, playthroughId) {
        count += 1;
      }
      i -= 1;
    }
    while count > cap {
      let j = 0;
      while j < ArraySize(this.m_ledger) {
        if !IsDefined(this.m_ledger[j]) || Equals(this.m_ledger[j].playthroughId, playthroughId) {
          ArrayErase(this.m_ledger, j);
          count -= 1;
          break;
        }
        j += 1;
      }
    }
  }

  private func TrimTotal() -> Void {
    let cap = CBConfig.CapLedgerTotal();
    while ArraySize(this.m_ledger) > cap {
      ArrayErase(this.m_ledger, 0);
    }
  }

  // The newest death on record, for "forget every death up to now". -1 when there are none.
  public func LastLedgerId() -> Int32 {
    return this.m_nextLedgerId - 1;
  }

  // ---- Forgotten Rivals ------------------------------------------------------------------

  public func GetForgetNote(playthroughId: CName) -> ref<CBForgetNote> {
    if !IsNameValid(playthroughId) {
      return null;
    }
    let i = 0;
    while i < ArraySize(this.m_forgetNotes) {
      let n = this.m_forgetNotes[i];
      if IsDefined(n) && Equals(n.playthroughId, playthroughId) {
        return n;
      }
      i += 1;
    }
    return null;
  }

  // Forget everything up to these ids. Never lowers what is already forgotten: a later branch
  // of the same playthrough may have forgotten more.
  public func NoteForget(playthroughId: CName, rivalUpTo: Int32, ledgerUpTo: Int32) -> Void {
    if !IsNameValid(playthroughId) {
      return;
    }
    let n = this.GetForgetNote(playthroughId);
    if !IsDefined(n) {
      n = new CBForgetNote();
      n.playthroughId = playthroughId;
      n.rivalUpTo = -1;
      n.ledgerUpTo = -1;
      ArrayPush(this.m_forgetNotes, n);
      while ArraySize(this.m_forgetNotes) > CBConfig.CapForgetNotes() {
        ArrayErase(this.m_forgetNotes, 0);
      }
    }
    n.rivalUpTo = Max(n.rivalUpTo, rivalUpTo);
    n.ledgerUpTo = Max(n.ledgerUpTo, ledgerUpTo);
  }

  // Put a note back exactly as it was before a forget that was then taken back on the Hub. A
  // negative `rivalUpTo` means there was no note at all.
  public func RestoreForget(playthroughId: CName, rivalUpTo: Int32, ledgerUpTo: Int32) -> Void {
    if !IsNameValid(playthroughId) {
      return;
    }
    let i = ArraySize(this.m_forgetNotes) - 1;
    while i >= 0 {
      let n = this.m_forgetNotes[i];
      if !IsDefined(n) || Equals(n.playthroughId, playthroughId) {
        ArrayErase(this.m_forgetNotes, i);
      }
      i -= 1;
    }
    if rivalUpTo >= 0 || ledgerUpTo >= 0 {
      let back = new CBForgetNote();
      back.playthroughId = playthroughId;
      back.rivalUpTo = rivalUpTo;
      back.ledgerUpTo = ledgerUpTo;
      ArrayPush(this.m_forgetNotes, back);
    }
  }

  // ---- Rivals forgotten one at a time (1.8.2) ----------------------------------------------

  public func GetForgottenRivals() -> array<ref<CBForgottenRival>> {
    return this.m_forgottenRivals;
  }

  public func NoteForgetRival(playthroughId: CName, rivalId: Int32, recordID: TweakDBID) -> Void {
    if !IsNameValid(playthroughId) || rivalId < 0 {
      return;
    }
    for f in this.m_forgottenRivals {
      if IsDefined(f) && f.rivalId == rivalId && Equals(f.playthroughId, playthroughId) {
        f.recordID = recordID;
        return;
      }
    }
    let n = new CBForgottenRival();
    n.playthroughId = playthroughId;
    n.rivalId = rivalId;
    n.recordID = recordID;
    ArrayPush(this.m_forgottenRivals, n);
    while ArraySize(this.m_forgottenRivals) > CBConfig.CapForgottenRivals() {
      ArrayErase(this.m_forgottenRivals, 0);
    }
  }

  // Taken back on the Hub before it was carried out.
  public func UnnoteForgetRival(playthroughId: CName, rivalId: Int32) -> Void {
    let i = ArraySize(this.m_forgottenRivals) - 1;
    while i >= 0 {
      let f = this.m_forgottenRivals[i];
      if !IsDefined(f) || (f.rivalId == rivalId && Equals(f.playthroughId, playthroughId)) {
        ArrayErase(this.m_forgottenRivals, i);
      }
      i -= 1;
    }
  }

  // ---- Started over ----------------------------------------------------------------------

  public func IsRetired(playthroughId: CName) -> Bool {
    return IsNameValid(playthroughId) && ArrayContains(this.m_retiredIds, playthroughId);
  }

  public func Retire(playthroughId: CName) -> Void {
    if !IsNameValid(playthroughId) || ArrayContains(this.m_retiredIds, playthroughId) {
      return;
    }
    ArrayPush(this.m_retiredIds, playthroughId);
    while ArraySize(this.m_retiredIds) > CBConfig.CapRetiredIds() {
      ArrayErase(this.m_retiredIds, 0);
    }
  }

  // ---- Sightings (Rivals/Whereabouts.reds) -----------------------------------------------

  public func GetSightings() -> array<ref<CBSighting>> {
    return this.m_sightings;
  }

  public func FindSighting(playthroughId: CName, rivalId: Int32) -> ref<CBSighting> {
    if !IsNameValid(playthroughId) {
      return null;
    }
    let i = 0;
    while i < ArraySize(this.m_sightings) {
      let s = this.m_sightings[i];
      if IsDefined(s) && s.rivalId == rivalId && Equals(s.playthroughId, playthroughId) {
        return s;
      }
      i += 1;
    }
    return null;
  }

  // Somebody saw this Rival here. A new sighting replaces the old one and has not been passed on
  // to V yet, because the place has changed.
  public func NoteSighting(playthroughId: CName, rivalId: Int32, recordID: TweakDBID, at: Vector4,
                           district: CName, seenAt: Float) -> Void {
    if !IsNameValid(playthroughId) || !TDBID.IsValid(recordID) {
      return;
    }
    let s = this.FindSighting(playthroughId, rivalId);
    if !IsDefined(s) {
      s = new CBSighting();
      s.playthroughId = playthroughId;
      s.rivalId = rivalId;
      ArrayPush(this.m_sightings, s);
      while ArraySize(this.m_sightings) > CBConfig.CapSightings() {
        ArrayErase(this.m_sightings, 0);
      }
    }
    s.recordID = recordID;
    s.x = at.X;
    s.y = at.Y;
    s.z = at.Z;
    s.district = district;
    s.seenAt = seenAt;
    s.tippedAt = 0.0;
    s.tipFaction = n"";
  }

  public func DropSighting(playthroughId: CName, rivalId: Int32) -> Void {
    let i = ArraySize(this.m_sightings) - 1;
    while i >= 0 {
      let s = this.m_sightings[i];
      if !IsDefined(s) || (s.rivalId == rivalId && Equals(s.playthroughId, playthroughId)) {
        ArrayErase(this.m_sightings, i);
      }
      i -= 1;
    }
  }

  // Every sighting of this playthrough's Rivals up to this id. -1 never matches an id.
  public func DropSightingsUpTo(playthroughId: CName, rivalUpTo: Int32) -> Void {
    let i = ArraySize(this.m_sightings) - 1;
    while i >= 0 {
      let s = this.m_sightings[i];
      if !IsDefined(s) || (s.rivalId <= rivalUpTo && Equals(s.playthroughId, playthroughId)) {
        ArrayErase(this.m_sightings, i);
      }
      i -= 1;
    }
  }

  // ---- Gang strength (Model/Territory.reds) ---------------------------------------------

  public func FindGangPower(playthroughId: CName, faction: CName) -> ref<CBGangPower> {
    if !IsNameValid(playthroughId) {
      return null;
    }
    let i = 0;
    while i < ArraySize(this.m_gangPower) {
      let p = this.m_gangPower[i];
      if IsDefined(p) && Equals(p.faction, faction) && Equals(p.playthroughId, playthroughId) {
        return p;
      }
      i += 1;
    }
    return null;
  }

  public func NoteGangPower(playthroughId: CName, faction: CName, strength: Float, at: Float) -> Void {
    if !IsNameValid(playthroughId) || Equals(faction, n"") {
      return;
    }
    let p = this.FindGangPower(playthroughId, faction);
    if !IsDefined(p) {
      p = new CBGangPower();
      p.playthroughId = playthroughId;
      p.faction = faction;
      ArrayPush(this.m_gangPower, p);
      while ArraySize(this.m_gangPower) > CBConfig.CapGangPower() {
        ArrayErase(this.m_gangPower, 0);
      }
    }
    p.strength = strength;
    p.at = at;
  }

  public func DropPlaythroughGangPower(playthroughId: CName) -> Void {
    let i = ArraySize(this.m_gangPower) - 1;
    while i >= 0 {
      let p = this.m_gangPower[i];
      if !IsDefined(p) || Equals(p.playthroughId, playthroughId) {
        ArrayErase(this.m_gangPower, i);
      }
      i -= 1;
    }
  }

  public func DropPlaythroughSightings(playthroughId: CName) -> Void {
    let i = ArraySize(this.m_sightings) - 1;
    while i >= 0 {
      let s = this.m_sightings[i];
      if !IsDefined(s) || Equals(s.playthroughId, playthroughId) {
        ArrayErase(this.m_sightings, i);
      }
      i -= 1;
    }
  }

  // ---- Which V a playthrough id belongs to (1.8.3) ----------------------------------------

  // Is this id somebody's already? Every kind of record is asked, not only the births: a
  // playthrough from before 1.8.3 has no birth on record, only its deaths, notes and numbers.
  // An empty id is never free.
  public func IsPlaythroughIdInUse(id: CName) -> Bool {
    if !IsNameValid(id) {
      return true;
    }
    if ArrayContains(this.m_retiredIds, id) {
      return true;
    }
    for e in this.m_ledger {
      if IsDefined(e) && Equals(e.playthroughId, id) {
        return true;
      }
    }
    for n in this.m_forgetNotes {
      if IsDefined(n) && Equals(n.playthroughId, id) {
        return true;
      }
    }
    for s in this.m_sightings {
      if IsDefined(s) && Equals(s.playthroughId, id) {
        return true;
      }
    }
    for p in this.m_gangPower {
      if IsDefined(p) && Equals(p.playthroughId, id) {
        return true;
      }
    }
    for f in this.m_forgottenRivals {
      if IsDefined(f) && Equals(f.playthroughId, id) {
        return true;
      }
    }
    for b in this.m_births {
      if IsDefined(b) && Equals(b.playthroughId, id) {
        return true;
      }
    }
    return false;
  }

  public func FindBirth(id: CName) -> ref<CBPlaythroughBirth> {
    if !IsNameValid(id) {
      return null;
    }
    for b in this.m_births {
      if IsDefined(b) && Equals(b.playthroughId, id) {
        return b;
      }
    }
    return null;
  }

  // Put this playthrough on record as born at `bornAt` to this V, replacing what was there.
  public func NoteBirth(id: CName, bornAt: Float, lifepath: Int32) -> Void {
    if !IsNameValid(id) || bornAt <= 0.0 {
      return;
    }
    let b = this.FindBirth(id);
    if !IsDefined(b) {
      b = new CBPlaythroughBirth();
      b.playthroughId = id;
      ArrayPush(this.m_births, b);
      while ArraySize(this.m_births) > CBConfig.CapBirths() {
        ArrayErase(this.m_births, 0);
      }
    }
    b.bornAt = bornAt;
    b.lifepath = lifepath < 0 ? -1 : lifepath;
  }

  // A playthrough split off from `fromId` for the saves that carried `formerBornAt` there, for this
  // V. Those saves are one character, so the next of them to load joins it.
  public func FindSplit(fromId: CName, formerBornAt: Float, lifepath: Int32) -> ref<CBPlaythroughBirth> {
    if !IsNameValid(fromId) {
      return null;
    }
    for b in this.m_births {
      if IsDefined(b) && Equals(b.splitFrom, fromId) && b.formerBornAt == formerBornAt
         && b.lifepath == lifepath {
        return b;
      }
    }
    return null;
  }

  // Put a split-off playthrough on record (FindSplit).
  public func NoteSplit(id: CName, bornAt: Float, lifepath: Int32, fromId: CName, formerBornAt: Float) -> Void {
    this.NoteBirth(id, bornAt, lifepath);
    let b = this.FindBirth(id);
    if IsDefined(b) {
      b.splitFrom = fromId;
      b.formerBornAt = formerBornAt;
    }
  }

  // Fill in which V it is, where that could not be read when the birth was written. Never changes
  // one that is known: that is the thing that tells two characters apart.
  public func NoteBirthLifepath(id: CName, lifepath: Int32) -> Void {
    let b = this.FindBirth(id);
    if IsDefined(b) && b.lifepath < 0 && lifepath >= 0 {
      b.lifepath = lifepath;
    }
  }

  // A save that turned out to be another character keeps, under its new id, what its old id's
  // records said at this point in its own time, so nothing it already had changes under it: gang
  // strength that counts for it now (Model/Territory.reds reads a record from more than an hour
  // ahead as not this save's), and sightings that are not ahead of it (Rivals/Whereabouts.reds
  // drops those as foreign). Anything ahead of `now` was the other character's. Notes are not
  // copied: "forget every rival" and "start over" from the other character must never reach it.
  public func CopyPlaythroughRecords(fromId: CName, toId: CName, now: Float) -> Void {
    if !IsNameValid(fromId) || !IsNameValid(toId) || Equals(fromId, toId) {
      return;
    }
    // Collected first: NoteGangPower and the sighting cap both change the arrays being read.
    let powers: array<ref<CBGangPower>>;
    for p in this.m_gangPower {
      if IsDefined(p) && Equals(p.playthroughId, fromId) && p.at <= now + CBConfig.SecondsPerHour() {
        ArrayPush(powers, p);
      }
    }
    let seen: array<ref<CBSighting>>;
    for s in this.m_sightings {
      if IsDefined(s) && Equals(s.playthroughId, fromId) && s.seenAt <= now
         && (s.tippedAt <= 0.0 || s.tippedAt <= now) {
        ArrayPush(seen, s);
      }
    }
    for p in powers {
      this.NoteGangPower(toId, p.faction, p.strength, p.at);
    }
    for s in seen {
      let c = new CBSighting();
      c.playthroughId = toId;
      c.rivalId = s.rivalId;
      c.recordID = s.recordID;
      c.x = s.x;
      c.y = s.y;
      c.z = s.z;
      c.district = s.district;
      c.seenAt = s.seenAt;
      c.tippedAt = s.tippedAt;
      c.tipFaction = s.tipFaction;
      ArrayPush(this.m_sightings, c);
    }
    while ArraySize(this.m_sightings) > CBConfig.CapSightings() {
      ArrayErase(this.m_sightings, 0);
    }
  }

  // ---- The action switches (1.8.3) --------------------------------------------------------

  public func GetResetSwitch() -> Int32 {
    return this.m_resetSwitch;
  }

  public func SetResetSwitch(state: Int32) -> Void {
    this.m_resetSwitch = state;
  }

  public func GetSeparateSwitch() -> Int32 {
    return this.m_separateSwitch;
  }

  public func SetSeparateSwitch(state: Int32) -> Void {
    this.m_separateSwitch = state;
  }
}

// What an action switch was last seen doing (CyberbaneService.m_resetSwitch).
public func CBSwitchUnseen() -> Int32 = 0
public func CBSwitchOff() -> Int32 = 1
public func CBSwitchActed() -> Int32 = 2

// Cyberbane - Deed application (spec §7.2)
//
// Applies a completed deed's effects: Renown, deed-Dread, faction standing/renown,
// deed-gated titles, a rumor and a Legend Log entry. The journal signal (S-02)
// calls CBApplyDeedById when it detects completion; bootstrap applies past deeds
// with `silent = true` (no messages). Generic gigs/hustles use their own helpers.

// Deeds, fired from the game's own completion record (spec 7.2, spike S-02).
//
// This was blocked for most of the project's life and the reason recorded for it was wrong.
// The note said `JournalManager.ChangeEntryState` is inherited from a class missing from the
// Codeware dump; it is in fact declared on `JournalManager` itself
// (core/systems/journalManager.script:424) and the real obstacle is that it is
// `public import function` - a native, and redscript cannot wrap natives. So no amount of
// work on that method was ever going to succeed.
//
// The game does not need to be hooked at all. It records what V has finished as quest facts
// and reads them back the same way anywhere it cares - `GetFact( gi, 'q005_done' )` in
// cyberpunk/managers/rpgManager.script:2465. `QuestsSystem.GetFact` is an ordinary readable
// native (core/systems/questSystem.script:24), so the deeds just ask.
//
// Polling is safe here: `CBApplyDeed` already refuses a deed `sys.HasDeed` has recorded, so a
// fact that stays set fires its deed exactly once, and a fact name that does not exist reads 0
// for ever and simply never fires. That last part is why the unverified names below cost
// nothing - the failure mode of a wrong guess is the behaviour this already had.
public func CBDeedFactTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let content = CBContent(game);
  let qs = GameInstance.GetQuestsSystem(game);
  if !IsDefined(sys) || !IsDefined(content) || !IsDefined(qs) {
    return;
  }
  // Held in a local: this getter returns the array by value, and indexing the call result
  // directly reads out of a temporary that is gone by the end of the statement (the crash
  // note on GetRumors in Model/RumorEngine.reds).
  let deeds = content.GetDeeds();
  let i = 0;
  while i < ArraySize(deeds) {
    let def = deeds[i];
    i += 1;
    if IsDefined(def) && NotEquals(def.fact, n"") && !sys.HasDeed(def.id) {
      if qs.GetFact(def.fact) > 0 {
        CBLog.Info(n"Model", s"Deed \(NameToString(def.id)) fired from fact \(NameToString(def.fact)).");
        CBApplyDeed(sys, game, def, false);
      }
    }
  }
}

// Print the candidate quest facts and what the game says they are, so the names the deeds still
// need can be read off a real playthrough instead of guessed. Verbose only, once per session,
// and it reads facts and nothing else.
public func CBProbeDeedFacts(game: GameInstance) -> Void {
  let qs = GameInstance.GetQuestsSystem(game);
  // CBLog.Verbose gates on the configured level itself, so no extra check is needed here.
  if !IsDefined(qs) {
    return;
  }
  let names: array<CName> = [
    n"q003_done", n"q005_done", n"q101_done", n"q110_done", n"q201_done", n"q202_done",
    n"q203_done", n"q204_done", n"mq048_done", n"mq057_done", n"mq058_done", n"sq024_done",
    n"sq027_done", n"sq028_done", n"sq030_done", n"q301_done", n"q302_done", n"q303_done",
    n"courier_missions_done", n"prologue_sts_done", n"wat_sts_counter"
  ];
  let i = 0;
  while i < ArraySize(names) {
    CBLog.Verbose(n"Probe", s"fact \(NameToString(names[i])) = \(qs.GetFact(names[i]))");
    i += 1;
  }
}

public func CBApplyDeedById(sys: ref<CyberbaneSystem>, game: GameInstance, deedId: CName, silent: Bool) -> Void {
  let content = CBContent(game);
  if !IsDefined(content) {
    return;
  }
  CBApplyDeed(sys, game, content.GetDeed(deedId), silent);
}

public func CBApplyDeed(sys: ref<CyberbaneSystem>, game: GameInstance, def: ref<CBDeedDef>, silent: Bool) -> Void {
  if !IsDefined(sys) || !IsDefined(def) {
    return;
  }
  if sys.HasDeed(def.id) {
    return;
  }
  sys.MarkDeed(def.id);

  let renownMult = 1.0;
  let dreadMult = 1.0;
  let toasts = false;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    renownMult = rt.GetSettings().renownGainMult;
    dreadMult = rt.GetSettings().dreadGainMult;
    toasts = CBMessagesOn() && !silent;
  }

  sys.AddRenownPoints(def.renown * renownMult);
  sys.AddDeedDreadPoints(def.dread * dreadMult);

  let firstFaction = n"";
  for fe in def.factionEffects {
    let fs = sys.EnsureFaction(fe.faction);
    fs.standing = ClampF(fs.standing + fe.standingDelta, -100.0, 100.0);
    fs.renown = ClampF(fs.renown + fe.renownDelta, 0.0, 100.0);
    fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
    if Equals(firstFaction, n"") {
      firstFaction = fe.faction;
    }
  }

  let content = CBContent(game);
  for tid in def.titles {
    if !sys.HasTitle(tid) {
      sys.UnlockTitle(tid);
      sys.AddRenownPoints(25.0 * renownMult);
      // The street names you; somebody who works this part of town tells you what they are
      // calling you. A popup about a title was the mod talking, and this is the city.
      if toasts {
        CBContactMessage(game, "Heard them calling you " + CBTitleDisplayById(sys, content, tid) + " today.");
      }
    }
  }

  if def.rumor > 0.0 {
    CBCreateRumor(sys, game, n"Deed", def.rumor, def.district, firstFaction, true);
  }

  let entry = new CBLogEntry();
  entry.kind = n"Deed";
  entry.at = CBGameSeconds(game);
  entry.district = def.district;
  entry.faction = firstFaction;
  entry.value = def.renown;
  sys.AddLogEntry(entry);

  if toasts {
    CBPhoneFromStreet(game, "Your name came up again today. It is getting around.");
  }
  CBEvaluateTitles(sys, game);
}

// Generic gig completion (spec §7.2.3): +20 Renown, Professional +3.
public func CBApplyGig(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints(20.0 * mult);
  sys.AddArchetype(EnumInt(ECBArchetype.Professional), 3.0);
  sys.RefreshPrimaryArchetype();
}

// Generic NCPD hustle (spec §7.2.3): +5 Renown, NCPD +1.5, Professional +1.
public func CBApplyHustle(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let mult = 1.0;
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) && rt.HasSettings() {
    mult = rt.GetSettings().renownGainMult;
  }
  sys.AddRenownPoints(5.0 * mult);
  sys.AddArchetype(EnumInt(ECBArchetype.Professional), 1.0);
  let fs = sys.EnsureFaction(n"NCPD");
  fs.standing = ClampF(fs.standing + 1.5, -100.0, 100.0);
  fs.renown = ClampF(fs.renown + 1.5, 0.0, 100.0);
  fs.renownPeak = MaxF(fs.renownPeak, fs.renown);
  sys.RefreshPrimaryArchetype();
}

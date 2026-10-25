// Cyberbane - Deed application (spec §7.2)
//
// Applies a completed deed's effects: Renown, deed-Dread, faction standing/renown,
// deed-gated titles, a rumor and a Legend Log entry. The journal signal (S-02)
// calls CBApplyDeedById when it detects completion; bootstrap applies past deeds
// with `silent = true` (no messages). Generic gigs/hustles use their own helpers.

public func CBApplyDeedById(sys: ref<CyberbaneSystem>, game: GameInstance, deedId: CName, silent: Bool) -> Void {
  let content = CyberbaneContent.Get();
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
    toasts = rt.GetSettings().toasts && !silent;
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

  let content = CyberbaneContent.Get();
  for tid in def.titles {
    if !sys.HasTitle(tid) {
      sys.UnlockTitle(tid);
      sys.AddRenownPoints(25.0 * renownMult);
      if toasts {
        let tdisp = NameToString(tid);
        if IsDefined(content) {
          let tdef = content.GetTitle(tid);
          if IsDefined(tdef) {
            tdisp = tdef.display;
          }
        }
        CBShowMessage(game, "Cyberbane: Title unlocked - " + tdisp, 5.0);
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
    CBShowMessage(game, "Cyberbane: Your reputation grows.", 4.0);
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

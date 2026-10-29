// Cyberbane - Broker peace & compatibility backoff (spec §11.3, §17)
//
// Broker peace: pay a gang you can buy off to drop a hostility or vendetta. It costs
// eddies scaled by how much blood is between you, pulls their standing back out of the
// hostile band and clears the vendetta. Triggered from the Hub (Shift + Hub key) or the
// public API.
//
// Compatibility: when They Will Remember compatibility is on (or auto-detected), Cyberbane
// stands down from the systems that overlap - hostile-on-sight, hit squads and faction
// disguises - and leaves the rest running (spec §17).

public func CBTwrActive() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(rt) || !rt.HasSettings() {
    return false;
  }
  let mode = rt.GetSettings().twrCompat;
  if Equals(mode, ECBTwrCompat.On) {
    return true;
  }
  if Equals(mode, ECBTwrCompat.Off) {
    return false;
  }
  return CBDetectTwr();   // Auto
}

// Detect They Will Remember by asking Mod Settings which mods have registered a page.
//
// That list is the steadiest signal available: They Will Remember requires Mod Settings,
// and the names in this list are the ones the player sees in the settings menu, so they
// do not move when the other mod reorganises its own classes. Matching on "Remember" also
// catches Night City Remembers, which is a ground-up replacement for They Will Remember
// and overlaps Cyberbane in exactly the same places.
//
// Scanned once and cached on the runtime service - the compat check is read per NPC per
// tick. An empty list means Mod Settings has not finished registering yet, so that answer
// is not cached and the scan is retried on the next call.
func CBDetectTwr() -> Bool {
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    let cached = rt.GetTwrDetected();
    if cached != 0 {
      return cached == 1;
    }
  }
  // The compiler already knows, and that answer is exact: ModuleExists asks whether They
  // Will Remember's own scripts are in this build. The settings-page scan below stays as the
  // fallback, because Night City Remembers is a separate rewrite with its own module name
  // and the name match is what catches it.
  let found = CBTwrModulePresent();
  if !found {
    let mods = ModSettings.GetMods();
    if ArraySize(mods) == 0 {
      return false;   // not ready yet; ask again next time rather than caching a guess
    }
    for mod in mods {
      if StrContains(NameToString(mod), "Remember") {
        found = true;
      }
    }
  }
  if IsDefined(rt) {
    rt.SetTwrDetected(found);
  }
  if found {
    CBLog.Info(n"Core", "They Will Remember detected; standing down the systems that overlap (hostility on sight, hit squads, faction disguises).");
  } else {
    CBLog.Info(n"Core", "They Will Remember not detected; Cyberbane is running its own hostility, hit squad and disguise systems.");
  }
  return found;
}

// Is New Game Plus running?
//
// Checked at compile time rather than by name, which is the exact signal: ModuleExists asks
// the compiler whether that mod's scripts are in the build, so there is no list to scan, no
// cache to invalidate and no way for a renamed settings page to fool it.
//
// It matters because New Game Plus rebuilds every NPC in the game to be harder. Its buffs and
// Cyberbane's are both stat multipliers on the same puppet, so they multiply rather than
// replace, and an apex under both would simply not die. Cyberbane halves its own contribution
// and stops rolling its own traits when this is true (see CBApexStrengthFraction).
@if(ModuleExists("NGPlus"))
public func CBNgpActive() -> Bool {
  return true;
}

@if(!ModuleExists("NGPlus"))
public func CBNgpActive() -> Bool {
  return false;
}

// Is They Will Remember compiled into this build?
@if(ModuleExists("TheyWillRemember"))
func CBTwrModulePresent() -> Bool {
  return true;
}

@if(!ModuleExists("TheyWillRemember"))
func CBTwrModulePresent() -> Bool {
  return false;
}

// What will this gang take to call it off?
//
// The old price was the body count and nothing else: `1000 + 50 * kills`. That meant a gang at
// vendetta charged exactly the same as a gang that merely disliked you, which is wrong in the
// way that matters - the whole point of a vendetta is that it is harder to get out of. It also
// meant the number said nothing about the thing the player is actually buying their way out of.
//
// Three things set the price now:
//   - the bodies, as before, because that is the grievance;
//   - how far into the hostile band their standing has fallen, because that is how much they
//     hate you rather than how much you have cost them;
//   - and a straight multiplier for a vendetta, because a vendetta is a decision they have
//     already taken and taking it back is expensive.
//
// Still capped, so a long campaign against one gang does not price peace out of reach forever.
public func CBPeacePrice(fs: ref<CBFactionState>, posture: ECBPosture) -> Int32 {
  if !IsDefined(fs) {
    return CBConfig.PeaceBaseCost();
  }
  let cost = Cast<Float>(CBConfig.PeaceBaseCost())
           + Cast<Float>(CBConfig.PeacePerKill()) * Cast<Float>(fs.kills);
  // Standing runs to -100 at its worst. Only the hostile part of it is charged for.
  let hate = ClampF(-fs.standing / 100.0, 0.0, 1.0);
  cost += Cast<Float>(CBConfig.PeacePerHate()) * hate;
  if Equals(posture, ECBPosture.Vendetta) {
    cost *= CBConfig.PeaceVendettaMult();
  }
  let capped = FloorF(cost);
  if capped > CBConfig.PeaceMaxCost() {
    capped = CBConfig.PeaceMaxCost();
  }
  return capped;
}

// Pay off a single faction. Returns true only if peace was actually brokered.
public func CBBrokerPeace(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName) -> Bool {
  if !IsDefined(sys) || Equals(factionId, n"") {
    return false;
  }
  let content = CBContent(game);
  if !IsDefined(content) {
    return false;
  }
  let prof = content.GetFaction(factionId);
  if !IsDefined(prof) || !prof.canBeBought {
    return false;   // corps and the law cannot be bought off (spec §9.8/§11.3)
  }
  let fs = sys.FindFaction(factionId);
  let score = sys.GetScore();
  if !IsDefined(fs) || !IsDefined(score) {
    return false;
  }
  let posture = score.GetPosture(factionId);
  if !(Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta)) {
    return false;   // nothing to buy off
  }

  let cost = CBPeacePrice(fs, posture);
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return false;
  }
  let money = ItemID.FromTDBID(t"Items.money");
  if ts.GetItemQuantity(player, money) < cost {
    if CBToastsOn() {
      CBShowMessage(game, s"Cyberbane: \(NameToString(factionId)) want \(cost)eb to call it off. You're short.", 4.0);
    }
    return false;
  }

  ts.RemoveItem(player, money, cost);
  fs.standing = MaxF(fs.standing, 15.0);   // pull out of the hostile band
  fs.vendettaSince = 0.0;
  fs.lastPeaceAt = CBGameSeconds(game);

  // Whatever they already had on its way is called off. Without this the Hub went on
  // counting down a crew from a gang the player had just paid, and the apex warning stood.
  if Equals(sys.GetPendingSquadFaction(), factionId) {
    sys.ClearPendingSquad();
  }
  if Equals(sys.GetPendingApexFaction(), factionId) {
    sys.SetPendingApex(n"", 0);
  }

  let deal = new CBPeaceDeal();
  deal.faction = factionId;
  deal.at = fs.lastPeaceAt;
  deal.cost = cost;
  sys.AddPeaceDeal(deal);

  if CBToastsOn() {
    let what = Equals(posture, ECBPosture.Vendetta) ? "vendetta" : "hostility";
    CBShowMessage(game, s"Cyberbane: \(NameToString(factionId)) \(what) bought off for \(cost)eb.", 4.0);
  }
  CBLog.Info(n"Economy", s"Peace brokered with \(NameToString(factionId)) for \(cost).");
  return true;
}

// Broker peace with the worst gang you can buy off (used by the Hub shortcut).
public func CBBrokerPeaceBest(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let content = CBContent(game);
  let score = sys.GetScore();
  if !IsDefined(content) || !IsDefined(score) {
    return false;
  }
  let worst: ref<CBFactionState>;
  let worstStanding = 1000.0;
  for fs in sys.GetFactionStates() {
    if IsDefined(fs) {
      let prof = content.GetFaction(fs.id);
      let posture = score.GetPosture(fs.id);
      let hostile = Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta);
      if IsDefined(prof) && prof.canBeBought && hostile && fs.standing < worstStanding {
        worst = fs;
        worstStanding = fs.standing;
      }
    }
  }
  if !IsDefined(worst) {
    if CBToastsOn() {
      CBShowMessage(game, "Cyberbane: no one to make peace with right now.", 3.0);
    }
    return false;
  }
  return CBBrokerPeace(sys, game, worst.id);
}

func CBToastsOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() && rt.GetSettings().toasts;
}

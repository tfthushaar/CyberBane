// Cyberbane — Broker peace & compatibility backoff (spec §11.3, §17)
//
// Broker peace: pay a gang you can buy off to drop a hostility or vendetta. It costs
// eddies scaled by how much blood is between you, pulls their standing back out of the
// hostile band and clears the vendetta. Triggered from the Hub (Shift + Hub key) or the
// public API.
//
// Compatibility: when They Will Remember compatibility is on (or auto-detected), Cyberbane
// stands down from the systems that overlap — hostile-on-sight, hit squads and faction
// disguises — and leaves the rest running (spec §17).

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

// TODO S-16: detect They Will Remember at runtime (a known record / class). Until that
// is verified in-game, Auto behaves as Off so Cyberbane keeps its own systems.
func CBDetectTwr() -> Bool {
  return false;
}

// Pay off a single faction. Returns true only if peace was actually brokered.
public func CBBrokerPeace(sys: ref<CyberbaneSystem>, game: GameInstance, factionId: CName) -> Bool {
  if !IsDefined(sys) || Equals(factionId, n"") {
    return false;
  }
  let content = CyberbaneContent.Get();
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

  let cost = 1000 + 50 * fs.kills;
  if cost > 15000 {
    cost = 15000;
  }
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

  let deal = new CBPeaceDeal();
  deal.faction = factionId;
  deal.at = fs.lastPeaceAt;
  deal.cost = cost;
  sys.AddPeaceDeal(deal);

  if CBToastsOn() {
    CBShowMessage(game, s"Cyberbane: peace brokered with \(NameToString(factionId)) for \(cost)eb.", 4.0);
  }
  CBLog.Info(n"Economy", s"Peace brokered with \(NameToString(factionId)) for \(cost).");
  return true;
}

// Broker peace with the worst gang you can buy off (used by the Hub shortcut).
public func CBBrokerPeaceBest(sys: ref<CyberbaneSystem>, game: GameInstance) -> Bool {
  if !IsDefined(sys) {
    return false;
  }
  let content = CyberbaneContent.Get();
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

// Cyberbane - Gangs that hate each other (spec §11.5)
//
// Hurting a gang raises V's standing with the gangs that hate it, so Friendly and Allied can be earned in play.

// The gangs this one is at war with.
public func CBGangRivalsOf(content: ref<CyberbaneContent>, faction: CName) -> array<CName> {
  let none: array<CName>;
  if !IsDefined(content) || Equals(faction, n"") {
    return none;
  }
  let prof = content.GetFaction(faction);
  if !IsDefined(prof) {
    return none;
  }
  return prof.rivalFactions;
}

public func CBEnemyOfEnemyShare() -> Float {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.HasSettings() ? rt.GetSettings().enemyOfEnemyShare : CBConfig.RivalGangShare();
}

func CBGangHurtLately(fs: ref<CBFactionState>, now: Float) -> Bool {
  return fs.lastIncidentAt > 0.0 && now >= fs.lastIncidentAt
      && (now - fs.lastIncidentAt) < CBConfig.GangGrudgeHours() * CBConfig.SecondsPerHour();
}

public func CBGangsAreRivals(content: ref<CyberbaneContent>, a: CName, b: CName) -> Bool {
  let rivals = CBGangRivalsOf(content, a);
  let i = 0;
  while i < ArraySize(rivals) {
    if Equals(rivals[i], b) {
      return true;
    }
    i += 1;
  }
  return false;
}

// V just cost `victim` this much standing (negative, already scaled by who saw it). Their enemies warm to V by a share
// of it, up to a ceiling: being somebody's enemy's enemy makes you welcome, it does not make you family.
public func CBCreditRivalGangs(sys: ref<CyberbaneSystem>, game: GameInstance, victim: CName, loss: Float) -> Void {
  // Not with reputation frozen: kills stopped short of here, words in the street did not.
  if !IsDefined(sys) || loss >= 0.0 || CBReputationFrozen() {
    return;
  }
  let content = CBContent(game);
  let rivals = CBGangRivalsOf(content, victim);
  let gain = -loss * CBEnemyOfEnemyShare();
  if gain <= 0.0 {
    return;
  }
  let now = CBGameSeconds(game);
  let i = 0;
  while i < ArraySize(rivals) {
    let id = rivals[i];
    i += 1;
    if NotEquals(id, n"") && NotEquals(id, victim) {
      let fs = sys.EnsureFaction(id);
      // Whoever V has been killing does not get to be grateful. The credit also stops short of Allied
      // for a gang V has any blood with: being useful to somebody is not the same as being theirs.
      if IsDefined(fs) && !CBGangHurtLately(fs, now) {
        let ceiling = fs.kills > 0 ? CBConfig.RivalGangCeilingBloodied() : CBConfig.RivalGangCeiling();
        let got = gain;
        // The gang V backs, where it is on the streets: V's work counts double, and can take it all the way
        // (Economy/War.reds, [33]).
        if CBBackedHere(sys, game, id) {
          got = gain * 2.0;
          ceiling = 100.0;
        }
        if fs.standing < ceiling {
          fs.standing = MinF(fs.standing + got, ceiling);
        }
      }
    }
  }
}

// The enemy of theirs V has hurt the most, for the line they send.
func CBTopEnemyOf(sys: ref<CyberbaneSystem>, content: ref<CyberbaneContent>, faction: CName) -> CName {
  let rivals = CBGangRivalsOf(content, faction);
  let best = n"";
  let bestKills = 0;
  let i = 0;
  while i < ArraySize(rivals) {
    let fs = sys.FindFaction(rivals[i]);
    if IsDefined(fs) && fs.kills > bestKills {
      best = rivals[i];
      bestKills = fs.kills;
    }
    i += 1;
  }
  return best;
}

// V put one of theirs down and left them breathing, or let a Rival of theirs walk.
public func CBCreditMercy(sys: ref<CyberbaneSystem>, faction: CName, amount: Float) -> Void {
  // Not with reputation frozen: talk, surrenders and the street's events credit mercy here directly.
  if !IsDefined(sys) || Equals(faction, n"") || amount <= 0.0 || CBReputationFrozen() {
    return;
  }
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(fs) || fs.standing >= CBConfig.MercyCeiling() {
    return;
  }
  // Some gangs make more of mercy than others (Data/GangCodes.reds).
  fs.standing = ClampF(fs.standing + amount * sys.WornPerk().mercyMult * CBCodeMercy(faction), -100.0, CBConfig.MercyCeiling());
}

// A corporation's contract done (Spawn/LivingStreet.reds): the one steady way to win a corporation over, whose people
// are rarely on the street to be helped, spared or fought beside.
public func CBCreditContract(sys: ref<CyberbaneSystem>, faction: CName, amount: Float) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") || amount <= 0.0 || CBReputationFrozen() {
    return;
  }
  let fs = sys.EnsureFaction(faction);
  if IsDefined(fs) {
    fs.standing = ClampF(fs.standing + amount, -100.0, 100.0);
  }
}

// A gang has just come round to V. Called from the posture watch, once per crossing.
public func CBAnnounceWarming(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName, allied: Bool) -> Void {
  let content = CBContent(game);
  let enemy = CBTopEnemyOf(sys, content, faction);
  let enemyLabel = CBFactionLabel(enemy);
  CBFileLog(sys, allied ? n"Allied" : n"Friendly", CBGameSeconds(game), CBEventDistrict(sys, game), faction, 0.0);
  if !CBToastsOn() || !CBFactionFieldsSquads(faction) {
    return;
  }
  if allied {
    if StrLen(enemyLabel) > 0 {
      CBPhoneFromAlly(game, faction, CBTf(n"Cyberbane-GangRivalries-YouHaveDoneMoreToThan", [s"\(enemyLabel)"]));
    } else {
      CBPhoneFromAlly(game, faction, CBT(n"Cyberbane-GangRivalries-YouHaveEarnedItOurStreets"));
    }
    return;
  }
  if StrLen(enemyLabel) > 0 {
    CBPhoneFromAlly(game, faction, CBTf(n"Cyberbane-GangRivalries-WordIsYouHaveBeenMaking", [s"\(enemyLabel)"]));
  } else {
    CBPhoneFromAlly(game, faction, CBT(n"Cyberbane-GangRivalries-YouAreAllRightByUs"));
  }
}

// One of `attacker`'s enemies who likes V gives V a heads up that `attacker` has sent people.
public func CBAllyTipOff(sys: ref<CyberbaneSystem>, game: GameInstance, attacker: CName) -> Bool {
  if !IsDefined(sys) || !CBToastsOn() {
    return false;
  }
  let score = sys.GetScore();
  let content = CBContent(game);
  if !IsDefined(score) || !IsDefined(content) {
    return false;
  }
  let rivals = CBGangRivalsOf(content, attacker);
  let label = CBFactionLabel(attacker);
  if StrLen(label) == 0 {
    return false;
  }
  let i = 0;
  while i < ArraySize(rivals) {
    let ally = rivals[i];
    i += 1;
    let posture = score.GetPosture(ally);
    if (Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly))
       && CBFactionFieldsSquads(ally) {
      CBPhoneSendUrgent(game, CBPhoneGangSender(ally), CBTf(n"Cyberbane-GangRivalries-HeadsUpJustSentPeopleYour", [s"\(label)"]), CBHudCyan());
      return true;   // one warning is enough
    }
  }
  return false;
}

// Vendors on a gang's turf know where V stands with that gang.
public func CBTurfPriceModifier(sys: ref<CyberbaneSystem>) -> Float {
  if !IsDefined(sys) {
    return 0.0;
  }
  let score = sys.GetScore();
  let content = sys.GetContent();
  let district = sys.GetCurrentDistrict();
  if !IsDefined(score) || !IsDefined(content) || Equals(district, n"") {
    return 0.0;
  }
  let best = 0.0;
  let worst = 0.0;
  // Whoever holds these streets now (Spawn/Queue.reds, CBTurfGangsHere): a gang pushed out of a
  // district no longer has the vendors there looking over their shoulder at it.
  for id in CBTurfGangsHere(sys) {
    if NotEquals(id, n"") {
      let posture = score.GetPosture(id);
      if Equals(posture, ECBPosture.Allied) {
        best = MinF(best, -CBConfig.TurfAlliedDiscount());
      } else {
        if Equals(posture, ECBPosture.Friendly) {
          best = MinF(best, -CBConfig.TurfFriendlyDiscount());
        } else {
          if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
            worst = MaxF(worst, CBConfig.TurfHostileSurcharge());
          }
        }
      }
    }
  }
  // A district can belong to two gangs. Liking V counts for more than hating V there, because
  // the vendor is choosing whose good side to stay on.
  return best < 0.0 ? best : worst;
}

// Keeping the peace on a gang's streets.
public func CBKeepThePeaceTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || CBReputationFrozen() || sys.IsInSafeZone() {
    return;
  }
  let now = CBGameSeconds(game);
  let quiet = CBConfig.PeaceKeptQuietHours() * CBConfig.SecondsPerHour();
  for id in CBTurfGangsHere(sys) {
    if NotEquals(id, n"") && CBFactionFieldsSquads(id) {
      let fs = sys.EnsureFaction(id);
      if IsDefined(fs) && fs.standing > CBConfig.PostureHostile() && fs.standing < CBConfig.MercyCeiling()
         && (fs.lastIncidentAt <= 0.0 || (now >= fs.lastIncidentAt && (now - fs.lastIncidentAt) >= quiet)) {
        fs.standing = MinF(CBConfig.MercyCeiling(), fs.standing + CBConfig.PeaceKeptPerHour());
      }
    }
  }
}

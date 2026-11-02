// Cyberbane - Gangs that hate each other (spec §11.5)
//
// Standing could only ever fall. Kills took it down, decay drifted it back toward where a gang
// started, and the only thing that ever raised it was tribute, which is a gang paying to stay out
// of V's way rather than liking V. So no gang could come to think well of V however V played,
// and the Friendly and Allied postures existed only on paper.
//
// Night City's gangs are at war with each other, and the enemy of my enemy is the oldest deal on
// the street. Each gang's profile names the crews it is at war with (Data/Factions.reds), and
// every time V hurts one of them, the gangs that hate it hear about it and warm to V by a share of
// what the victim lost. It goes through the same witness scaling as the loss itself: work nobody
// saw is worth a quarter, because the bodies turn up but nobody can say who did it.
//
// What it gets V, once a gang is Friendly or better:
//   - better prices from vendors on their turf (Signals/VendorSignals.reds);
//   - a warning when one of their enemies sends people after V (CBAllyTipOff);
//   - and they never send anyone, since only a hostile gang does.
// A gang that crosses into Friendly or Allied says so, and it goes in the street's file.

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

// V just cost `victim` this much standing (negative, already scaled by who saw it). Their
// enemies warm to V by a share of it, up to a ceiling: being somebody's enemy's enemy makes you
// welcome, it does not make you family. A gang already above the ceiling is left where it is.
public func CBCreditRivalGangs(sys: ref<CyberbaneSystem>, game: GameInstance, victim: CName, loss: Float) -> Void {
  if !IsDefined(sys) || loss >= 0.0 {
    return;
  }
  let content = CBContent(game);
  let rivals = CBGangRivalsOf(content, victim);
  let gain = -loss * CBConfig.RivalGangShare();
  let ceiling = CBConfig.RivalGangCeiling();
  let i = 0;
  while i < ArraySize(rivals) {
    let id = rivals[i];
    i += 1;
    if NotEquals(id, n"") && NotEquals(id, victim) {
      let fs = sys.EnsureFaction(id);
      if IsDefined(fs) && fs.standing < ceiling {
        fs.standing = MinF(fs.standing + gain, ceiling);
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
//
// This is the other way to be thought well of, and it is deliberately the weaker one: it is
// capped at MercyCeiling, which is above Neutral and below Allied, so restraint alone makes a
// gang tolerate V and nothing more. A gang already past the cap is left alone rather than
// pulled back down to it, because a gang that likes V for other reasons does not mind mercy.
public func CBCreditMercy(sys: ref<CyberbaneSystem>, faction: CName, amount: Float) -> Void {
  if !IsDefined(sys) || Equals(faction, n"") || amount <= 0.0 {
    return;
  }
  let fs = sys.EnsureFaction(faction);
  if !IsDefined(fs) || fs.standing >= CBConfig.MercyCeiling() {
    return;
  }
  fs.standing = ClampF(fs.standing + amount, -100.0, CBConfig.MercyCeiling());
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
      CBPhoneFromAlly(game, faction, s"You have done more to \(enemyLabel) than half our own crew. Our streets are yours. Prices too.");
    } else {
      CBPhoneFromAlly(game, faction, "You have earned it. Our streets are yours. Prices too.");
    }
    return;
  }
  if StrLen(enemyLabel) > 0 {
    CBPhoneFromAlly(game, faction, s"Word is you have been making life hard for \(enemyLabel). You are welcome on our streets.");
  } else {
    CBPhoneFromAlly(game, faction, "You are all right by us. You are welcome on our streets.");
  }
}

// One of `attacker`'s enemies who likes V gives V a heads up that `attacker` has sent people.
public func CBAllyTipOff(sys: ref<CyberbaneSystem>, game: GameInstance, attacker: CName) -> Void {
  if !IsDefined(sys) || !CBToastsOn() {
    return;
  }
  let score = sys.GetScore();
  let content = CBContent(game);
  if !IsDefined(score) || !IsDefined(content) {
    return;
  }
  let rivals = CBGangRivalsOf(content, attacker);
  let label = CBFactionLabel(attacker);
  if StrLen(label) == 0 {
    return;
  }
  let i = 0;
  while i < ArraySize(rivals) {
    let ally = rivals[i];
    i += 1;
    let posture = score.GetPosture(ally);
    if (Equals(posture, ECBPosture.Allied) || Equals(posture, ECBPosture.Friendly))
       && CBFactionFieldsSquads(ally) {
      CBPhoneFromAlly(game, ally, s"Heads up. \(label) just sent people your way. Watch the road.");
      return;   // one warning is enough
    }
  }
}

// Vendors on a gang's turf know where V stands with that gang. Returns a signed buy-price
// modifier for the district V is in: a discount where the turf belongs to a gang that likes V, a
// surcharge where it belongs to one that wants V dead.
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
  for prof in content.GetFactions() {
    if IsDefined(prof) && prof.isGang && ArrayContains(prof.turf, district) {
      let posture = score.GetPosture(prof.id);
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

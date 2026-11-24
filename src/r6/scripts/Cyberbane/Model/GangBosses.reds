// Cyberbane - The gangs' bosses, sit-down invitations, and what crashing gang business leads to (2.7.7)
//
// Every gang has a boss with a name. When the gang has a Rival at the top of its ladder (rank 4), that Rival is the boss
// and can be met as any Rival can; otherwise the boss is a name from the gang's own pool, the same for the whole
// playthrough. The boss is named on the Gangs page, and signs the gang's biggest texts: a vendetta sworn, a price to call
// one off, an invitation to a sit-down.
//
// A gang that respects V (friendly or allied) invites V to its sit-down. V standing there while it is settled is V
// speaking for them: they think better of V for it, the other side less. Crashing a sit-down or a deal leads somewhere:
// the side V helped says thank you, the side V hurt may make a Rival of it, and on a deal's own streets the hurt gang loses
// ground.

// The boss's name, by their gang.
public func CBGangBossName(sys: ref<CyberbaneSystem>, gang: CName) -> String {
  if !IsDefined(sys) || !IsNameValid(gang) {
    return "";
  }
  let top = CBGangBossRival(sys, gang);
  if IsDefined(top) {
    return CBRivalDisplayName(sys.GetContent(), top);
  }
  let content = sys.GetContent();
  let pool = IsDefined(content) ? content.GetFactionNames(gang) : null;
  if !IsDefined(pool) || ArraySize(pool.firstNames) == 0 || ArraySize(pool.lastNames) == 0 {
    return "";
  }
  let seed = CBGangBossSeed(sys, gang);
  return pool.firstNames[CBHashIndex(seed, 11, ArraySize(pool.firstNames))] + " " + pool.lastNames[CBHashIndex(seed, 29, ArraySize(pool.lastNames))];
}

// A Rival of theirs at the top of the ladder, still out there: the boss.
public func CBGangBossRival(sys: ref<CyberbaneSystem>, gang: CName) -> ref<CBRival> {
  let best: ref<CBRival>;
  for r in sys.GetRivals() {
    if IsDefined(r) && Equals(r.faction, gang) && r.rank >= 4
       && (r.state == EnumInt(ECBRivalState.Active) || r.state == EnumInt(ECBRivalState.Hunting) || r.state == EnumInt(ECBRivalState.Dormant))
       && (!IsDefined(best) || r.encounters > best.encounters) {
      best = r;
    }
  }
  return best;
}

// The same for the whole playthrough: the gang's place in the content list and the playthrough's birth.
func CBGangBossSeed(sys: ref<CyberbaneSystem>, gang: CName) -> Int32 {
  let content = sys.GetContent();
  let i = 0;
  let at = 0;
  if IsDefined(content) {
    for f in content.GetFactions() {
      if IsDefined(f) && Equals(f.id, gang) {
        at = i;
      }
      i += 1;
    }
  }
  return at * 7919 + StrLen(NameToString(sys.GetPlaythroughId())) * 131;
}

// A text from the gang, signed by its boss when the gang has one: "Mama Welles: ..." style, the way the crew's group chat
// signs its lines. The text's own tone is its sound (no ring: the game's ring plays until a call stops it, UI/Sounds.reds).
public func CBGangBossSigned(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName, body: String) -> String {
  let boss = CBGangBossName(sys, gang);
  if StrLen(boss) == 0 {
    return body;
  }
  return CBTf(n"Cyberbane-GangBosses-Signed", [boss, body]);
}

// What each standing level gets V with a gang, in a line for the Gangs page.
public func CBGangStandingPerks(posture: ECBPosture) -> String {
  switch posture {
    case ECBPosture.Allied: return CBT(n"Cyberbane-GangBosses-PerksAllied");
    case ECBPosture.Friendly: return CBT(n"Cyberbane-GangBosses-PerksFriendly");
    case ECBPosture.Neutral: return CBT(n"Cyberbane-GangBosses-PerksNeutral");
    case ECBPosture.Hostile: return CBT(n"Cyberbane-GangBosses-PerksHostile");
    case ECBPosture.Vendetta: return CBT(n"Cyberbane-GangBosses-PerksVendetta");
  }
  return "";
}

// The Gangs page's lines about the boss and the standing (UI/Hud.reds).
public func CBGangBossLines(sys: ref<CyberbaneSystem>, gang: CName) -> String {
  let out = "";
  let boss = CBGangBossName(sys, gang);
  if StrLen(boss) > 0 {
    out += IsDefined(CBGangBossRival(sys, gang)) ? CBTf(n"Cyberbane-GangBosses-BossRival", [boss]) : CBTf(n"Cyberbane-GangBosses-Boss", [boss]);
  }
  let score = sys.GetScore();
  if IsDefined(score) {
    let perks = CBGangStandingPerks(score.GetPosture(gang));
    if StrLen(perks) > 0 {
      out += CBTf(n"Cyberbane-GangBosses-Perks", [perks]);
    }
  }
  return out;
}

// ---- Sit-down invitations ------------------------------------------------------------------------------------------

// A sit-down was set (Spawn/StreetEvents.reds): a gang that respects V asks V to come and speak for them. The gang asking.
public func CBSitDownInvite(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> CName {
  let score = sys.GetScore();
  if !IsDefined(score) || !IsDefined(ev) || !CBMessagesOn() {
    return n"";
  }
  let inviter = n"";
  let pa = score.GetPosture(ev.a);
  let pb = score.GetPosture(ev.b);
  if Equals(pa, ECBPosture.Allied) || (Equals(pa, ECBPosture.Friendly) && !Equals(pb, ECBPosture.Allied)) {
    inviter = ev.a;
  } else {
    if Equals(pb, ECBPosture.Allied) || Equals(pb, ECBPosture.Friendly) {
      inviter = ev.b;
    }
  }
  if !IsNameValid(inviter) {
    return n"";
  }
  let other = Equals(inviter, ev.a) ? ev.b : ev.a;
  CBPhoneSendTinted(game, CBPhoneGangSender(inviter),
    CBGangBossSigned(sys, game, inviter, CBTf(n"Cyberbane-GangBosses-Invite", [CBFactionLabel(other), CBClockWord(ev.from)])), CBHudCyan());
  CBLog.Info(n"Street", s"\(NameToString(inviter)) invited V to its sit-down.");
  return inviter;
}

// The sit-down settled with V standing there: V spoke for whoever asked.
public func CBSitDownSpokeFor(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  if !IsDefined(ev) || !IsNameValid(ev.invitedBy) || !ev.placed || ev.nearest > CBConfig.SitDownPresentDistance() {
    return;
  }
  let other = Equals(ev.invitedBy, ev.a) ? ev.b : ev.a;
  CBTalkWarm(sys, game, ev.invitedBy, CBConfig.SitDownSpokeWarmth(), 100.0);
  CBTalkSlight(sys, game, other, CBConfig.SitDownSpokeWarmth() * 0.5);
  if CBMessagesOn() {
    CBPhoneSendTinted(game, CBPhoneGangSender(ev.invitedBy), CBGangBossSigned(sys, game, ev.invitedBy, CBT(n"Cyberbane-GangBosses-SpokeFor")), CBHudCyan());
  }
  CBFileLog(sys, n"SpokeAtSitDown", CBGameSeconds(game), CBEventDistrict(sys, game), ev.invitedBy, 0.0);
  CBLog.Info(n"Street", "V spoke for a gang at its sit-down.");
}

// ---- Consequences of crashing gang business ------------------------------------------------------------------------

// A sit-down or a deal V broke up (CBEventCrashed): the side V helped, the side V hurt, the ground.
public func CBEventConsequences(sys: ref<CyberbaneSystem>, game: GameInstance, ev: ref<CBStreetEvent>) -> Void {
  if !IsDefined(ev) || !(Equals(ev.kind, CBEvSitDown()) || Equals(ev.kind, CBEvArmsDeal()) || Equals(ev.kind, CBEvRacket())) {
    return;
  }
  let hurt = ev.a;
  let content = sys.GetContent();
  // Who V helped: the hurt gang's worst enemy, who is glad of it.
  let helped = IsDefined(content) ? CBTopEnemyOf(sys, content, hurt) : n"";
  if Equals(ev.kind, CBEvSitDown()) {
    helped = n"";   // both sides of a sit-down were hurt
  }
  if IsNameValid(helped) && CBFactionOn(helped) && CBMessagesOn() {
    CBTalkWarm(sys, game, helped, CBConfig.EventHelpedWarmth(), 60.0);
    CBHearsayFromAlly(game, helped, CBTf(n"Cyberbane-GangBosses-Helped", [CBFactionLabel(hurt)]), n"");
  }
  // One of the side V hurt takes it personally: a Rival of theirs, now and then.
  if CBRivalsOn() && RandF() < CBConfig.EventRivalChance() {
    let record = CBGangTemplate(sys, hurt);
    if TDBID.IsValid(record) {
      let r = CBCreateRival(sys, game, hurt, record, n"", ECBRivalSource.Survivor, CBEventDistrict(sys, game), CBGameSeconds(game));
      if IsDefined(r) {
        CBLog.Info(n"Street", "Crashing gang business made a Rival.");
      }
    }
  }
  // A deal or a racket on their own streets: the ground loosens under them.
  if !Equals(ev.kind, CBEvSitDown()) {
    let tb = CBTurfBook.Get(game);
    if IsDefined(tb) && IsNameValid(ev.district) {
      tb.AddLocalLoss(ev.district, hurt, CBConfig.EventGroundLoss(), CBGameSeconds(game));
    }
  }
}

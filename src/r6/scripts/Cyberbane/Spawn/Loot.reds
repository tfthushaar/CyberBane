// Cyberbane - What they leave behind (spec §9.12)
//
// Loot on the bodies of the people Cyberbane sends, with a chance of an iconic from top Rivals and gang leaders.

// Iconic weapons found exploring the city. Edit this list to taste; each entry is still checked
// at runtime (it must exist, carry the IconicWeapon tag, and not carry the Quest tag).
public func CBLootIconics() -> array<TweakDBID> {
  let out: array<TweakDBID>;
  ArrayPush(out, t"Items.Preset_Burya_Comrade");        // Comrade's Hammer
  ArrayPush(out, t"Items.Preset_Igla_Sovereign");       // Sovereign
  ArrayPush(out, t"Items.Preset_Ajax_Moron");           // Moron Labe
  ArrayPush(out, t"Items.Preset_Copperhead_Genesis");   // Genesis
  ArrayPush(out, t"Items.Preset_Pulsar_Buzzsaw");       // Buzzsaw
  ArrayPush(out, t"Items.Preset_Tactician_Headsman");   // Headsman
  return out;
}

// How much more V gets at V's level: 1.0 at level 1, up to 1 + LootLevelScaleMax at level 60.
public func CBLootLevelScale(game: GameInstance) -> Float {
  let player = GetPlayer(game);
  let stats = GameInstance.GetStatsSystem(game);
  if !IsDefined(player) || !IsDefined(stats) {
    return 1.0;
  }
  let level = stats.GetStatValue(Cast<StatsObjectID>(player.GetEntityID()), gamedataStatType.Level);
  return 1.0 + ClampF(level / 60.0, 0.0, 1.0) * CBConfig.LootLevelScaleMax();
}

// Loot tiers.
public func CBLootTierCrew() -> Int32 = 1
public func CBLootTierApex() -> Int32 = 4

// The tier for a Rival: higher rank, better loot, and a leader one step better again.
public func CBLootTierRival(r: ref<CBRival>, role: Int32) -> Int32 {
  if !IsDefined(r) {
    return 2;
  }
  let t = 1 + r.rank + (role == CBRoleLeader() ? 1 : 0);
  return Clamp(t, 2, 5);
}

func CBLootValid(id: TweakDBID) -> Bool {
  return TDBID.IsValid(id) && IsDefined(TweakDBInterface.GetItemRecord(id));
}

func CBLootAdd(out ids: array<TweakDBID>, out counts: array<Int32>, id: TweakDBID, count: Int32) -> Void {
  if count > 0 && CBLootValid(id) {
    ArrayPush(ids, id);
    ArrayPush(counts, count);
  }
}

// What a body of this tier carries.
public func CBLootRoll(tier: Int32, out ids: array<TweakDBID>, out counts: array<Int32>) -> Void {
  let ammo: array<TweakDBID>;
  ArrayPush(ammo, t"Ammo.HandgunAmmo");
  ArrayPush(ammo, t"Ammo.RifleAmmo");
  ArrayPush(ammo, t"Ammo.ShotgunAmmo");
  ArrayPush(ammo, t"Ammo.SniperRifleAmmo");
  let pick = ammo[RandRange(0, ArraySize(ammo))];
  if tier <= 1 {
    if RandF() < CBConfig.LootCrewChance() {
      CBLootAdd(ids, counts, pick, RandRange(15, 31));
      CBLootAdd(ids, counts, t"Items.CommonMaterial1", RandRange(1, 4));
      if RandF() < 0.4 {
        CBLootAdd(ids, counts, t"Items.UncommonMaterial1", 1);
      }
    }
    return;
  }
  CBLootAdd(ids, counts, pick, RandRange(20, 41));
  if tier == 2 {
    CBLootAdd(ids, counts, t"Items.UncommonMaterial1", RandRange(2, 4));
    CBLootAdd(ids, counts, t"Items.RareMaterial1", 1);
    return;
  }
  if tier == 3 {
    CBLootAdd(ids, counts, t"Items.UncommonMaterial1", 2);
    CBLootAdd(ids, counts, t"Items.RareMaterial1", RandRange(2, 4));
    return;
  }
  if tier == 4 {
    CBLootAdd(ids, counts, t"Items.RareMaterial1", RandRange(2, 4));
    CBLootAdd(ids, counts, t"Items.EpicMaterial1", RandRange(1, 3));
    if RandF() < CBConfig.LootLegendaryChanceApex() {
      CBLootAdd(ids, counts, t"Items.LegendaryMaterial1", 1);
    }
    return;
  }
  CBLootAdd(ids, counts, t"Items.EpicMaterial1", RandRange(2, 4));
  if RandF() < CBConfig.LootLegendaryChanceTop() {
    CBLootAdd(ids, counts, t"Items.LegendaryMaterial1", RandRange(1, 3));
  }
}

// The iconics of the list V carries now, each remembered in the save, so one V has had never drops again even once it
// is in the stash, sold or given away. The stash itself can only be read while V's apartment is loaded.
public func CBLootNoteCarriedIconics(sys: ref<CyberbaneSystem>, pool: array<TweakDBID>) -> Void {
  let game = sys.GetGameInstance();
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return;
  }
  let items: array<wref<gameItemData>>;
  ts.GetItemListByTag(player, n"Weapon", items);
  for d in items {
    if IsDefined(d) {
      let rid = ItemID.GetTDBID(d.GetID());
      if ArrayContains(pool, rid) {
        sys.NoteIconicGiven(rid);
      }
    }
  }
}

// One iconic, if the dice say so: one that exists, is an iconic, is not a quest item, and V has never had, from
// Cyberbane or anywhere else V was seen carrying it. TDBID.None otherwise.
public func CBLootIconicRoll(sys: ref<CyberbaneSystem>, chance: Float) -> TweakDBID {
  if !IsDefined(sys) || chance <= 0.0 || RandF() >= chance {
    return TDBID.None();
  }
  let pool = CBLootIconics();
  CBLootNoteCarriedIconics(sys, pool);
  let usable: array<TweakDBID>;
  let i = 0;
  while i < ArraySize(pool) {
    let rec = TweakDBInterface.GetItemRecord(pool[i]);
    if IsDefined(rec) && rec.TagsContains(n"IconicWeapon") && !rec.TagsContains(n"Quest")
       && !sys.IconicGiven(pool[i]) {
      ArrayPush(usable, pool[i]);
    }
    i += 1;
  }
  if ArraySize(usable) == 0 {
    return TDBID.None();
  }
  return usable[RandRange(0, ArraySize(usable))];
}

// Hand it over, a moment after they go down.
public class CBLootDropCallback extends DelayCallback {
  public let entityId: EntityID;
  public let position: Vector4;
  public let tier: Int32;
  public let iconicChance: Float;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    // Waits while the world is unsettled, and while the player is not V: it is V's loot, and it
    // goes in V's pockets, not the VR avatar's or Johnny's (Core/StoryHold.reds).
    if !CBWorldStable(game) || !CBGameHasVHere(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let ds = GameInstance.GetDelaySystem(game);
        if IsDefined(ds) {
          let again = new CBLootDropCallback();
          again.entityId = this.entityId;
          again.position = this.position;
          again.tier = this.tier;
          again.iconicChance = this.iconicChance;
          again.waits = this.waits + (CBWaitCounts(game) ? 1 : 0);
          ds.DelayCallback(again, CBConfig.LootDelaySeconds(), false);
        }
      }
      return;
    }
    let sys = CyberbaneSystem.Get(game);
    let player = GetPlayer(game);
    let ts = GameInstance.GetTransactionSystem(game);
    if !IsDefined(sys) || !IsDefined(player) || !IsDefined(ts) {
      return;
    }
    let ids: array<TweakDBID>;
    let counts: array<Int32>;
    CBLootRoll(this.tier, ids, counts);
    // More for a stronger V: the parts and ammo scale with level, so a late-game fight is still
    // worth winning.
    let scale = CBLootLevelScale(game) * sys.WornPerk().lootMult;
    let k = 0;
    while k < ArraySize(counts) {
      counts[k] = Max(1, RoundF(Cast<Float>(counts[k]) * scale));
      k += 1;
    }
    // Crews carry some cash. Six of them is worth going through.
    if this.tier <= 1 {
      let cash = RoundF(Cast<Float>(RandRange(CBConfig.CrewEddiesMin(), CBConfig.CrewEddiesMax() + 1)) * scale);
      if cash > 0 {
        ArrayPush(ids, t"Items.money");
        ArrayPush(counts, cash);
      }
    }
    let iconic = CBLootIconicRoll(sys, this.iconicChance);
    if TDBID.IsValid(iconic) {
      ArrayPush(ids, iconic);
      ArrayPush(counts, 1);
      sys.NoteIconicGiven(iconic);
      CBLog.Info(n"Loot", s"An iconic dropped: \(TDBID.ToStringDEBUG(iconic)).");
    }
    if ArraySize(ids) == 0 {
      return;
    }
    // The pickup is the one part worth giving up for a loot system that cannot take the game down with it.
    let i = 0;
    let best = 0;
    while i < ArraySize(ids) {
      ts.GiveItem(player, ItemID.FromTDBID(ids[i]), counts[i]);
      let rec = TweakDBInterface.GetItemRecord(ids[i]);
      if IsDefined(rec) && IsDefined(rec.Quality()) {
        best = Max(best, CBCrewTierOf(rec.Quality().Type()));
      }
      i += 1;
    }
    // Something worth having: the game's sting for an epic or legendary find.
    if best >= 4 || TDBID.IsValid(iconic) {
      CBUiSound(game, n"ui_loot_rarity_legendary", n"LootRare", 6.0);
    } else {
      if best == 3 {
        CBUiSound(game, n"ui_loot_rarity_epic", n"LootRare", 6.0);
      }
    }
  }
}

// Called from the death hook for one of ours that V put down.
public func CBScheduleLoot(sys: ref<CyberbaneSystem>, game: GameInstance, puppet: ref<ScriptedPuppet>,
                           tier: Int32, iconicChance: Float) -> Void {
  let rt = CyberbaneRuntime.Get();
  if !IsDefined(puppet) || (IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().lootDrops) {
    return;
  }
  let ds = GameInstance.GetDelaySystem(game);
  if !IsDefined(ds) {
    return;
  }
  let cb = new CBLootDropCallback();
  cb.entityId = puppet.GetEntityID();
  cb.position = puppet.GetWorldPosition();
  cb.tier = tier;
  cb.iconicChance = iconicChance;
  ds.DelayCallback(cb, CBConfig.LootDelaySeconds(), false);
}

// ---- Bounties ------------------------------------------------------------------

// Who pays for this gang's people: the gang most at war with them that V has done the most for,
// or nobody in particular.
func CBBountyPayer(sys: ref<CyberbaneSystem>, game: GameInstance, faction: CName) -> CName {
  let content = CBContent(game);
  let rivals = CBGangRivalsOf(content, faction);
  let score = sys.GetScore();
  let best = n"";
  let bestStanding = -1000.0;
  let i = 0;
  while i < ArraySize(rivals) {
    let id = rivals[i];
    i += 1;
    if CBFactionFieldsSquads(id) && IsDefined(score) {
      let st = score.GetStanding(id);
      if st > bestStanding {
        best = id;
        bestStanding = st;
      }
    }
  }
  // A gang that wants V dead does not pay V for anything.
  if bestStanding < 0.0 {
    return n"";
  }
  return best;
}

// What a payout is for, so its line can be written when it lands (CBPayoutLine): the text cannot wait in a save, the
// facts can.
public func CBPayoutRival() -> Int32 = 0
public func CBPayoutApex() -> Int32 = 1
public func CBPayoutCrew() -> Int32 = 2

// Payouts on their way to V. Nobody pays the second a body drops: word has to reach whoever wanted it done, and they
// have to believe it. (2.7.9) The eddies and the text came the instant the fight ended, which felt like a game paying
// out rather than a city; now both come together a few in-game hours later, and wait in the save until they do.
public class CBPayoutBook extends ScriptableSystem {
  private persistent let m_amount: array<Int32>;
  private persistent let m_victim: array<CName>;   // the gang of whoever V put down
  private persistent let m_kind: array<Int32>;
  private persistent let m_rival: array<Int32>;    // the Rival, for CBPayoutRival
  private persistent let m_due: array<Float>;      // game seconds

  public static func Get(game: GameInstance) -> ref<CBPayoutBook> {
    let container = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(container) ? container.Get(n"CBPayoutBook") as CBPayoutBook : null;
  }

  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.Trim();
  }

  // Parallel arrays from a save that broke off mid-write are cut to the shortest.
  private func Trim() -> Void {
    let n = Min(Min(ArraySize(this.m_amount), ArraySize(this.m_victim)), Min(ArraySize(this.m_kind), Min(ArraySize(this.m_rival), ArraySize(this.m_due))));
    ArrayResize(this.m_amount, n);
    ArrayResize(this.m_victim, n);
    ArrayResize(this.m_kind, n);
    ArrayResize(this.m_rival, n);
    ArrayResize(this.m_due, n);
  }

  public func Add(amount: Int32, victim: CName, kind: Int32, rival: Int32, due: Float) -> Void {
    this.Trim();
    ArrayPush(this.m_amount, amount);
    ArrayPush(this.m_victim, victim);
    ArrayPush(this.m_kind, kind);
    ArrayPush(this.m_rival, rival);
    ArrayPush(this.m_due, due);
  }

  public func Count() -> Int32 { return ArraySize(this.m_due); }

  // The first one due at `now`, -1 for none. One stamped implausibly far ahead (a clock from somewhere else) is due.
  public func FirstDue(now: Float) -> Int32 {
    let pick = -1;
    let i = 0;
    while i < ArraySize(this.m_due) {
      let due = this.m_due[i];
      if (due <= now || due > now + CBConfig.PayoutHoursMax() * 2.0 * CBConfig.SecondsPerHour())
         && (pick < 0 || due < this.m_due[pick]) {
        pick = i;
      }
      i += 1;
    }
    return pick;
  }

  public func Amount(i: Int32) -> Int32 { return this.m_amount[i]; }
  public func Victim(i: Int32) -> CName { return this.m_victim[i]; }
  public func Kind(i: Int32) -> Int32 { return this.m_kind[i]; }
  public func Rival(i: Int32) -> Int32 { return this.m_rival[i]; }

  public func Remove(i: Int32) -> Void {
    if i < 0 || i >= ArraySize(this.m_due) {
      return;
    }
    ArrayErase(this.m_amount, i);
    ArrayErase(this.m_victim, i);
    ArrayErase(this.m_kind, i);
    ArrayErase(this.m_rival, i);
    ArrayErase(this.m_due, i);
  }

  public func Clear() -> Void {
    ArrayClear(this.m_amount);
    ArrayClear(this.m_victim);
    ArrayClear(this.m_kind);
    ArrayClear(this.m_rival);
    ArrayClear(this.m_due);
  }
}

// A bounty earned: on its way, not in V's hand yet.
func CBPayBounty(sys: ref<CyberbaneSystem>, game: GameInstance, victimFaction: CName, baseAmount: Int32, kind: Int32,
                 rivalId: Int32) -> Void {
  let amount = RoundF(Cast<Float>(baseAmount) * sys.WornPerk().bountyMult / 50.0) * 50;
  let book = CBPayoutBook.Get(game);
  if amount <= 0 || !CBBountiesOn() || !IsDefined(book) {
    return;
  }
  let now = CBGameSeconds(game);
  book.Add(amount, victimFaction, kind, rivalId,
           now + RandRangeF(CBConfig.PayoutHoursMin(), CBConfig.PayoutHoursMax()) * CBConfig.SecondsPerHour());
  CBLog.Info(n"Loot", s"Bounty earned: \(amount)eb for \(NameToString(victimFaction)), paid once word gets round.");
}

public func CBBountiesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return !IsDefined(rt) || !rt.HasSettings() || rt.GetSettings().bounties;
}

// What the payout is for, in the words of whoever pays it.
func CBPayoutLine(sys: ref<CyberbaneSystem>, game: GameInstance, kind: Int32, victim: CName, rivalId: Int32) -> String {
  let label = CBFactionLabel(victim);
  if kind == CBPayoutApex() {
    return StrLen(label) > 0 ? CBTf(n"Cyberbane-Loot-YouTookApartTheBestOf", [s"\(label)"]) : CBT(n"Cyberbane-Loot-YouTookApartTheirBest");
  }
  if kind == CBPayoutCrew() {
    return StrLen(label) > 0 ? CBTf(n"Cyberbane-Queue-HeardYouDealtWithThatCrew", [s"\(label)"]) : CBT(n"Cyberbane-Queue-HeardYouDealtWithThatCrew-2");
  }
  let r = sys.FindRivalById(rivalId);
  let content = CBContent(game);
  let name = IsDefined(r) && IsDefined(content) ? CBRivalDisplayName(content, r) : CBT(n"Cyberbane-Loot-ThatOne");
  return CBTf(n"Cyberbane-Loot-HeardYouPutInTheGround", [s"\(name)"]);
}

// One payout whose time has come, a tick: the eddies and the word together, from whoever pays, out of their chest.
// Not in a fight, and never while the world is busy (the tick only runs settled).
public func CBPayoutTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let book = CBPayoutBook.Get(game);
  let player = GetPlayer(game);
  if !IsDefined(sys) || !IsDefined(book) || book.Count() == 0 || !IsDefined(player) || player.IsInCombat() {
    return;
  }
  let now = CBGameSeconds(game);
  if now <= 0.0 {
    return;   // the clock is not up yet
  }
  let i = book.FirstDue(now);
  if i < 0 {
    return;
  }
  let amount = book.Amount(i);
  let victim = book.Victim(i);
  let kind = book.Kind(i);
  let rivalId = book.Rival(i);
  book.Remove(i);
  let ts = GameInstance.GetTransactionSystem(game);
  if !CBBountiesOn() || amount <= 0 || !IsDefined(ts) {
    return;   // Bounties switched off since: nobody pays
  }
  let line = CBPayoutLine(sys, game, kind, victim, rivalId);
  ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  let payer = CBBountyPayer(sys, game, victim);
  CBWarSpend(game, payer, Cast<Float>(amount));   // out of whoever pays (Economy/War.reds)
  if CBToastsOn() {
    if NotEquals(payer, n"") {
      CBPhoneFromAlly(game, payer, CBTf(n"Cyberbane-Loot-EbFromUs", [line, s"\(amount)"]));
    } else {
      CBPhoneFromStreet(game, CBTf(n"Cyberbane-Loot-SomebodyWantedThatDoneEb", [line, s"\(amount)"]));
    }
  }
  CBLog.Info(n"Loot", s"Bounty paid: \(amount)eb for \(NameToString(victim)).");
}

// A Rival is dead by V's hand.
public func CBPayRivalBounty(sys: ref<CyberbaneSystem>, game: GameInstance, r: ref<CBRival>, role: Int32) -> Void {
  if !IsDefined(sys) || !IsDefined(r) {
    return;
  }
  let amount = CBConfig.BountyRivalPerRank() * r.rank;
  if role == CBRoleLeader() {
    amount += CBConfig.BountyLeaderBonus();
  } else {
    if role == CBRoleLieutenant() {
      amount += CBConfig.BountyLeaderBonus() / 2;
    }
  }
  CBPayBounty(sys, game, r.faction, amount, CBPayoutRival(), r.id);
}

// The last of an apex squad is down.
public func CBPayApexBounty(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) {
    return;
  }
  let faction = sys.TakeApexBounty();
  if Equals(faction, n"") {
    return;
  }
  let scale = 0.6 + 0.4 * CBMenaceScale(sys);
  let amount = RoundF(Cast<Float>(CBConfig.BountyApexSquad()) * scale / 50.0) * 50;
  CBPayBounty(sys, game, faction, amount, CBPayoutApex(), 0);
}

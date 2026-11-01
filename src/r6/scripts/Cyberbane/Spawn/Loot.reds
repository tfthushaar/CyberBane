// Cyberbane - What they leave behind (spec §9.12)
//
// "Hard to kill mobs that eat ammo like no tomorrow, with little reward for actually defeating
// them." The reward was reputation and a counter in the Hub. Beating somebody the city sent after
// you should be worth something you can hold.
//
// Everyone Cyberbane sends who goes down by V's hand drops a loot bag on their body, scaled to who
// they were:
//   - crew and escorts: sometimes ammo and a few common parts;
//   - Rivals: better parts the higher they ranked, more for a leader;
//   - apex squad members: rare and epic parts, a chance of legendary ones, and a small chance of
//     an iconic weapon.
// Putting down a Rival, or wiping out an apex squad, also pays a bounty in eddies, from one of
// the gangs at war with theirs (Model/GangRivalries.reds), who text V to say so.
//
// Iconic weapons are only ever ones a player could come across exploring the city. Anything the
// game tags as a quest item is refused at runtime, and the list itself (CBLootIconics) leaves out
// weapons that come from missions, gigs, story beats and companions, so nothing is spoiled and
// nobody's personal weapon turns up on a ganger. Each iconic drops at most once per session.
//
// Every item is checked against TweakDB before it is used, so an id that does not exist on
// somebody's patch is skipped rather than handed to the inventory system.
//
// The bag goes on the body: the items are given to the corpse and dropped from it the way vendors
// drop what you buy (vendor.script, SpawnItemDropOfManyItems). If the corpse is gone by then, they
// go to V directly. Scheduled a moment after death, never from inside the death handler.

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

// One iconic, if the dice say so: one that exists, is an iconic, is not a quest item, and has not
// already dropped this session. TDBID.None() otherwise.
public func CBLootIconicRoll(sys: ref<CyberbaneSystem>, chance: Float) -> TweakDBID {
  if !IsDefined(sys) || chance <= 0.0 || RandF() >= chance {
    return TDBID.None();
  }
  let pool = CBLootIconics();
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

// Drop it on the body, a moment after they go down.
public class CBLootDropCallback extends DelayCallback {
  public let entityId: EntityID;
  public let position: Vector4;
  public let tier: Int32;
  public let iconicChance: Float;
  public let waits: Int32;

  public func Call() -> Void {
    let game = GetGameInstance();
    if !CBWorldStable(game) {
      if this.waits < CBConfig.CallbackStableWaits() {
        let ds = GameInstance.GetDelaySystem(game);
        if IsDefined(ds) {
          let again = new CBLootDropCallback();
          again.entityId = this.entityId;
          again.position = this.position;
          again.tier = this.tier;
          again.iconicChance = this.iconicChance;
          again.waits = this.waits + 1;
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
    // The body if it is still there, V otherwise.
    let holder = GameInstance.FindEntityByID(game, this.entityId) as GameObject;
    let lm = GameInstance.GetLootManager(game);
    let receiver: ref<GameObject> = player;
    if IsDefined(holder) {
      receiver = holder;
    }
    let instructions: array<DropInstruction>;
    let i = 0;
    while i < ArraySize(ids) {
      let item = ItemID.FromTDBID(ids[i]);
      ts.GiveItem(receiver, item, counts[i]);
      ArrayPush(instructions, DropInstruction.Create(item, counts[i]));
      i += 1;
    }
    if IsDefined(holder) && IsDefined(lm) {
      lm.SpawnItemDropOfManyItems(holder, instructions, lm.GetDefaultDropItemName(), this.position);
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

func CBPayBounty(sys: ref<CyberbaneSystem>, game: GameInstance, victimFaction: CName, amount: Int32,
                 line: String) -> Void {
  let rt = CyberbaneRuntime.Get();
  if amount <= 0 || (IsDefined(rt) && rt.HasSettings() && !rt.GetSettings().bounties) {
    return;
  }
  let player = GetPlayer(game);
  let ts = GameInstance.GetTransactionSystem(game);
  if !IsDefined(player) || !IsDefined(ts) {
    return;
  }
  ts.GiveItem(player, ItemID.FromTDBID(t"Items.money"), amount);
  let payer = CBBountyPayer(sys, game, victimFaction);
  if CBToastsOn() {
    if NotEquals(payer, n"") {
      CBPhoneFromAlly(game, payer, line + s" \(amount)eb, from us.");
    } else {
      CBPhoneFromStreet(game, line + s" Somebody wanted that done. \(amount)eb.");
    }
  }
  CBLog.Info(n"Loot", s"Bounty paid: \(amount)eb for \(NameToString(victimFaction)).");
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
  let content = CBContent(game);
  let name = IsDefined(content) ? CBRivalDisplayName(content, r) : "That one";
  CBPayBounty(sys, game, r.faction, amount, s"Heard you put \(name) in the ground.");
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
  let label = CBFactionLabel(faction);
  CBPayBounty(sys, game, faction, amount,
              StrLen(label) > 0 ? s"You took apart \(label)'s best." : "You took apart their best.");
}

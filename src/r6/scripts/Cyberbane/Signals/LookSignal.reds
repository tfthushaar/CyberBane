// Cyberbane - Look & disguise signal (spec §7.4, §9.3; spike S-10)
//
// Reads V's equipped clothing and turns it into two things: a Look score (how much your
// outfit adds to the impression you make) and a Disguise value (how much it stops people
// placing you). Masks and hoods make you harder to recognize; dressing in a gang's colours
// makes that gang slower to clock you. Both feed the existing recognition and dread maths.
//
// The reader is complete; its visible effect depends on the look registry's data (visual
// tag names and gang-clothing records), which is populated and tuned in-game (S-10). Add
// entries with CyberbaneAPI.RegisterLookTag / RegisterLookItem. Fully reversible.

public func CBUpdateLook(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  // Same wait as the chrome reading (1.9.5).
  if !IsDefined(sys) || !sys.WornReady() {
    return;
  }
  let score = sys.GetScore();
  let content = CBContent(game);
  let player = GetPlayer(game);
  if !IsDefined(score) || !IsDefined(content) || !IsDefined(player) {
    return;
  }
  let es = CBGetSystem(game, n"EquipmentSystem") as EquipmentSystem;
  if !IsDefined(es) {
    return;
  }
  let data = es.GetPlayerData(player);
  if !IsDefined(data) {
    return;
  }


  let lookSum = 0.0;
  let disguiseSum = 0.0;
  let bestFaction = n"";
  let bestFactionDisguise = 0.0;
  let gangsWorn: array<CName>;

  // What a stranger sees V wearing, the reading the chrome sample has just made (Signals/Concealment.reds):
  // the game's clothing areas as drawn, outfit presets and hidden slots included, and anything else on
  // V's body, such as an outfit mod's own slots. Read here only when nothing has read it yet.
  let worn = sys.GetWorn();
  if !IsDefined(worn) {
    worn = CBReadWorn(game, data);
    sys.SetWorn(worn);
  }
  for item in worn.garments {
    if ItemID.IsValid(item) {
      let tdbid = ItemID.GetTDBID(item);

      // Exact-record match takes priority (spec: gang-specific clothing).
      let li = content.GetLookItem(tdbid);
      if IsDefined(li) {
        lookSum += li.score;
        if Equals(li.factionTag, n"") {
          disguiseSum += li.disguise;
        }
      }

      // What the garment itself says (1.9.3). This read the item's visual tags against a list of
      // nine names, and not one of them exists in the game's data, so no outfit ever counted for
      // anything: Look was always zero, and with it a sixth of Dread. Clothing does carry tags the
      // game uses, a style or two and often a gang, and those are read instead.
      let rec = TweakDBInterface.GetItemRecord(tdbid);
      if IsDefined(rec) {
        lookSum += CBGarmentLookScore(rec);
        // Tags another mod has registered (CyberbaneAPI.RegisterLookTag), on either list.
        let extra = content.GetLookTags();
        if ArraySize(extra) > 0 {
          let shown = rec.VisualTags();
          for lt in extra {
            if IsDefined(lt) && (rec.TagsContains(lt.tag) || ArrayContains(shown, lt.tag)) {
              lookSum += lt.score;
              disguiseSum += lt.disguise;
              if NotEquals(lt.factionTag, n"") {
                ArrayPush(gangsWorn, lt.factionTag);
              }
            }
          }
        }
        if !IsDefined(li) || Equals(li.factionTag, n"") {
          let gang = CBGarmentGang(rec);
          if NotEquals(gang, n"") {
            ArrayPush(gangsWorn, gang);
          }
        }
      }
      if IsDefined(li) && NotEquals(li.factionTag, n"") {
        ArrayPush(gangsWorn, li.factionTag);
      }
    }
  }
  // Whose colours V is mostly in. One piece is a start; four or more is head to toe.
  let g = 0;
  while g < ArraySize(gangsWorn) {
    let pieces = 0;
    for other in gangsWorn {
      if Equals(other, gangsWorn[g]) {
        pieces += 1;
      }
    }
    let strength = MinF(0.8, 0.2 + 0.15 * Cast<Float>(pieces));
    if strength > bestFactionDisguise {
      bestFaction = gangsWorn[g];
      bestFactionDisguise = strength;
    }
    g += 1;
  }
  if worn.masked {
    lookSum += 12.0;   // a covered face reads as trouble before anything else does
  }

  // A mask is a disguise whether or not the look tables happen to list that particular one.
  // Those tables are hand-written and will never cover every face item in the game, and a
  // player who covers their face and sees nothing change reasonably concludes the system does
  // not work.
  if worn.masked {
    disguiseSum += CBConfig.MaskDisguise();
  }
  score.SetLook(MaxF(lookSum, 0.0), ClampF(disguiseSum, 0.0, 0.85));

  // Faction-colour disguise is off under the kill switch, when disabled, or in TWR compat.
  let rt = CyberbaneRuntime.Get();
  let allow = !CBTwrActive();
  if IsDefined(rt) {
    if !rt.IsEnabled() {
      allow = false;
    }
    if rt.HasSettings() && !rt.GetSettings().factionDisguises {
      allow = false;
    }
  }
  if allow {
    sys.SetDisguise(bestFaction, ClampF(bestFactionDisguise, 0.0, 0.8));
  } else {
    sys.SetDisguise(n"", 0.0);
  }
}

// How dangerous one garment makes V look, from the style tags the game files its clothing under
// (1.9.3). Fatigues, leathers and gang gear read as trouble; a suit reads as money.
func CBGarmentLookScore(rec: ref<Item_Record>) -> Float {
  let s = 0.0;
  if rec.TagsContains(n"Military") { s += 7.0; }
  if rec.TagsContains(n"Punk") { s += 5.0; }
  if rec.TagsContains(n"Biker") { s += 5.0; }
  if rec.TagsContains(n"Samurai") { s += 5.0; }
  if rec.TagsContains(n"Industrial") { s += 4.0; }
  if rec.TagsContains(n"Rocker") { s += 3.0; }
  if rec.TagsContains(n"Streetwear") { s += 1.0; }
  if rec.TagsContains(n"Formal") { s -= 4.0; }
  if rec.TagsContains(n"Corpo") { s -= 4.0; }
  if rec.TagsContains(n"Rich") { s -= 2.0; }
  if NotEquals(CBGarmentGang(rec), n"") { s += 3.0; }
  return s;
}

// Whose gear this is, if the game files it under a gang or a corporation (1.9.3). Fifteen factions
// have clothing of their own in the game's data; only nomad gear and one Wraiths vest used to count.
func CBGarmentGang(rec: ref<Item_Record>) -> CName {
  if rec.TagsContains(n"TygerClaws") { return n"TygerClaws"; }
  if rec.TagsContains(n"Moxies") { return n"Mox"; }
  if rec.TagsContains(n"Valentinos") { return n"Valentinos"; }
  if rec.TagsContains(n"Animals") { return n"Animals"; }
  if rec.TagsContains(n"VoodooBoys") { return n"VoodooBoys"; }
  if rec.TagsContains(n"SixthStreet") { return n"SixthStreet"; }
  if rec.TagsContains(n"Aldecaldos") { return n"Aldecaldos"; }
  if rec.TagsContains(n"Maelstrom") { return n"Maelstrom"; }
  if rec.TagsContains(n"Wraiths") { return n"Wraiths"; }
  if rec.TagsContains(n"Scavengers") { return n"Scavengers"; }
  if rec.TagsContains(n"Barghest") { return n"Barghest"; }
  if rec.TagsContains(n"Arasaka") { return n"Arasaka"; }
  if rec.TagsContains(n"Militech") { return n"Militech"; }
  if rec.TagsContains(n"KangTao") { return n"KangTao"; }
  if rec.TagsContains(n"NCPD") { return n"NCPD"; }
  return n"";
}

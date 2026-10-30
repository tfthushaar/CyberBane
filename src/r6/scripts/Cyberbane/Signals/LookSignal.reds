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
  if !IsDefined(sys) {
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

  let areas = [
    gamedataEquipmentArea.Head, gamedataEquipmentArea.Face, gamedataEquipmentArea.OuterChest,
    gamedataEquipmentArea.InnerChest, gamedataEquipmentArea.Legs, gamedataEquipmentArea.Feet,
    gamedataEquipmentArea.Outfit
  ];

  let lookSum = 0.0;
  let disguiseSum = 0.0;
  let bestFaction = n"";
  let bestFactionDisguise = 0.0;

  for area in areas {
    let item = data.GetActiveItem(area);
    if ItemID.IsValid(item) {
      let tdbid = ItemID.GetTDBID(item);

      // Exact-record match takes priority (spec: gang-specific clothing).
      let li = content.GetLookItem(tdbid);
      if IsDefined(li) {
        lookSum += li.score;
        disguiseSum += li.disguise;
        if NotEquals(li.factionTag, n"") && li.disguise > bestFactionDisguise {
          bestFaction = li.factionTag;
          bestFactionDisguise = li.disguise;
        }
      }

      // Visual-tag matches (masks, hoods, gang styles, etc.).
      let rec = TweakDBInterface.GetItemRecord(tdbid);
      if IsDefined(rec) {
        let tags = rec.VisualTags();
        for t in tags {
          let lt = content.GetLookTag(t);
          if IsDefined(lt) {
            lookSum += lt.score;
            disguiseSum += lt.disguise;
            if NotEquals(lt.factionTag, n"") && lt.disguise > bestFactionDisguise {
              bestFaction = lt.factionTag;
              bestFactionDisguise = lt.disguise;
            }
          }
        }
      }
    }
  }

  // A mask is a disguise whether or not the look tables happen to list that particular one.
  // Those tables are hand-written and will never cover every face item in the game, and a
  // player who covers their face and sees nothing change reasonably concludes the system does
  // not work.
  if CBFaceCovered(data) && CBPlayerMasked(game) {
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

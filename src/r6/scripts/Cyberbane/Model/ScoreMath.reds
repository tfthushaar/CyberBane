// Cyberbane — Scoring math (spec §8)
//
// Pure, stateless functions. Every input is a primitive and every output is
// derived with no game calls, so this layer is deterministic and fully testable
// on its own. The stateful ScoreEngine feeds live values (chrome, look, heat,
// street cred, faction/district state) into these functions.
//
// All constants come from CBConfig so balance passes touch one file.

// ---- Renown (spec §8.1) --------------------------------------------------

// R_raw = 1000 * (1 - e^(-points / scale)); floored by street cred when enabled.
public func CBComputeRenown(renownPoints: Float, streetCred: Float, useFloor: Bool) -> Float {
  let raw = CBConfig.RenownMax() * (1.0 - ExpF(-renownPoints / CBConfig.RenownCurveScale()));
  if useFloor {
    raw = MaxF(raw, CBConfig.StreetCredFloorFactor() * streetCred);
  }
  return ClampF(raw, 0.0, CBConfig.RenownMax());
}

public func CBRenownTier(renown: Float) -> ECBRenownTier {
  if renown >= CBConfig.TierLegend() { return ECBRenownTier.Legend; }
  if renown >= CBConfig.TierInfamous() { return ECBRenownTier.Infamous; }
  if renown >= CBConfig.TierNotorious() { return ECBRenownTier.Notorious; }
  if renown >= CBConfig.TierKnownMerc() { return ECBRenownTier.KnownMerc; }
  if renown >= CBConfig.TierLocalName() { return ECBRenownTier.LocalName; }
  return ECBRenownTier.Nobody;
}

// ---- Dread (spec §8.2) ---------------------------------------------------

// Individual exponential components, each saturating to 100.
public func CBKillDreadComponent(killDreadPoints: Float) -> Float {
  return 100.0 * (1.0 - ExpF(-killDreadPoints / CBConfig.KillDreadCurveScale()));
}

public func CBDeedDreadComponent(deedDreadPoints: Float) -> Float {
  return 100.0 * (1.0 - ExpF(-deedDreadPoints / CBConfig.DeedDreadCurveScale()));
}

public func CBHeatDreadComponent(heatPoints: Float) -> Float {
  return 100.0 * (1.0 - ExpF(-heatPoints / CBConfig.HeatCurveScale()));
}

// D = clamp(0.35K + 0.20C + 0.15L + 0.20X + 0.10H, 0, 100)
public func CBComputeDread(k: Float, c: Float, l: Float, x: Float, h: Float) -> Float {
  let d = CBConfig.DreadWeightK() * k
        + CBConfig.DreadWeightC() * c
        + CBConfig.DreadWeightL() * l
        + CBConfig.DreadWeightX() * x
        + CBConfig.DreadWeightH() * h;
  return ClampF(d, 0.0, 100.0);
}

// Civilian-perceived dread (spec §8.2). mercyRatio = nonLethal / (nonLethal+lethal).
public func CBComputeDreadCiv(dread: Float, primaryArchetype: Int32, mercyRatio: Float) -> Float {
  let civ = dread * CBCivMult(primaryArchetype) * (1.0 - 0.3 * mercyRatio);
  return ClampF(civ, 0.0, 100.0);
}

public func CBMercyRatio(nonLethal: Int32, lethalKills: Int32) -> Float {
  let denom = Max(1, nonLethal + lethalKills);
  return Cast<Float>(nonLethal) / Cast<Float>(denom);
}

// civMult by primary archetype (-1 = Unknown).
public func CBCivMult(primaryArchetype: Int32) -> Float {
  if primaryArchetype == EnumInt(ECBArchetype.Butcher) { return 1.20; }
  if primaryArchetype == EnumInt(ECBArchetype.Chromed) { return 1.15; }
  if primaryArchetype == EnumInt(ECBArchetype.Brawler) { return 1.00; }
  if primaryArchetype == EnumInt(ECBArchetype.Netrunner) { return 0.95; }
  if primaryArchetype == EnumInt(ECBArchetype.Professional) { return 0.85; }
  if primaryArchetype == EnumInt(ECBArchetype.Ghost) { return 0.75; }
  return 1.00;   // Unknown
}

// ---- Aura (spec §8.6) ----------------------------------------------------
// Momentary threat. Caller passes the current conditions; result is clamped to 40.
// In Low Profile the caller passes everything false, yielding 0.
public func CBComputeAura(
    weaponDrawn: Bool,
    heavyOrBladeOrArmCW: Bool,
    combatCyberwareActive: Bool,
    inCombat: Bool,
    recentNearbyKills: Int32,
    heatStageAtLeast3: Bool) -> Float {
  let a = 0.0;
  if weaponDrawn {
    a += heavyOrBladeOrArmCW ? 12.0 : 8.0;
  }
  if combatCyberwareActive { a += 15.0; }
  if inCombat { a += 8.0; }
  // +4 per kill within 40 m in the last 60 s, capped at +16.
  a += MinF(Cast<Float>(recentNearbyKills) * 4.0, 16.0);
  if heatStageAtLeast3 { a += 6.0; }
  return ClampF(a, 0.0, CBConfig.AuraCap());
}

// ---- Recognition (spec §8.7) ---------------------------------------------
// distinct = max(C_visible, L)/100. Rivals always recognise V (caller forces p=1).
public func CBRecognitionChance(
    renown: Float,
    districtRenown: Float,
    cVisible: Float,
    look: Float,
    disguise: Float,
    npcFactionRenown: Float,   // RF_f of the NPC's faction, or 0 if none
    npcIsNcpdHighHeat: Bool,
    lowProfile: Bool) -> Float {
  let distinct = MaxF(cVisible, look) / 100.0;
  let p = 0.05
        + 0.55 * districtRenown / 100.0
        + 0.25 * renown / 1000.0
        + 0.15 * distinct
        - disguise;
  p += 0.20 * npcFactionRenown / 100.0;
  if npcIsNcpdHighHeat { p += 0.10; }
  if lowProfile { p *= 0.5; }
  return ClampF(p, 0.0, CBConfig.RecognitionCap());
}

// ---- Perceived threat & effective fear (spec §8.8) -----------------------
public func CBAppearanceThreat(look: Float, cVisible: Float) -> Float {
  return 0.5 * look + 0.3 * cVisible;
}

// base = recognised ? (factionMember ? F_f : D_civ) : 0
public func CBPerceivedThreat(
    recognised: Bool,
    isFactionMember: Bool,
    factionFear: Float,
    dreadCiv: Float,
    look: Float,
    cVisible: Float,
    aura: Float) -> Float {
  let base = 0.0;
  if recognised {
    base = isFactionMember ? factionFear : dreadCiv;
  }
  let t = MaxF(base, CBAppearanceThreat(look, cVisible)) + aura;
  return ClampF(t, 0.0, 100.0);
}

// E = T/100 - courage
public func CBEffectiveFear(perceivedThreat: Float, courage: Float) -> Float {
  return perceivedThreat / 100.0 - courage;
}

// ---- Factions (spec §8.4) ------------------------------------------------
// F_f = clamp(D*dreadSens*(0.35 + 0.65*RF/100) + (C-50)*chromeAttitude*0.3, 0, 100)
public func CBFactionFear(dread: Float, chrome: Float, factionRenown: Float, dreadSens: Float, chromeAttitude: Float) -> Float {
  let f = dread * dreadSens * (0.35 + 0.65 * factionRenown / 100.0)
        + (chrome - 50.0) * chromeAttitude * 0.3;
  return ClampF(f, 0.0, 100.0);
}

// P_f = clamp((R/10)*(0.4 + 0.6*RF/100)*(1 + Σ respect[a]*share_a)
//             + max(0,-chromeAttitude)*max(0,C-50)*0.4, 0, 100)
// respectBlend is the precomputed Σ respect[a]*share_a term.
public func CBFactionRespect(renown: Float, chrome: Float, factionRenown: Float, chromeAttitude: Float, respectBlend: Float) -> Float {
  let p = (renown / 10.0) * (0.4 + 0.6 * factionRenown / 100.0) * (1.0 + respectBlend)
        + MaxF(0.0, -chromeAttitude) * MaxF(0.0, chrome - 50.0) * 0.4;
  return ClampF(p, 0.0, 100.0);
}

// ---- Chrome (spec §7.3) & Look (spec §7.4) -------------------------------
// Tier multiplier for an implant (Tier 1..5+). Iconic adds +0.10 at the call site.
public func CBTierMult(tier: Int32) -> Float {
  if tier <= 1 { return 0.60; }
  if tier == 2 { return 0.75; }
  if tier == 3 { return 0.90; }
  if tier == 4 { return 1.00; }
  if tier == 5 { return 1.10; }
  return 1.20;   // 5+ / 5++
}

// C = clamp(55*min(usage,1) + implantSum(cap 35) + (overallocated ? 10 : 0), 0, 100).
public func CBComputeChrome(usage: Float, implantSum: Float, overallocated: Bool) -> Float {
  let c = 55.0 * MinF(usage, 1.0) + ClampF(implantSum, 0.0, 35.0) + (overallocated ? 10.0 : 0.0);
  return ClampF(c, 0.0, 100.0);
}

// C_visible = clamp(visibleImplantScore*2.5 + faceChromeScore, 0, 100). The caller
// passes Σ(visibleScore × tierMult) as visibleImplantScore.
public func CBComputeChromeVisible(visibleImplantScore: Float, faceChromeScore: Float) -> Float {
  return ClampF(visibleImplantScore * 2.5 + faceChromeScore, 0.0, 100.0);
}

// L = clamp(min(Σ clothingScore, 60) + min(Σ customizationScore, 40), 0, 100).
public func CBComputeLook(clothingSum: Float, customizationSum: Float) -> Float {
  return ClampF(MinF(clothingSum, 60.0) + MinF(customizationSum, 40.0), 0.0, 100.0);
}

// Dg = clamp(Σ disguise(item), 0, 0.6).
public func CBComputeDisguise(disguiseSum: Float) -> Float {
  return ClampF(disguiseSum, 0.0, 0.6);
}

public func CBPostureFromStanding(standing: Float) -> ECBPosture {
  if standing >= CBConfig.PostureAllied() { return ECBPosture.Allied; }
  if standing >= CBConfig.PostureFriendly() { return ECBPosture.Friendly; }
  if standing <= CBConfig.PostureVendetta() { return ECBPosture.Vendetta; }
  if standing <= CBConfig.PostureHostile() { return ECBPosture.Hostile; }
  return ECBPosture.Neutral;
}

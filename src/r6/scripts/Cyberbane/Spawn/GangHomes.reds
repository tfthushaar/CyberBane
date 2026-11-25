// Cyberbane - Gang homes
//
// Each gang has a home at one of the game's named places (the Mox at Lizzie's Bar, Maelstrom at Totentanz and so on),
// where V can find their people.

public func CBMemGangHome() -> Int32 = 4

public func CBTalkActAskHome() -> Int32 = 61

public func CBGangHomesOn() -> Bool {
  let rt = CyberbaneRuntime.Get();
  return IsDefined(rt) && rt.IsEnabled() && (!rt.HasSettings() || rt.GetSettings().gangHomes);
}

// ---- The table ---------------------------------------------------------------------------------------

public func CBGangHomeCount() -> Int32 = 6

public func CBGangHomeGang(i: Int32) -> CName {
  switch i {
    case 0: return n"Mox";
    case 1: return n"Maelstrom";
    case 2: return n"Valentinos";
    case 3: return n"TygerClaws";
    case 4: return n"VoodooBoys";
    case 5: return n"Animals";
    default: return n"";
  }
}

// The game's sub-district at the place, by the enum name the game reports while V is in it (CBSubDistrictName).
public func CBGangHomeSub(i: Int32) -> String {
  switch i {
    case 0: return "Kabuki_LizziesBar";
    case 1: return "Northside_Totentaz";
    case 2: return "Vista_del_rey_ElCoyoteCojo";
    case 3: return "JapanTown_Wakakos_Pachinko_Parlor";
    case 4: return "Coastview_VDBChapel";
    case 5: return "Coastview_GrandImperialMall";
    default: return "";
  }
}

public func CBGangHomeRecord(i: Int32) -> TweakDBID {
  switch i {
    case 0: return t"Districts.LizziesBar";
    case 1: return t"Districts.Totentaz";
    case 2: return t"Districts.ElCoyoteCojo";
    case 3: return t"Districts.WakakosPachinkoParlor";
    case 4: return t"Districts.VDBChapel";
    case 5: return t"Districts.GrandImperialMall";
    default: return TDBID.None();
  }
}

public func CBGangHomeOf(gang: CName) -> Int32 {
  let i = 0;
  while i < CBGangHomeCount() {
    if Equals(CBGangHomeGang(i), gang) {
      return i;
    }
    i += 1;
  }
  return -1;
}

public func CBGangHomeBySub(sub: String) -> Int32 {
  if StrLen(sub) == 0 {
    return -1;
  }
  let low = StrLower(sub);
  let i = 0;
  while i < CBGangHomeCount() {
    if Equals(StrLower(CBGangHomeSub(i)), low) {
      return i;
    }
    i += 1;
  }
  return -1;
}

// The place's name, in the game's words and language.
public func CBGangHomePlace(i: Int32) -> String {
  let rec = TweakDBInterface.GetDistrictRecord(CBGangHomeRecord(i));
  return IsDefined(rec) ? GetLocalizedText(rec.LocalizedName()) : "";
}

// The district the place is in, by the game's name for it.
public func CBGangHomeArea(i: Int32) -> String {
  let rec = TweakDBInterface.GetDistrictRecord(CBGangHomeRecord(i));
  let parent = IsDefined(rec) ? rec.ParentDistrict() : null;
  return IsDefined(parent) ? GetLocalizedText(parent.LocalizedName()) : "";
}

// The map book's memory of a learned home, or null.
public func CBGangHomeMemory(book: ref<CBMapBook>, i: Int32) -> ref<CBMapMemory> {
  if !IsDefined(book) {
    return null;
  }
  let k = 0;
  while k < book.Count() {
    let m = book.At(k);
    if IsDefined(m) && m.kind == CBMemGangHome() && m.subject == i {
      return m;
    }
    k += 1;
  }
  return null;
}

// Whether a gang's home is shown: they are not Hostile or at Vendetta with V, by Cyberbane or by They Will Remember.
public func CBGangHomeShown(sys: ref<CyberbaneSystem>, game: GameInstance, gang: CName) -> Bool {
  if !CBGangHomesOn() || !CBMapMarkersOn() || !CBFactionOn(gang) {
    return false;
  }
  let score = IsDefined(sys) ? sys.GetScore() : null;
  let posture = IsDefined(score) ? score.GetPosture(gang) : ECBPosture.Neutral;
  if Equals(posture, ECBPosture.Hostile) || Equals(posture, ECBPosture.Vendetta) {
    return false;
  }
  return CBTwrGangHostile(game, gang) != 1;
}

// ---- Learning one --------------------------------------------------------------------------------------

// On the street tick: V standing in a home's sub-district, outside the bar or the church itself and nowhere a story is
// being told, is where that home is from now on.
public func CBGangHomeTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  let st = CBHangoutState.Get(game);
  if !IsDefined(sys) || !IsDefined(st) || !CBGangHomesOn() || !CBWorldStable(game) {
    return;
  }
  let player = GetPlayer(game);
  if !IsDefined(player) || IsDefined(player.GetMountedVehicle()) || sys.IsInQuestArea()
     || sys.GetStoryHold() != CBStoryNone() || CBPlayerInScene(game) {
    return;
  }
  let at = player.GetWorldPosition();
  let now = CBGameSeconds(game);
  let i = CBGangHomeBySub(CBSubDistrictName(game));
  if i >= 0 {
    st.homeInside = i + 1;
    st.homeInsideAt = at;
    st.homeInsideWhen = now;
  } else {
    if st.homeInside > 0 && now - st.homeInsideWhen <= 60.0
       && Vector4.Distance(at, st.homeInsideAt) <= CBConfig.GangHomeStepOut() {
      i = st.homeInside - 1;
    }
  }
  if i < 0 || sys.IsInSafeZone() {
    return;
  }
  let book = CBMapBook.Get(game);
  if !IsDefined(book) || IsDefined(CBGangHomeMemory(book, i)) {
    return;
  }
  if !CBLairPointUsable(sys, game, at) {
    return;
  }
  st.homeInside = 0;
  let gang = CBGangHomeGang(i);
  book.Add(CBMemGangHome(), at, CBGameSeconds(game), i, gang, n"", StringToName(CBGangHomeSub(i)), sys.GetCurrentDistrict(), false);
  if CBGangHomeShown(sys, game, gang) {
    CBSystemNote(game, CBTf(n"Cyberbane-GangHomes-Learned", [CBGangHomePlace(i), CBFactionLabel(gang)]), 6.0);
  }
  CBLog.Info(n"Street", s"Learned a gang's home: \(NameToString(gang)) at \(CBGangHomeSub(i)).");
}

// The nearest learned home within `reach` of a point, and where it is; -1 for none.
public func CBGangHomeNear(game: GameInstance, from: Vector4, reach: Float, out at: Vector4) -> Int32 {
  let book = CBMapBook.Get(game);
  if !IsDefined(book) {
    return -1;
  }
  let best = -1;
  let bestDist = reach;
  let k = 0;
  while k < book.Count() {
    let m = book.At(k);
    k += 1;
    if IsDefined(m) && m.kind == CBMemGangHome() {
      let spot = new Vector4(m.x, m.y, m.z, 1.0);
      let d = Vector4.Distance(from, spot);
      if d <= bestDist {
        bestDist = d;
        best = m.subject;
        at = spot;
      }
    }
  }
  return best;
}

// ---- Somebody there ------------------------------------------------------------------------------------

// A few of a gang's people around a spot, out of V's sight, the way a gathering is placed (Spawn/StreetEvents.reds).
public func CBPlaceAround(sys: ref<CyberbaneSystem>, game: GameInstance, record: TweakDBID, at: Vector4, wanted: Int32,
                          tag: CName) -> Int32 {
  let des = GameInstance.GetDynamicEntitySystem();
  let player = GetPlayer(game);
  if !IsDefined(des) || !IsDefined(player) || !CBWorldStable(game) || !TDBID.IsValid(record) || !CBRecordIsPerson(record) {
    return 0;
  }
  let want = Min(wanted, CBSpawnRoom(game) - CBCrewRoomKept(game));
  let ppos = player.GetWorldPosition();
  let fwd = player.GetWorldForward();
  let placed = 0;
  let ring = 0;
  while ring < 3 && placed < want {
    let radius = 2.0 + Cast<Float>(ring) * 2.0;
    let slots = 8 + ring * 4;
    let k = 0;
    while k < slots && placed < want {
      let ang = Cast<Float>(k) * 6.28318 / Cast<Float>(slots);
      k += 1;
      let snapped: Vector4;
      let spot: Vector4;
      if CBNavSnap(game, at.X + CosF(ang) * radius, at.Y + SinF(ang) * radius, at.Z, snapped)
         && CBSettleOnGround(game, snapped, spot) && CBPointHiddenFrom(game, ppos, fwd, spot)
         && CBStandsWith(game, spot, at, CBConfig.GroundMaxDrop()) && CBLairPointUsable(sys, game, spot) {
        let facing = Quaternion.BuildFromDirectionVector(new Vector4(-CosF(ang), -SinF(ang), 0.0, 0.0));
        let id: EntityID;
        if CBCreateSpawn(des, record, n"", spot, facing, tag, id) {
          placed += 1;
        }
      }
    }
    ring += 1;
  }
  // Too few hidden round the place: the navmesh's own hidden points near it, one query (Spawn/Spawner.reds).
  if placed < want {
    let pts: array<Vector4>;
    if CBPursuitPointsAround(game, ppos, at, want - placed, 3.0, CBConfig.PlaceAroundPursuitMax(), pts) {
      for p in pts {
        if placed < want && CBPointHiddenFrom(game, ppos, fwd, p) && CBStandsWith(game, p, at, CBConfig.GroundMaxDrop())
           && CBLairPointUsable(sys, game, p) {
          let toward = new Vector4(at.X - p.X, at.Y - p.Y, 0.0, 0.0);
          let face = Quaternion.BuildFromDirectionVector(Vector4.Length(toward) > 0.1 ? Vector4.Normalize(toward) : fwd);
          let pid: EntityID;
          if CBCreateSpawn(des, record, n"", p, face, tag, pid) {
            placed += 1;
          }
        }
      }
    }
  }
  return placed;
}

// ---- Asked on the street --------------------------------------------------------------------------------

public func CBGangHomeTalkLine(t: ref<CBTalkTarget>) -> ref<CBTalkLine> {
  if !CBGangHomesOn() || t.cop || CBGangHomeOf(t.faction) < 0 {
    return null;
  }
  let line = CBTalkMakeLine(CBT(n"Cyberbane-GangHomes-AskWhereDoYourPeople"), CBTalkActAskHome(), t"ChoiceCaptionParts.GangWatchIcon");
  line.said = CBTalkDid(t.npc, CBTalkActAskHome());
  return line;
}

public func CBTalkAnswerHome(sys: ref<CyberbaneSystem>, game: GameInstance, t: ref<CBTalkTarget>, again: Bool) -> ref<CBTalkAnswer> {
  let i = CBGangHomeOf(t.faction);
  if i < 0 {
    return CBTalkSay(CBT(n"Cyberbane-GangHomes-NowhereYouDBeWelcome"), n"");
  }
  if again {
    return CBTalkSay(CBT(n"Cyberbane-TalkTopics-SameAsFiveMinutesAgo"), n"");
  }
  if t.mood == CBTalkHostile() {
    return CBTalkSay(CBT(n"Cyberbane-GangHomes-NotTellingYou"), n"");
  }
  let place = CBGangHomePlace(i);
  let area = CBGangHomeArea(i);
  let known = IsDefined(CBGangHomeMemory(CBMapBook.Get(game), i));
  let line = t.mood == CBTalkFriendly()
             ? CBTf(n"Cyberbane-GangHomes-FriendlyAnswer", [place, area])
             : CBTf(n"Cyberbane-GangHomes-PlainAnswer", [place, area]);
  if !known {
    line += CBT(n"Cyberbane-GangHomes-GoAndSee");
  }
  return CBTalkSay(line, n"");
}

// ---- The pin ----------------------------------------------------------------------------------------------

public func CBGangHomePinTitle(m: ref<CBMapMemory>) -> String {
  return CBTf(n"Cyberbane-GangHomes-PinTitle", [CBFactionName(m.a), CBGangHomePlace(m.subject)]);
}

public func CBGangHomePinDesc(sys: ref<CyberbaneSystem>, m: ref<CBMapMemory>) -> String {
  return CBTf(n"Cyberbane-GangHomes-PinDesc", [CBFactionLabel(m.a)]);
}

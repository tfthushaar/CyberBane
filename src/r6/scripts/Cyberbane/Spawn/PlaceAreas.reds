// Cyberbane - Which part of a district a travel point stands in
//
// The game files every fast-travel point under a district (fasttravelpoints.tweak), and in the Badlands that is never one
// of its smaller parts: no point is filed under Biotechnica Flats or the SoCal Border Crossing, so asking for places
// inside one of those found nothing. The game does say which part V is in (PreventionSystem.GetCurrentDistrict, as
// CBSubDistrictName reads it), so each point learns its own part the first time V passes close to it, and the places
// asked for by part (FindPlacesIn) match a point by that as well as by where it is filed.

public class CBPlaceAreaBook extends ScriptableSystem {
  private persistent let m_point: array<TweakDBID>;
  private persistent let m_area: array<TweakDBID>;

  public static func Get(game: GameInstance) -> ref<CBPlaceAreaBook> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBPlaceAreaBook") as CBPlaceAreaBook : null;
  }

  // The part of a district this point was found in, or no id before V has been near it.
  public func AreaOf(point: TweakDBID) -> TweakDBID {
    let i = 0;
    let n = Min(ArraySize(this.m_point), ArraySize(this.m_area));
    while i < n {
      if this.m_point[i] == point {
        return this.m_area[i];
      }
      i += 1;
    }
    return TDBID.None();
  }

  public func Note(point: TweakDBID, area: TweakDBID) -> Void {
    let i = 0;
    let n = Min(ArraySize(this.m_point), ArraySize(this.m_area));
    while i < n {
      if this.m_point[i] == point {
        this.m_area[i] = area;
        return;
      }
      i += 1;
    }
    ArrayPush(this.m_point, point);
    ArrayPush(this.m_area, area);
  }
}

// The district record of the part V stands in, or no id.
public func CBSubDistrictId(game: GameInstance) -> TweakDBID {
  let prev = CBGetSystem(game, n"PreventionSystem") as PreventionSystem;
  let district = IsDefined(prev) ? prev.GetCurrentDistrict() : null;
  let rec = IsDefined(district) ? district.GetDistrictRecord() : null;
  return IsDefined(rec) ? rec.GetID() : TDBID.None();
}

// Every few ticks: the travel point nearest V, when V is close enough to stand in the same part, learns that part.
public func CBPlaceAreaTick(sys: ref<CyberbaneSystem>, game: GameInstance) -> Void {
  if !IsDefined(sys) || sys.GetTickCount() % CBConfig.PlaceAreaLearnTicks() != 0 || !CBWorldStable(game) {
    return;
  }
  let book = CBPlaceAreaBook.Get(game);
  let player = GetPlayer(game);
  let container = GameInstance.GetScriptableSystemsContainer(game);
  let ms = GameInstance.GetMappinSystem(game);
  if !IsDefined(book) || !IsDefined(player) || !IsDefined(container) || !IsDefined(ms) {
    return;
  }
  let fts = container.Get(n"FastTravelSystem") as FastTravelSystem;
  if !IsDefined(fts) {
    return;
  }
  let area = CBSubDistrictId(game);
  if !TDBID.IsValid(area) {
    return;
  }
  let ppos = player.GetWorldPosition();
  let nearest = TDBID.None();
  let best = CBConfig.PlaceAreaLearnDistance();
  let points = fts.GetFastTravelPoints();
  for pt in points {
    if IsDefined(pt) {
      let pin = ms.GetMappin(pt.mappinID);
      if IsDefined(pin) {
        let d = Vector4.Distance(ppos, pin.GetWorldPosition());
        if d <= best {
          best = d;
          nearest = pt.GetPointRecord();
        }
      }
    }
  }
  if TDBID.IsValid(nearest) && book.AreaOf(nearest) != area {
    book.Note(nearest, area);
  }
}

// Does this point stand in the named district, by the part it was found in?
public func CBPointLearnedWithin(game: GameInstance, point: TweakDBID, within: CName) -> Bool {
  let book = CBPlaceAreaBook.Get(game);
  if !IsDefined(book) {
    return false;
  }
  let area = book.AreaOf(point);
  return TDBID.IsValid(area) && CBDistrictWithin(area, within);
}

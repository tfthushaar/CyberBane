// Cyberbane - an add-on's cards on the Hub (extension API level 1)
//
// Data only, drawn by Cyberbane's own row and body code (crash rule: UI goes in as data, never as injected widgets). A
// card is a row in the Gangs page's list (Show as a list): its title, a subtitle, a colour and a bar of pips; picked,
// its lines fill the page and its actions (three at most) are the page's buttons.

public func CBHubCardCyan() -> Int32 = 0
public func CBHubCardGreen() -> Int32 = 1
public func CBHubCardAmber() -> Int32 = 2
public func CBHubCardRed() -> Int32 = 3
public func CBHubCardDim() -> Int32 = 4

public class CBHubCardSpec {
  public let id: CName;            // the add-on's own, unique
  public let titleKey: CName;      // a localization key; or `title` when this is empty
  public let title: String;
  public let subtitle: String;
  public let colour: Int32;        // CBHubCardCyan .. CBHubCardDim
  public let pips: Int32;          // 0 to 5, drawn as a bar
  public let lines: array<String>;
  public let actions: array<String>;   // labels, three at most
}

public class CBHubPageSpec {
  public let id: CName;
  public let titleKey: CName;
  public let cards: array<ref<CBHubCardSpec>>;
}

public abstract class CBHubActionListener extends IScriptable {
  public func OnHubAction(game: GameInstance, cardId: CName, action: Int32) -> Void {}
}

public class CBApiHub extends ScriptableSystem {
  private let m_cards: array<ref<CBHubCardSpec>>;
  private let m_cardListener: array<ref<CBHubActionListener>>;
  private let m_pageTitles: array<CName>;   // a page's title, before its cards in the list (n"" for a gangs row)
  private let m_reqCard: array<CName>;
  private let m_reqAction: array<Int32>;

  public static func Get(game: GameInstance) -> ref<CBApiHub> {
    let c = GameInstance.GetScriptableSystemsContainer(game);
    return IsDefined(c) ? c.Get(n"CBApiHub") as CBApiHub : null;
  }

  public func Add(card: ref<CBHubCardSpec>, listener: ref<CBHubActionListener>, pageTitle: CName) -> Bool {
    if !IsDefined(card) || !IsNameValid(card.id) || IsDefined(this.Card(card.id)) {
      return false;
    }
    ArrayPush(this.m_cards, card);
    ArrayPush(this.m_cardListener, listener);
    ArrayPush(this.m_pageTitles, pageTitle);
    return true;
  }

  public func Count() -> Int32 {
    return Min(Min(ArraySize(this.m_cards), ArraySize(this.m_cardListener)), ArraySize(this.m_pageTitles));
  }

  public func At(i: Int32) -> ref<CBHubCardSpec> { return i >= 0 && i < this.Count() ? this.m_cards[i] : null; }
  public func PageTitleAt(i: Int32) -> CName { return i >= 0 && i < this.Count() ? this.m_pageTitles[i] : n""; }

  public func Card(id: CName) -> ref<CBHubCardSpec> {
    for c in this.m_cards {
      if IsDefined(c) && Equals(c.id, id) {
        return c;
      }
    }
    return null;
  }

  public func Request(id: CName, action: Int32) -> Void {
    ArrayPush(this.m_reqCard, id);
    ArrayPush(this.m_reqAction, action);
  }

  // On the settled tick: every click since, to the listener of its card.
  public func Deliver(game: GameInstance) -> Void {
    let n = Min(ArraySize(this.m_reqCard), ArraySize(this.m_reqAction));
    if n == 0 {
      return;
    }
    let cards = this.m_reqCard;
    let actions = this.m_reqAction;
    ArrayClear(this.m_reqCard);
    ArrayClear(this.m_reqAction);
    let i = 0;
    while i < n {
      let k = 0;
      while k < this.Count() {
        if IsDefined(this.m_cards[k]) && Equals(this.m_cards[k].id, cards[i]) && IsDefined(this.m_cardListener[k]) {
          this.m_cardListener[k].OnHubAction(game, cards[i], actions[i]);
        }
        k += 1;
      }
      i += 1;
    }
  }
}

// The Gangs list's id for a card: never a faction's.
public func CBApiCardRowId(card: ref<CBHubCardSpec>) -> CName {
  return StringToName("CBApi:" + NameToString(card.id));
}

public func CBApiCardOfRowId(game: GameInstance, rowId: CName) -> ref<CBHubCardSpec> {
  let s = NameToString(rowId);
  let hub = CBApiHub.Get(game);
  if !StrBeginsWith(s, "CBApi:") || !IsDefined(hub) {
    return null;
  }
  return hub.Card(StringToName(StrAfterFirst(s, "CBApi:")));
}

public func CBApiCardTitle(card: ref<CBHubCardSpec>) -> String {
  return IsNameValid(card.titleKey) ? CBT(card.titleKey) : card.title;
}

public func CBApiCardTint(colour: Int32) -> HDRColor {
  if colour == CBHubCardGreen() { return CBHudGreen(); }
  if colour == CBHubCardAmber() { return CBHudAmber(); }
  if colour == CBHubCardRed() { return CBHudRed(); }
  if colour == CBHubCardDim() { return CBHudDim(); }
  return CBHudCyan();
}

public func CBApiHubTick(game: GameInstance) -> Void {
  let hub = CBApiHub.Get(game);
  if IsDefined(hub) && CBWorldStable(game) {
    hub.Deliver(game);
  }
}

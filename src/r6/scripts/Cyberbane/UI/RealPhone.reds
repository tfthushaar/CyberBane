// Cyberbane - The phone V carries (spec §12.2)
//
// Players asked for the gang messages to be "actual text messages", and the phone is where text
// messages live. This file puts Cyberbane's senders into it: each one is a contact in the
// phone's Messages list, a new message arrives through the game's own incoming-SMS notification,
// and opening the contact shows the thread in the phone's own messenger panel, drawn with the
// game's own message bubbles.
//
// ---- How it fits into the game's phone (read against the 2.5 scripts) ----
//
// The list. `NewHudPhoneGameController` builds the Messages tab from
// `MessengerUtils.GetSimpleContactDataArray`, which returns plain `ContactData` objects
// (core/systems/journalManager.script:366, a constructible script class). Cyberbane appends one
// per thread. The full-screen messenger in the hub menu calls the same function but passes its
// sync object, and the phone does not (messengerController.script:290 against
// newHudPhoneGameController.script:1421/1531), so the threads only go where they can be drawn.
//
// Opening a thread. Selecting a contact makes the phone queue an `OpenSmsMessengerEvent` (or a
// refresh) carrying a `JournalNotificationData` whose `journalEntry` it looks up by hash. Ours
// has no journal entry, so `GotoSmsMessenger` and `RefreshSmsMessager` hand over a subclass
// carrying the thread instead, and `PhoneMessagePopupGameController.SetupData` sets the panel up
// for it without ever asking the journal about it. The lines are handed to the messenger's own
// message list as list data, so the game spawns its own `MessangerItemRenderer` bubbles for them.
//
// The notification. `PushSMSNotification` (newHudPhoneGameController.script:1768) fills a
// `PhoneMessageNotificationViewData` and hands it to `AddNewNotificationData`. Cyberbane does
// the same with its own text and an action that opens the phone on the thread, which is what
// `OpenPhoneMessageAction` and `PhoneSystem.OnUsePhone` do for a real message: set
// `MessageToOpenHash` on the UI_ComDevice blackboard, then open the contact list.
//
// Answering. A gang V can buy off that has sent a hostile message leaves an answer open in its
// thread, handed to the messenger's own reply list and chosen the way the game's own reply
// choices are chosen (up, down, select, or a click). Paying runs CBBrokerPeace, the same
// function and price as the Hub's shortcut; refusing gets their answer. The game marks a chosen
// reply as a journal entry, and ours have none, so the panel's "has replies" test and the two
// ways of choosing are wrapped to answer for Cyberbane's rows while one of its threads shows.
//
// The approach is the one the Phone Extension framework (r457 and gh057) proved on 2.x. None of
// its code is used and nothing here depends on it; every name is Cyberbane's own, so both can
// be installed together.
//
// ---- Safety ----
//
// Everything is a wrap that falls straight through to the game unless the contact, the panel or
// the notification is one of Cyberbane's. A contact is ours only if its hash is in Cyberbane's
// block (CBConfig.PhoneHashBase) and the thread exists. Nothing is added to the phone at all in
// the Cards or Notices delivery modes, or with the kill switch thrown, and a panel that is
// already showing one of ours keeps working when the setting changes, rather than being handed
// to vanilla code that would look for a journal entry that is not there.

// ---- Our contacts ---------------------------------------------------------

public func CBPhoneThreadHash(thread: Int32) -> Int32 {
  return CBConfig.PhoneHashBase() + thread;
}

func CBPhoneThreadOf(hash: Int32) -> Int32 {
  return hash - CBConfig.PhoneHashBase();
}

func CBPhoneStore() -> ref<CBPhone> {
  let sys = CyberbaneSystem.Get(GetGameInstance());
  if !IsDefined(sys) {
    return null;
  }
  return sys.GetPhone();
}

// Is this hash one of Cyberbane's threads?
public func CBRealPhoneOwns(hash: Int32) -> Bool {
  let thread = CBPhoneThreadOf(hash);
  if thread < 0 || thread >= CBConfig.PhoneThreadCap() {
    return false;
  }
  let store = CBPhoneStore();
  return IsDefined(store) && thread < store.ThreadCount();
}

// Fill a ContactData from the thread it stands for. Used to build the row and to refresh it
// after the thread has been read.
public func CBRealPhoneFill(contact: ref<ContactData>) -> Void {
  let store = CBPhoneStore();
  if !IsDefined(store) || !IsDefined(contact) {
    return;
  }
  let thread = CBPhoneThreadOf(contact.hash);
  let unread = store.ThreadUnread(thread);
  contact.lastMesssagePreview = store.ThreadPreview(thread);
  contact.playerIsLastSender = store.ThreadPreviewMine(thread);
  contact.playerCanReply = ArraySize(CBRealPhoneChoices(contact.hash)) > 0;
  contact.repliesCount = contact.playerCanReply ? 2 : 0;
  contact.messagesCount = store.ThreadSize(thread);
  contact.unreadMessegeCount = unread;
  ArrayClear(contact.unreadMessages);
  // The phone only ever counts these and looks for a hash among them, so each unread line is
  // marked with the thread's own hash: nothing of the game's can match it.
  let i = 0;
  while i < unread {
    ArrayPush(contact.unreadMessages, contact.hash);
    i += 1;
  }
  contact.timeStamp = store.ThreadTime(thread);
}

// One row per thread, for the phone's Messages tab. With the tab showing unread only, a thread
// that has been read stays out unless V can still answer it, the same rule the game applies to
// its own contacts (MessengerUtils.AddContactData).
public func CBRealPhoneContacts(includeRead: Bool) -> array<ref<IScriptable>> {
  let out: array<ref<IScriptable>>;
  let store = CBPhoneStore();
  if !IsDefined(store) {
    return out;
  }
  let i = 0;
  while i < store.ThreadCount() {
    let hash = CBPhoneThreadHash(i);
    let canReply = ArraySize(CBRealPhoneChoices(hash)) > 0;
    if store.ThreadSize(i) > 0 && (includeRead || store.ThreadUnread(i) > 0 || canReply) {
      let c = new ContactData();
      c.id = "cyberbane_thread_" + IntToString(i);
      c.contactId = c.id;
      c.hash = hash;
      c.conversationHash = 0;
      c.localizedName = store.ThreadName(i);
      c.type = MessengerContactType.SingleThread;
      c.hasMessages = true;
      c.hasValidTitle = false;
      c.isCallable = false;
      c.questRelated = false;
      c.hasQuestImportantReply = false;
      c.threadsCount = 1;
      CBRealPhoneFill(c);
      ArrayPush(out, c);
    }
    i += 1;
  }
  return out;
}

public func CBRealPhoneMarkRead(hash: Int32) -> Void {
  if !CBRealPhoneOwns(hash) {
    return;
  }
  let store = CBPhoneStore();
  if IsDefined(store) {
    store.MarkThreadRead(CBPhoneThreadOf(hash));
  }
}

public func CBRealPhoneThreadMine(hash: Int32) -> array<Bool> {
  let none: array<Bool>;
  if !CBRealPhoneOwns(hash) {
    return none;
  }
  let store = CBPhoneStore();
  if !IsDefined(store) {
    return none;
  }
  return store.ThreadMine(CBPhoneThreadOf(hash), CBConfig.PhoneThreadShown());
}

// The answers V can send in this thread right now, as the reply rows show them. Worked out
// fresh every time from the gang's current standing and price, so a stale offer never shows:
// once they are no longer hostile, or the price has moved, the rows say so or disappear.
public func CBRealPhoneChoices(hash: Int32) -> array<String> {
  let out: array<String>;
  if !CBRealPhoneOwns(hash) {
    return out;
  }
  let game = GetGameInstance();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return out;
  }
  let store = sys.GetPhone();
  let thread = CBPhoneThreadOf(hash);
  let faction = store.ThreadOffer(thread);
  if Equals(faction, n"") {
    return out;
  }
  let cost = CBPeaceQuote(sys, game, faction);
  if cost < 0 {
    store.ClearOffer(thread);
    return out;
  }
  ArrayPush(out, s"Pay \(cost)eb to call it off");
  ArrayPush(out, "Not paying");
  return out;
}

// V picked answer `choice` in this thread. V's line goes into the thread first, then whatever
// it does happens, and the gang's answer arrives as a message of its own a moment later.
public func CBRealPhoneReply(hash: Int32, choice: Int32) -> Void {
  let choices = CBRealPhoneChoices(hash);
  if choice < 0 || choice >= ArraySize(choices) {
    return;
  }
  let game = GetGameInstance();
  let sys = CyberbaneSystem.Get(game);
  if !IsDefined(sys) {
    return;
  }
  let store = sys.GetPhone();
  let thread = CBPhoneThreadOf(hash);
  let faction = store.ThreadOffer(thread);
  let cost = CBPeaceQuote(sys, game, faction);
  store.ClearOffer(thread);
  if choice == 0 {
    store.Reply(game, thread, s"\(cost)eb. Call it off.");
    // Pays, clears the vendetta and anything on its way, and has the gang confirm it. If V
    // cannot cover it, the gang says so and the offer stays open.
    CBBrokerPeace(sys, game, faction);
  } else {
    store.Reply(game, thread, "Not paying. Send whoever you want.");
    CBPhoneFromGangFinal(game, faction, "Then we will be seeing you.");
  }
}

public func CBRealPhoneThreadBodies(hash: Int32) -> array<String> {
  let none: array<String>;
  if !CBRealPhoneOwns(hash) {
    return none;
  }
  let store = CBPhoneStore();
  if !IsDefined(store) {
    return none;
  }
  return store.ThreadBodies(CBPhoneThreadOf(hash), CBConfig.PhoneThreadShown());
}

// What the messenger panel is opened with for one of ours. The game's own data class, so every
// field it reads is there; the thread rides along in the fields this subclass adds.
public class CBPhoneThreadData extends JournalNotificationData {
  public let cbHash: Int32;
  public let cbName: String;
}

func CBRealPhoneThreadData(contact: wref<ContactData>, source: PhoneScreenType) -> ref<CBPhoneThreadData> {
  let data = new CBPhoneThreadData();
  data.cbHash = contact.hash;
  data.cbName = contact.localizedName;
  data.type = MessengerContactType.SingleThread;
  data.contactNameLocKey = n"";
  data.mode = JournalNotificationMode.HUD;
  data.openedFromPhone = true;
  data.source = source;
  return data;
}

// Pressing the notification: open the phone on the thread. The same two blackboard writes the
// game makes for one of its own messages (PhoneSystem.OnUsePhone and ToggleContacts), behind
// the same checks.
public class CBOpenThreadAction extends GenericNotificationBaseAction {
  public let m_phoneSystem: wref<PhoneSystem>;
  public let m_hash: Int32;

  public func Execute(data: ref<IScriptable>) -> Bool {
    let game = GetGameInstance();
    let bbs = GameInstance.GetBlackboardSystem(game);
    if !IsDefined(bbs) || !IsDefined(this.m_phoneSystem) {
      return true;
    }
    let defs = GetAllBlackboardDefs().UI_ComDevice;
    let bb = bbs.Get(defs);
    if !IsDefined(bb) {
      return true;
    }
    // Already open: nothing to do, which is what the game does too.
    if bb.GetBool(defs.ContactsActive) {
      return true;
    }
    if !this.m_phoneSystem.IsPhoneEnabled() {
      let ui = GameInstance.GetUISystem(game);
      if IsDefined(ui) {
        ui.QueueEvent(new UIInGameNotificationRemoveEvent());
        let blocked = new UIInGameNotificationEvent();
        blocked.m_notificationType = UIInGameNotificationType.CombatRestriction;
        ui.QueueEvent(blocked);
      }
      return true;
    }
    if CBRealPhoneOwns(this.m_hash) {
      bb.SetInt(defs.MessageToOpenHash, this.m_hash, true);
    }
    bb.SetBool(defs.ContactsActive, true, true);
    return true;
  }

  public func GetLabel() -> String {
    return "";
  }
}

// ---- The phone controller -------------------------------------------------

// Keep hold of the phone when the HUD builds it. Weak, and re-checked on every use.
@wrapMethod(NewHudPhoneGameController)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
  let result = wrappedMethod(playerPuppet);
  if IsDefined(playerPuppet) {
    let sys = CyberbaneSystem.Get(playerPuppet.GetGame());
    if IsDefined(sys) {
      sys.GetPhone().SetPhoneController(this);
    }
  }
  return result;
}

// A new message from one of ours. Called from CBPhone.Deliver, on a settled tick.
@addMethod(NewHudPhoneGameController)
public func CBDeliverThread(hash: Int32, sender: String, body: String, sound: Bool) -> Void {
  // The phone is already in V's hand: refresh the list the way the game refreshes it for its
  // own messages (NotifyOrRefreshData), rather than putting a notification over the phone the
  // player is already holding.
  if IsDefined(this.contactsElement.widget) {
    if IsDefined(this.m_contactListLogicController)
        && Equals(this.m_screenType, PhoneScreenType.Unread)
        && !this.m_messagesPanelVisible {
      this.SetScreenType(PhoneScreenType.Unread);
    }
    return;
  }
  let action = new CBOpenThreadAction();
  action.m_phoneSystem = this.m_PhoneSystem;
  action.m_hash = hash;
  let userData = new PhoneMessageNotificationViewData();
  userData.entryHash = 0;
  userData.threadHash = hash;
  // No contact entry to look up: the notification asks the journal for this hash, and zero is
  // the one value that can never collide with a real entry's.
  userData.contactHash = 0;
  userData.title = sender;
  userData.SMSText = body;
  userData.action = action;
  userData.animation = n"notification_phone_MSG";
  userData.soundEvent = sound ? n"PhoneSmsPopup" : n"";
  userData.soundAction = n"OnOpen";
  let notification: gameuiGenericNotificationData;
  notification.time = 6.7;
  notification.widgetLibraryItemName = n"notification_message";
  notification.notificationData = userData;
  this.AddNewNotificationData(notification);
}

// ---- The Messages list ----------------------------------------------------

@wrapMethod(MessengerUtils)
public final static func GetSimpleContactDataArray(journal: ref<JournalManager>, includeUnknown: Bool, skipEmpty: Bool, includeWithNoUnread: Bool, opt activeDataSync: wref<MessengerContactSyncData>) -> array<ref<IScriptable>> {
  let list = wrappedMethod(journal, includeUnknown, skipEmpty, includeWithNoUnread, activeDataSync);
  // Only the phone in V's hand, which passes no sync object. The hub menu's messenger has no
  // way to draw a thread that is not in the journal, so it never sees one.
  if !IsDefined(activeDataSync) && CBRealPhoneOn() {
    let ours = CBRealPhoneContacts(includeWithNoUnread);
    let i = 0;
    while i < ArraySize(ours) {
      ArrayPush(list, ours[i]);
      i += 1;
    }
  }
  return list;
}

// Selecting one of ours: open the panel with the thread rather than with a journal entry.
@wrapMethod(NewHudPhoneGameController)
public final func GotoSmsMessenger(contactData: wref<ContactData>) -> Void {
  if IsDefined(contactData) && CBRealPhoneOwns(contactData.hash) {
    let evt = new OpenSmsMessengerEvent();
    evt.m_data = CBRealPhoneThreadData(contactData, this.m_screenType);
    this.QueueEvent(evt);
    return;
  }
  wrappedMethod(contactData);
}

// Moving to one of ours while the panel is already up.
@wrapMethod(NewHudPhoneGameController)
public final func RefreshSmsMessager(contactData: wref<ContactData>) -> Void {
  if IsDefined(contactData) && CBRealPhoneOwns(contactData.hash) {
    let evt = new RefreshSmsMessagerEvent();
    evt.m_data = CBRealPhoneThreadData(contactData, this.m_screenType);
    this.QueueEvent(evt);
    return;
  }
  wrappedMethod(contactData);
}

// Coming back out of one of ours. The game re-reads the contact from the journal here, finds
// nothing for our hash and reports no change; reading it from the thread instead lets the game
// treat a read thread the way it treats its own and take it off the unread list.
@wrapMethod(NewHudPhoneGameController)
public final func RefreshReplies(contactData: ref<ContactData>) -> Bool {
  if IsDefined(contactData) && CBRealPhoneOwns(contactData.hash) {
    let unreadBefore = ArraySize(contactData.unreadMessages);
    let replyBefore = contactData.playerCanReply;
    CBRealPhoneFill(contactData);
    return unreadBefore != ArraySize(contactData.unreadMessages)
        || NotEquals(replyBefore, contactData.playerCanReply);
  }
  return wrappedMethod(contactData);
}

// ---- The messenger panel --------------------------------------------------

@wrapMethod(PhoneMessagePopupGameController)
private final func SetupData() -> Void {
  let ours = this.m_data as CBPhoneThreadData;
  if IsDefined(ours) {
    this.CBSetupThread(ours);
    return;
  }
  // Leaving one of ours for one of the game's in the same panel: take our bubbles down first,
  // because the game's list only clears the rows it made itself.
  if IsDefined(this.m_dialogViewController) {
    this.m_dialogViewController.CBLeaveThread();
  }
  wrappedMethod();
}

// SetupData for one of ours: every widget the game's version sets, set for a contact with no
// journal entry, no attachment and no call button.
@addMethod(PhoneMessagePopupGameController)
private func CBSetupThread(data: ref<CBPhoneThreadData>) -> Void {
  this.m_contactEntry = null;
  this.m_entry = null;
  this.m_attachment = null;
  this.m_activeEntry = null;
  this.m_journalEntryHash = data.cbHash;
  inkWidgetRef.SetVisible(this.m_menuBackgrouns, false);
  inkWidgetRef.SetVisible(this.m_hintTrack, false);
  inkWidgetRef.SetVisible(this.m_contactsPath, Equals(data.source, PhoneScreenType.Contacts));
  inkWidgetRef.SetVisible(this.m_messagesPath, Equals(data.source, PhoneScreenType.Unread));
  inkWidgetRef.SetVisible(this.m_hintCall, false);
  inkWidgetRef.SetVisible(this.m_hintReply, false);
  inkWidgetRef.SetVisible(this.m_scrollReply, false);
  inkWidgetRef.SetVisible(this.m_hintMessenger, true);
  let noAvatar: TweakDBID;
  InkImageUtils.RequestAvatarOrUnknown(this, this.m_avatarImage, noAvatar);
  inkTextRef.SetText(this.m_title, data.cbName);
  if IsDefined(this.m_dialogViewController) {
    this.m_dialogViewController.CBShowThread(data.cbHash);
  }
  // Opened from the phone, so it starts as a preview beside the list and takes focus when the
  // player opens it, exactly as the game's own threads do.
  this.SetFocus(!data.openedFromPhone);
}

// Opening a thread is reading it.
@wrapMethod(PhoneMessagePopupGameController)
private final func SetFocus(isFocused: Bool) -> Void {
  wrappedMethod(isFocused);
  let ours = this.m_data as CBPhoneThreadData;
  let store = CBPhoneStore();
  if IsDefined(ours) {
    if isFocused {
      CBRealPhoneMarkRead(ours.cbHash);
    }
    if IsDefined(store) {
      store.SetFocusedThread(isFocused ? ours.cbHash : 0);
    }
  } else {
    if IsDefined(store) {
      store.SetFocusedThread(0);
    }
  }
}

// Nobody to call. The game would ask a contact entry that ours does not have.
@wrapMethod(PhoneMessagePopupGameController)
private final func TryCallContact() -> Void {
  if IsDefined(this.m_data as CBPhoneThreadData) {
    return;
  }
  wrappedMethod();
}

// ---- The thread itself ----------------------------------------------------
//
// The panel's message list and reply list are the game's own list controllers
// (JournalEntriesListController, native ListController underneath). Each owns the widgets in its
// container: it spawns them when data is pushed and destroys them when it is cleared. So a
// Cyberbane thread is handed to those same controllers as data, exactly the way the game hands
// them journal entries in MessengerDialogViewController.UpdateData, and the game builds,
// selects, highlights and destroys every widget itself.
//
// 1.4.7 spawned its own bubbles and reply rows into those containers and cleared them with
// RemoveAllChildren, which took widgets out from under a native list that was still tracking
// them. That is the likeliest cause of the crash reported on opening a gang's text, which is
// the thread that carries reply rows. Nothing here adds or removes a widget by hand any more.
//
// Each line rides in the list item's m_extraData as a CBPhoneLine, and the two item renderers
// are wrapped to draw a CBPhoneLine when they are given one. A game entry never carries one, so
// the game's own threads draw exactly as before.

// One line of a thread or one answer, as list data.
public class CBPhoneLine extends IScriptable {
  public let text: String;
  public let mine: Bool;
}

func CBPhoneLineItem(text: String, mine: Bool) -> ref<JournalEntryListItemData> {
  let line = new CBPhoneLine();
  line.text = text;
  line.mine = mine;
  let item = new JournalEntryListItemData();
  item.m_extraData = line;
  return item;
}

// Non-zero while this panel is showing one of Cyberbane's threads.
@addField(MessengerDialogViewController)
public let cbThreadHash: Int32;

// How many answers are drawn under it. Which one is picked is the reply list's own selection.
@addField(MessengerDialogViewController)
public let cbChoiceCount: Int32;

@addMethod(MessengerDialogViewController)
public func CBShowThread(hash: Int32) -> Void {
  this.cbThreadHash = hash;
  this.m_contactHash = hash;
  this.m_conversationHash = 0;
  this.m_parentEntry = null;
  this.m_parentHash = hash;
  this.m_singleThreadMode = true;
  this.CBRenderThread(false);
  let store = CBPhoneStore();
  if IsDefined(store) {
    store.SetOpenDialog(this);
  }
}

// Draw the thread, the same steps in the same order as the game's UpdateData.
@addMethod(MessengerDialogViewController)
public func CBRenderThread(animateLast: Bool) -> Void {
  if this.cbThreadHash == 0 {
    return;
  }
  this.StopDotsAnimation();
  // Nothing of the game's may be left in these: the game's reply and visited handling walks them.
  ArrayClear(this.m_replyOptions);
  ArrayClear(this.m_messages);

  let bodies = CBRealPhoneThreadBodies(this.cbThreadHash);
  let mine = CBRealPhoneThreadMine(this.cbThreadHash);
  let lines: array<ref<IScriptable>>;
  let i = 0;
  while i < ArraySize(bodies) {
    ArrayPush(lines, CBPhoneLineItem(bodies[i], i < ArraySize(mine) && mine[i]));
    i += 1;
  }
  let choices = CBRealPhoneChoices(this.cbThreadHash);
  let answers: array<ref<IScriptable>>;
  let c = 0;
  while c < ArraySize(choices) {
    ArrayPush(answers, CBPhoneLineItem(choices[c], true));
    c += 1;
  }
  this.cbChoiceCount = ArraySize(answers);

  inkCompoundRef.SetVisible(this.m_replayFluff, this.cbChoiceCount > 0);
  if IsDefined(this.m_messagesListController) {
    this.m_messagesListController.Clear();
    this.m_messagesListController.PushDataList(lines, true);
  }
  if IsDefined(this.m_choicesListController) {
    this.m_choicesListController.Clear();
    this.m_choicesListController.PushDataList(answers, true);
    if this.cbChoiceCount > 0 {
      this.SetFocus(this.m_hasFocus);
      this.m_choicesListController.SetSelectedIndex(0);
    }
  }
  if animateLast && IsDefined(this.m_messagesListController) {
    let count = this.m_messagesListController.Size();
    if count > 0 {
      let lastWidget = this.m_messagesListController.GetItemAt(count - 1);
      if IsDefined(lastWidget) {
        this.PlayLibraryAnimationOnAutoSelectedTargets(n"reply_sent", lastWidget);
      }
    }
  }
  if IsDefined(this.m_scrollController) {
    this.m_scrollController.SetScrollPosition(1.0);
  }
}

// Redraw on the panel's next frame rather than now. Used whenever the redraw is asked for from
// inside something the lists are doing (a reply row being activated) or from outside the UI (a
// message arriving): clearing a list from inside its own callback would destroy the row whose
// callback is running. The game does the same thing for its own threads: a reply changes the
// journal, and the redraw comes back later as a DelayedJournalUpdate.
@addMethod(MessengerDialogViewController)
public func CBQueueRedraw(animate: Bool) -> Void {
  if this.cbThreadHash == 0 {
    return;
  }
  let evt = new DelayedJournalUpdate();
  evt.m_newMessageSpawned = animate;
  evt.m_typing = false;
  evt.m_delay = 0.0;
  evt.m_contactHash = this.cbThreadHash;
  this.QueueEvent(evt);
}

// Send the answer at `index`.
@addMethod(MessengerDialogViewController)
public func CBActivateChoice(index: Int32) -> Void {
  if this.cbThreadHash == 0 || index < 0 || index >= this.cbChoiceCount {
    return;
  }
  let hash = this.cbThreadHash;
  if IsDefined(this.m_audioSystem) {
    this.m_audioSystem.Play(n"ui_messenger_select");
  }
  this.PlayRumble(RumbleStrength.SuperLight, RumbleType.Pulse, RumblePosition.Right);
  // No answer can be sent twice while the redraw is on its way.
  this.cbChoiceCount = 0;
  CBRealPhoneReply(hash, index);
  this.CBQueueRedraw(true);
}

// Hand the panel back to the game. Its lists are cleared and refilled by the game's own
// UpdateData straight after this, so there is nothing of ours to take down.
@addMethod(MessengerDialogViewController)
public func CBLeaveThread() -> Void {
  this.cbThreadHash = 0;
  this.cbChoiceCount = 0;
}

// The game refreshes the panel whenever anything in the journal's phone section changes. While
// it is showing one of ours, that refresh redraws ours instead of asking the journal for an
// entry that does not exist (which would come back empty and wipe the thread off the panel).
@wrapMethod(MessengerDialogViewController)
public final func UpdateData(animateLastMessage: Bool, setVisited: Bool) -> Void {
  if this.cbThreadHash != 0 {
    this.CBRenderThread(animateLastMessage);
    return;
  }
  wrappedMethod(animateLastMessage, setVisited);
}

// Journal traffic for the game's threads while one of ours is up. A redraw is a redraw of ours;
// the typing dots belong to the game's thread and would read its message list, which is empty
// while ours is showing.
@wrapMethod(MessengerDialogViewController)
protected cb func OnDelayedJournalUpdate(evt: ref<DelayedJournalUpdate>) -> Bool {
  if this.cbThreadHash != 0 {
    if IsDefined(evt) && evt.m_delay == 0.0 {
      this.CBRenderThread(evt.m_newMessageSpawned && evt.m_contactHash == this.cbThreadHash);
    }
    return true;
  }
  return wrappedMethod(evt);
}

// The reply controls, pointed at Cyberbane's answers while one of its threads is up. Moving
// between answers is left to the game: the rows are the reply list's own items, so its
// Next/Prior and its highlight work on them unchanged.
@wrapMethod(MessengerDialogViewController)
public final func HasReplyOptions() -> Bool {
  if this.cbThreadHash != 0 {
    return this.cbChoiceCount > 0;
  }
  return wrappedMethod();
}

@wrapMethod(MessengerDialogViewController)
public final func ActivateSelectedReplyOption() -> Void {
  if this.cbThreadHash != 0 {
    let index = IsDefined(this.m_choicesListController) ? this.m_choicesListController.GetSelectedIndex() : -1;
    this.CBActivateChoice(index);
    return;
  }
  wrappedMethod();
}

// A click on an answer row. The game's version would mark a journal entry as chosen, and ours
// have none.
@wrapMethod(MessengerDialogViewController)
protected cb func OnPlayerReplyActivated(index: Int32, target: ref<ListItemController>) -> Bool {
  if this.cbThreadHash != 0 {
    this.CBActivateChoice(index);
    return true;
  }
  return wrappedMethod(index, target);
}

// A line of ours, in the game's message bubble: the contact's on the left, V's on the right.
@wrapMethod(MessangerItemRenderer)
protected func OnJournalEntryUpdated(entry: wref<JournalEntry>, extraData: ref<IScriptable>) -> Void {
  let line = extraData as CBPhoneLine;
  if IsDefined(line) {
    let noName = "";
    inkImageRef.SetVisible(this.m_image, false);
    this.SetMessageView(line.text, line.mine ? MessageViewType.Sent : MessageViewType.Received, noName);
    return;
  }
  wrappedMethod(entry, extraData);
}

// An answer of ours, in the game's reply row.
@wrapMethod(MessangerReplyItemRenderer)
protected func OnJournalEntryUpdated(entry: wref<JournalEntry>, extraData: ref<IScriptable>) -> Void {
  let line = extraData as CBPhoneLine;
  if IsDefined(line) {
    inkTextRef.SetText(this.m_labelPathRef, line.text);
    this.m_isQuestImportant = false;
    this.AnimateSelection();
    return;
  }
  wrappedMethod(entry, extraData);
}

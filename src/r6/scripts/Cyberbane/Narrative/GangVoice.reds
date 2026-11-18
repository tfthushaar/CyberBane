// Cyberbane - Each gang's voice ([L3], 2.3.2)
//
// The texts, warnings, refusals and surrenders a gang's people say, written for that gang, from its code
// (Data/GangCodes.reds): the Valentinos' family and honour, the Claws' face and business, Maelstrom's chrome,
// 6th Street's veterans, the Animals' strength, the Voodoo Boys' Net, the Mox looking after their own, the
// Scavengers, the Wraiths' road, the Aldecaldos' family, Barghest's soldiers. Every line goes through the line
// library (Narrative/Lines.reds), so none comes twice running. A gang with nothing of its own here, or a
// moment it has nothing for, answers "" and the caller says what it always said.

// A street warning from one of theirs, before they draw (the Director's warning, Narrative/Whispers.reds).
public func CBGangWarnLine(f: CName) -> String {
  if Equals(f, n"Valentinos") {
    return CBLineOf(["This is Valentino blood's street. Walk away, and we let you keep your face.",
                     "Por la familia, I'm giving you one chance. Turn around.",
                     "You disrespect this barrio, you disrespect all of us. Go."]);
  }
  if Equals(f, n"TygerClaws") {
    return CBLineOf(["This street pays the Claws. You don't. Leave.",
                     "Bad for business, you being here. Worse for you.",
                     "Walk away now and nobody loses face. Stay and you lose more."]);
  }
  if Equals(f, n"Maelstrom") {
    return CBLineOf(["Nice chrome. Be a shame if we peeled it off you.",
                     "Meat like you doesn't walk Maelstrom streets. Run.",
                     "Keep walking, or leave your implants on the way out."]);
  }
  if Equals(f, n"SixthStreet") {
    return CBLineOf(["This is a 6th Street neighbourhood. We keep it safe. Move along.",
                     "We've done tours that'd break you. Don't make this one.",
                     "Patrol's watching you, merc. Keep it peaceful or keep walking."]);
  }
  if Equals(f, n"Animals") {
    return CBLineOf(["You looking for a beating? Keep walking this way.",
                     "Small thing like you on Animal ground. Cute. Go.",
                     "Put the gun down and I'll show you what strong is. Or leave."]);
  }
  if Equals(f, n"VoodooBoys") {
    return CBLineOf(["We already know everything about you. Leave before we use it.",
                     "Your ICE is paper, merc. Don't make us prove it.",
                     "Loa are watching you. So are we. Walk."]);
  }
  if Equals(f, n"Mox") {
    return CBLineOf(["Nobody hurts anyone on our street. That includes you. Go.",
                     "We look after our own here. You're not ours.",
                     "Leave the girls alone and walk on. Last time I say it."]);
  }
  if Equals(f, n"Scavengers") {
    return CBLineOf(["Nice parts. Walk away before we take them.",
                     "Keep moving, unless you wanna end up in a bathtub.",
                     "Everything on you has a price. Don't make us collect."]);
  }
  if Equals(f, n"Wraiths") {
    return CBLineOf(["This is Wraith road. Turn your car around.",
                     "Out here nobody hears you scream. Leave.",
                     "The desert takes everyone. Don't hurry it."]);
  }
  if Equals(f, n"Aldecaldos") {
    return CBLineOf(["You're near the family's camp. Show some respect and move on.",
                     "We don't want trouble. Don't bring any.",
                     "Family looks after family. You're not family. Keep going."]);
  }
  if Equals(f, n"Barghest") {
    return CBLineOf(["Restricted zone. Leave the area.",
                     "This is your only warning, civilian. Turn back.",
                     "You are being tracked. Comply and withdraw."]);
  }
  return "";
}

// A crew on its way, in their own words, around how many and where (CBCrewWarning, Spawn/Hunt.reds).
public func CBGangCrewText(f: CName, where: String, coming: String, vendetta: Bool, onTheirTurf: Bool) -> String {
  let place = StrLen(where) > 0 ? where : "around here";
  if Equals(f, n"Valentinos") {
    return CBLineOf([s"You hurt the family. Now the family comes for you in \(place). \(coming)",
                     s"We know you're in \(place). Pray to whoever you pray to. \(coming)",
                     s"Honour says we tell you first: we're coming, \(place). \(coming)"]);
  }
  if Equals(f, n"TygerClaws") {
    return CBLineOf([s"You cost us face. That's a debt. We're collecting in \(place). \(coming)",
                     s"Business is business. You're bad for ours. \(coming) \(place).",
                     s"We found you in \(place). \(coming) Try not to embarrass yourself."]);
  }
  if Equals(f, n"Maelstrom") {
    return CBLineOf([s"We want those implants, choom. Coming to \(place) to get them. \(coming)",
                     s"Heard you're in \(place). Hope your chrome's worth it. \(coming)",
                     s"Your arms'd look better on one of us. \(coming) See you in \(place)."]);
  }
  if Equals(f, n"SixthStreet") {
    return CBLineOf([s"Squad's rolling out to \(place). You don't get to hurt our people and walk. \(coming)",
                     s"Target confirmed in \(place). \(coming)",
                     s"We protect this city from people like you. \(coming) \(place)."]);
  }
  if Equals(f, n"Animals") {
    return CBLineOf([s"You think you're strong? We're coming to \(place) to find out. \(coming)",
                     s"Juiced up and headed your way in \(place). \(coming)",
                     s"Gonna break you in half, merc. \(place). \(coming)"]);
  }
  if Equals(f, n"VoodooBoys") {
    return CBLineOf([s"We traced you to \(place) before you knew we were looking. \(coming)",
                     s"Your location is \(place). Your time is short. \(coming)",
                     s"The Net told us where you are: \(place). \(coming)"]);
  }
  if Equals(f, n"Mox") {
    return CBLineOf([s"You hurt one of ours. We don't let that go. \(coming) \(place).",
                     s"Coming to \(place). This is for her. \(coming)",
                     s"We protect our own, and you made it personal. \(coming)"]);
  }
  if Equals(f, n"Scavengers") {
    return CBLineOf([s"Fresh parts walking round \(place). We're coming shopping. \(coming)",
                     s"Price on your organs just went up. \(coming) \(place).",
                     s"Found you in \(place). Hold still. \(coming)"]);
  }
  if Equals(f, n"Wraiths") {
    return CBLineOf([s"You're on our road now, \(place). \(coming)",
                     s"Engines are running. \(place). \(coming)",
                     s"Out here nobody comes to help. \(coming) \(place)."]);
  }
  if Equals(f, n"Aldecaldos") {
    return CBLineOf([s"You hurt family. The clan doesn't forget. \(coming) \(place).",
                     s"We'd rather not do this. You gave us no choice. \(place). \(coming)",
                     s"Family's coming for you in \(place). \(coming)"]);
  }
  if Equals(f, n"Barghest") {
    return CBLineOf([s"Hostile located in \(place). Unit deployed. \(coming)",
                     s"Engaging target in \(place). \(coming)",
                     s"You were warned. Strike team inbound to \(place). \(coming)"]);
  }
  return "";
}

// One of theirs won't talk (StreetTalk.Refuse).
public func CBGangRefuseLine(f: CName) -> String {
  if Equals(f, n"Valentinos") { return CBLineOf(["No tengo nada para ti. Walk.", "You don't talk to family like you've earned it.", "Not one word, pendejo."]); }
  if Equals(f, n"TygerClaws") { return CBLineOf(["You can't afford my time.", "Talk costs. You're broke to me.", "Make an appointment. Never."]); }
  if Equals(f, n"Maelstrom") { return CBLineOf(["Talk's for meat. Move.", "I don't talk to you. I take from you.", "Your voice is ugly. Shut it."]); }
  if Equals(f, n"SixthStreet") { return CBLineOf(["Move along, merc.", "Nothing to discuss. Keep walking.", "You're not cleared to talk to me."]); }
  if Equals(f, n"Animals") { return CBLineOf(["Words are for the weak.", "Talk to my fists.", "Not interested. Walk."]); }
  if Equals(f, n"VoodooBoys") { return CBLineOf(["We have nothing to say to you.", "You're not worth the bandwidth.", "Go. The Net's watching you."]); }
  if Equals(f, n"Mox") { return CBLineOf(["Not talking to you, sweetie.", "You lost the right to talk to us.", "Keep walking."]); }
  if Equals(f, n"Scavengers") { return CBLineOf(["What, you want a discount on your kidneys?", "Talk's cheap. You're not.", "Beat it."]); }
  if Equals(f, n"Wraiths") { return CBLineOf(["Road's this way. Take it.", "Nothing to say to you.", "Get lost, desert's big enough."]); }
  if Equals(f, n"Aldecaldos") { return CBLineOf(["Not now. Not to you.", "You know what you did.", "Family doesn't talk to you anymore."]); }
  if Equals(f, n"Barghest") { return CBLineOf(["Move along, civilian.", "No comment.", "This conversation is over before it started."]); }
  return "";
}

// Their scout stopped answering (CBScoutSilenced).
public func CBGangScoutLostLine(f: CName) -> String {
  if Equals(f, n"Valentinos") { return CBLineOf(["Our hermano stopped answering. We'll find you another way.", "You took our eyes. The family still sees."]); }
  if Equals(f, n"TygerClaws") { return CBLineOf(["Our man went quiet. Costly for you, later.", "Lost a scout. We have more money than you have luck."]); }
  if Equals(f, n"Maelstrom") { return CBLineOf(["Spotter's offline. We'll track you by your chrome.", "Killed our eyes? We'll grow new ones."]); }
  if Equals(f, n"SixthStreet") { return CBLineOf(["Lost contact with our recon. We'll regroup.", "Scout's down. Doesn't matter. We'll find you."]); }
  if Equals(f, n"Animals") { return CBLineOf(["Our guy's not answering. Lucky you. For now.", "You got our boy. Next one's bigger."]); }
  if Equals(f, n"VoodooBoys") { return CBLineOf(["You cut one thread. The web is still here.", "Our eyes went dark. The Net didn't."]); }
  if Equals(f, n"Mox") { return CBLineOf(["She stopped answering. You'd better pray she's alright.", "Lost our lookout. We'll be back."]); }
  if Equals(f, n"Scavengers") { return CBLineOf(["Lost our guy. Whatever, there's always another.", "He's not answering. More parts for us, then."]); }
  if Equals(f, n"Wraiths") { return CBLineOf(["Rider's gone quiet. The road remembers you.", "Lost our spotter. Desert's still ours."]); }
  if Equals(f, n"Aldecaldos") { return CBLineOf(["Our cousin's not answering. If he's hurt, you'll answer for it.", "Lost our scout. We'll find you."]); }
  if Equals(f, n"Barghest") { return CBLineOf(["Recon unit lost. Adjusting.", "Forward observer down. Mission continues."]); }
  return "";
}

// Hands up, in their own words (Spawn/LivingStreet.reds, TrySurrender).
public func CBGangSurrenderLine(f: CName) -> String {
  if Equals(f, n"Valentinos") { return CBLineOf(["Okay! Okay. I yield, on my mother.", "Basta! It's over, I'm done!", "Por favor! I give up!"]); }
  if Equals(f, n"TygerClaws") { return CBLineOf(["Enough! I'll pay you, just stop!", "I yield! Bad business, this!", "Stop! You win, you win!"]); }
  if Equals(f, n"Maelstrom") { return CBLineOf(["Fine! Fine! Take whatever, I'm out!", "My chrome's fried, I'm done!", "Don't scrap me! I quit!"]); }
  if Equals(f, n"SixthStreet") { return CBLineOf(["I'm out! Hands where you can see them!", "Stand down, stand down! I'm done!", "Surrendering! Don't shoot!"]); }
  if Equals(f, n"Animals") { return CBLineOf(["Okay, you're stronger! I'm done!", "Enough! You win this one!"]); }
  if Equals(f, n"VoodooBoys") { return CBLineOf(["I'm disconnecting! I'm out!", "Enough! You've made your point!", "Stop! I yield!"]); }
  if Equals(f, n"Mox") { return CBLineOf(["Okay! Okay, I'm done, please!", "I give up! Don't hurt me!", "Enough! I'm out of this!"]); }
  if Equals(f, n"Scavengers") { return CBLineOf(["Don't shoot! I'll go, I'll go!", "Okay! Take the parts, I'm out!", "Please! I'm done!"]); }
  if Equals(f, n"Wraiths") { return CBLineOf(["Alright! Road's yours! I'm done!", "Enough! I give!"]); }
  if Equals(f, n"Aldecaldos") { return CBLineOf(["Okay! For the family's sake, I'm done!", "Stop! I yield, I yield!"]); }
  return CBPick3("Okay! Okay! I'm done!", "Don't shoot! I give up!", "Enough! It's over, I'm out!");
}

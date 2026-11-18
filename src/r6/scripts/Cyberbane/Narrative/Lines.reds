// Cyberbane - The line library (2.3.1)
//
// Everything somebody says in Cyberbane is picked here: an overheard line, a passer-by's answer in talk,
// a ganger's warning, a rumour, a text. Each place that speaks still writes its own lines, whole, for
// who is speaking and what has just happened; this is how one of them is chosen, and how the street
// keeps from saying the same thing twice.
//
// What the old picker did was keep one index, shared by every list in the mod, and nudge a roll off it.
// So two lists of three lines could still land the same sentence twice running, and a line heard a
// minute before could come straight back as long as it was not the very last one. Now:
//
//   - The street remembers what it has said lately: the last LineMemory lines that reached the screen,
//     from anybody, in any form (a subtitle, an overheard line, a text). A pick steers away from all
//     of them, and only when every option was heard lately does it take the one heard longest ago.
//   - A line is remembered when it is shown, never when it is built. A whisper builds a dozen
//     candidates and shows one; only the one shown is something anybody heard (CBLineHeard, called
//     from the three doors in UI/PhoneMessages.reds).
//
// What the moment is (the hour, the rain, V bleeding or fresh from a fight, the district's temper, a
// place that remembers) is read once into the street read (Model/StreetRead.reds), and each builder
// chooses from it.

// One of these, steering clear of anything said lately.
public func CBLineOf(options: array<String>) -> String {
  let n = ArraySize(options);
  if n == 0 {
    return "";
  }
  if n == 1 {
    return options[0];
  }
  let rt = CyberbaneRuntime.Get();
  let start = RandRange(0, n);
  let i = 0;
  while i < n {
    let line = options[(start + i) % n];
    if !IsDefined(rt) || !rt.SaidLately(line) {
      return line;
    }
    i += 1;
  }
  return rt.HeardLongestAgo(options);
}

public func CBPick2(a: String, b: String) -> String {
  return CBLineOf([a, b]);
}

public func CBPick3(a: String, b: String, c: String) -> String {
  return CBLineOf([a, b, c]);
}

public func CBPick4(a: String, b: String, c: String, d: String) -> String {
  return CBLineOf([a, b, c, d]);
}

// Somebody said this, on screen. Called by the doors every line goes out through.
public func CBLineHeard(line: String) -> Void {
  if StrLen(line) == 0 {
    return;
  }
  let rt = CyberbaneRuntime.Get();
  if IsDefined(rt) {
    rt.NoteSaid(line);
  }
}

// The lines on offer for one moment, each with what it is about and how much it is worth saying.
//
// Topic-weighted, so what V is doing right now outweighs what V is known for, and the topic the last
// line was about sits the next one out while anything else is on offer (1.9.5). A line heard lately is
// worth a fraction of its weight, so the bag moves on from it without ever running dry.
public class CBLineBag {
  public let lines: array<String>;
  public let topics: array<CName>;
  public let weights: array<Float>;

  public func Add(topic: CName, weight: Float, line: String) -> Void {
    if weight <= 0.0 || StrLen(line) == 0 {
      return;
    }
    let rt = CyberbaneRuntime.Get();
    if IsDefined(rt) && rt.SaidLately(line) {
      weight *= CBConfig.LineHeardWeight();
    }
    ArrayPush(this.lines, line);
    ArrayPush(this.topics, topic);
    ArrayPush(this.weights, weight);
  }

  public func Size() -> Int32 {
    return ArraySize(this.lines);
  }

  // A weighted draw, leaving out whatever the last line was about while anything else is on offer.
  public func Pick(lastTopic: CName) -> Int32 {
    let n = Min(ArraySize(this.lines), Min(ArraySize(this.topics), ArraySize(this.weights)));
    let total = 0.0;
    let others = 0;
    let i = 0;
    while i < n {
      if NotEquals(this.topics[i], lastTopic) {
        total += this.weights[i];
        others += 1;
      }
      i += 1;
    }
    let skipLast = others > 0;
    if !skipLast {
      total = 0.0;
      i = 0;
      while i < n {
        total += this.weights[i];
        i += 1;
      }
    }
    if total <= 0.0 {
      return -1;
    }
    let roll = RandRangeF(0.0, total);
    i = 0;
    while i < n {
      if !skipLast || NotEquals(this.topics[i], lastTopic) {
        roll -= this.weights[i];
        if roll <= 0.0 {
          return i;
        }
      }
      i += 1;
    }
    return n - 1;
  }
}

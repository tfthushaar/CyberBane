// Cyberbane - Rival name pools & epithets (spec Appendix I)
//
// Names are stored on a Rival as integer indices into these pools (no String in
// persistent fields). Handle-only factions have no surnames. ASCII only, so the
// strings survive any encoding round-trip.

public func CBSeedNames(c: ref<CyberbaneContent>) -> Void {
  // Two rules for these lists:
  //   - Only ever add to the end. A Rival is saved as a position in the list, so putting a name
  //     anywhere else, or taking one out, renames every Rival after it in every save.
  //   - Keep a gang's two lists at different lengths. A Rival's first guess at a name is arithmetic
  //     on its number, and two lists of one length only make as many first guesses as one has names.
  // No names of the game's own characters: a stranger called the same as somebody in the story
  // reads as that person.
  let copFirst = ["Marcus", "Dana", "Elliot", "Rosa", "Tyler", "Hal", "June", "Ivan", "Priya", "Owen",
                  "Terrence", "Gwen", "Sam", "Lourdes", "Nate", "Bea", "Curtis"];
  let copLast = ["Reyes", "Okafor", "Vasquez", "Delgado", "Brennan", "Park", "Whitfield", "Nguyen",
                 "Castellano", "Abara", "Doyle", "Mwangi", "Sorensen"];
  // Cops and corps had no pool at all, so every Rival from them came out as "Unknown".
  // They use real names rather than street handles.
  c.AddFactionNames(CBMakeFactionNames(n"NCPD", copFirst, copLast));
  c.AddFactionNames(CBMakeFactionNames(n"Police", copFirst, copLast));
  c.AddFactionNames(CBMakeFactionNames(n"Arasaka",
    ["Hiroshi", "Yuki", "Kenzo", "Mariko", "Takeda", "Noboru", "Sayuri", "Masato", "Ayane", "Shinji",
     "Kiyomi", "Isao", "Reiko", "Tetsuo", "Natsuko", "Yoshiro", "Hanae"],
    ["Oshima", "Nakai", "Fujimoto", "Arakawa", "Kobayashi", "Tachibana", "Miura", "Ueda", "Hasegawa",
     "Kondo", "Sakai", "Nomura", "Iwata"]));
  c.AddFactionNames(CBMakeFactionNames(n"Militech",
    ["Grant", "Dallas", "Vera", "Cole", "Shane", "Reid", "Morgan", "Blair", "Logan", "Sloan",
     "Quentin", "Regan", "Harper", "Drew", "Nash", "Tessa", "Bryce"],
    ["Hollister", "Pryce", "Kowalski", "Ramsey", "Whitlock", "Stanton", "Mallory", "Drummond",
     "Kincaid", "Sawyer", "Thorne", "Lockhart", "Voss"]));
  c.AddFactionNames(CBMakeFactionNames(n"KangTao",
    ["Wei", "Lian", "Jun", "Mei", "Bohai", "Feng", "Xiu", "Tao", "Yan", "Haoran",
     "Ning", "Zihan", "Qing", "Shen", "Ruolan", "Kai", "Yifei"],
    ["Zhao", "Ling", "Xu", "Chen", "Wang", "Liu", "Huang", "Zhou", "Wu", "Gao", "Luo", "Tang", "Deng"]));
  c.AddFactionNames(CBMakeFactionNames(n"Aldecaldos",
    ["Santiago", "Paloma", "Esteban", "Luz", "Mateo", "Rosario", "Joaquin", "Ximena", "Ruben", "Alma",
     "Gael", "Marta", "Ignacio", "Soledad", "Dario", "Elena", "Nico", "Tomasa", "Hugo", "Consuelo",
     "Felix", "Inez", "Lorenzo"],
    ["Ibarra", "Cortes", "Mendoza", "Rivas", "Cardenas", "Solis", "Montoya", "Pacheco", "Sandoval",
     "Trujillo", "Arroyo", "Campos", "Duran", "Escobar", "Galindo", "Lozano", "Medina", "Osorio", "Tapia"]));

  c.AddFactionNames(CBMakeFactionNames(n"TygerClaws",
    ["Kenji", "Haru", "Daisuke", "Aiko", "Ren", "Akira", "Sora", "Naoki", "Ryo", "Yuna",
     "Kaito", "Mei", "Shun", "Emi", "Hayato", "Rin", "Tatsuya", "Nao", "Kazuki", "Saki",
     "Jiro", "Koji", "Mio"],
    ["Morita", "Sato", "Kuroda", "Ishikawa", "Hayashi", "Mori", "Tanaka", "Nishida", "Kimura", "Aoki",
     "Fujita", "Shimizu", "Endo", "Ogawa", "Yamane", "Hoshino", "Kubo", "Taniguchi", "Inoue"]));

  c.AddFactionNames(CBMakeFactionNames(n"Valentinos",
    ["Mateo", "Lupe", "Rafael", "Ines", "Santiago", "Diego", "Carmen", "Alejandro", "Marisol", "Hector",
     "Ximena", "Emilio", "Paz", "Joaquin", "Dolores", "Ramon", "Yolanda", "Cesar", "Alma", "Tomas",
     "Nayeli", "Beto", "Reina"],
    ["Ortega", "Vargas", "Delgado", "Cruz", "Morales", "Salazar", "Fuentes", "Herrera", "Castillo",
     "Navarro", "Ruiz", "Quintero", "Aguilar", "Mejia", "Cabrera", "Zamora", "Luna", "Trevino", "Bautista"]));

  c.AddFactionNames(CBMakeFactionNames(n"SixthStreet",
    ["Cody", "Travis", "Dana", "Wade", "Brooke", "Hank", "Colt", "Reese", "Mason", "Tanner",
     "Kayla", "Dale", "Shelby", "Garrett", "Jolene", "Clint", "Riley", "Boyd", "Darla", "Hunter",
     "Lacey", "Vern", "Tucker"],
    ["Hollis", "McCray", "Barnes", "Tate", "Dawson", "Pruitt", "Whitaker", "Cobb", "Riggs", "Mercer",
     "Sutter", "Lowry", "Boone", "Crane", "Haskell", "Pickett", "Yates", "Stroud", "Garner"]));

  c.AddFactionNames(CBMakeFactionNames(n"VoodooBoys",
    ["Jean", "Mirlande", "Placid", "Fabienne", "Emmanuel", "Widline", "Frantz", "Nadege", "Wilner", "Guerline",
     "Dieudonne", "Marjorie", "Jacques", "Roseline", "Evens", "Islande", "Ricot", "Yolette", "Stanley",
     "Mackenson", "Darline", "Jude", "Sabine"],
    ["Duval", "Toussaint", "Celestin", "Baptiste", "Joseph", "Pierre", "Charles", "Desir", "Etienne",
     "Francois", "Louissaint", "Augustin", "Dorval", "Laguerre", "Metellus", "Philippe", "Alexis", "Cadet", "Noel"]));

  c.AddFactionNames(CBMakeFactionNames(n"Mox",
    ["Tess", "Coral", "Dex", "Jo", "Roxy", "Billie", "Sky", "Frankie", "Lux", "Marlowe",
     "Ash", "Vee", "Sloane", "Piper", "Remy", "Kit", "Harlow", "Nova", "Bex", "Indie",
     "Cass", "Zia", "Wren"],
    ["Lane", "Rivera", "Shaw", "Monroe", "Vale", "Holloway", "Quinn", "Sinclair", "Moreau", "Blake",
     "Carver", "Hart", "Lennox", "Reyes", "Ward", "Cruz", "Bell", "Sterling", "Dane"]));

  c.AddFactionNames(CBMakeFactionNames(n"Barghest",
    ["Viktor", "Aleks", "Jonas", "Mira", "Dragan", "Yusuf", "Katya", "Omar", "Ilya", "Nadia",
     "Emre", "Tarek", "Sasha", "Lena", "Goran", "Zara", "Milos", "Anton", "Rania", "Stefan",
     "Dimitri", "Samir", "Irina"],
    ["Kessler", "Brandt", "Novak", "Haddad", "Petrov", "Vogel", "Demir", "Sokolov", "Weber", "Marek",
     "Rahimi", "Kovac", "Lang", "Mansour", "Horvat", "Schiller", "Antonov", "Yilmaz", "Bauer"]));

  // Handle-only factions.
  c.AddFactionNames(CBMakeHandleNames(n"Maelstrom",
    ["Static", "Rustbite", "Nullwire", "Shardjaw", "Flatscan", "Hexrot", "Ironlung", "Deadpixel", "Chromeskull",
     "Wirehead", "Bitrot", "Kernel", "Scrapcode", "Voidtooth", "Burnout", "Overclock", "Sparkplug", "Gearrot",
     "Corrode", "Blackscreen", "Feedback", "Solder", "Cathode"]));
  c.AddFactionNames(CBMakeHandleNames(n"Animals",
    ["Bullneck", "Tusk", "Brickhouse", "Anvil", "Mastodon", "Ironjaw", "Slab", "Hogtie", "Boar", "Bison",
     "Knuckles", "Tank", "Gristle", "Grizzly", "Bulldozer", "Sledge", "Meathook", "Crusher", "Haunch", "Ox",
     "Mauler", "Gorilla", "Stampede"]));
  c.AddFactionNames(CBMakeHandleNames(n"Scavengers",
    ["Gutter", "Scalpel", "Tin", "Ragpicker", "Bonesaw", "Stitch", "Cutter", "Harvest", "Leech", "Scrap",
     "Vulture", "Rust", "Organ", "Forceps", "Tongs", "Magpie", "Junker", "Hacksaw", "Sawbones", "Maggot",
     "Clamp", "Tourniquet", "Spare Parts"]));
  c.AddFactionNames(CBMakeHandleNames(n"Wraiths",
    ["Dustdevil", "Rattler", "Bonefire", "Sidewinder", "Sunburn", "Mirage", "Coyote", "Stinger", "Buzzard",
     "Drywell", "Hardpan", "Tumbleweed", "Gila", "Saltflat", "Sandstorm", "Cinder", "Dune", "Jackal", "Vagrant",
     "Arroyo", "Mesquite", "Dry Gulch", "Heatstroke"]));

  // A name is never given out twice in a save, so a gang with one list needs far more than one list
  // can reasonably hold. These run after the handles above. To add more, add another call after these
  // four, because a word added to one of these lists moves every name built after it.
  CBAddCompoundHandles(c, n"Maelstrom",
    ["Chrome", "Rust", "Null", "Hex", "Bit", "Void", "Slag", "Wire", "Glitch", "Scrap", "Arc", "Fuse"],
    ["bite", "jaw", "rot", "skull", "tooth", "lung", "spine", "socket", "gut", "vein"]);
  CBAddCompoundHandles(c, n"Animals",
    ["Iron", "Bull", "Brick", "Slab", "Hog", "Ox", "Tusk", "Granite", "Hammer", "Thick", "Mule", "Rhino"],
    ["neck", "jaw", "back", "fist", "shoulder", "knee", "skull", "hide", "gut", "horn"]);
  CBAddCompoundHandles(c, n"Scavengers",
    ["Bone", "Scrap", "Gut", "Rag", "Tin", "Rust", "Skin", "Flesh", "Vein", "Marrow", "Needle", "Sinew"],
    ["saw", "picker", "hook", "cutter", "stitch", "knife", "jar", "thief", "tongs", "peeler"]);
  CBAddCompoundHandles(c, n"Wraiths",
    ["Dust", "Sand", "Salt", "Bone", "Sun", "Dry", "Ash", "Thorn", "Flint", "Rattle", "Burn", "Scorch"],
    ["devil", "wind", "runner", "fang", "snake", "back", "claw", "mouth", "walker", "crow"]);

  // How long each list was before 1.7.7. These numbers never change: they mark the names that may
  // already have been somebody in a save, before saves kept a record of them.
  c.MarkOldNames(n"NCPD", 5, 5);
  c.MarkOldNames(n"Police", 5, 5);
  c.MarkOldNames(n"Arasaka", 5, 4);
  c.MarkOldNames(n"Militech", 5, 4);
  c.MarkOldNames(n"KangTao", 5, 4);
  c.MarkOldNames(n"Aldecaldos", 5, 4);
  c.MarkOldNames(n"TygerClaws", 5, 4);
  c.MarkOldNames(n"Valentinos", 5, 4);
  c.MarkOldNames(n"SixthStreet", 5, 4);
  c.MarkOldNames(n"VoodooBoys", 4, 3);
  c.MarkOldNames(n"Mox", 4, 3);
  c.MarkOldNames(n"Barghest", 4, 3);
  c.MarkOldNames(n"Maelstrom", 4, 0);
  c.MarkOldNames(n"Animals", 3, 0);
  c.MarkOldNames(n"Scavengers", 3, 0);
  c.MarkOldNames(n"Wraiths", 3, 0);

  // Epithets by Rival source + promotion. Added to at the end only, as above.
  let e = new CBEpithets();
  // 1.8.5 added the second line of each, at the end, so every Rival who already has one keeps it.
  e.survivor = ["Who Ran", "the Survivor", "Last One Standing", "Still Breathing", "Lucky", "Cockroach",
                "Nine Lives", "the Getaway", "Not Today", "Long Shot", "Walked Away", "Patched Up", "Bad Penny",
                "Slippery", "Ghost Step", "Close Call", "Half-Dead", "Stitches", "Second Wind", "Rabbit",
                "Back Door", "Fire Escape", "Scar Tissue", "Escape Artist", "Near Miss", "Quickstep",
                "Sewer Rat", "Runaway", "Sixth Life", "Dodger", "Blood Trail", "Hard Case", "Leftover",
                "Tourniquet", "Gone Ghost"];
  e.spared = ["the Humbled", "Second Chance", "Iron Jaw", "Owes You", "Let Go", "Borrowed Time",
              "the Mercy Case", "Kneeler", "On Notice", "Grudge", "Turned Loose",
              "Pardoned", "the Forgiven", "Bent Knee", "Sore Loser", "Bruised Pride", "Paper Tiger",
              "Lost Face", "Stood Down", "Grace Period", "Clean Slate", "the Reprieve", "Charity Case",
              "Spit Blood", "Glass Jaw", "Ground Floor", "Small Mercy", "Paroled", "Bad Memory",
              "Unfinished", "Proud Again", "Sleepless", "Shoulder Chip"];
  e.killer = ["V-Killer", "the Undertaker", "Flatline", "Gravedigger", "Last Face", "Zero Count",
              "Toe Tag", "the Closer", "Lights Out", "Body Bag", "Final Word",
              "Executioner", "the Reaper", "Coffin Nail", "Morgue Ticket", "Dead Air", "Endgame",
              "the Mortician", "Six Feet", "Cold Hands", "Headstone", "Tombstone", "Black Bag",
              "Last Rites", "Wake Call", "Ashes", "Bone Saw", "Grim", "Hearse", "Requiem", "Coroner",
              "Eulogy", "Kill Count"];
  e.avenger = ["Bloodsworn", "the Avenger", "Blood Debt", "the Reckoning", "Payback", "Oathbound",
               "Widowmaker", "Eye for an Eye", "Black Armband", "Settling Up", "Next of Kin", "Vendetta", "Unforgiven",
               "Blood Price", "Scarred Oath", "Hold Fast", "Ember", "the Mourner", "Grudgebound",
               "Debt Collector", "Red Ledger", "Grave Oath", "Burning Bridge", "Last Wish", "Ironclad",
               "Tears Dry", "Hell Bent", "No Mercy", "Wildfire", "Tenfold", "Back Pay", "Cold Comfort",
               "Heartbreak", "Sworn", "Salt Wound"];
  e.hunter = ["the Hound", "Bounty", "Tracker", "Bloodhound", "Long Arm", "the Collector", "Contract",
              "Headhunter", "Pointman", "Sniffer", "Repo",
              "Trigger", "Scope", "Bird Dog", "Night Owl", "the Ferret", "Lockjaw", "Leash", "Snare",
              "Steel Trap", "Fetch", "Tailgate", "Shadow", "Crosshair", "Spotter", "Packwolf",
              "Bounty Board", "Tagger", "Gunsight", "Homing", "Sure Shot", "Posse", "Manhunter"];
  e.promotion = ["Twice-Burned", "the Unbroken", "Scarface"];
  c.SetEpithets(e);
}

// Every head with every tail, onto the end of a gang's list, leaving out any it already has.
func CBAddCompoundHandles(c: ref<CyberbaneContent>, faction: CName, heads: array<String>, tails: array<String>) -> Void {
  let pool = c.GetFactionNames(faction);
  if !IsDefined(pool) {
    return;
  }
  for head in heads {
    for tail in tails {
      let handle = head + tail;
      if !ArrayContains(pool.firstNames, handle) {
        ArrayPush(pool.firstNames, handle);
      }
    }
  }
}

// Cyberbane - Rival name pools & epithets (spec Appendix I)
//
// Names are stored on a Rival as integer indices into these pools (no String in
// persistent fields). Handle-only factions have no surnames. ASCII only, so the
// strings survive any encoding round-trip.

public func CBSeedNames(c: ref<CyberbaneContent>) -> Void {
  // Two rules for these lists:
  //   - Only ever add to the end. A Rival is saved as a position in the list, so putting a name
  //     anywhere else, or taking one out, renames every Rival after it in every save.
  //   - Keep a gang's two lists at different prime lengths. The pick walks both lists in step, so
  //     two lists of the same length only ever make as many pairs as one of them has names.
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

  // Epithets by Rival source + promotion. Added to at the end only, as above.
  let e = new CBEpithets();
  e.survivor = ["Who Ran", "the Survivor", "Last One Standing", "Still Breathing", "Lucky", "Cockroach",
                "Nine Lives", "the Getaway", "Not Today", "Long Shot", "Walked Away", "Patched Up", "Bad Penny"];
  e.spared = ["the Humbled", "Second Chance", "Iron Jaw", "Owes You", "Let Go", "Borrowed Time",
              "the Mercy Case", "Kneeler", "On Notice", "Grudge", "Turned Loose"];
  e.killer = ["V-Killer", "the Undertaker", "Flatline", "Gravedigger", "Last Face", "Zero Count",
              "Toe Tag", "the Closer", "Lights Out", "Body Bag", "Final Word"];
  e.avenger = ["Bloodsworn", "the Avenger", "Blood Debt", "the Reckoning", "Payback", "Oathbound",
               "Widowmaker", "Eye for an Eye", "Black Armband", "Settling Up", "Next of Kin", "Vendetta", "Unforgiven"];
  e.hunter = ["the Hound", "Bounty", "Tracker", "Bloodhound", "Long Arm", "the Collector", "Contract",
              "Headhunter", "Pointman", "Sniffer", "Repo"];
  e.promotion = ["Twice-Burned", "the Unbroken", "Scarface"];
  c.SetEpithets(e);
}

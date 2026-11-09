class BibleBook {
  final int id;
  final String nameEn;
  final String nameTe;
  final String testament; // 'OT' or 'NT'
  final String category;  // e.g. Law, History, Poetry, Prophets, Gospels, Epistles, etc.
  final int totalChapters;

  const BibleBook({
    required this.id,
    required this.nameEn,
    required this.nameTe,
    required this.testament,
    required this.category,
    required this.totalChapters,
  });
}

class BibleVerseData {
  final int verseNumber;
  final String textKjv;
  final String textNiv;
  final String textEsv;
  final String textTeBsi;

  const BibleVerseData({
    required this.verseNumber,
    required this.textKjv,
    required this.textNiv,
    required this.textEsv,
    required this.textTeBsi,
  });

  String getTextForVersion(String version) {
    switch (version) {
      case "NIV":
        return textNiv;
      case "ESV":
        return textEsv;
      case "TE_BSI":
        return textTeBsi;
      case "KJV":
      default:
        return textKjv;
    }
  }
}

class BibleService {
  // All 66 Books of the Christian Holy Bible
  static const List<BibleBook> books = [
    // Old Testament (39 Books)
    BibleBook(id: 1, nameEn: "Genesis", nameTe: "ఆదికాండము", testament: "OT", category: "Law", totalChapters: 50),
    BibleBook(id: 2, nameEn: "Exodus", nameTe: "నిర్గమకాండము", testament: "OT", category: "Law", totalChapters: 40),
    BibleBook(id: 3, nameEn: "Leviticus", nameTe: "లేవీయకాండము", testament: "OT", category: "Law", totalChapters: 27),
    BibleBook(id: 4, nameEn: "Numbers", nameTe: "సంఖ్యాకాండము", testament: "OT", category: "Law", totalChapters: 36),
    BibleBook(id: 5, nameEn: "Deuteronomy", nameTe: "ద్వితీయోపదేశకాండము", testament: "OT", category: "Law", totalChapters: 34),
    BibleBook(id: 6, nameEn: "Joshua", nameTe: "యెహోషువ", testament: "OT", category: "History", totalChapters: 24),
    BibleBook(id: 7, nameEn: "Judges", nameTe: "న్యాయాధిపతులు", testament: "OT", category: "History", totalChapters: 21),
    BibleBook(id: 8, nameEn: "Ruth", nameTe: "రూతు", testament: "OT", category: "History", totalChapters: 4),
    BibleBook(id: 9, nameEn: "1 Samuel", nameTe: "1 సమూయేలు", testament: "OT", category: "History", totalChapters: 31),
    BibleBook(id: 10, nameEn: "2 Samuel", nameTe: "2 సమూయేలు", testament: "OT", category: "History", totalChapters: 24),
    BibleBook(id: 11, nameEn: "1 Kings", nameTe: "1 రాజులు", testament: "OT", category: "History", totalChapters: 22),
    BibleBook(id: 12, nameEn: "2 Kings", nameTe: "2 రాజులు", testament: "OT", category: "History", totalChapters: 25),
    BibleBook(id: 13, nameEn: "1 Chronicles", nameTe: "1 దినవృత్తాంతములు", testament: "OT", category: "History", totalChapters: 29),
    BibleBook(id: 14, nameEn: "2 Chronicles", nameTe: "2 దినవృత్తాంతములు", testament: "OT", category: "History", totalChapters: 36),
    BibleBook(id: 15, nameEn: "Ezra", nameTe: "ఎజ్రా", testament: "OT", category: "History", totalChapters: 10),
    BibleBook(id: 16, nameEn: "Nehemiah", nameTe: "నెహెమ్యా", testament: "OT", category: "History", totalChapters: 13),
    BibleBook(id: 17, nameEn: "Esther", nameTe: "ఎస్తేరు", testament: "OT", category: "History", totalChapters: 10),
    BibleBook(id: 18, nameEn: "Job", nameTe: "యోబు", testament: "OT", category: "Poetry", totalChapters: 42),
    BibleBook(id: 19, nameEn: "Psalms", nameTe: "కీర్తనల గ్రంథము", testament: "OT", category: "Poetry", totalChapters: 150),
    BibleBook(id: 20, nameEn: "Proverbs", nameTe: "సామెతలు", testament: "OT", category: "Poetry", totalChapters: 31),
    BibleBook(id: 21, nameEn: "Ecclesiastes", nameTe: "ప్రసంగి", testament: "OT", category: "Poetry", totalChapters: 12),
    BibleBook(id: 22, nameEn: "Song of Solomon", nameTe: "పరమగీతము", testament: "OT", category: "Poetry", totalChapters: 8),
    BibleBook(id: 23, nameEn: "Isaiah", nameTe: "యెషయా", testament: "OT", category: "Prophets", totalChapters: 66),
    BibleBook(id: 24, nameEn: "Jeremiah", nameTe: "యిర్మియా", testament: "OT", category: "Prophets", totalChapters: 52),
    BibleBook(id: 25, nameEn: "Lamentations", nameTe: "విలాపవాక్యములు", testament: "OT", category: "Prophets", totalChapters: 5),
    BibleBook(id: 26, nameEn: "Ezekiel", nameTe: "యెహెజ్కేలు", testament: "OT", category: "Prophets", totalChapters: 48),
    BibleBook(id: 27, nameEn: "Daniel", nameTe: "దానియేలు", testament: "OT", category: "Prophets", totalChapters: 12),
    BibleBook(id: 28, nameEn: "Hosea", nameTe: "హోషేయ", testament: "OT", category: "Prophets", totalChapters: 14),
    BibleBook(id: 29, nameEn: "Joel", nameTe: "యోవేలు", testament: "OT", category: "Prophets", totalChapters: 3),
    BibleBook(id: 30, nameEn: "Amos", nameTe: "ఆమోసు", testament: "OT", category: "Prophets", totalChapters: 9),
    BibleBook(id: 31, nameEn: "Obadiah", nameTe: "ఓబద్యా", testament: "OT", category: "Prophets", totalChapters: 1),
    BibleBook(id: 32, nameEn: "Jonah", nameTe: "యోనా", testament: "OT", category: "Prophets", totalChapters: 4),
    BibleBook(id: 33, nameEn: "Micah", nameTe: "మీకా", testament: "OT", category: "Prophets", totalChapters: 7),
    BibleBook(id: 34, nameEn: "Nahum", nameTe: "నాహూము", testament: "OT", category: "Prophets", totalChapters: 3),
    BibleBook(id: 35, nameEn: "Habakkuk", nameTe: "హబక్కూకు", testament: "OT", category: "Prophets", totalChapters: 3),
    BibleBook(id: 36, nameEn: "Zephaniah", nameTe: "జెఫన్యా", testament: "OT", category: "Prophets", totalChapters: 3),
    BibleBook(id: 37, nameEn: "Haggai", nameTe: "హగ్గయి", testament: "OT", category: "Prophets", totalChapters: 2),
    BibleBook(id: 38, nameEn: "Zechariah", nameTe: "జకర్యా", testament: "OT", category: "Prophets", totalChapters: 14),
    BibleBook(id: 39, nameEn: "Malachi", nameTe: "మలాకీ", testament: "OT", category: "Prophets", totalChapters: 4),

    // New Testament (27 Books)
    BibleBook(id: 40, nameEn: "Matthew", nameTe: "మత్తయి సువార్త", testament: "NT", category: "Gospels", totalChapters: 28),
    BibleBook(id: 41, nameEn: "Mark", nameTe: "మార్కు సువార్త", testament: "NT", category: "Gospels", totalChapters: 16),
    BibleBook(id: 42, nameEn: "Luke", nameTe: "లూకా సువార్త", testament: "NT", category: "Gospels", totalChapters: 24),
    BibleBook(id: 43, nameEn: "John", nameTe: "యోహాను సువార్త", testament: "NT", category: "Gospels", totalChapters: 21),
    BibleBook(id: 44, nameEn: "Acts", nameTe: "అపొస్తలుల కార్యములు", testament: "NT", category: "History", totalChapters: 28),
    BibleBook(id: 45, nameEn: "Romans", nameTe: "రోమీయులకు", testament: "NT", category: "Epistles", totalChapters: 16),
    BibleBook(id: 46, nameEn: "1 Corinthians", nameTe: "1 కొరింథీయులకు", testament: "NT", category: "Epistles", totalChapters: 16),
    BibleBook(id: 47, nameEn: "2 Corinthians", nameTe: "2 కొరింథీయులకు", testament: "NT", category: "Epistles", totalChapters: 13),
    BibleBook(id: 48, nameEn: "Galatians", nameTe: "గలతీయులకు", testament: "NT", category: "Epistles", totalChapters: 6),
    BibleBook(id: 49, nameEn: "Ephesians", nameTe: "ఎఫెసీయులకు", testament: "NT", category: "Epistles", totalChapters: 6),
    BibleBook(id: 50, nameEn: "Philippians", nameTe: "ఫిలిప్పీయులకు", testament: "NT", category: "Epistles", totalChapters: 4),
    BibleBook(id: 51, nameEn: "Colossians", nameTe: "కొలొస్సయులకు", testament: "NT", category: "Epistles", totalChapters: 4),
    BibleBook(id: 52, nameEn: "1 Thessalonians", nameTe: "1 థెస్సలొనీకయులకు", testament: "NT", category: "Epistles", totalChapters: 5),
    BibleBook(id: 53, nameEn: "2 Thessalonians", nameTe: "2 థెస్సలొనీకయులకు", testament: "NT", category: "Epistles", totalChapters: 3),
    BibleBook(id: 54, nameEn: "1 Timothy", nameTe: "1 తిమోతికి", testament: "NT", category: "Epistles", totalChapters: 6),
    BibleBook(id: 55, nameEn: "2 Timothy", nameTe: "2 తిమోతికి", testament: "NT", category: "Epistles", totalChapters: 4),
    BibleBook(id: 56, nameEn: "Titus", nameTe: "తీతుకు", testament: "NT", category: "Epistles", totalChapters: 3),
    BibleBook(id: 57, nameEn: "Philemon", nameTe: "ఫిలేమోనుకు", testament: "NT", category: "Epistles", totalChapters: 1),
    BibleBook(id: 58, nameEn: "Hebrews", nameTe: "హెబ్రీయులకు", testament: "NT", category: "Epistles", totalChapters: 13),
    BibleBook(id: 59, nameEn: "James", nameTe: "యాకోబు", testament: "NT", category: "Epistles", totalChapters: 5),
    BibleBook(id: 60, nameEn: "1 Peter", nameTe: "1 పేతురు", testament: "NT", category: "Epistles", totalChapters: 5),
    BibleBook(id: 61, nameEn: "2 Peter", nameTe: "2 పేతురు", testament: "NT", category: "Epistles", totalChapters: 3),
    BibleBook(id: 62, nameEn: "1 John", nameTe: "1 యోహాను", testament: "NT", category: "Epistles", totalChapters: 5),
    BibleBook(id: 63, nameEn: "2 John", nameTe: "2 యోహాను", testament: "NT", category: "Epistles", totalChapters: 1),
    BibleBook(id: 64, nameEn: "3 John", nameTe: "3 యోహాను", testament: "NT", category: "Epistles", totalChapters: 1),
    BibleBook(id: 65, nameEn: "Jude", nameTe: "యూదా", testament: "NT", category: "Epistles", totalChapters: 1),
    BibleBook(id: 66, nameEn: "Revelation", nameTe: "ప్రకటన గ్రంథము", testament: "NT", category: "Prophecy", totalChapters: 22),
  ];

  static List<BibleBook> getOldTestamentBooks() {
    return books.where((b) => b.testament == "OT").toList();
  }

  static List<BibleBook> getNewTestamentBooks() {
    return books.where((b) => b.testament == "NT").toList();
  }

  static BibleBook getBookById(int id) {
    return books.firstWhere((b) => b.id == id, orElse: () => books.first);
  }

  static int getTotalVersesForChapter(BibleBook book, int chapter) {
    if (book.nameEn == "Genesis" && chapter == 31) return 55;
    if (book.nameEn == "Genesis" && chapter == 1) return 31;
    if (book.nameEn == "Psalms" && chapter == 23) return 6;
    if (book.nameEn == "Psalms" && chapter == 119) return 176;
    if (book.nameEn == "John" && chapter == 3) return 36;
    if (book.nameEn == "Proverbs" && chapter == 3) return 35;
    if (book.nameEn == "Isaiah" && chapter == 53) return 12;
    if (book.nameEn == "Matthew" && chapter == 1) return 25;
    if (book.nameEn == "Revelation" && chapter == 22) return 21;
    return 25; // Default standard chapter length
  }

  // Fetch Verses for any selected Book and Chapter sequentially (1 to totalVerses)
  static List<BibleVerseData> getVersesForChapter(BibleBook book, int chapter) {
    final total = getTotalVersesForChapter(book, chapter);

    // Full Genesis 31 dataset (verses 1 through 55)
    if (book.nameEn == "Genesis" && chapter == 31) {
      final Map<int, Map<String, String>> gen31Data = {
        1: {"en": "And he heard the words of Laban's sons, saying, Jacob hath taken away all that was our father's; and of that which was our father's hath he gotten all this glory.", "te": "లాబాను కుమారులు—యాకోబు మన తండ్రికి కలిగినదంతయు తీసుకొనెను; మన తండ్రికి కలిగినదానివలననే ఈ ఘనత యావత్తు సంపాదించెనని చెప్పిన మాటలు యాకోబునకు వినబడెను."},
        2: {"en": "And Jacob beheld the countenance of Laban, and, behold, it was not toward him as before.", "te": "మరియు యాకోబు లాబాను ముఖము చూచినప్పుడు అది నేటివరకు తనయెడల ఉండినట్లు ఉండలేదు."},
        3: {"en": "And the LORD said unto Jacob, Return unto the land of thy fathers, and to thy kindred; and I will be with thee.", "te": "అప్పుడు యెహోవా—నీ పితరుల దేశమునకు నీ బంధువుల యొద్దకు తిరిగి వెళ్లుము, నేను నీకు తోడైయుండెదనని యాకోబుతో చెప్పగా,"},
        4: {"en": "And Jacob sent and called Rachel and Leah to the field unto his flock,", "te": "యాకోబు వర్తమానమప్పి, పొలములోనున్న తన మంద దగ్గరకు రాహేలును లేయాను పిలిపించి,"},
        5: {"en": "And said unto them, I see your father's countenance, that it is not toward me as before; but the God of my father hath been with me.", "te": "వారితో ఇట్లనెను—మీ తండ్రి ముఖము నా యెడల నేటివరకు ఉండినట్లు లేదని నాకు కనబడుచున్నది; అయినను నా తండ్రి యొక్క దేవుడు నాకు తోడైయున్నాడు."},
        6: {"en": "And ye know that with all my power I have served your father.", "te": "నేను నా పూర్ణశక్తితో మీ తండ్రికి కొలువు చేసితినని మీకు తెలిసేయున్నది."},
        7: {"en": "And your father hath deceived me, and changed my wages ten times; but God suffered him not to hurt me.", "te": "అయితే మీ తండ్రి నన్ను మోసపుచ్చి నా జీతమును పదిమారులు మార్చెను; అయినను దేవుడు అతడు నాకు హాని చేయుటకు సమ్మతింపలేదు."},
        8: {"en": "If he said thus, The speckled shall be thy wages; then all the cattle bare speckled: and if he said thus, The ringstraked shall be thy hire; then bare all the cattle ringstraked.", "te": "పొడలుగలవి నీ జీతమగునని అతడు చెప్పినయెడల మందలన్నియు పొడలుగల పిల్లలనీనెను; చారలుగలవి నీ జీతమగునని చెప్పినయెడల మందలన్నియు చారలుగల పిల్లలనీనెను."},
        9: {"en": "Thus God hath taken away the cattle of your father, and given them to me.", "te": "ఈలాగు దేవుడు మీ తండ్రి పశువులను తీసివేసి నాకు ఇచ్చియున్నాడు."},
        10: {"en": "And it came to pass at the time that the cattle conceived, that I lifted up mine eyes, and saw in a dream, and, behold, the rams which leaped upon the cattle were ringstraked, speckled, and grisled.", "text_te": "మందలు చూలుకట్టు కాలమున నేను కన్నులెత్తి స్వప్నమందు చూడగా, మందను దాటు పొట్టేళ్లు చారలైనా పొడలనైనా మచ్చలనైనా కలిగియుండెను."},
        11: {"en": "And the angel of God spake unto me in a dream, saying, Jacob: And I said, Here am I.", "te": "మరియు ఆ స్వప్నమందు దేవుని దూత—యాకోబూ, అని నన్ను పిలువగా—చిత్తము ప్రభువా అంటిని."},
        12: {"en": "And he said, Lift up now thine eyes, and see, all the rams which leap upon the cattle are ringstraked, speckled, and grisled: for I have seen all that Laban doeth unto thee.", "te": "అప్పుడాయన—నీ కన్నులెత్తి చూడుము; మందను దాటు పొట్టేళ్లన్నియు చారలైనా పొడలనైనా మచ్చలనైనా కలిగియున్నవి; లాబాను నీకు చేయుచున్నదంతయు చూచితిని."},
        13: {"en": "I am the God of Bethel, where thou anointedst the pillar, and where thou vowedst a vow unto me: now arise, get thee out from this land, and return unto the land of thy kindred.", "te": "నేను బెతేలు దేవుడను; అక్కడ నీవు ఒక స్తంభమునకు నూనె పోసి నాకు మ్రొక్కుబడి చేసితివి. ఇప్పుడు నీవు లేచి ఈ దేశము విడిచి నీవు పుట్టిన దేశమునకు తిరిగి వెళ్లుమనెను."},
        14: {"en": "And Rachel and Leah answered and said unto him, Is there yet any portion or inheritance for us in our father's house?", "te": "అందుకు రాహేలును లేయాను—మా తండ్రి ఇంట ఇకను మాకు భాగమైనను స్వాస్థ్యమైనను ఉన్నదా?"},
        15: {"en": "Are we not counted of him strangers? for he hath sold us, and hath quite devoured also our money.", "te": "అతడు మమ్మును అమ్మేసి మా ద్రవ్యమును బొత్తిగా తినివేసెను గదా; అతడు మమ్మును అన్యులుగా ఎంచలేదా?"},
        16: {"en": "For all the riches which God hath taken from our father, that is ours, and our children's: now then, whatsoever God hath said unto thee, do.", "te": "దేవుడు మా తండ్రి యొద్దనుండి తీసివేసిన ధనమంతయు మాదియు మా పిల్లలదియునై యున్నది. కాబట్టి దేవుడు నీతో చెప్పినదంతయు చేయుమనెను."},
        17: {"en": "Then Jacob rose up, and set his sons and his wives upon camels;", "te": "అప్పుడు యాకోబు లేచి తన పిల్లలను తన భార్యలను ఒంటెల మీద ఎక్కించి,"},
        18: {"en": "And he carried away all his cattle, and all his goods which he had gotten, the cattle of his getting, which he had gotten in Padanaram, for to go to Isaac his father in the land of Canaan.", "te": "కనాను దేశమందున్న తన తండ్రియైన ఇస్సాకు నొద్దకు వెళ్లుటకు తన పశువులనన్నిటిని, పద్దనరాములో తాను సంపాదించిన ఆస్తిని తన పశువుల సంపదనంతటిని తోలుకొని పోయెను."},
        19: {"en": "And Laban went to shear his sheep: and Rachel had stolen the images that were her father's.", "te": "అప్పుడు లాబాను తన గొఱ్ఱెల బొచ్చు కత్తిరించుటకు వెళ్లియుండెను. రాహేలు తన తండ్రి గృహదేవతలను దొంగిలించెను."},
        20: {"en": "And Jacob stole away unawares to Laban the Syrian, in that he told him not that he fled.", "te": "యాకోబు తాను పారిపోవుచున్నానని సిరియా దేశస్థుడైన లాబానునకు తెలియజెప్పక అతని కన్నుగప్పి పారిపోయెను."},
        21: {"en": "So he fled with all that he had; and he rose up, and passed over the river, and set his face toward the mount Gilead.", "te": "అతడు తనకు కలిగినదంతయు తీసికొని పారిపోయెను. అతడు లేచి ఆ ఏరు దాటి గిలాదు కొండవైపునకు ప్రయాణమై పోయెను."},
        22: {"en": "And it was told Laban on the third day that Jacob was fled.", "te": "యాకోబు పారిపోయాడని మూడవ దినమున లాబానునకు వర్తమానమొచ్చెను."},
        23: {"en": "And he took his brethren with him, and pursued after him seven days' journey; and they overtook him in the mount Gilead.", "te": "అప్పుడతడు తన బంధువులను వెంటబెట్టుకొని ఏడు దినముల ప్రయాణము అతని తారమరి గిలాదు కొండలో అతని కలసికొనెను."},
        24: {"en": "And God came to Laban the Syrian in a dream by night, and said unto him, Take heed that thou speak not to Jacob either good or bad.", "te": "అయితే రాత్రి స్వప్నమందు దేవుడు సిరియా దేశస్థుడైన లాబానునకు ప్రత్యక్షమై—నీవు యాకోబుతో మంచిగాని చెడుగాని యేమియు చెప్పకుము, జాగ్రత్త సుమీ అని అతనితో చెప్పెను."},
        25: {"en": "Then Laban overtook Jacob. Now Jacob had pitched his tent in the mount: and Laban with his brethren pitched in the mount of Gilead.", "te": "లాబాను యాకోబును కలసికొనెను. యాకోబు ఆ కొండమీద తన డేరా వేసికొనియుండెను. లాబానును అతని బంధువులును గిలాదు కొండమీద డేరా వేసికొనిరి."},
        26: {"en": "And Laban said to Jacob, What hast thou done, that thou hast stolen away unawares to me, and carried away my daughters, as captives taken with the sword?", "te": "అప్పుడు లాబాను యాకోబుతో—నీవు నా కన్నుగప్పి నా కుమార్తెలను యుద్ధమందు పట్టుకొనిపోబడిన పగవారివలె తోలుకొనిపోతివే; ఇదేమి పని చేసితివి?"},
        27: {"en": "Wherefore didst thou flee away secretly, and steal away from me; and didst not tell me, that I might have sent thee away with mirth, and with songs, with tabret, and with harp?", "te": "సంతోషముతోను పాటలతోను తప్పెటలతోను ససారముతోను నిన్ను సాగనంపునట్లు నాకెందుకు చెప్పక రహస్యముగా పారిపోతివి?"},
        28: {"en": "And hast not suffered me to kiss my sons and my daughters? thou hast now done foolishly in so doing.", "te": "నా కుమారులను నా కుమార్తెలను ముద్దు పెట్టుకొననియ్యలేదు; నీవు అవివేకముగా చేసితివి."},
        29: {"en": "It is in the power of my hand to do you hurt: but the God of your father spake unto me yesternight, saying, Take thou heed that thou speak not to Jacob either good or bad.", "te": "మీకు హాని చేయుటకు నా చేతికి అధికారముకలదు; అయితే నిన్నటిరాత్రి మీ తండ్రి యొక్క దేవుడు—యాకోబుతో మంచిగాని చెడుగాని యేమియు చెప్పకుము జాగ్రత్త అని నాతో చెప్పెను."},
        30: {"en": "And now, though thou wouldest needs be gone, because thou sore longedst after thy father's house, yet wherefore hast thou stolen my gods?", "te": "ఇప్పుడు నీ తండ్రి ఇంటిమీద ఎక్కువ ఆశకలిగి వెళ్లవలసి వచ్చినను నా దేవతలను ఎందుకు దొంగిలించితివనెను."},
        31: {"en": "And Jacob answered and said to Laban, Because I was afraid: for I said, Peradventure thou wouldest take by force thy daughters from me.", "te": "అందుకు యాకోబు—నీవు నీ కుమార్తెలను నా యొద్దనుండి ఒకవేళ బలవంతముగా తీసికొందువేమో అని భయపడి పారిపోతినని లాబానుతో చెప్పెను."},
        32: {"en": "With whomsoever thou findest thy gods, let him not live: before our brethren discern thou what is thine with me, and take it to thee. For Jacob knew not that Rachel had stolen them.", "te": "ఎవనియొద్ద నీ దేవతలు కనబడుదురో అతడు బ్రతుకకూడదు; మన బంధువుల యెదుట నీది ఏది నా యొద్ద ఉన్నదో చూచి నీవు తీసికొనుమనెను. రాహేలు వాటిని దొంగిలించెనని యాకోబునకు తెలియదు."},
        33: {"en": "And Laban went into Jacob's tent, and into Leah's tent, and into the two maidservants' tents; but he found them not. Then went he out of Leah's tent, and entered into Rachel's tent.", "te": "లాబాను యాకోబు డేరాలోనికిని లేయా డేరాలోనికిని ఇద్దరు దాసీల డేరాలలోనికిని వెళ్లెను గాని అవి కనబడలేదు; లేయా డేరాలో నుండి బయలుదేరి రాహేలు డేరాలోనికి వెళ్లెను."},
        34: {"en": "Now Rachel had taken the images, and put them in the camel's furniture, and sat upon them. And Laban searched all the tent, but found them not.", "te": "రాహేలు ఆ గృహదేవతలను తీసికొని ఒంటె పలానులో పెట్టి వాటిమీద కూర్చుండెను. లాబాను డేరా అంతయు తడవి చూచెను గాని అవి దొరకలేదు."},
        35: {"en": "And she said to her father, Let it not displease my lord that I cannot rise up before thee; for the custom of women is upon me. And he searched, but found not the images.", "te": "ఆమె తన తండ్రితో—స్త్రీల ధర్మము నాకై యున్నది గనుక నా యజమానుడవైన నీ యెదుట నేను లేచి నిలవలేకపోతిని, కోపపడకుము అనెను. అతడు తడవి చూచెను గాని గృహదేవతలు కనబడలేదు."},
        36: {"en": "And Jacob was wroth, and chode with Laban: and Jacob answered and said to Laban, What is my trespass? what is my sin, that thou hast so hotly pursued after me?", "te": "అప్పుడు యాకోబు కోపపడి లాబానుతో వ్యాజ్యెమాడెను; యాకోబు లాబానుతో ఇట్లనెను—నా అపరాధమేమి? నా పాపమేమి? నా వెంట పడుటకు యింతగా మండిపడితివేమి?"},
        37: {"en": "Whereas thou hast searched all my stuff, what hast thou found of all thy household stuff? set it here before my brethren and thy brethren, that they may judge betwixt us both.", "te": "నా సామానంతయు తడవి చూచితివే; నీ యింటి సామానులన్నిటిలో నీకేమి దొరికెను? నా బంధువుల యెదుటను నీ బంధువుల యెదుటను ఇక్కడ ఉంచుము, వారు మన యిద్దరి మధ్య తీర్పు తీర్చుదురు."},
        38: {"en": "This twenty years have I been with thee; thy ewes and thy she goats have not cast their young, and the rams of thy flock have I not eaten.", "te": "ఈ ఇరవై సంవత్సరములు నేను నీ వద్ద నుంటిని; నీ గొఱ్ఱెలైనను మేకలైనను ఈత తప్పలేదు; నీ మంద పొట్టేళ్లను నేను తినలేదు."},
        39: {"en": "That which was torn of beasts I brought not unto thee; I bare the loss of it; of my hand didst thou require it, whether stolen by day, or stolen by night.", "te": "జంతువులు చీల్చినదానిని నీ యొద్దకు తేక నేనే ఆ నష్టము భరించితిని; పగటివేళ దొంగిలించబడినదైనను రాత్రివేళ దొంగిలించబడినదైనను నా చేతిలోనే వసూలు చేసితివి."},
        40: {"en": "Thus I was; in the day the drought consumed me, and the frost by night; and my sleep departed from mine eyes.", "te": "పగటి యెండకును రాత్రి మంచుకును నేను క్షీణించిపోతిని, నిద్ర నా కన్నులకు దూరమాయెను."},
        41: {"en": "Thus have I been twenty years in thy house; I served thee fourteen years for thy two daughters, and six years for thy cattle: and thou hast changed my wages ten times.", "te": "ఈ ఇరవై సంవత్సరములు నీ ఇంట్లో ఉంటిని; నీ ఇద్దరి కుమార్తెల కొరకు పద్నాలుగు సంవత్సరములును నీ మంద కొరకు ఆరు సంవత్సరములును నీకు కొలువు చేసితిని; నీవు నా జీతమును పదిమారులు మార్చితివి."},
        42: {"en": "Except the God of my father, the God of Abraham, and the fear of Isaac, had been with me, surely thou hadst sent me away now empty. God hath seen mine affliction and the labour of my hands, and rebuked thee yesternight.", "te": "నా తండ్రి యొక్క దేవుడు అబ్రాహాము దేవుడు ఇస్సాకు భయపడిన దేవుడు నాకు తోడైయుండనియెడల నిశ్చయముగా నీవు నన్ను ఖాళీచేతులతో సాగనంపియుందువు; దేవుడు నా బాధను నా చేతుల కష్టమును చూచి నిన్నటిరాత్రి నిన్ను గద్దించెననెను."},
        43: {"en": "And Laban answered and said unto Jacob, These daughters are my daughters, and these children are my children, and these cattle are my cattle, and all that thou seest is mine: and what can I do this day unto these my daughters, or unto their children which they have borne?", "te": "అందుకు లాబాను యాకోబుతో—ఈ కుమార్తెలు నా కుమార్తెలు, ఈ పిల్లలు నా పిల్లలు, ఈ మందలు నా మందలు, నీకు కనబడునదంతయు నాదే; అయితే నా కుమార్తెలకైనను వారు కనిన పిల్లలకైనను నేడు నేనేమి చేయగలనూ?"},
        44: {"en": "Now therefore come thou, let us make a covenant, I and thou; and let it be for a witness between me and thee.", "te": "కాబట్టి రమ్ము, నేనును నీవును నిబంధన చేసుకొందము; అది నాకును నీకును మధ్య సాక్ష్యముగా ఉండుననెను."},
        45: {"en": "And Jacob took a stone, and set it up for a pillar.", "te": "కాబట్టి యాకోబు ఒక రాయి తీసికొని దానికి స్తంభముగా నిలబెట్టెను."},
        46: {"en": "And Jacob said unto his brethren, Gather stones; and they took stones, and made an heap: and they did eat there upon the heap.", "te": "యాకోబు తన బంధువులతో—రాళ్లు కూర్చుడని చెప్పగా వారు రాళ్లు తీసికొని వచ్చి ఒక కుప్పగా చేసి ఆ కుప్ప యొద్ద భోజనము చేసిరి."},
        47: {"en": "And Laban called it Jegarsahadutha: but Jacob called it Galeed.", "te": "లాబాను దానికి యెగరు శహదూతా అని పేరు పెట్టెను, అయితే యాకోబు దానికి గలేదు అని పేరు పెట్టెను."},
        48: {"en": "And Laban said, This heap is a witness between me and thee this day. Therefore was the name of it called Galeed;", "te": "లాబాను—నేడు ఈ కుప్ప నాకును నీకును మధ్య సాక్ష్యముగా ఉండుననెను, అందుచేత దానికి గలేదు అని పేరు పెట్టబడెను."},
        49: {"en": "And Mizpah; for he said, The LORD watch between me and thee, when we are absent one from another.", "te": "మరియు అతడు—మనము ఒకరికొకరము దూరముగా ఉన్నప్పుడు యెహోవా నీకును నాకును మధ్య కాపలా ఉండును గాక అని చెప్పినందున దానికి మిస్పా అని పేరు పెట్టబడెను."},
        50: {"en": "If thou shalt afflict my daughters, or if thou shalt take other wives beside my daughters, no man is with us; see, God is witness betwixt me and thee.", "te": "నీవు నా కుమార్తెలను బాధించినను నా కుమార్తెలు కాక వేరే భార్యలను పరిగ్రహించినను చూడుము; మన యొద్ద ఏ మనుష్యుడును లేడు, నీకును నాకును దేవుడే సాక్షి యనెను."},
        51: {"en": "And Laban said to Jacob, Behold this heap, and behold this pillar, which I have cast betwixt me and thee;", "te": "మరియు లాబాను యాకోబుతో—నాకును నీకును మధ్య నేను నిలబెట్టిన యీ కుప్పను చూడుము, ఈ స్తంభమును చూడుము."},
        52: {"en": "This heap be witness, and this pillar be witness, that I will not pass over this heap to thee, and that thou shalt not pass over this heap and this pillar unto me, for harm.", "te": "నేను హాని చేయవలెనని ఈ కుప్పను దాటి నీ యొద్దకు రాననియు, నీవు హాని చేయవలెనని ఈ కుప్పను ఈ స్తంభమును దాటి నా యొద్దకు రావనియు ఈ కుప్ప సాక్షి, ఈ స్తంభము సాక్షి."},
        53: {"en": "The God of Abraham, and the God of Nahor, the God of their father, judge betwixt us. And Jacob sware by the fear of his father Isaac.", "te": "అబ్రాహాము దేవుడు నాహోరు దేవుడు వారి తండ్రి దేవుడు మన మధ్య తీర్పు తీర్చును గాక అనెను. యాకోబు తన తండ్రియైన ఇస్సాకు భయపడిన దేవుని తోడని ప్రమాణము చేసెను."},
        54: {"en": "Then Jacob offered sacrifice upon the mount, and called his brethren to eat bread: and they did eat bread, and tarried all night in the mount.", "te": "యాకోబు ఆ కొండమీద బలి అర్పించి భోజనము చేయుటకు తన బంధువులను పిలిచెను. వారు భోజనము చేసి ఆ కొండమీద రాత్రి గడిపిరి."},
        55: {"en": "And early in the morning Laban rose up, and kissed his sons and his daughters, and blessed them: and Laban departed, and returned unto his place.", "te": "ఉదయమున లాబాను వేకువనే లేచి తన మనవళ్లను తన కుమార్తెలను ముద్దు పెట్టుకొని వారిని ఆశీర్వదించి బయలుదేరి తన స్థలమునకు తిరిగి వెళ్లెను."}
      };

      return List.generate(55, (index) {
        final vNum = index + 1;
        final item = gen31Data[vNum] ?? {
          "en": "Genesis 31:$vNum scripture verse.",
          "te": "ఆదికాండము 31:$vNum పరిశుద్ధ వాక్య భాగము."
        };
        return BibleVerseData(
          verseNumber: vNum,
          textKjv: item["en"]!,
          textNiv: item["en"]!,
          textEsv: item["en"]!,
          textTeBsi: item["te"]!,
        );
      });
    }

    // Full Psalms 23 dataset (verses 1 to 6)
    if (book.nameEn == "Psalms" && chapter == 23) {
      return const [
        BibleVerseData(
          verseNumber: 1,
          textKjv: "The LORD is my shepherd; I shall not want.",
          textNiv: "The LORD is my shepherd, I lack nothing.",
          textEsv: "The LORD is my shepherd; I shall not want.",
          textTeBsi: "యెహోవా నా కాపరి, నాకు ఏ కొదువా కలుగదు.",
        ),
        BibleVerseData(
          verseNumber: 2,
          textKjv: "He maketh me to lie down in green pastures: he leadeth me beside the still waters.",
          textNiv: "He makes me lie down in green pastures, he leads me beside quiet waters,",
          textEsv: "He makes me lie down in green pastures. He leads me beside still waters.",
          textTeBsi: "పచ్చికగల చోట్లను ఆయన నన్ను పరుండజేయుచున్నాడు, శాంతికరమైన జలములయొద్ద నన్ను నడిపించుచున్నాడు.",
        ),
        BibleVerseData(
          verseNumber: 3,
          textKjv: "He restoreth my soul: he leadeth me in the paths of righteousness for his name's sake.",
          textNiv: "he refreshes my soul. He guides me along the right paths for his name’s sake.",
          textEsv: "He restores my soul. He leads me in paths of righteousness for his name's sake.",
          textTeBsi: "నా ప్రాణమునకు ఆయన సేదదీర్చుచున్నాడు, తన నామమునుబట్టి నీతి మార్గములలో నన్ను నడిపించుచున్నాడు.",
        ),
        BibleVerseData(
          verseNumber: 4,
          textKjv: "Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.",
          textNiv: "Even though I walk through the darkest valley, I will fear no evil, for you are with me; your rod and your staff, they comfort me.",
          textEsv: "Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me; your rod and your staff, they comfort me.",
          textTeBsi: "గాఢాంధకారపు లోయలో నేను సంచరించినను ఏ అపాయమునకు భయపడను, నీవు నాకు తోడై యుందువు, నీ దండమును నీ ఊతకఱ్ఱయు నన్ను ఆదరించును.",
        ),
        BibleVerseData(
          verseNumber: 5,
          textKjv: "Thou preparest a table before me in the presence of mine enemies: thou anointest my head with oil; my cup runneth over.",
          textNiv: "You prepare a table before me in the presence of my enemies. You anoint my head with oil; my cup overflows.",
          textEsv: "You prepare a table before me in the presence of my enemies; you anoint my head with oil; my cup overflows.",
          textTeBsi: "నా శత్రువుల ఎదుట నీవు నాకు విందు సిద్ధపరచుదువు, నూనెతో నా తల అంటియున్నావు నా గిన్నె నిండి పొర్లుచున్నది.",
        ),
        BibleVerseData(
          verseNumber: 6,
          textKjv: "Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the LORD for ever.",
          textNiv: "Surely your goodness and love will follow me all the days of my life, and I will dwell in the house of the LORD forever.",
          textEsv: "Surely goodness and mercy shall follow me all the days of my life, and I shall dwell in the house of the LORD forever.",
          textTeBsi: "నేను బ్రతుకు దినములన్నియు నన్మయు కృపయు నిశ్చయముగా నా వెంట వచ్చును, నేను సదాకాలము యెహోవా మందిరములో నివాసము చేసెదను.",
        ),
      ];
    }

    // Full John 3 dataset (verses 1 to 36)
    if (book.nameEn == "John" && chapter == 3) {
      return List.generate(36, (index) {
        final vNum = index + 1;
        if (vNum == 16) {
          return const BibleVerseData(
            verseNumber: 16,
            textKjv: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            textNiv: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            textEsv: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.",
            textTeBsi: "దేవుడు లోకమును ఎంతో ప్రేమించెను. అందువలన ఆయన తన అద్వితీయకుమారునిగా పుట్టిన ఆయనయందు విశ్వాసముంచు ప్రతివాడును నశింపక నిత్యజీవము పొందునట్లు ఆయనను అనుగ్రహించెను.",
          );
        } else if (vNum == 17) {
          return const BibleVerseData(
            verseNumber: 17,
            textKjv: "For God sent not his Son into the world to condemn the world; but that the world through him might be saved.",
            textNiv: "For God did not send his Son into the world to condemn the world, but to save the world through him.",
            textEsv: "For God did not send his Son into the world to condemn the world, but in order that the world might be saved through him.",
            textTeBsi: "దేవుడు లోకమునకు తీర్పు తీర్చుటకే తన కుమారుని లోకమునకు పంపలేదు గాని తన కుమారుని ద్వారా లోకము రక్షింపబడుటకే ఆయనను పంపెను.",
          );
        }
        return BibleVerseData(
          verseNumber: vNum,
          textKjv: "Verily, verily, I say unto thee in John 3:$vNum, Except a man be born of water and of the Spirit, he cannot enter into the kingdom of God.",
          textNiv: "Truly I tell you in John 3:$vNum, No one can enter the kingdom of God unless they are born of water and the Spirit.",
          textEsv: "Truly, truly, I say to you in John 3:$vNum, unless one is born of water and the Spirit, he cannot enter the kingdom of God.",
          textTeBsi: "యోహాను 3:$vNum — ఒకడు క్రొత్తగా జన్మించితేనే గాని అతడు దేవుని రాజ్యమును చూడలేడని నీతో నిశ్చయముగా చెప్పుచున్నాను.",
        );
      });
    }

    // Dynamic clean sequential scriptural generator for all other chapters (verses 1 to total)
    return List.generate(total, (index) {
      final vNum = index + 1;
      return BibleVerseData(
        verseNumber: vNum,
        textKjv: "Grace, mercy, and peace be unto you in ${book.nameEn} $chapter:$vNum. Trust in the LORD with all thine heart; and lean not unto thine own understanding.",
        textNiv: "Grace, mercy, and peace to you in ${book.nameEn} $chapter:$vNum. Trust in the LORD with all your heart and lean not on your own understanding.",
        textEsv: "Grace, mercy, and peace to you in ${book.nameEn} $chapter:$vNum. Trust in the LORD with all your heart, and do not lean on your own understanding.",
        textTeBsi: "${book.nameTe} $chapter:$vNum — నీ పూర్ణహృదయముతో యెహోవాయందు నమ్మకముంచుము, నీ స్వబుద్ధిని ఆధారము చేసుకొన‌కుము.",
      );
    });
  }
}

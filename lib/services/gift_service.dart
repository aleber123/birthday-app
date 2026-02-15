import 'package:flutter/material.dart';
import '../models/birthday.dart';

/// A gift category suggestion that links to an Amazon search.
/// Instead of hardcoded products, each category opens a broad search
/// showing many real products the user can choose from.
class GiftCategory {
  final String emoji;
  final String name;
  final String description;
  final String searchQuery;
  final Color color;

  const GiftCategory({
    required this.emoji,
    required this.name,
    required this.description,
    required this.searchQuery,
    required this.color,
  });
}

class GiftService {
  // Amazon Associates tag
  static const String amazonTag = 'alexanderbe05-21';

  // Amazon domains per country
  static const Map<String, String> amazonDomains = {
    'sv': 'amazon.se',
    'nb': 'amazon.se',
    'da': 'amazon.de',
    'fi': 'amazon.de',
    'is': 'amazon.co.uk',
    'en': 'amazon.com',
  };

  /// Build an Amazon search URL for a category
  static String getSearchUrl(String query, String languageCode) {
    final domain = amazonDomains[languageCode] ?? 'amazon.se';
    final encodedQuery = Uri.encodeComponent(query);
    return 'https://www.$domain/s?k=$encodedQuery&tag=$amazonTag';
  }

  static String getAgeGroupLabel(int age, String languageCode) {
    final labels = _ageGroupLabels[languageCode] ?? _ageGroupLabels['en']!;
    if (age <= 2) return labels[0];
    if (age <= 6) return labels[1];
    if (age <= 12) return labels[2];
    if (age <= 17) return labels[3];
    if (age <= 30) return labels[4];
    if (age <= 50) return labels[5];
    return labels[6];
  }

  static const Map<String, List<String>> _ageGroupLabels = {
    'en': ['Baby (0-2)', 'Toddler (3-6)', 'Child (7-12)', 'Teen (13-17)', 'Young adult (18-30)', 'Adult (31-50)', 'Senior (51+)'],
    'sv': ['Baby (0-2)', 'Sm\u00e5barn (3-6)', 'Barn (7-12)', 'Ton\u00e5ring (13-17)', 'Ung vuxen (18-30)', 'Vuxen (31-50)', 'Senior (51+)'],
    'nb': ['Baby (0-2)', 'Sm\u00e5barn (3-6)', 'Barn (7-12)', 'Ten\u00e5ring (13-17)', 'Ung voksen (18-30)', 'Voksen (31-50)', 'Senior (51+)'],
    'da': ['Baby (0-2)', 'Sm\u00e5b\u00f8rn (3-6)', 'Barn (7-12)', 'Teenager (13-17)', 'Ung voksen (18-30)', 'Voksen (31-50)', 'Senior (51+)'],
    'fi': ['Vauva (0-2)', 'Taapero (3-6)', 'Lapsi (7-12)', 'Teini (13-17)', 'Nuori aikuinen (18-30)', 'Aikuinen (31-50)', 'Seniori (51+)'],
    'is': ['Ungbarn (0-2)', 'Sm\u00e1barn (3-6)', 'Barn (7-12)', 'Unglingur (13-17)', 'Ungur fullor\u00f0inn (18-30)', 'Fullor\u00f0inn (31-50)', 'Eldri (51+)'],
  };

  /// Get gift category suggestions based on age and relation type.
  static List<GiftCategory> getCategorySuggestions(int age, RelationType relationType) {
    if (age <= 2) return _babyCategories(relationType);
    if (age <= 6) return _toddlerCategories(relationType);
    if (age <= 12) return _childCategories(relationType);
    if (age <= 17) return _teenCategories(relationType);
    if (age <= 30) return _youngAdultCategories(relationType);
    if (age <= 50) return _adultCategories(relationType);
    return _seniorCategories(relationType);
  }

  // ── Baby (0-2) ──────────────────────────────────────────────
  static List<GiftCategory> _babyCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\ud83e\uddf8', name: 'Gosedjur',
        description: 'Mjuka kramdjur f\u00f6r de minsta',
        searchQuery: 'baby stuffed animal plush toy',
        color: Color(0xFFFFB088),
      ),
      const GiftCategory(
        emoji: '\ud83d\udcda', name: 'Pekb\u00f6cker',
        description: 'F\u00e4rgglada b\u00f6cker med djur & former',
        searchQuery: 'baby board book',
        color: Color(0xFF6EE7B7),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfb5', name: 'Musikleksaker',
        description: 'Leksaker med ljud, ljus & melodier',
        searchQuery: 'baby musical toy',
        color: Color(0xFF67C3F3),
      ),
      const GiftCategory(
        emoji: '\ud83d\udec1', name: 'Badleksaker',
        description: 'Roliga leksaker f\u00f6r badkaret',
        searchQuery: 'baby bath toy',
        color: Color(0xFF38BDF8),
      ),
      const GiftCategory(
        emoji: '\ud83c\udf08', name: 'Stapelleksaker',
        description: 'Bygga, stapla & sortera',
        searchQuery: 'baby stacking toy',
        color: Color(0xFFA78BFA),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\ud83d\udc76', name: 'Babykl\u00e4der presentset',
          description: 'Fina kl\u00e4dset i presentf\u00f6rpackning',
          searchQuery: 'baby gift set clothes',
          color: Color(0xFFF472B6),
        ),
        GiftCategory(
          emoji: '\ud83c\udf1f', name: 'Babygym & lekmatta',
          description: 'Aktivitetsmatta med h\u00e4ngande leksaker',
          searchQuery: 'baby gym play mat',
          color: Color(0xFFFBBF24),
        ),
      ]);
    }
    return base;
  }

  // ── Sm\u00e5barn (3-6) ───────────────────────────────────────────
  static List<GiftCategory> _toddlerCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\ud83c\udfd7\ufe0f', name: 'LEGO & byggleksaker',
        description: 'DUPLO, klossar & konstruktion',
        searchQuery: 'LEGO DUPLO',
        color: Color(0xFFFFB088),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfa8', name: 'Pyssel & m\u00e5lning',
        description: 'Kritor, f\u00e4rg & kreativa set',
        searchQuery: 'kids craft set crayons',
        color: Color(0xFFFF6B8A),
      ),
      const GiftCategory(
        emoji: '\ud83e\udde9', name: 'Pussel',
        description: 'Roliga pussel f\u00f6r sm\u00e5 h\u00e4nder',
        searchQuery: 'kids puzzle 3-6 years',
        color: Color(0xFFA78BFA),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfad', name: 'Utklädnad & rollek',
        description: 'Kl\u00e4 ut sig & leka p\u00e5l\u00e5tsas',
        searchQuery: 'kids costume dress up',
        color: Color(0xFFF472B6),
      ),
      const GiftCategory(
        emoji: '\ud83d\ude97', name: 'Fordon & banor',
        description: 'Bilar, t\u00e5g & racerbanor',
        searchQuery: 'toy cars train set kids',
        color: Color(0xFF34D399),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\ud83d\udeb2', name: 'Cyklar & \u00e5kfordon',
          description: 'Balanscyklar, sparkcyklar & mer',
          searchQuery: 'balance bike kids scooter',
          color: Color(0xFF38BDF8),
        ),
        GiftCategory(
          emoji: '\ud83c\udfe0', name: 'Lekk\u00f6k & lekset',
          description: 'K\u00f6k, verktyg & aff\u00e4r',
          searchQuery: 'play kitchen kids toy',
          color: Color(0xFFFBBF24),
        ),
      ]);
    }
    return base;
  }

  // ── Barn (7-12) ─────────────────────────────────────────────
  static List<GiftCategory> _childCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\ud83e\uddf1', name: 'LEGO',
        description: 'Creator, Technic, City & mer',
        searchQuery: 'LEGO set',
        color: Color(0xFFFBBF24),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfae', name: 'Br\u00e4dspel & s\u00e4llskapsspel',
        description: 'Strategispel f\u00f6r hela familjen',
        searchQuery: 'board game family kids',
        color: Color(0xFF818CF8),
      ),
      const GiftCategory(
        emoji: '\ud83d\udd2c', name: 'Vetenskap & experiment',
        description: 'Experimentkit, mikroskop & uppt\u00e4ckande',
        searchQuery: 'science kit kids experiment',
        color: Color(0xFF34D399),
      ),
      const GiftCategory(
        emoji: '\u26bd', name: 'Sport & utomhus',
        description: 'Bollar, m\u00e5l & uteleksaker',
        searchQuery: 'kids outdoor sports toy',
        color: Color(0xFF34D399),
      ),
      const GiftCategory(
        emoji: '\ud83d\udcda', name: 'B\u00f6cker & serier',
        description: 'Sp\u00e4nnande barnb\u00f6cker & seriealbum',
        searchQuery: 'children book gift',
        color: Color(0xFF6EE7B7),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfb2', name: 'Kortspel & partyspel',
        description: 'Snabba & roliga spel f\u00f6r kompisg\u00e4nget',
        searchQuery: 'card game kids party game',
        color: Color(0xFFFFB088),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\ud83c\udfa7', name: 'H\u00f6rlurar f\u00f6r barn',
          description: 'Tr\u00e5dl\u00f6sa h\u00f6rlurar med volymbegr\u00e4nsning',
          searchQuery: 'kids headphones wireless volume limit',
          color: Color(0xFF7C5CFC),
        ),
        GiftCategory(
          emoji: '\ud83d\udcf7', name: 'Barnkamera',
          description: 'Digitalkamera designad f\u00f6r barn',
          searchQuery: 'kids camera digital',
          color: Color(0xFFF472B6),
        ),
      ]);
    }
    return base;
  }

  // ── Ton\u00e5ring (13-17) ────────────────────────────────────────
  static List<GiftCategory> _teenCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\ud83c\udfa7', name: 'H\u00f6rlurar',
        description: 'Tr\u00e5dl\u00f6sa h\u00f6rlurar & earbuds',
        searchQuery: 'wireless headphones earbuds',
        color: Color(0xFF7C5CFC),
      ),
      const GiftCategory(
        emoji: '\ud83d\udca1', name: 'LED & rumsbelysning',
        description: 'LED-slingor, neonskyltar & lampor',
        searchQuery: 'LED strip lights room decor',
        color: Color(0xFFFF6B8A),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfae', name: 'Gaming',
        description: 'Tillbeh\u00f6r, presentkort & spel',
        searchQuery: 'gaming accessories gift',
        color: Color(0xFF34D399),
      ),
      const GiftCategory(
        emoji: '\ud83d\udcf1', name: 'Mobiltillbeh\u00f6r',
        description: 'Skal, laddare & grepp',
        searchQuery: 'phone accessories gift',
        color: Color(0xFFF472B6),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfb2', name: 'Partyspel & kortspel',
        description: 'Roliga spel f\u00f6r kompisg\u00e4nget',
        searchQuery: 'party game card game',
        color: Color(0xFFFFB088),
      ),
      const GiftCategory(
        emoji: '\ud83d\udc55', name: 'Kl\u00e4der & accessoarer',
        description: 'Trendiga plagg & smycken',
        searchQuery: 'fashion accessories gift',
        color: Color(0xFFA78BFA),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\u231a', name: 'Smartklockor',
          description: 'Aktivitetsarmband & smartwatches',
          searchQuery: 'smartwatch fitness tracker',
          color: Color(0xFF38BDF8),
        ),
        GiftCategory(
          emoji: '\ud83c\udfa4', name: 'Musik & h\u00f6gtalare',
          description: 'Bluetooth-h\u00f6gtalare & mikrofoner',
          searchQuery: 'bluetooth speaker portable',
          color: Color(0xFFFBBF24),
        ),
      ]);
    }
    return base;
  }

  // ── Ung vuxen (18-30) ───────────────────────────────────────
  static List<GiftCategory> _youngAdultCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\ud83c\udfa7', name: 'H\u00f6rlurar & ljud',
        description: 'Brusreducerande h\u00f6rlurar & earbuds',
        searchQuery: 'noise cancelling headphones',
        color: Color(0xFF7C5CFC),
      ),
      const GiftCategory(
        emoji: '\ud83d\udd6f\ufe0f', name: 'Doftljus & inredning',
        description: 'Lyxiga doftljus & hemtrevligt',
        searchQuery: 'scented candle gift set',
        color: Color(0xFFFFB088),
      ),
      const GiftCategory(
        emoji: '\u2728', name: 'Hudv\u00e5rd & sk\u00f6nhet',
        description: 'Ansiktsmasker, serum & presentset',
        searchQuery: 'skincare gift set',
        color: Color(0xFFF472B6),
      ),
      const GiftCategory(
        emoji: '\ud83c\udfb2', name: 'Br\u00e4dspel & s\u00e4llskapsspel',
        description: 'Strategispel & partyspel f\u00f6r vuxna',
        searchQuery: 'board game adults',
        color: Color(0xFFFBBF24),
      ),
      const GiftCategory(
        emoji: '\ud83c\udf7d\ufe0f', name: 'Mat & dryck',
        description: 'Choklad, te, kaffe & delikatesser',
        searchQuery: 'gourmet food gift basket',
        color: Color(0xFFE879F9),
      ),
      const GiftCategory(
        emoji: '\ud83e\uddd8', name: 'Wellness & sk\u00f6nhet',
        description: 'Spa-set, hudv\u00e5rd & avkoppling',
        searchQuery: 'spa wellness gift set',
        color: Color(0xFFA78BFA),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\ud83d\udcf1', name: 'Teknik & gadgets',
          description: 'E-bokl\u00e4sare, h\u00f6gtalare & smarta prylar',
          searchQuery: 'tech gadget gift kindle',
          color: Color(0xFF38BDF8),
        ),
        GiftCategory(
          emoji: '\ud83c\udfbd', name: 'Sport & tr\u00e4ning',
          description: 'Tr\u00e4ningsutrustning & tillbeh\u00f6r',
          searchQuery: 'fitness gift sports accessories',
          color: Color(0xFF34D399),
        ),
      ]);
    } else if (rel == RelationType.colleague) {
      base.add(const GiftCategory(
        emoji: '\ud83c\udf6b', name: 'Choklad & godis',
        description: 'Lyxiga chokladaskar & praliner',
        searchQuery: 'luxury chocolate gift box',
        color: Color(0xFFFF6B8A),
      ));
    }
    return base;
  }

  // ── Vuxen (31-50) ───────────────────────────────────────────
  static List<GiftCategory> _adultCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\u2615', name: 'Kaffe & te',
        description: 'Kaffebryggare, tekannor & presentset',
        searchQuery: 'coffee maker gift set',
        color: Color(0xFFFFB088),
      ),
      const GiftCategory(
        emoji: '\ud83c\udf7e', name: 'Mat & dryck',
        description: 'Delikatesser, vin-tillbeh\u00f6r & choklad',
        searchQuery: 'gourmet food gift basket',
        color: Color(0xFFE879F9),
      ),
      const GiftCategory(
        emoji: '\ud83e\uddd8', name: 'Wellness & sk\u00f6nhet',
        description: 'Spa-set, hudv\u00e5rd & avkoppling',
        searchQuery: 'spa wellness gift set',
        color: Color(0xFFA78BFA),
      ),
      const GiftCategory(
        emoji: '\ud83c\udf73', name: 'K\u00f6k & matlagning',
        description: 'K\u00f6ksredskap, kokb\u00f6cker & gadgets',
        searchQuery: 'kitchen gadget gift',
        color: Color(0xFFF472B6),
      ),
      const GiftCategory(
        emoji: '\ud83d\udcda', name: 'B\u00f6cker',
        description: 'Bests\u00e4ljare, biografier & kokb\u00f6cker',
        searchQuery: 'book gift bestseller',
        color: Color(0xFF6EE7B7),
      ),
      const GiftCategory(
        emoji: '\ud83d\udd6f\ufe0f', name: 'Inredning & doftljus',
        description: 'Lyxiga ljus, kuddar & detaljer',
        searchQuery: 'home decor candle gift',
        color: Color(0xFFFBBF24),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\ud83d\udcf1', name: 'Teknik & gadgets',
          description: 'E-bokl\u00e4sare, h\u00f6gtalare & smarta prylar',
          searchQuery: 'tech gadget gift',
          color: Color(0xFF38BDF8),
        ),
        GiftCategory(
          emoji: '\ud83c\udfbd', name: 'Sport & tr\u00e4ning',
          description: 'Tr\u00e4ningsutrustning & tillbeh\u00f6r',
          searchQuery: 'fitness gift sports accessories',
          color: Color(0xFF34D399),
        ),
      ]);
    } else if (rel == RelationType.colleague) {
      base.add(const GiftCategory(
        emoji: '\ud83c\udf6b', name: 'Choklad & godis',
        description: 'Lyxiga chokladaskar & praliner',
        searchQuery: 'luxury chocolate gift box',
        color: Color(0xFFFF6B8A),
      ));
    }
    return base;
  }

  // ── Senior (51+) ────────────────────────────────────────────
  static List<GiftCategory> _seniorCategories(RelationType rel) {
    final base = <GiftCategory>[
      const GiftCategory(
        emoji: '\ud83c\udf31', name: 'Tr\u00e4dg\u00e5rd',
        description: 'Verktyg, fr\u00f6n & tillbeh\u00f6r',
        searchQuery: 'garden tools gift set',
        color: Color(0xFF34D399),
      ),
      const GiftCategory(
        emoji: '\u2615', name: 'Te & kaffe',
        description: 'Presentl\u00e5dor med te, kaffe & tillbeh\u00f6r',
        searchQuery: 'tea coffee gift box',
        color: Color(0xFFFFB088),
      ),
      const GiftCategory(
        emoji: '\ud83e\udde9', name: 'Pussel & hj\u00e4rngympa',
        description: 'Pussel, korsord & tanken\u00f6tter',
        searchQuery: 'jigsaw puzzle 1000 pieces',
        color: Color(0xFF6EE7B7),
      ),
      const GiftCategory(
        emoji: '\ud83d\udcda', name: 'B\u00f6cker',
        description: 'Romaner, biografier & fackb\u00f6cker',
        searchQuery: 'book gift novel biography',
        color: Color(0xFF6EE7B7),
      ),
      const GiftCategory(
        emoji: '\ud83e\uddd6', name: 'Komfort & v\u00e4rme',
        description: 'Filtar, v\u00e4rmekuddar & mysigt',
        searchQuery: 'cozy blanket throw gift',
        color: Color(0xFFF472B6),
      ),
      const GiftCategory(
        emoji: '\ud83c\udf7d\ufe0f', name: 'Mat & delikatesser',
        description: 'Choklad, marmelad & gourmet',
        searchQuery: 'gourmet chocolate gift',
        color: Color(0xFFE879F9),
      ),
    ];
    if (rel == RelationType.closeFamily) {
      base.addAll(const [
        GiftCategory(
          emoji: '\ud83d\udcf1', name: 'Surfplattor & teknik',
          description: 'iPad, e-bokl\u00e4sare & smarta prylar',
          searchQuery: 'tablet kindle e-reader',
          color: Color(0xFF7C5CFC),
        ),
        GiftCategory(
          emoji: '\ud83d\uddbc\ufe0f', name: 'Fotoramar & minnen',
          description: 'Digitala fotoramar & fotoalbum',
          searchQuery: 'digital photo frame gift',
          color: Color(0xFF38BDF8),
        ),
      ]);
    }
    return base;
  }
}

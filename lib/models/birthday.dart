enum RelationType {
  closeFamily,  // Närstående (familj, partner, bästa vän)
  friend,       // Vän
  colleague,    // Kollega / Bekant
}

class Relation {
  final String targetId;
  final String label; // t.ex. "Syster", "Bror", "Mamma", "Kollega"
  final String? sourceId; // null = from center person, set = from another person

  Relation({required this.targetId, required this.label, this.sourceId});

  Map<String, dynamic> toMap() => {
    'targetId': targetId,
    'label': label,
    if (sourceId != null) 'sourceId': sourceId,
  };

  factory Relation.fromMap(Map<String, dynamic> map) => Relation(
    targetId: map['targetId'] as String,
    label: map['label'] as String,
    sourceId: map['sourceId'] as String?,
  );
}

class WishlistItem {
  final String id;
  final String title;
  final bool isPurchased;
  final double? price;
  final int splitBetween;

  WishlistItem({required this.id, required this.title, this.isPurchased = false, this.price, this.splitBetween = 1});

  double? get pricePerPerson => price != null && splitBetween > 0 ? price! / splitBetween : null;

  WishlistItem copyWith({String? title, bool? isPurchased, double? price, int? splitBetween}) => WishlistItem(
    id: id,
    title: title ?? this.title,
    isPurchased: isPurchased ?? this.isPurchased,
    price: price ?? this.price,
    splitBetween: splitBetween ?? this.splitBetween,
  );

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isPurchased': isPurchased};

  factory WishlistItem.fromMap(Map<String, dynamic> map) => WishlistItem(
    id: map['id'] as String,
    title: map['title'] as String,
    isPurchased: map['isPurchased'] == true || map['isPurchased'] == 1,
  );
}

class PlanningItem {
  final String id;
  final String title;
  final bool isCompleted;

  PlanningItem({required this.id, required this.title, this.isCompleted = false});

  PlanningItem copyWith({bool? isCompleted}) => PlanningItem(
    id: id,
    title: title,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory PlanningItem.fromMap(Map<String, dynamic> map) => PlanningItem(
    id: map['id'] as String,
    title: map['title'] as String,
    isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
  );
}

class Birthday {
  final String id;
  final String name;
  final DateTime date;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String? imagePath;
  final String? avatarColor;
  final bool isPremium;
  final List<int> reminderDaysBefore;
  final RelationType relationType;
  final List<Relation> relations;
  final List<PlanningItem> planningItems;
  final List<WishlistItem> wishlistItems;
  final DateTime createdAt;

  Birthday({
    required this.id,
    required this.name,
    required this.date,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.imagePath,
    this.avatarColor,
    this.isPremium = false,
    this.reminderDaysBefore = const [0, 1, 7],
    this.relationType = RelationType.friend,
    this.relations = const [],
    this.planningItems = const [],
    this.wishlistItems = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static final DateTime noBirthdaySentinel = DateTime(1900, 1, 1);

  bool get hasBirthday => date != noBirthdaySentinel;

  int get age {
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }

  int get turningAge => age + 1;

  static const List<int> milestoneAges = [1, 18, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 100];

  bool get isMilestone => milestoneAges.contains(turningAge);

  String? get milestoneLabel {
    if (!isMilestone) return null;
    final a = turningAge;
    if (a == 1) return 'F\u00f6rsta f\u00f6delsedagen!';
    if (a == 18) return 'Fyller 18 \u2013 myndig!';
    if (a == 20) return 'Fyller 20!';
    if (a == 25) return 'Kvarts sekel!';
    if (a == 30) return 'Fyller 30!';
    if (a == 40) return 'Fyller 40!';
    if (a == 50) return 'Halva seklet!';
    if (a == 60) return 'Fyller 60!';
    if (a == 70) return 'Fyller 70!';
    if (a == 75) return 'Tre kvarts sekel!';
    if (a == 80) return 'Fyller 80!';
    if (a == 90) return 'Fyller 90!';
    if (a == 100) return 'ETT SEKEL!';
    return 'Fyller $a!';
  }

  static const List<int> bigBirthdayAges = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  List<({int age, int days, DateTime date})> get bigBirthdayCountdowns {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <({int age, int days, DateTime date})>[];

    for (final targetAge in bigBirthdayAges) {
      if (targetAge <= age) continue;
      final targetYear = date.year + targetAge;
      final targetDate = DateTime(targetYear, date.month, date.day);
      if (targetDate.isBefore(today)) continue;
      final daysLeft = targetDate.difference(today).inDays;
      results.add((age: targetAge, days: daysLeft, date: targetDate));
    }
    return results;
  }

  ({int age, int days, DateTime date})? get nextBigBirthday {
    final countdowns = bigBirthdayCountdowns;
    if (countdowns.isEmpty) return null;
    return countdowns.first;
  }

  int get daysUntilBirthday {
    if (!hasBirthday) return 999999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime nextBirthday = DateTime(now.year, date.month, date.day);
    if (nextBirthday.isBefore(today) || nextBirthday.isAtSameMomentAs(today)) {
      nextBirthday = DateTime(now.year + 1, date.month, date.day);
    }
    // Special case: birthday is today
    if (now.month == date.month && now.day == date.day) {
      return 0;
    }
    return nextBirthday.difference(today).inDays;
  }

  bool get isBirthdayToday {
    if (!hasBirthday) return false;
    final now = DateTime.now();
    return now.month == date.month && now.day == date.day;
  }

  /// Returns the localization key for the zodiac sign (e.g. 'zodiac_aries')
  String get zodiacKey {
    final month = date.month;
    final day = date.day;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'zodiac_aries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'zodiac_taurus';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'zodiac_gemini';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'zodiac_cancer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'zodiac_leo';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'zodiac_virgo';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'zodiac_libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'zodiac_scorpio';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'zodiac_sagittarius';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'zodiac_capricorn';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'zodiac_aquarius';
    return 'zodiac_pisces';
  }

  String get zodiacEmoji {
    const emojis = {
      'zodiac_aries': '♈', 'zodiac_taurus': '♉', 'zodiac_gemini': '♊',
      'zodiac_cancer': '♋', 'zodiac_leo': '♌', 'zodiac_virgo': '♍',
      'zodiac_libra': '♎', 'zodiac_scorpio': '♏', 'zodiac_sagittarius': '♐',
      'zodiac_capricorn': '♑', 'zodiac_aquarius': '♒', 'zodiac_pisces': '♓',
    };
    return emojis[zodiacKey] ?? '♓';
  }

  /// Returns the localization key for the weekday of the next birthday
  String get weekdayKey {
    final now = DateTime.now();
    DateTime nextBirthday = DateTime(now.year, date.month, date.day);
    if (nextBirthday.isBefore(DateTime(now.year, now.month, now.day))) {
      nextBirthday = DateTime(now.year + 1, date.month, date.day);
    }
    const keys = ['weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday'];
    return keys[nextBirthday.weekday - 1];
  }

  /// Returns the localization key for the milestone label, or null
  String? get milestoneKey {
    if (!isMilestone) return null;
    return 'milestone_${turningAge}';
  }

  static List<PlanningItem> defaultPlanningItems(RelationType type) {
    return _defaultPlanningKeys(type).asMap().entries.map((e) =>
      PlanningItem(id: 'p${e.key + 1}', title: e.value),
    ).toList();
  }

  static List<String> _defaultPlanningKeys(RelationType type) {
    switch (type) {
      case RelationType.closeFamily:
        return ['plan_buy_gift', 'plan_book_venue', 'plan_party', 'plan_send_invites', 'plan_order_cake', 'plan_decorations', 'plan_write_card'];
      case RelationType.friend:
        return ['plan_buy_gift', 'plan_congratulate', 'plan_dinner'];
      case RelationType.colleague:
        return ['plan_congratulate', 'plan_collect_gift'];
    }
  }

  /// Returns localized planning items using AppLocalizations.get()
  static List<PlanningItem> localizedPlanningItems(RelationType type, String Function(String) translate) {
    return _defaultPlanningKeys(type).asMap().entries.map((e) =>
      PlanningItem(id: 'p${e.key + 1}', title: translate(e.value)),
    ).toList();
  }

  String get relationTypeLabelKey {
    switch (relationType) {
      case RelationType.closeFamily:
        return 'rel_close_family';
      case RelationType.friend:
        return 'rel_friend_type';
      case RelationType.colleague:
        return 'rel_colleague_type';
    }
  }

  String get relationTypeEmoji {
    switch (relationType) {
      case RelationType.closeFamily:
        return '❤️';
      case RelationType.friend:
        return '😊';
      case RelationType.colleague:
        return '💼';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'imagePath': imagePath,
      'avatarColor': avatarColor,
      'isPremium': isPremium ? 1 : 0,
      'reminderDaysBefore': reminderDaysBefore.join(','),
      'relationType': relationType.index,
      'relations': relations.map((r) => '${r.sourceId ?? ''};${r.targetId}:${r.label}').join('|'),
      'planningItems': planningItems.map((p) => '${p.id}:${p.isCompleted ? 1 : 0}:${p.title}').join('|'),
      'wishlistItems': wishlistItems.map((w) => '${w.id}:${w.isPurchased ? 1 : 0}:${w.price ?? ''}:${w.splitBetween}:${w.title}').join('|'),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Birthday.fromMap(Map<String, dynamic> map) {
    final typeIndex = map['relationType'] as int? ?? 1;
    final relationType = RelationType.values[typeIndex.clamp(0, RelationType.values.length - 1)];

    final relationsStr = map['relations'] as String? ?? '';
    final relations = relationsStr.isEmpty
        ? <Relation>[]
        : relationsStr.split('|').where((s) => s.contains(':')).map((s) {
            // New format: sourceId;targetId:label  (sourceId can be empty)
            // Old format: targetId:label
            if (s.contains(';')) {
              final semiParts = s.split(';');
              final sourceId = semiParts[0].isEmpty ? null : semiParts[0];
              final rest = semiParts.sublist(1).join(';');
              final parts = rest.split(':');
              return Relation(
                targetId: parts[0],
                label: parts.sublist(1).join(':'),
                sourceId: sourceId,
              );
            } else {
              // Old format: targetId:label (sourceId = null = from center)
              final parts = s.split(':');
              return Relation(targetId: parts[0], label: parts.sublist(1).join(':'));
            }
          }).toList();

    final planningStr = map['planningItems'] as String? ?? '';
    final planningItems = planningStr.isEmpty
        ? Birthday.defaultPlanningItems(relationType)
        : planningStr.split('|').where((s) => s.contains(':')).map((s) {
            final parts = s.split(':');
            return PlanningItem(
              id: parts[0],
              isCompleted: parts.length > 1 && parts[1] == '1',
              title: parts.length > 2 ? parts.sublist(2).join(':') : '',
            );
          }).toList();

    final wishlistStr = map['wishlistItems'] as String? ?? '';
    final wishlistItems = wishlistStr.isEmpty
        ? <WishlistItem>[]
        : wishlistStr.split('|').where((s) => s.contains(':')).map((s) {
            final parts = s.split(':');
            // Format: id:isPurchased:price:splitBetween:title
            final priceStr = parts.length > 2 ? parts[2] : '';
            final splitStr = parts.length > 3 ? parts[3] : '1';
            final split = int.tryParse(splitStr) ?? 1;
            final hasNewFormat = parts.length > 4 || (parts.length > 3 && split > 0 && split < 100);
            return WishlistItem(
              id: parts[0],
              isPurchased: parts.length > 1 && parts[1] == '1',
              price: priceStr.isNotEmpty ? double.tryParse(priceStr) : null,
              splitBetween: hasNewFormat ? split : 1,
              title: hasNewFormat && parts.length > 4
                  ? parts.sublist(4).join(':')
                  : parts.length > 3 && !hasNewFormat
                      ? parts.sublist(3).join(':')
                      : parts.length > 2 && priceStr.isEmpty
                          ? parts.sublist(2).join(':')
                          : (parts.length > 3 ? parts.sublist(3).join(':') : ''),
            );
          }).toList();

    return Birthday(
      id: map['id'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      imagePath: map['imagePath'] as String?,
      avatarColor: map['avatarColor'] as String?,
      isPremium: (map['isPremium'] as int?) == 1,
      reminderDaysBefore: (map['reminderDaysBefore'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList() ??
          [0, 1, 7],
      relationType: relationType,
      relations: relations,
      planningItems: planningItems,
      wishlistItems: wishlistItems,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Birthday copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? imagePath,
    String? avatarColor,
    bool? isPremium,
    List<int>? reminderDaysBefore,
    RelationType? relationType,
    List<Relation>? relations,
    List<PlanningItem>? planningItems,
    List<WishlistItem>? wishlistItems,
  }) {
    return Birthday(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      avatarColor: avatarColor ?? this.avatarColor,
      isPremium: isPremium ?? this.isPremium,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      relationType: relationType ?? this.relationType,
      relations: relations ?? this.relations,
      planningItems: planningItems ?? this.planningItems,
      wishlistItems: wishlistItems ?? this.wishlistItems,
      createdAt: createdAt,
    );
  }
}

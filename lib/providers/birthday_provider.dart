import 'package:flutter/foundation.dart';
import '../models/birthday.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class BirthdayProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();

  List<Birthday> _birthdays = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SortMode _sortMode = SortMode.upcoming;

  List<Birthday> get birthdays => _filteredAndSorted;
  List<Birthday> get allBirthdays => _birthdays;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  SortMode get sortMode => _sortMode;

  List<Birthday> get todaysBirthdays =>
      _birthdays.where((b) => b.isBirthdayToday).toList();

  List<Birthday> get upcomingBirthdays {
    final list = _birthdays.where((b) => !b.isBirthdayToday).toList();
    list.sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
    return list.take(5).toList();
  }

  List<Birthday> get _filteredAndSorted {
    var list = _birthdays.toList();

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    switch (_sortMode) {
      case SortMode.upcoming:
        list.sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
        break;
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.age:
        list.sort((a, b) => a.age.compareTo(b.age));
        break;
      case SortMode.recentlyAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  Map<int, List<Birthday>> get birthdaysByMonth {
    final map = <int, List<Birthday>>{};
    for (final b in _birthdays) {
      map.putIfAbsent(b.date.month, () => []).add(b);
    }
    return map;
  }

  Future<void> loadBirthdays() async {
    _isLoading = true;
    notifyListeners();

    _birthdays = await _db.getAllBirthdays();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBirthday(Birthday birthday) async {
    await _db.insertBirthday(birthday);
    await _notifications.scheduleBirthdayReminders(birthday);
    await loadBirthdays();
  }

  Future<void> updateBirthday(Birthday birthday) async {
    await _db.updateBirthday(birthday);
    await _notifications.scheduleBirthdayReminders(birthday);
    await loadBirthdays();
  }

  Future<void> deleteBirthday(String id) async {
    await _db.deleteBirthday(id);
    await _notifications.cancelBirthdayReminders(id);
    await loadBirthdays();
  }

  Future<void> importBirthdays(List<Birthday> birthdays) async {
    for (final birthday in birthdays) {
      await _db.insertBirthday(birthday);
      await _notifications.scheduleBirthdayReminders(birthday);
    }
    await loadBirthdays();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  Future<int> get birthdayCount => _db.getBirthdayCount();
}

enum SortMode { upcoming, name, age, recentlyAdded }

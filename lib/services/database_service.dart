import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/birthday.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'birthdays';
  static const String _treeLinksTable = 'tree_links';
  static const String _treeSettingsTable = 'tree_settings';
  static const String _webStorageKey = 'birthdays_data';

  // --- SQLite (mobile/desktop) ---

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'birthday_reminder.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            date TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            address TEXT,
            notes TEXT,
            imagePath TEXT,
            avatarColor TEXT,
            isPremium INTEGER DEFAULT 0,
            reminderDaysBefore TEXT DEFAULT '0,1,7',
            relationType INTEGER DEFAULT 1,
            relations TEXT DEFAULT '',
            planningItems TEXT DEFAULT '',
            wishlistItems TEXT DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');
        await _createTreeTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN address TEXT');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN relationType INTEGER DEFAULT 1');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN relations TEXT DEFAULT ""');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN planningItems TEXT DEFAULT ""');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN imagePath TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN wishlistItems TEXT DEFAULT ""');
        }
        if (oldVersion < 5) {
          await _createTreeTables(db);
        }
      },
    );
  }

  // --- Web fallback (SharedPreferences + JSON) ---

  Future<List<Birthday>> _webGetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_webStorageKey);
    if (jsonStr == null) return [];
    final List<dynamic> list = json.decode(jsonStr);
    return list.map((m) => Birthday.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<void> _webSaveAll(List<Birthday> birthdays) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(birthdays.map((b) => b.toMap()).toList());
    await prefs.setString(_webStorageKey, jsonStr);
  }

  // --- Public API (delegates to web or native) ---

  Future<List<Birthday>> getAllBirthdays() async {
    if (kIsWeb) return _webGetAll();
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'name ASC');
    return maps.map((map) => Birthday.fromMap(map)).toList();
  }

  Future<Birthday?> getBirthdayById(String id) async {
    if (kIsWeb) {
      final all = await _webGetAll();
      return all.where((b) => b.id == id).firstOrNull;
    }
    final db = await database;
    final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Birthday.fromMap(maps.first);
  }

  Future<void> insertBirthday(Birthday birthday) async {
    if (kIsWeb) {
      final all = await _webGetAll();
      all.removeWhere((b) => b.id == birthday.id);
      all.add(birthday);
      await _webSaveAll(all);
      return;
    }
    final db = await database;
    await db.insert(
      _tableName,
      birthday.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBirthday(Birthday birthday) async {
    if (kIsWeb) {
      final all = await _webGetAll();
      final idx = all.indexWhere((b) => b.id == birthday.id);
      if (idx >= 0) all[idx] = birthday;
      await _webSaveAll(all);
      return;
    }
    final db = await database;
    await db.update(
      _tableName,
      birthday.toMap(),
      where: 'id = ?',
      whereArgs: [birthday.id],
    );
  }

  Future<void> deleteBirthday(String id) async {
    if (kIsWeb) {
      final all = await _webGetAll();
      all.removeWhere((b) => b.id == id);
      await _webSaveAll(all);
      return;
    }
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getBirthdayCount() async {
    final all = await getAllBirthdays();
    return all.length;
  }

  Future<List<Birthday>> getUpcomingBirthdays({int days = 30}) async {
    final all = await getAllBirthdays();
    final upcoming = all.where((b) => b.daysUntilBirthday <= days).toList();
    upcoming.sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
    return upcoming;
  }

  Future<List<Birthday>> getTodaysBirthdays() async {
    final all = await getAllBirthdays();
    return all.where((b) => b.isBirthdayToday).toList();
  }

  Future<void> exportToCsv() async {
    // TODO: Implement CSV export for premium users
  }

  // ── Tree links & settings (SQLite) ─────────────────────

  static Future<void> _createTreeTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_treeLinksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parentId TEXT NOT NULL,
        childId TEXT NOT NULL,
        label TEXT NOT NULL,
        UNIQUE(parentId, childId)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_treeSettingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Migrate tree data from SharedPreferences to SQLite (run once)
  Future<void> migrateTreeDataFromPrefs() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool('tree_migrated_to_db') ?? false;
    if (alreadyMigrated) return;

    final db = await database;

    // Migrate tree_links
    final linksJson = prefs.getString('tree_links');
    if (linksJson != null) {
      final list = json.decode(linksJson) as List;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        await db.insert(_treeLinksTable, {
          'parentId': m['parentId'],
          'childId': m['childId'],
          'label': m['label'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // Migrate owner_name, owner_birthday, tree_locked, tree_drag_offsets
    final ownerName = prefs.getString('owner_name');
    final ownerBirthday = prefs.getString('owner_birthday');
    final treeLocked = prefs.getBool('tree_locked');
    final dragOffsets = prefs.getString('tree_drag_offsets');

    if (ownerName != null) {
      await db.insert(_treeSettingsTable, {'key': 'owner_name', 'value': ownerName},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    if (ownerBirthday != null) {
      await db.insert(_treeSettingsTable, {'key': 'owner_birthday', 'value': ownerBirthday},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    if (treeLocked != null) {
      await db.insert(_treeSettingsTable, {'key': 'tree_locked', 'value': treeLocked.toString()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    if (dragOffsets != null) {
      await db.insert(_treeSettingsTable, {'key': 'tree_drag_offsets', 'value': dragOffsets},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await prefs.setBool('tree_migrated_to_db', true);
  }

  // ── Tree links CRUD ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTreeLinks() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query(_treeLinksTable);
  }

  Future<void> saveTreeLinks(List<Map<String, dynamic>> links) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(_treeLinksTable);
    for (final link in links) {
      await db.insert(_treeLinksTable, {
        'parentId': link['parentId'],
        'childId': link['childId'],
        'label': link['label'],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> addTreeLink(String parentId, String childId, String label) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(_treeLinksTable, {
      'parentId': parentId,
      'childId': childId,
      'label': label,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteTreeLink(String parentId, String childId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(_treeLinksTable,
        where: 'parentId = ? AND childId = ?', whereArgs: [parentId, childId]);
  }

  // ── Tree settings CRUD ─────────────────────────────────

  Future<String?> getTreeSetting(String key) async {
    if (kIsWeb) return null;
    final db = await database;
    final rows = await db.query(_treeSettingsTable, where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setTreeSetting(String key, String value) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(_treeSettingsTable, {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

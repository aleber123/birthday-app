import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_reminder/models/birthday.dart';

void main() {
  group('Birthday model tests', () {
    test('age calculation is correct', () {
      final now = DateTime.now();
      final birthday = Birthday(
        id: '1',
        name: 'Test Person',
        date: DateTime(now.year - 30, now.month, now.day),
      );
      expect(birthday.age, 30);
    });

    test('daysUntilBirthday returns 0 for today', () {
      final now = DateTime.now();
      final birthday = Birthday(
        id: '2',
        name: 'Today Person',
        date: DateTime(1990, now.month, now.day),
      );
      expect(birthday.daysUntilBirthday, 0);
      expect(birthday.isBirthdayToday, true);
    });

    test('zodiac sign is correct for known dates', () {
      final birthday = Birthday(
        id: '3',
        name: 'Aries Person',
        date: DateTime(1990, 4, 5),
      );
      expect(birthday.zodiacKey, equals('zodiac_aries'));
    });

    test('toMap and fromMap roundtrip', () {
      final original = Birthday(
        id: 'test-id',
        name: 'Anna Svensson',
        date: DateTime(1995, 6, 15),
        phone: '0701234567',
        notes: 'Gillar blommor',
        reminderDaysBefore: [0, 1, 7],
      );
      final map = original.toMap();
      final restored = Birthday.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.date, original.date);
      expect(restored.phone, original.phone);
      expect(restored.notes, original.notes);
      expect(restored.reminderDaysBefore, original.reminderDaysBefore);
    });
  });
}

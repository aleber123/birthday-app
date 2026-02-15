import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../l10n/app_localizations.dart';
import '../models/birthday.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleBirthdayReminders(Birthday birthday) async {
    if (kIsWeb) return;
    await cancelBirthdayReminders(birthday.id);

    for (final daysBefore in birthday.reminderDaysBefore) {
      await _scheduleReminder(birthday, daysBefore);
    }
  }

  Future<void> _scheduleReminder(Birthday birthday, int daysBefore) async {
    final now = DateTime.now();
    DateTime nextBirthday = DateTime(now.year, birthday.date.month, birthday.date.day, 9, 0);

    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthday.date.month, birthday.date.day, 9, 0);
    }

    final reminderDate = nextBirthday.subtract(Duration(days: daysBefore));

    if (reminderDate.isBefore(now)) return;

    final notificationId = '${birthday.id}_$daysBefore'.hashCode.abs() % 2147483647;

    // Get system locale for notification text
    final systemLocale = PlatformDispatcher.instance.locale;
    final l = AppLocalizations(systemLocale);

    String title;
    String body;

    if (daysBefore == 0) {
      title = '🎂 ${l.get('notif_today_title')}';
      body = '${birthday.name} ${l.get('notif_today_body').replaceAll('{age}', '${birthday.turningAge}')}';
    } else if (daysBefore == 1) {
      title = '🎁 ${l.get('notif_tomorrow_title')}';
      body = '${birthday.name} ${l.get('notif_tomorrow_body').replaceAll('{age}', '${birthday.turningAge}')}';
    } else {
      title = '📅 ${l.get('notif_soon_title')}';
      body = '${birthday.name} ${l.get('notif_soon_body').replaceAll('{age}', '${birthday.turningAge}').replaceAll('{days}', '$daysBefore')}';
    }

    final androidDetails = AndroidNotificationDetails(
      'birthday_reminders',
      l.get('notif_channel_name'),
      channelDescription: l.get('notif_channel_desc'),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(reminderDate, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelBirthdayReminders(String birthdayId) async {
    if (kIsWeb) return;
    for (final daysBefore in [0, 1, 3, 7, 14, 30]) {
      final notificationId = '${birthdayId}_$daysBefore'.hashCode.abs() % 2147483647;
      await _notifications.cancel(notificationId);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  Future<void> rescheduleAllReminders(List<Birthday> birthdays) async {
    if (kIsWeb) return;
    await cancelAllNotifications();
    for (final birthday in birthdays) {
      await scheduleBirthdayReminders(birthday);
    }
  }
}

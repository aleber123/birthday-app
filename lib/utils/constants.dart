import '../l10n/app_localizations.dart';

class AppConstants {
  static const int freeMaxBirthdays = 10;
  static const List<int> freeReminderOptions = [0, 1, 7];
  static const List<int> premiumReminderOptions = [0, 1, 3, 7, 14, 30];

  static const String appName = 'Födelsedagar';
  static const String appVersion = '1.0.0';

  // GitHub Pages URLs (App Store required)
  static const String privacyPolicyUrl = 'https://aleber123.github.io/birthday-app/privacy.html';
  static const String termsOfUseUrl = 'https://aleber123.github.io/birthday-app/terms.html';
  static const String supportUrl = 'https://aleber123.github.io/birthday-app/support.html';
  static const String supportEmail = 'support@alexanderbergqvist.com';
  static const String appStoreUrl = 'https://apps.apple.com/app/fodelsedagar/id6742128498';

  static String formatDaysUntil(int days, AppLocalizations l) {
    if (days == 0) return l.get('today_excl');
    if (days == 1) return l.get('tomorrow');
    if (days < 7) return l.get('days_format').replaceAll('{days}', '$days');
    if (days < 30) {
      final weeks = days ~/ 7;
      return weeks == 1
          ? l.get('weeks_format_1')
          : l.get('weeks_format').replaceAll('{weeks}', '$weeks');
    }
    if (days < 365) {
      final months = days ~/ 30;
      return months == 1
          ? l.get('months_format_1')
          : l.get('months_format').replaceAll('{months}', '$months');
    }
    return l.get('days_format').replaceAll('{days}', '$days');
  }
}

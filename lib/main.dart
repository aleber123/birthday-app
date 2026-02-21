import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/birthday_provider.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'services/premium_service.dart';
import 'services/theme_service.dart';
import 'services/facebook_analytics_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('sv_SE', null);

  if (!kIsWeb) {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
  }

  final premiumService = PremiumService();
  await premiumService.initialize();

  final themeService = ThemeService();
  await themeService.initialize();

  await AdService().initialize();

  runApp(const BirthdayReminderApp());
}

class BirthdayReminderApp extends StatelessWidget {
  const BirthdayReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BirthdayProvider()),
        ChangeNotifierProvider(create: (_) => PremiumService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'Födelsedagar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeService.primaryColor,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeService.primaryColor,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: ThemeMode.system,
        supportedLocales: const [
          Locale('sv'),
          Locale('nb'),
          Locale('da'),
          Locale('fi'),
          Locale('is'),
          Locale('en'),
        ],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
            home: const _SplashWrapper(),
          );
        },
      ),
    );
  }
}

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  bool _showHome = false;

  @override
  Widget build(BuildContext context) {
    if (_showHome) return const HomeScreen();

    return SplashScreen(
      onComplete: () async {
        if (!mounted) return;
        setState(() => _showHome = true);
        await AttPermissionHandler.requestAndInit();
      },
    );
  }
}

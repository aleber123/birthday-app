import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorTheme {
  violet,   // Default
  ocean,
  sunset,
  forest,
  rose,
  midnight,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_color_theme';

  AppColorTheme _currentTheme = AppColorTheme.violet;
  AppColorTheme get currentTheme => _currentTheme;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 0;
    _currentTheme = AppColorTheme.values[index.clamp(0, AppColorTheme.values.length - 1)];
    notifyListeners();
  }

  Future<void> setTheme(AppColorTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  Color get primaryColor => themeColors[_currentTheme]!['primary']!;
  Color get secondaryColor => themeColors[_currentTheme]!['secondary']!;
  Color get accentColor => themeColors[_currentTheme]!['accent']!;

  String themeName(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.violet:
        return 'Violett';
      case AppColorTheme.ocean:
        return 'Hav';
      case AppColorTheme.sunset:
        return 'Solnedg\u00e5ng';
      case AppColorTheme.forest:
        return 'Skog';
      case AppColorTheme.rose:
        return 'Ros\u00e9';
      case AppColorTheme.midnight:
        return 'Midnatt';
    }
  }

  static const Map<AppColorTheme, Map<String, Color>> themeColors = {
    AppColorTheme.violet: {
      'primary': Color(0xFF7C5CFC),
      'secondary': Color(0xFFFF6B8A),
      'accent': Color(0xFF6EE7B7),
    },
    AppColorTheme.ocean: {
      'primary': Color(0xFF0EA5E9),
      'secondary': Color(0xFF38BDF8),
      'accent': Color(0xFF67E8F9),
    },
    AppColorTheme.sunset: {
      'primary': Color(0xFFF97316),
      'secondary': Color(0xFFFB923C),
      'accent': Color(0xFFFBBF24),
    },
    AppColorTheme.forest: {
      'primary': Color(0xFF059669),
      'secondary': Color(0xFF34D399),
      'accent': Color(0xFF6EE7B7),
    },
    AppColorTheme.rose: {
      'primary': Color(0xFFE11D48),
      'secondary': Color(0xFFF472B6),
      'accent': Color(0xFFFDA4AF),
    },
    AppColorTheme.midnight: {
      'primary': Color(0xFF6366F1),
      'secondary': Color(0xFF818CF8),
      'accent': Color(0xFFA5B4FC),
    },
  };
}

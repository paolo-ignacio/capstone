import 'package:flutter/material.dart';
import 'package:legallyai/components/dark_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load saved theme from shared preferences
  void _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  // Toggle theme and save preference
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? legallyAiTheme : lightTheme;
  }

  // Light theme definition
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    primaryColor: const Color(0xFFD4AF37),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFF8e84cc),
      background: Color(0xFFF5F5F5),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.black,
    ),
    // Customize other components here for light theme...
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Load saved theme from SharedPreferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme');

    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // Toggle and save theme
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await prefs.setString('theme', 'dark');
    } else {
      _themeMode = ThemeMode.light;
      await prefs.setString('theme', 'light');
    }
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}

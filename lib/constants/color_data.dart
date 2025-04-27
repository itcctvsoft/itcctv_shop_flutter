// ignore: file_names
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme controller with palette support
class ThemeController {
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _themeIndexKey = 'themeIndex';

  static bool _isDarkMode = false;
  static int _currentThemeIndex = 0;

  // Global key to force rebuild application
  static final GlobalKey appKey = GlobalKey();

  // Available theme palettes
  static final List<ThemePalette> themePalettes = [
    ThemePalette(
      name: "Teal",
      primary: "#146C62",
      primaryDark: "#10544D",
      accent: "#27AE60",
    ),
    ThemePalette(
      name: "Purple",
      primary: "#673AB7",
      primaryDark: "#512DA8",
      accent: "#9C27B0",
    ),
    ThemePalette(
      name: "Blue",
      primary: "#2196F3",
      primaryDark: "#1976D2",
      accent: "#03A9F4",
    ),
    ThemePalette(
      name: "Amber",
      primary: "#FF9800",
      primaryDark: "#F57C00",
      accent: "#FFC107",
    ),
    ThemePalette(
      name: "Red",
      primary: "#F44336",
      primaryDark: "#D32F2F",
      accent: "#FF5722",
    ),
    ThemePalette(
      name: "Pink",
      primary: "#E91E63",
      primaryDark: "#C2185B",
      accent: "#FF4081",
    ),
    ThemePalette(
      name: "Green",
      primary: "#4CAF50",
      primaryDark: "#388E3C",
      accent: "#8BC34A",
    ),
    ThemePalette(
      name: "Cyan",
      primary: "#00BCD4",
      primaryDark: "#0097A7",
      accent: "#84FFFF",
    ),
    ThemePalette(
      name: "Orange",
      primary: "#FF5722",
      primaryDark: "#E64A19",
      accent: "#FF9E80",
    ),
    ThemePalette(
      name: "Brown",
      primary: "#795548",
      primaryDark: "#5D4037",
      accent: "#A1887F",
    ),
    ThemePalette(
      name: "Indigo",
      primary: "#3F51B5",
      primaryDark: "#303F9F",
      accent: "#536DFE",
    ),
    // Thêm màu tím mộng mơ
    ThemePalette(
      name: "Dreamy Purple",
      primary: "#9C73B5",
      primaryDark: "#7D5A94",
      accent: "#C498DE",
    ),
    // Thêm màu xanh ngọc (Turquoise)
    ThemePalette(
      name: "Turquoise",
      primary: "#1ABC9C",
      primaryDark: "#16A085",
      accent: "#4ECDC4",
    ),
    // Thêm màu hồng san hô (Coral)
    ThemePalette(
      name: "Coral",
      primary: "#FF6B6B",
      primaryDark: "#E84855",
      accent: "#FF9D9D",
    ),
    // Thêm màu xanh bạc hà (Mint)
    ThemePalette(
      name: "Mint",
      primary: "#2BC275",
      primaryDark: "#219959",
      accent: "#5EDBA3",
    ),
    // Thêm màu tím lavender
    ThemePalette(
      name: "Lavender",
      primary: "#9883E5",
      primaryDark: "#7B65D1",
      accent: "#BFB3FA",
    ),
    // Thêm màu vàng nghệ (Mustard)
    ThemePalette(
      name: "Mustard",
      primary: "#E3B505",
      primaryDark: "#C49B04",
      accent: "#F5D547",
    ),
    // Thêm màu xanh biển (Ocean)
    ThemePalette(
      name: "Ocean",
      primary: "#3A7BD5",
      primaryDark: "#2F63AA",
      accent: "#5B9CEF",
    ),
  ];

  // Theme listeners
  static final List<Function()> _listeners = [];

  // Initialize theme from preferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
    _currentThemeIndex = prefs.getInt(_themeIndexKey) ?? 0;
  }

  // Get current theme mode
  static bool get isDarkMode => _isDarkMode;

  // Get current theme index
  static int get currentThemeIndex => _currentThemeIndex;

  // Get current theme palette
  static ThemePalette get currentTheme => themePalettes[_currentThemeIndex];

  // Toggle theme mode
  static Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, _isDarkMode);

    // Notify listeners
    notifyListeners();

    // Force update MaterialApp to rebuild with new theme
    _refreshApp();
  }

  // Change theme palette
  static Future<void> setTheme(int index) async {
    if (index >= 0 && index < themePalettes.length) {
      _currentThemeIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeIndexKey, _currentThemeIndex);

      // Notify listeners
      notifyListeners();

      // Force update MaterialApp to rebuild with new theme
      _refreshApp();
    }
  }

  // Force update entire app by posting a frame callback
  static void _refreshApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This forces most widgets to rebuild in the next frame
      appKey.currentState?.setState(() {});
    });
  }

  // Notify all listeners
  static void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Add listener for theme changes
  static void addListener(Function() listener) {
    _listeners.add(listener);
  }

  // Remove listener
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
}

// Theme palette data class
class ThemePalette {
  final String name;
  final String primary;
  final String primaryDark;
  final String accent;

  ThemePalette({
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.accent,
  });

  Color get primaryColor => primary.toColor();
  Color get primaryDarkColor => primaryDark.toColor();
  Color get accentColor => accent.toColor();
}

// Light theme colors
class LightThemeColors {
  static Color get primaryColor => ThemeController.currentTheme.primaryColor;
  static Color get primaryDarkColor =>
      ThemeController.currentTheme.primaryDarkColor;
  static Color get accentColor => ThemeController.currentTheme.accentColor;
  static Color backgroundColor = "#F9F9F9".toColor();
  static Color fontBlack = "#000000".toColor();
  static Color fontLight = "#FFFFFF".toColor();
  static Color greyFont = "#616161".toColor();
  static Color cardColor = Colors.white;
  static Color shadowColor = Colors.black12;
  static Color dividerColor = Colors.grey.shade200;
  static Color get iconColor => primaryColor;
  static Color get appBarColor => primaryColor;
  static Color get buttonColor => primaryColor;
}

// Dark theme colors
class DarkThemeColors {
  // Generate darker versions for dark mode
  static Color get primaryColor =>
      ThemeController.currentTheme.primaryColor.withOpacity(0.8);
  static Color get primaryDarkColor =>
      ThemeController.currentTheme.primaryDarkColor.withOpacity(0.8);
  static Color get accentColor =>
      ThemeController.currentTheme.accentColor.withOpacity(0.9);
  static Color backgroundColor = "#121212".toColor();
  static Color secondaryBackground = "#1E1E1E".toColor();
  static Color fontBlack = "#FFFFFF".toColor();
  static Color fontLight = "#FFFFFF".toColor();
  static Color greyFont = "#B0B0B0".toColor();
  static Color cardColor = "#1E1E1E".toColor();
  static Color shadowColor = Colors.black45;
  static Color dividerColor = Colors.grey.shade800;
  static Color get iconColor => accentColor;
  static Color get appBarColor => primaryColor;
  static Color get buttonColor => primaryColor;
}

// Dynamic color accessor based on current theme
class AppColors {
  static Color get primaryColor => ThemeController.isDarkMode
      ? DarkThemeColors.primaryColor
      : LightThemeColors.primaryColor;

  static Color get primaryDarkColor => ThemeController.isDarkMode
      ? DarkThemeColors.primaryDarkColor
      : LightThemeColors.primaryDarkColor;

  static Color get accentColor => ThemeController.isDarkMode
      ? DarkThemeColors.accentColor
      : LightThemeColors.accentColor;

  static Color get backgroundColor => ThemeController.isDarkMode
      ? DarkThemeColors.backgroundColor
      : LightThemeColors.backgroundColor;

  static Color get fontBlack => ThemeController.isDarkMode
      ? DarkThemeColors.fontBlack
      : LightThemeColors.fontBlack;

  static Color get fontLight => LightThemeColors.fontLight; // Always white

  static Color get greyFont => ThemeController.isDarkMode
      ? DarkThemeColors.greyFont
      : LightThemeColors.greyFont;

  static Color get cardColor => ThemeController.isDarkMode
      ? DarkThemeColors.cardColor
      : LightThemeColors.cardColor;

  static Color get shadowColor => ThemeController.isDarkMode
      ? DarkThemeColors.shadowColor
      : LightThemeColors.shadowColor;

  static Color get dividerColor => ThemeController.isDarkMode
      ? DarkThemeColors.dividerColor
      : LightThemeColors.dividerColor;

  static Color get iconColor => ThemeController.isDarkMode
      ? DarkThemeColors.iconColor
      : LightThemeColors.iconColor;

  static Color get appBarColor => ThemeController.isDarkMode
      ? DarkThemeColors.appBarColor
      : LightThemeColors.appBarColor;

  static Color get buttonColor => ThemeController.isDarkMode
      ? DarkThemeColors.buttonColor
      : LightThemeColors.buttonColor;
}

// For backward compatibility
Color get primaryColor => AppColors.primaryColor;
Color get backgroundColor => AppColors.backgroundColor;
Color get fontBlack => AppColors.fontBlack;
Color get greyFont => AppColors.greyFont;
Color get cardColor => AppColors.cardColor;
Color get shadowColor => AppColors.shadowColor;

extension ColorExtension on String {
  toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }
}

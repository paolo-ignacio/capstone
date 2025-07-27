import 'package:flutter/material.dart';

final ThemeData legallyAiLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8F8F9),
  primaryColor: const Color(0xFFD4AF37),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFD4AF37),
    secondary: Color(0xFF1C1C2E),
    background: Color(0xFFF8F8F9),
    surface: Colors.white,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.black,
  ),

  // AppBar uses dark theme color
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1C1C2E),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),

  // FloatingActionButton
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFD4AF37),
    foregroundColor: Colors.black,
  ),

  // ElevatedButton
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD4AF37),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),

  // Input fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF0F0F2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Colors.black45),
    labelStyle: const TextStyle(color: Colors.black87),
  ),

  // Cards — optionally also use dark color for contrast
  cardTheme: CardTheme(
    color: const Color(0xFF1C1C2E), // Retained dark color for contrast
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 6,
    shadowColor: Colors.black26,
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
  ),

  // ListTile
  listTileTheme: const ListTileThemeData(
    tileColor: Colors.white,
    iconColor: Color(0xFFD4AF37),
    textColor: Colors.black,
  ),

  // Chip
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFE6E6EB),
    selectedColor: const Color(0xFFD4AF37),
    secondarySelectedColor: const Color(0xFFD4AF37),
    labelStyle: const TextStyle(color: Colors.black),
    secondaryLabelStyle: const TextStyle(color: Colors.black),
    brightness: Brightness.light,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),

  // Text styles
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54, fontSize: 11),
    titleMedium: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
    labelLarge: TextStyle(color: Colors.black),
  ),
);

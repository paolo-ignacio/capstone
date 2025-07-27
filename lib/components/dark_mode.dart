import 'package:flutter/material.dart';

final ThemeData legallyAiTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1C1C2E),
  primaryColor: const Color(0xFFD4AF37),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFD4AF37),
    secondary: Color(0xFF8e84cc),
    background: Color(0xFF1C1C2E),
    surface: Color(0xFF2A2A3C),
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onSurface: Colors.white,
  ),

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2A2A3C),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),

  // FAB
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

  // TextField / InputDecoration
  // inputDecorationTheme: InputDecorationTheme(
  //   filled: true,
  //   //fillColor: const Color(0xFF2A2A3C),
  //   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //   border: OutlineInputBorder(
  //     borderRadius: BorderRadius.circular(12),
  //     borderSide: BorderSide.none,
  //   ),
  //   hintStyle: const TextStyle(color: Colors.white54),
  //   labelStyle: const TextStyle(color: Colors.white70),
  // ),

  // Card
  // cardTheme: CardTheme(
  //   color: const Color(0xFF2A2A3C),
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(16),
  //   ),
  //   elevation: 6,
  //   shadowColor: Colors.black45,
  //   margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
  // ),

  // ListTile
  // listTileTheme: const ListTileThemeData(
  //   //tileColor: Color(0xFF2A2A3C),
  //   //tileColor: Colors.white,
  //   iconColor: Color(0xFFD4AF37),
  //   textColor: Colors.white,
  // ),

  // Chip
  // chipTheme: ChipThemeData(
  //   //backgroundColor: const Color(0xFF3A3A4D),
  //   selectedColor: const Color(0xFFD4AF37),
  //   secondarySelectedColor: const Color(0xFFD4AF37),
  //   labelStyle: const TextStyle(color: Colors.white),
  //   secondaryLabelStyle: const TextStyle(color: Colors.black),
  //   brightness: Brightness.dark,
  //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  // ),

  // Text
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black87, fontSize: 11),
    titleMedium: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
    labelLarge: TextStyle(color: Colors.black),
  ),
);

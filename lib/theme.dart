import 'package:flutter/material.dart';

const Color _nexoraDark = Color(0xFF0E1A2B); // deep navy blue
const Color _nexoraGold = Color(0xFFE3B857); // gold/muted yellow
const Color _darkGray = Color(0xFF1A2A3F); // slightly lighter navy
const Color _lightGray = Color(0xFFB0B8C1); // light gray
const Color _darkGrayText = Color(0xFF6B7280); // darker gray for disabled

final ThemeData nexoraTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: _nexoraDark,
  scaffoldBackgroundColor: _nexoraDark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _nexoraGold,
    brightness: Brightness.dark,
    primary: _nexoraGold,
    secondary: _nexoraGold,
    surface: _darkGray,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _nexoraDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _nexoraDark,
    selectedItemColor: _nexoraGold,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
  ),
  cardColor: _darkGray,
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _nexoraGold, width: 2),
    ),
    hintStyle: const TextStyle(color: _lightGray),
    labelStyle: const TextStyle(color: Colors.white),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: _lightGray,
      fontSize: 14,
    ),
    labelMedium: TextStyle(
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _nexoraGold,
      foregroundColor: _nexoraDark,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      backgroundColor: _nexoraDark,
      foregroundColor: Colors.white,
      side: const BorderSide(color: _nexoraGold, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _nexoraGold,
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
);

import 'package:flutter/material.dart';

const Color _nexoraDark = Color(0xFF072146); // dark blue
const Color _nexoraGold = Color(0xFFCF9A2B); // gold

final ThemeData nexoraTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: _nexoraDark,
  scaffoldBackgroundColor: _nexoraDark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _nexoraGold,
    brightness: Brightness.dark,
    primary: _nexoraDark,
    secondary: _nexoraGold,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _nexoraDark,
    elevation: 0,
    centerTitle: true,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _nexoraDark,
    selectedItemColor: _nexoraGold,
    unselectedItemColor: Colors.white70,
  ),
  cardColor: Color(0xFF0B3554),
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);

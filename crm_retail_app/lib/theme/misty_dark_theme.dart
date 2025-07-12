import 'package:flutter/material.dart';

final ThemeData mistyDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1A1D23),
  primaryColor: const Color(0xFF6C8EFF), // misty blue
  secondaryHeaderColor: const Color(0xFF8796B4), // muted mist
  hintColor: const Color(0xFFB4C0D3), // light mist
  canvasColor: const Color(0xFF252A34),
  cardColor: const Color(0xFF2F3543),
  dividerColor: Colors.white10,
  shadowColor: Colors.black45,
  fontFamily: 'Roboto',

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF232834),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF6C8EFF),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF2A2F3A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    labelStyle: TextStyle(color: Color(0xFFB4C0D3)),
    hintStyle: TextStyle(color: Colors.white38),
    prefixIconColor: Color(0xFF8796B4),
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFDBE2EF)),
    bodyMedium: TextStyle(color: Color(0xFFBFCBD9)),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Color(0xFFB4C0D3)),
  ),
);

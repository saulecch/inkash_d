import 'package:flutter/material.dart';

const kFondo = Color(0xFF0E120C);
const kSuperficie = Color(0xFF181E14);
const kBorde = Color(0xFF2A3222);
const kTexto = Color(0xFFF1F4EA);
const kMuted = Color(0xFF8F9C80);
const kLima = Color(0xFFC8F54E);
const kIconoFondo = Color(0xFF37491C);
const kPeligro = Color(0xFFFF8A80);

ThemeData buildInkashTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kFondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kLima,
      brightness: Brightness.dark,
      surface: kSuperficie,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kFondo,
      foregroundColor: kTexto,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: kSuperficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: kBorde),
      ),
    ),
  );
}

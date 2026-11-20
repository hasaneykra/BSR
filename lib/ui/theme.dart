import 'package:flutter/material.dart';

const brand = Color(0xFF006A4E);
const gold = Color(0xFFC9A227);

ThemeData buildTheme(Brightness b) {
  final cs = ColorScheme.fromSeed(seedColor: brand, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: cs.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: cs.onSurface)),
    ),
  );
}

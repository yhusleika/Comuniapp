import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF416FDF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF6EAEE7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFDF2020),
  onError: Color(0xFFFFFFFF),
  background: Color(0xfffcfdf6),
  onBackground: Color(0xff1a1c18),
  shadow: Color(0xff000000),
  outlineVariant: Color(0xffc2c88c),
  surface: Color(0xfff9faf3),
  onSurface: Color(0xff1a1c18),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5A8DF3),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF8DC0EE),
  onSecondary: Color(0xFF10304C),
  error: Color(0xFFCF6679),
  onError: Color(0xFF000000),
  background: Color(0xFF121212),
  onBackground: Color(0xFFE1E1E1),
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFF3E3F42),
  surface: Color(0xFF1E1E1E),
  onSurface: Color(0xFFE1E1E1),
);

class AppTheme {
  ThemeData getTheme(bool isDark) {
    final scheme = isDark ? darkColorScheme : lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1a1c18),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1a1c18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            scheme.primary,
          ),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          elevation: MaterialStateProperty.all<double>(5.0),
          padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      ),
    );
  }
}

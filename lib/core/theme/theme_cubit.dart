import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox('app_preferences');
      final isDark = box.get('is_dark_theme', defaultValue: false);
      emit(isDark ? ThemeMode.dark : ThemeMode.light);
    } catch (_) {
      emit(ThemeMode.light);
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    try {
      final box = await Hive.openBox('app_preferences');
      await box.put('is_dark_theme', isDark);
      emit(isDark ? ThemeMode.dark : ThemeMode.light);
    } catch (_) {
      emit(isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/settings/settings_cubit.dart';
import 'package:efteqad/core/settings/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  Locale currentLocale = const Locale('ar', 'EG');
  ThemeMode currentTheme = ThemeMode.light;

  @override
  Future<Locale> loadLocale() async => currentLocale;

  @override
  Future<void> saveLocale(Locale locale) async {
    currentLocale = locale;
  }

  @override
  Future<ThemeMode> loadThemeMode() async => currentTheme;

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    currentTheme = themeMode;
  }
}

void main() {
  group('SettingsCubit Unit Tests', () {
    test('loads default values on initialization', () async {
      final repo = MockSettingsRepository();
      final cubit = SettingsCubit(repository: repo);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.locale, const Locale('ar', 'EG'));
      expect(cubit.state.themeMode, ThemeMode.light);
      expect(cubit.state.isLoaded, isTrue);
      expect(cubit.state.isArabic, isTrue);
    });

    test('switches and persists locale correctly', () async {
      final repo = MockSettingsRepository();
      final cubit = SettingsCubit(repository: repo);

      await cubit.setLocale(const Locale('en', 'US'));

      expect(cubit.state.locale, const Locale('en', 'US'));
      expect(cubit.state.isArabic, isFalse);
      expect(repo.currentLocale, const Locale('en', 'US'));
    });

    test('switches and persists themeMode correctly', () async {
      final repo = MockSettingsRepository();
      final cubit = SettingsCubit(repository: repo);

      await cubit.setThemeMode(ThemeMode.dark);

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(repo.currentTheme, ThemeMode.dark);
    });
  });
}

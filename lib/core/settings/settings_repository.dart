import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsRepository {
  Future<Locale> loadLocale();
  Future<void> saveLocale(Locale locale);
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode themeMode);
}

abstract class AccountLocaleIntentRepository {
  Future<Map<String, String>> loadLocaleIntents();
  Future<void> saveLocaleIntents(Map<String, String> intents);
}

class SharedPrefsSettingsRepository
    implements SettingsRepository, AccountLocaleIntentRepository {
  final Future<SharedPreferences> _prefsFuture;

  SharedPrefsSettingsRepository({Future<SharedPreferences>? prefsFuture})
    : _prefsFuture = prefsFuture ?? SharedPreferences.getInstance();

  @override
  Future<Map<String, String>> loadLocaleIntents() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString('pref_account_locale_intents');
    if (raw == null) return {};
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return {};
      return {
        for (final entry in value.entries)
          if (entry.key is String &&
              (entry.key as String).isNotEmpty &&
              {'ar', 'en'}.contains(entry.value))
            entry.key as String: entry.value as String,
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> saveLocaleIntents(Map<String, String> intents) async {
    final prefs = await _prefsFuture;
    if (!await prefs.setString(
      'pref_account_locale_intents',
      jsonEncode(intents),
    )) {
      throw StateError('Preference intent could not be persisted.');
    }
  }

  @override
  Future<Locale> loadLocale() async {
    final prefs = await _prefsFuture;
    final code = prefs.getString('pref_locale_code');
    if (code == 'en') return const Locale('en', 'US');
    return const Locale('ar', 'EG');
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    final prefs = await _prefsFuture;
    await prefs.setString('pref_locale_code', locale.languageCode);
  }

  @override
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await _prefsFuture;
    final mode = prefs.getString('pref_theme_mode');
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'system') return ThemeMode.system;
    return ThemeMode.light;
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await _prefsFuture;
    await prefs.setString('pref_theme_mode', themeMode.name);
  }
}

/// Writes only the signed-in profile's preference; offline failures never clear
/// the already persisted device preference. Rules independently enforce scope.
class AccountLocaleRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  AccountLocaleRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;
  Future<void> saveLocale(String uid, String locale) async {
    if (auth.currentUser?.uid != uid) {
      throw StateError('Account identity changed.');
    }
    final reference = firestore.collection('khodam').doc(uid);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (auth.currentUser?.uid != uid ||
          !snapshot.exists ||
          snapshot.data()?['status'] == 'deleting') {
        throw StateError('Account profile is not eligible.');
      }
      transaction.update(reference, {'locale': locale});
    });
  }
}

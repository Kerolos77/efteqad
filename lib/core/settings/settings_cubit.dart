import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_repository.dart';

class SettingsState {
  final Locale locale;
  final ThemeMode themeMode;
  final bool isLoaded;
  const SettingsState({
    this.locale = const Locale('ar', 'EG'),
    this.themeMode = ThemeMode.light,
    this.isLoaded = false,
  });
  bool get isArabic => locale.languageCode == 'ar';
  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? isLoaded,
  }) => SettingsState(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    isLoaded: isLoaded ?? this.isLoaded,
  );
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  final Future<void> Function(String uid, String locale)? saveAccountLocale;
  final Future<void> Function(String uid, String locale)? syncDeviceLocale;
  final Future<void> Function(Locale locale)? updateNotificationLocale;
  late final Future<void> ready;
  String? _accountUid, _reconciledUid;
  int _accountGeneration = 0, _localeRevision = 0;
  Map<String, String> _pendingLocales = {};
  Future<void> _localChanges = Future.value(),
      _accountChanges = Future.value(),
      _channelChanges = Future.value();
  bool get hasPendingAccountLocale =>
      _accountUid != null && _pendingLocales.containsKey(_accountUid);
  SettingsCubit({
    required SettingsRepository repository,
    this.saveAccountLocale,
    this.syncDeviceLocale,
    this.updateNotificationLocale,
  }) : _repository = repository,
       super(const SettingsState()) {
    ready = loadSettings();
  }
  Future<void> loadSettings() async {
    final locale = await _repository.loadLocale();
    final theme = await _repository.loadThemeMode();
    final repository = _repository;
    if (repository is AccountLocaleIntentRepository) {
      _pendingLocales = await (repository as AccountLocaleIntentRepository)
          .loadLocaleIntents();
    }
    if (!isClosed) {
      emit(state.copyWith(locale: locale, themeMode: theme, isLoaded: true));
    }
  }

  Future<void> _persistIntents() async {
    final repository = _repository;
    if (repository is AccountLocaleIntentRepository) {
      await (repository as AccountLocaleIntentRepository).saveLocaleIntents(
        Map.of(_pendingLocales),
      );
    }
  }

  Future<void> _enqueueLocal(Future<void> Function() work) {
    final operation = _localChanges.then((_) => work());
    _localChanges = operation.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> _updateChannel(int revision) {
    final operation = _channelChanges.then((_) async {
      if (isClosed || revision != _localeRevision) return;
      await updateNotificationLocale?.call(state.locale);
    });
    _channelChanges = operation.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  /// Remote writes are serialized separately from local rendering. An older
  /// request cannot overwrite a newer selection or rebind a replaced account.
  Future<void> _syncAccount(String uid, int generation, int revision) {
    final operation = _accountChanges.then((_) async {
      if (isClosed ||
          uid != _accountUid ||
          generation != _accountGeneration ||
          revision != _localeRevision) {
        return;
      }
      final locale = state.locale.languageCode;
      Object? failure;
      if (_pendingLocales[uid] == locale && saveAccountLocale != null) {
        try {
          await saveAccountLocale!(uid, locale);
          if (uid == _accountUid &&
              generation == _accountGeneration &&
              revision == _localeRevision &&
              _pendingLocales[uid] == locale) {
            _pendingLocales.remove(uid);
            await _persistIntents();
          }
        } catch (error) {
          failure = error;
        }
      }
      if (isClosed ||
          uid != _accountUid ||
          generation != _accountGeneration ||
          revision != _localeRevision) {
        return;
      }
      try {
        await syncDeviceLocale?.call(uid, locale);
      } catch (error) {
        failure ??= error;
      }
      if (failure != null) throw failure;
    });
    _accountChanges = operation.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  /// Account preference applies once on login. A pending explicit local choice
  /// takes priority until its own profile write is acknowledged by the server.
  Future<void> reconcileAccount({
    String? uid,
    String? locale,
    bool canAttach = false,
  }) async {
    await ready;
    final nextUid = canAttach ? uid : null;
    if (nextUid != _accountUid) {
      _accountUid = nextUid;
      _accountGeneration++;
    }
    if (nextUid == null) {
      _reconciledUid = null;
      return;
    }
    final pending = _pendingLocales[nextUid];
    if (pending != null) {
      _reconciledUid = nextUid;
      final revision = _localeRevision, generation = _accountGeneration;
      await _enqueueLocal(() async {
        if (nextUid != _accountUid ||
            generation != _accountGeneration ||
            revision != _localeRevision ||
            _pendingLocales[nextUid] != pending) {
          return;
        }
        final selected = Locale(pending, pending == 'ar' ? 'EG' : 'US');
        await _repository.saveLocale(selected);
        if (!isClosed) emit(state.copyWith(locale: selected));
      });
      await _updateChannel(revision);
      await _syncAccount(nextUid, generation, revision);
      return;
    }
    if (_reconciledUid == nextUid) return;
    _reconciledUid = nextUid;
    if (locale == 'ar' || locale == 'en') {
      final revision = ++_localeRevision, generation = _accountGeneration;
      await _enqueueLocal(() async {
        if (nextUid != _accountUid ||
            generation != _accountGeneration ||
            revision != _localeRevision) {
          return;
        }
        final selected = Locale(locale!, locale == 'ar' ? 'EG' : 'US');
        await _repository.saveLocale(selected);
        if (!isClosed) emit(state.copyWith(locale: selected));
      });
    }
  }

  Future<void> setLocale(Locale locale) async {
    await ready;
    if (!{'ar', 'en'}.contains(locale.languageCode)) {
      throw ArgumentError('Unsupported locale.');
    }
    final selected = Locale(
      locale.languageCode,
      locale.languageCode == 'ar' ? 'EG' : 'US',
    );
    final revision = ++_localeRevision,
        generation = _accountGeneration,
        uid = _accountUid;
    await _enqueueLocal(() async {
      await _repository.saveLocale(selected);
      if (!isClosed) emit(state.copyWith(locale: selected));
      if (uid != null &&
          uid == _accountUid &&
          generation == _accountGeneration &&
          saveAccountLocale != null) {
        _pendingLocales[uid] = selected.languageCode;
        await _persistIntents();
      }
    });
    if (isClosed || revision != _localeRevision) return;
    Object? failure;
    try {
      await _updateChannel(revision);
    } catch (error) {
      failure = error;
    }
    if (uid != null) {
      try {
        await _syncAccount(uid, generation, revision);
      } catch (error) {
        failure ??= error;
      }
    }
    if (revision == _localeRevision && failure != null) throw failure;
  }

  Future<void> refreshDeviceLocale() async {
    await ready;
    final uid = _accountUid;
    if (uid == null) return;
    await _syncAccount(uid, _accountGeneration, _localeRevision);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await ready;
    await _repository.saveThemeMode(themeMode);
    if (!isClosed) emit(state.copyWith(themeMode: themeMode));
  }
}

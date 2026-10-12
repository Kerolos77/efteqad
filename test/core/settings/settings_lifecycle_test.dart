import 'package:efteqad/core/models/task_model.dart';
import 'package:efteqad/features/tasks/presentation/screens/task_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import '../services/device_registration_service_test.dart'
    show
        MockDeviceRegistrationStore,
        AuthRestrictedDeviceStore,
        InstallationTokenBoundary;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:efteqad/core/settings/settings_cubit.dart';
import 'package:efteqad/core/settings/settings_repository.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/features/auth/presentation/screens/login_screen.dart';
import 'package:efteqad/main.dart';
import '../router/app_router_test.dart' show MockSessionCubit;
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/repositories/auth_repository.dart';
import '../session/session_cubit_test.dart' show FakeProfileRepository;

class SdkAuthBoundary implements AuthRepository {
  final changes = StreamController<AuthIdentity?>.broadcast(sync: true);
  @override
  AuthIdentity? currentAuth;
  void sdkIdentityChanged(String? uid) {
    currentAuth = uid == null ? null : AuthIdentity(uid: uid);
    changes.add(currentAuth);
  }

  @override
  Stream<AuthIdentity?> watchAuth() => changes.stream;
  @override
  Future<void> signOut() async => sdkIdentityChanged(null);
}

class SavedPreferences implements SettingsRepository {
  Locale locale = const Locale('en', 'US');
  ThemeMode theme = ThemeMode.dark;
  Completer<Locale>? waiting;
  @override
  Future<Locale> loadLocale() async => waiting?.future ?? locale;
  @override
  Future<ThemeMode> loadThemeMode() async => theme;
  @override
  Future<void> saveLocale(Locale value) async {
    locale = value;
  }

  @override
  Future<void> saveThemeMode(ThemeMode value) async {
    theme = value;
  }
}

class RootDeviceStore extends MockDeviceRegistrationStore {
  final boundB = Completer<void>(), detachedA = Completer<void>();
  @override
  Future<void> registerDevice({
    required String uid,
    required String installationId,
    required String token,
    required String locale,
  }) async {
    await super.registerDevice(
      uid: uid,
      installationId: installationId,
      token: token,
      locale: locale,
    );
    if (uid == 'b' && !boundB.isCompleted) boundB.complete();
  }

  @override
  Future<void> unregisterDevice({
    required String uid,
    required String installationId,
  }) async {
    await super.unregisterDevice(uid: uid, installationId: installationId);
    if (uid == 'a' && !detachedA.isCompleted) detachedA.complete();
  }
}

class MemoryDevicePreferences extends Fake implements SharedPreferences {
  final values = <String, String>{'device_installation_id': 'installation'};
  @override
  String? getString(String key) => values[key];
  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

class RootTokenStream extends Stream<String> {
  final controller = StreamController<String>.broadcast(sync: true);
  @override
  StreamSubscription<String> listen(
    void Function(String)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => RootTokenSubscription(
    controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
  );
}

class RootTokenSubscription extends Fake implements StreamSubscription<String> {
  final StreamSubscription<String> inner;
  RootTokenSubscription(this.inner);
  @override
  Future<void> cancel() {
    unawaited(inner.cancel());
    return SynchronousFuture<void>(null);
  }
}

void main() {
  for (final transition in ['signedOut', 'deleting']) {
    testWidgets(
      'production root $transition invalidates token when Auth denies unregister',
      (tester) async {
        final auth = SdkAuthBoundary();
        final profiles = FakeProfileRepository();
        final store = AuthRestrictedDeviceStore(() => auth.currentAuth?.uid);
        final fcm = InstallationTokenBoundary();
        final prefs = MemoryDevicePreferences();
        final refresh = RootTokenStream();
        final devices = DeviceRegistrationService(
          store: store,
          prefsFuture: SynchronousFuture(prefs),
          tokenGetter: fcm.getToken,
          tokenDeleter: fcm.deleteToken,
          tokenRefreshStream: refresh,
        );
        final session = SessionCubit(
          authRepository: auth,
          profileRepository: profiles,
          beforeSignOut: devices.unbindUser,
        );
        final settings = SettingsCubit(repository: SavedPreferences());
        await settings.ready;
        KhademModel profile(String uid, {String status = 'active'}) =>
            KhademModel(
              id: uid,
              name: uid,
              email: '$uid@example.org',
              phone: '',
              role: 'servant',
              grade: '1st',
              status: status,
              createdAt: DateTime(2026),
              locale: 'en',
            );
        Future<void> frames() async {
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 10));
          }
        }

        final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold())],
        );
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: settings),
              BlocProvider.value(value: session),
            ],
            child: EfteqadApp(
              router: router,
              devices: devices,
              updateNotificationLocale: (_) async {},
            ),
          ),
        );
        auth.sdkIdentityChanged('a');
        await frames();
        profiles.emitProfile('a', profile('a'));
        await frames();
        final oldToken =
            store.registeredDevices['a/installation']!['token'] as String;
        if (transition == 'signedOut') {
          auth.sdkIdentityChanged(null);
        } else {
          // Credential loss can precede its SDK auth-stream callback while the
          // last profile snapshot reports the deleting lifecycle.
          auth.currentAuth = null;
          profiles.emitProfile('a', profile('a', status: 'deleting'));
        }
        await frames();
        expect(
          session.state.status,
          transition == 'signedOut'
              ? SessionStatus.signedOut
              : SessionStatus.deleting,
        );
        expect(fcm.validTokens, isNot(contains(oldToken)));
        expect(store.registeredDevices['a/installation']?['token'], oldToken);
        expect(prefs.getString('device_pending_cleanup_uid'), 'a');
        refresh.controller.add('stale_refresh');
        await frames();
        expect(store.registrations, ['a']);
        auth.sdkIdentityChanged('b');
        await frames();
        profiles.emitProfile('b', profile('b'));
        await frames();
        expect(store.registeredDevices.keys, ['a/installation']);
        expect(prefs.getString('device_pending_cleanup_uid'), 'a');
        expect(fcm.validTokens, isEmpty);
        // Reauthentication as the old owner permits the same deferred cleanup;
        // a deleting profile keeps the root ineligible during that retry.
        auth.sdkIdentityChanged('a');
        await frames();
        profiles.emitProfile('a', profile('a', status: 'deleting'));
        await frames();
        expect(prefs.getString('device_pending_cleanup_uid'), isNull);
        expect(store.registeredDevices, isEmpty);
        auth.sdkIdentityChanged('b');
        await frames();
        profiles.emitProfile('b', profile('b'));
        await frames();
        final newToken =
            store.registeredDevices['b/installation']!['token'] as String;
        expect(newToken, isNot(oldToken));
        expect(fcm.validTokens, {newToken});
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await devices.dispose();
        unawaited(session.close());
        unawaited(settings.close());
        unawaited(refresh.controller.close());
        unawaited(auth.changes.close());
        profiles.dispose();
      },
    );
  }
  for (final transition in ['replacement', 'signedOut', 'deleting']) {
    testWidgets('production root ignores delayed channel for $transition', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'device_installation_id': 'installation',
        'device_bound_uid': 'a',
        'last_synced_token': 'token',
      });
      final store = RootDeviceStore();
      final refresh = RootTokenStream();
      final prefs = MemoryDevicePreferences();
      final devices = DeviceRegistrationService(
        store: store,
        prefsFuture: SynchronousFuture(prefs),
        tokenGetter: () async => 'token',
        tokenDeleter: () async {},
        tokenRefreshStream: refresh,
      );
      SessionState active(String uid) => SessionState(
        status: SessionStatus.active,
        userId: uid,
        role: UserRole.servant,
        grade: '1st',
        profile: KhademModel(
          id: uid,
          name: uid,
          email: '$uid@example.org',
          phone: '',
          role: 'servant',
          grade: '1st',
          status: 'active',
          createdAt: DateTime(2026),
          locale: 'en',
        ),
      );
      final settings = SettingsCubit(repository: SavedPreferences());
      await settings.ready;
      final session = MockSessionCubit(active('a'));
      final channel = Completer<void>();
      var calls = 0;
      await devices.bindUser('a');
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold())],
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settings),
            BlocProvider<SessionCubit>.value(value: session),
          ],
          child: EfteqadApp(
            router: router,
            devices: devices,
            updateNotificationLocale: (_) async {
              if (++calls == 1) await channel.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      session.emitMockState(switch (transition) {
        'replacement' => active('b'),
        'signedOut' => const SessionState.signedOut(),
        _ => active('a').copyWith(status: SessionStatus.deleting),
      });
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      for (
        var i = 0;
        i < 30 &&
            !(transition == 'replacement'
                ? store.boundB.isCompleted
                : store.detachedA.isCompleted);
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      final installation = await devices.getInstallationId();
      if (transition == 'replacement') {
        expect(store.registeredDevices.keys, ['b/$installation']);
      } else {
        expect(store.registeredDevices, isEmpty);
      }
      channel.complete();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        store.registeredDevices.keys,
        transition == 'replacement' ? ['b/$installation'] : isEmpty,
      );
      refresh.controller.add('refreshed');
      await tester.pumpAndSettle();
      expect(
        store.registeredDevices.keys,
        transition == 'replacement' ? ['b/$installation'] : isEmpty,
      );
      if (transition == 'replacement') {
        expect(store.registeredDevices.values.single['token'], 'refreshed');
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await devices.dispose();
      unawaited(settings.close());
      unawaited(session.close());
      unawaited(refresh.controller.close());
    });
  }
  test(
    'offline locale intent survives restart and older account preference',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = SettingsCubit(
        repository: SharedPrefsSettingsRepository(),
        saveAccountLocale: (_, locale) async {
          throw StateError('offline');
        },
      );
      await first.ready;
      await first.reconcileAccount(uid: 'a', locale: 'ar', canAttach: true);
      await expectLater(first.setLocale(const Locale('en')), throwsStateError);
      await first.close();
      final restarted = SettingsCubit(
        repository: SharedPrefsSettingsRepository(),
        saveAccountLocale: (_, locale) async {
          throw StateError('offline');
        },
      );
      await restarted.ready;
      try {
        await restarted.reconcileAccount(
          uid: 'a',
          locale: 'ar',
          canAttach: true,
        );
      } catch (_) {}
      expect(restarted.state.locale.languageCode, 'en');
      expect(
        await SharedPrefsSettingsRepository().loadLocale(),
        const Locale('en', 'US'),
      );
      await restarted.close();
    },
  );
  test(
    'late old-account acknowledgement preserves pending UID intents',
    () async {
      SharedPreferences.setMockInitialValues({});
      final started = Completer<void>(), acknowledged = Completer<void>();
      final settings = SettingsCubit(
        repository: SharedPrefsSettingsRepository(),
        saveAccountLocale: (uid, locale) async {
          if (uid == 'a') {
            started.complete();
            await acknowledged.future;
          } else {
            throw StateError('offline');
          }
        },
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', canAttach: true);
      final first = settings.setLocale(const Locale('en'));
      await started.future;
      await settings.reconcileAccount(uid: 'b', locale: 'ar', canAttach: true);
      final second = expectLater(
        settings.setLocale(const Locale('en')),
        throwsStateError,
      );
      await Future<void>.delayed(Duration.zero);
      acknowledged.complete();
      await first;
      await second;
      expect(await SharedPrefsSettingsRepository().loadLocaleIntents(), {
        'a': 'en',
        'b': 'en',
      });
      expect(settings.state.locale.languageCode, 'en');
      await settings.close();
    },
  );
  test(
    'rapid same-account choices leave server and retained device on latest language',
    () async {
      final waiting = Completer<void>();
      var serverLocale = 'en', deviceLocale = 'en';
      final settings = SettingsCubit(
        repository: SavedPreferences(),
        saveAccountLocale: (_, locale) async {
          if (locale == 'ar') await waiting.future;
          serverLocale = locale;
        },
        syncDeviceLocale: (_, locale) async {
          deviceLocale = locale;
        },
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', canAttach: true);
      final older = settings.setLocale(const Locale('ar'));
      await Future<void>.delayed(Duration.zero);
      final newer = settings.setLocale(const Locale('en'));
      await Future<void>.delayed(Duration.zero);
      waiting.complete();
      await Future.wait([older, newer]);
      expect(settings.state.locale.languageCode, 'en');
      expect(serverLocale, 'en');
      expect(deviceLocale, 'en');
      await settings.close();
    },
  );

  test(
    'locale selection and rejected deletion restore same installation through retained service',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = MockDeviceRegistrationStore();
      final refresh = StreamController<String>.broadcast();
      final devices = DeviceRegistrationService(
        store: store,
        tokenGetter: () async => 'token',
        tokenDeleter: () async {},
        tokenRefreshStream: refresh.stream,
      );
      final settings = SettingsCubit(
        repository: SavedPreferences(),
        syncDeviceLocale: (uid, locale) =>
            devices.bindUser(uid, locale: locale),
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', canAttach: true);
      await settings.setLocale(const Locale('ar'));
      final installation = await devices.getInstallationId();
      expect(
        (await store.getDevice(
          uid: 'a',
          installationId: installation,
        ))?['locale'],
        'ar',
      );
      await settings.setLocale(const Locale('en'));
      expect(store.registeredDevices.length, 1);
      expect(
        (await store.getDevice(
          uid: 'a',
          installationId: installation,
        ))?['locale'],
        'en',
      );
      await devices.unbindUser();
      expect(store.registeredDevices, isEmpty);
      await settings.refreshDeviceLocale();
      expect(
        (await store.getDevice(
          uid: 'a',
          installationId: installation,
        ))?['locale'],
        'en',
      );
      await settings.reconcileAccount(uid: 'a', canAttach: false);
      await devices.unbindUser();
      await settings.refreshDeviceLocale();
      expect(store.registeredDevices, isEmpty);
      await settings.close();
      await refresh.close();
    },
  );
  testWidgets('first production app frame uses persisted language and theme', (
    tester,
  ) async {
    final repo = SavedPreferences()..waiting = Completer<Locale>();
    final settings = SettingsCubit(repository: repo);
    final session = MockSessionCubit(const SessionState.signedOut());
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, state) => const LoginScreen())],
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider<SessionCubit>.value(value: session),
        ],
        child: EfteqadApp(
          router: router,
          devices: DeviceRegistrationService(
            store: MockDeviceRegistrationStore(),
            tokenGetter: () async => null,
            tokenDeleter: () async {},
            tokenRefreshStream: const Stream.empty(),
          ),
        ),
      ),
    );
    expect(find.byType(MaterialApp), findsNothing);
    repo.waiting!.complete(const Locale('en', 'US'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en', 'US'));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(settings.close());
    unawaited(session.close());
  });
  testWidgets(
    'production locale and theme changes retain exact task URI and user content',
    (tester) async {
      final settings = SettingsCubit(repository: SavedPreferences());
      await settings.ready;
      final session = MockSessionCubit(
        const SessionState(
          status: SessionStatus.active,
          userId: 'a',
          role: UserRole.servant,
          grade: '1st',
        ),
      );
      final model = TaskModel(
        id: 't',
        title: 'عنوان المستخدم بالعربية',
        assignedKhademId: 'a',
        assignedKhademName: 'اسم المستخدم',
        grade: '1st',
        createdById: 'admin',
        createdByName: 'الأمين',
        createdAt: DateTime(2026),
      );
      final router = GoRouter(
        initialLocation: '/tasks/t?tab=notes',
        routes: [
          GoRoute(
            path: '/tasks/:id',
            builder: (_, state) => TaskDetailsScreen(taskId: 't', task: model),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settings),
            BlocProvider<SessionCubit>.value(value: session),
          ],
          child: EfteqadApp(
            router: router,
            devices: DeviceRegistrationService(
              store: MockDeviceRegistrationStore(),
              tokenGetter: () async => null,
              tokenDeleter: () async {},
              tokenRefreshStream: const Stream.empty(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Task Details'), findsOneWidget);
      final uri = router.state.uri;
      await settings.setLocale(const Locale('ar'));
      await settings.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(router.state.uri, uri);
      expect(router.state.uri.toString(), '/tasks/t?tab=notes');
      expect(find.text('تفاصيل المهمة'), findsOneWidget);
      expect(find.text('عنوان المستخدم بالعربية'), findsOneWidget);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
      expect(app.locale?.languageCode, 'ar');
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(settings.close());
      unawaited(session.close());
    },
  );
  test(
    'account language applies once and later profile echo preserves device choice',
    () async {
      final repo = SavedPreferences();
      final saved = <String>[];
      final bound = <String>[];
      final settings = SettingsCubit(
        repository: repo,
        saveAccountLocale: (uid, locale) async {
          saved.add('$uid/$locale');
        },
        syncDeviceLocale: (uid, locale) async {
          bound.add('$uid/$locale');
        },
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', locale: 'ar', canAttach: true);
      expect(settings.state.locale.languageCode, 'ar');
      await settings.setLocale(const Locale('en'));
      await settings.reconcileAccount(uid: 'a', locale: 'ar', canAttach: true);
      expect(repo.locale.languageCode, 'en');
      expect(settings.state.locale.languageCode, 'en');
      expect(saved, ['a/en']);
      expect(bound, ['a/en']);
      await settings.close();
    },
  );
  test(
    'offline account preference failure preserves local choice and updates retained device',
    () async {
      final repo = SavedPreferences();
      String? boundLocale;
      final settings = SettingsCubit(
        repository: repo,
        saveAccountLocale: (_, locale) async {
          throw StateError('offline');
        },
        syncDeviceLocale: (_, locale) async {
          boundLocale = locale;
        },
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', canAttach: true);
      await expectLater(
        settings.setLocale(const Locale('ar')),
        throwsStateError,
      );
      expect(settings.state.locale.languageCode, 'ar');
      expect(repo.locale.languageCode, 'ar');
      expect(boundLocale, 'ar');
      await settings.close();
    },
  );
  test(
    'signed-out and deleting profile detach account locale and device updates',
    () async {
      final repo = SavedPreferences();
      final writes = <String>[];
      final settings = SettingsCubit(
        repository: repo,
        saveAccountLocale: (uid, locale) async {
          writes.add(uid);
        },
        syncDeviceLocale: (uid, locale) async {
          writes.add(uid);
        },
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', canAttach: true);
      await settings.reconcileAccount(uid: 'a', locale: 'ar', canAttach: false);
      await settings.setLocale(const Locale('en'));
      expect(writes, isEmpty);
      expect(repo.locale.languageCode, 'en');
      await settings.close();
    },
  );
  test(
    'delayed old account save cannot bind a newly selected account',
    () async {
      final repo = SavedPreferences(), pending = Completer<void>();
      final bound = <String>[];
      final settings = SettingsCubit(
        repository: repo,
        saveAccountLocale: (_, locale) => pending.future,
        syncDeviceLocale: (uid, locale) async {
          bound.add(uid);
        },
      );
      await settings.ready;
      await settings.reconcileAccount(uid: 'a', canAttach: true);
      final saving = settings.setLocale(const Locale('ar'));
      await Future<void>.delayed(Duration.zero);
      await settings.reconcileAccount(uid: 'b', canAttach: true);
      pending.complete();
      await saving;
      expect(bound, isEmpty);
      await settings.close();
    },
  );
}

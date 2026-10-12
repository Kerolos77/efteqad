import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/main.dart';
import 'package:efteqad/core/router/app_router.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/settings/settings_cubit.dart';
import 'package:efteqad/core/settings/settings_repository.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import 'core/router/app_router_test.dart' show MockSessionCubit;
import 'core/services/device_registration_service_test.dart'
    show MockDeviceRegistrationStore;

void main() {
  testWidgets(
    'production app changes pending route live and persists localized theme after restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsCubit(
        repository: SharedPrefsSettingsRepository(
          prefsFuture: Future.value(prefs),
        ),
      );
      await settings.ready;
      final session = MockSessionCubit(
        const SessionState(
          status: SessionStatus.pending,
          userId: 'new',
          role: UserRole.pending,
        ),
      );
      final router = createAppRouter(
        sessionCubit: session,
        initialLocation: '/forbidden',
      );
      final devices = DeviceRegistrationService(
        store: MockDeviceRegistrationStore(),
        prefsFuture: Future.value(prefs),
        tokenGetter: () async => null,
        tokenDeleter: () async {},
        tokenRefreshStream: const Stream.empty(),
      );
      Widget root(SettingsCubit s) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: s),
          BlocProvider<SessionCubit>.value(value: session),
        ],
        child: EfteqadApp(
          router: router,
          devices: devices,
          updateNotificationLocale: (_) async {},
        ),
      );
      await tester.pumpWidget(root(settings));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/pending');
      session.emitMockState(
        const SessionState(
          status: SessionStatus.active,
          userId: 'new',
          role: UserRole.servant,
          grade: '1st',
        ),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/forbidden');
      await settings.setLocale(const Locale('en'));
      await settings.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale?.languageCode, 'en');
      expect(app.themeMode, ThemeMode.dark);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final restarted = SettingsCubit(
        repository: SharedPrefsSettingsRepository(
          prefsFuture: Future.value(prefs),
        ),
      );
      await restarted.ready;
      await tester.pumpWidget(root(restarted));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(restarted.state.locale.languageCode, 'en');
      session.emitMockState(
        const SessionState(
          status: SessionStatus.pending,
          userId: 'replacement',
          role: UserRole.pending,
        ),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/pending');
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
      unawaited(settings.close());
      unawaited(restarted.close());
      unawaited(devices.dispose());
    },
  );
}

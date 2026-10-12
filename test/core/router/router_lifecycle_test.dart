import 'dart:async';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/router/app_router.dart';
import 'package:efteqad/core/router/widgets/protected_resource_page.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'app_router_test.dart' show MockSessionCubit;

void main() {
  testWidgets('cached extra cannot reveal details before server lookup', (
    tester,
  ) async {
    final remote = Completer<String?>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            GeneratedAppLocalizations.localizationsDelegates,
        supportedLocales: GeneratedAppLocalizations.supportedLocales,
        home: ProtectedResourcePage<String>(
          initialData: 'secret cache',
          loadResource: () => remote.future,
          builder: (_, data) => Text(data),
        ),
      ),
    );
    expect(find.text('secret cache'), findsNothing);
    remote.complete(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('secret cache'), findsNothing);
  });
  testWidgets('resource future survives parent rebuild', (tester) async {
    var calls = 0;
    Widget build() => MaterialApp(
      localizationsDelegates: GeneratedAppLocalizations.localizationsDelegates,
      supportedLocales: GeneratedAppLocalizations.supportedLocales,
      home: ProtectedResourcePage<String>(
        loadResource: () async {
          calls++;
          return 'verified';
        },
        builder: (_, data) => Text(data),
      ),
    );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
  testWidgets('real router closes current page when session becomes deleting', (
    tester,
  ) async {
    final session = MockSessionCubit(
      const SessionState(
        status: SessionStatus.active,
        userId: 'a',
        role: UserRole.servant,
        grade: '2nd',
      ),
    );
    final router = createAppRouter(
      sessionCubit: session,
      initialLocation: '/forbidden',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates:
            GeneratedAppLocalizations.localizationsDelegates,
        supportedLocales: GeneratedAppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    session.emitMockState(
      const SessionState(
        status: SessionStatus.deleting,
        userId: 'a',
        role: UserRole.servant,
        grade: '2nd',
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, '/deleting');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets('cold internal URI survives bootstrap readiness', (tester) async {
    final session = MockSessionCubit(const SessionState.booting());
    final router = createAppRouter(
      sessionCubit: session,
      initialLocation: '/forbidden?source=cold',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates:
            GeneratedAppLocalizations.localizationsDelegates,
        supportedLocales: GeneratedAppLocalizations.supportedLocales,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    session.emitMockState(
      const SessionState(
        status: SessionStatus.active,
        userId: 'a',
        role: UserRole.servant,
        grade: '2nd',
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/forbidden?source=cold',
    );
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
}

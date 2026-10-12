import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/auth_service.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import 'package:efteqad/core/repositories/account_repository.dart';
import '../core/services/auth_lifecycle_test.dart'
    show AuthSdk, GoogleSdk, UserSdk;
import '../core/services/device_registration_service_test.dart'
    show MockDeviceRegistrationStore;
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/core/settings/settings_cubit.dart';
import 'package:efteqad/features/settings/presentation/screens/settings_screen.dart';
import '../core/router/app_router_test.dart' show MockSessionCubit;
import 'localization_widget_matrix_test.dart' show MatrixSettings;

class AccountDeviceStore extends MockDeviceRegistrationStore {
  Completer<void>? restored;
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
    if (restored != null && !restored!.isCompleted) restored!.complete();
  }
}

Future<void> externalTurn(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump(const Duration(milliseconds: 50));
}

class ReplacementUser extends UserSdk {
  @override
  String get uid => 'other';
}

class MutableAccountSdk extends AuthSdk {
  @override
  User? get currentUser => replacement ?? super.currentUser;
}

void main() {
  for (final changeSdk in [false, true]) {
    testWidgets(
      'account change ${changeSdk ? 'in SDK' : 'in session'} cancels an old settings deletion warning',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final sdk = MutableAccountSdk();
        final devices = DeviceRegistrationService(
          store: MockDeviceRegistrationStore(),
          tokenGetter: () async => null,
          tokenDeleter: () async {},
          tokenRefreshStream: const Stream.empty(),
        );
        final auth = AuthService(
          auth: sdk,
          googleSignIn: GoogleSdk(),
          devices: devices,
          clearNotificationIntents: () {},
        );
        final session = MockSessionCubit(
          const SessionState(
            status: SessionStatus.active,
            userId: 'u',
            role: UserRole.gradeAdmin,
            grade: '1st',
          ),
        );
        final settings = SettingsCubit(repository: MatrixSettings());
        await settings.ready;
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, state) => SettingsScreen(
                accountActions: AuthAccountDeletionActions(authService: auth),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: session),
              BlocProvider.value(value: settings),
            ],
            child: MaterialApp.router(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Permanently Delete Account'));
        await tester.tap(find.text('Permanently Delete Account'));
        await tester.pumpAndSettle();
        if (changeSdk) {
          sdk.replacement = ReplacementUser();
        } else {
          session.emitMockState(session.state.copyWith(userId: 'other'));
        }
        await tester.pump();
        await tester.tap(find.text('Yes, Delete Account'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Password'), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(router.state.uri.path, '/settings');
        expect(sdk.signedOut, isFalse);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        unawaited(settings.close());
        unawaited(session.close());
      },
    );
  }

  for (final role in [UserRole.stageAdmin, UserRole.gradeAdmin]) {
    testWidgets(
      '$role real settings deletion warning requires password before rejection',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final sdk = AuthSdk(), store = AccountDeviceStore();
        final refresh = StreamController<String>.broadcast();
        final devices = DeviceRegistrationService(
          store: store,
          tokenGetter: () async => 'test-token',
          tokenDeleter: () async {},
          tokenRefreshStream: refresh.stream,
        );
        await devices.bindUser('u', locale: 'en');
        final installation = await devices.getInstallationId();
        final auth = AuthService(
          auth: sdk,
          googleSignIn: GoogleSdk(),
          devices: devices,
          clearNotificationIntents: () {},
        );
        final repository = FirebaseAccountRepository(
          auth: sdk,
          googleSignIn: GoogleSdk(),
          mutations: TrustedMutations(
            transport: (name, payload) async {
              if (sdk.user.reauths == 0) {
                throw FirebaseFunctionsException(
                  code: 'unauthenticated',
                  message: 'Sensitive SDK detail',
                );
              }
              throw FirebaseFunctionsException(
                code: 'failed-precondition',
                message: 'Server requires another active stage administrator.',
              );
            },
          ),
        );
        final session = MockSessionCubit(
          SessionState(
            status: SessionStatus.active,
            userId: 'u',
            role: role,
            grade: '1st',
          ),
        );
        final settings = SettingsCubit(
          repository: MatrixSettings(),
          syncDeviceLocale: (uid, locale) =>
              devices.bindUser(uid, locale: locale),
        );
        await settings.ready;
        await settings.setLocale(const Locale('en'));
        await settings.reconcileAccount(
          uid: 'u',
          locale: 'en',
          canAttach: true,
        );
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, state) => SettingsScreen(
                accountActions: AuthAccountDeletionActions(
                  authService: auth,
                  accountRepository: repository,
                ),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: session),
              BlocProvider.value(value: settings),
            ],
            child: MaterialApp.router(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Permanently Delete Account'));
        await tester.tap(find.text('Permanently Delete Account'));
        await tester.pumpAndSettle();
        if (role == UserRole.stageAdmin) {
          expect(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(
                'An active, verified replacement stage administrator is required before deleting your account.',
              ),
            ),
            findsOneWidget,
          );
        }
        await tester.tap(find.text('Yes, Delete Account'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Password'), findsOneWidget);
        expect(find.text('Account deleted successfully'), findsNothing);
        store.restored = Completer<void>();
        await tester.enterText(find.byType(TextField), 'confirmed');
        await tester.tap(find.text('Proceed'));
        for (var i = 0; i < 30 && !store.restored!.isCompleted; i++) {
          await externalTurn(tester);
        }
        await tester.pumpAndSettle();
        expect(find.text('Account deleted successfully'), findsNothing);
        expect(sdk.signedOut, isFalse);
        expect(sdk.user.deletes, 0);
        expect(
          (await store.getDevice(
            uid: 'u',
            installationId: installation,
          ))?['locale'],
          'en',
        );
        expect(router.state.uri.path, '/settings');
        if (role == UserRole.stageAdmin) {
          expect(
            find.descendant(
              of: find.byType(SnackBar),
              matching: find.text(
                'An active, verified replacement stage administrator is required before deleting your account.',
              ),
            ),
            findsOneWidget,
          );
        }
        expect(find.textContaining('Server requires'), findsNothing);
        expect(find.textContaining('Sensitive private'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        unawaited(session.close());
        unawaited(settings.close());
        var cleaned = false;
        final cleanup = devices.unbindUser().then((_) => cleaned = true);
        for (var i = 0; i < 30 && !cleaned; i++) {
          await externalTurn(tester);
        }
        expect(cleaned, isTrue);
        await cleanup;
        await refresh.close();
      },
    );
  }
}

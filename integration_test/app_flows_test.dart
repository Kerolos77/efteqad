import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:efteqad/main.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/repositories/auth_repository.dart';
import 'package:efteqad/core/repositories/profile_repository.dart';
import 'package:efteqad/core/repositories/account_repository.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/core/router/app_router.dart';
import 'package:efteqad/core/router/notification_intent_coordinator.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/import_coordinator.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import 'package:efteqad/core/services/attendance_analytics_service.dart';
import 'package:efteqad/core/settings/settings_cubit.dart';
import 'package:efteqad/core/settings/settings_repository.dart';
import 'demo_environment.dart';

// The identity provider has no emulator. Email/password uses real demo Auth;
// this boundary refuses all Google calls except local no-op logout cleanup.
class FencedGoogle extends Fake implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
  @override
  Future<GoogleSignInAccount?> signIn() async =>
      throw StateError('Google provider is a real-device acceptance gate');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'demo production repositories and app router integrated acceptance',
    (tester) async {
      await DemoEnvironment.initialize();
      final auth = FirebaseAuth.instance, db = FirebaseFirestore.instance;
      final tag = DateTime.now().microsecondsSinceEpoch.toString();
      final adminApp = await Firebase.initializeApp(
        name: 'demo-admin',
        options: Firebase.app().options,
      );
      final adminAuth = FirebaseAuth.instanceFor(app: adminApp);
      await adminAuth.useAuthEmulator(DemoEnvironment.host, 9099);
      final adminIdentity = await adminAuth.createUserWithEmailAndPassword(
        email: 'admin-$tag@example.test',
        password: 'demo-password',
      );
      await DemoEnvironment.seedStageAdmin(adminIdentity.user!.uid);
      final adminFunctions = FirebaseFunctions.instanceFor(app: adminApp);
      adminFunctions.useFunctionsEmulator(DemoEnvironment.host, 5001);
      final adminMutations = TrustedMutations(functions: adminFunctions),
          mutations = TrustedMutations();
      final email = 'new-$tag@example.test';
      final identity = await auth.createUserWithEmailAndPassword(
        email: email,
        password: 'demo-password',
      );
      final uid = identity.user!.uid;
      await db.doc('khodam/$uid').set({
        'name': 'New user',
        'phone': '',
        'email': email,
        'role': 'pending',
        'status': 'pending',
        'grade': null,
        'locale': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final authRepository = FirebaseAuthRepository(
        firebaseAuth: auth,
        googleSignIn: FencedGoogle(),
      );
      final devices = DeviceRegistrationService(
        store: FirestoreDeviceRegistrationStore(firestore: db),
        tokenGetter: () async => null,
        tokenDeleter: () async {},
        tokenRefreshStream: const Stream.empty(),
      );
      final session = SessionCubit(
        authRepository: authRepository,
        profileRepository: FirestoreProfileRepository(firestore: db),
        beforeSignOut: devices.unbindUser,
      );
      final settings = SettingsCubit(
        repository: SharedPrefsSettingsRepository(),
        saveAccountLocale: AccountLocaleRepository(
          firestore: db,
          auth: auth,
        ).saveLocale,
        updateNotificationLocale: (_) async {},
      );
      await settings.ready;
      final coordinator = NotificationIntentCoordinator();
      final service = FirestoreService(firestore: db, mutations: mutations);
      final attendance = FirestoreAttendanceRepository(
        firestore: db,
        mutations: mutations,
      );
      final router = createAppRouter(
        sessionCubit: session,
        notificationIntentCoordinator: coordinator,
        initialLocation: '/forbidden',
        firestoreService: service,
        attendanceRepository: attendance,
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: session),
            BlocProvider.value(value: settings),
          ],
          child: EfteqadApp(
            router: router,
            devices: devices,
            updateNotificationLocale: (_) async {},
          ),
        ),
      );
      Future<void> framesUntil(bool Function() condition) async {
        for (var i = 0; i < 100 && !condition(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), true);
      }

      await framesUntil(() => session.state.isPending);
      expect(router.routeInformationProvider.value.uri.path, '/pending');
      await service.updateKhademProfile(
        id: uid,
        name: 'Updated user',
        phone: '01000000000',
      );
      await adminMutations.call('setKhademGrade', {
        'khademId': uid,
        'grade': '1st',
      });
      await framesUntil(
        () =>
            session.state.isActive &&
            router.routeInformationProvider.value.uri.path == '/forbidden',
      );
      final children = [
        for (var i = 0; i < 2; i++)
          MakhdomModel(
            id: '',
            fullName: 'Demo child $i',
            phone: '0100000000$i',
            grade: '1st',
            createdAt: DateTime(2026, 10, 1),
            trackingStartDate: DateTime(2026, 10, 1),
          ),
      ];
      final importer = ImportCoordinator(
        mutations: adminMutations,
        userId: () => adminIdentity.user!.uid,
      );
      expect(
        (await importer.importRows(children, importId: 'flow-$tag')).imported,
        2,
      );
      expect(
        (await importer.importRows(children, importId: 'flow-$tag')).imported,
        2,
      );
      final imported = await adminMutations.call('importRows', {
        'importId': 'receipt-$tag',
        'grade': '1st',
        'rows': [
          {
            'fullName': 'Writer one',
            'phone': '01000000001',
            'trackingStartDate': '2026-10-01',
          },
          {
            'fullName': 'Writer two',
            'phone': '01000000002',
            'trackingStartDate': '2026-10-01',
          },
        ],
      });
      final ids = (imported['results'] as List)
          .map((r) => r['makhdomId'] as String)
          .toList();
      await adminMutations.call('assignMakhdoms', {
        'ids': ids,
        'targetKhademId': uid,
        'expectedAssignments': {for (final id in ids) id: null},
        'operationId': 'assign-$tag',
      });
      final task = await adminMutations.call('createTask', {
        'operationId': 'task-$tag',
        'taskData': {
          'title': 'Demo roster',
          'grade': '1st',
          'assignedKhademId': uid,
          'type': 'attendance_khedma',
          'dueDate': '2026-10-09',
        },
      });
      final taskId = task['taskId'] as String;
      coordinator.enqueue(
        NotificationIntent(type: 'attendance_khedma', taskId: taskId),
      );
      await framesUntil(
        () =>
            router.routeInformationProvider.value.uri.path ==
            '/tasks/$taskId/attendance',
      );
      const sessionId = '2026-10-09_khedma_1st';
      final adminAttendance = FirestoreAttendanceRepository(
        mutations: adminMutations,
      );
      Future<void> presence(AttendanceRepository repo, String id, String op) =>
          repo.setPresence(
            sessionId: sessionId,
            grade: '1st',
            makhdomId: id,
            isPresent: true,
            date: '2026-10-09',
            type: 'khedma',
            khademId: uid,
            khademName: 'ignored',
            taskId: taskId,
            operationId: op,
          );
      await Future.wait([
        presence(attendance, ids[0], 'one-$tag'),
        presence(adminAttendance, ids[1], 'two-$tag'),
      ]);
      await attendance.finalizeAttendance(
        sessionId: sessionId,
        grade: '1st',
        taskId: taskId,
      );
      final rows = await attendance
          .watchGradeAttendance(
            grade: '1st',
            from: DateTime(2026, 10, 9),
            to: DateTime(2026, 10, 9),
          )
          .firstWhere(
            (rows) => rows.any((r) => r.id == sessionId && r.isFinalized),
          )
          .timeout(const Duration(seconds: 20));
      expect(
        rows.singleWhere((r) => r.id == sessionId).attendedMakhdomIds.toSet(),
        ids.toSet(),
      );
      final adminDb = FirebaseFirestore.instanceFor(app: adminApp);
      adminDb.useFirestoreEmulator(DemoEnvironment.host, 8080);
      final stageRows = await FirestoreService(firestore: adminDb)
          .watchAttendanceWindow(
            from: DateTime(2026, 10, 9),
            to: DateTime(2026, 10, 9),
          )
          .firstWhere((rows) => rows.any((r) => r.id == sessionId));
      expect(stageRows.any((r) => r.id == sessionId), true);
      await adminAttendance.reopenAttendance(
        sessionId: sessionId,
        grade: '1st',
        reason: 'Demo correction',
        operationId: 'reopen-$tag',
      );
      final reopened = await attendance
          .watchGradeAttendance(
            grade: '1st',
            from: DateTime(2026, 10, 9),
            to: DateTime(2026, 10, 9),
          )
          .firstWhere(
            (rows) => rows.any((r) => r.id == sessionId && !r.isFinalized),
          );
      expect(
        AttendanceAnalyticsService.filterValidSessions(
          reopened,
          asOf: DateTime(2026, 10, 10),
        ),
        isEmpty,
      );
      await adminAttendance.finalizeAttendance(
        sessionId: sessionId,
        grade: '1st',
      );
      final latest = await mutations.call('recordVisit', {
        'makhdomId': ids[0],
        'visitDate': '2026-10-10',
        'visitType': 'home',
        'notes': 'Latest',
        'operationId': 'latest-$tag',
      });
      await mutations.call('recordVisit', {
        'makhdomId': ids[0],
        'visitDate': '2026-10-01',
        'visitType': 'home',
        'notes': 'Older',
        'operationId': 'older-$tag',
      });
      expect(
        (await db.doc('makhdomeen/${ids[0]}').get()).data()!['lastVisitId'],
        latest['visitId'],
      );
      await settings.setLocale(const Locale('ar'));
      await settings.setThemeMode(ThemeMode.dark);
      final restarted = SettingsCubit(
        repository: SharedPrefsSettingsRepository(),
      );
      await restarted.ready;
      expect(restarted.state.locale.languageCode, 'ar');
      expect(restarted.state.themeMode, ThemeMode.dark);
      await session.signOut();
      await framesUntil(() => !session.state.isAuthenticated);
      await auth.createUserWithEmailAndPassword(
        email: 'replacement-$tag@example.test',
        password: 'demo-password',
      );
      await framesUntil(
        () => session.state.userId != uid && session.state.isPending,
      );
      await expectLater(service.getMakhdom(ids[0]), throwsA(anything));
      expect(coordinator.pendingIntent, isNull);
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: email,
        password: 'demo-password',
      );
      await framesUntil(
        () => session.state.userId == uid && session.state.isActive,
      );
      final account = FirebaseAccountRepository(
        auth: auth,
        googleSignIn: FencedGoogle(),
        mutations: mutations,
      );
      await expectLater(
        account.reauthenticate(password: 'wrong-password'),
        throwsA(anything),
      );
      expect((await db.doc('khodam/$uid').get()).data()!['status'], 'active');
      await account.reauthenticate(password: 'demo-password');
      expect(
        await account.requestDeletion(
          operationId: 'delete-$tag',
          expectedUid: uid,
        ),
        uid,
      );
      await framesUntil(() => session.state.isDeleting);
      expect(router.routeInformationProvider.value.uri.path, '/deleting');
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      coordinator.dispose();
      await session.close();
      await settings.close();
      await restarted.close();
      await devices.dispose();
      await adminApp.delete();
    },
  );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/task_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/core/router/route_access_service.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/attendance_roster_repository.dart';
import 'package:efteqad/core/router/app_router.dart';
import 'package:efteqad/features/attendance/presentation/screens/attendance_screen.dart';
import '../../core/router/app_router_test.dart' show MockSessionCubit;
import '../../core/router/resource_router_test.dart'
    show Resources, ShellRepository;

void main() {
  final task = TaskModel(
    id: 't',
    status: 'completed',
    title: 'Attendance',
    assignedKhademId: 's',
    assignedKhademName: 'Servant',
    grade: '1st',
    createdById: 'a',
    createdByName: 'Admin',
    isCompleted: true,
    type: 'attendance_khedma',
    dueDate: DateTime(2026, 10, 9),
    createdAt: DateTime(2026, 10, 8),
  );
  const state = SessionState(
    status: SessionStatus.active,
    userId: 'a',
    role: UserRole.gradeAdmin,
    grade: '1st',
  );
  testWidgets(
    'attendance load error exposes Retry and recovers actual screen controls',
    (tester) async {
      Future<void> frames() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
      }

      final session = MockSessionCubit(state);
      var calls = 0, watches = 0, initialized = false;
      final repository = FirestoreAttendanceRepository(
        mutations: TrustedMutations(
          userId: () => 'a',
          transport: (name, p) async {
            expect(name, 'initializeAttendance');
            calls++;
            if (calls == 1) throw StateError('temporary offline');
            initialized = true;
            return {'success': true};
          },
        ),
        sessionStream: (id, g) {
          expect(initialized, true);
          watches++;
          return Stream.value(
            AttendanceSessionModel(
              id: id,
              date: '2026-10-09',
              grade: g,
              type: 'khedma',
              attendedMakhdomIds: ['m'],
              updatedAt: DateTime(2026),
            ),
          );
        },
      );
      await tester.pumpWidget(
        BlocProvider<SessionCubit>.value(
          value: session,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: GeneratedAppLocalizations.supportedLocales,
            localizationsDelegates:
                GeneratedAppLocalizations.localizationsDelegates,
            home: AttendanceScreen(
              task: task.copyWith(isCompleted: false, status: 'active'),
              repository: repository,
              loadRoster: (_) async => [
                const AttendanceRosterRow(
                  id: 'm',
                  fullName: 'Child',
                  grade: '1st',
                  active: true,
                ),
              ],
            ),
          ),
        ),
      );
      await frames();
      expect(calls, 1);
      expect(watches, 0);
      expect(find.text('Retry'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Retry'));
        await Future<void>.delayed(Duration.zero);
      });
      await frames();
      expect(calls, 2);
      expect(watches, 1);
      expect(find.text('Child'), findsWidgets);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
      expect(checkbox.onChanged, isNotNull);
      final finalize = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check_circle_outline),
      );
      expect(finalize.onPressed, isNotNull);
      expect(find.text('Retry'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(session.close());
    },
  );
  test(
    'completed attendance route remains available only to scoped administrator for reopen',
    () {
      const access = RouteAccessService();
      expect(
        () => access.authorizeTask(task, state, attendance: true),
        returnsNormally,
      );
      expect(
        () => access.authorizeTask(
          task,
          const SessionState(
            status: SessionStatus.active,
            userId: 's',
            role: UserRole.servant,
            grade: '1st',
          ),
          attendance: true,
        ),
        throwsA(anything),
      );
      expect(
        () => access.authorizeTask(
          task.copyWith(status: 'cancelled'),
          state,
          attendance: true,
        ),
        throwsA(anything),
      );
    },
  );
  for (final instant in ['2026-10-08T21:00:00Z', '2026-10-09T00:00:00Z']) {
    testWidgets(
      'decoded task canonical day reaches attendance router for $instant',
      (tester) async {
        final stored = TaskModel.fromMap({
          ...task.toMap(),
          'isCompleted': false,
          'status': 'active',
          'attendanceDay': instant.substring(0, 10),
          'dueDate': Timestamp.fromDate(DateTime.parse(instant)),
        }, 't');
        final decoded = instant.contains('09T')
            ? stored.copyWith(
                dueDate: DateTime.utc(2026, 10, 8, 17),
                attendanceDay: stored.attendanceDay,
              )
            : stored;
        final session = MockSessionCubit(state);
        final resources = Resources()..tasks['t'] = decoded;
        final watched = <String>[];
        final repository = FirestoreAttendanceRepository(
          mutations: TrustedMutations(
            transport: (_, _) async => {'success': true},
          ),
          sessionStream: (id, _) {
            watched.add(id);
            return Stream.value(null);
          },
        );
        final router = createAppRouter(
          sessionCubit: session,
          initialLocation: '/tasks/t/attendance',
          resourceLoader: resources,
          firestoreService: ShellRepository(),
          attendanceRepository: repository,
          attendanceRosterLoader: (_) async => [],
        );
        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('en'),
            supportedLocales: GeneratedAppLocalizations.supportedLocales,
            localizationsDelegates:
                GeneratedAppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          watched.single,
          instant.contains('08T')
              ? '2026-10-08_khedma_1st'
              : '2026-10-09_khedma_1st',
        );
        // Simulate the same timestamp viewed at a negative offset, keeping display instant.
        final shifted = decoded.copyWith(
          dueDate: DateTime.parse(instant).subtract(const Duration(hours: 7)),
          attendanceDay: instant.substring(0, 10),
        );
        expect(decoded.toMap()['attendanceDay'], instant.substring(0, 10));
        expect(
          shifted.toMap()['attendanceDay'],
          decoded.toMap()['attendanceDay'],
        );
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        unawaited(session.close());
      },
    );
  }
  for (final completeBeforeRoster in [false, true]) {
    testWidgets(
      'remote task reopen refreshes retained roster, completeBeforeRoster=$completeBeforeRoster',
      (tester) async {
        final session = MockSessionCubit(state);
        final resources = Resources()..tasks['t'] = task;
        final sessions = StreamController<AttendanceSessionModel?>.broadcast();
        final roster = Completer<List<AttendanceRosterRow>>();
        final presence = Completer<Map<String, dynamic>>();
        final sent = <Map<String, dynamic>>[];
        var loads = 0;
        final repository = FirestoreAttendanceRepository(
          sessionStream: (_, _) => sessions.stream,
          mutations: TrustedMutations(
            transport: (name, payload) async {
              if (name == 'initializeAttendance') return {'success': true};
              expect(name, 'setAttendancePresence');
              sent.add(payload);
              return presence.future;
            },
          ),
        );
        final router = createAppRouter(
          sessionCubit: session,
          initialLocation: '/tasks/t/attendance',
          resourceLoader: resources,
          firestoreService: ShellRepository(),
          attendanceRepository: repository,
          attendanceRosterLoader: (_) {
            loads++;
            return roster.future;
          },
        );
        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('en'),
            supportedLocales: GeneratedAppLocalizations.supportedLocales,
            localizationsDelegates:
                GeneratedAppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        );
        Future<void> frames() async {
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 20));
          }
        }

        AttendanceSessionModel remote(String status) => AttendanceSessionModel(
          id: '2026-10-09_khedma_1st',
          date: '2026-10-09',
          grade: '1st',
          type: 'khedma',
          status: status,
          attendedMakhdomIds: ['m'],
          updatedAt: DateTime(2026, 10, 9),
        );
        await frames();
        sessions.add(remote('finalized'));
        await frames();
        final retainedState = tester.state(find.byType(AttendanceScreen));
        expect(loads, 0);
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
        resources.taskStreams['t']!.add(
          task.copyWith(status: 'active', isCompleted: false),
        );
        sessions.add(remote('draft'));
        await frames();
        expect(
          tester.state(find.byType(AttendanceScreen)),
          same(retainedState),
        );
        expect(
          loads,
          1,
          reason: 'Remote reopen must fetch the active task roster',
        );
        if (completeBeforeRoster) {
          // A future cannot be cancelled; its obsolete stream must not publish.
          resources.taskStreams['t']!.add(task);
          sessions.add(remote('finalized'));
          await frames();
        }
        roster.complete(const [
          AttendanceRosterRow(
            id: 'm',
            fullName: 'Preserved child',
            grade: '1st',
            active: true,
          ),
          AttendanceRosterRow(
            id: 'n',
            fullName: 'Missing child',
            grade: '1st',
            active: true,
          ),
        ]);
        await frames();
        if (completeBeforeRoster) {
          expect(find.text('Preserved child'), findsNothing);
          expect(find.text('Missing child'), findsNothing);
          expect(find.byIcon(Icons.check_circle_outline), findsNothing);
          expect(sent, isEmpty);
        } else {
          expect(find.text('Preserved child'), findsWidgets);
          expect(find.text('Missing child'), findsOneWidget);
          expect(
            tester.widget<Checkbox>(find.byType(Checkbox).first).value,
            true,
          );
          expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
          await tester.tap(find.text('Missing child'));
          await frames();
          expect(sent.single['makhdomId'], 'n');
          expect(sent.single['isPresent'], true);
          expect(
            find.byIcon(Icons.check_circle_outline),
            findsNothing,
            reason: 'Pending save still prevents finalize after reopen',
          );
          resources.taskStreams['t']!.add(task);
          sessions.add(remote('finalized'));
          await frames();
          expect(find.byType(Checkbox), findsNothing);
          expect(find.byIcon(Icons.check_circle_outline), findsNothing);
          presence.complete({'success': true});
          await frames();
          expect(sent.length, 1);
          expect(find.byIcon(Icons.check_circle_outline), findsNothing);
        }
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        unawaited(sessions.close());
        for (final stream in resources.taskStreams.values) {
          unawaited(stream.close());
        }
        unawaited(session.close());
      },
    );
  }
  for (final role in [UserRole.gradeAdmin, UserRole.servant]) {
    testWidgets(
      'finalized sheet reopen control for $role uses trusted retry intent',
      (tester) async {
        final session = MockSessionCubit(
          SessionState(
            status: SessionStatus.active,
            userId: role == UserRole.servant ? 's' : 'a',
            role: role,
            grade: '1st',
          ),
        );
        final stream = StreamController<AttendanceSessionModel?>.broadcast();
        final payloads = <Map<String, dynamic>>[];
        final repository = FirestoreAttendanceRepository(
          sessionStream: (_, _) => stream.stream,
          mutations: TrustedMutations(
            transport: (name, p) async {
              if (name == 'initializeAttendance') return {'success': true};
              expect(name, 'reopenAttendance');
              payloads.add(p);
              if (payloads.length == 1) throw StateError('lost response');
              return {'success': true};
            },
          ),
        );
        await tester.pumpWidget(
          BlocProvider<SessionCubit>.value(
            value: session,
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: GeneratedAppLocalizations.supportedLocales,
              localizationsDelegates:
                  GeneratedAppLocalizations.localizationsDelegates,
              home: AttendanceScreen(
                task: task,
                repository: repository,
                loadRoster: (_) async => [],
              ),
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        stream.add(
          AttendanceSessionModel(
            id: '2026-10-09_khedma_1st',
            date: '2026-10-09',
            grade: '1st',
            type: 'khedma',
            status: 'finalized',
            attendedMakhdomIds: ['m'],
            updatedAt: DateTime(2026, 10, 9),
          ),
        );
        await tester.pumpAndSettle();
        if (role == UserRole.servant) {
          expect(find.byIcon(Icons.lock_open_rounded), findsNothing);
        } else {
          await tester.tap(find.byIcon(Icons.lock_open_rounded));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).last, 'Correct roster');
          await tester.tap(find.text('Reopen').last);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.tap(find.text('Reopen').last);
          await tester.pumpAndSettle();
          expect(payloads.length, 2);
          expect(payloads.last, payloads.first);
          expect(payloads.first['reason'], 'Correct roster');
          expect(find.byType(AlertDialog), findsNothing);
        }
        await tester.pumpWidget(const SizedBox());
        unawaited(stream.close());
        unawaited(session.close());
      },
    );
  }
}

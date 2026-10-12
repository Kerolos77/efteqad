import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efteqad/core/models/page_result.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/models/task_model.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/models/notification_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/core/router/app_router.dart';
import 'package:efteqad/core/router/route_resource_loader.dart';
import 'package:efteqad/core/router/notification_intent_coordinator.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'app_router_test.dart' show MockSessionCubit;
import '../session/session_cubit_test.dart'
    show FakeAuthRepository, FakeProfileRepository;
import 'package:efteqad/core/repositories/auth_repository.dart';
import 'package:efteqad/core/session/session_cubit.dart';

// External fixtures use the production decoder, including missing legacy status.
TaskModel task(
  String id, {
  String owner = 'a',
  String grade = '2nd',
  String? status,
}) => TaskModel.fromMap({
  'title': 'Private $id',
  'assignedKhademId': owner,
  'assignedKhademName': 'Owner',
  'grade': grade,
  'createdById': 'admin',
  'createdByName': 'Admin',
  'createdAt': '2026-10-08T00:00:00Z',
  if (status != null) 'status': status,
}, id);
const active = SessionState(
  status: SessionStatus.active,
  userId: 'a',
  role: UserRole.servant,
  grade: '2nd',
);

class Resources implements RouteResourceLoader {
  final tasks = <String, TaskModel?>{};
  final children = <String, MakhdomModel?>{};
  final taskStreams = <String, StreamController<TaskModel?>>{};
  final childStreams = <String, StreamController<MakhdomModel?>>{};
  final pending = <String, Completer<TaskModel?>>{};
  Object? error;
  int reads = 0;
  @override
  Future<TaskModel?> loadTask(String id) async {
    reads++;
    if (error != null) throw error!;
    return pending[id]?.future ?? tasks[id];
  }

  @override
  Stream<TaskModel?> watchTask(String id) => taskStreams
      .putIfAbsent(id, () => StreamController<TaskModel?>.broadcast())
      .stream;
  @override
  Future<MakhdomModel?> loadChild(String id) async => children[id];
  @override
  Stream<MakhdomModel?> watchChild(String id) => childStreams
      .putIfAbsent(id, () => StreamController<MakhdomModel?>.broadcast())
      .stream;
}

class ShellRepository extends FirestoreService {
  @override
  Stream<int> watchUnreadNotificationCount(String id) => Stream.value(0);
  @override
  Future<PageResult<NotificationModel>> fetchNotificationPage({
    required String uid,
    DocumentSnapshot? cursor,
    int limit = 50,
  }) async => PageResult.empty();
  @override
  Stream<List<VisitModel>> watchVisitsForChildrenWindow(
    List<String> childIds, {
    DateTime? from,
    DateTime? to,
  }) => Stream.value([]);

  @override
  Future<PageResult<VisitModel>> fetchVisitPage({
    required String makhdomId,
    DocumentSnapshot? cursor,
    int limit = 50,
    DateTime? from,
    DateTime? to,
  }) async => PageResult(
    items: await getVisitsForMakhdomStream(makhdomId, from: from, to: to).first,
    hasMore: false,
  );
  @override
  Stream<List<VisitModel>> getVisitsForMakhdomStream(
    String id, {
    DateTime? from,
    DateTime? to,
  }) => Stream.value([]);
  @override
  Stream<List<TaskModel>> getTasksForKhademStream(String id) =>
      Stream.value([task('one'), task('done').copyWith(isCompleted: true)]);
  @override
  Stream<List<MakhdomModel>> getMakhdomeenForKhademStream(String id) =>
      Stream.value([]);
  @override
  Stream<List<AttendanceSessionModel>> getAllAttendanceSessionsStream({
    DateTime? from,
    DateTime? to,
  }) => Stream.value([]);
  @override
  Stream<List<AttendanceSessionModel>> getAttendanceSessionsForGradeStream(
    String grade, {
    DateTime? from,
    DateTime? to,
  }) => getAllAttendanceSessionsStream(from: from, to: to);

  @override
  Stream<List<KhademModel>> getKhodamByGradeStream(String grade) =>
      Stream.value([]);
  @override
  Stream<List<MakhdomModel>> getMakhdomeenByGradeStream(String grade) =>
      Stream.value([]);
  @override
  Stream<List<TaskModel>> getTasksForGradeStream(String grade) => Stream.value([
    task('one', grade: grade),
    task('done', grade: grade).copyWith(isCompleted: true),
  ]);
  @override
  Stream<List<NotificationModel>> getNotificationsForUserStream(String id) =>
      Stream.value([]);
}

class LongShellRepository extends ShellRepository {
  @override
  Stream<List<TaskModel>> getTasksForKhademStream(String id) => Stream.value(
    List.generate(
      40,
      (index) => task('scroll$index').copyWith(isCompleted: index.isEven),
    ),
  );
}

class InboxRepository extends ShellRepository {
  @override
  Future<PageResult<NotificationModel>> fetchNotificationPage({
    required String uid,
    DocumentSnapshot? cursor,
    int limit = 50,
  }) async => PageResult(
    items: await getNotificationsForUserStream(uid).first,
    hasMore: false,
  );

  @override
  Stream<List<NotificationModel>> getNotificationsForUserStream(String id) =>
      Stream.value([
        NotificationModel(
          id: 'notification',
          recipientId: 'a',
          title: 'Push alias',
          body: 'Already read',
          type: 'task',
          data: const {'taskId': 'one', 'type': 'taskAttendance'},
          isRead: true,
          createdAt: DateTime(2026),
        ),
      ]);
}

class IdentityInboxRepository extends InboxRepository {
  final waiting = StreamController<List<NotificationModel>>.broadcast();
  @override
  Stream<List<NotificationModel>> getNotificationsForUserStream(String id) =>
      id == 'a' ? super.getNotificationsForUserStream(id) : waiting.stream;
}

Future<void> frames(WidgetTester tester) async {
  for (var n = 0; n < 5; n++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });
  testWidgets(
    'verified no-extra task closes on cancellation, then recovers live',
    (tester) async {
      final resources = Resources()..tasks['one'] = task('one');
      final session = MockSessionCubit(active);
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        initialLocation: '/tasks/one',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      expect(find.text('Private one'), findsOneWidget);
      resources.taskStreams['one']!.add(task('one', status: 'cancelled'));
      await frames(tester);
      expect(find.text('Private one'), findsNothing);
      expect(find.text('Page Not Found'), findsWidgets);
      resources.taskStreams['one']!.add(task('one', owner: 'another'));
      await frames(tester);
      expect(find.text('Access Denied'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
    },
  );
  testWidgets(
    'role downgrade and user switch cannot retain former detail or subscription',
    (tester) async {
      final resources = Resources()..tasks['one'] = task('one', owner: 'other');
      final session = MockSessionCubit(
        const SessionState(
          status: SessionStatus.active,
          userId: 'a',
          role: UserRole.stageAdmin,
        ),
      );
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        initialLocation: '/tasks/one',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      expect(find.text('Private one'), findsOneWidget);
      session.emitMockState(active);
      await frames(tester);
      expect(find.text('Private one'), findsNothing);
      expect(find.text('Access Denied'), findsWidgets);
      session.emitMockState(
        const SessionState(
          status: SessionStatus.active,
          userId: 'b',
          role: UserRole.servant,
          grade: '2nd',
        ),
      );
      await frames(tester);
      expect(find.text('Private one'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
    },
  );
  testWidgets('network failure has retry while permission has safe denial', (
    tester,
  ) async {
    final resources = Resources()..error = AppFailure.network();
    final session = MockSessionCubit(active);
    final router = createAppRouter(
      sessionCubit: session,
      resourceLoader: resources,
      initialLocation: '/tasks/one',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Private one'), findsNothing);
    resources.error = null;
    resources.tasks['one'] = task('one');
    await tester.tap(find.text('Retry'));
    await frames(tester);
    expect(find.text('Private one'), findsOneWidget);
    resources.taskStreams['one']!.addError(AppFailure.permissionDenied());
    await frames(tester);
    expect(find.text('Access Denied'), findsWidgets);
    expect(find.text('Private one'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets('route change while loading cannot show old ID', (tester) async {
    final resources = Resources()
      ..pending['one'] = Completer<TaskModel?>()
      ..tasks['two'] = task('two');
    final session = MockSessionCubit(active);
    final router = createAppRouter(
      sessionCubit: session,
      resourceLoader: resources,
      initialLocation: '/tasks/one',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    router.go('/tasks/two');
    await frames(tester);
    resources.pending['one']!.complete(task('one'));
    await frames(tester);
    expect(find.text('Private two'), findsOneWidget);
    expect(find.text('Private one'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets('notification remains queued until resource verification', (
    tester,
  ) async {
    final resources = Resources()..pending['one'] = Completer<TaskModel?>();
    final coordinator = NotificationIntentCoordinator()
      ..enqueue(const NotificationIntent(type: 'task', taskId: 'one'));
    final session = MockSessionCubit(active);
    final router = createAppRouter(
      sessionCubit: session,
      resourceLoader: resources,
      notificationIntentCoordinator: coordinator,
      initialLocation: '/forbidden',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    expect(coordinator.pendingIntent, isNotNull);
    resources.pending['one']!.complete(null);
    await frames(tester);
    expect(find.text('Page Not Found'), findsWidgets);
    expect(coordinator.pendingIntent, isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
    coordinator.dispose();
  });
  testWidgets(
    'logout destroys protected stack and different user gets a fresh scope',
    (tester) async {
      final resources = Resources()..tasks['one'] = task('one');
      final session = MockSessionCubit(active);
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        firestoreService: ShellRepository(),
        initialLocation: '/tasks/one',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      router.push('/tasks/one');
      await frames(tester);
      session.emitMockState(const SessionState.signedOut());
      await frames(tester);
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(router.canPop(), isFalse);
      expect(find.text('Private one'), findsNothing);
      session.emitMockState(
        const SessionState(
          status: SessionStatus.active,
          userId: 'b',
          role: UserRole.servant,
          grade: '2nd',
        ),
      );
      await frames(tester);
      expect(router.routeInformationProvider.value.uri.path, '/me/makhdomeen');
      expect(find.text('Private one'), findsNothing);
      router.go('/tasks/one');
      await frames(tester);
      expect(find.text('Access Denied'), findsWidgets);
      expect(find.text('Private one'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
    },
  );
  testWidgets('changing user clears the hidden shell filter', (tester) async {
    final session = MockSessionCubit(active);
    final router = createAppRouter(
      sessionCubit: session,
      firestoreService: ShellRepository(),
      initialLocation: '/me/tasks',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    await tester.tap(find.textContaining('Completed').first);
    await frames(tester);
    expect(find.text('Private one'), findsNothing);
    session.emitMockState(
      const SessionState(
        status: SessionStatus.active,
        userId: 'b',
        role: UserRole.servant,
        grade: '2nd',
      ),
    );
    await frames(tester);
    expect(find.text('Private one'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets('live child removal or reassignment closes actual history', (
    tester,
  ) async {
    final resources = Resources()
      ..children['child'] = MakhdomModel(
        id: 'child',
        fullName: 'Protected Child',
        phone: '',
        grade: '2nd',
        assignedKhademId: 'a',
        createdAt: DateTime(2026),
      );
    final session = MockSessionCubit(active);
    final router = createAppRouter(
      sessionCubit: session,
      resourceLoader: resources,
      firestoreService: ShellRepository(),
      initialLocation: '/makhdomeen/child/history',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    expect(find.text('Protected Child'), findsWidgets);
    resources.childStreams['child']!.add(
      resources.children['child']!.copyWith(assignedKhademId: 'b'),
    );
    await frames(tester);
    expect(find.text('Protected Child'), findsNothing);
    expect(find.text('Access Denied'), findsWidgets);
    resources.childStreams['child']!.add(null);
    await frames(tester);
    expect(find.text('Page Not Found'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets(
    'attendance route validates task and resets repository when live date changes',
    (tester) async {
      final attendance = task(
        'one',
      ).copyWith(type: 'attendance_khedma', dueDate: DateTime(2026, 10, 9));
      final resources = Resources()..tasks['one'] = attendance;
      final ids = <String>[];
      final repository = FirestoreAttendanceRepository(
        mutations: TrustedMutations(transport: (_, _) async => {'success': true}),
        sessionStream: (id, grade) {
          ids.add(id);
          return Stream.value(null);
        },
      );
      final session = MockSessionCubit(active);
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        attendanceRepository: repository,
        attendanceRosterLoader: (_) async => [],
        initialLocation: '/tasks/one/attendance',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      expect(ids, ['2026-10-09_khedma_2nd']);
      resources.taskStreams['one']!.add(
        attendance.copyWith(dueDate: DateTime(2026, 10, 16)),
      );
      await frames(tester);
      expect(ids, ['2026-10-09_khedma_2nd', '2026-10-16_khedma_2nd']);
      resources.taskStreams['one']!.add(attendance.copyWith(type: 'general'));
      await frames(tester);
      expect(find.text('Page Not Found'), findsWidgets);
      resources.taskStreams['one']!.add(
        attendance.copyWith(type: 'attendance'),
      );
      await frames(tester);
      expect(find.text('Page Not Found'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
    },
  );
  testWidgets('same-session tab changes preserve task list scroll', (
    tester,
  ) async {
    final session = MockSessionCubit(active);
    final router = createAppRouter(
      sessionCubit: session,
      firestoreService: LongShellRepository(),
      initialLocation: '/me/tasks',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    await tester.tap(find.textContaining('Completed').first);
    await frames(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await frames(tester);
    final before = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(before, greaterThan(100));
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected!(0);
    await frames(tester);
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected!(1);
    await frames(tester);
    final after = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(after, before);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets(
    'real profile read failure retries separately and restores cold task URI',
    (tester) async {
      final auth = FakeAuthRepository(), profiles = FakeProfileRepository();
      final session = SessionCubit(
        authRepository: auth,
        profileRepository: profiles,
      );
      final resources = Resources()..tasks['one'] = task('one');
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        initialLocation: '/tasks/one',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      auth.emitAuth(const AuthIdentity(uid: 'a'));
      await frames(tester);
      profiles.emitError('a', AppFailure.network());
      await frames(tester);
      expect(router.routeInformationProvider.value.uri.path, '/session-error');
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await frames(tester);
      expect(router.routeInformationProvider.value.uri.path, '/bootstrap');
      profiles.emitProfile(
        'a',
        KhademModel(
          id: 'a',
          name: 'A',
          email: 'a@example.org',
          phone: '',
          role: 'servant',
          grade: '2nd',
          status: 'active',
          createdAt: DateTime(2026),
        ),
      );
      await frames(tester);
      expect(router.routeInformationProvider.value.uri.path, '/tasks/one');
      expect(find.text('Private one'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
      auth.dispose();
      profiles.dispose();
    },
  );
  testWidgets('pending assignment readiness restores cold URI exactly once', (
    tester,
  ) async {
    final auth = FakeAuthRepository(), profiles = FakeProfileRepository();
    final session = SessionCubit(
      authRepository: auth,
      profileRepository: profiles,
    );
    final resources = Resources()..tasks['one'] = task('one');
    final router = createAppRouter(
      sessionCubit: session,
      resourceLoader: resources,
      initialLocation: '/tasks/one',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    auth.emitAuth(
      const AuthIdentity(uid: 'a', email: 'a@example.org', displayName: 'A'),
    );
    await frames(tester);
    profiles.emitProfile(
      'a',
      KhademModel(
        id: 'a',
        name: 'A',
        email: 'a@example.org',
        phone: '0123',
        role: 'pending',
        status: 'pending',
        createdAt: DateTime(2026),
      ),
    );
    await frames(tester);
    expect(router.routeInformationProvider.value.uri.path, '/pending');
    profiles.emitProfile(
      'a',
      KhademModel(
        id: 'a',
        name: 'A',
        email: 'a@example.org',
        phone: '0123',
        role: 'servant',
        grade: '2nd',
        status: 'active',
        createdAt: DateTime(2026),
      ),
    );
    await frames(tester);
    expect(router.routeInformationProvider.value.uri.path, '/tasks/one');
    expect(find.text('Private one'), findsOneWidget);
    router.go('/forbidden');
    await frames(tester);
    expect(router.routeInformationProvider.value.uri.path, '/forbidden');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
    auth.dispose();
    profiles.dispose();
  });
  testWidgets(
    'read inbox notification uses payload alias and still verifies attendance resource',
    (tester) async {
      final resources = Resources()..pending['one'] = Completer<TaskModel?>();
      final session = MockSessionCubit(active);
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        firestoreService: InboxRepository(),
        initialLocation: '/notifications',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      await tester.tap(find.text('Push alias'));
      await frames(tester);
      expect(router.state.uri.path, '/tasks/one/attendance');
      resources.pending['one']!.complete(task('one'));
      await frames(tester);
      expect(find.text('Private one'), findsNothing);
      expect(find.text('Page Not Found'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
    },
  );
  testWidgets('profile form cannot retain the previous users draft', (
    tester,
  ) async {
    final profileA = KhademModel(
      id: 'a',
      name: 'Profile A',
      email: 'a@example.org',
      role: 'servant',
      grade: '2nd',
      status: 'active',
      createdAt: DateTime(2026),
    );
    final profileB = KhademModel(
      id: 'b',
      name: 'Profile B',
      email: 'b@example.org',
      role: 'servant',
      grade: '2nd',
      status: 'active',
      createdAt: DateTime(2026),
    );
    final session = MockSessionCubit(active.copyWith(profile: profileA));
    final router = createAppRouter(
      sessionCubit: session,
      initialLocation: '/profile',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    expect(find.text('Profile A'), findsWidgets);
    session.emitMockState(active.copyWith(userId: 'b', profile: profileB));
    await frames(tester);
    expect(find.text('Profile A'), findsNothing);
    expect(find.text('Profile B'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
  });
  testWidgets('user switch clears inbox before the new query returns', (
    tester,
  ) async {
    final session = MockSessionCubit(active),
        repository = IdentityInboxRepository();
    final router = createAppRouter(
      sessionCubit: session,
      firestoreService: repository,
      initialLocation: '/notifications',
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        routerConfig: router,
      ),
    );
    await frames(tester);
    expect(find.text('Push alias'), findsOneWidget);
    session.emitMockState(active.copyWith(userId: 'b'));
    await frames(tester);
    expect(find.text('Push alias'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    unawaited(session.close());
    unawaited(repository.waiting.close());
  });
  testWidgets(
    'fresh internal link after logout binds to the next authorized user',
    (tester) async {
      final resources = Resources()
        ..tasks['one'] = task('one')
        ..tasks['two'] = task('two', owner: 'b');
      final session = MockSessionCubit(active);
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        firestoreService: ShellRepository(),
        initialLocation: '/tasks/one',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      session.emitMockState(const SessionState.signedOut());
      await frames(tester);
      router.go('/tasks/two');
      await frames(tester);
      session.emitMockState(active.copyWith(userId: 'b'));
      await frames(tester);
      expect(router.state.uri.path, '/tasks/two');
      expect(find.text('Private two'), findsOneWidget);
      expect(find.text('Private one'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
    },
  );
  testWidgets(
    'fresh notification after logout waits for the next session verification',
    (tester) async {
      final resources = Resources()..tasks['two'] = task('two', owner: 'b');
      final session = MockSessionCubit(active),
          coordinator = NotificationIntentCoordinator();
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        firestoreService: ShellRepository(),
        notificationIntentCoordinator: coordinator,
        initialLocation: '/forbidden',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      session.emitMockState(const SessionState.signedOut());
      await frames(tester);
      coordinator.enqueue(
        const NotificationIntent(type: 'task', taskId: 'two'),
      );
      await frames(tester);
      expect(coordinator.pendingIntent, isNotNull);
      session.emitMockState(active.copyWith(userId: 'b'));
      await frames(tester);
      expect(router.state.uri.path, '/tasks/two');
      expect(find.text('Private two'), findsOneWidget);
      expect(coordinator.pendingIntent, isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
      coordinator.dispose();
    },
  );
  testWidgets(
    'failed notification lookup allows Home and explicit verified retry',
    (tester) async {
      final resources = Resources()..error = AppFailure.network();
      final session = MockSessionCubit(active),
          coordinator = NotificationIntentCoordinator()
            ..enqueue(const NotificationIntent(type: 'task', taskId: 'one'));
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        firestoreService: ShellRepository(),
        notificationIntentCoordinator: coordinator,
        initialLocation: '/forbidden',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      expect(find.text('Retry'), findsOneWidget);
      expect(coordinator.pendingIntent, isNotNull);
      await tester.tap(find.text('Go Home'));
      await frames(tester);
      expect(router.state.uri.path, '/me/makhdomeen');
      expect(coordinator.pendingIntent, isNotNull);
      router.go('/settings');
      await frames(tester);
      expect(router.state.uri.path, '/settings');
      expect(coordinator.pendingIntent, isNotNull);
      resources.error = null;
      resources.tasks['one'] = task('one');
      router.go('/tasks/one');
      await frames(tester);
      expect(find.text('Private one'), findsOneWidget);
      expect(coordinator.pendingIntent, isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
      coordinator.dispose();
    },
  );
  testWidgets(
    'hanging notification lookup permits user navigation without acknowledgement',
    (tester) async {
      final resources = Resources()..pending['one'] = Completer<TaskModel?>();
      final session = MockSessionCubit(active),
          coordinator = NotificationIntentCoordinator()
            ..enqueue(const NotificationIntent(type: 'task', taskId: 'one'));
      final router = createAppRouter(
        sessionCubit: session,
        resourceLoader: resources,
        firestoreService: ShellRepository(),
        notificationIntentCoordinator: coordinator,
        initialLocation: '/forbidden',
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          routerConfig: router,
        ),
      );
      await frames(tester);
      expect(coordinator.pendingIntent, isNotNull);
      router.go('/me/tasks');
      await frames(tester);
      expect(router.state.uri.path, '/me/tasks');
      expect(coordinator.pendingIntent, isNotNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(session.close());
      coordinator.dispose();
    },
  );
  for (final role in [UserRole.gradeAdmin, UserRole.stageAdmin]) {
    testWidgets(
      '$role settings supports deletion with explicit stage successor constraint',
      (tester) async {
        final session = MockSessionCubit(active.copyWith(role: role));
        final router = createAppRouter(
          sessionCubit: session,
          initialLocation: '/settings',
        );
        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            routerConfig: router,
          ),
        );
        await frames(tester);
        if (role == UserRole.gradeAdmin) {
          expect(find.text('Permanently Delete Account'), findsOneWidget);
          await tester.ensureVisible(find.text('Permanently Delete Account'));
          await tester.tap(find.text('Permanently Delete Account'));
          await frames(tester);
          expect(find.byType(AlertDialog), findsOneWidget);
        } else {
          expect(find.text('Permanently Delete Account'), findsOneWidget);
          await tester.ensureVisible(find.text('Permanently Delete Account'));
          await tester.tap(find.text('Permanently Delete Account'));
          await frames(tester);
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
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        unawaited(session.close());
      },
    );
  }
  for (final grade in ['2nd', '3rd']) {
    testWidgets(
      '$grade first branch change stays in grade and retains task filter',
      (tester) async {
        final session = MockSessionCubit(
          SessionState(
            status: SessionStatus.active,
            userId: 'a',
            role: UserRole.gradeAdmin,
            grade: grade,
          ),
        );
        final router = createAppRouter(
          sessionCubit: session,
          firestoreService: ShellRepository(),
          initialLocation: '/grades/$grade/tasks',
        );
        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            routerConfig: router,
          ),
        );
        await frames(tester);
        await tester.tap(find.textContaining('Completed').first);
        await frames(tester);
        expect(find.text('Private one'), findsNothing);
        final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
        nav.onDestinationSelected!(2);
        await frames(tester);
        expect(
          router.routeInformationProvider.value.uri.path,
          '/grades/$grade/khodam',
        );
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .onDestinationSelected!(3);
        await frames(tester);
        expect(find.text('Private one'), findsNothing);
        expect(find.text('Private done'), findsOneWidget);
        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        );
        await frames(tester);
        expect(
          Directionality.of(tester.element(find.byType(NavigationBar))),
          TextDirection.rtl,
        );
        expect(
          router.routeInformationProvider.value.uri.path,
          '/grades/$grade/tasks',
        );
        expect(find.text('Private one'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        unawaited(session.close());
      },
    );
  }
}

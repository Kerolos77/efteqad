import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/router/app_routes.dart';
import 'package:efteqad/core/router/notification_intent_coordinator.dart';
import 'package:efteqad/core/router/route_access_service.dart';
import 'package:efteqad/core/session/session_state.dart';

void main() {
  group('NotificationIntent & Coordinator Unit Tests (Task 11)', () {
    const routeAccessService = RouteAccessService();
    late NotificationIntentCoordinator coordinator;

    final stageAdminSession = SessionState(
      status: SessionStatus.active,
      userId: 'stage-admin-1',
      role: UserRole.stageAdmin,
      profile: KhademModel(
        id: 'stage-admin-1',
        name: 'Stage Admin',
        email: 'stage@efteqad.com',
        phone: '01000000000',
        role: AppConstants.roleStageAdmin,
        createdAt: DateTime.now(),
      ),
    );

    final grade1AdminSession = SessionState(
      status: SessionStatus.active,
      userId: 'grade-1-admin',
      role: UserRole.gradeAdmin,
      grade: AppConstants.grade1st,
      profile: KhademModel(
        id: 'grade-1-admin',
        name: 'Grade 1 Head',
        email: 'grade1@efteqad.com',
        phone: '01000000001',
        role: AppConstants.roleGradeAdmin,
        grade: AppConstants.grade1st,
        createdAt: DateTime.now(),
      ),
    );

    final servantSession = SessionState(
      status: SessionStatus.active,
      userId: 'servant-1',
      role: UserRole.servant,
      grade: AppConstants.grade2nd,
      profile: KhademModel(
        id: 'servant-1',
        name: 'Servant',
        email: 'servant@efteqad.com',
        phone: '01000000002',
        role: AppConstants.roleServant,
        grade: AppConstants.grade2nd,
        createdAt: DateTime.now(),
      ),
    );

    final pendingSession = SessionState(
      status: SessionStatus.pending,
      userId: 'servant-1',
      role: UserRole.pending,
      profile: KhademModel(
        id: 'servant-1',
        name: 'Pending',
        email: 'pending@efteqad.com',
        phone: '01000000003',
        role: AppConstants.rolePending,
        createdAt: DateTime.now(),
      ),
    );

    const signedOutSession = SessionState.signedOut();

    setUp(() {
      coordinator = NotificationIntentCoordinator(
        routeAccessService: routeAccessService,
      );
    });

    test(
      'parses payload and routes consistently across foreground, local, background, and terminated sources',
      () {
        final terminatedPayload = {'type': 'task', 'taskId': 'task-100'};
        final backgroundPayload = {'type': 'taskDetails', 'taskId': 'task-100'};
        final foregroundPayload = {'type': 'task', 'taskId': 'task-100'};
        final localPayload = {'notificationType': 'task', 'taskId': 'task-100'};

        final intent1 = NotificationIntent.fromPayload(terminatedPayload);
        final intent2 = NotificationIntent.fromPayload(backgroundPayload);
        final intent3 = NotificationIntent.fromPayload(foregroundPayload);
        final intent4 = NotificationIntent.fromPayload(localPayload);

        expect(intent1.toRoutePath(), AppRoutes.taskDetails('task-100'));
        expect(intent2.toRoutePath(), AppRoutes.taskDetails('task-100'));
        expect(intent3.toRoutePath(), AppRoutes.taskDetails('task-100'));
        expect(intent4.toRoutePath(), AppRoutes.taskDetails('task-100'));
      },
    );

    test(
      'correctly maps attendance, makhdom history, and notifications payloads',
      () {
        // Attendance
        final attIntent = NotificationIntent.fromPayload({
          'type': 'attendance',
          'taskId': 'task-200',
        });
        expect(attIntent.toRoutePath(), AppRoutes.taskAttendance('task-200'));

        // Absence alert
        final absenceIntent = NotificationIntent.fromPayload({
          'type': 'absenceAlert',
          'makhdomId': 'mak-300',
        });
        expect(
          absenceIntent.toRoutePath(),
          AppRoutes.makhdomHistory('mak-300'),
        );

        // Absence snake_case
        final absenceSnake = NotificationIntent.fromPayload({
          'type': 'absence_alert',
          'makhdomId': 'mak-300',
        });
        expect(absenceSnake.toRoutePath(), AppRoutes.makhdomHistory('mak-300'));

        // Notifications center
        final notifIntent = NotificationIntent.fromPayload({
          'type': 'notifications',
        });
        expect(notifIntent.toRoutePath(), AppRoutes.notificationsPath);
      },
    );

    test('rejects arbitrary route tampering or path traversal attempts', () {
      final maliciousPayload1 = {
        'type': 'custom_admin_bypass',
        'route': '/stage/people',
      };
      final maliciousPayload2 = {
        'type': 'task',
        'taskId': '../../admin/delete_all',
      };
      final maliciousPayload3 = {
        'type': 'makhdomHistory',
        'makhdomId': ':makhdomId',
      };

      final intent1 = NotificationIntent.fromPayload(maliciousPayload1);
      final intent2 = NotificationIntent.fromPayload(maliciousPayload2);
      final intent3 = NotificationIntent.fromPayload(maliciousPayload3);

      expect(intent1.toRoutePath(), isNull);
      expect(intent2.toRoutePath(), isNull);
      expect(intent3.toRoutePath(), isNull);
    });

    test(
      'retains pending intent during signedOut/pending status, then consumes after active login',
      () {
        coordinator.enqueue(
          const NotificationIntent(type: 'task', taskId: 'task-555'),
        );

        // Attempt while signed out -> retained, returns null
        expect(coordinator.consumeFor(signedOutSession), isNull);
        expect(coordinator.pendingIntent, isNotNull);

        // Attempt while pending -> retained, returns null
        expect(coordinator.consumeFor(pendingSession), isNull);
        expect(coordinator.pendingIntent, isNotNull);

        // Active servant logs in -> consumed and returns path
        final target = coordinator.consumeFor(servantSession);
        expect(target, AppRoutes.taskDetails('task-555'));

        expect(coordinator.pendingIntent, isNotNull);
        coordinator.completeVerified('/tasks/task-555', servantSession);
        // Only the verified resource acknowledges consumption.
        expect(coordinator.consumeFor(servantSession), isNull);
        expect(coordinator.pendingIntent, isNull);
      },
    );

    test(
      'stageAdmin and gradeAdmin consume allowed intents for their scope',
      () {
        coordinator.enqueue(
          const NotificationIntent(type: 'taskDetails', taskId: 'task-777'),
        );
        expect(
          coordinator.consumeFor(stageAdminSession),
          AppRoutes.taskDetails('task-777'),
        );

        coordinator.observe(grade1AdminSession);
        coordinator.enqueue(
          const NotificationIntent(type: 'absence_alert', makhdomId: 'mak-888'),
        );
        expect(
          coordinator.consumeFor(grade1AdminSession),
          AppRoutes.makhdomHistory('mak-888'),
        );
      },
    );

    test('denies cross-scope or unauthorized intent and clears pending', () {
      final invalidIntent = const NotificationIntent(
        type: 'unknown_unsupported_type',
        taskId: '123',
      );
      coordinator.enqueue(invalidIntent);

      expect(coordinator.consumeFor(servantSession), isNull);
      expect(coordinator.pendingIntent, isNull);
    });

    test(
      'backend specific task types map accurately to taskAttendance and taskDetails routes',
      () {
        final khedma = NotificationIntent.fromPayload({
          'type': 'attendance_khedma',
          'taskId': 'khedma-1',
        });
        final qoddas = NotificationIntent.fromPayload({
          'type': 'attendance_qoddas',
          'taskId': 'qoddas-1',
        });
        final visitation = NotificationIntent.fromPayload({
          'type': 'visitation',
          'taskId': 'visit-1',
        });
        final general = NotificationIntent.fromPayload({
          'type': 'general',
          'taskId': 'gen-1',
        });

        expect(khedma.toRoutePath(), AppRoutes.taskAttendance('khedma-1'));
        expect(qoddas.toRoutePath(), AppRoutes.taskAttendance('qoddas-1'));
        expect(visitation.toRoutePath(), AppRoutes.taskDetails('visit-1'));
        expect(general.toRoutePath(), AppRoutes.taskDetails('gen-1'));
      },
    );

    test(
      'enqueue and clear notify listeners on coordinator for immediate router refresh',
      () {
        int notifyCount = 0;
        coordinator.addListener(() {
          notifyCount++;
        });

        coordinator.enqueue(
          const NotificationIntent(type: 'attendance_khedma', taskId: 't-1'),
        );
        expect(notifyCount, 1);

        coordinator.clear();
        expect(notifyCount, 2);
      },
    );

    test(
      'payload IDs cannot inject query, fragments, or encoded traversal',
      () {
        for (final id in [
          'one?scope=all',
          'one#secret',
          '%2e%2e',
          'one%2Fother',
          'https:evil',
          r'one\other',
        ]) {
          expect(
            NotificationIntent(type: 'task', taskId: id).toRoutePath(),
            isNull,
          );
        }
      },
    );
    test('clear() explicitly discards queued intent', () {
      coordinator.enqueue(const NotificationIntent(type: 'notifications'));
      expect(coordinator.pendingIntent, isNotNull);
      coordinator.clear();
      expect(coordinator.pendingIntent, isNull);
      expect(coordinator.consumeFor(servantSession), isNull);
    });
  });
}

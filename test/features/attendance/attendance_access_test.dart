import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/task_model.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/features/attendance/application/attendance_access.dart';

void main() {
  final task = TaskModel(
    id: 't',
    title: 'Attendance',
    assignedKhademId: 's',
    assignedKhademName: 'Servant',
    grade: '1st',
    createdById: 'former',
    createdByName: 'Former admin',
    type: 'attendance_khedma',
    dueDate: DateTime(2026, 10, 9),
    createdAt: DateTime(2026, 10, 8),
  );
  test(
    'current own-grade administrator may manage a task created by another admin',
    () {
      expect(
        canManageAttendance(
          const SessionState(
            status: SessionStatus.active,
            userId: 'g',
            role: UserRole.gradeAdmin,
            grade: '1st',
          ),
          task,
          'g',
        ),
        true,
      );
    },
  );
  test(
    'past creator privilege does not authorize a servant who is not assigned',
    () {
      expect(
        canManageAttendance(
          const SessionState(
            status: SessionStatus.active,
            userId: 'former',
            role: UserRole.servant,
            grade: '1st',
          ),
          task,
          'former',
        ),
        false,
      );
    },
  );
  test('deleting administrator cannot keep attendance controls enabled', () {
    expect(
      canManageAttendance(
        const SessionState(
          status: SessionStatus.deleting,
          userId: 'stage',
          role: UserRole.stageAdmin,
        ),
        task,
        'stage',
      ),
      false,
    );
  });
  test(
    'stale session identity cannot authorize a different authenticated user',
    () {
      expect(
        canManageAttendance(
          const SessionState(
            status: SessionStatus.active,
            userId: 'stage',
            role: UserRole.stageAdmin,
          ),
          task,
          'other',
        ),
        false,
      );
    },
  );
  test(
    'active assigned servant can manage attendance; other-grade admin cannot',
    () {
      expect(
        canManageAttendance(
          const SessionState(
            status: SessionStatus.active,
            userId: 's',
            role: UserRole.servant,
            grade: '1st',
          ),
          task,
          's',
        ),
        true,
      );
      expect(
        canManageAttendance(
          const SessionState(
            status: SessionStatus.active,
            userId: 'g',
            role: UserRole.gradeAdmin,
            grade: '2nd',
          ),
          task,
          'g',
        ),
        false,
      );
    },
  );
}

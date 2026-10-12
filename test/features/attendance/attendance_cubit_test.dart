import 'package:efteqad/core/errors/app_failure.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/features/attendance/application/attendance_cubit.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<void> reopenAttendance({
    required String sessionId,
    required String grade,
    required String reason,
    required String operationId,
  }) async => throw UnimplementedError();
  final StreamController<AttendanceSessionModel?> _sessionController =
      StreamController<AttendanceSessionModel?>.broadcast();

  AttendanceSessionModel? currentSession;
  final List<String> operationLog = [];
  bool shouldFailNext = false;
  String? lastFinalizedTaskId;

  // For controlling asynchronous resolution order
  final List<Completer<void>> pendingCompleters = [];
  bool manualAcks = false;
  bool commitBeforeResponse = false;

  @override
  Stream<AttendanceSessionModel?> watchGradeSession({
    required String sessionId,
    required String grade,
    String? taskId,
    String? expectedUid,
  }) => _sessionController.stream;

  @override
  Stream<List<AttendanceSessionModel>> watchGradeAttendance({
    required String grade,
    DateTime? from,
    DateTime? to,
  }) => Stream.value(currentSession != null ? [currentSession!] : []);

  @override
  Future<void> setPresence({
    required String sessionId,
    required String grade,
    required String makhdomId,
    required bool isPresent,
    required String date,
    required String type,
    required String khademId,
    required String khademName,
    String? taskId,
    String? operationId,
  }) async {
    operationLog.add('setPresence:$makhdomId:$isPresent');

    if (manualAcks && !commitBeforeResponse) {
      final completer = Completer<void>();
      pendingCompleters.add(completer);
      await completer.future;
    }

    if (shouldFailNext) {
      shouldFailNext = false;
      throw Exception('Simulated network failure');
    }

    final currentIds = List<String>.from(
      currentSession?.attendedMakhdomIds ?? [],
    );
    if (isPresent) {
      if (!currentIds.contains(makhdomId)) currentIds.add(makhdomId);
    } else {
      currentIds.remove(makhdomId);
    }

    currentSession = AttendanceSessionModel(
      id: sessionId,
      date: date,
      type: type,
      grade: grade,
      attendedMakhdomIds: currentIds,
      status: currentSession?.status ?? 'draft',
      updatedAt: DateTime.now(),
    );
    _sessionController.add(currentSession);
    if (manualAcks && commitBeforeResponse) {
      final response = Completer<void>();
      pendingCompleters.add(response);
      await response.future;
    }
  }

  @override
  Future<void> finalizeAttendance({
    required String sessionId,
    required String grade,
    String? taskId,
  }) async {
    operationLog.add('finalize:$sessionId:${taskId ?? ''}');
    lastFinalizedTaskId = taskId;
    currentSession = currentSession?.copyWith(
      status: 'finalized',
      finalizedAt: DateTime.now(),
    );
    _sessionController.add(currentSession);
  }

  void emitSession(AttendanceSessionModel? session) {
    currentSession = session;
    _sessionController.add(session);
  }

  void emitError(Object error) {
    _sessionController.addError(error);
  }

  void dispose() {
    _sessionController.close();
  }
}

void main() {
  group('AttendanceCubit Tests', () {
    late FakeAttendanceRepository repository;
    late AttendanceCubit cubit;

    setUp(() {
      repository = FakeAttendanceRepository();
      cubit = AttendanceCubit(
        repository: repository,
        sessionId: '2026-10-09_khedma_1st',
        grade: '1st',
        date: '2026-10-09',
        type: 'khedma',
        khademId: 'khadem_1',
        khademName: 'Servant One',
      );
    });

    tearDown(() async {
      await cubit.close();
      repository.dispose();
    });

    test(
      'Initial state reflects empty session and hasLoadedRemote false until snapshot',
      () {
        expect(cubit.state.remoteIds, isEmpty);
        expect(cubit.state.pendingById, isEmpty);
        expect(cubit.state.isFinalized, isFalse);
        expect(cubit.state.hasLoadedRemote, isFalse);
      },
    );

    test(
      'First two writes keep both IDs without race condition under out-of-order acknowledgments',
      () async {
        repository.manualAcks = true;

        // Launch both writes concurrently
        final future1 = cubit.setPresence(makhdomId: 'm1', isPresent: true);
        final future2 = cubit.setPresence(makhdomId: 'm2', isPresent: true);

        // Verify optimistic update has both
        expect(cubit.isAttended('m1'), isTrue);
        expect(cubit.isAttended('m2'), isTrue);
        expect(cubit.state.pendingById.containsKey('m1'), isTrue);
        expect(cubit.state.pendingById.containsKey('m2'), isTrue);

        await Future<void>.delayed(Duration.zero);
        // Complete write 2 BEFORE write 1 (out of order acknowledgment)
        repository.pendingCompleters[1].complete();
        await future2;
        await Future<void>.delayed(Duration.zero);

        expect(cubit.isAttended('m1'), isTrue);
        expect(cubit.isAttended('m2'), isTrue);

        // Now complete write 1
        repository.pendingCompleters[0].complete();
        await future1;
        await Future<void>.delayed(Duration.zero);

        expect(cubit.isAttended('m1'), isTrue);
        expect(cubit.isAttended('m2'), isTrue);
        expect(cubit.state.remoteIds, containsAll(['m1', 'm2']));
        expect(cubit.state.pendingById, isEmpty);
      },
    );

    for (final finalized in [false, true]) {
      test(
        'old presence HTTP response cannot replace newer remote removal finalized=$finalized',
        () async {
          repository.manualAcks = true;
          repository.commitBeforeResponse = true;
          final save = cubit.setPresence(makhdomId: 'm1', isPresent: true);
          await Future<void>.delayed(Duration.zero);
          repository.emitSession(
            repository.currentSession!.copyWith(
              attendedMakhdomIds: [],
              status: finalized ? 'finalized' : 'draft',
            ),
          );
          await Future<void>.delayed(Duration.zero);
          repository.pendingCompleters.single.complete();
          await save;
          expect(cubit.state.remoteIds, isEmpty);
          expect(cubit.isAttended('m1'), false);
          expect(cubit.state.isFinalized, finalized);
        },
      );
    }

    test('Remote remove is reflected in UI', () async {
      repository.emitSession(
        AttendanceSessionModel(
          id: '2026-10-09_khedma_1st',
          date: '2026-10-09',
          type: 'khedma',
          grade: '1st',
          attendedMakhdomIds: ['m1', 'm2'],
          status: 'draft',
          updatedAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isAttended('m1'), isTrue);
      expect(cubit.isAttended('m2'), isTrue);

      // Remote update removes m2
      repository.emitSession(
        AttendanceSessionModel(
          id: '2026-10-09_khedma_1st',
          date: '2026-10-09',
          type: 'khedma',
          grade: '1st',
          attendedMakhdomIds: ['m1'],
          status: 'draft',
          updatedAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isAttended('m1'), isTrue);
      expect(cubit.isAttended('m2'), isFalse);
    });

    test(
      'Remote null session resets remoteIds without keeping stale state',
      () async {
        repository.emitSession(
          AttendanceSessionModel(
            id: '2026-10-09_khedma_1st',
            date: '2026-10-09',
            type: 'khedma',
            grade: '1st',
            attendedMakhdomIds: ['m1', 'm2'],
            status: 'draft',
            updatedAt: DateTime.now(),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.remoteIds, containsAll(['m1', 'm2']));

        // Remote session is deleted or cleared
        repository.emitSession(null);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.remoteIds, isEmpty);
        expect(cubit.isAttended('m1'), isFalse);
      },
    );

    test(
      'Rapid true -> false toggle retains the latest intent (false)',
      () async {
        final f1 = cubit.setPresence(makhdomId: 'm1', isPresent: true);
        final f2 = cubit.setPresence(makhdomId: 'm1', isPresent: false);

        await Future.wait<void>([f1, f2]);

        expect(cubit.isAttended('m1'), isFalse);
        expect(cubit.state.remoteIds.contains('m1'), isFalse);
      },
    );

    test('Old failure does not cancel a newer user toggle', () async {
      repository.shouldFailNext = true;
      // Start toggle to true which will fail
      final firstToggle = cubit.setPresence(makhdomId: 'm1', isPresent: true);

      // User immediately toggles back to false
      final secondToggle = cubit.setPresence(makhdomId: 'm1', isPresent: false);

      await Future.wait<void>([firstToggle, secondToggle]);

      // Should be false
      expect(cubit.isAttended('m1'), isFalse);
    });

    test('Failed toggle can be retried without duplicate entries', () async {
      repository.shouldFailNext = true;
      await cubit.setPresence(makhdomId: 'm1', isPresent: true);

      expect(cubit.state.status, 'error');
      expect(cubit.state.hasError('m1'), isTrue);

      // Retry the failed operation
      await cubit.retry('m1');

      expect(cubit.state.status, 'idle');
      expect(cubit.state.hasError('m1'), isFalse);
      expect(cubit.isAttended('m1'), isTrue);
      expect(cubit.state.remoteIds.where((id) => id == 'm1').length, 1);

      // Repeating retry when already true does not duplicate
      await cubit.retry('m1');
      expect(cubit.state.remoteIds.where((id) => id == 'm1').length, 1);
    });

    test('Remote stream error sets cubit status to error', () async {
      repository.emitError(Exception('Connection lost'));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, 'error');
    });

    test('Modifying finalized attendance is prevented', () async {
      repository.emitSession(
        AttendanceSessionModel(
          id: '2026-10-09_khedma_1st',
          date: '2026-10-09',
          type: 'khedma',
          grade: '1st',
          attendedMakhdomIds: ['m1'],
          status: 'finalized',
          updatedAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isFinalized, isTrue);

      await expectLater(
        () => cubit.setPresence(makhdomId: 'm2', isPresent: true),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'attendance-finalized',
          ),
        ),
      );
    });

    test(
      'finalizeAttendance with taskId marks session finalized and links task',
      () async {
        repository.emitSession(null);
        await Future<void>.delayed(Duration.zero);
        await cubit.finalizeAttendance(taskId: 'task_att_99');

        expect(cubit.state.isFinalized, isTrue);
        expect(cubit.state.status, 'finalized');
        expect(repository.lastFinalizedTaskId, 'task_att_99');
      },
    );

    test(
      'finalizeAttendance throws StateError when pending writes exist',
      () async {
        repository.manualAcks = true;
        unawaited(cubit.setPresence(makhdomId: 'm1', isPresent: true));

        expect(cubit.state.pendingById, isNotEmpty);

        await expectLater(
          () => cubit.finalizeAttendance(),
          throwsA(isA<StateError>()),
        );

        // Clean up pending completer
        await Future<void>.delayed(Duration.zero);
        repository.pendingCompleters.first.complete();
      },
    );
  });
}

import 'package:efteqad/core/errors/app_failure.dart';
import 'dart:async';
import '../../../core/services/trusted_mutations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/attendance_session_model.dart';
import '../../../core/repositories/attendance_repository.dart';

class AttendanceState {
  final Set<String> remoteIds;
  final Map<String, bool> pendingById;
  final Map<String, Object> saveErrors;
  final Map<String, bool> failedIntentById;
  final String status; // 'idle', 'saving', 'finalizing', 'finalized', 'error'
  final bool isFinalized;
  final bool hasLoadedRemote;

  const AttendanceState({
    this.remoteIds = const {},
    this.pendingById = const {},
    this.saveErrors = const {},
    this.failedIntentById = const {},
    this.status = 'idle',
    this.isFinalized = false,
    this.hasLoadedRemote = false,
  });

  bool isAttended(String makhdomId) {
    if (pendingById.containsKey(makhdomId)) {
      return pendingById[makhdomId]!;
    }
    if (failedIntentById.containsKey(makhdomId)) {
      return failedIntentById[makhdomId]!;
    }
    return remoteIds.contains(makhdomId);
  }

  bool isPending(String makhdomId) => pendingById.containsKey(makhdomId);
  bool hasError(String makhdomId) => saveErrors.containsKey(makhdomId);

  Set<String> get effectiveAttendedIds {
    final set = Set<String>.from(remoteIds);
    pendingById.forEach((id, isPresent) {
      if (isPresent) {
        set.add(id);
      } else {
        set.remove(id);
      }
    });
    failedIntentById.forEach((id, present) {
      if (present) {
        set.add(id);
      } else {
        set.remove(id);
      }
    });
    return set;
  }

  int get attendedCount => effectiveAttendedIds.length;

  AttendanceState copyWith({
    Set<String>? remoteIds,
    Map<String, bool>? pendingById,
    Map<String, Object>? saveErrors,
    Map<String, bool>? failedIntentById,
    String? status,
    bool? isFinalized,
    bool? hasLoadedRemote,
  }) {
    return AttendanceState(
      remoteIds: remoteIds ?? this.remoteIds,
      pendingById: pendingById ?? this.pendingById,
      saveErrors: saveErrors ?? this.saveErrors,
      failedIntentById: failedIntentById ?? this.failedIntentById,
      status: status ?? this.status,
      isFinalized: isFinalized ?? this.isFinalized,
      hasLoadedRemote: hasLoadedRemote ?? this.hasLoadedRemote,
    );
  }
}

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;
  final String sessionId;
  final String grade;
  final String date;
  final String type;
  final String khademId;
  final String khademName;
  final String? taskId;
  final String Function() _userId;

  StreamSubscription<AttendanceSessionModel?>? _sessionSubscription;
  final Map<String, int> _sequences = {};
  final Map<String, Future<void>> _queues = {};
  final Map<String, String> _failedOperations = {};

  AttendanceCubit({
    required AttendanceRepository repository,
    required this.sessionId,
    required this.grade,
    required this.date,
    required this.type,
    required this.khademId,
    required this.khademName,
    this.taskId,
    String Function()? userId,
  }) : _userId = userId ?? (() => khademId),
       _repository = repository,
       super(const AttendanceState()) {
    _initSessionSubscription();
  }

  void _initSessionSubscription() {
    _sessionSubscription = _repository
        .watchGradeSession(
          sessionId: sessionId,
          grade: grade,
          taskId: taskId,
          expectedUid: khademId,
        )
        .listen(
          (session) {
            if (isClosed || _userId() != khademId) return;
            if (session != null) {
              emit(
                state.copyWith(
                  remoteIds: Set<String>.from(session.attendedMakhdomIds),
                  isFinalized: session.isFinalized,
                  status: session.isFinalized
                      ? 'finalized'
                      : (state.pendingById.isEmpty ? 'idle' : 'saving'),
                  hasLoadedRemote: true,
                ),
              );
            } else {
              emit(
                state.copyWith(
                  remoteIds: const {},
                  isFinalized: false,
                  hasLoadedRemote: true,
                  status: state.pendingById.isEmpty ? 'idle' : 'saving',
                ),
              );
            }
          },
          onError: (error) {
            if (isClosed || _userId() != khademId) return;
            emit(state.copyWith(status: 'error', hasLoadedRemote: false));
          },
        );
  }

  Future<void> retryLoading() async {
    if (_userId() != khademId || isClosed) return;
    await _sessionSubscription?.cancel();
    if (isClosed || _userId() != khademId) return;
    _initSessionSubscription();
  }

  bool isAttended(String makhdomId) => state.isAttended(makhdomId);

  Future<void> togglePresence(String makhdomId) async {
    final currentlyPresent = isAttended(makhdomId);
    await setPresence(makhdomId: makhdomId, isPresent: !currentlyPresent);
  }

  Future<void> setPresence({
    required String makhdomId,
    required bool isPresent,
    String? operationId,
  }) async {
    final uid = _userId();
    if (uid != khademId || isClosed) {
      throw StateError('The initiating account changed.');
    }
    if (state.status == 'finalizing') {
      throw StateError('Finalization in progress.');
    }
    if (state.isFinalized) {
      throw AppFailure(
        code: 'attendance-finalized',
        message: 'Attendance is finalized.',
      );
    }

    final currentSeq = (_sequences[makhdomId] ?? 0) + 1;
    _sequences[makhdomId] = currentSeq;

    // تحديث متفائل (Optimistic Update)
    final newPending = Map<String, bool>.from(state.pendingById);
    newPending[makhdomId] = isPresent;

    final newErrors = Map<String, Object>.from(state.saveErrors);
    newErrors.remove(makhdomId);

    final newFailed = Map<String, bool>.from(state.failedIntentById);
    newFailed.remove(makhdomId);

    emit(
      state.copyWith(
        pendingById: newPending,
        saveErrors: newErrors,
        failedIntentById: newFailed,
        status: 'saving',
      ),
    );

    final op = operationId ?? newOperationId('presence');
    final previous = _queues[makhdomId];
    final done = Completer<void>();
    _queues[makhdomId] = done.future;
    try {
      if (previous != null) await previous;
      if (_userId() != uid || isClosed) {
        throw StateError('The initiating account changed.');
      }
      await _repository.setPresence(
        sessionId: sessionId,
        grade: grade,
        makhdomId: makhdomId,
        isPresent: isPresent,
        date: date,
        type: type,
        khademId: khademId,
        khademName: khademName,
        taskId: taskId,
        operationId: op,
      );

      if (_userId() != uid || isClosed) {
        throw StateError('The initiating account changed.');
      }
      // تحقق من تسلسل الطلب لضمان عدم تجاوز طلب أحدث
      if (!isClosed && _sequences[makhdomId] == currentSeq) {
        _failedOperations.remove(makhdomId);
        final updatedPending = Map<String, bool>.from(state.pendingById);
        updatedPending.remove(makhdomId);

        final updatedFailed = Map<String, bool>.from(state.failedIntentById);
        updatedFailed.remove(makhdomId);

        emit(
          state.copyWith(
            pendingById: updatedPending,
            failedIntentById: updatedFailed,
            status: updatedPending.isEmpty
                ? (state.isFinalized ? 'finalized' : 'idle')
                : 'saving',
          ),
        );
      }
    } catch (e) {
      if (!isClosed && _sequences[makhdomId] == currentSeq) {
        final updatedPending = Map<String, bool>.from(state.pendingById);
        updatedPending.remove(makhdomId);

        final updatedErrors = Map<String, Object>.from(state.saveErrors);
        updatedErrors[makhdomId] = e;

        final updatedFailed = Map<String, bool>.from(state.failedIntentById);
        updatedFailed[makhdomId] = isPresent;
        _failedOperations[makhdomId] = op;

        emit(
          state.copyWith(
            pendingById: updatedPending,
            saveErrors: updatedErrors,
            failedIntentById: updatedFailed,
            status: 'error',
          ),
        );
      }
    } finally {
      done.complete();
      if (identical(_queues[makhdomId], done.future)) _queues.remove(makhdomId);
    }
  }

  Future<void> retry(String makhdomId) async {
    if (!state.hasError(makhdomId) &&
        !state.failedIntentById.containsKey(makhdomId)) {
      return;
    }
    final target = state.failedIntentById[makhdomId] ?? isAttended(makhdomId);
    await setPresence(
      makhdomId: makhdomId,
      isPresent: target,
      operationId: _failedOperations[makhdomId],
    );
  }

  Future<void> finalizeAttendance({String? taskId}) async {
    if (isClosed || _userId() != khademId) {
      throw StateError('The initiating account changed.');
    }
    if (!state.hasLoadedRemote ||
        state.saveErrors.isNotEmpty ||
        state.failedIntentById.isNotEmpty) {
      throw StateError(
        'Resolve attendance loading and failed saves before finalizing.',
      );
    }
    if (state.pendingById.isNotEmpty) {
      throw AppFailure(
        code: 'pending-saves',
        message: 'Attendance saves are pending.',
        retryable: true,
      );
    }

    emit(state.copyWith(status: 'finalizing'));

    try {
      await _repository.finalizeAttendance(
        sessionId: sessionId,
        grade: grade,
        taskId: taskId ?? this.taskId,
      );
      if (isClosed || _userId() != khademId) {
        throw StateError('The initiating account changed.');
      }
      emit(state.copyWith(status: 'finalized', isFinalized: true));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(status: 'error'));
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }
}

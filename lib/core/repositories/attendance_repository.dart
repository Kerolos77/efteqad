import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/constants.dart';
import '../models/attendance_session_model.dart';
import '../models/snapshot_list.dart';
import '../errors/app_failure.dart';
import '../services/trusted_mutations.dart';

abstract class AttendanceRepository {
  Stream<AttendanceSessionModel?> watchGradeSession({
    required String sessionId,
    required String grade,
    String? taskId,
    String? expectedUid,
  });
  Stream<List<AttendanceSessionModel>> watchGradeAttendance({
    required String grade,
    DateTime? from,
    DateTime? to,
  });
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
  });
  Future<void> finalizeAttendance({
    required String sessionId,
    required String grade,
    String? taskId,
  });
  Future<void> reopenAttendance({
    required String sessionId,
    required String grade,
    required String reason,
    required String operationId,
  });
}

typedef AttendancePartStream =
    Stream<AttendanceSessionModel?> Function(String sessionId, String grade);

class FirestoreAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  final TrustedMutations _mutations;
  final AttendancePartStream? _sessionStream;
  FirestoreAttendanceRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    TrustedMutations? mutations,
    AttendancePartStream? sessionStream,
  }) : _providedFirestore = firestore,
       _mutations = mutations ?? TrustedMutations(functions: functions),
       _sessionStream = sessionStream;
  Stream<AttendanceSessionModel?> _part(String sessionId, String grade) =>
      _sessionStream?.call(sessionId, grade) ??
      _firestore
          .collection(AppConstants.colAttendance)
          .doc(sessionId)
          .collection('grades')
          .doc(grade)
          .snapshots(includeMetadataChanges: true)
          .where(
            (snap) =>
                !snap.metadata.isFromCache && !snap.metadata.hasPendingWrites,
          )
          .map(
            (snap) => snap.exists
                ? AttendanceSessionModel.fromMap(snap.data()!, sessionId)
                : null,
          );
  @override
  Stream<AttendanceSessionModel?> watchGradeSession({
    required String sessionId,
    required String grade,
    String? taskId,
    String? expectedUid,
  }) {
    if (taskId != null) {
      return _initializedSession(sessionId, grade, taskId, expectedUid);
    }
    if (grade != 'all') return _part(sessionId, grade);
    late StreamController<AttendanceSessionModel?> controller;
    final latest = <String, AttendanceSessionModel?>{};
    final subscriptions = <StreamSubscription<AttendanceSessionModel?>>[];
    controller = StreamController<AttendanceSessionModel?>(
      onListen: () {
        for (final g in ['1st', '2nd', '3rd']) {
          subscriptions.add(
            _part(sessionId, g).listen((part) {
              latest[g] = part;
              if (latest.length != 3) return;
              final parts = latest.values
                  .whereType<AttendanceSessionModel>()
                  .toList();
              if (parts.isEmpty) {
                controller.add(null);
                return;
              }
              final first = parts.first;
              controller.add(
                first.copyWith(
                  id: sessionId,
                  grade: 'all',
                  attendedMakhdomIds: parts
                      .expand((p) => p.attendedMakhdomIds)
                      .toSet()
                      .toList(),
                  status: parts.any((p) => p.isFinalized)
                      ? 'finalized'
                      : 'draft',
                ),
              );
            }, onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<AttendanceSessionModel?> _initializedSession(
    String sessionId,
    String grade,
    String taskId,
    String? expectedUid,
  ) async* {
    await _mutations.call('initializeAttendance', {
      'sessionId': sessionId,
      'grade': grade,
      'taskId': taskId,
    }, expectedUid: expectedUid);
    yield* watchGradeSession(sessionId: sessionId, grade: grade);
  }

  @override
  Stream<List<AttendanceSessionModel>> watchGradeAttendance({
    required String grade,
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('grades')
        .where('grade', isEqualTo: grade);
    if (from != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime.utc(from.year, from.month, from.day),
        ),
      );
    }
    if (to != null) {
      query = query.where(
        'date',
        isLessThan: Timestamp.fromDate(
          DateTime.utc(to.year, to.month, to.day + 1),
        ),
      );
    }
    return query
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => SnapshotList<AttendanceSessionModel>.fromSnapshot(
            snap,
            (doc) => AttendanceSessionModel.fromMap(
              doc.data(),
              doc.data()['sessionId'] as String? ??
                  doc.reference.parent.parent!.id,
            ),
          ),
        )
        .handleError(
          (Object e, StackTrace st) => throw AppFailure.fromException(e, st),
        );
  }

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
    await _mutations.call('setAttendancePresence', {
      'expectedUid': khademId,
      'sessionId': sessionId,
      'grade': grade,
      'makhdomId': makhdomId,
      'isPresent': isPresent,
      'date': date,
      'type': type,
      if (taskId != null) 'taskId': taskId,
      'operationId': operationId ?? newOperationId('presence'),
    });
  }

  @override
  Future<void> finalizeAttendance({
    required String sessionId,
    required String grade,
    String? taskId,
  }) async {
    await _mutations.call('finalizeAttendance', {
      'sessionId': sessionId,
      'grade': grade,
      if (taskId != null) 'taskId': taskId,
    });
  }

  @override
  Future<void> reopenAttendance({
    required String sessionId,
    required String grade,
    required String reason,
    required String operationId,
  }) async {
    await _mutations.call('reopenAttendance', {
      'sessionId': sessionId,
      'grade': grade,
      'reason': reason,
      'operationId': operationId,
    });
  }
}

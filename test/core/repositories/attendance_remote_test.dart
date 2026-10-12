import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
// External SDK interfaces are intentionally simulated only in this test.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/features/attendance/application/attendance_cubit.dart';

// Only the external Firestore SDK snapshot boundary is simulated.
class MetadataSdk implements SnapshotMetadata {
  @override
  final bool isFromCache;
  MetadataSdk(this.isFromCache);
  @override
  bool get hasPendingWrites => false;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class SnapshotSdk implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final SnapshotMetadata metadata;
  SnapshotSdk(bool cached) : metadata = MetadataSdk(cached);
  @override
  bool get exists => false;
  @override
  Map<String, dynamic>? data() => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class DocumentSdk implements DocumentReference<Map<String, dynamic>> {
  final StoreSdk store;
  final String idValue;
  DocumentSdk(this.store, this.idValue);
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #collection) return CollectionSdk(store);
    if (i.memberName == #snapshots) {
      store.metadataListeners[idValue] =
          i.namedArguments[#includeMetadataChanges] == true;
      return store.controllers
          .putIfAbsent(
            idValue,
            () =>
                StreamController<
                  DocumentSnapshot<Map<String, dynamic>>
                >.broadcast(),
          )
          .stream;
    }
    return super.noSuchMethod(i);
  }
}

class CollectionSdk implements CollectionReference<Map<String, dynamic>> {
  final StoreSdk store;
  CollectionSdk(this.store);
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #doc) {
      return DocumentSdk(store, i.positionalArguments.single as String);
    }
    return super.noSuchMethod(i);
  }
}

class StoreSdk implements FirebaseFirestore {
  final controllers =
      <String, StreamController<DocumentSnapshot<Map<String, dynamic>>>>{};
  final metadataListeners = <String, bool>{};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      CollectionSdk(this);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  Future<void> close() async {
    for (final c in controllers.values) {
      await c.close();
    }
  }
}

void main() {
  test(
    'task session initializes before subscribing and retries a denied initial load',
    () async {
      var initialized = false, fail = true, watches = 0, calls = 0;
      final repo = FirestoreAttendanceRepository(
        mutations: TrustedMutations(
          userId: () => 's',
          transport: (name, p) async {
            expect(name, 'initializeAttendance');
            expect(p['expectedUid'], 's');
            calls++;
            if (fail) throw StateError('initial read unavailable');
            initialized = true;
            return {'success': true};
          },
        ),
        sessionStream: (sid, g) {
          expect(initialized, true);
          watches++;
          return Stream.value(
            AttendanceSessionModel(
              id: sid,
              date: '2026-10-09',
              grade: g,
              type: 'qoddas',
              attendedMakhdomIds: [],
              updatedAt: DateTime(2026),
            ),
          );
        },
      );
      final cubit = AttendanceCubit(
        repository: repo,
        sessionId: '2026-10-09_qoddas_all',
        grade: 'all',
        date: '2026-10-09',
        type: 'qoddas',
        khademId: 's',
        khademName: 'S',
        taskId: 'new',
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.hasLoadedRemote, false);
      expect(watches, 0);
      fail = false;
      await cubit.retryLoading();
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
      expect(watches, 3);
      expect(cubit.state.hasLoadedRemote, true);
      expect(cubit.state.remoteIds, isEmpty);
      await cubit.close();
    },
  );

  for (final scope in ['1st', 'all']) {
    test(
      'cached missing $scope attendance stays unknown until every identical server snapshot arrives',
      () async {
        final sdk = StoreSdk();
        final cubit = AttendanceCubit(
          repository: FirestoreAttendanceRepository(firestore: sdk),
          sessionId: '2026-10-09_qoddas_$scope',
          grade: scope,
          date: '2026-10-09',
          type: 'qoddas',
          khademId: 's',
          khademName: 'S',
        );
        addTearDown(() async {
          await cubit.close();
          await sdk.close();
        });
        for (final c in sdk.controllers.values) {
          c.add(SnapshotSdk(true));
        }
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.hasLoadedRemote, false);
        final grades = scope == 'all' ? ['1st', '2nd', '3rd'] : ['1st'];
        for (var i = 0; i < grades.length; i++) {
          final grade = grades[i];
          expect(
            sdk.metadataListeners[grade],
            true,
            reason:
                'Otherwise identical cache-to-server missing document is not delivered by SDK',
          );
          sdk.controllers[grade]!.add(SnapshotSdk(false));
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.hasLoadedRemote, i == grades.length - 1);
        }
      },
    );
  }
}

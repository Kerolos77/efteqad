import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/visit_draft_store.dart';
import 'package:efteqad/core/repositories/visit_repository.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/features/attendance/application/attendance_cubit.dart';

class DelayedDrafts extends VisitDraftStore {
  final saved = Completer<void>();
  final release = Completer<void>();
  bool delay = true;
  @override
  Future<void> saveDraft(String uid, Map<String, dynamic> draft) async {
    await super.saveDraft(uid, draft);
    if (delay) {
      saved.complete();
      await release.future;
      delay = false;
    }
  }
}

void main() {
  test(
    'assignment chunk continuation cannot use replacement account; A resumes stable receipt',
    () async {
      var uid = 'A';
      final response = Completer<Map<String, dynamic>>();
      final sent = <Map<String, dynamic>>[];
      final mutations = TrustedMutations(
        userId: () => uid,
        transport: (n, p) async {
          sent.add(p);
          final ids = p['ids'] as List;
          final result = {
            'assignedCount': ids.length,
            'results': ids
                .map((id) => {'id': id, 'status': 'assigned'})
                .toList(),
          };
          if (sent.length == 1) return response.future;
          return result;
        },
      );
      final ids = List.generate(201, (i) => 'child$i');
      Future<void> assign() => mutations.assign(
        ids: ids,
        expectedAssignments: {for (final id in ids) id: null},
        operationId: 'stable',
      );
      final run = assign();
      final failed = expectLater(run, throwsA(anything));
      uid = 'B';
      response.complete({'assignedCount': 200, 'results': []});
      await failed;
      expect(sent.length, 1);
      expect(sent.single['expectedUid'], 'A');
      uid = 'A';
      await assign();
      expect(sent.length, 3);
      expect(sent[1]['operationId'], sent.first['operationId']);
      expect(sent.last['expectedUid'], 'A');
    },
  );
  test(
    'visit draft save settling after A to B keeps A unresolved intent without sending; A resumes',
    () async {
      SharedPreferences.setMockInitialValues({});
      var uid = 'A';
      final store = DelayedDrafts();
      final sent = <Map<String, dynamic>>[];
      final repo = FirestoreVisitRepository(
        userId: () => uid,
        drafts: store,
        mutations: TrustedMutations(
          userId: () => uid,
          transport: (n, p) async {
            sent.add(p);
            return {'visitId': 'saved'};
          },
        ),
      );
      final visit = VisitModel(
        id: '',
        makhdomId: 'm',
        makhdomName: 'Child',
        khademId: 'A',
        khademName: 'A',
        visitDate: DateTime(2026, 10, 8),
        visitType: 'home',
        notes: 'Intent',
        createdAt: DateTime(2026),
      );
      final save = repo.recordVisit(visit: visit, operationId: 'stable');
      final failed = expectLater(save, throwsA(anything));
      await store.saved.future;
      uid = 'B';
      store.release.complete();
      await failed;
      expect(sent, isEmpty);
      expect((await store.getDrafts('A')).single['operationId'], 'stable');
      expect(await store.getDrafts('B'), isEmpty);
      uid = 'A';
      expect(await repo.recordVisit(visit: visit), 'saved');
      expect(sent.single['expectedUid'], 'A');
      expect(await store.getDrafts('A'), isEmpty);
    },
  );
  test(
    'queued attendance cannot send as B and A can retry retained latest intent',
    () async {
      var uid = 'A';
      final first = Completer<Map<String, dynamic>>();
      final sent = <Map<String, dynamic>>[];
      final repo = FirestoreAttendanceRepository(
        sessionStream: (_, _) => Stream.value(null),
        mutations: TrustedMutations(
          userId: () => uid,
          transport: (n, p) async {
            sent.add(p);
            if (sent.length == 1) return first.future;
            return {'success': true};
          },
        ),
      );
      final cubit = AttendanceCubit(
        repository: repo,
        sessionId: '2026-10-08_khedma_1st',
        grade: '1st',
        date: '2026-10-08',
        type: 'khedma',
        khademId: 'A',
        khademName: 'A',
        userId: () => uid,
      );
      final on = cubit.setPresence(makhdomId: 'm', isPresent: true);
      final off = cubit.setPresence(makhdomId: 'm', isPresent: false);
      uid = 'B';
      first.complete({'success': true});
      await Future.wait([on, off]);
      expect(sent.length, 1);
      expect(sent.single['expectedUid'], 'A');
      expect(cubit.state.failedIntentById, {'m': false});
      await expectLater(cubit.retry('m'), throwsStateError);
      expect(sent.length, 1);
      uid = 'A';
      await cubit.retry('m');
      expect(sent.last['expectedUid'], 'A');
      expect(sent.last['isPresent'], false);
      await cubit.close();
    },
  );
}

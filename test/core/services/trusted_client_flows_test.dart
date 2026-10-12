import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/visit_draft_store.dart';
import 'package:efteqad/core/models/task_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/models/makhdom_profile_patch.dart';
import 'package:efteqad/core/repositories/visit_repository.dart';
import 'package:efteqad/core/repositories/attendance_repository.dart';
import 'package:efteqad/features/attendance/application/attendance_cubit.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'both service task paths emit trusted JSON and return actual server ID',
    () async {
      final payloads = <Map<String, dynamic>>[];
      final names = <String>[];
      final mutations = TrustedMutations(
        transport: (name, payload) async {
          names.add(name);
          payloads.add(payload);
          return {'taskId': 'server-task'};
        },
      );
      final service = FirestoreService(mutations: mutations);
      final task = TaskModel(
        id: '',
        title: 'Private',
        description: 'details',
        assignedKhademId: 's',
        assignedKhademName: 'Spoof',
        grade: '1st',
        createdById: 'spoof',
        createdByName: 'spoof',
        type: 'attendance_khedma',
        dueDate: DateTime.utc(2026, 10, 9),
        createdAt: DateTime.utc(2026, 10, 8),
      );
      expect(await service.addTask(task, operationId: 'stable'), 'server-task');
      expect(
        await service.createTaskWithOutbox(
          task: task,
          outboxTitle: 'ignored',
          outboxBody: 'ignored',
          operationId: 'stable',
        ),
        'server-task',
      );
      expect(names, ['createTask', 'createTask']);
      expect(payloads.first, {
        'operationId': 'stable',
        'taskData': {
          'title': 'Private',
          'description': 'details',
          'assignedKhademId': 's',
          'grade': '1st',
          'type': 'attendance_khedma',
          'dueDate': '2026-10-09T00:00:00.000Z',
        },
      });
      expect(payloads.last, payloads.first);
    },
  );
  test(
    'profile explicit clears and patch fields survive the callable boundary',
    () async {
      Map<String, dynamic>? sent;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (name, p) async {
            expect(name, 'saveMakhdomProfile');
            sent = p;
            return {'makhdomId': 'm'};
          },
        ),
      );
      await service.updateMakhdomPatch(
        'm',
        const MakhdomProfilePatch(
          address: '',
          notes: 'general',
          clearPhotoUrl: true,
          clearBirthDate: true,
          clearHomeLocationUrl: true,
        ),
      );
      expect(sent!['patch'], {
        'address': '',
        'notes': 'general',
        'photoUrl': null,
        'birthDate': null,
        'homeLocationUrl': null,
      });
    },
  );
  test(
    'protected profile fields never silently disappear from a patch',
    () async {
      var calls = 0;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            calls++;
            return {'makhdomId': 'm'};
          },
        ),
      );
      await expectLater(
        service.updateMakhdomPatch(
          'm',
          const MakhdomProfilePatch(active: false),
        ),
        throwsArgumentError,
      );
      expect(calls, 0);
    },
  );
  test(
    'partial assignment response propagates conflict IDs to the real service caller',
    () async {
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async => {
            'assignedCount': 1,
            'results': [
              {'id': 'a', 'status': 'assigned'},
              {'id': 'b', 'status': 'conflict'},
              {'id': 'c', 'status': 'not-found'},
            ],
          },
        ),
      );
      await expectLater(
        service.assignMakhdomeenToKhadem(
          khademId: 's',
          khademName: 'S',
          makhdomeenIds: ['a', 'b', 'c'],
          expectedAssignments: {'a': null, 'b': null, 'c': null},
        ),
        throwsA(
          isA<PartialAssignmentFailure>().having((e) => e.failedIds, 'IDs', [
            'b',
            'c',
          ]),
        ),
      );
    },
  );
  test(
    'repository persists visit before transport; failed retry reuses operation ID and clears only confirmed draft',
    () async {
      final store = VisitDraftStore();
      final sent = <Map<String, dynamic>>[];
      bool fail = true;
      final repo = FirestoreVisitRepository(
        userId: () => 'u',
        drafts: store,
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'recordVisit');
            expect(
              (await store.getDrafts('u')).single['operationId'],
              'stable',
            );
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'visitId': 'server-visit'};
          },
        ),
      );
      final visit = VisitModel(
        id: '',
        makhdomId: 'm',
        makhdomName: 'M',
        khademId: 'u',
        khademName: 'U',
        visitDate: DateTime.utc(2026, 10, 9),
        visitType: 'مكالمة هاتفية',
        notes: 'text never translated',
        createdAt: DateTime.utc(2026, 10, 8),
      );
      await expectLater(
        repo.recordVisit(visit: visit, operationId: 'stable'),
        throwsA(anything),
      );
      expect(
        (await store.getDrafts('u')).single['notes'],
        'text never translated',
      );
      expect(await store.getDrafts('other'), isEmpty);
      fail = false;
      expect(
        await repo.recordVisit(visit: visit, operationId: 'stable'),
        'server-visit',
      );
      expect(sent.last, sent.first);
      expect(sent.first['visitType'], 'phone');
      expect(await store.getDrafts('u'), isEmpty);
    },
  );
  test(
    'assignment batches honor 200-row contract and retain all conflicts',
    () async {
      final lengths = <int>[];
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            final ids = p['ids'] as List;
            lengths.add(ids.length);
            if (ids.length > 200) throw StateError('Too many IDs');
            return {
              'assignedCount': ids.length,
              'results': ids
                  .map((id) => {'id': id, 'status': 'assigned'})
                  .toList(),
            };
          },
        ),
      );
      final ids = List.generate(201, (i) => 'm$i');
      await service.assignMakhdomeenToKhadem(
        khademId: 's',
        khademName: 'S',
        makhdomeenIds: ids,
        expectedAssignments: {for (final id in ids) id: null},
      );
      expect(lengths, [200, 1]);
    },
  );
  test(
    'attendance real repository emits task context and cubit serializes latest intent',
    () async {
      final requests = <Map<String, dynamic>>[];
      final first = Completer<void>();
      final repo = FirestoreAttendanceRepository(
        mutations: TrustedMutations(
          transport: (n, p) async {
            if (n == 'initializeAttendance') return {'success': true};
            requests.add(p);
            if (requests.length == 1) await first.future;
            return {'success': true};
          },
        ),
        sessionStream: (_, _) => Stream.value(null),
      );
      final cubit = AttendanceCubit(
        repository: repo,
        sessionId: '2026-10-09_khedma_1st',
        grade: '1st',
        date: '2026-10-09',
        type: 'khedma',
        khademId: 'u',
        khademName: 'U',
        taskId: 'actual-task',
      );
      await Future<void>.delayed(Duration.zero);
      final on = cubit.setPresence(makhdomId: 'm', isPresent: true);
      final off = cubit.setPresence(makhdomId: 'm', isPresent: false);
      await Future<void>.delayed(Duration.zero);
      expect(requests.length, 1);
      first.complete();
      await Future.wait([on, off]);
      expect(requests.map((p) => p['isPresent']), [true, false]);
      expect(requests.last['taskId'], 'actual-task');
      expect(requests.last['date'], '2026-10-09');
      expect(
        requests.first['operationId'],
        isNot(requests.last['operationId']),
      );
      expect(cubit.isAttended('m'), false);
      await cubit.close();
    },
  );
  test(
    'attendance failed save and unknown remote snapshot prevent finalization',
    () async {
      final stream = StreamController<dynamic>();
      final repo = FirestoreAttendanceRepository(
        mutations: TrustedMutations(
          transport: (n, p) async {
            if (n == 'initializeAttendance') return {'success': true};
            throw StateError('offline');
          },
        ),
        sessionStream: (_, _) => stream.stream.cast(),
      );
      final cubit = AttendanceCubit(
        repository: repo,
        sessionId: '2026-10-09_khedma_1st',
        grade: '1st',
        date: '2026-10-09',
        type: 'khedma',
        khademId: 'u',
        khademName: 'U',
        taskId: 't',
      );
      await expectLater(cubit.finalizeAttendance(), throwsStateError);
      stream.add(null);
      await Future<void>.delayed(Duration.zero);
      await cubit.setPresence(makhdomId: 'm', isPresent: true);
      expect(cubit.state.failedIntentById, {'m': true});
      await expectLater(cubit.finalizeAttendance(), throwsStateError);
      await cubit.close();
      await stream.close();
    },
  );
}

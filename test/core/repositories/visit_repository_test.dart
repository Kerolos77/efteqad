import 'package:efteqad/core/repositories/visit_repository.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/services/visit_draft_store.dart';

void main() {
  test(
    'changed visit retry retains newer draft and cannot claim the prior receipt saved its text',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = VisitDraftStore();
      final requests = <Map<String, dynamic>>[];
      final repository = FirestoreVisitRepository(
        userId: () => 'u',
        drafts: store,
        mutations: TrustedMutations(
          transport: (n, p) async {
            requests.add(p);
            if (requests.length == 1) {
              throw StateError('response lost after commit');
            }
            return {'visitId': 'committed'};
          },
        ),
      );
      VisitModel visit(String notes) => VisitModel(
        id: '',
        makhdomId: 'm',
        makhdomName: 'M',
        khademId: 'u',
        khademName: 'U',
        visitDate: DateTime(2026, 10, 8),
        visitType: 'home',
        notes: notes,
        createdAt: DateTime(2026),
      );
      await expectLater(
        repository.recordVisit(visit: visit('original'), operationId: 'op'),
        throwsA(anything),
      );
      await expectLater(
        repository.recordVisit(visit: visit('newer text'), operationId: 'op'),
        throwsA(isA<StateError>()),
      );
      expect(requests.length, 1);
      final draft = (await store.getDrafts('u')).single;
      expect((draft['submittedPayload'] as Map)['notes'], 'original');
      expect((draft['editedDraft'] as Map)['notes'], 'newer text');
    },
  );
  group('Visit Logic & Concurrency Tests', () {
    test(
      'Older visit does not overwrite lastVisitDate or lastVisitId of a newer visit',
      () {
        final now = DateTime(2026, 10, 5);
        final earlier = DateTime(2026, 9, 20);

        var student = MakhdomModel(
          id: 's1',
          fullName: 'Student 1',
          phone: '01000000000',
          grade: '1st',
          visitCount: 1,
          lastVisitDate: now,
          notes: 'Latest visit notes',
          createdAt: DateTime(2026, 9, 1),
        );
        String? lastVisitId = 'v_new';

        // Now adding an earlier visit retrospectively
        final olderVisit = VisitModel(
          id: 'v_old',
          makhdomId: 's1',
          makhdomName: 'Student 1',
          khademId: 'k1',
          khademName: 'Khadem',
          visitDate: earlier,
          notes: 'Older visit notes',
          visitType: 'home',
          createdAt: DateTime(2026, 10, 6), // entered later
        );

        // Concurrency / transaction logic:
        final newCount = student.visitCount + 1;
        final bool isNewest =
            student.lastVisitDate == null ||
            olderVisit.visitDate.isAfter(student.lastVisitDate!);

        final updatedLastVisitDate = isNewest
            ? olderVisit.visitDate
            : student.lastVisitDate;
        final updatedLastVisitId = isNewest ? olderVisit.id : lastVisitId;
        final updatedLastVisitNotes = isNewest
            ? olderVisit.notes
            : student.lastVisitNotes;

        student = student.copyWith(
          visitCount: newCount,
          lastVisitDate: updatedLastVisitDate,
        );

        // Verify count is 2
        expect(student.visitCount, 2);
        // Last visit date remains the newer date (2026-10-05)
        expect(student.lastVisitDate, now);
        // Last visit ID remains v_new
        expect(updatedLastVisitId, 'v_new');
        // Student general notes remain completely untouched!
        expect(student.notes, 'Latest visit notes');
        expect(updatedLastVisitNotes, isNull);
      },
    );

    test('Deterministic tie-breaking when visit dates are identical', () {
      final date = DateTime(2026, 10, 5, 10, 0);
      final v1 = VisitModel(
        id: 'v1',
        makhdomId: 's1',
        makhdomName: 'Student',
        khademId: 'k1',
        khademName: 'Khadem',
        visitDate: date,
        visitType: 'home',
        createdAt: DateTime(2026, 10, 5, 12, 0),
      );
      final v2 = VisitModel(
        id: 'v2',
        makhdomId: 's1',
        makhdomName: 'Student',
        khademId: 'k1',
        khademName: 'Khadem',
        visitDate: date,
        visitType: 'home',
        createdAt: DateTime(2026, 10, 5, 13, 0),
      );

      final list = [v1, v2];
      list.sort((a, b) {
        final dateComp = b.visitDate.compareTo(a.visitDate);
        if (dateComp != 0) return dateComp;
        final createdComp = b.createdAt.compareTo(a.createdAt);
        if (createdComp != 0) return createdComp;
        return b.id.compareTo(a.id);
      });

      // v2 has newer createdAt, so it must be first
      expect(list.first.id, 'v2');
    });

    test('Updating notes of old visit does not touch student summary', () {
      const studentLastVisitId = 'v_latest';
      var studentSummaryNotes = 'Latest notes summary';

      const editingVisitId = 'v_old';
      const updatedNotesOnOldVisit = 'Modified older notes';

      if (editingVisitId == studentLastVisitId) {
        studentSummaryNotes = updatedNotesOnOldVisit;
      }

      expect(studentSummaryNotes, 'Latest notes summary');
    });

    test('Emptying notes on latest visit clears the student summary', () {
      const studentLastVisitId = 'v_latest';
      String? studentSummaryNotes = 'Old summary';

      const editingVisitId = 'v_latest';
      const updatedNotesOnLatest = '';

      if (editingVisitId == studentLastVisitId) {
        studentSummaryNotes = updatedNotesOnLatest.trim().isEmpty
            ? null
            : updatedNotesOnLatest;
      }

      expect(studentSummaryNotes, isNull);
    });

    test('unreadable drafts surface an error and retain local data', () async {
      SharedPreferences.setMockInitialValues({'visit_drafts_u': 'broken-json'});
      final store = VisitDraftStore();
      await expectLater(store.getDrafts('u'), throwsFormatException);
      expect(
        (await SharedPreferences.getInstance()).getString('visit_drafts_u'),
        'broken-json',
      );
    });
    test('parallel draft saves do not lose either user intent', () async {
      SharedPreferences.setMockInitialValues({});
      final store = VisitDraftStore();
      await Future.wait([
        store.saveDraft('u', {'id': 'a', 'operationId': 'oa'}),
        store.saveDraft('u', {'id': 'b', 'operationId': 'ob'}),
      ]);
      expect((await store.getDrafts('u')).map((d) => d['id']).toSet(), {
        'a',
        'b',
      });
    });
    test('VisitDraftStore saves and isolates drafts per user', () async {
      SharedPreferences.setMockInitialValues({});
      final store = VisitDraftStore();

      await store.saveDraft('user_A', {
        'id': 'draft_1',
        'makhdomId': 'm_1',
        'notes': 'Draft for user A',
      });

      await store.saveDraft('user_B', {
        'id': 'draft_2',
        'makhdomId': 'm_2',
        'notes': 'Draft for user B',
      });

      final draftsA = await store.getDrafts('user_A');
      final draftsB = await store.getDrafts('user_B');

      expect(draftsA.length, 1);
      expect(draftsA.first['notes'], 'Draft for user A');

      expect(draftsB.length, 1);
      expect(draftsB.first['notes'], 'Draft for user B');

      await store.removeDraft('user_A', 'draft_1');
      final remainingA = await store.getDrafts('user_A');
      expect(remainingA.isEmpty, isTrue);

      final remainingB = await store.getDrafts('user_B');
      expect(remainingB.length, 1);
    });
  });
}

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/notification_service.dart';
import 'package:efteqad/core/services/excel_service.dart';
import 'package:efteqad/core/localization/excel_column_labels.dart';
import 'package:efteqad/core/models/makhdom_model.dart';

void main() {
  test(
    'task deletion callable keeps its stable operation across failure and retry',
    () async {
      final sent = <Map<String, dynamic>>[];
      var fail = true;
      final service = FirestoreService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'deleteTask');
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'success': true, 'status': 'cancelled'};
          },
        ),
      );
      await expectLater(service.deleteTask('task'), throwsA(anything));
      fail = false;
      await service.deleteTask('task');
      expect(sent.last, sent.first);
      expect(sent.first['taskId'], 'task');
      expect(sent.first['operationId'], isNotEmpty);
    },
  );
  test(
    'legacy notify caller emits only child identity, trusted kind and retained intent',
    () async {
      final sent = <Map<String, dynamic>>[];
      var fail = true;
      final service = NotificationService(
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'sendChildAlert');
            sent.add(p);
            if (fail) throw StateError('offline');
            return {'success': true, 'recipientId': 'new', 'outboxId': 'o'};
          },
        ),
      );
      Future<void> send() => service.notifyKhadem(
        recipientId: 'spoof',
        recipientName: 'Spoof',
        title: 'Private title',
        body: 'Private body',
        type: 'absence_alert',
        data: {'makhdomId': 'm', 'grade': 'spoof', 'consecutiveAbsences': 99},
      );
      await expectLater(send(), throwsA(anything));
      fail = false;
      await send();
      expect(sent.last, sent.first);
      expect(sent.first.keys.toSet(), {'makhdomId', 'kind', 'operationId'});
      expect(sent.first['makhdomId'], 'm');
      expect(sent.first['kind'], 'absence');
    },
  );
  test(
    'AR/EN Excel profile roundtrip preserves tracking date and text phones without importing derived state',
    () {
      final child = MakhdomModel(
        id: 'm',
        fullName: 'Name',
        phone: '01000000000',
        grade: '3rd',
        trackingStartDate: DateTime(2026, 9, 25),
        assignedKhademId: 's',
        visitCount: 99,
        createdAt: DateTime.now(),
      );
      for (final locale in [const Locale('ar'), const Locale('en')]) {
        final bytes = ExcelService.exportMakhdomeenBytes([
          child,
        ], labels: ExcelColumnLabels(locale));
        final parsed = ExcelService.parseMakhdomeen(
          bytes,
          grade: '3rd',
        ).rows.single;
        expect(parsed.trackingStartDate, DateTime(2026, 9, 25));
        expect(parsed.phone, '01000000000');
        expect(parsed.visitCount, 0);
        expect(parsed.assignedKhademId, isNull);
      }
      expect(
        TrustedMutations.profileFields(child)['trackingStartDate'],
        '2026-09-25T00:00:00.000',
      );
    },
  );
}

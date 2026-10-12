import 'dart:async';
// Exercise the installed preference plugin's external persistence boundary.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/import_coordinator.dart';
import 'package:efteqad/core/models/makhdom_model.dart';

class PersistenceSdk extends InMemorySharedPreferencesStore {
  final int failAt;
  int writes = 0;
  PersistenceSdk(this.failAt) : super.empty();
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (++writes == failAt) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  for (final switchDuringPrefs in [true, false]) {
    test(
      'import retains A intent across switch during prefs=$switchDuringPrefs',
      () async {
        SharedPreferences.setMockInitialValues({});
        var uid = 'A';
        final prefs = Completer<SharedPreferences>();
        final first = Completer<Map<String, dynamic>>();
        final sent = <Map<String, dynamic>>[];
        final rows = List.generate(
          201,
          (i) => MakhdomModel(
            id: '',
            fullName: 'Child $i',
            phone: '01000000000',
            grade: '1st',
            createdAt: DateTime(2026),
          ),
        );
        final coordinator = ImportCoordinator(
          userId: () => uid,
          prefsFuture: prefs.future,
          mutations: TrustedMutations(
            transport: (n, p) async {
              sent.add(p);
              if (sent.length == 1 && !switchDuringPrefs) return first.future;
              return {
                'imported': (p['rows'] as List).length,
                'rejectedDetails': [],
              };
            },
          ),
        );
        final run = coordinator.importRows(rows);
        final failure = expectLater(run, throwsA(anything));
        if (!switchDuringPrefs) {
          prefs.complete(await SharedPreferences.getInstance());
          await Future<void>.delayed(Duration.zero);
        }
        uid = 'B';
        if (switchDuringPrefs) {
          prefs.complete(await SharedPreferences.getInstance());
        } else {
          first.complete({'imported': 200, 'rejectedDetails': []});
        }
        await failure;
        expect(sent.length, switchDuringPrefs ? 0 : 1);
        uid = 'A';
        final resumed = await coordinator.importRows(rows);
        expect(resumed.imported, 201);
        if (!switchDuringPrefs) {
          expect(sent[1]['importId'], sent.first['importId']);
        }
      },
    );
  }

  for (final boundary in [1, 2]) {
    test(
      'import persistence failure at write $boundary stops before further remote work',
      () async {
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = PersistenceSdk(boundary);
        var calls = 0;
        final rows = List.generate(
          201,
          (i) => MakhdomModel(
            id: '',
            fullName: 'Name $i',
            phone: '01000000000',
            grade: '1st',
            createdAt: DateTime(2026),
          ),
        );
        final coordinator = ImportCoordinator(
          userId: () => 'u',
          mutations: TrustedMutations(
            transport: (n, p) async {
              calls++;
              return {
                'imported': (p['rows'] as List).length,
                'rejectedDetails': [],
              };
            },
          ),
        );
        await expectLater(
          coordinator.importRows(rows),
          throwsA(isA<StateError>()),
        );
        expect(calls, boundary == 1 ? 0 : 1);
      },
    );
  }

  test(
    'import ledger survives restart, resumes identical chunks and reports rejected rows',
    () async {
      SharedPreferences.setMockInitialValues({});
      final calls = <Map<String, dynamic>>[];
      bool fail = true;
      final mutations = TrustedMutations(
        transport: (n, p) async {
          expect(n, 'importRows');
          calls.add(p);
          if ((p['rows'] as List).length == 1 && fail) {
            throw StateError('offline');
          }
          return {
            'imported': (p['rows'] as List).length - 1,
            'results': [
              {'rowIndex': 1, 'status': 'rejected', 'error': 'phone invalid'},
            ],
            'rejectedDetails': [
              {'rowIndex': 1, 'error': 'phone invalid'},
            ],
          };
        },
      );
      final rows = List.generate(
        201,
        (i) => MakhdomModel(
          id: '',
          fullName: 'Name $i',
          phone: '01000000000',
          grade: '1st',
          notes: 'text',
          createdAt: DateTime.now(),
        ),
      );
      await expectLater(
        ImportCoordinator(
          mutations: mutations,
          userId: () => 'u',
        ).importRows(rows),
        throwsA(anything),
      );
      final firstIds = calls.map((p) => p['importId']).toList();
      fail = false;
      final result = await ImportCoordinator(
        mutations: mutations,
        userId: () => 'u',
      ).importRows(rows);
      expect(calls.length, 3);
      expect(calls.last['importId'], firstIds.last);
      expect(result.imported, 199);
      expect(result.rejected.map((r) => r['rowIndex']), [1, 201]);
      final payload = (calls.first['rows'] as List).first as Map;
      expect(payload.containsKey('createdAt'), false);
      expect(payload.containsKey('visitCount'), false);
      expect(payload.containsKey('assignedKhademId'), false);
      expect(payload['phone'], '01000000000');
    },
  );
}

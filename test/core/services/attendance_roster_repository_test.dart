import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/services/attendance_roster_repository.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';

void main() {
  test(
    'minimal roster pages task scope and discards sensitive payload extras',
    () async {
      final sent = <Map<String, dynamic>>[];
      final repo = AttendanceRosterRepository(
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'getAttendanceRoster');
            sent.add(p);
            return sent.length == 1
                ? {
                    'rows': [
                      {
                        'id': 'a',
                        'fullName': 'A',
                        'grade': '1st',
                        'active': true,
                        'phone': 'private',
                      },
                    ],
                    'nextCursor': 'a',
                  }
                : {
                    'rows': [
                      {
                        'id': 'b',
                        'fullName': 'B',
                        'grade': '2nd',
                        'active': true,
                      },
                    ],
                    'nextCursor': null,
                  };
          },
        ),
      );
      final roster = await repo.load('actual-task');
      expect(roster.map((r) => r.id), ['a', 'b']);
      expect(sent, [
        {'taskId': 'actual-task', 'limit': 200},
        {'taskId': 'actual-task', 'limit': 200, 'cursor': 'a'},
      ]);
    },
  );
}

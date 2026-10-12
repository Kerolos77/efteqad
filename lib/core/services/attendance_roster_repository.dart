import 'trusted_mutations.dart';

class AttendanceRosterRow {
  final String id, fullName, grade;
  final bool active;
  const AttendanceRosterRow({
    required this.id,
    required this.fullName,
    required this.grade,
    required this.active,
  });
  factory AttendanceRosterRow.fromMap(Map<String, dynamic> row) =>
      AttendanceRosterRow(
        id: row['id'] as String,
        fullName: row['fullName'] as String,
        grade: row['grade'] as String,
        active: row['active'] == true,
      );
}

class AttendanceRosterRepository {
  final TrustedMutations _mutations;
  AttendanceRosterRepository({TrustedMutations? mutations})
    : _mutations = mutations ?? TrustedMutations();
  Future<List<AttendanceRosterRow>> load(String taskId) async {
    final rows = <AttendanceRosterRow>[];
    String? cursor;
    final seen = <String>{};
    do {
      final page = await _mutations.call('getAttendanceRoster', {
        'taskId': taskId,
        'limit': 200,
        if (cursor != null) 'cursor': cursor,
      });
      rows.addAll(
        (page['rows'] as List).map(
          (row) => AttendanceRosterRow.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        ),
      );
      cursor = page['nextCursor'] as String?;
      if (cursor != null && !seen.add(cursor)) {
        throw StateError('Invalid roster pagination.');
      }
    } while (cursor != null);
    return rows;
  }
}

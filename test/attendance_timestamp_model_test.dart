import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';

void main() {
  test(
    'canonical backend Timestamp attendance becomes a stable calendar date for analytics',
    () {
      final model = AttendanceSessionModel.fromMap({
        'date': Timestamp.fromDate(DateTime.utc(2026, 10, 9)),
        'type': 'khedma',
        'grade': '1st',
        'status': 'finalized',
        'attendedMakhdomIds': ['m'],
      }, 's');
      expect(model.date, '2026-10-09');
      expect(model.isFinalized, true);
      expect(
        AttendanceSessionModel.fromMap({'date': '2026-10-09'}, 'legacy').date,
        '2026-10-09',
      );
    },
  );
}

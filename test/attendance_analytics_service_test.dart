import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/services/attendance_analytics_service.dart';

void main() {
  group('AttendanceAnalyticsService Unit Tests (Task 12)', () {
    final asOf = DateTime(2026, 10, 16);

    final student1stA = MakhdomModel(
      id: 'mak-1',
      fullName: 'مارك يوسف',
      phone: '01000000001',
      grade: AppConstants.grade1st,
      visitCount: 2,
      createdAt: DateTime(2026, 1, 1),
    );

    final student1stB = MakhdomModel(
      id: 'mak-2',
      fullName: 'بيشوي نبيل',
      phone: '01000000002',
      grade: AppConstants.grade1st,
      visitCount: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    final student2nd = MakhdomModel(
      id: 'mak-3',
      fullName: 'جورج فادي',
      phone: '01000000003',
      grade: AppConstants.grade2nd,
      visitCount: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    test('zero sessions handles gracefully and returns empty results', () {
      final atRisk = AttendanceAnalyticsService.getAtRiskStudents(
        makhdomeen: [student1stA],
        sessions: [],
        asOf: asOf,
      );
      expect(atRisk, isEmpty);

      final overall = AttendanceAnalyticsService.calculateOverallAttendanceRate(
        makhdomeen: [student1stA],
        sessions: [],
        asOf: asOf,
      );
      expect(overall, isNull);

      final impact = AttendanceAnalyticsService.calculateVisitationImpact(
        makhdomeen: [student1stA],
        sessions: [],
        asOf: asOf,
      );
      expect(impact.visitedAttendanceRate, isNull);
      expect(impact.unvisitedAttendanceRate, isNull);
      expect(impact.impactPercentage, isNull);
      expect(impact.correlationDifference, isNull);
    });

    test(
      'draft and future sessions are excluded and do not trigger false absences',
      () {
        final sessions = [
          // Past finalized session
          AttendanceSessionModel(
            id: 's1',
            date: '2026-10-02',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: ['mak-1'],
            updatedAt: DateTime(2026, 10, 2),
          ),
          // Past draft session (should be ignored)
          AttendanceSessionModel(
            id: 's2',
            date: '2026-10-09',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'draft',
            attendedMakhdomIds: [],
            updatedAt: DateTime(2026, 10, 9),
          ),
          // Future session (should be ignored)
          AttendanceSessionModel(
            id: 's3',
            date: '2026-10-23',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: [],
            updatedAt: DateTime(2026, 10, 23),
          ),
        ];

        final atRisk = AttendanceAnalyticsService.getAtRiskStudents(
          makhdomeen: [student1stA],
          sessions: sessions,
          asOf: asOf,
        );

        // Student attended the only valid past finalized session -> NOT at risk!
        expect(atRisk, isEmpty);
      },
    );

    test(
      'two consecutive Friday service absences flags student as at risk',
      () {
        final sessions = [
          AttendanceSessionModel(
            id: 's1',
            date: '2026-10-02',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: [], // missed
            updatedAt: DateTime(2026, 10, 2),
          ),
          AttendanceSessionModel(
            id: 's2',
            date: '2026-10-09',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: [], // missed
            updatedAt: DateTime(2026, 10, 9),
          ),
          AttendanceSessionModel(
            id: 's3',
            date: '2026-09-25',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: ['mak-1'], // attended 3 weeks ago
            updatedAt: DateTime(2026, 9, 25),
          ),
        ];

        final atRisk = AttendanceAnalyticsService.getAtRiskStudents(
          makhdomeen: [student1stA],
          sessions: sessions,
          asOf: asOf,
        );

        expect(atRisk.length, 1);
        expect(atRisk.first.makhdom.id, 'mak-1');
        expect(atRisk.first.consecutiveAbsences, 2);
        expect(atRisk.first.isCritical, isFalse);
        expect(
          atRisk.first.missedDates,
          containsAll(['2026-10-09', '2026-10-02']),
        );
      },
    );

    test(
      'mass and service on the same day counts as ONE attendance opportunity and resets absence streak if attended',
      () {
        final sessions = [
          // Friday 2026-10-02: student missed
          AttendanceSessionModel(
            id: 's1_khedma',
            date: '2026-10-02',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: [],
            updatedAt: DateTime(2026, 10, 2),
          ),
          // Friday 2026-10-09: two sessions on same day (qoddas and khedma)
          // Student missed Mass, but ATTENDED Service
          AttendanceSessionModel(
            id: 's2_qoddas',
            date: '2026-10-09',
            type: 'qoddas',
            grade: 'all',
            status: 'finalized',
            attendedMakhdomIds: [],
            updatedAt: DateTime(2026, 10, 9),
          ),
          AttendanceSessionModel(
            id: 's2_khedma',
            date: '2026-10-09',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: ['mak-1'], // ATTENDED
            updatedAt: DateTime(2026, 10, 9),
          ),
        ];

        final atRisk = AttendanceAnalyticsService.getAtRiskStudents(
          makhdomeen: [student1stA],
          sessions: sessions,
          asOf: asOf,
        );

        // Friday 10-09 was attended, so streak on 10-09 is 0 -> not 2 consecutive absences!
        expect(atRisk, isEmpty);
      },
    );

    test('different grades isolate sessions correctly', () {
      final sessions = [
        // Grade 1st session missed by student1stA
        AttendanceSessionModel(
          id: 's1_1st',
          date: '2026-10-02',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 10, 2),
        ),
        AttendanceSessionModel(
          id: 's2_1st',
          date: '2026-10-09',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 10, 9),
        ),
        // Grade 2nd session (student2nd attended)
        AttendanceSessionModel(
          id: 's1_2nd',
          date: '2026-10-02',
          type: 'khedma',
          grade: AppConstants.grade2nd,
          status: 'finalized',
          attendedMakhdomIds: ['mak-3'],
          updatedAt: DateTime(2026, 10, 2),
        ),
        AttendanceSessionModel(
          id: 's2_2nd',
          date: '2026-10-09',
          type: 'khedma',
          grade: AppConstants.grade2nd,
          status: 'finalized',
          attendedMakhdomIds: ['mak-3'],
          updatedAt: DateTime(2026, 10, 9),
        ),
      ];

      final atRisk = AttendanceAnalyticsService.getAtRiskStudents(
        makhdomeen: [student1stA, student2nd],
        sessions: sessions,
        asOf: asOf,
      );

      expect(atRisk.length, 1);
      expect(atRisk.first.makhdom.id, 'mak-1');
      expect(atRisk.any((r) => r.makhdom.id == 'mak-3'), isFalse);
    });

    test(
      'behavioral segmentation categorizes consistent, irregular, and atRisk students',
      () {
        final sessions = [
          AttendanceSessionModel(
            id: 's1',
            date: '2026-10-02',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: ['mak-1'], // mak-1 attended
            updatedAt: DateTime(2026, 10, 2),
          ),
          AttendanceSessionModel(
            id: 's2',
            date: '2026-10-09',
            type: 'khedma',
            grade: AppConstants.grade1st,
            status: 'finalized',
            attendedMakhdomIds: ['mak-1'], // mak-1 attended, mak-2 missed
            updatedAt: DateTime(2026, 10, 9),
          ),
        ];

        final segmentation = AttendanceAnalyticsService.segmentStudents(
          makhdomeen: [student1stA, student1stB],
          sessions: sessions,
          asOf: asOf,
        );

        // mak-1 attended 2/2 = 100% -> consistent
        expect(segmentation.consistent.map((m) => m.id), contains('mak-1'));
        // mak-2 attended 0/2 = 0% and missed 2 consecutive -> atRisk
        expect(segmentation.atRisk.map((m) => m.id), contains('mak-2'));
      },
    );
  });
}

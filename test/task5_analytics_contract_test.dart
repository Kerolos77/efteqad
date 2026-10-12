import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/services/attendance_analytics_service.dart';
import 'package:efteqad/features/admin/application/makhdom_history_service.dart';

void main() {
  final asOf = DateTime(2026, 10, 16);
  final child = MakhdomModel(
    id: 'm',
    fullName: 'Child',
    phone: '',
    createdAt: DateTime(2026, 1, 1),
  );
  AttendanceSessionModel session(
    String date, {
    String type = 'khedma',
    String grade = '1st',
    String status = 'finalized',
    List<String> ids = const [],
  }) => AttendanceSessionModel(
    id: '$date-$type-$grade',
    date: date,
    type: type,
    grade: grade,
    status: status,
    attendedMakhdomIds: ids,
    updatedAt: asOf,
  );
  test('mass presence does not break finalized service absence streak', () {
    final sessions = [
      for (final d in ['2026-10-02', '2026-10-09']) ...[
        session(d),
        session(d, type: 'qoddas', ids: ['m']),
      ],
    ];
    expect(
      AttendanceAnalyticsService.getAtRiskStudents(
        makhdomeen: [child],
        sessions: sessions,
        asOf: asOf,
      ).single.consecutiveAbsences,
      2,
    );
    expect(
      const MakhdomHistoryService()
          .analyzeHistory(
            makhdom: child,
            visits: [],
            sessions: sessions,
            asOf: asOf,
          )
          .consecutiveAbsences,
      2,
    );
  });
  test(
    'mass only creates neither service risk nor sufficient service data',
    () {
      final sessions = [
        session('2026-10-02', type: 'qoddas'),
        session('2026-10-09', type: 'qoddas'),
      ];
      expect(
        AttendanceAnalyticsService.getAtRiskStudents(
          makhdomeen: [child],
          sessions: sessions,
          asOf: asOf,
        ),
        isEmpty,
      );
      expect(
        const MakhdomHistoryService()
            .analyzeHistory(
              makhdom: child,
              visits: [],
              sessions: sessions,
              asOf: asOf,
            )
            .hasSufficientData,
        isFalse,
      );
    },
  );
  test(
    'tracking is inclusive by local date and excludes prior completed service',
    () {
      final tracked = child.copyWith(
        trackingStartDate: DateTime(2026, 10, 9, 19),
      );
      final result = const MakhdomHistoryService().analyzeHistory(
        makhdom: tracked,
        visits: [],
        sessions: [
          session('2026-10-02'),
          session('2026-10-09', ids: ['m']),
        ],
        asOf: asOf,
      );
      expect(result.totalEligibleSessions, 1);
      expect(result.serviceAttendanceRate, 100);
    },
  );
  test('unknown draft future and malformed dates supply no opportunities', () {
    final sessions = [
      session('2026-10-02', status: 'legacyUnknown'),
      session('2026-10-09', status: 'draft'),
      session('2026-10-23'),
      session('2026-02-30'),
    ];
    expect(
      const MakhdomHistoryService()
          .analyzeHistory(
            makhdom: child,
            visits: [],
            sessions: sessions,
            asOf: asOf,
          )
          .totalEligibleSessions,
      0,
    );
    expect(
      AttendanceAnalyticsService.calculateOverallAttendanceRate(
        makhdomeen: [child],
        sessions: sessions,
        asOf: asOf,
      ),
      isNull,
    );
  });
  test('zero service sessions is unknown rather than zero rate or at risk', () {
    expect(
      AttendanceAnalyticsService.calculateOverallAttendanceRate(
        makhdomeen: [child],
        sessions: [],
        asOf: asOf,
      ),
      isNull,
    );
    expect(
      AttendanceAnalyticsService.segmentStudents(
        makhdomeen: [child],
        sessions: [],
        asOf: asOf,
      ).atRisk,
      isEmpty,
    );
  });
  test(
    'numerator uses the same active tracked grade population as denominator',
    () {
      final other = child.copyWith(id: 'other', grade: '2nd');
      final archived = child.copyWith(id: 'archived', active: false);
      final untracked = child.copyWith(
        id: 'new',
        trackingStartDate: DateTime(2026, 10, 15),
      );
      expect(
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: [child, other, archived, untracked],
          sessions: [
            session('2026-10-09', ids: ['m', 'other', 'archived', 'new']),
          ],
          asOf: asOf,
        ),
        100,
      );
    },
  );
  test(
    'maxWeeks counts distinct service dates and merges root grade duplicate',
    () {
      final sessions = [
        session('2026-10-02', ids: ['m']),
        session('2026-10-09'),
        session('2026-10-09', grade: 'all', ids: ['m']),
        session('2026-10-09', type: 'qoddas'),
      ];
      final points = AttendanceAnalyticsService.getWeeklyTrend(
        makhdomeen: [child],
        sessions: sessions,
        maxWeeks: 2,
        asOf: asOf,
      );
      expect(points.map((p) => p.date), ['2026-10-02', '2026-10-09']);
      expect(points.last.attendedCount, 1);
      expect(points.last.totalEligible, 1);
    },
  );
  test('missing legacy createdAt remains unknown after map round trip', () {
    final unknown = MakhdomModel.fromMap({
      'fullName': 'Legacy',
      'grade': '1st',
    }, 'm');
    final restored = MakhdomModel.fromMap(unknown.toMap(), 'm');
    expect(
      AttendanceAnalyticsService.calculateOverallAttendanceRate(
        makhdomeen: [restored],
        sessions: [session('2026-10-09')],
        asOf: DateTime(2090),
      ),
      isNull,
    );
  });
}

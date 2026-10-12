import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/features/admin/application/makhdom_history_service.dart';
import 'package:efteqad/features/admin/models/history_analysis.dart';

void main() {
  group('MakhdomHistoryService Unit Tests (Task 12)', () {
    const service = MakhdomHistoryService();
    final asOf = DateTime(2026, 10, 16);

    final makhdom = MakhdomModel(
      id: 'mak-100',
      fullName: 'يوحنا سامي',
      phone: '01000000010',
      grade: AppConstants.grade1st,
      visitCount: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    test(
      'zero eligible service is insufficient while one finalized service has a known rate',
      () {
        final analysisEmpty = service.analyzeHistory(
          makhdom: makhdom,
          visits: [],
          sessions: [],
          asOf: asOf,
        );

        expect(analysisEmpty.hasSufficientData, isFalse);
        expect(analysisEmpty.totalEligibleSessions, 0);
        expect(analysisEmpty.overallAttendanceRate, isNull);
        expect(analysisEmpty.consecutiveAbsences, 0);

        final singleSession = AttendanceSessionModel(
          id: 's1',
          date: '2026-10-09',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: ['mak-100'],
          updatedAt: DateTime(2026, 10, 9),
        );

        final analysisSingle = service.analyzeHistory(
          makhdom: makhdom,
          visits: [],
          sessions: [singleSession],
          asOf: asOf,
        );

        expect(analysisSingle.hasSufficientData, isTrue);
        expect(analysisSingle.totalEligibleSessions, 1);
        expect(analysisSingle.totalAttendedSessions, 1);
        expect(analysisSingle.overallAttendanceRate, 100.0);
      },
    );

    test('ignores draft and future sessions', () {
      final pastFinalized = AttendanceSessionModel(
        id: 's_past',
        date: '2026-10-02',
        type: 'khedma',
        grade: AppConstants.grade1st,
        status: 'finalized',
        attendedMakhdomIds: ['mak-100'],
        updatedAt: DateTime(2026, 10, 2),
      );
      final pastDraft = AttendanceSessionModel(
        id: 's_draft',
        date: '2026-10-09',
        type: 'khedma',
        grade: AppConstants.grade1st,
        status: 'draft',
        attendedMakhdomIds: [],
        updatedAt: DateTime(2026, 10, 9),
      );
      final futureSession = AttendanceSessionModel(
        id: 's_future',
        date: '2026-10-23',
        type: 'khedma',
        grade: AppConstants.grade1st,
        status: 'finalized',
        attendedMakhdomIds: [],
        updatedAt: DateTime(2026, 10, 23),
      );

      final analysis = service.analyzeHistory(
        makhdom: makhdom,
        visits: [],
        sessions: [pastFinalized, pastDraft, futureSession],
        asOf: asOf,
      );

      // Only the past finalized session counts
      expect(analysis.totalEligibleSessions, 1);
      expect(analysis.totalAttendedSessions, 1);
      expect(analysis.consecutiveAbsences, 0);
    });

    test('two consecutive Friday absences triggers at risk flags', () {
      final sessions = [
        AttendanceSessionModel(
          id: 's1',
          date: '2026-10-02',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 10, 2),
        ),
        AttendanceSessionModel(
          id: 's2',
          date: '2026-10-09',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 10, 9),
        ),
      ];

      final analysis = service.analyzeHistory(
        makhdom: makhdom,
        visits: [],
        sessions: sessions,
        asOf: asOf,
      );

      expect(analysis.hasSufficientData, isTrue);
      expect(analysis.consecutiveAbsences, 2);
      expect(analysis.isAtRisk, isTrue);
      expect(analysis.isCriticalRisk, isFalse);
    });

    test('three consecutive Friday absences triggers critical risk flag', () {
      final sessions = [
        AttendanceSessionModel(
          id: 's1',
          date: '2026-09-25',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 9, 25),
        ),
        AttendanceSessionModel(
          id: 's2',
          date: '2026-10-02',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 10, 2),
        ),
        AttendanceSessionModel(
          id: 's3',
          date: '2026-10-09',
          type: 'khedma',
          grade: AppConstants.grade1st,
          status: 'finalized',
          attendedMakhdomIds: [],
          updatedAt: DateTime(2026, 10, 9),
        ),
      ];

      final analysis = service.analyzeHistory(
        makhdom: makhdom,
        visits: [],
        sessions: sessions,
        asOf: asOf,
      );

      expect(analysis.consecutiveAbsences, 3);
      expect(analysis.isAtRisk, isTrue);
      expect(analysis.isCriticalRisk, isTrue);
    });

    test('analyzes visit impact on following Friday accurately', () {
      // Visit was on Wednesday 2026-10-07
      final visit = VisitModel(
        id: 'v1',
        makhdomId: 'mak-100',
        makhdomName: 'يوحنا سامي',
        khademId: 'kh-1',
        khademName: 'الخادم مينا',
        visitDate: DateTime(2026, 10, 7),
        visitType: 'زيارة منزلية',
        notes: 'تمت الزيارة وسيحضر الجمعة القادمة',
        createdAt: DateTime(2026, 10, 7),
      );

      // Following Friday is 2026-10-09
      final massSession = AttendanceSessionModel(
        id: 's_mass',
        date: '2026-10-09',
        type: 'qoddas',
        grade: 'all',
        status: 'finalized',
        attendedMakhdomIds: ['mak-100'],
        updatedAt: DateTime(2026, 10, 9),
      );
      final serviceSession = AttendanceSessionModel(
        id: 's_khedma',
        date: '2026-10-09',
        type: 'khedma',
        grade: AppConstants.grade1st,
        status: 'finalized',
        attendedMakhdomIds: ['mak-100'],
        updatedAt: DateTime(2026, 10, 9),
      );

      final analysis = service.analyzeHistory(
        makhdom: makhdom,
        visits: [visit],
        sessions: [massSession, serviceSession],
        asOf: asOf,
      );

      expect(analysis.visitsWithImpact.length, 1);
      final vi = analysis.visitsWithImpact.first;
      expect(vi.nextFridayFormatted, '2026-10-09');
      expect(vi.outcome, VisitFridayOutcome.both);
      expect(vi.attendedMass, isTrue);
      expect(vi.attendedService, isTrue);
      expect(analysis.totalVisitsCount, 1);
      expect(
        analysis.daysSinceLastVisit,
        asOf.difference(DateTime(2026, 10, 7)).inDays,
      );
    });

    test(
      'recent visit with following Friday in the future has pending outcome',
      () {
        // Visit on Thursday 2026-10-15
        final visit = VisitModel(
          id: 'v2',
          makhdomId: 'mak-100',
          makhdomName: 'يوحنا سامي',
          khademId: 'kh-1',
          khademName: 'الخادم مينا',
          visitDate: DateTime(2026, 10, 15),
          visitType: 'مكالمة تليفونية',
          createdAt: DateTime(2026, 10, 15),
        );

        // As of Thursday 2026-10-15 12:00
        final analysis = service.analyzeHistory(
          makhdom: makhdom,
          visits: [visit],
          sessions: [],
          asOf: DateTime(2026, 10, 15, 12, 0),
        );

        expect(analysis.visitsWithImpact.length, 1);
        final vi = analysis.visitsWithImpact.first;
        expect(vi.nextFridayFormatted, '2026-10-16');
        expect(vi.outcome, VisitFridayOutcome.pending);
      },
    );
  });
}

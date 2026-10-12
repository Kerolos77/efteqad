import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/models/page_result.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/attendance_analytics_service.dart';
import 'package:efteqad/features/admin/application/makhdom_history_service.dart';
import 'package:efteqad/features/admin/presentation/screens/makhdom_history_screen.dart';
import 'task5_widgets_test.dart' show app;

class WindowBoundary extends FirestoreService {
  final scopes = <String>[];
  DateTime? from, to;
  @override
  Stream<List<VisitModel>> getVisitsForMakhdomStream(
    String id, {
    DateTime? from,
    DateTime? to,
  }) {
    this.from = from;
    this.to = to;
    return Stream.value([]);
  }

  @override
  Stream<List<AttendanceSessionModel>> getAttendanceSessionsForGradeStream(
    String grade, {
    DateTime? from,
    DateTime? to,
  }) {
    scopes.add(grade);
    return Stream.value([
      AttendanceSessionModel(
        id: 's',
        date: '2026-10-09',
        grade: grade,
        type: 'khedma',
        status: 'finalized',
        attendedMakhdomIds: grade == '1st' ? ['m'] : [],
        updatedAt: DateTime(2026, 10, 9),
      ),
    ]);
  }

  @override
  Future<PageResult<VisitModel>> fetchVisitPage({
    required String makhdomId,
    DocumentSnapshot? cursor,
    int limit = 50,
    DateTime? from,
    DateTime? to,
  }) async => PageResult.empty();
}

void main() {
  final child = MakhdomModel(
    id: 'm',
    fullName: 'Child',
    phone: '',
    createdAt: DateTime(2026, 1, 1),
  );
  testWidgets(
    'history default90day queries and live grade update immediately recalculate KPIs',
    (t) async {
      final boundary = WindowBoundary();
      final date = DateTime(2026, 10, 16);
      await t.pumpWidget(
        app(
          MakhdomHistoryScreen(
            makhdom: child,
            asOf: date,
            firestoreService: boundary,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(boundary.from, DateTime(2026, 7, 19));
      expect(boundary.to, date);
      expect(find.text('100%'), findsWidgets);
      await t.pumpWidget(
        app(
          MakhdomHistoryScreen(
            makhdom: child.copyWith(grade: '2nd', fullName: 'Updated'),
            asOf: date,
            firestoreService: boundary,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(boundary.scopes, ['1st', '2nd']);
      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
      expect(find.text('0%'), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );
  test(
    'visit comparison uses selected window rather than lifetime visitCount',
    () {
      final other = child.copyWith(id: 'b', visitCount: 0),
          lifetime = child.copyWith(visitCount: 99);
      VisitModel visit(String id, String childId, DateTime date) => VisitModel(
        id: id,
        makhdomId: childId,
        makhdomName: '',
        khademId: 's',
        khademName: '',
        visitDate: date,
        visitType: 'home',
        createdAt: date,
      );
      final session = AttendanceSessionModel(
        id: 's',
        date: '2026-10-09',
        grade: '1st',
        type: 'khedma',
        status: 'finalized',
        attendedMakhdomIds: ['m'],
        updatedAt: DateTime(2026, 10, 9),
      );
      final comparison = AttendanceAnalyticsService.calculateVisitationImpact(
        makhdomeen: [lifetime, other],
        sessions: [session],
        visits: [
          visit('old', 'm', DateTime(2026, 6, 1)),
          visit('new', 'b', DateTime(2026, 10, 8)),
        ],
        from: DateTime(2026, 7, 19),
        asOf: DateTime(2026, 10, 16),
      );
      expect(comparison.visitedStudentsCount, 1);
      expect(comparison.visitedAttendanceRate, 0);
      expect(comparison.unvisitedAttendanceRate, 100);
      expect(comparison.impactPercentage, -100);
    },
  );
  test(
    'history ties use createdAt then ID and repeated visits do not duplicate post-Friday',
    () {
      VisitModel visit(String id, int creationDay) => VisitModel(
        id: id,
        makhdomId: 'm',
        makhdomName: '',
        khademId: 's',
        khademName: '',
        visitDate: DateTime(2026, 10, 8),
        visitType: 'home',
        createdAt: DateTime(2026, 10, creationDay),
      );
      final sessions = [
        for (final day in ['2026-10-02', '2026-10-09'])
          AttendanceSessionModel(
            id: day,
            date: day,
            grade: '1st',
            type: 'khedma',
            status: 'finalized',
            attendedMakhdomIds: day == '2026-10-09' ? ['m'] : [],
            updatedAt: DateTime(2026, 10, 9),
          ),
      ];
      final history = const MakhdomHistoryService().analyzeHistory(
        makhdom: child,
        visits: [visit('a', 9), visit('b', 9), visit('z', 8)],
        sessions: sessions,
        from: DateTime(2026, 10, 1),
        asOf: DateTime(2026, 10, 16),
      );
      expect(history.lastVisit!.id, 'b');
      expect(history.postVisitAttendanceRate, 100);
      expect(history.nonPostVisitAttendanceRate, 0);
      expect(history.correlationDifference, 100);
      expect(history.totalEligibleSessions, 2);
    },
  );
}

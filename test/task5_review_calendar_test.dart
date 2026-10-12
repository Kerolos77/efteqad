import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/repositories/visit_repository.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/attendance_analytics_service.dart';
import 'package:efteqad/features/admin/application/makhdom_history_service.dart';
import 'package:efteqad/features/admin/presentation/screens/makhdom_history_screen.dart';
import 'task5_widgets_test.dart' show app;
import 'task5_window_test.dart' show WindowBoundary;
import 'task5_query_contract_test.dart' show QueryProbe, QueryEvent, Meta;

// SDK query boundary probe captures actual emitted timestamp values.
// Test-only SDK boundary fake inherits the existing sealed Query probe.
// ignore: must_be_immutable, subtype_of_sealed_class
class CalendarQueryProbe extends QueryProbe {
  final cutoffs = <DateTime>[];
  CalendarQueryProbe()
    : super(Stream.value(QueryEvent(const Meta(false, false)))) {
    read = (_) async => QueryEvent(const Meta(false, false));
  }
  @override
  dynamic noSuchMethod(Invocation i) {
    final bound = i.namedArguments[#isLessThan];
    if (bound is Timestamp) cutoffs.add(bound.toDate());
    return super.noSuchMethod(i);
  }
}

bool cairoOffsetsMatch(Duration spring, Duration fallStart, Duration fallEnd) =>
    spring == const Duration(hours: 3) &&
    fallStart == const Duration(hours: 3) &&
    fallEnd == const Duration(hours: 2);

void main() {
  final cairoHost = cairoOffsetsMatch(
    DateTime(2026, 5, 1).timeZoneOffset,
    DateTime(2026, 10, 29).timeZoneOffset,
    DateTime(2026, 10, 30).timeZoneOffset,
  );
  final cairoSkip = cairoHost
      ? false
      : 'Requires Cairo-compatible 2026 spring/fall offsets (+3, +3, +2).';
  final child = MakhdomModel(
    id: 'm',
    fullName: 'Child',
    phone: '',
    createdAt: DateTime(2026, 1, 1),
  );
  final lateVisit = VisitModel(
    id: 'v',
    makhdomId: 'm',
    makhdomName: '',
    khademId: 's',
    khademName: '',
    visitDate: DateTime(2026, 10, 29, 23, 30),
    visitType: 'home',
    createdAt: DateTime(2026, 10, 29, 23, 30),
  );
  final session = AttendanceSessionModel(
    id: 's',
    date: '2026-10-23',
    type: 'khedma',
    grade: '1st',
    status: 'finalized',
    attendedMakhdomIds: ['b'],
    updatedAt: DateTime(2026, 10, 23),
  );
  test(
    'Cairo host gate accepts Cairo offsets and rejects UTC without failing setup',
    () {
      expect(
        cairoOffsetsMatch(
          const Duration(hours: 3),
          const Duration(hours: 3),
          const Duration(hours: 2),
        ),
        isTrue,
      );
      expect(
        cairoOffsetsMatch(Duration.zero, Duration.zero, Duration.zero),
        isFalse,
      );
    },
  );
  testWidgets('history last90 local dates start February1', (t) async {
    final boundary = WindowBoundary();
    await t.pumpWidget(
      app(
        MakhdomHistoryScreen(
          makhdom: child,
          asOf: DateTime(2026, 5, 1),
          firestoreService: boundary,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(boundary.from, DateTime(2026, 2, 1));
  });
  test('actual live visit query ends at next local midnight', () async {
    final probe = CalendarQueryProbe();
    await FirestoreService(
      firestore: probe,
    ).watchVisitsWindow(makhdomId: 'm', to: DateTime(2026, 10, 29)).first;
    expect(probe.cutoffs.single, DateTime(2026, 10, 30));
  });
  test(
    'actual visit page query uses same next local midnight as live analysis',
    () async {
      final probe = CalendarQueryProbe();
      await FirestoreVisitRepository(
        firestore: probe,
      ).fetchVisitPage(makhdomId: 'm', to: DateTime(2026, 10, 29));
      expect(probe.cutoffs.single, DateTime(2026, 10, 30));
    },
  );
  test('history includes local visit at23:30 on last selected date', () {
    final history = const MakhdomHistoryService().analyzeHistory(
      makhdom: child,
      visits: [lateVisit],
      sessions: [session],
      asOf: DateTime(2026, 10, 29),
    );
    expect(history.totalVisitsCount, 1);
    expect(history.lastVisit!.id, 'v');
  });
  test(
    'same-window visit classification includes local visit in last selected hour',
    () {
      final impact = AttendanceAnalyticsService.calculateVisitationImpact(
        makhdomeen: [
          child,
          child.copyWith(id: 'b'),
        ],
        visits: [lateVisit],
        sessions: [session],
        asOf: DateTime(2026, 10, 29),
      );
      expect(impact.visitedStudentsCount, 1);
      expect(impact.impactPercentage, -100);
    },
  );
  test(
    'Cairo DST live query spans25 hours and includes UTC late-hour visit',
    () async {
      final probe = CalendarQueryProbe();
      await FirestoreService(
        firestore: probe,
      ).watchVisitsWindow(makhdomId: 'm', to: DateTime(2026, 10, 29)).first;
      expect(
        probe.cutoffs.single.difference(DateTime(2026, 10, 29)),
        const Duration(hours: 25),
      );
      final cairoVisit = lateVisit.copyWith(
        visitDate: DateTime.utc(2026, 10, 29, 21, 30).toLocal(),
      );
      expect(cairoVisit.visitDate.hour, 23);
      expect(cairoVisit.visitDate.timeZoneOffset, const Duration(hours: 2));
      final history = const MakhdomHistoryService().analyzeHistory(
        makhdom: child,
        visits: [cairoVisit],
        sessions: [session],
        asOf: DateTime(2026, 10, 29),
      );
      expect(history.totalVisitsCount, 1);
      final impact = AttendanceAnalyticsService.calculateVisitationImpact(
        makhdomeen: [
          child,
          child.copyWith(id: 'b'),
        ],
        visits: [cairoVisit],
        sessions: [session],
        asOf: DateTime(2026, 10, 29),
      );
      expect(impact.visitedStudentsCount, 1);
      expect(impact.impactPercentage, -100);
    },
    skip: cairoSkip,
  );
}

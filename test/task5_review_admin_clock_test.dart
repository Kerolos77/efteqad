import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/features/admin/presentation/screens/analytics_tab.dart';
import 'task5_widgets_test.dart' show app;

class AdminClockBoundary extends FirestoreService {
  final sessions = <AttendanceSessionModel>[
    for (final date in ['2030-10-04', '2030-10-11']) ...[
      AttendanceSessionModel(
        id: '$date-service',
        date: date,
        type: 'khedma',
        grade: '1st',
        status: 'finalized',
        attendedMakhdomIds: ['a'],
        updatedAt: DateTime(2030, 10, 11),
      ),
      AttendanceSessionModel(
        id: '$date-mass',
        date: date,
        type: 'qoddas',
        grade: '1st',
        status: 'finalized',
        attendedMakhdomIds: ['a', 'b'],
        updatedAt: DateTime(2030, 10, 11),
      ),
    ],
  ];
  DateTime? from, to;
  @override
  Stream<List<AttendanceSessionModel>> getAttendanceSessionsForGradeStream(
    String grade, {
    DateTime? from,
    DateTime? to,
  }) {
    this.from = from;
    this.to = to;
    return Stream.value(sessions);
  }

  @override
  Stream<List<VisitModel>> getAllVisitsStream({
    DateTime? from,
    DateTime? to,
    String? grade,
    String? khademId,
  }) => Stream.value([
    VisitModel(
      id: 'v',
      makhdomId: 'a',
      makhdomName: 'Present',
      khademId: 's',
      khademName: '',
      visitDate: DateTime(2030, 10, 10),
      visitType: 'home',
      createdAt: DateTime(2030, 10, 10),
    ),
  ]);
}

void main() {
  final children = [
    MakhdomModel(
      id: 'a',
      fullName: 'Present',
      phone: '',
      createdAt: DateTime(2026, 1, 1),
    ),
    MakhdomModel(
      id: 'b',
      fullName: 'Missing',
      phone: '',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
  Future<AppLocalizations> open(
    WidgetTester t,
    AdminClockBoundary boundary,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      app(
        AnalyticsTab(
          makhdomeen: children,
          khodam: const [],
          grade: '1st',
          asOf: DateTime(2030, 10, 18),
          firestoreService: boundary,
        ),
      ),
    );
    await t.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('en', 'US'));
  }

  testWidgets(
    'all admin attendance rates and trend use injected asOf rather than wall clock',
    (t) async {
      final boundary = AdminClockBoundary(), tr = await open(t, boundary);
      await t.tap(find.text(tr.tabAttendanceAnalytics));
      await t.pumpAndSettle();
      expect(boundary.to, DateTime(2030, 10, 18));
      expect(boundary.from, DateTime(2030, 7, 21));
      expect(find.text('50.0%'), findsNWidgets(2));
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.textContaining('2030-10-04'), findsOneWidget);
      expect(find.textContaining('2030-10-11'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'admin absence alerts use same injected date window as comparison',
    (t) async {
      final tr = await open(t, AdminClockBoundary());
      await t.tap(find.text(tr.tabSmartInsights));
      await t.pumpAndSettle();
      expect(find.text(tr.missedFridaysCount(2)), findsOneWidget);
      expect(find.textContaining('100.0 percentage points'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'admin behavioral segments use same injected date window as comparison',
    (t) async {
      final tr = await open(t, AdminClockBoundary());
      await t.tap(find.text(tr.tabSmartInsights));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text(tr.segmentConsistent));
      await t.tap(find.text(tr.segmentConsistent));
      await t.pumpAndSettle();
      expect(find.text('Present'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}

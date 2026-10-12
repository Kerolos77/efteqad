import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/features/admin/presentation/screens/makhdom_history_screen.dart';
import 'package:efteqad/features/khadem/presentation/widgets/my_analytics_tab.dart';

Widget app(Widget child) => MaterialApp(
  locale: const Locale('en', 'US'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

class HistoryFailure extends FirestoreService {
  @override
  Stream<List<VisitModel>> getVisitsForMakhdomStream(
    String id, {
    DateTime? from,
    DateTime? to,
  }) => Stream.error(
    const AppFailure(
      code: 'permission-denied',
      message: 'private detail',
      retryable: false,
    ),
  );
  @override
  Stream<List<AttendanceSessionModel>> getAllAttendanceSessionsStream({
    DateTime? from,
    DateTime? to,
  }) => Stream.value([]);
  @override
  Stream<List<AttendanceSessionModel>> getAttendanceSessionsForGradeStream(
    String grade, {
    DateTime? from,
    DateTime? to,
  }) => Stream.value([]);
}

void main() {
  final child = MakhdomModel(
    id: 'm',
    fullName: 'Child',
    phone: '',
    createdAt: DateTime(2026, 1, 1),
  );
  for (final difference in [-100, 0, 100]) {
    testWidgets(
      'servant renders signed $difference percentage point difference',
      (t) async {
        final other = child.copyWith(id: 'b');
        final ids = difference == 0
            ? ['m', 'b']
            : difference > 0
            ? ['m']
            : ['b'];
        final session = AttendanceSessionModel(
          id: 's',
          date: '2026-10-09',
          grade: '1st',
          type: 'khedma',
          status: 'finalized',
          attendedMakhdomIds: ids,
          updatedAt: DateTime(2026, 10, 9),
        );
        final visit = VisitModel(
          id: 'v',
          makhdomId: 'm',
          makhdomName: '',
          khademId: 's',
          khademName: '',
          visitDate: DateTime(2026, 10, 8),
          visitType: 'home',
          createdAt: DateTime(2026, 10, 8),
        );
        await t.pumpWidget(
          app(
            MyAnalyticsTab(
              myMakhdomeen: [child, other],
              sessions: [session],
              visits: [visit],
              from: DateTime(2026, 7, 19),
              asOf: DateTime(2026, 10, 16),
            ),
          ),
        );
        expect(
          find.textContaining('$difference.0 percentage points'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'history query permission failure is localized error rather than empty KPIs',
    (t) async {
      await t.pumpWidget(
        app(
          MakhdomHistoryScreen(
            makhdom: child,
            firestoreService: HistoryFailure(),
          ),
        ),
      );
      await t.pump();
      await t.pump();
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('private detail'), findsNothing);
    },
  );
  testWidgets(
    'servant analytics shows insufficient without crash or zero attendance',
    (t) async {
      await t.pumpWidget(
        app(MyAnalyticsTab(myMakhdomeen: [child], sessions: const [])),
      );
      expect(t.takeException(), isNull);
      expect(find.textContaining('Not enough'), findsWidgets);
    },
  );
}

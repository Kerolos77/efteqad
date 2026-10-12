import 'package:efteqad/core/models/visit_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/task_model.dart';
import 'package:efteqad/core/models/attendance_session_model.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/features/admin/presentation/screens/admin_main_screen.dart';
import 'package:efteqad/features/admin/presentation/screens/makhdom_history_screen.dart';
import 'package:efteqad/features/khadem/presentation/widgets/my_makhdomeen_tab.dart';
import 'package:efteqad/features/khadem/presentation/widgets/my_analytics_tab.dart';
import 'package:efteqad/features/tasks/presentation/widgets/tasks_tab.dart';
import '../core/router/app_router_test.dart' show MockSessionCubit;
import 'localization_widget_matrix_test.dart' show HistoryBoundary;

const phone = '+44 20 7946 0958';
final child = MakhdomModel(
  id: 'm',
  fullName: 'اسم مخصص',
  phone: phone,
  createdAt: DateTime(2026),
);
final servant = KhademModel(
  id: 's',
  name: 'اسم الخادم',
  email: 's@example.org',
  phone: phone,
  role: 'servant',
  grade: '1st',
  status: 'active',
  createdAt: DateTime(2026),
);
final task = TaskModel(
  id: 't',
  title: 'عنوان المستخدم',
  assignedKhademId: 's',
  assignedKhademName: 'اسم الخادم',
  grade: '1st',
  createdById: 'a',
  createdByName: 'الأمين',
  createdAt: DateTime(2026),
);

class AdminBoundary extends FirestoreService {
  @override
  Stream<List<VisitModel>> getAllVisitsStream({
    DateTime? from,
    DateTime? to,
    String? grade,
    String? khademId,
  }) => Stream.value([]);
  final List<KhademModel> servants;
  AdminBoundary(this.servants);
  @override
  Stream<List<MakhdomModel>> getMakhdomeenStream() => Stream.value([]);
  @override
  Stream<List<KhademModel>> getKhodamStream() => Stream.value(servants);
  @override
  Stream<List<TaskModel>> getAllTasksStream() => Stream.value([]);
  @override
  Stream<List<AttendanceSessionModel>> getAllAttendanceSessionsStream({
    DateTime? from,
    DateTime? to,
  }) => Stream.value([]);
}

Future<void> show(WidgetTester t, String language, Widget page) async {
  await t.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: page),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });
  for (final language in ['ar', 'en']) {
    const number = '1,234';
    for (final visit in [
      ('phone', 'مكالمة هاتفية', 'Phone Call', Icons.phone_in_talk_rounded),
      (
        '📞 مكالمة تليفونية',
        'مكالمة هاتفية',
        'Phone Call',
        Icons.phone_in_talk_rounded,
      ),
      ('church', 'لقاء بالكنيسة', 'Church Meetup', Icons.church_rounded),
      (
        '⛪ لقاء في الكنيسة',
        'لقاء بالكنيسة',
        'Church Meetup',
        Icons.church_rounded,
      ),
      (
        '🏠 زيارة منزلية',
        'زيارة منزلية',
        'Home Visit',
        Icons.home_work_rounded,
      ),
      (
        'مكالمة مخصصة بالعربية',
        'مكالمة مخصصة بالعربية',
        'مكالمة مخصصة بالعربية',
        Icons.volunteer_activism_rounded,
      ),
    ]) {
      testWidgets(
        'history $language translates known visit ${visit.$1} with canonical icon',
        (t) async {
          await show(
            t,
            language,
            MakhdomHistoryScreen(
              makhdom: child,
              firestoreService: HistoryBoundary(visitType: visit.$1),
            ),
          );
          final badge = find.text(language == 'ar' ? visit.$2 : visit.$3);
          await t.scrollUntilVisible(
            badge,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(CustomScrollView).first,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(badge, findsOneWidget);
          expect(
            find.descendant(
              of: find.ancestor(of: badge, matching: find.byType(Row)).first,
              matching: find.byIcon(visit.$4),
            ),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
        },
      );
    }
    testWidgets('unvisited filter formats large $language count', (t) async {
      await show(
        t,
        language,
        MyMakhdomeenTab(myMakhdomeen: List.filled(1234, child)),
      );
      expect(
        find.text(
          language == 'ar'
              ? 'لم يفتقدوا بعد ($number)'
              : 'Not Visited ($number)',
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
    testWidgets('all tasks filter formats large $language count', (t) async {
      await show(
        t,
        language,
        TasksTab(
          tasksStream: Stream.value(List.filled(1234, task)),
          availableKhodam: const [],
          grade: '1st',
          canCreateTasks: false,
        ),
      );
      expect(
        find.text(language == 'ar' ? 'الكل ($number)' : 'All ($number)'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
    testWidgets('admin servants header formats large $language count', (
      t,
    ) async {
      final session = MockSessionCubit(const SessionState.signedOut());
      await show(
        t,
        language,
        BlocProvider<SessionCubit>.value(
          value: session,
          child: AdminMainScreen(
            firestoreService: AdminBoundary(List.filled(1234, servant)),
          ),
        ),
      );
      expect(
        find.text(language == 'ar' ? '$number خادم' : '$number servants'),
        findsOneWidget,
      );
      final tr = lookupGeneratedAppLocalizations(Locale(language));
      expect(find.text('${tr.grade1stName} ($number)'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      unawaited(session.close());
    });
    testWidgets('analytics international phone stays LTR in $language list', (
      t,
    ) async {
      await show(
        t,
        language,
        MyAnalyticsTab(myMakhdomeen: [child], sessions: const []),
      );
      final text = t.widget<Text>(find.text(phone));
      expect(text.textDirection, TextDirection.ltr);
      expect(t.takeException(), isNull);
    });
    testWidgets(
      'admin head chooser international phone stays LTR in $language list',
      (t) async {
        final session = MockSessionCubit(const SessionState.signedOut());
        await show(
          t,
          language,
          BlocProvider<SessionCubit>.value(
            value: session,
            child: AdminMainScreen(firestoreService: AdminBoundary([servant])),
          ),
        );
        final tr = lookupGeneratedAppLocalizations(Locale(language));
        await t.tap(find.text(tr.appointGradeHeadBtn).first);
        await t.pumpAndSettle();
        final phoneText = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(phone),
        );
        expect(t.widget<Text>(phoneText).textDirection, TextDirection.ltr);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        unawaited(session.close());
      },
    );
  }
}

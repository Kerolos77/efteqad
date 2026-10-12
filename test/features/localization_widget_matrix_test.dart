import 'package:efteqad/core/widgets/async_content.dart';
import 'package:efteqad/core/models/snapshot_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efteqad/core/models/page_result.dart';
import 'package:efteqad/features/khadem/presentation/screens/khadem_profile_screen.dart';
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
import 'package:efteqad/core/models/visit_model.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/attendance_roster_repository.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/core/settings/settings_cubit.dart';
import 'package:efteqad/core/settings/settings_repository.dart';
import 'package:efteqad/features/auth/presentation/screens/login_screen.dart';
import 'package:efteqad/features/auth/presentation/screens/pending_assignment_screen.dart';
import 'package:efteqad/features/settings/presentation/screens/settings_screen.dart';
import 'package:efteqad/features/tasks/presentation/screens/task_details_screen.dart';
import 'package:efteqad/features/tasks/presentation/widgets/add_task_dialog.dart';
import 'package:efteqad/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:efteqad/features/admin/presentation/screens/makhdom_history_screen.dart';
import 'package:efteqad/features/common/presentation/screens/route_error_screen.dart';
import '../core/router/app_router_test.dart' show MockSessionCubit;
import 'attendance/attendance_cubit_test.dart' show FakeAttendanceRepository;

class MatrixSettings implements SettingsRepository {
  @override
  Future<Locale> loadLocale() async => const Locale('ar', 'EG');
  @override
  Future<ThemeMode> loadThemeMode() async => ThemeMode.light;
  @override
  Future<void> saveLocale(Locale locale) async {}
  @override
  Future<void> saveThemeMode(ThemeMode theme) async {}
}

class HistoryBoundary extends FirestoreService {
  @override
  Future<PageResult<VisitModel>> fetchVisitPage({
    required String makhdomId,
    DocumentSnapshot? cursor,
    int limit = 50,
    DateTime? from,
    DateTime? to,
  }) async => PageResult(
    items: await getVisitsForMakhdomStream(makhdomId, from: from, to: to).first,
    hasMore: false,
  );
  final String visitType;
  HistoryBoundary({this.visitType = 'home'});
  @override
  Stream<List<VisitModel>> getVisitsForMakhdomStream(
    String id, {
    DateTime? from,
    DateTime? to,
  }) => Stream.value([
    VisitModel(
      id: 'v',
      makhdomId: id,
      makhdomName: 'كيرلس عماد',
      khademId: 's',
      khademName: 'الخادم',
      visitDate: DateTime(2026, 10, 8),
      visitType: visitType,
      notes: 'ملاحظات الأسرة باللغة العربية',
      createdAt: DateTime(2026, 10, 8),
    ),
  ]);
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
  }) => getAllAttendanceSessionsStream(from: from, to: to);
}

Future<void> frames(WidgetTester t) async {
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
    for (final scale in [1.0, 2.0]) {
      for (final screen in [
        'login',
        'pending',
        'profile',
        'settings',
        'task',
        'addTask',
        'attendance',
        'history',
        'error',
      ]) {
        testWidgets(
          '$screen $language at ${scale * 100}% uses real screen and direction without overflow',
          (tester) async {
            final renderErrors = <FlutterErrorDetails>[];
            final previousOnError = FlutterError.onError;
            FlutterError.onError = (details) {
              renderErrors.add(details);
              previousOnError?.call(details);
            };
            addTearDown(() => FlutterError.onError = previousOnError);
            tester.view.physicalSize = const Size(430, 932);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final locale = Locale(language);
            final tr = lookupGeneratedAppLocalizations(locale);
            final settings = SettingsCubit(repository: MatrixSettings());
            await settings.ready;
            final session = MockSessionCubit(
              SessionState(
                status: screen == 'pending'
                    ? SessionStatus.pending
                    : SessionStatus.active,
                userId: 's',
                role: screen == 'pending' ? UserRole.pending : UserRole.servant,
                grade: '1st',
                profile: KhademModel(
                  id: 's',
                  email: 'user@example.org',
                  name: 'كيرلس عماد',
                  phone: '+201234567890',
                  role: 'servant',
                  grade: '1st',
                  status: 'active',
                  createdAt: DateTime(2026),
                ),
              ),
            );
            final task = TaskModel(
              id: 't',
              title: 'عنوان كتبه المستخدم',
              description: 'وصف مخصص بالعربية',
              assignedKhademId: 's',
              assignedKhademName: 'كيرلس عماد',
              grade: '1st',
              createdById: 'head',
              createdByName: 'أمين الخدمة',
              type: 'attendance_khedma',
              dueDate: DateTime(2026, 10, 9),
              createdAt: DateTime(2026),
            );
            final attendance = FakeAttendanceRepository();
            final child = MakhdomModel(
              id: 'm',
              fullName: 'كيرلس عماد',
              phone: '+201234567890',
              fatherPhone: '+201222222222',
              motherPhone: '+201111111111',
              address: 'شبرا مصر',
              school: 'مدرسة عربية',
              grade: '1st',
              createdAt: DateTime(2026, 10, 1),
            );
            final Widget page = switch (screen) {
              'login' => const LoginScreen(),
              'pending' => const PendingAssignmentScreen(),
              'profile' => const KhademProfileScreen(),
              'settings' => const SettingsScreen(),
              'task' => TaskDetailsScreen(taskId: 't', task: task),
              'addTask' => AddTaskDialog(
                availableKhodam: [session.state.profile!],
                grade: '1st',
              ),
              'attendance' => AttendanceScreen(
                task: task,
                repository: attendance,
                loadRoster: (_) async => [
                  const AttendanceRosterRow(
                    id: 'm',
                    fullName: 'كيرلس عماد',
                    grade: '1st',
                    active: true,
                  ),
                ],
              ),
              'history' => MakhdomHistoryScreen(
                makhdom: child,
                firestoreService: HistoryBoundary(),
              ),
              _ => RouteErrorScreen(
                type: RouteErrorType.forbidden,
                onRetry: () {},
              ),
            };
            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<SessionCubit>.value(value: session),
                  BlocProvider.value(value: settings),
                ],
                child: MaterialApp(
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: page,
                ),
              ),
            );
            await frames(tester);
            if (screen == 'attendance') {
              attendance.emitSession(null);
              await frames(tester);
            }
            final expected = switch (screen) {
              'login' => tr.continueWithGoogle,
              'pending' => tr.pendingStatusTitle,
              'profile' => tr.profileTitle,
              'settings' => tr.settingsTitle,
              'task' => tr.messageTaskDetails,
              'addTask' => tr.addTaskTitle,
              'attendance' => tr.attendanceScreenTitleService,
              'history' => tr.historyAction,
              _ => tr.messageAccessDenied,
            };
            expect(find.textContaining(expected), findsWidgets);
            expect(
              Directionality.of(
                tester.element(find.textContaining(expected).first),
              ),
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            );
            if (screen == 'pending' || screen == 'profile') {
              final phones = tester
                  .widgetList<EditableText>(find.byType(EditableText))
                  .where((field) => field.controller.text == '+201234567890');
              expect(phones, hasLength(1));
              expect(phones.single.textDirection, TextDirection.ltr);
            }
            if (screen == 'task') {
              expect(find.text('عنوان كتبه المستخدم'), findsOneWidget);
              expect(find.text('وصف مخصص بالعربية'), findsOneWidget);
            }
            if (screen == 'history') {
              expect(find.text('كيرلس عماد'), findsOneWidget);
              final badge = find.text(
                language == 'ar' ? 'زيارة منزلية' : 'Home Visit',
              );
              await tester.scrollUntilVisible(
                badge,
                200,
                scrollable: find
                    .descendant(
                      of: find.byType(CustomScrollView).first,
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await frames(tester);
              expect(badge, findsOneWidget);
              expect(find.byIcon(Icons.home_work_rounded), findsOneWidget);
            }
            expect(
              tester.takeException(),
              isNull,
              reason: renderErrors.map((e) => e.toString()).join('\n'),
            );
            await tester.pumpWidget(const SizedBox());
            unawaited(settings.close());
            unawaited(session.close());
            attendance.dispose();
          },
        );
      }
    }
  }
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final state in ['cached', 'pending']) {
        testWidgets(
          '$state read banner $language at ${scale * 100}% wraps at360px',
          (t) async {
            await t.binding.setSurfaceSize(const Size(360, 720));
            addTearDown(() => t.binding.setSurfaceSize(null));
            final locale = Locale(language, language == 'ar' ? 'EG' : 'US');
            final tr = await AppLocalizations.delegate.load(locale);
            await t.pumpWidget(
              MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: AsyncContent<List<String>>(
                    isLoading: false,
                    data: SnapshotList(
                      ['Loaded'],
                      isFromCache: state == 'cached',
                      hasPendingWrites: state == 'pending',
                    ),
                    builder: (context, items) =>
                        Center(child: Text(items.single)),
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
            expect(
              find.text(
                state == 'cached'
                    ? tr.cachedDataHint
                    : tr.messageSyncingPendingChanges,
              ),
              findsOneWidget,
            );
            expect(find.text('Loaded'), findsOneWidget);
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}

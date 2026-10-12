import '../utils/calendar_dates.dart';
import '../widgets/query_content.dart';
import '../models/visit_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/constants.dart';
import '../localization/app_localizations.dart';
import '../models/attendance_session_model.dart';
import '../models/khadem_model.dart';
import '../models/makhdom_model.dart';
import '../models/task_model.dart';
import 'route_resource_loader.dart';
import '../errors/app_failure.dart';
import '../repositories/attendance_repository.dart';
import '../services/attendance_roster_repository.dart';
import 'router_services.dart';
import '../services/firestore_service.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';
import 'app_routes.dart';
import 'notification_intent_coordinator.dart';
import 'route_access_service.dart';
import 'router_refresh_notifier.dart';
import 'widgets/protected_resource_page.dart';

// Screen imports
import '../../features/admin/presentation/screens/analytics_tab.dart';
import '../../features/admin/presentation/screens/khodam_tab.dart';
import '../../features/admin/presentation/screens/makhdom_history_screen.dart';
import '../../features/admin/presentation/widgets/add_edit_makhdom_dialog.dart';
import '../../features/admin/presentation/widgets/excel_actions_sheet.dart';
import '../../features/admin/presentation/widgets/grade_makhdomeen_tab.dart';
import '../../features/admin/presentation/widgets/stage_people_tab.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_assignment_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/common/presentation/screens/notifications_screen.dart';
import '../../features/common/presentation/screens/route_error_screen.dart';
import '../../features/common/presentation/screens/splash_screen.dart';
import '../../features/common/widgets/app_drawer.dart';
import '../../features/common/widgets/notifications_sheet.dart';
import '../../features/khadem/presentation/screens/khadem_profile_screen.dart';
import '../../features/khadem/presentation/widgets/my_analytics_tab.dart';
import '../../features/khadem/presentation/widgets/my_makhdomeen_tab.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/tasks/presentation/widgets/tasks_tab.dart';

/// Intent ownership belongs to this router, never to another login/router.
class RouterIntentState {
  String? intendedRoute;
  String? _owner;
  String? _lastScope;
  bool _hadActiveSession = false;

  bool observe(SessionState session) {
    var cleared = false;
    final scope = session.scopeKey;
    if ((_owner != null && session.status == SessionStatus.signedOut) ||
        (_hadActiveSession &&
            (session.status == SessionStatus.signedOut ||
                (session.isActive && _lastScope != scope)))) {
      intendedRoute = null;
      _owner = null;
      cleared = true;
    }
    if (_owner != null && session.userId != null && _owner != session.userId) {
      intendedRoute = null;
    }
    if (session.userId != null) _owner = session.userId;
    if (session.status == SessionStatus.signedOut) {
      _hadActiveSession = false;
      _lastScope = null;
    }
    if (session.isActive) {
      _hadActiveSession = true;
      _lastScope = scope;
    }
    return cleared;
  }

  void remember(Uri uri) {
    if (RouteAccessService.isSafeInternalUri(uri) &&
        !{
          AppRoutes.bootstrapPath,
          AppRoutes.loginPath,
          AppRoutes.pendingPath,
          AppRoutes.deletingPath,
          AppRoutes.sessionFailurePath,
          '/',
        }.contains(uri.path)) {
      intendedRoute ??= uri.toString();
    }
  }
}

String? evaluateAppRouterRedirect({
  required SessionState session,
  required String matchedLocation,
  required Uri uri,
  RouteAccessService routeAccessService = const RouteAccessService(),
  NotificationIntentCoordinator? notificationIntentCoordinator,
  RouterIntentState? intentState,
}) {
  final intents = intentState ?? RouterIntentState();
  final discardedOldScope = intents.observe(session);
  notificationIntentCoordinator?.observe(session);
  final path = matchedLocation;
  if (session.status == SessionStatus.booting ||
      session.status == SessionStatus.profileLoading) {
    intents.remember(uri);
    return path == AppRoutes.bootstrapPath ? null : AppRoutes.bootstrapPath;
  }
  if (session.status == SessionStatus.failure) {
    intents.remember(uri);
    return path == AppRoutes.sessionFailurePath ||
            path == AppRoutes.settingsPath
        ? null
        : AppRoutes.sessionFailurePath;
  }
  if (session.isDeleting) {
    intents.intendedRoute = null;
    return path == AppRoutes.deletingPath ? null : AppRoutes.deletingPath;
  }
  if (session.status == SessionStatus.signedOut || !session.isAuthenticated) {
    if (path == AppRoutes.settingsPath || path == AppRoutes.loginPath) {
      return null;
    }
    if (!discardedOldScope) intents.remember(uri);
    return AppRoutes.loginPath;
  }
  if (session.isPending) {
    if ({
      AppRoutes.pendingPath,
      AppRoutes.settingsPath,
      AppRoutes.profilePath,
    }.contains(path)) {
      return null;
    }
    intents.remember(uri);
    return AppRoutes.pendingPath;
  }
  if (session.isActive) {
    final intentPath = notificationIntentCoordinator?.consumeFor(session);
    if (intentPath != null && intentPath != uri.toString()) return intentPath;
    if ({
          AppRoutes.loginPath,
          AppRoutes.bootstrapPath,
          AppRoutes.pendingPath,
          AppRoutes.sessionFailurePath,
        }.contains(path) &&
        intents.intendedRoute != null) {
      final target = intents.intendedRoute!;
      intents.intendedRoute = null;
      final access = routeAccessService.check(Uri.parse(target), session);
      if (access == RouteAccessResult.allowed) return target;
      return access == RouteAccessResult.denied
          ? AppRoutes.forbiddenPath
          : AppRoutes.notFoundPath;
    }
    if ({
      AppRoutes.bootstrapPath,
      AppRoutes.loginPath,
      AppRoutes.pendingPath,
      AppRoutes.deletingPath,
      AppRoutes.sessionFailurePath,
      '/',
      '',
    }.contains(path)) {
      return AppRoutes.landing(session);
    }
    final access = routeAccessService.check(uri, session);
    if (access == RouteAccessResult.denied) return AppRoutes.forbiddenPath;
    if (access == RouteAccessResult.notFound) {
      return path == AppRoutes.notFoundPath ? null : AppRoutes.notFoundPath;
    }
  }
  return null;
}

GoRouter createAppRouter({
  required SessionCubit sessionCubit,
  RouteAccessService routeAccessService = const RouteAccessService(),
  NotificationIntentCoordinator? notificationIntentCoordinator,
  String? initialLocation,
  RouteResourceLoader? resourceLoader,
  FirestoreService? firestoreService,
  AttendanceRepository? attendanceRepository,
  Future<List<AttendanceRosterRow>> Function(String)? attendanceRosterLoader,
}) {
  final intents = RouterIntentState();
  final resources = resourceLoader ?? FirestoreRouteResourceLoader();
  final firestore = firestoreService ?? FirestoreService();
  List<RouteBase> routes() => [
    // Top-level Public & Auth Routes
    GoRoute(
      path: AppRoutes.bootstrapPath,
      name: AppRoutes.bootstrapName,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginPath,
      name: AppRoutes.loginName,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.pendingPath,
      name: AppRoutes.pendingName,
      builder: (context, state) => BlocProvider.value(
        value: sessionCubit,
        child: const PendingAssignmentScreen(),
      ),
    ),

    GoRoute(
      path: AppRoutes.deletingPath,
      builder: (context, state) =>
          _SessionExitScreen(sessionCubit: sessionCubit, deleting: true),
    ),
    GoRoute(
      path: AppRoutes.sessionFailurePath,
      builder: (context, state) =>
          _SessionExitScreen(sessionCubit: sessionCubit),
    ),
    // Top-level Utilities & Settings Routes
    GoRoute(
      path: AppRoutes.profilePath,
      name: AppRoutes.profileName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('profile/${sessionCubit.state.scopeKey}'),
        child: BlocProvider.value(
          value: sessionCubit,
          child: const KhademProfileScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsPath,
      name: AppRoutes.settingsName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('settings/${sessionCubit.state.scopeKey}'),
        child: BlocProvider.value(
          value: sessionCubit,
          child: const SettingsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.notificationsPath,
      name: AppRoutes.notificationsName,
      pageBuilder: (context, state) => NoTransitionPage(
        key: ValueKey('notifications/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: const NotificationsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.forbiddenPath,
      name: AppRoutes.forbiddenName,
      builder: (context, state) =>
          const RouteErrorScreen(type: RouteErrorType.forbidden),
    ),
    GoRoute(
      path: AppRoutes.notFoundPath,
      name: AppRoutes.notFoundName,
      builder: (context, state) =>
          const RouteErrorScreen(type: RouteErrorType.notFound),
    ),

    // Resource Detail Stack Routes (IDs in URL, extra is optional cache)
    GoRoute(
      path: AppRoutes.makhdomHistoryPattern,
      name: AppRoutes.makhdomHistoryName,
      builder: (context, state) {
        final makhdomId = state.pathParameters['makhdomId'] ?? '';
        return BlocBuilder<SessionCubit, SessionState>(
          bloc: sessionCubit,
          builder: (context, session) => ProtectedResourcePage<MakhdomModel>(
            key: ValueKey('$makhdomId/${session.scopeKey}'),
            loadResource: () => _loadAuthorized(
              routeAccessService.loadChild(
                resources,
                makhdomId,
                () => sessionCubit.state,
              ),
              (child) =>
                  routeAccessService.authorizeChild(child, sessionCubit.state),
              AppRoutes.makhdomHistory(makhdomId),
              session,
              notificationIntentCoordinator,
            ),
            watchResource: () => resources.watchChild(makhdomId),
            authorize: (child) =>
                routeAccessService.authorizeChild(child, sessionCubit.state),
            builder: (context, child) => MakhdomHistoryScreen(
              makhdom: child,
              firestoreService: firestore,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.taskDetailsPattern,
      name: AppRoutes.taskDetailsName,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return BlocBuilder<SessionCubit, SessionState>(
          bloc: sessionCubit,
          builder: (context, session) => ProtectedResourcePage<TaskModel>(
            key: ValueKey('$taskId/${session.scopeKey}'),
            loadResource: () => _loadAuthorized(
              routeAccessService.loadTask(
                resources,
                taskId,
                () => sessionCubit.state,
              ),
              (task) =>
                  routeAccessService.authorizeTask(task, sessionCubit.state),
              AppRoutes.taskDetails(taskId),
              session,
              notificationIntentCoordinator,
            ),
            watchResource: () => resources.watchTask(taskId),
            authorize: (task) =>
                routeAccessService.authorizeTask(task, sessionCubit.state),
            builder: (context, task) =>
                TaskDetailsScreen(taskId: taskId, task: task),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.taskAttendancePattern,
      name: AppRoutes.taskAttendanceName,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return BlocBuilder<SessionCubit, SessionState>(
          bloc: sessionCubit,
          builder: (context, session) => ProtectedResourcePage<TaskModel>(
            key: ValueKey('attendance/$taskId/${session.scopeKey}'),
            loadResource: () => _loadAuthorized(
              routeAccessService.loadTask(
                resources,
                taskId,
                () => sessionCubit.state,
                attendance: true,
              ),
              (task) => routeAccessService.authorizeTask(
                task,
                sessionCubit.state,
                attendance: true,
              ),
              AppRoutes.taskAttendance(taskId),
              session,
              notificationIntentCoordinator,
            ),
            watchResource: () => resources.watchTask(taskId),
            authorize: (task) => routeAccessService.authorizeTask(
              task,
              sessionCubit.state,
              attendance: true,
            ),
            builder: (context, task) => BlocProvider.value(
              value: sessionCubit,
              child: AttendanceScreen(
                key: ValueKey(
                  '${task.id}/${task.grade}/${task.type}/${task.attendanceDay}',
                ),
                task: task,
                repository: attendanceRepository,
                loadRoster: attendanceRosterLoader,
              ),
            ),
          ),
        );
      },
    ),

    // 1. Stage Shell Route (/stage/*)
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        key: ValueKey('stage/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: _StageShellScaffold(navigationShell: navigationShell),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stagePeoplePath,
              name: AppRoutes.stagePeopleName,
              builder: (context, state) => const _StagePeopleWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stageAnalyticsPath,
              name: AppRoutes.stageAnalyticsName,
              builder: (context, state) => const _StageAnalyticsWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stageTasksPath,
              name: AppRoutes.stageTasksName,
              builder: (context, state) => const _StageTasksWrapper(),
            ),
          ],
        ),
      ],
    ),

    // 2. Grade Shell Route (/grades/:grade/*)
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        key: ValueKey(
          'grade/${state.pathParameters['grade']}/${sessionCubit.state.scopeKey}',
        ),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: _GradeShellScaffold(
            grade: state.pathParameters['grade']!,
            navigationShell: navigationShell,
          ),
        ),
      ),
      branches: [
        StatefulShellBranch(
          initialLocation: '/grades/1st/makhdomeen',
          routes: [
            GoRoute(
              path: AppRoutes.gradeMakhdomeenPattern,
              name: AppRoutes.gradeMakhdomeenName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeMakhdomeenWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/analytics',
          routes: [
            GoRoute(
              path: AppRoutes.gradeAnalyticsPattern,
              name: AppRoutes.gradeAnalyticsName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeAnalyticsWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/khodam',
          routes: [
            GoRoute(
              path: AppRoutes.gradeKhodamPattern,
              name: AppRoutes.gradeKhodamName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeKhodamWrapper(grade: grade);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/grades/1st/tasks',
          routes: [
            GoRoute(
              path: AppRoutes.gradeTasksPattern,
              name: AppRoutes.gradeTasksName,
              builder: (context, state) {
                final grade =
                    state.pathParameters['grade'] ?? AppConstants.grade1st;
                return _GradeTasksWrapper(grade: grade);
              },
            ),
          ],
        ),
      ],
    ),

    // 3. Servant (Me) Shell Route (/me/*)
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        key: ValueKey('me/${sessionCubit.state.scopeKey}'),
        child: RouterServices(
          firestore: firestore,
          session: sessionCubit,
          child: _ServantShellScaffold(navigationShell: navigationShell),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myMakhdomeenPath,
              name: AppRoutes.myMakhdomeenName,
              builder: (context, state) => const _MyMakhdomeenWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myTasksPath,
              name: AppRoutes.myTasksName,
              builder: (context, state) => const _MyTasksWrapper(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myAnalyticsPath,
              name: AppRoutes.myAnalyticsName,
              builder: (context, state) => const _MyAnalyticsWrapper(),
            ),
          ],
        ),
      ],
    ),
  ];
  String? redirect(BuildContext context, GoRouterState state) =>
      evaluateAppRouterRedirect(
        intentState: intents,
        session: sessionCubit.state,
        matchedLocation: state.matchedLocation,
        uri: state.uri,
        routeAccessService: routeAccessService,
        notificationIntentCoordinator: notificationIntentCoordinator,
      );
  final configuration = ValueNotifier(
    RoutingConfig(routes: routes(), redirect: redirect),
  );
  final refresh = RouterRefreshNotifier(
    sessionCubit,
    coordinator: notificationIntentCoordinator,
    onScopeChange: () => configuration.value = RoutingConfig(
      routes: routes(),
      redirect: redirect,
    ),
    onDispose: configuration.dispose,
  );
  return GoRouter.routingConfig(
    routingConfig: configuration,
    initialLocation: initialLocation ?? AppRoutes.bootstrapPath,
    refreshListenable: refresh,
    errorBuilder: (context, state) =>
        const RouteErrorScreen(type: RouteErrorType.notFound),
  );
}

// =============================================================================
// Shell Scaffolds
// =============================================================================

class _StageShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _StageShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(isAdmin: true),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: context.tr.messageMainMenu,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          context.tr.stageDashboardTitle,
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
        ),
        actions: const [NotificationBellButton()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (idx) =>
            navigationShell.goBranch(idx, initialLocation: false),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.manage_accounts_outlined),
            selectedIcon: const Icon(Icons.manage_accounts),
            label: context.tr.tabGradesAndServants,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: context.tr.tabStageAnalytics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: context.tr.tabStageTasks,
          ),
        ],
      ),
      body: navigationShell,
    );
  }
}

class _GradeShellScaffold extends StatefulWidget {
  final String grade;
  final StatefulNavigationShell navigationShell;

  const _GradeShellScaffold({
    required this.grade,
    required this.navigationShell,
  });

  @override
  State<_GradeShellScaffold> createState() => _GradeShellScaffoldState();
}

class _GradeShellScaffoldState extends State<_GradeShellScaffold> {
  late final Set<int> _visited = {widget.navigationShell.currentIndex};
  String get grade => widget.grade;
  StatefulNavigationShell get navigationShell => widget.navigationShell;
  void _select(BuildContext context, int index) {
    if (_visited.add(index)) {
      context.go(
        [
          AppRoutes.gradeMakhdomeen(grade),
          AppRoutes.gradeAnalytics(grade),
          AppRoutes.gradeKhodam(grade),
          AppRoutes.gradeTasks(grade),
        ][index],
      );
    } else {
      navigationShell.goBranch(index);
    }
  }

  String _getGradeLabel(BuildContext context) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return grade;
    }
  }

  void _openAddMakhdomDialog(
    BuildContext context,
    List<KhademModel> khodamList,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditMakhdomDialog(
        khodamList: khodamList,
        initialMakhdom: MakhdomModel(
          id: '',
          fullName: '',
          phone: '',
          grade: grade,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradeLabel = _getGradeLabel(context);
    final firestoreService = RouterServices.of(context).firestore;

    return QueryContent<List<KhademModel>>(
      queryKey: '${RouterServices.of(context).session.state.scopeKey}/shell',
      query: () => firestoreService.getKhodamByGradeStream(grade),
      builder: (context, khodamList) {
        return Scaffold(
          drawer: AppDrawer(
            isAdmin: true,
            onOpenExcel: () async {
              final makhdomeen = await firestoreService.getMakhdomeenByGrade(
                grade,
              );
              if (context.mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ExcelActionsSheet(
                    currentMakhdomeen: makhdomeen,
                    grade: grade,
                  ),
                );
              }
            },
          ),
          appBar: AppBar(
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: context.tr.messageMainMenu,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text(
              context.tr.gradeDashboardTitle(gradeLabel),
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: const [NotificationBellButton()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (idx) => _select(context, idx),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: context.tr.messageMakhdomeen,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: context.tr.tabAnalytics,
              ),
              NavigationDestination(
                icon: const Icon(Icons.badge_outlined),
                selectedIcon: const Icon(Icons.badge),
                label: context.tr.tabKhodam(khodamList.length),
              ),
              NavigationDestination(
                icon: const Icon(Icons.task_alt_outlined),
                selectedIcon: const Icon(Icons.task_alt),
                label: context.tr.tabGradeTasks,
              ),
            ],
          ),
          floatingActionButton: navigationShell.currentIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openAddMakhdomDialog(context, khodamList),
                  backgroundColor: AppConstants.primaryLight,
                  icon: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    context.tr.addMakhdomBtn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          body: navigationShell,
        );
      },
    );
  }
}

class _ServantShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ServantShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(isAdmin: false),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: context.tr.messageMainMenu,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          context.tr.appName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        actions: const [NotificationBellButton()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (idx) =>
            navigationShell.goBranch(idx, initialLocation: false),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            selectedIcon: const Icon(Icons.people_alt),
            label: context.tr.messageMyStudents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: context.tr.messageMyTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: context.tr.tabAnalytics,
          ),
        ],
      ),
      body: navigationShell,
    );
  }
}

// =============================================================================
// Shell Branch Wrappers
// =============================================================================

class _StagePeopleWrapper extends StatelessWidget {
  const _StagePeopleWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenStream(),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamStream(),
          builder: (context, khodamSnap) {
            final allKhodam = khodamSnap;
            final pendingKhodam = allKhodam
                .where((k) => k.isPending || !k.isActive)
                .toList();
            final allMakhdomeen = makhdomeenSnap;

            return StagePeopleTab(
              pendingKhodam: pendingKhodam,
              allKhodam: allKhodam,
              allMakhdomeen: allMakhdomeen,
            );
          },
        );
      },
    );
  }
}

class _StageAnalyticsWrapper extends StatelessWidget {
  const _StageAnalyticsWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenStream(),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamStream(),
          builder: (context, khodamSnap) {
            final allKhodam = khodamSnap;
            final activeKhodam = allKhodam.where((k) => k.isActive).toList();
            final allMakhdomeen = makhdomeenSnap;

            return AnalyticsTab(
              firestoreService: firestore,
              makhdomeen: allMakhdomeen,
              khodam: activeKhodam,
            );
          },
        );
      },
    );
  }
}

class _StageTasksWrapper extends StatelessWidget {
  const _StageTasksWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<KhademModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
      query: () => firestore.getKhodamStream(),
      builder: (context, khodamSnap) {
        final allKhodam = khodamSnap;
        final activeKhodam = allKhodam.where((k) => k.isActive).toList();

        return TasksTab(
          tasksStream: firestore.getAllTasksStream(),
          tasksQuery: () => firestore.getAllTasksStream(),
          availableKhodam: activeKhodam,
          grade: 'all',
          canCreateTasks: true,
        );
      },
    );
  }
}

class _GradeMakhdomeenWrapper extends StatelessWidget {
  final String grade;

  const _GradeMakhdomeenWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenByGradeStream(grade),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamByGradeStream(grade),
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap;
            final khodamList = khodamSnap;

            return GradeMakhdomeenTab(
              grade: grade,
              allMakhdomeen: allMakhdomeen,
              khodamList: khodamList,
            );
          },
        );
      },
    );
  }
}

class _GradeAnalyticsWrapper extends StatelessWidget {
  final String grade;

  const _GradeAnalyticsWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenByGradeStream(grade),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamByGradeStream(grade),
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap;
            final khodamList = khodamSnap;

            return AnalyticsTab(
              firestoreService: firestore,
              makhdomeen: allMakhdomeen,
              khodam: khodamList,
              grade: grade,
            );
          },
        );
      },
    );
  }
}

class _GradeKhodamWrapper extends StatelessWidget {
  final String grade;

  const _GradeKhodamWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenByGradeStream(grade),
      builder: (context, makhdomeenSnap) {
        return QueryContent<List<KhademModel>>(
          queryKey:
              '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
          query: () => firestore.getKhodamByGradeStream(grade),
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap;
            final khodamList = khodamSnap;

            return KhodamTab(khodam: khodamList, allMakhdomeen: allMakhdomeen);
          },
        );
      },
    );
  }
}

class _GradeTasksWrapper extends StatelessWidget {
  final String grade;

  const _GradeTasksWrapper({required this.grade});

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    return QueryContent<List<KhademModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/khodamSnap',
      query: () => firestore.getKhodamByGradeStream(grade),
      builder: (context, khodamSnap) {
        final khodamList = khodamSnap;

        return TasksTab(
          tasksStream: firestore.getTasksForGradeStream(grade),
          tasksQuery: () => firestore.getTasksForGradeStream(grade),
          availableKhodam: khodamList,
          grade: grade,
          canCreateTasks: true,
        );
      },
    );
  }
}

class _MyMakhdomeenWrapper extends StatelessWidget {
  const _MyMakhdomeenWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final state = RouterServices.of(context).session.state;
    final uid = state.userId ?? '', grade = state.grade;
    if (state.status != SessionStatus.active || grade == null) {
      return const SizedBox.shrink();
    }

    return QueryContent<List<MakhdomModel>>(
      queryKey:
          '${RouterServices.of(context).session.state.scopeKey}/makhdomeenSnap',
      query: () => firestore.getMakhdomeenForKhademStream(uid),
      builder: (context, makhdomeenSnap) {
        final makhdomeen = makhdomeenSnap;

        return QueryContent<List<AttendanceSessionModel>>(
          queryKey:
              '${RouterServices.of(context).session.state.scopeKey}/sessionsSnap',
          query: () => firestore.getAttendanceSessionsForGradeStream(
            grade,
            from: calendarDay(DateTime.now(), -89),
            to: DateTime.now(),
          ),
          builder: (context, sessionsSnap) {
            final sessions = sessionsSnap;
            return MyMakhdomeenTab(
              myMakhdomeen: makhdomeen,
              sessions: sessions,
            );
          },
        );
      },
    );
  }
}

class _MyTasksWrapper extends StatelessWidget {
  const _MyTasksWrapper();

  @override
  Widget build(BuildContext context) {
    final firestore = RouterServices.of(context).firestore;
    final uid = RouterServices.of(context).session.state.userId ?? '';

    return TasksTab(
      tasksStream: firestore.getTasksForKhademStream(uid),
      tasksQuery: () => firestore.getTasksForKhademStream(uid),
      availableKhodam: const [],
      grade: 'all',
      canCreateTasks: false,
    );
  }
}

class _MyAnalyticsWrapper extends StatefulWidget {
  const _MyAnalyticsWrapper();
  @override
  State<_MyAnalyticsWrapper> createState() => _MyAnalyticsWrapperState();
}

class _MyAnalyticsWrapperState extends State<_MyAnalyticsWrapper> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    final services = RouterServices.of(context), firestore = services.firestore;
    final uid = services.session.state.userId ?? '',
        grade = services.session.state.grade;
    if (services.session.state.status != SessionStatus.active ||
        grade == null) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now(),
        asOf = DateTime(now.year, now.month, now.day),
        from = calendarDay(now, -89);
    return QueryContent<List<MakhdomModel>>(
      queryKey: services.session.state.scopeKey,
      query: () => firestore.getMakhdomeenForKhademStream(uid),
      builder: (context, children) {
        final ids = children.map((m) => m.id).toList()..sort();
        return QueryContent<List<VisitModel>>(
          queryKey:
              '${services.session.state.scopeKey}/${ids.join(',')}/$from/$_revision',
          query: () =>
              firestore.watchVisitsForChildrenWindow(ids, from: from, to: asOf),
          builder: (context, visits) =>
              QueryContent<List<AttendanceSessionModel>>(
                queryKey: '${services.session.state.scopeKey}/$grade/$from',
                query: () => firestore.getAttendanceSessionsForGradeStream(
                  grade,
                  from: from,
                  to: asOf,
                ),
                builder: (context, sessions) => Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        tooltip: context.tr.retryAction,
                        onPressed: () => setState(() => _revision++),
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                    Expanded(
                      child: MyAnalyticsTab(
                        myMakhdomeen: children,
                        sessions: sessions,
                        visits: visits,
                        from: from,
                        asOf: asOf,
                        onVisitRecorded: () => setState(() => _revision++),
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }
}

class _SessionExitScreen extends StatelessWidget {
  final SessionCubit sessionCubit;
  final bool deleting;
  const _SessionExitScreen({required this.sessionCubit, this.deleting = false});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          deleting
              ? (context.tr.messageAccountDeletionInProgress)
              : (context.tr.messageUnableToLoadProfile),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deleting) const CircularProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                deleting
                    ? (context.tr.messageYourDeletionRequestIsSavedYouCan)
                    : context.tr.dataUnavailable,
              ),
            ),
            OutlinedButton(
              onPressed: sessionCubit.retry,
              child: Text(context.tr.messageRetry),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await sessionCubit.signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr.dataUnavailable)),
                    );
                  }
                }
              },
              child: Text(context.tr.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> _loadAuthorized<T>(
  Future<T?> lookup,
  void Function(T) authorize,
  String target,
  SessionState session,
  NotificationIntentCoordinator? coordinator,
) async {
  try {
    final value = await lookup;
    if (value != null) authorize(value);
    coordinator?.completeVerified(target, session);
    return value;
  } catch (error) {
    final failure = AppFailure.fromException(error);
    if (failure.code == 'permission-denied' || failure.code == 'not-found') {
      coordinator?.completeVerified(target, session);
    }
    rethrow;
  }
}

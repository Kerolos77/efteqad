import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/repositories/auth_repository.dart';
import 'package:efteqad/core/repositories/profile_repository.dart';
import 'package:efteqad/core/router/app_router.dart';
import 'package:efteqad/core/router/app_routes.dart';
import 'package:efteqad/core/router/notification_intent_coordinator.dart';
import 'package:efteqad/core/router/route_access_service.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';

class StubAuthRepository implements AuthRepository {
  @override
  Stream<AuthIdentity?> watchAuth() => const Stream.empty();
  @override
  AuthIdentity? get currentAuth => null;
  @override
  Future<void> signOut() async {}
}

class StubProfileRepository implements ProfileRepository {
  @override
  Stream<KhademModel?> watchProfile(String uid) => const Stream.empty();

  @override
  Future<KhademModel?> getProfile(String uid) async => null;
}

class MockSessionCubit extends SessionCubit {
  MockSessionCubit(SessionState initialState)
    : super(
        authRepository: StubAuthRepository(),
        profileRepository: StubProfileRepository(),
      ) {
    emit(initialState);
  }
  void emitMockState(SessionState newState) => emit(newState);
}

void main() {
  group('AppRouter Redirect & Guard Unit Tests', () {
    late RouterIntentState intents;
    late RouteAccessService routeAccess;
    late NotificationIntentCoordinator coordinator;

    final stageAdmin = KhademModel(
      id: 'admin-1',
      name: 'Stage Admin',
      email: 'admin@efteqad.com',
      phone: '01000000000',
      role: AppConstants.roleStageAdmin,
      createdAt: DateTime.now(),
    );

    final grade2Admin = KhademModel(
      id: 'grade2-admin',
      name: 'Grade 2 Head',
      email: 'g2@efteqad.com',
      phone: '01000000001',
      role: AppConstants.roleGradeAdmin,
      grade: AppConstants.grade2nd,
      createdAt: DateTime.now(),
    );

    final servant = KhademModel(
      id: 'servant-1',
      name: 'Servant',
      email: 'servant@efteqad.com',
      phone: '01000000002',
      role: AppConstants.roleServant,
      grade: AppConstants.grade1st,
      createdAt: DateTime.now(),
    );

    final pendingServant = KhademModel(
      id: 'pending-1',
      name: 'Pending',
      email: 'pending@efteqad.com',
      phone: '01000000003',
      role: AppConstants.rolePending,
      createdAt: DateTime.now(),
    );

    setUp(() {
      intents = RouterIntentState();
      routeAccess = const RouteAccessService();
      coordinator = NotificationIntentCoordinator(
        routeAccessService: routeAccess,
      );
    });

    String? redirectFor({
      required SessionState session,
      required String location,
      NotificationIntentCoordinator? customCoordinator,
    }) {
      return evaluateAppRouterRedirect(
        intentState: intents,
        session: session,
        matchedLocation: location,
        uri: Uri.parse(location),
        routeAccessService: routeAccess,
        notificationIntentCoordinator: customCoordinator ?? coordinator,
      );
    }

    test('booting or profileLoading redirects to /bootstrap', () {
      expect(
        redirectFor(
          session: const SessionState.booting(),
          location: AppRoutes.stagePeoplePath,
        ),
        AppRoutes.bootstrapPath,
      );
      expect(
        redirectFor(
          session: const SessionState.profileLoading(userId: 'u1'),
          location: AppRoutes.myMakhdomeenPath,
        ),
        AppRoutes.bootstrapPath,
      );
      // Already at bootstrap
      expect(
        redirectFor(
          session: const SessionState.booting(),
          location: AppRoutes.bootstrapPath,
        ),
        isNull,
      );
    });

    test('signedOut redirects to /login unless accessing /settings', () {
      expect(
        redirectFor(
          session: const SessionState.signedOut(),
          location: AppRoutes.myMakhdomeenPath,
        ),
        AppRoutes.loginPath,
      );
      expect(
        redirectFor(
          session: const SessionState.signedOut(),
          location: AppRoutes.settingsPath,
        ),
        isNull,
      );
      expect(
        redirectFor(
          session: const SessionState.signedOut(),
          location: AppRoutes.loginPath,
        ),
        isNull,
      );
    });

    test(
      'pending role redirects to /pending unless accessing /settings or /profile',
      () {
        final pendingSession = SessionState(
          status: SessionStatus.pending,
          userId: 'pending-1',
          role: UserRole.pending,
          profile: pendingServant,
        );

        expect(
          redirectFor(
            session: pendingSession,
            location: AppRoutes.stagePeoplePath,
          ),
          AppRoutes.pendingPath,
        );
        expect(
          redirectFor(session: pendingSession, location: AppRoutes.profilePath),
          isNull,
        );
        expect(
          redirectFor(
            session: pendingSession,
            location: AppRoutes.settingsPath,
          ),
          isNull,
        );
        expect(
          redirectFor(session: pendingSession, location: AppRoutes.pendingPath),
          isNull,
        );
      },
    );

    test('landing redirects to appropriate dashboard for each role', () {
      // 1. Stage Admin
      final stageSession = SessionState(
        status: SessionStatus.active,
        userId: 'admin-1',
        role: UserRole.stageAdmin,
        profile: stageAdmin,
      );
      expect(
        redirectFor(session: stageSession, location: AppRoutes.loginPath),
        AppRoutes.stagePeoplePath,
      );
      expect(
        redirectFor(session: stageSession, location: AppRoutes.bootstrapPath),
        AppRoutes.stagePeoplePath,
      );

      // 2. Grade Admin
      final gradeSession = SessionState(
        status: SessionStatus.active,
        userId: 'grade2-admin',
        role: UserRole.gradeAdmin,
        grade: AppConstants.grade2nd,
        profile: grade2Admin,
      );
      expect(
        redirectFor(session: gradeSession, location: AppRoutes.loginPath),
        AppRoutes.gradeMakhdomeen('2nd'),
      );

      // 3. Normal Servant
      final servantSession = SessionState(
        status: SessionStatus.active,
        userId: 'servant-1',
        role: UserRole.servant,
        grade: AppConstants.grade1st,
        profile: servant,
      );
      expect(
        redirectFor(session: servantSession, location: AppRoutes.loginPath),
        AppRoutes.myMakhdomeenPath,
      );
    });

    test('accessing forbidden grade redirects to /forbidden', () {
      final grade2Session = SessionState(
        status: SessionStatus.active,
        userId: 'grade2-admin',
        role: UserRole.gradeAdmin,
        grade: AppConstants.grade2nd,
        profile: grade2Admin,
      );
      expect(
        redirectFor(
          session: grade2Session,
          location: AppRoutes.gradeMakhdomeen('1st'),
        ),
        AppRoutes.forbiddenPath,
      );
    });

    test('servant accessing stage routes redirects to /forbidden', () {
      final servantSession = SessionState(
        status: SessionStatus.active,
        userId: 'servant-1',
        role: UserRole.servant,
        grade: AppConstants.grade1st,
        profile: servant,
      );
      expect(
        redirectFor(
          session: servantSession,
          location: AppRoutes.stagePeoplePath,
        ),
        AppRoutes.forbiddenPath,
      );
    });

    test('malformed or invalid route path redirects to /not-found', () {
      final stageSession = SessionState(
        status: SessionStatus.active,
        userId: 'admin-1',
        role: UserRole.stageAdmin,
        profile: stageAdmin,
      );
      expect(
        redirectFor(
          session: stageSession,
          location: '/grades/non-existent-grade/makhdomeen',
        ),
        AppRoutes.notFoundPath,
      );
    });

    test(
      'active servant can access intended permitted detail routes without redirect',
      () {
        final servantSession = SessionState(
          status: SessionStatus.active,
          userId: 'servant-1',
          role: UserRole.servant,
          grade: AppConstants.grade1st,
          profile: servant,
        );
        expect(
          redirectFor(
            session: servantSession,
            location: AppRoutes.makhdomHistory('mak-100'),
          ),
          isNull,
        );
        expect(
          redirectFor(
            session: servantSession,
            location: AppRoutes.taskDetails('task-200'),
          ),
          isNull,
        );
      },
    );

    test('queued notification intent is consumed on active readiness', () {
      final servantSession = SessionState(
        status: SessionStatus.active,
        userId: 'servant-1',
        role: UserRole.servant,
        grade: AppConstants.grade1st,
        profile: servant,
      );

      coordinator.enqueue(
        const NotificationIntent(type: 'attendance', taskId: 'task-789'),
      );

      expect(
        redirectFor(session: servantSession, location: AppRoutes.loginPath),
        AppRoutes.taskAttendance('task-789'),
      );
    });

    test(
      'intended route is saved on unauthenticated access and restored upon login',
      () {
        intents = RouterIntentState();

        // 1. Unauthenticated user attempts to access task details
        final redirectUnauth = redirectFor(
          session: const SessionState.signedOut(),
          location: AppRoutes.taskDetails('task-special-1'),
        );
        expect(redirectUnauth, AppRoutes.loginPath);
        expect(intents.intendedRoute, AppRoutes.taskDetails('task-special-1'));

        // 2. User logs in and becomes active servant
        final servantSession = SessionState(
          status: SessionStatus.active,
          userId: 'servant-1',
          role: UserRole.servant,
          grade: AppConstants.grade1st,
          profile: servant,
        );

        final redirectAuth = redirectFor(
          session: servantSession,
          location: AppRoutes.loginPath,
        );

        // Should redirect to the intended route!
        expect(redirectAuth, AppRoutes.taskDetails('task-special-1'));
        // Intended route must be cleared
        expect(intents.intendedRoute, isNull);
      },
    );

    test('gradeAdmin for 3rd grade lands on /grades/3rd/makhdomeen', () {
      final grade3Admin = KhademModel(
        id: 'grade3-admin',
        name: 'Grade 3 Head',
        email: 'g3@efteqad.com',
        phone: '01000000003',
        role: AppConstants.roleGradeAdmin,
        grade: AppConstants.grade3rd,
        createdAt: DateTime.now(),
      );

      final grade3Session = SessionState(
        status: SessionStatus.active,
        userId: 'grade3-admin',
        role: UserRole.gradeAdmin,
        grade: AppConstants.grade3rd,
        profile: grade3Admin,
      );

      expect(
        redirectFor(session: grade3Session, location: AppRoutes.loginPath),
        AppRoutes.gradeMakhdomeen('3rd'),
      );
    });

    test('createAppRouter initializes without crashing', () {
      final cubit = MockSessionCubit(const SessionState.signedOut());
      final router = createAppRouter(
        sessionCubit: cubit,
        routeAccessService: routeAccess,
        notificationIntentCoordinator: coordinator,
      );

      expect(router, isNotNull);
      expect(router.configuration.routes.isNotEmpty, isTrue);
    });
  });
}

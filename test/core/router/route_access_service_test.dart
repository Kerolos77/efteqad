import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/router/app_routes.dart';
import 'package:efteqad/core/router/route_access_service.dart';
import 'package:efteqad/core/session/session_state.dart';

void main() {
  group('RouteAccessService Unit Tests', () {
    const service = RouteAccessService();

    final stageAdminSession = SessionState(
      status: SessionStatus.active,
      userId: 'stage-admin-1',
      role: UserRole.stageAdmin,
      profile: KhademModel(
        id: 'stage-admin-1',
        name: 'Stage Admin',
        email: 'stage@efteqad.com',
        phone: '01000000000',
        role: AppConstants.roleStageAdmin,
        createdAt: DateTime.now(),
      ),
    );

    final grade1AdminSession = SessionState(
      status: SessionStatus.active,
      userId: 'grade-1-admin',
      role: UserRole.gradeAdmin,
      grade: AppConstants.grade1st,
      profile: KhademModel(
        id: 'grade-1-admin',
        name: 'Grade 1 Head',
        email: 'grade1@efteqad.com',
        phone: '01000000001',
        role: AppConstants.roleGradeAdmin,
        grade: AppConstants.grade1st,
        createdAt: DateTime.now(),
      ),
    );

    final servantSession = SessionState(
      status: SessionStatus.active,
      userId: 'servant-1',
      role: UserRole.servant,
      grade: AppConstants.grade2nd,
      profile: KhademModel(
        id: 'servant-1',
        name: 'Servant',
        email: 'servant@efteqad.com',
        phone: '01000000002',
        role: AppConstants.roleServant,
        grade: AppConstants.grade2nd,
        createdAt: DateTime.now(),
      ),
    );

    final pendingSession = SessionState(
      status: SessionStatus.pending,
      userId: 'pending-user',
      role: UserRole.pending,
      profile: KhademModel(
        id: 'pending-user',
        name: 'New Servant',
        email: 'pending@efteqad.com',
        phone: '01000000003',
        role: AppConstants.rolePending,
        createdAt: DateTime.now(),
      ),
    );

    const signedOutSession = SessionState.signedOut();
    const bootingSession = SessionState.booting();

    test('public and utility routes are allowed appropriately', () {
      expect(
        service.check(Uri.parse(AppRoutes.bootstrapPath), signedOutSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.loginPath), signedOutSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.settingsPath), signedOutSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.forbiddenPath), signedOutSession),
        RouteAccessResult.allowed,
      );
    });

    test('signedOut and booting sessions cannot access authenticated resources', () {
      expect(
        service.check(Uri.parse(AppRoutes.stagePeoplePath), signedOutSession),
        RouteAccessResult.denied,
      );
      expect(
        service.check(Uri.parse(AppRoutes.myMakhdomeenPath), signedOutSession),
        RouteAccessResult.denied,
      );
      expect(
        service.check(Uri.parse(AppRoutes.stagePeoplePath), bootingSession),
        RouteAccessResult.denied,
      );
    });

    test('pending session can only access pending, settings, and profile', () {
      expect(
        service.check(Uri.parse(AppRoutes.pendingPath), pendingSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.profilePath), pendingSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.settingsPath), pendingSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.myMakhdomeenPath), pendingSession),
        RouteAccessResult.denied,
      );
      expect(
        service.check(Uri.parse(AppRoutes.stagePeoplePath), pendingSession),
        RouteAccessResult.denied,
      );
    });

    test('stageAdmin has access to stage, all grades, and servant routes', () {
      expect(
        service.check(Uri.parse(AppRoutes.stagePeoplePath), stageAdminSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.stageAnalyticsPath), stageAdminSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('1st')), stageAdminSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('2nd')), stageAdminSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('3rd')), stageAdminSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.myMakhdomeenPath), stageAdminSession),
        RouteAccessResult.allowed,
      );
    });

    test('gradeAdmin can only access their designated grade, denied cross-grade or stage', () {
      // Allowed for own grade (1st)
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('1st')), grade1AdminSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.gradeAnalytics('1st')), grade1AdminSession),
        RouteAccessResult.allowed,
      );

      // Denied cross-grade (2nd, 3rd)
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('2nd')), grade1AdminSession),
        RouteAccessResult.denied,
      );
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('3rd')), grade1AdminSession),
        RouteAccessResult.denied,
      );

      // Denied stage
      expect(
        service.check(Uri.parse(AppRoutes.stagePeoplePath), grade1AdminSession),
        RouteAccessResult.denied,
      );
    });

    test('servant is denied access to stage and grade routes, allowed me routes', () {
      expect(
        service.check(Uri.parse(AppRoutes.stagePeoplePath), servantSession),
        RouteAccessResult.denied,
      );
      expect(
        service.check(Uri.parse(AppRoutes.gradeMakhdomeen('2nd')), servantSession),
        RouteAccessResult.denied,
      );
      expect(
        service.check(Uri.parse(AppRoutes.myMakhdomeenPath), servantSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.myTasksPath), servantSession),
        RouteAccessResult.allowed,
      );
    });

    test('returns notFound for invalid grade or malformed resource routes', () {
      // Invalid grade 4th
      expect(
        service.check(Uri.parse('/grades/4th/makhdomeen'), stageAdminSession),
        RouteAccessResult.notFound,
      );
      // Empty ID
      expect(
        service.check(Uri.parse('/makhdomeen/:makhdomId/history'), stageAdminSession),
        RouteAccessResult.notFound,
      );
      expect(
        service.check(Uri.parse('/tasks/:taskId'), stageAdminSession),
        RouteAccessResult.notFound,
      );
      // Nonexistent route
      expect(
        service.check(Uri.parse('/random/unknown/path'), stageAdminSession),
        RouteAccessResult.notFound,
      );
    });

    test('valid resource IDs are allowed for authenticated active users', () {
      expect(
        service.check(Uri.parse(AppRoutes.makhdomHistory('student-123')), servantSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.taskDetails('task-456')), servantSession),
        RouteAccessResult.allowed,
      );
      expect(
        service.check(Uri.parse(AppRoutes.taskAttendance('task-456')), servantSession),
        RouteAccessResult.allowed,
      );
    });
  });
}

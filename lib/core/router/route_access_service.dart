import '../constants/constants.dart';
import '../models/makhdom_model.dart';
import '../models/task_model.dart';
import '../errors/app_failure.dart';
import '../session/session_state.dart';
import 'app_routes.dart';
import 'route_resource_loader.dart';

enum RouteAccessResult { allowed, denied, notFound }

class RouteAccessService {
  const RouteAccessService();

  static bool isSafeInternalUri(Uri uri) =>
      !uri.hasScheme &&
      !uri.hasAuthority &&
      uri.path.startsWith('/') &&
      !uri.path.startsWith('//') &&
      !uri.path.contains('\\') &&
      !uri.pathSegments.any(
        (part) =>
            part == '..' ||
            part == '.' ||
            part.contains('/') ||
            part.contains('\\'),
      );

  Future<MakhdomModel?> loadChild(
    RouteResourceLoader loader,
    String id,
    SessionState Function() session,
  ) async {
    final child = await loader.loadChild(id);
    if (child != null) authorizeChild(child, session());
    return child;
  }

  Future<TaskModel?> loadTask(
    RouteResourceLoader loader,
    String id,
    SessionState Function() session, {
    bool attendance = false,
  }) async {
    final task = await loader.loadTask(id);
    if (task != null) authorizeTask(task, session(), attendance: attendance);
    return task;
  }

  void authorizeChild(MakhdomModel child, SessionState session) {
    if (!child.active) throw AppFailure.notFound();
    if (!session.isActive ||
        !(session.isStageAdmin ||
            (session.isGradeAdmin && child.grade == session.grade) ||
            (session.isServant &&
                child.grade == session.grade &&
                child.assignedKhademId == session.userId))) {
      throw AppFailure.permissionDenied();
    }
  }

  void authorizeTask(
    TaskModel task,
    SessionState session, {
    bool attendance = false,
  }) {
    final canReopen =
        session.isActive &&
        task.isAttendanceTask &&
        (session.isStageAdmin ||
            (session.isGradeAdmin && task.grade == session.grade));
    if (task.status != 'active' && !(task.status == 'completed' && canReopen)) {
      throw AppFailure.notFound();
    }
    if (!session.isActive ||
        !(session.isStageAdmin ||
            (session.isGradeAdmin && task.grade == session.grade) ||
            (session.isServant &&
                task.assignedKhademId == session.userId &&
                (task.grade == session.grade ||
                    (task.grade == 'all' && task.isMassAttendance))))) {
      throw AppFailure.permissionDenied();
    }
    if (attendance &&
        (!{'attendance_khedma', 'attendance_qoddas'}.contains(task.type) ||
            task.dueDate == null ||
            (task.isCompleted && !canReopen))) {
      throw AppFailure.notFound();
    }
  }

  static const Set<String> validGrades = {
    AppConstants.grade1st,
    AppConstants.grade2nd,
    AppConstants.grade3rd,
  };

  RouteAccessResult check(Uri uri, SessionState session) {
    if (!isSafeInternalUri(uri)) return RouteAccessResult.notFound;
    final path = uri.path;

    // 1. Root / Bootstrap / Login / Settings / Forbidden
    if (path == AppRoutes.bootstrapPath || path == '/' || path.isEmpty) {
      return RouteAccessResult.allowed;
    }

    if (path == AppRoutes.forbiddenPath || path == AppRoutes.notFoundPath) {
      return RouteAccessResult.allowed;
    }

    if (path == AppRoutes.settingsPath) {
      return RouteAccessResult.allowed;
    }

    if (path == AppRoutes.loginPath) {
      return RouteAccessResult.allowed;
    }

    // 2. Unauthenticated guards
    if (session.status == SessionStatus.booting ||
        session.status == SessionStatus.profileLoading) {
      return RouteAccessResult.denied;
    }

    if (session.status == SessionStatus.signedOut || !session.isAuthenticated) {
      return RouteAccessResult.denied;
    }

    // 3. Pending user guards
    if (session.status == SessionStatus.pending || session.isPending) {
      if (path == AppRoutes.pendingPath ||
          path == AppRoutes.profilePath ||
          path == AppRoutes.settingsPath) {
        return RouteAccessResult.allowed;
      }
      return RouteAccessResult.denied;
    }

    // 4. Active user routes
    if (!session.isActive) {
      return RouteAccessResult.denied;
    }

    // Notifications and Profile
    if (path == AppRoutes.notificationsPath || path == AppRoutes.profilePath) {
      return RouteAccessResult.allowed;
    }

    // Stage routes
    if (path.startsWith('/stage/')) {
      if (!session.isStageAdmin) {
        return RouteAccessResult.denied;
      }
      if (path == AppRoutes.stagePeoplePath ||
          path == AppRoutes.stageAnalyticsPath ||
          path == AppRoutes.stageTasksPath) {
        return RouteAccessResult.allowed;
      }
      return RouteAccessResult.notFound;
    }

    // Grade routes: /grades/:grade/...
    if (path.startsWith('/grades/')) {
      final segments = uri.pathSegments; // ['grades', grade, tab]
      if (segments.length != 3) {
        return RouteAccessResult.notFound;
      }
      final grade = segments[1];
      if (!validGrades.contains(grade)) {
        return RouteAccessResult.notFound;
      }

      // Check role authorization for grade
      if (session.isStageAdmin) {
        // Stage admin can access any grade
      } else if (session.isGradeAdmin) {
        if (session.grade != grade) {
          return RouteAccessResult.denied;
        }
      } else {
        // Normal servant cannot access whole grade views
        return RouteAccessResult.denied;
      }

      final subPath = segments[2];
      if (subPath == 'makhdomeen' ||
          subPath == 'analytics' ||
          subPath == 'khodam' ||
          subPath == 'tasks') {
        return RouteAccessResult.allowed;
      }
      return RouteAccessResult.notFound;
    }

    // Servant / Me routes
    if (path.startsWith('/me/')) {
      if (path == AppRoutes.myMakhdomeenPath ||
          path == AppRoutes.myTasksPath ||
          path == AppRoutes.myAnalyticsPath) {
        return RouteAccessResult.allowed;
      }
      return RouteAccessResult.notFound;
    }

    // Makhdom History route: /makhdomeen/:makhdomId/history
    if (path.startsWith('/makhdomeen/')) {
      final segments = uri.pathSegments;
      if (segments.length == 3 &&
          segments[0] == 'makhdomeen' &&
          segments[2] == 'history') {
        final makhdomId = segments[1];
        if (makhdomId.isEmpty || makhdomId == ':makhdomId') {
          return RouteAccessResult.notFound;
        }
        return RouteAccessResult.allowed;
      }
      return RouteAccessResult.notFound;
    }

    // Tasks details / attendance: /tasks/:taskId and /tasks/:taskId/attendance
    if (path.startsWith('/tasks/')) {
      final segments = uri.pathSegments;
      if (segments.length == 2 && segments[0] == 'tasks') {
        final taskId = segments[1];
        if (taskId.isEmpty || taskId == ':taskId') {
          return RouteAccessResult.notFound;
        }
        return RouteAccessResult.allowed;
      }
      if (segments.length == 3 &&
          segments[0] == 'tasks' &&
          segments[2] == 'attendance') {
        final taskId = segments[1];
        if (taskId.isEmpty || taskId == ':taskId') {
          return RouteAccessResult.notFound;
        }
        return RouteAccessResult.allowed;
      }
      return RouteAccessResult.notFound;
    }

    return RouteAccessResult.notFound;
  }
}

import 'package:flutter/foundation.dart';
import '../session/session_state.dart';
import 'app_routes.dart';
import 'route_access_service.dart';

class NotificationIntent {
  final String type;
  final String? taskId;
  final String? makhdomId;
  final String? grade;
  final Map<String, dynamic> rawPayload;

  const NotificationIntent({
    required this.type,
    this.taskId,
    this.makhdomId,
    this.grade,
    this.rawPayload = const {},
  });

  factory NotificationIntent.fromPayload(Map<String, dynamic> payload) {
    final type = (payload['type'] ?? payload['notificationType'] ?? '')
        .toString();
    final taskId = payload['taskId']?.toString();
    final makhdomId = payload['makhdomId']?.toString();
    final grade = payload['grade']?.toString();

    return NotificationIntent(
      type: type,
      taskId: taskId != null && taskId.isNotEmpty ? taskId : null,
      makhdomId: makhdomId != null && makhdomId.isNotEmpty ? makhdomId : null,
      grade: grade != null && grade.isNotEmpty ? grade : null,
      rawPayload: payload,
    );
  }

  static bool _isValidId(String? id) =>
      id != null &&
      id.isNotEmpty &&
      !id.contains('..') &&
      !RegExp(r'[/?#\\:%\x00-\x20]').hasMatch(id);

  String? toRoutePath() {
    switch (type) {
      case 'attendance':
      case 'attendance_khedma':
      case 'attendance_qoddas':
      case 'taskAttendance':
      case 'task_attendance':
        if (_isValidId(taskId)) return AppRoutes.taskAttendance(taskId!);
        break;
      case 'task':
      case 'general':
      case 'visitation':
      case 'taskDetails':
      case 'task_details':
        if (_isValidId(taskId)) return AppRoutes.taskDetails(taskId!);
        break;
      case 'makhdomHistory':
      case 'makhdom_history':
      case 'history':
      case 'visit':
      case 'absence':
      case 'absenceAlert':
      case 'absence_alert':
        if (_isValidId(makhdomId)) return AppRoutes.makhdomHistory(makhdomId!);
        break;
      case 'notifications':
        return AppRoutes.notificationsPath;
      default:
        // Do not allow arbitrary route from payload
        return null;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationIntent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          taskId == other.taskId &&
          makhdomId == other.makhdomId &&
          grade == other.grade;

  @override
  int get hashCode =>
      type.hashCode ^ taskId.hashCode ^ makhdomId.hashCode ^ grade.hashCode;
}

class NotificationIntentCoordinator extends ChangeNotifier {
  final RouteAccessService routeAccessService;
  NotificationIntent? _pendingIntent;
  String? _owner;
  String? _scope;
  bool _ready = false;
  bool _dispatched = false;
  void observe(SessionState session) {
    if ((_owner != null &&
            (session.status == SessionStatus.signedOut ||
                session.isDeleting)) ||
        (_ready &&
            (session.status == SessionStatus.signedOut ||
                session.isDeleting ||
                (session.isActive && _scope != session.scopeKey)))) {
      _pendingIntent = null;
      _dispatched = false;
    }
    if (_owner != null && session.userId != null && _owner != session.userId) {
      _pendingIntent = null;
      _dispatched = false;
    }
    _owner = session.userId;
    if (session.status == SessionStatus.signedOut) {
      _ready = false;
      _scope = null;
    }
    if (session.isActive) {
      _ready = true;
      _scope = session.scopeKey;
    }
  }

  NotificationIntentCoordinator({
    this.routeAccessService = const RouteAccessService(),
  });

  NotificationIntent? get pendingIntent => _pendingIntent;

  void enqueue(NotificationIntent intent) {
    _pendingIntent = intent;
    _dispatched = false;
    notifyListeners();
  }

  void clear() {
    _pendingIntent = null;
    _dispatched = false;
    notifyListeners();
  }

  /// Resource intents leave the queue only when the authoritative lookup finishes.
  void completeVerified(String target, SessionState session) {
    if (!session.isActive ||
        _owner != session.userId ||
        _scope != session.scopeKey ||
        _pendingIntent?.toRoutePath() != target) {
      return;
    }
    _pendingIntent = null;
    _dispatched = false;
    notifyListeners();
  }

  String? consumeFor(SessionState session) {
    observe(session);
    final intent = _pendingIntent;
    if (intent == null || _dispatched) return null;

    if (!session.isActive) {
      // Keep pending until active session is ready
      return null;
    }

    final targetPath = intent.toRoutePath();
    if (targetPath == null) {
      _pendingIntent = null;
      _dispatched = false;
      return null;
    }

    final access = routeAccessService.check(Uri.parse(targetPath), session);
    if (access != RouteAccessResult.allowed ||
        targetPath == AppRoutes.notificationsPath) {
      _pendingIntent = null;
      _dispatched = false;
    }

    if (access == RouteAccessResult.allowed) {
      // Dispatch once; a retained lookup receipt must not capture later navigation.
      _dispatched = true;
      return targetPath;
    }
    return access == RouteAccessResult.denied
        ? AppRoutes.forbiddenPath
        : AppRoutes.notFoundPath;
  }
}

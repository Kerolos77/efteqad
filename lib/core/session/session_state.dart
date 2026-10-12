import '../models/khadem_model.dart';

enum SessionStatus {
  booting,
  signedOut,
  profileLoading,
  pending,
  active,
  deleting,
  failure,
}

enum UserRole {
  stageAdmin,
  gradeAdmin,
  servant,
  pending;

  static UserRole fromString(String? role) {
    switch (role) {
      case 'stageAdmin':
        return UserRole.stageAdmin;
      case 'gradeAdmin':
        return UserRole.gradeAdmin;
      case 'servant':
        return UserRole.servant;
      case 'pending':
      default:
        return UserRole.pending;
    }
  }

  String get asString {
    switch (this) {
      case UserRole.stageAdmin:
        return 'stageAdmin';
      case UserRole.gradeAdmin:
        return 'gradeAdmin';
      case UserRole.servant:
        return 'servant';
      case UserRole.pending:
        return 'pending';
    }
  }
}

class SessionState {
  final SessionStatus status;
  final String? userId;
  final UserRole? role;
  final String? grade;
  final KhademModel? profile;
  final Object? failure;

  const SessionState({
    required this.status,
    this.userId,
    this.role,
    this.grade,
    this.profile,
    this.failure,
  });

  const SessionState.booting()
    : status = SessionStatus.booting,
      userId = null,
      role = null,
      grade = null,
      profile = null,
      failure = null;

  const SessionState.signedOut()
    : status = SessionStatus.signedOut,
      userId = null,
      role = null,
      grade = null,
      profile = null,
      failure = null;

  const SessionState.profileLoading({required this.userId})
    : status = SessionStatus.profileLoading,
      role = null,
      grade = null,
      profile = null,
      failure = null;

  const SessionState.failure({this.userId, required this.failure})
    : status = SessionStatus.failure,
      role = null,
      grade = null,
      profile = null;

  String get scopeKey => '$userId/${role?.asString}/$grade/$status';

  bool get isAuthenticated =>
      userId != null &&
      status != SessionStatus.signedOut &&
      status != SessionStatus.booting;
  bool get isActive => status == SessionStatus.active;
  bool get isPending => status == SessionStatus.pending;
  bool get isDeleting => status == SessionStatus.deleting;
  bool get isStageAdmin => role == UserRole.stageAdmin;
  bool get isGradeAdmin => role == UserRole.gradeAdmin;
  bool get isServant => role == UserRole.servant;

  SessionState copyWith({
    SessionStatus? status,
    String? userId,
    UserRole? role,
    String? grade,
    KhademModel? profile,
    Object? failure,
  }) {
    return SessionState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      profile: profile ?? this.profile,
      failure: failure ?? this.failure,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          userId == other.userId &&
          role == other.role &&
          grade == other.grade &&
          profile == other.profile &&
          failure == other.failure;

  @override
  int get hashCode =>
      status.hashCode ^
      userId.hashCode ^
      role.hashCode ^
      grade.hashCode ^
      profile.hashCode ^
      failure.hashCode;

  @override
  String toString() {
    return 'SessionState(status: $status, userId: $userId, role: $role, grade: $grade, failure: $failure)';
  }
}

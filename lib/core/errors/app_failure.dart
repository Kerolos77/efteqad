import 'package:cloud_functions/cloud_functions.dart';
import '../localization/app_localizations.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a standardized application failure across network, database,
/// permissions, decoding, and auth layers.
class AppFailure implements Exception {
  final String code;
  final String message;
  final bool retryable;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppFailure({
    required this.code,
    required this.message,
    this.retryable = false,
    this.cause,
    this.stackTrace,
  });

  /// Factory for permission-denied errors (not retryable).
  factory AppFailure.permissionDenied({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: 'permission-denied',
      message: message ?? 'Application diagnostic',
      retryable: false,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory for network/connectivity errors (retryable).
  factory AppFailure.network({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: 'network-error',
      message: message ?? 'Application diagnostic',
      retryable: true,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory for resource not-found errors (not retryable).
  factory AppFailure.notFound({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: 'not-found',
      message: message ?? 'Application diagnostic',
      retryable: false,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Factory for schema or JSON/Map decode errors (not retryable).
  factory AppFailure.decode({
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: 'decode-error',
      message: message ?? 'Application diagnostic',
      retryable: false,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Universal mapping factory for any caught exception or error.
  factory AppFailure.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    if (error is FirebaseFunctionsException &&
        error.details is Map &&
        (error.details as Map)['reason'] == 'STAGE_ADMIN_REQUIRES_SUCCESSOR') {
      return AppFailure(
        code: 'stage-admin-requires-successor',
        message: 'Active successor required.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return AppFailure.permissionDenied(
            message: 'Application diagnostic',
            cause: error,
            stackTrace: stackTrace,
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return AppFailure.network(
            message: 'Application diagnostic',
            cause: error,
            stackTrace: stackTrace,
          );
        case 'not-found':
          return AppFailure.notFound(cause: error, stackTrace: stackTrace);
        case 'unauthenticated':
          return AppFailure(
            code: 'unauthenticated',
            message: 'Application diagnostic',
            retryable: false,
            cause: error,
            stackTrace: stackTrace,
          );
        default:
          return AppFailure(
            code: error.code,
            message: error.message ?? 'Application diagnostic',
            retryable: true,
            cause: error,
            stackTrace: stackTrace,
          );
      }
    }

    if (error is SocketException) {
      return AppFailure.network(
        message: 'Application diagnostic',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException || error is TypeError) {
      return AppFailure.decode(
        message: 'Application diagnostic',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppFailure(
      code: 'unknown',
      message: error.toString(),
      retryable: true,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  String localizedMessage(GeneratedAppLocalizations tr) {
    final normalized = code.toLowerCase();
    if (normalized == 'excel-empty') return tr.excelEmptyFailure;
    if (normalized == 'excel-columns') return tr.excelColumnsFailure;
    if (normalized == 'excel-unreadable') return tr.excelReadFailure;
    if (normalized == 'attendance-finalized') {
      return tr.attendanceFinalizedFailure;
    }
    if (normalized == 'pending-saves') return tr.pendingSavesFailure;
    if (normalized == 'permission-denied') return tr.failurePermissionDenied;
    if (normalized == 'network-error' ||
        normalized == 'unavailable' ||
        normalized == 'deadline-exceeded') {
      return tr.failureNetwork;
    }
    if (normalized == 'not-found') return tr.failureNotFound;
    if (normalized == 'decode-error') return tr.failureDecode;
    if ({
      'invalid-credential',
      'wrong-password',
      'invalid-email',
    }.contains(normalized)) {
      return tr.loginFailedCheckCredentials;
    }
    if (normalized == 'unauthenticated' ||
        normalized == 'requires-recent-login') {
      return tr.failureAuthentication;
    }
    if (normalized == 'stage-admin-requires-successor') {
      return tr.stageSuccessorRequired;
    }
    return tr.dataUnavailable;
  }

  @override
  String toString() =>
      'AppFailure(code: $code, message: $message, retryable: $retryable)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          retryable == other.retryable;

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ retryable.hashCode;
}

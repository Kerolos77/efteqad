import 'dart:io';
import 'package:flutter/material.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/errors/app_failure.dart';

void main() {
  group('AppFailure Unit Tests (Task 13)', () {
    test('permission-denied failure is not retryable and preserves cause', () {
      final failure = AppFailure.permissionDenied();
      expect(failure.code, 'permission-denied');
      expect(failure.retryable, isFalse);
      expect(
        failure.localizedMessage(
          lookupGeneratedAppLocalizations(const Locale('ar')),
        ),
        contains('صلاحية'),
      );
      expect(
        failure.localizedMessage(
          lookupGeneratedAppLocalizations(const Locale('en')),
        ),
        contains('permission'),
      );
    });

    test('network failure is retryable', () {
      final failure = AppFailure.network();
      expect(failure.code, 'network-error');
      expect(failure.retryable, isTrue);
    });

    test('not-found failure is not retryable', () {
      final failure = AppFailure.notFound();
      expect(failure.code, 'not-found');
      expect(failure.retryable, isFalse);
    });

    test('decode failure is not retryable', () {
      final failure = AppFailure.decode();
      expect(failure.code, 'decode-error');
      expect(failure.retryable, isFalse);
    });

    test('maps FirebaseException permission-denied correctly', () {
      final fbException = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      final failure = AppFailure.fromException(fbException);
      expect(failure.code, 'permission-denied');
      expect(failure.retryable, isFalse);
      expect(failure.cause, fbException);
    });

    test(
      'maps FirebaseException unavailable/timeout to retryable network error',
      () {
        final fbException = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
          message: 'The service is currently unavailable.',
        );

        final failure = AppFailure.fromException(fbException);
        expect(failure.code, 'network-error');
        expect(failure.retryable, isTrue);
      },
    );

    test('maps SocketException to retryable network error', () {
      const socketException = SocketException('Failed host lookup');
      final failure = AppFailure.fromException(socketException);
      expect(failure.code, 'network-error');
      expect(failure.retryable, isTrue);
    });

    test('maps FormatException and TypeError to decode error', () {
      const formatException = FormatException('Invalid JSON');
      final failure = AppFailure.fromException(formatException);
      expect(failure.code, 'decode-error');
      expect(failure.retryable, isFalse);
    });

    test('equality and hashCode work as expected', () {
      const f1 = AppFailure(code: 'test', message: 'msg', retryable: true);
      const f2 = AppFailure(code: 'test', message: 'msg', retryable: true);
      const f3 = AppFailure(code: 'test2', message: 'msg', retryable: false);

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1, isNot(equals(f3)));
    });
  });
}

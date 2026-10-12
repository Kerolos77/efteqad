import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import 'package:firebase_core/firebase_core.dart';

class MockDeviceRegistrationStore implements DeviceRegistrationStore {
  final Map<String, Map<String, dynamic>> registeredDevices = {};
  final List<String> registrations = [];
  final List<String> unregistrations = [];
  bool failCleanup = false;

  @override
  Future<void> registerDevice({
    required String uid,
    required String installationId,
    required String token,
    required String locale,
  }) async {
    registrations.add(uid);
    registeredDevices['$uid/$installationId'] = {
      'uid': uid,
      'installationId': installationId,
      'token': token,
      'locale': locale,
    };
  }

  @override
  Future<void> unregisterDevice({
    required String uid,
    required String installationId,
  }) async {
    if (failCleanup) throw StateError('offline cleanup');
    unregistrations.add(uid);
    registeredDevices.remove('$uid/$installationId');
  }

  @override
  Future<Map<String, dynamic>?> getDevice({
    required String uid,
    required String installationId,
  }) async {
    return registeredDevices['$uid/$installationId'];
  }
}

class AuthRestrictedDeviceStore extends MockDeviceRegistrationStore {
  final String? Function() authenticatedUid;
  AuthRestrictedDeviceStore(this.authenticatedUid);
  @override
  Future<void> unregisterDevice({
    required String uid,
    required String installationId,
  }) async {
    if (authenticatedUid() != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    await super.unregisterDevice(uid: uid, installationId: installationId);
  }

  @override
  Future<void> registerDevice({
    required String uid,
    required String installationId,
    required String token,
    required String locale,
  }) async {
    if (authenticatedUid() != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    await super.registerDevice(
      uid: uid,
      installationId: installationId,
      token: token,
      locale: locale,
    );
  }
}

class InstallationTokenBoundary {
  final validTokens = <String>{};
  String? currentToken;
  int _issued = 0;
  Future<String?> getToken() async {
    currentToken ??= 'token_${++_issued}';
    validTokens.add(currentToken!);
    return currentToken;
  }

  Future<void> deleteToken() async {
    validTokens.remove(currentToken);
    currentToken = null;
  }
}

void main() {
  test(
    'auth-denied unregister invalidates local token and gates replacement until retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      String? sdkUid = 'a';
      final store = AuthRestrictedDeviceStore(() => sdkUid);
      final fcm = InstallationTokenBoundary();
      final refresh = StreamController<String>.broadcast();
      final devices = DeviceRegistrationService(
        store: store,
        tokenGetter: fcm.getToken,
        tokenDeleter: fcm.deleteToken,
        tokenRefreshStream: refresh.stream,
      );
      await devices.bindUser('a');
      final prefs = await SharedPreferences.getInstance();
      final installation = await devices.getInstallationId();
      final oldToken =
          store.registeredDevices['a/$installation']!['token'] as String;
      sdkUid = null;
      await expectLater(
        devices.unbindUser(),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      expect(fcm.validTokens, isNot(contains(oldToken)));
      expect(store.registeredDevices['a/$installation']?['token'], oldToken);
      expect(prefs.getString('device_pending_cleanup_uid'), 'a');
      expect(prefs.getString('device_bound_uid'), 'a');
      sdkUid = 'b';
      await expectLater(
        devices.bindUser('b'),
        throwsA(isA<FirebaseException>()),
      );
      expect(store.registeredDevices.keys, ['a/$installation']);
      expect(prefs.getString('device_pending_cleanup_uid'), 'a');
      expect(fcm.validTokens, isEmpty);
      sdkUid = 'a';
      await devices.unbindUser();
      expect(prefs.getString('device_pending_cleanup_uid'), isNull);
      expect(store.registeredDevices, isEmpty);
      sdkUid = 'b';
      await devices.bindUser('b');
      final replacement =
          store.registeredDevices['b/$installation']!['token'] as String;
      expect(replacement, isNot(oldToken));
      expect(fcm.validTokens, {replacement});
      await devices.dispose();
      await refresh.close();
    },
  );
  test(
    'queued obsolete owner cannot clean up the retained replacement',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = MockDeviceRegistrationStore();
      final refresh = StreamController<String>.broadcast();
      var rotations = 0;
      final devices = DeviceRegistrationService(
        store: store,
        tokenGetter: () async => 'token',
        tokenDeleter: () async {
          rotations++;
        },
        tokenRefreshStream: refresh.stream,
      );
      await devices.bindUser('b');
      final obsolete = devices.bindUser('a');
      final latest = devices.bindUser('b', locale: 'en');
      await Future.wait([obsolete, latest]);
      expect(store.unregistrations, isEmpty);
      expect(rotations, 0);
      expect(store.registrations, ['b', 'b']);
      expect(store.registeredDevices.values.single['locale'], 'en');
      await devices.dispose();
      await refresh.close();
    },
  );
  test(
    'superseded token lookup cannot register stale owner or erase latest binding',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = MockDeviceRegistrationStore();
      final refresh = StreamController<String>.broadcast();
      final token = Completer<String?>(), started = Completer<void>();
      var calls = 0;
      final devices = DeviceRegistrationService(
        store: store,
        tokenGetter: () {
          if (++calls == 1) {
            started.complete();
            return token.future;
          }
          return Future.value('latest');
        },
        tokenDeleter: () async {},
        tokenRefreshStream: refresh.stream,
      );
      final older = devices.bindUser('a');
      await started.future;
      final newer = devices.bindUser('b', locale: 'en');
      token.complete('stale');
      await Future.wait([older, newer]);
      expect(store.registeredDevices.values.single['uid'], 'b');
      expect(store.registeredDevices.values.single['token'], 'latest');
      expect(store.registrations, ['b']);
      await devices.dispose();
      await refresh.close();
    },
  );
  group('DeviceRegistrationService Unit Tests', () {
    late MockDeviceRegistrationStore store;
    late StreamController<String> refreshController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = MockDeviceRegistrationStore();
      refreshController = StreamController<String>.broadcast();
    });

    tearDown(() {
      refreshController.close();
    });

    test(
      'cleanup failure persists old owner and blocks cross-account binding',
      () async {
        final service = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          tokenGetter: () async => 'token',
          tokenRefreshStream: refreshController.stream,
        );
        await service.bindUser('A');
        store.failCleanup = true;
        await expectLater(service.unbindUser(), throwsA(anything));
        await expectLater(service.bindUser('B'), throwsA(anything));
        refreshController.add('later');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(
          store.registeredDevices.keys.any((key) => key.startsWith('B/')),
          false,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('device_pending_cleanup_uid'), 'A');
        store.failCleanup = false;
        await service.bindUser('B');
        expect(
          store.registeredDevices.keys.any((key) => key.startsWith('A/')),
          false,
        );
        await service.unbindUser();
      },
    );

    test(
      'bindUser registers device under khodam/{uid}/devices/{installationId}',
      () async {
        final service = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          tokenGetter: () async => 'token_123',
          tokenRefreshStream: refreshController.stream,
        );

        await service.bindUser('user_A', locale: 'ar');

        final installationId = await service.getInstallationId();
        final device = await store.getDevice(
          uid: 'user_A',
          installationId: installationId,
        );

        expect(device, isNotNull);
        expect(device?['token'], 'token_123');
        expect(device?['locale'], 'ar');
      },
    );

    test(
      'switching user (A -> B) unbinds device from user A before binding to user B',
      () async {
        final service = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          tokenGetter: () async => 'token_common',
          tokenRefreshStream: refreshController.stream,
        );

        await service.bindUser('user_A', locale: 'ar');
        final installationId = await service.getInstallationId();
        expect(
          await store.getDevice(uid: 'user_A', installationId: installationId),
          isNotNull,
        );

        // Now switch user to user_B on same device
        await service.bindUser('user_B', locale: 'en');

        // user_A device must be unregistered
        expect(
          await store.getDevice(uid: 'user_A', installationId: installationId),
          isNull,
        );

        // user_B device must be registered
        final deviceB = await store.getDevice(
          uid: 'user_B',
          installationId: installationId,
        );
        expect(deviceB, isNotNull);
        expect(deviceB?['locale'], 'en');
      },
    );

    test('unbindUser removes device document and clears state', () async {
      final service = DeviceRegistrationService(
        tokenDeleter: () async {},
        store: store,
        tokenGetter: () async => 'token_123',
        tokenRefreshStream: refreshController.stream,
      );

      await service.bindUser('user_A', locale: 'ar');
      final installationId = await service.getInstallationId();
      expect(
        await store.getDevice(uid: 'user_A', installationId: installationId),
        isNotNull,
      );

      await service.unbindUser();

      expect(
        await store.getDevice(uid: 'user_A', installationId: installationId),
        isNull,
      );
    });

    test('token refresh updates current bound user device', () async {
      final service = DeviceRegistrationService(
        tokenDeleter: () async {},
        store: store,
        tokenGetter: () async => 'token_initial',
        tokenRefreshStream: refreshController.stream,
      );

      await service.bindUser('user_A', locale: 'ar');
      final installationId = await service.getInstallationId();

      // Emit new refreshed token
      refreshController.add('token_refreshed');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final device = await store.getDevice(
        uid: 'user_A',
        installationId: installationId,
      );
      expect(device?['token'], 'token_refreshed');
    });

    test('token refresh after unbindUser does not update old user', () async {
      final service = DeviceRegistrationService(
        tokenDeleter: () async {},
        store: store,
        tokenGetter: () async => 'token_initial',
        tokenRefreshStream: refreshController.stream,
      );

      await service.bindUser('user_A', locale: 'ar');
      final installationId = await service.getInstallationId();
      await service.unbindUser();

      // Refresh occurs after logout
      refreshController.add('token_after_logout');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        await store.getDevice(uid: 'user_A', installationId: installationId),
        isNull,
      );
    });

    test(
      'multiple devices can be registered for the same user concurrently',
      () async {
        SharedPreferences.setMockInitialValues({
          'device_installation_id': 'dev_phone',
        });
        final service1 = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          prefsFuture: Future.value(await SharedPreferences.getInstance()),
          tokenGetter: () async => 'token_phone',
          tokenRefreshStream: refreshController.stream,
        );
        await service1.bindUser('user_A', locale: 'ar');

        // Second device (e.g. tablet)
        SharedPreferences.setMockInitialValues({
          'device_installation_id': 'dev_tablet',
        });
        final service2 = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          prefsFuture: Future.value(await SharedPreferences.getInstance()),
          tokenGetter: () async => 'token_tablet',
          tokenRefreshStream: refreshController.stream,
        );
        await service2.bindUser('user_A', locale: 'en');

        final devPhone = await store.getDevice(
          uid: 'user_A',
          installationId: 'dev_phone',
        );
        final devTablet = await store.getDevice(
          uid: 'user_A',
          installationId: 'dev_tablet',
        );

        expect(devPhone?['token'], 'token_phone');
        expect(devPhone?['locale'], 'ar');
        expect(devTablet?['token'], 'token_tablet');
        expect(devTablet?['locale'], 'en');
      },
    );

    test(
      'unbindUser on a new service instance cancels static token refresh listener',
      () async {
        final service1 = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          tokenGetter: () async => 'token_1',
          tokenRefreshStream: refreshController.stream,
        );
        await service1.bindUser('user_A', locale: 'ar');
        final id = await service1.getInstallationId();

        // Another service instance unbinds
        final service2 = DeviceRegistrationService(
          tokenDeleter: () async {},
          store: store,
          tokenGetter: () async => 'token_1',
          tokenRefreshStream: refreshController.stream,
        );
        await service2.unbindUser();

        // Token refresh fires
        refreshController.add('token_after_new_instance_logout');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(
          await store.getDevice(uid: 'user_A', installationId: id),
          isNull,
        );
      },
    );

    test('updating locale re-registers device with updated locale', () async {
      final service = DeviceRegistrationService(
        tokenDeleter: () async {},
        store: store,
        tokenGetter: () async => 'token_123',
        tokenRefreshStream: refreshController.stream,
      );
      await service.bindUser('user_A', locale: 'ar');
      final id = await service.getInstallationId();
      expect(
        (await store.getDevice(uid: 'user_A', installationId: id))?['locale'],
        'ar',
      );

      await service.bindUser('user_A', locale: 'en');
      expect(
        (await store.getDevice(uid: 'user_A', installationId: id))?['locale'],
        'en',
      );
    });
  });
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DeviceRegistrationStore {
  Future<void> registerDevice({
    required String uid,
    required String installationId,
    required String token,
    required String locale,
  });

  Future<void> unregisterDevice({
    required String uid,
    required String installationId,
  });

  Future<Map<String, dynamic>?> getDevice({
    required String uid,
    required String installationId,
  });
}

class FirestoreDeviceRegistrationStore implements DeviceRegistrationStore {
  final FirebaseFirestore _firestore;

  FirestoreDeviceRegistrationStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> registerDevice({
    required String uid,
    required String installationId,
    required String token,
    required String locale,
  }) async {
    await _firestore
        .collection('khodam')
        .doc(uid)
        .collection('devices')
        .doc(installationId)
        .set({
          'token': token,
          'locale': locale,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> unregisterDevice({
    required String uid,
    required String installationId,
  }) async {
    await _firestore
        .collection('khodam')
        .doc(uid)
        .collection('devices')
        .doc(installationId)
        .delete();
  }

  @override
  Future<Map<String, dynamic>?> getDevice({
    required String uid,
    required String installationId,
  }) async {
    final doc = await _firestore
        .collection('khodam')
        .doc(uid)
        .collection('devices')
        .doc(installationId)
        .get();
    return doc.data();
  }
}

class DeviceRegistrationService {
  static DeviceRegistrationService? _shared;
  static DeviceRegistrationService get shared =>
      _shared ??= DeviceRegistrationService();
  final DeviceRegistrationStore _store;
  final Future<SharedPreferences> _prefsFuture;
  final Future<String?> Function() _tokenGetter;
  final Future<void> Function() _tokenDeleter;
  final Stream<String> _tokenRefreshStream;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _currentBoundUid;
  String _locale = 'ar';
  int _generation = 0;
  Future<void> _queue = Future.value();
  Object? lastRefreshFailure;
  DeviceRegistrationService({
    DeviceRegistrationStore? store,
    Future<SharedPreferences>? prefsFuture,
    Future<String?> Function()? tokenGetter,
    Future<void> Function()? tokenDeleter,
    Stream<String>? tokenRefreshStream,
  }) : _store = store ?? FirestoreDeviceRegistrationStore(),
       _prefsFuture = prefsFuture ?? SharedPreferences.getInstance(),
       _tokenGetter =
           tokenGetter ?? (() => FirebaseMessaging.instance.getToken()),
       _tokenDeleter =
           tokenDeleter ?? (() => FirebaseMessaging.instance.deleteToken()),
       _tokenRefreshStream =
           tokenRefreshStream ?? FirebaseMessaging.instance.onTokenRefresh;
  Future<void> _serialize(Future<void> Function() action) {
    final operation = _queue.then((_) => action());
    _queue = operation.then((_) {}, onError: (Object e, StackTrace st) {});
    return operation;
  }

  /// Invalidate queued account work immediately, before an asynchronous channel
  /// update or preference reconciliation can allow it to reach device effects.
  void invalidatePendingOperations() => ++_generation;

  Future<String> getInstallationId() async {
    final prefs = await _prefsFuture;
    var id = prefs.getString('device_installation_id');
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().microsecondsSinceEpoch}';
      await prefs.setString('device_installation_id', id);
    }
    return id;
  }

  Future<void> _stopListener() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _currentBoundUid = null;
  }

  Future<bool> _cleanup(
    SharedPreferences prefs,
    String uid,
    String installationId,
    int generation,
  ) async {
    if (generation != _generation) return false;
    await prefs.setString('device_pending_cleanup_uid', uid);
    if (generation != _generation) return false;
    // SDK sign-out can remove Auth before its session event reaches cleanup.
    // Invalidate the local token even when Rules reject the remote deletion.
    // Keep the pending owner until that deletion succeeds, gating new binds.
    await _tokenDeleter();
    if (generation != _generation) return false;
    await _store.unregisterDevice(uid: uid, installationId: installationId);
    if (generation != _generation) return false;
    await prefs.remove('device_pending_cleanup_uid');
    if (generation != _generation) return false;
    await prefs.remove('device_bound_uid');
    if (generation != _generation) return false;
    await prefs.remove('last_synced_token');
    return generation == _generation;
  }

  Future<void> bindUser(String uid, {String? locale}) {
    if (uid.isEmpty) return Future.value();
    final generation = ++_generation;
    return _serialize(() async {
      if (generation != _generation) return;
      await _stopListener();
      if (generation != _generation) return;
      final prefs = await _prefsFuture;
      if (generation != _generation) return;
      final id = await getInstallationId();
      if (generation != _generation) return;
      final pending = prefs.getString('device_pending_cleanup_uid');
      final previous = prefs.getString('device_bound_uid');
      if (pending != null) {
        if (!await _cleanup(prefs, pending, id, generation)) return;
      } else if (previous != null && previous != uid) {
        if (!await _cleanup(prefs, previous, id, generation)) return;
      }
      _locale = locale ?? prefs.getString('device_locale') ?? 'ar';
      final token = await _tokenGetter();
      if (generation != _generation) return;
      // Record ownership before a remote write, so a newer transition can
      // clean up a write that finishes after its generation was invalidated.
      await prefs.setString('device_bound_uid', uid);
      if (generation != _generation) return;
      if (token != null && token.isNotEmpty) {
        await _store.registerDevice(
          uid: uid,
          installationId: id,
          token: token,
          locale: _locale,
        );
        if (generation != _generation) return;
        await prefs.setString('last_synced_token', token);
        if (generation != _generation) return;
      }
      await prefs.setString('device_locale', _locale);
      if (generation != _generation) return;
      _currentBoundUid = uid;
      _tokenRefreshSub = _tokenRefreshStream.listen((token) {
        _serialize(() async {
          if (generation != _generation ||
              _currentBoundUid != uid ||
              prefs.getString('device_bound_uid') != uid ||
              prefs.getString('device_pending_cleanup_uid') != null) {
            return;
          }
          await _store.registerDevice(
            uid: uid,
            installationId: id,
            token: token,
            locale: _locale,
          );
          if (generation != _generation || _currentBoundUid != uid) return;
          await prefs.setString('last_synced_token', token);
        }).catchError((Object error) {
          lastRefreshFailure = error;
        });
      });
    });
  }

  Future<void> unbindUser() {
    final generation = ++_generation;
    return _serialize(() async {
      if (generation != _generation) return;
      await _stopListener();
      if (generation != _generation) return;
      final prefs = await _prefsFuture;
      if (generation != _generation) return;
      final uid =
          prefs.getString('device_pending_cleanup_uid') ??
          prefs.getString('device_bound_uid');
      if (uid != null && uid.isNotEmpty) {
        final id = await getInstallationId();
        if (generation != _generation) return;
        await _cleanup(prefs, uid, id, generation);
      }
    });
  }

  Future<void> dispose() async {
    ++_generation;
    await _serialize(_stopListener);
  }
}

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import '../services/auth_lifecycle_test.dart' show DeviceStore;
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/khadem_model.dart';
import 'package:efteqad/core/repositories/auth_repository.dart';
import 'package:efteqad/core/repositories/profile_repository.dart';
import 'package:efteqad/core/session/session_cubit.dart';
import 'package:efteqad/core/session/session_state.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<AuthIdentity?> _controller =
      StreamController<AuthIdentity?>.broadcast();
  AuthIdentity? _current;
  bool signOutFails = false;

  @override
  Stream<AuthIdentity?> watchAuth() => _controller.stream;

  @override
  AuthIdentity? get currentAuth => _current;

  void emitAuth(AuthIdentity? identity) {
    _current = identity;
    _controller.add(identity);
  }

  @override
  Future<void> signOut() async {
    if (signOutFails) throw StateError('Auth sign-out failed');
    emitAuth(null);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeProfileRepository implements ProfileRepository {
  final Map<String, StreamController<KhademModel?>> _controllers = {};
  final List<String> listenedUids = [];
  final List<String> cancelledUids = [];

  StreamController<KhademModel?> _getOrCreateController(String uid) {
    return _controllers.putIfAbsent(uid, () {
      late StreamController<KhademModel?> ctrl;
      ctrl = StreamController<KhademModel?>.broadcast(
        onListen: () => listenedUids.add(uid),
        onCancel: () => cancelledUids.add(uid),
      );
      return ctrl;
    });
  }

  @override
  Stream<KhademModel?> watchProfile(String uid) {
    return _getOrCreateController(uid).stream;
  }

  void emitProfile(String uid, KhademModel? profile) {
    _getOrCreateController(uid).add(profile);
  }

  void emitError(String uid, Object error) {
    _getOrCreateController(uid).addError(error);
  }

  @override
  Future<KhademModel?> getProfile(String uid) async => null;

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }
}

void main() {
  group('SessionCubit Tests', () {
    late FakeAuthRepository authRepo;
    late FakeProfileRepository profileRepo;
    late SessionCubit cubit;

    setUp(() {
      authRepo = FakeAuthRepository();
      profileRepo = FakeProfileRepository();
      cubit = SessionCubit(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );
    });

    tearDown(() async {
      await cubit.close();
      authRepo.dispose();
      profileRepo.dispose();
    });

    test(
      'Session logout waits for durable device cleanup and remains retryable after failure',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = DeviceStore();
        final devices = DeviceRegistrationService(
          store: store,
          tokenGetter: () async => 'token',
          tokenDeleter: () async {},
          tokenRefreshStream: const Stream.empty(),
        );
        await devices.bindUser('a');
        await cubit.close();
        cubit = SessionCubit(
          authRepository: authRepo,
          profileRepository: profileRepo,
          beforeSignOut: devices.unbindUser,
        );
        authRepo.emitAuth(const AuthIdentity(uid: 'a'));
        await Future<void>.delayed(Duration.zero);
        profileRepo.emitProfile(
          'a',
          KhademModel(
            id: 'a',
            name: 'A',
            email: 'a@example.org',
            role: 'servant',
            grade: '2nd',
            status: 'active',
            createdAt: DateTime(2026),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        store.fails = true;
        await expectLater(cubit.signOut(), throwsA(anything));
        expect(authRepo.currentAuth?.uid, 'a');
        expect(cubit.state.isActive, isTrue);
        expect(profileRepo.cancelledUids, isNot(contains('a')));
        expect(
          (await SharedPreferences.getInstance()).getString(
            'device_pending_cleanup_uid',
          ),
          'a',
        );
        store.fails = false;
        await cubit.signOut();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, SessionStatus.signedOut);
        expect(authRepo.currentAuth, isNull);
        expect(
          (await SharedPreferences.getInstance()).getString('device_bound_uid'),
          isNull,
        );
        await devices.dispose();
      },
    );
    test(
      'delayed logout cleanup cannot sign out the replacement user',
      () async {
        final cleanup = Completer<void>();
        await cubit.close();
        cubit = SessionCubit(
          authRepository: authRepo,
          profileRepository: profileRepo,
          beforeSignOut: () => cleanup.future,
        );
        authRepo.emitAuth(const AuthIdentity(uid: 'a'));
        await Future<void>.delayed(Duration.zero);
        final signOut = cubit.signOut();
        authRepo.emitAuth(const AuthIdentity(uid: 'b'));
        await Future<void>.delayed(Duration.zero);
        profileRepo.emitProfile(
          'b',
          KhademModel(
            id: 'b',
            name: 'B',
            email: 'b@example.org',
            role: 'servant',
            grade: '3rd',
            status: 'active',
            createdAt: DateTime(2026),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        cleanup.complete();
        await signOut;
        await Future<void>.delayed(Duration.zero);
        expect(authRepo.currentAuth?.uid, 'b');
        expect(cubit.state.userId, 'b');
        expect(cubit.state.isActive, isTrue);
      },
    );
    test(
      'Auth sign-out failure preserves trusted Session and retry succeeds',
      () async {
        await cubit.close();
        cubit = SessionCubit(
          authRepository: authRepo,
          profileRepository: profileRepo,
          beforeSignOut: () async {},
        );
        authRepo.emitAuth(const AuthIdentity(uid: 'a'));
        await Future<void>.delayed(Duration.zero);
        profileRepo.emitProfile(
          'a',
          KhademModel(
            id: 'a',
            name: 'A',
            email: 'a@example.org',
            role: 'servant',
            grade: '2nd',
            status: 'active',
            createdAt: DateTime(2026),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        authRepo.signOutFails = true;
        await expectLater(cubit.signOut(), throwsA(isA<StateError>()));
        expect(authRepo.currentAuth?.uid, 'a');
        expect(cubit.state.isActive, isTrue);
        expect(cubit.state.userId, 'a');
        expect(profileRepo.cancelledUids, isNot(contains('a')));
        profileRepo.emitProfile(
          'a',
          KhademModel(
            id: 'a',
            name: 'A',
            email: 'a@example.org',
            role: 'servant',
            grade: '3rd',
            status: 'active',
            createdAt: DateTime(2026),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.grade, '3rd');
        authRepo.signOutFails = false;
        await cubit.signOut();
        await Future<void>.delayed(Duration.zero);
        expect(authRepo.currentAuth, isNull);
        expect(cubit.state.status, SessionStatus.signedOut);
        expect(profileRepo.cancelledUids, contains('a'));
      },
    );
    test('Initial state is booting', () {
      expect(cubit.state.status, SessionStatus.booting);
    });

    test('stageAdmin without grade becomes active', () async {
      authRepo.emitAuth(
        const AuthIdentity(uid: 'admin_1', email: 'admin@stage.org'),
      );
      await Future<void>.delayed(Duration.zero);

      final adminProfile = KhademModel(
        id: 'admin_1',
        email: 'admin@stage.org',
        name: 'Stage Admin',
        role: 'stageAdmin',
        status: 'active',
        grade: null, // stage admin has no grade
        createdAt: DateTime.now(),
      );

      profileRepo.emitProfile('admin_1', adminProfile);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SessionStatus.active);
      expect(cubit.state.role, UserRole.stageAdmin);
      expect(cubit.state.grade, isNull);
      expect(cubit.state.userId, 'admin_1');
    });

    test(
      'stageAdmin with status deleting becomes deleting and denies access',
      () async {
        authRepo.emitAuth(
          const AuthIdentity(uid: 'admin_del', email: 'del@stage.org'),
        );
        await Future<void>.delayed(Duration.zero);

        final deletingAdmin = KhademModel(
          id: 'admin_del',
          email: 'del@stage.org',
          name: 'Deleting Admin',
          role: 'stageAdmin',
          status: 'deleting',
          createdAt: DateTime.now(),
        );

        profileRepo.emitProfile('admin_del', deletingAdmin);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.status, SessionStatus.deleting);
        expect(cubit.state.isDeleting, isTrue);
        expect(cubit.state.isActive, isFalse);
      },
    );

    test('stageAdmin with status pending becomes pending', () async {
      authRepo.emitAuth(
        const AuthIdentity(uid: 'admin_pend', email: 'pend@stage.org'),
      );
      await Future<void>.delayed(Duration.zero);

      final pendingAdmin = KhademModel(
        id: 'admin_pend',
        email: 'pend@stage.org',
        name: 'Pending Admin',
        role: 'stageAdmin',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      profileRepo.emitProfile('admin_pend', pendingAdmin);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SessionStatus.pending);
      expect(cubit.state.isPending, isTrue);
      expect(cubit.state.isActive, isFalse);
    });

    test('servant with status deleting becomes deleting', () async {
      authRepo.emitAuth(
        const AuthIdentity(uid: 'servant_del', email: 'sdel@test.com'),
      );
      await Future<void>.delayed(Duration.zero);

      final deletingServant = KhademModel(
        id: 'servant_del',
        email: 'sdel@test.com',
        name: 'Deleting Servant',
        role: 'servant',
        status: 'deleting',
        grade: '1st',
        createdAt: DateTime.now(),
      );

      profileRepo.emitProfile('servant_del', deletingServant);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SessionStatus.deleting);
      expect(cubit.state.isDeleting, isTrue);
      expect(cubit.state.isActive, isFalse);
    });

    test('servant without grade becomes pending', () async {
      authRepo.emitAuth(
        const AuthIdentity(uid: 'servant_1', email: 'servant@test.com'),
      );
      await Future<void>.delayed(Duration.zero);

      final unassignedServant = KhademModel(
        id: 'servant_1',
        email: 'servant@test.com',
        name: 'Servant One',
        role: 'servant',
        status: 'active',
        grade: null, // Servant with no grade cannot be active
        createdAt: DateTime.now(),
      );

      profileRepo.emitProfile('servant_1', unassignedServant);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SessionStatus.pending);
      expect(cubit.state.role, UserRole.servant);
      expect(cubit.state.grade, isNull);
    });

    test('servant with valid grade becomes active', () async {
      authRepo.emitAuth(
        const AuthIdentity(uid: 'servant_2', email: 'servant2@test.com'),
      );
      await Future<void>.delayed(Duration.zero);

      final assignedServant = KhademModel(
        id: 'servant_2',
        email: 'servant2@test.com',
        name: 'Servant Two',
        role: 'servant',
        status: 'active',
        grade: '1st',
        createdAt: DateTime.now(),
      );

      profileRepo.emitProfile('servant_2', assignedServant);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SessionStatus.active);
      expect(cubit.state.role, UserRole.servant);
      expect(cubit.state.grade, '1st');
    });

    test(
      'profile fetch failure stays in failure state and retry can recover',
      () async {
        authRepo.emitAuth(
          const AuthIdentity(uid: 'user_err', email: 'err@test.com'),
        );
        await Future<void>.delayed(Duration.zero);

        profileRepo.emitError('user_err', Exception('Network failure'));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.status, SessionStatus.failure);
        expect(cubit.state.failure, isNotNull);
        // Ensure failure is NOT converted to pending
        expect(cubit.state.status != SessionStatus.pending, isTrue);

        // Retry
        cubit.retry();
        await Future<void>.delayed(Duration.zero);

        final recoveredProfile = KhademModel(
          id: 'user_err',
          email: 'err@test.com',
          name: 'Recovered User',
          role: 'gradeAdmin',
          status: 'active',
          grade: '2nd',
          createdAt: DateTime.now(),
        );

        profileRepo.emitProfile('user_err', recoveredProfile);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.status, SessionStatus.active);
        expect(cubit.state.role, UserRole.gradeAdmin);
        expect(cubit.state.grade, '2nd');
      },
    );

    test('UID change cancels previous listener', () async {
      authRepo.emitAuth(const AuthIdentity(uid: 'user_A', email: 'a@test.com'));
      await Future<void>.delayed(Duration.zero);

      expect(profileRepo.listenedUids, contains('user_A'));

      // Switch to user B
      authRepo.emitAuth(const AuthIdentity(uid: 'user_B', email: 'b@test.com'));
      await Future<void>.delayed(Duration.zero);

      expect(profileRepo.cancelledUids, contains('user_A'));
      expect(profileRepo.listenedUids, contains('user_B'));

      // Sign out
      authRepo.emitAuth(null);
      await Future<void>.delayed(Duration.zero);

      expect(profileRepo.cancelledUids, contains('user_B'));
      expect(cubit.state.status, SessionStatus.signedOut);
    });
  });
}

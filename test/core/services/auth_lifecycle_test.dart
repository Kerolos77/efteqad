import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:efteqad/core/services/auth_service.dart';
import 'package:efteqad/core/services/device_registration_service.dart';
import 'package:efteqad/core/repositories/account_repository.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';

class AuthSdk extends Fake implements FirebaseAuth {
  final UserSdk user = UserSdk();
  User? replacement;
  bool signedOut = false;
  String? email;
  @override
  User? get currentUser => replacement ?? user;
  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    this.email = email;
    return CredentialSdk(user);
  }
}

class CredentialSdk extends Fake implements UserCredential {
  final UserSdk u;
  CredentialSdk(this.u);
  @override
  User? get user => u;
}

class UserSdk extends Fake implements User {
  int deletes = 0;
  int reauths = 0;
  bool reauthFails = false;
  Completer<void>? reauthBarrier;
  Completer<void>? reauthStarted;
  @override
  String? get displayName => 'User';
  @override
  String get uid => 'u';
  @override
  String? get email => 'allowed@example.org';
  @override
  List<UserInfo> get providerData => [
    ProviderSdk('password'),
    ProviderSdk('google.com'),
  ];
  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    reauths++;
    reauthStarted?.complete();
    await reauthBarrier?.future;
    if (reauthFails) throw StateError('reauth cancelled');
    return CredentialSdk(this);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'fresh';
  @override
  Future<void> delete() async {
    deletes++;
  }
}

class ProviderSdk extends Fake implements UserInfo {
  final String id;
  ProviderSdk(this.id);
  @override
  String get providerId => id;
}

class GoogleSdk extends Fake implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
  @override
  Future<GoogleSignInAccount?> signIn() async => null;
}

class DeviceStore extends Fake implements DeviceRegistrationStore {
  bool fails = false;
  Completer<void>? cleanupBarrier;
  Completer<void>? cleanupStarted;
  @override
  Future<void> registerDevice({
    required String uid,
    required String installationId,
    required String token,
    required String locale,
  }) async {}
  @override
  Future<void> unregisterDevice({
    required String uid,
    required String installationId,
  }) async {
    cleanupStarted?.complete();
    await cleanupBarrier?.future;
    if (fails) throw StateError('offline');
  }
}

class ReplacementUser extends UserSdk {
  @override
  String get uid => 'replacement';
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'account switch during real delayed reauthentication aborts deletion',
    () async {
      final sdk = AuthSdk();
      sdk.user.reauthBarrier = Completer<void>();
      sdk.user.reauthStarted = Completer<void>();
      final payloads = <Map<String, dynamic>>[];
      final devices = DeviceRegistrationService(
        store: DeviceStore(),
        tokenGetter: () async => 'token',
        tokenDeleter: () async {},
        tokenRefreshStream: const Stream.empty(),
      );
      final repo = FirebaseAccountRepository(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        mutations: TrustedMutations(
          transport: (_, payload) async {
            payloads.add(payload);
            return {'deletionId': 'u'};
          },
        ),
      );
      final auth = AuthService(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        devices: devices,
        clearNotificationIntents: () {},
      );
      final deletion = auth.deleteAccount(
        password: 'secret',
        accountRepository: repo,
      );
      final rejected = expectLater(deletion, throwsA(anything));
      await sdk.user.reauthStarted!.future;
      sdk.replacement = ReplacementUser();
      sdk.user.reauthBarrier!.complete();
      await rejected;
      expect(payloads, isEmpty);
      expect(sdk.signedOut, false);
      expect(sdk.currentUser!.uid, 'replacement');
      expect(
        (await SharedPreferences.getInstance()).getString(
          'deletion_intent_replacement',
        ),
        isNull,
      );
    },
  );
  test(
    'account switch during device cleanup prevents deletion request',
    () async {
      final sdk = AuthSdk(), store = DeviceStore();
      final devices = DeviceRegistrationService(
        store: store,
        tokenGetter: () async => 'token',
        tokenDeleter: () async {},
        tokenRefreshStream: const Stream.empty(),
      );
      await devices.bindUser('u');
      store.cleanupBarrier = Completer<void>();
      store.cleanupStarted = Completer<void>();
      var requests = 0;
      final repo = FirebaseAccountRepository(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        mutations: TrustedMutations(
          transport: (_, p) async {
            requests++;
            return {'deletionId': 'u'};
          },
        ),
      );
      final auth = AuthService(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        devices: devices,
        clearNotificationIntents: () {},
      );
      final rejected = expectLater(
        auth.deleteAccount(password: 'secret', accountRepository: repo),
        throwsA(anything),
      );
      await store.cleanupStarted!.future;
      sdk.replacement = ReplacementUser();
      store.cleanupBarrier!.complete();
      await rejected;
      expect(requests, 0);
      expect(sdk.signedOut, false);
      expect(sdk.currentUser!.uid, 'replacement');
    },
  );
  test('late deletion receipt cannot sign out replacement account', () async {
    final sdk = AuthSdk();
    final devices = DeviceRegistrationService(
      store: DeviceStore(),
      tokenGetter: () async => 'token',
      tokenDeleter: () async {},
      tokenRefreshStream: const Stream.empty(),
    );
    final sent = Completer<void>(), receipt = Completer<void>();
    final repo = FirebaseAccountRepository(
      auth: sdk,
      googleSignIn: GoogleSdk(),
      mutations: TrustedMutations(
        transport: (_, p) async {
          expect(p['expectedUid'], 'u');
          sent.complete();
          await receipt.future;
          return {'deletionId': 'u'};
        },
      ),
    );
    final auth = AuthService(
      auth: sdk,
      googleSignIn: GoogleSdk(),
      devices: devices,
      clearNotificationIntents: () {},
    );
    final rejected = expectLater(
      auth.deleteAccount(password: 'secret', accountRepository: repo),
      throwsA(anything),
    );
    await sent.future;
    sdk.replacement = ReplacementUser();
    receipt.complete();
    await rejected;
    expect(sdk.signedOut, false);
    expect(sdk.currentUser!.uid, 'replacement');
  });
  test(
    'logout cleanup failure gates auth sign-out and preserves pending cleanup',
    () async {
      final sdk = AuthSdk(), store = DeviceStore();
      final devices = DeviceRegistrationService(
        store: store,
        tokenGetter: () async => 'token',
        tokenDeleter: () async {},
        tokenRefreshStream: const Stream.empty(),
      );
      await devices.bindUser('u');
      store.fails = true;
      final auth = AuthService(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        devices: devices,
        clearNotificationIntents: () {},
      );
      await expectLater(auth.signOut(), throwsA(anything));
      expect(sdk.signedOut, false);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'device_pending_cleanup_uid',
        ),
        'u',
      );
    },
  );
  test(
    'deletion retries persist operation ID; backend owns Auth deletion',
    () async {
      final sdk = AuthSdk();
      final devices = DeviceRegistrationService(
        store: DeviceStore(),
        tokenGetter: () async => 'token',
        tokenDeleter: () async {},
        tokenRefreshStream: const Stream.empty(),
      );
      final payloads = <Map<String, dynamic>>[];
      bool fail = true;
      final repo = FirebaseAccountRepository(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        mutations: TrustedMutations(
          transport: (n, p) async {
            expect(n, 'requestAccountDeletion');
            payloads.add(p);
            if (fail) throw StateError('offline');
            return {'deletionId': 'u', 'success': true, 'status': 'queued'};
          },
        ),
      );
      final auth = AuthService(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        devices: devices,
        clearNotificationIntents: () {},
      );
      await expectLater(
        auth.deleteAccount(password: 'secret', accountRepository: repo),
        throwsA(anything),
      );
      fail = false;
      await auth.deleteAccount(password: 'secret', accountRepository: repo);
      expect(payloads.last, payloads.first);
      expect(payloads.last['expectedUid'], 'u');
      expect(sdk.user.deletes, 0);
      expect(sdk.signedOut, true);
    },
  );
  test(
    'multi-provider cancelled Google reauthentication never invokes deletion transport',
    () async {
      final sdk = AuthSdk();
      bool sent = false;
      final repo = FirebaseAccountRepository(
        auth: sdk,
        googleSignIn: GoogleSdk(),
        mutations: TrustedMutations(
          transport: (n, p) async {
            sent = true;
            return {'deletionId': 'u'};
          },
        ),
      );
      await expectLater(repo.reauthenticate(), throwsA(anything));
      expect(sent, false);
      expect(sdk.user.reauths, 0);
    },
  );
}

// Exercise real Firebase app/Auth/Functions selection with external platform adapters.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';

class CoreSdk extends FirebasePlatform {
  final records = <String, FirebaseAppPlatform>{};
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      records[name]!;
}

class FactorSdk extends MultiFactorPlatform {
  FactorSdk(super.auth);
}

class IdentitySdk extends UserPlatform {
  IdentitySdk(FirebaseAuthPlatform auth, String uid)
    : super(
        auth,
        FactorSdk(auth),
        PigeonUserDetails(
          userInfo: PigeonUserInfo(
            uid: uid,
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: [],
        ),
      );
}

class AuthSdk extends FirebaseAuthPlatform {
  final Map<String, AuthSdk> selected;
  String uid = '';
  AuthSdk(this.selected, {super.appInstance});
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) =>
      selected.putIfAbsent(app.name, () => AuthSdk(selected, appInstance: app));
  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;
  @override
  UserPlatform get currentUser => IdentitySdk(this, uid);
}

class Wire {
  final calls = <Map<String, dynamic>>[];
  Completer<Object?>? response;
}

class FunctionsSdk extends FirebaseFunctionsPlatform {
  final Wire wire;
  FunctionsSdk(this.wire, [FirebaseApp? app, String region = 'us-central1'])
    : super(app, region);
  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) => FunctionsSdk(wire, app, region);
  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) => CallableSdk(this, origin, name, options, wire);
}

class CallableSdk extends HttpsCallablePlatform {
  final Wire wire;
  CallableSdk(
    FirebaseFunctionsPlatform functions,
    String? origin,
    String name,
    HttpsCallableOptions options,
    this.wire,
  ) : super(functions, origin, name, options, null);
  @override
  Future<Object?> call([Object? parameters]) async {
    wire.calls.add({'app': functions.app!.name, 'payload': parameters});
    return wire.response?.future ?? {'success': true};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'injected admin Functions uses its own Auth and rejects replacement within that app',
    () async {
      final oldCore = FirebasePlatform.instance,
          oldAuth = FirebaseAuthPlatform.instance,
          oldFunctions = FirebaseFunctionsPlatform.instance;
      addTearDown(() {
        FirebasePlatform.instance = oldCore;
        FirebaseAuthPlatform.instance = oldAuth;
        FirebaseFunctionsPlatform.instance = oldFunctions;
      });
      final core = CoreSdk();
      const options = FirebaseOptions(
        apiKey: 'demo',
        appId: 'demo',
        messagingSenderId: 'demo',
        projectId: 'demo-efteqad-rules',
      );
      core.records['[DEFAULT]'] = FirebaseAppPlatform('[DEFAULT]', options);
      core.records['demo-admin-identity'] = FirebaseAppPlatform(
        'demo-admin-identity',
        options,
      );
      FirebasePlatform.instance = core;
      final auths = <String, AuthSdk>{};
      FirebaseAuthPlatform.instance = AuthSdk(auths);
      final defaultAuth = FirebaseAuth.instance,
          adminApp = Firebase.app('demo-admin-identity');
      final adminAuth = FirebaseAuth.instanceFor(app: adminApp);
      defaultAuth.currentUser;
      adminAuth.currentUser;
      auths['[DEFAULT]']!.uid = 'servant';
      auths[adminApp.name]!.uid = 'admin';
      final wire = Wire();
      FirebaseFunctionsPlatform.instance = FunctionsSdk(wire);
      final functions = FirebaseFunctions.instanceFor(app: adminApp);
      final mutations = TrustedMutations(functions: functions);
      await mutations.call('setKhademGrade', {
        'khademId': 'servant',
        'grade': '1st',
      });
      expect((wire.calls.single['payload'] as Map)['expectedUid'], 'admin');
      expect(wire.calls.single['app'], adminApp.name);
      auths['[DEFAULT]']!.uid = 'other-servant';
      await mutations.call('importRows', {'grade': '1st', 'rows': []});
      expect((wire.calls.last['payload'] as Map)['expectedUid'], 'admin');
      wire.response = Completer<Object?>();
      final pending = mutations.call('assignMakhdoms', {
        'ids': ['m'],
      });
      final rejected = expectLater(pending, throwsA(anything));
      auths[adminApp.name]!.uid = 'replacement-admin';
      wire.response!.complete({'success': true});
      await rejected;
      expect((wire.calls.last['payload'] as Map)['expectedUid'], 'admin');
      // Explicit overrides/custom transport keep their existing contract.
      final sent = <Map<String, dynamic>>[];
      await TrustedMutations(
        functions: functions,
        userId: () => 'explicit',
        transport: (n, p) async {
          sent.add(p);
          return {'success': true};
        },
      ).call('operation', {});
      expect(sent.single['expectedUid'], 'explicit');
    },
  );
}

import 'package:cloud_functions/cloud_functions.dart';
import '../services/trusted_mutations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AccountRepository {
  Future<void> reauthenticate({String? password});
  Future<String> requestDeletion({
    required String operationId,
    required String expectedUid,
  });
}

class FirebaseAccountRepository implements AccountRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final TrustedMutations _mutations;

  FirebaseAccountRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
    TrustedMutations? mutations,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _mutations = mutations ?? TrustedMutations(functions: functions);

  @override
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found for reauthentication.');
    }

    final isPasswordUser = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    final isGoogleUser = user.providerData.any(
      (p) => p.providerId == 'google.com',
    );
    if (isPasswordUser && (password != null || !isGoogleUser)) {
      if (password == null || password.isEmpty) {
        throw ArgumentError('Password required for reauthentication.');
      }
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.getIdToken(true);
      return;
    }

    if (!isGoogleUser) throw StateError('Unsupported authentication provider.');
    // Google re-authentication
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('User cancelled re-authentication.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
    await user.getIdToken(true);
  }

  @override
  Future<String> requestDeletion({
    required String operationId,
    required String expectedUid,
  }) async {
    if (_auth.currentUser?.uid != expectedUid) {
      throw StateError('Account changed before deletion request.');
    }
    final data = await _mutations.call('requestAccountDeletion', {
      'operationId': operationId,
      'expectedUid': expectedUid,
    });
    return data['deletionId'] as String;
  }
}

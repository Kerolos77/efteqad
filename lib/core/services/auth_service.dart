import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';
import '../models/khadem_model.dart';
import '../repositories/account_repository.dart';
import '../errors/app_failure.dart';
import 'device_registration_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import 'trusted_mutations.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;
  final DeviceRegistrationService _devices;
  final void Function() _clearNotificationIntents;
  static KhademModel? _loadedProfile;
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirestoreService? firestoreService,
    DeviceRegistrationService? devices,
    void Function()? clearNotificationIntents,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestoreService = firestoreService ?? FirestoreService(),
       _devices = devices ?? DeviceRegistrationService.shared,
       _clearNotificationIntents =
           clearNotificationIntents ??
           (() => NotificationService().intentCoordinator?.clear());
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  // Transitional synchronous callers must migrate to SessionCubit (Task3/Task4).
  bool get isStageAdmin =>
      _loadedProfile?.id == currentUser?.uid &&
      _loadedProfile?.status == 'active' &&
      _loadedProfile?.role == AppConstants.roleStageAdmin;
  bool get isAdmin => isStageAdmin;
  Future<UserCredential> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _loadedProfile = credential.user == null
        ? null
        : await _firestoreService.getKhadem(credential.user!.uid);
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final result = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );
    final user = result.user;
    if (user != null) {
      await _firestoreService.saveOrUpdateKhadem(
        KhademModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          phone: user.phoneNumber ?? '',
          colorHex: '',
          role: 'pending',
          grade: null,
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      );
      _loadedProfile = await _firestoreService.getKhadem(user.uid);
    }
    return result;
  }

  Future<void> signOut() async {
    try {
      await _devices.unbindUser();
      _clearNotificationIntents();
      await _googleSignIn.signOut();
      await _auth.signOut();
      _loadedProfile = null;
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }

  Future<void> reauthenticate({String? password}) => FirebaseAccountRepository(
    auth: _auth,
    googleSignIn: _googleSignIn,
  ).reauthenticate(password: password);
  Future<void> deleteAccount({
    String? password,
    AccountRepository? accountRepository,
  }) async {
    final user = currentUser;
    if (user == null) throw StateError('Authentication required.');
    final repo =
        accountRepository ??
        FirebaseAccountRepository(auth: _auth, googleSignIn: _googleSignIn);
    final initiatingUid = user.uid;
    void requireInitiatingAccount() {
      if (currentUser?.uid != initiatingUid) {
        throw const AppFailure(
          code: 'failed-precondition',
          message: 'Account changed during deletion.',
          retryable: false,
        );
      }
    }

    await repo.reauthenticate(password: password);
    requireInitiatingAccount();
    final prefs = await SharedPreferences.getInstance(),
        key = 'deletion_intent_$initiatingUid';
    final operationId = prefs.getString(key) ?? newOperationId('deletion');
    requireInitiatingAccount();
    await prefs.setString(key, operationId);
    requireInitiatingAccount();
    await _devices.unbindUser();
    requireInitiatingAccount();
    await repo.requestDeletion(
      operationId: operationId,
      expectedUid: initiatingUid,
    );
    // A late receipt belongs to the initiating account; never sign out its replacement.
    requireInitiatingAccount();
    _clearNotificationIntents();
    await _googleSignIn.signOut();
    requireInitiatingAccount();
    await _auth.signOut();
    _loadedProfile = null;
  }
}

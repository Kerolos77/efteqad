import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthIdentity {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AuthIdentity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthIdentity &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      uid.hashCode ^ email.hashCode ^ displayName.hashCode ^ photoUrl.hashCode;

  @override
  String toString() => 'AuthIdentity(uid: $uid, email: $email, name: $displayName)';
}

abstract class AuthRepository {
  Stream<AuthIdentity?> watchAuth();
  AuthIdentity? get currentAuth;
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<AuthIdentity?> watchAuth() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  AuthIdentity? get currentAuth => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  static AuthIdentity? _mapUser(User? user) {
    if (user == null) return null;
    return AuthIdentity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}

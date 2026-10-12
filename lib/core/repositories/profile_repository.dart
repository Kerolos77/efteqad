import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';
import '../models/khadem_model.dart';

abstract class ProfileRepository {
  Stream<KhademModel?> watchProfile(String uid);
  Future<KhademModel?> getProfile(String uid);
}

class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<KhademModel?> watchProfile(String uid) {
    return _firestore
        .collection(AppConstants.colKhodam)
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists && doc.data() != null
              ? KhademModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  @override
  Future<KhademModel?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.colKhodam)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return KhademModel.fromMap(doc.data()!, doc.id);
  }
}

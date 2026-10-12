import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/trusted_mutations.dart';
import '../constants/constants.dart';
import '../models/makhdom_model.dart';
import '../models/makhdom_profile_patch.dart';

abstract class MakhdomRepository {
  Stream<List<MakhdomModel>> watchMakhdomeenByGrade(String grade);
  Stream<List<MakhdomModel>> watchMakhdomeenForKhadem(String khademId);
  Stream<MakhdomModel?> watchMakhdom(String id);
  Future<MakhdomModel?> getMakhdom(String id);
  Future<void> updateProfile(String id, MakhdomProfilePatch patch);
  Future<void> archiveMakhdom(String id);
  Future<void> assignMakhdoms({
    required List<String> ids,
    String? targetKhademId,
    String? targetKhademName,
    Map<String, String?>? expectedAssignments,
    String? operationId,
  });
}

class FirestoreMakhdomRepository implements MakhdomRepository {
  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  final TrustedMutations _mutations;

  FirestoreMakhdomRepository({
    FirebaseFirestore? firestore,
    TrustedMutations? mutations,
  }) : _providedFirestore = firestore,
       _mutations = mutations ?? TrustedMutations();

  @override
  Stream<List<MakhdomModel>> watchMakhdomeenByGrade(String grade) {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .where('grade', isEqualTo: grade)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
              .where((m) => docActive(m))
              .toList();
          list.sort((a, b) => a.fullName.compareTo(b.fullName));
          return list;
        });
  }

  @override
  Stream<List<MakhdomModel>> watchMakhdomeenForKhadem(String khademId) {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .where('assignedKhademId', isEqualTo: khademId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
              .where((m) => docActive(m))
              .toList(),
        );
  }

  @override
  Stream<MakhdomModel?> watchMakhdom(String id) {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .doc(id)
        .snapshots()
        .map(
          (doc) => doc.exists && doc.data() != null
              ? MakhdomModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  @override
  Future<MakhdomModel?> getMakhdom(String id) async {
    final doc = await _firestore
        .collection(AppConstants.colMakhdomeen)
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return MakhdomModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> updateProfile(String id, MakhdomProfilePatch patch) async {
    final fields = TrustedMutations.patchFields(patch);
    if (fields.isEmpty) return;
    await _mutations.saveProfile(id: id, patch: fields);
  }

  @override
  Future<void> archiveMakhdom(String id) async {
    await _mutations.call('archiveMakhdom', {
      'makhdomId': id,
      'operationId': newOperationId('archive'),
    });
  }

  @override
  Future<void> assignMakhdoms({
    required List<String> ids,
    String? targetKhademId,
    String? targetKhademName,
    Map<String, String?>? expectedAssignments,
    String? operationId,
  }) async {
    if (expectedAssignments == null) {
      throw ArgumentError('Expected assignments are required.');
    }
    await _mutations.assign(
      ids: ids,
      targetKhademId: targetKhademId,
      expectedAssignments: expectedAssignments,
      operationId: operationId,
    );
  }

  static bool docActive(MakhdomModel m) {
    // Only active makhdomeen appear in active streams and roster
    return m.active;
  }
}

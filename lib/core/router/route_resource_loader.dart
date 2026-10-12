import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';
import '../models/makhdom_model.dart';
import '../models/task_model.dart';

abstract class RouteResourceLoader {
  Future<MakhdomModel?> loadChild(String id);
  Stream<MakhdomModel?> watchChild(String id);
  Future<TaskModel?> loadTask(String id);
  Stream<TaskModel?> watchTask(String id);
}

class FirestoreRouteResourceLoader implements RouteResourceLoader {
  final FirebaseFirestore? firestore;
  FirestoreRouteResourceLoader({this.firestore});
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;
  @override
  Future<MakhdomModel?> loadChild(String id) async {
    final doc = await _db
        .collection(AppConstants.colMakhdomeen)
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.exists ? MakhdomModel.fromMap(doc.data()!, doc.id) : null;
  }

  @override
  Stream<MakhdomModel?> watchChild(String id) => _db
      .collection(AppConstants.colMakhdomeen)
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .where(
        (doc) => !doc.metadata.isFromCache && !doc.metadata.hasPendingWrites,
      )
      .map(
        (doc) => doc.exists ? MakhdomModel.fromMap(doc.data()!, doc.id) : null,
      );
  @override
  Future<TaskModel?> loadTask(String id) async {
    final doc = await _db
        .collection(AppConstants.colTasks)
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.exists ? TaskModel.fromFirestore(doc) : null;
  }

  @override
  Stream<TaskModel?> watchTask(String id) => _db
      .collection(AppConstants.colTasks)
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .where(
        (doc) => !doc.metadata.isFromCache && !doc.metadata.hasPendingWrites,
      )
      .map((doc) => doc.exists ? TaskModel.fromFirestore(doc) : null);
}

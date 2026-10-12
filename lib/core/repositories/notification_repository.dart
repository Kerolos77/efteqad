import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';
import '../errors/app_failure.dart';
import '../models/notification_model.dart';
import '../models/page_result.dart';
import '../models/snapshot_list.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> watchNotificationsForUser(String uid);
  Stream<int> watchUnreadCount(String uid);
  Future<PageResult<NotificationModel>> fetchNotificationPage({
    required String uid,
    DocumentSnapshot? cursor,
    int limit = 50,
  });
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead(String uid);
}

class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<NotificationModel>> watchNotificationsForUser(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection(AppConstants.colNotifications)
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(50)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => SnapshotList<NotificationModel>.fromSnapshot(
            snapshot,
            (doc) => NotificationModel.fromMap(doc.data(), doc.id),
          ),
        )
        .handleError((e, st) => throw AppFailure.fromException(e, st));
  }

  @override
  Stream<int> watchUnreadCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return _firestore
        .collection(AppConstants.colNotifications)
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.length)
        .handleError((e, st) => throw AppFailure.fromException(e, st));
  }

  @override
  Future<PageResult<NotificationModel>> fetchNotificationPage({
    required String uid,
    DocumentSnapshot? cursor,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.colNotifications)
          .where('recipientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      final items = snap.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();

      final hasMore = snap.docs.length == limit;
      final newCursor = snap.docs.isNotEmpty ? snap.docs.last : null;

      return PageResult<NotificationModel>(
        items: SnapshotList(
          items,
          isFromCache: snap.metadata.isFromCache,
          hasPendingWrites: snap.metadata.hasPendingWrites,
        ),
        cursor: newCursor,
        hasMore: hasMore,
      );
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.colNotifications)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String uid) async {
    try {
      // Chunked in batches of 200 to prevent Firestore 500-op batch limits and allow resumability
      const int batchSize = 200;
      bool hasMore = true;

      while (hasMore) {
        final querySnap = await _firestore
            .collection(AppConstants.colNotifications)
            .where('recipientId', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .limit(batchSize)
            .get();

        if (querySnap.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        for (final doc in querySnap.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();

        if (querySnap.docs.length < batchSize) {
          hasMore = false;
        }
      }
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/constants.dart';
import '../models/makhdom_model.dart';
import '../models/khadem_model.dart';
import '../models/visit_model.dart';
import '../models/task_model.dart';
import '../models/attendance_session_model.dart';
import '../models/notification_model.dart';
import '../models/makhdom_profile_patch.dart';
import '../models/page_result.dart';
import '../models/snapshot_list.dart';
import '../errors/app_failure.dart';
import '../repositories/notification_repository.dart';
import '../utils/calendar_dates.dart';
import 'privileged_operations_service.dart';
import 'trusted_mutations.dart';
import '../repositories/visit_repository.dart';
import '../repositories/attendance_repository.dart';
import 'import_coordinator.dart';

class FirestoreService {
  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  final TrustedMutations _mutations;
  final PrivilegedOperationsService _privilegedOps;
  final Map<String, String> _deleteOperations = {};
  final ImportCoordinator? _providedImportCoordinator;

  FirestoreService({
    FirebaseFirestore? firestore,
    ImportCoordinator? importCoordinator,
    PrivilegedOperationsService? privilegedOps,
    TrustedMutations? mutations,
  }) : _providedFirestore = firestore,
       _providedImportCoordinator = importCoordinator,
       _mutations = mutations ?? TrustedMutations(),
       _privilegedOps = privilegedOps ?? PrivilegedOperationsService();

  // ===================== مخدومين (Makhdomeen) =====================

  /// جلب كل المخدومين في بث مباشر (Realtime Stream)
  Stream<List<MakhdomModel>> getMakhdomeenStream() {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .orderBy('fullName')
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => SnapshotList(
            snapshot.docs
                .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
                .where((m) => m.active)
                .toList(),
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          ),
        );
  }

  /// جلب مخدومي سنة دراسية معينة فقط (لأمين السنة)
  Stream<List<MakhdomModel>> getMakhdomeenByGradeStream(String grade) {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .where('grade', isEqualTo: grade)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
              .where((m) => m.active)
              .toList();
          list.sort((a, b) => a.fullName.compareTo(b.fullName));
          return SnapshotList(
            list,
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
        });
  }

  /// جلب مخدومي خادم معين فقط (للخادم)
  Stream<List<MakhdomModel>> getMakhdomeenForKhademStream(String khademId) {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .where('assignedKhademId', isEqualTo: khademId)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => SnapshotList(
            snapshot.docs
                .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
                .where((m) => m.active)
                .toList(),
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          ),
        );
  }

  /// جلب مخدوم محدد (Stream للتحديث اللحظي)
  Stream<MakhdomModel?> getMakhdomStream(String id) {
    return _firestore
        .collection(AppConstants.colMakhdomeen)
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .map(
          (doc) => doc.exists && doc.data() != null
              ? MakhdomModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  /// جلب بيانات مخدوم محدد كـ Future
  Future<MakhdomModel?> getMakhdom(String id) async {
    final doc = await _firestore
        .collection(AppConstants.colMakhdomeen)
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return MakhdomModel.fromMap(doc.data()!, doc.id);
  }

  /// جلب مخدومي سنة دراسية كـ Future
  Future<List<MakhdomModel>> getMakhdomeenByGrade(String grade) async {
    final snapshot = await _firestore
        .collection(AppConstants.colMakhdomeen)
        .where('grade', isEqualTo: grade)
        .get();
    final list = snapshot.docs
        .map((doc) => MakhdomModel.fromMap(doc.data(), doc.id))
        .where((m) => m.active)
        .toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return SnapshotList(
      list,
      isFromCache: snapshot.metadata.isFromCache,
      hasPendingWrites: snapshot.metadata.hasPendingWrites,
    );
  }

  String? captureMutationIdentity() => _mutations.captureIdentity();
  void checkMutationIdentity(String? uid) => _mutations.checkIdentity(uid);

  /// إضافة مخدوم جديد
  Future<String> addMakhdom(
    MakhdomModel makhdom, {
    String? operationId,
    String? expectedUid,
  }) => _mutations.saveProfile(
    expectedUid: expectedUid,
    patch: TrustedMutations.profileFields(makhdom),
    operationId: operationId,
  );

  /// تعديل بيانات مخدوم باستخدام Patch جزئي
  Future<void> updateMakhdomPatch(
    String id,
    MakhdomProfilePatch patch, {
    String? operationId,
    String? expectedUid,
  }) async {
    final fields = TrustedMutations.patchFields(patch);
    if (fields.isNotEmpty) {
      await _mutations.saveProfile(
        id: id,
        expectedUid: expectedUid,
        patch: fields,
        operationId: operationId,
      );
    }
  }

  /// تعديل بيانات مخدوم (متوافق): يحدّث الحقول القابلة للتعديل فقط دون لمس العدادات أو التواريخ
  Future<void> updateMakhdom(MakhdomModel makhdom) async {
    final patch = MakhdomProfilePatch(
      fullName: makhdom.fullName,
      phone: makhdom.phone,
      fatherPhone: makhdom.fatherPhone,
      motherPhone: makhdom.motherPhone,
      address: makhdom.address,
      area: makhdom.area,
      school: makhdom.school,
      secondaryType: makhdom.secondaryType,
      secondaryTypeCustomLabel: makhdom.secondaryTypeCustomLabel,
      grade: makhdom.grade,
      homeLocationUrl: makhdom.homeLocationUrl,
      isBrethrenOfLord: makhdom.isBrethrenOfLord,
      photoUrl: makhdom.photoUrl,
      notes: makhdom.notes,
      birthDate: makhdom.birthDate,
      clearBirthDate: makhdom.birthDate == null,
    );
    await updateMakhdomPatch(makhdom.id, patch);
  }

  /// حذف مخدوم منطقياً (أرشفة) مع فك ارتباطه وتعديل عداد خادمه ذرّياً
  Future<void> deleteMakhdom(String id) async {
    await _mutations.call('archiveMakhdom', {
      'makhdomId': id,
      'operationId': newOperationId('archive'),
    });
  }

  /// إضافة قائمة مخدومين دفعة واحدة (من شيت Excel) بأجزاء تطبيقية حدها 200 صف
  /// مع دعم importId لضمان عدم التكرار عند إعادة المحاولة (Idempotent Bulk Import)
  Future<int> addBulkMakhdomeen(
    List<MakhdomModel> list, {
    String? importId,
    int chunkSize = 200,
    void Function(int processed, int total)? onProgress,
  }) async {
    final result = await ImportCoordinator(
      mutations: _mutations,
    ).importRows(list, importId: importId, onProgress: onProgress);
    if (result.rejected.isNotEmpty) throw PartialImportFailure(result);
    return result.imported;
  }

  Future<ImportOutcome> importMakhdomeen(
    List<MakhdomModel> list, {
    void Function(int processed, int total)? onProgress,
  }) => (_providedImportCoordinator ?? ImportCoordinator(mutations: _mutations))
      .importRows(list, onProgress: onProgress);

  /// إسناد وتوزيع قائمة مخدومين لخادم معين (Transaction ذرّية تحافظ على عدادات كافة الخدام)
  Future<void> assignMakhdomeenToKhadem({
    required String khademId,
    required String khademName,
    required List<String> makhdomeenIds,
    Map<String, String?>? expectedAssignments,
    String? operationId,
    String? expectedUid,
  }) async {
    if (expectedAssignments == null) {
      throw ArgumentError('Expected assignments are required.');
    }
    await _mutations.assign(
      expectedUid: expectedUid,
      ids: makhdomeenIds,
      targetKhademId: khademId,
      expectedAssignments: expectedAssignments,
      operationId: operationId,
    );
  }

  /// إلغاء ربط مخدوم بخادم مع تحديث عداد الخادم ذرّياً
  Future<void> unassignMakhdom(
    String makhdomId, {
    required String? expectedKhademId,
    String? operationId,
    String? expectedUid,
  }) async {
    final expected = expectedKhademId;
    await _mutations.assign(
      expectedUid: expectedUid,
      ids: [makhdomId],
      expectedAssignments: {makhdomId: expected},
      operationId: operationId,
    );
  }

  // ===================== الخدام (Khodam) =====================

  /// جلب قائمة الخدام بث مباشر
  Stream<List<KhademModel>> getKhodamStream() {
    return _firestore
        .collection(AppConstants.colKhodam)
        .orderBy('name')
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => SnapshotList(
            snapshot.docs
                .map((doc) => KhademModel.fromMap(doc.data(), doc.id))
                .toList(),
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          ),
        );
  }

  /// جلب قائمة الخدام لسنة دراسية معينة فقط
  Stream<List<KhademModel>> getKhodamByGradeStream(String grade) {
    return _firestore
        .collection(AppConstants.colKhodam)
        .where('grade', isEqualTo: grade)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => KhademModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.name.compareTo(b.name));
          return SnapshotList(
            list,
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
        });
  }

  /// جلب قائمة الخدام الجدد في الانتظار (Pending)
  Stream<List<KhademModel>> getPendingKhodamStream() {
    return _firestore
        .collection(AppConstants.colKhodam)
        .where('role', isEqualTo: AppConstants.rolePending)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => KhademModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return SnapshotList(
            list,
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
        });
  }

  /// جلب بيانات خادم كـ Stream لمراقبة التسكين لحظياً
  Stream<KhademModel?> getKhademStream(String id) {
    return _firestore
        .collection(AppConstants.colKhodam)
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .map(
          (doc) => doc.exists && doc.data() != null
              ? KhademModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  /// تسكين خادم في سنة دراسية معينة (بواسطة أمين المرحلة عبر Cloud Function أو مباشرة)
  Future<void> assignKhademToGrade(String khademId, String grade) =>
      _privilegedOps.setKhademGrade(khademId: khademId, grade: grade);

  /// تعيين خادم كأمين لسنة دراسية معينة (بواسطة أمين المرحلة عبر Cloud Function أو مباشرة)
  Future<void> setGradeAdmin(String grade, String newAdminKhademId) =>
      _privilegedOps.setGradeAdmin(khademId: newAdminKhademId, grade: grade);

  /// إزالة صفة أمين السنة وتحويله لخادم عادي
  Future<void> removeGradeAdmin(String khademId) async {
    final profile = await getKhadem(khademId);
    if (profile?.grade == null) throw StateError('Missing grade');
    await _privilegedOps.setKhademGrade(
      khademId: khademId,
      grade: profile!.grade!,
    );
  }

  /// إضافة أو تحديث خادم بعد تسجيل الدخول
  Future<void> saveOrUpdateKhadem(KhademModel khadem) async {
    final ref = _firestore.collection(AppConstants.colKhodam).doc(khadem.id);
    if (!(await ref.get()).exists) {
      await ref.set({
        'name': khadem.name,
        'phone': khadem.phone,
        'email': khadem.email,
        'role': 'pending',
        'status': 'pending',
        'grade': null,
        'locale': 'ar',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// تحديث الملف الشخصي للخادم (الاسم ورقم التليفون) وتحديث اسمه لدى مخدوميه
  Future<void> updateKhademProfile({
    required String id,
    required String name,
    required String phone,
  }) => _firestore.collection(AppConstants.colKhodam).doc(id).update({
    'name': name,
    'phone': phone,
  });

  /// حذف حساب الخادم وفك ارتباط أولاده
  Future<void> deleteKhademAccount(String khademId) async {
    throw UnsupportedError(
      'Use reauthenticated requestAccountDeletion for the signed-in account.',
    );
  }

  /// جلب بيانات خادم محدد
  Future<KhademModel?> getKhadem(String khademId) async {
    final doc = await _firestore
        .collection(AppConstants.colKhodam)
        .doc(khademId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return KhademModel.fromMap(doc.data()!, doc.id);
  }

  /// تحديث عدد المخدومين التابعين للخادم
  Future<void> updateKhademAssignedCount(String khademId) async {
    throw UnsupportedError(
      'Assignment counters are maintained by trusted operations.',
    );
  }

  // ===================== الافتقاد والزيارات (Visits) =====================

  /// تسجيل زيارة أو مكالمة جديدة باستخدام Transaction تحافظ على آخر تاريخ وآخر ID
  Future<String> recordVisit(VisitModel visit, {String? operationId}) =>
      FirestoreVisitRepository(
        mutations: _mutations,
        userId: () => visit.khademId,
      ).recordVisit(visit: visit, operationId: operationId);

  /// تحديث أو إضافة ملاحظات ديسكريبشن لزيارة مسجلة مسبقاً مع حماية ملخص المخدوم
  Future<void> updateVisitNotes({
    required String visitId,
    required String makhdomId,
    required String notes,
  }) async {
    await _mutations.call('updateVisitNotes', {
      'visitId': visitId,
      'notes': notes.trim(),
    });
  }

  /// جلب سجل افتقادات مخدوم معين بترتيب زمني ثابت
  Stream<List<VisitModel>> getVisitsForMakhdomStream(
    String makhdomId, {
    DateTime? from,
    DateTime? to,
  }) => watchVisitsWindow(makhdomId: makhdomId, from: from, to: to);

  Stream<List<VisitModel>> getAllVisitsStream({
    DateTime? from,
    DateTime? to,
    String? grade,
    String? khademId,
  }) => watchVisitsWindow(grade: grade, khademId: khademId, from: from, to: to);

  Query<Map<String, dynamic>> _visitWindowQuery({
    String? makhdomId,
    String? grade,
    String? khademId,
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      AppConstants.colVisits,
    );
    if (makhdomId != null) {
      query = query.where('makhdomId', isEqualTo: makhdomId);
    } else if (grade != null) {
      query = query.where('grade', isEqualTo: grade);
    } else if (khademId != null) {
      query = query.where('khademId', isEqualTo: khademId);
    }
    if (from != null) {
      query = query.where(
        'visitDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(calendarDay(from)),
      );
    }
    if (to != null) {
      query = query.where(
        'visitDate',
        isLessThan: Timestamp.fromDate(calendarDay(to, 1)),
      );
    }
    return query
        .orderBy('visitDate', descending: true)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Stream<List<VisitModel>> watchVisitsWindow({
    String? makhdomId,
    String? grade,
    String? khademId,
    DateTime? from,
    DateTime? to,
  }) {
    return _visitWindowQuery(
          makhdomId: makhdomId,
          grade: grade,
          khademId: khademId,
          from: from,
          to: to,
        )
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => SnapshotList<VisitModel>.fromSnapshot(
            snapshot,
            (doc) => VisitModel.fromMap(doc.data(), doc.id),
          ),
        )
        .handleError(
          (Object e, StackTrace st) => throw AppFailure.fromException(e, st),
        );
  }

  /// Reads every currently assigned child's window, at most four requests in flight.
  /// Cancelling a changed assignment scope prevents scheduling further groups.
  Stream<List<VisitModel>> watchVisitsForChildrenWindow(
    List<String> childIds, {
    DateTime? from,
    DateTime? to,
  }) {
    late StreamController<List<VisitModel>> controller;
    var cancelled = false;
    controller = StreamController(
      onListen: () async {
        try {
          final ids = childIds.toSet().toList()..sort();
          final items = <VisitModel>[];
          var cached = false, pending = false;
          for (var offset = 0; offset < ids.length && !cancelled; offset += 4) {
            final group = ids.skip(offset).take(4);
            final snapshots = await Future.wait(
              group.map(
                (id) =>
                    _visitWindowQuery(makhdomId: id, from: from, to: to).get(),
              ),
            );
            if (cancelled) return;
            for (final snap in snapshots) {
              cached = cached || snap.metadata.isFromCache;
              pending = pending || snap.metadata.hasPendingWrites;
              items.addAll(
                snap.docs.map((doc) => VisitModel.fromMap(doc.data(), doc.id)),
              );
            }
          }
          if (!cancelled) {
            controller.add(
              SnapshotList(
                items,
                isFromCache: cached,
                hasPendingWrites: pending,
              ),
            );
            await controller.close();
          }
        } catch (e, st) {
          if (!cancelled) {
            controller.addError(AppFailure.fromException(e, st), st);
            await controller.close();
          }
        }
      },
      onCancel: () {
        cancelled = true;
      },
    );
    return controller.stream;
  }

  // ===================== المهام (Tasks) =====================

  /// جلب المهام المسندة لخادم معين (سواء من أمين المرحلة أو أمين سنته)
  Stream<List<TaskModel>> getTasksForKhademStream(String khademId) {
    return _firestore
        .collection(AppConstants.colTasks)
        .where('assignedKhademId', isEqualTo: khademId)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final list = snapshot.docs
              .where((doc) => doc.data()['status'] != 'cancelled')
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return SnapshotList(
            list,
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
        });
  }

  /// جلب مهام سنة دراسية معينة (لأمين السنة)
  Stream<List<TaskModel>> getTasksForGradeStream(String grade) {
    return _firestore
        .collection(AppConstants.colTasks)
        .where('grade', isEqualTo: grade)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final list = snapshot.docs
              .where((doc) => doc.data()['status'] != 'cancelled')
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return SnapshotList(
            list,
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
        });
  }

  /// جلب جميع المهام للمرحلة ككل (لأمين مرحلة ثانوي)
  Stream<List<TaskModel>> getAllTasksStream() {
    return _firestore
        .collection(AppConstants.colTasks)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final list = snapshot.docs
              .where((doc) => doc.data()['status'] != 'cancelled')
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return SnapshotList(
            list,
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          );
        });
  }

  /// إضافة مهمة جديدة
  Future<String> addTask(TaskModel task, {String? operationId}) =>
      _mutations.createTask(task, operationId ?? newOperationId('task'));

  /// إضافة مهمة جديدة مع إشعار Outbox ذري يمنع تباين حالة التكليف عن الإشعار
  Future<String> createTaskWithOutbox({
    required TaskModel task,
    required String outboxTitle,
    required String outboxBody,
    String? operationId,
  }) => addTask(task, operationId: operationId);

  /// تبديل حالة إنجاز المهمة (تم الإنجاز / لم يتم)
  Future<void> toggleTaskStatus(String taskId, bool isCompleted) async {
    await _firestore.collection(AppConstants.colTasks).doc(taskId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? Timestamp.now() : null,
    });
  }

  /// حذف مهمة
  Future<void> deleteTask(String taskId, {String? operationId}) async {
    final op =
        operationId ??
        _deleteOperations.putIfAbsent(
          taskId,
          () => newOperationId('delete_task'),
        );
    await _mutations.call('deleteTask', {'taskId': taskId, 'operationId': op});
    _deleteOperations.remove(taskId);
  }

  // ===================== الحضور والغياب (Attendance) =====================

  /// جلب جلسة حضور محددة بالبث المباشر
  Stream<AttendanceSessionModel?> getAttendanceSessionStream(
    String sessionId,
  ) => FirestoreAttendanceRepository(
    firestore: _firestore,
    mutations: _mutations,
  ).watchGradeSession(sessionId: sessionId, grade: sessionId.split('_').last);

  /// تبديل حالة حضور مخدوم بلحظية تامة في قاعدة البيانات
  Future<void> toggleMakhdomAttendance({
    required String sessionId,
    required String date,
    required String type,
    required String grade,
    required String makhdomId,
    required bool isAttended,
    required String khademId,
    required String khademName,
    String? taskId,
    String? operationId,
  }) async {
    await _mutations.call('setAttendancePresence', {
      'sessionId': sessionId,
      'date': date,
      'type': type,
      'grade': grade,
      'makhdomId': makhdomId,
      'isPresent': isAttended,
      if (taskId != null) 'taskId': taskId,
      'operationId': operationId ?? newOperationId('presence'),
    });
  }

  /// جلب كافة جلسات الحضور مرتبة تنازلياً حسب التاريخ
  Stream<List<AttendanceSessionModel>> getAllAttendanceSessionsStream({
    DateTime? from,
    DateTime? to,
  }) async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const AppFailure(
        code: 'unauthenticated',
        message: '',
        retryable: false,
      );
    }
    final profile = await getKhadem(uid);
    if (profile?.status != 'active') {
      throw const AppFailure(
        code: 'permission-denied',
        message: '',
        retryable: false,
      );
    }
    yield* watchAttendanceWindow(
      grade: profile!.isStageAdmin ? null : profile.grade,
      from: from,
      to: to,
    );
  }

  Stream<List<AttendanceSessionModel>> watchAttendanceWindow({
    String? grade,
    DateTime? from,
    DateTime? to,
  }) {
    if (grade != null) {
      return watchGradeAttendance(grade: grade, from: from, to: to);
    }
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('grades')
        .where('grade', whereIn: ['1st', '2nd', '3rd']);
    if (from != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime.utc(from.year, from.month, from.day),
        ),
      );
    }
    if (to != null) {
      query = query.where(
        'date',
        isLessThan: Timestamp.fromDate(
          DateTime.utc(to.year, to.month, to.day + 1),
        ),
      );
    }
    return query
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => SnapshotList<AttendanceSessionModel>.fromSnapshot(
            snapshot,
            (doc) => AttendanceSessionModel.fromMap(
              doc.data(),
              doc.data()['sessionId'] as String? ??
                  doc.reference.parent.parent!.id,
            ),
          ),
        )
        .handleError(
          (Object e, StackTrace st) => throw AppFailure.fromException(e, st),
        );
  }

  /// جلب جلسات الحضور لسنة دراسية وفترة زمنية محددة باستعلام مباشر على الخادم
  Stream<List<AttendanceSessionModel>> watchGradeAttendance({
    required String grade,
    DateTime? from,
    DateTime? to,
  }) => FirestoreAttendanceRepository(
    firestore: _firestore,
    mutations: _mutations,
  ).watchGradeAttendance(grade: grade, from: from, to: to);

  /// جلب جلسات الحضور الخاصة بسنة معينة وجلسات القداس العامة للمرحلة باستعلام مباشر
  Stream<List<AttendanceSessionModel>> getAttendanceSessionsForGradeStream(
    String grade, {
    DateTime? from,
    DateTime? to,
  }) {
    return watchGradeAttendance(grade: grade, from: from, to: to);
  }

  /// جلب صفحة من الزيارات للمخدوم باستخدام cursor للترتيب والتقسيم
  Future<PageResult<VisitModel>> fetchVisitPage({
    required String makhdomId,
    DocumentSnapshot? cursor,
    int limit = 50,
    DateTime? from,
    DateTime? to,
  }) => FirestoreVisitRepository(firestore: _firestore, mutations: _mutations)
      .fetchVisitPage(
        makhdomId: makhdomId,
        cursor: cursor,
        limit: limit,
        from: from,
        to: to,
      );

  // ===================== الإشعارات و FCM (Notifications) =====================

  /// حفظ وتحديث توكن FCM الخاص بجهاز الخادم
  Future<void> updateKhademFcmToken(String khademId, String fcmToken) async {
    throw UnsupportedError(
      'Use DeviceRegistrationService to register installations.',
    );
  }

  /// حفظ إشعار جديد في فايرستور
  Future<String> saveNotification(NotificationModel notification) async {
    throw UnsupportedError(
      'Notifications must be created by a trusted server operation.',
    );
  }

  /// جلب إشعارات خادم معين بالبث المباشر (الأحدث أولاً)
  Stream<List<NotificationModel>> getNotificationsForUserStream(
    String userId,
  ) => FirestoreNotificationRepository(
    firestore: _firestore,
  ).watchNotificationsForUser(userId);
  Stream<int> watchUnreadNotificationCount(String userId) =>
      FirestoreNotificationRepository(
        firestore: _firestore,
      ).watchUnreadCount(userId);
  Future<PageResult<NotificationModel>> fetchNotificationPage({
    required String uid,
    DocumentSnapshot? cursor,
    int limit = 50,
  }) => FirestoreNotificationRepository(
    firestore: _firestore,
  ).fetchNotificationPage(uid: uid, cursor: cursor, limit: limit);

  /// تحديد إشعار كمقروء
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.colNotifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// تحديد كافة إشعارات المستخدم كمقروءة (على دفعات قابلة للاستكمال ومحمية من حدود 500 عملية)
  Future<void> markAllNotificationsAsRead(String userId) =>
      FirestoreNotificationRepository(
        firestore: _firestore,
      ).markAllNotificationsAsRead(userId);
}

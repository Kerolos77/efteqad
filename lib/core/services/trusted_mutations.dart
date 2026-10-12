import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../errors/app_failure.dart';
import '../models/task_model.dart';
import '../models/makhdom_model.dart';
import '../models/makhdom_profile_patch.dart';

typedef CallableTransport =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> payload,
    );
String newOperationId(String kind) =>
    '${kind}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(0x7fffffff)}';

class PartialAssignmentFailure implements Exception {
  final int assignedCount;
  final List<Map<String, dynamic>> failures;
  const PartialAssignmentFailure(this.assignedCount, this.failures);
  List<String> get failedIds =>
      failures.map((r) => (r['id'] ?? r['makhdomId']).toString()).toList();
  @override
  String toString() =>
      '$assignedCount assignments saved; ${failures.map((r) => "${r['id'] ?? r['makhdomId']}: ${r['status']}").join(', ')}';
}

class TrustedMutations {
  final CallableTransport _transport;
  final String Function()? _userId;
  String? captureIdentity() {
    final uid = _userId?.call();
    if (uid != null && uid.isEmpty) {
      throw StateError('Authentication required.');
    }
    return uid;
  }

  void checkIdentity(String? uid) {
    if (uid != null && _userId != null && _userId() != uid) {
      throw StateError(
        'The initiating account changed. Resume with that account.',
      );
    }
  }

  TrustedMutations({
    CallableTransport? transport,
    FirebaseFunctions? functions,
    String Function()? userId,
  }) : _userId =
           userId ??
           (transport == null
               ? (() =>
                     (functions == null
                             ? FirebaseAuth.instance
                             : FirebaseAuth.instanceFor(app: functions.app))
                         .currentUser
                         ?.uid ??
                     '')
               : null),
       _transport =
           transport ??
           ((name, payload) async {
             final result = await (functions ?? FirebaseFunctions.instance)
                 .httpsCallable(name)
                 .call<Map<dynamic, dynamic>>(payload);
             return Map<String, dynamic>.from(result.data);
           });
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> payload, {
    String? expectedUid,
  }) async {
    final uid =
        expectedUid ?? payload['expectedUid'] as String? ?? captureIdentity();
    checkIdentity(uid);
    try {
      final result = await _transport(name, {
        ...payload,
        if (uid != null) 'expectedUid': uid,
      });
      checkIdentity(uid);
      if (result['success'] == false) {
        throw StateError(result['error']?.toString() ?? 'Operation failed');
      }
      return result;
    } catch (e, st) {
      throw AppFailure.fromException(e, st);
    }
  }

  Future<String> createTask(TaskModel task, String operationId) async =>
      (await call('createTask', {
            'operationId': operationId,
            'taskData': {
              'title': task.title,
              'description': task.description,
              'assignedKhademId': task.assignedKhademId,
              'grade': task.grade,
              'type': task.type,
              if (task.dueDate != null)
                'dueDate': task.dueDate!.toIso8601String(),
            },
          }))['taskId']
          as String;
  static Map<String, dynamic> profileFields(MakhdomModel m) => {
    'fullName': m.fullName,
    'phone': m.phone,
    'fatherPhone': m.fatherPhone,
    'motherPhone': m.motherPhone,
    'address': m.address,
    'area': m.area,
    'school': m.school,
    'secondaryType': m.secondaryType,
    'secondaryTypeCustomLabel': m.secondaryTypeCustomLabel,
    'grade': m.grade,
    'homeLocationUrl': m.homeLocationUrl,
    'isBrethrenOfLord': m.isBrethrenOfLord,
    'photoUrl': m.photoUrl,
    'birthDate': m.birthDate?.toIso8601String(),
    'notes': m.notes,
    if (m.trackingStartDate != null && !m.isTrackingEstimated)
      'trackingStartDate': m.trackingStartDate!.toIso8601String(),
  };
  static Map<String, dynamic> patchFields(MakhdomProfilePatch p) {
    if (p.active != null) {
      throw ArgumentError('Use archiveMakhdom for protected active state.');
    }
    return {
      if (p.fullName != null) 'fullName': p.fullName,
      if (p.phone != null) 'phone': p.phone,
      if (p.fatherPhone != null) 'fatherPhone': p.fatherPhone,
      if (p.motherPhone != null) 'motherPhone': p.motherPhone,
      if (p.address != null) 'address': p.address,
      if (p.area != null) 'area': p.area,
      if (p.school != null) 'school': p.school,
      if (p.secondaryType != null) 'secondaryType': p.secondaryType,
      if (p.clearSecondaryTypeCustomLabel || p.secondaryTypeCustomLabel != null)
        'secondaryTypeCustomLabel': p.clearSecondaryTypeCustomLabel
            ? null
            : p.secondaryTypeCustomLabel,
      if (p.clearTrackingStartDate || p.trackingStartDate != null)
        'trackingStartDate': p.clearTrackingStartDate
            ? null
            : p.trackingStartDate!.toIso8601String(),
      if (p.grade != null) 'grade': p.grade,
      if (p.isBrethrenOfLord != null) 'isBrethrenOfLord': p.isBrethrenOfLord,
      if (p.clearPhotoUrl || p.photoUrl != null)
        'photoUrl': p.clearPhotoUrl ? null : p.photoUrl,
      if (p.clearBirthDate || p.birthDate != null)
        'birthDate': p.clearBirthDate ? null : p.birthDate!.toIso8601String(),
      if (p.clearHomeLocationUrl || p.homeLocationUrl != null)
        'homeLocationUrl': p.clearHomeLocationUrl ? null : p.homeLocationUrl,
      if (p.clearNotes || p.notes != null)
        'notes': p.clearNotes ? null : p.notes,
    };
  }

  Future<String> saveProfile({
    String? id,
    required Map<String, dynamic> patch,
    String? operationId,
    String? expectedUid,
  }) async =>
      (await call('saveMakhdomProfile', {
            if (id != null) 'makhdomId': id,
            'patch': patch,
            'operationId': operationId ?? newOperationId('profile'),
          }, expectedUid: expectedUid))['makhdomId']
          as String;
  Future<void> assign({
    required List<String> ids,
    String? targetKhademId,
    required Map<String, String?> expectedAssignments,
    String? operationId,
    String? expectedUid,
  }) async {
    final uid = expectedUid ?? captureIdentity();
    checkIdentity(uid);
    if (ids.isEmpty) return;
    final unique = ids.toSet().toList();
    final base = operationId ?? newOperationId('assignment');
    var assigned = 0;
    final failures = <Map<String, dynamic>>[];
    for (var offset = 0; offset < unique.length; offset += 200) {
      final end = offset + 200 < unique.length ? offset + 200 : unique.length;
      final chunk = unique.sublist(offset, end);
      if (chunk.any((id) => !expectedAssignments.containsKey(id))) {
        throw ArgumentError(
          'Every child requires an explicit expected assignment.',
        );
      }
      final result = await call('assignMakhdoms', {
        'ids': chunk,
        'targetKhademId': targetKhademId,
        'expectedAssignments': {
          for (final id in chunk) id: expectedAssignments[id],
        },
        'operationId': '${base}_chunk_${offset ~/ 200}',
      }, expectedUid: uid);
      assigned += (result['assignedCount'] as num?)?.toInt() ?? 0;
      failures.addAll(
        (result['results'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .where((r) => !['assigned', 'unchanged'].contains(r['status'])),
      );
    }
    if (failures.isNotEmpty) throw PartialAssignmentFailure(assigned, failures);
  }
}

String canonicalVisitType(String value) {
  switch (value
      .trim()
      .replaceFirst(RegExp(r'^[🏠📞⛪💬]\s*', unicode: true), '')
      .toLowerCase()) {
    case 'home':
    case 'منزلية':
    case 'زيارة منزلية':
    case 'زيارة بيت':
    case 'home visit':
      return 'home';
    case 'phone':
    case 'مكالمة تليفونية':
    case 'تليفونية':
    case 'مكالمة':
    case 'مكالمة هاتفية':
    case 'phone call':
      return 'phone';
    case 'church':
    case 'كنيسة':
    case 'church meetup':
    case 'لقاء في الكنيسة':
    case 'لقاء بالكنيسة':
    case 'church meeting':
      return 'church';
    case 'other':
    case 'message / other':
    case 'رسالة / أخرى':
    case 'أخرى':
    case 'اخرى':
      return 'other';
    default:
      return value; // Legacy custom labels remain user text.
  }
}

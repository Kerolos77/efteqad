import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

class KhademModel {
  final String id; // UID from Firebase Auth
  final String email;
  final String name;
  final String phone;
  final String? colorHex;
  final int assignedCount;
  final String role; // 'stageAdmin', 'gradeAdmin', 'servant', 'pending'
  final String? grade; // '1st', '2nd', '3rd', or null
  final String status; // 'active', 'pending'
  final String? locale;
  final String? fcmToken; // FCM push token for device
  final DateTime createdAt;

  const KhademModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.colorHex,
    this.assignedCount = 0,
    this.role = AppConstants.rolePending,
    this.grade,
    this.status = AppConstants.rolePending,
    this.locale,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isStageAdmin => role == AppConstants.roleStageAdmin;
  bool get isGradeAdmin => role == AppConstants.roleGradeAdmin;
  bool get isPending =>
      role == AppConstants.rolePending ||
      status == AppConstants.rolePending ||
      (role != AppConstants.roleStageAdmin && grade == null);
  bool get isActive => !isPending;

  KhademModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? colorHex,
    int? assignedCount,
    String? role,
    String? grade,
    String? status,
    String? locale,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return KhademModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      colorHex: colorHex ?? this.colorHex,
      assignedCount: assignedCount ?? this.assignedCount,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      locale: locale ?? this.locale,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'colorHex': colorHex,
      'assignedCount': assignedCount,
      'role': role,
      'grade': grade,
      'status': status,
      'locale': locale,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory KhademModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return KhademModel(
      id: docId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      colorHex: map['colorHex'],
      assignedCount: (map['assignedCount'] is num)
          ? (map['assignedCount'] as num).toInt()
          : 0,
      role: map['role'] ?? AppConstants.rolePending,
      grade: map['grade'],
      status:
          map['status'] ??
          (map['grade'] != null ? 'active' : AppConstants.rolePending),
      locale: map['locale'] is String ? map['locale'] as String : null,
      fcmToken: map['fcmToken'],
      createdAt: parseDate(map['createdAt']),
    );
  }
}

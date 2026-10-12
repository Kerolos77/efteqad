import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

class MakhdomModel {
  final String id;
  final String fullName; // 1. الاسم رباعي
  final String phone; // 2. رقم تليفون المخدوم
  final String fatherPhone; // 3. رقم تليفون الأب
  final String motherPhone; // 4. رقم تليفون الأم
  final String address; // 5. العنوان بالتفصيل
  final String area; // 6. المنطقة
  final String school; // 7. المدرسة
  final String secondaryType; // 8. نوع الثانوية (عامة، صنايع، فني، خدمات...)
  final String? secondaryTypeCustomLabel;
  final String grade; // السنة الدراسية: '1st', '2nd', '3rd'
  final String?
  homeLocationUrl; // 9. لوكيشن بيت المخدوم (رابط خريطة أو إحداثيات)
  final bool isBrethrenOfLord; // 10. أخوة رب (نعم / لا)
  final String? photoUrl; // 11. لينك صورة المخدوم
  final String? assignedKhademId; // معرّف الخادم المربوط به
  final String? assignedKhademName; // اسم الخادم المربوط به
  final DateTime? birthDate; // تاريخ الميلاد
  final String? notes; // ملاحظات
  final String? lastVisitNotes; // ملخص آخر زيارة
  final int visitCount; // عدد مرات الافتقاد
  final DateTime? lastVisitDate; // تاريخ آخر افتقاد
  final DateTime? trackingStartDate; // تاريخ بدء التتبع (إن وُجد)
  final bool trackingStartEstimated;
  final bool createdAtKnown;
  final String? legacyNotes;
  final bool active; // حالة التفعيل (false = مؤرشف)
  final DateTime createdAt;

  const MakhdomModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.birthDate,
    this.fatherPhone = '',
    this.motherPhone = '',
    this.address = '',
    this.area = '',
    this.school = '',
    this.secondaryType = '',
    this.secondaryTypeCustomLabel,
    this.grade = AppConstants.grade1st,
    this.homeLocationUrl,
    this.isBrethrenOfLord = false,
    this.photoUrl,
    this.assignedKhademId,
    this.assignedKhademName,
    this.notes,
    this.lastVisitNotes,
    this.visitCount = 0,
    this.lastVisitDate,
    this.trackingStartDate,
    this.trackingStartEstimated = false,
    this.createdAtKnown = true,
    this.legacyNotes,
    this.active = true,
    required this.createdAt,
  });

  bool get isAssigned =>
      assignedKhademId != null && assignedKhademId!.trim().isNotEmpty;

  bool get isAgeEstimated => birthDate == null;

  /// تاريخ بدء التتبع الفعلي؛ في حال عدم تحديده نعتمد تاريخ الإنشاء كتقدير افتراضي
  DateTime get effectiveTrackingStartDate => trackingStartDate ?? createdAt;

  /// هل تاريخ التتبع تقديري غير معتمد صراحة؟
  bool get isTrackingEstimated =>
      trackingStartDate == null || trackingStartEstimated;

  bool get hasKnownTrackingOrigin =>
      trackingStartDate != null || createdAtKnown;

  int? get age {
    if (birthDate != null) {
      final now = DateTime.now();
      int a = now.year - birthDate!.year;
      if (now.month < birthDate!.month ||
          (now.month == birthDate!.month && now.day < birthDate!.day)) {
        a--;
      }
      return a >= 0 ? a : null;
    }
    // حساب العمر تلقائياً بناءً على السنة الدراسية لمرحلة ثانوي (15/16/17 سنة)
    switch (grade) {
      case AppConstants.grade1st:
        return 15;
      case AppConstants.grade2nd:
        return 16;
      case AppConstants.grade3rd:
        return 17;
      default:
        return 15;
    }
  }

  MakhdomModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? fatherPhone,
    String? motherPhone,
    String? address,
    String? area,
    String? school,
    String? secondaryType,
    String? secondaryTypeCustomLabel,
    bool clearSecondaryTypeCustomLabel = false,
    String? grade,
    String? homeLocationUrl,
    bool? isBrethrenOfLord,
    String? photoUrl,
    String? assignedKhademId,
    String? assignedKhademName,
    String? notes,
    String? lastVisitNotes,
    int? visitCount,
    DateTime? lastVisitDate,
    DateTime? trackingStartDate,
    bool clearTrackingStartDate = false,
    bool? trackingStartEstimated,
    bool? createdAtKnown,
    String? legacyNotes,
    bool? active,
    DateTime? createdAt,
  }) {
    return MakhdomModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      fatherPhone: fatherPhone ?? this.fatherPhone,
      motherPhone: motherPhone ?? this.motherPhone,
      address: address ?? this.address,
      area: area ?? this.area,
      school: school ?? this.school,
      secondaryType: secondaryType ?? this.secondaryType,
      secondaryTypeCustomLabel: clearSecondaryTypeCustomLabel
          ? null
          : secondaryTypeCustomLabel ?? this.secondaryTypeCustomLabel,
      grade: grade ?? this.grade,
      homeLocationUrl: homeLocationUrl ?? this.homeLocationUrl,
      isBrethrenOfLord: isBrethrenOfLord ?? this.isBrethrenOfLord,
      photoUrl: photoUrl ?? this.photoUrl,
      assignedKhademId: assignedKhademId ?? this.assignedKhademId,
      assignedKhademName: assignedKhademName ?? this.assignedKhademName,
      notes: notes ?? this.notes,
      lastVisitNotes: lastVisitNotes ?? this.lastVisitNotes,
      visitCount: visitCount ?? this.visitCount,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      trackingStartDate: clearTrackingStartDate
          ? null
          : (trackingStartDate ?? this.trackingStartDate),
      trackingStartEstimated: clearTrackingStartDate
          ? false
          : trackingStartEstimated ??
                (trackingStartDate != null
                    ? false
                    : this.trackingStartEstimated),
      createdAtKnown: createdAtKnown ?? this.createdAtKnown,
      legacyNotes: legacyNotes ?? this.legacyNotes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'age': age,
      'fatherPhone': fatherPhone,
      'motherPhone': motherPhone,
      'address': address,
      'area': area,
      'school': school,
      'secondaryType': secondaryType,
      'secondaryTypeCustomLabel': secondaryTypeCustomLabel,
      'grade': grade,
      'homeLocationUrl': homeLocationUrl,
      'isBrethrenOfLord': isBrethrenOfLord,
      'photoUrl': photoUrl,
      'assignedKhademId': assignedKhademId,
      'assignedKhademName': assignedKhademName,
      'notes': notes,
      'description': notes,
      'lastVisitNotes': lastVisitNotes,
      'visitCount': visitCount,
      'lastVisitDate': lastVisitDate != null
          ? Timestamp.fromDate(lastVisitDate!)
          : null,
      'trackingStartDate': trackingStartDate != null
          ? Timestamp.fromDate(trackingStartDate!)
          : null,
      'trackingStartEstimated': isTrackingEstimated,
      'createdAtKnown': createdAtKnown,
      'legacyNotes': legacyNotes,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MakhdomModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawNotes = map['notes'] ?? map['description'];
    final notesStr = rawNotes?.toString().trim();
    final rawLastVisitNotes = map['lastVisitNotes'];
    final lastVisitNotesStr = rawLastVisitNotes?.toString().trim();

    return MakhdomModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: parseDate(map['birthDate']),
      fatherPhone: map['fatherPhone'] ?? '',
      motherPhone: map['motherPhone'] ?? '',
      address: map['address'] ?? '',
      area: map['area'] ?? '',
      school: map['school'] ?? '',
      secondaryType: map['secondaryType'] ?? '',
      secondaryTypeCustomLabel: map['secondaryTypeCustomLabel'] as String?,
      grade: map['grade'] ?? AppConstants.grade1st,
      homeLocationUrl: map['homeLocationUrl'],
      isBrethrenOfLord: map['isBrethrenOfLord'] is bool
          ? map['isBrethrenOfLord']
          : (map['isBrethrenOfLord']?.toString().toLowerCase() == 'true' ||
                map['isBrethrenOfLord']?.toString() == 'نعم'),
      photoUrl: map['photoUrl'],
      assignedKhademId: map['assignedKhademId'],
      assignedKhademName: map['assignedKhademName'],
      notes: (notesStr != null && notesStr.isNotEmpty) ? notesStr : null,
      lastVisitNotes:
          (lastVisitNotesStr != null && lastVisitNotesStr.isNotEmpty)
          ? lastVisitNotesStr
          : null,
      visitCount: (map['visitCount'] is num)
          ? (map['visitCount'] as num).toInt()
          : 0,
      lastVisitDate: parseDate(map['lastVisitDate']),
      trackingStartDate: parseDate(map['trackingStartDate']),
      trackingStartEstimated: map['trackingStartEstimated'] == true,
      createdAtKnown:
          map['createdAtKnown'] != false && parseDate(map['createdAt']) != null,
      legacyNotes: map['legacyNotes'] as String?,
      active: map['active'] == false ? false : true,
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }
}

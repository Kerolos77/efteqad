import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String status;
  final String title;
  final String description;
  final String assignedKhademId;
  final String assignedKhademName;
  final String grade; // '1st', '2nd', '3rd', or 'all'
  final String createdById;
  final String createdByName;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String? _attendanceDay;
  // Attendance uses a UTC calendar key, independent of the viewer's display date.
  String? get attendanceDay =>
      _attendanceDay ?? dueDate?.toIso8601String().substring(0, 10);
  final String type; // 'general', 'attendance', 'visitation'
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    this.status = 'active',
    required this.title,
    this.description = '',
    required this.assignedKhademId,
    required this.assignedKhademName,
    required this.grade,
    required this.createdById,
    required this.createdByName,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    String? attendanceDay,
    this.type = 'general',
    required this.createdAt,
  }) : _attendanceDay = attendanceDay;

  bool get isAttendanceTask =>
      type == 'attendance' ||
      type == 'attendance_khedma' ||
      type == 'attendance_qoddas';

  bool get isMassAttendance => type == 'attendance_qoddas';
  bool get isServiceAttendance =>
      type == 'attendance' || type == 'attendance_khedma';

  TaskModel copyWith({
    String? id,
    String? status,
    String? title,
    String? description,
    String? assignedKhademId,
    String? assignedKhademName,
    String? grade,
    String? createdById,
    String? createdByName,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    String? attendanceDay,
    String? type,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedKhademId: assignedKhademId ?? this.assignedKhademId,
      assignedKhademName: assignedKhademName ?? this.assignedKhademName,
      grade: grade ?? this.grade,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      attendanceDay:
          attendanceDay ?? (dueDate == null ? this.attendanceDay : null),
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'title': title,
      'description': description,
      'assignedKhademId': assignedKhademId,
      'assignedKhademName': assignedKhademName,
      'grade': grade,
      'createdById': createdById,
      'createdByName': createdByName,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'attendanceDay': attendanceDay,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) =>
      TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TaskModel(
      id: docId,
      status: map['status'] ?? 'active',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedKhademId: map['assignedKhademId'] ?? '',
      assignedKhademName: map['assignedKhademName'] ?? '',
      grade: map['grade'] ?? 'all',
      createdById: map['createdById'] ?? '',
      createdByName: map['createdByName'] ?? '',
      isCompleted: map['isCompleted'] == true,
      completedAt: parseDate(map['completedAt']),
      dueDate: parseDate(map['dueDate']),
      attendanceDay:
          map['attendanceDay'] as String? ??
          parseDate(map['dueDate'])?.toUtc().toIso8601String().substring(0, 10),
      type: map['type'] ?? 'general',
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }
}

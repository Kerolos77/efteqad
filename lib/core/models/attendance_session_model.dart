import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionModel {
  final String
  id; // Format: ${date}_${type}_${grade} e.g. 2026-10-09_khedma_1st
  final String date; // YYYY-MM-DD
  final String type; // 'khedma' or 'qoddas'
  final String grade; // '1st', '2nd', '3rd', or 'all'
  final List<String> attendedMakhdomIds;
  final String takenByKhademId;
  final String takenByKhademName;
  final String status; // 'draft', 'finalized'
  final DateTime? finalizedAt;
  final DateTime updatedAt;

  const AttendanceSessionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.grade,
    this.attendedMakhdomIds = const [],
    this.takenByKhademId = '',
    this.takenByKhademName = '',
    this.status = 'draft',
    this.finalizedAt,
    required this.updatedAt,
  });

  bool isAttended(String makhdomId) => attendedMakhdomIds.contains(makhdomId);
  int get attendedCount => attendedMakhdomIds.length;
  bool get isMass => type == 'qoddas';
  bool get isService => type == 'khedma';
  bool get isFinalized => status == 'finalized';
  bool get isDraft => status == 'draft';

  static String generateSessionId({
    required String date,
    required String type,
    required String grade,
  }) {
    return '${date}_${type}_$grade';
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'grade': grade,
      'attendedMakhdomIds': attendedMakhdomIds,
      'takenByKhademId': takenByKhademId,
      'takenByKhademName': takenByKhademName,
      'status': status,
      'finalizedAt': finalizedAt != null
          ? Timestamp.fromDate(finalizedAt!)
          : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AttendanceSessionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    // The trusted backend's session ID/day uses UTC calendar dates. Retain that
    // day regardless of the viewing device's time zone; legacy strings read as-is.
    String parseSessionDay(dynamic value) {
      if (value is String) return value;
      if (value is Timestamp) {
        final date = value.toDate().toUtc();
        return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return '';
    }

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawList = map['attendedMakhdomIds'];
    final attendedIds = rawList is List
        ? rawList.map((e) => e.toString()).toList()
        : <String>[];

    return AttendanceSessionModel(
      id: docId,
      date: parseSessionDay(map['date']),
      type: map['type'] ?? 'khedma',
      grade: map['grade'] ?? '1st',
      attendedMakhdomIds: attendedIds,
      takenByKhademId: map['takenByKhademId'] ?? '',
      takenByKhademName: map['takenByKhademName'] ?? '',
      status: map['status'] ?? 'draft',
      finalizedAt: parseNullableDate(map['finalizedAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  AttendanceSessionModel copyWith({
    String? id,
    String? date,
    String? type,
    String? grade,
    List<String>? attendedMakhdomIds,
    String? takenByKhademId,
    String? takenByKhademName,
    String? status,
    DateTime? finalizedAt,
    DateTime? updatedAt,
  }) {
    return AttendanceSessionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      grade: grade ?? this.grade,
      attendedMakhdomIds: attendedMakhdomIds ?? this.attendedMakhdomIds,
      takenByKhademId: takenByKhademId ?? this.takenByKhademId,
      takenByKhademName: takenByKhademName ?? this.takenByKhademName,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

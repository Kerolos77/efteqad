import 'package:cloud_firestore/cloud_firestore.dart';

class VisitModel {
  final String id;
  final String makhdomId;
  final String makhdomName;
  final String khademId;
  final String khademName;
  final DateTime visitDate;
  final String
  visitType; // 'زيارة منزلية', 'مكالمة تليفونية', 'لقاء في الكنيسة'
  final String? notes;
  final DateTime createdAt;

  const VisitModel({
    required this.id,
    required this.makhdomId,
    required this.makhdomName,
    required this.khademId,
    required this.khademName,
    required this.visitDate,
    required this.visitType,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'makhdomId': makhdomId,
      'makhdomName': makhdomName,
      'khademId': khademId,
      'servantId': khademId,
      'khademName': khademName,
      'servantName': khademName,
      'visitDate': Timestamp.fromDate(visitDate),
      'visitType': visitType,
      'notes': notes,
      'description': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  VisitModel copyWith({
    String? id,
    String? makhdomId,
    String? makhdomName,
    String? khademId,
    String? khademName,
    DateTime? visitDate,
    String? visitType,
    String? notes,
    DateTime? createdAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      makhdomId: makhdomId ?? this.makhdomId,
      makhdomName: makhdomName ?? this.makhdomName,
      khademId: khademId ?? this.khademId,
      khademName: khademName ?? this.khademName,
      visitDate: visitDate ?? this.visitDate,
      visitType: visitType ?? this.visitType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory VisitModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawNotes =
        map['notes'] ??
        map['description'] ??
        map['desc'] ??
        map['details'] ??
        map['comment'] ??
        map['report'] ??
        map['content'];

    final notesStr = rawNotes?.toString().trim();

    return VisitModel(
      id: docId,
      makhdomId: map['makhdomId'] ?? '',
      makhdomName: map['makhdomName'] ?? '',
      khademId: map['khademId'] ?? '',
      khademName: map['khademName'] ?? '',
      visitDate: parseDate(map['visitDate']),
      visitType: map['visitType'] ?? 'home',
      notes: (notesStr != null && notesStr.isNotEmpty) ? notesStr : null,
      createdAt: parseDate(map['createdAt']),
    );
  }
}

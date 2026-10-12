import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String recipientName;
  final String title;
  final String body;
  final String? templateKey;
  final Map<String, dynamic> templateArgs;
  final String type; // 'task', 'absence_alert', 'general'
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    this.recipientName = '',
    required this.title,
    required this.body,
    this.templateKey,
    this.templateArgs = const {},
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  bool get isTask => type == 'task';
  bool get isAbsenceAlert => type == 'absence_alert';
  String? get relatedTaskId => data['taskId']?.toString();
  String? get relatedMakhdomId => data['makhdomId']?.toString();

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? recipientName,
    String? title,
    String? body,
    String? templateKey,
    Map<String, dynamic>? templateArgs,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      title: title ?? this.title,
      body: body ?? this.body,
      templateKey: templateKey ?? this.templateKey,
      templateArgs: templateArgs ?? this.templateArgs,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientName': recipientName,
      'title': title,
      'body': body,
      if (templateKey != null) 'templateKey': templateKey,
      'templateArgs': templateArgs,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawData = map['data'];
    Map<String, dynamic> dataMap = {};
    if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    }

    return NotificationModel(
      id: docId,
      recipientId: map['recipientId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      templateKey: map['templateKey'] is String
          ? map['templateKey'] as String
          : null,
      templateArgs: map['templateArgs'] is Map
          ? Map<String, dynamic>.from(map['templateArgs'])
          : const {},
      type: map['type'] ?? 'general',
      data: dataMap,
      isRead: map['isRead'] ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}

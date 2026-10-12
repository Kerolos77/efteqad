import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efteqad/core/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    final now = DateTime.now();

    test('NotificationModel serialization and deserialization works correctly', () {
      final notification = NotificationModel(
        id: 'notif_123',
        recipientId: 'khadem_456',
        recipientName: 'مينا سمير',
        title: 'مهمة جديدة: حضور الخدمة',
        body: 'تم تكليفك برصد حضور وغياب الخدمة',
        type: 'task',
        data: {'taskId': 'task_789', 'grade': '1st'},
        isRead: false,
        createdAt: now,
      );

      final map = notification.toMap();
      expect(map['recipientId'], 'khadem_456');
      expect(map['recipientName'], 'مينا سمير');
      expect(map['title'], 'مهمة جديدة: حضور الخدمة');
      expect(map['type'], 'task');
      expect(map['isRead'], isFalse);
      expect(map['data']['taskId'], 'task_789');

      // Test fromMap
      final parsed = NotificationModel.fromMap({
        'recipientId': 'khadem_456',
        'recipientName': 'مينا سمير',
        'title': 'مهمة جديدة: حضور الخدمة',
        'body': 'تم تكليفك برصد حضور وغياب الخدمة',
        'type': 'task',
        'data': {'taskId': 'task_789', 'grade': '1st'},
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      }, 'notif_123');

      expect(parsed.id, 'notif_123');
      expect(parsed.isTask, isTrue);
      expect(parsed.isAbsenceAlert, isFalse);
      expect(parsed.data['grade'], '1st');
    });

    test('Absence alert type getters work as expected', () {
      final alert = NotificationModel(
        id: 'alert_1',
        recipientId: 'khadem_1',
        title: 'تنبيه غياب متكرر',
        body: 'المخدوم غائب لجمعتين متتاليتين',
        type: 'absence_alert',
        createdAt: now,
      );

      expect(alert.isAbsenceAlert, isTrue);
      expect(alert.isTask, isFalse);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/services/notification_service.dart';

void main() {
  test(
    'channel locale changes generated metadata while retaining worker channel ID',
    () {
      final ar = NotificationService.channelForLocale(const Locale('ar'));
      final en = NotificationService.channelForLocale(const Locale('en'));
      expect(ar.id, en.id);
      expect(en.id, 'efteqad_high_importance_channel');
      expect(ar.name, 'إشعارات افتقاد والمهام');
      expect(en.name, 'Visits and task notifications');
      expect(en.description, 'Task, assignment, attendance and absence alerts');
    },
  );
}

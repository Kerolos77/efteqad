import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/notification_model.dart';
import 'package:efteqad/core/models/page_result.dart';
import 'package:efteqad/core/router/router_services.dart';
import 'package:efteqad/core/session/session_state.dart';
import 'package:efteqad/features/common/widgets/notification_list.dart';
import '../core/router/app_router_test.dart' show MockSessionCubit;
import '../core/router/resource_router_test.dart' show ShellRepository;

class Notifications extends ShellRepository {
  final List<NotificationModel> rows;
  Notifications(this.rows);
  @override
  Future<PageResult<NotificationModel>> fetchNotificationPage({
    required String uid,
    DocumentSnapshot? cursor,
    int limit = 50,
  }) async => PageResult(items: rows, hasMore: false);
}

void main() {
  testWidgets(
    'producer templates rerender on reader locale switch and preserve user and fallback text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = MockSessionCubit(
        const SessionState(
          status: SessionStatus.active,
          userId: 'a',
          role: UserRole.servant,
          grade: '1st',
        ),
      );
      NotificationModel document(
        String id,
        String? key, {
        String description = '',
        bool oldTemplate = false,
      }) => NotificationModel.fromMap({
        'recipientId': 'a',
        'title': 'stored $id',
        'body': description.isEmpty
            ? (oldTemplate
                  ? 'قام My admin بتكليفك بمهمة جديدة'
                  : 'stored body $id')
            : description,
        'type': 'task',
        if (key != null) 'templateKey': key,
        'templateArgs': {
          'title': 'My title',
          'createdByName': 'My admin',
          if (!oldTemplate) 'description': description,
        },
        'data': {'taskId': 't'},
        'createdAt': Timestamp.now(),
        'isRead': false,
      }, id);
      final store = Notifications([
        document('general', 'task_assigned'),
        document('user', 'task_assigned', description: 'User description'),
        document('follow', 'child_absence_alert'),
        document('mass', 'attendance_qoddas'),
        document('unknown', 'future_template'),
        document('legacy', null),
        document('oldempty', 'task_assigned', oldTemplate: true),
        document(
          'olduser',
          'task_assigned',
          oldTemplate: true,
          description: 'Old user description',
        ),
      ]);
      Widget app(Locale locale) => MaterialApp(
        locale: locale,
        supportedLocales: GeneratedAppLocalizations.supportedLocales,
        localizationsDelegates:
            GeneratedAppLocalizations.localizationsDelegates,
        home: RouterServices(
          firestore: store,
          session: session,
          child: const Scaffold(body: NotificationList()),
        ),
      );
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('New Task: My title 📋'), findsNWidgets(5));
      expect(find.text('My admin assigned you a new task'), findsNWidgets(2));
      expect(find.text('Follow-up alert'), findsOneWidget);
      expect(find.text('User description'), findsOneWidget);
      expect(find.text('Old user description'), findsOneWidget);
      expect(find.text('stored unknown'), findsOneWidget);
      expect(find.text('stored legacy'), findsOneWidget);
      await tester.pumpWidget(app(const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.text('New Task: My title 📋'), findsNothing);
      expect(find.text('مهمة جديدة: My title 📋'), findsNWidgets(5));
      expect(find.text('تنبيه متابعة'), findsOneWidget);
      expect(find.text('User description'), findsOneWidget);
      expect(find.text('Old user description'), findsOneWidget);
      expect(find.text('stored unknown'), findsOneWidget);
      expect(find.text('stored legacy'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(session.close());
    },
  );
}

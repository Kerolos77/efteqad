import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/services/firestore_service.dart';
import '../../widgets/notification_list.dart';
import '../../../../core/errors/app_failure.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.messageNotificationsCenter),
        centerTitle: true,
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () async {
                try {
                  await (services?.firestore ?? FirestoreService())
                      .markAllNotificationsAsRead(userId);
                  if (mounted) setState(() => _revision++);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppFailure.fromException(
                            e,
                          ).localizedMessage(context.tr),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                context.tr.messageMarkAllRead,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: NotificationList(key: ValueKey(_revision)),
    );
  }
}

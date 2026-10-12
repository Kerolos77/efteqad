import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/app_failure.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/services/firestore_service.dart';
import 'notification_list.dart';
import '../../../../core/router/router_services.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: (services?.firestore ?? FirestoreService())
          .watchUnreadNotificationCount(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            icon: const Icon(Icons.error_outline_rounded),
            tooltip: AppFailure.fromException(
              snapshot.error!,
            ).localizedMessage(context.tr),
            onPressed: () => NotificationsSheet.show(context),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final unreadCount = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: context.tr.messageNotifications,
              onPressed: () => NotificationsSheet.show(context),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.errorColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9
                        ? '9+'
                        : AppFormatters(
                            Localizations.localeOf(context),
                          ).formatNumber(unreadCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final services = RouterServices.maybeOf(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => services == null
          ? const NotificationsSheet()
          : RouterServices(
              firestore: services.firestore,
              session: services.session,
              child: const NotificationsSheet(),
            ),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;
    final firestoreService = services?.firestore ?? FirestoreService();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryLight.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppConstants.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr.messageNotificationsCenter616,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    if (userId != null) {
                      try {
                        await firestoreService.markAllNotificationsAsRead(
                          userId,
                        );
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
          ),
          const Divider(height: 1),

          // Notifications Stream
          Expanded(
            child: NotificationList(
              key: ValueKey(_revision),
              onNotificationTapped: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

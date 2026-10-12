import 'package:efteqad/core/localization/notification_text.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/router/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/router/notification_intent_coordinator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/paged_content.dart';
import '../../../../core/errors/app_failure.dart';

class NotificationList extends StatefulWidget {
  final VoidCallback? onNotificationTapped;

  const NotificationList({super.key, this.onNotificationTapped});
  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final Set<String> _readIds = {};

  String _formatTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return context.tr.messageJustNow;
    } else if (diff.inMinutes < 60) {
      return context.tr.messageMAgo(
        AppFormatters(
          Localizations.localeOf(context),
        ).formatNumber(diff.inMinutes),
      );
    } else if (diff.inHours < 24) {
      return context.tr.messageHAgo(
        AppFormatters(
          Localizations.localeOf(context),
        ).formatNumber(diff.inHours),
      );
    } else if (diff.inDays < 7) {
      return context.tr.messageDAgo(
        AppFormatters(
          Localizations.localeOf(context),
        ).formatNumber(diff.inDays),
      );
    } else {
      return AppFormatters(
        Localizations.localeOf(context),
      ).formatDate(date, format: 'yyyy/MM/dd');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.isArabic;
    final services = RouterServices.maybeOf(context);
    final userId =
        (services?.session ?? context.read<SessionCubit>()).state.userId;
    final firestoreService = services?.firestore ?? FirestoreService();

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return PagedContent<NotificationModel>(
      queryKey: userId,
      fetch: (cursor) =>
          firestoreService.fetchNotificationPage(uid: userId, cursor: cursor),
      emptyWidget: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 40,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr.messageNoNotificationsYet,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr.messageTaskAssignmentsAndAlertsWillAppearHere,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, notifications, more) {
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: notifications.length + (more != null ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == notifications.length) return more!;
            final n = notifications[index];
            return _buildNotificationCard(
              context,
              n,
              isDark,
              isArabic,
              firestoreService,
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel n,
    bool isDark,
    bool isArabic,
    FirestoreService firestoreService,
  ) {
    final isRead = n.isRead || _readIds.contains(n.id);
    Color iconColor;
    IconData iconData;

    if (n.isTask) {
      iconColor = AppConstants.primaryLight;
      iconData = Icons.task_alt_rounded;
    } else if (n.isAbsenceAlert) {
      iconColor = AppConstants.errorColor;
      iconData = Icons.warning_amber_rounded;
    } else {
      iconColor = AppConstants.accentGold;
      iconData = Icons.notifications_rounded;
    }

    return InkWell(
      onTap: () async {
        if (!isRead) {
          try {
            await firestoreService.markNotificationAsRead(n.id);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppFailure.fromException(e).localizedMessage(context.tr),
                  ),
                ),
              );
            }
            return;
          }
        }
        if (!context.mounted) return;
        setState(() => _readIds.add(n.id));
        widget.onNotificationTapped?.call();

        final target = NotificationIntent.fromPayload({
          'type': n.type,
          ...n.data,
        }).toRoutePath();
        context.push(target ?? AppRoutes.notFoundPath);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? AppConstants.surfaceDark : Colors.white)
              : (isDark
                    ? AppConstants.primaryLight.withValues(alpha: 0.15)
                    : const Color(0xFFEFF6FF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? (isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight)
                : AppConstants.primaryLight.withValues(alpha: 0.4),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.readerTitle(context.tr),
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.bold
                                : FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(context, n.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.readerBody(context.tr),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

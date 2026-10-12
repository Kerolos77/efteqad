import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/session/session_cubit.dart';
import '../../../core/router/router_services.dart';
import '../../../core/utils/color_generator.dart';
import '../../../main.dart';

class AppDrawer extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback? onOpenExcel;

  const AppDrawer({super.key, required this.isAdmin, this.onOpenExcel});

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppConstants.errorColor),
            const SizedBox(width: 8),
            Text(
              context.tr.signOutConfirmTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(context.tr.signOutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr.signOut,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final session =
          RouterServices.maybeOf(context)?.session ??
          context.read<SessionCubit>();
      try {
        await session.signOut();
        if (context.mounted) context.go(AppRoutes.loginPath);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr.dataUnavailable)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final session =
            RouterServices.maybeOf(context)?.session.state ??
            context.watch<SessionCubit>().state;
        final user = session.profile;
        final khademColor = ColorGenerator.getColorForId(
          user?.email ?? user?.id,
        );

        return Drawer(
          backgroundColor: isDark ? AppConstants.backgroundDark : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // الهيدر العصري بنمط Apple / Notion
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.surfaceDark
                        : AppConstants.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppConstants.cardBorderDark
                          : AppConstants.cardBorderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              (isAdmin ? AppConstants.accentGold : khademColor)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAdmin
                                ? AppConstants.accentGold
                                : khademColor,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isAdmin
                              ? const Icon(
                                  Icons.shield_rounded,
                                  color: AppConstants.accentGold,
                                  size: 26,
                                )
                              : Text(
                                  (user?.name != null && user!.name.isNotEmpty)
                                      ? user.name[0]
                                      : context.tr.messageS,
                                  style: TextStyle(
                                    color: khademColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isAdmin
                                        ? context.tr.headServant
                                        : (user?.name ?? context.tr.servant),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isAdmin
                                                ? AppConstants.accentGold
                                                : AppConstants.primaryLight)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAdmin
                                        ? context.tr.adminRole
                                        : context.tr.servantRole,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isAdmin
                                          ? AppConstants.accentGold
                                          : AppConstants.primaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? AppConstants.constAdminEmail,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppConstants.textMutedDark
                                    : AppConstants.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // قائمة الخيارات والتنقل
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      if (isAdmin) ...[
                        _buildDrawerTile(
                          icon: Icons.dashboard_outlined,
                          title: context.tr.mainDashboard,
                          onTap: () {
                            final target = AppRoutes.landing(session);
                            Navigator.pop(context);
                            context.go(target);
                          },
                          isDark: isDark,
                        ),
                        if (onOpenExcel != null)
                          _buildDrawerTile(
                            icon: Icons.table_chart_outlined,
                            title: context.tr.excelTools,
                            onTap: () {
                              Navigator.pop(context);
                              onOpenExcel!();
                            },
                            isDark: isDark,
                          ),
                      ] else ...[
                        _buildDrawerTile(
                          icon: Icons.people_alt_outlined,
                          title: context.tr.myGroupAndVisits,
                          onTap: () {
                            final target = AppRoutes.landing(session);
                            Navigator.pop(context);
                            context.go(target);
                          },
                          isDark: isDark,
                        ),
                        _buildDrawerTile(
                          icon: Icons.person_outline_rounded,
                          title: context.tr.servantProfile,
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.profilePath);
                          },
                          isDark: isDark,
                        ),
                      ],

                      const SizedBox(height: 6),
                      Divider(
                        color: isDark
                            ? AppConstants.cardBorderDark
                            : AppConstants.cardBorderLight,
                        indent: 8,
                        endIndent: 8,
                      ),
                      const SizedBox(height: 6),

                      // زر التبديل السريع للمظهر (الداكن / الفاتح)
                      _buildThemeToggleTile(context, isDark),

                      // صفحة الإعدادات الشاملة
                      _buildDrawerTile(
                        icon: Icons.settings_outlined,
                        title: context.tr.generalSettings,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.settingsPath);
                        },
                        isDark: isDark,
                      ),

                      // تسجيل الخروج
                      _buildDrawerTile(
                        icon: Icons.logout_rounded,
                        title: context.tr.signOut,
                        color: AppConstants.errorColor,
                        onTap: () => _handleLogout(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // الفوتر الكنسي الأنيق
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr.shepherdVerseShort,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppConstants.textMutedDark
                                  : AppConstants.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr.appName} ${context.tr.version(AppConstants.appVersion)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final itemColor = color ?? (isDark ? Colors.white : AppConstants.textDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: color ?? (isDark ? Colors.white70 : AppConstants.primaryNavy),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: itemColor,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: isDark ? Colors.amber : AppConstants.primaryLight,
          size: 22,
        ),
        title: Text(
          isDark ? context.tr.darkMode : context.tr.lightMode,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppConstants.textDark,
          ),
        ),
        trailing: Switch(
          value: isDark,
          activeThumbColor: Colors.amber,
          onChanged: (val) {
            themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        dense: true,
      ),
    );
  }
}

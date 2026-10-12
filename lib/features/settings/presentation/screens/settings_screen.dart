import 'package:efteqad/core/repositories/account_repository.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../main.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/session_cubit.dart';

abstract class AccountDeletionActions {
  String? get currentUserId;
  bool get requiresPassword;
  Future<void> deleteAccount({String? password});
}

class AuthAccountDeletionActions implements AccountDeletionActions {
  final AuthService? authService;
  final AccountRepository? accountRepository;
  AuthAccountDeletionActions({this.authService, this.accountRepository});
  AuthService get _auth => authService ?? AuthService();
  @override
  String? get currentUserId => _auth.currentUser?.uid;
  @override
  bool get requiresPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;
  @override
  Future<void> deleteAccount({String? password}) => _auth.deleteAccount(
    password: password,
    accountRepository: accountRepository,
  );
}

class SettingsScreen extends StatefulWidget {
  final AccountDeletionActions? accountActions;
  const SettingsScreen({super.key, this.accountActions});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AccountDeletionActions get _accountActions =>
      widget.accountActions ?? AuthAccountDeletionActions();
  bool _isDeleting = false;
  final _deletePasswordController = TextEditingController();
  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectLocale(Locale locale) async {
    try {
      await context.read<SettingsCubit>().setLocale(locale);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(error).localizedMessage(
                lookupGeneratedAppLocalizations(
                  context.read<SettingsCubit>().state.locale,
                ),
              ),
            ),
            action: SnackBarAction(
              label: context.tr.retryAction,
              onPressed: () => _selectLocale(locale),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppConstants.errorColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.tr.signOutConfirmTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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

    if (confirm == true && mounted) {
      try {
        await context.read<SessionCubit>().signOut();
        if (mounted) context.go(AppRoutes.loginPath);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr.dataUnavailable)));
        }
      }
    }
  }

  bool _ownsDeletion(String uid) {
    final session = context.read<SessionCubit>().state;
    return session.userId == uid &&
        session.isAuthenticated &&
        !session.isDeleting &&
        _accountActions.currentUserId == uid;
  }

  Future<void> _handleDeleteAccount() async {
    final owner = context.read<SessionCubit>().state.userId;
    if (owner == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppConstants.errorColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr.deleteAccountWarningTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.deleteAccountWarningPrompt,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (context.read<SessionCubit>().state.isStageAdmin)
                Text(context.tr.stageSuccessorRequired),
              Text(
                context.tr.deleteAccountPoints,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.back),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr.deleteAccountConfirmBtn,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (!_ownsDeletion(owner)) return;
      final isPasswordProvider = _accountActions.requiresPassword;

      String? password;
      if (isPasswordProvider) {
        final passController = _deletePasswordController;
        passController.clear();
        bool obscure = true;
        final passConfirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                context.tr.messageConfirmPassword,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr.messageToDeleteYourAccountPleaseEnterYour,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: context.tr.messagePassword,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.tr.back),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.errorColor,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    context.tr.messageProceed,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        final enteredPassword = passController.text.trim();
        passController.clear();
        if (passConfirm != true || enteredPassword.isEmpty) return;
        password = enteredPassword;
      }

      if (!mounted || !_ownsDeletion(owner)) return;
      setState(() => _isDeleting = true);
      try {
        await _accountActions.deleteAccount(password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.messageYourDeletionRequestIsSavedYouCan),
              backgroundColor: AppConstants.successColor,
            ),
          );
          context.go(AppRoutes.loginPath);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          if (context.read<SessionCubit>().state.userId != owner) return;
          final failure = AppFailure.fromException(e);
          final errorMsg =
              context.read<SessionCubit>().state.isStageAdmin &&
                  failure.code == 'failed-precondition'
              ? context.tr.stageSuccessorRequired
              : failure.localizedMessage(context.tr);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          try {
            await context.read<SettingsCubit>().refreshDeviceLocale();
          } catch (error) {
            debugPrint(
              'Device restoration after rejected deletion failed: $error',
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final isStageAdmin = session.isStageAdmin;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark
              ? AppConstants.backgroundDark
              : AppConstants.backgroundLight,
          appBar: AppBar(
            backgroundColor: isDark
                ? AppConstants.backgroundDark
                : AppConstants.backgroundLight,
            title: Text(
              context.tr.settingsTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. قطاع المظهر (Appearance)
                _buildSectionTitle(
                  context.tr.appearanceSection,
                  Icons.palette_outlined,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? Colors.amber
                                      : AppConstants.primaryLight)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: isDark
                              ? Colors.amber
                              : AppConstants.primaryLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDark
                                  ? context.tr.darkMode
                                  : context.tr.lightMode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isDark
                                  ? context.tr.darkModeDesc
                                  : context.tr.lightModeDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppConstants.textMutedDark
                                    : AppConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDark,
                        activeThumbColor: Colors.amber,
                        onChanged: (val) async {
                          final newMode = val
                              ? ThemeMode.dark
                              : ThemeMode.light;
                          try {
                            await context.read<SettingsCubit>().setThemeMode(
                              newMode,
                            );
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppFailure.fromException(
                                      error,
                                    ).localizedMessage(context.tr),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. قطاع اللغة (Language)
                _buildSectionTitle(
                  context.tr.languageSection,
                  Icons.translate_outlined,
                ),
                _buildCard(
                  isDark: isDark,
                  child: ValueListenableBuilder<Locale>(
                    valueListenable: localeNotifier,
                    builder: (context, currentLocale, _) {
                      final isArabic = currentLocale.languageCode == 'ar';
                      return Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              await _selectLocale(const Locale('ar', 'EG'));
                            },
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isArabic
                                          ? AppConstants.primaryLight
                                                .withValues(alpha: 0.15)
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.04,
                                                  )),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '🇪🇬',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr.arabicLang,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          context.tr.arabicLangDesc,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppConstants.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isArabic)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppConstants.primaryLight,
                                      size: 22,
                                    )
                                  else
                                    Icon(
                                      Icons.radio_button_unchecked,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark
                                ? AppConstants.cardBorderDark
                                : AppConstants.cardBorderLight,
                          ),
                          InkWell(
                            onTap: () async {
                              await _selectLocale(const Locale('en', 'US'));
                            },
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: !isArabic
                                          ? AppConstants.primaryLight
                                                .withValues(alpha: 0.15)
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.04,
                                                  )),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '🇺🇸',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr.englishLang,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          context.tr.englishLangDesc,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppConstants.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isArabic)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppConstants.primaryLight,
                                      size: 22,
                                    )
                                  else
                                    Icon(
                                      Icons.radio_button_unchecked,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 3. عن التطبيق (About)
                _buildSectionTitle(
                  context.tr.aboutSection,
                  Icons.info_outline_rounded,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryNavy,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppConstants.sacredGold.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                AppConstants.appLogoPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr.appName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '«${context.tr.appTagline}»',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppConstants.accentGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                context.tr.version(AppConstants.appVersion),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppConstants.textMutedDark
                                      : AppConstants.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr.aboutServiceDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppConstants.textMutedDark
                              : AppConstants.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. الحساب والأمان (Account & Security)
                _buildSectionTitle(
                  context.tr.accountSection,
                  Icons.security_outlined,
                ),
                _buildCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: AppConstants.errorColor,
                        ),
                        title: Text(
                          context.tr.signOut,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          context.tr.signOutAccountDesc,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: _handleLogout,
                      ),
                      if (session.isAuthenticated && !session.isDeleting) ...[
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppConstants.cardBorderDark
                              : AppConstants.cardBorderLight,
                        ),
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: _isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppConstants.errorColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_forever_rounded,
                                  color: AppConstants.errorColor,
                                ),
                          title: Text(
                            context.tr.deleteAccount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppConstants.errorColor,
                            ),
                          ),
                          subtitle: Text(
                            isStageAdmin
                                ? context.tr.stageSuccessorRequired
                                : context.tr.deleteAccountDesc,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.errorColor,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppConstants.errorColor,
                          ),
                          onTap: _isDeleting ? null : _handleDeleteAccount,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, end: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppConstants.textMutedDark : AppConstants.textMuted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppConstants.textMutedDark
                    : AppConstants.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
      ),
      child: child,
    );
  }
}

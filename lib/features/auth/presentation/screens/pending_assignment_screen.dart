import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/session/session_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';

class PendingAssignmentScreen extends StatefulWidget {
  const PendingAssignmentScreen({super.key});

  @override
  State<PendingAssignmentScreen> createState() =>
      _PendingAssignmentScreenState();
}

class _PendingAssignmentScreenState extends State<PendingAssignmentScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>();
    _nameController = TextEditingController(
      text:
          session.state.profile?.name ??
          session.authIdentity?.displayName ??
          '',
    );
    _phoneController = TextEditingController(
      text: session.state.profile?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<SessionCubit>().state.userId;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateKhademProfile(
        id: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.profileUpdatedSuccess),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSignOut() async {
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>();
    if (session.state.userId == null) return const SizedBox.shrink();
    final user =
        session.authIdentity ??
        AuthIdentity(
          uid: session.state.userId!,
          email: session.state.profile?.email,
          displayName: session.state.profile?.name,
        );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userColor = ColorGenerator.getColorForId(user.email ?? user.uid);

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, session) {
        final khadem = session.profile;

        // مزامنة الحقول عند أول جلب من فايرستور
        if (!_initialized && khadem != null) {
          _initialized = true;
          if (khadem.name.isNotEmpty) _nameController.text = khadem.name;
          if (khadem.phone.isNotEmpty) _phoneController.text = khadem.phone;
        }

        return Scaffold(
          backgroundColor: isDark
              ? AppConstants.backgroundDark
              : AppConstants.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppConstants.errorColor,
                ),
                tooltip: context.tr.signOut,
                onPressed: _handleSignOut,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة الخادم باللون المخصص
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: userColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: userColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: userColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (khadem?.name.isNotEmpty ?? false)
                              ? khadem!.name[0]
                              : (user.displayName?.isNotEmpty ?? false
                                    ? user.displayName![0]
                                    : context.tr.messageS),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: userColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // عنوان الترحيب
                    Text(
                      context.tr.pendingWelcome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // بطاقة حالة الانتظار (Status Hero Card)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppConstants.accentGold.withValues(
                            alpha: 0.35,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.04,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppConstants.accentGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: AppConstants.accentGold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr.pendingStatusTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.accentGold
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        context.tr.pendingRoleLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants.accentGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr.pendingStatusDesc,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: isDark
                                  ? AppConstants.textMutedDark
                                  : AppConstants.textMuted,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // استمارة تأكيد الاسم ورقم الهاتف
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppConstants.cardBorderDark
                              : AppConstants.cardBorderLight,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.completeProfilePrompt,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // حقل الاسم
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: context.tr.servantFullNameLabel,
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return context.tr.servantNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // حقل التليفون
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: context.tr.servantPhoneLabel,
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return context.tr.servantPhoneRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // زر حفظ البيانات
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : _handleSaveProfile,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                      ),
                                label: Text(context.tr.updateAndSave),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryLight,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

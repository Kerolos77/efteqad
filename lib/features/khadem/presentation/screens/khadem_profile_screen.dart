import 'package:efteqad/core/errors/app_failure.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';

class KhademProfileScreen extends StatefulWidget {
  const KhademProfileScreen({super.key});

  @override
  State<KhademProfileScreen> createState() => _KhademProfileScreenState();
}

class _KhademProfileScreenState extends State<KhademProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthService get _authService => AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isLoading = true;
  bool _isSaving = false;
  KhademModel? _currentKhadem;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>();
    _currentKhadem = session.state.profile;
    _nameController = TextEditingController(
      text: _currentKhadem?.name ?? session.authIdentity?.displayName ?? '',
    );
    _phoneController = TextEditingController(text: _currentKhadem?.phone ?? '');
    _emailController = TextEditingController(
      text: _currentKhadem?.email ?? session.authIdentity?.email ?? '',
    );
    _isLoading = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    try {
      // 1. تحديث الاسم في Firebase Auth
      await user.updateDisplayName(newName);

      // 2. تحديث الاسم والتليفون في Firestore
      await _firestoreService.updateKhademProfile(
        id: user.uid,
        name: newName,
        phone: newPhone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.profileUpdatedSuccess),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.bootstrapPath);
        }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionCubit>().state;
    final khademColor = ColorGenerator.getColorForId(
      session.profile?.email ?? session.userId,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppConstants.backgroundDark
          : AppConstants.backgroundLight,
      appBar: AppBar(
        title: Text(
          context.tr.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // بطاقة الأفاتار الفخمة
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: khademColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: khademColor,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: khademColor.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0]
                                    : context.tr.messageS,
                                style: TextStyle(
                                  color: khademColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: khademColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppConstants.backgroundDark
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // اسم ورتبة الخادم
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : context.tr.messageStageServant,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: khademColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.tr.verifiedServantBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: khademColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // كارت إحصائية المخدومين التابعين له
                    if (_currentKhadem != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppConstants.surfaceDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppConstants.cardBorderDark
                                : AppConstants.cardBorderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryLight.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.groups_outlined,
                                color: AppConstants.primaryLight,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                context.tr.assignedCountInCare(
                                  _currentKhadem!.assignedCount,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // حقول التعديل
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppConstants.cardBorderDark
                              : AppConstants.cardBorderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.personalInfoSection,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 1. الاسم بالخدمة
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: context.tr.servantFullNameLabel,
                              prefixIcon: const Icon(
                                Icons.person_rounded,
                                size: 20,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? context.tr.servantNameRequired
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // 2. رقم التليفون
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: context.tr.servantPhoneLabel,
                              prefixIcon: const Icon(
                                Icons.phone_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. البريد الإلكتروني (للقراءة فقط)
                          TextFormField(
                            controller: _emailController,
                            textDirection: TextDirection.ltr,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: context.tr.googleEmailLabel,
                              prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                                size: 20,
                              ),
                              suffixIcon: Tooltip(
                                message: context.tr.emailReadOnlyNote,
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : const Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // زر حفظ التعديلات
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          _isSaving ? '...' : context.tr.saveChanges,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: khademColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

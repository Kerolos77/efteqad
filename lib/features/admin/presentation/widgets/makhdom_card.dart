import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/utils/color_generator.dart';

class MakhdomCard extends StatefulWidget {
  final MakhdomModel makhdom;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUnassign;
  final VoidCallback? onLogVisit; // اختياري لتسجيل الافتقاد مباشرة

  const MakhdomCard({
    super.key,
    required this.makhdom,
    this.onEdit,
    this.onDelete,
    this.onUnassign,
    this.onLogVisit,
  });

  @override
  State<MakhdomCard> createState() => _MakhdomCardState();
}

class _MakhdomCardState extends State<MakhdomCard> {
  bool _isExpanded = false;

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) clean = '2$clean';
    if (!clean.startsWith('20') && clean.length == 11) clean = '2$clean';
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLocation(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    final url = Uri.parse(urlString.trim());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final makhdom = widget.makhdom;
    final khademColor = ColorGenerator.getColorForId(
      makhdom.assignedKhademId ?? makhdom.assignedKhademName,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            context.push(AppRoutes.makhdomHistory(widget.makhdom.id));
          },
          child: Column(
            children: [
              // القسم الأساسي للكارت
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصف العلوي: الصورة + الاسم والشارات + زر المنيو
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الصورة أو الحرف مع إطار بلون الخادم المسؤول
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: khademColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: makhdom.isAssigned
                                  ? khademColor
                                  : (isDark ? Colors.white24 : Colors.black12),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child:
                                (makhdom.photoUrl != null &&
                                    makhdom.photoUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: makhdom.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _buildInitialAvatar(
                                          makhdom,
                                          khademColor,
                                        ),
                                  )
                                : _buildInitialAvatar(makhdom, khademColor),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // الاسم والتاجات
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                makhdom.fullName,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppConstants.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),

                              // التاجات المصغرة (أخوة الرب، المنطقة، المدرسة)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (makhdom.isBrethrenOfLord)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.accentGold
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 10,
                                            color: AppConstants.accentGold,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            context.tr.brethrenBadge,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppConstants.accentGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (makhdom.area.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.location_on_outlined,
                                      makhdom.area,
                                      isDark,
                                    ),
                                  if (makhdom.school.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.school_rounded,
                                      makhdom.school,
                                      isDark,
                                    ),
                                  if (makhdom.age != null)
                                    _buildMiniTag(
                                      Icons.cake_outlined,
                                      context.tr.ageYearsOld(makhdom.age!),
                                      isDark,
                                    ),
                                  if (makhdom.secondaryType.isNotEmpty)
                                    _buildMiniTag(
                                      Icons.category_outlined,
                                      DomainLabels(
                                        Localizations.localeOf(context),
                                      ).secondaryTypeName(
                                        makhdom.secondaryType,
                                        customLabel:
                                            makhdom.secondaryTypeCustomLabel,
                                      ),
                                      isDark,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // زر الخيارات الأنيق
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            color: isDark
                                ? Colors.white54
                                : AppConstants.textMuted,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (val) {
                            if (val == 'history') {
                              context.push(
                                AppRoutes.makhdomHistory(widget.makhdom.id),
                              );
                            }
                            if (val == 'edit') widget.onEdit?.call();
                            if (val == 'delete') widget.onDelete?.call();
                            if (val == 'unassign') widget.onUnassign?.call();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'history',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history_edu_rounded,
                                    size: 18,
                                    color: AppConstants.sacredGold,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.tr.historyAction,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppConstants.primaryLight,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.tr.editDetailsAction,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.onUnassign != null && makhdom.isAssigned)
                              PopupMenuItem(
                                value: 'unassign',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_remove_outlined,
                                      size: 18,
                                      color: AppConstants.warningColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.tr.unassignServantAction,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.onDelete != null)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppConstants.errorColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.tr.deleteMakhdomAction,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // سطر حالة الخادم والافتقاد
                    Row(
                      children: [
                        // كبسولة الخادم المسؤول
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: khademColor.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: khademColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 13,
                                  color: khademColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    makhdom.isAssigned
                                        ? makhdom.assignedKhademName!
                                        : context.tr.unassignedBadge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: makhdom.isAssigned
                                          ? khademColor
                                          : AppConstants.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // حالة الافتقاد
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: makhdom.visitCount > 0
                                ? AppConstants.successColor.withValues(
                                    alpha: 0.12,
                                  )
                                : (isDark
                                      ? Colors.white10
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: makhdom.visitCount > 0
                                      ? AppConstants.successColor
                                      : AppConstants.warningColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                makhdom.visitCount > 0
                                    ? context.tr.visitCountSummary(
                                        makhdom.visitCount,
                                      )
                                    : context.tr.notVisitedYetBadge,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: makhdom.visitCount > 0
                                      ? AppConstants.successColor
                                      : (isDark
                                            ? Colors.white70
                                            : AppConstants.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // قسم التفاصيل الموسعة (العنوان، تليفون الوالدين، الملاحظات)
              if (_isExpanded)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppConstants.cardBorderDark
                            : AppConstants.cardBorderLight,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (makhdom.address.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.home_outlined,
                              size: 15,
                              color: AppConstants.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                makhdom.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (makhdom.school.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 15,
                              color: AppConstants.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.tr.schoolLabel} ${makhdom.school}${makhdom.secondaryType.isNotEmpty ? " (${makhdom.secondaryType})" : ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (makhdom.age != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cake_outlined,
                              size: 15,
                              color: Colors.pinkAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                makhdom.birthDate != null
                                    ? '${context.tr.birthDateDetailLabel} ${AppFormatters(Localizations.localeOf(context)).formatDate(makhdom.birthDate)} (${context.tr.ageYearsOld(makhdom.age!)})'
                                    : context.tr.messageAgeEstimatedFrom(
                                        (context.tr.ageYearsOld(
                                          makhdom.age!,
                                        )).toString(),
                                        (DomainLabels(
                                          Localizations.localeOf(context),
                                        ).gradeName(makhdom.grade)).toString(),
                                      ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // هواتف الوالدين
                      Row(
                        children: [
                          if (makhdom.fatherPhone.isNotEmpty)
                            Expanded(
                              child: InkWell(
                                onTap: () => _makeCall(makhdom.fatherPhone),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppConstants.surfaceDark
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppConstants.cardBorderDark
                                          : AppConstants.cardBorderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_android,
                                        size: 14,
                                        color: AppConstants.primaryLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${context.tr.fatherPhoneLabel} ${AppFormatters(Localizations.localeOf(context)).ltr(makhdom.fatherPhone)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (makhdom.fatherPhone.isNotEmpty &&
                              makhdom.motherPhone.isNotEmpty)
                            const SizedBox(width: 8),
                          if (makhdom.motherPhone.isNotEmpty)
                            Expanded(
                              child: InkWell(
                                onTap: () => _makeCall(makhdom.motherPhone),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppConstants.surfaceDark
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppConstants.cardBorderDark
                                          : AppConstants.cardBorderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_android,
                                        size: 14,
                                        color: Colors.purple,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${context.tr.motherPhoneLabel} ${AppFormatters(Localizations.localeOf(context)).ltr(makhdom.motherPhone)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (makhdom.notes != null &&
                          makhdom.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.accentGold.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${context.tr.notesLabel} ${makhdom.notes!}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // شريط الأزرار السريع السفلي (Modern Action Dock)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131D31)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppConstants.cardBorderDark
                          : AppConstants.cardBorderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // زر الاتصال المباشر بالمخدوم
                            if (makhdom.phone.isNotEmpty)
                              _buildDockButton(
                                icon: Icons.call,
                                bgColor: AppConstants.successColor.withValues(
                                  alpha: 0.12,
                                ),
                                iconColor: AppConstants.successColor,
                                onTap: () => _makeCall(makhdom.phone),
                              ),

                            // زر الواتساب
                            if (makhdom.phone.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildDockButton(
                                icon: FontAwesomeIcons.whatsapp,
                                bgColor: const Color(
                                  0xFF25D366,
                                ).withValues(alpha: 0.12),
                                iconColor: const Color(0xFF25D366),
                                isFa: true,
                                onTap: () => _openWhatsApp(makhdom.phone),
                              ),
                            ],

                            // زر اللوكيشن
                            if (makhdom.homeLocationUrl != null &&
                                makhdom.homeLocationUrl!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildDockButton(
                                icon: Icons.map_outlined,
                                bgColor: AppConstants.primaryLight.withValues(
                                  alpha: 0.12,
                                ),
                                iconColor: AppConstants.primaryLight,
                                onTap: () =>
                                    _openLocation(makhdom.homeLocationUrl),
                              ),
                            ],

                            // زر تسجيل افتقاد مباشر (إن وُجد)
                            if (widget.onLogVisit != null) ...[
                              const SizedBox(width: 6),
                              _buildDockButton(
                                icon: Icons.add_task,
                                label: context.tr.visitAction,
                                bgColor: AppConstants.accentIndigo.withValues(
                                  alpha: 0.14,
                                ),
                                iconColor: AppConstants.accentIndigo,
                                onTap: widget.onLogVisit!,
                              ),
                            ],

                            // زر سجل الافتقاد والحضور الشامل
                            const SizedBox(width: 6),
                            _buildDockButton(
                              icon: Icons.history_edu_rounded,
                              label: context.tr.historyAction,
                              bgColor: AppConstants.sacredGold.withValues(
                                alpha: 0.15,
                              ),
                              iconColor: AppConstants.sacredGold,
                              onTap: () {
                                context.push(
                                  AppRoutes.makhdomHistory(makhdom.id),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // زر إظهار/إخفاء التفاصيل
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Text(
                            //   _isExpanded ? context.tr.less : context.tr.details,
                            //   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConstants.textMuted),
                            // ),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppConstants.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(MakhdomModel m, Color color) {
    return Center(
      child: Text(
        m.fullName.isNotEmpty ? m.fullName[0] : (context.tr.messageM),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppConstants.textMuted),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppConstants.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton({
    required dynamic icon,
    String? label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool isFa = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 10 : 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFa)
              FaIcon(icon as IconData, size: 14, color: iconColor)
            else
              Icon(icon as IconData, size: 15, color: iconColor),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

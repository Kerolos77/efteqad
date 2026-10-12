import '../../../../core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';

class HistoryHeader extends StatelessWidget {
  final MakhdomModel makhdom;
  final String? latestVisitNotes;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onWhatsApp;
  final ValueChanged<String?> onOpenLocation;
  final void Function(String text, String label) onCopy;

  const HistoryHeader({
    super.key,
    required this.makhdom,
    this.latestVisitNotes,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onCall,
    required this.onWhatsApp,
    required this.onOpenLocation,
    required this.onCopy,
  });

  Widget _buildInitialAvatarText(MakhdomModel makhdom) {
    final initials = makhdom.fullName.isNotEmpty
        ? makhdom.fullName
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
        : '?';
    return Container(
      color: AppConstants.sacredGold.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppConstants.sacredGold,
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionIconButton({
    required Widget icon,
    required Color color,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: IconTheme(
              data: IconThemeData(color: color, size: 18),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    String? copyValue,
    Color? iconColor,
    VoidCallback? onCallTap,
    VoidCallback? onWhatsAppTap,
  }) {
    final effectiveColor = iconColor ?? AppConstants.sacredGold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppConstants.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: onCallTap != null ? TextDirection.ltr : null,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppConstants.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onCallTap != null) ...[
            const SizedBox(width: 4),
            _buildQuickActionIconButton(
              icon: const Icon(Icons.call_rounded, size: 14),
              color: AppConstants.successColor,
              tooltip: context.tr.callAction,
              isDark: isDark,
              onPressed: onCallTap,
            ),
          ],
          if (onWhatsAppTap != null) ...[
            const SizedBox(width: 4),
            _buildQuickActionIconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 14),
              color: const Color(0xFF25D366),
              tooltip: context.tr.whatsappAction,
              isDark: isDark,
              onPressed: onWhatsAppTap,
            ),
          ],
          if (copyValue != null && copyValue.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 15),
              tooltip: context.tr.copyPhoneAction,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => onCopy(copyValue, label),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سطر الهوية: الصورة الشخصية والاسم والوسامات
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppConstants.sacredGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.sacredGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.sacredGold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child:
                      (makhdom.photoUrl != null && makhdom.photoUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: makhdom.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _buildInitialAvatarText(makhdom),
                        )
                      : _buildInitialAvatarText(makhdom),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      makhdom.fullName,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppConstants.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _buildHeaderBadge(
                          icon: Icons.school_rounded,
                          text: DomainLabels(
                            Localizations.localeOf(context),
                          ).gradeName(makhdom.grade),
                          color: AppConstants.primaryLight,
                          isDark: isDark,
                        ),
                        if (makhdom.isBrethrenOfLord)
                          _buildHeaderBadge(
                            icon: Icons.star_rounded,
                            text: context.tr.brethrenBadge,
                            color: AppConstants.accentGold,
                            isDark: isDark,
                          ),
                        if (makhdom.assignedKhademName != null &&
                            makhdom.assignedKhademName!.isNotEmpty)
                          _buildHeaderBadge(
                            icon: Icons.person_rounded,
                            text: makhdom.assignedKhademName!,
                            color: AppConstants.sacredGold,
                            isDark: isDark,
                          )
                        else
                          _buildHeaderBadge(
                            icon: Icons.person_off_rounded,
                            text: context.tr.unassignedBadge,
                            color: isDark
                                ? Colors.white54
                                : AppConstants.textMuted,
                            isDark: isDark,
                          ),
                        if (makhdom.age != null)
                          _buildHeaderBadge(
                            icon: Icons.cake_outlined,
                            text: context.tr.ageYearsOld(makhdom.age!),
                            color: Colors.pinkAccent,
                            isDark: isDark,
                          ),
                        if (makhdom.area.isNotEmpty)
                          _buildHeaderBadge(
                            icon: Icons.location_on_outlined,
                            text: makhdom.area,
                            color: AppConstants.accentBlue,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !makhdom.hasKnownTrackingOrigin
                ? context.tr.trackingOriginUnknown
                : makhdom.isTrackingEstimated
                ? context.tr.trackingStartEstimatedLabel(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatDate(makhdom.effectiveTrackingStartDate),
                  )
                : context.tr.trackingStartLabel(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatDate(makhdom.effectiveTrackingStartDate),
                  ),
          ),
          if (latestVisitNotes != null && latestVisitNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr.visitReportLabel),
                  Text(latestVisitNotes!),
                ],
              ),
            ),
          if (makhdom.legacyNotes != null && makhdom.legacyNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr.legacyNotesLabel),
                  Text(makhdom.legacyNotes!),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // أزرار التواصل السريع وزر التوسيع
          Row(
            children: [
              if (makhdom.phone.isNotEmpty) ...[
                _buildQuickActionIconButton(
                  icon: const Icon(Icons.call_rounded, size: 18),
                  color: AppConstants.successColor,
                  tooltip: context.tr.callAction,
                  isDark: isDark,
                  onPressed: () => onCall(makhdom.phone),
                ),
                const SizedBox(width: 6),
                _buildQuickActionIconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  color: const Color(0xFF25D366),
                  tooltip: context.tr.whatsappAction,
                  isDark: isDark,
                  onPressed: () => onWhatsApp(makhdom.phone),
                ),
                const SizedBox(width: 6),
              ],
              if (makhdom.homeLocationUrl != null &&
                  makhdom.homeLocationUrl!.isNotEmpty) ...[
                _buildQuickActionIconButton(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  color: AppConstants.primaryLight,
                  tooltip: context.tr.mapAction,
                  isDark: isDark,
                  onPressed: () => onOpenLocation(makhdom.homeLocationUrl),
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              Flexible(
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.sacredGold.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppConstants.sacredGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppConstants.sacredGold,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isExpanded
                                ? context.tr.hideDetailsAction
                                : context.tr.allDetailsAction,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppConstants.sacredGold,
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

          // التفاصيل الموسعة
          if (isExpanded) ...[
            const Divider(height: 24),
            if (makhdom.phone.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.phone_android_rounded,
                label: context.tr.makhdomPhoneLabel,
                value: makhdom.phone,
                copyValue: makhdom.phone,
                iconColor: AppConstants.successColor,
              ),
            if (makhdom.fatherPhone.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.phone_iphone_rounded,
                label: context.tr.fatherPhoneLabel,
                value: makhdom.fatherPhone,
                copyValue: makhdom.fatherPhone,
                iconColor: AppConstants.accentBlue,
                onCallTap: () => onCall(makhdom.fatherPhone),
                onWhatsAppTap: () => onWhatsApp(makhdom.fatherPhone),
              ),
            if (makhdom.motherPhone.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.phone_iphone_rounded,
                label: context.tr.motherPhoneLabel,
                value: makhdom.motherPhone,
                copyValue: makhdom.motherPhone,
                iconColor: Colors.purpleAccent,
                onCallTap: () => onCall(makhdom.motherPhone),
                onWhatsAppTap: () => onWhatsApp(makhdom.motherPhone),
              ),
            if (makhdom.address.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.home_rounded,
                label: context.tr.addressLabel,
                value: makhdom.address,
                copyValue: makhdom.address,
                iconColor: AppConstants.primaryLight,
              ),
            if (makhdom.school.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.business_rounded,
                label: context.tr.schoolLabel,
                value: makhdom.school,
                iconColor: Colors.teal,
              ),
            if (makhdom.assignedKhademName != null &&
                makhdom.assignedKhademName!.isNotEmpty)
              _buildDetailRow(
                context: context,
                icon: Icons.badge_rounded,
                label: context.tr.assignedKhademLabel,
                value: makhdom.assignedKhademName!,
                iconColor: AppConstants.sacredGold,
              ),

            // ملاحظات عامة دائمة عن المخدوم (مفصولة بوضوح عن تقارير الزيارات)
            if (makhdom.notes != null && makhdom.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 15,
                          color: AppConstants.sacredGold,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr.generalNotesTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      makhdom.notes!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppConstants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

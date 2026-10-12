import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';

class StagePeopleTab extends StatefulWidget {
  final List<KhademModel> pendingKhodam;
  final List<KhademModel> allKhodam;
  final List<MakhdomModel> allMakhdomeen;

  const StagePeopleTab({
    super.key,
    required this.pendingKhodam,
    required this.allKhodam,
    required this.allMakhdomeen,
  });

  @override
  State<StagePeopleTab> createState() => _StagePeopleTabState();
}

class _StagePeopleTabState extends State<StagePeopleTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedGradeFilter = 'all';

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openAssignGradeDialog(KhademModel khadem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ctx.tr.assignServantToGradePrompt,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ctx.tr.messageServant580}: ${khadem.name}'),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school, color: Color(0xFF3B82F6)),
              title: Text(ctx.tr.grade1stName),
              onTap: () async {
                Navigator.pop(ctx);
                await _firestoreService.assignKhademToGrade(
                  khadem.id,
                  AppConstants.grade1st,
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school, color: Color(0xFF8B5CF6)),
              title: Text(ctx.tr.grade2ndName),
              onTap: () async {
                Navigator.pop(ctx);
                await _firestoreService.assignKhademToGrade(
                  khadem.id,
                  AppConstants.grade2nd,
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school, color: Color(0xFFEC4899)),
              title: Text(ctx.tr.grade3rdName),
              onTap: () async {
                Navigator.pop(ctx);
                await _firestoreService.assignKhademToGrade(
                  khadem.id,
                  AppConstants.grade3rd,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAppointHeadDialog({
    required String gradeKey,
    required String gradeTitle,
    required List<KhademModel> gradeKhodam,
    required KhademModel? currentHead,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${ctx.tr.appointGradeHeadBtn} - $gradeTitle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ctx.tr.messageSelectAServantToAppointAsGrade,
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (gradeKhodam.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    ctx.tr.messageNoServantsAssignedToYet(
                      (gradeTitle).toString(),
                    ),
                    style: const TextStyle(color: AppConstants.textMuted),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: gradeKhodam.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final k = gradeKhodam[idx];
                    final isHead = k.id == currentHead?.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: ColorGenerator.getColorForId(
                          k.id,
                        ).withValues(alpha: 0.15),
                        child: Text(
                          k.name.isNotEmpty ? k.name[0] : context.tr.messageS,
                          style: TextStyle(
                            color: ColorGenerator.getColorForId(k.id),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        k.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        k.phone,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isHead
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.sacredGold.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ctx.tr.currentGradeAdmin,
                                style: TextStyle(
                                  color: AppConstants.sacredGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _firestoreService.setGradeAdmin(
                                  gradeKey,
                                  k.id,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppConstants.primaryLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                ctx.tr.messageAppointHead,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final khodam1st = widget.allKhodam
        .where((k) => k.grade == AppConstants.grade1st)
        .toList();
    final khodam2nd = widget.allKhodam
        .where((k) => k.grade == AppConstants.grade2nd)
        .toList();
    final khodam3rd = widget.allKhodam
        .where((k) => k.grade == AppConstants.grade3rd)
        .toList();

    KhademModel? head1st;
    KhademModel? head2nd;
    KhademModel? head3rd;
    try {
      head1st = khodam1st.firstWhere((k) => k.isGradeAdmin);
    } catch (_) {}
    try {
      head2nd = khodam2nd.firstWhere((k) => k.isGradeAdmin);
    } catch (_) {}
    try {
      head3rd = khodam3rd.firstWhere((k) => k.isGradeAdmin);
    } catch (_) {}

    List<KhademModel> displayedKhodam;
    if (_selectedGradeFilter == AppConstants.grade1st) {
      displayedKhodam = khodam1st;
    } else if (_selectedGradeFilter == AppConstants.grade2nd) {
      displayedKhodam = khodam2nd;
    } else if (_selectedGradeFilter == AppConstants.grade3rd) {
      displayedKhodam = khodam3rd;
    } else {
      displayedKhodam = widget.allKhodam.where((k) => k.isActive).toList();
    }

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 85),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. قطاع الخدام الجدد بانتظار التسكين
        if (widget.pendingKhodam.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 16,
                  color: AppConstants.warningColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr.pendingServantsSection,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber(widget.pendingKhodam.length),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.pendingKhodam.map(
            (khadem) => _buildPendingKhademCard(khadem, isDark),
          ),
          const SizedBox(height: 20),
        ],

        // 2. قطاع أمناء السنين الدراسية
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: AppConstants.primaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr.gradeHeadsSection,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildGradeHeadCard(
          gradeKey: AppConstants.grade1st,
          gradeTitle: context.tr.grade1stName,
          headKhadem: head1st,
          gradeKhodam: khodam1st,
          color: const Color(0xFF3B82F6),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildGradeHeadCard(
          gradeKey: AppConstants.grade2nd,
          gradeTitle: context.tr.grade2ndName,
          headKhadem: head2nd,
          gradeKhodam: khodam2nd,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildGradeHeadCard(
          gradeKey: AppConstants.grade3rd,
          gradeTitle: context.tr.grade3rdName,
          headKhadem: head3rd,
          gradeKhodam: khodam3rd,
          color: const Color(0xFFEC4899),
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // 3. فريق الخدام وتوزيع السنين
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr.messageAssignedSecondaryStageServants,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            Text(
              context.tr.messageServants((displayedKhodam.length).toString()),
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // فلاتر السنين
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildGradeFilterChip('all', context.tr.allGrades, isDark),
              const SizedBox(width: 8),
              _buildGradeFilterChip(
                AppConstants.grade1st,
                '${context.tr.grade1stName} (${khodam1st.length})',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildGradeFilterChip(
                AppConstants.grade2nd,
                '${context.tr.grade2ndName} (${khodam2nd.length})',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildGradeFilterChip(
                AppConstants.grade3rd,
                '${context.tr.grade3rdName} (${khodam3rd.length})',
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (displayedKhodam.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                context.tr.messageNoServantsAssignedToThisSectionYet,
                style: TextStyle(color: AppConstants.textMuted),
              ),
            ),
          )
        else
          ...displayedKhodam.map((khadem) {
            final color = ColorGenerator.getColorForId(khadem.id);
            final assignedCount = widget.allMakhdomeen
                .where((m) => m.assignedKhademId == khadem.id)
                .length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      khadem.name.isNotEmpty
                          ? khadem.name[0]
                          : context.tr.messageS,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
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
                            Text(
                              khadem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            if (khadem.isGradeAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.sacredGold.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr.currentGradeAdmin,
                                  style: TextStyle(
                                    color: AppConstants.sacredGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr.messageAssignedStudents730(
                            (_getGradeLabel(khadem.grade)).toString(),
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatNumber((assignedCount)),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    color: AppConstants.textMuted,
                    onPressed: () => _makeCall(khadem.phone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppConstants.textMuted,
                    tooltip: context.tr.messageChangeGrade732,
                    onPressed: () => _openAssignGradeDialog(khadem),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPendingKhademCard(KhademModel khadem, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppConstants.warningColor.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_add_rounded,
              color: AppConstants.warningColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  khadem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  khadem.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openAssignGradeDialog(khadem),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              context.tr.messageAssign,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeHeadCard({
    required String gradeKey,
    required String gradeTitle,
    required KhademModel? headKhadem,
    required List<KhademModel> gradeKhodam,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gradeTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  headKhadem != null
                      ? headKhadem.name
                      : context.tr.noGradeHeadAssigned,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: headKhadem != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: headKhadem != null ? null : AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _openAppointHeadDialog(
              gradeKey: gradeKey,
              gradeTitle: gradeTitle,
              gradeKhodam: gradeKhodam,
              currentHead: headKhadem,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              headKhadem != null
                  ? (context.tr.messageChangeHead)
                  : (context.tr.messageAppointHead),
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeFilterChip(String key, String label, bool isDark) {
    final isSelected = _selectedGradeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedGradeFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryLight
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryLight
                : (isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppConstants.textDark),
          ),
        ),
      ),
    );
  }

  String _getGradeLabel(String? grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return context.tr.messageUnspecified;
    }
  }
}

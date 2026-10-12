import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class MyAnalyticsTab extends StatefulWidget {
  final List<MakhdomModel> myMakhdomeen;
  final List<AttendanceSessionModel> sessions;
  final List<VisitModel> visits;
  final DateTime? from, asOf;
  final VoidCallback? onVisitRecorded;

  const MyAnalyticsTab({
    super.key,
    required this.myMakhdomeen,
    required this.sessions,
    this.visits = const [],
    this.from,
    this.asOf,
    this.onVisitRecorded,
  });

  @override
  State<MyAnalyticsTab> createState() => _MyAnalyticsTabState();
}

class _MyAnalyticsTabState extends State<MyAnalyticsTab> {
  String _behaviorFilter = 'all';

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    final url = Uri.parse('https://wa.me/2$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.myMakhdomeen.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.query_stats_rounded,
                size: 48,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.noMakhdomeenAssignedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr.noMakhdomeenAssignedSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final attendanceRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: widget.myMakhdomeen,
          sessions: widget.sessions,
          from: widget.from,
          asOf: widget.asOf,
        );
    final visitedIds = widget.visits.map((v) => v.makhdomId).toSet();
    final visitedCount = widget.myMakhdomeen
        .where((m) => visitedIds.contains(m.id))
        .length;
    final totalCount = widget.myMakhdomeen.length;
    final visitRate = totalCount > 0 ? (visitedCount / totalCount * 100) : 0.0;

    final impact = AttendanceAnalyticsService.calculateVisitationImpact(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      visits: widget.visits,
      from: widget.from,
      asOf: widget.asOf,
    );

    final segmentation = AttendanceAnalyticsService.segmentStudents(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      from: widget.from,
      asOf: widget.asOf,
    );

    final atRiskList = AttendanceAnalyticsService.getAtRiskStudents(
      makhdomeen: widget.myMakhdomeen,
      sessions: widget.sessions,
      from: widget.from,
      asOf: widget.asOf,
    );

    List<MakhdomModel> segmentedList;
    if (_behaviorFilter == 'consistent') {
      segmentedList = segmentation.consistent;
    } else if (_behaviorFilter == 'irregular') {
      segmentedList = segmentation.irregular;
    } else if (_behaviorFilter == 'atRisk') {
      segmentedList = segmentation.atRisk;
    } else if (_behaviorFilter == 'insufficient') {
      segmentedList = segmentation.insufficient;
    } else {
      segmentedList = widget.myMakhdomeen;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.from != null)
            Text(
              context.tr.analyticsDateBounds(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatDate(widget.from!),
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatDate(widget.asOf ?? DateTime.now()),
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _buildStatCard(
                title: context.tr.servantGroupAttendanceRate,
                value: attendanceRate == null
                    ? context.tr.insufficientAttendanceData
                    : '${AppFormatters(Localizations.localeOf(context)).formatNumber(attendanceRate, decimalDigits: 0)}%',
                subtitle: context.tr.messageAllSessions,
                icon: Icons.how_to_reg_rounded,
                color: Colors.teal,
                isDark: isDark,
              ),
              _buildStatCard(
                title: context.tr.servantGroupVisitationProgress,
                value:
                    '${AppFormatters(Localizations.localeOf(context)).formatNumber(visitRate, decimalDigits: 0)}%',
                subtitle: context.tr.messageOfStudents(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber((visitedCount)),
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber((totalCount)),
                ),
                icon: Icons.volunteer_activism_rounded,
                color: AppConstants.primaryLight,
                isDark: isDark,
              ),
              _buildStatCard(
                title: context.tr.urgentVisitationNeeded,
                value: '${atRiskList.length}',
                subtitle: attendanceRate == null
                    ? context.tr.insufficientAttendanceData
                    : atRiskList.isEmpty
                    ? (context.tr.messageAllConsistent)
                    : (context.tr.messageAbsenceAlert649),
                icon: Icons.warning_amber_rounded,
                color: atRiskList.isEmpty
                    ? AppConstants.successColor
                    : AppConstants.errorColor,
                isDark: isDark,
              ),
              _buildStatCard(
                title: context.tr.segmentConsistent,
                value: AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(segmentation.consistent.length),
                subtitle: context.tr.messageAttendance75,
                icon: Icons.star_rounded,
                color: AppConstants.accentGold,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildVisitationImpactCard(impact, isDark),
          const SizedBox(height: 18),
          _buildAbsenceAlertsSection(atRiskList, isDark),
          const SizedBox(height: 22),
          _buildBehavioralSegmentationSection(
            segmentation,
            segmentedList,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitationImpactCard(VisitationImpactInfo impact, bool isDark) {
    if (!impact.hasSufficientData) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(context.tr.insufficientAttendanceData),
      );
    }
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.visitationImpactHeader,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      context.tr.visitationImpactSubtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr.messageVisited,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${AppFormatters(Localizations.localeOf(context)).formatNumber(impact.visitedAttendanceRate!, decimalDigits: 0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (impact.visitedAttendanceRate! / 100).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppConstants.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr.messageUnvisited,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${AppFormatters(Localizations.localeOf(context)).formatNumber(impact.unvisitedAttendanceRate!, decimalDigits: 0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (impact.unvisitedAttendanceRate! / 100).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppConstants.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: impact.impactPercentage! > 0
                  ? AppConstants.successColor.withValues(alpha: 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              context.tr.visitationImpactValue(impact.impactPercentage!),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: impact.impactPercentage! > 0
                    ? AppConstants.successColor
                    : (isDark ? Colors.white70 : AppConstants.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceAlertsSection(
    List<AtRiskStudentInfo> atRiskList,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: AppConstants.errorColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr.absenceAlertsHeader,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    (atRiskList.isEmpty
                            ? AppConstants.successColor
                            : AppConstants.errorColor)
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${atRiskList.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: atRiskList.isEmpty
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.tr.absenceAlertsSubtitle,
          style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
        ),
        const SizedBox(height: 10),
        if (atRiskList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppConstants.successColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AttendanceAnalyticsService.calculateOverallAttendanceRate(
                              makhdomeen: widget.myMakhdomeen,
                              sessions: widget.sessions,
                              asOf: widget.asOf,
                              from: widget.from,
                            ) ==
                            null
                        ? context.tr.insufficientAttendanceData
                        : context.tr.noAbsenceAlerts,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppConstants.successColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...atRiskList.map((info) => _buildAtRiskStudentCard(info, isDark)),
      ],
    );
  }

  Widget _buildAtRiskStudentCard(AtRiskStudentInfo info, bool isDark) {
    final m = info.makhdom;
    final color = info.isCritical ? AppConstants.errorColor : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (m.area.isNotEmpty)
                      Text(
                        m.area,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppConstants.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr.missedFridaysCount(info.consecutiveAbsences),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (m.phone.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => _makeCall(m.phone),
                  icon: const Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: AppConstants.successColor,
                  ),
                  label: Text(
                    context.tr.messageCall,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.successColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    side: const BorderSide(color: AppConstants.successColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(m.phone),
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 14,
                    color: Colors.teal,
                  ),
                  label: Text(
                    context.tr.messageWhatsapp,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  await RecordVisitSheet.show(context, makhdom: m);
                  if (mounted) widget.onVisitRecorded?.call();
                },
                icon: const Icon(
                  Icons.edit_calendar_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  context.tr.messageVisit650,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehavioralSegmentationSection(
    BehavioralSegmentation segmentation,
    List<MakhdomModel> segmentedList,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.messageBehavioralSegmentation651,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSegmentTabChip(
              label: context.tr.all,
              count: widget.myMakhdomeen.length,
              key: 'all',
              color: AppConstants.primaryLight,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildSegmentTabChip(
              label: context.tr.segmentConsistent,
              count: segmentation.consistent.length,
              key: 'consistent',
              color: AppConstants.successColor,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildSegmentTabChip(
              label: context.tr.segmentIrregular,
              count: segmentation.irregular.length,
              key: 'irregular',
              color: Colors.orange,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildSegmentTabChip(
              label: context.tr.segmentAtRisk,
              count: segmentation.atRisk.length,
              key: 'atRisk',
              color: AppConstants.errorColor,
              isDark: isDark,
            ),
            _buildSegmentTabChip(
              label: context.tr.insufficientAttendanceData,
              count: segmentation.insufficient.length,
              key: 'insufficient',
              color: Colors.blueGrey,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (segmentedList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                context.tr.noSearchResults,
                style: const TextStyle(color: AppConstants.textMuted),
              ),
            ),
          )
        else
          ...segmentedList.map((m) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppConstants.royalGold.withValues(alpha: 0.15),
                child: Text(
                  m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
                ),
              ),
              title: Text(
                m.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                m.phone,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: () async {
                  await RecordVisitSheet.show(context, makhdom: m);
                  if (mounted) widget.onVisitRecorded?.call();
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSegmentTabChip({
    required String label,
    required int count,
    required String key,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _behaviorFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _behaviorFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppConstants.textDark),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              AppFormatters(
                Localizations.localeOf(context),
              ).formatNumber(count),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white70 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

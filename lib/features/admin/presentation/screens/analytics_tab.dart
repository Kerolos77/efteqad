import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/widgets/query_content.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class AnalyticsTab extends StatefulWidget {
  final FirestoreService? firestoreService;
  final DateTime? asOf;
  final List<MakhdomModel> makhdomeen;
  final List<KhademModel> khodam;
  final String? grade; // '1st', '2nd', '3rd', or null for Stage Admin

  const AnalyticsTab({
    super.key,
    required this.makhdomeen,
    required this.khodam,
    this.grade,
    this.firestoreService,
    this.asOf,
  });

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  String _selectedSubTab = 'visits'; // 'visits', 'attendance', 'insights'
  String _behaviorFilter = 'all'; // 'all', 'consistent', 'irregular', 'atRisk'

  late Stream<List<AttendanceSessionModel>> _attendanceStream;
  late final DateTime _asOf = widget.asOf ?? DateTime.now();
  bool _allTime = false;
  DateTime? get _from => _allTime ? null : calendarDay(_asOf, -89);
  List<VisitModel> _windowVisits = [];
  Set<String> get _visitedIds => _windowVisits.map((v) => v.makhdomId).toSet();

  @override
  void initState() {
    super.initState();
    _initAttendanceStream();
  }

  void _initAttendanceStream() {
    if (widget.grade != null) {
      _attendanceStream = _firestoreService.getAttendanceSessionsForGradeStream(
        widget.grade!,
        from: _from,
        to: _asOf,
      );
    } else {
      _attendanceStream = _firestoreService.getAllAttendanceSessionsStream(
        from: _from,
        to: _asOf,
      );
    }
  }

  @override
  void didUpdateWidget(covariant AnalyticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.grade != oldWidget.grade) {
      setState(() {
        _initAttendanceStream();
      });
    }
  }

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
    if (clean.isEmpty) return;
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.makhdomeen.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 50,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr.noAnalyticsData,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return QueryContent<List<VisitModel>>(
      queryKey: '${widget.grade}/$_from/$_asOf',
      query: () => _firestoreService.getAllVisitsStream(
        grade: widget.grade,
        from: _from,
        to: _asOf,
      ),
      builder: (context, visits) {
        _windowVisits = visits;
        return QueryContent<List<AttendanceSessionModel>>(
          queryKey: '${widget.grade}/$_from/$_asOf',
          query: () => _attendanceStream,
          builder: (context, sessions) {
            final atRiskList = AttendanceAnalyticsService.getAtRiskStudents(
              makhdomeen: widget.makhdomeen,
              sessions: sessions,
              minConsecutiveAbsences: 2,
              asOf: _asOf,
              from: _from,
            );

            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر الرئيسي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.performanceAndCareIndicators,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : AppConstants.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                context.tr.liveFollowupAndRates,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.sacredGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _allTime
                                      ? context.tr.filterAllTime
                                      : context.tr.messageLast90Days,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppConstants.sacredGold
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    _from == null
                        ? context.tr.filterAllTime
                        : context.tr.analyticsDateBounds(
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatDate(_from!),
                            AppFormatters(
                              Localizations.localeOf(context),
                            ).formatDate(_asOf),
                          ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _allTime = !_allTime;
                      _initAttendanceStream();
                    }),
                    child: Text(
                      _allTime
                          ? context.tr.filterLast90Days
                          : context.tr.filterAllTime,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // شريط التنقل الفرعي الثلاثي (مؤشرات الافتقاد • مؤشرات الحضور • التحليلات والتنبيهات)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildSubTabChip(
                          key: 'visits',
                          label: context.tr.tabVisitsAnalytics,
                          icon: Icons.volunteer_activism_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSubTabChip(
                          key: 'attendance',
                          label: context.tr.tabAttendanceAnalytics,
                          icon: Icons.fact_check_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSubTabChip(
                          key: 'insights',
                          label: context.tr.tabSmartInsights,
                          icon: Icons.psychology_outlined,
                          isDark: isDark,
                          badgeCount: atRiskList.length,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // محتوى التبويب المختار
                  if (_selectedSubTab == 'visits')
                    _buildVisitsContent(isDark)
                  else if (_selectedSubTab == 'attendance')
                    _buildAttendanceContent(sessions, isDark)
                  else
                    _buildSmartInsightsContent(sessions, atRiskList, isDark),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubTabChip({
    required String key,
    required String label,
    required IconData icon,
    required bool isDark,
    int? badgeCount,
  }) {
    final isSelected = _selectedSubTab == key;

    return InkWell(
      onTap: () => setState(() => _selectedSubTab = key),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15)
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryLight
                : (isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppConstants.primaryLight
                  : (isDark ? Colors.white70 : AppConstants.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppConstants.primaryLight
                    : (isDark ? Colors.white70 : AppConstants.textDark),
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber(badgeCount),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. مؤشرات الافتقاد (Visits Content)
  // ===========================================================================
  Widget _buildVisitsContent(bool isDark) {
    final totalMakhdomeen = widget.makhdomeen.length;
    final assignedMakhdomeen = widget.makhdomeen
        .where((m) => m.isAssigned)
        .length;
    final unassignedMakhdomeen = totalMakhdomeen - assignedMakhdomeen;
    final visitedAtLeastOnce = widget.makhdomeen
        .where((m) => _visitedIds.contains(m.id))
        .length;
    final neverVisited = totalMakhdomeen - visitedAtLeastOnce;
    final brethrenCount = widget.makhdomeen
        .where((m) => m.isBrethrenOfLord)
        .length;
    final visitPercentage = totalMakhdomeen > 0
        ? (visitedAtLeastOnce / totalMakhdomeen) * 100
        : 0.0;

    final List<Map<String, dynamic>> khademStats = [];
    for (var k in widget.khodam) {
      final myMakhdomeen = widget.makhdomeen
          .where((m) => m.assignedKhademId == k.id)
          .toList();
      final total = myMakhdomeen.length;
      final visited = myMakhdomeen
          .where((m) => _visitedIds.contains(m.id))
          .length;
      final percentage = total > 0 ? (visited / total) * 100 : 0.0;

      khademStats.add({
        'khadem': k,
        'total': total,
        'visited': visited,
        'percentage': percentage,
      });
    }
    khademStats.sort(
      (a, b) =>
          (b['percentage'] as double).compareTo(a['percentage'] as double),
    );

    final unvisitedList = widget.makhdomeen
        .where((m) => !_visitedIds.contains(m.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // كروت الإحصائيات السريعة
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _buildStatCard(
              title: context.tr.totalMakhdomeenTitle,
              value: '$totalMakhdomeen',
              icon: Icons.groups_outlined,
              color: AppConstants.primaryLight,
              subtitle: context.tr.totalBoysAssignedSubtitle(
                assignedMakhdomeen,
              ),
              isDark: isDark,
            ),
            _buildStatCard(
              title: context.tr.visitationRateTitle,
              value:
                  '${AppFormatters(Localizations.localeOf(context)).formatNumber(visitPercentage, decimalDigits: 0)}%',
              icon: Icons.pie_chart_outline,
              color: AppConstants.successColor,
              subtitle: context.tr.visitedBoysCountSubtitle(visitedAtLeastOnce),
              isDark: isDark,
            ),
            _buildStatCard(
              title: context.tr.neverVisitedTitle,
              value: '$neverVisited',
              icon: Icons.person_off_outlined,
              color: AppConstants.errorColor,
              subtitle: context.tr.needsUrgentVisitSubtitle,
              isDark: isDark,
            ),
            _buildStatCard(
              title: context.tr.brethrenOfLordTitle,
              value: AppFormatters(
                Localizations.localeOf(context),
              ).formatNumber(brethrenCount),
              icon: Icons.favorite_border,
              color: AppConstants.accentGold,
              subtitle: context.tr.specialFollowupSubtitle,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // الرسم البياني الدائري لحالة الافتقاد
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
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
                context.tr.visitationDistributionTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: visitedAtLeastOnce.toDouble(),
                        title:
                            '${AppFormatters(Localizations.localeOf(context)).formatNumber(visitPercentage, decimalDigits: 0)}%',
                        color: AppConstants.successColor,
                        radius: 38,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      PieChartSectionData(
                        value: neverVisited.toDouble(),
                        title:
                            '${AppFormatters(Localizations.localeOf(context)).formatNumber(((neverVisited / totalMakhdomeen) * 100), decimalDigits: 0)}%',
                        color: AppConstants.errorColor,
                        radius: 38,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      if (unassignedMakhdomeen > 0)
                        PieChartSectionData(
                          value: unassignedMakhdomeen.toDouble(),
                          title: '',
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                          radius: 32,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: [
                  _buildLegendItem(
                    AppConstants.successColor,
                    '${context.tr.filterVisited} ($visitedAtLeastOnce)',
                    isDark,
                  ),
                  _buildLegendItem(
                    AppConstants.errorColor,
                    '${context.tr.filterUnvisited} ($neverVisited)',
                    isDark,
                  ),
                  if (unassignedMakhdomeen > 0)
                    _buildLegendItem(
                      isDark ? Colors.white38 : Colors.grey.shade400,
                      '${context.tr.filterUnassigned} ($unassignedMakhdomeen)',
                      isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // نسب إنجاز الخدام
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
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
                  const Icon(
                    Icons.leaderboard_outlined,
                    color: AppConstants.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr.servantsAchievementRatesTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (khademStats.isEmpty)
                Center(
                  child: Text(
                    context.tr.noKhodamYet,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                    ),
                  ),
                )
              else
                ...khademStats.map((stat) {
                  final k = stat['khadem'] as KhademModel;
                  final total = stat['total'] as int;
                  final visited = stat['visited'] as int;
                  final p = stat['percentage'] as double;
                  final color = ColorGenerator.getColorForId(k.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: color.withValues(alpha: 0.2),
                                  child: Text(
                                    k.name.isNotEmpty
                                        ? k.name[0]
                                        : context.tr.messageS,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  k.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${AppFormatters(Localizations.localeOf(context)).formatNumber(visited)} / ${AppFormatters(Localizations.localeOf(context)).formatNumber(total)} (${AppFormatters(Localizations.localeOf(context)).formatNumber(p, decimalDigits: 0)}%)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total > 0 ? (visited / total) : 0.0,
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // قائمة الأولاد الذين لم يُفتقدوا نهائياً
        if (unvisitedList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppConstants.errorColor.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppConstants.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr.unvisitedChildrenHeader(
                            unvisitedList.length,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...unvisitedList.take(6).map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppConstants.cardBorderDark
                            : AppConstants.cardBorderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                m.isAssigned
                                    ? context.tr.assignedToKhademLabel(
                                        m.assignedKhademName!,
                                      )
                                    : context.tr.unassignedBadge,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: m.isAssigned
                                      ? AppConstants.textMuted
                                      : AppConstants.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (m.phone.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: AppConstants.successColor,
                            ),
                            onPressed: () => _makeCall(m.phone),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 2. مؤشرات الحضور والغياب (Attendance Content)
  // ===========================================================================
  Widget _buildAttendanceContent(
    List<AttendanceSessionModel> sessions,
    bool isDark,
  ) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.messageNoAttendanceSessionsRecordedYet,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context
                    .tr
                    .messageWeeklyStatisticsAppearHereAfterRecordingAttendance,
                style: TextStyle(fontSize: 11.5, color: AppConstants.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final overallRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: widget.makhdomeen,
          sessions: sessions,
          asOf: _asOf,
          from: _from,
        );

    final serviceSessions = sessions.where((s) => s.type == 'khedma').toList();
    final massSessions = sessions.where((s) => s.type == 'qoddas').toList();

    final serviceRate =
        AttendanceAnalyticsService.calculateOverallAttendanceRate(
          makhdomeen: widget.makhdomeen,
          sessions: serviceSessions,
          asOf: _asOf,
          from: _from,
        );
    final massRate = AttendanceAnalyticsService.calculateOverallAttendanceRate(
      makhdomeen: widget.makhdomeen,
      sessions: massSessions,
      type: 'qoddas',
      asOf: _asOf,
      from: _from,
    );

    final weeklyTrend = AttendanceAnalyticsService.getWeeklyTrend(
      makhdomeen: widget.makhdomeen,
      sessions: sessions,
      asOf: _asOf,
      from: _from,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // كروت نسب الحضور الرئيسية
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _buildStatCard(
              title: context.tr.messageOverallAttendanceRate,
              value: overallRate == null
                  ? context.tr.insufficientAttendanceData
                  : '${AppFormatters(Localizations.localeOf(context)).formatNumber(overallRate, decimalDigits: 1)}%',
              icon: Icons.how_to_reg_rounded,
              color: const Color(0xFF8B5CF6),
              subtitle: context.tr.messageAverageOfRecordedSessions,
              isDark: isDark,
            ),
            _buildStatCard(
              title: context.tr.messageAttendanceFridays,
              value: '${sessions.length}',
              icon: Icons.calendar_today_rounded,
              color: AppConstants.primaryLight,
              subtitle: context.tr.messageServiceMass(
                (serviceSessions.length).toString(),
                (massSessions.length).toString(),
              ),
              isDark: isDark,
            ),
            _buildStatCard(
              title: context.tr.messageServiceAttendance,
              value: serviceRate == null
                  ? context.tr.insufficientAttendanceData
                  : '${AppFormatters(Localizations.localeOf(context)).formatNumber(serviceRate, decimalDigits: 1)}%',
              icon: Icons.fact_check_outlined,
              color: AppConstants.successColor,
              subtitle: context.tr.messageAverageSundaySchoolAttendance,
              isDark: isDark,
            ),
            _buildStatCard(
              title: context.tr.messageMassAttendance,
              value: massRate == null
                  ? context.tr.insufficientAttendanceData
                  : '${AppFormatters(Localizations.localeOf(context)).formatNumber(massRate, decimalDigits: 1)}%',
              icon: Icons.church_rounded,
              color: AppConstants.accentGold,
              subtitle: context.tr.messageAverageMassAttendance,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // منحنى وجدول الجلسات الأسبوعية
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
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
                  const Icon(
                    Icons.timeline_rounded,
                    color: AppConstants.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr.messageWeeklyAttendanceRecentFridays,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...weeklyTrend.map((point) {
                final isMass = point.type == 'qoddas';
                final color = isMass
                    ? AppConstants.accentGold
                    : const Color(0xFF8B5CF6);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isMass
                                      ? context.tr.messageMass
                                      : context.tr.messageService,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final dt = DateTime.tryParse(point.date);
                                  final dayLabel = dt != null
                                      ? AppFormatters(
                                          Localizations.localeOf(context),
                                        ).formatDate(dt, format: 'EEEE')
                                      : (context.tr.messageSession);
                                  return Text(
                                    '$dayLabel ${point.date}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            '${point.attendedCount} / ${point.totalEligible} (${AppFormatters(Localizations.localeOf(context)).formatNumber(point.percentage, decimalDigits: 0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: point.totalEligible > 0
                              ? (point.attendedCount / point.totalEligible)
                              : 0.0,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. التحليلات الذكية والتنبيهات (Smart Insights & Absence Alerts)
  // ===========================================================================
  Widget _buildSmartInsightsContent(
    List<AttendanceSessionModel> sessions,
    List<AtRiskStudentInfo> atRiskList,
    bool isDark,
  ) {
    final impact = AttendanceAnalyticsService.calculateVisitationImpact(
      makhdomeen: widget.makhdomeen,
      sessions: sessions,
      visits: _windowVisits,
      from: _from,
      asOf: _asOf,
    );

    final segmentation = AttendanceAnalyticsService.segmentStudents(
      makhdomeen: widget.makhdomeen,
      sessions: sessions,
      asOf: _asOf,
      from: _from,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------ كارت إنذارات الغياب المتكرر ------------------
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: atRiskList.isNotEmpty
                  ? AppConstants.errorColor.withValues(alpha: 0.35)
                  : AppConstants.successColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        atRiskList.isNotEmpty
                            ? Icons.warning_rounded
                            : Icons.check_circle_outline,
                        color: atRiskList.isNotEmpty
                            ? AppConstants.errorColor
                            : AppConstants.successColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr.absenceAlertsHeader,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: atRiskList.isNotEmpty
                              ? AppConstants.errorColor
                              : AppConstants.successColor,
                        ),
                      ),
                    ],
                  ),
                  if (atRiskList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.errorColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.tr.messageStudents(
                          (atRiskList.length).toString(),
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.errorColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr.absenceAlertsSubtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textMuted,
                ),
              ),
              const SizedBox(height: 14),

              if (atRiskList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      AttendanceAnalyticsService.calculateOverallAttendanceRate(
                                makhdomeen: widget.makhdomeen,
                                sessions: sessions,
                                asOf: _asOf,
                                from: _from,
                              ) ==
                              null
                          ? context.tr.insufficientAttendanceData
                          : context.tr.noAbsenceAlerts,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                )
              else
                ...atRiskList.map((info) {
                  final m = info.makhdom;
                  final badgeColor = info.isCritical
                      ? AppConstants.errorColor
                      : AppConstants.warningColor;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                info.isCritical
                                    ? context.tr.criticalAbsenceBadge
                                    : context.tr.warningAbsenceBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              context.tr.missedFridaysCount(
                                info.consecutiveAbsences,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                            if (m.isAssigned) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(color: AppConstants.textMuted),
                              ),
                              Text(
                                context.tr.assignedToKhademLabel(
                                  m.assignedKhademName!,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // أزرار الإجراء الفوري المباشر (اتصال، واتساب، تسجيل افتقاد)
                        Row(
                          children: [
                            if (m.phone.isNotEmpty) ...[
                              InkWell(
                                onTap: () => _makeCall(m.phone),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.successColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.call,
                                        size: 13,
                                        color: AppConstants.successColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.tr.callAction,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppConstants.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _openWhatsApp(m.phone),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF25D366,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.whatsapp,
                                        size: 13,
                                        color: Color(0xFF25D366),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.tr.whatsappAction,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF25D366),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (m.isAssigned) ...[
                              InkWell(
                                onTap: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    final receipt = await NotificationService()
                                        .notifyKhadem(
                                          recipientId: m.assignedKhademId!,
                                          recipientName:
                                              m.assignedKhademName ?? '',
                                          title: context.tr.messageAbsenceAlert(
                                            (m.fullName).toString(),
                                          ),
                                          body: context.tr
                                              .messageStudentMissedFridaysPleaseVisitSoon(
                                                (info.consecutiveAbsences)
                                                    .toString(),
                                              ),
                                          type: 'absence_alert',
                                          data: {
                                            'makhdomId': m.id,
                                            'consecutiveAbsences':
                                                info.consecutiveAbsences,
                                            'grade': m.grade,
                                          },
                                        );
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.tr.messageUrgentAlertSentTo(
                                              receipt['recipientName']
                                                      as String? ??
                                                  '',
                                            ),
                                          ),
                                          backgroundColor:
                                              AppConstants.successColor,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppFailure.fromException(
                                              e,
                                            ).localizedMessage(context.tr),
                                          ),
                                          backgroundColor:
                                              AppConstants.errorColor,
                                        ),
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.notifications_active_outlined,
                                        size: 13,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.tr.messageNotify,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // زر تسجيل افتقاد مباشر
                            ElevatedButton.icon(
                              onPressed: () {
                                RecordVisitSheet.show(context, makhdom: m);
                              },
                              icon: const Icon(Icons.add_task, size: 14),
                              label: Text(
                                context.tr.visitAction,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.accentIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ------------------ كارت أثر الافتقاد على الحضور ------------------
        if (!impact.hasSufficientData)
          Text(context.tr.insufficientAttendanceData)
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppConstants.accentGold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      color: AppConstants.accentGold,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr.visitationImpactHeader,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr.visitationImpactSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textMuted,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // المفتقدون
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppConstants.successColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.tr.messageVisitedStudents,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${AppFormatters(Localizations.localeOf(context)).formatNumber(impact.visitedAttendanceRate!, decimalDigits: 1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConstants.successColor,
                              ),
                            ),
                            Text(
                              context.tr.messageStudents705(
                                (impact.visitedStudentsCount).toString(),
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // غير المفتقدين
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppConstants.errorColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.tr.messageUnvisitedStudents,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${AppFormatters(Localizations.localeOf(context)).formatNumber(impact.unvisitedAttendanceRate!, decimalDigits: 1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConstants.errorColor,
                              ),
                            ),
                            Text(
                              context.tr.messageStudents708(
                                (impact.unvisitedStudentsCount).toString(),
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // شريط النتيجة الإحصائية
                if (impact.hasSufficientData)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: AppConstants.accentGold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr.visitationImpactValue(
                              impact.impactPercentage!,
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),

        // ------------------ كارت التصنيف السلوكي للأولاد ------------------
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
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
                  const Icon(
                    Icons.psychology_outlined,
                    color: AppConstants.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr.messageStudentAttendanceGroups,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // الأزرار الثلاثة للاختيار
              Row(
                children: [
                  Expanded(
                    child: _buildBehaviorChip(
                      label: context.tr.segmentConsistent,
                      count: segmentation.consistent.length,
                      color: AppConstants.successColor,
                      key: 'consistent',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBehaviorChip(
                      label: context.tr.segmentIrregular,
                      count: segmentation.irregular.length,
                      color: AppConstants.warningColor,
                      key: 'irregular',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBehaviorChip(
                      label: context.tr.segmentAtRisk,
                      count: segmentation.atRisk.length,
                      color: AppConstants.errorColor,
                      key: 'atRisk',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildBehaviorChip(
                label: context.tr.insufficientAttendanceData,
                count: segmentation.insufficient.length,
                color: Colors.blueGrey,
                key: 'insufficient',
              ),
              // عرض قائمة أسماء المجموعة المختارة
              _buildSelectedBehaviorList(segmentation, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorChip({
    required String label,
    required int count,
    required Color color,
    required String key,
  }) {
    final isSelected = _behaviorFilter == key;

    return InkWell(
      onTap: () {
        setState(() {
          _behaviorFilter = isSelected ? 'all' : key;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(
              AppFormatters(
                Localizations.localeOf(context),
              ).formatNumber(count),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBehaviorList(
    BehavioralSegmentation segmentation,
    bool isDark,
  ) {
    List<MakhdomModel> list;
    if (_behaviorFilter == 'consistent') {
      list = segmentation.consistent;
    } else if (_behaviorFilter == 'irregular') {
      list = segmentation.irregular;
    } else if (_behaviorFilter == 'atRisk') {
      list = segmentation.atRisk;
    } else if (_behaviorFilter == 'insufficient') {
      list = segmentation.insufficient;
    } else {
      return const SizedBox.shrink();
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            context.tr.messageNoStudentsInThisGroup,
            style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: list.take(8).map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.fullName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                m.isAssigned
                    ? m.assignedKhademName!
                    : context.tr.unassignedBadge,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppConstants.textDark,
          ),
        ),
      ],
    );
  }
}

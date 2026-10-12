import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../admin/presentation/widgets/makhdom_card.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../common/widgets/notifications_sheet.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import '../../../tasks/presentation/widgets/tasks_tab.dart';

class KhademHomeScreen extends StatefulWidget {
  final String? grade;

  const KhademHomeScreen({super.key, this.grade});

  @override
  State<KhademHomeScreen> createState() => _KhademHomeScreenState();
}

class _KhademHomeScreenState extends State<KhademHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late final Stream<List<MakhdomModel>> _makhdomeenStream;
  late final Stream<List<TaskModel>> _tasksStream;
  late final Stream<List<AttendanceSessionModel>> _attendanceStream;

  int _selectedTabIndex = 0;
  String _filter = 'all'; // 'all', 'visited', 'unvisited', 'brethren'
  String _search = '';
  String _behaviorFilter = 'all'; // 'all', 'consistent', 'irregular', 'atRisk'

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _makhdomeenStream = _firestoreService.getMakhdomeenForKhademStream(
      user?.uid ?? '',
    );
    _tasksStream = _firestoreService.getTasksForKhademStream(user?.uid ?? '');
    if (widget.grade != null) {
      _attendanceStream = _firestoreService.getAttendanceSessionsForGradeStream(
        widget.grade!,
      );
    } else {
      _attendanceStream = _firestoreService.getAllAttendanceSessionsStream();
    }
  }

  void _openRecordVisitSheet(MakhdomModel makhdom) {
    RecordVisitSheet.show(context, makhdom: makhdom);
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
    final user = _authService.currentUser;
    final khademColor = ColorGenerator.getColorForId(user?.uid ?? user?.email);

    return Scaffold(
      drawer: const AppDrawer(isAdmin: false),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: context.tr.messageMainMenu,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _selectedTabIndex == 0
                  ? context.tr.myGroupAndVisits
                  : (_selectedTabIndex == 1
                        ? context.tr.myTasksTitle
                        : context.tr.servantMyAnalytics),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            if (widget.grade != null)
              Text(
                widget.grade == AppConstants.grade1st
                    ? context.tr.grade1stName
                    : (widget.grade == AppConstants.grade2nd
                          ? context.tr.grade2ndName
                          : context.tr.grade3rdName),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: const [NotificationBellButton()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.tr.myGroupAndVisits,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: context.tr.myTasksTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: context.tr.servantMyAnalytics,
          ),
        ],
      ),
      body: StreamBuilder<List<MakhdomModel>>(
        stream: _makhdomeenStream,
        builder: (context, makhdomeenSnap) {
          return StreamBuilder<List<AttendanceSessionModel>>(
            stream: _attendanceStream,
            builder: (context, attendanceSnap) {
              if (makhdomeenSnap.connectionState == ConnectionState.waiting &&
                  !makhdomeenSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allMyMakhdomeen = makhdomeenSnap.data ?? [];
              final attendanceSessions = attendanceSnap.data ?? [];

              final atRiskList = AttendanceAnalyticsService.getAtRiskStudents(
                makhdomeen: allMyMakhdomeen,
                sessions: attendanceSessions,
              );

              return IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // Tab 0: قائمة المخدومين والافتقاد مع تنبيه الغياب المبكر
                  _buildMyGroupTab(
                    isDark: isDark,
                    user: user,
                    khademColor: khademColor,
                    allMyMakhdomeen: allMyMakhdomeen,
                    atRiskList: atRiskList,
                  ),

                  // Tab 1: مهامي المكلف بها
                  TasksTab(
                    tasksStream: _tasksStream,
                    availableKhodam: const [],
                    grade: widget.grade ?? 'all',
                    canCreateTasks: false,
                  ),

                  // Tab 2: إحصائياتي الشخصية عن أولادي
                  _buildMyAnalyticsTab(
                    isDark: isDark,
                    khademColor: khademColor,
                    myMakhdomeen: allMyMakhdomeen,
                    sessions: attendanceSessions,
                    atRiskList: atRiskList,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Tab 0: قائمة المخدومين
  // ===========================================================================
  Widget _buildMyGroupTab({
    required bool isDark,
    required dynamic user,
    required Color khademColor,
    required List<MakhdomModel> allMyMakhdomeen,
    required List<AtRiskStudentInfo> atRiskList,
  }) {
    final visitedCount = allMyMakhdomeen.where((m) => m.visitCount > 0).length;
    final totalCount = allMyMakhdomeen.length;
    final percentage = totalCount > 0 ? (visitedCount / totalCount) : 0.0;

    // الفلترة
    final filtered = allMyMakhdomeen.where((m) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!m.fullName.toLowerCase().contains(q) &&
            !m.area.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filter == 'visited') return m.visitCount > 0;
      if (_filter == 'unvisited') return m.visitCount == 0;
      if (_filter == 'brethren') return m.isBrethrenOfLord;
      return true;
    }).toList();

    return Column(
      children: [
        // كارت ترحيب وإحصائيات الخادم الفخم (Hero Progress Card)
        Container(
          margin: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppConstants.cardBorderDark
                  : AppConstants.cardBorderLight,
              width: 1,
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
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: khademColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: khademColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        (user?.displayName != null &&
                                user!.displayName!.isNotEmpty)
                            ? user.displayName![0]
                            : (context.tr.messageS),
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
                        Text(
                          context.tr.servantGreeting(
                            user?.displayName ?? (context.tr.messageServant),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr.shepherdVerseGoodShepherd,
                          style: const TextStyle(
                            color: AppConstants.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // شريط الإنجاز
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr.visitedRatio(visitedCount, totalCount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${AppFormatters(Localizations.localeOf(context)).formatNumber((percentage * 100), decimalDigits: 0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: khademColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(khademColor),
                ),
              ),
            ],
          ),
        ),

        // تنبيه الغياب المتكرر العاجل (Early Absence Warning Banner)
        if (atRiskList.isNotEmpty)
          Container(
            margin: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr.messageAlertBoysNeedUrgentVisitRepeatedAbsence(
                      (atRiskList.length).toString(),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTabIndex = 2),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    context.tr.messageView,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // حقل البحث والفلترة (يظهر فقط إذا كان لدى الخادم مخدومين)
        if (allMyMakhdomeen.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) => setState(() => _search = val.trim()),
              decoration: InputDecoration(
                hintText: context.tr.searchMyMakhdomeen,
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // أزرار الفلترة السريعة (Clean Chips)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  '${context.tr.all} (${AppFormatters(Localizations.localeOf(context)).formatNumber(totalCount)})',
                  'all',
                  isDark,
                ),
                _buildFilterChip(
                  '${context.tr.filterUnvisited} (${totalCount - visitedCount})',
                  'unvisited',
                  isDark,
                ),
                _buildFilterChip(
                  '${context.tr.filterVisited} (${AppFormatters(Localizations.localeOf(context)).formatNumber(visitedCount)})',
                  'visited',
                  isDark,
                ),
                _buildFilterChip(
                  '${context.tr.filterBrethren} (${AppFormatters(Localizations.localeOf(context)).formatNumber(allMyMakhdomeen.where((m) => m.isBrethrenOfLord).length)})',
                  'brethren',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // قائمة الأولاد
        Expanded(
          child: allMyMakhdomeen.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_search_rounded,
                            size: 40,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr.noSearchResults,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    return MakhdomCard(
                      makhdom: m,
                      onLogVisit: () => _openRecordVisitSheet(m),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Tab 2: إحصائياتي الشخصية عن أولادي
  // ===========================================================================
  Widget _buildMyAnalyticsTab({
    required bool isDark,
    required Color khademColor,
    required List<MakhdomModel> myMakhdomeen,
    required List<AttendanceSessionModel> sessions,
    required List<AtRiskStudentInfo> atRiskList,
  }) {
    if (myMakhdomeen.isEmpty) {
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
          makhdomeen: myMakhdomeen,
          sessions: sessions,
        );
    final visitedCount = myMakhdomeen.where((m) => m.visitCount > 0).length;
    final totalCount = myMakhdomeen.length;
    final visitRate = totalCount > 0 ? (visitedCount / totalCount * 100) : 0.0;

    final impact = AttendanceAnalyticsService.calculateVisitationImpact(
      makhdomeen: myMakhdomeen,
      sessions: sessions,
    );

    final segmentation = AttendanceAnalyticsService.segmentStudents(
      makhdomeen: myMakhdomeen,
      sessions: sessions,
    );

    // قائمة الأولاد وفق التصنيف السلوكي المختار
    List<MakhdomModel> segmentedList;
    if (_behaviorFilter == 'consistent') {
      segmentedList = segmentation.consistent;
    } else if (_behaviorFilter == 'irregular') {
      segmentedList = segmentation.irregular;
    } else if (_behaviorFilter == 'atRisk') {
      segmentedList = segmentation.atRisk;
    } else {
      segmentedList = myMakhdomeen;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. كروت المؤشرات السريعة لمجموعتي
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
                subtitle: atRiskList.isEmpty
                    ? (context.tr.messageAllConsistent)
                    : (context.tr.messageAbsenceAlert637),
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

          // 2. كارت أثر الافتقاد على الحضور لمجموعتك
          _buildVisitationImpactCard(impact, isDark),
          const SizedBox(height: 18),

          // 3. إنذارات الغياب المتكرر لأولادي (Consecutive Absence Alerts)
          _buildAbsenceAlertsSection(atRiskList, isDark),
          const SizedBox(height: 22),

          // 4. التصنيف السلوكي للأولاد وقائمتهم (Behavioral Segmentation)
          _buildBehavioralSegmentationSection(
            segmentation,
            segmentedList,
            sessions,
            isDark,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // مساعدات تصميم كروت إحصائيات الخادم
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: color,
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

          // شرائط المقارنة
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

          // ملاحظة الأثر الإحصائي
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
              impact.impactPercentage! != 0
                  ? context.tr.visitationImpactValue(impact.impactPercentage!)
                  : (context.tr.messageAttendanceRatesCurrentlyEqual),
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
                    context.tr.noAbsenceAlerts,
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
              // Badge
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
                onPressed: () => _openRecordVisitSheet(m),
                icon: const Icon(
                  Icons.edit_calendar_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  context.tr.messageVisit644,
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
    List<MakhdomModel> list,
    List<AttendanceSessionModel> sessions,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.psychology_rounded,
              color: AppConstants.accentGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr.messageBehavioralSegmentation,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // أزرار الفلترة بالتصنيف السلوكي
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildBehaviorChip(
                label:
                    '${context.tr.all} (${segmentation.consistent.length + segmentation.irregular.length + segmentation.atRisk.length})',
                value: 'all',
                color: AppConstants.primaryLight,
                isDark: isDark,
              ),
              _buildBehaviorChip(
                label:
                    '${context.tr.segmentConsistent} (${AppFormatters(Localizations.localeOf(context)).formatNumber(segmentation.consistent.length)})',
                value: 'consistent',
                color: AppConstants.accentGold,
                isDark: isDark,
              ),
              _buildBehaviorChip(
                label:
                    '${context.tr.segmentIrregular} (${AppFormatters(Localizations.localeOf(context)).formatNumber(segmentation.irregular.length)})',
                value: 'irregular',
                color: Colors.blue,
                isDark: isDark,
              ),
              _buildBehaviorChip(
                label:
                    '${context.tr.segmentAtRisk} (${AppFormatters(Localizations.localeOf(context)).formatNumber(segmentation.atRisk.length)})',
                value: 'atRisk',
                color: AppConstants.errorColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // قائمة الأولاد المصنفين
        if (list.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.tr.messageNoStudentsInThisSegment,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
            ),
          )
        else
          ...list.map((m) {
            final boyRate =
                AttendanceAnalyticsService.calculateOverallAttendanceRate(
                  makhdomeen: [m],
                  sessions: sessions,
                );
            return _buildStudentBehaviorCard(m, boyRate, isDark);
          }),
      ],
    );
  }

  Widget _buildStudentBehaviorCard(
    MakhdomModel m,
    double? boyRate,
    bool isDark,
  ) {
    Color rateColor = AppConstants.successColor;
    if (boyRate != null && boyRate < 40) {
      rateColor = AppConstants.errorColor;
    } else if (boyRate != null && boyRate < 75) {
      rateColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: rateColor.withValues(alpha: 0.15),
            child: Text(
              m.fullName.isNotEmpty ? m.fullName[0] : context.tr.messageM,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: rateColor,
                fontSize: 12,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      context.tr.messageVisits((m.visitCount).toString()),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    if (m.area.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppConstants.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m.area,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              boyRate == null
                  ? context.tr.insufficientAttendanceData
                  : context.tr.messageAttendance(
                      (AppFormatters(
                        Localizations.localeOf(context),
                      ).formatNumber(boyRate, decimalDigits: 0)).toString(),
                    ),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: rateColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (m.phone.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppConstants.successColor,
              ),
              onPressed: () => _makeCall(m.phone),
            ),
          IconButton(
            icon: const Icon(
              Icons.edit_calendar_rounded,
              size: 18,
              color: AppConstants.primaryLight,
            ),
            onPressed: () => _openRecordVisitSheet(m),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _behaviorFilter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: InkWell(
        onTap: () => setState(() => _behaviorFilter = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                : (isDark ? AppConstants.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark
                        ? AppConstants.cardBorderDark
                        : AppConstants.cardBorderLight),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? color
                  : (isDark ? Colors.white70 : AppConstants.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryLight.withValues(
                    alpha: isDark ? 0.25 : 0.15,
                  )
                : (isDark ? AppConstants.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryLight
                  : (isDark
                        ? AppConstants.cardBorderDark
                        : AppConstants.cardBorderLight),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? AppConstants.primaryLight
                  : (isDark ? Colors.white70 : AppConstants.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

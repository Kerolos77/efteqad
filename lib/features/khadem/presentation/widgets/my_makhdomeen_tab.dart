import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../../../admin/presentation/widgets/makhdom_card.dart';
import '../../../common/widgets/record_visit_sheet.dart';

class MyMakhdomeenTab extends StatefulWidget {
  final List<MakhdomModel> myMakhdomeen;
  final List<AttendanceSessionModel> sessions;
  final VoidCallback? onSwitchToAnalytics;

  const MyMakhdomeenTab({
    super.key,
    required this.myMakhdomeen,
    this.sessions = const [],
    this.onSwitchToAnalytics,
  });

  @override
  State<MyMakhdomeenTab> createState() => _MyMakhdomeenTabState();
}

class _MyMakhdomeenTabState extends State<MyMakhdomeenTab> {
  String _search = '';
  String _filter = 'all'; // 'all', 'visited', 'unvisited', 'brethren'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = widget.myMakhdomeen.length;
    final visitedCount = widget.myMakhdomeen
        .where((m) => m.visitCount > 0)
        .length;
    final percentage = totalCount > 0 ? (visitedCount / totalCount) : 0.0;

    final atRiskList = widget.sessions.isNotEmpty
        ? AttendanceAnalyticsService.getAtRiskStudents(
            makhdomeen: widget.myMakhdomeen,
            sessions: widget.sessions,
          )
        : <AtRiskStudentInfo>[];

    final filtered = widget.myMakhdomeen.where((m) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matches =
            m.fullName.toLowerCase().contains(q) ||
            m.area.toLowerCase().contains(q) ||
            m.phone.contains(q);
        if (!matches) return false;
      }
      switch (_filter) {
        case 'visited':
          return m.visitCount > 0;
        case 'unvisited':
          return m.visitCount == 0;
        case 'brethren':
          return m.isBrethrenOfLord;
        default:
          return true;
      }
    }).toList();

    return Column(
      children: [
        // Header summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppConstants.backgroundDark
                : AppConstants.backgroundLight,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr.messageOfVisited(
                      AppFormatters(
                        Localizations.localeOf(context),
                      ).formatNumber((visitedCount)),
                      AppFormatters(
                        Localizations.localeOf(context),
                      ).formatNumber((totalCount)),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppConstants.royalGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppConstants.royalGold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // At-risk warning banner
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
                      AppFormatters(
                        Localizations.localeOf(context),
                      ).formatNumber(atRiskList.length),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                if (widget.onSwitchToAnalytics != null)
                  TextButton(
                    onPressed: widget.onSwitchToAnalytics,
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

        // Search & Filter
        if (widget.myMakhdomeen.isNotEmpty) ...[
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
                  '${context.tr.filterUnvisited} (${AppFormatters(Localizations.localeOf(context)).formatNumber(totalCount - visitedCount)})',
                  'unvisited',
                  isDark,
                ),
                _buildFilterChip(
                  '${context.tr.filterVisited} (${AppFormatters(Localizations.localeOf(context)).formatNumber(visitedCount)})',
                  'visited',
                  isDark,
                ),
                _buildFilterChip(
                  '${context.tr.filterBrethren} (${AppFormatters(Localizations.localeOf(context)).formatNumber(widget.myMakhdomeen.where((m) => m.isBrethrenOfLord).length)})',
                  'brethren',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Student list
        Expanded(
          child: widget.myMakhdomeen.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                  child: Text(
                    context.tr.noSearchResults,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textMuted,
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
                      onLogVisit: () {
                        RecordVisitSheet.show(context, makhdom: m);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key, bool isDark) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsetsDirectional.only(start: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.royalGold
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.royalGold
                : (isDark
                      ? AppConstants.cardBorderDark
                      : AppConstants.cardBorderLight),
          ),
        ),
        child: Center(
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
      ),
    );
  }
}

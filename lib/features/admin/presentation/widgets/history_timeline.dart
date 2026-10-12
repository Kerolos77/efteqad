import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:efteqad/core/services/trusted_mutations.dart'
    show canonicalVisitType;
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/visit_model.dart';
import '../../models/history_analysis.dart';
import 'history_filters.dart';

class HistoryTimeline extends StatelessWidget {
  final HistoryAnalysis analysis;
  final Set<String>? visibleVisitIds;
  final Widget? moreVisits;
  final HistoryFilterType selectedFilter;
  final bool Function(DateTime) isDateInRange;
  final bool isDark;
  final ValueChanged<VisitModel> onEditVisitNotes;

  const HistoryTimeline({
    super.key,
    required this.analysis,
    this.visibleVisitIds,
    this.moreVisits,
    required this.selectedFilter,
    required this.isDateInRange,
    required this.isDark,
    required this.onEditVisitNotes,
  });

  Widget _buildVisitTimelineCard(
    BuildContext context,
    VisitWithImpact item,
    AppFormatters displayDateFormat,
  ) {
    final visit = item.visit;
    final dateStr = displayDateFormat.formatDate(
      visit.visitDate,
      format: 'EEEE d MMMM yyyy',
    );

    Color typeColor;
    IconData typeIcon;
    final typeLabel = visit.visitType.isNotEmpty
        ? DomainLabels(
            Localizations.localeOf(context),
          ).visitTypeName(visit.visitType)
        : context.tr.pastoralVisitGeneral;

    final typeCode = canonicalVisitType(visit.visitType);
    if (typeCode == 'home') {
      typeColor = const Color(0xFF059669);
      typeIcon = Icons.home_work_rounded;
    } else if (typeCode == 'phone') {
      typeColor = const Color(0xFF2563EB);
      typeIcon = Icons.phone_in_talk_rounded;
    } else if (typeCode == 'church') {
      typeColor = const Color(0xFF7C3AED);
      typeIcon = Icons.church_rounded;
    } else {
      typeColor = AppConstants.sacredGold;
      typeIcon = Icons.volunteer_activism_rounded;
    }

    Color outcomeColor = AppConstants.textMuted;
    String outcomeText = '';
    IconData outcomeIcon = Icons.help_outline_rounded;

    switch (item.outcome) {
      case VisitFridayOutcome.both:
        outcomeColor = AppConstants.successColor;
        outcomeText = context.tr.visitOutcomeBoth;
        outcomeIcon = Icons.stars_rounded;
        break;
      case VisitFridayOutcome.serviceOnly:
        outcomeColor = const Color(0xFF10B981);
        outcomeText = context.tr.visitOutcomeServiceOnly;
        outcomeIcon = Icons.check_circle_rounded;
        break;
      case VisitFridayOutcome.massOnly:
        outcomeColor = const Color(0xFF10B981);
        outcomeText = context.tr.visitOutcomeMassOnly;
        outcomeIcon = Icons.check_circle_rounded;
        break;
      case VisitFridayOutcome.missed:
        outcomeColor = AppConstants.errorColor;
        outcomeText = context.tr.visitOutcomeMissed;
        outcomeIcon = Icons.error_outline_rounded;
        break;
      case VisitFridayOutcome.pending:
        outcomeColor = AppConstants.sacredGold;
        outcomeText = context.tr.visitOutcomePending;
        outcomeIcon = Icons.hourglass_top_rounded;
        break;
      case VisitFridayOutcome.noData:
        outcomeColor = AppConstants.textMuted;
        outcomeText = context.tr.visitOutcomeNoData;
        outcomeIcon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: typeColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الكارت
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: typeColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : AppConstants.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الخادم القائم بالافتقاد
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppConstants.sacredGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        size: 16,
                        color: AppConstants.sacredGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.tr.visitingServantLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white60
                              : AppConstants.textMuted,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        visit.khademName.isNotEmpty
                            ? visit.khademName
                            : context.tr.assignedKhademPlaceholder,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppConstants.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // تقرير وملاحظات الافتقاد
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
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
                          Icon(
                            Icons.edit_note_rounded,
                            size: 17,
                            color: typeColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.tr.visitReportNotesHeader,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => onEditVisitNotes(visit),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: typeColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      (visit.notes != null &&
                                              visit.notes!.trim().isNotEmpty)
                                          ? context.tr.editNoteAction
                                          : context.tr.addNoteAction,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: typeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (visit.notes != null && visit.notes!.trim().isNotEmpty)
                        Text(
                          visit.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppConstants.textDark,
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppConstants.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.tr.visitNoDetailedNotes,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // أثر الافتقاد في الجمعة التالية
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: outcomeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: outcomeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(outcomeIcon, size: 16, color: outcomeColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.visitOutcomeHeader(
                                item.nextFridayFormatted,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : AppConstants.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outcomeText,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: outcomeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFridayTimelineCard(
    BuildContext context,
    FridayAttendanceRecord item,
    AppFormatters displayDateFormat,
  ) {
    final dateStr = displayDateFormat.formatDate(
      item.date,
      format: 'EEEE d MMMM yyyy',
    );
    final isFruitful = item.isAttendedAny && item.precedingVisit != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFruitful
              ? AppConstants.successColor.withValues(alpha: 0.4)
              : (isDark
                    ? AppConstants.cardBorderDark
                    : AppConstants.cardBorderLight),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isFruitful
                  ? AppConstants.successColor.withValues(
                      alpha: isDark ? 0.14 : 0.09,
                    )
                  : (item.isAttendedAny
                        ? AppConstants.primaryLight.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          )
                        : AppConstants.errorColor.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          )),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.church_rounded,
                  size: 16,
                  color: item.isAttendedAny
                      ? AppConstants.primaryLight
                      : AppConstants.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: item.isAttendedAny
                        ? AppConstants.successColor.withValues(alpha: 0.18)
                        : AppConstants.errorColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.isAttendedBoth
                        ? context.tr.attendedMassAndService
                        : (item.isAttendedAny
                              ? context.tr.attendedPartial
                              : context.tr.absentBoth),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: item.isAttendedAny
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.hasMassSession)
                      _buildSessionChip(
                        context,
                        label: context.tr.massLabel,
                        attended: item.attendedMass,
                      ),
                    if (item.hasMassSession && item.hasServiceSession)
                      const SizedBox(width: 8),
                    if (item.hasServiceSession)
                      _buildSessionChip(
                        context,
                        label: context.tr.serviceLabel,
                        attended: item.attendedService,
                      ),
                  ],
                ),
                if (item.precedingVisit != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.sacredGold.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.sacredGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volunteer_activism_rounded,
                          size: 14,
                          color: AppConstants.sacredGold,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr.precededByVisitNote(
                              AppFormatters(
                                Localizations.localeOf(context),
                              ).formatDate(
                                item.precedingVisit!.visitDate,
                                format: 'yyyy/MM/dd',
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionChip(
    BuildContext context, {
    required String label,
    required bool attended,
  }) {
    final color = attended
        ? AppConstants.successColor
        : AppConstants.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attended ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDateFormat = AppFormatters(Localizations.localeOf(context));

    // بناء قائمة العناصر المتطابقة مع الفلتر والنطاق الزمني
    final List<Widget> items = [];

    // إضافة الافتقادات إذا كان الفلتر يسمح
    if (selectedFilter == HistoryFilterType.all ||
        selectedFilter == HistoryFilterType.visitsOnly ||
        selectedFilter == HistoryFilterType.fruitfulOnly) {
      for (final vi in analysis.visitsWithImpact) {
        if (visibleVisitIds != null &&
            !visibleVisitIds!.contains(vi.visit.id)) {
          continue;
        }
        if (!isDateInRange(vi.visit.visitDate)) continue;
        if (selectedFilter == HistoryFilterType.fruitfulOnly &&
            vi.outcome != VisitFridayOutcome.both &&
            vi.outcome != VisitFridayOutcome.serviceOnly &&
            vi.outcome != VisitFridayOutcome.massOnly) {
          continue;
        }

        items.add(_buildVisitTimelineCard(context, vi, displayDateFormat));
      }
    }

    // إضافة جمعات الحضور إذا كان الفلتر يسمح
    if (selectedFilter == HistoryFilterType.all ||
        selectedFilter == HistoryFilterType.attendanceOnly ||
        selectedFilter == HistoryFilterType.absencesOnly ||
        selectedFilter == HistoryFilterType.fruitfulOnly) {
      for (final fr in analysis.fridayRecords) {
        if (!isDateInRange(fr.date)) continue;
        if (selectedFilter == HistoryFilterType.absencesOnly && !fr.isAbsent) {
          continue;
        }
        if (selectedFilter == HistoryFilterType.fruitfulOnly &&
            (!fr.isAttendedAny || fr.precedingVisit == null)) {
          continue;
        }

        items.add(_buildFridayTimelineCard(context, fr, displayDateFormat));
      }
    }

    if (moreVisits != null) items.add(moreVisits!);
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.noEventsMatchingFilter,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => items[index],
          childCount: items.length,
        ),
      ),
    );
  }
}

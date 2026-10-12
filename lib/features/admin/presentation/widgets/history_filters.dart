import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';

enum HistoryFilterType {
  all,
  visitsOnly,
  attendanceOnly,
  fruitfulOnly,
  absencesOnly,
}

enum HistoryDateRange { allTime, last30Days, last90Days, custom }

class HistoryFilters extends StatelessWidget {
  final HistoryFilterType selectedFilter;
  final ValueChanged<HistoryFilterType> onFilterChanged;
  final HistoryDateRange selectedDateRange;
  final ValueChanged<HistoryDateRange> onDateRangeChanged;
  final DateTimeRange? customDateRange;
  final VoidCallback onPickCustomDateRange;
  final Map<HistoryFilterType, int> counts;
  final bool isDark;

  const HistoryFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
    this.customDateRange,
    required this.onPickCustomDateRange,
    required this.counts,
    required this.isDark,
  });

  String _getFilterLabel(BuildContext context, HistoryFilterType type) {
    switch (type) {
      case HistoryFilterType.all:
        return context.tr.filterAllEvents;
      case HistoryFilterType.visitsOnly:
        return context.tr.filterVisitsOnly;
      case HistoryFilterType.attendanceOnly:
        return context.tr.filterAttendanceOnly;
      case HistoryFilterType.fruitfulOnly:
        return context.tr.filterFruitfulOnly;
      case HistoryFilterType.absencesOnly:
        return context.tr.filterAbsencesOnly;
    }
  }

  String _getDateRangeLabel(BuildContext context, HistoryDateRange range) {
    switch (range) {
      case HistoryDateRange.allTime:
        return context.tr.rangeAllTime;
      case HistoryDateRange.last30Days:
        return context.tr.rangeLast30Days;
      case HistoryDateRange.last90Days:
        return context.tr.rangeLast90Days;
      case HistoryDateRange.custom:
        return context.tr.rangeCustom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
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
        children: [
          // 1. فلاتر نوع الحدث (أزرار أفقية قابلة للتمرير)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: HistoryFilterType.values.map((type) {
                final isSelected = selectedFilter == type;
                final count = counts[type] ?? 0;
                final label = _getFilterLabel(context, type);

                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: FilterChip(
                    label: Text(
                      count > 0
                          ? '$label (${AppFormatters(Localizations.localeOf(context)).formatNumber(count)})'
                          : label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : AppConstants.textDark),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onFilterChanged(type),
                    selectedColor: AppConstants.sacredGold,
                    backgroundColor: isDark
                        ? Colors.white10
                        : const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? AppConstants.sacredGold
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 2. فلاتر النطاق الزمني
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: HistoryDateRange.values.map((range) {
                final isSelected = selectedDateRange == range;
                final label = _getDateRangeLabel(context, range);

                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white60
                                  : AppConstants.textMuted),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      if (range == HistoryDateRange.custom) {
                        onPickCustomDateRange();
                      } else {
                        onDateRangeChanged(range);
                      }
                    },
                    selectedColor: AppConstants.primaryLight,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? AppConstants.primaryLight
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

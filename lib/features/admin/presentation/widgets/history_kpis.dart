import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/history_analysis.dart';

class HistoryKpis extends StatelessWidget {
  final HistoryAnalysis analysis;
  final bool isDark;

  const HistoryKpis({super.key, required this.analysis, required this.isDark});

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = analysis.hasSufficientData;
    String rate(double? value) => value == null
        ? context.tr.insufficientDataShort
        : '${AppFormatters(Localizations.localeOf(context)).formatNumber(value, decimalDigits: 0)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // شبكة الـ KPIs الرئيسية
          GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 1
                  : 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(200),
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. نسبة الحضور الإجمالية
              _buildKpiCard(
                context: context,
                title: context.tr.overallAttendanceTitle,
                value: rate(analysis.overallAttendanceRate),
                subtitle: context.tr.attendanceRatio(
                  analysis.totalAttendedSessions,
                  analysis.totalEligibleSessions,
                ),
                icon: Icons.percent_rounded,
                color:
                    analysis.overallAttendanceRate != null &&
                        analysis.overallAttendanceRate! >= 75
                    ? AppConstants.successColor
                    : (analysis.overallAttendanceRate != null &&
                              analysis.overallAttendanceRate! >= 40
                          ? AppConstants.accentGold
                          : AppConstants.errorColor),
              ),

              // 2. إجمالي الافتقادات
              _buildKpiCard(
                context: context,
                title: context.tr.totalVisitsTitle,
                value: '${analysis.totalVisitsCount}',
                subtitle: analysis.daysSinceLastVisit != null
                    ? context.tr.daysSinceLastVisit(
                        analysis.daysSinceLastVisit!,
                      )
                    : context.tr.noVisitsYet,
                icon: Icons.volunteer_activism_rounded,
                color: AppConstants.sacredGold,
              ),

              // 3. الغياب المتتالي
              _buildKpiCard(
                context: context,
                title: context.tr.consecutiveAbsenceTitle,
                value: hasData
                    ? '${analysis.consecutiveAbsences}'
                    : context.tr.insufficientDataShort,
                subtitle: !hasData
                    ? context.tr.insufficientAttendanceData
                    : analysis.consecutiveAbsences == 0
                    ? context.tr.noConsecutiveAbsences
                    : (analysis.isCriticalRisk
                          ? context.tr.criticalAbsenceAlert
                          : context.tr.warningAbsenceAlert),
                icon: Icons.event_busy_rounded,
                color: analysis.consecutiveAbsences >= 2
                    ? AppConstants.errorColor
                    : AppConstants.successColor,
              ),

              // 4. حضور القداس مقابل الخدمة
              _buildKpiCard(
                context: context,
                title: context.tr.massAndServiceRatesTitle,
                value: rate(analysis.serviceAttendanceRate),
                subtitle: analysis.massAttendanceRate == null
                    ? context.tr.insufficientAttendanceData
                    : context.tr.massRateSubtitle(
                        AppFormatters(
                          Localizations.localeOf(context),
                        ).formatNumber(
                          analysis.massAttendanceRate!,
                          decimalDigits: 0,
                        ),
                      ),
                icon: Icons.church_rounded,
                color: AppConstants.primaryLight,
              ),
            ],
          ),

          // 5. بطاقة الارتباط الإحصائي للزيارة (دون ادعاء سببية)
          if (analysis.correlationDifference != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppConstants.surfaceDark
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppConstants.cardBorderDark
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.sacredGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: AppConstants.sacredGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.visitationCorrelationTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr.visitationCorrelationBody(
                            analysis.correlationDifference! >= 0
                                ? '+${AppFormatters(Localizations.localeOf(context)).formatNumber(analysis.correlationDifference!, decimalDigits: 0)}'
                                : AppFormatters(
                                    Localizations.localeOf(context),
                                  ).formatNumber(
                                    analysis.correlationDifference!,
                                    decimalDigits: 0,
                                  ),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white70
                                : AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!hasData) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr.insufficientHistoryDataHint,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

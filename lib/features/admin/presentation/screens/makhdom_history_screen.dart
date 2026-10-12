import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import '../../application/makhdom_history_service.dart';
import '../../../../core/widgets/query_content.dart';
import '../../../../core/widgets/paged_content.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../models/history_analysis.dart';
import '../widgets/history_filters.dart';
import '../widgets/history_header.dart';
import '../widgets/history_kpis.dart';
import '../widgets/history_timeline.dart';

class MakhdomHistoryScreen extends StatefulWidget {
  final MakhdomModel makhdom;
  final FirestoreService? firestoreService;
  final DateTime? asOf;

  const MakhdomHistoryScreen({
    super.key,
    required this.makhdom,
    this.firestoreService,
    this.asOf,
  });

  @override
  State<MakhdomHistoryScreen> createState() => _MakhdomHistoryScreenState();
}

class _MakhdomHistoryScreenState extends State<MakhdomHistoryScreen> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  final MakhdomHistoryService _historyService = const MakhdomHistoryService();

  HistoryFilterType _selectedFilter = HistoryFilterType.all;
  HistoryDateRange _selectedDateRange = HistoryDateRange.last90Days;
  DateTimeRange? _customDateRange;
  bool _isProfileExpanded = false;
  int _pageRevision = 0;

  /// فتح تطبيق الاتصال
  Future<void> _makeCall(String phone) async {
    if (phone.trim().isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// فتح محادثة واتساب
  Future<void> _openWhatsApp(String phone) async {
    if (phone.trim().isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    String intlPhone = cleanPhone;
    if (cleanPhone.startsWith('0')) {
      intlPhone = '+2$cleanPhone';
    }
    final uri = Uri.parse('https://wa.me/$intlPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// فتح رابط خرائط جوجل
  Future<void> _openLocation(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    final uri = Uri.parse(urlString.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// نسخ نص إلى الحافظة
  void _copyToClipboard(String text, String label) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${context.tr.copyPhoneSuccess} ($label: $text)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        backgroundColor: AppConstants.primaryLight,
      ),
    );
  }

  /// اختيار فترة مخصصة
  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: calendarDay(now, -29), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.sacredGold,
              onPrimary: Colors.black,
              surface: Theme.of(context).brightness == Brightness.dark
                  ? AppConstants.surfaceDark
                  : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateRange = HistoryDateRange.custom;
      });
    }
  }

  late final DateTime _asOf = widget.asOf ?? DateTime.now();
  DateTime? get _from {
    switch (_selectedDateRange) {
      case HistoryDateRange.allTime:
        return null;
      case HistoryDateRange.last30Days:
        return calendarDay(_asOf, -29);
      case HistoryDateRange.last90Days:
        return calendarDay(_asOf, -89);
      case HistoryDateRange.custom:
        return _customDateRange == null
            ? null
            : calendarDay(_customDateRange!.start);
    }
  }

  DateTime get _to => _selectedDateRange == HistoryDateRange.custom
      ? _customDateRange?.end ?? _asOf
      : _asOf;
  bool _isDateInRange(DateTime date) =>
      (_from == null || !date.isBefore(_from!)) &&
      date.isBefore(calendarDay(_to, 1));

  /// حوار تعديل أو إضافة ملاحظات ديسكريبشن الافتقاد
  Future<void> _showEditVisitNotesDialog(VisitModel visit) async {
    final controller = TextEditingController(text: visit.notes ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.sacredGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppConstants.sacredGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.editVisitNotesTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.editVisitNotesSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : AppConstants.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.tr.editVisitNotesHint,
                      hintStyle: const TextStyle(fontSize: 12.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.black26
                          : const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(context.tr.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.sacredGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final tr = context.tr;
                          setDialogState(() => isSaving = true);
                          try {
                            final newNotes = controller.text.trim();
                            await _firestoreService.updateVisitNotes(
                              visitId: visit.id,
                              notes: newNotes,
                              makhdomId: widget.makhdom.id,
                            );
                            if (mounted && dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(tr.visitNotesUpdatedSuccess),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppConstants.successColor,
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
                                    ).localizedMessage(tr),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppConstants.errorColor,
                                ),
                              );
                            }
                          } finally {
                            if (dialogCtx.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          context.tr.save,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<HistoryFilterType, int> _calculateCounts(HistoryAnalysis analysis) {
    int visitsCount = 0;
    int attendanceCount = 0;
    int fruitfulCount = 0;
    int absencesCount = 0;

    for (final vi in analysis.visitsWithImpact) {
      if (_isDateInRange(vi.visit.visitDate)) {
        visitsCount++;
        if (vi.outcome == VisitFridayOutcome.both ||
            vi.outcome == VisitFridayOutcome.serviceOnly ||
            vi.outcome == VisitFridayOutcome.massOnly) {
          fruitfulCount++;
        }
      }
    }

    for (final fr in analysis.fridayRecords) {
      if (_isDateInRange(fr.date)) {
        attendanceCount++;
        if (fr.isAbsent) {
          absencesCount++;
        }
      }
    }

    return {
      HistoryFilterType.all: visitsCount + attendanceCount,
      HistoryFilterType.visitsOnly: visitsCount,
      HistoryFilterType.attendanceOnly: attendanceCount,
      HistoryFilterType.fruitfulOnly: fruitfulCount,
      HistoryFilterType.absencesOnly: absencesCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppConstants.backgroundDark
          : AppConstants.backgroundLight,
      appBar: AppBar(
        title: Text(
          context.tr.historyAction,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, size: 22),
            tooltip: context.tr.filterCustomDate,
            onPressed: _pickCustomDateRange,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.sacredGold,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, size: 20),
        label: Text(
          context.tr.logNewVisitButton,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        onPressed: () async {
          await RecordVisitSheet.show(context, makhdom: widget.makhdom);
          if (mounted) setState(() => _pageRevision++);
        },
      ),
      body: Builder(
        builder: (context) {
          final liveMakhdom = widget.makhdom;

          final queryKey =
              '${liveMakhdom.id}/${liveMakhdom.grade}/$_from/$_to/$_pageRevision';
          return QueryContent<List<VisitModel>>(
            queryKey: queryKey,
            query: () => _firestoreService.getVisitsForMakhdomStream(
              liveMakhdom.id,
              from: _from,
              to: _to,
            ),
            builder: (context, allVisits) =>
                QueryContent<List<AttendanceSessionModel>>(
                  queryKey: queryKey,
                  query: () =>
                      _firestoreService.getAttendanceSessionsForGradeStream(
                        liveMakhdom.grade,
                        from: _from,
                        to: _to,
                      ),
                  builder: (context, allSessions) {
                    final analysis = _historyService.analyzeHistory(
                      makhdom: liveMakhdom,
                      visits: allVisits,
                      sessions: allSessions,
                      asOf: _to.isBefore(_asOf) ? _to : _asOf,
                      from: _from,
                    );

                    final counts = _calculateCounts(analysis);

                    return PagedContent<VisitModel>(
                      queryKey: queryKey,
                      showEmptyAsContent: true,
                      fetch: (cursor) => _firestoreService.fetchVisitPage(
                        makhdomId: liveMakhdom.id,
                        cursor: cursor,
                        from: _from,
                        to: _to,
                      ),
                      builder: (context, pageVisits, moreVisits) =>
                          CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _from == null
                                        ? context.tr.filterAllTime
                                        : context.tr.analyticsDateBounds(
                                            AppFormatters(
                                              Localizations.localeOf(context),
                                            ).formatDate(_from!),
                                            AppFormatters(
                                              Localizations.localeOf(context),
                                            ).formatDate(_to),
                                          ),
                                  ),
                                ),
                              ),
                              // 1. بطاقة الهوية والتواصل والبيانات الشاملة
                              SliverToBoxAdapter(
                                child: HistoryHeader(
                                  makhdom: liveMakhdom,
                                  latestVisitNotes: analysis.lastVisit?.notes,
                                  isDark: isDark,
                                  isExpanded: _isProfileExpanded,
                                  onToggleExpanded: () {
                                    setState(
                                      () => _isProfileExpanded =
                                          !_isProfileExpanded,
                                    );
                                  },
                                  onCall: _makeCall,
                                  onWhatsApp: _openWhatsApp,
                                  onOpenLocation: _openLocation,
                                  onCopy: _copyToClipboard,
                                ),
                              ),

                              // 2. مؤشرات الأداء والارتباط (KPIs)
                              SliverToBoxAdapter(
                                child: HistoryKpis(
                                  analysis: analysis,
                                  isDark: isDark,
                                ),
                              ),

                              // 3. شريط الفلاتر والنطاق الزمني
                              SliverToBoxAdapter(
                                child: HistoryFilters(
                                  selectedFilter: _selectedFilter,
                                  onFilterChanged: (f) =>
                                      setState(() => _selectedFilter = f),
                                  selectedDateRange: _selectedDateRange,
                                  onDateRangeChanged: (r) =>
                                      setState(() => _selectedDateRange = r),
                                  customDateRange: _customDateRange,
                                  onPickCustomDateRange: _pickCustomDateRange,
                                  counts: counts,
                                  isDark: isDark,
                                ),
                              ),

                              // 4. التايملاين الزمني للأحداث
                              HistoryTimeline(
                                analysis: analysis,
                                visibleVisitIds: pageVisits
                                    .map((v) => v.id)
                                    .toSet(),
                                moreVisits: moreVisits,
                                selectedFilter: _selectedFilter,
                                isDateInRange: _isDateInRange,
                                isDark: isDark,
                                onEditVisitNotes: _showEditVisitNotesDialog,
                              ),

                              // مسافة سفلية للزر العائم
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 80),
                              ),
                            ],
                          ),
                    );
                  },
                ),
          );
        },
      ),
    );
  }
}

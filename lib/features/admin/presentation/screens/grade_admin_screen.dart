import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../common/widgets/notifications_sheet.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import '../../../tasks/presentation/widgets/tasks_tab.dart';
import '../widgets/add_edit_makhdom_dialog.dart';
import '../widgets/assign_makhdomeen_modal.dart';
import '../widgets/excel_actions_sheet.dart';
import '../widgets/makhdom_card.dart';
import 'analytics_tab.dart';
import 'khodam_tab.dart';

class GradeAdminScreen extends StatefulWidget {
  final String grade; // '1st', '2nd', '3rd'

  const GradeAdminScreen({super.key, required this.grade});

  @override
  State<GradeAdminScreen> createState() => _GradeAdminScreenState();
}

class _GradeAdminScreenState extends State<GradeAdminScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  late final Stream<List<MakhdomModel>> _makhdomeenStream;
  late final Stream<List<KhademModel>> _khodamStream;
  late final Stream<List<TaskModel>> _tasksStream;

  int _selectedTabIndex = 0;
  String?
  _selectedKhademFilterId; // null = الكل, 'unassigned' = بدون خادم, 'brethren' = أخوة رب
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _makhdomeenStream = _firestoreService.getMakhdomeenByGradeStream(
      widget.grade,
    );
    _khodamStream = _firestoreService.getKhodamByGradeStream(widget.grade);
    _tasksStream = _firestoreService.getTasksForGradeStream(widget.grade);
  }

  String _getGradeLabel(BuildContext context) {
    switch (widget.grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return widget.grade;
    }
  }

  void _openAddMakhdomDialog(
    List<KhademModel> khodamList, [
    MakhdomModel? makhdom,
  ]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditMakhdomDialog(
        khodamList: khodamList,
        initialMakhdom:
            makhdom ??
            MakhdomModel(
              id: '',
              fullName: '',
              phone: '',
              grade: widget.grade,
              createdAt: DateTime.now(),
            ),
      ),
    );
  }

  void _openExcelActionsSheet(List<MakhdomModel> currentList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExcelActionsSheet(
        currentMakhdomeen: currentList,
        grade: widget.grade,
      ),
    );
  }

  void _openAssignModalForSelectedKhadem(
    KhademModel khadem,
    List<MakhdomModel> allMakhdomeen,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignMakhdomeenModal(
        targetKhadem: khadem,
        allMakhdomeen: allMakhdomeen,
      ),
    );
  }

  Future<void> _handleDeleteMakhdom(MakhdomModel m) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(ctx.tr.deleteMakhdomTitle),
        content: Text(ctx.tr.deleteMakhdomPrompt(m.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteMakhdom(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.makhdomDeletedSuccess)),
        );
      }
    }
  }

  Future<void> _handleUnassignMakhdom(MakhdomModel m) async {
    try {
      await _firestoreService.unassignMakhdom(
        m.id,
        expectedKhademId: m.assignedKhademId,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(error).localizedMessage(context.tr),
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.makhdomUnassignedSuccess(m.fullName)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeLabel = _getGradeLabel(context);

    return StreamBuilder<List<MakhdomModel>>(
      stream: _makhdomeenStream,
      builder: (context, makhdomeenSnap) {
        return StreamBuilder<List<KhademModel>>(
          stream: _khodamStream,
          builder: (context, khodamSnap) {
            final allMakhdomeen = makhdomeenSnap.data ?? [];
            final khodamList = khodamSnap.data ?? [];

            // فلترة القائمة المعروضة
            List<MakhdomModel> filteredList = allMakhdomeen.where((m) {
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                final matchesName = m.fullName.toLowerCase().contains(q);
                final matchesArea = m.area.toLowerCase().contains(q);
                final matchesPhone = m.phone.contains(q);
                final matchesSchool = m.school.toLowerCase().contains(q);
                if (!matchesName &&
                    !matchesArea &&
                    !matchesPhone &&
                    !matchesSchool) {
                  return false;
                }
              }

              if (_selectedKhademFilterId == 'unassigned') {
                return !m.isAssigned;
              } else if (_selectedKhademFilterId == 'brethren') {
                return m.isBrethrenOfLord;
              } else if (_selectedKhademFilterId != null) {
                return m.assignedKhademId == _selectedKhademFilterId;
              }

              return true;
            }).toList();

            KhademModel? currentSelectedKhadem;
            if (_selectedKhademFilterId != null &&
                _selectedKhademFilterId != 'unassigned' &&
                _selectedKhademFilterId != 'brethren') {
              try {
                currentSelectedKhadem = khodamList.firstWhere(
                  (k) => k.id == _selectedKhademFilterId,
                );
              } catch (_) {}
            }

            return Scaffold(
              drawer: AppDrawer(
                isAdmin: true,
                onOpenExcel: () => _openExcelActionsSheet(allMakhdomeen),
              ),
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
                      context.tr.gradeDashboardTitle(gradeLabel),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.tr.makhdomeenAndKhodamSummary(
                        allMakhdomeen.length,
                        khodamList.length,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                actions: const [NotificationBellButton()],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedTabIndex,
                onDestinationSelected: (idx) =>
                    setState(() => _selectedTabIndex = idx),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.groups_outlined),
                    selectedIcon: const Icon(Icons.groups),
                    label: context.tr.tabMakhdomeen(allMakhdomeen.length),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.insights_outlined),
                    selectedIcon: const Icon(Icons.insights),
                    label: context.tr.tabAnalytics,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.badge_outlined),
                    selectedIcon: const Icon(Icons.badge),
                    label: context.tr.tabKhodam(khodamList.length),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.task_alt_outlined),
                    selectedIcon: const Icon(Icons.task_alt),
                    label: context.tr.tabGradeTasks,
                  ),
                ],
              ),
              body:
                  makhdomeenSnap.connectionState == ConnectionState.waiting &&
                      allMakhdomeen.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        // Tab 0: قائمة المخدومين والفلترة والإسناد
                        _buildMakhdomeenTab(
                          allMakhdomeen: allMakhdomeen,
                          filteredList: filteredList,
                          khodamList: khodamList,
                          currentSelectedKhadem: currentSelectedKhadem,
                        ),

                        // Tab 1: لوحة التحليلات
                        AnalyticsTab(
                          makhdomeen: allMakhdomeen,
                          khodam: khodamList,
                          grade: widget.grade,
                        ),

                        // Tab 2: قائمة الخدام
                        KhodamTab(
                          khodam: khodamList,
                          allMakhdomeen: allMakhdomeen,
                        ),

                        // Tab 3: مهام السنة الدراسية
                        TasksTab(
                          tasksStream: _tasksStream,
                          availableKhodam: khodamList,
                          grade: widget.grade,
                          canCreateTasks: true,
                        ),
                      ],
                    ),
              floatingActionButton: _selectedTabIndex == 0
                  ? FloatingActionButton.extended(
                      onPressed: () => _openAddMakhdomDialog(khodamList),
                      backgroundColor: AppConstants.primaryLight,
                      icon: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        context.tr.addMakhdomBtn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildMakhdomeenTab({
    required List<MakhdomModel> allMakhdomeen,
    required List<MakhdomModel> filteredList,
    required List<KhademModel> khodamList,
    required KhademModel? currentSelectedKhadem,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = _authService.currentUser;
    final myAssignedCount = currentUser == null
        ? 0
        : allMakhdomeen
              .where((m) => m.assignedKhademId == currentUser.uid)
              .length;

    return Column(
      children: [
        // شريط البحث وفلاتر الخدام
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppConstants.backgroundDark
                : AppConstants.backgroundLight,
          ),
          child: Column(
            children: [
              // مربع البحث
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: context.tr.searchAdminHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // فلتر الخدام الأنيق (Horizontal Scrollable Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildKhademFilterChip(
                      id: null,
                      name: context.tr.all,
                      count: allMakhdomeen.length,
                      color: AppConstants.primaryLight,
                    ),
                    if (currentUser != null && myAssignedCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildKhademFilterChip(
                        id: currentUser.uid,
                        name: '⭐ ${context.tr.filterMyMakhdomeen}',
                        count: myAssignedCount,
                        color: AppConstants.accentIndigo,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _buildKhademFilterChip(
                      id: 'unassigned',
                      name: context.tr.filterUnassigned,
                      count: allMakhdomeen.where((m) => !m.isAssigned).length,
                      color: AppConstants.errorColor,
                    ),
                    const SizedBox(width: 8),
                    _buildKhademFilterChip(
                      id: 'brethren',
                      name: context.tr.filterBrethren,
                      count: allMakhdomeen
                          .where((m) => m.isBrethrenOfLord)
                          .length,
                      color: AppConstants.accentGold,
                    ),
                    const SizedBox(width: 8),
                    ...khodamList
                        .where(
                          (k) =>
                              k.id != currentUser?.uid || myAssignedCount == 0,
                        )
                        .map((khadem) {
                          final count = allMakhdomeen
                              .where((m) => m.assignedKhademId == khadem.id)
                              .length;
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: _buildKhademFilterChip(
                              id: khadem.id,
                              name: khadem.name,
                              count: count,
                              color: ColorGenerator.getColorForId(khadem.id),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // بانر مخصص عند اختيار خادم معين
        if (currentSelectedKhadem != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: ColorGenerator.getColorForId(
                currentSelectedKhadem.id,
              ).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_ind_rounded,
                  size: 18,
                  color: ColorGenerator.getColorForId(currentSelectedKhadem.id),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.servantGroupHeader(currentSelectedKhadem.name),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: ColorGenerator.getColorForId(
                        currentSelectedKhadem.id,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openAssignModalForSelectedKhadem(
                    currentSelectedKhadem,
                    allMakhdomeen,
                  ),
                  child: Text(context.tr.assignChildrenBtn),
                ),
              ],
            ),
          ),

        // قائمة المخدومين
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 50,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr.noSearchResults,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 85),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final makhdom = filteredList[index];
                    return MakhdomCard(
                      makhdom: makhdom,
                      onEdit: () => _openAddMakhdomDialog(khodamList, makhdom),
                      onDelete: () => _handleDeleteMakhdom(makhdom),
                      onUnassign: () => _handleUnassignMakhdom(makhdom),
                      onLogVisit: () {
                        final currentKhadem = khodamList
                            .cast<KhademModel?>()
                            .firstWhere(
                              (k) => k?.id == currentUser?.uid,
                              orElse: () => null,
                            );
                        RecordVisitSheet.show(
                          context,
                          makhdom: makhdom,
                          khademName: currentKhadem?.name,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKhademFilterChip({
    required String? id,
    required String name,
    required int count,
    required Color color,
  }) {
    final isSelected = _selectedKhademFilterId == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedKhademFilterId = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
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
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppConstants.textDark),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(count),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

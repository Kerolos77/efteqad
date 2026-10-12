import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/router/router_services.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/color_generator.dart';
import '../../../common/widgets/record_visit_sheet.dart';
import 'add_edit_makhdom_dialog.dart';
import 'assign_makhdomeen_modal.dart';
import 'makhdom_card.dart';

class GradeMakhdomeenTab extends StatefulWidget {
  final String grade;
  final List<MakhdomModel> allMakhdomeen;
  final List<KhademModel> khodamList;
  final VoidCallback? onRefresh;

  const GradeMakhdomeenTab({
    super.key,
    required this.grade,
    required this.allMakhdomeen,
    required this.khodamList,
    this.onRefresh,
  });

  @override
  State<GradeMakhdomeenTab> createState() => _GradeMakhdomeenTabState();
}

class _GradeMakhdomeenTabState extends State<GradeMakhdomeenTab> {
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedKhademFilterId;
  String _searchQuery = '';

  void _openAddMakhdomDialog([MakhdomModel? makhdom]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditMakhdomDialog(
        khodamList: widget.khodamList,
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

  void _handleDeleteMakhdom(MakhdomModel makhdom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr.deleteMakhdomTitle),
        content: Text(ctx.tr.deleteMakhdomPrompt(makhdom.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteMakhdom(makhdom.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: Text(ctx.tr.delete),
          ),
        ],
      ),
    );
  }

  void _handleUnassignMakhdom(MakhdomModel makhdom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr.messageUnassignStudent),
        content: Text(
          ctx.tr.messageAreYouSureYouWantToUnassign(
            (makhdom.fullName).toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.unassignMakhdom(
                  makhdom.id,
                  expectedKhademId: makhdom.assignedKhademId,
                );
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppFailure.fromException(
                          error,
                        ).localizedMessage(context.tr),
                      ),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: Text(ctx.tr.messageUnassign),
          ),
        ],
      ),
    );
  }

  void _openAssignModalForSelectedKhadem(KhademModel khadem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssignMakhdomeenModal(
        targetKhadem: khadem,
        allMakhdomeen: widget.allMakhdomeen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser =
        RouterServices.maybeOf(context)?.session.state.profile ??
        context.read<SessionCubit>().state.profile;
    final myAssignedCount = currentUser == null
        ? 0
        : widget.allMakhdomeen
              .where((m) => m.assignedKhademId == currentUser.id)
              .length;

    final filteredList = widget.allMakhdomeen.where((m) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = m.fullName.toLowerCase().contains(q);
        final matchesArea = m.area.toLowerCase().contains(q);
        final matchesPhone = m.phone.contains(q);
        final matchesSchool = m.school.toLowerCase().contains(q);
        if (!matchesName && !matchesArea && !matchesPhone && !matchesSchool) {
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
        currentSelectedKhadem = widget.khodamList.firstWhere(
          (k) => k.id == _selectedKhademFilterId,
        );
      } catch (_) {}
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppConstants.backgroundDark
                : AppConstants.backgroundLight,
          ),
          child: Column(
            children: [
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildKhademFilterChip(
                      id: null,
                      name: context.tr.all,
                      count: widget.allMakhdomeen.length,
                      color: AppConstants.primaryLight,
                    ),
                    if (currentUser != null && myAssignedCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildKhademFilterChip(
                        id: currentUser.id,
                        name: '⭐ ${context.tr.filterMyMakhdomeen}',
                        count: myAssignedCount,
                        color: AppConstants.accentIndigo,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _buildKhademFilterChip(
                      id: 'unassigned',
                      name: context.tr.filterUnassigned,
                      count: widget.allMakhdomeen
                          .where((m) => !m.isAssigned)
                          .length,
                      color: AppConstants.errorColor,
                    ),
                    const SizedBox(width: 8),
                    _buildKhademFilterChip(
                      id: 'brethren',
                      name: context.tr.filterBrethren,
                      count: widget.allMakhdomeen
                          .where((m) => m.isBrethrenOfLord)
                          .length,
                      color: AppConstants.accentGold,
                    ),
                    const SizedBox(width: 8),
                    ...widget.khodamList
                        .where(
                          (k) =>
                              k.id != currentUser?.id || myAssignedCount == 0,
                        )
                        .map((khadem) {
                          final count = widget.allMakhdomeen
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
                  onPressed: () =>
                      _openAssignModalForSelectedKhadem(currentSelectedKhadem!),
                  child: Text(context.tr.assignChildrenBtn),
                ),
              ],
            ),
          ),
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
                      onEdit: () => _openAddMakhdomDialog(makhdom),
                      onDelete: () => _handleDeleteMakhdom(makhdom),
                      onUnassign: () => _handleUnassignMakhdom(makhdom),
                      onLogVisit: () {
                        RecordVisitSheet.show(context, makhdom: makhdom);
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

    return GestureDetector(
      onTap: () =>
          setState(() => _selectedKhademFilterId = isSelected ? null : id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppConstants.textDark),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppFormatters(
                  Localizations.localeOf(context),
                ).formatNumber(count),
                style: TextStyle(
                  fontSize: 10.5,
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

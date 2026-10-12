import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/query_content.dart';
import 'add_task_dialog.dart';

class TasksTab extends StatefulWidget {
  final Stream<List<TaskModel>> tasksStream;
  final Stream<List<TaskModel>> Function()? tasksQuery;
  final List<KhademModel> availableKhodam;
  final String grade; // '1st', '2nd', '3rd', or 'all'
  final bool canCreateTasks;

  const TasksTab({
    super.key,
    required this.tasksStream,
    this.tasksQuery,
    required this.availableKhodam,
    required this.grade,
    this.canCreateTasks = true,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filter = 'all'; // 'all', 'pending', 'completed'

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        availableKhodam: widget.availableKhodam,
        grade: widget.grade,
      ),
    );
  }

  Future<void> _handleDeleteTask(TaskModel task) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(ctx.tr.deleteMakhdomTitle),
        content: Text(ctx.tr.deleteTaskPrompt),
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
      await _firestoreService.deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return QueryContent<List<TaskModel>>(
      queryKey: 'tasks/${widget.grade}',
      query: widget.tasksQuery ?? () => widget.tasksStream,
      builder: (context, allTasks) {
        final filteredTasks = allTasks.where((t) {
          if (_filter == 'pending') return !t.isCompleted;
          if (_filter == 'completed') return t.isCompleted;
          return true;
        }).toList();

        final completedCount = allTasks.where((t) => t.isCompleted).length;
        final pendingCount = allTasks.length - completedCount;

        return Column(
          children: [
            // شريط الفلاتر والإحصائيات وزر الإضافة
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
              color: isDark ? AppConstants.surfaceDark : Colors.white,
              child: Row(
                children: [
                  // شارات التصفية
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'all',
                            '${context.tr.all} (${AppFormatters(Localizations.localeOf(context)).formatNumber(allTasks.length)})',
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'pending',
                            '${context.tr.pendingTasksSection} (${AppFormatters(Localizations.localeOf(context)).formatNumber(pendingCount)})',
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'completed',
                            '${context.tr.completedTasksSection} (${AppFormatters(Localizations.localeOf(context)).formatNumber(completedCount)})',
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // زر إضافة مهمة جديدة
                  if (widget.canCreateTasks &&
                      widget.availableKhodam.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _openAddTaskDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        context.tr.addTaskTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // قائمة المهام
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 48,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr.noTasksYet,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        16,
                        85,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return _buildTaskCard(task, isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _filter == filterKey;
    return InkWell(
      onTap: () => setState(() => _filter = filterKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryLight
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppConstants.textDark),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool isDark) {
    Color typeColor;
    IconData typeIcon;
    switch (task.type) {
      case 'attendance_qoddas':
        typeColor = AppConstants.accentGold;
        typeIcon = Icons.church_rounded;
        break;
      case 'attendance':
      case 'attendance_khedma':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.fact_check_outlined;
        break;
      case 'visitation':
        typeColor = AppConstants.accentGold;
        typeIcon = Icons.home_work_outlined;
        break;
      case 'general':
      default:
        typeColor = AppConstants.primaryLight;
        typeIcon = Icons.task_alt_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isCompleted
              ? AppConstants.successColor.withValues(alpha: 0.3)
              : (isDark
                    ? AppConstants.cardBorderDark
                    : AppConstants.cardBorderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شيك بوكس إنجاز المهمة
          Checkbox(
            value: task.isCompleted,
            activeColor: AppConstants.successColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (val) {
              if (val != null) {
                _firestoreService.toggleTaskStatus(task.id, val);
              }
            },
          ),
          const SizedBox(width: 8),

          // تفاصيل المهمة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // كبسولة نوع المهمة
                    Container(
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
                          Icon(typeIcon, size: 12, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            DomainLabels(
                              Localizations.localeOf(context),
                            ).taskTypeName(task.type),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // شارة الخادم المكلف
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: AppConstants.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                task.assignedKhademName,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // عنوان المهمة
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? AppConstants.textMuted
                        : (isDark ? Colors.white : AppConstants.textDark),
                  ),
                ),

                // تفاصيل المهمة إن وجدت
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppConstants.textMutedDark
                          : AppConstants.textMuted,
                    ),
                  ),
                ],

                // زر الانتقال المباشر لشاشة رصد الحضور
                if (task.isAttendanceTask) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.taskAttendance(task.id));
                    },
                    icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                    label: Text(
                      context.tr.takeAttendanceAction,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isMassAttendance
                          ? AppConstants.accentGold
                          : const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // زر حذف المهمة للأدمن
          if (widget.canCreateTasks)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppConstants.errorColor,
              ),
              onPressed: () => _handleDeleteTask(task),
            ),
        ],
      ),
    );
  }
}

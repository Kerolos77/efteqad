import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_formatters.dart';
import '../../../../core/localization/domain_labels.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/firestore_service.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  final TaskModel? task;

  const TaskDetailsScreen({super.key, required this.taskId, this.task});

  @override
  Widget build(BuildContext context) =>
      _TaskDetailsView(key: ValueKey(task!.id), task: task!);
}

class _TaskDetailsView extends StatefulWidget {
  final TaskModel task;

  const _TaskDetailsView({super.key, required this.task});

  @override
  State<_TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<_TaskDetailsView> {
  late bool _isCompleted;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void didUpdateWidget(covariant _TaskDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      _isCompleted = widget.task.isCompleted;
    }
  }

  Future<void> _toggleCompleted() async {
    setState(() => _isLoading = true);
    final newStatus = !_isCompleted;
    try {
      await FirestoreService().toggleTaskStatus(widget.task.id, newStatus);
      if (mounted) {
        setState(() {
          _isCompleted = newStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final domainLabels = DomainLabels(locale);
    final formatters = AppFormatters(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.messageTaskDetails),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConstants.sacredGold.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.task.isAttendanceTask
                                ? Icons.fact_check_rounded
                                : Icons.task_alt_rounded,
                            color: AppConstants.sacredGold,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.royalGold.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  domainLabels.taskTypeName(widget.task.type),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.royalGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.task.description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        context.tr.messageDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.task.description,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: context.tr.messageAssignedServant661,
                      value: widget.task.assignedKhademName,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.school_outlined,
                      label: context.tr.messageGrade,
                      value: domainLabels.gradeName(widget.task.grade),
                    ),
                    if (widget.task.dueDate != null) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: context.tr.messageDueDate,
                        value: formatters.formatDate(widget.task.dueDate!),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.create_rounded,
                      label: context.tr.messageCreatedBy,
                      value: widget.task.createdByName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.task.isAttendanceTask) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppConstants.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  context.go(AppRoutes.taskAttendance(widget.task.id));
                },
                icon: const Icon(Icons.assignment_turned_in_rounded),
                label: Text(
                  context.tr.messageOpenAttendanceSheet,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: _isCompleted ? Colors.green : Colors.grey,
                ),
              ),
              onPressed: _isLoading || widget.task.isAttendanceTask
                  ? null
                  : _toggleCompleted,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _isCompleted ? Colors.green : null,
                    ),
              label: Text(
                _isCompleted
                    ? (context.tr.messageCompleted)
                    : (context.tr.messageMarkAsCompleted),
                style: TextStyle(
                  color: _isCompleted ? Colors.green : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

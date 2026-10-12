import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';

class AddTaskDialog extends StatefulWidget {
  final List<KhademModel> availableKhodam;
  final String grade; // '1st', '2nd', '3rd', or 'all'

  final FirestoreService? firestoreService;
  final AuthService? authService;
  const AddTaskDialog({
    super.key,
    this.firestoreService,
    this.authService,
    required this.availableKhodam,
    required this.grade,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late final FirestoreService _firestoreService;
  AuthService get _authService => widget.authService ?? AuthService();

  String? _selectedKhademId;
  String _taskType = 'general';
  DateTime? _dueDate;
  bool _isSaving = false;
  final String _operationId = newOperationId('task');
  TaskModel? _submittedTask;

  DateTime _getNextFriday() {
    final now = DateTime.now();
    int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    if (daysUntilFriday == 0 && now.hour >= 18) {
      daysUntilFriday = 7;
    }
    return DateTime(now.year, now.month, now.day + daysUntilFriday);
  }

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    if (widget.availableKhodam.isNotEmpty) {
      _selectedKhademId = widget.availableKhodam.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving ||
        (_submittedTask == null && !_formKey.currentState!.validate())) {
      return;
    }
    if (_selectedKhademId == null) return;

    final selectedKhadem = _submittedTask == null
        ? widget.availableKhodam.firstWhere((k) => k.id == _selectedKhademId)
        : null;
    final currentUser = _authService.currentUser;
    final successText = context.tr.taskCreatedSuccess;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final task = _submittedTask ??= TaskModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        assignedKhademId: selectedKhadem!.id,
        assignedKhademName: selectedKhadem.name,
        grade: widget.grade,
        createdById: currentUser?.uid ?? 'admin',
        createdByName: currentUser?.displayName ?? (context.tr.messageAdmin),
        type: _taskType,
        dueDate: _dueDate,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      String notifBody;
      if (task.type == AppConstants.taskTypeAttendanceKhedma) {
        notifBody = context.tr.messageYouAreAssignedToTakeServiceAttendance;
      } else if (task.type == AppConstants.taskTypeAttendanceQoddas) {
        notifBody = context.tr.messageYouAreAssignedToTakeMassAttendance;
      } else if (task.description.isNotEmpty) {
        notifBody = task.description;
      } else {
        notifBody = context.tr.messageAssignedYouANewTask(
          (task.createdByName).toString(),
        );
      }

      final notifTitle = context.tr.messageNewTask((task.title).toString());

      await _firestoreService.createTaskWithOutbox(
        task: task,
        outboxTitle: notifTitle,
        outboxBody: notifBody,
        operationId: _operationId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successText),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppConstants.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_submittedTask != null)
                    Text(
                      context
                          .tr
                          .messageSubmissionIsLockedUntilConfirmationRetryTo,
                    ),
                  // الهيدر
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryLight.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.assignment_add,
                          color: AppConstants.primaryLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.tr.addTaskTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // عنوان المهمة
                  TextFormField(
                    enabled: _submittedTask == null,
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.tr.taskTitleLabel,
                      prefixIcon: const Icon(Icons.title_rounded, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return context.tr.taskTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // نوع المهمة
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    itemHeight: null,
                    initialValue: _taskType,
                    decoration: InputDecoration(
                      labelText: context.tr.taskTypeLabel,
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text(context.tr.taskTypeGeneral),
                      ),
                      if (widget.grade == AppConstants.gradeAll)
                        DropdownMenuItem(
                          value: AppConstants.taskTypeAttendanceQoddas,
                          child: Text(context.tr.taskTypeAttendanceQoddas),
                        )
                      else
                        DropdownMenuItem(
                          value: AppConstants.taskTypeAttendanceKhedma,
                          child: Text(context.tr.taskTypeAttendanceKhedma),
                        ),
                      DropdownMenuItem(
                        value: 'visitation',
                        child: Text(context.tr.taskTypeVisitation),
                      ),
                    ],
                    onChanged: _submittedTask != null
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                _taskType = val;
                                if (_taskType.startsWith('attendance')) {
                                  _dueDate ??= _getNextFriday();
                                  if (_titleController.text.isEmpty ||
                                      _titleController.text ==
                                          context.tr.taskTypeAttendanceKhedma ||
                                      _titleController.text ==
                                          context.tr.taskTypeAttendanceQoddas) {
                                    _titleController.text =
                                        _taskType ==
                                            AppConstants
                                                .taskTypeAttendanceQoddas
                                        ? context.tr.taskTypeAttendanceQoddas
                                        : context.tr.taskTypeAttendanceKhedma;
                                  }
                                }
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 14),

                  // تاريخ الاستحقاق / يوم الجمعة
                  InkWell(
                    onTap: () async {
                      if (_submittedTask != null) return;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? _getNextFriday(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 7),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        selectableDayPredicate:
                            _taskType.startsWith('attendance')
                            ? (DateTime day) => day.weekday == DateTime.friday
                            : null,
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131D31)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppConstants.cardBorderDark
                              : AppConstants.cardBorderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _taskType.startsWith('attendance')
                                ? Icons.event_available_rounded
                                : Icons.calendar_today_outlined,
                            size: 18,
                            color: AppConstants.primaryLight,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _dueDate != null
                                  ? context.tr.messageDate(
                                      (AppFormatters(
                                            Localizations.localeOf(context),
                                          ).formatDate(
                                            _dueDate!,
                                            format: 'yyyy-MM-dd',
                                          ))
                                          .toString(),
                                    )
                                  : context.tr.messageSelectDueDateOptional,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _dueDate != null
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _dueDate != null
                                    ? (isDark
                                          ? Colors.white
                                          : AppConstants.textDark)
                                    : AppConstants.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_taskType.startsWith('attendance'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryLight.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppFormatters(
                                  Localizations.localeOf(context),
                                ).formatWeekday(_dueDate ?? _getNextFriday()),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // اختيار الخادم المكلف
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    itemHeight: null,
                    initialValue: _selectedKhademId,
                    decoration: InputDecoration(
                      labelText: context.tr.taskAssigneeLabel,
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                    items: widget.availableKhodam.map((khadem) {
                      return DropdownMenuItem(
                        value: khadem.id,
                        child: Text(
                          khadem.name.isNotEmpty ? khadem.name : khadem.email,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _submittedTask != null
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedKhademId = val);
                            }
                          },
                  ),
                  const SizedBox(height: 14),

                  // تفاصيل المهمة
                  TextFormField(
                    enabled: _submittedTask == null,
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr.taskDescLabel,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // أزرار الحفظ والإلغاء
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.tr.save,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

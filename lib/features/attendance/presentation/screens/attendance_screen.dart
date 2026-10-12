import 'package:efteqad/core/widgets/async_content.dart';
import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/services/attendance_roster_repository.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/repositories/attendance_repository.dart';
import '../../../../core/services/trusted_mutations.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/utils/color_generator.dart';
import '../../application/attendance_cubit.dart';
import '../../application/attendance_access.dart';

class AttendanceScreen extends StatefulWidget {
  final TaskModel task;
  final AttendanceRepository? repository;
  final Future<List<AttendanceRosterRow>> Function(String)? loadRoster;

  const AttendanceScreen({
    super.key,
    required this.task,
    this.repository,
    this.loadRoster,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final DateTime _dueDate;
  late final String _sessionDate;
  late final String _sessionType; // 'khedma' or 'qoddas'
  late final String _sessionGrade; // '1st', '2nd', '3rd', or 'all'
  late final String _sessionId;

  late final AttendanceRepository _attendanceRepository;
  late final AttendanceCubit _attendanceCubit;
  late Stream<List<AttendanceRosterRow>> _makhdomeenStream;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dueDate = widget.task.dueDate ?? _getNextFriday();
    _sessionDate =
        widget.task.attendanceDay ??
        DateFormat('yyyy-MM-dd').format(_dueDate.toUtc());
    _sessionType = widget.task.isMassAttendance ? 'qoddas' : 'khedma';
    _sessionGrade = widget.task.grade;

    _sessionId = AttendanceSessionModel.generateSessionId(
      date: _sessionDate,
      type: _sessionType,
      grade: _sessionGrade,
    );

    _attendanceRepository =
        widget.repository ?? FirestoreAttendanceRepository();

    final sessionCubit = context.read<SessionCubit>();
    final session = sessionCubit.state;
    final khademName = session.profile?.name ?? '';

    _attendanceCubit = AttendanceCubit(
      repository: _attendanceRepository,
      sessionId: _sessionId,
      grade: _sessionGrade,
      date: _sessionDate,
      type: _sessionType,
      khademId: session.userId ?? '',
      khademName: khademName,
      taskId: widget.task.id,
      userId: () => sessionCubit.state.userId ?? '',
    );

    _makhdomeenStream = _rosterForCurrentTask();
  }

  Stream<List<AttendanceRosterRow>> _rosterForCurrentTask() =>
      widget.task.isCompleted || widget.task.status != 'active'
      ? Stream.value([])
      : (widget.loadRoster ?? AttendanceRosterRepository().load)(
          widget.task.id,
        ).asStream();

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The router replaces state for identity/scope/date changes, but retains
    // this screen across completion changes from another administrator.
    if (oldWidget.task.id == widget.task.id &&
        oldWidget.task.isCompleted != widget.task.isCompleted) {
      _makhdomeenStream = _rosterForCurrentTask();
    }
  }

  @override
  void dispose() {
    _attendanceCubit.close();
    super.dispose();
  }

  DateTime _getNextFriday() {
    final now = DateTime.now();
    int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilFriday));
  }

  bool _isUserAuthorized() => canManageAttendance(
    context.read<SessionCubit>().state,
    widget.task,
    context.read<SessionCubit>().state.userId,
  );

  bool get _canReopen {
    final session = context.read<SessionCubit>().state;
    return session.isActive &&
        widget.task.status != 'cancelled' &&
        (session.isStageAdmin ||
            (session.isGradeAdmin && session.grade == _sessionGrade));
  }

  Future<void> _handleReopenAttendance() async {
    var reason = '';
    final operationId = newOperationId('reopen');
    var saving = false;
    Object? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.tr.reopenAttendance),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => reason = value,
                enabled: !saving && error == null,
                maxLength: 500,
                decoration: InputDecoration(labelText: context.tr.reopenReason),
              ),
              if (error != null)
                Text(
                  AppFailure.fromException(error!).localizedMessage(context.tr),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(context.tr.messageCancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (reason.trim().isEmpty) return;
                      setDialogState(() {
                        saving = true;
                      });
                      try {
                        await _attendanceRepository.reopenAttendance(
                          sessionId: _sessionId,
                          grade: _sessionGrade,
                          reason: reason.trim(),
                          operationId: operationId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            saving = false;
                            error = e;
                          });
                        }
                      }
                    },
              child: Text(context.tr.reopenAttendanceAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAttendance(
    AttendanceRosterRow makhdom,
    bool isPresent,
  ) async {
    if (_attendanceCubit.state.isFinalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.messageThisSessionHasBeenFinalizedAndCannot),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    try {
      await _attendanceCubit.setPresence(
        makhdomId: makhdom.id,
        isPresent: isPresent,
      );
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
    }
  }

  Future<void> _handleFinalizeAttendance() async {
    if (_attendanceCubit.state.pendingById.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.messagePleaseWaitForPendingSavesToFinish),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.messageFinalizeAttendance),
        content: Text(context.tr.messageAreYouSureYouWantToFinalize),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.messageCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.successColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr.messageConfirmFinalization),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _attendanceCubit.finalizeAttendance(taskId: widget.task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.messageAttendanceFinalizedSuccessfully),
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
      }
    }
  }

  String _getGradeLabel(String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return context.tr.messageSecondary;
    }
  }

  Widget _buildStatusBadge(AttendanceState state) {
    if (!state.hasLoadedRemote) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                context.tr.messageLoading,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isFinalized) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.primaryNavy.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppConstants.primaryNavy.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 12,
              color: AppConstants.primaryNavy,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.tr.messageFinalized,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryNavy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == 'saving' || state.pendingById.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.warningColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppConstants.warningColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppConstants.warningColor,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                context.tr.messageSaving,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.warningColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == 'error' || state.saveErrors.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.errorColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppConstants.errorColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 10,
              color: AppConstants.errorColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.tr.messageSaveError,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.errorColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppConstants.successColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppConstants.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              context.tr.autoSavedNotice,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppConstants.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthorized = _isUserAuthorized();

    return BlocProvider.value(
      value: _attendanceCubit,
      child: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, attendanceState) {
          return Scaffold(
            backgroundColor: isDark
                ? AppConstants.backgroundDark
                : AppConstants.backgroundLight,
            appBar: AppBar(
              toolbarHeight:
                  56 *
                  MediaQuery.textScalerOf(context).scale(1) *
                  MediaQuery.textScalerOf(context).scale(1),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _sessionType == 'qoddas'
                        ? context.tr.attendanceScreenTitleMass
                        : '${context.tr.attendanceScreenTitleService} (${_getGradeLabel(_sessionGrade)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    AppFormatters(
                      Localizations.localeOf(context),
                    ).formatDayAndDate(_dueDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                if (_canReopen &&
                    attendanceState.isFinalized &&
                    attendanceState.hasLoadedRemote)
                  IconButton(
                    icon: const Icon(Icons.lock_open_rounded),
                    tooltip: context.tr.reopenAttendance,
                    onPressed: _handleReopenAttendance,
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.35,
                  ),
                  child: _buildStatusBadge(attendanceState),
                ),
                if (isAuthorized &&
                    !attendanceState.isFinalized &&
                    attendanceState.hasLoadedRemote &&
                    attendanceState.saveErrors.isEmpty &&
                    attendanceState.pendingById.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    tooltip: context.tr.messageFinalizeAttendance,
                    onPressed: _handleFinalizeAttendance,
                  ),
                const SizedBox(width: 4),
              ],
            ),
            body: StreamBuilder<List<AttendanceRosterRow>>(
              stream: _makhdomeenStream,
              builder: (context, makhdomeenSnap) {
                if (!attendanceState.hasLoadedRemote &&
                    attendanceState.status == 'error') {
                  return AsyncContent<void>(
                    isLoading: false,
                    error: const AppFailure(
                      code: 'attendance-load',
                      message: 'Attendance could not load.',
                      retryable: true,
                    ),
                    onRetry: _attendanceCubit.retryLoading,
                    builder: (_, _) => const SizedBox.shrink(),
                  );
                }
                if (makhdomeenSnap.connectionState == ConnectionState.waiting &&
                    !makhdomeenSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (makhdomeenSnap.hasError) {
                  return AsyncContent<List<AttendanceRosterRow>>(
                    isLoading: false,
                    error: makhdomeenSnap.error,
                    onRetry: () => setState(() {
                      _makhdomeenStream =
                          (widget.loadRoster ??
                                  AttendanceRosterRepository().load)(
                                widget.task.id,
                              )
                              .asStream();
                    }),
                    builder: (_, rows) => const SizedBox.shrink(),
                  );
                }
                final allMakhdomeen = makhdomeenSnap.data ?? [];
                final attendedList = allMakhdomeen
                    .where((m) => attendanceState.isAttended(m.id))
                    .toList();

                final filteredList = allMakhdomeen.where((m) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return m.fullName.toLowerCase().contains(q);
                }).toList();

                return Column(
                  children: [
                    // غير مصرح بالتعديل تنبيه
                    if (!isAuthorized)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        color: AppConstants.warningColor.withValues(
                          alpha: 0.15,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppConstants.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr.notAuthorizedAttendance,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.warningColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // تنبيه جلسة معتمدة
                    if (attendanceState.isFinalized)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        color: AppConstants.successColor.withValues(
                          alpha: 0.15,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: AppConstants.successColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context
                                    .tr
                                    .messageAttendanceSessionIsFinalizedAndLockedRead,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // =================== الجزء العلوي: الثلث (1/3) ===================
                    _buildTopAttendedSection(
                      attendedList: attendedList,
                      totalCount: allMakhdomeen.length,
                      isDark: isDark,
                      isAuthorized:
                          isAuthorized && !attendanceState.isFinalized,
                    ),

                    // =================== الفاصل وشريط البحث ===================
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        10,
                        16,
                        8,
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: context.tr.messageSearchByName,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),

                    // =================== الجزء السفلي: الثلثين (2/3) ===================
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 44,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr.noSearchResults,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                0,
                                16,
                                30,
                              ),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final makhdom = filteredList[index];
                                final isAttended = attendanceState.isAttended(
                                  makhdom.id,
                                );
                                final isPending = attendanceState.isPending(
                                  makhdom.id,
                                );
                                final hasError = attendanceState.hasError(
                                  makhdom.id,
                                );
                                return _buildMakhdomAttendanceRow(
                                  makhdom: makhdom,
                                  isAttended: isAttended,
                                  isPending: isPending,
                                  hasError: hasError,
                                  isDark: isDark,
                                  isAuthorized:
                                      isAuthorized &&
                                      !attendanceState.isFinalized,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // الجزء العلوي (1/3 الشاشة)
  Widget _buildTopAttendedSection({
    required List<AttendanceRosterRow> attendedList,
    required int totalCount,
    required bool isDark,
    required bool isAuthorized,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight =
        (screenHeight * 0.30).clamp(160.0, 240.0) *
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

    return Container(
      height: topHeight,
      margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attendedList.isNotEmpty
              ? AppConstants.primaryLight.withValues(alpha: 0.35)
              : (isDark
                    ? AppConstants.cardBorderDark
                    : AppConstants.cardBorderLight),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  size: 16,
                  color: AppConstants.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr.selectedAttendedHeader,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr.totalAttendedCount(
                    attendedList.length,
                    totalCount,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Expanded(
            child: attendedList.isEmpty
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: isDark
                              ? Colors.white38
                              : AppConstants.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.tr.noAttendedYetHint,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : AppConstants.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attendedList.map((m) {
                        return _buildAttendedChip(m, isDark, isAuthorized);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendedChip(
    AttendanceRosterRow m,
    bool isDark,
    bool isAuthorized,
  ) {
    final color = ColorGenerator.getColorForId(m.id);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAuthorized)
            InkWell(
              onTap: () => _toggleAttendance(m, false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(2),
                margin: const EdgeInsetsDirectional.only(start: 4),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppConstants.errorColor,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              m.fullName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppConstants.textDark,
              ),
            ),
          ),
          if (_sessionType == 'qoddas') ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getGradeShortLabel(m.grade),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGradeShortLabel(String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.message1st;
      case AppConstants.grade2nd:
        return context.tr.message2nd;
      case AppConstants.grade3rd:
        return context.tr.message3rd;
      default:
        return '';
    }
  }

  Widget _buildMakhdomAttendanceRow({
    required AttendanceRosterRow makhdom,
    required bool isAttended,
    required bool isPending,
    required bool hasError,
    required bool isDark,
    required bool isAuthorized,
  }) {
    final khademColor = ColorGenerator.getColorForId(makhdom.id);

    return InkWell(
      onTap: isAuthorized && !isPending
          ? () => _toggleAttendance(makhdom, !isAttended)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isAttended
              ? AppConstants.primaryLight.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? AppConstants.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError
                ? AppConstants.errorColor
                : (isAttended
                      ? AppConstants.primaryLight
                      : (isDark
                            ? AppConstants.cardBorderDark
                            : AppConstants.cardBorderLight)),
            width: isAttended || hasError ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isPending)
              const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Checkbox(
                value: isAttended,
                activeColor: AppConstants.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: isAuthorized
                    ? (val) => _toggleAttendance(makhdom, val ?? false)
                    : null,
              ),
            const SizedBox(width: 8),

            CircleAvatar(
              radius: 16,
              backgroundColor: khademColor.withValues(alpha: 0.15),
              child: Text(
                makhdom.fullName.isNotEmpty
                    ? makhdom.fullName[0]
                    : context.tr.messageM,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: khademColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          makhdom.fullName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isAttended
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppConstants.textDark,
                          ),
                        ),
                      ),
                      if (hasError)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.error_outline,
                            size: 16,
                            color: AppConstants.errorColor,
                          ),
                        ),
                    ],
                  ),
                  if (_sessionType == 'qoddas')
                    Row(
                      children: [
                        if (_sessionType == 'qoddas') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: khademColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _getGradeLabel(makhdom.grade),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: khademColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

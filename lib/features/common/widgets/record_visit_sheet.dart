import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/visit_draft_store.dart';
import '../../../../core/services/trusted_mutations.dart';

class RecordVisitSheet extends StatefulWidget {
  final MakhdomModel makhdom;
  final String? khademName;

  final FirestoreService? firestoreService;
  final AuthService? authService;
  final VisitDraftStore? draftStore;
  const RecordVisitSheet({
    super.key,
    this.firestoreService,
    this.authService,
    this.draftStore,
    required this.makhdom,
    this.khademName,
  });

  static Future<void> show(
    BuildContext context, {
    required MakhdomModel makhdom,
    String? khademName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          RecordVisitSheet(makhdom: makhdom, khademName: khademName),
    );
  }

  @override
  State<RecordVisitSheet> createState() => _RecordVisitSheetState();
}

class _RecordVisitSheetState extends State<RecordVisitSheet> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final VisitDraftStore _draftStore;
  final TextEditingController _notesController = TextEditingController();

  String? _visitType;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _hasDraft = false;
  bool _isLoadingDraft = true;
  Object? _draftLoadError;
  String? _draftOperationId;
  String? _draftUid;
  VisitModel? _submittedVisit;

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    _authService = widget.authService ?? AuthService();
    _draftStore = widget.draftStore ?? VisitDraftStore();
    _loadDraftIfAny();
  }

  Future<void> _loadDraftIfAny() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw StateError('Authentication required.');
      _draftUid = user.uid;
      final drafts = await _draftStore.getDrafts(user.uid);
      if (!mounted) return;
      if (_authService.currentUser?.uid != user.uid) {
        throw StateError(
          'The initiating account changed. Resume with that account.',
        );
      }
      final match = drafts
          .where((d) => d['makhdomId'] == widget.makhdom.id)
          .firstOrNull;
      if (match != null && mounted) {
        _hasDraft = true;
        _draftOperationId = match['operationId'] as String?;
        _notesController.text = match['notes']?.toString() ?? '';
        if (match['visitType'] != null) {
          _visitType = canonicalVisitType(match['visitType'].toString());
        }
        if (match['visitDate'] != null) {
          _selectedDate =
              DateTime.tryParse(match['visitDate'].toString()) ?? _selectedDate;
        }
        if (_draftOperationId != null) {
          _submittedVisit = VisitModel(
            id: '',
            makhdomId: widget.makhdom.id,
            makhdomName: widget.makhdom.fullName,
            khademId: user.uid,
            khademName: widget.khademName ?? user.displayName ?? '',
            visitDate: _selectedDate,
            visitType: _visitType ?? 'home',
            notes: match['notes'] as String?,
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (error) {
      _draftLoadError = error;
    } finally {
      if (mounted) setState(() => _isLoadingDraft = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visitType ??= 'home';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving || _isLoadingDraft || _draftLoadError != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != _draftUid) {
        throw StateError(
          'The initiating account changed. Resume with that account.',
        );
      }
      final khademName =
          widget.khademName ??
          (currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName!
              : context.tr.servant);

      final operationId = _draftOperationId ??= newOperationId('visit');

      final effectiveVisitType = _visitType ?? 'home';

      final visit = _submittedVisit ??= VisitModel(
        id: '',
        makhdomId: widget.makhdom.id,
        makhdomName: widget.makhdom.fullName,
        khademId: currentUser.uid,
        khademName: khademName,
        visitDate: _selectedDate,
        visitType: effectiveVisitType,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      await _firestoreService.recordVisit(visit, operationId: operationId);
      if (_authService.currentUser?.uid != currentUser.uid) {
        throw StateError('The initiating account changed.');
      }
      await _draftStore.removeDraft(currentUser.uid, widget.makhdom.id);
      if (_authService.currentUser?.uid != currentUser.uid) {
        throw StateError('The initiating account changed.');
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.visitSavedSuccess),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppFailure.fromException(e).localizedMessage(context.tr),
            ),
            backgroundColor: AppConstants.warningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTypeChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: _submittedVisit != null ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15)
              : (isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryLight : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? AppConstants.primaryLight
                : (isDark ? Colors.white70 : AppConstants.textDark),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _visitType ??= 'home';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.accentIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.add_task,
                    color: AppConstants.accentIndigo,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.logVisitTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppConstants.textDark,
                        ),
                      ),
                      Text(
                        widget.makhdom.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_draftLoadError != null)
              Text(
                context.tr.dataUnavailable,
                style: const TextStyle(color: AppConstants.errorColor),
              ),
            if (_hasDraft) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: AppConstants.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context
                            .tr
                            .messageLocalSubmissionLoadedConfirmationIsPending,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Visit type selection
            Text(
              context.tr.visitTypeLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip(
                  context.tr.visitHome,
                  _visitType == 'home',
                  () => setState(() => _visitType = 'home'),
                  isDark,
                ),
                _buildTypeChip(
                  context.tr.visitPhone,
                  _visitType == 'phone',
                  () => setState(() => _visitType = 'phone'),
                  isDark,
                ),
                _buildTypeChip(
                  context.tr.visitChurch,
                  _visitType == 'church',
                  () => setState(() => _visitType = 'church'),
                  isDark,
                ),
                _buildTypeChip(
                  context.tr.visitOther,
                  _visitType == 'other',
                  () => setState(() => _visitType = 'other'),
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date selection
            InkWell(
              onTap: () async {
                if (_submittedVisit != null) return;
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131D31)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppConstants.cardBorderDark
                        : AppConstants.cardBorderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppConstants.primaryLight,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr.visitDateLabel(
                        AppFormatters(
                          Localizations.localeOf(context),
                        ).formatDate(_selectedDate),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppConstants.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // تقرير الافتقاد وملاحظات الخادم (الديسكريبشن)
            TextField(
              enabled: _submittedVisit == null,
              controller: _notesController,
              maxLines: 4,
              minLines: 2,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.tr.messageVisitNotesAndDiscussion,
                hintText: context
                    .tr
                    .messageRecordVisitDiscussionMeetingDetailsOrPastoral,
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppConstants.accentIndigo,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF131D31)
                    : const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 20),

            if (_submittedVisit != null)
              Text(
                context.tr.messageFieldsAreLockedUntilConfirmationRetryTo631,
              ),
            // Save button
            ElevatedButton(
              onPressed: _isSaving || _isLoadingDraft || _draftLoadError != null
                  ? null
                  : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      context.tr.saveVisitBtn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

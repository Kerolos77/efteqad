import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/khadem_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/makhdom_profile_patch.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/trusted_mutations.dart';

class AddEditMakhdomDialog extends StatefulWidget {
  final MakhdomModel? initialMakhdom;
  final List<KhademModel> khodamList;
  final FirestoreService? firestoreService;

  const AddEditMakhdomDialog({
    super.key,
    this.firestoreService,
    this.initialMakhdom,
    required this.khodamList,
  });

  @override
  State<AddEditMakhdomDialog> createState() => _AddEditMakhdomDialogState();
}

class _AddEditMakhdomDialogState extends State<AddEditMakhdomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final FirestoreService _firestoreService;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _fatherPhoneController;
  late TextEditingController _motherPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _schoolController;
  late TextEditingController _secondaryTypeController;
  late TextEditingController _secondaryCustomController;
  bool _secondaryEdited = false;
  bool get _supportsCustomSecondary => !const [
    'general',
    'technical',
    'services',
    'commercial',
  ].contains(_secondaryTypeController.text);
  DateTime? _trackingStartDate;
  bool _trackingEdited = false;
  late TextEditingController _locationController;
  late TextEditingController _photoController;
  late TextEditingController _notesController;

  DateTime? _birthDate;
  bool _isBrethren = false;
  String? _selectedKhademId;
  String? _selectedKhademName;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  final String _createOperationId = newOperationId('profile');
  String? _createdId;
  bool _submissionStarted = false;
  String? _submittedUid;
  bool _profileSaved = false;
  MakhdomProfilePatch? _submittedPatch;
  MakhdomModel? _submittedMakhdom;
  String? _submittedKhademId;
  String? _submittedKhademName;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // تحقق من الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr.locationPermissionDenied),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.locationPermissionPermanentlyDenied),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: context.tr.openSettings,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _locationController.text =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.locationFetchedSuccess),
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
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  int? _calculateAge(DateTime bDate) {
    final now = DateTime.now();
    int a = now.year - bDate.year;
    if (now.month < bDate.month ||
        (now.month == bDate.month && now.day < bDate.day)) {
      a--;
    }
    return a >= 0 ? a : null;
  }

  int _defaultAgeForGrade(String? grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return 15;
      case AppConstants.grade2nd:
        return 16;
      case AppConstants.grade3rd:
        return 17;
      default:
        return 15;
    }
  }

  int get _currentEffectiveAge {
    if (_birthDate != null) {
      return _calculateAge(_birthDate!) ??
          _defaultAgeForGrade(widget.initialMakhdom?.grade);
    }
    return _defaultAgeForGrade(widget.initialMakhdom?.grade);
  }

  @override
  void initState() {
    super.initState();
    _firestoreService = widget.firestoreService ?? FirestoreService();
    final m = widget.initialMakhdom;
    _nameController = TextEditingController(text: m?.fullName ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _birthDate = m?.birthDate;
    _fatherPhoneController = TextEditingController(text: m?.fatherPhone ?? '');
    _motherPhoneController = TextEditingController(text: m?.motherPhone ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _areaController = TextEditingController(text: m?.area ?? '');
    _schoolController = TextEditingController(text: m?.school ?? '');
    _secondaryCustomController = TextEditingController(
      text: m?.secondaryTypeCustomLabel ?? '',
    );
    _trackingStartDate = m?.trackingStartDate;
    final secondaryCode = const DomainLabels(
      Locale('ar'),
    ).secondaryTypeCode(m?.secondaryType ?? 'general');
    _secondaryTypeController = TextEditingController(
      text: secondaryCode.isEmpty ? 'general' : secondaryCode,
    );
    _locationController = TextEditingController(text: m?.homeLocationUrl ?? '');
    _photoController = TextEditingController(text: m?.photoUrl ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');

    _isBrethren = m?.isBrethrenOfLord ?? false;
    _selectedKhademId = m?.assignedKhademId;
    _selectedKhademName = m?.assignedKhademName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fatherPhoneController.dispose();
    _motherPhoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _schoolController.dispose();
    _secondaryTypeController.dispose();
    _secondaryCustomController.dispose();
    _locationController.dispose();
    _photoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading ||
        _isLoadingLocation ||
        (!_submissionStarted && !_formKey.currentState!.validate())) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      if (!_submissionStarted) {
        _submittedKhademId = _selectedKhademId;
        _submittedKhademName = _selectedKhademName;
        _submittedUid = _firestoreService.captureMutationIdentity();
        _submissionStarted = true;
      }
      _isLoading = true;
    });
    try {
      _firestoreService.checkMutationIdentity(_submittedUid);
      final isEdit =
          widget.initialMakhdom != null && widget.initialMakhdom!.id.isNotEmpty;

      if (isEdit) {
        final patch = _submittedPatch ??= MakhdomProfilePatch(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDate,
          clearBirthDate:
              _birthDate == null && widget.initialMakhdom?.birthDate != null,
          fatherPhone: _fatherPhoneController.text.trim(),
          motherPhone: _motherPhoneController.text.trim(),
          address: _addressController.text.trim(),
          area: _areaController.text.trim(),
          school: _schoolController.text.trim(),
          secondaryType: _secondaryTypeController.text,
          secondaryTypeCustomLabel: _secondaryEdited
              ? (_supportsCustomSecondary
                    ? _secondaryCustomController.text.trim()
                    : null)
              : widget.initialMakhdom?.secondaryTypeCustomLabel,
          clearSecondaryTypeCustomLabel:
              _secondaryEdited &&
              (!_supportsCustomSecondary ||
                  _secondaryCustomController.text.trim().isEmpty),
          trackingStartDate: _trackingEdited ? _trackingStartDate : null,
          clearTrackingStartDate: _trackingEdited && _trackingStartDate == null,
          grade: widget.initialMakhdom?.grade ?? AppConstants.grade1st,
          homeLocationUrl: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          clearHomeLocationUrl:
              _locationController.text.trim().isEmpty &&
              widget.initialMakhdom?.homeLocationUrl != null,
          isBrethrenOfLord: _isBrethren,
          photoUrl: _photoController.text.trim().isNotEmpty
              ? _photoController.text.trim()
              : null,
          clearPhotoUrl:
              _photoController.text.trim().isEmpty &&
              widget.initialMakhdom?.photoUrl != null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          clearNotes:
              _notesController.text.trim().isEmpty &&
              widget.initialMakhdom?.notes != null,
        );

        if (!_profileSaved) {
          await _firestoreService.updateMakhdomPatch(
            widget.initialMakhdom!.id,
            patch,
            expectedUid: _submittedUid,
            operationId: _createOperationId,
          );
          _firestoreService.checkMutationIdentity(_submittedUid);
          _profileSaved = true;
        }

        // إذا تغير تعيين الخادم، يتم تحديث الإسناد بشكل مستقل وذرّي
        if (_submittedKhademId != widget.initialMakhdom?.assignedKhademId) {
          if (_submittedKhademId != null && _submittedKhademId!.isNotEmpty) {
            await _firestoreService.assignMakhdomeenToKhadem(
              khademId: _submittedKhademId!,
              khademName: _submittedKhademName ?? '',
              makhdomeenIds: [widget.initialMakhdom!.id],
              expectedAssignments: {
                widget.initialMakhdom!.id:
                    widget.initialMakhdom?.assignedKhademId,
              },
              expectedUid: _submittedUid,
              operationId: '${_createOperationId}_assign',
            );
          } else {
            await _firestoreService.unassignMakhdom(
              widget.initialMakhdom!.id,
              expectedKhademId: widget.initialMakhdom?.assignedKhademId,
              expectedUid: _submittedUid,
              operationId: '${_createOperationId}_unassign',
            );
          }
        }
      } else {
        final makhdom = _submittedMakhdom ??= MakhdomModel(
          id: '',
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDate,
          fatherPhone: _fatherPhoneController.text.trim(),
          motherPhone: _motherPhoneController.text.trim(),
          address: _addressController.text.trim(),
          area: _areaController.text.trim(),
          school: _schoolController.text.trim(),
          secondaryType: _secondaryTypeController.text,
          secondaryTypeCustomLabel: _supportsCustomSecondary
              ? _secondaryCustomController.text.trim()
              : null,
          trackingStartDate: _trackingStartDate,
          grade: widget.initialMakhdom?.grade ?? AppConstants.grade1st,
          homeLocationUrl: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          isBrethrenOfLord: _isBrethren,
          photoUrl: _photoController.text.trim().isNotEmpty
              ? _photoController.text.trim()
              : null,
          assignedKhademId: _submittedKhademId,
          assignedKhademName: _submittedKhademName,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          visitCount: 0,
          lastVisitDate: null,
          createdAt: DateTime.now(),
        );

        _createdId ??= await _firestoreService.addMakhdom(
          makhdom,
          expectedUid: _submittedUid,
          operationId: _createOperationId,
        );
        _firestoreService.checkMutationIdentity(_submittedUid);
        if (_submittedKhademId != null) {
          await _firestoreService.assignMakhdomeenToKhadem(
            khademId: _submittedKhademId!,
            khademName: _submittedKhademName ?? '',
            makhdomeenIds: [_createdId!],
            expectedAssignments: {_createdId!: null},
            expectedUid: _submittedUid,
            operationId: '${_createOperationId}_assign',
          );
        }
      }

      _firestoreService.checkMutationIdentity(_submittedUid);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.makhdomSavedSuccess),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConstants.primaryLight),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppConstants.textSecondaryDark
                  : AppConstants.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isDark
                  ? AppConstants.borderDark
                  : AppConstants.borderLight,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit =
        widget.initialMakhdom != null && widget.initialMakhdom!.id.isNotEmpty;

    return Dialog(
      backgroundColor: isDark ? AppConstants.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.94,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          (isEdit
                                  ? AppConstants.accentBlue
                                  : AppConstants.primaryLight)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: isEdit
                          ? AppConstants.accentBlue
                          : AppConstants.primaryLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? context.tr.editMakhdomTitle
                              : context.tr.addMakhdomTitle,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppConstants.textPrimary,
                          ),
                        ),
                        Text(
                          isEdit
                              ? (context
                                    .tr
                                    .messageUpdateRecordAndPersonalDetails)
                              : (context
                                    .tr
                                    .messageInsertNewMakhdomToCareRegistry),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppConstants.textMutedDark
                                : AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppConstants.textMutedDark
                          : AppConstants.textMuted,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Section 1: البيانات الشخصية والاتصال
                      _buildSectionHeader(
                        context,
                        icon: Icons.person_pin_outlined,
                        title: context.tr.personalAndContactSec,
                      ),

                      // 1. الاسم رباعي
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: context.tr.fullNameRequiredLabel,
                          prefixIcon: const Icon(
                            Icons.person_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr.fullNameValidation
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // 2. رقم تليفون المخدوم
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr.makhdomPhoneLabel,
                          prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr.phoneRequired
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // 3. العمر وتاريخ الميلاد (محسوب تلقائياً)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppConstants.surfaceDark
                                      : const Color(0xFFF1F5F9))
                                  .withValues(alpha: 0.7),
                          border: Border.all(
                            color: isDark
                                ? AppConstants.borderDark
                                : AppConstants.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryLight.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.cake_outlined,
                                    size: 20,
                                    color: AppConstants.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              context.tr.messageAgeYears(
                                                AppFormatters(
                                                  Localizations.localeOf(
                                                    context,
                                                  ),
                                                ).formatNumber(
                                                  (_currentEffectiveAge),
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppConstants.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  (_birthDate != null
                                                          ? AppConstants
                                                                .successColor
                                                          : AppConstants
                                                                .accentBlue)
                                                      .withValues(alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _birthDate != null
                                                  ? context
                                                        .tr
                                                        .messageCalculatedPrecisely
                                                  : context.tr.messageAutomatic,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: _birthDate != null
                                                    ? AppConstants.successColor
                                                    : AppConstants.accentBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _birthDate != null
                                            ? context.tr.birthDateCaption(
                                                AppFormatters(
                                                  Localizations.localeOf(
                                                    context,
                                                  ),
                                                ).formatDate(_birthDate),
                                              )
                                            : context.tr
                                                  .messageAgeEstimatedFromSecondaryGrade(
                                                    (DomainLabels(
                                                          Localizations.localeOf(
                                                            context,
                                                          ),
                                                        ).gradeName(
                                                          widget
                                                                  .initialMakhdom
                                                                  ?.grade ??
                                                              AppConstants
                                                                  .grade1st,
                                                        ))
                                                        .toString(),
                                                  ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppConstants.textMutedDark
                                              : AppConstants.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_birthDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    splashRadius: 16,
                                    tooltip: context
                                        .tr
                                        .messageResetToAutomaticCalculation,
                                    color: AppConstants.textMuted,
                                    onPressed: _submissionStarted
                                        ? null
                                        : () =>
                                              setState(() => _birthDate = null),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // شريط سريع لاختيار السن بنقرة واحدة أو تحديد تاريخ دقيق
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  ...[14, 15, 16, 17, 18].map((ageVal) {
                                    final isSelected =
                                        _currentEffectiveAge == ageVal;
                                    return Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 6,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          if (_submissionStarted) return;
                                          final targetYear =
                                              DateTime.now().year - ageVal;
                                          setState(() {
                                            _birthDate = DateTime(
                                              targetYear,
                                              1,
                                              1,
                                            );
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppConstants.primaryLight
                                                : (isDark
                                                      ? Colors.white10
                                                      : Colors.white),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppConstants.primaryLight
                                                  : (isDark
                                                        ? Colors.white12
                                                        : AppConstants
                                                              .borderLight),
                                            ),
                                          ),
                                          child: Text(
                                            context.tr.messageYears721(
                                              AppFormatters(
                                                Localizations.localeOf(context),
                                              ).formatNumber((ageVal)),
                                            ),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white70
                                                        : AppConstants
                                                              .textSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () async {
                                      if (_submissionStarted) return;
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            _birthDate ??
                                            DateTime(
                                              DateTime.now().year -
                                                  _currentEffectiveAge,
                                              1,
                                              1,
                                            ),
                                        firstDate: DateTime(1990),
                                        lastDate: DateTime.now(),
                                        initialDatePickerMode:
                                            DatePickerMode.year,
                                        helpText: context
                                            .tr
                                            .messageChooseExactBirthDate,
                                        confirmText: context.tr.confirm,
                                        cancelText: context.tr.cancel,
                                      );
                                      if (picked != null) {
                                        setState(() => _birthDate = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : AppConstants.borderLight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_month_outlined,
                                            size: 14,
                                            color: AppConstants.accentBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            context.tr.messageExactDate,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : AppConstants.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3 & 4. تليفون الأب والأم
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _fatherPhoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: context.tr.fatherPhoneInputLabel,
                                prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _motherPhoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: context.tr.motherPhoneInputLabel,
                                prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Section 2: السكن والتعليم
                      _buildSectionHeader(
                        context,
                        icon: Icons.location_on_outlined,
                        title: context.tr.residenceAndSchoolSec,
                      ),

                      // 5 & 6. المنطقة والعنوان
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _areaController,
                              decoration: InputDecoration(
                                labelText: context.tr.residentialAreaLabel,
                                prefixIcon: const Icon(
                                  Icons.location_city_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              enabled: !_submissionStarted,
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: context.tr.detailedAddressLabel,
                                prefixIcon: const Icon(
                                  Icons.home_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 7. المدرسة
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _schoolController,
                        decoration: InputDecoration(
                          labelText: context.tr.schoolNameInputLabel,
                          prefixIcon: const Icon(
                            Icons.school_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 8. نوع الثانوية
                      () {
                        const standardTypes = [
                          'general',
                          'technical',
                          'services',
                          'commercial',
                          'other',
                        ];
                        final currentVal = _secondaryTypeController.text;
                        final effectiveVal = currentVal.isNotEmpty
                            ? currentVal
                            : 'general';
                        final allTypes = standardTypes.contains(effectiveVal)
                            ? standardTypes
                            : [effectiveVal, ...standardTypes];

                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: effectiveVal,
                          decoration: InputDecoration(
                            labelText: context.tr.secondaryTypeInputLabel,
                            prefixIcon: const Icon(
                              Icons.category_rounded,
                              size: 20,
                            ),
                          ),
                          items: allTypes.map((t) {
                            return DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                DomainLabels(
                                  Localizations.localeOf(context),
                                ).secondaryTypeName(
                                  t,
                                  customLabel: t == currentVal
                                      ? _secondaryCustomController.text
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _submissionStarted
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _secondaryTypeController.text = val;
                                      _secondaryEdited = true;
                                    });
                                  }
                                },
                        );
                      }(),
                      const SizedBox(height: 10),

                      if (_supportsCustomSecondary) ...[
                        TextFormField(
                          enabled: !_submissionStarted,
                          controller: _secondaryCustomController,
                          onChanged: (_) => _secondaryEdited = true,
                          decoration: InputDecoration(
                            labelText: context.tr.secondaryTypeCustomLabel,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _trackingStartDate == null
                              ? context.tr.trackingOriginUnknown
                              : context.tr.trackingStartLabel(
                                  AppFormatters(
                                    Localizations.localeOf(context),
                                  ).formatDate(_trackingStartDate!),
                                ),
                        ),
                        onTap: _submissionStarted
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _trackingStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null && mounted) {
                                  setState(() {
                                    _trackingStartDate = date;
                                    _trackingEdited = true;
                                  });
                                }
                              },
                        trailing: _trackingStartDate == null
                            ? const Icon(Icons.date_range)
                            : IconButton(
                                onPressed: _submissionStarted
                                    ? null
                                    : () => setState(() {
                                        _trackingStartDate = null;
                                        _trackingEdited = true;
                                      }),
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      const SizedBox(height: 10),

                      // 9. لوكيشن البيت
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _locationController,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr.googleMapsUrlLabel,
                          prefixIcon: const Icon(Icons.map_rounded, size: 20),
                          suffixIcon: _isLoadingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.my_location, size: 20),
                                  color: AppConstants.primaryLight,
                                  tooltip: context.tr.useCurrentLocation,
                                  onPressed: _submissionStarted
                                      ? null
                                      : _getCurrentLocation,
                                ),
                        ),
                      ),

                      // Section 3: الخدمة والرعاية
                      _buildSectionHeader(
                        context,
                        icon: Icons.supervised_user_circle_outlined,
                        title: context.tr.serviceAndCareSec,
                      ),

                      // اختيار الخادم المسؤول
                      () {
                        final isKhademInList =
                            _selectedKhademId == null ||
                            widget.khodamList.any(
                              (k) => k.id == _selectedKhademId,
                            );
                        final effectiveKhademId = isKhademInList
                            ? _selectedKhademId
                            : null;

                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: effectiveKhademId,
                          decoration: InputDecoration(
                            labelText: context.tr.assignedServantSelectLabel,
                            prefixIcon: const Icon(
                              Icons.person_pin_rounded,
                              size: 20,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                context.tr.unassignedNoServantOption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...widget.khodamList.map(
                              (k) => DropdownMenuItem(
                                value: k.id,
                                child: Text(
                                  k.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (!isKhademInList && _selectedKhademId != null)
                              DropdownMenuItem(
                                value: _selectedKhademId,
                                child: Text(
                                  _selectedKhademName ??
                                      context
                                          .tr
                                          .messageServantUnavailableInThisList,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _submissionStarted
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedKhademId = val;
                                    if (val == null) {
                                      _selectedKhademName = null;
                                    } else {
                                      final matches = widget.khodamList.where(
                                        (element) => element.id == val,
                                      );
                                      _selectedKhademName = matches.isNotEmpty
                                          ? matches.first.name
                                          : _selectedKhademName;
                                    }
                                  });
                                },
                        );
                      }(),
                      const SizedBox(height: 10),

                      // Switch أخوة الرب بتصميم أنيق
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isBrethren
                              ? AppConstants.accentGold.withValues(alpha: 0.1)
                              : (isDark
                                    ? AppConstants.surfaceDark
                                    : AppConstants.surfaceLight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isBrethren
                                ? AppConstants.accentGold.withValues(alpha: 0.6)
                                : (isDark
                                      ? AppConstants.borderDark
                                      : AppConstants.borderLight),
                            width: _isBrethren ? 1.5 : 1,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(
                                _isBrethren
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: _isBrethren
                                    ? AppConstants.accentGold
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black45),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr.brethrenSwitchLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          activeThumbColor: AppConstants.accentGold,
                          value: _isBrethren,
                          onChanged: _submissionStarted
                              ? null
                              : (val) => setState(() => _isBrethren = val),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // رابط الصورة
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _photoController,
                        decoration: InputDecoration(
                          labelText: context.tr.photoUrlOptionalLabel,
                          prefixIcon: const Icon(
                            Icons.image_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ملاحظات
                      TextFormField(
                        enabled: !_submissionStarted,
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: context.tr.additionalNotesOptionalLabel,
                          prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (_submissionStarted)
                Text(context.tr.messageFieldsAreLockedUntilConfirmationRetryTo),
              // Action buttons (Cancel & Save)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? AppConstants.borderDark
                              : AppConstants.borderLight,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.tr.cancel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppConstants.textSecondaryDark
                              : AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSave,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          _isLoading
                              ? context.tr.saving
                              : (isEdit
                                    ? context.tr.saveChanges
                                    : context.tr.save),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEdit
                              ? AppConstants.accentBlue
                              : AppConstants.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

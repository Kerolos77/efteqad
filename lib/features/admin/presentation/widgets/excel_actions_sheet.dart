import 'package:efteqad/core/localization/app_formatters.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/excel_column_labels.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/excel_import_result.dart';
import '../../../../core/services/excel_service.dart';
import '../../../../core/services/firestore_service.dart';

class ExcelActionsSheet extends StatefulWidget {
  final List<MakhdomModel> currentMakhdomeen;
  final String grade;
  final FirestoreService? firestoreService;
  final Future<ExcelImportResult> Function(String grade)? picker;

  const ExcelActionsSheet({
    super.key,
    this.firestoreService,
    this.picker,
    required this.currentMakhdomeen,
    required this.grade,
  });

  @override
  State<ExcelActionsSheet> createState() => _ExcelActionsSheetState();
}

class _ExcelActionsSheetState extends State<ExcelActionsSheet> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  bool _isLoading = false;
  String? _statusText;

  String _getGradeLabel(String grade) {
    switch (grade) {
      case AppConstants.grade1st:
        return context.tr.grade1stName;
      case AppConstants.grade2nd:
        return context.tr.grade2ndName;
      case AppConstants.grade3rd:
        return context.tr.grade3rdName;
      default:
        return grade;
    }
  }

  Future<void> _handleDownloadTemplate() async {
    setState(() {
      _isLoading = true;
      _statusText = context.tr.messageGeneratingSharingTemplate;
    });

    try {
      final labels = ExcelColumnLabels(Localizations.localeOf(context));
      await ExcelService.generateAndShareTemplate(labels: labels);
      if (mounted) Navigator.pop(context);
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

  Future<void> _handleUploadExcel() async {
    setState(() {
      _isLoading = true;
      _statusText = context.tr.messageReadingAndExtractingDataFromFile;
    });

    try {
      final result =
          await (widget.picker?.call(widget.grade) ??
              ExcelService.pickAndParseExcel(
                grade: widget.grade,
                labels: ExcelColumnLabels(Localizations.localeOf(context)),
              ));

      if (result.rows.isEmpty) {
        if (mounted) {
          if (result.hasErrors) {
            final errorSummary = result.rowErrors
                .take(3)
                .map((e) => '${e.rowIndex}: ${e.errorMessage}')
                .join('\n');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr.messageCouldNotImportAnyRowsDueTo(
                    (errorSummary).toString(),
                  ),
                ),
                backgroundColor: AppConstants.errorColor,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr.excelEmptyOrCanceled)),
            );
          }
        }
        return;
      }

      // إظهار نافذة المعاينة والتأكيد مع تفاصيل السنة والأخطاء والتحذيرات
      if (!mounted) return;
      final gradeLabel = _getGradeLabel(widget.grade);

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(ctx.tr.excelConfirmImportTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.messageTargetGrade((gradeLabel).toString()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(ctx.tr.excelConfirmImportPrompt(result.rows.length)),
                if (result.hasErrors) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr.messageRowsExcluded(
                        AppFormatters(
                          Localizations.localeOf(context),
                        ).formatNumber((result.rowErrors.length)),
                        (result.rowErrors
                                .map((e) => "${e.rowIndex}: ${e.errorMessage}")
                                .join('\n'))
                            .toString(),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (result.hasWarnings) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: result.warnings
                          .map(
                            (w) => Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Text(
                                '• $w',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppConstants.warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr.excelImportNowBtn),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _statusText = context.tr.messageSavingToFirebase);
        final outcome = await _firestoreService.importMakhdomeen(
          result.rows,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                _statusText = context.tr.messageSavingToFirebase564(
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber((done)),
                  AppFormatters(
                    Localizations.localeOf(context),
                  ).formatNumber((total)),
                );
              });
            }
          },
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                [
                  context.tr.excelImportSuccessMsg(outcome.imported),
                  if (result.rowErrors.isNotEmpty)
                    '${AppFormatters(Localizations.localeOf(context)).formatNumber(result.rowErrors.length)} ${context.tr.messageLocalRowsExcluded}: ${result.rowErrors.map((e) => "${e.rowIndex}: ${e.errorMessage}").join(', ')}',
                  if (outcome.rejected.isNotEmpty)
                    '${AppFormatters(Localizations.localeOf(context)).formatNumber(outcome.rejected.length)} ${context.tr.messageServerRowsRejected}: ${outcome.rejected.map((r) => "${r['rowIndex']}: ${context.tr.dataUnavailable}").join(', ')}',
                ].join('; '),
              ),
              backgroundColor:
                  outcome.rejected.isEmpty && result.rowErrors.isEmpty
                  ? AppConstants.successColor
                  : AppConstants.warningColor,
            ),
          );
        }
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

  Future<void> _handleExportAll() async {
    setState(() {
      _isLoading = true;
      _statusText = context.tr.messageExportingDataToExcel;
    });

    try {
      final labels = ExcelColumnLabels(Localizations.localeOf(context));
      await ExcelService.exportMakhdomeen(
        widget.currentMakhdomeen,
        labels: labels,
        title: context.tr.messageStudents726(
          (_getGradeLabel(widget.grade)).toString(),
        ),
      );
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? AppConstants.cardBorderDark
              : AppConstants.cardBorderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.fileExcel,
                  color: AppConstants.successColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr.excelSheetTitle} (${_getGradeLabel(widget.grade)})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr.messageBulkDataManagementAndSheetExports,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    _statusText ?? (context.tr.messageProcessing),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else ...[
            _buildActionTile(
              icon: Icons.download_for_offline_outlined,
              iconColor: AppConstants.primaryLight,
              title: context.tr.excelDownloadTemplate,
              subtitle: context.tr.excelDownloadTemplateDesc,
              isDark: isDark,
              onTap: _handleDownloadTemplate,
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.upload_file_outlined,
              iconColor: AppConstants.successColor,
              title: context.tr.excelImportMakhdomeen,
              subtitle:
                  '${context.tr.excelImportMakhdomeenDesc} (${_getGradeLabel(widget.grade)})',
              isDark: isDark,
              onTap: _handleUploadExcel,
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              icon: Icons.share_outlined,
              iconColor: AppConstants.accentGold,
              title:
                  '${context.tr.excelExportMakhdomeen} (${AppFormatters(Localizations.localeOf(context)).formatNumber(widget.currentMakhdomeen.length)})',
              subtitle: context.tr.excelExportMakhdomeenDesc,
              isDark: isDark,
              onTap: _handleExportAll,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppConstants.cardBorderDark
                : AppConstants.cardBorderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: isDark ? Colors.white38 : AppConstants.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

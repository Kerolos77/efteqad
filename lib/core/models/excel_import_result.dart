import '../models/makhdom_model.dart';

class ExcelRowError {
  final int rowIndex; // 1-based row number
  final String? studentName;
  final String errorMessage;

  const ExcelRowError({
    required this.rowIndex,
    this.studentName,
    required this.errorMessage,
  });

  @override
  String toString() => 'Row $rowIndex: $errorMessage (Student: $studentName)';
}

class ExcelImportResult {
  final List<MakhdomModel> rows;
  final List<ExcelRowError> rowErrors;
  final List<String> warnings;

  const ExcelImportResult({
    required this.rows,
    this.rowErrors = const [],
    this.warnings = const [],
  });

  int get totalProcessed => rows.length + rowErrors.length;
  bool get hasErrors => rowErrors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

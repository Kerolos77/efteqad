import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:efteqad/core/services/excel_service.dart';
import 'package:efteqad/core/services/import_coordinator.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/localization/excel_column_labels.dart';
import 'package:efteqad/features/admin/presentation/widgets/excel_actions_sheet.dart';
import 'mutation_dialogs_test.dart' show app;

void main() {
  testWidgets(
    'mixed import preview and completion show actual local source rows and date reasons',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(900, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final labels = ExcelColumnLabels(const Locale('en'));
      final excel = Excel.createExcel();
      final sheet = excel['Rows'];
      excel.delete('Sheet1');
      sheet.appendRow(labels.templateHeaders.map(TextCellValue.new).toList());
      sheet.appendRow([
        TextCellValue('Good'),
        TextCellValue('2008-02-10'),
        TextCellValue('01000000000'),
      ]);
      sheet.appendRow([
        TextCellValue('Bad birth'),
        TextCellValue('2008-02-31'),
        TextCellValue('01000000001'),
      ]);
      sheet.appendRow([
        TextCellValue('Bad tracking'),
        TextCellValue('2008-02-10'),
        TextCellValue('01000000002'),
        ...List.generate(10, (_) => TextCellValue('')),
        TextCellValue('invalid tracking'),
      ]);
      final result = ExcelService.parseMakhdomeen(
        excel.encode()!,
        grade: '1st',
      );
      expect(result.rows.length, 1);
      expect(result.rowErrors.map((r) => r.rowIndex), [3, 4]);
      final service = FirestoreService(
        importCoordinator: ImportCoordinator(
          userId: () => 'u',
          mutations: TrustedMutations(
            transport: (n, p) async => {'imported': 1, 'rejectedDetails': []},
          ),
        ),
      );
      await tester.pumpWidget(
        app(
          (ctx) => Material(
            child: ExcelActionsSheet(
              currentMakhdomeen: const [],
              grade: '1st',
              firestoreService: service,
              picker: (grade) async => result,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining('Import Makhdomeen from Excel').first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      for (final e in result.rowErrors) {
        expect(
          find.textContaining('${e.rowIndex}: ${e.errorMessage}'),
          findsOneWidget,
        );
      }
      await tester.tap(find.text('Import Now'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 local rows excluded'), findsOneWidget);
    },
  );
}

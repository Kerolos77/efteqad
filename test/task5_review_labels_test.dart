import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/domain_labels.dart';
import 'package:efteqad/core/localization/excel_column_labels.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/services/excel_service.dart';
import 'package:efteqad/core/services/firestore_service.dart';
import 'package:efteqad/core/services/trusted_mutations.dart';
import 'package:efteqad/features/admin/presentation/widgets/makhdom_card.dart';
import 'package:efteqad/features/admin/presentation/widgets/add_edit_makhdom_dialog.dart';
import 'task5_widgets_test.dart' show app;
import 'features/mutation_dialogs_test.dart' as dialogs;

void main() {
  final child = MakhdomModel(
    id: 'm',
    fullName: 'Child',
    phone: '01000000000',
    secondaryType: 'other',
    secondaryTypeCustomLabel: 'My school',
    createdAt: DateTime(2026, 1, 1),
  );
  test(
    'custom secondary labels survive other/custom/legacy aliases in both locales',
    () {
      for (final language in ['ar', 'en']) {
        final labels = DomainLabels(Locale(language));
        for (final type in [
          'other',
          'Other',
          'custom',
          'أخرى',
          'Legacy school',
        ]) {
          expect(
            labels.secondaryTypeName(type, customLabel: 'My school'),
            'My school',
          );
        }
        expect(
          labels.secondaryTypeName('general', customLabel: 'My school'),
          language == 'en' ? 'General secondary' : 'ثانوية عامة',
        );
      }
    },
  );
  test('actual exported workbook contains the custom school label', () {
    for (final language in ['ar', 'en']) {
      final labels = ExcelColumnLabels(Locale(language));
      final workbook = Excel.decodeBytes(
        ExcelService.exportMakhdomeenBytes([child], labels: labels),
      );
      expect(
        workbook.tables[labels.sheetName]!.rows[1][9]!.value.toString(),
        'My school',
      );
    }
  });
  testWidgets('actual child card displays custom school instead of Other', (
    t,
  ) async {
    await t.pumpWidget(app(MakhdomCard(makhdom: child)));
    expect(find.text('My school'), findsOneWidget);
  });
  for (final type in ['other', 'Other', 'custom', 'Legacy school']) {
    testWidgets(
      'unrelated profile edit preserves the $type label in actual trusted payload',
      (t) async {
        await t.binding.setSurfaceSize(const Size(1000, 1400));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final payloads = <Map<String, dynamic>>[];
        final service = FirestoreService(
          mutations: TrustedMutations(
            transport: (name, p) async {
              payloads.add(p);
              return {'makhdomId': 'm'};
            },
          ),
        );
        await t.pumpWidget(
          dialogs.app(
            (context) => AddEditMakhdomDialog(
              initialMakhdom: child.copyWith(secondaryType: type),
              khodamList: const [],
              firestoreService: service,
            ),
          ),
        );
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextFormField).first, 'Changed name');
        await t.ensureVisible(find.text('Save Changes'));
        await t.tap(find.text('Save Changes'));
        await t.pumpAndSettle();
        expect(payloads, isNotEmpty);
        final patch = payloads.single['patch'] as Map;
        expect(patch['fullName'], 'Changed name');
        expect(patch['secondaryTypeCustomLabel'], 'My school');
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('custom code exposes the existing custom label editor', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      dialogs.app(
        (context) => AddEditMakhdomDialog(
          initialMakhdom: child.copyWith(secondaryType: 'custom'),
          khodamList: const [],
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller?.text == 'My school',
      ),
      findsOneWidget,
    );
  });
}

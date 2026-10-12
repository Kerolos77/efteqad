import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/localization/excel_column_labels.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/services/excel_service.dart';

void main() {
  group('ExcelService Unit Tests', () {
    for (final entry in {
      'ar': 'ثانوية عامة',
      'en': 'General secondary',
    }.entries) {
      test(
        'generated secondary label in actual ${entry.key} workbook preserves user text and phones',
        () {
          final labels = ExcelColumnLabels(Locale(entry.key));
          final student = MakhdomModel(
            id: 's',
            fullName: 'اسم المستخدم',
            phone: '01000000000',
            grade: '1st',
            secondaryType: 'general',
            notes: 'ملاحظات الأسرة',
            createdAt: DateTime(2026),
          );
          final workbook = Excel.decodeBytes(
            ExcelService.exportMakhdomeenBytes([student], labels: labels),
          );
          final row = workbook.tables[labels.sheetName]!.rows[1];
          expect(row[0]!.value.toString(), 'اسم المستخدم');
          expect(row[3]!.value.toString(), '01000000000');
          expect(row[9]!.value.toString(), entry.value);
          expect(row[13]!.value.toString(), 'ملاحظات الأسرة');
          final template = Excel.decodeBytes(
            ExcelService.generateTemplateBytes(labels: labels),
          );
          expect(
            template.tables[labels.templateSheetName]!.rows[1][8]!.value
                .toString(),
            entry.value,
          );
          final imported = ExcelService.parseMakhdomeen(
            ExcelService.exportMakhdomeenBytes([student], labels: labels),
            grade: '1st',
            labels: labels,
          );
          expect(imported.rows.single.fullName, 'اسم المستخدم');
          expect(imported.rows.single.phone, '01000000000');
          expect(imported.rows.single.notes, 'ملاحظات الأسرة');
        },
      );
    }
    test(
      'overflow and malformed dates reject rows instead of normalizing or silently dropping dates',
      () {
        final excel = Excel.createExcel();
        final target = excel['Sheet1'];
        target.appendRow([
          TextCellValue('Full Name'),
          TextCellValue('Student Phone'),
          TextCellValue('Date of Birth'),
        ]);
        target.appendRow([
          TextCellValue('Bad February'),
          TextCellValue('01012345678'),
          TextCellValue('2008-02-31'),
        ]);
        target.appendRow([
          TextCellValue('Bad text'),
          TextCellValue('01012345679'),
          TextCellValue('unparseable'),
        ]);
        final result = ExcelService.parseMakhdomeen(
          excel.encode()!,
          grade: '1st',
        );
        expect(result.rows, isEmpty);
        expect(result.rowErrors.length, 2);
      },
    );

    test('throws ArgumentError if grade is empty', () {
      final excel = Excel.createExcel();
      final bytes = excel.encode()!;
      expect(
        () => ExcelService.parseMakhdomeen(bytes, grade: ''),
        throwsArgumentError,
      );
    });

    test(
      'parses Arabic headers and sets requested grade correctly (2nd grade)',
      () {
        final excel = Excel.createExcel();
        final sheet = excel['ورقة1'];
        excel.delete('Sheet1');

        // Add Arabic headers
        const headers = [
          'الاسم رباعي',
          'تاريخ الميلاد (YYYY-MM-DD)',
          'رقم تليفون المخدوم',
          'رقم تليفون الأب',
          'رقم تليفون الأم',
          'العنوان بالتفصيل',
          'المنطقة',
          'المدرسة',
          'نوع الثانوية',
          'أخوة رب (نعم/لا)',
        ];

        for (int i = 0; i < headers.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
              .value = TextCellValue(
            headers[i],
          );
        }

        // Add a valid student row
        final rowData = [
          'كيرلس ماجد عزيز',
          '2007-08-20',
          '01234567890',
          '01122334455',
          '01099887766',
          'شارع شبرا',
          'شبرا',
          'التوفيقية',
          'عام',
          'نعم',
        ];
        for (int i = 0; i < rowData.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
              .value = TextCellValue(
            rowData[i],
          );
        }

        final bytes = excel.encode()!;
        final result = ExcelService.parseMakhdomeen(
          bytes,
          grade: AppConstants.grade2nd,
        );

        expect(result.rows.length, 1);
        final student = result.rows.first;
        expect(student.fullName, 'كيرلس ماجد عزيز');
        expect(student.grade, AppConstants.grade2nd);
        expect(student.phone, '01234567890');
        expect(student.fatherPhone, '01122334455');
        expect(student.motherPhone, '01099887766');
        expect(student.address, 'شارع شبرا');
        expect(student.area, 'شبرا');
        expect(student.school, 'التوفيقية');
        expect(student.isBrethrenOfLord, isTrue);
        expect(student.birthDate, DateTime(2007, 8, 20));
        expect(result.rowErrors, isEmpty);
      },
    );

    test(
      'parses English headers and sets requested grade correctly (3rd grade)',
      () {
        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];

        const headers = [
          'Full Name',
          'Date of Birth',
          'Student Phone',
          'Father Phone',
          'Mother Phone',
          'Detailed Address',
          'Area',
          'School',
          'Secondary Type',
          'Brethren of Lord (Yes/No)',
        ];

        for (int i = 0; i < headers.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
              .value = TextCellValue(
            headers[i],
          );
        }

        final rowData = [
          'Mark Nader Fikry',
          '2006-11-12',
          '01012345678',
          '01287654321',
          '01133445566',
          'Abbassia',
          'Cairo',
          'St George',
          'General',
          'No',
        ];
        for (int i = 0; i < rowData.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
              .value = TextCellValue(
            rowData[i],
          );
        }

        final bytes = excel.encode()!;
        final result = ExcelService.parseMakhdomeen(
          bytes,
          grade: AppConstants.grade3rd,
        );

        expect(result.rows.length, 1);
        final student = result.rows.first;
        expect(student.fullName, 'Mark Nader Fikry');
        expect(student.grade, AppConstants.grade3rd);
        expect(student.phone, '01012345678');
        expect(student.isBrethrenOfLord, isFalse);
      },
    );

    test(
      'preserves and restores leading zero when phone is numeric IntCellValue',
      () {
        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = TextCellValue(
          'الاسم',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
            .value = TextCellValue(
          'رقم التليفون',
        );

        // Student row where Excel stripped the leading 0 into an integer: 1012345678
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
            .value = TextCellValue(
          'يوحنا عادل',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
            .value = IntCellValue(
          1012345678,
        ); // 10 digits starting with 10

        final bytes = excel.encode()!;
        final result = ExcelService.parseMakhdomeen(
          bytes,
          grade: AppConstants.grade1st,
        );

        expect(result.rows.length, 1);
        expect(result.rows.first.phone, '01012345678');
      },
    );

    test('detects sample template row and skips it with a warning', () {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'الاسم رباعي',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = TextCellValue(
        'رقم تليفون المخدوم',
      );

      // Sample template row
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'مينا سمير فايز حنا',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
          .value = TextCellValue(
        '01234567890',
      );

      // Real student row
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
          .value = TextCellValue(
        'بولا رأفت لمعي',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
          .value = TextCellValue(
        '01299998888',
      );

      final bytes = excel.encode()!;
      final result = ExcelService.parseMakhdomeen(
        bytes,
        grade: AppConstants.grade2nd,
      );

      expect(result.rows.length, 1);
      expect(result.rows.first.fullName, 'بولا رأفت لمعي');
      expect(result.warnings.length, 1);
      expect(result.warnings.first, contains('مينا سمير فايز حنا'));
    });

    test('warns about duplicate phone without dropping student (siblings)', () {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'الاسم',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = TextCellValue(
        'رقم التليفون',
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'الأخ الأول',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
          .value = TextCellValue(
        '01222222222',
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
          .value = TextCellValue(
        'الأخ الثاني',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
          .value = TextCellValue(
        '01222222222',
      );

      final bytes = excel.encode()!;
      final result = ExcelService.parseMakhdomeen(
        bytes,
        grade: AppConstants.grade1st,
      );

      expect(result.rows.length, 2);
      expect(result.warnings.any((w) => w.contains('تكرار')), isTrue);
    });

    test('records row error when student name or phone is missing', () {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'الاسم',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
          .value = TextCellValue(
        'رقم التليفون',
      );

      // Empty name
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        '',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
          .value = TextCellValue(
        '01234567890',
      );

      // Empty phone
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
          .value = TextCellValue(
        'طالب بدون هاتف',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
          .value = TextCellValue(
        '',
      );

      final bytes = excel.encode()!;
      final result = ExcelService.parseMakhdomeen(
        bytes,
        grade: AppConstants.grade1st,
      );

      expect(result.rows, isEmpty);
      expect(result.rowErrors.length, 2);
    });

    test('round-trip export and import preserves data accurately', () {
      final labels = ExcelColumnLabels(const Locale('ar'));

      final originalStudent = MakhdomModel(
        id: 'std-1',
        fullName: 'بيشوي عاطف نجيب',
        phone: '01098765432',
        birthDate: DateTime(2008, 3, 25),
        fatherPhone: '01211112222',
        motherPhone: '01144445555',
        address: '10 شارع النصر',
        area: 'المعادي',
        school: 'المعادي الثانوية',
        secondaryType: 'عام',
        grade: AppConstants.grade2nd,
        isBrethrenOfLord: true,
        notes: 'ملتزم في خدمة الشمامسة',
        createdAt: DateTime(2026, 1, 1),
      );

      final exportedBytes = ExcelService.exportMakhdomeenBytes([
        originalStudent,
      ], labels: labels);

      final importResult = ExcelService.parseMakhdomeen(
        exportedBytes,
        grade: AppConstants.grade2nd,
      );

      expect(importResult.rows.length, 1);
      final imported = importResult.rows.first;
      expect(imported.fullName, originalStudent.fullName);
      expect(imported.phone, originalStudent.phone);
      expect(imported.grade, AppConstants.grade2nd);
      expect(imported.birthDate, DateTime(2008, 3, 25));
      expect(imported.fatherPhone, originalStudent.fatherPhone);
      expect(imported.motherPhone, originalStudent.motherPhone);
      expect(imported.address, originalStudent.address);
      expect(imported.area, originalStudent.area);
      expect(imported.school, originalStudent.school);
      expect(imported.isBrethrenOfLord, isTrue);
      expect(imported.notes, originalStudent.notes);
    });

    test(
      'round-trip export and import in English preserves all columns and phone text integrity',
      () {
        final labels = ExcelColumnLabels(const Locale('en'));

        final originalStudent = MakhdomModel(
          id: 'std-2',
          fullName: 'David Nader Boutros',
          phone: '01200001111',
          birthDate: DateTime(2007, 11, 10),
          fatherPhone: '01022223333',
          motherPhone: '01155556666',
          address: '25 Church St',
          area: 'Heliopolis',
          school: 'St. George College',
          secondaryType: 'Languages',
          grade: AppConstants.grade3rd,
          isBrethrenOfLord: false,
          notes: 'Active deacon and servant',
          createdAt: DateTime(2026, 2, 1),
        );

        final exportedBytes = ExcelService.exportMakhdomeenBytes([
          originalStudent,
        ], labels: labels);

        final importResult = ExcelService.parseMakhdomeen(
          exportedBytes,
          grade: AppConstants.grade3rd,
        );

        expect(importResult.rows.length, 1);
        final imported = importResult.rows.first;
        expect(imported.fullName, originalStudent.fullName);
        expect(imported.phone, originalStudent.phone);
        expect(imported.grade, AppConstants.grade3rd);
        expect(imported.birthDate, DateTime(2007, 11, 10));
        expect(imported.fatherPhone, originalStudent.fatherPhone);
        expect(imported.motherPhone, originalStudent.motherPhone);
        expect(imported.address, originalStudent.address);
        expect(imported.area, originalStudent.area);
        expect(imported.school, originalStudent.school);
        expect(imported.isBrethrenOfLord, isFalse);
        expect(imported.notes, originalStudent.notes);
      },
    );

    group('Excel Fixtures Tests', () {
      const fixturesDir = 'test/fixtures/excel';

      test('parses arabic_valid.xlsx fixture correctly', () {
        final bytes = File('$fixturesDir/arabic_valid.xlsx').readAsBytesSync();
        final result = ExcelService.parseMakhdomeen(
          bytes,
          grade: AppConstants.grade2nd,
        );

        expect(result.rows.length, 1);
        expect(result.rows.first.fullName, 'فادي نبيل رشدي');
        expect(result.rows.first.phone, '01234567890');
        expect(result.rows.first.grade, AppConstants.grade2nd);
        expect(result.rowErrors, isEmpty);
      });

      test('parses english_valid.xlsx fixture correctly', () {
        final bytes = File('$fixturesDir/english_valid.xlsx').readAsBytesSync();
        final result = ExcelService.parseMakhdomeen(
          bytes,
          grade: AppConstants.grade3rd,
        );

        expect(result.rows.length, 1);
        expect(result.rows.first.fullName, 'John Mark Doe');
        expect(result.rows.first.phone, '01299998888');
        expect(result.rows.first.grade, AppConstants.grade3rd);
        expect(result.rowErrors, isEmpty);
      });

      test('throws exception on missing_column.xlsx fixture', () {
        final bytes = File(
          '$fixturesDir/missing_column.xlsx',
        ).readAsBytesSync();
        expect(
          () =>
              ExcelService.parseMakhdomeen(bytes, grade: AppConstants.grade1st),
          throwsException,
        );
      });

      test(
        'rejects invalid_date.xlsx rows without silently clearing dates',
        () {
          final bytes = File(
            '$fixturesDir/invalid_date.xlsx',
          ).readAsBytesSync();
          final result = ExcelService.parseMakhdomeen(
            bytes,
            grade: AppConstants.grade1st,
          );

          expect(result.rows, isEmpty);
          expect(result.rowErrors.single.studentName, 'رامي عادل');
          expect(
            result.rowErrors.single.errorMessage,
            contains('تاريخ ميلاد غير صالح'),
          );
        },
      );

      test(
        'sample_row.xlsx fixture skips sample row and preserves real row',
        () {
          final bytes = File('$fixturesDir/sample_row.xlsx').readAsBytesSync();
          final result = ExcelService.parseMakhdomeen(
            bytes,
            grade: AppConstants.grade1st,
          );

          expect(result.rows.length, 1);
          expect(result.rows.first.fullName, 'بولا وجدي سامي');
          expect(
            result.warnings.any((w) => w.contains('صف العينة التجريبي')),
            isTrue,
          );
        },
      );

      test(
        'multipart_sample.xlsx selects non-empty data sheet skipping instruction sheet',
        () {
          final bytes = File(
            '$fixturesDir/multipart_sample.xlsx',
          ).readAsBytesSync();
          final result = ExcelService.parseMakhdomeen(
            bytes,
            grade: AppConstants.grade2nd,
          );

          expect(result.rows.length, 1);
          expect(result.rows.first.fullName, 'يوسف رأفت كمال');
          expect(result.rows.first.phone, '01012341234');
        },
      );
    });
  });
}

import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final dir = Directory('test/fixtures/excel');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // 1. arabic_valid.xlsx
  {
    final excel = Excel.createExcel();
    final sheet = excel['ورقة1'];
    excel.delete('Sheet1');
    const headers = [
      'الاسم رباعي',
      'تاريخ الميلاد',
      'رقم تليفون المخدوم',
      'رقم تليفون الأب',
      'رقم تليفون الأم',
      'العنوان',
      'المنطقة',
      'المدرسة',
      'نوع الثانوية',
      'أخوة رب'
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }
    final row = [
      'فادي نبيل رشدي',
      '2008-01-15',
      '01234567890',
      '01011112222',
      '01133334444',
      'شارع مراد',
      'الجيزة',
      'السعيدية',
      'عام',
      'نعم'
    ];
    for (int i = 0; i < row.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
          TextCellValue(row[i]);
    }
    File('${dir.path}/arabic_valid.xlsx').writeAsBytesSync(excel.encode()!);
  }

  // 2. english_valid.xlsx
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    const headers = [
      'Full Name',
      'Date of Birth',
      'Student Phone',
      'Father Phone',
      'Mother Phone',
      'Address',
      'Area',
      'School',
      'Secondary Type',
      'Brethren'
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }
    final row = [
      'John Mark Doe',
      '2007-06-20',
      '01299998888',
      '01055556666',
      '',
      '10 Main St',
      'Downtown',
      'High School',
      'General',
      'No'
    ];
    for (int i = 0; i < row.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
          TextCellValue(row[i]);
    }
    File('${dir.path}/english_valid.xlsx').writeAsBytesSync(excel.encode()!);
  }

  // 3. missing_column.xlsx
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    const headers = ['العنوان', 'المنطقة', 'المدرسة'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
          TextCellValue('شارع مجهول');
    File('${dir.path}/missing_column.xlsx').writeAsBytesSync(excel.encode()!);
  }

  // 4. invalid_date.xlsx
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    const headers = ['الاسم', 'تاريخ الميلاد', 'تليفون الطالب'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }
    final row = ['رامي عادل', 'invalid-date-string', '01288887777'];
    for (int i = 0; i < row.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
          TextCellValue(row[i]);
    }
    File('${dir.path}/invalid_date.xlsx').writeAsBytesSync(excel.encode()!);
  }

  // 5. sample_row.xlsx
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    const headers = ['الاسم', 'تليفون المخدوم'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }
    final sampleRow = ['مينا سمير فايز حنا', '01234567890'];
    final realRow = ['بولا وجدي سامي', '01123456789'];
    for (int i = 0; i < 2; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
          TextCellValue(sampleRow[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2)).value =
          TextCellValue(realRow[i]);
    }
    File('${dir.path}/sample_row.xlsx').writeAsBytesSync(excel.encode()!);
  }

  // 6. multipart_sample.xlsx (First sheet empty/instructions, second sheet data)
  {
    final excel = Excel.createExcel();
    final introSheet = excel['تعليمات'];
    excel.delete('Sheet1');
    introSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('يرجى عدم تعديل الأعمدة');

    final dataSheet = excel['بيانات المخدومين'];
    const headers = ['الاسم رباعي', 'رقم تليفون المخدوم', 'المدرسة'];
    for (int i = 0; i < headers.length; i++) {
      dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }
    final row = ['يوسف رأفت كمال', '01012341234', 'القومية'];
    for (int i = 0; i < row.length; i++) {
      dataSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
          TextCellValue(row[i]);
    }
    File('${dir.path}/multipart_sample.xlsx').writeAsBytesSync(excel.encode()!);
  }
}

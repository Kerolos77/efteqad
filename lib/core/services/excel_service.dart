import '../errors/app_failure.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../localization/excel_column_labels.dart';
import '../localization/domain_labels.dart';
import '../models/excel_import_result.dart';
import '../models/makhdom_model.dart';

class ExcelService {
  static String _normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '');
  }

  /// 1. توليد مصفوفة بايتات نموذج Excel فارغ (Template) للمخدومين
  static Uint8List generateTemplateBytes({required ExcelColumnLabels labels}) {
    final excel = Excel.createExcel();
    final sheet = excel[labels.templateSheetName];
    excel.delete('Sheet1');

    final headers = labels.templateHeaders;

    // ترويسة الأعمدة
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // إضافة صف تجريبي توضيحي
    final sampleData = labels.isArabic
        ? [
            'مينا سمير فايز حنا',
            '2008-05-15',
            '01234567890',
            '01222222222',
            '01233333333',
            '15 شارع الكنيسة، الدور الثاني',
            'شبرا',
            'الشهيد يوسف الثانوية',
            labels.tr.secondaryGeneral,
            'https://maps.google.com/?q=30.0444,31.2357',
            labels.no,
            '',
            'محبوب ويشارك في الكشافة',
          ]
        : [
            'Mina Samir Fayez Hanna',
            '2008-05-15',
            '01234567890',
            '01222222222',
            '01233333333',
            '15 Church Street, 2nd floor',
            'Shubra',
            'St. Joseph High School',
            labels.tr.secondaryGeneral,
            'https://maps.google.com/?q=30.0444,31.2357',
            labels.no,
            '',
            'Active in scouts',
          ];

    for (int col = 0; col < sampleData.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
      );
      cell.value = TextCellValue(sampleData[col]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// مشاركة أو حفظ القالب
  static Future<String> generateAndShareTemplate({
    ExcelColumnLabels? labels,
  }) async {
    final effectiveLabels = labels ?? const ExcelColumnLabels(Locale('ar'));
    final bytes = generateTemplateBytes(labels: effectiveLabels);

    final tempDir = await getTemporaryDirectory();
    final fileName = effectiveLabels.tr.messageStudentsImportTemplateXlsx;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          effectiveLabels.tr.messageExcelTemplateForImportingStudentsInEfteqad,
    );

    return file.path;
  }

  /// 2. معالجة البايتات واستخراج المخدومين مع إلزامية السنة (Strict Grade Parsing)
  static ExcelImportResult parseMakhdomeen(
    List<int> bytes, {
    required String grade,
    ExcelColumnLabels? labels,
  }) {
    final tr = (labels ?? const ExcelColumnLabels(Locale('ar'))).tr;
    if (grade.trim().isEmpty) {
      throw ArgumentError('grade is required and cannot be empty.');
    }

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw AppFailure(
        code: 'excel-empty',
        message: 'Workbook contains no sheets.',
      );
    }

    String? chosenSheet;
    for (final name in excel.tables.keys) {
      final t = excel.tables[name];
      if (t != null && t.rows.isNotEmpty) {
        final firstRow = t.rows[0];
        final rowText = firstRow
            .map((c) => _normalize(c?.value?.toString() ?? ''))
            .join(' ');
        if (rowText.contains('اسم') ||
            rowText.contains('name') ||
            rowText.contains('تليفون') ||
            rowText.contains('هاتف') ||
            rowText.contains('phone')) {
          chosenSheet = name;
          break;
        }
      }
    }
    final sheetName =
        chosenSheet ??
        excel.tables.keys.firstWhere(
          (k) => excel.tables[k]?.rows.isNotEmpty == true,
          orElse: () => excel.tables.keys.first,
        );
    final table = excel.tables[sheetName];

    if (table == null || table.rows.isEmpty) {
      throw AppFailure(
        code: 'excel-empty',
        message: 'Workbook contains no rows.',
      );
    }

    final headerRow = table.rows[0];
    final normalizedHeaders = headerRow.map((cell) {
      final val = cell?.value?.toString() ?? '';
      return _normalize(val);
    }).toList();

    int findCol(List<String> keywords, {Set<int>? exclude}) {
      for (int i = 0; i < normalizedHeaders.length; i++) {
        if (exclude != null && exclude.contains(i)) continue;
        final h = normalizedHeaders[i];
        for (final rawKw in keywords) {
          final kw = _normalize(rawKw);
          if (h.contains(kw)) return i;
        }
      }
      return -1;
    }

    final usedIndices = <int>{};

    int registerCol(List<String> keywords) {
      final index = findCol(keywords, exclude: usedIndices);
      if (index >= 0) usedIndices.add(index);
      return index;
    }

    // مطابقة الحقول بالترتيب المناسب لتجنب الخلط بين تليفون الطالب وتليفون الأب/الأم
    final colFather = registerCol([
      'تليفون الاب',
      'هاتف الاب',
      'موبايل الاب',
      'الاب',
      'father',
    ]);
    final colMother = registerCol([
      'تليفون الام',
      'هاتف الام',
      'موبايل الام',
      'الام',
      'mother',
    ]);
    final colBirth = registerCol([
      'تاريخ الميلاد',
      'تاريخ ميلاد',
      'ميلاد',
      'birth',
      'dob',
    ]);
    final colName = registerCol([
      'الاسم رباعي',
      'اسم الطالب',
      'اسم المخدوم',
      'الاسم',
      'اسم',
      'name',
    ]);
    final colPhone = registerCol([
      'تليفون المخدوم',
      'هاتف المخدوم',
      'تليفون الطالب',
      'هاتف الطالب',
      'المخدوم',
      'طالب',
      'student phone',
      'phone',
      'mobile',
      'تليفون',
      'هاتف',
      'موبايل',
    ]);
    final colAddress = registerCol([
      'العنوان بالتفصيل',
      'العنوان',
      'عنوان',
      'address',
    ]);
    final colArea = registerCol([
      'المنطقة',
      'المنطقه',
      'منطقة',
      'منطقه',
      'area',
    ]);
    final colSchool = registerCol([
      'المدرسة',
      'المدرسه',
      'مدرسة',
      'مدرسه',
      'school',
    ]);
    final colSecondary = registerCol([
      'نوع الثانوية',
      'نوع الثانويه',
      'نوع التعليم',
      'ثانوية',
      'ثانويه',
      'secondary',
    ]);
    final colLocation = registerCol([
      'لوكيشن البيت',
      'لوكيشن',
      'خرائط جوجل',
      'خرائط',
      'location',
      'maps',
    ]);
    final colBrethren = registerCol([
      'اخوة رب',
      'اخوه رب',
      'اخوة الرب',
      'اخوه الرب',
      'اخوة',
      'اخوه',
      'رب',
      'brethren',
    ]);
    final colPhoto = registerCol([
      'رابط صورة',
      'رابط صوره',
      'صورة',
      'صوره',
      'photo',
      'image',
    ]);
    final colNotes = registerCol(['ملاحظات', 'ملاحظه', 'notes', 'comments']);

    final colTracking = registerCol([
      'تاريخ بدء التتبع',
      'تاريخ بداية التتبع',
      'tracking start',
      'tracking',
    ]);
    if (colName == -1 && colPhone == -1) {
      throw AppFailure(
        code: 'excel-columns',
        message: 'Required columns missing.',
      );
    }

    final List<MakhdomModel> rows = [];
    final List<ExcelRowError> rowErrors = [];
    final List<String> warnings = [];
    final Set<String> seenPhones = {};

    DateTime? parseDateCell(CellValue? value) {
      DateTime? checked(int year, int month, int day) {
        final date = DateTime(year, month, day);
        return date.year == year && date.month == month && date.day == day
            ? date
            : null;
      }

      if (value == null) return null;
      if (value is DateCellValue) {
        return checked(value.year, value.month, value.day);
      }
      if (value is DateTimeCellValue) {
        return checked(value.year, value.month, value.day);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      final iso = RegExp(
        r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:T.*)?$',
      ).firstMatch(text);
      if (iso != null) {
        if (text.contains('T') && DateTime.tryParse(text) == null) return null;
        return checked(
          int.parse(iso[1]!),
          int.parse(iso[2]!),
          int.parse(iso[3]!),
        );
      }
      final local = RegExp(
        r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
      ).firstMatch(text);
      if (local != null) {
        return checked(
          int.parse(local[3]!),
          int.parse(local[2]!),
          int.parse(local[1]!),
        );
      }
      return null;
    }

    String cleanPhone(CellValue? val) {
      if (val == null) return '';
      String s = '';
      if (val is IntCellValue) {
        s = val.value.toString();
      } else if (val is DoubleCellValue) {
        s = val.value.toInt().toString();
      } else {
        s = val.toString().trim();
      }

      // إزالة الفواصل والرموز غير الرقمية ما عدا + في البداية
      s = s.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (s.startsWith('+20')) {
        s = '0${s.substring(3)}';
      } else if (s.startsWith('20') && s.length == 12) {
        s = '0${s.substring(2)}';
      }

      // إذا كان الرقم 10 أرقام ويبدأ بـ 10, 11, 12, 15 (أرقام مصرية تم مسح الصفر الأول منها في إكسيل)
      if (s.length == 10 &&
          (s.startsWith('10') ||
              s.startsWith('11') ||
              s.startsWith('12') ||
              s.startsWith('15'))) {
        s = '0$s';
      }

      return s;
    }

    // المعالجة بدءاً من الصف الثاني (تخطي الترويسة)
    for (int i = 1; i < table.rows.length; i++) {
      final row = table.rows[i];
      if (row.isEmpty) continue;

      String getCellText(int colIndex) {
        if (colIndex < 0 || colIndex >= row.length) return '';
        final val = row[colIndex]?.value;
        if (val == null) return '';
        return val.toString().trim();
      }

      CellValue? getCellValue(int colIndex) {
        if (colIndex < 0 || colIndex >= row.length) return null;
        return row[colIndex]?.value;
      }

      final fullName = colName >= 0 ? getCellText(colName) : '';
      final rawPhone = colPhone >= 0 ? getCellValue(colPhone) : null;
      final phone = cleanPhone(rawPhone);

      // فحص إذا كان الصف فارغاً في كافة الخلايا
      final isEntireRowEmpty = row.every(
        (c) => c?.value == null || c!.value.toString().trim().isEmpty,
      );
      if (isEntireRowEmpty) {
        continue;
      }

      // كشف وتجاهل صف العينة التجريبي
      if (fullName.contains('مينا سمير فايز حنا') ||
          fullName.contains('Mina Samir Fayez Hanna')) {
        warnings.add(tr.excelSampleSkipped(fullName));
        continue;
      }

      // التحقق من الحقول الإجبارية
      if (fullName.isEmpty) {
        rowErrors.add(
          ExcelRowError(
            rowIndex: i + 1,
            studentName: null,
            errorMessage: tr.excelMissingName(i + 1),
          ),
        );
        continue;
      }

      if (phone.isEmpty) {
        rowErrors.add(
          ExcelRowError(
            rowIndex: i + 1,
            studentName: fullName,
            errorMessage: tr.excelMissingPhone(i + 1),
          ),
        );
        continue;
      }

      // التحقق من تكرار الهاتف في الملف وتنبيه المستخدم دون حذفه (لاشتراك الإخوة)
      if (seenPhones.contains(phone)) {
        warnings.add(tr.excelDuplicatePhone(phone, fullName));
      } else {
        seenPhones.add(phone);
      }

      final rawBirthStr = colBirth >= 0 ? getCellText(colBirth) : '';
      final birthDate = colBirth >= 0
          ? parseDateCell(getCellValue(colBirth))
          : null;
      if (rawBirthStr.isNotEmpty && birthDate == null) {
        rowErrors.add(
          ExcelRowError(
            rowIndex: i + 1,
            studentName: fullName,
            errorMessage: tr.excelInvalidBirthDate(rawBirthStr),
          ),
        );
        continue;
      }
      final trackingText = getCellText(colTracking);
      final trackingStartDate = colTracking >= 0
          ? parseDateCell(getCellValue(colTracking))
          : null;
      if (trackingText.isNotEmpty && trackingStartDate == null) {
        rowErrors.add(
          ExcelRowError(
            rowIndex: i + 1,
            studentName: fullName,
            errorMessage: tr.excelInvalidTrackingDate(trackingText),
          ),
        );
        continue;
      }
      final fatherPhone = colFather >= 0
          ? cleanPhone(getCellValue(colFather))
          : '';
      final motherPhone = colMother >= 0
          ? cleanPhone(getCellValue(colMother))
          : '';
      final address = colAddress >= 0 ? getCellText(colAddress) : '';
      final area = colArea >= 0 ? getCellText(colArea) : '';
      final school = colSchool >= 0 ? getCellText(colSchool) : '';
      final secondaryType = colSecondary >= 0 ? getCellText(colSecondary) : '';
      final locationUrl = colLocation >= 0 ? getCellText(colLocation) : '';
      final brethrenStr = colBrethren >= 0
          ? _normalize(getCellText(colBrethren))
          : '';
      final isBrethren =
          brethrenStr == 'نعم' ||
          brethrenStr == 'yes' ||
          brethrenStr == 'true' ||
          brethrenStr == '1' ||
          brethrenStr.startsWith('نعم');
      final photoUrl = colPhoto >= 0 ? getCellText(colPhoto) : '';
      final notes = colNotes >= 0 ? getCellText(colNotes) : '';

      rows.add(
        MakhdomModel(
          id: '', // يتم توليده في فايرستور
          fullName: fullName,
          phone: phone,
          birthDate: birthDate,
          trackingStartDate: trackingStartDate,
          fatherPhone: fatherPhone,
          motherPhone: motherPhone,
          address: address,
          area: area,
          school: school,
          secondaryType: secondaryType,
          grade: grade, // تثبيت السنة المحددة وعدم الرجوع لأولى افتراضياً
          homeLocationUrl: locationUrl.isNotEmpty ? locationUrl : null,
          isBrethrenOfLord: isBrethren,
          photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
          notes: notes.isNotEmpty ? notes : null,
          createdAt: DateTime.now(),
        ),
      );
    }

    return ExcelImportResult(
      rows: rows,
      rowErrors: rowErrors,
      warnings: warnings,
    );
  }

  /// اختيار ملف إكسيل ومعالجته
  static Future<ExcelImportResult> pickAndParseExcel({
    required String grade,
    ExcelColumnLabels? labels,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const ExcelImportResult(rows: []);
    }

    final Uint8List? bytes =
        result.files.first.bytes ??
        (result.files.first.path != null
            ? await File(result.files.first.path!).readAsBytes()
            : null);

    if (bytes == null) {
      throw AppFailure(
        code: 'excel-unreadable',
        message: 'Workbook bytes unavailable.',
      );
    }

    return parseMakhdomeen(bytes, grade: grade, labels: labels);
  }

  /// 3. توليد بايتات التصدير بصيغة Excel
  static Uint8List exportMakhdomeenBytes(
    List<MakhdomModel> list, {
    required ExcelColumnLabels labels,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel[labels.sheetName];
    excel.delete('Sheet1');

    final exportHeaders = labels.exportHeaders;

    // ترويسة الأعمدة
    for (int col = 0; col < exportHeaders.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(exportHeaders[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#059669'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // إدراج البيانات مع الحفاظ التام على أرقام الهواتف كنصوص
    for (int i = 0; i < list.length; i++) {
      final m = list[i];
      final rowData = [
        m.fullName,
        m.birthDate != null
            ? '${m.birthDate!.year}-${m.birthDate!.month.toString().padLeft(2, '0')}-${m.birthDate!.day.toString().padLeft(2, '0')}'
            : '',
        m.age != null ? '${m.age} ${labels.yearsOld}' : '',
        m.phone,
        m.fatherPhone,
        m.motherPhone,
        m.address,
        m.area,
        m.school,
        DomainLabels(labels.locale).secondaryTypeName(
          m.secondaryType,
          customLabel: m.secondaryTypeCustomLabel,
        ),
        m.homeLocationUrl ?? '',
        m.isBrethrenOfLord ? labels.yes : labels.no,
        m.photoUrl ?? '',
        m.notes ?? '',
        m.assignedKhademName ?? labels.unassigned,
        m.visitCount.toString(),
        m.lastVisitDate != null
            ? m.lastVisitDate!.toString().split(' ')[0]
            : labels.notVisited,
        m.trackingStartDate != null
            ? DateFormat('yyyy-MM-dd').format(m.trackingStartDate!)
            : '',
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rowData[col]);
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// تصدير قائمة المخدومين الحالية إلى ملف Excel ومشاركته
  static Future<void> exportMakhdomeen(
    List<MakhdomModel> list, {
    required ExcelColumnLabels labels,
    String? title,
  }) async {
    final bytes = exportMakhdomeenBytes(list, labels: labels);
    final fileName = title ?? labels.sheetName;

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: labels.tr.messageStudentsReportEfteqad);
  }
}

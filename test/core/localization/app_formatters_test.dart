import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/app_formatters.dart';

void main() {
  group('AppFormatters & Plurals Unit Tests', () {
    const arFormatters = AppFormatters(Locale('ar', 'EG'));
    const enFormatters = AppFormatters(Locale('en', 'US'));

    test('Arabic plural rules for visits (0, 1, 2, few, many, other)', () {
      expect(arFormatters.pluralizeVisits(0), 'لا توجد افتقادات');
      expect(arFormatters.pluralizeVisits(1), 'افتقاد واحد');
      expect(arFormatters.pluralizeVisits(2), 'افتقادان');
      expect(arFormatters.pluralizeVisits(3), '3 افتقادات');
      expect(arFormatters.pluralizeVisits(10), '10 افتقادات');
      expect(arFormatters.pluralizeVisits(11), '11 افتقاداً');
      expect(arFormatters.pluralizeVisits(100), '100 افتقاد');
    });

    test('English plural rules for visits (0, 1, many)', () {
      expect(enFormatters.pluralizeVisits(0), 'No visits');
      expect(enFormatters.pluralizeVisits(1), '1 visit');
      expect(enFormatters.pluralizeVisits(2), '2 visits');
      expect(enFormatters.pluralizeVisits(15), '15 visits');
    });

    test('Arabic plural rules for students and servants', () {
      expect(arFormatters.pluralizeStudents(0), 'لا يوجد مخدومين');
      expect(arFormatters.pluralizeStudents(1), 'مخدوم واحد');
      expect(arFormatters.pluralizeStudents(2), 'مخدومان');
      expect(arFormatters.pluralizeStudents(5), '5 مخدومين');
      expect(arFormatters.pluralizeStudents(20), '20 مخدوماً');

      expect(arFormatters.pluralizeServants(0), 'لا يوجد خدام');
      expect(arFormatters.pluralizeServants(1), 'خادم واحد');
      expect(arFormatters.pluralizeServants(2), 'خادمان');
      expect(arFormatters.pluralizeServants(4), '4 خدام');
      expect(arFormatters.pluralizeServants(12), '12 خادماً');
    });

    test('percentage formatting', () {
      expect(arFormatters.formatPercentage(85.34), '85.3%');
      expect(enFormatters.formatPercentage(100.0), '100.0%');
    });
  });
}

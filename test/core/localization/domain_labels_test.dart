import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/localization/domain_labels.dart';

void main() {
  test(
    'known legacy visits with emoji translate while custom text survives',
    () {
      const ar = DomainLabels(Locale('ar'));
      const en = DomainLabels(Locale('en'));
      for (final value in [
        'مكالمة تليفونية',
        '📞 مكالمة تليفونية',
        'Phone Call',
      ]) {
        expect(en.visitTypeName(value), 'Phone Call');
        expect(ar.visitTypeName(value), 'مكالمة هاتفية');
      }
      for (final value in [
        'لقاء في الكنيسة',
        '⛪ لقاء في الكنيسة',
        'Church Meeting',
      ]) {
        expect(en.visitTypeName(value), 'Church Meetup');
        expect(ar.visitTypeName(value), 'لقاء بالكنيسة');
      }
      expect(en.visitTypeName('زيارة مخصصة للعائلة'), 'زيارة مخصصة للعائلة');
    },
  );
  group('DomainLabels Unit Tests', () {
    test('maps grades correctly in Arabic and English', () {
      const arLabels = DomainLabels(Locale('ar', 'EG'));
      const enLabels = DomainLabels(Locale('en', 'US'));

      expect(arLabels.gradeName(AppConstants.grade1st), 'أولى ثانوي');
      expect(enLabels.gradeName(AppConstants.grade1st), '1st Secondary');

      expect(arLabels.gradeName(AppConstants.grade2nd), 'تانية ثانوي');
      expect(enLabels.gradeName(AppConstants.grade2nd), '2nd Secondary');

      expect(arLabels.gradeName(AppConstants.grade3rd), 'تالتة ثانوي');
      expect(enLabels.gradeName(AppConstants.grade3rd), '3rd Secondary');

      expect(arLabels.gradeShort(AppConstants.grade1st), '1ث');
      expect(enLabels.gradeShort(AppConstants.grade1st), '1st');
    });

    test('maps roles correctly in Arabic and English', () {
      const arLabels = DomainLabels(Locale('ar', 'EG'));
      const enLabels = DomainLabels(Locale('en', 'US'));

      expect(arLabels.roleName('stageAdmin'), 'أمين المرحلة');
      expect(enLabels.roleName('stageAdmin'), 'Stage Administrator');

      expect(arLabels.roleName('gradeAdmin'), 'أمين السنة');
      expect(enLabels.roleName('gradeAdmin'), 'Grade Administrator');

      expect(arLabels.roleName('servant'), 'خادم');
      expect(enLabels.roleName('servant'), 'Servant');
    });

    test('maps visit types accurately', () {
      const arLabels = DomainLabels(Locale('ar', 'EG'));
      const enLabels = DomainLabels(Locale('en', 'US'));

      expect(arLabels.visitTypeName('home'), 'زيارة منزلية');
      expect(enLabels.visitTypeName('home'), 'Home Visit');

      expect(arLabels.visitTypeName('phone'), 'مكالمة هاتفية');
      expect(enLabels.visitTypeName('phone'), 'Phone Call');

      expect(arLabels.visitTypeName('church'), 'لقاء بالكنيسة');
      expect(enLabels.visitTypeName('church'), 'Church Meetup');
    });
  });
}

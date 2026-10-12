import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/makhdom_model.dart';

void main() {
  group('MakhdomModel Tests', () {
    test('Correctly calculates age from birthDate', () {
      final now = DateTime.now();
      final birthDate16 = DateTime(now.year - 16, now.month, now.day);
      final makhdom = MakhdomModel(
        id: '1',
        fullName: 'بيشوي عادل',
        phone: '01234567890',
        school: 'الشهيد يوسف',
        birthDate: birthDate16,
        createdAt: now,
      );

      expect(makhdom.age, equals(16));
      expect(makhdom.school, equals('الشهيد يوسف'));
    });

    test('Serializes and deserializes birthDate and school accurately', () {
      final now = DateTime.now();
      final bDate = DateTime(2008, 5, 20);
      final original = MakhdomModel(
        id: 'test_doc_1',
        fullName: 'مينا كمال',
        phone: '01000000000',
        school: 'سان مارك',
        secondaryType: 'ثانوية عامة',
        birthDate: bDate,
        createdAt: now,
      );

      final map = original.toMap();
      expect(map['school'], equals('سان مارك'));
      expect(map['birthDate'], isA<Timestamp>());
      expect((map['birthDate'] as Timestamp).toDate().year, equals(2008));

      final restored = MakhdomModel.fromMap(map, 'test_doc_1');
      expect(restored.id, equals('test_doc_1'));
      expect(restored.fullName, equals('مينا كمال'));
      expect(restored.school, equals('سان مارك'));
      expect(restored.birthDate?.year, equals(2008));
      expect(restored.birthDate?.month, equals(5));
      expect(restored.birthDate?.day, equals(20));
    });

    test('copyWith handles birthDate and clearBirthDate with automatic grade-based age', () {
      final now = DateTime.now();
      final m1 = MakhdomModel(
        id: '1',
        fullName: 'جورج',
        phone: '011',
        grade: '1st',
        birthDate: DateTime(2007, 1, 1),
        createdAt: now,
      );

      final m2 = m1.copyWith(birthDate: DateTime(2009, 2, 2));
      expect(m2.birthDate?.year, equals(2009));

      final m3 = m2.copyWith(clearBirthDate: true);
      expect(m3.birthDate, isNull);
      expect(m3.isAgeEstimated, isTrue);
      // Automatically calculates 15 years old for 1st secondary!
      expect(m3.age, equals(15));
    });

    test('Automatically calculates age for high school grades when birthDate is omitted', () {
      final now = DateTime.now();
      final m1st = MakhdomModel(id: '1', fullName: 'أولى', phone: '01', grade: '1st', createdAt: now);
      final m2nd = MakhdomModel(id: '2', fullName: 'ثانية', phone: '02', grade: '2nd', createdAt: now);
      final m3rd = MakhdomModel(id: '3', fullName: 'ثالثة', phone: '03', grade: '3rd', createdAt: now);

      expect(m1st.age, equals(15));
      expect(m2nd.age, equals(16));
      expect(m3rd.age, equals(17));
    });
  });
}

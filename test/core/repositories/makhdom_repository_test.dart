import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/core/models/makhdom_profile_patch.dart';

void main() {
  group('MakhdomProfilePatch & Repository Logic Tests', () {
    test('MakhdomProfilePatch does not touch visitCount, lastVisitDate, or createdAt', () {
      const patch = MakhdomProfilePatch(
        phone: '01012345678',
        address: 'New Address',
      );

      final map = patch.toFirestoreMap();

      expect(map.containsKey('phone'), isTrue);
      expect(map['phone'], '01012345678');
      expect(map.containsKey('address'), isTrue);
      expect(map['address'], 'New Address');

      // Crucial: Must NEVER touch counters, visit dates, or createdAt
      expect(map.containsKey('visitCount'), isFalse);
      expect(map.containsKey('lastVisitDate'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('assignedKhademId'), isFalse);
    });

    test('MakhdomProfilePatch distinguishes unset fields from explicit clearing', () {
      // 1. Unset birthDate: does not appear in map
      const patchUnset = MakhdomProfilePatch(phone: '0123');
      expect(patchUnset.toFirestoreMap().containsKey('birthDate'), isFalse);

      // 2. Clear birthDate: produces FieldValue.delete()
      const patchClear = MakhdomProfilePatch(clearBirthDate: true);
      final clearMap = patchClear.toFirestoreMap();
      expect(clearMap.containsKey('birthDate'), isTrue);
      expect(clearMap['birthDate'], isA<FieldValue>());

      // 3. Set birthDate: produces Timestamp
      final testDate = DateTime(2008, 5, 12);
      final patchSet = MakhdomProfilePatch(birthDate: testDate);
      final setMap = patchSet.toFirestoreMap();
      expect(setMap.containsKey('birthDate'), isTrue);
      expect(setMap['birthDate'], isA<Timestamp>());
    });

    test('Concurrent visit count increment is preserved when applying patch', () {
      // Initial student record
      var student = MakhdomModel(
        id: 'student_123',
        fullName: 'Bishoy Samir',
        phone: '01000000000',
        grade: '1st',
        visitCount: 3,
        lastVisitDate: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      // In the background, a visit is recorded, incrementing visitCount from 3 to 4
      student = student.copyWith(
        visitCount: 4,
        lastVisitDate: DateTime(2026, 10, 8),
      );

      // Meanwhile, servant submits phone edit
      const patch = MakhdomProfilePatch(phone: '01099999999');
      final patchMap = patch.toFirestoreMap();

      // Simulating Firestore applying the patch map to the document data
      final updatedData = student.toMap();
      patchMap.forEach((key, value) {
        updatedData[key] = value;
      });

      final resultStudent = MakhdomModel.fromMap(updatedData, student.id);

      // Phone is updated
      expect(resultStudent.phone, '01099999999');
      // Concurrently incremented visitCount is preserved at 4, NOT overwritten back to 3!
      expect(resultStudent.visitCount, 4);
      expect(resultStudent.lastVisitDate, DateTime(2026, 10, 8));
    });

    test('Archive sets active=false without deleting record', () {
      const patch = MakhdomProfilePatch(active: false);
      final map = patch.toFirestoreMap();
      expect(map['active'], false);
    });

    test('clearPhotoUrl produces FieldValue.delete() to remove photo', () {
      const patchClearPhoto = MakhdomProfilePatch(clearPhotoUrl: true);
      final map = patchClearPhoto.toFirestoreMap();
      expect(map.containsKey('photoUrl'), isTrue);
      expect(map['photoUrl'], isA<FieldValue>());
    });

    test('docActive accurately reflects makhdom active state', () {
      final activeMakhdom = MakhdomModel(
        id: 'm1',
        fullName: 'Active',
        phone: '0100',
        active: true,
        createdAt: DateTime.now(),
      );
      final inactiveMakhdom = MakhdomModel(
        id: 'm2',
        fullName: 'Inactive',
        phone: '0100',
        active: false,
        createdAt: DateTime.now(),
      );

      expect(activeMakhdom.active, isTrue);
      expect(inactiveMakhdom.active, isFalse);
    });
  });
}


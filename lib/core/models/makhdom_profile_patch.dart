import 'package:cloud_firestore/cloud_firestore.dart';

class MakhdomProfilePatch {
  final String? fullName;
  final String? phone;
  final String? fatherPhone;
  final String? motherPhone;
  final String? address;
  final String? area;
  final String? school;
  final String? secondaryType;
  final String? secondaryTypeCustomLabel;
  final bool clearSecondaryTypeCustomLabel;
  final DateTime? trackingStartDate;
  final bool clearTrackingStartDate;
  final String? grade;
  final String? homeLocationUrl;
  final bool? isBrethrenOfLord;
  final String? photoUrl;
  final String? notes;
  final DateTime? birthDate;
  final bool clearBirthDate;
  final bool clearHomeLocationUrl;
  final bool clearNotes;
  final bool clearPhotoUrl;
  final bool? active;

  const MakhdomProfilePatch({
    this.fullName,
    this.phone,
    this.fatherPhone,
    this.motherPhone,
    this.address,
    this.area,
    this.school,
    this.secondaryType,
    this.secondaryTypeCustomLabel,
    this.clearSecondaryTypeCustomLabel = false,
    this.trackingStartDate,
    this.clearTrackingStartDate = false,
    this.grade,
    this.homeLocationUrl,
    this.isBrethrenOfLord,
    this.photoUrl,
    this.notes,
    this.birthDate,
    this.clearBirthDate = false,
    this.clearHomeLocationUrl = false,
    this.clearNotes = false,
    this.clearPhotoUrl = false,
    this.active,
  });

  Map<String, dynamic> toFirestoreMap() {
    final map = <String, dynamic>{};

    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (fatherPhone != null) map['fatherPhone'] = fatherPhone;
    if (motherPhone != null) map['motherPhone'] = motherPhone;
    if (address != null) map['address'] = address;
    if (area != null) map['area'] = area;
    if (school != null) map['school'] = school;
    if (secondaryType != null) map['secondaryType'] = secondaryType;
    if (clearSecondaryTypeCustomLabel || secondaryTypeCustomLabel != null) {
      map['secondaryTypeCustomLabel'] = clearSecondaryTypeCustomLabel
          ? null
          : secondaryTypeCustomLabel;
    }
    if (clearTrackingStartDate || trackingStartDate != null) {
      map['trackingStartDate'] = clearTrackingStartDate
          ? FieldValue.delete()
          : Timestamp.fromDate(trackingStartDate!);
    }
    if (grade != null) map['grade'] = grade;
    if (isBrethrenOfLord != null) map['isBrethrenOfLord'] = isBrethrenOfLord;
    if (clearPhotoUrl) {
      map['photoUrl'] = FieldValue.delete();
    } else if (photoUrl != null) {
      map['photoUrl'] = photoUrl;
    }
    if (active != null) map['active'] = active;

    if (clearBirthDate) {
      map['birthDate'] = FieldValue.delete();
    } else if (birthDate != null) {
      map['birthDate'] = Timestamp.fromDate(birthDate!);
    }

    if (clearHomeLocationUrl) {
      map['homeLocationUrl'] = FieldValue.delete();
    } else if (homeLocationUrl != null) {
      map['homeLocationUrl'] = homeLocationUrl;
    }

    if (clearNotes) {
      map['notes'] = FieldValue.delete();
    } else if (notes != null) {
      map['notes'] = notes;
    }

    return map;
  }
}

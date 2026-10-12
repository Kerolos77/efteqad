import 'package:efteqad/core/localization/app_localizations.dart';
import 'dart:ui';

class ExcelColumnLabels {
  final Locale locale;

  const ExcelColumnLabels(this.locale);

  GeneratedAppLocalizations get tr => lookupGeneratedAppLocalizations(locale);

  bool get isArabic => locale.languageCode == 'ar';

  String get fullName => tr.messageFullName;
  String get birthDate => tr.messageDateOfBirthYyyyMmDd;
  String get trackingStartDate => tr.messageTrackingStartDateYyyyMmDd;
  String get age => tr.messageAge;
  String get phone => tr.messageStudentPhone;
  String get fatherPhone => tr.messageFatherPhone;
  String get motherPhone => tr.messageMotherPhone;
  String get address => tr.messageDetailedAddress;
  String get area => tr.messageArea;
  String get school => tr.messageSchool;
  String get secondaryType => tr.messageSecondaryType;
  String get locationUrl => tr.messageHomeLocationMapsLink;
  String get brethrenOfLord => tr.messageBrethrenOfLordYesNo;
  String get photoUrl => tr.messageStudentPhotoUrl;
  String get notes => tr.messageNotes;
  String get assignedKhadem => tr.messageAssignedServant;
  String get visitCount => tr.messageVisitsCount;
  String get lastVisitDate => tr.messageLastVisitDate;

  String get yes => tr.messageYes;
  String get no => tr.messageNo;
  String get unassigned => tr.messageUnassigned;
  String get notVisited => tr.messageNotVisited;
  String get yearsOld => tr.messageYears;
  String get sheetName => tr.messageStudentsData;
  String get templateSheetName => tr.messageStudentsTemplate;

  List<String> get exportHeaders => [
    fullName,
    birthDate,
    age,
    phone,
    fatherPhone,
    motherPhone,
    address,
    area,
    school,
    secondaryType,
    locationUrl,
    brethrenOfLord,
    photoUrl,
    notes,
    assignedKhadem,
    visitCount,
    lastVisitDate,
    trackingStartDate,
  ];

  List<String> get templateHeaders => [
    fullName,
    birthDate,
    phone,
    fatherPhone,
    motherPhone,
    address,
    area,
    school,
    secondaryType,
    locationUrl,
    brethrenOfLord,
    photoUrl,
    notes,
    trackingStartDate,
  ];
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GeneratedAppLocalizationsEn extends GeneratedAppLocalizations {
  GeneratedAppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Al-Ra\'ey';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get currentGradeAdmin => 'Current grade administrator';

  @override
  String get visitReportLabel => 'Visit report';

  @override
  String get saveFailed => 'Could not save. Please try again.';

  @override
  String get syncPending => 'Saved on this device; waiting to sync';

  @override
  String get dataUnavailable => 'Could not load data';

  @override
  String get insufficientAttendanceData => 'Not enough attendance data';

  @override
  String visitsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString visits',
      one: '1 visit',
      zero: 'No visits',
    );
    return '$_temp0';
  }

  @override
  String studentsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString students',
      one: '1 student',
      zero: 'No students',
    );
    return '$_temp0';
  }

  @override
  String servantsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString servants',
      one: '1 servant',
      zero: 'No servants',
    );
    return '$_temp0';
  }

  @override
  String get appTagline => '«I am the Good Shepherd»';

  @override
  String get shepherdVerse => '«Feed my lambs.. Tend my sheep»';

  @override
  String get shepherdVerseShort =>
      '«Be diligent to know the state of your flocks»';

  @override
  String get shepherdVerseLong =>
      '«Be diligent to know the state of your flocks, and look well to your herds»';

  @override
  String get shepherdVerseGoodShepherd =>
      '«The good shepherd gives His life for the sheep»';

  @override
  String version(String ver) {
    return 'Version $ver';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get or => 'OR';

  @override
  String get all => 'All';

  @override
  String get search => 'Search...';

  @override
  String get notes => 'Notes';

  @override
  String get address => 'Address';

  @override
  String get area => 'Area';

  @override
  String get school => 'School';

  @override
  String get phone => 'Phone Number';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get adminSignInButton => 'Admin Sign In';

  @override
  String get adminSignInTitle => 'Admin Sign In';

  @override
  String get adminSignInSubtitle => 'Enter password for administrative access';

  @override
  String get adminEmailLabel => 'Admin Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterDashboardButton => 'Enter Dashboard';

  @override
  String get pleaseFillAllFields => 'Please fill in all fields';

  @override
  String get loginFailedCheckCredentials =>
      'Sign in failed: Check email and password';

  @override
  String loginError(String err) {
    return 'Sign in error: $err';
  }

  @override
  String get headServant => 'Head Servant';

  @override
  String get servant => 'Servant';

  @override
  String get adminRole => 'Admin';

  @override
  String get servantRole => 'Servant';

  @override
  String get mainDashboard => 'Main Dashboard';

  @override
  String get excelTools => 'Excel Tools (Import & Export)';

  @override
  String get myGroupAndVisits => 'My Group & Visits';

  @override
  String get servantProfile => 'Servant Profile';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmTitle => 'Sign Out Confirmation';

  @override
  String get signOutConfirmMsg =>
      'Are you sure you want to sign out of the application?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance & Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkModeDesc => 'Gentle on your eyes in low light';

  @override
  String get lightModeDesc => 'Crisp and comfortable daytime colors';

  @override
  String get languageSection => 'Language';

  @override
  String get arabicLang => 'العربية (Arabic)';

  @override
  String get arabicLangDesc => 'Default language with RTL';

  @override
  String get englishLang => 'English (الإنجليزية)';

  @override
  String get englishLangDesc => 'Switch interface language';

  @override
  String get aboutSection => 'About App & Service';

  @override
  String get aboutServiceDesc =>
      'Dedicated to the pastoral care and visitation of Pope Kyrillos VI class, empowering servants and head servant to minister to every soul with love and faithfulness.';

  @override
  String get accountSection => 'Account Management';

  @override
  String get signOutAccountDesc =>
      'Sign out of current account and return to login screen';

  @override
  String get deleteAccount => 'Permanently Delete Account';

  @override
  String get deleteAccountDesc =>
      'Delete servant profile and unassign all makhdomeen';

  @override
  String get deleteAccountWarningTitle => 'Delete Account Permanently';

  @override
  String get deleteAccountWarningPrompt =>
      'You are about to permanently delete your account from Efteqad system.';

  @override
  String get deleteAccountPoints =>
      '• All makhdomeen assigned to you will be released to unassigned pool for redistribution.\n• Your profile will be permanently deleted from database.\n• This action cannot be undone.';

  @override
  String get deleteAccountConfirmBtn => 'Yes, Delete Account';

  @override
  String get accountDeletedSuccess => 'Account deleted successfully';

  @override
  String deleteAccountFailed(String err) {
    return 'Failed to delete account: $err (Re-login may be required for security verification)';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get verifiedServantBadge => 'Verified Servant';

  @override
  String assignedCountInCare(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString makhdomeen in your care';
  }

  @override
  String get personalInfoSection => 'Personal Information';

  @override
  String get servantFullNameLabel => 'Servant Full Name';

  @override
  String get servantNameRequired => 'Please enter servant name';

  @override
  String get servantPhoneLabel => 'Mobile Phone Number';

  @override
  String get servantPhoneRequired => 'Please enter phone number';

  @override
  String get googleEmailLabel => 'Email (Google Account)';

  @override
  String get emailReadOnlyNote =>
      'Email is associated with your Google account and cannot be modified';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdatedSuccess =>
      'Your profile has been updated successfully!';

  @override
  String profileUpdateError(String err) {
    return 'Error updating profile: $err';
  }

  @override
  String servantGreeting(String name) {
    return 'Peace & Grace, Mr. $name';
  }

  @override
  String visitedRatio(int v, int t) {
    final intl.NumberFormat vNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String vString = vNumberFormat.format(v);
    final intl.NumberFormat tNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String tString = tNumberFormat.format(t);

    return 'Visited $vString of $tString makhdomeen';
  }

  @override
  String get searchMyMakhdomeen => 'Search makhdomeen by name or area...';

  @override
  String get filterVisited => 'Visited';

  @override
  String get filterUnvisited => 'Not Visited';

  @override
  String get filterBrethren => 'Brethren of the Lord';

  @override
  String get filterMyMakhdomeen => 'My Makhdomeen';

  @override
  String get noMakhdomeenAssignedTitle => 'No makhdomeen assigned to you yet';

  @override
  String get noMakhdomeenAssignedSubtitle =>
      'The head servant will distribute makhdomeen to you soon';

  @override
  String get logVisitTitle => 'Log New Visit';

  @override
  String get visitTypeLabel => 'Visit Type:';

  @override
  String get visitHome => '🏠 Home Visit';

  @override
  String get visitPhone => '📞 Phone Call';

  @override
  String get visitChurch => '⛪ Church Meeting';

  @override
  String get visitOther => '💬 Message / Other';

  @override
  String visitDateLabel(String date) {
    return 'Visit Date: $date';
  }

  @override
  String get visitNotesHint => 'Visit notes (optional)...';

  @override
  String get saveVisitBtn => 'Save Visit';

  @override
  String get visitSavedSuccess => 'Visit logged successfully! ✝️';

  @override
  String visitSaveError(String err) {
    return 'Error logging visit: $err';
  }

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String makhdomeenAndKhodamSummary(int m, int k) {
    final intl.NumberFormat mNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String mString = mNumberFormat.format(m);
    final intl.NumberFormat kNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kString = kNumberFormat.format(k);

    return '$mString Makhdomeen • $kString Servants';
  }

  @override
  String tabMakhdomeen(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Makhdomeen ($countString)';
  }

  @override
  String get tabAnalytics => 'Analytics & Insights';

  @override
  String tabKhodam(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Servants ($countString)';
  }

  @override
  String get searchAdminHint => 'Search by name, area, phone, or school...';

  @override
  String get filterUnassigned => 'Unassigned';

  @override
  String get deleteMakhdomTitle => 'Confirm Deletion';

  @override
  String deleteMakhdomPrompt(String name) {
    return 'Are you sure you want to permanently delete ($name)?';
  }

  @override
  String get makhdomDeletedSuccess => 'Makhdom deleted successfully';

  @override
  String makhdomUnassignedSuccess(String name) {
    return '($name) unassigned from servant';
  }

  @override
  String get noSearchResults => 'No results matching search or filter';

  @override
  String get assignSelectedMakhdomeen => 'Assign Selected';

  @override
  String get totalCountBadge => 'Total';

  @override
  String get addMakhdomBtn => 'Add Makhdom';

  @override
  String servantGroupHeader(String name) {
    return '$name\'s Group';
  }

  @override
  String get servantGroupSubheader =>
      'Tap to select and assign children to this servant';

  @override
  String get assignChildrenBtn => 'Assign Children';

  @override
  String get noMatchingMakhdomeenPrompt =>
      'Try changing search keywords or choosing another filter';

  @override
  String get brethrenBadge => 'Brethren of the Lord';

  @override
  String get unassignedBadge => 'Unassigned';

  @override
  String servantBadge(String name) {
    return 'Servant: $name';
  }

  @override
  String get notVisitedYetBadge => 'Not Visited Yet';

  @override
  String lastVisitBadge(String date, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Last: $date ($countString visits)';
  }

  @override
  String visitCountSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString visits',
      one: '1 visit',
      zero: 'No visits',
    );
    return '$_temp0';
  }

  @override
  String get details => 'Details';

  @override
  String get less => 'Less';

  @override
  String get callAction => 'Call';

  @override
  String get whatsappAction => 'WhatsApp';

  @override
  String get mapAction => 'Map';

  @override
  String get visitAction => 'Visit';

  @override
  String get familyDetails => 'Family Details';

  @override
  String get fatherPhoneLabel => 'Father Phone:';

  @override
  String get motherPhoneLabel => 'Mother Phone:';

  @override
  String get addressLabel => 'Address:';

  @override
  String get schoolLabel => 'School:';

  @override
  String get birthDateDetailLabel => 'Birth Date:';

  @override
  String ageYearsOld(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return '$ageString yrs';
  }

  @override
  String get notesLabel => 'Notes:';

  @override
  String get editDetailsAction => 'Edit Details';

  @override
  String get unassignServantAction => 'Unassign from Servant';

  @override
  String get deleteMakhdomAction => 'Delete Makhdom';

  @override
  String get historyAction => 'Visits & Attendance History';

  @override
  String get makhdomHistorySubtitle =>
      'Detailed pastoral visits, attendance & impact history';

  @override
  String get totalVisitsLabel => 'Total Visits';

  @override
  String get massAttendanceLabel => 'Mass Attendance';

  @override
  String get serviceAttendanceLabel => 'Service Attendance';

  @override
  String get visitSuccessRateLabel => 'Visit Impact';

  @override
  String get filterAllLabel => 'All';

  @override
  String get filterVisitsLabel => 'Visits Only';

  @override
  String get filterAttendanceLabel => 'Attendance Only';

  @override
  String get filterFruitfulLabel => 'Fruitful (Attended Next Friday) ✅';

  @override
  String get filterAbsencesLabel => 'Absences ❌';

  @override
  String get filterAllTime => 'All Time';

  @override
  String get filterLast30Days => 'Last 30 Days';

  @override
  String get filterLast90Days => 'Last 3 Months';

  @override
  String get filterCustomDate => 'Custom Period...';

  @override
  String get nextFridayTitle => 'Next Friday Following Visit';

  @override
  String get fruitfulVisitBadge => 'Fruitful Visit: Attended Mass & Service 🌟';

  @override
  String get attendedServiceOnlyBadge => 'Attended Service Only';

  @override
  String get attendedMassOnlyBadge => 'Attended Mass Only';

  @override
  String get missedNextFridayBadge => 'Missed Mass & Service ⚠️';

  @override
  String get pendingNextFridayBadge => 'Pending Upcoming Friday ⏳';

  @override
  String get noSessionsNextFridayBadge => 'No Sessions Recorded';

  @override
  String get fridayRecordTitle => 'Friday Attendance';

  @override
  String get attendedMassStatus => 'Mass: Present ✅';

  @override
  String get absentMassStatus => 'Mass: Absent ❌';

  @override
  String get attendedServiceStatus => 'Service: Present ✅';

  @override
  String get absentServiceStatus => 'Service: Absent ❌';

  @override
  String precededByVisitBadge(String type, String servant, String date) {
    return '✨ Preceded by visit ($type) by $servant on $date';
  }

  @override
  String get noRecordsFoundForFilter => 'No records matching selected filters';

  @override
  String get logNewVisitButton => 'Log New Visit';

  @override
  String get makhdomProfileDetails => 'Full Student Profile';

  @override
  String get makhdomProfileHide => 'Hide Details';

  @override
  String get makhdomProfileShow => 'Show All Details';

  @override
  String get academicAndAgeInfo => 'Education, Grade & Age';

  @override
  String get residenceAndAddressInfo => 'Residence, Address & Map';

  @override
  String get familyAndContactsInfo => 'Family Contacts & Phones';

  @override
  String get registrationDateLabel => 'Enrolled in Service:';

  @override
  String get estimatedAgeLabel => 'Estimated Age';

  @override
  String get realBirthDateLabel => 'Verified Birth Date';

  @override
  String get notSpecified => 'Not Specified';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get pastoralNotes => 'Pastoral Notes';

  @override
  String get fatherLabel => 'Father';

  @override
  String get motherLabel => 'Mother';

  @override
  String get studentPhoneLabel => 'Student Phone';

  @override
  String get copyPhoneSuccess => 'Phone copied successfully';

  @override
  String get copyAddressSuccess => 'Address copied successfully';

  @override
  String get editMakhdomTitle => 'Edit Makhdom';

  @override
  String get addMakhdomTitle => 'Add New Makhdom';

  @override
  String get personalAndContactSec => 'Personal & Contact Info';

  @override
  String get fullNameRequiredLabel => 'Full Name *';

  @override
  String get fullNameValidation => 'Please enter makhdom full name';

  @override
  String get makhdomPhoneLabel => 'Makhdom Phone';

  @override
  String get birthDateInputLabel => 'Date of Birth';

  @override
  String get selectBirthDateHint => 'Tap to select date of birth';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get saving => 'Saving...';

  @override
  String get fatherPhoneInputLabel => 'Father Phone';

  @override
  String get motherPhoneInputLabel => 'Mother Phone';

  @override
  String get residenceAndSchoolSec => 'Residence & Education';

  @override
  String get residentialAreaLabel => 'Residential Area';

  @override
  String get detailedAddressLabel => 'Detailed Address';

  @override
  String get schoolNameInputLabel => 'School Name';

  @override
  String get secondaryTypeInputLabel => 'Secondary Education Type';

  @override
  String get googleMapsUrlLabel => 'Home Location (Google Maps URL)';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Please enable it in settings';

  @override
  String get openSettings => 'Settings';

  @override
  String get locationFetchedSuccess => '✓ Location fetched successfully';

  @override
  String get locationError => 'Location error';

  @override
  String get serviceAndCareSec => 'Service, Assignment & Care';

  @override
  String get assignedServantSelectLabel => 'Assigned Servant';

  @override
  String get unassignedNoServantOption => 'Unassigned (No Servant)';

  @override
  String get brethrenSwitchLabel => 'Brethren of the Lord (Special Care)';

  @override
  String get brethrenSwitchSublabel =>
      'Flag for special love and pastoral priority';

  @override
  String get photoUrlOptionalLabel => 'Photo URL (optional)';

  @override
  String get additionalNotesOptionalLabel => 'Additional Notes (optional)';

  @override
  String get makhdomSavedSuccess => 'Makhdom saved successfully';

  @override
  String makhdomSaveError(String err) {
    return 'Error saving makhdom: $err';
  }

  @override
  String assignModalHeader(String name) {
    return 'Assign Makhdomeen to $name';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get searchByNameOrArea => 'Search by name or area...';

  @override
  String get conflictWarningTitle => 'Reassignment Alert';

  @override
  String get conflictWarningSubtitle =>
      'Some selected makhdomeen are already assigned to other servants. Transfer them?';

  @override
  String conflictWarningTransferCount(int count, String name) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'You are about to reassign $countString makhdomeen currently with other servants to ($name):';
  }

  @override
  String get confirmTransferQuestion =>
      'Are you sure you want to transfer them and update database?';

  @override
  String get otherServant => 'Other Servant';

  @override
  String resultsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Results: $countString';
  }

  @override
  String saveAssignmentsWithCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Save Assignments ($countString Makhdomeen)';
  }

  @override
  String get conflictTransferBtn => 'Yes, Confirm Transfer';

  @override
  String get conflictKeepBtn => 'Cancel';

  @override
  String get saveAssignmentsBtn => 'Save Assignments';

  @override
  String get assignmentsSavedSuccess =>
      'Assignments updated and saved successfully';

  @override
  String get excelSheetTitle => 'Excel Data Management';

  @override
  String get excelDownloadTemplate => 'Download Blank Excel Template';

  @override
  String get excelDownloadTemplateDesc =>
      'Ready template with pre-set columns to fill easily';

  @override
  String get excelImportMakhdomeen => 'Import Makhdomeen from Excel';

  @override
  String get excelImportMakhdomeenDesc =>
      'Parse Excel file and import makhdomeen to database';

  @override
  String get excelExportMakhdomeen => 'Export Makhdomeen to Excel';

  @override
  String get excelExportMakhdomeenDesc =>
      'Download spreadsheet with all makhdomeen and visits';

  @override
  String get excelConfirmImportTitle => 'Confirm Import';

  @override
  String excelConfirmImportPrompt(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Found ($countString) makhdomeen in sheet. Do you want to import them now?';
  }

  @override
  String get excelImportNowBtn => 'Import Now';

  @override
  String excelImportSuccessMsg(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Imported ($countString) makhdomeen successfully!';
  }

  @override
  String get excelEmptyOrCanceled =>
      'No makhdomeen found in file or selection cancelled';

  @override
  String get performanceAndCareIndicators => 'Performance & Care Indicators';

  @override
  String get liveFollowupAndRates =>
      'Live tracking & servant achievement rates';

  @override
  String get noAnalyticsData => 'Not enough data to display analytics';

  @override
  String get totalMakhdomeenStat => 'Total Makhdomeen';

  @override
  String get visitedAtLeastOnceStat => 'Visited';

  @override
  String get neverVisitedStat => 'Never Visited';

  @override
  String get brethrenStat => 'Brethren of the Lord';

  @override
  String get overallVisitRate => 'Overall Visit Rate';

  @override
  String get servantsLeaderboard => 'Servants Leaderboard';

  @override
  String get rankedByVisitRate => 'Servants ranked by group visit completion';

  @override
  String get urgentFollowupNeverVisited => 'Urgent Follow-up: Never Visited';

  @override
  String urgentCountNeedingVisit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString makhdomeen need urgent visit';
  }

  @override
  String get activeServantsStat => 'Active Servants';

  @override
  String get totalMakhdomeenTitle => 'Total Makhdomeen';

  @override
  String totalBoysAssignedSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString assigned';
  }

  @override
  String get visitationRateTitle => 'Visitation Rate';

  @override
  String visitedBoysCountSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString visited';
  }

  @override
  String get neverVisitedTitle => 'Never Visited';

  @override
  String get needsUrgentVisitSubtitle => 'Needs urgent visit';

  @override
  String get brethrenOfLordTitle => 'Brethren of the Lord';

  @override
  String get specialFollowupSubtitle => 'Special follow-up';

  @override
  String get visitationDistributionTitle => 'Visitation Distribution';

  @override
  String get servantsAchievementRatesTitle => 'Servants Achievement Rates';

  @override
  String get noKhodamYet => 'No servants registered yet';

  @override
  String unvisitedChildrenHeader(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Unvisited Students ($countString)';
  }

  @override
  String assignedToKhademLabel(String name) {
    return 'Assigned to: $name';
  }

  @override
  String get noKhodamRegisteredYet => 'No Servants Registered Yet';

  @override
  String get khodamAutoAppearNote =>
      'Servants will automatically appear here once they sign in with their Google account.';

  @override
  String get assignMakhdomeenActionBtn => 'Assign Makhdomeen';

  @override
  String assignedMakhdomeenCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString assigned';
  }

  @override
  String visitedOfTotalCount(int v, int t) {
    final intl.NumberFormat vNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String vString = vNumberFormat.format(v);
    final intl.NumberFormat tNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String tString = tNumberFormat.format(t);

    return '$vString of $tString visited';
  }

  @override
  String get grade1stName => '1st Secondary';

  @override
  String get grade2ndName => '2nd Secondary';

  @override
  String get grade3rdName => '3rd Secondary';

  @override
  String get allGrades => 'All Grades';

  @override
  String get gradeLabel => 'Grade';

  @override
  String get stageAdminTitle => 'Secondary Stage Head';

  @override
  String gradeAdminTitle(String grade) {
    return '$grade Head';
  }

  @override
  String get servantRoleLabel => 'Servant';

  @override
  String get pendingRoleLabel => 'Pending';

  @override
  String get pendingWelcome =>
      'Welcome Servant of Christ to Secondary Ministry ✝️';

  @override
  String get pendingStatusTitle => 'Awaiting Stage Assignment';

  @override
  String get pendingStatusDesc =>
      'Your account is registered. The Secondary Stage Head will assign you to your grade (1st, 2nd, or 3rd) soon.';

  @override
  String get completeProfilePrompt =>
      'Please confirm your information for easy identification:';

  @override
  String get updateAndSave => 'Update & Save';

  @override
  String get stageDashboardTitle => 'Secondary Stage Leadership';

  @override
  String get tabGradesAndServants => 'Servants & Grades';

  @override
  String get tabStageAnalytics => 'Stage Analytics';

  @override
  String get tabStageTasks => 'Stage Tasks';

  @override
  String get pendingServantsSection => 'New Servants Awaiting Assignment';

  @override
  String get gradeHeadsSection => 'Grade Heads';

  @override
  String get appointGradeHeadBtn => 'Appoint Head';

  @override
  String get changeGradeHeadBtn => 'Change Head';

  @override
  String get noGradeHeadAssigned => 'No head appointed yet';

  @override
  String get assignServantToGradePrompt => 'Assign Servant to Grade';

  @override
  String get selectGradePrompt => 'Select Grade:';

  @override
  String get servantAssignedSuccess => 'Servant assigned successfully!';

  @override
  String get gradeHeadUpdatedSuccess => 'Grade head appointed successfully!';

  @override
  String gradeDashboardTitle(String grade) {
    return '$grade Leadership';
  }

  @override
  String get tabGradeMakhdomeen => 'Makhdomeen';

  @override
  String get tabGradeAnalytics => 'Analytics';

  @override
  String get tabGradeServants => 'Grade Servants';

  @override
  String get tabGradeTasks => 'Grade Tasks';

  @override
  String get myTasksTitle => 'My Assigned Tasks';

  @override
  String get addTaskTitle => 'Add New Task';

  @override
  String get taskTitleLabel => 'Task Title *';

  @override
  String get taskTitleRequired => 'Please enter task title';

  @override
  String get taskDescLabel => 'Task Details (optional)';

  @override
  String get taskAssigneeLabel => 'Assigned Servant *';

  @override
  String get taskTypeLabel => 'Task Type';

  @override
  String get taskTypeGeneral => 'General Task';

  @override
  String get taskTypeAttendance => 'Attendance Tracking';

  @override
  String get taskTypeVisitation => 'Special Visit';

  @override
  String get taskCreatedSuccess => 'Task created successfully!';

  @override
  String get noTasksYet => 'No tasks assigned yet';

  @override
  String get completedTasksSection => 'Completed Tasks';

  @override
  String get pendingTasksSection => 'Pending Tasks';

  @override
  String get taskCompletedMsg => 'Task marked as completed! ✝️';

  @override
  String get taskReopenedMsg => 'Task reopened';

  @override
  String get reopenAttendance => 'Reopen attendance';

  @override
  String get reopenAttendanceAction => 'Reopen';

  @override
  String get reopenReason => 'Reason for reopening';

  @override
  String get deleteTaskPrompt => 'Delete this task permanently?';

  @override
  String get taskTypeAttendanceKhedma => 'Service Attendance';

  @override
  String get taskTypeAttendanceQoddas => 'Mass Attendance';

  @override
  String get takeAttendanceAction => 'Take Attendance 📋';

  @override
  String get attendanceScreenTitleService => 'Service Attendance';

  @override
  String get attendanceScreenTitleMass => 'Mass Attendance';

  @override
  String totalAttendedCount(int attended, int total) {
    final intl.NumberFormat attendedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attendedString = attendedNumberFormat.format(attended);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Attended: $attendedString / $totalString';
  }

  @override
  String get selectedAttendedHeader => 'Currently Attending';

  @override
  String get noAttendedYetHint => 'No students marked yet • Check below';

  @override
  String get searchAttendanceHint => 'Search by name or phone...';

  @override
  String get fridayOnlyWarning => 'Attendance is recorded on Fridays only';

  @override
  String get scheduleMassAttendanceBtn => 'Schedule Friday Mass Attendance ⛪';

  @override
  String get scheduleMassAttendanceTitle =>
      'Schedule Secondary Mass Attendance';

  @override
  String get scheduleMassAttendanceSubtitle =>
      'Choose the Friday date and servant to take attendance for all grades';

  @override
  String get notAuthorizedAttendance =>
      'Sorry, this task is assigned to another servant';

  @override
  String get autoSavedNotice => 'Auto-saved in real time';

  @override
  String get tabVisitsAnalytics => 'Visitation';

  @override
  String get tabAttendanceAnalytics => 'Attendance';

  @override
  String get tabSmartInsights => 'Insights & Alerts 🧠';

  @override
  String get absenceAlertsHeader => 'Consecutive Absence Alerts';

  @override
  String get absenceAlertsSubtitle =>
      'Students missing 2+ consecutive Fridays needing urgent attention';

  @override
  String missedFridaysCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Missed $countString consecutive Fridays';
  }

  @override
  String get criticalAbsenceBadge => 'Critical Dropout Risk 🚨';

  @override
  String get warningAbsenceBadge => 'Consecutive Absence Warning ⚠️';

  @override
  String get visitationImpactHeader => 'Visitation Impact on Attendance 💡';

  @override
  String get visitationImpactSubtitle =>
      'Attendance comparison between visited and unvisited students';

  @override
  String visitationImpactValue(double impact) {
    final intl.NumberFormat impactNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String impactString = impactNumberFormat.format(impact);

    return 'Attendance difference associated with visits: $impactString percentage points (does not establish causation)';
  }

  @override
  String get segmentConsistent => 'Consistent 🌟';

  @override
  String get segmentIrregular => 'Irregular 🔄';

  @override
  String get segmentAtRisk => 'At-Risk 🚨';

  @override
  String get servantMyAnalytics => 'My Analytics';

  @override
  String get servantGroupAttendanceRate => 'Group Attendance Rate';

  @override
  String get servantGroupVisitationProgress => 'Group Visitation Progress';

  @override
  String get urgentVisitationNeeded => 'Urgent Visit Needed';

  @override
  String get noAbsenceAlerts =>
      'No absence alerts currently • Everyone is consistent 🎉';

  @override
  String get allDetailsAction => 'View All Details';

  @override
  String get hideDetailsAction => 'Hide Details';

  @override
  String get assignedKhademLabel => 'Assigned Servant';

  @override
  String get generalNotesTitle => 'General Notes';

  @override
  String get overallAttendanceTitle => 'Overall Attendance';

  @override
  String get totalVisitsTitle => 'Total Visits';

  @override
  String get consecutiveAbsenceTitle => 'Consecutive Absences';

  @override
  String get massAndServiceRatesTitle => 'Mass & Service Rates';

  @override
  String get visitationCorrelationTitle => 'Visitation Correlation';

  @override
  String visitationCorrelationBody(String diff) {
    return 'Attendance difference following visits: $diff percentage points (an association, without implying causality).';
  }

  @override
  String get insufficientHistoryDataHint =>
      'No eligible completed service sessions in this period.';

  @override
  String daysSinceLastVisit(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days ago',
      one: '1 day ago',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get noVisitsYet => 'No visits yet';

  @override
  String get noConsecutiveAbsences => 'Consistent';

  @override
  String get criticalAbsenceAlert => 'Critical dropout risk 🚨';

  @override
  String get warningAbsenceAlert => 'Urgent visit needed ⚠️';

  @override
  String attendanceRatio(int attended, int eligible) {
    final intl.NumberFormat attendedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attendedString = attendedNumberFormat.format(attended);
    final intl.NumberFormat eligibleNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eligibleString = eligibleNumberFormat.format(eligible);

    return '$attendedString of $eligibleString sessions';
  }

  @override
  String massRateSubtitle(String rate) {
    return 'Mass attendance $rate%';
  }

  @override
  String get filterAllEvents => 'All Events';

  @override
  String get filterVisitsOnly => 'Visits Only';

  @override
  String get filterAttendanceOnly => 'Attendance Only';

  @override
  String get filterFruitfulOnly => 'Fruitful Only';

  @override
  String get filterAbsencesOnly => 'Absences Only';

  @override
  String get rangeAllTime => 'All Time';

  @override
  String get rangeLast30Days => 'Last 30 Days';

  @override
  String get rangeLast90Days => 'Last 90 Days';

  @override
  String get rangeCustom => 'Custom';

  @override
  String get pastoralVisitGeneral => 'Pastoral Visit';

  @override
  String get visitOutcomeBoth => 'Fruitful visit: Attended Mass & Service 🌟';

  @override
  String get visitOutcomeServiceOnly =>
      'Fruitful visit: Attended Service only ✅';

  @override
  String get visitOutcomeMassOnly => 'Fruitful visit: Attended Mass only ✅';

  @override
  String get visitOutcomeMissed =>
      'Missed Mass and Service ⚠️ (Needs follow-up)';

  @override
  String get visitOutcomePending => 'Awaiting next Friday ⏳';

  @override
  String get visitOutcomeNoData => 'No attendance recorded this Friday';

  @override
  String get visitingServantLabel => 'Visiting servant: ';

  @override
  String get assignedKhademPlaceholder => 'Assigned servant';

  @override
  String get visitReportNotesHeader => 'Visit Report & Servant Notes:';

  @override
  String get editNoteAction => 'Edit';

  @override
  String get addNoteAction => 'Add';

  @override
  String get visitNoDetailedNotes =>
      'Visit completed (No detailed notes recorded)';

  @override
  String visitOutcomeHeader(String date) {
    return 'Visit outcome (Friday $date):';
  }

  @override
  String get attendedMassAndService => 'Attended Mass & Service ✅';

  @override
  String get attendedPartial => 'Partial Attendance';

  @override
  String get absentBoth => 'Absent ❌';

  @override
  String get massLabel => 'Mass';

  @override
  String get serviceLabel => 'Service';

  @override
  String precededByVisitNote(String date) {
    return 'Preceded by a visit ($date)';
  }

  @override
  String get noEventsMatchingFilter => 'No events matching selected filters';

  @override
  String get editVisitNotesTitle => 'Edit Visit Notes';

  @override
  String get editVisitNotesSubtitle =>
      'Record visit discussion details to accurately follow up:';

  @override
  String get editVisitNotesHint => 'Details of the visit and discussion...';

  @override
  String get visitNotesUpdatedSuccess => 'Visit notes saved successfully';

  @override
  String errorUpdatingNotes(String err) {
    return 'Error updating notes: $err';
  }

  @override
  String get copyPhoneAction => 'Copy phone';

  @override
  String get retryAction => 'Retry';

  @override
  String get message1stSecondary => '1st Secondary';

  @override
  String get message2ndSecondary => '2nd Secondary';

  @override
  String get message3rdSecondary => '3rd Secondary';

  @override
  String get messageAllGrades => 'All Grades';

  @override
  String get messageSecondary => 'Secondary';

  @override
  String get message1st => '1st';

  @override
  String get message2nd => '2nd';

  @override
  String get message3rd => '3rd';

  @override
  String get messageStageAdministrator => 'Stage Administrator';

  @override
  String get messageGradeAdministrator => 'Grade Administrator';

  @override
  String get messageServant => 'Servant';

  @override
  String get messagePending => 'Pending';

  @override
  String get messageServiceAttendance => 'Service attendance';

  @override
  String get messageMassAttendance => 'Mass attendance';

  @override
  String get messageVisitationTask => 'Visitation Task';

  @override
  String get messageGeneralTask => 'General Task';

  @override
  String get messageHomeVisit => 'Home Visit';

  @override
  String get messagePhoneCall => 'Phone Call';

  @override
  String get messageChurchMeetup => 'Church Meetup';

  @override
  String get messageOther => 'Other';

  @override
  String get messageVisit => 'Visit';

  @override
  String get messageFullName => 'Full Name';

  @override
  String get messageDateOfBirthYyyyMmDd => 'Date of Birth (YYYY-MM-DD)';

  @override
  String get messageTrackingStartDateYyyyMmDd =>
      'Tracking Start Date (YYYY-MM-DD)';

  @override
  String get messageAge => 'Age';

  @override
  String get messageStudentPhone => 'Student Phone';

  @override
  String get messageFatherPhone => 'Father Phone';

  @override
  String get messageMotherPhone => 'Mother Phone';

  @override
  String get messageDetailedAddress => 'Detailed Address';

  @override
  String get messageArea => 'Area';

  @override
  String get messageSchool => 'School';

  @override
  String get messageSecondaryType => 'Secondary Type';

  @override
  String get messageHomeLocationMapsLink => 'Home Location (Maps Link)';

  @override
  String get messageBrethrenOfLordYesNo => 'Brethren of Lord (Yes/No)';

  @override
  String get messageStudentPhotoUrl => 'Student Photo URL';

  @override
  String get messageNotes => 'Notes';

  @override
  String get messageAssignedServant => 'Assigned Servant';

  @override
  String get messageVisitsCount => 'Visits Count';

  @override
  String get messageLastVisitDate => 'Last Visit Date';

  @override
  String get messageYes => 'Yes';

  @override
  String get messageNo => 'No';

  @override
  String get messageUnassigned => 'Unassigned';

  @override
  String get messageNotVisited => 'Not Visited';

  @override
  String get messageYears => 'years';

  @override
  String get messageStudentsData => 'Students_Data';

  @override
  String get messageStudentsTemplate => 'Students_Template';

  @override
  String get messageMainMenu => 'Main Menu';

  @override
  String get messageMakhdomeen => 'Makhdomeen';

  @override
  String get messageMyStudents => 'My Students';

  @override
  String get messageMyTasks => 'My Tasks';

  @override
  String get messageAccountDeletionInProgress => 'Account deletion in progress';

  @override
  String get messageUnableToLoadProfile => 'Unable to load profile';

  @override
  String get messageYourDeletionRequestIsSavedYouCan =>
      'Your deletion request is saved. You can exit and check its status later.';

  @override
  String get messageRetry => 'Retry';

  @override
  String get messageStudentsImportTemplateXlsx =>
      'Students_Import_Template.xlsx';

  @override
  String get messageExcelTemplateForImportingStudentsInEfteqad =>
      'Excel template for importing students in Efteqad';

  @override
  String get messageStudentsReportEfteqad => 'Students Report - Efteqad';

  @override
  String get messageFailedToLoadAttendanceSessions =>
      'Failed to load attendance sessions';

  @override
  String get messageLast90Days => 'Last 90 days';

  @override
  String get messageEn => 'en';

  @override
  String get messageSession => 'Session';

  @override
  String messageAbsenceAlert(String value0) {
    return '⚠️ Absence Alert: $value0';
  }

  @override
  String messageStudentMissedFridaysPleaseVisitSoon(String value0) {
    return 'Student missed $value0 Fridays. Please visit soon.';
  }

  @override
  String messageUrgentAlertSentTo(String value0) {
    return 'Urgent alert sent to ($value0)! 🔔';
  }

  @override
  String get messageNotify => 'Notify';

  @override
  String get messageS => 'S';

  @override
  String get messageUpdateRecordAndPersonalDetails =>
      'Update record and personal details';

  @override
  String get messageInsertNewMakhdomToCareRegistry =>
      'Insert new makhdom to care registry';

  @override
  String get messageFieldsAreLockedUntilConfirmationRetryTo =>
      'Fields are locked until confirmation. Retry to finish this request.';

  @override
  String messageErrorSavingAssignments(String value0) {
    return 'Error saving assignments: $value0';
  }

  @override
  String get messageAssignMakhdomeenToServant => 'Assign Makhdomeen to Servant';

  @override
  String get messageSelectionIsLockedUntilConfirmationRetryTo =>
      'Selection is locked until confirmation. Retry to finish this request.';

  @override
  String get messageGeneratingSharingTemplate =>
      'Generating & sharing template...';

  @override
  String messageError(String value0) {
    return 'Error: $value0';
  }

  @override
  String get messageReadingAndExtractingDataFromFile =>
      'Reading and extracting data from file...';

  @override
  String messageCouldNotImportAnyRowsDueTo(String value0) {
    return 'Could not import any rows due to errors:\n$value0';
  }

  @override
  String messageTargetGrade(String value0) {
    return 'Target Grade: $value0';
  }

  @override
  String messageRowsExcluded(String value0, String value1) {
    return '⚠️ $value0 rows excluded:\n$value1';
  }

  @override
  String get messageSavingToFirebase => 'Saving to Firebase...';

  @override
  String messageSavingToFirebase564(String value0, String value1) {
    return 'Saving to Firebase ($value0 / $value1)...';
  }

  @override
  String get messageLocalRowsExcluded => 'local rows excluded';

  @override
  String get messageServerRowsRejected => 'server rows rejected';

  @override
  String messageImportFailed(String value0) {
    return 'Import failed: $value0';
  }

  @override
  String get messageExportingDataToExcel => 'Exporting data to Excel...';

  @override
  String messageExportError(String value0) {
    return 'Export error: $value0';
  }

  @override
  String get messageBulkDataManagementAndSheetExports =>
      'Bulk data management and sheet exports';

  @override
  String get messageProcessing => 'Processing...';

  @override
  String get messageUnassignStudent => 'Unassign Student';

  @override
  String messageAreYouSureYouWantToUnassign(String value0) {
    return 'Are you sure you want to unassign $value0?';
  }

  @override
  String get messageUnassign => 'Unassign';

  @override
  String get messageM => 'M';

  @override
  String get messageServant580 => 'Servant';

  @override
  String get messageSelectAServantToAppointAsGrade =>
      'Select a servant to appoint as grade administrator';

  @override
  String messageNoServantsAssignedToYet(String value0) {
    return 'No servants assigned to $value0 yet';
  }

  @override
  String get messageAppointHead => 'Appoint Head';

  @override
  String get messageAssign => 'Assign';

  @override
  String get messageChangeHead => 'Change Head';

  @override
  String get messageUnspecified => 'Unspecified';

  @override
  String get messageThisSessionHasBeenFinalizedAndCannot =>
      'This session has been finalized and cannot be modified.';

  @override
  String messageErrorSavingAttendance(String value0) {
    return 'Error saving attendance: $value0';
  }

  @override
  String get messagePleaseWaitForPendingSavesToFinish =>
      'Please wait for pending saves to finish.';

  @override
  String get messageFinalizeAttendance => 'Finalize Attendance';

  @override
  String get messageAreYouSureYouWantToFinalize =>
      'Are you sure you want to finalize this attendance session? It cannot be modified afterwards.';

  @override
  String get messageCancel => 'Cancel';

  @override
  String get messageConfirmFinalization => 'Confirm Finalization';

  @override
  String get messageAttendanceFinalizedSuccessfully =>
      'Attendance finalized successfully.';

  @override
  String messageErrorFinalizingAttendance(String value0) {
    return 'Error finalizing attendance: $value0';
  }

  @override
  String get messageLoading => 'Loading...';

  @override
  String get messageFinalized => 'Finalized';

  @override
  String get messageSaving => 'Saving...';

  @override
  String get messageSaveError => 'Save Error';

  @override
  String messageCouldNotLoadRoster(String value0) {
    return 'Could not load roster: $value0';
  }

  @override
  String get messageAttendanceSessionIsFinalizedAndLockedRead =>
      'Attendance session is finalized and locked. Read-only.';

  @override
  String get messageSearchByName => 'Search by name';

  @override
  String get messageNotificationsCenter => 'Notifications Center';

  @override
  String get messageMarkAllRead => 'Mark all read';

  @override
  String get messageAccessDenied => 'Access Denied';

  @override
  String get messageYouDoNotHavePermissionToAccess =>
      'You do not have permission to access this page.';

  @override
  String get messagePageNotFound => 'Page Not Found';

  @override
  String get messageThePageYouAreLookingForDoes =>
      'The page you are looking for does not exist or has been moved.';

  @override
  String get messageAnErrorOccurred => 'An Error Occurred';

  @override
  String get messageGoHome => 'Go Home';

  @override
  String get messageNotifications => 'Notifications';

  @override
  String get messageNotificationsCenter616 => 'Notifications Center';

  @override
  String get messageJustNow => 'Just now';

  @override
  String messageMAgo(String value0) {
    return '${value0}m ago';
  }

  @override
  String messageHAgo(String value0) {
    return '${value0}h ago';
  }

  @override
  String messageDAgo(String value0) {
    return '${value0}d ago';
  }

  @override
  String get messageNoNotificationsYet => 'No notifications yet';

  @override
  String get messageTaskAssignmentsAndAlertsWillAppearHere =>
      'Task assignments and alerts will appear here';

  @override
  String messageCouldNotConfirmSaveRetryTheSame(String value0) {
    return 'Could not confirm save. Retry the same locked submission: $value0';
  }

  @override
  String messageCouldNotLoadLocalDraft(String value0) {
    return 'Could not load local draft: $value0';
  }

  @override
  String get messageLocalSubmissionLoadedConfirmationIsPending =>
      'Local submission loaded; confirmation is pending';

  @override
  String get messageFieldsAreLockedUntilConfirmationRetryTo631 =>
      'Fields are locked until confirmation. Retry to confirm this visit.';

  @override
  String messageAlertBoysNeedUrgentVisitRepeatedAbsence(String value0) {
    return 'Alert: $value0 boys need urgent visit (repeated absence)';
  }

  @override
  String get messageView => 'View 👈';

  @override
  String get messageAllSessions => 'All sessions';

  @override
  String get messageAllConsistent => 'All consistent 🎉';

  @override
  String get messageAbsenceAlert637 => 'Absence alert ⚠️';

  @override
  String get messageAttendance75 => 'Attendance ≥ 75%';

  @override
  String get messageVisited => 'Visited';

  @override
  String get messageUnvisited => 'Unvisited';

  @override
  String get messageAttendanceRatesCurrentlyEqual =>
      'Attendance rates currently equal';

  @override
  String get messageCall => 'Call';

  @override
  String get messageWhatsapp => 'WhatsApp';

  @override
  String get messageVisit644 => 'Visit';

  @override
  String get messageBehavioralSegmentation => 'Behavioral Segmentation';

  @override
  String get messageNoStudentsInThisSegment => 'No students in this segment';

  @override
  String messageVisits(String value0) {
    return 'Visits: $value0';
  }

  @override
  String get messageAbsenceAlert649 => 'Absence alert ⚠️';

  @override
  String get messageVisit650 => 'Visit';

  @override
  String get messageBehavioralSegmentation651 => 'Behavioral Segmentation';

  @override
  String messageOfVisited(String value0, String value1) {
    return '$value0 of $value1 visited';
  }

  @override
  String get messageConfirmPassword => 'Confirm Password';

  @override
  String get messageToDeleteYourAccountPleaseEnterYour =>
      'To delete your account, please enter your password to confirm.';

  @override
  String get messagePassword => 'Password';

  @override
  String get messageProceed => 'Proceed';

  @override
  String get messageStageAdministratorCannotDeleteAccountBeforeAppointing =>
      'Stage administrator cannot delete account before appointing a confirmed successor.';

  @override
  String get messageTaskDetails => 'Task Details';

  @override
  String get messageDescription => 'Description';

  @override
  String get messageAssignedServant661 => 'Assigned Servant';

  @override
  String get messageGrade => 'Grade';

  @override
  String get messageDueDate => 'Due Date';

  @override
  String get messageCreatedBy => 'Created By';

  @override
  String get messageOpenAttendanceSheet => 'Open Attendance Sheet';

  @override
  String get messageCompleted => 'Completed';

  @override
  String get messageMarkAsCompleted => 'Mark as Completed';

  @override
  String get messageAdmin => 'Admin';

  @override
  String get messageYouAreAssignedToTakeServiceAttendance =>
      'You are assigned to take Service attendance';

  @override
  String get messageYouAreAssignedToTakeMassAttendance =>
      'You are assigned to take Mass attendance';

  @override
  String messageAssignedYouANewTask(String value0) {
    return '$value0 assigned you a new task';
  }

  @override
  String messageNewTask(String value0) {
    return 'New Task: $value0 📋';
  }

  @override
  String get messageSubmissionIsLockedUntilConfirmationRetryTo =>
      'Submission is locked until confirmation. Retry to confirm this task.';

  @override
  String get messageYouAreOffline => 'You are offline';

  @override
  String get messageSyncingPendingChanges => 'Syncing pending changes...';

  @override
  String messageNoServantsAssignedToYetAssignServants(String value0) {
    return 'No servants assigned to $value0 yet.\nAssign servants before appointing a head.';
  }

  @override
  String get messageCurrentHead => 'Current head';

  @override
  String get messageAssignedSecondaryStageServants =>
      'Assigned secondary stage servants';

  @override
  String messageServants(String value0) {
    return '$value0 servants';
  }

  @override
  String get messageNoServantsAssignedToThisSectionYet =>
      'No servants assigned to this section yet';

  @override
  String get messageGradeHead => 'Grade head';

  @override
  String messageAssignedStudents(String value0, String value1) {
    return '$value0 • $value1 assigned students';
  }

  @override
  String get messageChangeGrade => 'Change grade';

  @override
  String get messageNewServant => 'New servant';

  @override
  String get messageNoAttendanceSessionsRecordedYet =>
      'No attendance sessions recorded yet';

  @override
  String get messageWeeklyStatisticsAppearHereAfterRecordingAttendance =>
      'Weekly statistics appear here after recording attendance';

  @override
  String get messageOverallAttendanceRate => 'Overall attendance rate';

  @override
  String get messageAverageOfRecordedSessions => 'Average of recorded sessions';

  @override
  String get messageAttendanceFridays => 'Attendance Fridays';

  @override
  String messageServiceMass(String value0, String value1) {
    return '$value0 service • $value1 Mass';
  }

  @override
  String get messageAverageSundaySchoolAttendance =>
      'Average Sunday school attendance';

  @override
  String get messageAverageMassAttendance => 'Average Mass attendance';

  @override
  String get messageWeeklyAttendanceRecentFridays =>
      'Weekly attendance (recent Fridays)';

  @override
  String get messageMass => 'Mass';

  @override
  String get messageService => 'Service';

  @override
  String messageStudents(String value0) {
    return '$value0 students';
  }

  @override
  String get messageVisitedStudents => 'Visited students';

  @override
  String messageStudents705(String value0) {
    return '$value0 students';
  }

  @override
  String get messageUnvisitedStudents => 'Unvisited students';

  @override
  String messageStudents708(String value0) {
    return '$value0 students';
  }

  @override
  String get messageStudentAttendanceGroups => 'Student attendance groups';

  @override
  String get messageNoStudentsInThisGroup => 'No students in this group';

  @override
  String messageAgeYears(String value0) {
    return 'Age: $value0 years';
  }

  @override
  String get messageCalculatedPrecisely => 'Calculated precisely ⚡';

  @override
  String get messageAutomatic => 'Automatic ⚡';

  @override
  String messageBirthDate(String value0, String value1, String value2) {
    return 'Birth date: $value0/$value1/$value2';
  }

  @override
  String messageAgeEstimatedFromSecondaryGrade(String value0) {
    return 'Age estimated from secondary grade ($value0)';
  }

  @override
  String get messageResetToAutomaticCalculation =>
      'Reset to automatic calculation';

  @override
  String messageYears721(String value0) {
    return '$value0 years';
  }

  @override
  String get messageChooseExactBirthDate => 'Choose exact birth date';

  @override
  String get messageExactDate => 'Exact date...';

  @override
  String get messageServantUnavailableInThisList =>
      'Servant unavailable in this list';

  @override
  String messageStudents726(String value0) {
    return 'Students_$value0';
  }

  @override
  String messageAgeEstimatedFrom(String value0, String value1) {
    return 'Age: $value0 (estimated from $value1)';
  }

  @override
  String messageAssignedStudents730(String value0, String value1) {
    return '$value0 • $value1 assigned students';
  }

  @override
  String get messageChangeGrade732 => 'Change grade';

  @override
  String get messageVisitNotesAndDiscussion => 'Visit notes and discussion';

  @override
  String get messageRecordVisitDiscussionMeetingDetailsOrPastoral =>
      'Record visit discussion, meeting details, or pastoral needs...';

  @override
  String messageOfStudents(String value0, String value1) {
    return '$value0 of $value1 students';
  }

  @override
  String messageAttendance(String value0) {
    return '$value0% attendance';
  }

  @override
  String get messageStageServant => 'Stage servant';

  @override
  String messageDate(String value0) {
    return 'Date: $value0';
  }

  @override
  String get messageSelectDueDateOptional => 'Select due date (optional)';

  @override
  String get messageFriday => 'Friday';

  @override
  String get failurePermissionDenied =>
      'You do not have permission to perform this action.';

  @override
  String get failureNetwork =>
      'Could not connect. Check your internet connection and try again.';

  @override
  String get failureNotFound =>
      'The requested item is unavailable or has been removed.';

  @override
  String get failureDecode => 'Could not read the data. Try loading it again.';

  @override
  String get failureAuthentication => 'Sign in again to verify your identity.';

  @override
  String get stageSuccessorRequired =>
      'An active, verified replacement stage administrator is required before deleting your account.';

  @override
  String get channelName => 'Visits and task notifications';

  @override
  String get channelDescription =>
      'Task, assignment, attendance and absence alerts';

  @override
  String get newNotification => 'New notification 🔔';

  @override
  String get secondaryGeneral => 'General secondary';

  @override
  String get secondaryTechnical => 'Technical / vocational';

  @override
  String get secondaryService => 'Services';

  @override
  String get secondaryCommercial => 'Commercial';

  @override
  String get secondaryOther => 'Other';

  @override
  String excelSampleSkipped(String name) {
    return 'Sample row ($name) was skipped.';
  }

  @override
  String excelMissingName(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Student name is empty in row $rowString';
  }

  @override
  String excelMissingPhone(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'Student phone is empty in row $rowString';
  }

  @override
  String excelDuplicatePhone(String phone, String name) {
    return 'Duplicate phone ($phone) for student ($name)';
  }

  @override
  String excelInvalidBirthDate(String value) {
    return 'Invalid birth date: $value';
  }

  @override
  String excelInvalidTrackingDate(String value) {
    return 'Invalid tracking start date: $value';
  }

  @override
  String get excelEmptyFailure => 'The workbook is empty or invalid.';

  @override
  String get excelColumnsFailure =>
      'Could not find name or phone columns in the header.';

  @override
  String get excelReadFailure => 'Could not read the workbook.';

  @override
  String get attendanceFinalizedFailure =>
      'This attendance session has been finalized.';

  @override
  String get pendingSavesFailure => 'Wait for pending saves to finish.';

  @override
  String birthDateCaption(String date) {
    return 'Birth date: $date';
  }

  @override
  String analyticsDateBounds(String from, String to) {
    return '$from – $to';
  }

  @override
  String trackingStartLabel(String date) {
    return 'Tracking starts: $date';
  }

  @override
  String trackingStartEstimatedLabel(String date) {
    return 'Estimated tracking start: $date';
  }

  @override
  String get trackingOriginUnknown =>
      'Tracking start unknown; attendance data is insufficient.';

  @override
  String get loadMore => 'Load more';

  @override
  String get secondaryTypeCustomLabel => 'Custom secondary type';

  @override
  String get legacyNotesLabel => 'Legacy notes';

  @override
  String get cachedDataHint =>
      'Showing cached data; awaiting server confirmation.';

  @override
  String get insufficientDataShort => 'Insufficient';

  @override
  String get followupNotificationTitle => 'Follow-up alert';

  @override
  String get followupNotificationBody =>
      'Open Efteqad to follow up with an assigned student.';
}

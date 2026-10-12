// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class GeneratedAppLocalizationsAr extends GeneratedAppLocalizations {
  GeneratedAppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'الراعي';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get back => 'تراجع';

  @override
  String get copyAddress => 'نسخ العنوان';

  @override
  String get currentGradeAdmin => 'أمين السنة الحالي';

  @override
  String get visitReportLabel => 'تقرير الافتقاد';

  @override
  String get saveFailed => 'تعذر الحفظ. حاول مرة أخرى.';

  @override
  String get syncPending => 'محفوظ على الجهاز، في انتظار المزامنة';

  @override
  String get dataUnavailable => 'تعذر تحميل البيانات';

  @override
  String get insufficientAttendanceData => 'بيانات الحضور غير كافية';

  @override
  String visitsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString افتقاد',
      many: '$countString افتقاداً',
      few: '$countString افتقادات',
      two: 'افتقادان',
      one: 'افتقاد واحد',
      zero: 'لا توجد افتقادات',
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
      other: '$countString مخدوم',
      many: '$countString مخدوماً',
      few: '$countString مخدومين',
      two: 'مخدومان',
      one: 'مخدوم واحد',
      zero: 'لا يوجد مخدومين',
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
      other: '$countString خادم',
      many: '$countString خادماً',
      few: '$countString خدام',
      two: 'خادمان',
      one: 'خادم واحد',
      zero: 'لا يوجد خدام',
    );
    return '$_temp0';
  }

  @override
  String get appTagline => '«أَنَا هُوَ الرَّاعِي الصَّالِحُ»';

  @override
  String get shepherdVerse => '«اِرْعَ خِرَافِي.. اِرْعَ غَنَمِي»';

  @override
  String get shepherdVerseShort => '«كُنْ عَارِفًا حَالَ غَنَمِكَ»';

  @override
  String get shepherdVerseLong =>
      '«كُنْ عَارِفًا حَالَ غَنَمِكَ، وَاجْعَلْ قَلْبَكَ إِلَى قُطْعَانِكَ»';

  @override
  String get shepherdVerseGoodShepherd =>
      '«الرَّاعِي الصَّالِحُ يَبْذِلُ نَفْسَهُ عَنِ الْخِرَافِ»';

  @override
  String version(String ver) {
    return 'الإصدار $ver';
  }

  @override
  String get confirm => 'تأكيد';

  @override
  String get or => 'أو';

  @override
  String get all => 'الكل';

  @override
  String get search => 'بحث...';

  @override
  String get notes => 'ملاحظات';

  @override
  String get address => 'العنوان';

  @override
  String get area => 'المنطقة';

  @override
  String get school => 'المدرسة';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get continueWithGoogle => 'متابعة باستخدام حساب Google';

  @override
  String get adminSignInButton => 'دخول أمين الخدمة (Admin)';

  @override
  String get adminSignInTitle => 'تسجيل دخول مسؤول الخدمة';

  @override
  String get adminSignInSubtitle => 'أدخل كلمة المرور الخاصة بحساب الإدارة';

  @override
  String get adminEmailLabel => 'بريد المسؤول (Admin Email)';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get enterDashboardButton => 'دخول لوحة التحكم';

  @override
  String get pleaseFillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get loginFailedCheckCredentials =>
      'فشل الدخول: تحقق من صحة الإيميل وكلمة المرور';

  @override
  String loginError(String err) {
    return 'حدث خطأ أثناء تسجيل الدخول: $err';
  }

  @override
  String get headServant => 'أمين الخدمة';

  @override
  String get servant => 'خادم';

  @override
  String get adminRole => 'مسؤول';

  @override
  String get servantRole => 'خادم';

  @override
  String get mainDashboard => 'لوحة التحكم الرئيسية';

  @override
  String get excelTools => 'أدوات الإكسيل (استيراد وتصدير)';

  @override
  String get myGroupAndVisits => 'مجموعتي والافتقاد';

  @override
  String get servantProfile => 'الملف الشخصي للخادم';

  @override
  String get generalSettings => 'الإعدادات العامة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج';

  @override
  String get signOutConfirmMsg =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearanceSection => 'المظهر والرؤية';

  @override
  String get darkMode => 'الوضع الليلي (Dark Mode)';

  @override
  String get lightMode => 'الوضع الفاتح (Light Mode)';

  @override
  String get darkModeDesc => 'راحة للعين في الإضاءة الخافتة';

  @override
  String get lightModeDesc => 'ألوان ناصعة ومريحة في النهار';

  @override
  String get languageSection => 'اللغة (Language)';

  @override
  String get arabicLang => 'العربية (Arabic)';

  @override
  String get arabicLangDesc => 'اللغة الافتراضية مع دعم RTL';

  @override
  String get englishLang => 'English (الإنجليزية)';

  @override
  String get englishLangDesc => 'التبديل إلى الواجهة الإنجليزية';

  @override
  String get aboutSection => 'عن التطبيق والخدمة';

  @override
  String get aboutServiceDesc =>
      'تطبيق مخصص لخدمة وافتقاد مخدومي فصل البابا كيرلس السادس، يساعد الخدام وأمين الخدمة على رعاية وتدوين افتقاد كل نفس بمحبة وأمانة.';

  @override
  String get accountSection => 'إدارة الحساب';

  @override
  String get signOutAccountDesc =>
      'الخروج من الحساب الحالي والعودة لشاشة الدخول';

  @override
  String get deleteAccount => 'حذف الحساب نهائياً';

  @override
  String get deleteAccountDesc =>
      'حذف بيانات الخادم وفك ارتباط الأولاد المسندين';

  @override
  String get deleteAccountWarningTitle => 'حذف الحساب نهائياً';

  @override
  String get deleteAccountWarningPrompt =>
      'أنت على وشك حذف حسابك نهائياً من نظام الافتقاد.';

  @override
  String get deleteAccountPoints =>
      '• سيتم فك ارتباط جميع الأولاد المسندين لك وإعادتهم للأولاد غير الموزعين ليتمكن أمين الخدمة من إعادة توزيعهم.\n• سيتم مسح بياناتك نهائياً من قاعدة البيانات.\n• هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get deleteAccountConfirmBtn => 'نعم، احذف الحساب';

  @override
  String get accountDeletedSuccess => 'تم حذف الحساب بنجاح';

  @override
  String deleteAccountFailed(String err) {
    return 'فشل حذف الحساب: $err (قد يتطلب إعادة تسجيل الدخول للتأكيد الأمني)';
  }

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get verifiedServantBadge => 'خادم معتمد';

  @override
  String assignedCountInCare(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مخدومين بمسؤوليتك';
  }

  @override
  String get personalInfoSection => 'البيانات الشخصية';

  @override
  String get servantFullNameLabel => 'اسم الخادم بالكامل';

  @override
  String get servantNameRequired => 'يرجى إدخال اسم الخادم';

  @override
  String get servantPhoneLabel => 'رقم الهاتف المحمول';

  @override
  String get servantPhoneRequired => 'يرجى إدخال رقم الهاتف';

  @override
  String get googleEmailLabel => 'البريد الإلكتروني (Google)';

  @override
  String get emailReadOnlyNote =>
      'البريد الإلكتروني مرتبط بحساب Google ولا يمكن تعديله';

  @override
  String get saveChanges => 'حفظ التعديلات';

  @override
  String get profileUpdatedSuccess => 'تم تحديث بياناتك بنجاح!';

  @override
  String profileUpdateError(String err) {
    return 'حدث خطأ أثناء حفظ البيانات: $err';
  }

  @override
  String servantGreeting(String name) {
    return 'سلام ونعمة يا أ/ $name';
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

    return 'تم افتقاد $vString من $tString مخدوم';
  }

  @override
  String get searchMyMakhdomeen => 'ابحث في مخدوميك بالاسم أو المنطقة...';

  @override
  String get filterVisited => 'تم افتقادهم';

  @override
  String get filterUnvisited => 'لم يفتقدوا بعد';

  @override
  String get filterBrethren => 'أخوة الرب';

  @override
  String get filterMyMakhdomeen => 'مخدوميني';

  @override
  String get noMakhdomeenAssignedTitle => 'لا يوجد مخدومين مسندين إليك حالياً';

  @override
  String get noMakhdomeenAssignedSubtitle =>
      'سيتولى أمين الخدمة توزيع الأولاد عليك قريباً';

  @override
  String get logVisitTitle => 'تسجيل افتقاد جديد';

  @override
  String get visitTypeLabel => 'نوع الافتقاد:';

  @override
  String get visitHome => '🏠 زيارة منزلية';

  @override
  String get visitPhone => '📞 مكالمة تليفونية';

  @override
  String get visitChurch => '⛪ لقاء في الكنيسة';

  @override
  String get visitOther => '💬 رسالة / أخرى';

  @override
  String visitDateLabel(String date) {
    return 'تاريخ الافتقاد: $date';
  }

  @override
  String get visitNotesHint => 'ملاحظات الافتقاد (اختياري)...';

  @override
  String get saveVisitBtn => 'حفظ الافتقاد';

  @override
  String get visitSavedSuccess => 'تم تسجيل الافتقاد بنجاح! ✝️';

  @override
  String visitSaveError(String err) {
    return 'خطأ أثناء تسجيل الافتقاد: $err';
  }

  @override
  String get adminDashboardTitle => 'لوحة تحكم المسؤول';

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

    return '$mString مخدوم • $kString خدام';
  }

  @override
  String tabMakhdomeen(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'المخدومين ($countString)';
  }

  @override
  String get tabAnalytics => 'التحليلات والمتابعة';

  @override
  String tabKhodam(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'الخدام ($countString)';
  }

  @override
  String get searchAdminHint => 'ابحث بالاسم، المنطقة، الهاتف، أو المدرسة...';

  @override
  String get filterUnassigned => 'بدون خادم';

  @override
  String get deleteMakhdomTitle => 'تأكيد الحذف';

  @override
  String deleteMakhdomPrompt(String name) {
    return 'هل أنت متأكد من حذف المخدوم ($name) نهائياً؟';
  }

  @override
  String get makhdomDeletedSuccess => 'تم حذف المخدوم بنجاح';

  @override
  String makhdomUnassignedSuccess(String name) {
    return 'تم إلغاء ربط ($name) بالخادم';
  }

  @override
  String get noSearchResults => 'لا توجد نتائج مطابقة للبحث أو الفلتر';

  @override
  String get assignSelectedMakhdomeen => 'إسناد المحددين';

  @override
  String get totalCountBadge => 'الإجمالي';

  @override
  String get addMakhdomBtn => 'إضافة مخدوم';

  @override
  String servantGroupHeader(String name) {
    return 'مجموعة: $name';
  }

  @override
  String get servantGroupSubheader =>
      'اضغط لتحديد وتوزيع الأولاد على هذا الخادم';

  @override
  String get assignChildrenBtn => 'توزيع أولاد';

  @override
  String get noMatchingMakhdomeenPrompt =>
      'جرّب تغيير كلمات البحث أو اختيار فلتر آخر';

  @override
  String get brethrenBadge => 'أخوة الرب';

  @override
  String get unassignedBadge => 'بدون خادم';

  @override
  String servantBadge(String name) {
    return 'خادم: $name';
  }

  @override
  String get notVisitedYetBadge => 'لم يتم افتقاده';

  @override
  String lastVisitBadge(String date, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'آخر افتقاد: $date ($countString مرات)';
  }

  @override
  String visitCountSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString افتقاد',
      many: '$countString افتقاداً',
      few: '$countString افتقادات',
      two: 'افتقادان',
      one: 'افتقاد واحد',
      zero: 'لا توجد افتقادات',
    );
    return '$_temp0';
  }

  @override
  String get details => 'تفاصيل';

  @override
  String get less => 'أقل';

  @override
  String get callAction => 'اتصال';

  @override
  String get whatsappAction => 'واتساب';

  @override
  String get mapAction => 'الخريطة';

  @override
  String get visitAction => 'افتقاد';

  @override
  String get familyDetails => 'تفاصيل الأسرة';

  @override
  String get fatherPhoneLabel => 'تليفون الأب:';

  @override
  String get motherPhoneLabel => 'تليفون الأم:';

  @override
  String get addressLabel => 'العنوان:';

  @override
  String get schoolLabel => 'المدرسة:';

  @override
  String get birthDateDetailLabel => 'تاريخ الميلاد:';

  @override
  String ageYearsOld(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return '$ageString سنة';
  }

  @override
  String get notesLabel => 'ملاحظات:';

  @override
  String get editDetailsAction => 'تعديل البيانات';

  @override
  String get unassignServantAction => 'إلغاء الإسناد من الخادم';

  @override
  String get deleteMakhdomAction => 'حذف المخدوم نهائياً';

  @override
  String get historyAction => 'سجل الافتقاد والحضور';

  @override
  String get makhdomHistorySubtitle =>
      'سجل تفصيلي للافتقادات والحضور وأثر الافتقاد على الحضور';

  @override
  String get totalVisitsLabel => 'إجمالي الافتقادات';

  @override
  String get massAttendanceLabel => 'حضور القداس';

  @override
  String get serviceAttendanceLabel => 'حضور الخدمة';

  @override
  String get visitSuccessRateLabel => 'أثر الافتقاد';

  @override
  String get filterAllLabel => 'الكل';

  @override
  String get filterVisitsLabel => 'الافتقادات فقط';

  @override
  String get filterAttendanceLabel => 'الحضور والغياب';

  @override
  String get filterFruitfulLabel => 'أثمرت بحضور الجمعة ✅';

  @override
  String get filterAbsencesLabel => 'جمعات الغياب ❌';

  @override
  String get filterAllTime => 'كل الأوقات';

  @override
  String get filterLast30Days => 'آخر 30 يوم';

  @override
  String get filterLast90Days => 'آخر 3 أشهر';

  @override
  String get filterCustomDate => 'تحديد فترة...';

  @override
  String get nextFridayTitle => 'الجمعة التالية للافتقاد';

  @override
  String get fruitfulVisitBadge => 'أثمر الافتقاد: حضر القداس والخدمة 🌟';

  @override
  String get attendedServiceOnlyBadge => 'حضر الخدمة فقط';

  @override
  String get attendedMassOnlyBadge => 'حضر القداس فقط';

  @override
  String get missedNextFridayBadge => 'غائب عن القداس والخدمة ⚠️';

  @override
  String get pendingNextFridayBadge => 'في انتظار الجمعة القادمة ⏳';

  @override
  String get noSessionsNextFridayBadge => 'لم تسجل جلسات لهذه الجمعة';

  @override
  String get fridayRecordTitle => 'يوم الجمعة';

  @override
  String get attendedMassStatus => 'القداس: حاضر ✅';

  @override
  String get absentMassStatus => 'القداس: غائب ❌';

  @override
  String get attendedServiceStatus => 'الخدمة: حاضر ✅';

  @override
  String get absentServiceStatus => 'الخدمة: غائب ❌';

  @override
  String precededByVisitBadge(String type, String servant, String date) {
    return '✨ سُبق بافتقاد ($type) بواسطة $servant في $date';
  }

  @override
  String get noRecordsFoundForFilter => 'لا توجد سجلات مطابقة للفلاتر المحددة';

  @override
  String get logNewVisitButton => 'تسجيل افتقاد جديد';

  @override
  String get makhdomProfileDetails => 'بيانات المخدوم الكاملة';

  @override
  String get makhdomProfileHide => 'إخفاء التفاصيل';

  @override
  String get makhdomProfileShow => 'عرض كافة البيانات';

  @override
  String get academicAndAgeInfo => 'الدراسة والمرحلة والسن';

  @override
  String get residenceAndAddressInfo => 'السكن والعنوان واللوكيشن';

  @override
  String get familyAndContactsInfo => 'بيانات التواصل والعائلة';

  @override
  String get registrationDateLabel => 'تاريخ القيد بالخدمة:';

  @override
  String get estimatedAgeLabel => 'عمر تقديري';

  @override
  String get realBirthDateLabel => 'تاريخ ميلاد موثق';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get openInGoogleMaps => 'فتح في خرائط Google';

  @override
  String get pastoralNotes => 'ملاحظات رعوية خاصة';

  @override
  String get fatherLabel => 'والد المخدوم (الأب)';

  @override
  String get motherLabel => 'والدة المخدوم (الأم)';

  @override
  String get studentPhoneLabel => 'هاتف المخدوم';

  @override
  String get copyPhoneSuccess => 'تم نسخ الرقم بنجاح';

  @override
  String get copyAddressSuccess => 'تم نسخ العنوان بنجاح';

  @override
  String get editMakhdomTitle => 'تعديل بيانات مخدوم';

  @override
  String get addMakhdomTitle => 'إضافة مخدوم جديد';

  @override
  String get personalAndContactSec => 'البيانات الشخصية والاتصال';

  @override
  String get fullNameRequiredLabel => 'الاسم بالكامل *';

  @override
  String get fullNameValidation => 'يرجى إدخال اسم المخدوم بالكامل';

  @override
  String get makhdomPhoneLabel => 'رقم الهاتف (المخدوم)';

  @override
  String get birthDateInputLabel => 'تاريخ الميلاد';

  @override
  String get selectBirthDateHint => 'اضغط لاختيار تاريخ الميلاد';

  @override
  String get phoneRequired => 'رقم التليفون مطلوب';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get fatherPhoneInputLabel => 'تليفون الأب';

  @override
  String get motherPhoneInputLabel => 'تليفون الأم';

  @override
  String get residenceAndSchoolSec => 'السكن والتعليم';

  @override
  String get residentialAreaLabel => 'المنطقة السكنية';

  @override
  String get detailedAddressLabel => 'العنوان بالتفصيل';

  @override
  String get schoolNameInputLabel => 'اسم المدرسة';

  @override
  String get secondaryTypeInputLabel => 'نوع الثانوية';

  @override
  String get googleMapsUrlLabel => 'رابط موقع المنزل (Google Maps)';

  @override
  String get useCurrentLocation => 'استخدم موقعي الحالي';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع';

  @override
  String get locationPermissionPermanentlyDenied =>
      'إذن الموقع مرفوض دائماً، يرجى تفعيله من الإعدادات';

  @override
  String get openSettings => 'الإعدادات';

  @override
  String get locationFetchedSuccess => '✓ تم جلب الموقع بنجاح';

  @override
  String get locationError => 'خطأ في جلب الموقع';

  @override
  String get serviceAndCareSec => 'الخدمة والتوزيع والرعاية';

  @override
  String get assignedServantSelectLabel => 'الخادم المسؤول عن الافتقاد';

  @override
  String get unassignedNoServantOption => 'بدون خادم (غير موزع)';

  @override
  String get brethrenSwitchLabel => 'أخوة الرب (رعاية خاصة ومحبة)';

  @override
  String get brethrenSwitchSublabel =>
      'تمييز الحالة لتوفير اهتمام ورعاية استثنائية';

  @override
  String get photoUrlOptionalLabel => 'رابط الصورة الشخصية (اختياري)';

  @override
  String get additionalNotesOptionalLabel => 'ملاحظات إضافية (اختياري)';

  @override
  String get makhdomSavedSuccess => 'تم حفظ بيانات المخدوم بنجاح';

  @override
  String makhdomSaveError(String err) {
    return 'خطأ أثناء الحفظ: $err';
  }

  @override
  String assignModalHeader(String name) {
    return 'توزيع المخدومين على $name';
  }

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء التحديد';

  @override
  String get searchByNameOrArea => 'ابحث بالاسم أو المنطقة...';

  @override
  String get conflictWarningTitle => 'تنبيه نقل مخدومين';

  @override
  String get conflictWarningSubtitle =>
      'هناك مخدومين تم تحديدهم وهم مسندين بالفعل لخدام آخرين، هل تود نقلهم؟';

  @override
  String conflictWarningTransferCount(int count, String name) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'أنت على وشك نقل $countString مخدوم مربوطين حالياً بخدام آخرين إلى ($name):';
  }

  @override
  String get confirmTransferQuestion =>
      'هل تريد بالتأكيد نقلهم وتحديث قاعدة البيانات؟';

  @override
  String get otherServant => 'خادم آخر';

  @override
  String resultsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'عدد النتائج: $countString';
  }

  @override
  String saveAssignmentsWithCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'حفظ التوزيع وتأكيد ($countString) مخدوم';
  }

  @override
  String get conflictTransferBtn => 'نعم، تأكيد النقل';

  @override
  String get conflictKeepBtn => 'تراجع';

  @override
  String get saveAssignmentsBtn => 'حفظ التوزيع';

  @override
  String get assignmentsSavedSuccess => 'تم تحديث وحفظ توزيع المخدومين بنجاح';

  @override
  String get excelSheetTitle => 'إدارة ملفات Excel';

  @override
  String get excelDownloadTemplate => 'تحميل قالب إكسيل فارغ';

  @override
  String get excelDownloadTemplateDesc =>
      'قالب جاهز بالأعمدة لملء بيانات المخدومين بسهولة';

  @override
  String get excelImportMakhdomeen => 'استيراد مخدومين من إكسيل';

  @override
  String get excelImportMakhdomeenDesc =>
      'قراءة ملف إكسيل وإضافة المخدومين لقاعدة البيانات';

  @override
  String get excelExportMakhdomeen => 'تصدير المخدومين إلى إكسيل';

  @override
  String get excelExportMakhdomeenDesc =>
      'تنزيل ملف إكسيل بجميع المخدومين وحالات الافتقاد';

  @override
  String get excelConfirmImportTitle => 'تأكيد الاستيراد';

  @override
  String excelConfirmImportPrompt(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تم العثور على ($countString) مخدوم في الشيت. هل تريد استيرادهم وإضافتهم إلى قاعدة البيانات الآن؟';
  }

  @override
  String get excelImportNowBtn => 'استيراد الآن';

  @override
  String excelImportSuccessMsg(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تم استيراد ($countString) مخدوم بنجاح!';
  }

  @override
  String get excelEmptyOrCanceled =>
      'لم يتم العثور على مخدومين في الملف أو تم إلغاء الاختيار';

  @override
  String get performanceAndCareIndicators => 'مؤشرات الأداء والرعاية';

  @override
  String get liveFollowupAndRates => 'متابعة حية ونسب إنجاز خدام الفصل';

  @override
  String get noAnalyticsData => 'لا توجد بيانات كافية لعرض التحليلات';

  @override
  String get totalMakhdomeenStat => 'إجمالي المخدومين';

  @override
  String get visitedAtLeastOnceStat => 'تم افتقادهم';

  @override
  String get neverVisitedStat => 'لم يُفتقدوا';

  @override
  String get brethrenStat => 'أخوة الرب';

  @override
  String get overallVisitRate => 'نسبة الافتقاد العامة';

  @override
  String get servantsLeaderboard => 'لوحة إنجاز الخدام';

  @override
  String get rankedByVisitRate => 'ترتيب الخدام بحسب نسبة الافتقاد لمجموعاتهم';

  @override
  String get urgentFollowupNeverVisited =>
      'متابعة عاجلة: لم يتم افتقادهم نهائياً';

  @override
  String urgentCountNeedingVisit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مخدوم بحاجة لافتقاد سريع';
  }

  @override
  String get activeServantsStat => 'خدام نشطون';

  @override
  String get totalMakhdomeenTitle => 'إجمالي المخدومين';

  @override
  String totalBoysAssignedSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مسند لخادم';
  }

  @override
  String get visitationRateTitle => 'نسبة الافتقاد العامة';

  @override
  String visitedBoysCountSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString تم افتقادهم';
  }

  @override
  String get neverVisitedTitle => 'لم يُفتقدوا';

  @override
  String get needsUrgentVisitSubtitle => 'بحاجة لافتقاد سريع';

  @override
  String get brethrenOfLordTitle => 'أخوة الرب';

  @override
  String get specialFollowupSubtitle => 'رعاية وافتقاد خاص';

  @override
  String get visitationDistributionTitle => 'توزيع نسب الافتقاد';

  @override
  String get servantsAchievementRatesTitle => 'نسب إنجاز الخدام';

  @override
  String get noKhodamYet => 'لا يوجد خدام مسجلين بعد';

  @override
  String unvisitedChildrenHeader(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'مخدومون لم يتم افتقادهم ($countString)';
  }

  @override
  String assignedToKhademLabel(String name) {
    return 'مسند إلى: $name';
  }

  @override
  String get noKhodamRegisteredYet => 'لا يوجد خدام مسجلين بعد';

  @override
  String get khodamAutoAppearNote =>
      'سيظهر الخدام هنا تلقائياً بمجرد تسجيل دخولهم لأول مرة بحساب Google الخاص بهم.';

  @override
  String get assignMakhdomeenActionBtn => 'توزيع وإسناد المخدومين';

  @override
  String assignedMakhdomeenCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مخدوم مسند';
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

    return '$vString من $tString تم افتقادهم';
  }

  @override
  String get grade1stName => 'أولى ثانوي';

  @override
  String get grade2ndName => 'ثانية ثانوي';

  @override
  String get grade3rdName => 'ثالثة ثانوي';

  @override
  String get allGrades => 'كل السنين';

  @override
  String get gradeLabel => 'السنة الدراسية';

  @override
  String get stageAdminTitle => 'أمين مرحلة ثانوي';

  @override
  String gradeAdminTitle(String grade) {
    return 'أمين $grade';
  }

  @override
  String get servantRoleLabel => 'خادم';

  @override
  String get pendingRoleLabel => 'قيد التسكين';

  @override
  String get pendingWelcome => 'أهلاً بك يا خادم المسيح في أسرة مرحلة ثانوي ✝️';

  @override
  String get pendingStatusTitle => 'في انتظار تسكينك وتوزيعك';

  @override
  String get pendingStatusDesc =>
      'تم تسجيل حسابك بنجاح. سيتولى أمين مرحلة ثانوي تسكينك في سنتك الدراسية (أولى، ثانية، أو ثالثة ثانوي) قريباً.';

  @override
  String get completeProfilePrompt =>
      'يرجى تأكيد بياناتك الشخصية لتسهيل التعرف عليك:';

  @override
  String get updateAndSave => 'تحديث وحفظ';

  @override
  String get stageDashboardTitle => 'لوحة أمانة مرحلة ثانوي';

  @override
  String get tabGradesAndServants => 'الخدام والتسكين';

  @override
  String get tabStageAnalytics => 'تحليلات المرحلة';

  @override
  String get tabStageTasks => 'مهام المرحلة';

  @override
  String get pendingServantsSection => 'خدام جدد بانتظار التسكين';

  @override
  String get gradeHeadsSection => 'أمناء السنين الدراسية';

  @override
  String get appointGradeHeadBtn => 'تعيين أمين السنة';

  @override
  String get changeGradeHeadBtn => 'تغيير الأمين';

  @override
  String get noGradeHeadAssigned => 'لم يتم تعيين أمين بعد';

  @override
  String get assignServantToGradePrompt => 'تسكين الخادم في سنة دراسية';

  @override
  String get selectGradePrompt => 'اختر السنة الدراسية:';

  @override
  String get servantAssignedSuccess => 'تم تسكين الخادم بنجاح!';

  @override
  String get gradeHeadUpdatedSuccess => 'تم تعيين أمين السنة بنجاح!';

  @override
  String gradeDashboardTitle(String grade) {
    return 'لوحة أمانة $grade';
  }

  @override
  String get tabGradeMakhdomeen => 'المخدومين';

  @override
  String get tabGradeAnalytics => 'التحليلات';

  @override
  String get tabGradeServants => 'خدام السنة';

  @override
  String get tabGradeTasks => 'مهام السنة';

  @override
  String get myTasksTitle => 'مهامي المكلف بها';

  @override
  String get addTaskTitle => 'إضافة مهمة جديدة';

  @override
  String get taskTitleLabel => 'عنوان المهمة *';

  @override
  String get taskTitleRequired => 'يرجى كتابة عنوان المهمة';

  @override
  String get taskDescLabel => 'تفاصيل المهمة (اختياري)';

  @override
  String get taskAssigneeLabel => 'الخادم المكلف *';

  @override
  String get taskTypeLabel => 'نوع المهمة';

  @override
  String get taskTypeGeneral => 'مهمة عامة (تحضير/نشاط)';

  @override
  String get taskTypeAttendance => 'تسجيل حضور وغياب';

  @override
  String get taskTypeVisitation => 'افتقاد خاص';

  @override
  String get taskCreatedSuccess => 'تمت إضافة المهمة بنجاح!';

  @override
  String get noTasksYet => 'لا توجد مهام مسندة حالياً';

  @override
  String get completedTasksSection => 'مهام تم إنجازها';

  @override
  String get pendingTasksSection => 'مهام قيد التنفيذ';

  @override
  String get taskCompletedMsg => 'تم إنجاز المهمة بنجاح! ✝️';

  @override
  String get taskReopenedMsg => 'تمت إعادة فتح المهمة';

  @override
  String get reopenAttendance => 'إعادة فتح الحضور';

  @override
  String get reopenAttendanceAction => 'إعادة الفتح';

  @override
  String get reopenReason => 'سبب إعادة الفتح';

  @override
  String get deleteTaskPrompt => 'هل تريد حذف هذه المهمة نهائياً؟';

  @override
  String get taskTypeAttendanceKhedma => 'حضور الخدمة';

  @override
  String get taskTypeAttendanceQoddas => 'حضور القداس';

  @override
  String get takeAttendanceAction => 'بدء رصد الحضور 📋';

  @override
  String get attendanceScreenTitleService => 'رصد حضور الخدمة';

  @override
  String get attendanceScreenTitleMass => 'رصد حضور القداس';

  @override
  String totalAttendedCount(int attended, int total) {
    final intl.NumberFormat attendedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attendedString = attendedNumberFormat.format(attended);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'الحضور: $attendedString / $totalString';
  }

  @override
  String get selectedAttendedHeader => 'الحاضرون الآن';

  @override
  String get noAttendedYetHint => 'لم يتم تحديد أي مخدوم بعد • علم بالأسفل';

  @override
  String get searchAttendanceHint => 'ابحث بالاسم أو الهاتف...';

  @override
  String get fridayOnlyWarning => 'يتم رصد الحضور أيام الجمعة فقط';

  @override
  String get scheduleMassAttendanceBtn => 'جدولة حضور قداس الجمعة ⛪';

  @override
  String get scheduleMassAttendanceTitle => 'جدولة حضور قداس مرحلة ثانوي';

  @override
  String get scheduleMassAttendanceSubtitle =>
      'اختر تاريخ الجمعة والخادم المكلف برصد حضور كل السنين';

  @override
  String get notAuthorizedAttendance => 'عفواً، هذه المهمة مخصصة لخادم آخر';

  @override
  String get autoSavedNotice => 'يتم الحفظ تلقائياً';

  @override
  String get tabVisitsAnalytics => 'مؤشرات الافتقاد';

  @override
  String get tabAttendanceAnalytics => 'مؤشرات الحضور';

  @override
  String get tabSmartInsights => 'التحليلات الذكية والتنبيهات 🧠';

  @override
  String get absenceAlertsHeader => 'إنذارات الغياب المتكرر';

  @override
  String get absenceAlertsSubtitle =>
      'شباب تغيبوا لجمعتين متتاليتين أو أكثر ويحتاجون لافتقاد عاجل';

  @override
  String missedFridaysCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'غائب لـ $countString جمعات متتالية';
  }

  @override
  String get criticalAbsenceBadge => 'خطر انقطاع حرج 🚨';

  @override
  String get warningAbsenceBadge => 'تحذير غياب متكرر ⚠️';

  @override
  String get visitationImpactHeader => 'أثر الافتقاد على الحضور 💡';

  @override
  String get visitationImpactSubtitle =>
      'مقارنة نسبة الحضور بين الأولاد المفتقدين وغير المفتقدين';

  @override
  String visitationImpactValue(double impact) {
    final intl.NumberFormat impactNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String impactString = impactNumberFormat.format(impact);

    return 'الفرق المرتبط بالافتقاد في الحضور: $impactString نقطة مئوية (لا يدل على السببية)';
  }

  @override
  String get segmentConsistent => 'الملتزمون 🌟';

  @override
  String get segmentIrregular => 'المتذبذبون 🔄';

  @override
  String get segmentAtRisk => 'المعرضون للانقطاع 🚨';

  @override
  String get servantMyAnalytics => 'إحصائياتي';

  @override
  String get servantGroupAttendanceRate => 'نسبة حضور مجموعتي';

  @override
  String get servantGroupVisitationProgress => 'إنجاز افتقاد مجموعتي';

  @override
  String get urgentVisitationNeeded => 'مطلوب افتقاد عاجل';

  @override
  String get noAbsenceAlerts =>
      'لا توجد إنذارات غياب حالياً • الكل منتظم ومتابع 🎉';

  @override
  String get allDetailsAction => 'عرض كل البيانات';

  @override
  String get hideDetailsAction => 'إخفاء التفاصيل';

  @override
  String get assignedKhademLabel => 'الخادم المسؤول';

  @override
  String get generalNotesTitle => 'ملاحظات عامة عن المخدوم';

  @override
  String get overallAttendanceTitle => 'نسبة الحضور الإجمالية';

  @override
  String get totalVisitsTitle => 'إجمالي الافتقادات';

  @override
  String get consecutiveAbsenceTitle => 'الغياب المتتالي';

  @override
  String get massAndServiceRatesTitle => 'حضور القداس والخدمة';

  @override
  String get visitationCorrelationTitle => 'الارتباط الإحصائي للافتقاد';

  @override
  String visitationCorrelationBody(String diff) {
    return 'فرق الحضور بعد الزيارات: $diff نقطة مئوية (ارتباط دون ادعاء السببية).';
  }

  @override
  String get insufficientHistoryDataHint =>
      'لا توجد جلسات خدمة مكتملة ومؤهلة في هذه الفترة.';

  @override
  String daysSinceLastVisit(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'منذ $daysString يوم',
      many: 'منذ $daysString يوماً',
      few: 'منذ $daysString أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get noVisitsYet => 'لم يُفتقد بعد';

  @override
  String get noConsecutiveAbsences => 'منتظم ومتابع';

  @override
  String get criticalAbsenceAlert => 'إنذار خطر انقطاع 🚨';

  @override
  String get warningAbsenceAlert => 'مطلوب افتقاد عاجل ⚠️';

  @override
  String attendanceRatio(int attended, int eligible) {
    final intl.NumberFormat attendedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attendedString = attendedNumberFormat.format(attended);
    final intl.NumberFormat eligibleNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eligibleString = eligibleNumberFormat.format(eligible);

    return '$attendedString من $eligibleString جلسة';
  }

  @override
  String massRateSubtitle(String rate) {
    return 'نسبة حضور القداس $rate%';
  }

  @override
  String get filterAllEvents => 'كل الأحداث';

  @override
  String get filterVisitsOnly => 'الزيارات فقط';

  @override
  String get filterAttendanceOnly => 'الحضور فقط';

  @override
  String get filterFruitfulOnly => 'المثمرة فقط';

  @override
  String get filterAbsencesOnly => 'الغياب فقط';

  @override
  String get rangeAllTime => 'كل الفترات';

  @override
  String get rangeLast30Days => 'آخر 30 يوم';

  @override
  String get rangeLast90Days => 'آخر 90 يوم';

  @override
  String get rangeCustom => 'مخصصة';

  @override
  String get pastoralVisitGeneral => 'افتقاد رعوي';

  @override
  String get visitOutcomeBoth => 'أثمر الافتقاد: حضر القداس والخدمة 🌟';

  @override
  String get visitOutcomeServiceOnly => 'أثمر الافتقاد: حضر الخدمة فقط ✅';

  @override
  String get visitOutcomeMassOnly => 'أثمر الافتقاد: حضر القداس الإلهي فقط ✅';

  @override
  String get visitOutcomeMissed => 'غائب عن القداس والخدمة ⚠️ (يحتاج متابعة)';

  @override
  String get visitOutcomePending => 'في انتظار الجمعة القادمة ⏳';

  @override
  String get visitOutcomeNoData => 'لم تُسجل جلسات حضور في هذه الجمعة';

  @override
  String get visitingServantLabel => 'الخادم القائم بالافتقاد: ';

  @override
  String get assignedKhademPlaceholder => 'الخادم المسؤول';

  @override
  String get visitReportNotesHeader => 'ما دار في الافتقاد وملاحظات الخادم:';

  @override
  String get editNoteAction => 'تعديل';

  @override
  String get addNoteAction => 'إضافة';

  @override
  String get visitNoDetailedNotes =>
      'تم الافتقاد بنجاح (لم تُسجل ملاحظات تفصيلية)';

  @override
  String visitOutcomeHeader(String date) {
    return 'أثر الافتقاد (جمعة $date):';
  }

  @override
  String get attendedMassAndService => 'حاضر قداس وخدمة ✅';

  @override
  String get attendedPartial => 'حضور جزئي';

  @override
  String get absentBoth => 'غائب ❌';

  @override
  String get massLabel => 'القداس';

  @override
  String get serviceLabel => 'الخدمة';

  @override
  String precededByVisitNote(String date) {
    return 'سبق هذه الجمعة افتقاد ($date)';
  }

  @override
  String get noEventsMatchingFilter => 'لا توجد أحداث مطابقة للفلاتر المختارة';

  @override
  String get editVisitNotesTitle => 'تعديل ملاحظات الافتقاد';

  @override
  String get editVisitNotesSubtitle =>
      'اكتب ما دار في الافتقاد وتفاصيل الزيارة لمتابعة المخدوم بدقة:';

  @override
  String get editVisitNotesHint => 'تفاصيل الافتقاد وما تم التحدث بشأنه...';

  @override
  String get visitNotesUpdatedSuccess => 'تم حفظ ملاحظات الافتقاد بنجاح';

  @override
  String errorUpdatingNotes(String err) {
    return 'حدث خطأ أثناء حفظ الملاحظات: $err';
  }

  @override
  String get copyPhoneAction => 'نسخ الرقم';

  @override
  String get retryAction => 'إعادة المحاولة';

  @override
  String get message1stSecondary => 'أولى ثانوي';

  @override
  String get message2ndSecondary => 'تانية ثانوي';

  @override
  String get message3rdSecondary => 'تالتة ثانوي';

  @override
  String get messageAllGrades => 'كل المرحلة';

  @override
  String get messageSecondary => 'ثانوي';

  @override
  String get message1st => '1ث';

  @override
  String get message2nd => '2ث';

  @override
  String get message3rd => '3ث';

  @override
  String get messageStageAdministrator => 'أمين المرحلة';

  @override
  String get messageGradeAdministrator => 'أمين السنة';

  @override
  String get messageServant => 'خادم';

  @override
  String get messagePending => 'في الانتظار';

  @override
  String get messageServiceAttendance => 'حضور الخدمة';

  @override
  String get messageMassAttendance => 'حضور القداس';

  @override
  String get messageVisitationTask => 'تكليف افتقاد';

  @override
  String get messageGeneralTask => 'مهمة عامة';

  @override
  String get messageHomeVisit => 'زيارة منزلية';

  @override
  String get messagePhoneCall => 'مكالمة هاتفية';

  @override
  String get messageChurchMeetup => 'لقاء بالكنيسة';

  @override
  String get messageOther => 'أخرى';

  @override
  String get messageVisit => 'زيارة';

  @override
  String get messageFullName => 'الاسم رباعي';

  @override
  String get messageDateOfBirthYyyyMmDd => 'تاريخ الميلاد (YYYY-MM-DD)';

  @override
  String get messageTrackingStartDateYyyyMmDd =>
      'تاريخ بدء التتبع (YYYY-MM-DD)';

  @override
  String get messageAge => 'العمر';

  @override
  String get messageStudentPhone => 'رقم تليفون المخدوم';

  @override
  String get messageFatherPhone => 'رقم تليفون الأب';

  @override
  String get messageMotherPhone => 'رقم تليفون الأم';

  @override
  String get messageDetailedAddress => 'العنوان بالتفصيل';

  @override
  String get messageArea => 'المنطقة';

  @override
  String get messageSchool => 'المدرسة';

  @override
  String get messageSecondaryType => 'نوع الثانوية';

  @override
  String get messageHomeLocationMapsLink => 'لوكيشن البيت (رابط خرائط)';

  @override
  String get messageBrethrenOfLordYesNo => 'أخوة رب (نعم/لا)';

  @override
  String get messageStudentPhotoUrl => 'رابط صورة المخدوم';

  @override
  String get messageNotes => 'ملاحظات';

  @override
  String get messageAssignedServant => 'الخادم المسؤول';

  @override
  String get messageVisitsCount => 'عدد الافتقادات';

  @override
  String get messageLastVisitDate => 'تاريخ آخر افتقاد';

  @override
  String get messageYes => 'نعم';

  @override
  String get messageNo => 'لا';

  @override
  String get messageUnassigned => 'غير مربوط';

  @override
  String get messageNotVisited => 'لم يُفتقد';

  @override
  String get messageYears => 'سنة';

  @override
  String get messageStudentsData => 'بيانات_المخدومين';

  @override
  String get messageStudentsTemplate => 'قالب_المخدومين';

  @override
  String get messageMainMenu => 'القائمة الرئيسية';

  @override
  String get messageMakhdomeen => 'المخدومين';

  @override
  String get messageMyStudents => 'مخدوميني';

  @override
  String get messageMyTasks => 'مهامي';

  @override
  String get messageAccountDeletionInProgress => 'حذف الحساب قيد التنفيذ';

  @override
  String get messageUnableToLoadProfile => 'تعذر تحميل الملف الشخصي';

  @override
  String get messageYourDeletionRequestIsSavedYouCan =>
      'طلب الحذف محفوظ. يمكنك الخروج ومتابعة الحالة لاحقاً.';

  @override
  String get messageRetry => 'إعادة المحاولة';

  @override
  String get messageStudentsImportTemplateXlsx => 'قالب_إضافة_المخدومين.xlsx';

  @override
  String get messageExcelTemplateForImportingStudentsInEfteqad =>
      'قالب إكسيل لإضافة المخدومين في تطبيق افتقاد';

  @override
  String get messageStudentsReportEfteqad => 'تقرير المخدومين - تطبيق افتقاد';

  @override
  String get messageFailedToLoadAttendanceSessions => 'تعذر تحميل جلسات الحضور';

  @override
  String get messageLast90Days => 'آخر 90 يوماً';

  @override
  String get messageEn => 'ar';

  @override
  String get messageSession => 'جلسة';

  @override
  String messageAbsenceAlert(String value0) {
    return '⚠️ تنبيه غياب: $value0';
  }

  @override
  String messageStudentMissedFridaysPleaseVisitSoon(String value0) {
    return 'المخدوم غائب لـ $value0 جمعات متتالية. يرجى الافتقاد العاجل.';
  }

  @override
  String messageUrgentAlertSentTo(String value0) {
    return 'تم إرسال تنبيه عاجل للخادم ($value0) بنجاح! 🔔';
  }

  @override
  String get messageNotify => 'تنبيه الخادم';

  @override
  String get messageS => 'خ';

  @override
  String get messageUpdateRecordAndPersonalDetails =>
      'تحديث السجل والبيانات الشخصية';

  @override
  String get messageInsertNewMakhdomToCareRegistry =>
      'إدراج مخدوم جديد إلى دفتر الرعاية';

  @override
  String get messageFieldsAreLockedUntilConfirmationRetryTo =>
      'البيانات ثابتة حتى تأكيد الحفظ. أعد المحاولة لاستكمال الطلب.';

  @override
  String messageErrorSavingAssignments(String value0) {
    return 'حدث خطأ أثناء الحفظ: $value0';
  }

  @override
  String get messageAssignMakhdomeenToServant => 'إسناد وتوزيع مخدومين للخادم';

  @override
  String get messageSelectionIsLockedUntilConfirmationRetryTo =>
      'التحديد ثابت حتى تأكيد الحفظ. أعد المحاولة لاستكمال الطلب.';

  @override
  String get messageGeneratingSharingTemplate => 'جارٍ إنشاء ومشاركة القالب...';

  @override
  String messageError(String value0) {
    return 'خطأ: $value0';
  }

  @override
  String get messageReadingAndExtractingDataFromFile =>
      'جارٍ قراءة واستخراج البيانات من الملف...';

  @override
  String messageCouldNotImportAnyRowsDueTo(String value0) {
    return 'تعذر استيراد أي مخدوم بسبب أخطاء في الصفوف:\n$value0';
  }

  @override
  String messageTargetGrade(String value0) {
    return 'السنة المستهدفة: $value0';
  }

  @override
  String messageRowsExcluded(String value0, String value1) {
    return '⚠️ تم استبعاد $value0 صفاً:\n$value1';
  }

  @override
  String get messageSavingToFirebase => 'جارٍ الحفظ في فايربيس...';

  @override
  String messageSavingToFirebase564(String value0, String value1) {
    return 'جارٍ الحفظ في فايربيس ($value0 / $value1)...';
  }

  @override
  String get messageLocalRowsExcluded => 'صفوف محلية مستبعدة';

  @override
  String get messageServerRowsRejected => 'صفوف مرفوضة من الخادم';

  @override
  String messageImportFailed(String value0) {
    return 'فشل الاستيراد: $value0';
  }

  @override
  String get messageExportingDataToExcel => 'جارٍ تصدير البيانات إلى إكسيل...';

  @override
  String messageExportError(String value0) {
    return 'خطأ أثناء التصدير: $value0';
  }

  @override
  String get messageBulkDataManagementAndSheetExports =>
      'إدارة البيانات بشكل جماعي واستخراج الشيتات';

  @override
  String get messageProcessing => 'جارٍ المعالجة...';

  @override
  String get messageUnassignStudent => 'إلغاء التسكين';

  @override
  String messageAreYouSureYouWantToUnassign(String value0) {
    return 'هل أنت متأكد من إلغاء تسكين $value0 من خادمه الحالي؟';
  }

  @override
  String get messageUnassign => 'إلغاء التسكين';

  @override
  String get messageM => 'م';

  @override
  String get messageServant580 => 'الخادم';

  @override
  String get messageSelectAServantToAppointAsGrade =>
      'اختر خادماً لتعيينه أميناً للسنة الدراسية';

  @override
  String messageNoServantsAssignedToYet(String value0) {
    return 'لا يوجد خدام مسكنين في $value0 بعد';
  }

  @override
  String get messageAppointHead => 'تعيين كأمين';

  @override
  String get messageAssign => 'تسكين';

  @override
  String get messageChangeHead => 'تغيير الأمين';

  @override
  String get messageUnspecified => 'غير محدد';

  @override
  String get messageThisSessionHasBeenFinalizedAndCannot =>
      'تم اعتماد هذه الجلسة ولا يمكن تعديلها.';

  @override
  String messageErrorSavingAttendance(String value0) {
    return 'حدث خطأ أثناء الحفظ: $value0';
  }

  @override
  String get messagePleaseWaitForPendingSavesToFinish =>
      'يرجى الانتظار حتى اكتمال حفظ الطلبات المعلقة.';

  @override
  String get messageFinalizeAttendance => 'اعتماد الحضور';

  @override
  String get messageAreYouSureYouWantToFinalize =>
      'هل أنت متأكد من إنهاء واعتماد كشف الحضور لهذه الجلسة؟ لن يمكن التعديل عليها بعد ذلك.';

  @override
  String get messageCancel => 'إلغاء';

  @override
  String get messageConfirmFinalization => 'تأكيد الاعتماد';

  @override
  String get messageAttendanceFinalizedSuccessfully =>
      'تم اعتماد كشف الحضور بنجاح.';

  @override
  String messageErrorFinalizingAttendance(String value0) {
    return 'حدث خطأ أثناء اعتماد الحضور: $value0';
  }

  @override
  String get messageLoading => 'جاري التحميل...';

  @override
  String get messageFinalized => 'معتمد';

  @override
  String get messageSaving => 'جاري الحفظ...';

  @override
  String get messageSaveError => 'خطأ في الحفظ';

  @override
  String messageCouldNotLoadRoster(String value0) {
    return 'تعذر تحميل كشف الحضور: $value0';
  }

  @override
  String get messageAttendanceSessionIsFinalizedAndLockedRead =>
      'تم إنهاء واعتماد كشف الحضور لهذه الجلسة. القراءة فقط.';

  @override
  String get messageSearchByName => 'بحث بالاسم';

  @override
  String get messageNotificationsCenter => 'مركز الإشعارات';

  @override
  String get messageMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get messageAccessDenied => 'غير مصرح بالوصول';

  @override
  String get messageYouDoNotHavePermissionToAccess =>
      'ليس لديك الصلاحيات الكافية للوصول إلى هذه الصفحة.';

  @override
  String get messagePageNotFound => 'الصفحة غير موجودة';

  @override
  String get messageThePageYouAreLookingForDoes =>
      'عذراً، المسار الذي تحاول الوصول إليه غير موجود أو تم نقله.';

  @override
  String get messageAnErrorOccurred => 'حدث خطأ';

  @override
  String get messageGoHome => 'الصفحة الرئيسية';

  @override
  String get messageNotifications => 'الإشعارات والتنبيهات';

  @override
  String get messageNotificationsCenter616 => 'مركز الإشعارات والتنبيهات';

  @override
  String get messageJustNow => 'الآن';

  @override
  String messageMAgo(String value0) {
    return 'منذ $value0 دقيقة';
  }

  @override
  String messageHAgo(String value0) {
    return 'منذ $value0 ساعة';
  }

  @override
  String messageDAgo(String value0) {
    return 'منذ $value0 يوم';
  }

  @override
  String get messageNoNotificationsYet => 'لا توجد إشعارات حالياً';

  @override
  String get messageTaskAssignmentsAndAlertsWillAppearHere =>
      'ستظهر هنا إشعارات المهام والتنبيهات الموجهة إليك';

  @override
  String messageCouldNotConfirmSaveRetryTheSame(String value0) {
    return 'تعذر تأكيد الحفظ. الطلب ثابت لإعادة المحاولة: $value0';
  }

  @override
  String messageCouldNotLoadLocalDraft(String value0) {
    return 'تعذر تحميل المسودة المحلية: $value0';
  }

  @override
  String get messageLocalSubmissionLoadedConfirmationIsPending =>
      'تم استرجاع طلب محفوظ محلياً يحتاج تأكيد الحفظ';

  @override
  String get messageFieldsAreLockedUntilConfirmationRetryTo631 =>
      'البيانات ثابتة حتى تأكيد الحفظ. أعد المحاولة لتأكيد نفس الزيارة.';

  @override
  String messageAlertBoysNeedUrgentVisitRepeatedAbsence(String value0) {
    return 'تنبيه: يوجد $value0 من أولادك بحاجة لافتقاد عاجل (غياب متكرر)';
  }

  @override
  String get messageView => 'عرض 👈';

  @override
  String get messageAllSessions => 'حضور كل الجلسات';

  @override
  String get messageAllConsistent => 'الكل منتظم 🎉';

  @override
  String get messageAbsenceAlert637 => 'غياب متكرر ⚠️';

  @override
  String get messageAttendance75 => 'حضور ≥ 75%';

  @override
  String get messageVisited => 'المفتقدون';

  @override
  String get messageUnvisited => 'غير المفتقدين';

  @override
  String get messageAttendanceRatesCurrentlyEqual =>
      'نسب الحضور متساوية حالياً';

  @override
  String get messageCall => 'اتصال';

  @override
  String get messageWhatsapp => 'واتساب';

  @override
  String get messageVisit644 => 'افتقاد';

  @override
  String get messageBehavioralSegmentation => 'التصنيف السلوكي للمتابعة';

  @override
  String get messageNoStudentsInThisSegment => 'لا يوجد مخدومون في هذا التصنيف';

  @override
  String messageVisits(String value0) {
    return 'افتقاد: $value0';
  }

  @override
  String get messageAbsenceAlert649 => 'غياب متكرر ⚠️';

  @override
  String get messageVisit650 => 'افتقاد';

  @override
  String get messageBehavioralSegmentation651 => 'التصنيف السلوكي للأولاد';

  @override
  String messageOfVisited(String value0, String value1) {
    return '$value0 من $value1 مخدوم';
  }

  @override
  String get messageConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get messageToDeleteYourAccountPleaseEnterYour =>
      'لحذف الحساب، يرجى إدخال كلمة المرور الخاصة بحسابك للتأكيد.';

  @override
  String get messagePassword => 'كلمة المرور';

  @override
  String get messageProceed => 'متابعة الحذف';

  @override
  String get messageStageAdministratorCannotDeleteAccountBeforeAppointing =>
      'لا يمكن لأمين المرحلة حذف حسابه قبل تعيين أمين مرحلة بديل ومثبت.';

  @override
  String get messageTaskDetails => 'تفاصيل المهمة';

  @override
  String get messageDescription => 'الوصف';

  @override
  String get messageAssignedServant661 => 'الخادم المكلف';

  @override
  String get messageGrade => 'السنة الدراسية';

  @override
  String get messageDueDate => 'تاريخ الاستحقاق';

  @override
  String get messageCreatedBy => 'أنشئت بواسطة';

  @override
  String get messageOpenAttendanceSheet => 'فتح كشف الحضور';

  @override
  String get messageCompleted => 'مكتملة بنجاح';

  @override
  String get messageMarkAsCompleted => 'تحديد كمكتملة';

  @override
  String get messageAdmin => 'أمين الخدمة';

  @override
  String get messageYouAreAssignedToTakeServiceAttendance =>
      'تم تكليفك برصد حضور وغياب الخدمة';

  @override
  String get messageYouAreAssignedToTakeMassAttendance =>
      'تم تكليفك برصد حضور وغياب القداس الإلهي';

  @override
  String messageAssignedYouANewTask(String value0) {
    return 'قام $value0 بتكليفك بمهمة جديدة';
  }

  @override
  String messageNewTask(String value0) {
    return 'مهمة جديدة: $value0 📋';
  }

  @override
  String get messageSubmissionIsLockedUntilConfirmationRetryTo =>
      'الطلب ثابت حتى تأكيد الحفظ. أعد المحاولة لتأكيد نفس المهمة.';

  @override
  String get messageYouAreOffline => 'أنت في وضع عدم الاتصال (أوفلاين)';

  @override
  String get messageSyncingPendingChanges => 'جاري مزامنة التعديلات المعلقة...';

  @override
  String messageNoServantsAssignedToYetAssignServants(String value0) {
    return 'لا يوجد خدام مسكنين في $value0 بعد.\nقم بتسكين خدام أولاً لتتمكن من تعيين أمين.';
  }

  @override
  String get messageCurrentHead => 'الأمين الحالي';

  @override
  String get messageAssignedSecondaryStageServants =>
      'خدام مرحلة ثانوي المسكنين';

  @override
  String messageServants(String value0) {
    return '$value0 خادم';
  }

  @override
  String get messageNoServantsAssignedToThisSectionYet =>
      'لا يوجد خدام مسكنين في هذا القسم بعد';

  @override
  String get messageGradeHead => 'أمين سنة';

  @override
  String messageAssignedStudents(String value0, String value1) {
    return '$value0 • $value1 ولد مسند';
  }

  @override
  String get messageChangeGrade => 'تغيير السنة الدراسية';

  @override
  String get messageNewServant => 'خادم جديد';

  @override
  String get messageNoAttendanceSessionsRecordedYet =>
      'لم يتم رصد أي جلسات حضور حتى الآن';

  @override
  String get messageWeeklyStatisticsAppearHereAfterRecordingAttendance =>
      'ستظهر الإحصائيات الأسبوعية هنا بعد تسجيل حضور الجمعة';

  @override
  String get messageOverallAttendanceRate => 'نسبة الحضور العامة';

  @override
  String get messageAverageOfRecordedSessions => 'متوسط كل الجلسات المسجلة';

  @override
  String get messageAttendanceFridays => 'عدد جمعات الحضور';

  @override
  String messageServiceMass(String value0, String value1) {
    return '$value0 خدمة • $value1 قداس';
  }

  @override
  String get messageAverageSundaySchoolAttendance => 'متوسط حضور مدارس الأحد';

  @override
  String get messageAverageMassAttendance => 'متوسط حضور القداسات';

  @override
  String get messageWeeklyAttendanceRecentFridays =>
      'متابعة الحضور أسبوعياً (آخر الجمعات)';

  @override
  String get messageMass => 'قداس';

  @override
  String get messageService => 'خدمة';

  @override
  String messageStudents(String value0) {
    return '$value0 أولاد';
  }

  @override
  String get messageVisitedStudents => 'أولاد تم افتقادهم';

  @override
  String messageStudents705(String value0) {
    return '$value0 ولد';
  }

  @override
  String get messageUnvisitedStudents => 'أولاد لم يُفتقدوا';

  @override
  String messageStudents708(String value0) {
    return '$value0 ولد';
  }

  @override
  String get messageStudentAttendanceGroups =>
      'التصنيف السلوكي للأولاد (المجموعات)';

  @override
  String get messageNoStudentsInThisGroup => 'لا يوجد أولاد في هذه المجموعة';

  @override
  String messageAgeYears(String value0) {
    return 'العمر: $value0 سنة';
  }

  @override
  String get messageCalculatedPrecisely => 'محسوب بدقة ⚡';

  @override
  String get messageAutomatic => 'تلقائي ⚡';

  @override
  String messageBirthDate(String value0, String value1, String value2) {
    return 'تاريخ الميلاد: $value0/$value1/$value2';
  }

  @override
  String messageAgeEstimatedFromSecondaryGrade(String value0) {
    return 'تم حساب السن تلقائياً حسب مرحلة ثانوي ($value0)';
  }

  @override
  String get messageResetToAutomaticCalculation =>
      'إلغاء التخصيص والعودة للحساب التلقائي';

  @override
  String messageYears721(String value0) {
    return '$value0 سنة';
  }

  @override
  String get messageChooseExactBirthDate => 'اختر تاريخ الميلاد الدقيق';

  @override
  String get messageExactDate => 'تاريخ دقيق...';

  @override
  String get messageServantUnavailableInThisList => 'خادم غير موجود في القائمة';

  @override
  String messageStudents726(String value0) {
    return 'مخدومي_$value0';
  }

  @override
  String messageAgeEstimatedFrom(String value0, String value1) {
    return 'العمر: $value0 (محسوب تلقائياً حسب $value1)';
  }

  @override
  String messageAssignedStudents730(String value0, String value1) {
    return '$value0 • $value1 مخدوم مسكن';
  }

  @override
  String get messageChangeGrade732 => 'تغيير السنة';

  @override
  String get messageVisitNotesAndDiscussion =>
      'ملاحظات وما دار في الافتقاد (الديسكريبشن)';

  @override
  String get messageRecordVisitDiscussionMeetingDetailsOrPastoral =>
      'اكتب هنا ما دار في الافتقاد، تفاصيل المقابلة، أو أي احتياجات رعوية...';

  @override
  String messageOfStudents(String value0, String value1) {
    return '$value0 من $value1 مخدوم';
  }

  @override
  String messageAttendance(String value0) {
    return '$value0% حضور';
  }

  @override
  String get messageStageServant => 'خادم بالمرحلة';

  @override
  String messageDate(String value0) {
    return 'التاريخ: $value0';
  }

  @override
  String get messageSelectDueDateOptional => 'تحديد تاريخ المهمة (اختياري)';

  @override
  String get messageFriday => 'جمعة';

  @override
  String get failurePermissionDenied => 'ليس لديك صلاحية لتنفيذ هذه العملية.';

  @override
  String get failureNetwork =>
      'تعذر الاتصال. تحقق من اتصال الإنترنت وحاول مجدداً.';

  @override
  String get failureNotFound => 'المورد المطلوب غير موجود أو تم حذفه.';

  @override
  String get failureDecode => 'تعذر قراءة البيانات. حاول تحميلها مجدداً.';

  @override
  String get failureAuthentication => 'يرجى تسجيل الدخول مجدداً لتأكيد هويتك.';

  @override
  String get stageSuccessorRequired =>
      'يجب تعيين أمين مرحلة بديل نشط ومثبت قبل حذف حسابك.';

  @override
  String get channelName => 'إشعارات افتقاد والمهام';

  @override
  String get channelDescription => 'تنبيهات المهام والتكليفات والحضور والغياب';

  @override
  String get newNotification => 'إشعار جديد 🔔';

  @override
  String get secondaryGeneral => 'ثانوية عامة';

  @override
  String get secondaryTechnical => 'صنايع / فني';

  @override
  String get secondaryService => 'خدمات';

  @override
  String get secondaryCommercial => 'تجاري';

  @override
  String get secondaryOther => 'أخرى';

  @override
  String excelSampleSkipped(String name) {
    return 'تم رصد صف العينة التجريبي ($name) وتجاهله تلقائياً.';
  }

  @override
  String excelMissingName(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'اسم المخدوم فارغ في الصف $rowString';
  }

  @override
  String excelMissingPhone(int row) {
    final intl.NumberFormat rowNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rowString = rowNumberFormat.format(row);

    return 'رقم تليفون المخدوم فارغ في الصف $rowString';
  }

  @override
  String excelDuplicatePhone(String phone, String name) {
    return 'تكرار رقم هاتف في الملف ($phone) للمخدوم ($name)';
  }

  @override
  String excelInvalidBirthDate(String value) {
    return 'تاريخ ميلاد غير صالح: $value';
  }

  @override
  String excelInvalidTrackingDate(String value) {
    return 'تاريخ بدء التتبع غير صالح: $value';
  }

  @override
  String get excelEmptyFailure => 'ملف الإكسيل فارغ أو غير صالح.';

  @override
  String get excelColumnsFailure =>
      'تعذر العثور على أعمدة الاسم أو الهاتف في الترويسة.';

  @override
  String get excelReadFailure => 'تعذر قراءة بيانات الملف.';

  @override
  String get attendanceFinalizedFailure =>
      'لا يمكن تعديل جلسة حضور تم اعتمادها وإنهاء رصدها.';

  @override
  String get pendingSavesFailure =>
      'يوجد طلبات معلقة قيد الحفظ. يرجى الانتظار حتى اكتمالها.';

  @override
  String birthDateCaption(String date) {
    return 'تاريخ الميلاد: $date';
  }

  @override
  String analyticsDateBounds(String from, String to) {
    return '$from – $to';
  }

  @override
  String trackingStartLabel(String date) {
    return 'بدء التتبع: $date';
  }

  @override
  String trackingStartEstimatedLabel(String date) {
    return 'بدء التتبع تقديري: $date';
  }

  @override
  String get trackingOriginUnknown =>
      'بدء التتبع غير معروف؛ بيانات الحضور غير كافية.';

  @override
  String get loadMore => 'عرض المزيد';

  @override
  String get secondaryTypeCustomLabel => 'نوع الثانوية المخصص';

  @override
  String get legacyNotesLabel => 'ملاحظات قديمة';

  @override
  String get cachedDataHint =>
      'عرض بيانات مخزنة محليًا؛ في انتظار تأكيد الخادم.';

  @override
  String get insufficientDataShort => 'غير كافٍ';

  @override
  String get followupNotificationTitle => 'تنبيه متابعة';

  @override
  String get followupNotificationBody =>
      'افتح تطبيق افتقاد لمتابعة أحد مخدوميك.';
}

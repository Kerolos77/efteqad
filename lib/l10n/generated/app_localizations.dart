import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GeneratedAppLocalizations
/// returned by `GeneratedAppLocalizations.of(context)`.
///
/// Applications need to include `GeneratedAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GeneratedAppLocalizations.localizationsDelegates,
///   supportedLocales: GeneratedAppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GeneratedAppLocalizations.supportedLocales
/// property.
abstract class GeneratedAppLocalizations {
  GeneratedAppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GeneratedAppLocalizations? of(BuildContext context) {
    return Localizations.of<GeneratedAppLocalizations>(
      context,
      GeneratedAppLocalizations,
    );
  }

  static const LocalizationsDelegate<GeneratedAppLocalizations> delegate =
      _GeneratedAppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'الراعي'**
  String get appName;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get back;

  /// No description provided for @copyAddress.
  ///
  /// In ar, this message translates to:
  /// **'نسخ العنوان'**
  String get copyAddress;

  /// No description provided for @currentGradeAdmin.
  ///
  /// In ar, this message translates to:
  /// **'أمين السنة الحالي'**
  String get currentGradeAdmin;

  /// No description provided for @visitReportLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقرير الافتقاد'**
  String get visitReportLabel;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ. حاول مرة أخرى.'**
  String get saveFailed;

  /// No description provided for @syncPending.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ على الجهاز، في انتظار المزامنة'**
  String get syncPending;

  /// No description provided for @dataUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل البيانات'**
  String get dataUnavailable;

  /// No description provided for @insufficientAttendanceData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الحضور غير كافية'**
  String get insufficientAttendanceData;

  /// No description provided for @visitsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد افتقادات} =1{افتقاد واحد} =2{افتقادان} few{{count} افتقادات} many{{count} افتقاداً} other{{count} افتقاد}}'**
  String visitsCount(int count);

  /// No description provided for @studentsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا يوجد مخدومين} =1{مخدوم واحد} =2{مخدومان} few{{count} مخدومين} many{{count} مخدوماً} other{{count} مخدوم}}'**
  String studentsCount(int count);

  /// No description provided for @servantsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا يوجد خدام} =1{خادم واحد} =2{خادمان} few{{count} خدام} many{{count} خادماً} other{{count} خادم}}'**
  String servantsCount(int count);

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'«أَنَا هُوَ الرَّاعِي الصَّالِحُ»'**
  String get appTagline;

  /// No description provided for @shepherdVerse.
  ///
  /// In ar, this message translates to:
  /// **'«اِرْعَ خِرَافِي.. اِرْعَ غَنَمِي»'**
  String get shepherdVerse;

  /// No description provided for @shepherdVerseShort.
  ///
  /// In ar, this message translates to:
  /// **'«كُنْ عَارِفًا حَالَ غَنَمِكَ»'**
  String get shepherdVerseShort;

  /// No description provided for @shepherdVerseLong.
  ///
  /// In ar, this message translates to:
  /// **'«كُنْ عَارِفًا حَالَ غَنَمِكَ، وَاجْعَلْ قَلْبَكَ إِلَى قُطْعَانِكَ»'**
  String get shepherdVerseLong;

  /// No description provided for @shepherdVerseGoodShepherd.
  ///
  /// In ar, this message translates to:
  /// **'«الرَّاعِي الصَّالِحُ يَبْذِلُ نَفْسَهُ عَنِ الْخِرَافِ»'**
  String get shepherdVerseGoodShepherd;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {ver}'**
  String version(String ver);

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @or.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get or;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث...'**
  String get search;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @area.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get area;

  /// No description provided for @school.
  ///
  /// In ar, this message translates to:
  /// **'المدرسة'**
  String get school;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'متابعة باستخدام حساب Google'**
  String get continueWithGoogle;

  /// No description provided for @adminSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول أمين الخدمة (Admin)'**
  String get adminSignInButton;

  /// No description provided for @adminSignInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دخول مسؤول الخدمة'**
  String get adminSignInTitle;

  /// No description provided for @adminSignInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور الخاصة بحساب الإدارة'**
  String get adminSignInSubtitle;

  /// No description provided for @adminEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'بريد المسؤول (Admin Email)'**
  String get adminEmailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @enterDashboardButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول لوحة التحكم'**
  String get enterDashboardButton;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In ar, this message translates to:
  /// **'يرجى ملء جميع الحقول'**
  String get pleaseFillAllFields;

  /// No description provided for @loginFailedCheckCredentials.
  ///
  /// In ar, this message translates to:
  /// **'فشل الدخول: تحقق من صحة الإيميل وكلمة المرور'**
  String get loginFailedCheckCredentials;

  /// No description provided for @loginError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تسجيل الدخول: {err}'**
  String loginError(String err);

  /// No description provided for @headServant.
  ///
  /// In ar, this message translates to:
  /// **'أمين الخدمة'**
  String get headServant;

  /// No description provided for @servant.
  ///
  /// In ar, this message translates to:
  /// **'خادم'**
  String get servant;

  /// No description provided for @adminRole.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول'**
  String get adminRole;

  /// No description provided for @servantRole.
  ///
  /// In ar, this message translates to:
  /// **'خادم'**
  String get servantRole;

  /// No description provided for @mainDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم الرئيسية'**
  String get mainDashboard;

  /// No description provided for @excelTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات الإكسيل (استيراد وتصدير)'**
  String get excelTools;

  /// No description provided for @myGroupAndVisits.
  ///
  /// In ar, this message translates to:
  /// **'مجموعتي والافتقاد'**
  String get myGroupAndVisits;

  /// No description provided for @servantProfile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي للخادم'**
  String get servantProfile;

  /// No description provided for @generalSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات العامة'**
  String get generalSettings;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMsg.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟'**
  String get signOutConfirmMsg;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In ar, this message translates to:
  /// **'المظهر والرؤية'**
  String get appearanceSection;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي (Dark Mode)'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح (Light Mode)'**
  String get lightMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In ar, this message translates to:
  /// **'راحة للعين في الإضاءة الخافتة'**
  String get darkModeDesc;

  /// No description provided for @lightModeDesc.
  ///
  /// In ar, this message translates to:
  /// **'ألوان ناصعة ومريحة في النهار'**
  String get lightModeDesc;

  /// No description provided for @languageSection.
  ///
  /// In ar, this message translates to:
  /// **'اللغة (Language)'**
  String get languageSection;

  /// No description provided for @arabicLang.
  ///
  /// In ar, this message translates to:
  /// **'العربية (Arabic)'**
  String get arabicLang;

  /// No description provided for @arabicLangDesc.
  ///
  /// In ar, this message translates to:
  /// **'اللغة الافتراضية مع دعم RTL'**
  String get arabicLangDesc;

  /// No description provided for @englishLang.
  ///
  /// In ar, this message translates to:
  /// **'English (الإنجليزية)'**
  String get englishLang;

  /// No description provided for @englishLangDesc.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى الواجهة الإنجليزية'**
  String get englishLangDesc;

  /// No description provided for @aboutSection.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق والخدمة'**
  String get aboutSection;

  /// No description provided for @aboutServiceDesc.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق مخصص لخدمة وافتقاد مخدومي فصل البابا كيرلس السادس، يساعد الخدام وأمين الخدمة على رعاية وتدوين افتقاد كل نفس بمحبة وأمانة.'**
  String get aboutServiceDesc;

  /// No description provided for @accountSection.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحساب'**
  String get accountSection;

  /// No description provided for @signOutAccountDesc.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من الحساب الحالي والعودة لشاشة الدخول'**
  String get signOutAccountDesc;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات الخادم وفك ارتباط الأولاد المسندين'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteAccountWarningPrompt.
  ///
  /// In ar, this message translates to:
  /// **'أنت على وشك حذف حسابك نهائياً من نظام الافتقاد.'**
  String get deleteAccountWarningPrompt;

  /// No description provided for @deleteAccountPoints.
  ///
  /// In ar, this message translates to:
  /// **'• سيتم فك ارتباط جميع الأولاد المسندين لك وإعادتهم للأولاد غير الموزعين ليتمكن أمين الخدمة من إعادة توزيعهم.\n• سيتم مسح بياناتك نهائياً من قاعدة البيانات.\n• هذا الإجراء لا يمكن التراجع عنه.'**
  String get deleteAccountPoints;

  /// No description provided for @deleteAccountConfirmBtn.
  ///
  /// In ar, this message translates to:
  /// **'نعم، احذف الحساب'**
  String get deleteAccountConfirmBtn;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب بنجاح'**
  String get accountDeletedSuccess;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حذف الحساب: {err} (قد يتطلب إعادة تسجيل الدخول للتأكيد الأمني)'**
  String deleteAccountFailed(String err);

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileTitle;

  /// No description provided for @verifiedServantBadge.
  ///
  /// In ar, this message translates to:
  /// **'خادم معتمد'**
  String get verifiedServantBadge;

  /// No description provided for @assignedCountInCare.
  ///
  /// In ar, this message translates to:
  /// **'{count} مخدومين بمسؤوليتك'**
  String assignedCountInCare(int count);

  /// No description provided for @personalInfoSection.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الشخصية'**
  String get personalInfoSection;

  /// No description provided for @servantFullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الخادم بالكامل'**
  String get servantFullNameLabel;

  /// No description provided for @servantNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم الخادم'**
  String get servantNameRequired;

  /// No description provided for @servantPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف المحمول'**
  String get servantPhoneLabel;

  /// No description provided for @servantPhoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم الهاتف'**
  String get servantPhoneRequired;

  /// No description provided for @googleEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (Google)'**
  String get googleEmailLabel;

  /// No description provided for @emailReadOnlyNote.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مرتبط بحساب Google ولا يمكن تعديله'**
  String get emailReadOnlyNote;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get saveChanges;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث بياناتك بنجاح!'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء حفظ البيانات: {err}'**
  String profileUpdateError(String err);

  /// No description provided for @servantGreeting.
  ///
  /// In ar, this message translates to:
  /// **'سلام ونعمة يا أ/ {name}'**
  String servantGreeting(String name);

  /// No description provided for @visitedRatio.
  ///
  /// In ar, this message translates to:
  /// **'تم افتقاد {v} من {t} مخدوم'**
  String visitedRatio(int v, int t);

  /// No description provided for @searchMyMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في مخدوميك بالاسم أو المنطقة...'**
  String get searchMyMakhdomeen;

  /// No description provided for @filterVisited.
  ///
  /// In ar, this message translates to:
  /// **'تم افتقادهم'**
  String get filterVisited;

  /// No description provided for @filterUnvisited.
  ///
  /// In ar, this message translates to:
  /// **'لم يفتقدوا بعد'**
  String get filterUnvisited;

  /// No description provided for @filterBrethren.
  ///
  /// In ar, this message translates to:
  /// **'أخوة الرب'**
  String get filterBrethren;

  /// No description provided for @filterMyMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'مخدوميني'**
  String get filterMyMakhdomeen;

  /// No description provided for @noMakhdomeenAssignedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مخدومين مسندين إليك حالياً'**
  String get noMakhdomeenAssignedTitle;

  /// No description provided for @noMakhdomeenAssignedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سيتولى أمين الخدمة توزيع الأولاد عليك قريباً'**
  String get noMakhdomeenAssignedSubtitle;

  /// No description provided for @logVisitTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل افتقاد جديد'**
  String get logVisitTitle;

  /// No description provided for @visitTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الافتقاد:'**
  String get visitTypeLabel;

  /// No description provided for @visitHome.
  ///
  /// In ar, this message translates to:
  /// **'🏠 زيارة منزلية'**
  String get visitHome;

  /// No description provided for @visitPhone.
  ///
  /// In ar, this message translates to:
  /// **'📞 مكالمة تليفونية'**
  String get visitPhone;

  /// No description provided for @visitChurch.
  ///
  /// In ar, this message translates to:
  /// **'⛪ لقاء في الكنيسة'**
  String get visitChurch;

  /// No description provided for @visitOther.
  ///
  /// In ar, this message translates to:
  /// **'💬 رسالة / أخرى'**
  String get visitOther;

  /// No description provided for @visitDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الافتقاد: {date}'**
  String visitDateLabel(String date);

  /// No description provided for @visitNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الافتقاد (اختياري)...'**
  String get visitNotesHint;

  /// No description provided for @saveVisitBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الافتقاد'**
  String get saveVisitBtn;

  /// No description provided for @visitSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الافتقاد بنجاح! ✝️'**
  String get visitSavedSuccess;

  /// No description provided for @visitSaveError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ أثناء تسجيل الافتقاد: {err}'**
  String visitSaveError(String err);

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم المسؤول'**
  String get adminDashboardTitle;

  /// No description provided for @makhdomeenAndKhodamSummary.
  ///
  /// In ar, this message translates to:
  /// **'{m} مخدوم • {k} خدام'**
  String makhdomeenAndKhodamSummary(int m, int k);

  /// No description provided for @tabMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'المخدومين ({count})'**
  String tabMakhdomeen(int count);

  /// No description provided for @tabAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'التحليلات والمتابعة'**
  String get tabAnalytics;

  /// No description provided for @tabKhodam.
  ///
  /// In ar, this message translates to:
  /// **'الخدام ({count})'**
  String tabKhodam(int count);

  /// No description provided for @searchAdminHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم، المنطقة، الهاتف، أو المدرسة...'**
  String get searchAdminHint;

  /// No description provided for @filterUnassigned.
  ///
  /// In ar, this message translates to:
  /// **'بدون خادم'**
  String get filterUnassigned;

  /// No description provided for @deleteMakhdomTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get deleteMakhdomTitle;

  /// No description provided for @deleteMakhdomPrompt.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف المخدوم ({name}) نهائياً؟'**
  String deleteMakhdomPrompt(String name);

  /// No description provided for @makhdomDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المخدوم بنجاح'**
  String get makhdomDeletedSuccess;

  /// No description provided for @makhdomUnassignedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء ربط ({name}) بالخادم'**
  String makhdomUnassignedSuccess(String name);

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة للبحث أو الفلتر'**
  String get noSearchResults;

  /// No description provided for @assignSelectedMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'إسناد المحددين'**
  String get assignSelectedMakhdomeen;

  /// No description provided for @totalCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalCountBadge;

  /// No description provided for @addMakhdomBtn.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مخدوم'**
  String get addMakhdomBtn;

  /// No description provided for @servantGroupHeader.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة: {name}'**
  String servantGroupHeader(String name);

  /// No description provided for @servantGroupSubheader.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتحديد وتوزيع الأولاد على هذا الخادم'**
  String get servantGroupSubheader;

  /// No description provided for @assignChildrenBtn.
  ///
  /// In ar, this message translates to:
  /// **'توزيع أولاد'**
  String get assignChildrenBtn;

  /// No description provided for @noMatchingMakhdomeenPrompt.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تغيير كلمات البحث أو اختيار فلتر آخر'**
  String get noMatchingMakhdomeenPrompt;

  /// No description provided for @brethrenBadge.
  ///
  /// In ar, this message translates to:
  /// **'أخوة الرب'**
  String get brethrenBadge;

  /// No description provided for @unassignedBadge.
  ///
  /// In ar, this message translates to:
  /// **'بدون خادم'**
  String get unassignedBadge;

  /// No description provided for @servantBadge.
  ///
  /// In ar, this message translates to:
  /// **'خادم: {name}'**
  String servantBadge(String name);

  /// No description provided for @notVisitedYetBadge.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم افتقاده'**
  String get notVisitedYetBadge;

  /// No description provided for @lastVisitBadge.
  ///
  /// In ar, this message translates to:
  /// **'آخر افتقاد: {date} ({count} مرات)'**
  String lastVisitBadge(String date, int count);

  /// No description provided for @visitCountSummary.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد افتقادات} =1{افتقاد واحد} =2{افتقادان} few{{count} افتقادات} many{{count} افتقاداً} other{{count} افتقاد}}'**
  String visitCountSummary(int count);

  /// No description provided for @details.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل'**
  String get details;

  /// No description provided for @less.
  ///
  /// In ar, this message translates to:
  /// **'أقل'**
  String get less;

  /// No description provided for @callAction.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get callAction;

  /// No description provided for @whatsappAction.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsappAction;

  /// No description provided for @mapAction.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get mapAction;

  /// No description provided for @visitAction.
  ///
  /// In ar, this message translates to:
  /// **'افتقاد'**
  String get visitAction;

  /// No description provided for @familyDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الأسرة'**
  String get familyDetails;

  /// No description provided for @fatherPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'تليفون الأب:'**
  String get fatherPhoneLabel;

  /// No description provided for @motherPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'تليفون الأم:'**
  String get motherPhoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان:'**
  String get addressLabel;

  /// No description provided for @schoolLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدرسة:'**
  String get schoolLabel;

  /// No description provided for @birthDateDetailLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد:'**
  String get birthDateDetailLabel;

  /// No description provided for @ageYearsOld.
  ///
  /// In ar, this message translates to:
  /// **'{age} سنة'**
  String ageYearsOld(int age);

  /// No description provided for @notesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات:'**
  String get notesLabel;

  /// No description provided for @editDetailsAction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البيانات'**
  String get editDetailsAction;

  /// No description provided for @unassignServantAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الإسناد من الخادم'**
  String get unassignServantAction;

  /// No description provided for @deleteMakhdomAction.
  ///
  /// In ar, this message translates to:
  /// **'حذف المخدوم نهائياً'**
  String get deleteMakhdomAction;

  /// No description provided for @historyAction.
  ///
  /// In ar, this message translates to:
  /// **'سجل الافتقاد والحضور'**
  String get historyAction;

  /// No description provided for @makhdomHistorySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل تفصيلي للافتقادات والحضور وأثر الافتقاد على الحضور'**
  String get makhdomHistorySubtitle;

  /// No description provided for @totalVisitsLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الافتقادات'**
  String get totalVisitsLabel;

  /// No description provided for @massAttendanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'حضور القداس'**
  String get massAttendanceLabel;

  /// No description provided for @serviceAttendanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'حضور الخدمة'**
  String get serviceAttendanceLabel;

  /// No description provided for @visitSuccessRateLabel.
  ///
  /// In ar, this message translates to:
  /// **'أثر الافتقاد'**
  String get visitSuccessRateLabel;

  /// No description provided for @filterAllLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAllLabel;

  /// No description provided for @filterVisitsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الافتقادات فقط'**
  String get filterVisitsLabel;

  /// No description provided for @filterAttendanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحضور والغياب'**
  String get filterAttendanceLabel;

  /// No description provided for @filterFruitfulLabel.
  ///
  /// In ar, this message translates to:
  /// **'أثمرت بحضور الجمعة ✅'**
  String get filterFruitfulLabel;

  /// No description provided for @filterAbsencesLabel.
  ///
  /// In ar, this message translates to:
  /// **'جمعات الغياب ❌'**
  String get filterAbsencesLabel;

  /// No description provided for @filterAllTime.
  ///
  /// In ar, this message translates to:
  /// **'كل الأوقات'**
  String get filterAllTime;

  /// No description provided for @filterLast30Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 30 يوم'**
  String get filterLast30Days;

  /// No description provided for @filterLast90Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 3 أشهر'**
  String get filterLast90Days;

  /// No description provided for @filterCustomDate.
  ///
  /// In ar, this message translates to:
  /// **'تحديد فترة...'**
  String get filterCustomDate;

  /// No description provided for @nextFridayTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة التالية للافتقاد'**
  String get nextFridayTitle;

  /// No description provided for @fruitfulVisitBadge.
  ///
  /// In ar, this message translates to:
  /// **'أثمر الافتقاد: حضر القداس والخدمة 🌟'**
  String get fruitfulVisitBadge;

  /// No description provided for @attendedServiceOnlyBadge.
  ///
  /// In ar, this message translates to:
  /// **'حضر الخدمة فقط'**
  String get attendedServiceOnlyBadge;

  /// No description provided for @attendedMassOnlyBadge.
  ///
  /// In ar, this message translates to:
  /// **'حضر القداس فقط'**
  String get attendedMassOnlyBadge;

  /// No description provided for @missedNextFridayBadge.
  ///
  /// In ar, this message translates to:
  /// **'غائب عن القداس والخدمة ⚠️'**
  String get missedNextFridayBadge;

  /// No description provided for @pendingNextFridayBadge.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار الجمعة القادمة ⏳'**
  String get pendingNextFridayBadge;

  /// No description provided for @noSessionsNextFridayBadge.
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل جلسات لهذه الجمعة'**
  String get noSessionsNextFridayBadge;

  /// No description provided for @fridayRecordTitle.
  ///
  /// In ar, this message translates to:
  /// **'يوم الجمعة'**
  String get fridayRecordTitle;

  /// No description provided for @attendedMassStatus.
  ///
  /// In ar, this message translates to:
  /// **'القداس: حاضر ✅'**
  String get attendedMassStatus;

  /// No description provided for @absentMassStatus.
  ///
  /// In ar, this message translates to:
  /// **'القداس: غائب ❌'**
  String get absentMassStatus;

  /// No description provided for @attendedServiceStatus.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة: حاضر ✅'**
  String get attendedServiceStatus;

  /// No description provided for @absentServiceStatus.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة: غائب ❌'**
  String get absentServiceStatus;

  /// No description provided for @precededByVisitBadge.
  ///
  /// In ar, this message translates to:
  /// **'✨ سُبق بافتقاد ({type}) بواسطة {servant} في {date}'**
  String precededByVisitBadge(String type, String servant, String date);

  /// No description provided for @noRecordsFoundForFilter.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سجلات مطابقة للفلاتر المحددة'**
  String get noRecordsFoundForFilter;

  /// No description provided for @logNewVisitButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل افتقاد جديد'**
  String get logNewVisitButton;

  /// No description provided for @makhdomProfileDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المخدوم الكاملة'**
  String get makhdomProfileDetails;

  /// No description provided for @makhdomProfileHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء التفاصيل'**
  String get makhdomProfileHide;

  /// No description provided for @makhdomProfileShow.
  ///
  /// In ar, this message translates to:
  /// **'عرض كافة البيانات'**
  String get makhdomProfileShow;

  /// No description provided for @academicAndAgeInfo.
  ///
  /// In ar, this message translates to:
  /// **'الدراسة والمرحلة والسن'**
  String get academicAndAgeInfo;

  /// No description provided for @residenceAndAddressInfo.
  ///
  /// In ar, this message translates to:
  /// **'السكن والعنوان واللوكيشن'**
  String get residenceAndAddressInfo;

  /// No description provided for @familyAndContactsInfo.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل والعائلة'**
  String get familyAndContactsInfo;

  /// No description provided for @registrationDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ القيد بالخدمة:'**
  String get registrationDateLabel;

  /// No description provided for @estimatedAgeLabel.
  ///
  /// In ar, this message translates to:
  /// **'عمر تقديري'**
  String get estimatedAgeLabel;

  /// No description provided for @realBirthDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ ميلاد موثق'**
  String get realBirthDateLabel;

  /// No description provided for @notSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSpecified;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In ar, this message translates to:
  /// **'فتح في خرائط Google'**
  String get openInGoogleMaps;

  /// No description provided for @pastoralNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات رعوية خاصة'**
  String get pastoralNotes;

  /// No description provided for @fatherLabel.
  ///
  /// In ar, this message translates to:
  /// **'والد المخدوم (الأب)'**
  String get fatherLabel;

  /// No description provided for @motherLabel.
  ///
  /// In ar, this message translates to:
  /// **'والدة المخدوم (الأم)'**
  String get motherLabel;

  /// No description provided for @studentPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'هاتف المخدوم'**
  String get studentPhoneLabel;

  /// No description provided for @copyPhoneSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرقم بنجاح'**
  String get copyPhoneSuccess;

  /// No description provided for @copyAddressSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ العنوان بنجاح'**
  String get copyAddressSuccess;

  /// No description provided for @editMakhdomTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات مخدوم'**
  String get editMakhdomTitle;

  /// No description provided for @addMakhdomTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مخدوم جديد'**
  String get addMakhdomTitle;

  /// No description provided for @personalAndContactSec.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الشخصية والاتصال'**
  String get personalAndContactSec;

  /// No description provided for @fullNameRequiredLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل *'**
  String get fullNameRequiredLabel;

  /// No description provided for @fullNameValidation.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم المخدوم بالكامل'**
  String get fullNameValidation;

  /// No description provided for @makhdomPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف (المخدوم)'**
  String get makhdomPhoneLabel;

  /// No description provided for @birthDateInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get birthDateInputLabel;

  /// No description provided for @selectBirthDateHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لاختيار تاريخ الميلاد'**
  String get selectBirthDateHint;

  /// No description provided for @phoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'رقم التليفون مطلوب'**
  String get phoneRequired;

  /// No description provided for @saving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ...'**
  String get saving;

  /// No description provided for @fatherPhoneInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'تليفون الأب'**
  String get fatherPhoneInputLabel;

  /// No description provided for @motherPhoneInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'تليفون الأم'**
  String get motherPhoneInputLabel;

  /// No description provided for @residenceAndSchoolSec.
  ///
  /// In ar, this message translates to:
  /// **'السكن والتعليم'**
  String get residenceAndSchoolSec;

  /// No description provided for @residentialAreaLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة السكنية'**
  String get residentialAreaLabel;

  /// No description provided for @detailedAddressLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالتفصيل'**
  String get detailedAddressLabel;

  /// No description provided for @schoolNameInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم المدرسة'**
  String get schoolNameInputLabel;

  /// No description provided for @secondaryTypeInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الثانوية'**
  String get secondaryTypeInputLabel;

  /// No description provided for @googleMapsUrlLabel.
  ///
  /// In ar, this message translates to:
  /// **'رابط موقع المنزل (Google Maps)'**
  String get googleMapsUrlLabel;

  /// No description provided for @useCurrentLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي الحالي'**
  String get useCurrentLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض إذن الموقع'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض دائماً، يرجى تفعيله من الإعدادات'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get openSettings;

  /// No description provided for @locationFetchedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'✓ تم جلب الموقع بنجاح'**
  String get locationFetchedSuccess;

  /// No description provided for @locationError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في جلب الموقع'**
  String get locationError;

  /// No description provided for @serviceAndCareSec.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة والتوزيع والرعاية'**
  String get serviceAndCareSec;

  /// No description provided for @assignedServantSelectLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المسؤول عن الافتقاد'**
  String get assignedServantSelectLabel;

  /// No description provided for @unassignedNoServantOption.
  ///
  /// In ar, this message translates to:
  /// **'بدون خادم (غير موزع)'**
  String get unassignedNoServantOption;

  /// No description provided for @brethrenSwitchLabel.
  ///
  /// In ar, this message translates to:
  /// **'أخوة الرب (رعاية خاصة ومحبة)'**
  String get brethrenSwitchLabel;

  /// No description provided for @brethrenSwitchSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تمييز الحالة لتوفير اهتمام ورعاية استثنائية'**
  String get brethrenSwitchSublabel;

  /// No description provided for @photoUrlOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'رابط الصورة الشخصية (اختياري)'**
  String get photoUrlOptionalLabel;

  /// No description provided for @additionalNotesOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات إضافية (اختياري)'**
  String get additionalNotesOptionalLabel;

  /// No description provided for @makhdomSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ بيانات المخدوم بنجاح'**
  String get makhdomSavedSuccess;

  /// No description provided for @makhdomSaveError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ أثناء الحفظ: {err}'**
  String makhdomSaveError(String err);

  /// No description provided for @assignModalHeader.
  ///
  /// In ar, this message translates to:
  /// **'توزيع المخدومين على {name}'**
  String assignModalHeader(String name);

  /// No description provided for @selectAll.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التحديد'**
  String get deselectAll;

  /// No description provided for @searchByNameOrArea.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو المنطقة...'**
  String get searchByNameOrArea;

  /// No description provided for @conflictWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه نقل مخدومين'**
  String get conflictWarningTitle;

  /// No description provided for @conflictWarningSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'هناك مخدومين تم تحديدهم وهم مسندين بالفعل لخدام آخرين، هل تود نقلهم؟'**
  String get conflictWarningSubtitle;

  /// No description provided for @conflictWarningTransferCount.
  ///
  /// In ar, this message translates to:
  /// **'أنت على وشك نقل {count} مخدوم مربوطين حالياً بخدام آخرين إلى ({name}):'**
  String conflictWarningTransferCount(int count, String name);

  /// No description provided for @confirmTransferQuestion.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد بالتأكيد نقلهم وتحديث قاعدة البيانات؟'**
  String get confirmTransferQuestion;

  /// No description provided for @otherServant.
  ///
  /// In ar, this message translates to:
  /// **'خادم آخر'**
  String get otherServant;

  /// No description provided for @resultsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد النتائج: {count}'**
  String resultsCount(int count);

  /// No description provided for @saveAssignmentsWithCount.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التوزيع وتأكيد ({count}) مخدوم'**
  String saveAssignmentsWithCount(int count);

  /// No description provided for @conflictTransferBtn.
  ///
  /// In ar, this message translates to:
  /// **'نعم، تأكيد النقل'**
  String get conflictTransferBtn;

  /// No description provided for @conflictKeepBtn.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get conflictKeepBtn;

  /// No description provided for @saveAssignmentsBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التوزيع'**
  String get saveAssignmentsBtn;

  /// No description provided for @assignmentsSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث وحفظ توزيع المخدومين بنجاح'**
  String get assignmentsSavedSuccess;

  /// No description provided for @excelSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة ملفات Excel'**
  String get excelSheetTitle;

  /// No description provided for @excelDownloadTemplate.
  ///
  /// In ar, this message translates to:
  /// **'تحميل قالب إكسيل فارغ'**
  String get excelDownloadTemplate;

  /// No description provided for @excelDownloadTemplateDesc.
  ///
  /// In ar, this message translates to:
  /// **'قالب جاهز بالأعمدة لملء بيانات المخدومين بسهولة'**
  String get excelDownloadTemplateDesc;

  /// No description provided for @excelImportMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'استيراد مخدومين من إكسيل'**
  String get excelImportMakhdomeen;

  /// No description provided for @excelImportMakhdomeenDesc.
  ///
  /// In ar, this message translates to:
  /// **'قراءة ملف إكسيل وإضافة المخدومين لقاعدة البيانات'**
  String get excelImportMakhdomeenDesc;

  /// No description provided for @excelExportMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'تصدير المخدومين إلى إكسيل'**
  String get excelExportMakhdomeen;

  /// No description provided for @excelExportMakhdomeenDesc.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل ملف إكسيل بجميع المخدومين وحالات الافتقاد'**
  String get excelExportMakhdomeenDesc;

  /// No description provided for @excelConfirmImportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاستيراد'**
  String get excelConfirmImportTitle;

  /// No description provided for @excelConfirmImportPrompt.
  ///
  /// In ar, this message translates to:
  /// **'تم العثور على ({count}) مخدوم في الشيت. هل تريد استيرادهم وإضافتهم إلى قاعدة البيانات الآن؟'**
  String excelConfirmImportPrompt(int count);

  /// No description provided for @excelImportNowBtn.
  ///
  /// In ar, this message translates to:
  /// **'استيراد الآن'**
  String get excelImportNowBtn;

  /// No description provided for @excelImportSuccessMsg.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد ({count}) مخدوم بنجاح!'**
  String excelImportSuccessMsg(int count);

  /// No description provided for @excelEmptyOrCanceled.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مخدومين في الملف أو تم إلغاء الاختيار'**
  String get excelEmptyOrCanceled;

  /// No description provided for @performanceAndCareIndicators.
  ///
  /// In ar, this message translates to:
  /// **'مؤشرات الأداء والرعاية'**
  String get performanceAndCareIndicators;

  /// No description provided for @liveFollowupAndRates.
  ///
  /// In ar, this message translates to:
  /// **'متابعة حية ونسب إنجاز خدام الفصل'**
  String get liveFollowupAndRates;

  /// No description provided for @noAnalyticsData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات كافية لعرض التحليلات'**
  String get noAnalyticsData;

  /// No description provided for @totalMakhdomeenStat.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المخدومين'**
  String get totalMakhdomeenStat;

  /// No description provided for @visitedAtLeastOnceStat.
  ///
  /// In ar, this message translates to:
  /// **'تم افتقادهم'**
  String get visitedAtLeastOnceStat;

  /// No description provided for @neverVisitedStat.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفتقدوا'**
  String get neverVisitedStat;

  /// No description provided for @brethrenStat.
  ///
  /// In ar, this message translates to:
  /// **'أخوة الرب'**
  String get brethrenStat;

  /// No description provided for @overallVisitRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الافتقاد العامة'**
  String get overallVisitRate;

  /// No description provided for @servantsLeaderboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة إنجاز الخدام'**
  String get servantsLeaderboard;

  /// No description provided for @rankedByVisitRate.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الخدام بحسب نسبة الافتقاد لمجموعاتهم'**
  String get rankedByVisitRate;

  /// No description provided for @urgentFollowupNeverVisited.
  ///
  /// In ar, this message translates to:
  /// **'متابعة عاجلة: لم يتم افتقادهم نهائياً'**
  String get urgentFollowupNeverVisited;

  /// No description provided for @urgentCountNeedingVisit.
  ///
  /// In ar, this message translates to:
  /// **'{count} مخدوم بحاجة لافتقاد سريع'**
  String urgentCountNeedingVisit(int count);

  /// No description provided for @activeServantsStat.
  ///
  /// In ar, this message translates to:
  /// **'خدام نشطون'**
  String get activeServantsStat;

  /// No description provided for @totalMakhdomeenTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المخدومين'**
  String get totalMakhdomeenTitle;

  /// No description provided for @totalBoysAssignedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{count} مسند لخادم'**
  String totalBoysAssignedSubtitle(int count);

  /// No description provided for @visitationRateTitle.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الافتقاد العامة'**
  String get visitationRateTitle;

  /// No description provided for @visitedBoysCountSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{count} تم افتقادهم'**
  String visitedBoysCountSubtitle(int count);

  /// No description provided for @neverVisitedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفتقدوا'**
  String get neverVisitedTitle;

  /// No description provided for @needsUrgentVisitSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بحاجة لافتقاد سريع'**
  String get needsUrgentVisitSubtitle;

  /// No description provided for @brethrenOfLordTitle.
  ///
  /// In ar, this message translates to:
  /// **'أخوة الرب'**
  String get brethrenOfLordTitle;

  /// No description provided for @specialFollowupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رعاية وافتقاد خاص'**
  String get specialFollowupSubtitle;

  /// No description provided for @visitationDistributionTitle.
  ///
  /// In ar, this message translates to:
  /// **'توزيع نسب الافتقاد'**
  String get visitationDistributionTitle;

  /// No description provided for @servantsAchievementRatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'نسب إنجاز الخدام'**
  String get servantsAchievementRatesTitle;

  /// No description provided for @noKhodamYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خدام مسجلين بعد'**
  String get noKhodamYet;

  /// No description provided for @unvisitedChildrenHeader.
  ///
  /// In ar, this message translates to:
  /// **'مخدومون لم يتم افتقادهم ({count})'**
  String unvisitedChildrenHeader(int count);

  /// No description provided for @assignedToKhademLabel.
  ///
  /// In ar, this message translates to:
  /// **'مسند إلى: {name}'**
  String assignedToKhademLabel(String name);

  /// No description provided for @noKhodamRegisteredYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خدام مسجلين بعد'**
  String get noKhodamRegisteredYet;

  /// No description provided for @khodamAutoAppearNote.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر الخدام هنا تلقائياً بمجرد تسجيل دخولهم لأول مرة بحساب Google الخاص بهم.'**
  String get khodamAutoAppearNote;

  /// No description provided for @assignMakhdomeenActionBtn.
  ///
  /// In ar, this message translates to:
  /// **'توزيع وإسناد المخدومين'**
  String get assignMakhdomeenActionBtn;

  /// No description provided for @assignedMakhdomeenCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} مخدوم مسند'**
  String assignedMakhdomeenCount(int count);

  /// No description provided for @visitedOfTotalCount.
  ///
  /// In ar, this message translates to:
  /// **'{v} من {t} تم افتقادهم'**
  String visitedOfTotalCount(int v, int t);

  /// No description provided for @grade1stName.
  ///
  /// In ar, this message translates to:
  /// **'أولى ثانوي'**
  String get grade1stName;

  /// No description provided for @grade2ndName.
  ///
  /// In ar, this message translates to:
  /// **'ثانية ثانوي'**
  String get grade2ndName;

  /// No description provided for @grade3rdName.
  ///
  /// In ar, this message translates to:
  /// **'ثالثة ثانوي'**
  String get grade3rdName;

  /// No description provided for @allGrades.
  ///
  /// In ar, this message translates to:
  /// **'كل السنين'**
  String get allGrades;

  /// No description provided for @gradeLabel.
  ///
  /// In ar, this message translates to:
  /// **'السنة الدراسية'**
  String get gradeLabel;

  /// No description provided for @stageAdminTitle.
  ///
  /// In ar, this message translates to:
  /// **'أمين مرحلة ثانوي'**
  String get stageAdminTitle;

  /// No description provided for @gradeAdminTitle.
  ///
  /// In ar, this message translates to:
  /// **'أمين {grade}'**
  String gradeAdminTitle(String grade);

  /// No description provided for @servantRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'خادم'**
  String get servantRoleLabel;

  /// No description provided for @pendingRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'قيد التسكين'**
  String get pendingRoleLabel;

  /// No description provided for @pendingWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك يا خادم المسيح في أسرة مرحلة ثانوي ✝️'**
  String get pendingWelcome;

  /// No description provided for @pendingStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار تسكينك وتوزيعك'**
  String get pendingStatusTitle;

  /// No description provided for @pendingStatusDesc.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل حسابك بنجاح. سيتولى أمين مرحلة ثانوي تسكينك في سنتك الدراسية (أولى، ثانية، أو ثالثة ثانوي) قريباً.'**
  String get pendingStatusDesc;

  /// No description provided for @completeProfilePrompt.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد بياناتك الشخصية لتسهيل التعرف عليك:'**
  String get completeProfilePrompt;

  /// No description provided for @updateAndSave.
  ///
  /// In ar, this message translates to:
  /// **'تحديث وحفظ'**
  String get updateAndSave;

  /// No description provided for @stageDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة أمانة مرحلة ثانوي'**
  String get stageDashboardTitle;

  /// No description provided for @tabGradesAndServants.
  ///
  /// In ar, this message translates to:
  /// **'الخدام والتسكين'**
  String get tabGradesAndServants;

  /// No description provided for @tabStageAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'تحليلات المرحلة'**
  String get tabStageAnalytics;

  /// No description provided for @tabStageTasks.
  ///
  /// In ar, this message translates to:
  /// **'مهام المرحلة'**
  String get tabStageTasks;

  /// No description provided for @pendingServantsSection.
  ///
  /// In ar, this message translates to:
  /// **'خدام جدد بانتظار التسكين'**
  String get pendingServantsSection;

  /// No description provided for @gradeHeadsSection.
  ///
  /// In ar, this message translates to:
  /// **'أمناء السنين الدراسية'**
  String get gradeHeadsSection;

  /// No description provided for @appointGradeHeadBtn.
  ///
  /// In ar, this message translates to:
  /// **'تعيين أمين السنة'**
  String get appointGradeHeadBtn;

  /// No description provided for @changeGradeHeadBtn.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الأمين'**
  String get changeGradeHeadBtn;

  /// No description provided for @noGradeHeadAssigned.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تعيين أمين بعد'**
  String get noGradeHeadAssigned;

  /// No description provided for @assignServantToGradePrompt.
  ///
  /// In ar, this message translates to:
  /// **'تسكين الخادم في سنة دراسية'**
  String get assignServantToGradePrompt;

  /// No description provided for @selectGradePrompt.
  ///
  /// In ar, this message translates to:
  /// **'اختر السنة الدراسية:'**
  String get selectGradePrompt;

  /// No description provided for @servantAssignedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسكين الخادم بنجاح!'**
  String get servantAssignedSuccess;

  /// No description provided for @gradeHeadUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين أمين السنة بنجاح!'**
  String get gradeHeadUpdatedSuccess;

  /// No description provided for @gradeDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة أمانة {grade}'**
  String gradeDashboardTitle(String grade);

  /// No description provided for @tabGradeMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'المخدومين'**
  String get tabGradeMakhdomeen;

  /// No description provided for @tabGradeAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'التحليلات'**
  String get tabGradeAnalytics;

  /// No description provided for @tabGradeServants.
  ///
  /// In ar, this message translates to:
  /// **'خدام السنة'**
  String get tabGradeServants;

  /// No description provided for @tabGradeTasks.
  ///
  /// In ar, this message translates to:
  /// **'مهام السنة'**
  String get tabGradeTasks;

  /// No description provided for @myTasksTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهامي المكلف بها'**
  String get myTasksTitle;

  /// No description provided for @addTaskTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مهمة جديدة'**
  String get addTaskTitle;

  /// No description provided for @taskTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان المهمة *'**
  String get taskTitleLabel;

  /// No description provided for @taskTitleRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى كتابة عنوان المهمة'**
  String get taskTitleRequired;

  /// No description provided for @taskDescLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المهمة (اختياري)'**
  String get taskDescLabel;

  /// No description provided for @taskAssigneeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المكلف *'**
  String get taskAssigneeLabel;

  /// No description provided for @taskTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع المهمة'**
  String get taskTypeLabel;

  /// No description provided for @taskTypeGeneral.
  ///
  /// In ar, this message translates to:
  /// **'مهمة عامة (تحضير/نشاط)'**
  String get taskTypeGeneral;

  /// No description provided for @taskTypeAttendance.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور وغياب'**
  String get taskTypeAttendance;

  /// No description provided for @taskTypeVisitation.
  ///
  /// In ar, this message translates to:
  /// **'افتقاد خاص'**
  String get taskTypeVisitation;

  /// No description provided for @taskCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة المهمة بنجاح!'**
  String get taskCreatedSuccess;

  /// No description provided for @noTasksYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام مسندة حالياً'**
  String get noTasksYet;

  /// No description provided for @completedTasksSection.
  ///
  /// In ar, this message translates to:
  /// **'مهام تم إنجازها'**
  String get completedTasksSection;

  /// No description provided for @pendingTasksSection.
  ///
  /// In ar, this message translates to:
  /// **'مهام قيد التنفيذ'**
  String get pendingTasksSection;

  /// No description provided for @taskCompletedMsg.
  ///
  /// In ar, this message translates to:
  /// **'تم إنجاز المهمة بنجاح! ✝️'**
  String get taskCompletedMsg;

  /// No description provided for @taskReopenedMsg.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة فتح المهمة'**
  String get taskReopenedMsg;

  /// No description provided for @reopenAttendance.
  ///
  /// In ar, this message translates to:
  /// **'إعادة فتح الحضور'**
  String get reopenAttendance;

  /// No description provided for @reopenAttendanceAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الفتح'**
  String get reopenAttendanceAction;

  /// No description provided for @reopenReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب إعادة الفتح'**
  String get reopenReason;

  /// No description provided for @deleteTaskPrompt.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذه المهمة نهائياً؟'**
  String get deleteTaskPrompt;

  /// No description provided for @taskTypeAttendanceKhedma.
  ///
  /// In ar, this message translates to:
  /// **'حضور الخدمة'**
  String get taskTypeAttendanceKhedma;

  /// No description provided for @taskTypeAttendanceQoddas.
  ///
  /// In ar, this message translates to:
  /// **'حضور القداس'**
  String get taskTypeAttendanceQoddas;

  /// No description provided for @takeAttendanceAction.
  ///
  /// In ar, this message translates to:
  /// **'بدء رصد الحضور 📋'**
  String get takeAttendanceAction;

  /// No description provided for @attendanceScreenTitleService.
  ///
  /// In ar, this message translates to:
  /// **'رصد حضور الخدمة'**
  String get attendanceScreenTitleService;

  /// No description provided for @attendanceScreenTitleMass.
  ///
  /// In ar, this message translates to:
  /// **'رصد حضور القداس'**
  String get attendanceScreenTitleMass;

  /// No description provided for @totalAttendedCount.
  ///
  /// In ar, this message translates to:
  /// **'الحضور: {attended} / {total}'**
  String totalAttendedCount(int attended, int total);

  /// No description provided for @selectedAttendedHeader.
  ///
  /// In ar, this message translates to:
  /// **'الحاضرون الآن'**
  String get selectedAttendedHeader;

  /// No description provided for @noAttendedYetHint.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد أي مخدوم بعد • علم بالأسفل'**
  String get noAttendedYetHint;

  /// No description provided for @searchAttendanceHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الهاتف...'**
  String get searchAttendanceHint;

  /// No description provided for @fridayOnlyWarning.
  ///
  /// In ar, this message translates to:
  /// **'يتم رصد الحضور أيام الجمعة فقط'**
  String get fridayOnlyWarning;

  /// No description provided for @scheduleMassAttendanceBtn.
  ///
  /// In ar, this message translates to:
  /// **'جدولة حضور قداس الجمعة ⛪'**
  String get scheduleMassAttendanceBtn;

  /// No description provided for @scheduleMassAttendanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'جدولة حضور قداس مرحلة ثانوي'**
  String get scheduleMassAttendanceTitle;

  /// No description provided for @scheduleMassAttendanceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخ الجمعة والخادم المكلف برصد حضور كل السنين'**
  String get scheduleMassAttendanceSubtitle;

  /// No description provided for @notAuthorizedAttendance.
  ///
  /// In ar, this message translates to:
  /// **'عفواً، هذه المهمة مخصصة لخادم آخر'**
  String get notAuthorizedAttendance;

  /// No description provided for @autoSavedNotice.
  ///
  /// In ar, this message translates to:
  /// **'يتم الحفظ تلقائياً'**
  String get autoSavedNotice;

  /// No description provided for @tabVisitsAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'مؤشرات الافتقاد'**
  String get tabVisitsAnalytics;

  /// No description provided for @tabAttendanceAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'مؤشرات الحضور'**
  String get tabAttendanceAnalytics;

  /// No description provided for @tabSmartInsights.
  ///
  /// In ar, this message translates to:
  /// **'التحليلات الذكية والتنبيهات 🧠'**
  String get tabSmartInsights;

  /// No description provided for @absenceAlertsHeader.
  ///
  /// In ar, this message translates to:
  /// **'إنذارات الغياب المتكرر'**
  String get absenceAlertsHeader;

  /// No description provided for @absenceAlertsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'شباب تغيبوا لجمعتين متتاليتين أو أكثر ويحتاجون لافتقاد عاجل'**
  String get absenceAlertsSubtitle;

  /// No description provided for @missedFridaysCount.
  ///
  /// In ar, this message translates to:
  /// **'غائب لـ {count} جمعات متتالية'**
  String missedFridaysCount(int count);

  /// No description provided for @criticalAbsenceBadge.
  ///
  /// In ar, this message translates to:
  /// **'خطر انقطاع حرج 🚨'**
  String get criticalAbsenceBadge;

  /// No description provided for @warningAbsenceBadge.
  ///
  /// In ar, this message translates to:
  /// **'تحذير غياب متكرر ⚠️'**
  String get warningAbsenceBadge;

  /// No description provided for @visitationImpactHeader.
  ///
  /// In ar, this message translates to:
  /// **'أثر الافتقاد على الحضور 💡'**
  String get visitationImpactHeader;

  /// No description provided for @visitationImpactSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة نسبة الحضور بين الأولاد المفتقدين وغير المفتقدين'**
  String get visitationImpactSubtitle;

  /// No description provided for @visitationImpactValue.
  ///
  /// In ar, this message translates to:
  /// **'الفرق المرتبط بالافتقاد في الحضور: {impact} نقطة مئوية (لا يدل على السببية)'**
  String visitationImpactValue(double impact);

  /// No description provided for @segmentConsistent.
  ///
  /// In ar, this message translates to:
  /// **'الملتزمون 🌟'**
  String get segmentConsistent;

  /// No description provided for @segmentIrregular.
  ///
  /// In ar, this message translates to:
  /// **'المتذبذبون 🔄'**
  String get segmentIrregular;

  /// No description provided for @segmentAtRisk.
  ///
  /// In ar, this message translates to:
  /// **'المعرضون للانقطاع 🚨'**
  String get segmentAtRisk;

  /// No description provided for @servantMyAnalytics.
  ///
  /// In ar, this message translates to:
  /// **'إحصائياتي'**
  String get servantMyAnalytics;

  /// No description provided for @servantGroupAttendanceRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة حضور مجموعتي'**
  String get servantGroupAttendanceRate;

  /// No description provided for @servantGroupVisitationProgress.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز افتقاد مجموعتي'**
  String get servantGroupVisitationProgress;

  /// No description provided for @urgentVisitationNeeded.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب افتقاد عاجل'**
  String get urgentVisitationNeeded;

  /// No description provided for @noAbsenceAlerts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إنذارات غياب حالياً • الكل منتظم ومتابع 🎉'**
  String get noAbsenceAlerts;

  /// No description provided for @allDetailsAction.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل البيانات'**
  String get allDetailsAction;

  /// No description provided for @hideDetailsAction.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء التفاصيل'**
  String get hideDetailsAction;

  /// No description provided for @assignedKhademLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المسؤول'**
  String get assignedKhademLabel;

  /// No description provided for @generalNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات عامة عن المخدوم'**
  String get generalNotesTitle;

  /// No description provided for @overallAttendanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الحضور الإجمالية'**
  String get overallAttendanceTitle;

  /// No description provided for @totalVisitsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الافتقادات'**
  String get totalVisitsTitle;

  /// No description provided for @consecutiveAbsenceTitle.
  ///
  /// In ar, this message translates to:
  /// **'الغياب المتتالي'**
  String get consecutiveAbsenceTitle;

  /// No description provided for @massAndServiceRatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'حضور القداس والخدمة'**
  String get massAndServiceRatesTitle;

  /// No description provided for @visitationCorrelationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الارتباط الإحصائي للافتقاد'**
  String get visitationCorrelationTitle;

  /// No description provided for @visitationCorrelationBody.
  ///
  /// In ar, this message translates to:
  /// **'فرق الحضور بعد الزيارات: {diff} نقطة مئوية (ارتباط دون ادعاء السببية).'**
  String visitationCorrelationBody(String diff);

  /// No description provided for @insufficientHistoryDataHint.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات خدمة مكتملة ومؤهلة في هذه الفترة.'**
  String get insufficientHistoryDataHint;

  /// No description provided for @daysSinceLastVisit.
  ///
  /// In ar, this message translates to:
  /// **'{days, plural, =0{اليوم} =1{منذ يوم} =2{منذ يومين} few{منذ {days} أيام} many{منذ {days} يوماً} other{منذ {days} يوم}}'**
  String daysSinceLastVisit(int days);

  /// No description provided for @noVisitsYet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفتقد بعد'**
  String get noVisitsYet;

  /// No description provided for @noConsecutiveAbsences.
  ///
  /// In ar, this message translates to:
  /// **'منتظم ومتابع'**
  String get noConsecutiveAbsences;

  /// No description provided for @criticalAbsenceAlert.
  ///
  /// In ar, this message translates to:
  /// **'إنذار خطر انقطاع 🚨'**
  String get criticalAbsenceAlert;

  /// No description provided for @warningAbsenceAlert.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب افتقاد عاجل ⚠️'**
  String get warningAbsenceAlert;

  /// No description provided for @attendanceRatio.
  ///
  /// In ar, this message translates to:
  /// **'{attended} من {eligible} جلسة'**
  String attendanceRatio(int attended, int eligible);

  /// No description provided for @massRateSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نسبة حضور القداس {rate}%'**
  String massRateSubtitle(String rate);

  /// No description provided for @filterAllEvents.
  ///
  /// In ar, this message translates to:
  /// **'كل الأحداث'**
  String get filterAllEvents;

  /// No description provided for @filterVisitsOnly.
  ///
  /// In ar, this message translates to:
  /// **'الزيارات فقط'**
  String get filterVisitsOnly;

  /// No description provided for @filterAttendanceOnly.
  ///
  /// In ar, this message translates to:
  /// **'الحضور فقط'**
  String get filterAttendanceOnly;

  /// No description provided for @filterFruitfulOnly.
  ///
  /// In ar, this message translates to:
  /// **'المثمرة فقط'**
  String get filterFruitfulOnly;

  /// No description provided for @filterAbsencesOnly.
  ///
  /// In ar, this message translates to:
  /// **'الغياب فقط'**
  String get filterAbsencesOnly;

  /// No description provided for @rangeAllTime.
  ///
  /// In ar, this message translates to:
  /// **'كل الفترات'**
  String get rangeAllTime;

  /// No description provided for @rangeLast30Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 30 يوم'**
  String get rangeLast30Days;

  /// No description provided for @rangeLast90Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 90 يوم'**
  String get rangeLast90Days;

  /// No description provided for @rangeCustom.
  ///
  /// In ar, this message translates to:
  /// **'مخصصة'**
  String get rangeCustom;

  /// No description provided for @pastoralVisitGeneral.
  ///
  /// In ar, this message translates to:
  /// **'افتقاد رعوي'**
  String get pastoralVisitGeneral;

  /// No description provided for @visitOutcomeBoth.
  ///
  /// In ar, this message translates to:
  /// **'أثمر الافتقاد: حضر القداس والخدمة 🌟'**
  String get visitOutcomeBoth;

  /// No description provided for @visitOutcomeServiceOnly.
  ///
  /// In ar, this message translates to:
  /// **'أثمر الافتقاد: حضر الخدمة فقط ✅'**
  String get visitOutcomeServiceOnly;

  /// No description provided for @visitOutcomeMassOnly.
  ///
  /// In ar, this message translates to:
  /// **'أثمر الافتقاد: حضر القداس الإلهي فقط ✅'**
  String get visitOutcomeMassOnly;

  /// No description provided for @visitOutcomeMissed.
  ///
  /// In ar, this message translates to:
  /// **'غائب عن القداس والخدمة ⚠️ (يحتاج متابعة)'**
  String get visitOutcomeMissed;

  /// No description provided for @visitOutcomePending.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار الجمعة القادمة ⏳'**
  String get visitOutcomePending;

  /// No description provided for @visitOutcomeNoData.
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجل جلسات حضور في هذه الجمعة'**
  String get visitOutcomeNoData;

  /// No description provided for @visitingServantLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخادم القائم بالافتقاد: '**
  String get visitingServantLabel;

  /// No description provided for @assignedKhademPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المسؤول'**
  String get assignedKhademPlaceholder;

  /// No description provided for @visitReportNotesHeader.
  ///
  /// In ar, this message translates to:
  /// **'ما دار في الافتقاد وملاحظات الخادم:'**
  String get visitReportNotesHeader;

  /// No description provided for @editNoteAction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editNoteAction;

  /// No description provided for @addNoteAction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get addNoteAction;

  /// No description provided for @visitNoDetailedNotes.
  ///
  /// In ar, this message translates to:
  /// **'تم الافتقاد بنجاح (لم تُسجل ملاحظات تفصيلية)'**
  String get visitNoDetailedNotes;

  /// No description provided for @visitOutcomeHeader.
  ///
  /// In ar, this message translates to:
  /// **'أثر الافتقاد (جمعة {date}):'**
  String visitOutcomeHeader(String date);

  /// No description provided for @attendedMassAndService.
  ///
  /// In ar, this message translates to:
  /// **'حاضر قداس وخدمة ✅'**
  String get attendedMassAndService;

  /// No description provided for @attendedPartial.
  ///
  /// In ar, this message translates to:
  /// **'حضور جزئي'**
  String get attendedPartial;

  /// No description provided for @absentBoth.
  ///
  /// In ar, this message translates to:
  /// **'غائب ❌'**
  String get absentBoth;

  /// No description provided for @massLabel.
  ///
  /// In ar, this message translates to:
  /// **'القداس'**
  String get massLabel;

  /// No description provided for @serviceLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة'**
  String get serviceLabel;

  /// No description provided for @precededByVisitNote.
  ///
  /// In ar, this message translates to:
  /// **'سبق هذه الجمعة افتقاد ({date})'**
  String precededByVisitNote(String date);

  /// No description provided for @noEventsMatchingFilter.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أحداث مطابقة للفلاتر المختارة'**
  String get noEventsMatchingFilter;

  /// No description provided for @editVisitNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل ملاحظات الافتقاد'**
  String get editVisitNotesTitle;

  /// No description provided for @editVisitNotesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما دار في الافتقاد وتفاصيل الزيارة لمتابعة المخدوم بدقة:'**
  String get editVisitNotesSubtitle;

  /// No description provided for @editVisitNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الافتقاد وما تم التحدث بشأنه...'**
  String get editVisitNotesHint;

  /// No description provided for @visitNotesUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ ملاحظات الافتقاد بنجاح'**
  String get visitNotesUpdatedSuccess;

  /// No description provided for @errorUpdatingNotes.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء حفظ الملاحظات: {err}'**
  String errorUpdatingNotes(String err);

  /// No description provided for @copyPhoneAction.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرقم'**
  String get copyPhoneAction;

  /// No description provided for @retryAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryAction;

  /// No description provided for @message1stSecondary.
  ///
  /// In ar, this message translates to:
  /// **'أولى ثانوي'**
  String get message1stSecondary;

  /// No description provided for @message2ndSecondary.
  ///
  /// In ar, this message translates to:
  /// **'تانية ثانوي'**
  String get message2ndSecondary;

  /// No description provided for @message3rdSecondary.
  ///
  /// In ar, this message translates to:
  /// **'تالتة ثانوي'**
  String get message3rdSecondary;

  /// No description provided for @messageAllGrades.
  ///
  /// In ar, this message translates to:
  /// **'كل المرحلة'**
  String get messageAllGrades;

  /// No description provided for @messageSecondary.
  ///
  /// In ar, this message translates to:
  /// **'ثانوي'**
  String get messageSecondary;

  /// No description provided for @message1st.
  ///
  /// In ar, this message translates to:
  /// **'1ث'**
  String get message1st;

  /// No description provided for @message2nd.
  ///
  /// In ar, this message translates to:
  /// **'2ث'**
  String get message2nd;

  /// No description provided for @message3rd.
  ///
  /// In ar, this message translates to:
  /// **'3ث'**
  String get message3rd;

  /// No description provided for @messageStageAdministrator.
  ///
  /// In ar, this message translates to:
  /// **'أمين المرحلة'**
  String get messageStageAdministrator;

  /// No description provided for @messageGradeAdministrator.
  ///
  /// In ar, this message translates to:
  /// **'أمين السنة'**
  String get messageGradeAdministrator;

  /// No description provided for @messageServant.
  ///
  /// In ar, this message translates to:
  /// **'خادم'**
  String get messageServant;

  /// No description provided for @messagePending.
  ///
  /// In ar, this message translates to:
  /// **'في الانتظار'**
  String get messagePending;

  /// No description provided for @messageServiceAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حضور الخدمة'**
  String get messageServiceAttendance;

  /// No description provided for @messageMassAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حضور القداس'**
  String get messageMassAttendance;

  /// No description provided for @messageVisitationTask.
  ///
  /// In ar, this message translates to:
  /// **'تكليف افتقاد'**
  String get messageVisitationTask;

  /// No description provided for @messageGeneralTask.
  ///
  /// In ar, this message translates to:
  /// **'مهمة عامة'**
  String get messageGeneralTask;

  /// No description provided for @messageHomeVisit.
  ///
  /// In ar, this message translates to:
  /// **'زيارة منزلية'**
  String get messageHomeVisit;

  /// No description provided for @messagePhoneCall.
  ///
  /// In ar, this message translates to:
  /// **'مكالمة هاتفية'**
  String get messagePhoneCall;

  /// No description provided for @messageChurchMeetup.
  ///
  /// In ar, this message translates to:
  /// **'لقاء بالكنيسة'**
  String get messageChurchMeetup;

  /// No description provided for @messageOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get messageOther;

  /// No description provided for @messageVisit.
  ///
  /// In ar, this message translates to:
  /// **'زيارة'**
  String get messageVisit;

  /// No description provided for @messageFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم رباعي'**
  String get messageFullName;

  /// No description provided for @messageDateOfBirthYyyyMmDd.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد (YYYY-MM-DD)'**
  String get messageDateOfBirthYyyyMmDd;

  /// No description provided for @messageTrackingStartDateYyyyMmDd.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ بدء التتبع (YYYY-MM-DD)'**
  String get messageTrackingStartDateYyyyMmDd;

  /// No description provided for @messageAge.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get messageAge;

  /// No description provided for @messageStudentPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفون المخدوم'**
  String get messageStudentPhone;

  /// No description provided for @messageFatherPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفون الأب'**
  String get messageFatherPhone;

  /// No description provided for @messageMotherPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفون الأم'**
  String get messageMotherPhone;

  /// No description provided for @messageDetailedAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالتفصيل'**
  String get messageDetailedAddress;

  /// No description provided for @messageArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get messageArea;

  /// No description provided for @messageSchool.
  ///
  /// In ar, this message translates to:
  /// **'المدرسة'**
  String get messageSchool;

  /// No description provided for @messageSecondaryType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الثانوية'**
  String get messageSecondaryType;

  /// No description provided for @messageHomeLocationMapsLink.
  ///
  /// In ar, this message translates to:
  /// **'لوكيشن البيت (رابط خرائط)'**
  String get messageHomeLocationMapsLink;

  /// No description provided for @messageBrethrenOfLordYesNo.
  ///
  /// In ar, this message translates to:
  /// **'أخوة رب (نعم/لا)'**
  String get messageBrethrenOfLordYesNo;

  /// No description provided for @messageStudentPhotoUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط صورة المخدوم'**
  String get messageStudentPhotoUrl;

  /// No description provided for @messageNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get messageNotes;

  /// No description provided for @messageAssignedServant.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المسؤول'**
  String get messageAssignedServant;

  /// No description provided for @messageVisitsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الافتقادات'**
  String get messageVisitsCount;

  /// No description provided for @messageLastVisitDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ آخر افتقاد'**
  String get messageLastVisitDate;

  /// No description provided for @messageYes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get messageYes;

  /// No description provided for @messageNo.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get messageNo;

  /// No description provided for @messageUnassigned.
  ///
  /// In ar, this message translates to:
  /// **'غير مربوط'**
  String get messageUnassigned;

  /// No description provided for @messageNotVisited.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفتقد'**
  String get messageNotVisited;

  /// No description provided for @messageYears.
  ///
  /// In ar, this message translates to:
  /// **'سنة'**
  String get messageYears;

  /// No description provided for @messageStudentsData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات_المخدومين'**
  String get messageStudentsData;

  /// No description provided for @messageStudentsTemplate.
  ///
  /// In ar, this message translates to:
  /// **'قالب_المخدومين'**
  String get messageStudentsTemplate;

  /// No description provided for @messageMainMenu.
  ///
  /// In ar, this message translates to:
  /// **'القائمة الرئيسية'**
  String get messageMainMenu;

  /// No description provided for @messageMakhdomeen.
  ///
  /// In ar, this message translates to:
  /// **'المخدومين'**
  String get messageMakhdomeen;

  /// No description provided for @messageMyStudents.
  ///
  /// In ar, this message translates to:
  /// **'مخدوميني'**
  String get messageMyStudents;

  /// No description provided for @messageMyTasks.
  ///
  /// In ar, this message translates to:
  /// **'مهامي'**
  String get messageMyTasks;

  /// No description provided for @messageAccountDeletionInProgress.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب قيد التنفيذ'**
  String get messageAccountDeletionInProgress;

  /// No description provided for @messageUnableToLoadProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الملف الشخصي'**
  String get messageUnableToLoadProfile;

  /// No description provided for @messageYourDeletionRequestIsSavedYouCan.
  ///
  /// In ar, this message translates to:
  /// **'طلب الحذف محفوظ. يمكنك الخروج ومتابعة الحالة لاحقاً.'**
  String get messageYourDeletionRequestIsSavedYouCan;

  /// No description provided for @messageRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get messageRetry;

  /// No description provided for @messageStudentsImportTemplateXlsx.
  ///
  /// In ar, this message translates to:
  /// **'قالب_إضافة_المخدومين.xlsx'**
  String get messageStudentsImportTemplateXlsx;

  /// No description provided for @messageExcelTemplateForImportingStudentsInEfteqad.
  ///
  /// In ar, this message translates to:
  /// **'قالب إكسيل لإضافة المخدومين في تطبيق افتقاد'**
  String get messageExcelTemplateForImportingStudentsInEfteqad;

  /// No description provided for @messageStudentsReportEfteqad.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المخدومين - تطبيق افتقاد'**
  String get messageStudentsReportEfteqad;

  /// No description provided for @messageFailedToLoadAttendanceSessions.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل جلسات الحضور'**
  String get messageFailedToLoadAttendanceSessions;

  /// No description provided for @messageLast90Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 90 يوماً'**
  String get messageLast90Days;

  /// No description provided for @messageEn.
  ///
  /// In ar, this message translates to:
  /// **'ar'**
  String get messageEn;

  /// No description provided for @messageSession.
  ///
  /// In ar, this message translates to:
  /// **'جلسة'**
  String get messageSession;

  /// No description provided for @messageAbsenceAlert.
  ///
  /// In ar, this message translates to:
  /// **'⚠️ تنبيه غياب: {value0}'**
  String messageAbsenceAlert(String value0);

  /// No description provided for @messageStudentMissedFridaysPleaseVisitSoon.
  ///
  /// In ar, this message translates to:
  /// **'المخدوم غائب لـ {value0} جمعات متتالية. يرجى الافتقاد العاجل.'**
  String messageStudentMissedFridaysPleaseVisitSoon(String value0);

  /// No description provided for @messageUrgentAlertSentTo.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال تنبيه عاجل للخادم ({value0}) بنجاح! 🔔'**
  String messageUrgentAlertSentTo(String value0);

  /// No description provided for @messageNotify.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه الخادم'**
  String get messageNotify;

  /// No description provided for @messageS.
  ///
  /// In ar, this message translates to:
  /// **'خ'**
  String get messageS;

  /// No description provided for @messageUpdateRecordAndPersonalDetails.
  ///
  /// In ar, this message translates to:
  /// **'تحديث السجل والبيانات الشخصية'**
  String get messageUpdateRecordAndPersonalDetails;

  /// No description provided for @messageInsertNewMakhdomToCareRegistry.
  ///
  /// In ar, this message translates to:
  /// **'إدراج مخدوم جديد إلى دفتر الرعاية'**
  String get messageInsertNewMakhdomToCareRegistry;

  /// No description provided for @messageFieldsAreLockedUntilConfirmationRetryTo.
  ///
  /// In ar, this message translates to:
  /// **'البيانات ثابتة حتى تأكيد الحفظ. أعد المحاولة لاستكمال الطلب.'**
  String get messageFieldsAreLockedUntilConfirmationRetryTo;

  /// No description provided for @messageErrorSavingAssignments.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الحفظ: {value0}'**
  String messageErrorSavingAssignments(String value0);

  /// No description provided for @messageAssignMakhdomeenToServant.
  ///
  /// In ar, this message translates to:
  /// **'إسناد وتوزيع مخدومين للخادم'**
  String get messageAssignMakhdomeenToServant;

  /// No description provided for @messageSelectionIsLockedUntilConfirmationRetryTo.
  ///
  /// In ar, this message translates to:
  /// **'التحديد ثابت حتى تأكيد الحفظ. أعد المحاولة لاستكمال الطلب.'**
  String get messageSelectionIsLockedUntilConfirmationRetryTo;

  /// No description provided for @messageGeneratingSharingTemplate.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إنشاء ومشاركة القالب...'**
  String get messageGeneratingSharingTemplate;

  /// No description provided for @messageError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {value0}'**
  String messageError(String value0);

  /// No description provided for @messageReadingAndExtractingDataFromFile.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ قراءة واستخراج البيانات من الملف...'**
  String get messageReadingAndExtractingDataFromFile;

  /// No description provided for @messageCouldNotImportAnyRowsDueTo.
  ///
  /// In ar, this message translates to:
  /// **'تعذر استيراد أي مخدوم بسبب أخطاء في الصفوف:\n{value0}'**
  String messageCouldNotImportAnyRowsDueTo(String value0);

  /// No description provided for @messageTargetGrade.
  ///
  /// In ar, this message translates to:
  /// **'السنة المستهدفة: {value0}'**
  String messageTargetGrade(String value0);

  /// No description provided for @messageRowsExcluded.
  ///
  /// In ar, this message translates to:
  /// **'⚠️ تم استبعاد {value0} صفاً:\n{value1}'**
  String messageRowsExcluded(String value0, String value1);

  /// No description provided for @messageSavingToFirebase.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ في فايربيس...'**
  String get messageSavingToFirebase;

  /// No description provided for @messageSavingToFirebase564.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ في فايربيس ({value0} / {value1})...'**
  String messageSavingToFirebase564(String value0, String value1);

  /// No description provided for @messageLocalRowsExcluded.
  ///
  /// In ar, this message translates to:
  /// **'صفوف محلية مستبعدة'**
  String get messageLocalRowsExcluded;

  /// No description provided for @messageServerRowsRejected.
  ///
  /// In ar, this message translates to:
  /// **'صفوف مرفوضة من الخادم'**
  String get messageServerRowsRejected;

  /// No description provided for @messageImportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاستيراد: {value0}'**
  String messageImportFailed(String value0);

  /// No description provided for @messageExportingDataToExcel.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تصدير البيانات إلى إكسيل...'**
  String get messageExportingDataToExcel;

  /// No description provided for @messageExportError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ أثناء التصدير: {value0}'**
  String messageExportError(String value0);

  /// No description provided for @messageBulkDataManagementAndSheetExports.
  ///
  /// In ar, this message translates to:
  /// **'إدارة البيانات بشكل جماعي واستخراج الشيتات'**
  String get messageBulkDataManagementAndSheetExports;

  /// No description provided for @messageProcessing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المعالجة...'**
  String get messageProcessing;

  /// No description provided for @messageUnassignStudent.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التسكين'**
  String get messageUnassignStudent;

  /// No description provided for @messageAreYouSureYouWantToUnassign.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء تسكين {value0} من خادمه الحالي؟'**
  String messageAreYouSureYouWantToUnassign(String value0);

  /// No description provided for @messageUnassign.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التسكين'**
  String get messageUnassign;

  /// No description provided for @messageM.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get messageM;

  /// No description provided for @messageServant580.
  ///
  /// In ar, this message translates to:
  /// **'الخادم'**
  String get messageServant580;

  /// No description provided for @messageSelectAServantToAppointAsGrade.
  ///
  /// In ar, this message translates to:
  /// **'اختر خادماً لتعيينه أميناً للسنة الدراسية'**
  String get messageSelectAServantToAppointAsGrade;

  /// No description provided for @messageNoServantsAssignedToYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خدام مسكنين في {value0} بعد'**
  String messageNoServantsAssignedToYet(String value0);

  /// No description provided for @messageAppointHead.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كأمين'**
  String get messageAppointHead;

  /// No description provided for @messageAssign.
  ///
  /// In ar, this message translates to:
  /// **'تسكين'**
  String get messageAssign;

  /// No description provided for @messageChangeHead.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الأمين'**
  String get messageChangeHead;

  /// No description provided for @messageUnspecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get messageUnspecified;

  /// No description provided for @messageThisSessionHasBeenFinalizedAndCannot.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد هذه الجلسة ولا يمكن تعديلها.'**
  String get messageThisSessionHasBeenFinalizedAndCannot;

  /// No description provided for @messageErrorSavingAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الحفظ: {value0}'**
  String messageErrorSavingAttendance(String value0);

  /// No description provided for @messagePleaseWaitForPendingSavesToFinish.
  ///
  /// In ar, this message translates to:
  /// **'يرجى الانتظار حتى اكتمال حفظ الطلبات المعلقة.'**
  String get messagePleaseWaitForPendingSavesToFinish;

  /// No description provided for @messageFinalizeAttendance.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الحضور'**
  String get messageFinalizeAttendance;

  /// No description provided for @messageAreYouSureYouWantToFinalize.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إنهاء واعتماد كشف الحضور لهذه الجلسة؟ لن يمكن التعديل عليها بعد ذلك.'**
  String get messageAreYouSureYouWantToFinalize;

  /// No description provided for @messageCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get messageCancel;

  /// No description provided for @messageConfirmFinalization.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاعتماد'**
  String get messageConfirmFinalization;

  /// No description provided for @messageAttendanceFinalizedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد كشف الحضور بنجاح.'**
  String get messageAttendanceFinalizedSuccessfully;

  /// No description provided for @messageErrorFinalizingAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء اعتماد الحضور: {value0}'**
  String messageErrorFinalizingAttendance(String value0);

  /// No description provided for @messageLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get messageLoading;

  /// No description provided for @messageFinalized.
  ///
  /// In ar, this message translates to:
  /// **'معتمد'**
  String get messageFinalized;

  /// No description provided for @messageSaving.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحفظ...'**
  String get messageSaving;

  /// No description provided for @messageSaveError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الحفظ'**
  String get messageSaveError;

  /// No description provided for @messageCouldNotLoadRoster.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل كشف الحضور: {value0}'**
  String messageCouldNotLoadRoster(String value0);

  /// No description provided for @messageAttendanceSessionIsFinalizedAndLockedRead.
  ///
  /// In ar, this message translates to:
  /// **'تم إنهاء واعتماد كشف الحضور لهذه الجلسة. القراءة فقط.'**
  String get messageAttendanceSessionIsFinalizedAndLockedRead;

  /// No description provided for @messageSearchByName.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالاسم'**
  String get messageSearchByName;

  /// No description provided for @messageNotificationsCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز الإشعارات'**
  String get messageNotificationsCenter;

  /// No description provided for @messageMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get messageMarkAllRead;

  /// No description provided for @messageAccessDenied.
  ///
  /// In ar, this message translates to:
  /// **'غير مصرح بالوصول'**
  String get messageAccessDenied;

  /// No description provided for @messageYouDoNotHavePermissionToAccess.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك الصلاحيات الكافية للوصول إلى هذه الصفحة.'**
  String get messageYouDoNotHavePermissionToAccess;

  /// No description provided for @messagePageNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get messagePageNotFound;

  /// No description provided for @messageThePageYouAreLookingForDoes.
  ///
  /// In ar, this message translates to:
  /// **'عذراً، المسار الذي تحاول الوصول إليه غير موجود أو تم نقله.'**
  String get messageThePageYouAreLookingForDoes;

  /// No description provided for @messageAnErrorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get messageAnErrorOccurred;

  /// No description provided for @messageGoHome.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الرئيسية'**
  String get messageGoHome;

  /// No description provided for @messageNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات والتنبيهات'**
  String get messageNotifications;

  /// No description provided for @messageNotificationsCenter616.
  ///
  /// In ar, this message translates to:
  /// **'مركز الإشعارات والتنبيهات'**
  String get messageNotificationsCenter616;

  /// No description provided for @messageJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get messageJustNow;

  /// No description provided for @messageMAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {value0} دقيقة'**
  String messageMAgo(String value0);

  /// No description provided for @messageHAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {value0} ساعة'**
  String messageHAgo(String value0);

  /// No description provided for @messageDAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {value0} يوم'**
  String messageDAgo(String value0);

  /// No description provided for @messageNoNotificationsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات حالياً'**
  String get messageNoNotificationsYet;

  /// No description provided for @messageTaskAssignmentsAndAlertsWillAppearHere.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا إشعارات المهام والتنبيهات الموجهة إليك'**
  String get messageTaskAssignmentsAndAlertsWillAppearHere;

  /// No description provided for @messageCouldNotConfirmSaveRetryTheSame.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تأكيد الحفظ. الطلب ثابت لإعادة المحاولة: {value0}'**
  String messageCouldNotConfirmSaveRetryTheSame(String value0);

  /// No description provided for @messageCouldNotLoadLocalDraft.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المسودة المحلية: {value0}'**
  String messageCouldNotLoadLocalDraft(String value0);

  /// No description provided for @messageLocalSubmissionLoadedConfirmationIsPending.
  ///
  /// In ar, this message translates to:
  /// **'تم استرجاع طلب محفوظ محلياً يحتاج تأكيد الحفظ'**
  String get messageLocalSubmissionLoadedConfirmationIsPending;

  /// No description provided for @messageFieldsAreLockedUntilConfirmationRetryTo631.
  ///
  /// In ar, this message translates to:
  /// **'البيانات ثابتة حتى تأكيد الحفظ. أعد المحاولة لتأكيد نفس الزيارة.'**
  String get messageFieldsAreLockedUntilConfirmationRetryTo631;

  /// No description provided for @messageAlertBoysNeedUrgentVisitRepeatedAbsence.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: يوجد {value0} من أولادك بحاجة لافتقاد عاجل (غياب متكرر)'**
  String messageAlertBoysNeedUrgentVisitRepeatedAbsence(String value0);

  /// No description provided for @messageView.
  ///
  /// In ar, this message translates to:
  /// **'عرض 👈'**
  String get messageView;

  /// No description provided for @messageAllSessions.
  ///
  /// In ar, this message translates to:
  /// **'حضور كل الجلسات'**
  String get messageAllSessions;

  /// No description provided for @messageAllConsistent.
  ///
  /// In ar, this message translates to:
  /// **'الكل منتظم 🎉'**
  String get messageAllConsistent;

  /// No description provided for @messageAbsenceAlert637.
  ///
  /// In ar, this message translates to:
  /// **'غياب متكرر ⚠️'**
  String get messageAbsenceAlert637;

  /// No description provided for @messageAttendance75.
  ///
  /// In ar, this message translates to:
  /// **'حضور ≥ 75%'**
  String get messageAttendance75;

  /// No description provided for @messageVisited.
  ///
  /// In ar, this message translates to:
  /// **'المفتقدون'**
  String get messageVisited;

  /// No description provided for @messageUnvisited.
  ///
  /// In ar, this message translates to:
  /// **'غير المفتقدين'**
  String get messageUnvisited;

  /// No description provided for @messageAttendanceRatesCurrentlyEqual.
  ///
  /// In ar, this message translates to:
  /// **'نسب الحضور متساوية حالياً'**
  String get messageAttendanceRatesCurrentlyEqual;

  /// No description provided for @messageCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get messageCall;

  /// No description provided for @messageWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get messageWhatsapp;

  /// No description provided for @messageVisit644.
  ///
  /// In ar, this message translates to:
  /// **'افتقاد'**
  String get messageVisit644;

  /// No description provided for @messageBehavioralSegmentation.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف السلوكي للمتابعة'**
  String get messageBehavioralSegmentation;

  /// No description provided for @messageNoStudentsInThisSegment.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مخدومون في هذا التصنيف'**
  String get messageNoStudentsInThisSegment;

  /// No description provided for @messageVisits.
  ///
  /// In ar, this message translates to:
  /// **'افتقاد: {value0}'**
  String messageVisits(String value0);

  /// No description provided for @messageAbsenceAlert649.
  ///
  /// In ar, this message translates to:
  /// **'غياب متكرر ⚠️'**
  String get messageAbsenceAlert649;

  /// No description provided for @messageVisit650.
  ///
  /// In ar, this message translates to:
  /// **'افتقاد'**
  String get messageVisit650;

  /// No description provided for @messageBehavioralSegmentation651.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف السلوكي للأولاد'**
  String get messageBehavioralSegmentation651;

  /// No description provided for @messageOfVisited.
  ///
  /// In ar, this message translates to:
  /// **'{value0} من {value1} مخدوم'**
  String messageOfVisited(String value0, String value1);

  /// No description provided for @messageConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get messageConfirmPassword;

  /// No description provided for @messageToDeleteYourAccountPleaseEnterYour.
  ///
  /// In ar, this message translates to:
  /// **'لحذف الحساب، يرجى إدخال كلمة المرور الخاصة بحسابك للتأكيد.'**
  String get messageToDeleteYourAccountPleaseEnterYour;

  /// No description provided for @messagePassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get messagePassword;

  /// No description provided for @messageProceed.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الحذف'**
  String get messageProceed;

  /// No description provided for @messageStageAdministratorCannotDeleteAccountBeforeAppointing.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن لأمين المرحلة حذف حسابه قبل تعيين أمين مرحلة بديل ومثبت.'**
  String get messageStageAdministratorCannotDeleteAccountBeforeAppointing;

  /// No description provided for @messageTaskDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المهمة'**
  String get messageTaskDetails;

  /// No description provided for @messageDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get messageDescription;

  /// No description provided for @messageAssignedServant661.
  ///
  /// In ar, this message translates to:
  /// **'الخادم المكلف'**
  String get messageAssignedServant661;

  /// No description provided for @messageGrade.
  ///
  /// In ar, this message translates to:
  /// **'السنة الدراسية'**
  String get messageGrade;

  /// No description provided for @messageDueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get messageDueDate;

  /// No description provided for @messageCreatedBy.
  ///
  /// In ar, this message translates to:
  /// **'أنشئت بواسطة'**
  String get messageCreatedBy;

  /// No description provided for @messageOpenAttendanceSheet.
  ///
  /// In ar, this message translates to:
  /// **'فتح كشف الحضور'**
  String get messageOpenAttendanceSheet;

  /// No description provided for @messageCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة بنجاح'**
  String get messageCompleted;

  /// No description provided for @messageMarkAsCompleted.
  ///
  /// In ar, this message translates to:
  /// **'تحديد كمكتملة'**
  String get messageMarkAsCompleted;

  /// No description provided for @messageAdmin.
  ///
  /// In ar, this message translates to:
  /// **'أمين الخدمة'**
  String get messageAdmin;

  /// No description provided for @messageYouAreAssignedToTakeServiceAttendance.
  ///
  /// In ar, this message translates to:
  /// **'تم تكليفك برصد حضور وغياب الخدمة'**
  String get messageYouAreAssignedToTakeServiceAttendance;

  /// No description provided for @messageYouAreAssignedToTakeMassAttendance.
  ///
  /// In ar, this message translates to:
  /// **'تم تكليفك برصد حضور وغياب القداس الإلهي'**
  String get messageYouAreAssignedToTakeMassAttendance;

  /// No description provided for @messageAssignedYouANewTask.
  ///
  /// In ar, this message translates to:
  /// **'قام {value0} بتكليفك بمهمة جديدة'**
  String messageAssignedYouANewTask(String value0);

  /// No description provided for @messageNewTask.
  ///
  /// In ar, this message translates to:
  /// **'مهمة جديدة: {value0} 📋'**
  String messageNewTask(String value0);

  /// No description provided for @messageSubmissionIsLockedUntilConfirmationRetryTo.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ثابت حتى تأكيد الحفظ. أعد المحاولة لتأكيد نفس المهمة.'**
  String get messageSubmissionIsLockedUntilConfirmationRetryTo;

  /// No description provided for @messageYouAreOffline.
  ///
  /// In ar, this message translates to:
  /// **'أنت في وضع عدم الاتصال (أوفلاين)'**
  String get messageYouAreOffline;

  /// No description provided for @messageSyncingPendingChanges.
  ///
  /// In ar, this message translates to:
  /// **'جاري مزامنة التعديلات المعلقة...'**
  String get messageSyncingPendingChanges;

  /// No description provided for @messageNoServantsAssignedToYetAssignServants.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خدام مسكنين في {value0} بعد.\nقم بتسكين خدام أولاً لتتمكن من تعيين أمين.'**
  String messageNoServantsAssignedToYetAssignServants(String value0);

  /// No description provided for @messageCurrentHead.
  ///
  /// In ar, this message translates to:
  /// **'الأمين الحالي'**
  String get messageCurrentHead;

  /// No description provided for @messageAssignedSecondaryStageServants.
  ///
  /// In ar, this message translates to:
  /// **'خدام مرحلة ثانوي المسكنين'**
  String get messageAssignedSecondaryStageServants;

  /// No description provided for @messageServants.
  ///
  /// In ar, this message translates to:
  /// **'{value0} خادم'**
  String messageServants(String value0);

  /// No description provided for @messageNoServantsAssignedToThisSectionYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خدام مسكنين في هذا القسم بعد'**
  String get messageNoServantsAssignedToThisSectionYet;

  /// No description provided for @messageGradeHead.
  ///
  /// In ar, this message translates to:
  /// **'أمين سنة'**
  String get messageGradeHead;

  /// No description provided for @messageAssignedStudents.
  ///
  /// In ar, this message translates to:
  /// **'{value0} • {value1} ولد مسند'**
  String messageAssignedStudents(String value0, String value1);

  /// No description provided for @messageChangeGrade.
  ///
  /// In ar, this message translates to:
  /// **'تغيير السنة الدراسية'**
  String get messageChangeGrade;

  /// No description provided for @messageNewServant.
  ///
  /// In ar, this message translates to:
  /// **'خادم جديد'**
  String get messageNewServant;

  /// No description provided for @messageNoAttendanceSessionsRecordedYet.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم رصد أي جلسات حضور حتى الآن'**
  String get messageNoAttendanceSessionsRecordedYet;

  /// No description provided for @messageWeeklyStatisticsAppearHereAfterRecordingAttendance.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر الإحصائيات الأسبوعية هنا بعد تسجيل حضور الجمعة'**
  String get messageWeeklyStatisticsAppearHereAfterRecordingAttendance;

  /// No description provided for @messageOverallAttendanceRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الحضور العامة'**
  String get messageOverallAttendanceRate;

  /// No description provided for @messageAverageOfRecordedSessions.
  ///
  /// In ar, this message translates to:
  /// **'متوسط كل الجلسات المسجلة'**
  String get messageAverageOfRecordedSessions;

  /// No description provided for @messageAttendanceFridays.
  ///
  /// In ar, this message translates to:
  /// **'عدد جمعات الحضور'**
  String get messageAttendanceFridays;

  /// No description provided for @messageServiceMass.
  ///
  /// In ar, this message translates to:
  /// **'{value0} خدمة • {value1} قداس'**
  String messageServiceMass(String value0, String value1);

  /// No description provided for @messageAverageSundaySchoolAttendance.
  ///
  /// In ar, this message translates to:
  /// **'متوسط حضور مدارس الأحد'**
  String get messageAverageSundaySchoolAttendance;

  /// No description provided for @messageAverageMassAttendance.
  ///
  /// In ar, this message translates to:
  /// **'متوسط حضور القداسات'**
  String get messageAverageMassAttendance;

  /// No description provided for @messageWeeklyAttendanceRecentFridays.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الحضور أسبوعياً (آخر الجمعات)'**
  String get messageWeeklyAttendanceRecentFridays;

  /// No description provided for @messageMass.
  ///
  /// In ar, this message translates to:
  /// **'قداس'**
  String get messageMass;

  /// No description provided for @messageService.
  ///
  /// In ar, this message translates to:
  /// **'خدمة'**
  String get messageService;

  /// No description provided for @messageStudents.
  ///
  /// In ar, this message translates to:
  /// **'{value0} أولاد'**
  String messageStudents(String value0);

  /// No description provided for @messageVisitedStudents.
  ///
  /// In ar, this message translates to:
  /// **'أولاد تم افتقادهم'**
  String get messageVisitedStudents;

  /// No description provided for @messageStudents705.
  ///
  /// In ar, this message translates to:
  /// **'{value0} ولد'**
  String messageStudents705(String value0);

  /// No description provided for @messageUnvisitedStudents.
  ///
  /// In ar, this message translates to:
  /// **'أولاد لم يُفتقدوا'**
  String get messageUnvisitedStudents;

  /// No description provided for @messageStudents708.
  ///
  /// In ar, this message translates to:
  /// **'{value0} ولد'**
  String messageStudents708(String value0);

  /// No description provided for @messageStudentAttendanceGroups.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف السلوكي للأولاد (المجموعات)'**
  String get messageStudentAttendanceGroups;

  /// No description provided for @messageNoStudentsInThisGroup.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أولاد في هذه المجموعة'**
  String get messageNoStudentsInThisGroup;

  /// No description provided for @messageAgeYears.
  ///
  /// In ar, this message translates to:
  /// **'العمر: {value0} سنة'**
  String messageAgeYears(String value0);

  /// No description provided for @messageCalculatedPrecisely.
  ///
  /// In ar, this message translates to:
  /// **'محسوب بدقة ⚡'**
  String get messageCalculatedPrecisely;

  /// No description provided for @messageAutomatic.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي ⚡'**
  String get messageAutomatic;

  /// No description provided for @messageBirthDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد: {value0}/{value1}/{value2}'**
  String messageBirthDate(String value0, String value1, String value2);

  /// No description provided for @messageAgeEstimatedFromSecondaryGrade.
  ///
  /// In ar, this message translates to:
  /// **'تم حساب السن تلقائياً حسب مرحلة ثانوي ({value0})'**
  String messageAgeEstimatedFromSecondaryGrade(String value0);

  /// No description provided for @messageResetToAutomaticCalculation.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التخصيص والعودة للحساب التلقائي'**
  String get messageResetToAutomaticCalculation;

  /// No description provided for @messageYears721.
  ///
  /// In ar, this message translates to:
  /// **'{value0} سنة'**
  String messageYears721(String value0);

  /// No description provided for @messageChooseExactBirthDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخ الميلاد الدقيق'**
  String get messageChooseExactBirthDate;

  /// No description provided for @messageExactDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ دقيق...'**
  String get messageExactDate;

  /// No description provided for @messageServantUnavailableInThisList.
  ///
  /// In ar, this message translates to:
  /// **'خادم غير موجود في القائمة'**
  String get messageServantUnavailableInThisList;

  /// No description provided for @messageStudents726.
  ///
  /// In ar, this message translates to:
  /// **'مخدومي_{value0}'**
  String messageStudents726(String value0);

  /// No description provided for @messageAgeEstimatedFrom.
  ///
  /// In ar, this message translates to:
  /// **'العمر: {value0} (محسوب تلقائياً حسب {value1})'**
  String messageAgeEstimatedFrom(String value0, String value1);

  /// No description provided for @messageAssignedStudents730.
  ///
  /// In ar, this message translates to:
  /// **'{value0} • {value1} مخدوم مسكن'**
  String messageAssignedStudents730(String value0, String value1);

  /// No description provided for @messageChangeGrade732.
  ///
  /// In ar, this message translates to:
  /// **'تغيير السنة'**
  String get messageChangeGrade732;

  /// No description provided for @messageVisitNotesAndDiscussion.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات وما دار في الافتقاد (الديسكريبشن)'**
  String get messageVisitNotesAndDiscussion;

  /// No description provided for @messageRecordVisitDiscussionMeetingDetailsOrPastoral.
  ///
  /// In ar, this message translates to:
  /// **'اكتب هنا ما دار في الافتقاد، تفاصيل المقابلة، أو أي احتياجات رعوية...'**
  String get messageRecordVisitDiscussionMeetingDetailsOrPastoral;

  /// No description provided for @messageOfStudents.
  ///
  /// In ar, this message translates to:
  /// **'{value0} من {value1} مخدوم'**
  String messageOfStudents(String value0, String value1);

  /// No description provided for @messageAttendance.
  ///
  /// In ar, this message translates to:
  /// **'{value0}% حضور'**
  String messageAttendance(String value0);

  /// No description provided for @messageStageServant.
  ///
  /// In ar, this message translates to:
  /// **'خادم بالمرحلة'**
  String get messageStageServant;

  /// No description provided for @messageDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ: {value0}'**
  String messageDate(String value0);

  /// No description provided for @messageSelectDueDateOptional.
  ///
  /// In ar, this message translates to:
  /// **'تحديد تاريخ المهمة (اختياري)'**
  String get messageSelectDueDateOptional;

  /// No description provided for @messageFriday.
  ///
  /// In ar, this message translates to:
  /// **'جمعة'**
  String get messageFriday;

  /// No description provided for @failurePermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية لتنفيذ هذه العملية.'**
  String get failurePermissionDenied;

  /// No description provided for @failureNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال. تحقق من اتصال الإنترنت وحاول مجدداً.'**
  String get failureNetwork;

  /// No description provided for @failureNotFound.
  ///
  /// In ar, this message translates to:
  /// **'المورد المطلوب غير موجود أو تم حذفه.'**
  String get failureNotFound;

  /// No description provided for @failureDecode.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة البيانات. حاول تحميلها مجدداً.'**
  String get failureDecode;

  /// No description provided for @failureAuthentication.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تسجيل الدخول مجدداً لتأكيد هويتك.'**
  String get failureAuthentication;

  /// No description provided for @stageSuccessorRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب تعيين أمين مرحلة بديل نشط ومثبت قبل حذف حسابك.'**
  String get stageSuccessorRequired;

  /// No description provided for @channelName.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات افتقاد والمهام'**
  String get channelName;

  /// No description provided for @channelDescription.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات المهام والتكليفات والحضور والغياب'**
  String get channelDescription;

  /// No description provided for @newNotification.
  ///
  /// In ar, this message translates to:
  /// **'إشعار جديد 🔔'**
  String get newNotification;

  /// No description provided for @secondaryGeneral.
  ///
  /// In ar, this message translates to:
  /// **'ثانوية عامة'**
  String get secondaryGeneral;

  /// No description provided for @secondaryTechnical.
  ///
  /// In ar, this message translates to:
  /// **'صنايع / فني'**
  String get secondaryTechnical;

  /// No description provided for @secondaryService.
  ///
  /// In ar, this message translates to:
  /// **'خدمات'**
  String get secondaryService;

  /// No description provided for @secondaryCommercial.
  ///
  /// In ar, this message translates to:
  /// **'تجاري'**
  String get secondaryCommercial;

  /// No description provided for @secondaryOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get secondaryOther;

  /// No description provided for @excelSampleSkipped.
  ///
  /// In ar, this message translates to:
  /// **'تم رصد صف العينة التجريبي ({name}) وتجاهله تلقائياً.'**
  String excelSampleSkipped(String name);

  /// No description provided for @excelMissingName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المخدوم فارغ في الصف {row}'**
  String excelMissingName(int row);

  /// No description provided for @excelMissingPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفون المخدوم فارغ في الصف {row}'**
  String excelMissingPhone(int row);

  /// No description provided for @excelDuplicatePhone.
  ///
  /// In ar, this message translates to:
  /// **'تكرار رقم هاتف في الملف ({phone}) للمخدوم ({name})'**
  String excelDuplicatePhone(String phone, String name);

  /// No description provided for @excelInvalidBirthDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ ميلاد غير صالح: {value}'**
  String excelInvalidBirthDate(String value);

  /// No description provided for @excelInvalidTrackingDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ بدء التتبع غير صالح: {value}'**
  String excelInvalidTrackingDate(String value);

  /// No description provided for @excelEmptyFailure.
  ///
  /// In ar, this message translates to:
  /// **'ملف الإكسيل فارغ أو غير صالح.'**
  String get excelEmptyFailure;

  /// No description provided for @excelColumnsFailure.
  ///
  /// In ar, this message translates to:
  /// **'تعذر العثور على أعمدة الاسم أو الهاتف في الترويسة.'**
  String get excelColumnsFailure;

  /// No description provided for @excelReadFailure.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة بيانات الملف.'**
  String get excelReadFailure;

  /// No description provided for @attendanceFinalizedFailure.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تعديل جلسة حضور تم اعتمادها وإنهاء رصدها.'**
  String get attendanceFinalizedFailure;

  /// No description provided for @pendingSavesFailure.
  ///
  /// In ar, this message translates to:
  /// **'يوجد طلبات معلقة قيد الحفظ. يرجى الانتظار حتى اكتمالها.'**
  String get pendingSavesFailure;

  /// No description provided for @birthDateCaption.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد: {date}'**
  String birthDateCaption(String date);

  /// No description provided for @analyticsDateBounds.
  ///
  /// In ar, this message translates to:
  /// **'{from} – {to}'**
  String analyticsDateBounds(String from, String to);

  /// No description provided for @trackingStartLabel.
  ///
  /// In ar, this message translates to:
  /// **'بدء التتبع: {date}'**
  String trackingStartLabel(String date);

  /// No description provided for @trackingStartEstimatedLabel.
  ///
  /// In ar, this message translates to:
  /// **'بدء التتبع تقديري: {date}'**
  String trackingStartEstimatedLabel(String date);

  /// No description provided for @trackingOriginUnknown.
  ///
  /// In ar, this message translates to:
  /// **'بدء التتبع غير معروف؛ بيانات الحضور غير كافية.'**
  String get trackingOriginUnknown;

  /// No description provided for @loadMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get loadMore;

  /// No description provided for @secondaryTypeCustomLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الثانوية المخصص'**
  String get secondaryTypeCustomLabel;

  /// No description provided for @legacyNotesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات قديمة'**
  String get legacyNotesLabel;

  /// No description provided for @cachedDataHint.
  ///
  /// In ar, this message translates to:
  /// **'عرض بيانات مخزنة محليًا؛ في انتظار تأكيد الخادم.'**
  String get cachedDataHint;

  /// No description provided for @insufficientDataShort.
  ///
  /// In ar, this message translates to:
  /// **'غير كافٍ'**
  String get insufficientDataShort;

  /// No description provided for @followupNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه متابعة'**
  String get followupNotificationTitle;

  /// No description provided for @followupNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'افتح تطبيق افتقاد لمتابعة أحد مخدوميك.'**
  String get followupNotificationBody;
}

class _GeneratedAppLocalizationsDelegate
    extends LocalizationsDelegate<GeneratedAppLocalizations> {
  const _GeneratedAppLocalizationsDelegate();

  @override
  Future<GeneratedAppLocalizations> load(Locale locale) {
    return SynchronousFuture<GeneratedAppLocalizations>(
      lookupGeneratedAppLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_GeneratedAppLocalizationsDelegate old) => false;
}

GeneratedAppLocalizations lookupGeneratedAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return GeneratedAppLocalizationsAr();
    case 'en':
      return GeneratedAppLocalizationsEn();
  }

  throw FlutterError(
    'GeneratedAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

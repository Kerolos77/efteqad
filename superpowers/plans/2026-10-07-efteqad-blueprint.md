# Efteqad — Blueprint الإصلاحات والترجمة والروتر

> **For agentic workers:** عند طلب التنفيذ استخدم superpowers:executing-plans أو superpowers:subagent-driven-development حسب الطريقة المتفق عليها. الخطوات قابلة للتتبع بـcheckboxes. هذه وثيقة تخطيط فقط.

**Goal:** إصلاح الصلاحيات وسلامة البيانات، استكمال العربية والإنجليزية، وتوحيد التنقل مع اختبارات قبول.
**Architecture:** إبقاء Flutter/Firebase وتقسيم features؛ إضافة Session مركزية وRouter واحد ومستودعات محقونة؛ العمليات المميزة في backend موثوق؛ فصل codes عن النصوص.
**Tech Stack:** Flutter/Dart، Firebase Auth/Firestore/Functions/FCM، flutter_bloc وshared_preferences الموجودان، go_router المقترح، gen-l10n/ARB، Firebase Emulators.
**Spec:** قسم مواصفات التصميم في هذه الوثيقة هو مرجع المهام.
**التاريخ والحالة:** 2026-10-07 — Blueprint فقط، لا تنفيذ أو نشر.

## 1. القيود العامة

- جذر كل المسارات النسبية هنا: D:/work/flutter/efteqad/. أرقام الأسطر للنسخة المراجعة، واسم الدالة يبقى مرجعًا بعد التعديل.
- لم تُفحص Firebase المنشورة؛ القواعد المحلية لا تثبت المنشور. لا نشر أو ترحيل بيانات إنتاج في هذه الجولة.
- نتائج المراجعة السابقة: flutter analyze ناجح؛ 11 اختبارًا ناجحًا أحدها placeholder؛ node --check ناجح. لم تُعد اختبارات التطبيق في جولة كتابة الوثيقة.
- المجلد ليس Git repository وقت الفحص. تجهيز نسخة محفوظة/مستودع تحت إدارة المستخدم يسبق التنفيذ.
- اللغات ar-EG وen-US. أسماء المستخدمين وعناوينهم وتقاريرهم نصوص حرة لا تُترجم تلقائيًا.
- لا إعادة تصميم بصري شاملة؛ التغييرات البصرية للاتجاه والترجمة والأخطاء والحفظ والتنقل.
- go_router بإصدار متوافق مع Flutter المثبت وDart ^3.9.2 عند التنفيذ؛ تثبيت lockfile دون ترقية SDK ضمنية.
- كل مهمة سلوكية: اختبار فاشل للسبب المقصود، تنفيذ محدود، اختبار ناجح، مراجعة؛ لا اختبارات شكلية.
- كل الملفات الجديدة المذكورة مقترحة وليست موجودة لمجرد ورودها هنا.

## 2. مواصفات التصميم

### البدائل والاختيار

| البديل | التقييم |
|---|---|
| ترقيع الخدمات مع Navigator والنصوص المتفرقة | سريع مؤقتًا لكنه يبقي تكرار القرارات |
| إصلاح تدريجي + Session + go_router + ARB | الموصى به: يعالج الأسباب ويحافظ على الشاشات |
| إعادة كتابة كاملة | اتساع ومخاطرة دون حاجة مثبتة؛ خارج النطاق |

go_router يدعم redirection وShellRoute؛ نستخدم Router واحدًا يختار الوجهات حسب Session. المصادر: [go_router](https://pub.dev/packages/go_router)، [Redirection](https://pub.dev/documentation/go_router/latest/topics/Redirection-topic.html).
موارد الترجمة تُنقل إلى ARB وتُولد بـgen-l10n مع إبقاء context.tr أثناء الانتقال. المصدر: [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

### الصلاحيات

Firebase Auth يثبت الهوية، وملف khodam الموثوق يحدد role/grade/status. إزالة الاعتماد الإداري على بريد ثابت؛ تهيئة أمين المرحلة الحالي بأداة إدارية وUID صريح. لا client path لترقية الذات. الـRouter يحسن التدفق، وRules/Functions تفرض الأمان.

حالات Session: booting/signedOut/profileLoading/pending/active/deleting/failure. stageAdmin لا يحتاج grade، وباقي الأدوار النشطة تحتاج سنة صالحة. فشل الشبكة لا يتحول إلى pending.

| الدور | القراءة | الكتابة |
|---|---|---|
| غير مسجل | لا بيانات عمل | لا كتابة |
| pending | ملفه وتفضيلاته وأجهزته | name/phone/locale وجهازه؛ دون role/grade/status |
| servant | مخدوموه وسجلهم ومهامه وإشعاراته وحضور النطاق المسموح | زيارات مخدوميه وإكمال مهامه وحضور مهمة سارية مسندة إليه |
| gradeAdmin | نطاق سنته | مخدومو وإسنادات ومهام سنته؛ دون ترقية أدوار |
| stageAdmin | نطاق المرحلة | التسكين والترقية وإدارة المرحلة بعمليات موثوقة |

حضور القداس العام: إنشاء attendance_roster/{makhdomId} يحوي id/fullName/grade/active فقط؛ المكلف بمهمة all سارية يقرأ الدليل دون عناوين الأطفال وملاحظاتهم. لا نعتمد على إخفاء حقول الوثيقة في UI.

Schema الحضور المقترح: نفس sessionId، وتفاصيل السنة في attendance/{sessionId}/grades/{grade}. الصلاحيات والاستعلامات تضبط على نطاق السنة، والقراءة العامة تجمع الأجزاء. هذا تغيير يحتاج migration وليس نشرًا منفردًا.

### قرارات التحليلات المقترحة

- الإنذار الأسبوعي يعتمد جلسات الخدمة المكتملة؛ القداس مؤشر مستقل، وليس غيابًا ثانيًا لنفس الجمعة.
- status=draft/finalized وfinalizedAt؛ زر إنهاء الرصد؛ الاسم غير المسجل في draft لا يُحكم عليه غائبًا. إعادة فتح الجلسة للمسؤول مع audit.
- trackingStartDate؛ استبعاد الجلسات السابقة. للقديم createdAt افتراضي تقديري ظاهر، قابل للتصحيح من مصدر موثوق.
- لا جلسات مكتملة = بيانات غير كافية، وليس صفرًا أو انقطاعًا. جمعة غير مسجلة لا تعني غياب الجميع.
- تسمية «أثر الافتقاد» تصبح «فرق نسبة الحضور بين المفتقدين وغير المفتقدين»، ووحدة الفرق نقطة مئوية؛ لا ادعاء سببية.
- هذه قرارات مقترحة لمراجعة المعنى قبل التنفيذ؛ تحليل سببي جديد خارج النطاق.

## 3. سجل الإصلاحات

| ID/أولوية | المكان الحالي | التعديل الدقيق | اختبار القبول |
|---|---|---|---|
| SEC-01 حرج | firestore.rules:6؛ lib/core/services/auth_service.dart:isStageAdmin؛ constants.dart:constAdminEmail | قواعد لكل collection وحقول مسموحة؛ أدوار موثوقة؛ منع self-promotion | pending لا يقرأ الأطفال ولا يعدل دوره؛ منع cross-grade |
| DATA-01 مرتفع | firestore_service.dart:updateMakhdom:72؛ add_edit_makhdom_dialog.dart:166 | patch للحقول المتغيرة فقط؛ استبعاد visitCount/lastVisitDate/createdAt؛ الإسناد مستقل | حفظ هاتف بعد زيارة جديدة لا يرجع العداد 4 إلى 3 |
| ATT-01 مرتفع | firestore_service.dart:toggleMakhdomAttendance:489 | إزالة get ثم set؛ كتابة ذرية وarrayUnion/arrayRemove داخل وثيقة السنة | أول تسجيلين متزامنين يحتفظان بالاسمين |
| ATT-02 مرتفع | attendance_screen.dart:197 | remoteIds + pendingById؛ إزالة pending بعد الإقرار؛ sequence لكل مخدوم | remote remove يظهر؛ فشل طلب قديم لا يلغي اختيارًا أحدث |
| EXCEL-01 مرتفع | grade_admin_screen.dart:82؛ excel_actions_sheet.dart؛ excel_service.dart:203؛ makhdom_model.dart:37 | required grade من الشاشة إلى parser والحفظ؛ منع fallback لأول سنة | استيراد ثانية/ثالثة يحفظ فيهما |
| PUSH-01 مرتفع | notification_service.dart:116؛ auth_service.dart:83؛ main.dart:96 | listener واحد للجلسة؛ إزالة ربط الجهاز عند الخروج؛ tokens للأجهزة | A→B على نفس الهاتف لا يستقبل إشعار A |
| AUTH-01 مرتفع | auth_service.dart:deleteAccount:90؛ settings_screen.dart:57 | reauth أولًا؛ deletion job خادمي قابل للاستكمال؛ منع deleting | رفض reauth يترك البيانات؛ retry يستكمل التنظيف |
| VISIT-01 متوسط | firestore_service.dart:recordVisit:318 | مقارنة lastVisitDate داخل transaction؛ lastVisitId؛ فصل notes العامة | زيارة قديمة لا تستبدل الحديثة |
| VISIT-02 متوسط | firestore_service.dart:updateVisitNotes:348 | ملخص الطفل يتغير فقط إذا visitId هو الأخير؛ دعم مسح التقرير | تعديل القديمة لا يلوث الملخص؛ تفريغ الأخيرة يمسحه |
| ASSIGN-01 متوسط | assignMakhdomeenToKhadem/unassignMakhdom/updateMakhdom؛ khadem_profile_screen.dart:227 | معاملة تحديث المصدر والمستلم؛ كل مسارات الإسناد موحدة؛ repair dry-run | النقل والفك والأرشفة تحافظ على assignedCount |
| ANALYTICS-01 متوسط | attendance_analytics_service.dart:getAtRiskStudents/segmentStudents/getWeeklyTrend | finalized وtrackingStartDate؛ تجميع التاريخ؛ maxWeeks تواريخ مميزة | جلستان في الجمعة لا تصبحان أسبوعين؛ الجديد لا يرث غيابًا قديمًا |
| ANALYTICS-02 متوسط | calculateOverallAttendanceRate/getWeeklyTrend؛ app_localizations.dart:visitationImpactValue | نفس eligible IDs للبسط والمقام؛ insufficient عند صفر مقام؛ صياغة غير سببية | لا نسب مضللة عند اختلاف السنوات؛ فرق موجب/سالب/صفر صحيح |
| PERF-01 متوسط | firestore_service.dart:getAttendanceSessionsForGradeStream:523؛ history:getAllAttendanceSessionsStream | استعلام السنة والفترة على الخادم؛ indexes؛ pagination | عدم جلب تاريخ المرحلة كله لشاشة سنة |
| ERROR-01 متوسط | StreamBuilders في main/grade_admin/tasks/analytics/history/notifications | loading/empty/error/offline/pendingWrites مستقلة؛ retry؛ AppFailure | query failure لا يظهر «لا توجد بيانات»؛ pending ليس saved |
| PUSH-02 متوسط | login_screen.dart:46؛ main.dart:96؛ notification_service.dart | sync من Session بعد كل login؛ intent موحد للنقر | أول login يسجل الجهاز دون restart؛ الوجهة محمية |
| PUSH-03 متوسط | functions/index.js:70؛ notification_service.dart:199؛ add_task_dialog.dart | task+outbox معًا؛ pending/sent/failed؛ retry وdedupe | فشل التسليم ظاهر دون تكرار إنشاء المهمة |
| DEPLOY-01 قبل الإصدار | firebase.json:1؛ functions/package.json؛ android/app/build.gradle.kts:38 | rules/indexes/functions/emulators؛ runtime متحقق؛ release signing مستقل | staging ناجح وrelease موقّع بمفتاحه |
| TEST-01 مرتفع | test/widget_test.dart:12 وباقي test | إزالة placeholder؛ Rules/Router/UI/concurrency/import tests | الاختبارات تكشف سيناريوهات الرجوع |
| ARCH-01 متوسط | history 2347 سطرًا؛ analytics 1319؛ khadem_home 1186؛ firestore_service | استخراج حسابات وwidgets ومستودعات محقونة للأجزاء المتأثرة | business logic يُختبر دون Firebase/UI |
| PREF-01 متوسط | main.dart:40؛ settings_screen.dart:192/211/249؛ app_drawer | SettingsCubit وSharedPreferences قبل أول frame؛ مزامنة locale | اللغة والثيم يستمران بعد restart |

الأسماء المختصرة تشير إلى الملف الحالي المطابق تحت lib/core أو lib/features؛ الأقسام التالية تحدد المسارات الكاملة داخل المشروع.

## 4. الروتر الكامل

### الملفات الجديدة والواجهات

| الملف | المسؤولية |
|---|---|
| lib/core/session/session_state.dart | SessionState(status,userId,role,grade,failure)، SessionStatus، UserRole |
| lib/core/session/session_cubit.dart | SessionCubit(AuthRepository,ProfileRepository)، subscriptions حسب المستخدم |
| lib/core/router/app_router.dart | GoRouter createAppRouter(SessionCubit,RouteAccessService,NotificationIntentCoordinator)، instance واحد |
| lib/core/router/app_routes.dart | names/paths وhelpers لبناء الروابط |
| lib/core/router/route_access_service.dart | Future<RouteAccess> check(Uri,SessionState)، allowed/denied/notFound |
| lib/core/router/router_refresh_notifier.dart | Session stream→Listenable مع dispose |
| lib/core/router/notification_intent_coordinator.dart | enqueue(NotificationIntent)، consumeFor(SessionState) بعد فحص صلاحية الوجهة |
| lib/core/router/widgets/protected_resource_page.dart | تحميل ID وعرض loading/error/notFound قبل التفاصيل |
| lib/features/common/presentation/screens/route_error_screen.dart | منع/غير موجود/تعذر تحميل، مع ترجمة وretry |

### المسارات

| المسار | الاسم | المحتوى |
|---|---|---|
| /bootstrap | bootstrap | تهيئة Firebase/preferences/session |
| /login | login | الدخول، وmodal الإدارة |
| /pending | pending | انتظار التسكين وتعديل الملف |
| /stage/people | stagePeople | التسكين والخدام |
| /stage/analytics | stageAnalytics | تحليلات المرحلة |
| /stage/tasks | stageTasks | مهام المرحلة |
| /grades/:grade/makhdomeen | gradeMakhdomeen | مخدومو السنة |
| /grades/:grade/analytics | gradeAnalytics | تحليلاتها |
| /grades/:grade/khodam | gradeKhodam | خدامها |
| /grades/:grade/tasks | gradeTasks | مهامها |
| /me/makhdomeen | myMakhdomeen | مخدومو الخادم |
| /me/tasks | myTasks | مهامه |
| /me/analytics | myAnalytics | تحليلاته |
| /makhdomeen/:makhdomId/history | makhdomHistory | سجل بالـID وصلاحية الإسناد/السنة |
| /tasks/:taskId | taskDetails | صفحة تفاصيل خفيفة جديدة للمهام والإشعارات |
| /tasks/:taskId/attendance | taskAttendance | مهمة حضور مصرح بها وسارية |
| /profile | profile | الملف الشخصي |
| /settings | settings | التفضيلات والخروج والحذف |
| /notifications | notifications | مركز الإشعارات، إعادة استخدام محتوى sheet |
| /forbidden | forbidden | منع وصول |
| unmatched | notFound | مسار غير موجود |

StatefulShellRoute.indexedStack لكل stage/grade/me؛ Router يتحكم في tab مع حفظ scroll/filter. التفاصيل على root navigator. IDs مطلوبة، وextra Model اختياري كcache فقط؛ الروابط تعمل بدونه.

### قواعد الحراسة

1. booting/profileLoading→bootstrap مع حفظ intended URI داخلي صالح.
2. signedOut→login؛ pending→pending مع settings والخروج وفق السياسة.
3. active→وجهة الدور أو intended route بعد التحقق. grade فقط 1st/2nd/3rd.
4. تغير role/grade/userId يمسح shell state القديمة ويغلق streams. مفاتيح shells تعتمد هذه القيم.
5. logout يمسح stack وintents؛ Back لا يرجع لبيانات قديمة.
6. خطأ قراءة الملف له retry، لا pending أو redirect loop.
7. المورد المحذوف notFound والخارج عن النطاق forbidden؛ فحص ID لا يكفي.
8. إشعار قبل readiness ينتظر؛ payload لا يحدد arbitrary URL، فقط type+IDs في allowlist.
9. كل page navigation عبر Router. dialogs/sheets تبقى dialogs، وNavigator.pop لإغلاقها مسموح.
10. splash تابع للتهيئة؛ إزالة Timer 5.1 ثوانٍ كشرط انتقال.

### ملفات التحويل

| الملف | ما سيتغير |
|---|---|
| lib/main.dart:44/82 | MaterialApp.router، حذف AuthRouter بعد النقل، token sync خارج build |
| lib/features/common/presentation/screens/splash_screen.dart:45 | إزالة Timer/PageRouteBuilder |
| lib/features/auth/presentation/screens/login_screen.dart:46/55/60/65/210 | login فقط دون اختيار صفحة الدور |
| lib/features/auth/presentation/screens/pending_assignment_screen.dart:82/116/121 | إزالة pushAndRemoveUntil؛ Session يتابع التسكين |
| lib/features/common/widgets/app_drawer.dart:55/183/200/208/234 | named routes؛ home يفتح التبويب وليس فقط إغلاق Drawer |
| lib/features/settings/presentation/screens/settings_screen.dart:49/109 | logout/delete يغيران Session دون اختيار صفحة |
| lib/features/admin/presentation/widgets/makhdom_card.dart:91/208/572 | فتح history بـmakhdomId |
| lib/features/tasks/presentation/widgets/tasks_tab.dart:326 | attendance/details بـtaskId |
| lib/features/admin/presentation/screens/admin_main_screen.dart:224 | shell؛ استخراج stage_people_tab.dart |
| lib/features/admin/presentation/screens/grade_admin_screen.dart:218 | shell؛ استخراج grade_makhdomeen_tab.dart؛ streams تتبع grade |
| lib/features/khadem/presentation/screens/khadem_home_screen.dart:116/333 | shell؛ my_makhdomeen_tab.dart وmy_analytics_tab.dart؛ route لزر الإنذار |
| lib/features/admin/presentation/screens/makhdom_history_screen.dart | ID وتحليل الموديل الحي بدل widget.makhdom القديم |
| lib/features/attendance/presentation/screens/attendance_screen.dart | taskId ومراقبة الصلاحية أثناء الفتح |
| lib/features/common/widgets/notifications_sheet.dart؛ notification_service.dart | coordinator للنقر من القائمة وFCM والمحلي |

## 5. الترجمة

### البنية

- إنشاء l10n.yaml وlib/l10n/app_ar.arb وapp_en.arb؛ المولد في lib/l10n/generated/ باسم GeneratedAppLocalizations أثناء الانتقال.
- pubspec.yaml: flutter.generate=true. لا نظام ترجمة إضافي.
- lib/core/localization/app_localizations.dart يصبح compatibility export/extension؛ context.tr للمولد وisArabic من Locale؛ إزالة class/delegate اليدويين بعد نقل الاستدعاءات.
- إنشاء lib/core/localization/domain_labels.dart لأسماء grade/role/taskType/visitType؛ Models تحتفظ بـcodes.
- إنشاء lib/core/localization/app_formatters.dart للتاريخ والأرقام حسب locale؛ ICU plurals للجمع.
- إنشاء lib/core/settings/settings_cubit.dart وsettings_repository.dart: load، setLocale(Locale)، setThemeMode(ThemeMode). الافتراضي أول مرة ar-EG، ثم المحفوظ؛ تفضيل الحساب إن وجد يتقدم على الجهاز عند الدخول.
- الخدمات تنتج AppFailure codes؛ UI يترجم permissionDenied/networkUnavailable/invalidExcel/recentLoginRequired بدل عرض $e.

### مواضع النصوص المؤكدة

المسارات التالية تحت lib/features، إلا core تحت lib. هذه مواقع مثبتة وليست عدًّا لكل النصوص؛ التعليقات وlegacy values ليست UI.

| الملف والأسطر | النصوص | المفاتيح المقترحة |
|---|---|---|
| admin/presentation/screens/makhdom_history_screen.dart:770/805/887/1076/1162/1301/1552/2243 | نسخ العنوان/الموقع/الهاتف، الملخص والفلاتر والحالات الفارغة وتقرير الزيارة | copyAddress/copyLocation/copyPhone/historyVisitSummary/historyTimeline/noVisitsYet/visitReportHint/reportUpdated |
| admin/presentation/screens/analytics_tab.dart:556/600/608/616 | لا جلسات، نسبة عامة، عدد الجمعات، خدمة/قداس | noAttendanceSessions/overallAttendanceRate/recordedFridayCount/serviceAttendance/massAttendance |
| admin/presentation/screens/admin_main_screen.dart:128/152/397/401/434 | لا خدام، الأمين الحالي، التعداد | noServantsInGrade(grade)/currentGradeAdmin/assignedServantsCount(count) |
| admin/presentation/widgets/add_edit_makhdom_dialog.dart:393/410/423/437 | العمر، دقيق/تلقائي، الميلاد، إلغاء تخصيصه | ageYears/ageFromBirthDate/estimatedAge/birthDateValue/resetBirthDate |
| admin/presentation/widgets/makhdom_card.dart:403 | العمر حسب السنة | estimatedAgeForGrade(age,grade) |
| attendance/presentation/screens/attendance_screen.dart:116/153/485 | الخطأ، الجمعة ثابتة، 1ث/2ث/3ث | saveFailed/attendanceDate(date)/gradeShortLabel؛ يوم فعلي حسب التاريخ |
| tasks/presentation/widgets/add_task_dialog.dart:133/288/304 | خطأ، تحديد تاريخ، جمعة | taskDate/optionalTaskDate/nextFriday |
| common/widgets/record_visit_sheet.dart:315 | عنوان ووصف الديسكريبشن | visitReportLabel/visitReportHint |
| khadem/presentation/screens/khadem_home_screen.dart:541/1086 | X من Y مخدوم، % حضور | visitedOutOfTotal(visited,total)/attendancePercent(value) |
| khadem/presentation/screens/khadem_profile_screen.dart:182 | خادم بالمرحلة | stageServantFallback |
| core/models/khadem_model.dart:36؛ makhdom_model.dart:75؛ task_model.dart:32 | getters عربية للسنة/المهمة | DomainLabels |
| core/services/excel_service.dart:11/226 | الأعمدة، نعم/لا، العمر، غير مربوط، المشاركة | ExcelColumnLabels(locale) وexport/share resources |
| core/services/notification_service.dart:25/96؛ functions/index.js:36 | قناة وعنوان fallback ولغة المرسل | channel resources وقوالب بلغة المستلم |
| core/services/auth_service.dart:35 | رفض المسؤول بالعربية | AppFailure.notAuthorized |

نصوص مترجمة لكن مشتتة في excel_actions_sheet.dart وassign_makhdomeen_modal.dart وnotifications_sheet.dart وkhadem_home_screen.dart وadd_task_dialog.dart تُنقل من isArabic ternaries إلى ARB؛ لا تُصنف كلها «ناقصة».

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| copyAddress | نسخ العنوان | Copy address |
| currentGradeAdmin | أمين السنة الحالي | Current grade administrator |
| visitReportLabel | تقرير الافتقاد | Visit report |
| saveFailed | تعذر الحفظ. حاول مرة أخرى. | Could not save. Please try again. |
| syncPending | محفوظ على الجهاز، في انتظار المزامنة | Saved on this device; waiting to sync |
| dataUnavailable | تعذر تحميل البيانات | Could not load data |
| insufficientAttendanceData | بيانات الحضور غير كافية | Not enough attendance data |

### البيانات والاتجاه والتصدير

- visitType=home/phone/church/other؛ legacy parser للعربي والإنجليزي؛ unknown يحتفظ بالنص الأصلي دون contains في UI.
- secondaryType code للخيارات وcustomLabel للنص الحر. اللغة لا تغير البيانات المخزنة. session IDs وdate المخزن ISO ثابت، والعرض محلي.
- EdgeInsetsDirectional/AlignmentDirectional؛ الهواتف والروابط LTR داخل RTL؛ اختبار text scale 200%.
- فحص assets/images بصريًا وقت التنفيذ للنص المدمج؛ overlay مترجم أو أصل لكل لغة إذا وُجد؛ لا افتراض نتيجة فحص لم يحدث.
- Excel رؤوس عربية/إنجليزية وaliases للقالب القديم؛ منع التخمين عند header غير مفهوم؛ الهواتف نصوص؛ رفض الصفوف بتقرير، وتنبيه لصف العينة؛ export باللغة المختارة وISO للتبادل.
- اختبار xls بملف فعلي؛ إذا لم يدعمه parser يقيد picker بـxlsx.
- النظام يخزن إشعار templateKey+args مع legacy title/body fallback؛ العرض بلغة القارئ، وpush بلغة المستلم. نص المستخدم لا يترجم آليًا.
- channel ID ثابت مع ترجمة الاسم/الوصف؛ موارد اسم الأيقونة Android/iOS عند استهدافهما، لا MaterialApp title فقط.


## 6. مهام التنفيذ الدقيقة

الأوامر أدناه للاستخدام لاحقًا وليست اختبارات أُجريت على تنفيذ جديد. بعد كل مهمة يراجع فرق الملفات وتسجل نقطة رجوع إذا جُهز Git. كل إنشاء/تعديل في القواعد يترافق مع اختبار محاكي؛ لا تُنشر المراحل منفردة بما يكسر العميل القديم.

### Task 1 — الجلسة وحقن البيانات

**Modify:** lib/core/services/auth_service.dart، firestore_service.dart، lib/core/models/khadem_model.dart، lib/main.dart.
**Create:** lib/core/repositories/auth_repository.dart، profile_repository.dart، session files بالقسم 4.
**Interfaces:** AuthRepository.watchAuth(): Stream<AuthIdentity?>؛ ProfileRepository.watchProfile(String uid): Stream<KhademModel?>؛ AuthIdentity هو UID وبيانات عرض دون صلاحية مستنتجة من email؛ SessionCubit.state: SessionState.
- [ ] اكتب test/core/session/session_cubit_test.dart: stageAdmin بلا grade يصبح active؛ servant بلا grade يصبح pending؛ profile failure يبقى failure؛ تغيير UID يلغي listener القديم.
- [ ] شغّل flutter test test/core/session/session_cubit_test.dart وتأكد أنه يفشل للسبب المقصود.
- [ ] حقن Firebase implementations؛ مراقبة Auth/profile مرة واحدة؛ إزالة side effects من build.
- [ ] أعد الأمر؛ كل الحالات PASS؛ راجع وتوثق نقطة رجوع.

### Task 2 — القواعد والعمليات الإدارية

**Modify:** firestore.rules، firebase.json، functions/index.js، functions/package.json، pubspec.yaml.
**Create:** firestore.indexes.json؛ functions/src/access.js؛ functions/src/admin_operations.js؛ functions/test/firestore.rules.test.js؛ lib/core/services/privileged_operations_service.dart.
**Interfaces:** authorize(actor,operation,resource)؛ callable setKhademGrade({khademId,grade}) وsetGradeAdmin({khademId,grade})؛ actor من auth context وليس payload. إضافة cloud_functions بإصدار متوافق.
- [ ] اختبارات allow/deny لمصفوفة الأدوار، self-promotion، انتحال creatorId، cross-grade، roster، stageAdmin.
- [ ] جهز npm test في functions؛ شغّل firebase emulators:exec --only auth,firestore,functions "npm --prefix functions test"؛ أثبت الفشل ثم طبّق القواعد/العمليات وأعده PASS.
- [ ] المستخدم ينشئ ملف pending بUID نفسه وحقول محددة فقط؛ الأدوار والترقيات حصريًا backend؛ deny-default لباقي البيانات.
- [ ] طابق queries مع Rules؛ القواعد لا تعمل filter لنتائج استعلام واسع.
- [ ] اربط config وindexes وEmulators؛ الإنتاج ينتظر خطة الانتقال في Task 14.

### Task 3 — Patch المخدوم والإسناد

**Modify:** lib/core/services/firestore_service.dart:updateMakhdom/assign/unassign/deleteMakhdom؛ lib/features/admin/presentation/widgets/add_edit_makhdom_dialog.dart وassign_makhdomeen_modal.dart؛ lib/features/khadem/presentation/screens/khadem_profile_screen.dart.
**Create:** lib/core/repositories/makhdom_repository.dart؛ lib/core/models/makhdom_profile_patch.dart؛ functions/src/assignments.js؛ functions/test/assignments.test.js.
**Interfaces:** updateProfile(String id,MakhdomProfilePatch patch): Future<void>؛ callable assignMakhdoms({ids,targetKhademId,expectedAssignments,operationId})؛ null target يفك الإسناد. Patch يميز unset عن null الصريح ولا يحتوي عدادات/تواريخ زيارة/createdAt.
- [ ] اختبار عداد 3→4 أثناء فتح تعديل هاتف؛ إسناد تغير أثناء الحوار ينتج conflict؛ مسح حقل اختياري يعمل.
- [ ] flutter test test/core/repositories/makhdom_repository_test.dart واختبارات assignments بالمحاكي: FAIL ثم PASS.
- [ ] transaction لكل انتقال مع عدادي المصدر والمستلم، نتائج لكل عنصر bulk؛ operationId يمنع الزيادة المكررة. لا overwrite لإسناد غير متوقع.
- [ ] الحذف الحالي يتحول archive منطقي؛ active=false يخرج من القوائم الجديدة ويحفظ التاريخ. منع cascade غير موثق.

### Task 4 — الزيارات والملخصات

**Modify:** lib/core/services/firestore_service.dart:recordVisit/updateVisitNotes؛ lib/core/models/visit_model.dart وmakhdom_model.dart؛ lib/features/common/widgets/record_visit_sheet.dart؛ lib/features/admin/presentation/screens/makhdom_history_screen.dart.
**Create:** functions/src/visits.js؛ functions/test/visits.test.js؛ lib/core/repositories/visit_repository.dart؛ lib/core/services/visit_draft_store.dart.
**Interfaces:** recordVisit({operationId,makhdomId,visitDate,visitType,notes})→visitId؛ updateVisitNotes({visitId,notes})؛ backend يملأ هوية الكاتب من auth ويفحص الإسناد؛ visit draft مفصول حسب userId.
- [ ] زيارة حديثة ثم قديمة: count=2 وlastVisitId للحديثة؛ retry لنفس operationId لا يزيد؛ تعديل القديمة لا يغير الملخص؛ تفريغ الأخيرة يمسحه.
- [ ] اختبارات visits عبر أمر المحاكي: FAIL ثم PASS بعد transaction للسجل والعداد وآخر زيارة.
- [ ] عند تساوي visitDate استخدم createdAt ثم id لترتيب ثابت؛ general notes لا تتبدل بتقرير زيارة.
- [ ] callable يحتاج اتصالًا؛ offline يحتفظ بمسودة محلية عبر SharedPreferences ورسالة «لم تُرسل بعد»؛ إعادة إرسال صريحة بنفس operationId؛ مسحها بعد النجاح، لا ادعاء حفظ خادمي.

### Task 5 — الحضور والتزامن

**Modify:** lib/core/models/attendance_session_model.dart وtask_model.dart؛ lib/core/services/firestore_service.dart؛ lib/features/attendance/presentation/screens/attendance_screen.dart.
**Create:** lib/features/attendance/application/attendance_cubit.dart؛ lib/core/repositories/attendance_repository.dart؛ functions/src/attendance.js.
**Interfaces:** setPresence({sessionId,grade,makhdomId,isPresent}): Future<void>؛ watchGradeSession(...): Stream<AttendanceSessionModel?>؛ finalizeAttendance({sessionId,grade}) خادمي؛ AttendanceState(remoteIds,pendingById,saveErrors,status).
- [ ] test/features/attendance/attendance_cubit_test.dart: أول كتابتين، remote remove، true→false سريع، failure قديم، تعديل finalized ممنوع، retry دون تكرار.
- [ ] flutter test test/features/attendance/attendance_cubit_test.dart ومحاكي Firestore: FAIL ثم PASS.
- [ ] تطبيق schema السنة والكتابة الذرية؛ request sequence لكل ID؛ القائمة المعروضة آخر remote snapshot مع pending overrides.
- [ ] منع finalize مع طلبات معلقة؛ finalize يثبت completed على الخادم؛ offline لا يزعم إنهاء الرصد.
- [ ] إظهار saved/pending/failed بدقة؛ عدم استخدام جلسة draft في الغياب النهائي؛ تاريخ المهمة وليس نص «الجمعة» الثابت.

### Task 6 — Excel

**Modify:** lib/core/services/excel_service.dart؛ lib/features/admin/presentation/widgets/excel_actions_sheet.dart؛ lib/features/admin/presentation/screens/grade_admin_screen.dart؛ firestore_service.dart:addBulkMakhdomeen.
**Create:** lib/core/models/excel_import_result.dart؛ functions/src/imports.js؛ test/core/services/excel_service_test.dart؛ test/fixtures/excel/.
**Interfaces:** parseMakhdomeen(Uint8List bytes,{required String grade}): ExcelImportResult(rows,rowErrors,warnings)؛ importRows({importId,grade,rows})→ImportResult لكل صف؛ ExcelColumnLabels(Locale) في lib/core/localization/excel_column_labels.dart؛ exportMakhdomeen(...,{required ExcelColumnLabels labels}).
- [ ] fixtures عربي/إنجليزي، ثانية/ثالثة، عمود ناقص، هاتف صفره الأول، تاريخ غير صالح، صف عينة، نفس الملف مرتين، ملف متعدد الأجزاء.
- [ ] flutter test test/core/services/excel_service_test.dart: FAIL ثم PASS بعد فصل picker/parser وتمرير grade.
- [ ] المعاينة تعرض السنة والمقبول/المرفوض والتكرارات المحتملة؛ لا dedupe آلي بالهاتف لأن الإخوة قد يشتركون فيه.
- [ ] أجزاء بحد تطبيقي أولي 200 صف، لا ادعاء أنه حد Firebase؛ importId+rowId ثابت للretry؛ عرض تقدم ونتيجة جزئية قابلة للاستكمال.
- [ ] اختبر round-trip export→import باللغتين دون فقد أعمدة أو تحويل الهاتف لعدد.

### Task 7 — حذف الحساب

**Modify:** lib/core/services/auth_service.dart:deleteAccount؛ firestore_service.dart:deleteKhademAccount؛ lib/features/settings/presentation/screens/settings_screen.dart.
**Create:** functions/src/account_deletion.js؛ functions/test/account_deletion.test.js؛ lib/core/repositories/account_repository.dart.
**Interfaces:** reauthenticate(): Future<void>؛ requestDeletion({operationId})→deletionRequestId؛ account_deletions/{uid}: queued/cleaning/authDeleted/completed/failedRetryable.
- [ ] reauth ملغى/مرفوض لا يغير الإسنادات؛ فشل التنظيف يستكمل؛ retry لا يمس إسنادًا جديدًا؛ token listener لا يعيد إنشاء المستخدم المحذوف.
- [ ] اختبارات account deletion بالمحاكي وUI: FAIL ثم PASS.
- [ ] بعد reauth الخادم يثبت deleting ويمنع الوصول، ثم ينظف الأجهزة والإسنادات والملف ويحذف Auth مع retries؛ لا وعد بـtransaction واحدة عبر Auth وFirestore.
- [ ] أمين المرحلة لا يحذف نفسه قبل بديل إداري مثبت؛ قيد واضح مترجم.

### Task 8 — الأجهزة والإشعارات والمهام

**Modify:** lib/core/services/notification_service.dart وauth_service.dart؛ functions/index.js؛ lib/features/tasks/presentation/widgets/add_task_dialog.dart؛ lib/core/models/khadem_model.dart.
**Create:** lib/core/services/device_registration_service.dart؛ functions/src/notifications.js وtasks.js؛ functions/test/notifications.test.js.
**Interfaces:** bindUser(String uid)/unbindUser(): Future<void>؛ khodam/{uid}/devices/{installationId}:token,locale,updatedAt؛ createTask({operationId,...}) يحفظ task+notification outbox بنفس العملية؛ state=pending/sent/failed.
- [ ] اختبارات A→B، refresh بعد logout، أول login، جهازين، transient error، invalid token، repeated event.
- [ ] flutter test test/core/services/device_registration_service_test.dart واختبارات المحاكي: FAIL ثم PASS.
- [ ] listener واحد؛ تنظيف الربط القديم وتدوير/حذف التوكن عند الحاجة؛ عند offline يؤجل تفعيل push للحساب الجديد حتى cleanup؛ payload على lock screen بلا تفاصيل حساسة.
- [ ] retries محدودة ومؤجلة مع حذف invalid tokens؛ dedupe لا يدعي exactly-once لـFCM. sent تعني قبول FCM وليس قراءة المستخدم.

### Task 9 — ARB والتفضيلات

**Files:** كل ملفات القسم 5؛ lib/main.dart؛ settings_screen.dart؛ app_drawer.dart؛ pubspec.yaml.
**Interfaces:** context.tr من المولد؛ DomainLabels يستهلك codes والموارد؛ AppFormatters(Locale)؛ SettingsState(locale,themeMode,loaded).
- [ ] tests في test/core/localization/ وtest/core/settings/: استمرار locale/theme؛ plurals 0/1/2/3/11/100؛ codes لا تتغير؛ تبديل اللغة يحفظ route.
- [ ] نقل الموارد الموجودة أولًا ثم استكمال جدول النصوص؛ إصلاح كل توقيع getter؛ منع raw exception messages في UI.
- [ ] flutter gen-l10n ثم flutter test test/core/localization/ test/core/settings/: PASS بعد إثبات فشل الحالات الناقصة.
- [ ] إنشاء tool/audit_localization.dart لفحص AST للنصوص المعروضة والمفاتيح/placeholders مع allowlist موثق؛ لا اعتبار كل حرف عربي خطأ.
- [ ] widget tests للشاشات الأساسية ar/en واتجاه RTL/LTR وتكبير 200%؛ بيانات المستخدم العربية مسموحة في EN.
- [ ] قوالب backend: functions/src/notification_templates.js مع ar/en وrecipient locale؛ اختبارات مستقلة للمحتوى والمتغيرات.

### Task 10 — Router والـShells

**Files:** القسم 4؛ pubspec.yaml؛ جديد lib/features/tasks/presentation/screens/task_details_screen.dart؛ stage_people_tab.dart وgrade_makhdomeen_tab.dart في lib/features/admin/presentation/widgets/؛ my_makhdomeen_tab.dart وmy_analytics_tab.dart في lib/features/khadem/presentation/widgets/.
**Interfaces:** createAppRouter وRouteAccessService المحددان؛ history بالـmakhdomId وattendance بالـtaskId؛ لا extra إجباري.
- [ ] test/core/router/app_router_test.dart: landing لكل دور؛ pending/error؛ forbidden grade؛ bad/deleted ID؛ intended route؛ redirect loop؛ logout ثم Back.
- [ ] flutter test test/core/router/app_router_test.dart: FAIL ثم PASS بعد MaterialApp.router والـguards والـshells.
- [ ] انقل كل page navigation بالقسم 4، واحتفظ بإغلاق modals؛ Drawer home يفتح وجهة فعلية.
- [ ] widget tests تحفظ tab scroll/filter؛ تغيير role/grade/user يمسح القديم؛ downgrade أثناء التفاصيل يغلقها.
- [ ] URI refresh/deep link بالـID دون extra؛ Android/iOS app links تحتاج domain وإعدادات حقيقية قبل تفعيلها، لا اختراع نطاق. الـRouter الداخلي قابل للاختبار دون domain.

### Task 11 — نقر الإشعارات

**Modify:** notification_service.dart؛ notifications_sheet.dart؛ functions/src/notifications.js؛ notification_intent_coordinator.dart.
**Create:** lib/features/common/widgets/notification_list.dart؛ lib/features/common/presentation/screens/notifications_screen.dart.
**Interfaces:** NotificationIntent.fromPayload(Map<String,dynamic>) يتحقق من type/taskId/makhdomId؛ لا arbitrary route.
- [ ] test/core/router/notification_intent_test.dart: foreground/local/background/terminated لنفس الوجهة؛ deleted→notFound؛ cross-scope→forbidden؛ login ثم consume مرة واحدة.
- [ ] flutter test test/core/router/notification_intent_test.dart: FAIL ثم PASS.
- [ ] ربط getInitialMessage/onMessageOpenedApp/local launch response؛ انتظار session؛ markAsRead ليس دليل تصريح بفتح المورد.

### Task 12 — التحليلات وفصل السجل

**Modify:** lib/core/services/attendance_analytics_service.dart؛ lib/features/admin/presentation/screens/analytics_tab.dart وmakhdom_history_screen.dart؛ khadem_home_screen.dart؛ makhdom_model.dart.
**Create:** lib/features/admin/application/makhdom_history_service.dart؛ lib/features/admin/models/history_analysis.dart؛ history_header.dart وhistory_kpis.dart وhistory_filters.dart وhistory_timeline.dart في admin/presentation/widgets/.
**Interfaces:** analyzeHistory({required MakhdomModel makhdom,required List<VisitModel> visits,required List<AttendanceSessionModel> sessions,required DateTime asOf}): HistoryAnalysis؛ hasSufficientData؛ clock محقون.
- [ ] اختبارات جمعتي غياب خدمة، قداس وخدمة نفس اليوم، جديد، draft/future، صفر جلسات، درجات مختلفة، تعديل grade حي، weeks تواريخ مميزة.
- [ ] flutter test test/attendance_analytics_service_test.dart test/features/admin/makhdom_history_service_test.dart: FAIL ثم PASS.
- [ ] تطبيق سياسة القسم 2؛ إخراج الحسابات من build؛ استخدام الموديل الحي؛ الفصل بين general notes وvisit report؛ ترجمة فرق النسبة دون سببية.

### Task 13 — الاستعلامات والأخطاء والأداء

**Modify:** firestore_service.dart والمستودعات وStreamBuilders المحددة؛ main.dart:cacheSizeBytes؛ firestore.indexes.json.
**Create:** lib/core/errors/app_failure.dart؛ lib/core/widgets/async_content.dart؛ lib/core/models/page_result.dart.
**Interfaces:** watchGradeAttendance({grade,from,to})؛ fetchVisitPage({makhdomId,cursor,limit=50}): Future<PageResult<VisitModel>>؛ fetchNotificationPage({uid,cursor,limit=50})؛ AppFailure(code,retryable).
- [ ] tests: permission/network/decode ليست empty؛ pagination بتاريخ متساوٍ بلا فقد/تكرار؛ تغيير سنة يلغي query؛ offline cache موصوف.
- [ ] flutter test test/core/repositories/ test/core/widgets/ مع queries في emulator: FAIL ثم PASS.
- [ ] استعلام server-side للفترة والسنة، tie-break document ID وcursor؛ unread count منفصل عن كل الإشعارات؛ markAllRead على أجزاء قابلة للاستكمال.
- [ ] فترة التحليلات الافتراضية المقترحة 90 يومًا ظاهرة في العنوان؛ all-time بتجميع/استعلام صريح، لا حساب من أول صفحة فقط. كل المقارنات لنفس الفترة.
- [ ] قياس reads ووقت أول تحميل على staging؛ cache محدود بعد القياس، دون افتراض أن cache يحل خصوصية الهاتف المشترك.

### Task 14 — الترحيل والتوثيق والإصدار

**Modify:** firebase.json؛ functions/package.json؛ android/app/build.gradle.kts؛ README.md؛ ios/Runner/Info.plist عند استهداف iOS.
**Create:** functions/scripts/migrate_v2.js وbootstrap_admin.js؛ functions/test/migration.test.js؛ docs/release-checklist.md؛ .github/workflows/quality.yml فقط إذا اختير GitHub كمستودع.
**Interfaces:** migration CLI --dry-run/--apply/--resume مع report/checkpoint؛ لا أسرار في التقرير؛ bootstrap_admin يتطلب UID صريحًا.
- [ ] tests dry-run بلا كتابة، retry idempotent، legacy visitType وتوكن مفرد وعدادات خاطئة وحقول ناقصة؛ FAIL ثم PASS بالمحاكي.
- [ ] attendance القديم يتحول لأجزاء سنة من مصدر موثوق؛ لا استنتاج سنة تاريخية من السنة الحالية عند اختلافهما. الغامض يظهر في تقرير ولا يصحح صامتًا.
- [ ] حالة الجلسة القديمة legacyUnknown حتى اعتمادها، قبل دخولها في إنذارات finalized؛ trackingStartDate القديم تقديري؛ الاحتفاظ بـlegacyNotes عند اختلاط الملاحظة العامة بالتقرير.
- [ ] backup واستعادة تجريبية؛ readers متوافقة أولًا؛ backend/schema في staging؛ migration؛ client؛ تنسيق تشديد Rules وإيقاف العميل القديم دون فترة allow-all جديدة.
- [ ] README للتشغيل والأدوار والـRouter والترجمة والمحاكيات والتوقيع والاستعادة. الأسرار خارج الملفات المتتبعة.
- [ ] release signing مستقل؛ لا تغيير applicationId قبل مراجعة Firebase registration. config وحده لا يكفي لاختبار Google Sign-In.
- [ ] iOS: URL schemes ووصف استخدام الموقع وAPNs/capabilities في بيئة Apple؛ Web/desktop: اختبار plugins/exports/notifications قبل إعلان الدعم.
- [ ] تدقيق Runtime Functions المدعوم وقت التنفيذ بالوثائق الرسمية؛ lockfile؛ CI أو نفس الأوامر محليًا إذا لم يتوفر GitHub.

## 7. Review Focus والقبول

| الخطر المركب | المهمة المالكة للاختبار | النتيجة |
|---|---|---|
| تغيير المستخدم/السنة مع route وlistener وtoken نشط | 1،8،10 | لا بيانات أو إشعارات أو Back للحساب القديم |
| جهازان وشبكة متقطعة وضغط حضور متكرر | 5 | لا فقد أسماء ولا Saved كاذب |
| بيانات قديمة بلغتين وأنواع غير معروفة | 9،12،14 | توافق وحفظ الأصل وتقرير غموض |
| Rules جديدة واستعلامات قديمة واسعة | 2،13 | queries صحيحة أو خطأ مفهوم، لا empty وهمية |
| إشعار محذوف/غير مصرح قبل login أو بعد logout | 10،11 | انتظار ثم وجهة آمنة مرة واحدة |

سيناريو متكامل: Google login جديد → pending → تحديث الملف → تسكين من المسؤول → Router يتحدث → Excel للسنة الصحيحة → إسناد → مهمة وإشعار بلغة المستلم → فتح من الإشعار → حضور جهازين → finalize → زيارة قديمة لا تفسد الأخيرة → تغيير لغة وثيم وrestart → logout وتبديل حساب دون تسرب → حذف مع reauth فاشل ثم ناجح.

ملف جديد integration_test/app_flows_test.dart يغطي التدفق على emulator/staging دون بيانات إنتاج. إضافة integration_test كSDK dev dependency.

أوامر بوابة الجودة وقت التنفيذ:

~~~text
flutter gen-l10n
dart run tool/audit_localization.dart
flutter analyze
flutter test
firebase emulators:exec --only auth,firestore,functions "npm --prefix functions test"
flutter test integration_test/app_flows_test.dart -d <test-device-id>
flutter build appbundle --release
~~~

نجاح release build يحتاج إعداد توقيع فعلي ولا يعني نشر الإصدار. اختبارات الأجهزة وPush والمنصات تُذكر بنتائجها الفعلية دون استنتاج من نجاح unit tests.

## 8. التبعيات وترتيب التنفيذ

1. 1 و2 للجلسة والصلاحيات؛ لا نشر إنتاجي للقواعد وحدها.
2. 3→4→5→6→7→8 لسلامة البيانات والخدمات. تعديل Rules المقابل لكل schema مع اختبارها بالمحاكي.
3. 9 للترجمة والتفضيلات.
4. 10 للروتر يعتمد 1 والمستودعات؛ 11 يربط 8 بـ10.
5. 12 يعتمد finalized/trackingStartDate من 5 وموارد 9؛ 13 للاستعلامات والأخطاء.
6. 14 للترحيل وstaging والإصدار بعد الاختبارات المتكاملة.

**تعريف الاكتمال:** كل مشكلة لها اختبار قبول؛ كل صفحة كاملة لها route؛ النص النظامي مترجم بما فيه الصادرات والإشعارات؛ Rules تحمي البيانات؛ التزامن لا يفقدها؛ migration/restore مجربان على staging؛ الأداء والمنصات موثقان بما تم تشغيله فعليًا.

**ناتج هذه الجولة:** ملف البلوبرينت فقط. لا تنفيذ أو تثبيت حزم أو تعديل قواعد/كود التطبيق أو نشر.


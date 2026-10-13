# إعادة فحص تنفيذ البلوبرينت — 2026-10-08

النسخة: `1e89a59`، مقارنة بالمراجعة السابقة عند `cd3bf4b`. توجد 11 commits جديدة وتغييرات في62 ملفًا. المرجع: [البلو برينت](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md)، [تقرير الجولة الأولى](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-08-blueprint-implementation-audit.md).

**النتيجة: تحسن فعلي ونجاح بوابة الاختبارات المحلية، لكن البلوبرينت ما زال منفذًا جزئيًا.** لا تكفي النتائج الحالية لاعتماد كل شروط أي مهمة كاملة. هذا التقرير يحدّث أحكام الجولة الأولى؛ العيوب التي أُصلحت أدناه لا تُعد مفتوحة لمجرد وجودها في التقرير القديم.

فُحصت التغييرات ومسارات الاستدعاء الفعلية باستخدام Superpowers ومراجعات مستقلة. لم يُعدَّل كود التطبيق ولم يحدث نشر أو ترحيل للإنتاج.

## الاختبارات المعادة

| الفحص | النتيجة الحالية | المقارنة/الحدود |
|---|---|---|
| flutter analyze --no-pub | ناجح، No issues found | لا أخطاء تحليل ساكن |
| flutter test --no-pub | **143 ناجحة، exit0** | كانت105؛ اختبارات إضافية، لكن integration_test ما زال غائبًا |
| Firebase emulators:exec + npm test | **64 ناجحة، صفر فشل/تخطي، exit0** | كانت48/49 مع فشل Rules؛ المشكلة السابقة أُصلحت |
| تحميل Functions | نجح وتحملت11 دالة | إعداد node أصبح20؛ المحاكي استخدم Node22 المحلي مع تحذير mismatch، فلا يُثبت هذا التشغيل على20 |
| dart run tool/audit_localization.dart | ناجح؛16 مفتاحًا لكل لغة | لا يفحص الشاشات فعليًا؛ تفاصيل القصور أدناه |
| release/staging/backup/restore/FCM على أجهزة | غير متحقق | لا يُفترض النجاح من ملفات الإعداد |

استُخدم مشروع المحاكي `demo-efteqad-rules` وJava25 المثبت مع Android Studio؛ إعداد البيئة مؤقت داخل العملية. نجاح64 اختبارًا لا يعني وجود64 اختبارًا لاستدعاءات callable متكاملة؛ كثير منها business helpers بمخازن مقلدة.

## مراجعة جميع المهام

| المهمة | ما تحسن أو أُصلح | ما بقي | الحكم |
|---|---|---|---|
| 1 Session | stageAdmin يشترط active؛ deleting موجودة؛ نقل notifier mutations خارج build | Router لا يعالج deleting؛ بعض التنقل/الجلسات القديمة والتفضيلات قبل أول frame لم تكتمل | جزئي |
| 2 Rules/backend | إصلاح assignedCount القديم؛ whitelist pending؛ devices؛ aliases للزيارات والمهام؛ اختبارات Rules إضافية | auth-only callables، قراءة السنة لكل خادم، writes حضور بلا مهمة/finalized، بعض UI تخالف القواعد | جزئي |
| 3 patch/assignment/archive | clearPhoto؛ فلترة active بالقوائم؛ قراءة قبل الكتابة وحساب deltas؛ expectedAssignments؛ marker خادمي ذري | UI لا تستعمل callable؛ عدادات خادم آخر محظورة على gradeAdmin؛ تحقق سنة/حالة المستلم وper-item results ناقص | جزئي |
| 4 visits/drafts | الحفاظ على notes العامة؛ lastVisitNotes؛ drafts موصلة؛ marker داخل callable transaction | UI لا تمرر operationId للدالة؛ لا authorize بالـcallable؛ tie-break/آخر تقرير فارغ غير مكتملين | جزئي |
| 5 attendance | كتابة grades؛ finalize callable؛ retry intent/read errors/tests أفضل | Rules تسمح بتجاوز finalized والمهمة؛ taskId خادمي غير متحقق؛ mass تقرأ full records؛ أخطاء loading/order/finalize failed saves | جزئي |
| 6 Excel | fixtures حقيقية؛ تحذيرات التاريخ؛ عرض كل warnings؛ اختيار sheet populated؛ دعم importId بالخدمة | UI تولد ID جديدًا كل محاولة؛ merge قد يعيد counters/تعديلات؛ لا resume ledger؛ xls غير مثبت وinvalid numeric dates قد تُطبّع | جزئي |
| 7 deletion | reauth متعدد المزودين؛ deleting؛ إعادة قراءة الإسناد قبل فكه؛ بديل admin نشط؛ failure state | لا durable retry worker؛ فشل وضع deleting يُبتلع؛ race حذف آخر مسؤول؛ cleanup الجهاز غير مضمون | جزئي |
| 8 devices/push | listener static مشترك؛ fresh state check؛ no_devices/invalid/transient؛ templates موصلة | cleanup errors مستترة؛ لا تنفيذ retries مؤجلة؛ partial delivery تصبح sent؛ UI task ما زالت ممنوعة | جزئي |
| 9 localization/preferences | plurals واختبارات إضافية؛ تحسين JSON/placeholder checks | ARB غير موصلة،16 مفتاحًا فقط؛ نصوص عربية وraw errors باقية؛ audit بلا source scan؛ widgets اختباريّة وليست الشاشات | جزئي |
| 10 router | Drawer profile/settings/logout تحول؛ intended route لحالة signedOut؛ fetch حتى مع cache | login/pending/settings/history/tasks ما زالت Navigator؛ grade tabs ثابتة1st؛ cold boot link يضيع؛ guards/scope reset ناقصة | جزئي |
| 11 notification taps | aliases للbackend؛ enqueue ينعش Router؛ clear عند logout | فحص المورد/الدور الفعلي يعتمد Router الناقص؛ live downgrade/deleted/cross-account flow غير مثبت بالكامل | جزئي |
| 12 analytics/history | استبعاد غير finalized في AttendanceAnalyticsService | mass/service مختلطان؛ tracking غائب؛ numerator/denominator مختلفان؛ zero insufficient/maxWeeks/stale history | جزئي |
| 13 queries/errors/perf | بقاء helpers وgrade filters وتحسينات محدودة |90 يومًا عنوان فقط؛ cursor غير موصل؛ errors تتحول empty؛ cache metadata/قياس staging غائب | جزئي |
| 14 migration/release | runtime إعداد صالح وتحميل الدوال يعمل | migration/resume/grades/restore دون استكمال؛ debug signing fallback؛ platform acceptance غير متحقق | جزئي |

## العيوب الباقية ذات الأولوية

### 1. صلاحيات callables لا تزال ناقصة — P1

[recordVisit](D:/work/flutter/efteqad/functions/src/visits.js:46) و[createTask](D:/work/flutter/efteqad/functions/src/tasks.js:65) يفحصان وجود Auth فقط. الدالة الأولى تستورد authorize دون استخدامه. مستخدم pending أو من سنة أخرى يستطيع محاولة الكتابة بمعرف مورد خارج نطاقه عبر Admin SDK. المطلوب فحص role/status/grade/assignment من بيانات موثوقة داخل العملية، واختبارات callable فعلية.

[Rules](D:/work/flutter/efteqad/firestore.rules:116) ما زالت تسمح لكل خادم نشط بقراءة مخدومي سنته كاملين، وليس المسندين إليه فقط. قواعد إنشاء/تعديل الزيارة لا تفرض إسناد المخدوم أو whitelist كاملة.

### 2. إنشاء المهمة من UI ما زال مرفوضًا — P1

[AddTaskDialog](D:/work/flutter/efteqad/lib/features/tasks/presentation/widgets/add_task_dialog.dart:105) يستدعي [createTaskWithOutbox](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:650). تكتب batch في notification_outbox عند664، ولا توجد rule لهذا المسار؛ [deny-default](D:/work/flutter/efteqad/firestore.rules:240) يرفض العملية كلها. callable موجودة لكنها ليست المسار المستعمل. المطلوب توصيل UI بالـcallable بعد إصلاح صلاحياتها وidempotency، لا فتح outbox للعميل.

### 3. الإسناد لأمين السنة ما زال يصطدم بالقواعد — P1

[الحوار](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/assign_makhdomeen_modal.dart:196) يستعمل transaction مباشرة تحدّث عدادات خدام آخرين في [الخدمة](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:263). [Rules](D:/work/flutter/efteqad/firestore.rules:93) تسمح بذلك لأمين المرحلة فقط أو صاحب الملف دون تغيير العداد. تحسن حساب deltas لا يحل رفض العملية على المسار الفعلي. كذلك backend لا يتحقق من targetGrade/active رغم قراءته، ولا dedupe input IDs.

### 4. الحضور قابل للتعديل بعد الاعتماد، وtaskId غير موثوق — P1

[Rules](D:/work/flutter/efteqad/firestore.rules:155) تسمح لكل active في السنة بكتابة grade document دون مهمة مسندة أو منع تعديل finalized. فحص repository لا يحمي من عميل آخر.

[finalizeAttendance](D:/work/flutter/efteqad/functions/src/attendance.js:86) يعتمد أي taskId مرسل ويضبط completed دون قراءة المهمة أو التحقق من النوع/السنة/الإسناد/الجلسة. مقارنة grade تحسنت لكنها تستثني all. شاشة القداس ما زالت تقرأ الأطفال كاملين عند [attendance_screen.dart:75](D:/work/flutter/efteqad/lib/features/attendance/presentation/screens/attendance_screen.dart:75)، بدل minimal roster.

### 5. الاستيراد بعد فشل جزئي ما زال يكرر البيانات — P1

[Excel UI](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/excel_actions_sheet.dart:176) تنشئ importId بالوقت في كل محاولة. اختيار نفس الملف مجددًا بعد نجاح جزء يولد IDs جديدة. ولو أُعيد نفس ID فإن [batch.set مع merge](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:188) يكتب حقول الموديل كلها وقد يرجع counters/assignment/تعديلات أحدث. يلزم معرف ثابت محفوظ وسجل نجاح لكل صف وسياسة create-once/resume.

### 6. الإشعارات: تسجيل حالة retry لا يشغّل retry — P1

[notifications.js:200](D:/work/flutter/efteqad/functions/src/notifications.js:200) يسجل retryable_failure ثم ينتهي طبيعيًا. [المشغّل](D:/work/flutter/efteqad/functions/src/notifications.js:235) هو onCreate فقط؛ لا scheduler/queue للعمليات المؤجلة. وعند نجاح جهاز وفشل آخر transient، [السطر162](D:/work/flutter/efteqad/functions/src/notifications.js:162) يجعل العملية sent.

الـlistener المشترك أصلح مشكلة instances السابقة، لكن [unbind](D:/work/flutter/efteqad/lib/core/services/device_registration_service.dart:165) يبتلع فشل إزالة التوكن ويستمر logout/bind، فاحتمال ربط الجهاز القديم لم يُغلق.

### 7. مسودة الزيارة لا تعني idempotency في المسار الفعلي

[record_visit_sheet.dart:110](D:/work/flutter/efteqad/lib/features/common/widgets/record_visit_sheet.dart:110) تحفظ operationId، لكنها تستدعي recordVisit(visit) عند130 دون تمريره. [الخدمة](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:489) تنشئ visitId جديدًا في كل مرة. إصلاح marker داخل callable لا يحمي استدعاء UI الحالي. أحدث زيارة بلا notes تترك lastVisitNotes السابقة؛ tie-break للملخص لا يطابق دائمًا ترتيب القائمة.

### 8. Router ما زال غير موحد وفيه أخطاء فعلية

- [grade branches](D:/work/flutter/efteqad/lib/core/router/app_router.dart:309) تبدأ1st، و[معالج الضغط](D:/work/flutter/efteqad/lib/core/router/app_router.dart:545) يستعمل goBranch دون السنة الحالية؛ أول فتح تبويب آخر لأمين ثانية/ثالثة يتجه لسنة أولى.
- [redirect](D:/work/flutter/efteqad/lib/core/router/app_router.dart:137) لا يعالج deleting؛ قد تبقى الصفحة المحمية بدل الخروج من النطاق.
- [boot/profileLoading](D:/work/flutter/efteqad/lib/core/router/app_router.dart:60) يحول إلى bootstrap قبل حفظ intended URI.
- [login](D:/work/flutter/efteqad/lib/features/auth/presentation/screens/login_screen.dart:46)، [pending](D:/work/flutter/efteqad/lib/features/auth/presentation/screens/pending_assignment_screen.dart:82)، [settings](D:/work/flutter/efteqad/lib/features/settings/presentation/screens/settings_screen.dart:52)، [history card](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/makhdom_card.dart:91)، [tasks](D:/work/flutter/efteqad/lib/features/tasks/presentation/widgets/tasks_tab.dart:326) ما زالت تنقل الصفحات بـMaterialPageRoute.
- fetch مع initialData أُصلح جزئيًا، لكن [ProtectedResourcePage](D:/work/flutter/efteqad/lib/core/router/widgets/protected_resource_page.dart:22) تعرض الكاش أثناء الانتظار؛ [RouteAccessService](D:/work/flutter/efteqad/lib/core/router/route_access_service.dart:126) يفحص شكل ID فقط، ولا يثبت نطاق المورد الحي.

### 9. الترجمة والاختبارات الجديدة لا تغطي المطلوب

[main](D:/work/flutter/efteqad/lib/main.dart:121) ما زال يستخدم delegate اليدوية، والمولد ذو16 مفتاحًا ليس نظام الترجمة الفعلي. أمثلة باقية: [العمر](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/add_edit_makhdom_dialog.dart:432)، [خطأ المهمة والتاريخ](D:/work/flutter/efteqad/lib/features/tasks/presentation/widgets/add_task_dialog.dart:124)، [خادم بالمرحلة](D:/work/flutter/efteqad/lib/features/khadem/presentation/screens/khadem_profile_screen.dart:182).

[audit tool](D:/work/flutter/efteqad/tool/audit_localization.dart:94) يعد تسعة نصوص allowlist ثابتة دون قراءة source/AST؛ regex عند56 لا يفحص ICU المركب بالكامل. [widget matrix](D:/work/flutter/efteqad/test/features/localization_widget_matrix_test.dart:35) يبني Text/Column تجريبية، وليس شاشات المشروع الرئيسية. لذلك نجاحه لا يثبت اختفاء النصوص غير المترجمة أو سلامة كل الشاشات عند200%.

قوالب push أصبحت موصلة؛ لكن [sync من main](D:/work/flutter/efteqad/lib/main.dart:94) لا يمرر لغة Settings، وregistration يفترض ar. تفضيل الحساب وأولوية التحميل قبل أول frame لم يكتملَا.

### 10. التحليلات وفترة الاستعلام ما زالت غير صحيحة

[attendance_analytics_service.dart](D:/work/flutter/efteqad/lib/core/services/attendance_analytics_service.dart:75) استبعدت غير finalized، لكن عند106 ما زالت تخلط الخدمة والقداس؛ لا trackingStartDate؛ numerator عند174 ليس نفس population denominator عند170، وzero data يصبح0.0، وmaxWeeks عدد جلسات.

[analytics_tab.dart:180](D:/work/flutter/efteqad/lib/features/admin/presentation/screens/analytics_tab.dart:180) يقول90 يومًا بينما stream عند48 بلا حدود. [Router streams](D:/work/flutter/efteqad/lib/core/router/app_router.dart:660) ما زالت تعرض errors كقوائم فارغة، وcursor methods غير موصلة بالواجهة.

### 11. حذف الحساب والترحيل والإصدار لم تُغلق

الحذف يحفظ failedRetryable لكن لا يوجد consumer يستكمل job؛ [account_deletion.js:50](D:/work/flutter/efteqad/functions/src/account_deletion.js:50) يبتلع فشل وضع deleting. فحص بديل آخر stageAdmin منفصل عن الحذف ومعرض لسباق.

[Migration](D:/work/flutter/efteqad/functions/scripts/migrate_v2.js:22) ما زالت parse لـresume/checkpoint دون استئناف حقيقي، ولا تحول الحضور إلى grades. [Android release](D:/work/flutter/efteqad/android/app/build.gradle.kts:57) ما زال يعود لمفتاح debug عند غياب key.properties. integration_test، تقارير staging/restore واختبارات المنصات لم تظهر.

## ما يمكن اعتباره متحققًا الآن

نجاح التحليل الساكن،143 اختبار Flutter،64 اختبار backend بما فيها13 حالة Rules فعلية، وتحميل Functions. كذلك إصلاحات المصدر المذكورة في عمود «ما تحسن». لا نعيد تصنيف العيوب القديمة كفشل حالي إذا أُصلحت، ولا نعتبر نجاح هذه البوابة قبولًا لتدفق التطبيق الكامل.

الأولوية التالية: صلاحيات callables وتوصيل task/assignment/visit بالمسار الصحيح، ثم حراسة الحضور والـRouter، ثم retry/import/resume، ثم الترجمة والتحليلات والاستعلامات، وأخيرًا بوابة الإصدار المتكاملة.



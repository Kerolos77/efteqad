# مراجعة تنفيذ بلوبرينت Efteqad — 2026-10-08

المرجع: [البلو برينت الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md).
النسخة المراجعة: Git HEAD `cd3bf4b`. تمت المراجعة باستخدام مهارات Superpowers وبمراجعات مستقلة للقواعد والبيانات، الحضور والتحليلات، والـRouter والترجمة.

**الحكم: لم تُنفذ كل النقاط. توجد بنية جديدة وتنفيذ جزئي حقيقي، لكن لا توجد مهمة من المهام الـ14 يمكن اعتمادها كاملة وفق جميع شروطها الحالية.** لا يعني ذلك أن كل سطر ناقص؛ الجدول التفصيلي أدناه يفرق بين المنفذ والجزئي والفاشل وغير المتحقق. لا تُستخدم نسبة اكتمال مبنية على عدد الملفات أو أسماء commits.

هذه مراجعة للكود المحلي واختباراته، وليست تأكيدًا لما هو منشور على Firebase. لم يُعدَّل كود التطبيق ولم تُنفَّذ migration أو deploy. لم تُغيَّر checkboxes الأصلية حتى لا تتحول المراجعة إلى ادعاء قبول. خطوات FAIL ثم PASS تصف تاريخ تطوير لا يثبته نجاح الاختبارات اليوم.

## نتائج التحقق الفعلي

| الفحص | النتيجة | الحد العملي للدليل |
|---|---|---|
| `flutter analyze --no-pub` | ناجح، No issues found | لا يكشف عدم توافق Rules أو تدفق الصلاحيات |
| `flutter test --no-pub` | 105 اختبارات ناجحة | لا يوجد `integration_test/app_flows_test.dart`؛ بعض tests تحاكي منطقًا مستقلًا |
| `npm test` داخل functions | 42 ناجحة | Rules suite تُتخطى خارج المحاكي |
| `dart run tool/audit_localization.dart` | ناجح، 16 مفتاحًا لكل لغة | يقارن أسماء مفاتيح ARB فقط؛ ليس فحصًا لترجمة الشاشات |
| Firebase Emulators + npm tests | **49 اختبارًا: 48 ناجح و1 فاشل، exit 1** | اختبار تعديل الملف الشخصي يفشل عند غياب assignedCount |
| تحميل Cloud Functions في المحاكي | **فشل** | `engines.node = >=18` مرفوض؛ المحاكي المثبت يعرض 20/22/24 كقيم مقبولة |
| release / أجهزة فعلية / staging / restore | غير متحقق | لا يُستنتج نجاحها من المصدر أو checklist |

أمر المحاكي المستخدم على مشروع تجريبي فقط:

~~~powershell
$env:JAVA_HOME='C:/Program Files/Android/Android Studio/jbr'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:exec --config 'D:/work/flutter/efteqad/firebase.json' --project demo-efteqad-rules --only 'auth,firestore,functions' 'npm --prefix functions test'
~~~

استخدم Java 25 المثبت مع Android Studio داخل العملية فقط؛ المحاولة الأولى بـJava17 لم تبدأ. المحاكي شغّل Firestore Rules فعليًا، لكن فشل تحميل Functions يعني أن نجاح الاختبارات الأخرى لا يثبت استدعاءات callable متكاملة.

الفشل المثبت: [اختبار الملف الشخصي](D:/work/flutter/efteqad/functions/test/firestore.rules.test.js:130) ينشئ fixture دون assignedCount ثم يتوقع نجاح تعديل الاسم مع assignedCount=0؛ [القاعدة](D:/work/flutter/efteqad/firestore.rules:71) تقارن بحقل غير موجود فتُرفض العملية. يجب حسم عقد الحقول القديمة والجديدة وإصلاح القاعدة/الfixture وفقه، لا حذف assertion لإخفاء الفشل.

## أهم الموانع ومكان التعديل المطلوب

| الأولوية | النتيجة المثبتة في المصدر | المكان | المطلوب لإغلاقها |
|---|---|---|---|
| P1 | callable الزيارات والمهام يفحص Auth فقط، دون دور/سنة/إسناد | [visits.js](D:/work/flutter/efteqad/functions/src/visits.js:9)، [tasks.js](D:/work/flutter/efteqad/functions/src/tasks.js:65) | استدعاء authorize على actor الموثوق والمورد قبل كل كتابة؛ اختبارات pending/cross-grade/unassigned |
| P1 | القواعد تسمح للخادم بكل مخدومي السنة وبإنشاء notifications؛ roster متاح لكل active | [Rules](D:/work/flutter/efteqad/firestore.rules:80) | تطبيق مصفوفة الإسناد ومهمة الحضور وfield allowlists؛ backend-only للعمليات المميزة |
| P1 | إنشاء المهمة من UI يكتب outbox غير مسموحة؛ تسجيل الأجهزة محجوب؛ اسم حقل المهمة غير متطابق | [createTaskWithOutbox](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:596)، [Rules](D:/work/flutter/efteqad/firestore.rules:156)، [devices](D:/work/flutter/efteqad/lib/core/services/device_registration_service.dart:39) | توحيد عقد schema، ربط UI بالـcallable المصرح، Rules للأجهزة مقيّدة بالمالك؛ إبقاء outbox backend-only |
| P1 | UI تكتب khademId بينما Rules/backend يستخدمان servantId | [VisitModel](D:/work/flutter/efteqad/lib/core/models/visit_model.dart:30)، [Rules](D:/work/flutter/efteqad/firestore.rules:143) | اسم موحد مع قراءة legacy ومهاجرة واختبار query/create للسجل |
| P1 | حفظ الحضور للخادم يكتب root المحظور؛ finalize callable يقبل grade من المستخدم دون مقارنتها بالمورد | [AttendanceRepository](D:/work/flutter/efteqad/lib/core/repositories/attendance_repository.dart:96)، [attendance.js](D:/work/flutter/efteqad/functions/src/attendance.js:25) | schema السنة وroster؛ تحقق سنة الجلسة والمهمة الفعلية؛ finalize خادمي وتجميد finalized |
| P1 | counters الإسناد ومسار الحذف لا يضمنان الاتساق | [assign](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:183)، [deletion](D:/work/flutter/efteqad/functions/src/account_deletion.js:42) | توحيد مسار backend، تحقق assignment الحالي داخل transaction، operationId ذري وdeleting/retry job |
| P1 | استيراد ملف بعد فشل جزء يكرر الصفوف؛ callable retry قد يستبدل تعديلات لاحقة | [bulk import](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:167)، [imports](D:/work/flutter/efteqad/functions/src/imports.js:145) | ربط importId/rowId ثابت، سجل لكل صف ومعالجة create-once دون overwrite |
| P1 | role/grade/resource guards غير مكتملة، وtab ثانية/ثالثة يبدأ من1st | [route access](D:/work/flutter/efteqad/lib/core/router/route_access_service.dart:126)، [shell defaults](D:/work/flutter/efteqad/lib/core/router/app_router.dart:282) | تحقق المورد الحي والإسناد، tab routes بالسنة الحالية، reset عند تغير scope، إزالة page Navigator القديمة |
| P1 | listener جهاز مختلف في sync وlogout؛ transient push يصبح sent | [sync](D:/work/flutter/efteqad/lib/core/services/notification_service.dart:170)، [logout](D:/work/flutter/efteqad/lib/core/services/auth_service.dart:87)، [worker](D:/work/flutter/efteqad/functions/src/notifications.js:97) | instance واحدة محقونة، cleanup gate، retries/lease/idempotency وحالات تسليم دقيقة |
| P1 | بوابة emulator فاشلة وFunctions غير قابلة للتحميل بالإعداد الحالي | [package.json](D:/work/flutter/efteqad/functions/package.json:16) | runtime محدد متوافق ثم إعادة اختبارات Rules/callables على المحاكي |
| P2 | ARB غير موصلة؛ معظم الترجمة القديمة والنصوص المضمنة باقية | [main](D:/work/flutter/efteqad/lib/main.dart:115)، [الترجمة اليدوية](D:/work/flutter/efteqad/lib/core/localization/app_localizations.dart:1) | نقل الموارد الفعلية وربط generated delegate/context.tr ثم فحص الشاشات والأخطاء |
| P2 | خدمة/قداس مختلطان، لا trackingStartDate، نسب قد تتجاوز100%، label90 يومًا بلا فلتر | [analytics](D:/work/flutter/efteqad/lib/core/services/attendance_analytics_service.dart:106)، [analytics UI](D:/work/flutter/efteqad/lib/features/admin/presentation/screens/analytics_tab.dart:47) | finalized service-only وeligible IDs موحدة وinsufficient وفترة queries مشتركة |
| P2 | الأرشفة لا تستبعد المخدوم؛ الأخطاء تتحول إلى empty؛ pagination معزولة | [archive filter](D:/work/flutter/efteqad/lib/core/repositories/makhdom_repository.dart:177)، [route streams](D:/work/flutter/efteqad/lib/core/router/app_router.dart:635) | active query فعلي، AsyncContent موصل، cursor/date bounds في UI |
| P1 قبل الإصدار | migration لا تنشئ grades وresume غير مطبق؛ release قد يوقَّع بمفتاح debug | [migration](D:/work/flutter/efteqad/functions/scripts/migrate_v2.js:98)، [signing](D:/work/flutter/efteqad/android/app/build.gradle.kts:57) | checkpoint/recovery ومهاجرة schema كاملة على staging، وفشل build release عند غياب مفتاحه |

## سجل القبول: البنود الـ65

كل رقم أدناه هو Task.step بترتيب checkboxes في البلوبرينت. نص المطلوب يُنقل من الأصل، ثم نتيجة المراجعة وما بقي.


### Task 1 — الجلسة وحقن البيانات

**1.1 — جزئي**

> المطلوب: اكتب test/core/session/session_cubit_test.dart: stageAdmin بلا grade يصبح active؛ servant بلا grade يصبح pending؛ profile failure يبقى failure؛ تغيير UID يلغي listener القديم.

اختبارات Session موجودة وناجحة؛ لكن حالة stageAdmin لا تفحص profile.status ولا تُنتج deleting. [lib/core/session/session_cubit.dart:82](D:/work/flutter/efteqad/lib/core/session/session_cubit.dart:82).

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:232)

**1.2 — غير متحقق تاريخيًا**

> المطلوب: شغّل flutter test test/core/session/session_cubit_test.dart وتأكد أنه يفشل للسبب المقصود.

الاختبارات الحالية ناجحة؛ لا تكفي شجرة المصدر لإثبات أنها فشلت أولًا للسبب المطلوب.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:233)

**1.3 — جزئي**

> المطلوب: حقن Firebase implementations؛ مراقبة Auth/profile مرة واحدة؛ إزالة side effects من build.

Auth/Profile محقونان وRouter واحد؛ ما زال [main.dart:101](D:/work/flutter/efteqad/lib/main.dart:101) يحدّث ValueNotifiers داخل build، ومسارات قديمة تعتمد AuthService.isStageAdmin المبني على البريد.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:234)

**1.4 — جزئي**

> المطلوب: أعد الأمر؛ كل الحالات PASS؛ راجع وتوثق نقطة رجوع.

اختبارات Flutter الحالية ناجحة وتوجد commits لكل مهمة؛ قبول Session كاملًا يحتاج اختبار deleting وتبديل الحساب على التطبيق الفعلي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:235)


### Task 2 — القواعد والعمليات الإدارية

**2.1 — جزئي**

> المطلوب: اختبارات allow/deny لمصفوفة الأدوار، self-promotion، انتحال creatorId، cross-grade، roster، stageAdmin.

سبع حالات Rules فقط؛ لا اختبارات creator spoofing أو roster أو devices أو صلاحيات مهمة حضور أو finalized. [functions/test/firestore.rules.test.js:79](D:/work/flutter/efteqad/functions/test/firestore.rules.test.js:79).

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:242)

**2.2 — فشل التحقق الحالي**

> المطلوب: جهز npm test في functions؛ شغّل firebase emulators:exec --only auth,firestore,functions "npm --prefix functions test"؛ أثبت الفشل ثم طبّق القواعد/العمليات وأعده PASS.

شُغّل المحاكي: 48/49 نجحت وواحد فشل. تحديث الاسم لملف دون assignedCount يرفض بسبب [firestore.rules:71](D:/work/flutter/efteqad/firestore.rules:71). Functions لم تُحمّل بسبب engines >=18.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:243)

**2.3 — جزئي**

> المطلوب: المستخدم ينشئ ملف pending بUID نفسه وحقول محددة فقط؛ الأدوار والترقيات حصريًا backend؛ deny-default لباقي البيانات.

منع self-promotion موجود، لكن لا whitelist لإنشاء pending؛ stageAdmin يكتب الأدوار مباشرة، وstage_people_tab.dart يستخدم الكتابة المباشرة بدل callable.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:244)

**2.4 — غير منفذ بصورة صحيحة**

> المطلوب: طابق queries مع Rules؛ القواعد لا تعمل filter لنتائج استعلام واسع.

visits تستخدم khademId والقواعد servantId؛ tasks تستخدم assignedKhademId والقواعد assignedToId؛ devices/outbox بلا matches. [firestore.rules:145](D:/work/flutter/efteqad/firestore.rules:145)،159،197.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:245)

**2.5 — جزئي**

> المطلوب: اربط config وindexes وEmulators؛ الإنتاج ينتظر خطة الانتقال في Task 14.

firebase.json وindexes وemulators موجودة؛ index المهام يستخدم assignedToId الخاطئ. Functions runtime غير مقبول بالمحاكي. النشر غير متحقق.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:246)


### Task 3 — Patch المخدوم والإسناد

**3.1 — جزئي**

> المطلوب: اختبار عداد 3→4 أثناء فتح تعديل هاتف؛ إسناد تغير أثناء الحوار ينتج conflict؛ مسح حقل اختياري يعمل.

MakhdomProfilePatch يحمي counters عند تعديل الملف، لكن اختبار conflict لا يغطي UI؛ photoUrl:null يُهمَل بدل المسح. [lib/core/models/makhdom_profile_patch.dart:57](D:/work/flutter/efteqad/lib/core/models/makhdom_profile_patch.dart:57).

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:253)

**3.2 — جزئي**

> المطلوب: flutter test test/core/repositories/makhdom_repository_test.dart واختبارات assignments بالمحاكي: FAIL ثم PASS.

اختبارات ناجحة، لكنها تحاكي merge والحسابات؛ [functions/test/assignments.test.js](D:/work/flutter/efteqad/functions/test/assignments.test.js) لا يستدعي implementation الإنتاجي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:254)

**3.3 — جزئي مع عطل**

> المطلوب: transaction لكل انتقال مع عدادي المصدر والمستلم، نتائج لكل عنصر bulk؛ operationId يمنع الزيادة المكررة. لا overwrite لإسناد غير متوقع.

UI ما زالت تستخدم [firestore_service.dart:183](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:183)؛ قراءة بعد كتابة داخل loop، زيادة target بعدد القائمة كله عند219، دون expectedAssignments/operationId أو نتائج لكل عنصر. callable marker خارج transaction.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:255)

**3.4 — جزئي**

> المطلوب: الحذف الحالي يتحول archive منطقي؛ active=false يخرج من القوائم الجديدة ويحفظ التاريخ. منع cascade غير موثق.

archive يكتب active=false عند [firestore_service.dart:144](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:144) ويحفظ التاريخ؛ streams لا تستبعده، وmakhdom_repository.dart:177 يعيد true دائمًا.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:256)


### Task 4 — الزيارات والملخصات

**4.1 — جزئي مع عطل**

> المطلوب: زيارة حديثة ثم قديمة: count=2 وlastVisitId للحديثة؛ retry لنفس operationId لا يزيد؛ تعديل القديمة لا يغير الملخص؛ تفريغ الأخيرة يمسحه.

المقارنة الزمنية وlastVisitId موجودان؛ client لا يملك operationId والقواعد ترفض khademId. retry في callable غير ذري لأن marker خارج transaction.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:263)

**4.2 — جزئي**

> المطلوب: اختبارات visits عبر أمر المحاكي: FAIL ثم PASS بعد transaction للسجل والعداد وآخر زيارة.

[functions/test/visits.test.js](D:/work/flutter/efteqad/functions/test/visits.test.js) يقارن قيمًا مستقلة ولا يستدعي الوظيفة/Firestore؛ لا اختبار transaction حقيقي للسيناريو المطلوب.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:264)

**4.3 — غير مكتمل**

> المطلوب: عند تساوي visitDate استخدم createdAt ثم id لترتيب ثابت؛ general notes لا تتبدل بتقرير زيارة.

المسار المستخدم يفرز date فقط، ويكتب تقرير الزيارة في notes العامة. [firestore_service.dart:465](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:465)،508،527.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:265)

**4.4 — غير موصل**

> المطلوب: callable يحتاج اتصالًا؛ offline يحتفظ بمسودة محلية عبر SharedPreferences ورسالة «لم تُرسل بعد»؛ إعادة إرسال صريحة بنفس operationId؛ مسحها بعد النجاح، لا ادعاء حفظ خادمي.

VisitDraftStore موجود، لكن [record_visit_sheet.dart:86](D:/work/flutter/efteqad/lib/features/common/widgets/record_visit_sheet.dart:86) يستخدم direct transaction بلا draft أو callable أو retry ثابت.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:266)


### Task 5 — الحضور والتزامن

**5.1 — جزئي**

> المطلوب: test/features/attendance/attendance_cubit_test.dart: أول كتابتين، remote remove، true→false سريع، failure قديم، تعديل finalized ممنوع، retry دون تكرار.

[attendance_cubit_test.dart:118](D:/work/flutter/efteqad/test/features/attendance/attendance_cubit_test.dart:118) يختبر أول كتابتين بالتتابع؛ fake فوري لا يحاكي ترتيب acknowledgments، ولا retry واقعي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:273)

**5.2 — جزئي**

> المطلوب: flutter test test/features/attendance/attendance_cubit_test.dart ومحاكي Firestore: FAIL ثم PASS.

اختبارات Flutter ناجحة، لكن Rules suite لا تختبر حضورًا؛ لا دليل red→green تاريخي أو concurrency بالمحاكي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:274)

**5.3 — جزئي مع عطل**

> المطلوب: تطبيق schema السنة والكتابة الذرية؛ request sequence لكل ID؛ القائمة المعروضة آخر remote snapshot مع pending overrides.

transactions وpending overlay وsequence موجودة؛ [attendance_repository.dart:47](D:/work/flutter/efteqad/lib/core/repositories/attendance_repository.dart:47)،96 يقرأ/يكتب root flat، لا grades؛ Rules:110 تمنع servant. sequence يحمي UI فقط؛ snapshot null يبقي state قديمًا.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:275)

**5.4 — جزئي**

> المطلوب: منع finalize مع طلبات معلقة؛ finalize يثبت completed على الخادم؛ offline لا يزعم إنهاء الرصد.

منع finalize أثناء pending موجود؛ finalize كتابة client مباشرة عند [attendance_repository.dart:134](D:/work/flutter/efteqad/lib/core/repositories/attendance_repository.dart:134)؛ callable لا يقارن سنة الوثيقة بسنة payload ولا يربط completed task.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:276)

**5.5 — جزئي**

> المطلوب: إظهار saved/pending/failed بدقة؛ عدم استخدام جلسة draft في الغياب النهائي؛ تاريخ المهمة وليس نص «الجمعة» الثابت.

badges وتاريخ المهمة موجودان؛ idle يعرض saved قبل تأكيد القراءة، stream بلا onError، وlegacyUnknown يدخل التحليلات رغم استبعاد draft.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:277)


### Task 6 — Excel

**6.1 — جزئي**

> المطلوب: fixtures عربي/إنجليزي، ثانية/ثالثة، عمود ناقص، هاتف صفره الأول، تاريخ غير صالح، صف عينة، نفس الملف مرتين، ملف متعدد الأجزاء.

توجد tests داخل الذاكرة عربي/إنجليزي/سنة/هاتف/عينة؛ لا fixtures فعلية أو invalid-date أو repeated-file أو multipart. [excel_service.dart:120](D:/work/flutter/efteqad/lib/core/services/excel_service.dart:120) يقرأ أول sheet، تواريخ غير صحيحة قد تصبح null.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:284)

**6.2 — منفذ وظيفيًا؛ التسلسل التاريخي غير متحقق**

> المطلوب: flutter test test/core/services/excel_service_test.dart: FAIL ثم PASS بعد فصل picker/parser وتمرير grade.

parser مفصول وgrade إلزامي ويُمرر من شاشة السنة والRouter. الاختبارات الحالية ناجحة؛ لا دليل FAIL ثم PASS.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:285)

**6.3 — منفذ مع قيد**

> المطلوب: المعاينة تعرض السنة والمقبول/المرفوض والتكرارات المحتملة؛ لا dedupe آلي بالهاتف لأن الإخوة قد يشتركون فيه.

المعاينة تعرض السنة والمقبول/المرفوض وتحذير، ولا تحذف الأخوة ذوي نفس الهاتف. [excel_actions_sheet.dart:112](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/excel_actions_sheet.dart:112)–143 يعرض أول warning فقط، وقد يخفي تحذير التكرار.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:286)

**6.4 — جزئي مع خطر تكرار**

> المطلوب: أجزاء بحد تطبيقي أولي 200 صف، لا ادعاء أنه حد Firebase؛ importId+rowId ثابت للretry؛ عرض تقدم ونتيجة جزئية قابلة للاستكمال.

200 صف والتقدم موصلان، لكن UI تستخدم addBulkMakhdomeen؛ [firestore_service.dart:167](D:/work/flutter/efteqad/lib/core/services/firestore_service.dart:167) يولد IDs عشوائية. لا importId/rowId أو resume؛ إعادة الملف بعد نجاح جزء تكرر سجلاته.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:287)

**6.5 — جزئي**

> المطلوب: اختبر round-trip export→import باللغتين دون فقد أعمدة أو تحويل الهاتف لعدد.

التصدير نصي ورؤوسه مترجمة؛ اختبار round-trip عربي فقط ولحقول مختارة؛ assignment/counters/date المُصدّرة لا تُستعاد كلها.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:288)


### Task 7 — حذف الحساب

**7.1 — جزئي**

> المطلوب: reauth ملغى/مرفوض لا يغير الإسنادات؛ فشل التنظيف يستكمل؛ retry لا يمس إسنادًا جديدًا؛ token listener لا يعيد إنشاء المستخدم المحذوف.

reauth قبل طلب الحذف، لكن cleanup query ثم batch قد يمحو إسنادًا جديدًا، وtoken listener لا يُلغى بسبب اختلاف instances.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:295)

**7.2 — جزئي**

> المطلوب: اختبارات account deletion بالمحاكي وUI: FAIL ثم PASS.

Dart يختبر MockAccountRepository نفسه؛ backend happy path mocked؛ لا UI/emulator failure/resume/reassignment.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:296)

**7.3 — غير مكتمل**

> المطلوب: بعد reauth الخادم يثبت deleting ويمنع الوصول، ثم ينظف الأجهزة والإسنادات والملف ويحذف Auth مع retries؛ لا وعد بـtransaction واحدة عبر Auth وFirestore.

[account_deletion.js:36](D:/work/flutter/efteqad/functions/src/account_deletion.js:36) يحدّث job فقط لا profile.status=deleting؛ تنفيذ متزامن بلا worker/retries، authDeleted قبل حذف Auth، ولا تحقق auth_time خادمي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:297)

**7.4 — جزئي**

> المطلوب: أمين المرحلة لا يحذف نفسه قبل بديل إداري مثبت؛ قيد واضح مترجم.

قيد بديل إداري موجود، لكنه لا يشترط active؛ AuthService.reauthenticate Google فقط رغم دخول الإدارة email/password.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:298)


### Task 8 — الأجهزة والإشعارات والمهام

**8.1 — جزئي**

> المطلوب: اختبارات A→B، refresh بعد logout، أول login، جهازين، transient error، invalid token، repeated event.

اختبارات fake-store موجودة؛ لا integration للأول login/جهازين أو transient/repeated-event الحقيقي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:305)

**8.2 — جزئي**

> المطلوب: flutter test test/core/services/device_registration_service_test.dart واختبارات المحاكي: FAIL ثم PASS.

Flutter ناجح؛ لا اختبار registration مع Rules؛ subcollection devices محجوبة فعليًا بالقواعد المحلية.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:306)

**8.3 — غير مكتمل**

> المطلوب: listener واحد؛ تنظيف الربط القديم وتدوير/حذف التوكن عند الحاجة؛ عند offline يؤجل تفعيل push للحساب الجديد حتى cleanup؛ payload على lock screen بلا تفاصيل حساسة.

[notification_service.dart:170](D:/work/flutter/efteqad/lib/core/services/notification_service.dart:170) وauth_service.dart:87 ينشئان instance مختلفتين؛ logout لا يلغي listener الأصلي. فشل cleanup يُبتلع، وpayload يحمل تفاصيل المهمة بدل صياغة عامة.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:307)

**8.4 — جزئي مع أخطاء**

> المطلوب: retries محدودة ومؤجلة مع حذف invalid tokens؛ dedupe لا يدعي exactly-once لـFCM. sent تعني قبول FCM وليس قراءة المستخدم.

invalid token cleanup موجود؛ [notifications.js:97](D:/work/flutter/efteqad/functions/src/notifications.js:97)–113 يبتلع transient ثم يسجل sent، لا backoff/attempts، snapshot حدث مكرر لا يعاد التحقق منه، no-devices تصبح sent.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:308)


### Task 9 — ARB والتفضيلات

**9.1 — جزئي**

> المطلوب: tests في test/core/localization/ وtest/core/settings/: استمرار locale/theme؛ plurals 0/1/2/3/11/100؛ codes لا تتغير؛ تبديل اللغة يحفظ route.

Settings/formatters/domain tests موجودة وناجحة؛ لا إثبات route preservation على app widget، أو اختبار الشاشة لكل plurals 0/1/2/3/11/100.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:314)

**9.2 — غير مكتمل**

> المطلوب: نقل الموارد الموجودة أولًا ثم استكمال جدول النصوص؛ إصلاح كل توقيع getter؛ منع raw exception messages في UI.

[main.dart:115](D:/work/flutter/efteqad/lib/main.dart:115) ما زال يستخدم AppLocalizations اليدوية، ARB16 مفاتيح فقط؛ معظم الموارد لم تُنقل ونصوص عربية/raw exceptions باقية.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:315)

**9.3 — جزئي**

> المطلوب: flutter gen-l10n ثم flutter test test/core/localization/ test/core/settings/: PASS بعد إثبات فشل الحالات الناقصة.

ملفات generated موجودة واختبارات Flutter ناجحة؛ لم يُعد gen-l10n في مراجعة read-only، والمولد غير موصول بالواجهة.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:316)

**9.4 — غير مطابق**

> المطلوب: إنشاء tool/audit_localization.dart لفحص AST للنصوص المعروضة والمفاتيح/placeholders مع allowlist موثق؛ لا اعتبار كل حرف عربي خطأ.

[tool/audit_localization.dart](D:/work/flutter/efteqad/tool/audit_localization.dart) يقارن key sets بـRegExp فقط؛ لا AST للنصوص، ولا تحقق placeholders/ICU، ولا allowlist موثق.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:317)

**9.5 — غير منفذ كقبول شامل**

> المطلوب: widget tests للشاشات الأساسية ar/en واتجاه RTL/LTR وتكبير 200%؛ بيانات المستخدم العربية مسموحة في EN.

لا widget matrix للشاشات الأساسية ar/en وRTL/LTR وtext scale200%؛ tests helper ليست بديلًا.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:318)

**9.6 — جزئي وغير موصل**

> المطلوب: قوالب backend: functions/src/notification_templates.js مع ar/en وrecipient locale؛ اختبارات مستقلة للمحتوى والمتغيرات.

[notification_templates.js](D:/work/flutter/efteqad/functions/src/notification_templates.js) واختباراته موجودة، لكن sender لا يستدعي module؛ locale لا ينتقل من Settings للجهاز ولا templateKey+args للنظام كله.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:319)


### Task 10 — Router والـShells

**10.1 — جزئي**

> المطلوب: test/core/router/app_router_test.dart: landing لكل دور؛ pending/error؛ forbidden grade؛ bad/deleted ID؛ intended route؛ redirect loop؛ logout ثم Back.

[app_router_test.dart](D:/work/flutter/efteqad/test/core/router/app_router_test.dart) يختبر redirect/access helpers؛ لا تحميل مورد محذوف/خارج النطاق أو widget stack بعد logout، ولا intended URI محفوظ.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:325)

**10.2 — جزئي**

> المطلوب: flutter test test/core/router/app_router_test.dart: FAIL ثم PASS بعد MaterialApp.router والـguards والـshells.

MaterialApp.router وStatefulShellRoute موجودان والاختبارات ناجحة؛ guards للموارد تتحقق من ID syntax فقط، وgrade initialLocation مثبتة على1st.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:326)

**10.3 — غير مكتمل**

> المطلوب: انقل كل page navigation بالقسم 4، واحتفظ بإغلاق modals؛ Drawer home يفتح وجهة فعلية.

login/pending/drawer/settings/makhdom_card/tasks_tab ما زالت تستخدم page Navigator؛ Drawer home يغلق فقط. ليست كل الصفحات عبر Router.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:327)

**10.4 — غير متحقق وغير مكتمل**

> المطلوب: widget tests تحفظ tab scroll/filter؛ تغيير role/grade/user يمسح القديم؛ downgrade أثناء التفاصيل يغلقها.

لا widget tests للscroll/filter/downgrade؛ shells ليست keyed بالـuser/role/grade؛ ProtectedResourcePage يقبل initialData دون إعادة فحص المورد.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:328)

**10.5 — جزئي**

> المطلوب: URI refresh/deep link بالـID دون extra؛ Android/iOS app links تحتاج domain وإعدادات حقيقية قبل تفعيلها، لا اختراع نطاق. الـRouter الداخلي قابل للاختبار دون domain.

صفحات history/task/attendance تملك loader بالـID دون extra؛ intended link يُفقد في bootstrap/login، ولا حراسة resource scope حية؛ app links الفعلية غير متحققة ولا يلزم اختراع domain.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:329)


### Task 11 — نقر الإشعارات

**11.1 — جزئي**

> المطلوب: test/core/router/notification_intent_test.dart: foreground/local/background/terminated لنفس الوجهة؛ deleted→notFound؛ cross-scope→forbidden؛ login ثم consume مرة واحدة.

اختبارات payload/coordinator موجودة؛ لا اختبارات event hooks الحقيقية/Router ولا deleted/cross-scope resource lookup.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:336)

**11.2 — جزئي**

> المطلوب: flutter test test/core/router/notification_intent_test.dart: FAIL ثم PASS.

اختبارات Flutter ناجحة للحالات المكتوبة؛ لا تثبت التسليم والنقر end-to-end.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:337)

**11.3 — جزئي مع عطل**

> المطلوب: ربط getInitialMessage/onMessageOpenedApp/local launch response؛ انتظار session؛ markAsRead ليس دليل تصريح بفتح المورد.

getInitialMessage/onMessageOpenedApp/local launch موصلة إلى enqueue؛ enqueue لا ينعش Router، وtypes task من backend غير مدعومة بالallowlist؛ clear غير مستدعاة عند logout، وsheet القديم لا يوحد المسار.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:338)


### Task 12 — التحليلات وفصل السجل

**12.1 — جزئي**

> المطلوب: اختبارات جمعتي غياب خدمة، قداس وخدمة نفس اليوم، جديد، draft/future، صفر جلسات، درجات مختلفة، تعديل grade حي، weeks تواريخ مميزة.

اختبارات draft/future وبعض grades والتواريخ موجودة؛ لا trackingStartDate أو live-grade/widget أو distinct dates maxWeeks.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:345)

**12.2 — جزئي**

> المطلوب: flutter test test/attendance_analytics_service_test.dart test/features/admin/makhdom_history_service_test.dart: FAIL ثم PASS.

اختبارات ناجحة حاليًا؛ بعضها يثبت سياسة خاطئة مثل zero=0.0 بدل insufficient؛ النجاح لا يثبت المواصفات.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:346)

**12.3 — جزئي**

> المطلوب: تطبيق سياسة القسم 2؛ إخراج الحسابات من build؛ استخدام الموديل الحي؛ الفصل بين general notes وvisit report؛ ترجمة فرق النسبة دون سببية.

HistoryService وwidgets موصلة؛ لكن التحليل يخلط mass/service، لا trackingStartDate، legacyUnknown مسموح، numerator مختلف عن denominator، zero/no-data atRisk، maxWeeks عدد sessions؛ notes العامة ما زالت تتغير.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:347)


### Task 13 — الاستعلامات والأخطاء والأداء

**13.1 — جزئي**

> المطلوب: tests: permission/network/decode ليست empty؛ pagination بتاريخ متساوٍ بلا فقد/تكرار؛ تغيير سنة يلغي query؛ offline cache موصوف.

AppFailure/AsyncContent tests موجودة؛ pagination_test يفرز list محليًا وليس query؛ لا query cancellation/cache metadata أو failures متكاملة.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:354)

**13.2 — جزئي**

> المطلوب: flutter test test/core/repositories/ test/core/widgets/ مع queries في emulator: FAIL ثم PASS.

اختبارات Flutter ناجحة؛ لا emulator queries للحضور/pagination؛ بعض الاختبارات مستقلة عن repository الحقيقي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:355)

**13.3 — جزئي**

> المطلوب: استعلام server-side للفترة والسنة، tie-break document ID وcursor؛ unread count منفصل عن كل الإشعارات؛ markAllRead على أجزاء قابلة للاستكمال.

فلترة grade على الخادم موجودة، لكن from/to غير موصلة، cursor methods بلا UI callers، unread من full list. markAllRead أجزاء200 فعليًا لكن UI لا تنتظر/تلتقط الفشل ولا resume موثق.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:356)

**13.4 — غير منفذ في تدفق البيانات**

> المطلوب: فترة التحليلات الافتراضية المقترحة 90 يومًا ظاهرة في العنوان؛ all-time بتجميع/استعلام صريح، لا حساب من أول صفحة فقط. كل المقارنات لنفس الفترة.

[analytics_tab.dart:179](D:/work/flutter/efteqad/lib/features/admin/presentation/screens/analytics_tab.dart:179) يقول آخر90 يومًا لكن :47،49 لا يمرر فترة؛ زيارات lifetime عند312. فلاتر history تُطبّق بعد حساب KPIs.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:357)

**13.5 — جزئي؛ القياس غير متحقق**

> المطلوب: قياس reads ووقت أول تحميل على staging؛ cache محدود بعد القياس، دون افتراض أن cache يحل خصوصية الهاتف المشترك.

cache محدود100MB؛ لا تقرير staging reads/load. README يربطه بخصوصية الهاتف المشترك بلا أساس؛ cache ليس عزلًا بين الحسابات.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:358)


### Task 14 — الترحيل والتوثيق والإصدار

**14.1 — جزئي**

> المطلوب: tests dry-run بلا كتابة، retry idempotent، legacy visitType وتوكن مفرد وعدادات خاطئة وحقول ناقصة؛ FAIL ثم PASS بالمحاكي.

اختبارات helper/dry-run mocked؛ لا apply retry/resume أو legacy visitType/assignedCount repair؛ لا migration emulator integration.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:365)

**14.2 — غير منفذ**

> المطلوب: attendance القديم يتحول لأجزاء سنة من مصدر موثوق؛ لا استنتاج سنة تاريخية من السنة الحالية عند اختلافهما. الغامض يظهر في تقرير ولا يصحح صامتًا.

[migrate_v2.js:98](D:/work/flutter/efteqad/functions/scripts/migrate_v2.js:98)–114 يضيف flags للوثيقة القديمة دون إنشاء grades أو roster أو تحليل مصدر السنة التاريخي.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:366)

**14.3 — جزئي**

> المطلوب: حالة الجلسة القديمة legacyUnknown حتى اعتمادها، قبل دخولها في إنذارات finalized؛ trackingStartDate القديم تقديري؛ الاحتفاظ بـlegacyNotes عند اختلاط الملاحظة العامة بالتقرير.

legacyUnknown وtracking fallback موجودان بالسكريبت؛ التحليل لا يستبعد unknown، الموديل بلا tracking/legacyNotes، ولا علامة estimated؛ حفظ legacyNotes مشروط لا شامل.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:367)

**14.4 — غير متحقق؛ خطة الانتقال ناقصة**

> المطلوب: backup واستعادة تجريبية؛ readers متوافقة أولًا؛ backend/schema في staging؛ migration؛ client؛ تنسيق تشديد Rules وإيقاف العميل القديم دون فترة allow-all جديدة.

لا نتائج backup/restore/staging؛ checklist لا يثبت readers-compatible rollout أو إيقاف القديم، ويضع Rules قبل توافق backend/client.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:368)

**14.5 — جزئي**

> المطلوب: README للتشغيل والأدوار والـRouter والترجمة والمحاكيات والتوقيع والاستعادة. الأسرار خارج الملفات المتتبعة.

README/checklist موجودان، لكن ادعاءات حماية/offline أوسع من الكود وتوثيق Router/resume ناقص. لم تظهر keystore/service-account متتبعة بالفحص الاسمي؛ ليس تدقيق أسرار شاملًا.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:369)

**14.6 — جزئي**

> المطلوب: release signing مستقل؛ لا تغيير applicationId قبل مراجعة Firebase registration. config وحده لا يكفي لاختبار Google Sign-In.

applicationId ثابت؛ [android/app/build.gradle.kts:57](D:/work/flutter/efteqad/android/app/build.gradle.kts:57)–61 يعود لمفتاح debug عند غياب key.properties؛ توقيع release وGoogle Sign-In الفعلي غير متحققين.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:370)

**14.7 — جزئي؛ اختبار المنصات غير متحقق**

> المطلوب: iOS: URL schemes ووصف استخدام الموقع وAPNs/capabilities في بيئة Apple؛ Web/desktop: اختبار plugins/exports/notifications قبل إعلان الدعم.

iOS location description موجود، URL schemes مفقودة؛ APNs/capabilities وWeb/Desktop لم تُختبر في هذه المراجعة.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:371)

**14.8 — فشل التحقق الحالي**

> المطلوب: تدقيق Runtime Functions المدعوم وقت التنفيذ بالوثائق الرسمية؛ lockfile؛ CI أو نفس الأوامر محليًا إذا لم يتوفر GitHub.

lockfile موجود؛ engines >=18 يرفضه محاكي Functions المثبت، ويذكر20/22/24. لا تحقق runtime منشور؛ quality محلي جزئي وفحص emulator فاشل.

[البند الأصلي](D:/work/flutter/efteqad/docs/superpowers/plans/2026-10-07-efteqad-blueprint.md:372)


## سجل الإصلاحات الأصلي: جميع الـ20 ID

| ID | الحالة | الربط بالتفاصيل |
|---|---|---|
| SEC-01 | غير مغلق | Tasks1/2/5/8؛ صلاحيات backend ناقصة وRules غير متوافقة |
| DATA-01 | تحقق الإصلاح الأساسي؛ task جزئية | patch يحمي visitCount/date/createdAt؛ مسح optional/conflict غير كامل — Task3 |
| ATT-01 | جزئي | transaction موجود بالمسار الجديد لكن schema/Rules خاطئة؛ المسار القديم get ثم set باقٍ — Task5 |
| ATT-02 | جزئي | remote/pending/sequence موجودة؛ server ordering/read failures لا تغطيها tests — Task5 |
| EXCEL-01 | تحقق الإصلاح الأساسي | grade إلزامي من شاشة الثانية/الثالثة للparser؛ retry/import الأوسع ناقص — Task6 |
| PUSH-01 | غير مغلق | bind/unbind على instances مختلفة وcleanup failure مستتر — Task8 |
| AUTH-01 | جزئي | reauth أولًا موجود؛ deleting/resumable job/recency ناقصة — Task7 |
| VISIT-01 | جزئي | chronology تحسنت؛ notes العامة ما زالت تختلط وكتابة UI مرفوضة — Task4 |
| VISIT-02 | جزئي | lastVisitId/clear موجودان؛ notes العامة تحذف وschema mismatch — Task4 |
| ASSIGN-01 | غير مغلق | UI لا تستخدم callable؛ عدادات/retries/archive filter — Task3 |
| ANALYTICS-01 | جزئي | لا service-only/tracking/finalized-only/distinct maxWeeks — Task12 |
| ANALYTICS-02 | جزئي | الصياغة أقل سببية؛ numerator/zero/negative UI غير صحيحة — Task12 |
| PERF-01 | جزئي | grade query موجود؛ فترة/pagination غير موصلتين — Task13 |
| ERROR-01 | جزئي | Helpers موجودة؛ معظم live streams لا تزال تخفي الخطأ — Task13 |
| PUSH-02 | جزئي | Session sync/event hooks موجودة؛ التسجيل محجوب والنقر لا ينعش Router — Tasks8/11 |
| PUSH-03 | غير مغلق | outbox غير موصلة بصورة صحيحة، state/status وretries — Task8 |
| DEPLOY-01 | غير مغلق | runtime emulator failure وdebug signing fallback — Task14 |
| TEST-01 | جزئي | 105 Flutter tests، لكن placeholder باقٍ وintegration غائبة وقواعد فاشلة |
| ARCH-01 | جزئي | HistoryService/widgets ومستودعات أضيفت؛ خدمات مباشرة ومسارات قديمة ما زالت حية |
| PREF-01 | جزئي | حفظ local locale/theme يعمل؛ لا await قبل أول frame أو account locale/device sync |

## متطلبات إضافية من مواصفات البلوبرينت خارج checkboxes

| المتطلب | نتيجة المراجعة |
|---|---|
| مخدومو servant حسب الإسناد فقط؛ minimal roster مرتبط بمهمة all | غير مطابق: Rules توسع قراءة السنة، وroster لكل active، وشاشة القداس تقرأ مستندات الأطفال كاملة |
| lifecycle deleting ومنع الوصول | غير موصل في Session/profile؛ stageAdmin يعتبر active بغض النظر عن status |
| visitType codes وlegacy parser يحتفظ بـunknown | غير مكتمل: VisitModel يحتفظ بالنصوص العربية؛ لا توحيد legacy migration شامل |
| secondaryType code + customLabel | غير منفذ كعقد منفصل؛ الموديل ما زال secondaryType نصًا واحدًا |
| locale حساب المستخدم يتقدم على الجهاز بعد الدخول | غير موصل؛ SettingsRepository محلي، وتسجيل الجهاز لا يحصل على locale المختار |
| RTL/LTR وتكبير200% والهواتف/الروابط LTR | لا اختبارات شاشات كاملة تثبتها؛ لا اعتماد بصري في هذه الجولة |
| فحص assets للنص المدمج واسم التطبيق والقناة على المنصات | غير متحقق بصريًا/على الأجهزة؛ لا ادعاء أن كل الأصول مترجمة |
| xls بملف فعلي أو قصر picker على xlsx | picker ما زال يقبل xls؛ لا fixture فعلي يثبت الدعم |
| notifications تخزن templateKey+args؛ لغة قارئ ولغة مستلم | module templates موجود فقط؛ sender ومسار العرض لا يستخدمانه كنظام متكامل |
| history model حي وفصل التقرير عن الملاحظة | stream حي أضيف؛ بعض الأفعال تستعمل widget.makhdom القديم، والكتابة ما زالت تخلط notes |
| data/cache/pendingWrites حالات منفصلة | لا propagation فعلي لـisFromCache/hasPendingWrites؛ Helper وحده لا يحققها |
| إعادة فتح finalized للمسؤول مع audit | لا دليل على تدفق مكتمل بهذه السياسة |
| integration_test/app_flows_test.dart للتدفق الكامل | غير موجود؛ لا قبول end-to-end على emulator/staging |
| schema migration report/checkpoint/resume | --resume/checkpoint يتم parsing فقط دون حفظ أو استئناف فعلي، ولا إصلاح assignedCount شامل |
| production rules، backup restore، FCM على جهازين، platform builds | غير متحقق؛ لم نلمس الإنتاج أو نفترض نتائج تشغيل غير موجودة |

## ترتيب إغلاق النواقص

1. توحيد schema بين الموديلات وqueries وRules وFunctions، وإغلاق صلاحيات callables؛ إصلاح runtime وتشغيل gate المحاكي.
2. توصيل UI بالعمليات المقصودة: task/visit/assignment/import/finalize/deletion، بدل وجود نسختين من كل تدفق؛ اختبارات على المسار الحقيقي.
3. إصلاح Router وحراسة المورد وتبديل الدور/الحساب، ثم notification types/refresh وdevice lifecycle.
4. استكمال idempotency والتزامن والأرشفة والحذف والمهاجرة؛ اختبار retries وفشل منتصف العملية.
5. نقل الترجمة فعليًا إلى ARB، وتوحيد الأخطاء والقوالب والـlocale، وإتمام ar/en/RTL/LTR/200% tests.
6. تصحيح التحليلات وتوصيل الفترة/pagination/error states، ثم التدفق المتكامل وقياس staging.
7. backup/restore تجريبي ومهاجرة قابلة للاستئناف وتوقيع release واختبارات المنصات قبل اعتماد الإصدار.

معيار إغلاق أي بند: اختبار يمر عبر الواجهة/المستودع/الدالة المستخدمة فعلًا ويثبت سيناريو القبول، مع Rules في المحاكي عند لمس Firestore. وجود ملف جديد أو اختبار يكرر الحساب داخله لا يغلق البند.



## مواضع مباشرة لاستكمال الـRouter والترجمة

هذه أمثلة تنفيذية مؤكدة من الملفات الحالية، وتكمل سجل المهام أعلاه؛ ليست عدًّا إحصائيًا لكل النصوص.

### انتقالات صفحات لم تتحول إلى Router

| الملف | الموجود حاليًا | التعديل المتبقي |
|---|---|---|
| [login_screen.dart](D:/work/flutter/efteqad/lib/features/auth/presentation/screens/login_screen.dart:46) | pushReplacement عند46/55/60/65/210 يختار صفحات الأدوار القديمة | login يحدّث Auth فقط؛ Session/Router يختاران الوجهة |
| [pending_assignment_screen.dart](D:/work/flutter/efteqad/lib/features/auth/presentation/screens/pending_assignment_screen.dart:82) | pushAndRemoveUntil عند82/116/121 | متابعة Session دون إنشاء stack مستقل |
| [app_drawer.dart](D:/work/flutter/efteqad/lib/features/common/widgets/app_drawer.dart:55) | logout عند55، profile/settings عند208/234؛ home يغلق drawer فقط | named routes؛ home إلى landing الفعلي |
| [settings_screen.dart](D:/work/flutter/efteqad/lib/features/settings/presentation/screens/settings_screen.dart:51) | logout/delete يفتحان Login عبر Navigator عند51/111 | تغيير Session، مسح scope/intents، Router يتولى الدخول |
| [makhdom_card.dart](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/makhdom_card.dart:91) | history عبر MaterialPageRoute عند91/208/572 | رابط history بالـmakhdomId مع فحص المورد |
| [tasks_tab.dart](D:/work/flutter/efteqad/lib/features/tasks/presentation/widgets/tasks_tab.dart:326) | حضور عبر MaterialPageRoute يحمل Model | taskId route؛ مراقبة صلاحية المهمة وحالتها |
| [app_router.dart](D:/work/flutter/efteqad/lib/core/router/app_router.dart:282) | initialLocation لكل فروع السنة هو1st | بناء وجهة الفرع بالسنة الحالية؛ اختبار gradeAdmin ثانية/ثالثة |
| [ProtectedResourcePage](D:/work/flutter/efteqad/lib/core/router/widgets/protected_resource_page.dart:18) | extra/initialData يتجاوز loadResource بالكامل | extra cache للعرض فقط، لا يتجاوز إعادة التحقق من المورد والصلاحية |

إغلاق dialogs/sheets بـNavigator.pop مسموح كما في البلوبرينت؛ المشكلة في انتقالات الصفحات المذكورة، وليس كل استخدام لـNavigator.

### نصوص ما زالت تحتاج النقل والترجمة

| الملف | المثال المؤكد | ما بقي |
|---|---|---|
| [add_edit_makhdom_dialog.dart](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/add_edit_makhdom_dialog.dart:428) | العمر، «محسوب بدقة»، «تلقائي»، reset tooltip، اختيار تاريخ الميلاد عند428/445/459/472/534/558 | ARB + placeholders/locale format |
| [makhdom_card.dart](D:/work/flutter/efteqad/lib/features/admin/presentation/widgets/makhdom_card.dart:403) | جملة «العمر… محسوب تلقائياً حسب…» عربية | رسالة مولدة وDomainLabels |
| [add_task_dialog.dart](D:/work/flutter/efteqad/lib/features/tasks/presentation/widgets/add_task_dialog.dart:124) | «خطأ: $e»، «تحديد تاريخ المهمة»، «جمعة» عند124/279/280/295 | AppFailure مترجم، task date، يوم فعلي |
| [record_visit_sheet.dart](D:/work/flutter/efteqad/lib/features/common/widgets/record_visit_sheet.dart:315) | «ملاحظات وما دار في الافتقاد (الديسكريبشن)» | visitReportLabel/Hint |
| [khadem_profile_screen.dart](D:/work/flutter/efteqad/lib/features/khadem/presentation/screens/khadem_profile_screen.dart:182) | «خادم بالمرحلة» | stageServantFallback |
| [analytics_tab.dart](D:/work/flutter/efteqad/lib/features/admin/presentation/screens/analytics_tab.dart:684) | «حضور الخدمة»، «حضور القداس»، «متوسط حضور القداسات» عند684/692/696 | موارد مترجمة وصياغة مطابقة لنوع المؤشر |
| [notification_service.dart](D:/work/flutter/efteqad/lib/core/services/notification_service.dart:27) | اسم ووصف قناة Android عربيان ثابتان | ID ثابت واسم/وصف محليان؛ اختبار أثر تغيير اللغة على النظام |
| [ProtectedResourcePage](D:/work/flutter/efteqad/lib/core/router/widgets/protected_resource_page.dart:37) | snapshot.error.toString() يظهر للمستخدم | code→رسالة مترجمة مع retry |

وجود ternary عربي/إنجليزي ليس وحده «ترجمة مفقودة»، لكنه يبقى مخالفًا لمطلب نقل الموارد إلى ARB. نصوص المستخدمين الحرة بالعربية ليست أخطاء ترجمة.


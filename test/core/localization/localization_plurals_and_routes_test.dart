import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/constants/constants.dart';
import 'package:efteqad/core/localization/app_localizations.dart';

void main() {
  group('Localization Plurals Tests (0, 1, 2, 3, 11, 100)', () {
    final ar = lookupGeneratedAppLocalizations(const Locale('ar', 'EG'));
    final en = lookupGeneratedAppLocalizations(const Locale('en', 'US'));

    test('Arabic plural rules for visitsCount: 0, 1, 2, few, many, other', () {
      expect(ar.visitsCount(0), 'لا توجد افتقادات');
      expect(ar.visitsCount(1), 'افتقاد واحد');
      expect(ar.visitsCount(2), 'افتقادان');
      expect(ar.visitsCount(3), '3 افتقادات');
      expect(ar.visitsCount(5), '5 افتقادات');
      expect(ar.visitsCount(10), '10 افتقادات');
      expect(ar.visitsCount(11), '11 افتقاداً');
      expect(ar.visitsCount(25), '25 افتقاداً');
      expect(ar.visitsCount(99), '99 افتقاداً');
      expect(ar.visitsCount(100), '100 افتقاد');
      expect(ar.visitsCount(200), '200 افتقاد');
    });

    test('English plural rules for visitsCount: 0, 1, other', () {
      expect(en.visitsCount(0), 'No visits');
      expect(en.visitsCount(1), '1 visit');
      expect(en.visitsCount(2), '2 visits');
      expect(en.visitsCount(3), '3 visits');
      expect(en.visitsCount(11), '11 visits');
      expect(en.visitsCount(100), '100 visits');
    });

    test(
      'Arabic plural rules for studentsCount: 0, 1, 2, few, many, other',
      () {
        expect(ar.studentsCount(0), 'لا يوجد مخدومين');
        expect(ar.studentsCount(1), 'مخدوم واحد');
        expect(ar.studentsCount(2), 'مخدومان');
        expect(ar.studentsCount(3), '3 مخدومين');
        expect(ar.studentsCount(11), '11 مخدوماً');
        expect(ar.studentsCount(100), '100 مخدوم');
      },
    );

    test('English plural rules for studentsCount: 0, 1, other', () {
      expect(en.studentsCount(0), 'No students');
      expect(en.studentsCount(1), '1 student');
      expect(en.studentsCount(2), '2 students');
      expect(en.studentsCount(3), '3 students');
      expect(en.studentsCount(11), '11 students');
      expect(en.studentsCount(100), '100 students');
    });

    test(
      'Arabic plural rules for servantsCount: 0, 1, 2, few, many, other',
      () {
        expect(ar.servantsCount(0), 'لا يوجد خدام');
        expect(ar.servantsCount(1), 'خادم واحد');
        expect(ar.servantsCount(2), 'خادمان');
        expect(ar.servantsCount(3), '3 خدام');
        expect(ar.servantsCount(11), '11 خادماً');
        expect(ar.servantsCount(100), '100 خادم');
      },
    );

    test('English plural rules for servantsCount: 0, 1, other', () {
      expect(en.servantsCount(0), 'No servants');
      expect(en.servantsCount(1), '1 servant');
      expect(en.servantsCount(2), '2 servants');
      expect(en.servantsCount(3), '3 servants');
      expect(en.servantsCount(11), '11 servants');
      expect(en.servantsCount(100), '100 servants');
    });
  });

  group('Domain Data Codes Invariance Tests', () {
    test('Role codes and grade keys remain fixed strings in data models', () {
      expect(AppConstants.roleStageAdmin, 'stageAdmin');
      expect(AppConstants.roleGradeAdmin, 'gradeAdmin');
      expect(AppConstants.roleServant, 'servant');
      expect(AppConstants.rolePending, 'pending');

      expect(AppConstants.grade1st, '1st');
      expect(AppConstants.grade2nd, '2nd');
      expect(AppConstants.grade3rd, '3rd');

      expect(AppConstants.taskTypeAttendanceKhedma, 'attendance_khedma');
      expect(AppConstants.taskTypeAttendanceQoddas, 'attendance_qoddas');
    });
  });

  group('Route Preservation Across Locale Switch', () {
    testWidgets(
      'switching locale preserves active widget and navigator stack',
      (tester) async {
        final currentLocale = ValueNotifier<Locale>(const Locale('ar', 'EG'));

        await tester.pumpWidget(
          ValueListenableBuilder<Locale>(
            valueListenable: currentLocale,
            builder: (context, locale, _) {
              return MaterialApp(
                locale: locale,
                supportedLocales: const [
                  Locale('ar', 'EG'),
                  Locale('en', 'US'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Builder(
                  builder: (ctx) => Scaffold(
                    appBar: AppBar(title: Text(ctx.tr.appName)),
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).push(
                            MaterialPageRoute(
                              builder: (subCtx) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('SubScreenRoute'),
                                ),
                                body: Text(subCtx.tr.settingsTitle),
                              ),
                            ),
                          );
                        },
                        child: const Text('Go to SubRoute'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        // Verify Arabic home
        expect(find.text('الراعي'), findsOneWidget);

        // Navigate to sub-route
        await tester.tap(find.text('Go to SubRoute'));
        await tester.pumpAndSettle();

        expect(find.text('SubScreenRoute'), findsOneWidget);
        expect(find.text('الإعدادات'), findsOneWidget);

        // Switch language to English while on sub-route
        currentLocale.value = const Locale('en', 'US');
        await tester.pumpAndSettle();

        // Sub-route is STILL active (not popped or reset), text is now English
        expect(find.text('SubScreenRoute'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );
  });
}

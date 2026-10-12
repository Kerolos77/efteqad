import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/models/makhdom_model.dart';
import 'package:efteqad/features/admin/presentation/widgets/makhdom_card.dart';

void main() {
  final arabic = {
    0: 'لم يتم افتقاده',
    1: 'افتقاد واحد',
    2: 'افتقادان',
    3: '3 افتقادات',
    11: '11 افتقاداً',
    100: '100 افتقاد',
  };
  final english = {
    0: 'Not Visited Yet',
    1: '1 visit',
    2: '2 visits',
    3: '3 visits',
    11: '11 visits',
    100: '100 visits',
  };
  for (final language in ['ar', 'en']) {
    for (final count in [0, 1, 2, 3, 11, 100]) {
      testWidgets(
        'actual child card $language renders visit count $count with correct plural',
        (tester) async {
          final child = MakhdomModel(
            id: 'm',
            fullName: 'كيرلس',
            phone: '',
            visitCount: count,
            createdAt: DateTime(2026),
          );
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: SingleChildScrollView(child: MakhdomCard(makhdom: child)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text((language == 'ar' ? arabic : english)[count]!),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

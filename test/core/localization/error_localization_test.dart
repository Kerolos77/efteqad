import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/widgets/async_content.dart';

void main() {
  testWidgets(
    'English error UI localizes network code and hides technical details with retry',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AsyncContent<int>(
              isLoading: false,
              error: AppFailure.network(message: 'private sdk diagnostic'),
              onRetry: () => retried = true,
              builder: (_, data) => Text('$data'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not connect. Check your internet connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('private sdk diagnostic'), findsNothing);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    },
  );
}

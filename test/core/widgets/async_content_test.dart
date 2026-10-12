import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/localization/app_localizations.dart';
import 'package:efteqad/core/widgets/async_content.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    locale: const Locale('ar', 'EG'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AsyncContent Widget Tests (Task 13)', () {
    testWidgets('renders loading widget when loading with no data', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AsyncContent<List<String>>(
            isLoading: true,
            data: null,
            builder: (ctx, data) => Text('Count: ${data.length}'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Count:'), findsNothing);
    });

    testWidgets(
      'renders error view and NOT empty view on failure (permission/network/decode)',
      (tester) async {
        bool retried = false;
        const failure = AppFailure(
          code: 'permission-denied',
          message: 'ليس لديك صلاحية',
          retryable: true,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            AsyncContent<List<String>>(
              isLoading: false,
              error: failure,
              data: null,
              isEmpty: (data) => data.isEmpty,
              onRetry: () => retried = true,
              builder: (ctx, data) => Text('Count: ${data.length}'),
            ),
          ),
        );

        expect(
          find.text('ليس لديك صلاحية لتنفيذ هذه العملية.'),
          findsOneWidget,
        );
        expect(find.text('ليس لديك صلاحية'), findsNothing);
        // Crucial: Must NEVER show empty view on error!
        expect(find.byIcon(Icons.inbox_rounded), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Verify retry button operates
        final retryBtn = find.text('إعادة المحاولة');
        expect(retryBtn, findsOneWidget);
        await tester.tap(retryBtn);
        expect(retried, isTrue);
      },
    );

    testWidgets('renders empty view when data is empty and no error exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AsyncContent<List<String>>(
            isLoading: false,
            error: null,
            data: const [],
            isEmpty: (data) => data.isEmpty,
            builder: (ctx, data) => Text('Count: ${data.length}'),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.textContaining('Count:'), findsNothing);
    });

    testWidgets('renders content when data is populated', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AsyncContent<List<String>>(
            isLoading: false,
            error: null,
            data: const ['Item 1', 'Item 2'],
            isEmpty: (data) => data.isEmpty,
            builder: (ctx, data) => Text('Items: ${data.join(', ')}'),
          ),
        ),
      );

      expect(find.text('Items: Item 1, Item 2'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsNothing);
    });

    testWidgets('renders offline banner when isOffline is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AsyncContent<List<String>>(
            isLoading: false,
            error: null,
            isOffline: true,
            data: const ['Cached 1'],
            isEmpty: (data) => data.isEmpty,
            builder: (ctx, data) => Text('Cached: ${data.first}'),
          ),
        ),
      );

      expect(find.text('أنت في وضع عدم الاتصال (أوفلاين)'), findsOneWidget);
      expect(find.text('Cached: Cached 1'), findsOneWidget);
    });
  });
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/page_result.dart';
import 'package:efteqad/core/models/snapshot_list.dart';
import 'package:efteqad/core/errors/app_failure.dart';
import 'package:efteqad/core/widgets/paged_content.dart';
import 'package:efteqad/core/widgets/query_content.dart';
import 'task5_widgets_test.dart' show app;

// ignore: subtype_of_sealed_class
class Cursor implements DocumentSnapshot {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets(
    'all retained cached pages remain labeled awaiting server confirmation',
    (t) async {
      final cursor = Cursor();
      await t.pumpWidget(
        app(
          PagedContent<String>(
            queryKey: 'q',
            fetch: (after) async => after == null
                ? PageResult(
                    items: SnapshotList(
                      ['A'],
                      isFromCache: true,
                      hasPendingWrites: false,
                    ),
                    cursor: cursor,
                    hasMore: true,
                  )
                : PageResult(
                    items: SnapshotList(
                      ['B'],
                      isFromCache: false,
                      hasPendingWrites: false,
                    ),
                    hasMore: false,
                  ),
            builder: (context, items, more) => Column(
              children: [
                for (final s in items) Text(s),
                if (more != null) more,
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('cached data'), findsOneWidget);
      await t.tap(find.text('Load more'));
      await t.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.textContaining('cached data'), findsOneWidget);
    },
  );
  testWidgets(
    'failed next page retry reuses last successful cursor without duplicating items',
    (t) async {
      final cursor = Cursor();
      var attempt = 0;
      final used = <DocumentSnapshot?>[];
      await t.pumpWidget(
        app(
          PagedContent<String>(
            queryKey: 'q',
            fetch: (after) async {
              used.add(after);
              if (after == null) {
                return PageResult(items: ['A'], cursor: cursor, hasMore: true);
              }
              if (attempt++ == 0) {
                throw const AppFailure(
                  code: 'unavailable',
                  message: 'private',
                  retryable: true,
                );
              }
              return const PageResult(items: ['B'], hasMore: false);
            },
            builder: (context, items, more) => Column(
              children: [
                for (final s in items) Text(s),
                if (more != null) more,
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Load more'));
      await t.pumpAndSettle();
      expect(find.text('private'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(used, [null, cursor, cursor]);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    },
  );
  testWidgets(
    'query scope changes cancel prior listener and network retry creates a new one',
    (t) async {
      var cancelled = false, retries = 0;
      final old = StreamController<List<String>>(
        onCancel: () {
          cancelled = true;
        },
      );
      await t.pumpWidget(
        app(
          QueryContent<List<String>>(
            queryKey: 'grade1',
            query: () => old.stream,
            builder: (context, items) => Text(items.join()),
          ),
        ),
      );
      await t.pump();
      old.add(['old']);
      await t.pump();
      await t.pumpWidget(
        app(
          QueryContent<List<String>>(
            queryKey: 'grade2',
            query: () {
              retries++;
              return retries == 1
                  ? Stream.error(
                      const AppFailure(
                        code: 'unavailable',
                        message: 'private',
                        retryable: true,
                      ),
                    )
                  : Stream.value(['new']);
            },
            builder: (context, items) => Text(items.join()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(cancelled, isTrue);
      expect(find.text('old'), findsNothing);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(retries, 2);
      expect(find.text('new'), findsOneWidget);
      unawaited(old.close());
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:efteqad/core/models/page_result.dart';

void main() {
  group('Query Pagination & Tie-break Unit Tests (Task 13)', () {
    test('PageResult correctly reports empty and length properties', () {
      final emptyResult = PageResult<String>.empty();
      expect(emptyResult.isEmpty, isTrue);
      expect(emptyResult.isNotEmpty, isFalse);
      expect(emptyResult.length, 0);
      expect(emptyResult.hasMore, isFalse);
      expect(emptyResult.cursor, isNull);

      final populated = PageResult<String>(
        items: const ['a', 'b', 'c'],
        hasMore: true,
        cursor: null,
      );
      expect(populated.isEmpty, isFalse);
      expect(populated.length, 3);
      expect(populated.hasMore, isTrue);
    });
  });
}

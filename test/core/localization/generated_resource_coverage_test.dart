import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated catalogs cover the full runtime resource contract', () {
    final ar =
        jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync()) as Map;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final keys = ar.keys.where((key) => !key.startsWith('@')).toSet();
    expect(keys.length, greaterThan(350));
    expect(en.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    expect(ar['continueWithGoogle'], isNotNull);
    expect(en['visitOutcomeHeader'], contains('{date}'));
    expect(ar['@visitsCount']['placeholders']['count']['type'], 'int');
  });
}

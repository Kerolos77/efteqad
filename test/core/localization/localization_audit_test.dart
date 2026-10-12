import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ProcessResult> audit(
    String source,
    Map<String, dynamic> ar,
    Map<String, dynamic> en,
  ) async {
    final root = Directory.systemTemp.createTempSync('efteqad_l10n_');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/lib/l10n').createSync(recursive: true);
    File('${root.path}/lib/screen.dart').writeAsStringSync(source);
    File('${root.path}/lib/l10n/app_ar.arb').writeAsStringSync(jsonEncode(ar));
    File('${root.path}/lib/l10n/app_en.arb').writeAsStringSync(jsonEncode(en));
    return Process.run('dart', [
      'run',
      'tool/audit_localization.dart',
      '--root',
      root.path,
    ], runInShell: true);
  }

  test(
    'audit rejects Arabic Text and English InputDecoration literals',
    () async {
      final result = await audit(
        "void build(){ Text('مرحبا'); Text('Welcome'); InputDecoration(labelText: 'Email'); }",
        {'appName': 'الراعي'},
        {'appName': 'Shepherd'},
      );
      expect(result.exitCode, 1, reason: result.stdout.toString());
      expect(result.stderr.toString(), contains('hardcoded UI'));
      expect(result.stderr.toString(), contains('Welcome'));
    },
  );
  test('audit allows comments user data and stable storage codes', () async {
    final result = await audit(
      "// Text('تعليق')\nvoid build(String name){final data={'role':'stageAdmin','name':'أحمد','notes':'ملاحظات الأسرة'}; Text(name); Text(data['name']);}",
      {'appName': 'الراعي'},
      {'appName': 'Shepherd'},
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
  });
  test('audit follows a hardcoded English title variable into Text', () async {
    final result = await audit(
      "void build(){ final title='Untranslated title'; Text(title); }",
      {'appName': 'الراعي'},
      {'appName': 'Shepherd'},
    );
    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('Untranslated title'));
  });
  test(
    'audit rejects a missing generated key in an actual Text expression',
    () async {
      final result = await audit(
        'void build(){ Text(context.tr.missingResource); }',
        {'appName': 'الراعي'},
        {'appName': 'Shepherd'},
      );
      expect(result.exitCode, 1, reason: result.stdout.toString());
      expect(
        result.stderr.toString(),
        contains('missing generated resource key'),
      );
    },
  );
  test('audit rejects raw caught exception aliases rendered by Text', () async {
    final result = await audit(
      'void build(){ try { load(); } catch(e) { final raw=e.toString(); Text(raw); new Text(raw); new TextSpan(text: raw); } }',
      {'appName': 'الراعي'},
      {'appName': 'Shepherd'},
    );
    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(
      RegExp('raw exception in UI').allMatches(result.stderr.toString()).length,
      3,
    );
  });
  test('audit rejects mismatched and missing placeholder metadata', () async {
    final result = await audit(
      '',
      {
        'welcome': 'أهلا {name}',
        '@welcome': {
          'placeholders': {
            'name': {'type': 'String'},
          },
        },
      },
      {'welcome': 'Hello {user}'},
    );
    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('placeholder'));
  });
  test('audit rejects placeholder type differences across locales', () async {
    final result = await audit(
      '',
      {
        'welcome': 'أهلا {name}',
        '@welcome': {
          'placeholders': {
            'name': {'type': 'String'},
          },
        },
      },
      {
        'welcome': 'Hello {name}',
        '@welcome': {
          'placeholders': {
            'name': {'type': 'int'},
          },
        },
      },
    );
    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('types/formats'));
  });
  test('audit rejects malformed nested ICU plural', () async {
    final value = '{count, plural, =0{None} other{{count} visits}';
    final result = await audit(
      '',
      {
        'countVisits': value,
        '@countVisits': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      },
      {
        'countVisits': value,
        '@countVisits': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      },
    );
    expect(result.exitCode, 1, reason: result.stdout.toString());
    expect(result.stderr.toString(), contains('ICU'));
  });
}

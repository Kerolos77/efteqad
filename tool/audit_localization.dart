import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Parses nested ICU arguments and branches; braces inside plural branches are
/// parsed recursively, rather than treating the message as a flat regex.
class IcuParser {
  final String source;
  int offset = 0;
  final Set<String> placeholders = {};
  final Map<String, String> argumentKinds = {};
  IcuParser(this.source);
  Set<String> parse() {
    _message(false);
    return placeholders;
  }

  Never fail(String reason) =>
      throw FormatException('ICU $reason at $offset', source);
  void space() {
    while (offset < source.length && source[offset].trim().isEmpty) {
      offset++;
    }
  }

  String token() {
    space();
    final start = offset;
    while (offset < source.length &&
        RegExp(r'[\w=.-]').hasMatch(source[offset])) {
      offset++;
    }
    if (start == offset) fail('expected token');
    return source.substring(start, offset);
  }

  void _message(bool branch) {
    while (offset < source.length) {
      final ch = source[offset++];
      if (ch == '}') {
        if (!branch) fail('unexpected closing brace');
        return;
      }
      if (ch == '{') _argument();
    }
    if (branch) fail('unclosed branch');
  }

  void _argument() {
    final name = token();
    if (!RegExp(r'^[a-zA-Z_]\w*$').hasMatch(name)) fail('invalid placeholder');
    placeholders.add(name);
    space();
    if (offset >= source.length) fail('unclosed argument');
    if (source[offset] == '}') {
      offset++;
      return;
    }
    if (source[offset++] != ',') fail('expected comma');
    final kind = token();
    argumentKinds[name] = kind;
    space();
    if (!{'plural', 'select', 'selectordinal'}.contains(kind)) {
      fail('unsupported argument $kind');
    }
    if (offset >= source.length || source[offset++] != ',') {
      fail('expected branches');
    }
    final labels = <String>{};
    while (true) {
      space();
      if (offset >= source.length) fail('unclosed plural/select');
      if (source[offset] == '}') {
        offset++;
        break;
      }
      final label = token();
      if (kind != 'select' &&
          !{'zero', 'one', 'two', 'few', 'many', 'other'}.contains(label) &&
          !RegExp(r'^=-?\d+(?:\.\d+)?$').hasMatch(label)) {
        fail('invalid plural selector $label');
      }
      if (!labels.add(label)) fail('duplicate branch $label');
      space();
      if (offset >= source.length || source[offset++] != '{') {
        fail('expected branch body');
      }
      _message(true);
    }
    if (!labels.contains('other')) fail('missing other branch');
  }
}

List<String> auditCatalogs(Map<String, dynamic> ar, Map<String, dynamic> en) {
  final issues = <String>[];
  final keys = ar.keys.where((k) => !k.startsWith('@')).toSet();
  final other = en.keys.where((k) => !k.startsWith('@')).toSet();
  if (keys.difference(other).isNotEmpty || other.difference(keys).isNotEmpty) {
    issues.add(
      'resource key mismatch: ${keys.difference(other)} / ${other.difference(keys)}',
    );
  }
  for (final key in keys.intersection(other)) {
    Set<String>? first;
    for (final catalog in [ar, en]) {
      try {
        if (catalog[key] is! String) {
          throw FormatException('resource must be a string');
        }
        final parser = IcuParser(catalog[key] as String);
        final used = parser.parse();
        final metadata = catalog['@$key'];
        final declared = metadata is Map && metadata['placeholders'] is Map
            ? (metadata['placeholders'] as Map).keys.cast<String>().toSet()
            : <String>{};
        if (!sameSet(used, declared)) {
          issues.add('$key placeholder metadata mismatch: $used / $declared');
        }
        if (first != null && !sameSet(first, used)) {
          issues.add('$key placeholder locale mismatch: $first / $used');
        }
        first = used;
        if (catalog == en &&
            !sameSet(
              declared,
              (ar['@$key'] is Map && ar['@$key']['placeholders'] is Map)
                  ? (ar['@$key']['placeholders'] as Map).keys
                        .cast<String>()
                        .toSet()
                  : <String>{},
            )) {
          issues.add('$key placeholder metadata locale mismatch');
        }
        if (catalog == en &&
            metadata is Map &&
            ar['@$key'] is Map &&
            jsonEncode(metadata['placeholders']) !=
                jsonEncode(ar['@$key']['placeholders'])) {
          issues.add('$key placeholder types/formats differ across locales');
        }
        for (final name in declared) {
          final p = metadata['placeholders'][name];
          if (p is! Map ||
              !{
                'String',
                'int',
                'double',
                'num',
                'DateTime',
              }.contains(p['type'])) {
            issues.add('$key placeholder $name has missing/invalid type');
          }
          if (parser.argumentKinds[name] == 'plural' &&
              p is Map &&
              !{'int', 'double', 'num'}.contains(p['type'])) {
            issues.add('$key plural placeholder $name must be numeric');
          }
        }
      } on FormatException catch (e) {
        issues.add('$key $e');
      }
    }
  }
  return issues;
}

bool sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

class SourceIssue {
  final String file;
  final int line;
  final String source;
  SourceIssue(this.file, this.line, this.source);
  @override
  String toString() => '$file:$line hardcoded UI: $source';
}

/// Allowlist is per exact value and source location/reason, kept separate from
/// the visitor. No whole feature folder or Arabic-language exemption exists.
AstNode sourceScope(AstNode node) =>
    node.thisOrAncestorOfType<FunctionExpression>() ??
    node.thisOrAncestorOfType<MethodDeclaration>() ??
    node.thisOrAncestorOfType<FunctionDeclaration>() ??
    node.thisOrAncestorOfType<ClassDeclaration>() ??
    node.root;

class DefinitionCollector extends RecursiveAstVisitor<void> {
  final Map<AstNode, Map<String, List<Expression>>> definitions = {};
  void add(AstNode node, String name, Expression expression) {
    definitions
        .putIfAbsent(sourceScope(node), () => {})
        .putIfAbsent(name, () => [])
        .add(expression);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null) {
      add(node, node.name.lexeme, node.initializer!);
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.leftHandSide is SimpleIdentifier) {
      add(
        node,
        (node.leftHandSide as SimpleIdentifier).name,
        node.rightHandSide,
      );
    }
    super.visitAssignmentExpression(node);
  }
}

class SourceAudit extends RecursiveAstVisitor<void> {
  final String path;
  final String content;
  final Set<String>? resourceKeys;
  final Map<String, Set<String>> allowlistedValues;
  final List<SourceIssue> issues = [];
  int literals = 0;
  int sinks = 0;
  int references = 0;
  final taintedNames = <String>{};
  final DefinitionCollector definitions = DefinitionCollector();
  final traced = <int>{};
  final checked = <int>{};
  SourceAudit(
    this.path,
    this.content, {
    this.resourceKeys,
    this.allowlistedValues = const {},
  });
  bool isCaseLabel(AstNode node) =>
      node.thisOrAncestorOfType<ConstantPattern>() != null ||
      (node.parent is SwitchCase &&
          (node.parent as SwitchCase).expression == node);
  bool allowed(String value, AstNode node) {
    if (node.parent is MapLiteralEntry) {
      final entry = node.parent as MapLiteralEntry;
      if (entry.key is SimpleStringLiteral &&
          {
            'name',
            'fullName',
            'notes',
            'address',
            'school',
          }.contains((entry.key as SimpleStringLiteral).value)) {
        return true; // User-data sample fields; names/notes/addresses remain untranslated.
      }
    }
    final named = node.thisOrAncestorOfType<NamedExpression>();
    final call = named?.parent?.parent;
    if (named?.name.label.name == 'message' &&
        ((call is MethodInvocation &&
                (call.methodName.name == 'AppFailure' ||
                    call.target?.toSource() == 'AppFailure')) ||
            (call is InstanceCreationExpression &&
                call.constructorName.type.name2.lexeme == 'AppFailure'))) {
      return true; // Technical failure diagnostics; localizedMessage is the only UI boundary.
    }
    if (path ==
            'lib/features/admin/presentation/widgets/add_edit_makhdom_dialog.dart' &&
        value == 'general' &&
        call is MethodInvocation &&
        call.methodName.name == 'TextEditingController') {
      return true; // Stored secondary type code; Dropdown renders DomainLabels.
    }
    if ({
          'yyyy-MM-dd',
          'yyyy/MM/dd',
          'EEEE d MMMM yyyy',
          'EEEE',
        }.contains(value) &&
        node.thisOrAncestorOfType<MethodInvocation>()?.methodName.name ==
            'formatDate') {
      return true; // Locale-aware formatter patterns, never display copy.
    }
    if (value == '🇺🇸' || value == '«»') {
      return true; // Flag and typographic decorations.
    }
    if (path == 'lib/core/errors/app_failure.dart' &&
        node
                .thisOrAncestorOfType<InstanceCreationExpression>()
                ?.constructorName
                .type
                .name2
                .lexeme ==
            'AppFailure') {
      return true; // Diagnostic messages; only localizedMessage is displayed.
    }

    if (path == 'lib/core/services/trusted_mutations.dart' &&
        isCaseLabel(node)) {
      return true; // Exact legacy visit aliases; canonical internal codes are returned.
    }
    if (value.trim().isEmpty ||
        RegExp(
          r'^[\d\s%.,;«»:/+−–—×•()!?✅❌✝️⭐🌟⚠️🚨📋🏠📞⛪💬🔔🇪🇬🇬🇧-]+$',
        ).hasMatch(value)) {
      return true; // Decorative symbols/separators and numeric chart ticks.
    }
    if (value.startsWith('assets/') ||
        value.startsWith('https://') ||
        value.startsWith('http://')) {
      return true; // Asset/network identifiers.
    }
    if (allowlistedValues[path]?.contains(value) ?? false) {
      return true; // Exact file/value/reason entries, never a whole parsing function.
    }
    if (path == 'lib/core/services/trusted_mutations.dart' &&
        node.thisOrAncestorOfType<MethodInvocation>()?.methodName.name ==
            'contains') {
      return true; // Legacy visit type aliases.
    }
    if (path == 'lib/core/localization/domain_labels.dart' &&
        isCaseLabel(node)) {
      return true; // Legacy persisted visit aliases.
    }
    if (path ==
            'lib/features/admin/presentation/widgets/history_timeline.dart' &&
        node.thisOrAncestorOfType<MethodInvocation>()?.methodName.name ==
            'contains') {
      return true; // Legacy visit icon classification.
    }
    if (path == 'lib/core/constants/constants.dart' &&
        {'appName', 'appTagline'}.contains(
          node.thisOrAncestorOfType<VariableDeclaration>()?.name.lexeme,
        )) {
      return true; // Branding and stable schema constants; displayed branding uses generated onGenerateTitle.
    }
    return false;
  }

  bool facing(AstNode node, String text) {
    if (node.parent is IndexExpression) {
      return false; // Storage keys, including title/description.
    }
    if (node.parent is BinaryExpression &&
        {
          '==',
          '!=',
        }.contains((node.parent as BinaryExpression).operator.lexeme)) {
      return false; // Stable code comparison, not the rendered label.
    }
    AstNode? p = node.parent;
    while (p != null) {
      if (p is ImportDirective || p is ExportDirective || p is Annotation) {
        return false;
      }
      if (p is MethodInvocation &&
          {
            'print',
            'debugPrint',
            'log',
            'contains',
            'startsWith',
            'replaceAll',
            'putIfAbsent',
            'collection',
            'doc',
          }.contains(p.methodName.name)) {
        return false;
      }
      if (p is NamedExpression &&
          {
            'labelText',
            'hintText',
            'helperText',
            'errorText',
            'tooltip',
            'title',
            'subtitle',
            'message',
            'description',
            'label',
            'text',
            'semanticLabel',
            'confirmLabel',
            'cancelLabel',
            'emptyMessage',
          }.contains(p.name.label.name)) {
        return true;
      }
      if (p is InstanceCreationExpression &&
          {
            'Text',
            'TextSpan',
            'Tooltip',
            'SnackBar',
            'AlertDialog',
            'InputDecoration',
            'AndroidNotificationChannel',
          }.contains(p.constructorName.type.name2.lexeme)) {
        return true;
      }
      if (p is MethodInvocation &&
          ({
                'Text',
                'TextSpan',
                'Tooltip',
                'SnackBar',
                'AlertDialog',
                'InputDecoration',
                'AndroidNotificationChannel',
              }.contains(p.methodName.name) ||
              p.methodName.name == '_showMessage' ||
              p.methodName.name.contains('SectionTitle') ||
              p.methodName.name.contains('InfoRow') ||
              p.methodName.name.contains('StatCard') ||
              p.methodName.name.contains('Badge'))) {
        return true;
      }
      if (p is Statement || p is ClassMember || p is CompilationUnit) break;
      p = p.parent;
    }
    // Legacy localization outputs: Arabic outside comments/data/schema aliases.
    return RegExp(r'[\u0600-\u06ff]').hasMatch(text);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.accept(definitions);
    super.visitCompilationUnit(node);
  }

  void traceUi(Expression expression) {
    if (expression is SimpleStringLiteral) {
      check(expression, expression.value, forceUi: true);
      return;
    }
    if (expression is StringInterpolation) {
      check(
        expression,
        expression.elements
            .whereType<InterpolationString>()
            .map((e) => e.value)
            .join(),
        forceUi: true,
      );
      for (final part
          in expression.elements.whereType<InterpolationExpression>()) {
        traceUi(part.expression);
      }
      return;
    }
    if (expression is SimpleIdentifier) {
      AstNode? scope = expression.parent;
      while (scope != null) {
        final candidates = definitions.definitions[scope]?[expression.name];
        if (candidates != null) {
          for (final definition in candidates) {
            if (traced.add(definition.offset)) traceUi(definition);
          }
          break;
        }
        scope = scope.parent;
      }
      return;
    }
    if (expression is ParenthesizedExpression) {
      traceUi(expression.expression);
      return;
    }
    if (expression is ConditionalExpression) {
      traceUi(expression.thenExpression);
      traceUi(expression.elseExpression);
      return;
    }
    if (expression is BinaryExpression && expression.operator.lexeme == '+') {
      traceUi(expression.leftOperand);
      traceUi(expression.rightOperand);
    }
    // A method/property read is an external data or formatting boundary; its
    // arguments are not its returned UI string. Direct literals in UI arguments
    // are still inspected by the normal AST visitor.
  }

  bool translatedTarget(Expression? target) =>
      target?.toSource() == 'tr' ||
      (target?.toSource().endsWith('.tr') ?? false);
  void issue(AstNode node, String reason) {
    issues.add(
      SourceIssue(
        path,
        '\n'.allMatches(content.substring(0, node.offset)).length + 1,
        reason,
      ),
    );
  }

  bool rawError(Expression expression) {
    final source = expression.toSource();
    if (source.contains('localizedMessage(')) return false;
    if (path ==
            'lib/features/admin/presentation/widgets/excel_actions_sheet.dart' &&
        source.contains('.errorMessage')) {
      return false; // Excel parser messages come from the selected generated catalog.
    }
    final caught = expression
        .thisOrAncestorOfType<CatchClause>()
        ?.exceptionParameter
        ?.name;
    if (caught != null && RegExp('\\b$caught\\b').hasMatch(source)) return true;
    if (RegExp(
      r'\b(?:failure|_error|snapshot|makhdomeenSnap)\.(?:message|error)\b',
    ).hasMatch(source)) {
      return true;
    }
    return taintedNames.any((name) => RegExp('\\b$name\\b').hasMatch(source));
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null && rawError(node.initializer!)) {
      taintedNames.add(node.name.lexeme);
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (translatedTarget(node.target)) {
      references++;
      if (resourceKeys != null &&
          !resourceKeys!.contains(node.methodName.name)) {
        issue(node, 'missing generated resource key ${node.methodName.name}');
      }
    }
    if (translatedTarget(node.target) ||
        {
          'Text',
          'TextSpan',
          'Tooltip',
          'SnackBar',
          'AlertDialog',
          'InputDecoration',
        }.contains(node.methodName.name)) {
      for (final argument in node.argumentList.arguments) {
        final value = argument is NamedExpression
            ? argument.expression
            : argument;
        if (rawError(value)) {
          issue(value, 'raw exception in UI: ${value.toSource()}');
        }
        traceUi(value);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if ({
      'Text',
      'TextSpan',
      'Tooltip',
      'SnackBar',
      'AlertDialog',
      'InputDecoration',
    }.contains(node.constructorName.type.name2.lexeme)) {
      for (final argument in node.argumentList.arguments) {
        final value = argument is NamedExpression
            ? argument.expression
            : argument;
        if (rawError(value)) {
          issue(value, 'raw exception in UI: ${value.toSource()}');
        }
        traceUi(value);
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if ({
      'gradeDisplayName',
      'typeDisplayName',
    }.contains(node.propertyName.name)) {
      issue(
        node,
        'legacy localized model getter ${node.propertyName.name}; use DomainLabels',
      );
    }
    if (translatedTarget(node.target) &&
        !{'isArabic', 'localeName'}.contains(node.propertyName.name)) {
      references++;
      if (resourceKeys != null &&
          !resourceKeys!.contains(node.propertyName.name)) {
        issue(node, 'missing generated resource key ${node.propertyName.name}');
      }
    }
    super.visitPropertyAccess(node);
  }

  void check(StringLiteral node, String text, {bool forceUi = false}) {
    if (!forceUi) literals++;
    if (node.parent is IndexExpression ||
        (node.parent is BinaryExpression &&
            {
              '==',
              '!=',
            }.contains((node.parent as BinaryExpression).operator.lexeme))) {
      return;
    }
    if (!(forceUi || facing(node, text)) || !checked.add(node.offset)) return;
    sinks++;
    if (!allowed(text, node)) {
      issues.add(
        SourceIssue(
          path,
          '\n'.allMatches(content.substring(0, node.offset)).length + 1,
          node.toSource(),
        ),
      );
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    check(node, node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    check(
      node,
      node.elements.whereType<InterpolationString>().map((e) => e.value).join(),
    );
    super.visitStringInterpolation(node);
  }
}

void main(List<String> args) {
  final root = args.contains('--root') ? args[args.indexOf('--root') + 1] : '.';
  final ar =
      jsonDecode(File('$root/lib/l10n/app_ar.arb').readAsStringSync())
          as Map<String, dynamic>;
  final en =
      jsonDecode(File('$root/lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final issues = auditCatalogs(ar, en);
  final allowed = <String, Set<String>>{};
  final allowlistFile = File('$root/tool/localization_allowlist.json');
  if (allowlistFile.existsSync()) {
    for (final entry in jsonDecode(allowlistFile.readAsStringSync()) as List) {
      if (entry['reason'] is! String ||
          (entry['reason'] as String).trim().isEmpty) {
        issues.add('Allowlist entry lacks a reason');
        continue;
      }
      allowed
          .putIfAbsent(entry['file'] as String, () => {})
          .addAll((entry['values'] as List).cast<String>());
    }
  }
  var files = 0, literals = 0, sinks = 0, references = 0;
  for (final file
      in Directory('$root/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    final path = file.path
        .substring(Directory(root).path.length)
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/'), '');
    if (path.startsWith('lib/l10n/generated/') ||
        path == 'lib/firebase_options.dart') {
      continue; // Machine generated catalogs/platform SDK credentials.
    }
    final source = file.readAsStringSync();
    final parsed = parseString(
      content: source,
      path: path,
      throwIfDiagnostics: false,
    );
    if (parsed.errors.isNotEmpty) {
      issues.add('$path AST parse diagnostics: ${parsed.errors}');
      continue;
    }
    final visitor = SourceAudit(
      path,
      source,
      resourceKeys: ar.keys.where((key) => !key.startsWith('@')).toSet(),
      allowlistedValues: allowed,
    );
    parsed.unit.accept(visitor);
    files++;
    literals += visitor.literals;
    sinks += visitor.sinks;
    references += visitor.references;
    issues.addAll(visitor.issues.map((e) => e.toString()));
  }
  stdout.writeln(
    'Resources: ${ar.keys.where((k) => !k.startsWith('@')).length}; AST files: $files; literals/interpolations: $literals; UI/legacy candidates: $sinks; generated references: $references; issues: ${issues.length}',
  );
  for (final issue in issues) {
    stderr.writeln(issue);
  }
  if (issues.isNotEmpty) exitCode = 1;
}

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/makhdom_model.dart';
import 'trusted_mutations.dart';

class ImportOutcome {
  final int imported;
  final List<Map<String, dynamic>> rejected;
  const ImportOutcome(this.imported, this.rejected);
}

class PartialImportFailure implements Exception {
  final ImportOutcome outcome;
  const PartialImportFailure(this.outcome);
  @override
  String toString() =>
      '${outcome.imported} imported; ${outcome.rejected.length} rejected: ${outcome.rejected}';
}

class ImportCoordinator {
  final TrustedMutations _mutations;
  final Future<SharedPreferences> _prefs;
  final String Function() _userId;
  ImportCoordinator({
    TrustedMutations? mutations,
    Future<SharedPreferences>? prefsFuture,
    String Function()? userId,
  }) : _mutations = mutations ?? TrustedMutations(),
       _prefs = prefsFuture ?? SharedPreferences.getInstance(),
       _userId = userId ?? (() => FirebaseAuth.instance.currentUser?.uid ?? '');
  // Two independent rolling hashes locate a ledger; the exact normalized payload verifies collisions.
  static String fingerprint(String text) {
    var a = 0x811c9dc5, b = 0x9e3779b9;
    for (final byte in utf8.encode(text)) {
      a = ((a ^ byte) * 0x01000193) & 0xffffffff;
      b = ((b ^ byte) * 0x85ebca6b) & 0xffffffff;
    }
    return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}_${text.length}';
  }

  Future<ImportOutcome> importRows(
    List<MakhdomModel> list, {
    String? importId,
    void Function(int processed, int total)? onProgress,
  }) async {
    if (list.isEmpty) return const ImportOutcome(0, []);
    final uid = _userId();
    if (uid.isEmpty) throw StateError('Authentication required.');
    void checkIdentity() {
      if (_userId() != uid) {
        throw StateError(
          'The initiating account changed. Resume the import as its owner.',
        );
      }
    }

    final grade = list.first.grade;
    if (list.any((r) => r.grade != grade)) {
      throw ArgumentError('One grade per import is required.');
    }
    final rows = list
        .map(TrustedMutations.profileFields)
        .map((r) => r.map((k, v) => MapEntry(k, v is String ? v.trim() : v)))
        .toList();
    final normalized = jsonEncode({'grade': grade, 'rows': rows});
    final prefs = await _prefs;
    final key = 'import_ledger_${uid}_${importId ?? fingerprint(normalized)}';
    final saved = prefs.getString(key);
    final ledger = saved == null
        ? <String, dynamic>{
            'expectedUid': uid,
            'importId': importId ?? newOperationId('import'),
            'normalized': normalized,
            'chunks': <String, dynamic>{},
          }
        : Map<String, dynamic>.from(jsonDecode(saved) as Map);
    if (ledger['normalized'] != normalized) {
      throw StateError('Import identifier already belongs to other rows.');
    }
    if (!await prefs.setString(key, jsonEncode(ledger))) {
      throw StateError('Could not persist import intent; no rows were sent.');
    }
    checkIdentity();
    final chunks = Map<String, dynamic>.from(ledger['chunks'] as Map);
    var imported = 0;
    final rejected = <Map<String, dynamic>>[];
    for (var offset = 0; offset < rows.length; offset += 200) {
      final index = offset ~/ 200,
          end = (offset + 200 < rows.length ? offset + 200 : rows.length);
      checkIdentity();
      Map<String, dynamic> result;
      if (chunks.containsKey('$index')) {
        result = Map<String, dynamic>.from(chunks['$index'] as Map);
      } else {
        result = await _mutations.call('importRows', {
          'expectedUid': uid,
          'importId': '${ledger['importId']}_chunk_$index',
          'grade': grade,
          'rows': rows.sublist(offset, end),
        });
        checkIdentity();
        chunks['$index'] = result;
        ledger['chunks'] = chunks;
        if (!await prefs.setString(key, jsonEncode(ledger))) {
          throw StateError(
            'Chunk $index was confirmed but its progress could not be persisted. Retry the same import to resolve its receipt.',
          );
        }
      }
      checkIdentity();
      imported += (result['imported'] as num).toInt();
      for (final row in result['rejectedDetails'] as List? ?? const []) {
        final error = Map<String, dynamic>.from(row as Map);
        error['rowIndex'] = (error['rowIndex'] as num).toInt() + offset;
        rejected.add(error);
      }
      onProgress?.call(end, rows.length);
      checkIdentity();
    }
    return ImportOutcome(imported, rejected);
  }
}

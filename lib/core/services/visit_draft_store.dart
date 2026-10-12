import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VisitDraftStore {
  static const String _prefix = 'visit_drafts_';

  Future<void> saveDraft(String userId, Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts(userId);

    final id =
        draft['id'] ?? draft['operationId'] ?? DateTime.now().toIso8601String();
    draft['id'] = id;

    drafts.removeWhere((d) => d['id'] == id);
    drafts.add(draft);

    final encoded = jsonEncode(drafts);
    if (!await prefs.setString('$_prefix$userId', encoded)) {
      throw StateError('Could not persist visit draft.');
    }
  }

  Future<List<Map<String, dynamic>>> getDrafts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> removeDraft(String userId, String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts(userId);
    drafts.removeWhere((d) => d['id'] == draftId);

    if (drafts.isEmpty) {
      await prefs.remove('$_prefix$userId');
    } else {
      await prefs.setString('$_prefix$userId', jsonEncode(drafts));
    }
  }

  Future<void> clearDrafts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$userId');
  }
}

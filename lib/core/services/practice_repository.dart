import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_session.dart';

class PracticeRepository {
  static const _sessionsKey = 'tempoflow_practice_sessions';

  List<PracticeSession> _sessions = [];

  // Persistence ---------------------------------------------------------------

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final sessionsJson = prefs.getString(_sessionsKey);
    if (sessionsJson != null) {
      final list = jsonDecode(sessionsJson) as List;
      _sessions = list
          .map((e) => PracticeSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, json);
  }

  // Session methods -----------------------------------------------------------

  List<PracticeSession> get sessions => List.unmodifiable(_sessions);

  List<PracticeSession> sessionsForUser(String userId) {
    return _sessions.where((s) => s.userId == userId).toList();
  }

  PracticeSession? activeSessionForUser(String userId) {
    final matches = _sessions.where(
      (s) => s.userId == userId && s.endAt == null,
    );
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> addSession(PracticeSession session) async {
    _sessions.add(session);
    await _saveSessions();
  }

  Future<void> updateSession(PracticeSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
      await _saveSessions();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions();
  }

  // Daily aggregation ---------------------------------------------------------

  Map<String, int> dailyTotalsForUser(String userId) {
    final totals = <String, int>{};
    for (final s in _sessions) {
      if (s.userId != userId || s.endAt == null) continue;
      final day = _formatDate(s.startAt);
      totals[day] = (totals[day] ?? 0) + s.durationSec;
    }
    return totals;
  }

  int totalSecondsForUser(String userId) {
    return _sessions
        .where((s) => s.userId == userId && s.endAt != null)
        .fold<int>(0, (sum, s) => sum + s.durationSec);
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Export ---------------------------------------------------------------------

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'practiceSessions': _sessions.map((s) => s.toJson()).toList(),
    });
  }
}

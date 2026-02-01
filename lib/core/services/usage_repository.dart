import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user.dart';
import '../models/usage_session.dart';

class UsageRepository {
  static const _usersKey = 'tempoflow_users';
  static const _sessionsKey = 'tempoflow_sessions';
  static const _activeUserIdKey = 'tempoflow_active_user_id';

  List<LocalUser> _users = [];
  List<UsageSession> _sessions = [];
  String? _activeUserId;

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final list = jsonDecode(usersJson) as List;
      _users =
          list.map((e) => LocalUser.fromJson(e as Map<String, dynamic>)).toList();
    }

    final sessionsJson = prefs.getString(_sessionsKey);
    if (sessionsJson != null) {
      final list = jsonDecode(sessionsJson) as List;
      _sessions = list
          .map((e) => UsageSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _activeUserId = prefs.getString(_activeUserIdKey);
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, json);
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, json);
  }

  // ---------------------------------------------------------------------------
  // User methods
  // ---------------------------------------------------------------------------

  List<LocalUser> get users => List.unmodifiable(_users);

  LocalUser? get activeUser {
    if (_activeUserId == null) return null;
    final index = _users.indexWhere((u) => u.id == _activeUserId);
    return index >= 0 ? _users[index] : null;
  }

  String? get activeUserId => _activeUserId;

  Future<void> addUser(LocalUser user) async {
    _users.add(user);
    await _saveUsers();
  }

  Future<void> updateUser(LocalUser user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
      await _saveUsers();
    }
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    _sessions.removeWhere((s) => s.userId == userId);
    if (_activeUserId == userId) {
      _activeUserId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeUserIdKey);
    }
    await _saveUsers();
    await _saveSessions();
  }

  Future<void> setActiveUserId(String? id) async {
    _activeUserId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_activeUserIdKey, id);
    } else {
      await prefs.remove(_activeUserIdKey);
    }
  }

  // ---------------------------------------------------------------------------
  // Session methods
  // ---------------------------------------------------------------------------

  List<UsageSession> get sessions => List.unmodifiable(_sessions);

  List<UsageSession> sessionsForUser(String userId) {
    return _sessions.where((s) => s.userId == userId).toList();
  }

  UsageSession? activeSessionForUser(String userId) {
    final matches = _sessions.where(
      (s) => s.userId == userId && s.endAt == null,
    );
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> addSession(UsageSession session) async {
    _sessions.add(session);
    await _saveSessions();
  }

  Future<void> updateSession(UsageSession session) async {
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

  Future<void> cleanupShortSessions({int minDurationSec = 5}) async {
    _sessions.removeWhere(
      (s) => s.endAt != null && s.durationSec < minDurationSec,
    );
    await _saveSessions();
  }

  // ---------------------------------------------------------------------------
  // Daily aggregation
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'users': _users.map((u) => u.toJson()).toList(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
    });
  }
}

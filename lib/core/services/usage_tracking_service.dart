import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/local_user.dart';
import '../models/usage_session.dart';
import 'usage_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UsageTrackingState {
  final LocalUser? activeUser;
  final UsageSession? currentSession;
  final List<LocalUser> users;

  const UsageTrackingState({
    this.activeUser,
    this.currentSession,
    this.users = const [],
  });

  UsageTrackingState copyWith({
    LocalUser? Function()? activeUser,
    UsageSession? Function()? currentSession,
    List<LocalUser>? users,
  }) {
    return UsageTrackingState(
      activeUser: activeUser != null ? activeUser() : this.activeUser,
      currentSession:
          currentSession != null ? currentSession() : this.currentSession,
      users: users ?? this.users,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageTrackingState &&
          activeUser == other.activeUser &&
          currentSession == other.currentSession &&
          _listEquals(users, other.users);

  @override
  int get hashCode =>
      activeUser.hashCode ^ currentSession.hashCode ^ users.hashCode;

  static bool _listEquals(List<LocalUser> a, List<LocalUser> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'UsageTrackingState(activeUser: $activeUser, '
      'currentSession: $currentSession, '
      'users: ${users.length} user(s))';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class UsageTrackingService {
  final UsageRepository _repository;

  final _stateController = StreamController<UsageTrackingState>.broadcast();

  UsageTrackingState _state = const UsageTrackingState();

  /// Tracks when the last session ended so we can debounce rapid
  /// pause/resume cycles (ignores starts within 1 second of the last end).
  DateTime? _lastSessionEndTime;

  UsageTrackingService(this._repository);

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  Stream<UsageTrackingState> get stateStream => _stateController.stream;

  UsageTrackingState get state => _state;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Loads persisted data and restores (or starts) a session for the active
  /// user, if one exists.
  Future<void> initialize() async {
    await _repository.load();

    final activeUser = _repository.activeUser;
    if (activeUser != null) {
      // Try to restore an active session that was never properly ended.
      final existingSession =
          _repository.activeSessionForUser(activeUser.id);

      if (existingSession != null) {
        _emitState();
        debugPrint(
          '[UsageTrackingService] Restored active session '
          '${existingSession.id} for user ${activeUser.displayName}',
        );
      } else {
        // No active session – start a fresh one.
        _emitState();
        startSession();
        debugPrint(
          '[UsageTrackingService] Started new session for '
          'restored user ${activeUser.displayName}',
        );
      }
    } else {
      _emitState();
      debugPrint('[UsageTrackingService] Initialized with no active user');
    }
  }

  /// Cleans up resources. Ends any running session and closes the stream.
  Future<void> dispose() async {
    await endSession();
    await _stateController.close();
  }

  // -------------------------------------------------------------------------
  // User management
  // -------------------------------------------------------------------------

  /// Creates a new [LocalUser], sets it as the active user, and starts a
  /// session. If another user was active, their session is ended first.
  Future<void> createUser(String displayName) async {
    // End the current user's session if one is running.
    await endSession();

    final user = LocalUser.create(displayName: displayName);
    await _repository.addUser(user);
    await _repository.setActiveUserId(user.id);

    _emitState();
    startSession();

    debugPrint(
      '[UsageTrackingService] Created user ${user.displayName} (${user.id})',
    );
  }

  /// Switches the active user to [userId]. Ends the current session (if any),
  /// updates [lastActiveAt] on the target user, and starts a new session.
  Future<void> switchUser(String userId) async {
    // End session for the current user.
    await endSession();

    await _repository.setActiveUserId(userId);

    // Update lastActiveAt on the newly active user.
    final user = _repository.activeUser;
    if (user != null) {
      final updated = user.copyWith(lastActiveAt: DateTime.now());
      await _repository.updateUser(updated);
    }

    _emitState();
    startSession();

    debugPrint(
      '[UsageTrackingService] Switched to user ${user?.displayName} '
      '(${user?.id})',
    );
  }

  /// Deletes the user identified by [userId]. If that user is the active user,
  /// the current session is ended and the active user is cleared.
  Future<void> deleteUser(String userId) async {
    final isActive = _repository.activeUserId == userId;

    if (isActive) {
      await endSession();
      await _repository.setActiveUserId(null);
    }

    await _repository.deleteUser(userId);
    _emitState();

    debugPrint('[UsageTrackingService] Deleted user $userId');
  }

  // -------------------------------------------------------------------------
  // Session management
  // -------------------------------------------------------------------------

  /// Starts a new session for the active user.
  ///
  /// No-ops when:
  /// * There is no active user.
  /// * A session is already running.
  /// * The last session ended less than 1 second ago (debounce).
  void startSession() {
    final activeUser = _repository.activeUser;
    if (activeUser == null) return;

    // Don't start a second session if one is already active.
    final existing = _repository.activeSessionForUser(activeUser.id);
    if (existing != null) return;

    // Debounce: avoid rapid start after a recent end.
    if (_lastSessionEndTime != null) {
      final elapsed = DateTime.now().difference(_lastSessionEndTime!);
      if (elapsed.inMilliseconds < 1000) {
        debugPrint(
          '[UsageTrackingService] startSession debounced '
          '(${elapsed.inMilliseconds}ms since last end)',
        );
        return;
      }
    }

    final session = UsageSession.start(userId: activeUser.id);
    _repository.addSession(session);
    _emitState();

    debugPrint(
      '[UsageTrackingService] Session ${session.id} started for '
      '${activeUser.displayName}',
    );
  }

  /// Ends the current session.
  ///
  /// If the session lasted less than 5 seconds it is deleted rather than
  /// persisted, keeping the data clean.
  Future<void> endSession() async {
    final activeUser = _repository.activeUser;
    if (activeUser == null) return;

    final session = _repository.activeSessionForUser(activeUser.id);
    if (session == null || !session.isActive) return;

    final ended = session.copyWith(endAt: () => DateTime.now());

    if (ended.durationSec < 5) {
      // Session too short – discard it.
      await _repository.deleteSession(ended.id);
      debugPrint(
        '[UsageTrackingService] Discarded short session ${ended.id} '
        '(${ended.durationSec}s)',
      );
    } else {
      await _repository.updateSession(ended);
      debugPrint(
        '[UsageTrackingService] Ended session ${ended.id} '
        '(${ended.durationSec}s)',
      );
    }

    _lastSessionEndTime = DateTime.now();
    _emitState();
  }

  // -------------------------------------------------------------------------
  // App lifecycle hooks
  // -------------------------------------------------------------------------

  /// Should be called when the app transitions to a paused/inactive state.
  Future<void> onAppPaused() async {
    await endSession();
  }

  /// Should be called when the app returns to the foreground.
  Future<void> onAppResumed() async {
    if (_repository.activeUser != null) {
      startSession();
    }
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  /// Builds a fresh [UsageTrackingState] from the repository and pushes it
  /// to listeners.
  void _emitState() {
    final activeUser = _repository.activeUser;

    _state = UsageTrackingState(
      activeUser: activeUser,
      currentSession: activeUser != null
          ? _repository.activeSessionForUser(activeUser.id)
          : null,
      users: _repository.users,
    );

    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }
}

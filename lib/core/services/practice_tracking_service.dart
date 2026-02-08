import 'dart:async';

import 'package:flutter/foundation.dart';

import '../midi/midi_service.dart';
import '../models/practice_session.dart';
import 'practice_repository.dart';
import 'usage_repository.dart';

// State -----------------------------------------------------------------------

class PracticeTrackingState {
  final PracticeSession? currentSession;
  final MidiConnectionState connectionState;
  final List<String> connectedDevices;
  final bool isPlaying;

  const PracticeTrackingState({
    this.currentSession,
    this.connectionState = MidiConnectionState.disconnected,
    this.connectedDevices = const [],
    this.isPlaying = false,
  });

  PracticeTrackingState copyWith({
    PracticeSession? Function()? currentSession,
    MidiConnectionState? connectionState,
    List<String>? connectedDevices,
    bool? isPlaying,
  }) {
    return PracticeTrackingState(
      currentSession:
          currentSession != null ? currentSession() : this.currentSession,
      connectionState: connectionState ?? this.connectionState,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeTrackingState &&
          currentSession == other.currentSession &&
          connectionState == other.connectionState &&
          isPlaying == other.isPlaying &&
          _listEquals(connectedDevices, other.connectedDevices);

  @override
  int get hashCode =>
      currentSession.hashCode ^
      connectionState.hashCode ^
      connectedDevices.hashCode ^
      isPlaying.hashCode;

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'PracticeTrackingState(connectionState: $connectionState, '
      'isPlaying: $isPlaying, '
      'devices: ${connectedDevices.length}, '
      'session: $currentSession)';
}

// Service ---------------------------------------------------------------------

class PracticeTrackingService {
  final PracticeRepository _repository;
  final MidiService _midiService;
  final UsageRepository _usageRepository;

  final _stateController =
      StreamController<PracticeTrackingState>.broadcast();

  PracticeTrackingState _state = const PracticeTrackingState();

  StreamSubscription<MidiConnectionState>? _connectionSub;
  StreamSubscription<MidiNoteEvent>? _noteSub;
  Timer? _idleTimer;

  static const _idleTimeoutSeconds = 10;
  static const _minSessionSeconds = 5;

  PracticeTrackingService(
    this._repository,
    this._midiService,
    this._usageRepository,
  );

  // Public getters ------------------------------------------------------------

  Stream<PracticeTrackingState> get stateStream => _stateController.stream;

  PracticeTrackingState get state => _state;

  // Lifecycle -----------------------------------------------------------------

  Future<void> initialize() async {
    await _repository.load();
    await _midiService.initialize();

    // Listen to MIDI connection changes
    _connectionSub = _midiService.connectionStream.listen(_onConnectionChange);

    // Listen to MIDI note events
    _noteSub = _midiService.noteStream.listen(_onNoteEvent);

    _emitState();

    debugPrint(
      '[PracticeTrackingService] Initialized '
      '(MIDI supported: ${_midiService.isSupported})',
    );
  }

  Future<void> dispose() async {
    _idleTimer?.cancel();
    await _endCurrentSession();
    await _connectionSub?.cancel();
    await _noteSub?.cancel();
    await _stateController.close();
    await _midiService.dispose();
  }

  // App lifecycle hooks -------------------------------------------------------

  Future<void> onAppPaused() async {
    await _endCurrentSession();
  }

  Future<void> onAppResumed() async {
    // Don't auto-start — wait for actual MIDI input
  }

  // Internals -----------------------------------------------------------------

  void _onConnectionChange(MidiConnectionState connectionState) {
    debugPrint(
      '[PracticeTrackingService] Connection: $connectionState',
    );

    if (connectionState == MidiConnectionState.disconnected) {
      // Device disconnected → end any active session immediately
      _endCurrentSession();
    }

    _emitState();
  }

  void _onNoteEvent(MidiNoteEvent event) {
    // Ignore if no active user
    final activeUserId = _usageRepository.activeUserId;
    if (activeUserId == null) return;

    // Only react to note-on events
    if (!event.isNoteOn) return;

    // If no active session, start one
    if (_state.currentSession == null) {
      _startSession(activeUserId);
    }

    // Reset idle timer
    _resetIdleTimer();
  }

  void _startSession(String userId) {
    final session = PracticeSession.start(userId: userId);
    _repository.addSession(session);

    debugPrint(
      '[PracticeTrackingService] Session ${session.id} started',
    );

    _emitState();
  }

  Future<void> _endCurrentSession() async {
    _idleTimer?.cancel();
    _idleTimer = null;

    final activeUserId = _usageRepository.activeUserId;
    if (activeUserId == null) {
      _emitState();
      return;
    }

    final session = _repository.activeSessionForUser(activeUserId);
    if (session == null || !session.isActive) {
      _emitState();
      return;
    }

    final ended = session.copyWith(endAt: () => DateTime.now());

    if (ended.durationSec < _minSessionSeconds) {
      await _repository.deleteSession(ended.id);
      debugPrint(
        '[PracticeTrackingService] Discarded short session ${ended.id} '
        '(${ended.durationSec}s)',
      );
    } else {
      await _repository.updateSession(ended);
      debugPrint(
        '[PracticeTrackingService] Ended session ${ended.id} '
        '(${ended.durationSec}s)',
      );
    }

    _emitState();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      const Duration(seconds: _idleTimeoutSeconds),
      () {
        debugPrint('[PracticeTrackingService] Idle timeout reached');
        _endCurrentSession();
      },
    );
  }

  void _emitState() {
    final activeUserId = _usageRepository.activeUserId;

    final currentSession = activeUserId != null
        ? _repository.activeSessionForUser(activeUserId)
        : null;

    // Determine connection state from the MIDI service
    MidiConnectionState connectionState;
    if (!_midiService.isSupported) {
      connectionState = MidiConnectionState.unsupported;
    } else if (_midiService.connectedDevices.isNotEmpty) {
      connectionState = MidiConnectionState.connected;
    } else {
      connectionState = MidiConnectionState.disconnected;
    }

    _state = PracticeTrackingState(
      currentSession: currentSession,
      connectionState: connectionState,
      connectedDevices: _midiService.connectedDevices,
      isPlaying: currentSession?.isActive ?? false,
    );

    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }
}

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sound_type.dart';
import 'audio_engine.dart';

/// Native audio engine using platform MethodChannel.
/// Falls back to a Dart-based timer scheduler with audioplayers when native plugin is unavailable.
class NativeAudioEngine implements AudioEngine {
  static const _channel = MethodChannel('com.tempoflow/audio_engine');
  final _beatController = StreamController<BeatEvent>.broadcast();
  bool _isPlaying = false;
  bool _hasNativePlugin = false;

  // Dart fallback scheduler state
  Timer? _fallbackTimer;
  final Stopwatch _stopwatch = Stopwatch();
  double _nextNoteTime = 0.0;
  int _bpm = 120;
  int _beatsPerBar = 4;
  int _subdivision = 1;
  int _currentBeat = 0;
  int _currentSubBeat = 0;
  List<double> _accentPattern = [1.0, 0.7, 0.7, 0.7];

  // Audio players pool for fallback mode
  SoundType _soundType = SoundType.click;
  double _masterVolume = 0.8;
  double _accentVolume = 1.0;
  double _subdivisionVolume = 0.5;
  final List<AudioPlayer> _playerPool = [];
  int _playerIndex = 0;
  static const _poolSize = 4;

  NativeAudioEngine() {
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'onBeat':
        final args = call.arguments as Map;
        _beatController.add(BeatEvent(
          beat: args['beat'] as int,
          subBeat: args['subBeat'] as int,
          type: BeatType.values[args['type'] as int],
          scheduledTime: (args['time'] as num).toDouble(),
        ));
        break;
    }
  }

  @override
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      _hasNativePlugin = true;
    } on MissingPluginException {
      debugPrint('Native audio plugin not available, using audioplayers fallback');
      _hasNativePlugin = false;
      // Create player pool for low-latency playback
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        _playerPool.add(player);
      }
    }
  }

  @override
  Future<void> dispose() async {
    stop();
    if (_hasNativePlugin) {
      try {
        await _channel.invokeMethod('dispose');
      } on MissingPluginException {
        // ignore
      }
    }
    for (final player in _playerPool) {
      await player.dispose();
    }
    _playerPool.clear();
    await _beatController.close();
  }

  @override
  Future<void> loadSound(SoundType type) async {
    _soundType = type;
    if (!_hasNativePlugin) return;
    try {
      await _channel.invokeMethod('loadSound', {
        'normal': type.assetPath,
        'accent': type.accentAssetPath,
      });
    } on MissingPluginException {
      // ignore
    }
  }

  @override
  void start({
    required int bpm,
    required int beatsPerBar,
    required int subdivision,
    required List<double> accentPattern,
    required SoundType soundType,
    required double masterVolume,
    required double accentVolume,
    required double subdivisionVolume,
  }) {
    _bpm = bpm;
    _beatsPerBar = beatsPerBar;
    _subdivision = subdivision;
    _accentPattern = accentPattern;
    _soundType = soundType;
    _masterVolume = masterVolume;
    _accentVolume = accentVolume;
    _subdivisionVolume = subdivisionVolume;
    _isPlaying = true;

    if (_hasNativePlugin) {
      _channel.invokeMethod('start', {
        'bpm': bpm,
        'beatsPerBar': beatsPerBar,
        'subdivision': subdivision,
        'accentPattern': accentPattern,
        'soundNormal': soundType.assetPath,
        'soundAccent': soundType.accentAssetPath,
        'masterVolume': masterVolume,
        'accentVolume': accentVolume,
        'subdivisionVolume': subdivisionVolume,
      });
    } else {
      _startFallbackScheduler();
    }
  }

  @override
  void stop() {
    _isPlaying = false;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _stopwatch.stop();
    _stopwatch.reset();
    if (_hasNativePlugin) {
      _channel.invokeMethod('stop');
    }
  }

  void _startFallbackScheduler() {
    _currentBeat = 0;
    _currentSubBeat = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _nextNoteTime = 0.05; // slight initial delay

    _fallbackTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _fallbackTick(),
    );
  }

  void _fallbackTick() {
    if (!_isPlaying) return;
    final now = _stopwatch.elapsedMicroseconds / 1000000.0;

    while (_nextNoteTime <= now + 0.01) {
      final isMainBeat = _currentSubBeat == 0;
      final isAccent = isMainBeat &&
          _currentBeat < _accentPattern.length &&
          _accentPattern[_currentBeat] >= 0.9;

      final beatType = isAccent
          ? BeatType.accent
          : isMainBeat
              ? BeatType.normal
              : BeatType.subdivision;

      // Play sound
      if (_playerPool.isNotEmpty) {
        final assetPath = isAccent
            ? _soundType.accentAssetPath
            : _soundType.assetPath;
        final volume = isMainBeat
            ? (isAccent ? _masterVolume * _accentVolume : _masterVolume * (_currentBeat < _accentPattern.length ? _accentPattern[_currentBeat] : 0.7))
            : _masterVolume * _subdivisionVolume;
        final player = _playerPool[_playerIndex % _poolSize];
        _playerIndex++;
        player.setVolume(volume.clamp(0.0, 1.0));
        player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
      }

      _beatController.add(BeatEvent(
        beat: _currentBeat,
        subBeat: _currentSubBeat,
        type: beatType,
        scheduledTime: _nextNoteTime,
      ));

      // Advance
      final secondsPerSubBeat = 60.0 / _bpm / _subdivision;
      _nextNoteTime += secondsPerSubBeat;
      _currentSubBeat++;
      if (_currentSubBeat >= _subdivision) {
        _currentSubBeat = 0;
        _currentBeat++;
        if (_currentBeat >= _beatsPerBar) {
          _currentBeat = 0;
        }
      }
    }
  }

  @override
  void updateBpm(int bpm) {
    _bpm = bpm;
    if (_hasNativePlugin) {
      _channel.invokeMethod('updateBpm', {'bpm': bpm});
    }
  }

  @override
  void updateVolume({double? master, double? accent, double? subdivision}) {
    if (master != null) _masterVolume = master;
    if (accent != null) _accentVolume = accent;
    if (subdivision != null) _subdivisionVolume = subdivision;
    if (_hasNativePlugin) {
      _channel.invokeMethod('updateVolume', {
        if (master != null) 'master': master,
        if (accent != null) 'accent': accent,
        if (subdivision != null) 'subdivision': subdivision,
      });
    }
  }

  @override
  void updateBeats({int? beatsPerBar, int? subdivision, List<double>? accentPattern}) {
    if (beatsPerBar != null) _beatsPerBar = beatsPerBar;
    if (subdivision != null) _subdivision = subdivision;
    if (accentPattern != null) _accentPattern = accentPattern;
    if (_currentBeat >= _beatsPerBar) _currentBeat = 0;
    if (_hasNativePlugin) {
      _channel.invokeMethod('updateBeats', {
        if (beatsPerBar != null) 'beatsPerBar': beatsPerBar,
        if (subdivision != null) 'subdivision': subdivision,
        if (accentPattern != null) 'accentPattern': accentPattern,
      });
    }
  }

  @override
  void updateSound(SoundType type) {
    _soundType = type;
    if (_hasNativePlugin) {
      _channel.invokeMethod('updateSound', {
        'normal': type.assetPath,
        'accent': type.accentAssetPath,
      });
    }
  }

  @override
  Stream<BeatEvent> get beatStream => _beatController.stream;

  @override
  bool get isPlaying => _isPlaying;
}

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../models/sound_type.dart';
import 'audio_engine.dart';

class WebAudioEngine implements AudioEngine {
  web.AudioContext? _audioContext;
  final _beatController = StreamController<BeatEvent>.broadcast();
  final Map<String, web.AudioBuffer?> _buffers = {};

  bool _isPlaying = false;
  int _bpm = 120;
  int _beatsPerBar = 4;
  int _subdivision = 1;
  List<double> _accentPattern = [1.0, 0.7, 0.7, 0.7];
  SoundType _soundType = SoundType.click;
  double _masterVolume = 0.8;
  double _accentVolume = 1.0;
  double _subdivisionVolume = 0.5;

  int _currentBeat = 0;
  int _currentSubBeat = 0;
  double _nextNoteTime = 0.0;
  int? _schedulerTimerId;

  static const double _scheduleAheadTime = 0.1; // 100ms look-ahead
  static const double _lookaheadMs = 25.0; // 25ms polling

  @override
  Future<void> initialize() async {
    _audioContext = web.AudioContext();
  }

  @override
  Future<void> dispose() async {
    stop();
    await _audioContext?.close().toDart;
    _audioContext = null;
    await _beatController.close();
  }

  @override
  Future<void> loadSound(SoundType type) async {
    final ctx = _audioContext;
    if (ctx == null) return;

    // Load normal and accent sounds
    for (final path in [type.assetPath, type.accentAssetPath]) {
      if (_buffers.containsKey(path)) continue;
      try {
        // Flutter web serves assets under 'assets/' prefix
        final fetchPath = 'assets/$path';
        final response = await web.window.fetch(fetchPath.toJS).toDart;
        final arrayBuffer = await response.arrayBuffer().toDart;
        final audioBuffer = await ctx.decodeAudioData(arrayBuffer).toDart;
        _buffers[path] = audioBuffer;
      } catch (e) {
        debugPrint('Failed to load sound: $path - $e');
      }
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
    final ctx = _audioContext;
    if (ctx == null) return;

    // Resume context if suspended (browser autoplay policy)
    if (ctx.state == 'suspended') {
      ctx.resume();
    }

    _bpm = bpm;
    _beatsPerBar = beatsPerBar;
    _subdivision = subdivision;
    _accentPattern = accentPattern;
    _soundType = soundType;
    _masterVolume = masterVolume;
    _accentVolume = accentVolume;
    _subdivisionVolume = subdivisionVolume;

    _currentBeat = 0;
    _currentSubBeat = 0;
    _isPlaying = true;
    _nextNoteTime = ctx.currentTime + 0.05; // slight delay to start

    _startScheduler();
  }

  void _startScheduler() {
    _schedulerTimerId = web.window.setInterval(
      _scheduler.toJS,
      _lookaheadMs.toInt().toJS,
    );
  }

  void _scheduler() {
    final ctx = _audioContext;
    if (ctx == null || !_isPlaying) return;

    while (_nextNoteTime < ctx.currentTime + _scheduleAheadTime) {
      _scheduleNote(_nextNoteTime);
      _advanceBeat();
    }
  }

  void _scheduleNote(double time) {
    final ctx = _audioContext;
    if (ctx == null) return;

    final isMainBeat = _currentSubBeat == 0;
    final isAccent = isMainBeat && _currentBeat < _accentPattern.length && _accentPattern[_currentBeat] >= 0.9;

    BeatType beatType;
    double volume;
    String assetPath;

    if (isMainBeat) {
      if (isAccent) {
        beatType = BeatType.accent;
        volume = _masterVolume * _accentVolume;
        assetPath = _soundType.accentAssetPath;
      } else {
        beatType = BeatType.normal;
        final weight = _currentBeat < _accentPattern.length ? _accentPattern[_currentBeat] : 0.7;
        volume = _masterVolume * weight;
        assetPath = _soundType.assetPath;
      }
    } else {
      beatType = BeatType.subdivision;
      volume = _masterVolume * _subdivisionVolume;
      assetPath = _soundType.assetPath;
    }

    final buffer = _buffers[assetPath];
    if (buffer != null) {
      final source = ctx.createBufferSource();
      source.buffer = buffer;

      final gainNode = ctx.createGain();
      gainNode.gain.setValueAtTime(volume, time);

      source.connect(gainNode);
      gainNode.connect(ctx.destination);
      source.start(time);
    }

    _beatController.add(BeatEvent(
      beat: _currentBeat,
      subBeat: _currentSubBeat,
      type: beatType,
      scheduledTime: time,
    ));
  }

  void _advanceBeat() {
    final secondsPerBeat = 60.0 / _bpm;
    final secondsPerSubBeat = secondsPerBeat / _subdivision;

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

  @override
  void stop() {
    _isPlaying = false;
    if (_schedulerTimerId != null) {
      web.window.clearInterval(_schedulerTimerId!);
      _schedulerTimerId = null;
    }
  }

  @override
  void updateBpm(int bpm) {
    _bpm = bpm;
  }

  @override
  void updateVolume({double? master, double? accent, double? subdivision}) {
    if (master != null) _masterVolume = master;
    if (accent != null) _accentVolume = accent;
    if (subdivision != null) _subdivisionVolume = subdivision;
  }

  @override
  void updateBeats({int? beatsPerBar, int? subdivision, List<double>? accentPattern}) {
    if (beatsPerBar != null) _beatsPerBar = beatsPerBar;
    if (subdivision != null) _subdivision = subdivision;
    if (accentPattern != null) _accentPattern = accentPattern;
    // Reset beat position to avoid out of bounds
    if (_currentBeat >= _beatsPerBar) _currentBeat = 0;
  }

  @override
  void updateSound(SoundType type) {
    _soundType = type;
  }

  @override
  Stream<BeatEvent> get beatStream => _beatController.stream;

  @override
  bool get isPlaying => _isPlaying;
}

import 'dart:async';

import 'package:flutter/services.dart';

import '../models/sound_type.dart';
import 'audio_engine.dart';

class NativeAudioEngine implements AudioEngine {
  static const _channel = MethodChannel('com.tempoflow/audio_engine');
  final _beatController = StreamController<BeatEvent>.broadcast();
  bool _isPlaying = false;

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
    await _channel.invokeMethod('initialize');
  }

  @override
  Future<void> dispose() async {
    stop();
    await _channel.invokeMethod('dispose');
    await _beatController.close();
  }

  @override
  Future<void> loadSound(SoundType type) async {
    await _channel.invokeMethod('loadSound', {
      'normal': type.assetPath,
      'accent': type.accentAssetPath,
    });
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
    _isPlaying = true;
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
  }

  @override
  void stop() {
    _isPlaying = false;
    _channel.invokeMethod('stop');
  }

  @override
  void updateBpm(int bpm) {
    _channel.invokeMethod('updateBpm', {'bpm': bpm});
  }

  @override
  void updateVolume({double? master, double? accent, double? subdivision}) {
    _channel.invokeMethod('updateVolume', {
      if (master != null) 'master': master,
      if (accent != null) 'accent': accent,
      if (subdivision != null) 'subdivision': subdivision,
    });
  }

  @override
  void updateBeats({int? beatsPerBar, int? subdivision, List<double>? accentPattern}) {
    _channel.invokeMethod('updateBeats', {
      if (beatsPerBar != null) 'beatsPerBar': beatsPerBar,
      if (subdivision != null) 'subdivision': subdivision,
      if (accentPattern != null) 'accentPattern': accentPattern,
    });
  }

  @override
  void updateSound(SoundType type) {
    _channel.invokeMethod('updateSound', {
      'normal': type.assetPath,
      'accent': type.accentAssetPath,
    });
  }

  @override
  Stream<BeatEvent> get beatStream => _beatController.stream;

  @override
  bool get isPlaying => _isPlaying;
}

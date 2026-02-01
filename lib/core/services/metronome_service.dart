import 'dart:async';

import '../audio/audio_engine.dart';
import '../audio/audio_engine_factory.dart';
import '../models/metronome_state.dart';
import '../models/sound_type.dart';
import '../models/time_signature.dart';
import '../models/accent_pattern.dart';
import '../models/visual_mode.dart';

class MetronomeService {
  late final AudioEngine _engine;
  final _stateController = StreamController<MetronomeState>.broadcast();
  MetronomeState _state = const MetronomeState();
  StreamSubscription<BeatEvent>? _beatSubscription;
  int _barBeatCount = 0;

  // Callback for bar completion (used by speed trainer)
  void Function()? onBarComplete;

  MetronomeService() {
    _engine = createPlatformAudioEngine();
  }

  MetronomeState get state => _state;
  Stream<MetronomeState> get stateStream => _stateController.stream;

  Future<void> initialize() async {
    await _engine.initialize();
    await _engine.loadSound(_state.soundType);
    _beatSubscription = _engine.beatStream.listen(_onBeat);
  }

  Future<void> dispose() async {
    _beatSubscription?.cancel();
    await _engine.dispose();
    await _stateController.close();
  }

  void _onBeat(BeatEvent event) {
    _state = _state.copyWith(
      currentBeat: event.beat,
      currentSubBeat: event.subBeat,
    );
    _stateController.add(_state);

    // Track bar completion
    if (event.subBeat == 0 && event.beat == 0 && _barBeatCount > 0) {
      onBarComplete?.call();
    }
    if (event.subBeat == 0) {
      _barBeatCount++;
    }
  }

  void togglePlayback() {
    if (_state.isPlaying) {
      stop();
    } else {
      play();
    }
  }

  void play() {
    _barBeatCount = 0;
    _engine.start(
      bpm: _state.bpm,
      beatsPerBar: _state.timeSignature.beatsPerBar,
      subdivision: _state.subdivision,
      accentPattern: _state.accentEnabled ? _state.accentPattern.weights : List.filled(_state.timeSignature.beatsPerBar, 0.7),
      soundType: _state.soundType,
      masterVolume: _state.masterVolume,
      accentVolume: _state.accentVolume,
      subdivisionVolume: _state.subdivisionVolume,
    );
    _state = _state.copyWith(isPlaying: true, currentBeat: 0, currentSubBeat: 0);
    _stateController.add(_state);
  }

  void stop() {
    _engine.stop();
    _state = _state.copyWith(isPlaying: false, currentBeat: 0, currentSubBeat: 0);
    _stateController.add(_state);
  }

  void setBpm(int bpm) {
    bpm = bpm.clamp(20, 300);
    _state = _state.copyWith(bpm: bpm);
    if (_state.isPlaying) {
      _engine.updateBpm(bpm);
    }
    _stateController.add(_state);
  }

  void setTimeSignature(TimeSignature ts) {
    final newPattern = _state.accentPattern.resize(ts.beatsPerBar);
    _state = _state.copyWith(
      timeSignature: ts,
      accentPattern: newPattern,
    );
    if (_state.isPlaying) {
      _engine.updateBeats(
        beatsPerBar: ts.beatsPerBar,
        accentPattern: newPattern.weights,
      );
    }
    _stateController.add(_state);
  }

  void setSubdivision(int subdivision) {
    subdivision = subdivision.clamp(1, 4);
    _state = _state.copyWith(subdivision: subdivision);
    if (_state.isPlaying) {
      _engine.updateBeats(subdivision: subdivision);
    }
    _stateController.add(_state);
  }

  void setAccentEnabled(bool enabled) {
    _state = _state.copyWith(accentEnabled: enabled);
    if (_state.isPlaying) {
      _engine.updateBeats(
        accentPattern: enabled
            ? _state.accentPattern.weights
            : List.filled(_state.timeSignature.beatsPerBar, 0.7),
      );
    }
    _stateController.add(_state);
  }

  void setAccentPattern(AccentPattern pattern) {
    _state = _state.copyWith(accentPattern: pattern);
    if (_state.isPlaying && _state.accentEnabled) {
      _engine.updateBeats(accentPattern: pattern.weights);
    }
    _stateController.add(_state);
  }

  void setAccentWeight(int beat, double weight) {
    final newPattern = _state.accentPattern.withWeight(beat, weight);
    setAccentPattern(newPattern);
  }

  Future<void> setSoundType(SoundType type) async {
    await _engine.loadSound(type);
    _state = _state.copyWith(soundType: type);
    if (_state.isPlaying) {
      _engine.updateSound(type);
    }
    _stateController.add(_state);
  }

  void setMasterVolume(double volume) {
    _state = _state.copyWith(masterVolume: volume.clamp(0.0, 1.0));
    if (_state.isPlaying) {
      _engine.updateVolume(master: _state.masterVolume);
    }
    _stateController.add(_state);
  }

  void setAccentVolume(double volume) {
    _state = _state.copyWith(accentVolume: volume.clamp(0.0, 1.0));
    if (_state.isPlaying) {
      _engine.updateVolume(accent: _state.accentVolume);
    }
    _stateController.add(_state);
  }

  void setSubdivisionVolume(double volume) {
    _state = _state.copyWith(subdivisionVolume: volume.clamp(0.0, 1.0));
    if (_state.isPlaying) {
      _engine.updateVolume(subdivision: _state.subdivisionVolume);
    }
    _stateController.add(_state);
  }

  void setVisualMode(VisualMode mode) {
    _state = _state.copyWith(visualMode: mode);
    _stateController.add(_state);
  }

  void setVibration(bool enabled) {
    _state = _state.copyWith(vibrationEnabled: enabled);
    _stateController.add(_state);
  }
}

import 'sound_type.dart';
import 'visual_mode.dart';
import 'time_signature.dart';
import 'accent_pattern.dart';

class MetronomeState {
  final int bpm;
  final TimeSignature timeSignature;
  final int subdivision;
  final bool accentEnabled;
  final AccentPattern accentPattern;
  final SoundType soundType;
  final double masterVolume;
  final double accentVolume;
  final double subdivisionVolume;
  final VisualMode visualMode;
  final bool vibrationEnabled;
  final bool isPlaying;
  final int currentBeat;
  final int currentSubBeat;

  const MetronomeState({
    this.bpm = 120,
    this.timeSignature = const TimeSignature(),
    this.subdivision = 1,
    this.accentEnabled = true,
    this.accentPattern = const AccentPattern([1.0, 0.7, 0.7, 0.7]),
    this.soundType = SoundType.click,
    this.masterVolume = 0.8,
    this.accentVolume = 1.0,
    this.subdivisionVolume = 0.5,
    this.visualMode = VisualMode.led,
    this.vibrationEnabled = false,
    this.isPlaying = false,
    this.currentBeat = 0,
    this.currentSubBeat = 0,
  });

  double get beatInterval => 60.0 / bpm;
  double get subBeatInterval => beatInterval / subdivision;

  MetronomeState copyWith({
    int? bpm,
    TimeSignature? timeSignature,
    int? subdivision,
    bool? accentEnabled,
    AccentPattern? accentPattern,
    SoundType? soundType,
    double? masterVolume,
    double? accentVolume,
    double? subdivisionVolume,
    VisualMode? visualMode,
    bool? vibrationEnabled,
    bool? isPlaying,
    int? currentBeat,
    int? currentSubBeat,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      subdivision: subdivision ?? this.subdivision,
      accentEnabled: accentEnabled ?? this.accentEnabled,
      accentPattern: accentPattern ?? this.accentPattern,
      soundType: soundType ?? this.soundType,
      masterVolume: masterVolume ?? this.masterVolume,
      accentVolume: accentVolume ?? this.accentVolume,
      subdivisionVolume: subdivisionVolume ?? this.subdivisionVolume,
      visualMode: visualMode ?? this.visualMode,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
      currentBeat: currentBeat ?? this.currentBeat,
      currentSubBeat: currentSubBeat ?? this.currentSubBeat,
    );
  }
}

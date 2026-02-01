import 'sound_type.dart';
import 'visual_mode.dart';
import 'time_signature.dart';
import 'accent_pattern.dart';

class Preset {
  final String id;
  final String name;
  final int bpm;
  final TimeSignature timeSignature;
  final int subdivision;
  final bool accentEnabled;
  final AccentPattern accentPattern;
  final SoundType soundType;
  final VisualMode visualMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Preset({
    required this.id,
    required this.name,
    required this.bpm,
    this.timeSignature = const TimeSignature(),
    this.subdivision = 1,
    this.accentEnabled = true,
    AccentPattern? accentPattern,
    this.soundType = SoundType.click,
    this.visualMode = VisualMode.led,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : accentPattern = accentPattern ?? AccentPattern.standard(timeSignature.beatsPerBar),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bpm': bpm,
    'timeSignature': timeSignature.toJson(),
    'subdivision': subdivision,
    'accentEnabled': accentEnabled,
    'accentPattern': accentPattern.toJson(),
    'soundType': soundType.name,
    'visualMode': visualMode.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
    id: json['id'] as String,
    name: json['name'] as String,
    bpm: json['bpm'] as int,
    timeSignature: TimeSignature.fromJson(json['timeSignature'] as Map<String, dynamic>),
    subdivision: json['subdivision'] as int? ?? 1,
    accentEnabled: json['accentEnabled'] as bool? ?? true,
    accentPattern: AccentPattern.fromJson(json['accentPattern'] as List<dynamic>),
    soundType: SoundType.values.byName(json['soundType'] as String? ?? 'click'),
    visualMode: VisualMode.values.byName(json['visualMode'] as String? ?? 'led'),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

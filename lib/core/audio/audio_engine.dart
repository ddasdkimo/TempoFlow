import '../models/sound_type.dart';

enum BeatType { accent, normal, subdivision }

abstract class AudioEngine {
  Future<void> initialize();
  Future<void> dispose();
  Future<void> loadSound(SoundType type);
  void start({
    required int bpm,
    required int beatsPerBar,
    required int subdivision,
    required List<double> accentPattern,
    required SoundType soundType,
    required double masterVolume,
    required double accentVolume,
    required double subdivisionVolume,
  });
  void stop();
  void updateBpm(int bpm);
  void updateVolume({double? master, double? accent, double? subdivision});
  void updateBeats({
    int? beatsPerBar,
    int? subdivision,
    List<double>? accentPattern,
  });
  void updateSound(SoundType type);
  Stream<BeatEvent> get beatStream;
  bool get isPlaying;
}

class BeatEvent {
  final int beat;
  final int subBeat;
  final BeatType type;
  final double scheduledTime;

  const BeatEvent({
    required this.beat,
    required this.subBeat,
    required this.type,
    required this.scheduledTime,
  });
}

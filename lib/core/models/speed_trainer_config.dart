enum TrainerEndMode { stop, loop }

class SpeedTrainerConfig {
  final int startBpm;
  final int targetBpm;
  final int incrementBpm;
  final int barsPerStep;
  final TrainerEndMode endMode;
  final bool playSoundOnComplete;

  const SpeedTrainerConfig({
    this.startBpm = 60,
    this.targetBpm = 120,
    this.incrementBpm = 5,
    this.barsPerStep = 4,
    this.endMode = TrainerEndMode.stop,
    this.playSoundOnComplete = true,
  });

  int get totalSteps => ((targetBpm - startBpm) / incrementBpm).ceil() + 1;

  int bpmAtStep(int step) {
    final bpm = startBpm + (step * incrementBpm);
    return bpm.clamp(startBpm, targetBpm);
  }

  SpeedTrainerConfig copyWith({
    int? startBpm,
    int? targetBpm,
    int? incrementBpm,
    int? barsPerStep,
    TrainerEndMode? endMode,
    bool? playSoundOnComplete,
  }) {
    return SpeedTrainerConfig(
      startBpm: startBpm ?? this.startBpm,
      targetBpm: targetBpm ?? this.targetBpm,
      incrementBpm: incrementBpm ?? this.incrementBpm,
      barsPerStep: barsPerStep ?? this.barsPerStep,
      endMode: endMode ?? this.endMode,
      playSoundOnComplete: playSoundOnComplete ?? this.playSoundOnComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'startBpm': startBpm,
    'targetBpm': targetBpm,
    'incrementBpm': incrementBpm,
    'barsPerStep': barsPerStep,
    'endMode': endMode.name,
    'playSoundOnComplete': playSoundOnComplete,
  };

  factory SpeedTrainerConfig.fromJson(Map<String, dynamic> json) => SpeedTrainerConfig(
    startBpm: json['startBpm'] as int? ?? 60,
    targetBpm: json['targetBpm'] as int? ?? 120,
    incrementBpm: json['incrementBpm'] as int? ?? 5,
    barsPerStep: json['barsPerStep'] as int? ?? 4,
    endMode: TrainerEndMode.values.byName(json['endMode'] as String? ?? 'stop'),
    playSoundOnComplete: json['playSoundOnComplete'] as bool? ?? true,
  );
}

import '../models/speed_trainer_config.dart';

class SpeedTrainerState {
  final int currentStep;
  final int currentBpm;
  final int currentBar;
  final bool isActive;
  final bool isComplete;

  const SpeedTrainerState({
    this.currentStep = 0,
    this.currentBpm = 60,
    this.currentBar = 0,
    this.isActive = false,
    this.isComplete = false,
  });

  SpeedTrainerState copyWith({
    int? currentStep,
    int? currentBpm,
    int? currentBar,
    bool? isActive,
    bool? isComplete,
  }) {
    return SpeedTrainerState(
      currentStep: currentStep ?? this.currentStep,
      currentBpm: currentBpm ?? this.currentBpm,
      currentBar: currentBar ?? this.currentBar,
      isActive: isActive ?? this.isActive,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  double progressPercent(SpeedTrainerConfig config) {
    if (config.totalSteps <= 1) return 1.0;
    return currentStep / (config.totalSteps - 1);
  }
}

class SpeedTrainerService {
  SpeedTrainerConfig _config;
  SpeedTrainerState _state = const SpeedTrainerState();

  SpeedTrainerService({SpeedTrainerConfig? config})
      : _config = config ?? const SpeedTrainerConfig();

  SpeedTrainerConfig get config => _config;
  SpeedTrainerState get state => _state;

  void configure(SpeedTrainerConfig config) {
    _config = config;
    _state = SpeedTrainerState(
      currentBpm: config.startBpm,
    );
  }

  void start() {
    _state = SpeedTrainerState(
      currentBpm: _config.startBpm,
      currentStep: 0,
      currentBar: 0,
      isActive: true,
      isComplete: false,
    );
  }

  void stop() {
    _state = _state.copyWith(isActive: false);
  }

  /// Called when a bar completes. Returns the new BPM if changed, null otherwise.
  int? onBarComplete() {
    if (!_state.isActive || _state.isComplete) return null;

    final newBar = _state.currentBar + 1;

    if (newBar >= _config.barsPerStep) {
      // Advance to next step
      final nextStep = _state.currentStep + 1;
      final nextBpm = _config.bpmAtStep(nextStep);

      if (nextBpm >= _config.targetBpm) {
        // Reached target
        if (_config.endMode == TrainerEndMode.loop) {
          _state = SpeedTrainerState(
            currentStep: 0,
            currentBpm: _config.startBpm,
            currentBar: 0,
            isActive: true,
          );
          return _config.startBpm;
        } else {
          _state = _state.copyWith(
            currentBpm: _config.targetBpm,
            isComplete: true,
          );
          return null;
        }
      }

      _state = SpeedTrainerState(
        currentStep: nextStep,
        currentBpm: nextBpm,
        currentBar: 0,
        isActive: true,
      );
      return nextBpm;
    } else {
      _state = _state.copyWith(currentBar: newBar);
      return null;
    }
  }
}

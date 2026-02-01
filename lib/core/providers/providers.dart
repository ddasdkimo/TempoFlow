import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/metronome_service.dart';
import '../services/preset_service.dart';
import '../services/tap_tempo_service.dart';
import '../services/speed_trainer_service.dart';
import '../models/metronome_state.dart';

final metronomeServiceProvider = Provider<MetronomeService>((ref) {
  final service = MetronomeService();
  ref.onDispose(() => service.dispose());
  return service;
});

final presetServiceProvider = Provider<PresetService>((ref) {
  return PresetService();
});

final tapTempoServiceProvider = Provider<TapTempoService>((ref) {
  return TapTempoService();
});

final speedTrainerServiceProvider = Provider<SpeedTrainerService>((ref) {
  return SpeedTrainerService();
});

final metronomeStateProvider = StreamProvider<MetronomeState>((ref) {
  final service = ref.watch(metronomeServiceProvider);
  return service.stateStream;
});

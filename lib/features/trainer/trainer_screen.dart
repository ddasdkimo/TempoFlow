import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/models/speed_trainer_config.dart';

class TrainerScreen extends ConsumerStatefulWidget {
  const TrainerScreen({super.key});

  @override
  ConsumerState<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends ConsumerState<TrainerScreen> {
  var _config = const SpeedTrainerConfig();

  @override
  Widget build(BuildContext context) {
    final speedTrainer = ref.watch(speedTrainerServiceProvider);
    final metronome = ref.watch(metronomeServiceProvider);
    final trainerState = speedTrainer.state;

    return Scaffold(
      appBar: AppBar(title: const Text('加速訓練')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start BPM
            _buildSliderRow(
              label: '起始 BPM',
              value: _config.startBpm,
              min: 20,
              max: 280,
              onChanged: (v) => setState(() {
                _config = _config.copyWith(startBpm: v);
              }),
            ),
            const SizedBox(height: 16),
            // Target BPM
            _buildSliderRow(
              label: '目標 BPM',
              value: _config.targetBpm,
              min: _config.startBpm + 10,
              max: 300,
              onChanged: (v) => setState(() {
                _config = _config.copyWith(targetBpm: v);
              }),
            ),
            const SizedBox(height: 16),
            // Increment
            _buildSliderRow(
              label: '每次增量',
              value: _config.incrementBpm,
              min: 1,
              max: 20,
              onChanged: (v) => setState(() {
                _config = _config.copyWith(incrementBpm: v);
              }),
            ),
            const SizedBox(height: 16),
            // Bars per step
            _buildSliderRow(
              label: '每段小節數',
              value: _config.barsPerStep,
              min: 1,
              max: 16,
              onChanged: (v) => setState(() {
                _config = _config.copyWith(barsPerStep: v);
              }),
            ),
            const SizedBox(height: 16),
            // End mode
            Row(
              children: [
                const Text('結束模式：', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('停止'),
                  selected: _config.endMode == TrainerEndMode.stop,
                  onSelected: (_) => setState(() {
                    _config = _config.copyWith(endMode: TrainerEndMode.stop);
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('循環'),
                  selected: _config.endMode == TrainerEndMode.loop,
                  onSelected: (_) => setState(() {
                    _config = _config.copyWith(endMode: TrainerEndMode.loop);
                  }),
                ),
              ],
            ),
            const Spacer(),
            // Progress
            if (trainerState.isActive) ...[
              LinearProgressIndicator(
                value: trainerState.progressPercent(_config),
                backgroundColor: Colors.white12,
              ),
              const SizedBox(height: 8),
              Text(
                '目前 ${trainerState.currentBpm} BPM  (${trainerState.currentStep + 1}/${_config.totalSteps})',
                style: const TextStyle(color: Colors.white70),
              ),
              if (trainerState.isComplete)
                const Text(
                  '訓練完成！',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 16),
            ],
            // Start/Stop button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(trainerState.isActive ? Icons.stop : Icons.play_arrow),
                label: Text(trainerState.isActive ? '停止訓練' : '開始訓練'),
                onPressed: () {
                  if (trainerState.isActive) {
                    speedTrainer.stop();
                    metronome.stop();
                  } else {
                    speedTrainer.configure(_config);
                    speedTrainer.start();
                    metronome.setBpm(_config.startBpm);
                    metronome.onBarComplete = () {
                      final newBpm = speedTrainer.onBarComplete();
                      if (newBpm != null) {
                        metronome.setBpm(newBpm);
                      }
                    };
                    metronome.play();
                  }
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

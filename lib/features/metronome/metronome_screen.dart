import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../features/presets/preset_screen.dart';
import '../../features/trainer/trainer_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stage/stage_mode_screen.dart';
import 'widgets/bpm_control.dart';
import 'widgets/beat_indicator.dart';
import 'widgets/time_signature_picker.dart';
import 'widgets/subdivision_selector.dart';
import 'widgets/accent_editor.dart';
import 'widgets/tap_tempo_button.dart';

class MetronomeScreen extends ConsumerStatefulWidget {
  const MetronomeScreen({super.key});

  @override
  ConsumerState<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends ConsumerState<MetronomeScreen> {
  @override
  Widget build(BuildContext context) {
    final service = ref.watch(metronomeServiceProvider);
    final asyncState = ref.watch(metronomeStateProvider);
    final state = asyncState.valueOrNull ?? service.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TempoFlow'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: '舞台模式',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StageModeScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'presets':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PresetScreen()));
                  break;
                case 'trainer':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TrainerScreen()));
                  break;
                case 'settings':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'presets', child: Text('Presets')),
              const PopupMenuItem(value: 'trainer', child: Text('加速訓練')),
              const PopupMenuItem(value: 'settings', child: Text('設定')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = [
              const SizedBox(height: 16),
              // Beat indicator
              BeatIndicator(
                beatsPerBar: state.timeSignature.beatsPerBar,
                currentBeat: state.currentBeat,
                isPlaying: state.isPlaying,
                accentPattern: state.accentPattern,
              ),
              const SizedBox(height: 24),
              // BPM Control
              BpmControl(
                bpm: state.bpm,
                onBpmChanged: (bpm) => service.setBpm(bpm),
              ),
              const SizedBox(height: 16),
              // Time signature & subdivision row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TimeSignaturePicker(
                        timeSignature: state.timeSignature,
                        onChanged: (ts) => service.setTimeSignature(ts),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SubdivisionSelector(
                        subdivision: state.subdivision,
                        onChanged: (s) => service.setSubdivision(s),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Accent editor
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AccentEditor(
                  accentPattern: state.accentPattern,
                  accentEnabled: state.accentEnabled,
                  onEnabledChanged: (e) => service.setAccentEnabled(e),
                  onWeightChanged: (beat, weight) =>
                      service.setAccentWeight(beat, weight),
                ),
              ),
              const SizedBox(height: 24),
              // Play/Stop button and Tap Tempo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TapTempoButton(
                      onBpmDetected: (bpm) => service.setBpm(bpm),
                    ),
                    const SizedBox(width: 24),
                    _PlayButton(
                      isPlaying: state.isPlaying,
                      onPressed: () => service.togglePlayback(),
                    ),
                    const SizedBox(width: 24),
                    const SizedBox(width: 64), // balance
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ];

            // Use scrollable layout when space is tight (landscape)
            if (constraints.maxHeight < 500) {
              return SingleChildScrollView(
                child: Column(children: content),
              );
            }

            // Normal portrait: let BPM control expand
            return Column(
              children: [
                content[0], // SizedBox(16)
                content[1], // BeatIndicator
                content[2], // SizedBox(24)
                Expanded(child: content[3]), // BpmControl
                ...content.skip(4),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayButton({required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}

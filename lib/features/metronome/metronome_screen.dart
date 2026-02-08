import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/midi/midi_service.dart';
import '../../core/providers/providers.dart';
import '../../features/presets/preset_screen.dart';
import '../../features/trainer/trainer_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stage/stage_mode_screen.dart';
import '../../features/usage/user_avatar_chip.dart';
import '../../features/usage/usage_stats_screen.dart';
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
  MidiConnectionState? _lastMidiState;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(metronomeServiceProvider);
    final asyncState = ref.watch(metronomeStateProvider);
    final state = asyncState.valueOrNull ?? service.state;

    // Listen to MIDI connection changes for snackbar
    final practiceService = ref.watch(practiceTrackingServiceProvider);
    final practiceAsync = ref.watch(practiceTrackingStateProvider);
    final practiceState = practiceAsync.valueOrNull ?? practiceService.state;
    _handleMidiSnackbar(context, practiceState.connectionState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TempoFlow'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Center(child: UserAvatarChip()),
        ),
        leadingWidth: 140,
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
                case 'usage':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UsageStatsScreen()));
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
              const PopupMenuItem(value: 'usage', child: Text('使用統計')),
              const PopupMenuItem(value: 'settings', child: Text('設定')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
            // MIDI connection status chip
            if (practiceState.connectionState == MidiConnectionState.connected ||
                practiceState.isPlaying)
              _MidiStatusChip(
                isPlaying: practiceState.isPlaying,
                devices: practiceState.connectedDevices,
                sessionStartAt: practiceState.currentSession?.startAt,
                onTap: () => _navigateToMidiStats(context),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMidiSnackbar(BuildContext context, MidiConnectionState current) {
    if (_lastMidiState != null &&
        _lastMidiState != MidiConnectionState.connected &&
        current == MidiConnectionState.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('MIDI 鍵盤已連接'),
            backgroundColor: const Color(0xFF0F3460),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(
              label: '查看練習統計',
              textColor: const Color(0xFFB388FF),
              onPressed: () => _navigateToMidiStats(context),
            ),
          ),
        );
      });
    }
    _lastMidiState = current;
  }

  void _navigateToMidiStats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UsageStatsScreen(initialTab: 1),
      ),
    );
  }
}

class _MidiStatusChip extends StatefulWidget {
  final bool isPlaying;
  final List<String> devices;
  final DateTime? sessionStartAt;
  final VoidCallback onTap;

  const _MidiStatusChip({
    required this.isPlaying,
    required this.devices,
    this.sessionStartAt,
    required this.onTap,
  });

  @override
  State<_MidiStatusChip> createState() => _MidiStatusChipState();
}

class _MidiStatusChipState extends State<_MidiStatusChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _startTimer();
  }

  @override
  void didUpdateWidget(covariant _MidiStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startTimer();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isPlaying
        ? '練習中 ${_formatElapsed(widget.sessionStartAt)}'
        : widget.devices.isNotEmpty
            ? widget.devices.first
            : 'MIDI';
    final color = widget.isPlaying
        ? const Color(0xFF7C4DFF)
        : const Color(0xFF66BB6A);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.piano, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
            if (widget.isPlaying) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatElapsed(DateTime? startAt) {
  if (startAt == null) return '0:00';
  final elapsed = DateTime.now().difference(startAt);
  final h = elapsed.inHours;
  final m = elapsed.inMinutes.remainder(60);
  final s = elapsed.inSeconds.remainder(60);
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return '$m:${s.toString().padLeft(2, '0')}';
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

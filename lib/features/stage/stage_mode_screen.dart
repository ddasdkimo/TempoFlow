import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../shared/theme/stage_theme.dart';

class StageModeScreen extends ConsumerStatefulWidget {
  const StageModeScreen({super.key});

  @override
  ConsumerState<StageModeScreen> createState() => _StageModeScreenState();
}

class _StageModeScreenState extends ConsumerState<StageModeScreen> {
  @override
  void initState() {
    super.initState();
    // Force landscape and hide system UI for stage mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    // Keep screen awake - in production use wakelock_plus
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(metronomeServiceProvider);
    final asyncState = ref.watch(metronomeStateProvider);
    final state = asyncState.valueOrNull ?? service.state;
    final primary = StageTheme.accentColor;

    // MIDI practice state
    final practiceService = ref.watch(practiceTrackingServiceProvider);
    final practiceAsync = ref.watch(practiceTrackingStateProvider);
    final practiceState = practiceAsync.valueOrNull ?? practiceService.state;
    final practiceRepo = ref.watch(practiceRepositoryProvider);
    final usageState = ref.watch(usageTrackingStateProvider).valueOrNull ??
        ref.watch(usageTrackingServiceProvider).state;
    final activeUserId = usageState.activeUser?.id;
    final totalPracticeSeconds = activeUserId != null
        ? practiceRepo.totalSecondsForUser(activeUserId)
        : 0;

    return Scaffold(
      backgroundColor: StageTheme.backgroundColor,
      body: GestureDetector(
        onTap: () => service.togglePlayback(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -100) {
              service.setBpm((state.bpm + 1).clamp(20, 300));
            } else if (details.primaryVelocity! > 100) {
              service.setBpm((state.bpm - 1).clamp(20, 300));
            }
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Flash overlay when beat hits
              if (state.isPlaying)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  color: state.currentBeat == 0 &&
                          state.currentSubBeat == 0
                      ? primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time signature
                    Text(
                      state.timeSignature.display,
                      style: StageTheme.labelTextStyle,
                    ),
                    const SizedBox(height: 8),
                    // BPM
                    Text(
                      '${state.bpm}',
                      style: StageTheme.bpmTextStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BPM',
                      style: StageTheme.labelTextStyle,
                    ),
                    const SizedBox(height: 32),
                    // Beat dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        state.timeSignature.beatsPerBar,
                        (i) {
                          final isActive = state.isPlaying && i == state.currentBeat;
                          return Container(
                            width: isActive ? 28 : 20,
                            height: isActive ? 28 : 20,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? primary
                                  : StageTheme.beatInactiveColor,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.6),
                                        blurRadius: 16,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Play state indicator
                    Text(
                      state.isPlaying ? '點擊停止' : '點擊開始',
                      style: StageTheme.labelTextStyle.copyWith(
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
              // Back button
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // MIDI practice timer
              if (practiceState.isPlaying)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _StagePracticeTimer(
                      sessionStartAt: practiceState.currentSession?.startAt,
                      totalPreviousSeconds: totalPracticeSeconds,
                    ),
                  ),
                ),
              // BPM adjust buttons
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: primary, size: 36),
                      onPressed: () => service.setBpm((state.bpm + 1).clamp(20, 300)),
                    ),
                    const SizedBox(height: 24),
                    IconButton(
                      icon: Icon(Icons.remove, color: primary, size: 36),
                      onPressed: () => service.setBpm((state.bpm - 1).clamp(20, 300)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StagePracticeTimer extends StatefulWidget {
  final DateTime? sessionStartAt;
  final int totalPreviousSeconds;

  const _StagePracticeTimer({
    this.sessionStartAt,
    this.totalPreviousSeconds = 0,
  });

  @override
  State<_StagePracticeTimer> createState() => _StagePracticeTimerState();
}

class _StagePracticeTimerState extends State<_StagePracticeTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSec = widget.sessionStartAt != null
        ? DateTime.now().difference(widget.sessionStartAt!).inSeconds
        : 0;
    final total = widget.totalPreviousSeconds + currentSec;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final timeStr = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '$m:${s.toString().padLeft(2, '0')}';

    return Text(
      '練習中 $timeStr',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Color(0xFFB388FF),
      ),
    );
  }
}

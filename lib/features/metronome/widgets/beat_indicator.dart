import 'package:flutter/material.dart';

import '../../../core/models/accent_pattern.dart';

class BeatIndicator extends StatelessWidget {
  final int beatsPerBar;
  final int currentBeat;
  final bool isPlaying;
  final AccentPattern accentPattern;

  const BeatIndicator({
    super.key,
    required this.beatsPerBar,
    required this.currentBeat,
    required this.isPlaying,
    required this.accentPattern,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(beatsPerBar, (i) {
          final isActive = isPlaying && i == currentBeat;
          final isAccent = accentPattern.weightAt(i) >= 0.9;
          final size = isAccent ? 20.0 : 16.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: isActive ? size + 4 : size,
              height: isActive ? size + 4 : size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? primary
                    : (isAccent
                        ? primary.withValues(alpha: 0.3)
                        : Colors.white24),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/models/accent_pattern.dart';

class AccentEditor extends StatelessWidget {
  final AccentPattern accentPattern;
  final bool accentEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final void Function(int beat, double weight) onWeightChanged;

  const AccentEditor({
    super.key,
    required this.accentPattern,
    required this.accentEnabled,
    required this.onEnabledChanged,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        // Toggle
        GestureDetector(
          onTap: () => onEnabledChanged(!accentEnabled),
          child: Icon(
            accentEnabled ? Icons.volume_up : Icons.volume_off,
            color: accentEnabled ? primary : Colors.white38,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        // Beat weight indicators
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(accentPattern.weights.length, (i) {
              final weight = accentPattern.weights[i];
              final isAccent = weight >= 0.9;
              return GestureDetector(
                onTap: accentEnabled
                    ? () {
                        // Cycle: 1.0 -> 0.7 -> 0.0 -> 1.0
                        double newWeight;
                        if (weight >= 0.9) {
                          newWeight = 0.7;
                        } else if (weight >= 0.5) {
                          newWeight = 0.0;
                        } else {
                          newWeight = 1.0;
                        }
                        onWeightChanged(i, newWeight);
                      }
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: !accentEnabled
                        ? Colors.white12
                        : weight >= 0.9
                            ? primary
                            : weight >= 0.5
                                ? primary.withValues(alpha: 0.4)
                                : Colors.white12,
                    border: Border.all(
                      color: !accentEnabled
                          ? Colors.white12
                          : isAccent
                              ? primary
                              : Colors.white24,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: !accentEnabled
                            ? Colors.white24
                            : weight >= 0.5
                                ? Colors.white
                                : Colors.white38,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

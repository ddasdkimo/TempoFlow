import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';

class TapTempoButton extends ConsumerWidget {
  final ValueChanged<int> onBpmDetected;

  const TapTempoButton({
    super.key,
    required this.onBpmDetected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapService = ref.watch(tapTempoServiceProvider);

    return GestureDetector(
      onTap: () {
        final bpm = tapService.calculateBpm();
        if (bpm != null) {
          onBpmDetected(bpm);
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 20, color: Colors.white70),
            Text(
              'TAP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

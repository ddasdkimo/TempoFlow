import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BpmControl extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onBpmChanged;

  const BpmControl({
    super.key,
    required this.bpm,
    required this.onBpmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 200;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // BPM display
            GestureDetector(
              onTap: () => _showBpmInput(context),
              child: Text(
                '$bpm',
                style: compact
                    ? Theme.of(context).textTheme.headlineLarge
                    : Theme.of(context).textTheme.displayLarge,
              ),
            ),
            Text(
              'BPM',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: compact ? 8 : 24),
            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                ),
                child: Slider(
                  value: bpm.toDouble(),
                  min: 20,
                  max: 300,
                  onChanged: (v) => onBpmChanged(v.round()),
                ),
              ),
            ),
            // +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BpmAdjustButton(
                  icon: Icons.remove,
                  onTap: () => onBpmChanged((bpm - 1).clamp(20, 300)),
                  onLongPress: () => onBpmChanged((bpm - 5).clamp(20, 300)),
                ),
                const SizedBox(width: 48),
                _BpmAdjustButton(
                  icon: Icons.add,
                  onTap: () => onBpmChanged((bpm + 1).clamp(20, 300)),
                  onLongPress: () => onBpmChanged((bpm + 5).clamp(20, 300)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showBpmInput(BuildContext context) {
    final controller = TextEditingController(text: '$bpm');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('輸入 BPM'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '20-300',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                onBpmChanged(value.clamp(20, 300));
              }
              Navigator.pop(ctx);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

class _BpmAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BpmAdjustButton({
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }
}

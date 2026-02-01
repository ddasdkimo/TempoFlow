import 'package:flutter/material.dart';

import '../../../core/models/time_signature.dart';

class TimeSignaturePicker extends StatelessWidget {
  final TimeSignature timeSignature;
  final ValueChanged<TimeSignature> onChanged;

  const TimeSignaturePicker({
    super.key,
    required this.timeSignature,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(
                timeSignature.display,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '拍號',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '選擇拍號',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...TimeSignature.presets.map((ts) => _chip(ctx, ts)),
                _chip(ctx, const TimeSignature(beatsPerBar: 5, noteValue: 4)),
                _chip(ctx, const TimeSignature(beatsPerBar: 7, noteValue: 8)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, TimeSignature ts) {
    final isSelected = ts == timeSignature;
    return ChoiceChip(
      label: Text(ts.display),
      selected: isSelected,
      onSelected: (_) {
        onChanged(ts);
        Navigator.pop(context);
      },
    );
  }
}

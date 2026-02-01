import 'package:flutter/material.dart';

class SubdivisionSelector extends StatelessWidget {
  final int subdivision;
  final ValueChanged<int> onChanged;

  const SubdivisionSelector({
    super.key,
    required this.subdivision,
    required this.onChanged,
  });

  static const _labels = {
    1: '♩',
    2: '♪♪',
    3: '三連',
    4: '♬♬',
  };

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
                _labels[subdivision] ?? '$subdivision',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '細分',
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
                '細分節拍',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: 12,
              children: _labels.entries.map((e) {
                return ChoiceChip(
                  label: Text(e.value),
                  selected: subdivision == e.key,
                  onSelected: (_) {
                    onChanged(e.key);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/models/sound_type.dart';
import '../../core/models/visual_mode.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(metronomeServiceProvider);
    final asyncState = ref.watch(metronomeStateProvider);
    final state = asyncState.valueOrNull ?? service.state;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound type
          const _SectionHeader('音色'),
          Card(
            child: Column(
              children: SoundType.values.map((type) {
                return RadioListTile<SoundType>(
                  title: Text(type.displayName),
                  value: type,
                  groupValue: state.soundType,
                  onChanged: (v) {
                    if (v != null) service.setSoundType(v);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Volume controls
          const _SectionHeader('音量'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _VolumeSlider(
                    label: '總音量',
                    value: state.masterVolume,
                    onChanged: (v) => service.setMasterVolume(v),
                  ),
                  _VolumeSlider(
                    label: '強拍音量',
                    value: state.accentVolume,
                    onChanged: (v) => service.setAccentVolume(v),
                  ),
                  _VolumeSlider(
                    label: '細分音量',
                    value: state.subdivisionVolume,
                    onChanged: (v) => service.setSubdivisionVolume(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Visual mode
          const _SectionHeader('視覺模式'),
          Card(
            child: Column(
              children: VisualMode.values.map((mode) {
                return RadioListTile<VisualMode>(
                  title: Text(mode.displayName),
                  value: mode,
                  groupValue: state.visualMode,
                  onChanged: (v) {
                    if (v != null) service.setVisualMode(v);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Vibration
          const _SectionHeader('震動'),
          Card(
            child: SwitchListTile(
              title: const Text('主拍震動'),
              subtitle: const Text('Web 平台不支援'),
              value: state.vibrationEnabled,
              onChanged: (v) => service.setVibration(v),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}',
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

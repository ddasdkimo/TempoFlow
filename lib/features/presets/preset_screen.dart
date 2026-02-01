import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/models/preset.dart';

class PresetScreen extends ConsumerStatefulWidget {
  const PresetScreen({super.key});

  @override
  ConsumerState<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends ConsumerState<PresetScreen> {
  @override
  Widget build(BuildContext context) {
    final presetService = ref.watch(presetServiceProvider);
    final metronomeService = ref.watch(metronomeServiceProvider);
    final presets = presetService.presets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _saveCurrentAsPreset(context),
          ),
        ],
      ),
      body: presets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    '尚無 Preset',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '點擊右上角 + 儲存目前設定',
                    style: TextStyle(color: Colors.white24, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: presets.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) {
                final preset = presets[i];
                return Card(
                  child: ListTile(
                    title: Text(preset.name),
                    subtitle: Text(
                      '${preset.bpm} BPM  ${preset.timeSignature.display}  ${preset.soundType.displayName}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white38),
                      onPressed: () async {
                        await presetService.deletePreset(preset.id);
                        setState(() {});
                      },
                    ),
                    onTap: () {
                      // Apply preset to metronome
                      metronomeService.setBpm(preset.bpm);
                      metronomeService.setTimeSignature(preset.timeSignature);
                      metronomeService.setSubdivision(preset.subdivision);
                      metronomeService.setAccentEnabled(preset.accentEnabled);
                      metronomeService.setAccentPattern(preset.accentPattern);
                      metronomeService.setSoundType(preset.soundType);
                      presetService.markRecent(preset.id);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _saveCurrentAsPreset(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('儲存 Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '輸入名稱',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final metronomeService = ref.read(metronomeServiceProvider);
              final state = metronomeService.state;
              final presetService = ref.read(presetServiceProvider);

              final preset = Preset(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                bpm: state.bpm,
                timeSignature: state.timeSignature,
                subdivision: state.subdivision,
                accentEnabled: state.accentEnabled,
                accentPattern: state.accentPattern,
                soundType: state.soundType,
                visualMode: state.visualMode,
              );

              await presetService.addPreset(preset);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

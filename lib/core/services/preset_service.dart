import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/preset.dart';

class PresetService {
  static const _storageKey = 'tempoflow_presets';
  static const _recentKey = 'tempoflow_recent_presets';
  static const int _maxRecent = 10;

  List<Preset> _presets = [];
  List<String> _recentIds = [];

  List<Preset> get presets => List.unmodifiable(_presets);
  List<Preset> get recentPresets {
    return _recentIds
        .map((id) => _presets.firstWhere(
              (p) => p.id == id,
              orElse: () => _presets.first,
            ))
        .where((p) => _presets.contains(p))
        .toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _presets = list.map((e) => Preset.fromJson(e as Map<String, dynamic>)).toList();
    }
    _recentIds = prefs.getStringList(_recentKey) ?? [];
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_presets.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, json);
    await prefs.setStringList(_recentKey, _recentIds);
  }

  Future<void> addPreset(Preset preset) async {
    _presets.add(preset);
    await save();
  }

  Future<void> updatePreset(Preset preset) async {
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index >= 0) {
      _presets[index] = preset;
      await save();
    }
  }

  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    _recentIds.remove(id);
    await save();
  }

  Future<void> markRecent(String id) async {
    _recentIds.remove(id);
    _recentIds.insert(0, id);
    if (_recentIds.length > _maxRecent) {
      _recentIds = _recentIds.sublist(0, _maxRecent);
    }
    await save();
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ')
        .convert(_presets.map((p) => p.toJson()).toList());
  }

  Future<int> importJson(String json) async {
    final list = jsonDecode(json) as List;
    final imported = list.map((e) => Preset.fromJson(e as Map<String, dynamic>)).toList();
    int count = 0;
    for (final preset in imported) {
      if (!_presets.any((p) => p.id == preset.id)) {
        _presets.add(preset);
        count++;
      }
    }
    if (count > 0) await save();
    return count;
  }
}

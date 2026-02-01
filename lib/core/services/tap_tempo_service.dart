class TapTempoService {
  final List<int> _tapTimestamps = [];
  static const int _maxTaps = 8;
  static const int _resetTimeoutMs = 2000;

  int? calculateBpm() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Reset if timeout exceeded
    if (_tapTimestamps.isNotEmpty && now - _tapTimestamps.last > _resetTimeoutMs) {
      _tapTimestamps.clear();
    }

    _tapTimestamps.add(now);

    // Keep only last N taps
    while (_tapTimestamps.length > _maxTaps) {
      _tapTimestamps.removeAt(0);
    }

    // Need at least 2 taps to calculate
    if (_tapTimestamps.length < 2) return null;

    // Calculate average interval
    double totalInterval = 0;
    for (int i = 1; i < _tapTimestamps.length; i++) {
      totalInterval += _tapTimestamps[i] - _tapTimestamps[i - 1];
    }
    final avgInterval = totalInterval / (_tapTimestamps.length - 1);

    // Convert to BPM
    final bpm = (60000.0 / avgInterval).round();
    return bpm.clamp(20, 300);
  }

  void reset() {
    _tapTimestamps.clear();
  }
}

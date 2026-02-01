class AccentPattern {
  final List<double> weights;

  const AccentPattern(this.weights);

  factory AccentPattern.standard(int beats) {
    return AccentPattern([
      1.0,
      ...List.filled(beats - 1, 0.7),
    ]);
  }

  factory AccentPattern.march(int beats) {
    final w = <double>[];
    for (int i = 0; i < beats; i++) {
      w.add(i % 2 == 0 ? 1.0 : 0.5);
    }
    return AccentPattern(w);
  }

  factory AccentPattern.waltz() {
    return const AccentPattern([1.0, 0.5, 0.5]);
  }

  factory AccentPattern.uniform(int beats) {
    return AccentPattern(List.filled(beats, 0.7));
  }

  double weightAt(int beat) {
    if (beat < 0 || beat >= weights.length) return 0.7;
    return weights[beat];
  }

  AccentPattern withWeight(int beat, double weight) {
    final newWeights = List<double>.from(weights);
    if (beat >= 0 && beat < newWeights.length) {
      newWeights[beat] = weight.clamp(0.0, 1.0);
    }
    return AccentPattern(newWeights);
  }

  AccentPattern resize(int newSize) {
    if (newSize == weights.length) return this;
    if (newSize < weights.length) {
      return AccentPattern(weights.sublist(0, newSize));
    }
    return AccentPattern([
      ...weights,
      ...List.filled(newSize - weights.length, 0.7),
    ]);
  }

  List<double> toJson() => weights;

  factory AccentPattern.fromJson(List<dynamic> json) =>
      AccentPattern(json.cast<double>());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccentPattern &&
          _listEquals(weights, other.weights);

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(weights);
}

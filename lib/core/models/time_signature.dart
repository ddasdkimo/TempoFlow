class TimeSignature {
  final int beatsPerBar;
  final int noteValue;

  const TimeSignature({
    this.beatsPerBar = 4,
    this.noteValue = 4,
  });

  static const common = TimeSignature(beatsPerBar: 4, noteValue: 4);
  static const waltz = TimeSignature(beatsPerBar: 3, noteValue: 4);
  static const march = TimeSignature(beatsPerBar: 2, noteValue: 4);
  static const sixEight = TimeSignature(beatsPerBar: 6, noteValue: 8);

  static const presets = [common, waltz, march, sixEight];

  String get display => '$beatsPerBar/$noteValue';

  TimeSignature copyWith({int? beatsPerBar, int? noteValue}) {
    return TimeSignature(
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      noteValue: noteValue ?? this.noteValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'beatsPerBar': beatsPerBar,
    'noteValue': noteValue,
  };

  factory TimeSignature.fromJson(Map<String, dynamic> json) => TimeSignature(
    beatsPerBar: json['beatsPerBar'] as int? ?? 4,
    noteValue: json['noteValue'] as int? ?? 4,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature &&
          beatsPerBar == other.beatsPerBar &&
          noteValue == other.noteValue;

  @override
  int get hashCode => beatsPerBar.hashCode ^ noteValue.hashCode;
}

import '../utils/uuid_helper.dart';

class PracticeSession {
  final String id;
  final String userId;
  final DateTime startAt;
  final DateTime? endAt;

  const PracticeSession({
    required this.id,
    required this.userId,
    required this.startAt,
    this.endAt,
  });

  /// Creates a new [PracticeSession] with a generated UUID starting now.
  factory PracticeSession.start({required String userId}) {
    return PracticeSession(
      id: UuidHelper.generate(),
      userId: userId,
      startAt: DateTime.now(),
    );
  }

  /// Duration in seconds. If [endAt] is null (session is active),
  /// calculates from [startAt] to [DateTime.now()].
  int get durationSec {
    final end = endAt ?? DateTime.now();
    return end.difference(startAt).inSeconds;
  }

  /// Whether this session is still active (has not ended).
  bool get isActive => endAt == null;

  PracticeSession copyWith({
    String? id,
    String? userId,
    DateTime? startAt,
    DateTime? Function()? endAt,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startAt: startAt ?? this.startAt,
      endAt: endAt != null ? endAt() : this.endAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
  };

  factory PracticeSession.fromJson(Map<String, dynamic> json) =>
      PracticeSession(
        id: json['id'] as String,
        userId: json['userId'] as String,
        startAt: DateTime.parse(json['startAt'] as String),
        endAt: json['endAt'] != null
            ? DateTime.parse(json['endAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeSession &&
          id == other.id &&
          userId == other.userId &&
          startAt == other.startAt &&
          endAt == other.endAt;

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ startAt.hashCode ^ endAt.hashCode;

  @override
  String toString() =>
      'PracticeSession(id: $id, userId: $userId, '
      'startAt: $startAt, endAt: $endAt, '
      'durationSec: $durationSec, isActive: $isActive)';
}

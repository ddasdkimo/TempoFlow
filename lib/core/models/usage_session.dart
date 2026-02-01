import '../utils/uuid_helper.dart';

class UsageSession {
  final String id;
  final String userId;
  final DateTime startAt;
  final DateTime? endAt;

  const UsageSession({
    required this.id,
    required this.userId,
    required this.startAt,
    this.endAt,
  });

  /// Creates a new [UsageSession] with a generated UUID starting now.
  factory UsageSession.start({required String userId}) {
    return UsageSession(
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

  UsageSession copyWith({
    String? id,
    String? userId,
    DateTime? startAt,
    DateTime? Function()? endAt,
  }) {
    return UsageSession(
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

  factory UsageSession.fromJson(Map<String, dynamic> json) => UsageSession(
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
      other is UsageSession &&
          id == other.id &&
          userId == other.userId &&
          startAt == other.startAt &&
          endAt == other.endAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      startAt.hashCode ^
      endAt.hashCode;

  @override
  String toString() =>
      'UsageSession(id: $id, userId: $userId, '
      'startAt: $startAt, endAt: $endAt, '
      'durationSec: $durationSec, isActive: $isActive)';
}

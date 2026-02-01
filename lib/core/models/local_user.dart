import '../utils/uuid_helper.dart';

class LocalUser {
  final String id;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const LocalUser({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.lastActiveAt,
  });

  /// Creates a new [LocalUser] with a generated UUID and current timestamps.
  factory LocalUser.create({required String displayName}) {
    final now = DateTime.now();
    return LocalUser(
      id: UuidHelper.generate(),
      displayName: displayName,
      createdAt: now,
      lastActiveAt: now,
    );
  }

  LocalUser copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return LocalUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUser &&
          id == other.id &&
          displayName == other.displayName &&
          createdAt == other.createdAt &&
          lastActiveAt == other.lastActiveAt;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      createdAt.hashCode ^
      lastActiveAt.hashCode;

  @override
  String toString() =>
      'LocalUser(id: $id, displayName: $displayName, '
      'createdAt: $createdAt, lastActiveAt: $lastActiveAt)';
}

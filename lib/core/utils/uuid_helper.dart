import 'dart:math';

class UuidHelper {
  static final _random = Random.secure();

  /// Generates a UUID v4 string.
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4 (0100 in binary).
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Set variant to RFC 4122 (10xx in binary).
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    return _formatBytes(bytes);
  }

  static String _formatBytes(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}'
        '-${hex.sublist(4, 6).join()}'
        '-${hex.sublist(6, 8).join()}'
        '-${hex.sublist(8, 10).join()}'
        '-${hex.sublist(10, 16).join()}';
  }
}

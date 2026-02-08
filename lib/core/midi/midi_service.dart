import 'dart:async';

enum MidiConnectionState {
  disconnected,
  connected,
  unsupported,
  permissionDenied,
}

class MidiNoteEvent {
  final int note;
  final int velocity;
  final bool isNoteOn;
  final DateTime timestamp;

  const MidiNoteEvent({
    required this.note,
    required this.velocity,
    required this.isNoteOn,
    required this.timestamp,
  });

  @override
  String toString() =>
      'MidiNoteEvent(note: $note, velocity: $velocity, '
      'isNoteOn: $isNoteOn, timestamp: $timestamp)';
}

abstract class MidiService {
  bool get isSupported;
  Stream<MidiConnectionState> get connectionStream;
  Stream<MidiNoteEvent> get noteStream;
  List<String> get connectedDevices;
  Future<void> initialize();
  Future<void> dispose();
}

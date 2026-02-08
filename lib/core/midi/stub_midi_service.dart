import 'midi_service.dart';

MidiService createPlatformMidiService() => StubMidiService();

class StubMidiService implements MidiService {
  @override
  bool get isSupported => false;

  @override
  Stream<MidiConnectionState> get connectionStream => const Stream.empty();

  @override
  Stream<MidiNoteEvent> get noteStream => const Stream.empty();

  @override
  List<String> get connectedDevices => const [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}

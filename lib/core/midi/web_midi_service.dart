import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'midi_service.dart';

MidiService createPlatformMidiService() => WebMidiService();

class WebMidiService implements MidiService {
  web.MIDIAccess? _midiAccess;

  final _connectionController =
      StreamController<MidiConnectionState>.broadcast();
  final _noteController = StreamController<MidiNoteEvent>.broadcast();

  final List<String> _connectedDevices = [];
  bool _isSupported = false;

  @override
  bool get isSupported => _isSupported;

  @override
  Stream<MidiConnectionState> get connectionStream =>
      _connectionController.stream;

  @override
  Stream<MidiNoteEvent> get noteStream => _noteController.stream;

  @override
  List<String> get connectedDevices => List.unmodifiable(_connectedDevices);

  @override
  Future<void> initialize() async {
    // Check if requestMIDIAccess is available on navigator
    final nav = web.window.navigator as JSObject;
    if (!nav.has('requestMIDIAccess')) {
      _isSupported = false;
      _connectionController.add(MidiConnectionState.unsupported);
      debugPrint('[WebMidiService] Web MIDI API not supported');
      return;
    }

    _isSupported = true;

    try {
      final promise = web.window.navigator.requestMIDIAccess();
      _midiAccess = await promise.toDart;

      // Listen for connection state changes
      _midiAccess!.onstatechange = _onStateChange.toJS;

      // Scan initial inputs
      _scanInputs();

      if (_connectedDevices.isNotEmpty) {
        _connectionController.add(MidiConnectionState.connected);
      } else {
        _connectionController.add(MidiConnectionState.disconnected);
      }

      debugPrint(
        '[WebMidiService] Initialized with '
        '${_connectedDevices.length} device(s)',
      );
    } catch (e) {
      debugPrint('[WebMidiService] Permission denied or error: $e');
      _connectionController.add(MidiConnectionState.permissionDenied);
    }
  }

  @override
  Future<void> dispose() async {
    _midiAccess = null;
    await _connectionController.close();
    await _noteController.close();
  }

  /// Scans the current MIDIInputMap and attaches listeners to all inputs.
  void _scanInputs() {
    final access = _midiAccess;
    if (access == null) return;

    _connectedDevices.clear();

    // MIDIInputMap is a JS Map-like object; use forEach via JS interop.
    final inputMap = access.inputs as JSObject;
    inputMap.callMethodVarArgs('forEach'.toJS, [
      ((web.MIDIInput input, JSString key, JSObject map) {
        final name = input.name ?? input.id;
        _connectedDevices.add(name);

        // Attach MIDI message listener
        input.onmidimessage = _onMidiMessage.toJS;

        debugPrint('[WebMidiService] Attached listener to: $name');
      }).toJS,
    ]);
  }

  /// Called when a MIDI device is connected or disconnected.
  void _onStateChange(web.Event event) {
    final connectionEvent = event as web.MIDIConnectionEvent;
    final port = connectionEvent.port;
    if (port == null) return;

    debugPrint(
      '[WebMidiService] State change: ${port.name} '
      'type=${port.type} state=${port.state}',
    );

    // Re-scan all inputs and re-attach listeners
    _scanInputs();

    if (_connectedDevices.isNotEmpty) {
      _connectionController.add(MidiConnectionState.connected);
    } else {
      _connectionController.add(MidiConnectionState.disconnected);
    }
  }

  /// Called when a MIDI message is received from any input.
  void _onMidiMessage(web.Event event) {
    final midiEvent = event as web.MIDIMessageEvent;
    final data = midiEvent.data;
    if (data == null) return;

    // Convert JSUint8Array to Dart Uint8List for easy access
    final bytes = data.toDart;
    if (bytes.length < 3) return;

    final status = bytes[0];
    final note = bytes[1];
    final velocity = bytes[2];

    final command = status & 0xF0;

    // 0x90 = note on, 0x80 = note off
    // Note on with velocity 0 is also treated as note off
    if (command == 0x90 || command == 0x80) {
      final isNoteOn = command == 0x90 && velocity > 0;

      if (!_noteController.isClosed) {
        _noteController.add(MidiNoteEvent(
          note: note,
          velocity: velocity,
          isNoteOn: isNoteOn,
          timestamp: DateTime.now(),
        ));
      }
    }
  }
}

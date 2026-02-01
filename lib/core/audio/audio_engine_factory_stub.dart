import 'audio_engine.dart';

AudioEngine createPlatformAudioEngine() {
  throw UnsupportedError('No audio engine available for this platform');
}

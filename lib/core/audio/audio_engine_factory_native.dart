import 'audio_engine.dart';
import 'native_audio_engine.dart';

AudioEngine createPlatformAudioEngine() => NativeAudioEngine();

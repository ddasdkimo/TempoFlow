import 'audio_engine.dart';
import 'web_audio_engine.dart';

AudioEngine createPlatformAudioEngine() => WebAudioEngine();

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Bahasa dan karakter suara
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.65);
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.65);

    // Selesaikan ucapan sebelum lanjut ke proses berikutnya
    await _tts.awaitSpeakCompletion(true);

    // Pilih voice Bahasa Indonesia yang tersedia
   

    _initialized = true;
  }

  Future<void> speak(String text) async {
    await initialize();

    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
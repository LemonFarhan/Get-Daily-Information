import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Bahasa dan karakter suara
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.65);
    await _tts.setPitch(0.65);
    await _tts.setVolume(0.65);

    // Selesaikan ucapan sebelum lanjut ke proses berikutnya
    await _tts.awaitSpeakCompletion(true);

    // Pilih voice Bahasa Indonesia yang tersedia
    try {
      final dynamic voices = await _tts.getVoices;

      if (voices is List) {
        for (final dynamic voice in voices) {
          if (voice is! Map) continue;

          final locale = (voice['locale'] ?? '')
              .toString()
              .replaceAll('_', '-')
              .toLowerCase();

          if (locale == 'id-id' ||
              locale.startsWith('id-id-')) {
            final name = voice['name']?.toString();
            final voiceLocale = voice['locale']?.toString();

            if (name != null && voiceLocale != null) {
              await _tts.setVoice({
                'name': name,
                'locale': voiceLocale,
              });
              break;
            }
          }
        }
      }
    } catch (_) {
      // Tetap gunakan bahasa id-ID jika daftar voice
      // tidak dapat diakses oleh perangkat.
    }

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
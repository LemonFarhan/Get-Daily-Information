import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    _initialized = await _speech.initialize();

    return _initialized;
  }

  Future<String> listen() async {
    if (!_initialized) {
      final available = await initialize();

      if (!available) {
        return '';
      }
    }

    String resultText = '';

    await _speech.listen(
      localeId: 'id_ID',
      onResult: (SpeechRecognitionResult result) {
        resultText = result.recognizedWords;
      },
    );

    while (_speech.isListening) {
      await Future.delayed(
        const Duration(milliseconds: 100),
      );
    }

    return resultText.trim();
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
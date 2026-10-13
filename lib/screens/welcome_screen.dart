import 'package:flutter/material.dart';

import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() =>
      _WelcomeScreenState();
}

class _WelcomeScreenState
    extends State<WelcomeScreen> {
  // =========================================================
  // SERVICE
  // =========================================================

  final TtsService _ttsService =
      TtsService();

  final SpeechService _speechService =
      SpeechService();

  // =========================================================
  // VARIABLE
  // =========================================================

  bool _isListening = false;

  String _statusText =
      'KETUK AREA KOSONG UNTUK MEMULAI';

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _prepareWelcome();
  }

  Future<void> _prepareWelcome() async {
    await _ttsService.initialize();
    await _speechService.initialize();

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    await _ttsService.speak(
      'Selamat datang di Get Daily Information. '
      'Anda dapat menggunakan aplikasi secara manual, '
      'atau ketuk area kosong untuk menggunakan suara.',
    );
  }

  // =========================================================
  // VOICE WELCOME
  // =========================================================

  Future<void> _startVoiceWelcome() async {
    if (_isListening) {
      return;
    }

    await _ttsService.stop();

    setState(() {
      _isListening = true;
      _statusText =
          'SEDANG MENDENGARKAN';
    });

    await _ttsService.speak(
      'Silakan katakan login atau daftar.',
    );

    final command =
        await _speechService.listen();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (command.isEmpty) {
      await _ttsService.speak(
        'Saya tidak mendengar perintah Anda. '
        'Ketuk area kosong untuk mencoba lagi.',
      );

      setState(() {
        _statusText =
            'KETUK AREA KOSONG UNTUK MENCOBA LAGI';
      });

      return;
    }

    final text =
        command.toLowerCase().trim();

    // ========================================================
    // LOGIN
    // ========================================================

    if (text.contains('login') ||
        text.contains('masuk')) {
      await _ttsService.speak(
        'Baik, membuka halaman login.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );

      return;
    }

    // ========================================================
    // DAFTAR
    // ========================================================

    if (text.contains('daftar') ||
        text.contains('register')) {
      await _ttsService.speak(
        'Baik, membuka halaman pendaftaran.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RegisterScreen(),
        ),
      );

      return;
    }

    // ========================================================
    // TIDAK DIKENALI
    // ========================================================

    await _ttsService.speak(
      'Maaf, saya belum memahami. '
      'Silakan katakan login atau daftar.',
    );

    setState(() {
      _statusText =
          'KETUK AREA KOSONG UNTUK MENCOBA LAGI';
    });
  }

  // =========================================================
  // TAP AREA KOSONG
  // =========================================================

  Future<void> _handleScreenTap() async {
    if (_isListening) {
      return;
    }

    await _startVoiceWelcome();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleScreenTap,

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [
                const SizedBox(height: 60),

                const Icon(
                  Icons.record_voice_over,
                  size: 120,
                ),

                const SizedBox(height: 30),

                const Text(
                  'GET DAILY\nINFORMATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Icon(
                  _isListening
                      ? Icons.mic
                      : Icons.touch_app,
                  size: 70,
                ),

                const SizedBox(height: 40),

                // =================================================
                // LOGIN MANUAL
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 60,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.login,
                    ),

                    label: const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // DAFTAR MANUAL
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 60,

                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RegisterScreen(),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.person_add,
                    ),

                    label: const Text(
                      'DAFTAR',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'Pengguna yang tidak dapat melihat layar '
                  'dapat mengetuk area kosong untuk menggunakan '
                  'navigasi suara.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
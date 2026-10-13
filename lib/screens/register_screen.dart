import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  // =========================================================
  // SERVICE
  // =========================================================

  final AuthService _authService = AuthService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  // =========================================================
  // VARIABLE
  // =========================================================

  bool _loading = false;
  bool _voiceLoading = false;

  String _errorMessage = '';

  // =========================================================
  // INIT STATE
  // =========================================================

  @override
  void initState() {
    super.initState();

    _prepareRegister();
  }

  Future<void> _prepareRegister() async {
    await _ttsService.initialize();
    await _speechService.initialize();

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    await _ttsService.speak(
      'Halaman pendaftaran. '
      'Anda dapat mengisi nama, email, dan password secara manual. '
      'Atau ketuk area kosong untuk menggunakan pendaftaran suara.',
    );
  }

  // =========================================================
  // VOICE REGISTER
  // =========================================================

  Future<void> _startVoiceRegister() async {
    if (_voiceLoading) {
      return;
    }

    setState(() {
      _voiceLoading = true;
      _errorMessage = '';
    });

    try {
      await _ttsService.stop();

      // -------------------------------------------------------
      // NAMA
      // -------------------------------------------------------

      await _ttsService.speak(
        'Silakan sebutkan nama Anda.',
      );

      final nameSpeech =
          await _speechService.listen();

      if (nameSpeech.isEmpty) {
        await _ttsService.speak(
          'Nama tidak terdengar. '
          'Ketuk area kosong untuk mencoba lagi.',
        );
        return;
      }

      final cleanName = nameSpeech.trim();

      _nameController.text = cleanName;

      // -------------------------------------------------------
      // EMAIL
      // -------------------------------------------------------

      await _ttsService.speak(
        'Baik $cleanName. '
        'Sekarang silakan sebutkan email Anda.',
      );

      final emailSpeech =
          await _speechService.listen();

      if (emailSpeech.isEmpty) {
        await _ttsService.speak(
          'Email tidak terdengar. '
          'Ketuk area kosong untuk mencoba lagi.',
        );
        return;
      }

      final cleanEmail =
          _convertSpeechToEmail(emailSpeech);

      _emailController.text = cleanEmail;

      // -------------------------------------------------------
      // PASSWORD
      // -------------------------------------------------------

      await _ttsService.speak(
        'Saya mendengar email $cleanEmail. '
        'Sekarang silakan sebutkan password Anda. '
        'Password minimal enam karakter.',
      );

      final passwordSpeech =
          await _speechService.listen();

      if (passwordSpeech.isEmpty) {
        await _ttsService.speak(
          'Password tidak terdengar. '
          'Ketuk area kosong untuk mencoba lagi.',
        );
        return;
      }

      final password =
          _convertSpeechToPassword(passwordSpeech);

      _passwordController.text = password;

      if (password.length < 6) {
        await _ttsService.speak(
          'Password harus memiliki minimal enam karakter. '
          'Ketuk area kosong untuk mencoba lagi.',
        );
        return;
      }

      // -------------------------------------------------------
      // REGISTER FIREBASE
      // -------------------------------------------------------

      await _authService.register(
        name: cleanName,
        email: cleanEmail,
        password: password,
      );

      await _ttsService.speak(
        'Pendaftaran berhasil. '
        'Selamat datang $cleanName.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message =
          'Pendaftaran gagal.';

      if (e.code == 'email-already-in-use') {
        message =
            'Email tersebut sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        message =
            'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        message =
            'Password terlalu lemah.';
      }

      setState(() {
        _errorMessage = message;
      });

      await _ttsService.speak(
        '$message Ketuk area kosong untuk mencoba lagi.',
      );
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat pendaftaran.';
      });

      await _ttsService.speak(
        'Terjadi kesalahan saat pendaftaran.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _voiceLoading = false;
        });
      }
    }
  }

  // =========================================================
  // KONVERSI EMAIL
  // =========================================================

  String _convertSpeechToEmail(String text) {
    String email =
        text.toLowerCase().trim();

    email = email.replaceAll(
      RegExp(r'\b(at|at the rate)\b'),
      '@',
    );

    email = email.replaceAll(
      RegExp(r'\b(dot|titik)\b'),
      '.',
    );

    email = email.replaceAll(
      ' ',
      '',
    );

    return email;
  }

  // =========================================================
  // KONVERSI PASSWORD
  // =========================================================

  String _convertSpeechToPassword(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
  }

  // =========================================================
  // REGISTER MANUAL
  // =========================================================

  Future<void> _register() async {
    final name =
        _nameController.text.trim();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(() {
        _errorMessage =
            'Semua data harus diisi.';
      });

      await _ttsService.speak(
        'Nama, email, dan password harus diisi.',
      );

      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage =
            'Password minimal enam karakter.';
      });

      await _ttsService.speak(
        'Password minimal enam karakter.',
      );

      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      await _ttsService.speak(
        'Pendaftaran berhasil. Selamat datang $name.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message =
          'Pendaftaran gagal.';

      if (e.code == 'email-already-in-use') {
        message =
            'Email tersebut sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        message =
            'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        message =
            'Password terlalu lemah.';
      }

      setState(() {
        _errorMessage = message;
      });

      await _ttsService.speak(message);
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat pendaftaran.';
      });

      await _ttsService.speak(
        'Terjadi kesalahan saat pendaftaran.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // TAP AREA KOSONG = VOICE REGISTER
  // =========================================================

  Future<void> _handleScreenTap() async {
    if (_voiceLoading) {
      return;
    }

    await _startVoiceRegister();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar'),
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleScreenTap,

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.person_add_alt_1,
                  size: 90,
                ),

                const SizedBox(height: 25),

                const Text(
                  'DAFTAR',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 35),

                // =================================================
                // NAMA
                // =================================================

                TextField(
                  controller: _nameController,

                  decoration:
                      const InputDecoration(
                    labelText: 'Nama',
                    hintText:
                        'Masukkan nama',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // EMAIL
                // =================================================

                TextField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,

                  decoration:
                      const InputDecoration(
                    labelText: 'Email',
                    hintText:
                        'Masukkan email',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // PASSWORD
                // =================================================

                TextField(
                  controller: _passwordController,
                  obscureText: true,

                  decoration:
                      const InputDecoration(
                    labelText: 'Password',
                    hintText:
                        'Minimal 6 karakter',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // DAFTAR MANUAL
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 60,

                  child: ElevatedButton.icon(
                    onPressed:
                        _loading
                            ? null
                            : _register,

                    icon: const Icon(
                      Icons.person_add,
                    ),

                    label: Text(
                      _loading
                          ? 'MEMPROSES...'
                          : 'DAFTAR',

                      style:
                          const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // INFO VOICE
                // =================================================

                const Icon(
                  Icons.record_voice_over,
                  size: 55,
                ),

                const SizedBox(height: 12),

                Text(
                  _voiceLoading
                      ? 'SEDANG MENDENGARKAN...'
                      : 'KETUK AREA KOSONG UNTUK PENDAFTARAN SUARA',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // ERROR
                // =================================================

                if (_errorMessage
                    .isNotEmpty)
                  Text(
                    _errorMessage,
                    textAlign:
                        TextAlign.center,
                  ),

                const SizedBox(height: 30),

                // =================================================
                // KE LOGIN
                // =================================================

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    'Sudah punya akun? Login',
                    style:
                        TextStyle(
                      fontSize: 16,
                    ),
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
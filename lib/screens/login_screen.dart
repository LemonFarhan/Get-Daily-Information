import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

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
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _prepareLogin();
  }

  Future<void> _prepareLogin() async {
    await _ttsService.initialize();
    await _speechService.initialize();

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    await _ttsService.speak(
      'Halaman login. '
      'Silakan isi email dan password secara manual, '
      'atau ketuk area kosong untuk login menggunakan suara.',
    );
  }

  // =========================================================
  // VOICE LOGIN
  // =========================================================

  Future<void> _startVoiceLogin() async {
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
      // EMAIL
      // -------------------------------------------------------

      await _ttsService.speak(
        'Silakan sebutkan email Anda.',
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
        'Sekarang silakan sebutkan password Anda.',
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

      // -------------------------------------------------------
      // FIREBASE LOGIN
      // -------------------------------------------------------

      await _authService.login(
        email: cleanEmail,
        password: password,
      );

      await _ttsService.speak(
        'Login berhasil. Selamat datang.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login gagal.';

      if (e.code == 'invalid-credential') {
        message =
            'Email atau password salah.';
      } else if (e.code == 'user-not-found') {
        message =
            'Akun tidak ditemukan.';
      } else if (e.code == 'wrong-password') {
        message =
            'Password salah.';
      } else if (e.code == 'invalid-email') {
        message =
            'Format email tidak valid.';
      }

      setState(() {
        _errorMessage = message;
      });

      await _ttsService.speak(
        message,
      );
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat login.';
      });

      await _ttsService.speak(
        'Terjadi kesalahan saat login.',
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
  // EMAIL DARI SUARA
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
  // PASSWORD DARI SUARA
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
  // LOGIN MANUAL
  // =========================================================

  Future<void> _login() async {
    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      setState(() {
        _errorMessage =
            'Email dan password harus diisi.';
      });

      await _ttsService.speak(
        'Email dan password harus diisi.',
      );

      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await _authService.login(
        email: email,
        password: password,
      );

      await _ttsService.speak(
        'Login berhasil. Selamat datang.',
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
          'Login gagal.';

      if (e.code ==
          'invalid-credential') {
        message =
            'Email atau password salah.';
      } else if (e.code ==
          'user-not-found') {
        message =
            'Akun tidak ditemukan.';
      } else if (e.code ==
          'wrong-password') {
        message =
            'Password salah.';
      } else if (e.code ==
          'invalid-email') {
        message =
            'Format email tidak valid.';
      }

      setState(() {
        _errorMessage = message;
      });

      await _ttsService.speak(
        message,
      );
    } catch (e) {
      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat login.';
      });

      await _ttsService.speak(
        'Terjadi kesalahan saat login.',
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
  // TAP AREA KOSONG = VOICE LOGIN
  // =========================================================

  Future<void> _handleScreenTap() async {
    if (_voiceLoading) {
      return;
    }

    await _startVoiceLogin();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
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
        title: const Text('Login'),
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

                // =================================================
                // ICON
                // =================================================

                const Icon(
                  Icons.login,
                  size: 90,
                ),

                const SizedBox(height: 25),

                const Text(
                  'LOGIN',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 35),

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
                        'Masukkan password',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // LOGIN MANUAL
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 60,

                  child: ElevatedButton.icon(
                    onPressed:
                        _loading
                            ? null
                            : _login,

                    icon: const Icon(
                      Icons.login,
                    ),

                    label: Text(
                      _loading
                          ? 'MEMPROSES...'
                          : 'LOGIN',

                      style:
                          const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // VOICE INFO
                // =================================================

                const Icon(
                  Icons.record_voice_over,
                  size: 55,
                ),

                const SizedBox(height: 12),

                Text(
                  _voiceLoading
                      ? 'SEDANG MENDENGARKAN...'
                      : 'KETUK AREA KOSONG UNTUK LOGIN DENGAN SUARA',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // ERROR
                // =================================================

                if (_errorMessage
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 10,
                    ),

                    child: Text(
                      _errorMessage,
                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // =================================================
                // REGISTER
                // =================================================

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    'Belum punya akun? Daftar',
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
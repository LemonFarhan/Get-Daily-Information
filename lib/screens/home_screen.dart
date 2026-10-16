import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/weather_service.dart';
import '../utils/command_parser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();
  final CommandParser _commandParser = CommandParser();
  final WeatherService _weatherService = WeatherService();

  bool _isListening = false;
  String _lastCommand = '';
  String _lastResponse = '';

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    await _ttsService.initialize();
    await _speechService.initialize();

    await _ttsService.speak(
      'Selamat datang di Get Daily Information. '
      'Tekan di mana saja untuk memberikan perintah.',
    );
  }

  Future<void> _handleScreenTap() async {
    // Hentikan suara yang sedang berjalan
    await _ttsService.stop();

    // Jangan mulai sesi baru kalau microphone masih aktif
    if (_isListening) {
      return;
    }

    setState(() {
      _isListening = true;
      _lastCommand = '';
    });

    // Beri instruksi kepada pengguna
    await _ttsService.speak('Silakan katakan perintah.');

    final command = await _speechService.listen();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _lastCommand = command;
    });

    if (command.isEmpty) {
      await _ttsService.speak('Maaf, saya tidak mendengar perintah Anda.');

      return;
    }

    await _processCommand(command);
  }

  Future<void> _processCommand(String command) async {
    if (command.toLowerCase().contains('ulangi')) {
      if (_lastResponse.isEmpty) {
        await _ttsService.speak('Belum ada informasi untuk diulangi.');
      } else {
        await _ttsService.speak(_lastResponse);
      }

      return;
    }

    final commandType = _commandParser.parse(command);

    switch (commandType) {
      case 'day':
        await _sayDay();
        break;

      case 'date':
        await _sayDate();
        break;

      case 'time':
        await _sayTime();
        break;

      case 'weather':
        await _sayWeather();
        break;

      case 'exitapplication':
        await _exitApplication();
        break;

      default:
        await _ttsService.speak('Maaf, saya belum memahami perintah tersebut.');
        break;
    }
  }

  Future<void> _sayDay() async {
    final now = DateTime.now();

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    final today = days[now.weekday - 1];

    _lastResponse = 'Hari ini adalah $today.';

    await _ttsService.speak(_lastResponse);
  }

  Future<void> _sayDate() async {
    final now = DateTime.now();

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    _lastResponse =
        'Hari ini tanggal ${now.day} '
        '${months[now.month - 1]} '
        '${now.year}.';

    await _ttsService.speak(_lastResponse);
  }

  Future<void> _sayTime() async {
    final now = DateTime.now();

    _lastResponse = 'Sekarang pukul ${now.hour} lewat ${now.minute} menit.';

    await _ttsService.speak(_lastResponse);
  }

  Future<void> _sayWeather() async {
    try {
      await _ttsService.speak(
        'Sebentar, saya mengambil informasi cuaca Batam.',
      );

      final data = await _weatherService.getTodayWeather();

      final current = data['current'] as Map<String, dynamic>;

      final daily = data['daily'] as Map<String, dynamic>;

      final temperature = (current['temperature_2m'] as num).round();

      final apparentTemperature = (current['apparent_temperature'] as num)
          .round();

      final humidity = (current['relative_humidity_2m'] as num).round();

      final windSpeed = (current['wind_speed_10m'] as num).round();

      final precipitation = (current['precipitation'] as num).toDouble();

      final weatherCode = (current['weather_code'] as num).toInt();

      final isDay = (current['is_day'] as num).toInt() == 1;

      final maxTemperature = (daily['temperature_2m_max'][0] as num).round();

      final minTemperature = (daily['temperature_2m_min'][0] as num).round();

      final rainProbability = (daily['precipitation_probability_max'][0] as num)
          .round();

      final description = _weatherService.getWeatherDescription(
        weatherCode,
        isDay: isDay,
      );

      final timeDescription = isDay
          ? 'saat ini siang hari'
          : 'saat ini malam hari';

      _lastResponse =
          'Di Batam, $timeDescription. '
          'Kondisi cuaca $description, '
          'dengan suhu $temperature derajat Celsius. '
          'Suhu terasa seperti $apparentTemperature derajat. '
          'Kelembapan $humidity persen. '
          'Kecepatan angin $windSpeed kilometer per jam. '
          'Suhu hari ini diperkirakan antara '
          '$minTemperature sampai $maxTemperature derajat Celsius. '
          'Peluang hujan $rainProbability persen. '
          'Curah hujan saat ini $precipitation milimeter.';

      await _ttsService.speak(_lastResponse);
    } catch (e) {
      _lastResponse = 'Maaf, informasi cuaca Batam sedang tidak tersedia.';

      await _ttsService.speak(_lastResponse);
    }
  }

  Future<void> _exitApplication() async {
    await _ttsService.speak(
      'Terima kasih telah menggunakan Get Daily Information. '
      'Sampai jumpa!',
    );

    // Delay untuk memastikan TTS selesai sebelum keluar
    await Future.delayed(const Duration(seconds: 2));

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroSize = (constraints.maxWidth * 0.38).clamp(190.0, 290.0);
            final touchSize = (constraints.maxWidth * 0.25).clamp(140.0, 190.0);
            final titleSize = (constraints.maxWidth * 0.065).clamp(27.0, 44.0);

            return Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _HomeBackgroundPainter()),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleScreenTap,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: heroSize,
                                  height: heroSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      heroSize * 0.42,
                                    ),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFDDF2FF),
                                        Color(0xFFEAF6FF),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.record_voice_over_rounded,
                                    size: 148,
                                    color: Color(0xFF1674E8),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'GET DAILY',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF3484E8),
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.12,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                Text(
                                  'INFORMATION',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF0B3C8C),
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.12,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                Container(
                                  width: 110,
                                  height: 8,
                                  margin: const EdgeInsets.only(
                                    top: 26,
                                    bottom: 38,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF9BD2FF),
                                  ),
                                ),
                                Container(
                                  width: touchSize,
                                  height: touchSize,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFDDF2FF),
                                        Color(0xFFCFEAFF),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    _isListening
                                        ? Icons.mic_rounded
                                        : Icons.touch_app_rounded,
                                    size: touchSize * 0.62,
                                    color: const Color(0xFF1686F5),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD8EEFF),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFFC2E3FF),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    _isListening
                                        ? 'SEDANG MENDENGARKAN'
                                        : 'TEKAN DI MANA SAJA',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF1264CC),
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Ketuk layar untuk memberikan\nperintah suara.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF4C6078),
                                    fontSize: 18,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 42),
                                _LastCommandCard(
                                  command: _lastCommand.isEmpty
                                      ? 'Belum ada perintah'
                                      : _lastCommand,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LastCommandCard extends StatelessWidget {
  const _LastCommandCard({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEFF).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFB9DFFF), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFCBE7FF),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52,
              color: Color(0xFF1674E8),
            ),
          ),
          const SizedBox(width: 18),
          Container(width: 2, height: 92, color: const Color(0xFFB1D9FF)),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERINTAH TERAKHIR:',
                  style: TextStyle(
                    color: Color(0xFF5298ED),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  command,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF124DA7),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF7FBFF), Color(0xFFEDF7FF), Color(0xFFE4F3FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final topShape = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.36, 0)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.11,
        size.width * 0.07,
        size.height * 0.08,
        0,
        size.height * 0.19,
      )
      ..close();
    final topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC6E4FF), Color(0xFFE2F2FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.4, size.height * 0.2));
    canvas.drawPath(topShape, topPaint);

    final bottomShape = Path()
      ..moveTo(size.width * 0.56, size.height)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.91,
        size.width * 0.94,
        size.height * 0.97,
        size.width,
        size.height * 0.82,
      )
      ..lineTo(size.width, size.height)
      ..close();
    final bottomPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB8DEFF), Color(0xFF83C5FF)],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.56,
              size.height * 0.82,
              size.width * 0.44,
              size.height * 0.18,
            ),
          );
    canvas.drawPath(bottomShape, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) => false;
}

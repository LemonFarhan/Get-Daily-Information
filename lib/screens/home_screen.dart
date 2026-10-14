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
  await _ttsService.speak(
    'Silakan katakan perintah.',
  );

  final command = await _speechService.listen();

  if (!mounted) return;

  setState(() {
    _isListening = false;
    _lastCommand = command;
  });

  if (command.isEmpty) {
    await _ttsService.speak(
      'Maaf, saya tidak mendengar perintah Anda.',
    );

    return;
  }

  await _processCommand(command);
}

  Future<void> _processCommand(String command) async {
  if (command.toLowerCase().contains('ulangi')) {
    if (_lastResponse.isEmpty) {
      await _ttsService.speak(
        'Belum ada informasi untuk diulangi.',
      );
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
      await _ttsService.speak(
        'Maaf, saya belum memahami perintah tersebut.',
      );
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

  _lastResponse =
      'Sekarang pukul ${now.hour} lewat ${now.minute} menit.';

  await _ttsService.speak(_lastResponse);
}

Future<void> _sayWeather() async {
  try {
    await _ttsService.speak(
      'Sebentar, saya mengambil informasi cuaca Batam.',
    );

    final data = await _weatherService.getTodayWeather();

    final current =
        data['current'] as Map<String, dynamic>;

    final daily =
        data['daily'] as Map<String, dynamic>;

    final temperature =
        (current['temperature_2m'] as num).round();

    final apparentTemperature =
        (current['apparent_temperature'] as num).round();

    final humidity =
        (current['relative_humidity_2m'] as num).round();

    final windSpeed =
        (current['wind_speed_10m'] as num).round();

    final precipitation =
        (current['precipitation'] as num).toDouble();

    final weatherCode =
        (current['weather_code'] as num).toInt();

    final isDay =
        (current['is_day'] as num).toInt() == 1;
        
    final maxTemperature =
        (daily['temperature_2m_max'][0] as num).round();

    final minTemperature =
        (daily['temperature_2m_min'][0] as num).round();

    final rainProbability =
        (daily['precipitation_probability_max'][0] as num)
            .round();

    final description =
    _weatherService.getWeatherDescription(
  weatherCode,
  isDay: isDay,
);

    final timeDescription =
    isDay ? 'saat ini siang hari' : 'saat ini malam hari';

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
    _lastResponse =
        'Maaf, informasi cuaca Batam sedang tidak tersedia.';

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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleScreenTap,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                Icon(
                  _isListening
                      ? Icons.mic
                      : Icons.touch_app,
                  size: 80,
                ),

                const SizedBox(height: 20),

                Text(
                  _isListening
                      ? 'SEDANG MENDENGARKAN'
                      : 'TEKAN DI MANA SAJA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Ketuk layar untuk memberikan '
                  'perintah suara.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                if (_lastCommand.isNotEmpty) ...[
                  const SizedBox(height: 40),

                  Text(
                    'Perintah terakhir:\n$_lastCommand',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/weather_service.dart';
import '../utils/command_parser.dart';

enum _AssistantState { ready, listening, processing, responding, result }

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

  _AssistantState _assistantState = _AssistantState.ready;
  String _lastCommand = '';
  String _lastResponse = '';
  _AssistantResult? _result;

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    await _ttsService.initialize();
    await _speechService.initialize();
    await _ttsService.speak(
      'Selamat datang di DailyBrief. '
      'Ketuk di mana saja atau ucapkan perintah.',
    );
  }

  Future<void> _handleScreenTap() async {
    if (_assistantState == _AssistantState.listening ||
        _assistantState == _AssistantState.processing ||
        _assistantState == _AssistantState.responding) {
      return;
    }

    await _ttsService.stop();

    setState(() {
      _assistantState = _AssistantState.listening;
      _lastCommand = '';
    });

    final command = await _speechService.listen();
    if (!mounted) return;

    setState(() {
      _lastCommand = command;
      _assistantState = _AssistantState.processing;
    });

    if (command.isEmpty) {
      await _presentResult(
        'Maaf, saya tidak mendengar perintah Anda.',
        const _AssistantResult(
          label: 'BELUM ADA PERINTAH',
          title: 'Suara belum terdengar',
          subtitle: 'Silakan coba ucapkan perintah sekali lagi.',
          icon: Icons.mic_off_rounded,
        ),
      );
      return;
    }

    await _processCommand(command);
  }

  Future<void> _processCommand(String command) async {
    final commandType = _commandParser.parse(command);

    switch (commandType) {
      case 'repeat':
        if (_lastResponse.isEmpty || _result == null) {
          await _presentResult(
            'Belum ada informasi untuk diulangi.',
            const _AssistantResult(
              label: 'INFORMASI',
              title: 'Belum ada jawaban',
              subtitle: 'Ajukan pertanyaan terlebih dahulu.',
              icon: Icons.info_outline_rounded,
            ),
          );
        } else {
          await _presentResult(_lastResponse, _result!);
        }
        break;
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
        await _presentResult(
          'Maaf, saya belum memahami perintah tersebut.',
          const _AssistantResult(
            label: 'PERINTAH',
            title: 'Belum dipahami',
            subtitle: 'Coba tanyakan hari, tanggal, jam, atau cuaca.',
            icon: Icons.help_outline_rounded,
          ),
        );
    }
  }

  Future<void> _sayDay() async {
    final now = DateTime.now();
    final day = _dayName(now.weekday);
    final date = '${now.day} ${_monthName(now.month)} ${now.year}';
    final response = 'Hari ini adalah $day.';

    await _presentResult(
      response,
      _AssistantResult(
        label: 'HARI INI',
        title: 'Hari $day',
        subtitle: date,
        icon: Icons.calendar_today_rounded,
      ),
    );
  }

  Future<void> _sayDate() async {
    final now = DateTime.now();
    final date = '${now.day} ${_monthName(now.month)} ${now.year}';
    final response = 'Hari ini tanggal $date.';

    await _presentResult(
      response,
      _AssistantResult(
        label: 'TANGGAL HARI INI',
        title: date,
        subtitle: _dayName(now.weekday),
        icon: Icons.event_rounded,
      ),
    );
  }

  Future<void> _sayTime() async {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}.'
        '${now.minute.toString().padLeft(2, '0')}';
    final response = 'Sekarang pukul ${now.hour} lewat ${now.minute} menit.';

    await _presentResult(
      response,
      _AssistantResult(
        label: 'WAKTU SEKARANG',
        title: time,
        subtitle:
            '${_dayName(now.weekday)}, ${now.day} '
            '${_monthName(now.month)} ${now.year}',
        icon: Icons.schedule_rounded,
      ),
    );
  }

  Future<void> _sayWeather() async {
    try {
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
      final maxTemperature = (daily['temperature_2m_max'] as List).first as num;
      final minTemperature = (daily['temperature_2m_min'] as List).first as num;
      final rainProbability =
          (daily['precipitation_probability_max'] as List).first as num;
      final description = _weatherService.getWeatherDescription(
        weatherCode,
        isDay: isDay,
      );
      final spokenDescription = isDay
          ? 'saat ini siang hari'
          : 'saat ini malam hari';

      final response =
          'Di Batam, $spokenDescription. '
          'Kondisi cuaca $description, dengan suhu $temperature derajat Celsius. '
          'Suhu terasa seperti $apparentTemperature derajat. '
          'Kelembapan $humidity persen. '
          'Kecepatan angin $windSpeed kilometer per jam. '
          'Suhu hari ini diperkirakan antara '
          '${minTemperature.round()} sampai ${maxTemperature.round()} '
          'derajat Celsius. Peluang hujan ${rainProbability.round()} persen. '
          'Curah hujan saat ini $precipitation milimeter.';

      await _presentResult(
        response,
        _AssistantResult(
          label: 'CUACA HARI INI',
          title: _capitalize(description),
          subtitle: 'Batam · $temperature°C',
          icon: _weatherIcon(weatherCode),
          detail:
              'Terasa $apparentTemperature°C  ·  '
              'Kelembapan $humidity%  ·  Angin $windSpeed km/jam\n'
              'Hujan ${rainProbability.round()}%  ·  '
              '${minTemperature.round()}°–${maxTemperature.round()}° hari ini',
        ),
      );
    } catch (error) {
      debugPrint('Failed to retrieve weather information: $error');
      const response = 'Maaf, informasi cuaca Batam sedang tidak tersedia.';
      await _presentResult(
        response,
        const _AssistantResult(
          label: 'CUACA HARI INI',
          title: 'Cuaca tidak tersedia',
          subtitle: 'Periksa koneksi internet lalu coba lagi.',
          icon: Icons.cloud_off_rounded,
        ),
      );
    }
  }

  Future<void> _presentResult(String response, _AssistantResult result) async {
    _lastResponse = response;
    if (!mounted) return;
    setState(() {
      _result = result;
      _assistantState = _AssistantState.responding;
    });
    await _ttsService.speak(response);
    if (!mounted) return;
    setState(() => _assistantState = _AssistantState.result);
  }

  Future<void> _exitApplication() async {
    await _ttsService.speak(
      'Terima kasih telah menggunakan DailyBrief. Sampai jumpa!',
    );
    await Future.delayed(const Duration(seconds: 2));
    SystemNavigator.pop();
  }

  String _dayName(int weekday) => const [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ][weekday - 1];

  String _monthName(int month) => const [
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
  ][month - 1];

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  IconData _weatherIcon(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny_outlined;
    if (code == 2 || code == 3) return Icons.wb_cloudy_outlined;
    if (code == 45 || code == 48) return Icons.blur_on_rounded;
    if (code >= 95) return Icons.thunderstorm_outlined;
    if (code >= 51 && code <= 82) return Icons.umbrella_outlined;
    return Icons.cloud_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleScreenTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 700;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildHeader(),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child:
                              _assistantState == _AssistantState.result ||
                                  _assistantState == _AssistantState.responding
                              ? _buildResultView(isCompact)
                              : _buildVoiceView(isCompact),
                        ),
                      ),
                    ),
                    _buildFooter(isCompact),
                    SizedBox(height: isCompact ? 22 : 38),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isReady = _assistantState == _AssistantState.ready;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReady
                  ? Icons.radio_button_checked_rounded
                  : _assistantState == _AssistantState.listening
                  ? Icons.graphic_eq_rounded
                  : Icons.circle,
              color: const Color(0xFF2563EB),
              size: 21,
            ),
            const SizedBox(width: 9),
            const Text(
              'DailyBrief',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_assistantState == _AssistantState.ready) ...[
          const SizedBox(height: 17),
          const Text(
            'SIAP MENERIMA PERINTAH',
            style: TextStyle(
              color: Color(0xFF8A9BB4),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceView(bool isCompact) {
    final listening = _assistantState == _AssistantState.listening;
    final processing = _assistantState == _AssistantState.processing;
    final diameter = isCompact ? 220.0 : 260.0;
    final centerSize = isCompact ? 84.0 : 96.0;

    return Column(
      key: const ValueKey('voice'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDCE8FF), width: 1),
                ),
              ),
              Container(
                width: diameter * 0.75,
                height: diameter * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: processing ? const Color(0xFFF8FAFF) : Colors.white,
                  border: Border.all(color: const Color(0xFFBFD5FF), width: 1),
                ),
              ),
              if (processing)
                Container(
                  width: diameter * 0.88,
                  height: diameter * 0.88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDCE8FF),
                      width: 1,
                    ),
                  ),
                ),
              Container(
                width: centerSize,
                height: centerSize,
                decoration: const BoxDecoration(
                  color: Color(0xFF234FDC),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33234FDC),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: centerSize * 0.43,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 28 : 38),
        if (listening || processing)
          Text(
            listening ? 'Mendengarkan...' : 'Sedang Memproses...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF172033),
              fontSize: isCompact ? 20 : 22,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          const SizedBox.shrink(),
        if (listening || processing) const SizedBox(height: 10),
        if (listening || processing)
          Text(
            listening ? 'Silakan ucapkan perintah Anda' : 'Mohon tunggu sebentar, sistem sedang\nmencari informasi untuk Anda',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF617493),
              fontSize: 14,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildResultView(bool isCompact) {
    final result = _result;
    if (result == null) return _buildVoiceView(isCompact);

    return Padding(
      key: const ValueKey('result'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 22,
          vertical: isCompact ? 24 : 30,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F3F8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080B1B36),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF647895),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 22),
            Icon(result.icon, color: const Color(0xFF3168F5), size: 42),
            const SizedBox(height: 14),
            Text(
              result.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF172033),
                fontSize: isCompact ? 22 : 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF617493),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (result.detail != null) ...[
              const SizedBox(height: 16),
              Text(
                result.detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF617493),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
            if (_lastCommand.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Perintah: “$_lastCommand”',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8796AC), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isCompact) {
    if (_assistantState == _AssistantState.listening ||
        _assistantState == _AssistantState.processing) {
      return const SizedBox.shrink();
    }

    final prompt = _assistantState == _AssistantState.responding
        ? 'Sedang berbicara...'
        : _assistantState == _AssistantState.result
        ? 'Ketuk mikrofon untuk bertanya lagi'
        : 'Ketuk di mana saja atau ucapkan\nperintah';

    return Column(
      children: [
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF617493),
            fontSize: isCompact ? 13 : 14,
            height: 1.45,
          ),
        ),
        if (_assistantState == _AssistantState.result) ...[
          const SizedBox(height: 18),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFABD0FF),
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 25),
          ),
        ],
      ],
    );
  }
}

class _AssistantResult {
  const _AssistantResult({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.detail,
  });

  final String label;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? detail;
}

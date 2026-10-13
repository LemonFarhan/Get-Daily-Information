import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  // Koordinat sekitar Batam
  static const double latitude = 1.1303;
  static const double longitude = 104.0529;

  Future<Map<String, dynamic>> getTodayWeather() async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'precipitation,weather_code,wind_speed_10m,is_day'
      '&daily=temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max,weather_code'
      '&timezone=auto',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data cuaca');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String getWeatherDescription(
  int code, {
  required bool isDay,
}) {
  switch (code) {
    case 0:
      return 'langit cerah';

    case 1:
      return isDay
          ? 'sebagian besar cerah'
          : 'sebagian besar cerah pada malam hari';

    case 2:
      return isDay
          ? 'cerah berawan'
          : 'sebagian berawan pada malam hari';

    case 3:
      return 'berawan';

    case 45:
    case 48:
      return 'berkabut';

    case 51:
    case 53:
    case 55:
      return 'gerimis';

    case 61:
    case 63:
    case 65:
      return 'hujan';

    case 66:
    case 67:
      return 'hujan membeku';

    case 71:
    case 73:
    case 75:
      return 'salju';

    case 77:
      return 'butiran salju';

    case 80:
    case 81:
    case 82:
      return 'hujan deras';

    case 85:
    case 86:
      return 'hujan salju';

    case 95:
      return 'badai petir';

    case 96:
    case 99:
      return 'badai petir dengan hujan es';

    default:
      return 'kondisi cuaca tidak diketahui';
  }
}
}
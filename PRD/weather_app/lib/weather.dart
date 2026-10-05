import 'dart:convert';

import 'package:http/http.dart' as http;

/// 오늘 날씨 (PRD #4-3)
class Weather {
  const Weather({
    required this.code,
    required this.temperature,
    required this.max,
    required this.min,
    required this.rainChance,
  });

  final int code; // WMO 날씨 코드
  final double temperature;
  final double max;
  final double min;
  final int rainChance; // 퍼센트

  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    return Weather(
      code: current['weather_code'] as int,
      temperature: (current['temperature_2m'] as num).toDouble(),
      max: (daily['temperature_2m_max'][0] as num).toDouble(),
      min: (daily['temperature_2m_min'][0] as num).toDouble(),
      rainChance: (daily['precipitation_probability_max'][0] as num? ?? 0)
          .toInt(),
    );
  }
}

/// Open-Meteo에서 오늘 날씨를 가져온다. 가입·키가 필요 없다 (PRD #7-2)
Future<Weather> fetchWeather({
  required double latitude,
  required double longitude,
  http.Client? client,
}) async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '$latitude',
    'longitude': '$longitude',
    'current': 'temperature_2m,weather_code',
    'daily':
        'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    'timezone': 'auto', // "오늘"은 사용자 위치의 시간 기준 (PRD #8-5)
    'forecast_days': '1',
  });
  final res = await (client?.get(uri) ?? http.get(uri));
  if (res.statusCode != 200) {
    throw http.ClientException('날씨 서버 응답 ${res.statusCode}', uri);
  }
  return Weather.fromJson(jsonDecode(res.body));
}

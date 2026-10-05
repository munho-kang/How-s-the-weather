import 'dart:convert';

import 'package:http/http.dart' as http;

class Weather {
  final double temperature;
  final double max;
  final double min;
  final int rainChance;
  final int code;

  Weather({
    required this.temperature,
    required this.max,
    required this.min,
    required this.rainChance,
    required this.code,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      code: current['weather_code'] as int,
      max: (daily['temperature_2m_max'][0] as num).toDouble(),
      min: (daily['temperature_2m_min'][0] as num).toDouble(),
      rainChance: (daily['precipitation_probability_max'][0] as num).toInt(),
    );
  }

  String get description => describeCode(code);

  String toSentence() =>
      '오늘 서울 날씨는 $description입니다. '
      '현재 기온은 ${temperature.round()}도이고, '
      '최고 ${max.round()}도, 최저 ${min.round()}도입니다. '
      '비 올 확률은 $rainChance퍼센트입니다.';
}

// WMO 날씨 코드 → 한국어
String describeCode(int code) {
  if (code == 0) return '맑음';
  if (code <= 2) return '구름 조금';
  if (code == 3) return '흐림';
  if (code <= 48) return '안개';
  if (code <= 57) return '이슬비';
  if (code <= 67) return '비';
  if (code <= 77) return '눈';
  if (code <= 82) return '소나기';
  if (code <= 86) return '눈보라';
  return '뇌우';
}

// ponytail: 서울 고정 좌표, 위치 기반은 필요해지면 추가
Future<Weather> fetchWeather() async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '37.5665',
    'longitude': '126.978',
    'current': 'temperature_2m,weather_code',
    'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    'timezone': 'Asia/Seoul',
    'forecast_days': '1',
  });
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('날씨 정보를 가져오지 못했습니다 (${res.statusCode})');
  }
  return Weather.fromJson(jsonDecode(res.body));
}

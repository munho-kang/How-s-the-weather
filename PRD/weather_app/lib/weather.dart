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

/// WMO 날씨 코드를 한국어 하늘 상태로 바꾼다 (PRD #4-3, #10-3)
String describeSky(int code) {
  if (code == 0) return '맑음';
  if (code <= 2) return '구름 조금';
  if (code == 3) return '흐림';
  if (code <= 48) return '안개';
  if (code <= 57) return '이슬비';
  if (code <= 67) return '비';
  if (code <= 77) return '눈';
  if (code <= 82) return '소나기';
  if (code <= 86) return '눈보라';
  return '천둥 번개';
}

/// 비 올 확률이 50% 이상이거나 지금 비·눈이 오면 우산이 필요하다 (PRD #4-3)
bool needsUmbrella(Weather w) => w.rainChance >= 50 || w.code >= 51;

String umbrellaAdvice(Weather w) =>
    needsUmbrella(w) ? '우산을 챙기세요.' : '우산은 챙기지 않아도 돼요.';

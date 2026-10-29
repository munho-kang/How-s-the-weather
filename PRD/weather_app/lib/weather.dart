import 'dart:convert';

import 'package:http/http.dart' as http;

import 'location.dart';

/// 오늘 날씨 (PRD #4-3)
class Weather {
  const Weather({
    required this.code,
    required this.temperature,
    required this.max,
    required this.min,
    required this.rainChance,
    this.yesterdayMax,
    this.yesterdayMin,
  });

  final int code; // WMO 날씨 코드
  final double temperature;
  final double max;
  final double min;
  final int rainChance; // 퍼센트
  final double? yesterdayMax; // 어제 기온, 못 받으면 null (PRD #4-6)
  final double? yesterdayMin;

  /// daily 배열은 [어제, 오늘] 순서 (past_days=1)
  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    final List maxes = daily['temperature_2m_max'];
    final List mins = daily['temperature_2m_min'];
    double? yesterday(List l) =>
        l.length > 1 ? (l.first as num?)?.toDouble() : null;
    return Weather(
      code: current['weather_code'] as int,
      temperature: (current['temperature_2m'] as num).toDouble(),
      max: (maxes.last as num).toDouble(),
      min: (mins.last as num).toDouble(),
      rainChance: (daily['precipitation_probability_max'].last as num? ?? 0)
          .toInt(),
      yesterdayMax: yesterday(maxes),
      yesterdayMin: yesterday(mins),
    );
  }
}

/// Open-Meteo에서 오늘 날씨를 가져온다. 가입·키가 필요 없다 (PRD #7-2)
Future<Weather> fetchWeather({
  required double latitude,
  required double longitude,
  http.Client? client,
  Duration timeout = const Duration(seconds: 4),
}) async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '$latitude',
    'longitude': '$longitude',
    'current': 'temperature_2m,weather_code',
    'daily':
        'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    'timezone': 'auto', // "오늘"은 사용자 위치의 시간 기준 (PRD #8-5)
    'forecast_days': '1',
    'past_days': '1', // 어제 기온도 같은 요청으로 받는다 (PRD #4-6)
  });
  // 10초 안에 답해야 하므로 오래 걸리면 포기한다 (PRD #10-2)
  // 말 끝난 뒤 듣기 종료 2초 + 위치 3초 + 날씨 4초 = 최악 9초
  final res = await (client?.get(uri) ?? http.get(uri)).timeout(timeout);
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

/// 소리로 듣기 좋게 기온을 읽는다. 예: -3.4 → "영하 3도"
String degrees(double t) {
  final n = t.round();
  return n < 0 ? '영하 ${-n}도' : '$n도';
}

/// 한 기온을 어제와 비교한 말. 1도 이하 차이는 비슷하다고 한다 (PRD #9-5)
/// [end]면 문장을 끝맺고("더워요"), 아니면 뒤로 잇는다("덥고").
String _vsYesterday(
  String which,
  double today,
  double yesterday, {
  required bool end,
}) {
  final diff = today.round() - yesterday.round();
  if (diff.abs() <= 1) return '$which 기온은 어제와 ${end ? '비슷해요' : '비슷하고'}';
  return diff > 0
      ? '$which 기온은 어제보다 $diff도 높아 더 ${end ? '더워요' : '덥고'}'
      : '$which 기온은 어제보다 ${-diff}도 낮아 더 ${end ? '추워요' : '춥고'}';
}

/// 최고·최저 기온을 어제와 비교한 문장 (PRD #4-6)
/// 예: "최고 기온은 어제보다 3도 높아 더 덥고, 최저 기온은 어제와 비슷해요."
String compareYesterday(Weather w) {
  final high = _vsYesterday('최고', w.max, w.yesterdayMax!, end: false);
  final low = _vsYesterday('최저', w.min, w.yesterdayMin!, end: true);
  if (high.endsWith('비슷하고') && low.endsWith('비슷해요')) {
    return '최고·최저 기온 모두 어제와 비슷해요.';
  }
  return '$high, $low.';
}

/// 5가지 정보를 모두 담은 날씨 문장 (PRD #10-3)
/// 어제 비교는 최고·최저 기온 바로 뒤에 넣는다 (PRD #4-6, #10-9)
String weatherSentence(Weather w, {required String place}) =>
    '오늘 $place 날씨는 ${describeSky(w.code)}입니다. '
    '지금 기온은 ${degrees(w.temperature)}, '
    '최고 ${degrees(w.max)}, 최저 ${degrees(w.min)}입니다. '
    '${compareYesterday(w)} '
    '비 올 확률은 ${w.rainChance}퍼센트, ${umbrellaAdvice(w)}';

const noLocation = '위치를 알 수 없어 서울 날씨를 알려드려요.';

/// 서울 시청 좌표
const seoulLat = 37.5665, seoulLon = 126.978;

Future<Weather> _fetch(double lat, double lon) =>
    fetchWeather(latitude: lat, longitude: lon);

/// 현재 위치의 날씨 답 문장 (PRD #4-4)
Future<String> weatherAnswer({
  Future<Coords?> Function() locate = currentPosition,
  Future<Weather> Function(double lat, double lon) fetch = _fetch,
}) async {
  final here = await locate();
  if (here == null) {
    // 위치를 모르면 이유를 말하고 서울 날씨로 대신한다 (PRD #9-1, #10-4)
    final w = await fetch(seoulLat, seoulLon);
    return '$noLocation ${weatherSentence(w, place: '서울')}';
  }
  return weatherSentence(await fetch(here.lat, here.lon), place: '현재 위치');
}

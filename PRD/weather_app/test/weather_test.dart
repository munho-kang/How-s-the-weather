import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:weather_app/weather.dart';

const clear = Weather(
  code: 0,
  temperature: 14.4,
  max: 19.3,
  min: 13.3,
  rainChance: 10,
);

void main() {
  test('날씨 코드를 한국어 하늘 상태로 바꾼다', () {
    expect(describeSky(0), '맑음');
    expect(describeSky(2), '구름 조금');
    expect(describeSky(3), '흐림');
    expect(describeSky(45), '안개');
    expect(describeSky(63), '비');
    expect(describeSky(73), '눈');
    expect(describeSky(81), '소나기');
    expect(describeSky(95), '천둥 번개');
  });

  test('비 올 확률 50% 이상이거나 지금 비가 오면 우산이 필요하다', () {
    expect(needsUmbrella(clear), isFalse);
    expect(
      needsUmbrella(
        const Weather(code: 3, temperature: 0, max: 0, min: 0, rainChance: 50),
      ),
      isTrue,
    );
    expect(
      needsUmbrella(
        const Weather(code: 61, temperature: 0, max: 0, min: 0, rainChance: 0),
      ),
      isTrue,
    );
  });

  test('영하 기온은 "영하 N도"로 읽는다', () {
    expect(degrees(-3.4), '영하 3도');
    expect(degrees(0.2), '0도');
    expect(degrees(19.6), '20도');
  });

  test('날씨 문장에 5가지 정보가 모두 들어 있다', () {
    expect(
      weatherSentence(clear, place: '서울'),
      '오늘 서울 날씨는 맑음입니다. 지금 기온은 14도, 최고 19도, 최저 13도입니다. '
      '비 올 확률은 10퍼센트, 우산은 챙기지 않아도 돼요.',
    );
  });

  test('Open-Meteo 응답을 읽는다', () async {
    final client = MockClient((req) async {
      expect(req.url.host, 'api.open-meteo.com');
      expect(req.url.queryParameters['latitude'], '37.5');
      return http.Response(
        jsonEncode({
          'current': {'temperature_2m': 14.4, 'weather_code': 0},
          'daily': {
            'temperature_2m_max': [19.3],
            'temperature_2m_min': [13.3],
            'precipitation_probability_max': [96],
          },
        }),
        200,
      );
    });
    final w = await fetchWeather(
      latitude: 37.5,
      longitude: 127,
      client: client,
    );
    expect(w.rainChance, 96);
    expect(w.max, 19.3);
  });

  test('서버 오류면 예외를 던진다', () async {
    final client = MockClient((_) async => http.Response('', 500));
    expect(
      fetchWeather(latitude: 0, longitude: 0, client: client),
      throwsA(isA<http.ClientException>()),
    );
  });
}

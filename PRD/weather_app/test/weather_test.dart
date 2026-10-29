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
  yesterdayMax: 16.4,
  yesterdayMin: 13.0,
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
      '최고 기온은 어제보다 3도 높아 더 덥고, 최저 기온은 어제와 비슷해요. '
      '비 올 확률은 10퍼센트, 우산은 챙기지 않아도 돼요.',
    );
  });

  group('어제와 비교 (7-2 ~ 7-4)', () {
    Weather day(double max, double min, double? yMax, double? yMin) => Weather(
      code: 0,
      temperature: 0,
      max: max,
      min: min,
      rainChance: 0,
      yesterdayMax: yMax,
      yesterdayMin: yMin,
    );

    test('어제보다 높으면 더 덥다, 낮으면 더 춥다고 말한다', () {
      expect(
        compareYesterday(day(20, 10, 17, 13)),
        '최고 기온은 어제보다 3도 높아 더 덥고, 최저 기온은 어제보다 3도 낮아 더 추워요.',
      );
      expect(
        compareYesterday(day(15, 12, 18, 9.6)),
        '최고 기온은 어제보다 3도 낮아 더 춥고, 최저 기온은 어제보다 2도 높아 더 더워요.',
      );
    });

    test('1도 이하 차이는 비슷하다고 말한다', () {
      expect(
        compareYesterday(day(20, 10, 19, 7)),
        '최고 기온은 어제와 비슷하고, 최저 기온은 어제보다 3도 높아 더 더워요.',
      );
      expect(
        compareYesterday(day(20.4, 10, 20.6, 11)),
        '최고·최저 기온 모두 어제와 비슷해요.',
      );
    });

    test('영하끼리도 차이를 바르게 센다', () {
      expect(
        compareYesterday(day(-1, -8, 2, -5)),
        '최고 기온은 어제보다 3도 낮아 더 춥고, 최저 기온은 어제보다 3도 낮아 더 추워요.',
      );
    });

    test('어제 기온이 없으면 비교 문장만 빠진다', () {
      final noYesterday = day(19.3, 13.3, null, null);
      expect(compareYesterday(noYesterday), isNull);
      expect(compareYesterday(day(19.3, 13.3, 16, null)), isNull);
      final text = weatherSentence(noYesterday, place: '서울');
      expect(text, isNot(contains('어제')));
      expect(text, contains('최저 13도입니다. 비 올 확률은'));
    });

    test('서울로 대신 알려줄 때도 비교가 들어간다', () async {
      final text = await weatherAnswer(
        locate: () async => null,
        fetch: (lat, lon) async => clear,
      );
      expect(text, startsWith(noLocation));
      expect(text, contains('최고 기온은 어제보다 3도 높아 더 덥고'));
    });

    test('응답에 어제 칸이 없거나 비어 있으면 어제 기온은 null', () {
      Weather parse(List maxes, List mins) => Weather.fromJson({
        'current': {'temperature_2m': 14.4, 'weather_code': 0},
        'daily': {
          'temperature_2m_max': maxes,
          'temperature_2m_min': mins,
          'precipitation_probability_max': [10],
        },
      });
      final onlyToday = parse([19.3], [13.3]);
      expect(onlyToday.max, 19.3);
      expect(onlyToday.yesterdayMax, isNull);
      final emptyYesterday = parse([null, 19.3], [null, 13.3]);
      expect(emptyYesterday.max, 19.3);
      expect(emptyYesterday.yesterdayMin, isNull);
    });
  });

  test('Open-Meteo 응답을 읽는다', () async {
    final client = MockClient((req) async {
      expect(req.url.host, 'api.open-meteo.com');
      expect(req.url.queryParameters['latitude'], '37.5');
      expect(req.url.queryParameters['past_days'], '1');
      return http.Response(
        jsonEncode({
          'current': {'temperature_2m': 14.4, 'weather_code': 0},
          'daily': {
            'temperature_2m_max': [16.1, 19.3], // [어제, 오늘]
            'temperature_2m_min': [12.8, 13.3],
            'precipitation_probability_max': [20, 96],
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
    expect(w.min, 13.3);
    expect(w.yesterdayMax, 16.1);
    expect(w.yesterdayMin, 12.8);
  });

  test('서버 오류면 예외를 던진다', () async {
    final client = MockClient((_) async => http.Response('', 500));
    expect(
      fetchWeather(latitude: 0, longitude: 0, client: client),
      throwsA(isA<http.ClientException>()),
    );
  });
}

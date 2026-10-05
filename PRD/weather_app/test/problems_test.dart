import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/weather.dart';

const rainy = Weather(
  code: 61,
  temperature: 9,
  max: 12,
  min: 7,
  rainChance: 80,
);

void main() {
  group('위치 (5-1, 5-2)', () {
    test('위치를 알면 그 좌표로 날씨를 찾고 "현재 위치"라고 말한다', () async {
      final asked = <(double, double)>[];
      final text = await weatherAnswer(
        locate: () async => (lat: 35.1, lon: 129.0),
        fetch: (lat, lon) async {
          asked.add((lat, lon));
          return rainy;
        },
      );
      expect(asked, [(35.1, 129.0)]);
      expect(text, startsWith('오늘 현재 위치 날씨는 비입니다.'));
      expect(text, isNot(contains(noLocation)));
    });

    test('위치를 모르면 이유를 말하고 서울 날씨를 알려준다', () async {
      final asked = <(double, double)>[];
      final text = await weatherAnswer(
        locate: () async => null,
        fetch: (lat, lon) async {
          asked.add((lat, lon));
          return rainy;
        },
      );
      expect(asked, [(seoulLat, seoulLon)]);
      expect(text, startsWith('$noLocation 오늘 서울 날씨는 비입니다.'));
    });
  });

  group('날씨 조회 (5-3, 5-5)', () {
    test('인터넷이 끊기면 예외를 던진다', () async {
      final client = MockClient(
        (req) async => throw http.ClientException('offline', req.url),
      );
      expect(
        fetchWeather(latitude: 0, longitude: 0, client: client),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('서버가 늦으면 시간 제한에서 끊는다', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      expect(
        fetchWeather(
          latitude: 0,
          longitude: 0,
          client: client,
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('화면 안내 (5-3, 5-4)', () {
    Future<List<String>> run(
      WidgetTester tester, {
      required String? heard,
      required Future<String> Function() answer,
    }) async {
      final spoken = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            answer: answer,
            speak: (t) async => spoken.add(t),
            listen: () async => heard,
          ),
        ),
      );
      await tester.tap(find.text('날씨 물어보기'));
      await tester.pumpAndSettle();
      return spoken;
    }

    testWidgets('날씨를 못 가져오면 인터넷 확인 안내를 읽어준다', (tester) async {
      final spoken = await run(
        tester,
        heard: '오늘 날씨가 뭐야',
        answer: () async => throw TimeoutException('slow'),
      );
      expect(spoken.last, noInternet);
      expect(find.text(noInternet), findsOneWidget);
    });

    testWidgets('마이크를 쓸 수 없으면 권한 켜는 방법을 읽어준다', (tester) async {
      final spoken = await run(
        tester,
        heard: null,
        answer: () async => fail('날씨를 찾으면 안 된다'),
      );
      expect(spoken.last, noMic);
      expect(noMic, contains('설정 앱'));
    });
  });
}

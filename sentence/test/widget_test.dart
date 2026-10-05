import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/voice.dart';
import 'package:weather_app/weather.dart';

Future<Weather> fakeWeather() async =>
    Weather(temperature: 20, max: 25, min: 15, rainChance: 30, code: 3);

Widget app({
  Future<Weather> Function() fetch = fakeWeather,
  String? heard = '오늘 날씨가 뭐야',
  List<String>? spoken,
}) =>
    MaterialApp(
      home: HomePage(
        fetch: fetch,
        listen: () async => heard,
        speak: (t) async => spoken?.add(t),
      ),
    );

void main() {
  test('날씨 질문인지 알아본다', () {
    expect(isWeatherQuestion('오늘 날씨가 뭐야'), isTrue);
    expect(isWeatherQuestion('지금 몇 시야'), isFalse);
  });

  testWidgets('"오늘 날씨가 뭐야"라고 물으면 날씨를 보여주고 읽어준다', (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(app(spoken: spoken));

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('흐림'), findsOneWidget);
    expect(spoken.single, contains('흐림'));
  });

  testWidgets('음성 인식을 못 쓰면 바로 날씨를 알려준다', (tester) async {
    await tester.pumpWidget(app(heard: null));

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('흐림'), findsOneWidget);
  });

  testWidgets('날씨와 상관없는 말이면 다시 물어보라고 안내한다', (tester) async {
    await tester.pumpWidget(app(heard: '지금 몇 시야'));

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('"지금 몇 시야"라고 들었어요'), findsOneWidget);
  });

  testWidgets('날씨를 못 가져오면 안내 문장이 보인다', (tester) async {
    Future<Weather> broken() async => throw Exception('offline');
    await tester.pumpWidget(app(fetch: broken));

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('가져오지 못했어요'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/weather.dart';

void main() {
  testWidgets('버튼을 누르면 날씨 문장이 보인다', (tester) async {
    Future<Weather> fake() async => Weather(
          temperature: 20,
          max: 25,
          min: 15,
          rainChance: 30,
          code: 3,
        );
    await tester.pumpWidget(MaterialApp(home: HomePage(fetch: fake)));

    expect(find.text('날씨 물어보기'), findsOneWidget);

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('흐림'), findsOneWidget);
  });

  testWidgets('날씨를 못 가져오면 안내 문장이 보인다', (tester) async {
    Future<Weather> broken() async => throw Exception('offline');
    await tester.pumpWidget(MaterialApp(home: HomePage(fetch: broken)));

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('가져오지 못했어요'), findsOneWidget);
  });
}

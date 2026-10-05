import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/voice.dart';

const sunny = '오늘 서울 날씨는 맑음입니다.';

/// [heard]: 가짜 음성 인식 결과. [spoken]: 앱이 읽은 문장 기록.
Widget app(String? heard, List<String> spoken, {List<String>? calls}) =>
    MaterialApp(
      home: HomePage(
        answer: () async {
          calls?.add('answer');
          return sunny;
        },
        speak: (t) async => spoken.add(t),
        listen: () async {
          calls?.add('listen');
          return heard;
        },
      ),
    );

Future<void> pressAsk(WidgetTester tester) async {
  await tester.tap(find.text('날씨 물어보기'));
  await tester.pumpAndSettle();
}

void main() {
  test('"날씨"가 들어간 말은 날씨 질문이다', () {
    expect(isWeatherQuestion('오늘 날씨가 뭐야'), isTrue);
    expect(isWeatherQuestion('날씨 알려줘'), isTrue);
    expect(isWeatherQuestion('오늘 날 씨 어때'), isTrue);
    expect(isWeatherQuestion('지금 몇 시야'), isFalse);
    expect(isWeatherQuestion(''), isFalse);
  });

  testWidgets('"말씀하세요"라고 안내한 다음에 듣기 시작한다', (tester) async {
    final spoken = <String>[];
    final calls = <String>[];
    await tester.pumpWidget(app('오늘 날씨가 뭐야', spoken, calls: calls));

    await pressAsk(tester);

    expect(spoken.first, '말씀하세요.');
    expect(calls, ['listen', 'answer']);
    expect(spoken.last, sunny);
  });

  testWidgets('버튼을 누르기 전에는 듣지 않는다', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(app('오늘 날씨가 뭐야', [], calls: calls));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  for (final heard in ['지금 몇 시야', '']) {
    testWidgets('"$heard"(이)면 날씨를 찾지 않고 다시 말하라고 안내한다', (tester) async {
      final spoken = <String>[];
      final calls = <String>[];
      await tester.pumpWidget(app(heard, spoken, calls: calls));

      await pressAsk(tester);

      expect(calls, ['listen']);
      expect(spoken.last, askAgain);
      expect(find.text(askAgain), findsOneWidget);
    });
  }

  testWidgets('다시 말하라는 안내 뒤 글을 눌러도 지난 날씨만 다시 읽는다', (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(app('지금 몇 시야', spoken));
    await pressAsk(tester);

    await tester.tap(find.text(askAgain));
    await tester.pumpAndSettle();

    // 날씨를 들은 적이 없으므로 아무것도 다시 읽지 않는다
    expect(spoken.where((t) => t == askAgain).length, 1);
  });
}

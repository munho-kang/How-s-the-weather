import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  group('처음 쓸 때 허락 먼저 받기 (추가-2)', () {
    testWidgets('허락 안내를 먼저 말하고, 그다음에 듣기 시작한다', (tester) async {
      final said = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            prepare: (say) async {
              await say('허용을 눌러 주세요.');
              return true;
            },
            speak: (t) async => said.add(t),
            listen: () async {
              said.add('(듣기)');
              return '오늘 날씨가 뭐야';
            },
            answer: () async => '맑음입니다.',
          ),
        ),
      );
      await tester.tap(find.text('날씨 물어보기'));
      await tester.pumpAndSettle();
      expect(said, ['허용을 눌러 주세요.', '말씀하세요.', '(듣기)', '맑음입니다.']);
    });

    testWidgets('마이크를 허락하지 않으면 듣지 않고 마이크 켜는 방법을 안내한다', (tester) async {
      var listened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            prepare: (_) async => false,
            speak: (_) async {},
            listen: () async {
              listened = true;
              return '오늘 날씨가 뭐야';
            },
            answer: () async => '맑음입니다.',
          ),
        ),
      );
      await tester.tap(find.text('날씨 물어보기'));
      await tester.pumpAndSettle();
      expect(listened, isFalse);
      expect(find.text(noMic), findsOneWidget);
    });
  });
}

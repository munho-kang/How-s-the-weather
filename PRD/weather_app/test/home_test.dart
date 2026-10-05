import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('첫 화면: 큰 버튼과 28pt 이상 안내 글이 보인다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const WeatherApp());

    expect(find.text('날씨 물어보기'), findsOneWidget);
    final message = find.textContaining('오늘 날씨가 뭐야?');
    expect(message, findsOneWidget);
    expect(
      tester.widget<Text>(message).style!.fontSize,
      greaterThanOrEqualTo(28),
    );

    // 버튼은 화면 높이의 절반 이상 (PRD #6-4)
    final buttonHeight = tester.getSize(find.byType(ElevatedButton)).height;
    expect(buttonHeight, greaterThanOrEqualTo(844 / 2));
  });

  testWidgets('VoiceOver가 버튼 이름과 사용법을 읽을 수 있다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const WeatherApp());

    expect(
      tester.getSemantics(find.byType(ElevatedButton)),
      matchesSemantics(
        label: '날씨 물어보기',
        hint: '두 번 탭하면 질문을 듣기 시작합니다',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('버튼을 누르면 날씨 문장이 화면에 나온다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(answer: () async => '오늘 서울 날씨는 맑음입니다.')),
    );
    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 서울 날씨는 맑음입니다.'), findsOneWidget);
  });

  testWidgets('날씨를 못 가져오면 다시 누르라고 안내한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(answer: () async => throw Exception('x'))),
    );
    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('다시 눌러 주세요'), findsOneWidget);
  });
}

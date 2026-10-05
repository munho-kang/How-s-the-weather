import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

const sunny = '오늘 서울 날씨는 맑음입니다.';

Widget app(List<String> spoken) => MaterialApp(
  home: HomePage(
    answer: () async => sunny,
    speak: (t) async => spoken.add(t),
    listen: () async => '오늘 날씨가 뭐야',
  ),
);

void main() {
  testWidgets('날씨 문장을 화면에 보여주고 같은 문장을 읽어준다', (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(app(spoken));

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    expect(find.text(sunny), findsOneWidget);
    expect(spoken.last, sunny);
  });

  testWidgets('결과 글을 누르면 방금 들은 날씨를 다시 읽어준다', (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(app(spoken));
    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();
    final before = spoken.length;

    await tester.tap(find.text(sunny));
    await tester.pumpAndSettle();

    expect(spoken.length, before + 1);
    expect(spoken.last, sunny);
  });

  testWidgets('답이 나오기 전에는 글을 눌러도 아무것도 읽지 않는다', (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(app(spoken));

    await tester.tap(find.textContaining('오늘 날씨가 뭐야?'));
    await tester.pumpAndSettle();

    expect(spoken, isEmpty);
  });

  testWidgets('VoiceOver: 결과 글은 자동으로 읽히지 않고, 다시 듣기 안내가 있다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app([]));
    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.text(sunny));
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isLiveRegion, isFalse);
    expect(data.hint, '두 번 탭하면 다시 들려줍니다');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}

// PRD #10 완성 기준 점검 (Todolist 6단계)
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

/// WCAG 대비율: (밝은 색 + 0.05) / (어두운 색 + 0.05)
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('6-7: 글자와 배경 대비가 WCAG 최고 등급(7:1) 이상이다', () {
    expect(contrast(textColor, background), greaterThanOrEqualTo(7)); // 안내 글
    expect(contrast(background, accent), greaterThanOrEqualTo(7)); // 버튼 글씨
  });

  testWidgets('6-7: 화면의 모든 글씨가 28pt 이상이다', (tester) async {
    await tester.pumpWidget(const WeatherApp());
    final texts = tester.widgetList<Text>(find.byType(Text));
    expect(texts, isNotEmpty);
    for (final t in texts) {
      expect(t.style?.fontSize, greaterThanOrEqualTo(28), reason: t.data);
    }
  });

  testWidgets('6-5: VoiceOver로 쓸어 넘기면 안내 글 → 버튼 순서로 모두 읽힌다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          answer: () async => '오늘 서울 날씨는 맑음입니다.',
          speak: (_) async {},
          listen: () async => '오늘 날씨가 뭐야',
        ),
      ),
    );
    await tester.tap(find.text('날씨 물어보기'));
    await tester.pumpAndSettle();

    // VoiceOver가 읽는 순서대로 이름이 있는 칸만 모은다
    final read = <String>[];
    void visit(SemanticsNode node) {
      final d = node.getSemanticsData();
      if (d.label.isNotEmpty) read.add('${d.label} / ${d.hint}');
      node.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    var root = tester.getSemantics(find.byType(HomePage));
    while (root.parent != null) {
      root = root.parent!;
    }
    visit(root);
    expect(read, [
      '오늘 서울 날씨는 맑음입니다. / 두 번 탭하면 다시 들려줍니다',
      '날씨 물어보기 / 두 번 탭하면 질문을 듣기 시작합니다',
    ]);
    semantics.dispose();
  });
}

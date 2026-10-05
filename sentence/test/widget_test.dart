import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('첫 화면에 날씨 물어보기 버튼이 보인다', (tester) async {
    await tester.pumpWidget(const WeatherApp());

    expect(find.text('날씨 물어보기'), findsOneWidget);

    await tester.tap(find.text('날씨 물어보기'));
    await tester.pump();

    expect(find.text('날씨 기능은 준비 중입니다.'), findsOneWidget);
  });
}

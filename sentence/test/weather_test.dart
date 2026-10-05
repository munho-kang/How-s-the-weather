import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/weather.dart';

void main() {
  test('날씨 코드를 한국어로 바꾼다', () {
    expect(describeCode(0), '맑음');
    expect(describeCode(3), '흐림');
    expect(describeCode(63), '비');
    expect(describeCode(73), '눈');
    expect(describeCode(95), '뇌우');
  });

  test('API 응답으로 날씨 문장을 만든다', () {
    final w = Weather.fromJson({
      'current': {'temperature_2m': 14.4, 'weather_code': 0},
      'daily': {
        'temperature_2m_max': [19.3],
        'temperature_2m_min': [13.3],
        'precipitation_probability_max': [10],
      },
    });
    expect(
      w.toSentence(),
      '오늘 서울 날씨는 맑음입니다. 현재 기온은 14도이고, 최고 19도, 최저 13도입니다. 비 올 확률은 10퍼센트입니다.',
    );
  });
}

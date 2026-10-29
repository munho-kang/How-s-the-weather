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

  test('API 응답(어제, 오늘)으로 날씨 문장을 만든다', () {
    final w = Weather.fromJson({
      'current': {'temperature_2m': 14.4, 'weather_code': 0},
      'daily': {
        'temperature_2m_max': [16.2, 19.3],
        'temperature_2m_min': [10.0, 13.3],
        'precipitation_probability_max': [0, 10],
      },
    });
    expect(
      w.toSentence(),
      '오늘 서울 날씨는 맑음입니다. 현재 기온은 14도이고, 최고 19도, 최저 13도입니다. 비 올 확률은 10퍼센트입니다. '
      '최고 기온은 어제보다 3도 높습니다.',
    );
  });

  test('어제와 비교한다', () {
    Weather w(double max, double yesterdayMax) => Weather(
      temperature: 0,
      max: max,
      min: 0,
      rainChance: 0,
      code: 0,
      yesterdayMax: yesterdayMax,
    );
    expect(w(10.7, 11.5).compareYesterday(), '최고 기온은 어제보다 1도 낮습니다.');
    expect(w(20.4, 19.6).compareYesterday(), '최고 기온은 어제와 비슷합니다.');
  });
}

import 'package:flutter/material.dart';

import 'weather.dart';

void main() {
  runApp(const WeatherApp());
}

// 고대비: 검은 배경 + 노란색·흰색 글씨 (PRD #6-2)
const background = Colors.black;
const accent = Color(0xFFFFD600);
const textColor = Colors.white;

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘 날씨 알리미',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: background,
          primary: accent,
          onPrimary: background,
          onSurface: textColor,
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// 서울 시청 좌표
const seoulLat = 37.5665, seoulLon = 126.978;

Future<String> seoulWeatherAnswer() async => weatherSentence(
  await fetchWeather(latitude: seoulLat, longitude: seoulLon),
  place: '서울',
);

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.answer = seoulWeatherAnswer});

  /// 날씨 답 문장을 만든다. 테스트에서는 가짜로 바꿔 끼운다.
  final Future<String> Function() answer;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _message = '아래 노란 버튼을 누르고\n"오늘 날씨가 뭐야?"라고 말해 보세요.';

  Future<void> _onAsk() async {
    setState(() => _message = '날씨를 확인하고 있어요.');
    String text;
    try {
      text = await widget.answer();
    } catch (_) {
      text = '날씨를 가져오지 못했어요. 다시 눌러 주세요.';
    }
    if (mounted) setState(() => _message = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내·결과 문장, 28pt 이상 (PRD #6-3)
              Expanded(
                flex: 2,
                child: Center(
                  // VoiceOver가 안내·결과 문장을 한 덩어리로 읽도록 묶는다 (PRD #3-1, #7-4)
                  child: Semantics(
                    container: true,
                    child: SingleChildScrollView(
                      child: Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.4,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 화면 높이의 절반 이상을 차지하는 버튼 하나 (PRD #4-1, #6-4)
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _onAsk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  // 힌트는 버튼 안쪽에 두어야 버튼 이름과 함께 읽힌다
                  child: Semantics(
                    hint: '두 번 탭하면 질문을 듣기 시작합니다',
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExcludeSemantics(child: Icon(Icons.mic, size: 96)),
                        SizedBox(height: 16),
                        Text(
                          '날씨 물어보기',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

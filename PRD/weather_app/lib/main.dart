import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'voice.dart';
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

// 날씨를 못 가져오는 대부분의 원인은 인터넷 연결이다 (PRD #4-5, #10-6)
const noInternet = '날씨를 가져오지 못했어요. 인터넷 연결을 확인하고 다시 버튼을 눌러 주세요.';
final noMic = kIsWeb
    ? '마이크를 쓸 수 없어요. 브라우저 주소창 옆 마이크 아이콘에서 마이크를 허용한 뒤 다시 버튼을 눌러 주세요.'
    : '마이크를 쓸 수 없어요. 설정 앱에서 오늘 날씨 알리미를 찾아 마이크와 음성 인식을 켠 뒤 다시 버튼을 눌러 주세요.';
const askAgain = '잘 알아듣지 못했어요. 다시 버튼을 누르고 "오늘 날씨가 뭐야?"라고 말해 주세요.';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.answer = weatherAnswer,
    this.speak = speakText,
    this.listen = listenOnce,
  });

  /// 날씨 답 문장을 만든다. 테스트에서는 가짜로 바꿔 끼운다.
  final Future<String> Function() answer;

  /// 문장을 소리로 읽는다.
  final Future<void> Function(String) speak;

  /// 한 번 듣고 알아들은 문장을 돌려준다.
  final Future<String?> Function() listen;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _lastSpoken;
  String _message = '아래 노란 버튼을 누르고\n"오늘 날씨가 뭐야?"라고 말해 보세요.';

  bool _busy = false;

  Future<void> _onAsk() async {
    if (_busy) return; // 듣거나 읽는 중에 또 누르면 무시
    _busy = true;
    try {
      // 버튼을 누른 뒤에만 듣기 시작한다 (PRD #4-1, #9-2)
      await _say('말씀하세요.', remember: false);
      if (!mounted) return;
      setState(() => _message = '듣고 있어요...');
      final heard = await widget.listen();
      if (!mounted) return;
      // 못 알아들었거나 날씨 질문이 아니면 다음 행동을 안내한다 (PRD #4-5, #10-6)
      if (heard == null) {
        // 마이크·음성 인식 권한이 없거나 쓸 수 없다 (PRD #4-5)
        await _say(noMic, remember: false);
        return;
      }
      if (!isWeatherQuestion(heard)) {
        await _say(askAgain, remember: false);
        return;
      }

      setState(() => _message = '날씨를 확인하고 있어요.');
      String text;
      try {
        text = await widget.answer();
      } catch (_) {
        text = noInternet;
      }
      if (mounted) await _say(text);
    } finally {
      _busy = false;
    }
  }

  void _replay() => _say(_lastSpoken!);

  /// 화면 글자를 바꾸고 같은 문장을 소리로 읽는다 (PRD #9-3)
  Future<void> _say(String text, {bool remember = true}) async {
    setState(() {
      _message = text;
      if (remember) _lastSpoken = text;
    });
    try {
      await widget.speak(text);
    } catch (_) {
      // 소리가 안 나와도 화면 글자는 남아 있으므로 앱은 계속 쓸 수 있다
    }
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
                // VoiceOver가 안내·결과 문장을 한 덩어리로 읽도록 묶는다 (PRD #3-1, #7-4)
                child: Semantics(
                  container: true,
                  // 글자가 바뀌어도 VoiceOver가 자동으로 읽지 않게 한다.
                  // 앱 음성이 이미 읽어주므로 두 번 들리면 안 된다 (PRD #7-4, #9-3)
                  liveRegion: false,
                  // 문장·다시 듣기 안내·누르기 동작을 한 칸에 모아 함께 읽히게 한다
                  label: _message,
                  excludeSemantics: true,
                  button: _lastSpoken != null,
                  onTap: _lastSpoken == null ? null : _replay,
                  hint: _lastSpoken == null ? null : '두 번 탭하면 다시 들려줍니다',
                  // 결과 글을 누르면 방금 들은 내용을 다시 읽는다 (PRD #4-3)
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _lastSpoken == null ? null : _replay,
                    child: Center(
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

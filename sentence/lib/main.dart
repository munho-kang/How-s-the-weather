import 'package:flutter/material.dart';

import 'voice.dart';
import 'weather.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘 날씨',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.fetch = fetchWeather,
    this.listen = listenOnce,
    this.speak = speakText,
  });

  final Future<Weather> Function() fetch;
  final Future<String?> Function() listen;
  final Future<void> Function(String) speak;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _message = '아래 버튼을 누르고 "오늘 날씨가 뭐야?"라고 물어보세요.';

  void _say(String text) {
    setState(() => _message = text);
    widget.speak(text);
  }

  Future<void> _onAsk() async {
    setState(() => _message = '듣고 있어요. "오늘 날씨가 뭐야?"라고 말해 주세요.');
    final heard = await widget.listen();
    // 음성 인식을 못 쓰거나 아무 말도 없으면 버튼 누른 걸로 보고 바로 날씨를 알려준다.
    if (heard != null && heard.isNotEmpty && !isWeatherQuestion(heard)) {
      _say('"$heard"라고 들었어요. 날씨가 궁금하면 "오늘 날씨가 뭐야?"라고 물어보세요.');
      return;
    }
    setState(() => _message = '날씨를 확인하고 있어요...');
    try {
      final weather = await widget.fetch();
      _say(weather.toSentence());
    } catch (_) {
      _say('날씨 정보를 가져오지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 날씨')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 120,
              child: ElevatedButton.icon(
                onPressed: _onAsk,
                icon: const Icon(Icons.mic, size: 48),
                label: const Text('날씨 물어보기', style: TextStyle(fontSize: 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

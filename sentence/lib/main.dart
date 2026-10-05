import 'package:flutter/material.dart';

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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _message = '아래 버튼을 누르고 "오늘 날씨가 뭐야?"라고 물어보세요.';

  void _onAsk() {
    setState(() => _message = '날씨 기능은 준비 중입니다.');
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

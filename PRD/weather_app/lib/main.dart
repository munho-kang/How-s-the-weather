import 'package:flutter/material.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _message = '아래 노란 버튼을 누르고\n"오늘 날씨가 뭐야?"라고 말해 보세요.';

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
              const SizedBox(height: 16),
              // 화면 높이의 절반 이상을 차지하는 버튼 하나 (PRD #4-1, #6-4)
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, size: 96),
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
            ],
          ),
        ),
      ),
    );
  }
}

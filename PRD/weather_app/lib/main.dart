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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: SizedBox.expand()));
  }
}

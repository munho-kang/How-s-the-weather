import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

final _stt = SpeechToText();
final _tts = FlutterTts();

bool isWeatherQuestion(String text) => text.contains('날씨');

/// 한 번 듣고 알아들은 문장을 돌려준다. 음성 인식을 쓸 수 없으면 null.
Future<String?> listenOnce() async {
  try {
    if (!await _stt.initialize()) return null;
  } catch (_) {
    return null;
  }
  final done = Completer<String?>();
  await _stt.listen(
    listenOptions: SpeechListenOptions(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    ),
    onResult: (r) {
      if (r.finalResult && !done.isCompleted) done.complete(r.recognizedWords);
    },
  );
  return done.future.timeout(const Duration(seconds: 12), onTimeout: () {
    _stt.stop();
    return _stt.lastRecognizedWords;
  });
}

Future<void> speak(String text) async {
  await _tts.setLanguage('ko-KR');
  await _tts.speak(text);
}

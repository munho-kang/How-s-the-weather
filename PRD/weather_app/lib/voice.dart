import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

final _tts = FlutterTts();
final _stt = SpeechToText();
bool _ttsReady = false;
void Function()? _listenEnded;

/// 한국어 음성 합성으로 읽어준다. 다 읽을 때까지 기다린다 (PRD #4-3, #7-3, #9-3)
Future<void> speakText(String text) async {
  if (!_ttsReady) {
    await _tts.setLanguage('ko-KR');
    await _tts.awaitSpeakCompletion(true);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // 무음 스위치가 켜져 있어도 들리고, 이후 마이크와도 함께 쓸 수 있게
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        ],
      );
    }
    _ttsReady = true;
  }
  await _tts.stop(); // 앞에 읽던 말과 겹치지 않게
  await _tts.speak(text);
}

/// 한 번 듣고 알아들은 문장을 돌려준다 (PRD #4-2, #7-3)
/// - 음성 인식을 쓸 수 없으면 null
/// - 아무 말도 못 알아들었으면 빈 문자열
Future<String?> listenOnce() async {
  try {
    final ok = await _stt.initialize(
      // 말이 끝났거나 오류가 나면 바로 듣기를 마친다
      onStatus: (s) {
        if (s == SpeechToText.doneStatus) _listenEnded?.call();
      },
      onError: (_) => _listenEnded?.call(),
    );
    if (!ok) return null;
  } catch (_) {
    return null;
  }
  final done = Completer<String>();
  void finish() {
    if (!done.isCompleted) done.complete(_stt.lastRecognizedWords);
  }

  _listenEnded = finish;

  await _stt.listen(
    listenOptions: SpeechListenOptions(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
    ),
    onResult: (r) {
      if (r.finalResult) finish();
    },
  );
  // 결과가 안 오면 (말이 없거나 오류) 기다리다가 끝낸다
  return done.future.timeout(
    const Duration(seconds: 9),
    onTimeout: () {
      _stt.stop();
      return _stt.lastRecognizedWords;
    },
  );
}

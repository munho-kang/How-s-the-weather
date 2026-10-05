import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

final _tts = FlutterTts();
bool _ttsReady = false;

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

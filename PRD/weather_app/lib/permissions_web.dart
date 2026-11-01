import 'dart:js_interop';

import 'package:geolocator/geolocator.dart';
import 'package:web/web.dart' as web;

const micFirstTime = '처음 한 번만 마이크 사용 허락이 필요해요. 브라우저에 뜬 창에서 허용을 눌러 주세요.';
const locationFirstTime = '현재 위치의 날씨를 알려면 위치 허락도 필요해요. 브라우저에 뜬 창에서 허용을 눌러 주세요.';

/// 처음 쓰는 사람에게 듣기 전에 마이크·위치 허락을 미리 받는다 (추가-2)
/// 허락 창이 듣는 도중에 뜨면, 창을 찾는 사이 듣기 시간이 끝나 실패하기 때문이다.
/// 마이크를 쓸 수 없으면 false.
Future<bool> askPermissions(Future<void> Function(String) say) async {
  final mic = await _state('microphone');
  if (mic == 'denied') return false;
  if (mic != 'granted') {
    await say(micFirstTime);
    if (!await _requestMic()) return false;
  }
  if (await _state('geolocation') == 'prompt') {
    await say(locationFirstTime);
    // 사용자가 답할 때까지 기다린다. 거부해도 서울 날씨로 대신한다 (PRD #9-1)
    await Geolocator.requestPermission();
  }
  return true;
}

/// 'granted'(허락함) · 'denied'(거부함) · 'prompt'(아직 안 물어봄)
Future<String> _state(String name) async {
  try {
    final status = await web.window.navigator.permissions
        .query({'name': name}.jsify() as JSObject)
        .toDart;
    return status.state;
  } catch (_) {
    return 'prompt'; // 상태를 알 수 없으면 일단 물어본다
  }
}

/// 마이크 허락 창을 띄우고 답을 기다린다. 허락받으면 마이크는 바로 끈다.
Future<bool> _requestMic() async {
  try {
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
        .toDart;
    for (final track in stream.getTracks().toDart) {
      track.stop();
    }
    return true;
  } catch (_) {
    return false;
  }
}

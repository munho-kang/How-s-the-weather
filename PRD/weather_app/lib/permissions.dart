// 웹이 아닐 때(iOS·테스트)는 미리 허락을 받을 필요가 없다.
// iOS는 음성 인식 준비(initialize) 단계에서 허락 창이 뜨고 답을 기다려 준다.
export 'permissions_stub.dart'
    if (dart.library.js_interop) 'permissions_web.dart';

/// 웹이 아니면 할 일이 없다. 항상 마이크를 쓸 수 있다고 본다.
Future<bool> askPermissions(Future<void> Function(String) say) async => true;

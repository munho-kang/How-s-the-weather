import 'package:geolocator/geolocator.dart';

typedef Coords = ({double lat, double lon});

/// 현재 위치. 위치 서비스가 꺼져 있거나, 권한이 없거나, 오래 걸리면 null (PRD #4-4)
Future<Coords?> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // 날씨는 동네 수준이면 충분
        timeLimit: Duration(seconds: 3),
      ),
    );
    return (lat: p.latitude, lon: p.longitude);
  } catch (_) {
    return null;
  }
}

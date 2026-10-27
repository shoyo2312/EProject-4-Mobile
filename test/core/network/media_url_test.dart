import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/media_url.dart';

void main() {
  const upload = 'http://localhost:9000/video-media';

  test('emulator: localhost storage is moved to 10.0.2.2, port and path kept', () {
    expect(
      reachableFromDevice(upload, apiBaseUrl: 'http://10.0.2.2:8080/api/v1'),
      'http://10.0.2.2:9000/video-media',
    );
  });

  test('phone on Wi-Fi: localhost storage is moved to the LAN IP', () {
    expect(
      reachableFromDevice('http://127.0.0.1:9000/b/k.mp4?x=1',
          apiBaseUrl: 'http://192.168.1.5:8080/api/v1'),
      'http://192.168.1.5:9000/b/k.mp4?x=1',
    );
  });

  test('API on localhost (USB + adb reverse, desktop): unchanged', () {
    expect(
      reachableFromDevice(upload, apiBaseUrl: 'http://localhost:8080/api/v1'),
      upload,
    );
  });

  test('production storage host: unchanged', () {
    const prod = 'http://media.nowaa.site:9000/video-media';
    expect(
      reachableFromDevice(prod, apiBaseUrl: 'http://10.0.2.2:8080/api/v1'),
      prod,
    );
  });
}

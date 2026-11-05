import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/auth/data/qr_login_scan.dart';

void main() {
  group('qrLoginIdFrom', () {
    test('reads the id out of a web sign-in code', () {
      expect(qrLoginIdFrom('nowa://qr-login?id=AbCdEfGhIjKlMnOpQrSt_-'),
          'AbCdEfGhIjKlMnOpQrSt_-');
      expect(qrLoginIdFrom('  nowa://qr-login?id=AbCdEfGhIjKlMnOpQrSt12\n'),
          'AbCdEfGhIjKlMnOpQrSt12');
    });

    test('ignores anything that is not ours', () {
      expect(qrLoginIdFrom('https://example.com/?id=AbCdEfGhIjKlMnOpQrSt12'), isNull);
      expect(qrLoginIdFrom('nowa://profile?id=AbCdEfGhIjKlMnOpQrSt12'), isNull);
      expect(qrLoginIdFrom('nowa://qr-login'), isNull);
      expect(qrLoginIdFrom('nowa://qr-login?id=short'), isNull);
      expect(qrLoginIdFrom('nowa://qr-login?id=../../auth/me/aaaaaaaaaa'), isNull);
      expect(qrLoginIdFrom('just some text'), isNull);
    });
  });

  test('a scan answer parses, with or without a label and place', () {
    final full = QrLoginScan.fromJson({
      'deviceLabel': 'Chrome on Windows',
      'location': 'Hanoi, Vietnam',
      'expiresAt': '2026-11-05T10:00:00Z',
    });
    expect(full.deviceLabel, 'Chrome on Windows');
    expect(full.expiresAt, DateTime.utc(2026, 11, 5, 10));

    final bare = QrLoginScan.fromJson({'expiresAt': '2026-11-05T10:00:00Z'});
    expect(bare.deviceLabel, isNull);
    expect(bare.location, isNull);
  });
}

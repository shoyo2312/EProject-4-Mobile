import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/utils/badge_count.dart';

void main() {
  test('shows the count itself up to 99', () {
    expect(badgeCount(0), '0');
    expect(badgeCount(5), '5');
    expect(badgeCount(99), '99');
  });

  test('caps at 99+ from 100 on', () {
    expect(badgeCount(100), '99+');
    expect(badgeCount(150), '99+');
    expect(badgeCount(100000), '99+');
  });
}

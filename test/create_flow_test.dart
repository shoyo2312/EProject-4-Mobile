import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

void main() {
  test('visibility maps to the three values video-service accepts', () {
    expect(wireVisibility(VideoVisibility.public), 'PUBLIC');
    expect(wireVisibility(VideoVisibility.friends), 'FRIENDS');
    expect(wireVisibility(VideoVisibility.private), 'PRIVATE');
    expect(wireVisibility(VideoVisibility.unknown), 'PUBLIC');
  });
}

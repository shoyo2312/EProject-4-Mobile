import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';

void main() {
  test('changeLine writes the change and its percent, TikTok style', () {
    expect(changeLine(120, 80), '+40 (+50.0%)');
    expect(changeLine(60, 80), '-20 (-25.0%)');
    expect(changeLine(5, 5), '0 (0.0%)');
    // Nothing before: no infinity.
    expect(changeLine(7, 0), '+7 (--)');
    // A negative base still gives a sensible direction.
    expect(changeLine(2, -2), '+4 (+200.0%)');
  });

  test('niceMax rounds up to 1, 2 or 5 times a power of ten', () {
    expect(niceMax(0), 1);
    expect(niceMax(7), 10);
    expect(niceMax(13), 20);
    expect(niceMax(420), 500);
    expect(niceMax(1000), 1000);
  });

  test('retentionInsight finds the steepest drop', () {
    expect(retentionInsight([1, 0.9, 0.5, 0.45]), 2);
    expect(retentionInsight([1, 1, 1]), isNull);
    expect(retentionInsight([]), isNull);
  });

  test('labelIndexes keeps both ends and never more than max', () {
    expect(labelIndexes(3), [0, 1, 2]);
    expect(labelIndexes(28), [0, 7, 14, 20, 27]);
    expect(labelIndexes(365).length, 5);
    expect(labelIndexes(0), isEmpty);
  });

  test('watch time and percent read like the web', () {
    expect(formatWatchTime(5400), '5.4s');
    expect(formatWatchTime(5000), '5s');
    expect(formatWatchTime(65000), '1m 5s');
    expect(formatWatchTime(7380000), '2h 3m');
    expect(formatPercent(0.425), '42.5%');
    expect(formatPercent(0.4), '40%');
  });

  test('dayLabel reads the calendar date as given', () {
    expect(dayLabel('2026-10-17'), 'Oct 17');
    expect(dayLabel('2026-01-01'), 'Jan 1');
    expect(dayLabel('garbage'), 'garbage');
  });

  test('labels cover every status and source', () {
    expect(statusLabel(VideoStatus.published), isNull);
    expect(statusLabel(VideoStatus.pendingReview), 'Under review');
    expect(statusNote(VideoStatus.rejected), isNotEmpty);
    expect(trafficSourceLabel(TrafficSource.forYou), 'For You');
    expect(trafficSourceLabel(TrafficSource.unknown), 'Other');
    expect(visibilityLabel(VideoVisibility.private), 'Only me');
    expect(visibilityWire(VideoVisibility.friends), 'FRIENDS');
  });

  test('code points count an emoji once', () {
    expect(codePointLength('ab😀'), 3);
  });

  test('overviewMetrics turns the overview into five series', () {
    const overview = CreatorOverview(
      current: CreatorTotals(views: 10, netFollowers: 2),
      previous: CreatorTotals(views: 5),
      daily: [
        CreatorDailyStats(day: '2026-11-06', views: 4, followersGained: 3, followersLost: 1),
        CreatorDailyStats(day: '2026-11-07', views: 6),
      ],
    );

    final metrics = overviewMetrics(overview);

    expect([for (final m in metrics) m.key],
        ['views', 'likes', 'comments', 'shares', 'followers']);
    expect(metrics.first.series, [4, 6]);
    expect(metrics.last.series, [2, 0]);
    expect(metrics.last.value, 2);
  });
}

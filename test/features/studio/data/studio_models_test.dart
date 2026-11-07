import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';

void main() {
  test('overview parses totals and every day of the window', () {
    final overview = CreatorOverview.fromJson({
      'current': {
        'views': 120,
        'likes': -3,
        'comments': 4,
        'shares': 2,
        'saves': 6,
        'netFollowers': 5,
      },
      'previous': {
        'views': 80,
        'likes': 25,
        'comments': 6,
        'shares': 0,
        'saves': 2,
        'netFollowers': 1,
      },
      'daily': [
        {
          'day': '2026-10-17',
          'views': 10,
          'likes': 3,
          'comments': 0,
          'shares': 0,
          'saves': 1,
          'followersGained': 1,
          'followersLost': 0,
        },
      ],
    });

    expect(overview.current.views, 120);
    // Net counts can go negative.
    expect(overview.current.likes, -3);
    expect(overview.previous.netFollowers, 1);
    expect(overview.daily.single.day, '2026-10-17');
    expect(overview.daily.single.followersGained, 1);
  });

  test('video detail keeps breakdowns null below the privacy threshold', () {
    final detail = CreatorVideoDetail.fromJson({
      'videoId': '7312458901234567',
      'views': 100,
      'viewers': 60,
      'totalWatchMs': 540000,
      'avgWatchMs': 5400,
      'completionRate': 0.42,
      'likes': 12,
      'comments': 3,
      'shares': 1,
      'saves': 4,
      'newFollowers': 2,
      // Jackson writes 1.0 as 1.0, but an int must parse as well.
      'retention': [1, 0.93, 0.5],
      'daily': <Object>[],
      'current': {'views': 40},
      'previous': {'views': 30},
      'trafficSources': [
        {'source': 'FOR_YOU', 'views': 28},
        {'source': 'SOMETHING_NEW', 'views': 2},
      ],
      'searchQueries': [
        {'query': 'mèo con', 'views': 4},
      ],
      'audience': {
        'total': 60,
        'newViewers': 25,
        'previousTotal': 40,
        'previousNewViewers': 10,
        'breakdownAvailable': false,
        'returning': null,
        'followers': null,
        'nonFollowers': null,
        'ageGroups': null,
      },
    });

    expect(detail.retention, [1.0, 0.93, 0.5]);
    expect(detail.current.views, 40);
    expect(detail.current.likes, 0);
    expect(detail.trafficSources.first.source, TrafficSource.forYou);
    // An unknown source does not break the page.
    expect(detail.trafficSources.last.source, TrafficSource.unknown);
    expect(detail.searchQueries.single.query, 'mèo con');
    expect(detail.audience.breakdownAvailable, isFalse);
    expect(detail.audience.ageGroups, isNull);
    expect(detail.audience.returning, isNull);
  });

  test('viewers parse with and without breakdowns', () {
    final open = CreatorViewers.fromJson({
      'totalViewers': 140,
      'newViewers': 35,
      'previousTotalViewers': 90,
      'previousNewViewers': 20,
      'breakdownAvailable': true,
      'activeHours': List.filled(24, 1),
      'activeDays': List.filled(7, 2),
    });
    final closed = CreatorViewers.fromJson({
      'totalViewers': 3,
      'newViewers': 1,
      'previousTotalViewers': 0,
      'previousNewViewers': 0,
      'breakdownAvailable': false,
      'activeHours': null,
      'activeDays': null,
    });

    expect(open.activeHours, hasLength(24));
    expect(open.activeDays, hasLength(7));
    expect(closed.activeHours, isNull);
  });

  test('top video rows take a numeric id as a string', () {
    final row = CreatorVideoStats.fromJson({
      'videoId': 7312458901234567,
      'views': 100,
      'viewers': 50,
      'newViewers': 8,
      'likes': 12,
      'comments': 3,
      'shares': 1,
      'saves': 4,
    });

    expect(row.videoId, '7312458901234567');
  });

  test('a post query is filtered only when a list filter is set', () {
    expect(const StudioPostQuery().isFiltered, isFalse);
    expect(const StudioPostQuery(q: 'trip').isFiltered, isFalse);
    expect(const StudioPostQuery(statuses: ['PUBLISHED']).isFiltered, isTrue);
    expect(const StudioPostQuery(views: [CountRange.under1k]).isFiltered, isTrue);
  });
}

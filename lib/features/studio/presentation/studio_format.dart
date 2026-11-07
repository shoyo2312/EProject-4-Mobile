import 'dart:math' as math;

import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';

/// Studio's number formatting and chart geometry. No data, no widgets —
/// ported from the web's `lib/studio/metrics.ts` so both read the same.

String rangeLabel(int days) => 'Last $days days';

/// The line under a metric, the way TikTok writes it: "+40 (+50.0%)". With
/// nothing before to compare against, the percent is "--" rather than an
/// infinity.
String changeLine(int current, int previous) {
  final delta = current - previous;
  final percent = previous == 0
      ? '--'
      : '${_signed(delta / previous.abs() * 100, 1)}%';
  return '${_signed(delta.toDouble(), 0)} ($percent)';
}

String _signed(double value, int digits) {
  final text = value.abs().toStringAsFixed(digits);
  if (double.parse(text) == 0) return text;
  return '${value > 0 ? '+' : '-'}$text';
}

/// Whether [changeLine] reads as up, down or flat — for its colour.
int changeSign(int current, int previous) => (current - previous).sign;

/// The top of a chart's axis: the next 1, 2 or 5 times a power of ten at or
/// above [max].
double niceMax(double max) {
  if (max <= 0) return 1;
  final power = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  for (final m in const [1, 2, 5, 10]) {
    if (m * power >= max) return m * power;
  }
  return 10 * power;
}

/// Where a retention curve falls the most: the index whose step down from the
/// point before is the largest. Null when it never steps down.
int? retentionInsight(List<double> points) {
  int? best;
  var largest = 0.0;
  for (var i = 1; i < points.length; i++) {
    final drop = points[i - 1] - points[i];
    if (drop > largest) {
      largest = drop;
      best = i;
    }
  }
  return best;
}

/// Which of [count] points get a label under a chart: both ends and the rest
/// evenly between, never more than [max].
List<int> labelIndexes(int count, {int max = 5}) {
  if (count <= 0) return const [];
  if (count <= max) return List.generate(count, (i) => i);
  final step = (count - 1) / (max - 1);
  return List.generate(max, (i) => (i * step).round());
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A `YYYY-MM-DD` analytics day as "Oct 17". Read as a calendar date, never
/// through a time zone.
String dayLabel(String day) {
  final parts = day.split('-');
  if (parts.length != 3) return day;
  final month = int.tryParse(parts[1]) ?? 0;
  final date = int.tryParse(parts[2]) ?? 0;
  if (month < 1 || month > 12) return day;
  return '${_months[month - 1]} $date';
}

/// A full date as "Oct 17, 2026", local time.
String dateLabel(DateTime when) {
  final local = when.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Watch time as "5.4s", "1m 5s" or "2h 3m".
String formatWatchTime(int ms) {
  final seconds = ms / 1000;
  if (seconds < 60) return '${_trim(seconds.toStringAsFixed(1))}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ${(seconds % 60).floor()}s';
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

/// A 0–1 share as "42.5%".
String formatPercent(double share) =>
    '${_trim((share * 100).toStringAsFixed(1))}%';

/// "5.0" → "5", "5.4" stays.
String _trim(String fixed) =>
    fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;

/// TikTok Studio's names for where a view came from.
String trafficSourceLabel(TrafficSource source) => switch (source) {
      TrafficSource.forYou => 'For You',
      TrafficSource.following => 'Following',
      TrafficSource.friends => 'Friends',
      TrafficSource.explore => 'Explore',
      TrafficSource.profile => 'Personal profile',
      TrafficSource.search => 'Search',
      TrafficSource.message => 'Messages',
      TrafficSource.direct => 'Direct link',
      TrafficSource.other || TrafficSource.unknown => 'Other',
    };

/// Age groups in the order Studio lists them, with their labels.
const ageGroups = [
  ('13-17', '13-17'),
  ('18-24', '18-24'),
  ('25-34', '25-34'),
  ('35-44', '35-44'),
  ('45-54', '45-54'),
  ('55+', '55+'),
  ('UNKNOWN', 'Unknown'),
];

/// Who can watch, in the order Studio's menus list them.
const studioVisibilities = [
  VideoVisibility.public,
  VideoVisibility.friends,
  VideoVisibility.private,
];

String visibilityLabel(VideoVisibility visibility) => switch (visibility) {
      VideoVisibility.public || VideoVisibility.unknown => 'Everyone',
      VideoVisibility.friends => 'Friends',
      VideoVisibility.private => 'Only me',
    };

/// The wire name of a visibility, for the Posts filter.
String visibilityWire(VideoVisibility visibility) => switch (visibility) {
      VideoVisibility.public || VideoVisibility.unknown => 'PUBLIC',
      VideoVisibility.friends => 'FRIENDS',
      VideoVisibility.private => 'PRIVATE',
    };

/// What the Posts list says about a video that is not simply live; null for a
/// live one.
String? statusLabel(VideoStatus status) => switch (status) {
      VideoStatus.processing => 'Processing',
      VideoStatus.pendingModeration ||
      VideoStatus.pendingReview =>
        'Under review',
      VideoStatus.published => null,
      VideoStatus.failed => 'Upload failed',
      VideoStatus.rejected => 'Removed',
      VideoStatus.takenDown => 'Taken down',
      VideoStatus.unknown => 'Unavailable',
    };

/// Why a video is not live, in a sentence. Only its owner ever sees these.
String statusNote(VideoStatus status) => switch (status) {
      VideoStatus.processing =>
        'Still processing — it will play once transcoding finishes.',
      VideoStatus.pendingModeration =>
        'Being checked — it goes live as soon as the check clears.',
      VideoStatus.pendingReview =>
        'Waiting on a moderator. It goes live once it is approved.',
      VideoStatus.published => '',
      VideoStatus.failed =>
        'Transcoding failed. Delete this video and upload it again.',
      VideoStatus.rejected =>
        'Removed automatically for likely adult content. Contact support to have it reviewed.',
      VideoStatus.takenDown => 'This video was taken down by a moderator.',
      VideoStatus.unknown => '',
    };

/// The Posts filter's status groups: label and the wire statuses behind it.
const statusFilters = [
  ('Live', ['PUBLISHED']),
  ('Processing', ['PROCESSING']),
  ('Under review', ['PENDING_MODERATION', 'PENDING_REVIEW']),
  ('Not live', ['FAILED', 'REJECTED', 'TAKEN_DOWN']),
];

/// Weekday names for `activeDays`, which start on Monday.
const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Number of Unicode code points — what the server counts for its limits, so
/// an emoji counts once, not twice.
int codePointLength(String text) => text.runes.length;

/// One cell of Studio's metric strip and the daily series behind it.
class OverviewMetric {
  const OverviewMetric({
    required this.key,
    required this.label,
    required this.value,
    required this.previous,
    required this.series,
  });

  final String key;
  final String label;
  final int value;
  final int previous;
  final List<double> series;
}

/// The overview as Studio's five metrics. TikTok's profile views and rewards
/// have no backend, so net followers takes the last place.
List<OverviewMetric> overviewMetrics(CreatorOverview overview) {
  final c = overview.current;
  final p = overview.previous;
  final d = overview.daily;
  List<double> of(int Function(CreatorDailyStats day) pick) =>
      [for (final day in d) pick(day).toDouble()];
  return [
    OverviewMetric(
      key: 'views',
      label: 'Video views',
      value: c.views,
      previous: p.views,
      series: of((x) => x.views),
    ),
    OverviewMetric(
      key: 'likes',
      label: 'Likes',
      value: c.likes,
      previous: p.likes,
      series: of((x) => x.likes),
    ),
    OverviewMetric(
      key: 'comments',
      label: 'Comments',
      value: c.comments,
      previous: p.comments,
      series: of((x) => x.comments),
    ),
    OverviewMetric(
      key: 'shares',
      label: 'Shares',
      value: c.shares,
      previous: p.shares,
      series: of((x) => x.shares),
    ),
    OverviewMetric(
      key: 'followers',
      label: 'Net followers',
      value: c.netFollowers,
      previous: p.netFollowers,
      series: of((x) => x.followersGained - x.followersLost),
    ),
  ];
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'studio_models.freezed.dart';
part 'studio_models.g.dart';

// Analytics sends ids as strings already, but a number would parse too.
String _idFromJson(Object? value) => value.toString();

/// A window's totals for the whole account (`GET /analytics/creator/overview`).
///
/// Likes, comments and saves are net — an unlike or a deleted comment in the
/// window takes one back — so a quiet window can come out negative.
@freezed
class CreatorTotals with _$CreatorTotals {
  const factory CreatorTotals({
    @Default(0) int views,
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
    @Default(0) int saves,
    @Default(0) int netFollowers,
  }) = _CreatorTotals;

  factory CreatorTotals.fromJson(Map<String, dynamic> json) =>
      _$CreatorTotalsFromJson(json);
}

/// One day of a chart, in Vietnam's calendar. Every day of the window is
/// present, zeros included.
@freezed
class CreatorDailyStats with _$CreatorDailyStats {
  const factory CreatorDailyStats({
    /// `YYYY-MM-DD`.
    required String day,
    @Default(0) int views,
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
    @Default(0) int saves,
    @Default(0) int followersGained,
    @Default(0) int followersLost,
  }) = _CreatorDailyStats;

  factory CreatorDailyStats.fromJson(Map<String, dynamic> json) =>
      _$CreatorDailyStatsFromJson(json);
}

/// Studio's key metrics, compared with the window of the same length before.
@freezed
class CreatorOverview with _$CreatorOverview {
  const factory CreatorOverview({
    required CreatorTotals current,
    required CreatorTotals previous,
    @Default([]) List<CreatorDailyStats> daily,
  }) = _CreatorOverview;

  factory CreatorOverview.fromJson(Map<String, dynamic> json) =>
      _$CreatorOverviewFromJson(json);
}

/// One row of `GET /analytics/creator/videos/top`. Ids only: the title and
/// thumbnail come from `/videos/batch`.
@freezed
class CreatorVideoStats with _$CreatorVideoStats {
  const factory CreatorVideoStats({
    @JsonKey(fromJson: _idFromJson) required String videoId,
    @Default(0) int views,
    @Default(0) int viewers,

    /// Viewers who had never watched this creator and came in through this
    /// video.
    @Default(0) int newViewers,
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
    @Default(0) int saves,
  }) = _CreatorVideoStats;

  factory CreatorVideoStats.fromJson(Map<String, dynamic> json) =>
      _$CreatorVideoStatsFromJson(json);
}

/// One video's numbers over a window.
@freezed
class CreatorVideoTotals with _$CreatorVideoTotals {
  const factory CreatorVideoTotals({
    @Default(0) int views,
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
    @Default(0) int saves,
    @Default(0) int newFollowers,
  }) = _CreatorVideoTotals;

  factory CreatorVideoTotals.fromJson(Map<String, dynamic> json) =>
      _$CreatorVideoTotalsFromJson(json);
}

/// Where a view came from — the screen the viewer tapped the video on.
enum TrafficSource {
  @JsonValue('FOR_YOU')
  forYou,
  @JsonValue('FOLLOWING')
  following,
  @JsonValue('FRIENDS')
  friends,
  @JsonValue('EXPLORE')
  explore,
  @JsonValue('PROFILE')
  profile,
  @JsonValue('SEARCH')
  search,
  @JsonValue('MESSAGE')
  message,
  @JsonValue('DIRECT')
  direct,
  @JsonValue('OTHER')
  other,
  unknown,
}

@freezed
class TrafficSourceRow with _$TrafficSourceRow {
  const factory TrafficSourceRow({
    @JsonKey(unknownEnumValue: TrafficSource.unknown)
    required TrafficSource source,
    @Default(0) int views,
  }) = _TrafficSourceRow;

  factory TrafficSourceRow.fromJson(Map<String, dynamic> json) =>
      _$TrafficSourceRowFromJson(json);
}

@freezed
class SearchQueryRow with _$SearchQueryRow {
  const factory SearchQueryRow({
    required String query,
    @Default(0) int views,
  }) = _SearchQueryRow;

  factory SearchQueryRow.fromJson(Map<String, dynamic> json) =>
      _$SearchQueryRowFromJson(json);
}

/// Who watched one video in the window. The four breakdowns are null and
/// [breakdownAvailable] false until the audience is large enough to name no
/// one (`CREATOR_MIN_AUDIENCE` on the server, 100 by default).
@freezed
class CreatorVideoViewers with _$CreatorVideoViewers {
  const factory CreatorVideoViewers({
    @Default(0) int total,
    @Default(0) int newViewers,
    @Default(0) int previousTotal,
    @Default(0) int previousNewViewers,
    @Default(false) bool breakdownAvailable,
    int? returning,
    int? followers,
    int? nonFollowers,

    /// Always the seven keys `13-17, 18-24, 25-34, 35-44, 45-54, 55+,
    /// UNKNOWN` when present.
    Map<String, int>? ageGroups,
  }) = _CreatorVideoViewers;

  factory CreatorVideoViewers.fromJson(Map<String, dynamic> json) =>
      _$CreatorVideoViewersFromJson(json);
}

/// `GET /analytics/creator/videos/{id}`. The top-level numbers are lifetime;
/// [current] / [previous] / [daily] / [audience] cover the window asked for.
@freezed
class CreatorVideoDetail with _$CreatorVideoDetail {
  const factory CreatorVideoDetail({
    @JsonKey(fromJson: _idFromJson) required String videoId,
    @Default(0) int views,
    @Default(0) int viewers,
    @Default(0) int totalWatchMs,
    @Default(0) int avgWatchMs,

    /// Share of views that reached the end, 0 to 1.
    @Default(0) double completionRate,
    @Default(0) int likes,
    @Default(0) int comments,
    @Default(0) int shares,
    @Default(0) int saves,
    @Default(0) int newFollowers,

    /// 21 points, 0% to 100% of the video in 5% steps: the share of views
    /// still watching there.
    @Default([]) List<double> retention,
    @Default([]) List<CreatorDailyStats> daily,
    @Default(CreatorVideoTotals()) CreatorVideoTotals current,
    @Default(CreatorVideoTotals()) CreatorVideoTotals previous,
    @Default([]) List<TrafficSourceRow> trafficSources,
    @Default([]) List<SearchQueryRow> searchQueries,
    @Default(CreatorVideoViewers()) CreatorVideoViewers audience,
  }) = _CreatorVideoDetail;

  factory CreatorVideoDetail.fromJson(Map<String, dynamic> json) =>
      _$CreatorVideoDetailFromJson(json);
}

/// `GET /analytics/creator/viewers`. The two lists are null until the audience
/// is large enough (see [CreatorVideoViewers]).
@freezed
class CreatorViewers with _$CreatorViewers {
  const factory CreatorViewers({
    @Default(0) int totalViewers,
    @Default(0) int newViewers,
    @Default(0) int previousTotalViewers,
    @Default(0) int previousNewViewers,
    @Default(false) bool breakdownAvailable,

    /// Distinct viewers by hour, 24 entries from 00:00 (Vietnam time).
    List<int>? activeHours,

    /// Distinct viewers by weekday, 7 entries from Monday.
    List<int>? activeDays,
  }) = _CreatorViewers;

  factory CreatorViewers.fromJson(Map<String, dynamic> json) =>
      _$CreatorViewersFromJson(json);
}

// ---------------------------------------------------------------------------
// Request parameters. Plain enums: they only ever go up, as their wire name.
// ---------------------------------------------------------------------------

/// How the analytics top list is ranked.
enum CreatorVideoSort {
  views('VIEWS', 'Views'),
  viewers('VIEWERS', 'Viewers'),
  newViewers('NEW_VIEWERS', 'New viewers'),
  likes('LIKES', 'Likes'),
  comments('COMMENTS', 'Comments'),
  shares('SHARES', 'Shares');

  const CreatorVideoSort(this.wire, this.label);
  final String wire;
  final String label;
}

/// Columns the Posts list can be ordered by.
enum StudioPostSort {
  newest('NEWEST', 'Date posted'),
  views('VIEWS', 'Views'),
  likes('LIKES', 'Likes'),
  comments('COMMENTS', 'Comments');

  const StudioPostSort(this.wire, this.label);
  final String wire;
  final String label;
}

/// Studio's count buckets for the views / likes / comments filters.
enum CountRange {
  under1k('UNDER_1K', '<1K'),
  from1kTo10k('FROM_1K_TO_10K', '1K–10K'),
  from10kTo100k('FROM_10K_TO_100K', '10K–100K'),
  over100k('OVER_100K', '>100K');

  const CountRange(this.wire, this.label);
  final String wire;
  final String label;
}

/// The filters of `GET /videos/me`. Each list matches any one of its values;
/// an empty list is no filter.
@freezed
class StudioPostQuery with _$StudioPostQuery {
  const factory StudioPostQuery({
    @Default([]) List<String> statuses,
    @Default([]) List<String> visibilities,
    @Default([]) List<CountRange> views,
    @Default(StudioPostSort.newest) StudioPostSort sort,
    @Default(true) bool descending,
    @Default('') String q,
  }) = _StudioPostQuery;

  const StudioPostQuery._();

  bool get isFiltered =>
      statuses.isNotEmpty || visibilities.isNotEmpty || views.isNotEmpty;
}

/// Comment inbox order. The two non-default ones need a video picked.
enum InboxSort {
  newest('NEWEST', 'Newest'),
  mostLiked('MOST_LIKED', 'Most liked'),
  mostReplied('MOST_REPLIED', 'Most replied');

  const InboxSort(this.wire, this.label);
  final String wire;
  final String label;
}

/// The filters of `GET /interactions/users/me/comments`. A cursor belongs to
/// the filters it was issued under, so a change of filter starts over.
@freezed
class InboxQuery with _$InboxQuery {
  const factory InboxQuery({
    /// Only this video's comments. Also unlocks [sort] and [replied].
    String? videoId,

    /// Only comments held back for the owner to approve.
    @Default(false) bool heldOnly,
    @Default('') String q,
    @Default(InboxSort.newest) InboxSort sort,

    /// true: only threads the owner answered; false: only unanswered ones.
    bool? replied,
  }) = _InboxQuery;
}

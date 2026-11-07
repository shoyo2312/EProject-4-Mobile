// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreatorTotalsImpl _$$CreatorTotalsImplFromJson(Map<String, dynamic> json) =>
    _$CreatorTotalsImpl(
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      netFollowers: (json['netFollowers'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CreatorTotalsImplToJson(_$CreatorTotalsImpl instance) =>
    <String, dynamic>{
      'views': instance.views,
      'likes': instance.likes,
      'comments': instance.comments,
      'shares': instance.shares,
      'saves': instance.saves,
      'netFollowers': instance.netFollowers,
    };

_$CreatorDailyStatsImpl _$$CreatorDailyStatsImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorDailyStatsImpl(
  day: json['day'] as String,
  views: (json['views'] as num?)?.toInt() ?? 0,
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  shares: (json['shares'] as num?)?.toInt() ?? 0,
  saves: (json['saves'] as num?)?.toInt() ?? 0,
  followersGained: (json['followersGained'] as num?)?.toInt() ?? 0,
  followersLost: (json['followersLost'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CreatorDailyStatsImplToJson(
  _$CreatorDailyStatsImpl instance,
) => <String, dynamic>{
  'day': instance.day,
  'views': instance.views,
  'likes': instance.likes,
  'comments': instance.comments,
  'shares': instance.shares,
  'saves': instance.saves,
  'followersGained': instance.followersGained,
  'followersLost': instance.followersLost,
};

_$CreatorOverviewImpl _$$CreatorOverviewImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorOverviewImpl(
  current: CreatorTotals.fromJson(json['current'] as Map<String, dynamic>),
  previous: CreatorTotals.fromJson(json['previous'] as Map<String, dynamic>),
  daily:
      (json['daily'] as List<dynamic>?)
          ?.map((e) => CreatorDailyStats.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$CreatorOverviewImplToJson(
  _$CreatorOverviewImpl instance,
) => <String, dynamic>{
  'current': instance.current,
  'previous': instance.previous,
  'daily': instance.daily,
};

_$CreatorVideoStatsImpl _$$CreatorVideoStatsImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorVideoStatsImpl(
  videoId: _idFromJson(json['videoId']),
  views: (json['views'] as num?)?.toInt() ?? 0,
  viewers: (json['viewers'] as num?)?.toInt() ?? 0,
  newViewers: (json['newViewers'] as num?)?.toInt() ?? 0,
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  shares: (json['shares'] as num?)?.toInt() ?? 0,
  saves: (json['saves'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CreatorVideoStatsImplToJson(
  _$CreatorVideoStatsImpl instance,
) => <String, dynamic>{
  'videoId': instance.videoId,
  'views': instance.views,
  'viewers': instance.viewers,
  'newViewers': instance.newViewers,
  'likes': instance.likes,
  'comments': instance.comments,
  'shares': instance.shares,
  'saves': instance.saves,
};

_$CreatorVideoTotalsImpl _$$CreatorVideoTotalsImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorVideoTotalsImpl(
  views: (json['views'] as num?)?.toInt() ?? 0,
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  shares: (json['shares'] as num?)?.toInt() ?? 0,
  saves: (json['saves'] as num?)?.toInt() ?? 0,
  newFollowers: (json['newFollowers'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CreatorVideoTotalsImplToJson(
  _$CreatorVideoTotalsImpl instance,
) => <String, dynamic>{
  'views': instance.views,
  'likes': instance.likes,
  'comments': instance.comments,
  'shares': instance.shares,
  'saves': instance.saves,
  'newFollowers': instance.newFollowers,
};

_$TrafficSourceRowImpl _$$TrafficSourceRowImplFromJson(
  Map<String, dynamic> json,
) => _$TrafficSourceRowImpl(
  source: $enumDecode(
    _$TrafficSourceEnumMap,
    json['source'],
    unknownValue: TrafficSource.unknown,
  ),
  views: (json['views'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$TrafficSourceRowImplToJson(
  _$TrafficSourceRowImpl instance,
) => <String, dynamic>{
  'source': _$TrafficSourceEnumMap[instance.source]!,
  'views': instance.views,
};

const _$TrafficSourceEnumMap = {
  TrafficSource.forYou: 'FOR_YOU',
  TrafficSource.following: 'FOLLOWING',
  TrafficSource.friends: 'FRIENDS',
  TrafficSource.explore: 'EXPLORE',
  TrafficSource.profile: 'PROFILE',
  TrafficSource.search: 'SEARCH',
  TrafficSource.message: 'MESSAGE',
  TrafficSource.direct: 'DIRECT',
  TrafficSource.other: 'OTHER',
  TrafficSource.unknown: 'unknown',
};

_$SearchQueryRowImpl _$$SearchQueryRowImplFromJson(Map<String, dynamic> json) =>
    _$SearchQueryRowImpl(
      query: json['query'] as String,
      views: (json['views'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SearchQueryRowImplToJson(
  _$SearchQueryRowImpl instance,
) => <String, dynamic>{'query': instance.query, 'views': instance.views};

_$CreatorVideoViewersImpl _$$CreatorVideoViewersImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorVideoViewersImpl(
  total: (json['total'] as num?)?.toInt() ?? 0,
  newViewers: (json['newViewers'] as num?)?.toInt() ?? 0,
  previousTotal: (json['previousTotal'] as num?)?.toInt() ?? 0,
  previousNewViewers: (json['previousNewViewers'] as num?)?.toInt() ?? 0,
  breakdownAvailable: json['breakdownAvailable'] as bool? ?? false,
  returning: (json['returning'] as num?)?.toInt(),
  followers: (json['followers'] as num?)?.toInt(),
  nonFollowers: (json['nonFollowers'] as num?)?.toInt(),
  ageGroups: (json['ageGroups'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
);

Map<String, dynamic> _$$CreatorVideoViewersImplToJson(
  _$CreatorVideoViewersImpl instance,
) => <String, dynamic>{
  'total': instance.total,
  'newViewers': instance.newViewers,
  'previousTotal': instance.previousTotal,
  'previousNewViewers': instance.previousNewViewers,
  'breakdownAvailable': instance.breakdownAvailable,
  'returning': instance.returning,
  'followers': instance.followers,
  'nonFollowers': instance.nonFollowers,
  'ageGroups': instance.ageGroups,
};

_$CreatorVideoDetailImpl _$$CreatorVideoDetailImplFromJson(
  Map<String, dynamic> json,
) => _$CreatorVideoDetailImpl(
  videoId: _idFromJson(json['videoId']),
  views: (json['views'] as num?)?.toInt() ?? 0,
  viewers: (json['viewers'] as num?)?.toInt() ?? 0,
  totalWatchMs: (json['totalWatchMs'] as num?)?.toInt() ?? 0,
  avgWatchMs: (json['avgWatchMs'] as num?)?.toInt() ?? 0,
  completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  shares: (json['shares'] as num?)?.toInt() ?? 0,
  saves: (json['saves'] as num?)?.toInt() ?? 0,
  newFollowers: (json['newFollowers'] as num?)?.toInt() ?? 0,
  retention:
      (json['retention'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [],
  daily:
      (json['daily'] as List<dynamic>?)
          ?.map((e) => CreatorDailyStats.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  current: json['current'] == null
      ? const CreatorVideoTotals()
      : CreatorVideoTotals.fromJson(json['current'] as Map<String, dynamic>),
  previous: json['previous'] == null
      ? const CreatorVideoTotals()
      : CreatorVideoTotals.fromJson(json['previous'] as Map<String, dynamic>),
  trafficSources:
      (json['trafficSources'] as List<dynamic>?)
          ?.map((e) => TrafficSourceRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  searchQueries:
      (json['searchQueries'] as List<dynamic>?)
          ?.map((e) => SearchQueryRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  audience: json['audience'] == null
      ? const CreatorVideoViewers()
      : CreatorVideoViewers.fromJson(json['audience'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$CreatorVideoDetailImplToJson(
  _$CreatorVideoDetailImpl instance,
) => <String, dynamic>{
  'videoId': instance.videoId,
  'views': instance.views,
  'viewers': instance.viewers,
  'totalWatchMs': instance.totalWatchMs,
  'avgWatchMs': instance.avgWatchMs,
  'completionRate': instance.completionRate,
  'likes': instance.likes,
  'comments': instance.comments,
  'shares': instance.shares,
  'saves': instance.saves,
  'newFollowers': instance.newFollowers,
  'retention': instance.retention,
  'daily': instance.daily,
  'current': instance.current,
  'previous': instance.previous,
  'trafficSources': instance.trafficSources,
  'searchQueries': instance.searchQueries,
  'audience': instance.audience,
};

_$CreatorViewersImpl _$$CreatorViewersImplFromJson(Map<String, dynamic> json) =>
    _$CreatorViewersImpl(
      totalViewers: (json['totalViewers'] as num?)?.toInt() ?? 0,
      newViewers: (json['newViewers'] as num?)?.toInt() ?? 0,
      previousTotalViewers:
          (json['previousTotalViewers'] as num?)?.toInt() ?? 0,
      previousNewViewers: (json['previousNewViewers'] as num?)?.toInt() ?? 0,
      breakdownAvailable: json['breakdownAvailable'] as bool? ?? false,
      activeHours: (json['activeHours'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      activeDays: (json['activeDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$CreatorViewersImplToJson(
  _$CreatorViewersImpl instance,
) => <String, dynamic>{
  'totalViewers': instance.totalViewers,
  'newViewers': instance.newViewers,
  'previousTotalViewers': instance.previousTotalViewers,
  'previousNewViewers': instance.previousNewViewers,
  'breakdownAvailable': instance.breakdownAvailable,
  'activeHours': instance.activeHours,
  'activeDays': instance.activeDays,
};

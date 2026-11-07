// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'studio_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreatorTotals _$CreatorTotalsFromJson(Map<String, dynamic> json) {
  return _CreatorTotals.fromJson(json);
}

/// @nodoc
mixin _$CreatorTotals {
  int get views => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get comments => throw _privateConstructorUsedError;
  int get shares => throw _privateConstructorUsedError;
  int get saves => throw _privateConstructorUsedError;
  int get netFollowers => throw _privateConstructorUsedError;

  /// Serializes this CreatorTotals to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorTotalsCopyWith<CreatorTotals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorTotalsCopyWith<$Res> {
  factory $CreatorTotalsCopyWith(
    CreatorTotals value,
    $Res Function(CreatorTotals) then,
  ) = _$CreatorTotalsCopyWithImpl<$Res, CreatorTotals>;
  @useResult
  $Res call({
    int views,
    int likes,
    int comments,
    int shares,
    int saves,
    int netFollowers,
  });
}

/// @nodoc
class _$CreatorTotalsCopyWithImpl<$Res, $Val extends CreatorTotals>
    implements $CreatorTotalsCopyWith<$Res> {
  _$CreatorTotalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? views = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? netFollowers = null,
  }) {
    return _then(
      _value.copyWith(
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
            likes: null == likes
                ? _value.likes
                : likes // ignore: cast_nullable_to_non_nullable
                      as int,
            comments: null == comments
                ? _value.comments
                : comments // ignore: cast_nullable_to_non_nullable
                      as int,
            shares: null == shares
                ? _value.shares
                : shares // ignore: cast_nullable_to_non_nullable
                      as int,
            saves: null == saves
                ? _value.saves
                : saves // ignore: cast_nullable_to_non_nullable
                      as int,
            netFollowers: null == netFollowers
                ? _value.netFollowers
                : netFollowers // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorTotalsImplCopyWith<$Res>
    implements $CreatorTotalsCopyWith<$Res> {
  factory _$$CreatorTotalsImplCopyWith(
    _$CreatorTotalsImpl value,
    $Res Function(_$CreatorTotalsImpl) then,
  ) = __$$CreatorTotalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int views,
    int likes,
    int comments,
    int shares,
    int saves,
    int netFollowers,
  });
}

/// @nodoc
class __$$CreatorTotalsImplCopyWithImpl<$Res>
    extends _$CreatorTotalsCopyWithImpl<$Res, _$CreatorTotalsImpl>
    implements _$$CreatorTotalsImplCopyWith<$Res> {
  __$$CreatorTotalsImplCopyWithImpl(
    _$CreatorTotalsImpl _value,
    $Res Function(_$CreatorTotalsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? views = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? netFollowers = null,
  }) {
    return _then(
      _$CreatorTotalsImpl(
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
        likes: null == likes
            ? _value.likes
            : likes // ignore: cast_nullable_to_non_nullable
                  as int,
        comments: null == comments
            ? _value.comments
            : comments // ignore: cast_nullable_to_non_nullable
                  as int,
        shares: null == shares
            ? _value.shares
            : shares // ignore: cast_nullable_to_non_nullable
                  as int,
        saves: null == saves
            ? _value.saves
            : saves // ignore: cast_nullable_to_non_nullable
                  as int,
        netFollowers: null == netFollowers
            ? _value.netFollowers
            : netFollowers // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorTotalsImpl implements _CreatorTotals {
  const _$CreatorTotalsImpl({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.netFollowers = 0,
  });

  factory _$CreatorTotalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorTotalsImplFromJson(json);

  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int likes;
  @override
  @JsonKey()
  final int comments;
  @override
  @JsonKey()
  final int shares;
  @override
  @JsonKey()
  final int saves;
  @override
  @JsonKey()
  final int netFollowers;

  @override
  String toString() {
    return 'CreatorTotals(views: $views, likes: $likes, comments: $comments, shares: $shares, saves: $saves, netFollowers: $netFollowers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorTotalsImpl &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.likes, likes) || other.likes == likes) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.shares, shares) || other.shares == shares) &&
            (identical(other.saves, saves) || other.saves == saves) &&
            (identical(other.netFollowers, netFollowers) ||
                other.netFollowers == netFollowers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    views,
    likes,
    comments,
    shares,
    saves,
    netFollowers,
  );

  /// Create a copy of CreatorTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorTotalsImplCopyWith<_$CreatorTotalsImpl> get copyWith =>
      __$$CreatorTotalsImplCopyWithImpl<_$CreatorTotalsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorTotalsImplToJson(this);
  }
}

abstract class _CreatorTotals implements CreatorTotals {
  const factory _CreatorTotals({
    final int views,
    final int likes,
    final int comments,
    final int shares,
    final int saves,
    final int netFollowers,
  }) = _$CreatorTotalsImpl;

  factory _CreatorTotals.fromJson(Map<String, dynamic> json) =
      _$CreatorTotalsImpl.fromJson;

  @override
  int get views;
  @override
  int get likes;
  @override
  int get comments;
  @override
  int get shares;
  @override
  int get saves;
  @override
  int get netFollowers;

  /// Create a copy of CreatorTotals
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorTotalsImplCopyWith<_$CreatorTotalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorDailyStats _$CreatorDailyStatsFromJson(Map<String, dynamic> json) {
  return _CreatorDailyStats.fromJson(json);
}

/// @nodoc
mixin _$CreatorDailyStats {
  /// `YYYY-MM-DD`.
  String get day => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get comments => throw _privateConstructorUsedError;
  int get shares => throw _privateConstructorUsedError;
  int get saves => throw _privateConstructorUsedError;
  int get followersGained => throw _privateConstructorUsedError;
  int get followersLost => throw _privateConstructorUsedError;

  /// Serializes this CreatorDailyStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorDailyStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorDailyStatsCopyWith<CreatorDailyStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorDailyStatsCopyWith<$Res> {
  factory $CreatorDailyStatsCopyWith(
    CreatorDailyStats value,
    $Res Function(CreatorDailyStats) then,
  ) = _$CreatorDailyStatsCopyWithImpl<$Res, CreatorDailyStats>;
  @useResult
  $Res call({
    String day,
    int views,
    int likes,
    int comments,
    int shares,
    int saves,
    int followersGained,
    int followersLost,
  });
}

/// @nodoc
class _$CreatorDailyStatsCopyWithImpl<$Res, $Val extends CreatorDailyStats>
    implements $CreatorDailyStatsCopyWith<$Res> {
  _$CreatorDailyStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorDailyStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? views = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? followersGained = null,
    Object? followersLost = null,
  }) {
    return _then(
      _value.copyWith(
            day: null == day
                ? _value.day
                : day // ignore: cast_nullable_to_non_nullable
                      as String,
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
            likes: null == likes
                ? _value.likes
                : likes // ignore: cast_nullable_to_non_nullable
                      as int,
            comments: null == comments
                ? _value.comments
                : comments // ignore: cast_nullable_to_non_nullable
                      as int,
            shares: null == shares
                ? _value.shares
                : shares // ignore: cast_nullable_to_non_nullable
                      as int,
            saves: null == saves
                ? _value.saves
                : saves // ignore: cast_nullable_to_non_nullable
                      as int,
            followersGained: null == followersGained
                ? _value.followersGained
                : followersGained // ignore: cast_nullable_to_non_nullable
                      as int,
            followersLost: null == followersLost
                ? _value.followersLost
                : followersLost // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorDailyStatsImplCopyWith<$Res>
    implements $CreatorDailyStatsCopyWith<$Res> {
  factory _$$CreatorDailyStatsImplCopyWith(
    _$CreatorDailyStatsImpl value,
    $Res Function(_$CreatorDailyStatsImpl) then,
  ) = __$$CreatorDailyStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String day,
    int views,
    int likes,
    int comments,
    int shares,
    int saves,
    int followersGained,
    int followersLost,
  });
}

/// @nodoc
class __$$CreatorDailyStatsImplCopyWithImpl<$Res>
    extends _$CreatorDailyStatsCopyWithImpl<$Res, _$CreatorDailyStatsImpl>
    implements _$$CreatorDailyStatsImplCopyWith<$Res> {
  __$$CreatorDailyStatsImplCopyWithImpl(
    _$CreatorDailyStatsImpl _value,
    $Res Function(_$CreatorDailyStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorDailyStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? views = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? followersGained = null,
    Object? followersLost = null,
  }) {
    return _then(
      _$CreatorDailyStatsImpl(
        day: null == day
            ? _value.day
            : day // ignore: cast_nullable_to_non_nullable
                  as String,
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
        likes: null == likes
            ? _value.likes
            : likes // ignore: cast_nullable_to_non_nullable
                  as int,
        comments: null == comments
            ? _value.comments
            : comments // ignore: cast_nullable_to_non_nullable
                  as int,
        shares: null == shares
            ? _value.shares
            : shares // ignore: cast_nullable_to_non_nullable
                  as int,
        saves: null == saves
            ? _value.saves
            : saves // ignore: cast_nullable_to_non_nullable
                  as int,
        followersGained: null == followersGained
            ? _value.followersGained
            : followersGained // ignore: cast_nullable_to_non_nullable
                  as int,
        followersLost: null == followersLost
            ? _value.followersLost
            : followersLost // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorDailyStatsImpl implements _CreatorDailyStats {
  const _$CreatorDailyStatsImpl({
    required this.day,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.followersGained = 0,
    this.followersLost = 0,
  });

  factory _$CreatorDailyStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorDailyStatsImplFromJson(json);

  /// `YYYY-MM-DD`.
  @override
  final String day;
  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int likes;
  @override
  @JsonKey()
  final int comments;
  @override
  @JsonKey()
  final int shares;
  @override
  @JsonKey()
  final int saves;
  @override
  @JsonKey()
  final int followersGained;
  @override
  @JsonKey()
  final int followersLost;

  @override
  String toString() {
    return 'CreatorDailyStats(day: $day, views: $views, likes: $likes, comments: $comments, shares: $shares, saves: $saves, followersGained: $followersGained, followersLost: $followersLost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorDailyStatsImpl &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.likes, likes) || other.likes == likes) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.shares, shares) || other.shares == shares) &&
            (identical(other.saves, saves) || other.saves == saves) &&
            (identical(other.followersGained, followersGained) ||
                other.followersGained == followersGained) &&
            (identical(other.followersLost, followersLost) ||
                other.followersLost == followersLost));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    day,
    views,
    likes,
    comments,
    shares,
    saves,
    followersGained,
    followersLost,
  );

  /// Create a copy of CreatorDailyStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorDailyStatsImplCopyWith<_$CreatorDailyStatsImpl> get copyWith =>
      __$$CreatorDailyStatsImplCopyWithImpl<_$CreatorDailyStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorDailyStatsImplToJson(this);
  }
}

abstract class _CreatorDailyStats implements CreatorDailyStats {
  const factory _CreatorDailyStats({
    required final String day,
    final int views,
    final int likes,
    final int comments,
    final int shares,
    final int saves,
    final int followersGained,
    final int followersLost,
  }) = _$CreatorDailyStatsImpl;

  factory _CreatorDailyStats.fromJson(Map<String, dynamic> json) =
      _$CreatorDailyStatsImpl.fromJson;

  /// `YYYY-MM-DD`.
  @override
  String get day;
  @override
  int get views;
  @override
  int get likes;
  @override
  int get comments;
  @override
  int get shares;
  @override
  int get saves;
  @override
  int get followersGained;
  @override
  int get followersLost;

  /// Create a copy of CreatorDailyStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorDailyStatsImplCopyWith<_$CreatorDailyStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorOverview _$CreatorOverviewFromJson(Map<String, dynamic> json) {
  return _CreatorOverview.fromJson(json);
}

/// @nodoc
mixin _$CreatorOverview {
  CreatorTotals get current => throw _privateConstructorUsedError;
  CreatorTotals get previous => throw _privateConstructorUsedError;
  List<CreatorDailyStats> get daily => throw _privateConstructorUsedError;

  /// Serializes this CreatorOverview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorOverviewCopyWith<CreatorOverview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorOverviewCopyWith<$Res> {
  factory $CreatorOverviewCopyWith(
    CreatorOverview value,
    $Res Function(CreatorOverview) then,
  ) = _$CreatorOverviewCopyWithImpl<$Res, CreatorOverview>;
  @useResult
  $Res call({
    CreatorTotals current,
    CreatorTotals previous,
    List<CreatorDailyStats> daily,
  });

  $CreatorTotalsCopyWith<$Res> get current;
  $CreatorTotalsCopyWith<$Res> get previous;
}

/// @nodoc
class _$CreatorOverviewCopyWithImpl<$Res, $Val extends CreatorOverview>
    implements $CreatorOverviewCopyWith<$Res> {
  _$CreatorOverviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = null,
    Object? previous = null,
    Object? daily = null,
  }) {
    return _then(
      _value.copyWith(
            current: null == current
                ? _value.current
                : current // ignore: cast_nullable_to_non_nullable
                      as CreatorTotals,
            previous: null == previous
                ? _value.previous
                : previous // ignore: cast_nullable_to_non_nullable
                      as CreatorTotals,
            daily: null == daily
                ? _value.daily
                : daily // ignore: cast_nullable_to_non_nullable
                      as List<CreatorDailyStats>,
          )
          as $Val,
    );
  }

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorTotalsCopyWith<$Res> get current {
    return $CreatorTotalsCopyWith<$Res>(_value.current, (value) {
      return _then(_value.copyWith(current: value) as $Val);
    });
  }

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorTotalsCopyWith<$Res> get previous {
    return $CreatorTotalsCopyWith<$Res>(_value.previous, (value) {
      return _then(_value.copyWith(previous: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CreatorOverviewImplCopyWith<$Res>
    implements $CreatorOverviewCopyWith<$Res> {
  factory _$$CreatorOverviewImplCopyWith(
    _$CreatorOverviewImpl value,
    $Res Function(_$CreatorOverviewImpl) then,
  ) = __$$CreatorOverviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CreatorTotals current,
    CreatorTotals previous,
    List<CreatorDailyStats> daily,
  });

  @override
  $CreatorTotalsCopyWith<$Res> get current;
  @override
  $CreatorTotalsCopyWith<$Res> get previous;
}

/// @nodoc
class __$$CreatorOverviewImplCopyWithImpl<$Res>
    extends _$CreatorOverviewCopyWithImpl<$Res, _$CreatorOverviewImpl>
    implements _$$CreatorOverviewImplCopyWith<$Res> {
  __$$CreatorOverviewImplCopyWithImpl(
    _$CreatorOverviewImpl _value,
    $Res Function(_$CreatorOverviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = null,
    Object? previous = null,
    Object? daily = null,
  }) {
    return _then(
      _$CreatorOverviewImpl(
        current: null == current
            ? _value.current
            : current // ignore: cast_nullable_to_non_nullable
                  as CreatorTotals,
        previous: null == previous
            ? _value.previous
            : previous // ignore: cast_nullable_to_non_nullable
                  as CreatorTotals,
        daily: null == daily
            ? _value._daily
            : daily // ignore: cast_nullable_to_non_nullable
                  as List<CreatorDailyStats>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorOverviewImpl implements _CreatorOverview {
  const _$CreatorOverviewImpl({
    required this.current,
    required this.previous,
    final List<CreatorDailyStats> daily = const [],
  }) : _daily = daily;

  factory _$CreatorOverviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorOverviewImplFromJson(json);

  @override
  final CreatorTotals current;
  @override
  final CreatorTotals previous;
  final List<CreatorDailyStats> _daily;
  @override
  @JsonKey()
  List<CreatorDailyStats> get daily {
    if (_daily is EqualUnmodifiableListView) return _daily;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_daily);
  }

  @override
  String toString() {
    return 'CreatorOverview(current: $current, previous: $previous, daily: $daily)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorOverviewImpl &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.previous, previous) ||
                other.previous == previous) &&
            const DeepCollectionEquality().equals(other._daily, _daily));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    current,
    previous,
    const DeepCollectionEquality().hash(_daily),
  );

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorOverviewImplCopyWith<_$CreatorOverviewImpl> get copyWith =>
      __$$CreatorOverviewImplCopyWithImpl<_$CreatorOverviewImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorOverviewImplToJson(this);
  }
}

abstract class _CreatorOverview implements CreatorOverview {
  const factory _CreatorOverview({
    required final CreatorTotals current,
    required final CreatorTotals previous,
    final List<CreatorDailyStats> daily,
  }) = _$CreatorOverviewImpl;

  factory _CreatorOverview.fromJson(Map<String, dynamic> json) =
      _$CreatorOverviewImpl.fromJson;

  @override
  CreatorTotals get current;
  @override
  CreatorTotals get previous;
  @override
  List<CreatorDailyStats> get daily;

  /// Create a copy of CreatorOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorOverviewImplCopyWith<_$CreatorOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorVideoStats _$CreatorVideoStatsFromJson(Map<String, dynamic> json) {
  return _CreatorVideoStats.fromJson(json);
}

/// @nodoc
mixin _$CreatorVideoStats {
  @JsonKey(fromJson: _idFromJson)
  String get videoId => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;
  int get viewers => throw _privateConstructorUsedError;

  /// Viewers who had never watched this creator and came in through this
  /// video.
  int get newViewers => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get comments => throw _privateConstructorUsedError;
  int get shares => throw _privateConstructorUsedError;
  int get saves => throw _privateConstructorUsedError;

  /// Serializes this CreatorVideoStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorVideoStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorVideoStatsCopyWith<CreatorVideoStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorVideoStatsCopyWith<$Res> {
  factory $CreatorVideoStatsCopyWith(
    CreatorVideoStats value,
    $Res Function(CreatorVideoStats) then,
  ) = _$CreatorVideoStatsCopyWithImpl<$Res, CreatorVideoStats>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    int views,
    int viewers,
    int newViewers,
    int likes,
    int comments,
    int shares,
    int saves,
  });
}

/// @nodoc
class _$CreatorVideoStatsCopyWithImpl<$Res, $Val extends CreatorVideoStats>
    implements $CreatorVideoStatsCopyWith<$Res> {
  _$CreatorVideoStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorVideoStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? views = null,
    Object? viewers = null,
    Object? newViewers = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
  }) {
    return _then(
      _value.copyWith(
            videoId: null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String,
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
            viewers: null == viewers
                ? _value.viewers
                : viewers // ignore: cast_nullable_to_non_nullable
                      as int,
            newViewers: null == newViewers
                ? _value.newViewers
                : newViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            likes: null == likes
                ? _value.likes
                : likes // ignore: cast_nullable_to_non_nullable
                      as int,
            comments: null == comments
                ? _value.comments
                : comments // ignore: cast_nullable_to_non_nullable
                      as int,
            shares: null == shares
                ? _value.shares
                : shares // ignore: cast_nullable_to_non_nullable
                      as int,
            saves: null == saves
                ? _value.saves
                : saves // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorVideoStatsImplCopyWith<$Res>
    implements $CreatorVideoStatsCopyWith<$Res> {
  factory _$$CreatorVideoStatsImplCopyWith(
    _$CreatorVideoStatsImpl value,
    $Res Function(_$CreatorVideoStatsImpl) then,
  ) = __$$CreatorVideoStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    int views,
    int viewers,
    int newViewers,
    int likes,
    int comments,
    int shares,
    int saves,
  });
}

/// @nodoc
class __$$CreatorVideoStatsImplCopyWithImpl<$Res>
    extends _$CreatorVideoStatsCopyWithImpl<$Res, _$CreatorVideoStatsImpl>
    implements _$$CreatorVideoStatsImplCopyWith<$Res> {
  __$$CreatorVideoStatsImplCopyWithImpl(
    _$CreatorVideoStatsImpl _value,
    $Res Function(_$CreatorVideoStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorVideoStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? views = null,
    Object? viewers = null,
    Object? newViewers = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
  }) {
    return _then(
      _$CreatorVideoStatsImpl(
        videoId: null == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String,
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
        viewers: null == viewers
            ? _value.viewers
            : viewers // ignore: cast_nullable_to_non_nullable
                  as int,
        newViewers: null == newViewers
            ? _value.newViewers
            : newViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        likes: null == likes
            ? _value.likes
            : likes // ignore: cast_nullable_to_non_nullable
                  as int,
        comments: null == comments
            ? _value.comments
            : comments // ignore: cast_nullable_to_non_nullable
                  as int,
        shares: null == shares
            ? _value.shares
            : shares // ignore: cast_nullable_to_non_nullable
                  as int,
        saves: null == saves
            ? _value.saves
            : saves // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorVideoStatsImpl implements _CreatorVideoStats {
  const _$CreatorVideoStatsImpl({
    @JsonKey(fromJson: _idFromJson) required this.videoId,
    this.views = 0,
    this.viewers = 0,
    this.newViewers = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
  });

  factory _$CreatorVideoStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorVideoStatsImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String videoId;
  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int viewers;

  /// Viewers who had never watched this creator and came in through this
  /// video.
  @override
  @JsonKey()
  final int newViewers;
  @override
  @JsonKey()
  final int likes;
  @override
  @JsonKey()
  final int comments;
  @override
  @JsonKey()
  final int shares;
  @override
  @JsonKey()
  final int saves;

  @override
  String toString() {
    return 'CreatorVideoStats(videoId: $videoId, views: $views, viewers: $viewers, newViewers: $newViewers, likes: $likes, comments: $comments, shares: $shares, saves: $saves)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorVideoStatsImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.viewers, viewers) || other.viewers == viewers) &&
            (identical(other.newViewers, newViewers) ||
                other.newViewers == newViewers) &&
            (identical(other.likes, likes) || other.likes == likes) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.shares, shares) || other.shares == shares) &&
            (identical(other.saves, saves) || other.saves == saves));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    videoId,
    views,
    viewers,
    newViewers,
    likes,
    comments,
    shares,
    saves,
  );

  /// Create a copy of CreatorVideoStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorVideoStatsImplCopyWith<_$CreatorVideoStatsImpl> get copyWith =>
      __$$CreatorVideoStatsImplCopyWithImpl<_$CreatorVideoStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorVideoStatsImplToJson(this);
  }
}

abstract class _CreatorVideoStats implements CreatorVideoStats {
  const factory _CreatorVideoStats({
    @JsonKey(fromJson: _idFromJson) required final String videoId,
    final int views,
    final int viewers,
    final int newViewers,
    final int likes,
    final int comments,
    final int shares,
    final int saves,
  }) = _$CreatorVideoStatsImpl;

  factory _CreatorVideoStats.fromJson(Map<String, dynamic> json) =
      _$CreatorVideoStatsImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get videoId;
  @override
  int get views;
  @override
  int get viewers;

  /// Viewers who had never watched this creator and came in through this
  /// video.
  @override
  int get newViewers;
  @override
  int get likes;
  @override
  int get comments;
  @override
  int get shares;
  @override
  int get saves;

  /// Create a copy of CreatorVideoStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorVideoStatsImplCopyWith<_$CreatorVideoStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorVideoTotals _$CreatorVideoTotalsFromJson(Map<String, dynamic> json) {
  return _CreatorVideoTotals.fromJson(json);
}

/// @nodoc
mixin _$CreatorVideoTotals {
  int get views => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get comments => throw _privateConstructorUsedError;
  int get shares => throw _privateConstructorUsedError;
  int get saves => throw _privateConstructorUsedError;
  int get newFollowers => throw _privateConstructorUsedError;

  /// Serializes this CreatorVideoTotals to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorVideoTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorVideoTotalsCopyWith<CreatorVideoTotals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorVideoTotalsCopyWith<$Res> {
  factory $CreatorVideoTotalsCopyWith(
    CreatorVideoTotals value,
    $Res Function(CreatorVideoTotals) then,
  ) = _$CreatorVideoTotalsCopyWithImpl<$Res, CreatorVideoTotals>;
  @useResult
  $Res call({
    int views,
    int likes,
    int comments,
    int shares,
    int saves,
    int newFollowers,
  });
}

/// @nodoc
class _$CreatorVideoTotalsCopyWithImpl<$Res, $Val extends CreatorVideoTotals>
    implements $CreatorVideoTotalsCopyWith<$Res> {
  _$CreatorVideoTotalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorVideoTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? views = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? newFollowers = null,
  }) {
    return _then(
      _value.copyWith(
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
            likes: null == likes
                ? _value.likes
                : likes // ignore: cast_nullable_to_non_nullable
                      as int,
            comments: null == comments
                ? _value.comments
                : comments // ignore: cast_nullable_to_non_nullable
                      as int,
            shares: null == shares
                ? _value.shares
                : shares // ignore: cast_nullable_to_non_nullable
                      as int,
            saves: null == saves
                ? _value.saves
                : saves // ignore: cast_nullable_to_non_nullable
                      as int,
            newFollowers: null == newFollowers
                ? _value.newFollowers
                : newFollowers // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorVideoTotalsImplCopyWith<$Res>
    implements $CreatorVideoTotalsCopyWith<$Res> {
  factory _$$CreatorVideoTotalsImplCopyWith(
    _$CreatorVideoTotalsImpl value,
    $Res Function(_$CreatorVideoTotalsImpl) then,
  ) = __$$CreatorVideoTotalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int views,
    int likes,
    int comments,
    int shares,
    int saves,
    int newFollowers,
  });
}

/// @nodoc
class __$$CreatorVideoTotalsImplCopyWithImpl<$Res>
    extends _$CreatorVideoTotalsCopyWithImpl<$Res, _$CreatorVideoTotalsImpl>
    implements _$$CreatorVideoTotalsImplCopyWith<$Res> {
  __$$CreatorVideoTotalsImplCopyWithImpl(
    _$CreatorVideoTotalsImpl _value,
    $Res Function(_$CreatorVideoTotalsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorVideoTotals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? views = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? newFollowers = null,
  }) {
    return _then(
      _$CreatorVideoTotalsImpl(
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
        likes: null == likes
            ? _value.likes
            : likes // ignore: cast_nullable_to_non_nullable
                  as int,
        comments: null == comments
            ? _value.comments
            : comments // ignore: cast_nullable_to_non_nullable
                  as int,
        shares: null == shares
            ? _value.shares
            : shares // ignore: cast_nullable_to_non_nullable
                  as int,
        saves: null == saves
            ? _value.saves
            : saves // ignore: cast_nullable_to_non_nullable
                  as int,
        newFollowers: null == newFollowers
            ? _value.newFollowers
            : newFollowers // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorVideoTotalsImpl implements _CreatorVideoTotals {
  const _$CreatorVideoTotalsImpl({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.newFollowers = 0,
  });

  factory _$CreatorVideoTotalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorVideoTotalsImplFromJson(json);

  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int likes;
  @override
  @JsonKey()
  final int comments;
  @override
  @JsonKey()
  final int shares;
  @override
  @JsonKey()
  final int saves;
  @override
  @JsonKey()
  final int newFollowers;

  @override
  String toString() {
    return 'CreatorVideoTotals(views: $views, likes: $likes, comments: $comments, shares: $shares, saves: $saves, newFollowers: $newFollowers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorVideoTotalsImpl &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.likes, likes) || other.likes == likes) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.shares, shares) || other.shares == shares) &&
            (identical(other.saves, saves) || other.saves == saves) &&
            (identical(other.newFollowers, newFollowers) ||
                other.newFollowers == newFollowers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    views,
    likes,
    comments,
    shares,
    saves,
    newFollowers,
  );

  /// Create a copy of CreatorVideoTotals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorVideoTotalsImplCopyWith<_$CreatorVideoTotalsImpl> get copyWith =>
      __$$CreatorVideoTotalsImplCopyWithImpl<_$CreatorVideoTotalsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorVideoTotalsImplToJson(this);
  }
}

abstract class _CreatorVideoTotals implements CreatorVideoTotals {
  const factory _CreatorVideoTotals({
    final int views,
    final int likes,
    final int comments,
    final int shares,
    final int saves,
    final int newFollowers,
  }) = _$CreatorVideoTotalsImpl;

  factory _CreatorVideoTotals.fromJson(Map<String, dynamic> json) =
      _$CreatorVideoTotalsImpl.fromJson;

  @override
  int get views;
  @override
  int get likes;
  @override
  int get comments;
  @override
  int get shares;
  @override
  int get saves;
  @override
  int get newFollowers;

  /// Create a copy of CreatorVideoTotals
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorVideoTotalsImplCopyWith<_$CreatorVideoTotalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrafficSourceRow _$TrafficSourceRowFromJson(Map<String, dynamic> json) {
  return _TrafficSourceRow.fromJson(json);
}

/// @nodoc
mixin _$TrafficSourceRow {
  @JsonKey(unknownEnumValue: TrafficSource.unknown)
  TrafficSource get source => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;

  /// Serializes this TrafficSourceRow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrafficSourceRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrafficSourceRowCopyWith<TrafficSourceRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrafficSourceRowCopyWith<$Res> {
  factory $TrafficSourceRowCopyWith(
    TrafficSourceRow value,
    $Res Function(TrafficSourceRow) then,
  ) = _$TrafficSourceRowCopyWithImpl<$Res, TrafficSourceRow>;
  @useResult
  $Res call({
    @JsonKey(unknownEnumValue: TrafficSource.unknown) TrafficSource source,
    int views,
  });
}

/// @nodoc
class _$TrafficSourceRowCopyWithImpl<$Res, $Val extends TrafficSourceRow>
    implements $TrafficSourceRowCopyWith<$Res> {
  _$TrafficSourceRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrafficSourceRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? source = null, Object? views = null}) {
    return _then(
      _value.copyWith(
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as TrafficSource,
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TrafficSourceRowImplCopyWith<$Res>
    implements $TrafficSourceRowCopyWith<$Res> {
  factory _$$TrafficSourceRowImplCopyWith(
    _$TrafficSourceRowImpl value,
    $Res Function(_$TrafficSourceRowImpl) then,
  ) = __$$TrafficSourceRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(unknownEnumValue: TrafficSource.unknown) TrafficSource source,
    int views,
  });
}

/// @nodoc
class __$$TrafficSourceRowImplCopyWithImpl<$Res>
    extends _$TrafficSourceRowCopyWithImpl<$Res, _$TrafficSourceRowImpl>
    implements _$$TrafficSourceRowImplCopyWith<$Res> {
  __$$TrafficSourceRowImplCopyWithImpl(
    _$TrafficSourceRowImpl _value,
    $Res Function(_$TrafficSourceRowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrafficSourceRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? source = null, Object? views = null}) {
    return _then(
      _$TrafficSourceRowImpl(
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as TrafficSource,
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TrafficSourceRowImpl implements _TrafficSourceRow {
  const _$TrafficSourceRowImpl({
    @JsonKey(unknownEnumValue: TrafficSource.unknown) required this.source,
    this.views = 0,
  });

  factory _$TrafficSourceRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrafficSourceRowImplFromJson(json);

  @override
  @JsonKey(unknownEnumValue: TrafficSource.unknown)
  final TrafficSource source;
  @override
  @JsonKey()
  final int views;

  @override
  String toString() {
    return 'TrafficSourceRow(source: $source, views: $views)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrafficSourceRowImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.views, views) || other.views == views));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, source, views);

  /// Create a copy of TrafficSourceRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrafficSourceRowImplCopyWith<_$TrafficSourceRowImpl> get copyWith =>
      __$$TrafficSourceRowImplCopyWithImpl<_$TrafficSourceRowImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TrafficSourceRowImplToJson(this);
  }
}

abstract class _TrafficSourceRow implements TrafficSourceRow {
  const factory _TrafficSourceRow({
    @JsonKey(unknownEnumValue: TrafficSource.unknown)
    required final TrafficSource source,
    final int views,
  }) = _$TrafficSourceRowImpl;

  factory _TrafficSourceRow.fromJson(Map<String, dynamic> json) =
      _$TrafficSourceRowImpl.fromJson;

  @override
  @JsonKey(unknownEnumValue: TrafficSource.unknown)
  TrafficSource get source;
  @override
  int get views;

  /// Create a copy of TrafficSourceRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrafficSourceRowImplCopyWith<_$TrafficSourceRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchQueryRow _$SearchQueryRowFromJson(Map<String, dynamic> json) {
  return _SearchQueryRow.fromJson(json);
}

/// @nodoc
mixin _$SearchQueryRow {
  String get query => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;

  /// Serializes this SearchQueryRow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchQueryRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchQueryRowCopyWith<SearchQueryRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchQueryRowCopyWith<$Res> {
  factory $SearchQueryRowCopyWith(
    SearchQueryRow value,
    $Res Function(SearchQueryRow) then,
  ) = _$SearchQueryRowCopyWithImpl<$Res, SearchQueryRow>;
  @useResult
  $Res call({String query, int views});
}

/// @nodoc
class _$SearchQueryRowCopyWithImpl<$Res, $Val extends SearchQueryRow>
    implements $SearchQueryRowCopyWith<$Res> {
  _$SearchQueryRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchQueryRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? views = null}) {
    return _then(
      _value.copyWith(
            query: null == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                      as String,
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchQueryRowImplCopyWith<$Res>
    implements $SearchQueryRowCopyWith<$Res> {
  factory _$$SearchQueryRowImplCopyWith(
    _$SearchQueryRowImpl value,
    $Res Function(_$SearchQueryRowImpl) then,
  ) = __$$SearchQueryRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String query, int views});
}

/// @nodoc
class __$$SearchQueryRowImplCopyWithImpl<$Res>
    extends _$SearchQueryRowCopyWithImpl<$Res, _$SearchQueryRowImpl>
    implements _$$SearchQueryRowImplCopyWith<$Res> {
  __$$SearchQueryRowImplCopyWithImpl(
    _$SearchQueryRowImpl _value,
    $Res Function(_$SearchQueryRowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchQueryRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? views = null}) {
    return _then(
      _$SearchQueryRowImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchQueryRowImpl implements _SearchQueryRow {
  const _$SearchQueryRowImpl({required this.query, this.views = 0});

  factory _$SearchQueryRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchQueryRowImplFromJson(json);

  @override
  final String query;
  @override
  @JsonKey()
  final int views;

  @override
  String toString() {
    return 'SearchQueryRow(query: $query, views: $views)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchQueryRowImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.views, views) || other.views == views));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, query, views);

  /// Create a copy of SearchQueryRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchQueryRowImplCopyWith<_$SearchQueryRowImpl> get copyWith =>
      __$$SearchQueryRowImplCopyWithImpl<_$SearchQueryRowImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchQueryRowImplToJson(this);
  }
}

abstract class _SearchQueryRow implements SearchQueryRow {
  const factory _SearchQueryRow({
    required final String query,
    final int views,
  }) = _$SearchQueryRowImpl;

  factory _SearchQueryRow.fromJson(Map<String, dynamic> json) =
      _$SearchQueryRowImpl.fromJson;

  @override
  String get query;
  @override
  int get views;

  /// Create a copy of SearchQueryRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchQueryRowImplCopyWith<_$SearchQueryRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorVideoViewers _$CreatorVideoViewersFromJson(Map<String, dynamic> json) {
  return _CreatorVideoViewers.fromJson(json);
}

/// @nodoc
mixin _$CreatorVideoViewers {
  int get total => throw _privateConstructorUsedError;
  int get newViewers => throw _privateConstructorUsedError;
  int get previousTotal => throw _privateConstructorUsedError;
  int get previousNewViewers => throw _privateConstructorUsedError;
  bool get breakdownAvailable => throw _privateConstructorUsedError;
  int? get returning => throw _privateConstructorUsedError;
  int? get followers => throw _privateConstructorUsedError;
  int? get nonFollowers => throw _privateConstructorUsedError;

  /// Always the seven keys `13-17, 18-24, 25-34, 35-44, 45-54, 55+,
  /// UNKNOWN` when present.
  Map<String, int>? get ageGroups => throw _privateConstructorUsedError;

  /// Serializes this CreatorVideoViewers to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorVideoViewers
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorVideoViewersCopyWith<CreatorVideoViewers> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorVideoViewersCopyWith<$Res> {
  factory $CreatorVideoViewersCopyWith(
    CreatorVideoViewers value,
    $Res Function(CreatorVideoViewers) then,
  ) = _$CreatorVideoViewersCopyWithImpl<$Res, CreatorVideoViewers>;
  @useResult
  $Res call({
    int total,
    int newViewers,
    int previousTotal,
    int previousNewViewers,
    bool breakdownAvailable,
    int? returning,
    int? followers,
    int? nonFollowers,
    Map<String, int>? ageGroups,
  });
}

/// @nodoc
class _$CreatorVideoViewersCopyWithImpl<$Res, $Val extends CreatorVideoViewers>
    implements $CreatorVideoViewersCopyWith<$Res> {
  _$CreatorVideoViewersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorVideoViewers
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? newViewers = null,
    Object? previousTotal = null,
    Object? previousNewViewers = null,
    Object? breakdownAvailable = null,
    Object? returning = freezed,
    Object? followers = freezed,
    Object? nonFollowers = freezed,
    Object? ageGroups = freezed,
  }) {
    return _then(
      _value.copyWith(
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            newViewers: null == newViewers
                ? _value.newViewers
                : newViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            previousTotal: null == previousTotal
                ? _value.previousTotal
                : previousTotal // ignore: cast_nullable_to_non_nullable
                      as int,
            previousNewViewers: null == previousNewViewers
                ? _value.previousNewViewers
                : previousNewViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            breakdownAvailable: null == breakdownAvailable
                ? _value.breakdownAvailable
                : breakdownAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            returning: freezed == returning
                ? _value.returning
                : returning // ignore: cast_nullable_to_non_nullable
                      as int?,
            followers: freezed == followers
                ? _value.followers
                : followers // ignore: cast_nullable_to_non_nullable
                      as int?,
            nonFollowers: freezed == nonFollowers
                ? _value.nonFollowers
                : nonFollowers // ignore: cast_nullable_to_non_nullable
                      as int?,
            ageGroups: freezed == ageGroups
                ? _value.ageGroups
                : ageGroups // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorVideoViewersImplCopyWith<$Res>
    implements $CreatorVideoViewersCopyWith<$Res> {
  factory _$$CreatorVideoViewersImplCopyWith(
    _$CreatorVideoViewersImpl value,
    $Res Function(_$CreatorVideoViewersImpl) then,
  ) = __$$CreatorVideoViewersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int total,
    int newViewers,
    int previousTotal,
    int previousNewViewers,
    bool breakdownAvailable,
    int? returning,
    int? followers,
    int? nonFollowers,
    Map<String, int>? ageGroups,
  });
}

/// @nodoc
class __$$CreatorVideoViewersImplCopyWithImpl<$Res>
    extends _$CreatorVideoViewersCopyWithImpl<$Res, _$CreatorVideoViewersImpl>
    implements _$$CreatorVideoViewersImplCopyWith<$Res> {
  __$$CreatorVideoViewersImplCopyWithImpl(
    _$CreatorVideoViewersImpl _value,
    $Res Function(_$CreatorVideoViewersImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorVideoViewers
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? newViewers = null,
    Object? previousTotal = null,
    Object? previousNewViewers = null,
    Object? breakdownAvailable = null,
    Object? returning = freezed,
    Object? followers = freezed,
    Object? nonFollowers = freezed,
    Object? ageGroups = freezed,
  }) {
    return _then(
      _$CreatorVideoViewersImpl(
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        newViewers: null == newViewers
            ? _value.newViewers
            : newViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        previousTotal: null == previousTotal
            ? _value.previousTotal
            : previousTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        previousNewViewers: null == previousNewViewers
            ? _value.previousNewViewers
            : previousNewViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        breakdownAvailable: null == breakdownAvailable
            ? _value.breakdownAvailable
            : breakdownAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        returning: freezed == returning
            ? _value.returning
            : returning // ignore: cast_nullable_to_non_nullable
                  as int?,
        followers: freezed == followers
            ? _value.followers
            : followers // ignore: cast_nullable_to_non_nullable
                  as int?,
        nonFollowers: freezed == nonFollowers
            ? _value.nonFollowers
            : nonFollowers // ignore: cast_nullable_to_non_nullable
                  as int?,
        ageGroups: freezed == ageGroups
            ? _value._ageGroups
            : ageGroups // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorVideoViewersImpl implements _CreatorVideoViewers {
  const _$CreatorVideoViewersImpl({
    this.total = 0,
    this.newViewers = 0,
    this.previousTotal = 0,
    this.previousNewViewers = 0,
    this.breakdownAvailable = false,
    this.returning,
    this.followers,
    this.nonFollowers,
    final Map<String, int>? ageGroups,
  }) : _ageGroups = ageGroups;

  factory _$CreatorVideoViewersImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorVideoViewersImplFromJson(json);

  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final int newViewers;
  @override
  @JsonKey()
  final int previousTotal;
  @override
  @JsonKey()
  final int previousNewViewers;
  @override
  @JsonKey()
  final bool breakdownAvailable;
  @override
  final int? returning;
  @override
  final int? followers;
  @override
  final int? nonFollowers;

  /// Always the seven keys `13-17, 18-24, 25-34, 35-44, 45-54, 55+,
  /// UNKNOWN` when present.
  final Map<String, int>? _ageGroups;

  /// Always the seven keys `13-17, 18-24, 25-34, 35-44, 45-54, 55+,
  /// UNKNOWN` when present.
  @override
  Map<String, int>? get ageGroups {
    final value = _ageGroups;
    if (value == null) return null;
    if (_ageGroups is EqualUnmodifiableMapView) return _ageGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'CreatorVideoViewers(total: $total, newViewers: $newViewers, previousTotal: $previousTotal, previousNewViewers: $previousNewViewers, breakdownAvailable: $breakdownAvailable, returning: $returning, followers: $followers, nonFollowers: $nonFollowers, ageGroups: $ageGroups)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorVideoViewersImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.newViewers, newViewers) ||
                other.newViewers == newViewers) &&
            (identical(other.previousTotal, previousTotal) ||
                other.previousTotal == previousTotal) &&
            (identical(other.previousNewViewers, previousNewViewers) ||
                other.previousNewViewers == previousNewViewers) &&
            (identical(other.breakdownAvailable, breakdownAvailable) ||
                other.breakdownAvailable == breakdownAvailable) &&
            (identical(other.returning, returning) ||
                other.returning == returning) &&
            (identical(other.followers, followers) ||
                other.followers == followers) &&
            (identical(other.nonFollowers, nonFollowers) ||
                other.nonFollowers == nonFollowers) &&
            const DeepCollectionEquality().equals(
              other._ageGroups,
              _ageGroups,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    total,
    newViewers,
    previousTotal,
    previousNewViewers,
    breakdownAvailable,
    returning,
    followers,
    nonFollowers,
    const DeepCollectionEquality().hash(_ageGroups),
  );

  /// Create a copy of CreatorVideoViewers
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorVideoViewersImplCopyWith<_$CreatorVideoViewersImpl> get copyWith =>
      __$$CreatorVideoViewersImplCopyWithImpl<_$CreatorVideoViewersImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorVideoViewersImplToJson(this);
  }
}

abstract class _CreatorVideoViewers implements CreatorVideoViewers {
  const factory _CreatorVideoViewers({
    final int total,
    final int newViewers,
    final int previousTotal,
    final int previousNewViewers,
    final bool breakdownAvailable,
    final int? returning,
    final int? followers,
    final int? nonFollowers,
    final Map<String, int>? ageGroups,
  }) = _$CreatorVideoViewersImpl;

  factory _CreatorVideoViewers.fromJson(Map<String, dynamic> json) =
      _$CreatorVideoViewersImpl.fromJson;

  @override
  int get total;
  @override
  int get newViewers;
  @override
  int get previousTotal;
  @override
  int get previousNewViewers;
  @override
  bool get breakdownAvailable;
  @override
  int? get returning;
  @override
  int? get followers;
  @override
  int? get nonFollowers;

  /// Always the seven keys `13-17, 18-24, 25-34, 35-44, 45-54, 55+,
  /// UNKNOWN` when present.
  @override
  Map<String, int>? get ageGroups;

  /// Create a copy of CreatorVideoViewers
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorVideoViewersImplCopyWith<_$CreatorVideoViewersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorVideoDetail _$CreatorVideoDetailFromJson(Map<String, dynamic> json) {
  return _CreatorVideoDetail.fromJson(json);
}

/// @nodoc
mixin _$CreatorVideoDetail {
  @JsonKey(fromJson: _idFromJson)
  String get videoId => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;
  int get viewers => throw _privateConstructorUsedError;
  int get totalWatchMs => throw _privateConstructorUsedError;
  int get avgWatchMs => throw _privateConstructorUsedError;

  /// Share of views that reached the end, 0 to 1.
  double get completionRate => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get comments => throw _privateConstructorUsedError;
  int get shares => throw _privateConstructorUsedError;
  int get saves => throw _privateConstructorUsedError;
  int get newFollowers => throw _privateConstructorUsedError;

  /// 21 points, 0% to 100% of the video in 5% steps: the share of views
  /// still watching there.
  List<double> get retention => throw _privateConstructorUsedError;
  List<CreatorDailyStats> get daily => throw _privateConstructorUsedError;
  CreatorVideoTotals get current => throw _privateConstructorUsedError;
  CreatorVideoTotals get previous => throw _privateConstructorUsedError;
  List<TrafficSourceRow> get trafficSources =>
      throw _privateConstructorUsedError;
  List<SearchQueryRow> get searchQueries => throw _privateConstructorUsedError;
  CreatorVideoViewers get audience => throw _privateConstructorUsedError;

  /// Serializes this CreatorVideoDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorVideoDetailCopyWith<CreatorVideoDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorVideoDetailCopyWith<$Res> {
  factory $CreatorVideoDetailCopyWith(
    CreatorVideoDetail value,
    $Res Function(CreatorVideoDetail) then,
  ) = _$CreatorVideoDetailCopyWithImpl<$Res, CreatorVideoDetail>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    int views,
    int viewers,
    int totalWatchMs,
    int avgWatchMs,
    double completionRate,
    int likes,
    int comments,
    int shares,
    int saves,
    int newFollowers,
    List<double> retention,
    List<CreatorDailyStats> daily,
    CreatorVideoTotals current,
    CreatorVideoTotals previous,
    List<TrafficSourceRow> trafficSources,
    List<SearchQueryRow> searchQueries,
    CreatorVideoViewers audience,
  });

  $CreatorVideoTotalsCopyWith<$Res> get current;
  $CreatorVideoTotalsCopyWith<$Res> get previous;
  $CreatorVideoViewersCopyWith<$Res> get audience;
}

/// @nodoc
class _$CreatorVideoDetailCopyWithImpl<$Res, $Val extends CreatorVideoDetail>
    implements $CreatorVideoDetailCopyWith<$Res> {
  _$CreatorVideoDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? views = null,
    Object? viewers = null,
    Object? totalWatchMs = null,
    Object? avgWatchMs = null,
    Object? completionRate = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? newFollowers = null,
    Object? retention = null,
    Object? daily = null,
    Object? current = null,
    Object? previous = null,
    Object? trafficSources = null,
    Object? searchQueries = null,
    Object? audience = null,
  }) {
    return _then(
      _value.copyWith(
            videoId: null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String,
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as int,
            viewers: null == viewers
                ? _value.viewers
                : viewers // ignore: cast_nullable_to_non_nullable
                      as int,
            totalWatchMs: null == totalWatchMs
                ? _value.totalWatchMs
                : totalWatchMs // ignore: cast_nullable_to_non_nullable
                      as int,
            avgWatchMs: null == avgWatchMs
                ? _value.avgWatchMs
                : avgWatchMs // ignore: cast_nullable_to_non_nullable
                      as int,
            completionRate: null == completionRate
                ? _value.completionRate
                : completionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            likes: null == likes
                ? _value.likes
                : likes // ignore: cast_nullable_to_non_nullable
                      as int,
            comments: null == comments
                ? _value.comments
                : comments // ignore: cast_nullable_to_non_nullable
                      as int,
            shares: null == shares
                ? _value.shares
                : shares // ignore: cast_nullable_to_non_nullable
                      as int,
            saves: null == saves
                ? _value.saves
                : saves // ignore: cast_nullable_to_non_nullable
                      as int,
            newFollowers: null == newFollowers
                ? _value.newFollowers
                : newFollowers // ignore: cast_nullable_to_non_nullable
                      as int,
            retention: null == retention
                ? _value.retention
                : retention // ignore: cast_nullable_to_non_nullable
                      as List<double>,
            daily: null == daily
                ? _value.daily
                : daily // ignore: cast_nullable_to_non_nullable
                      as List<CreatorDailyStats>,
            current: null == current
                ? _value.current
                : current // ignore: cast_nullable_to_non_nullable
                      as CreatorVideoTotals,
            previous: null == previous
                ? _value.previous
                : previous // ignore: cast_nullable_to_non_nullable
                      as CreatorVideoTotals,
            trafficSources: null == trafficSources
                ? _value.trafficSources
                : trafficSources // ignore: cast_nullable_to_non_nullable
                      as List<TrafficSourceRow>,
            searchQueries: null == searchQueries
                ? _value.searchQueries
                : searchQueries // ignore: cast_nullable_to_non_nullable
                      as List<SearchQueryRow>,
            audience: null == audience
                ? _value.audience
                : audience // ignore: cast_nullable_to_non_nullable
                      as CreatorVideoViewers,
          )
          as $Val,
    );
  }

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorVideoTotalsCopyWith<$Res> get current {
    return $CreatorVideoTotalsCopyWith<$Res>(_value.current, (value) {
      return _then(_value.copyWith(current: value) as $Val);
    });
  }

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorVideoTotalsCopyWith<$Res> get previous {
    return $CreatorVideoTotalsCopyWith<$Res>(_value.previous, (value) {
      return _then(_value.copyWith(previous: value) as $Val);
    });
  }

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorVideoViewersCopyWith<$Res> get audience {
    return $CreatorVideoViewersCopyWith<$Res>(_value.audience, (value) {
      return _then(_value.copyWith(audience: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CreatorVideoDetailImplCopyWith<$Res>
    implements $CreatorVideoDetailCopyWith<$Res> {
  factory _$$CreatorVideoDetailImplCopyWith(
    _$CreatorVideoDetailImpl value,
    $Res Function(_$CreatorVideoDetailImpl) then,
  ) = __$$CreatorVideoDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    int views,
    int viewers,
    int totalWatchMs,
    int avgWatchMs,
    double completionRate,
    int likes,
    int comments,
    int shares,
    int saves,
    int newFollowers,
    List<double> retention,
    List<CreatorDailyStats> daily,
    CreatorVideoTotals current,
    CreatorVideoTotals previous,
    List<TrafficSourceRow> trafficSources,
    List<SearchQueryRow> searchQueries,
    CreatorVideoViewers audience,
  });

  @override
  $CreatorVideoTotalsCopyWith<$Res> get current;
  @override
  $CreatorVideoTotalsCopyWith<$Res> get previous;
  @override
  $CreatorVideoViewersCopyWith<$Res> get audience;
}

/// @nodoc
class __$$CreatorVideoDetailImplCopyWithImpl<$Res>
    extends _$CreatorVideoDetailCopyWithImpl<$Res, _$CreatorVideoDetailImpl>
    implements _$$CreatorVideoDetailImplCopyWith<$Res> {
  __$$CreatorVideoDetailImplCopyWithImpl(
    _$CreatorVideoDetailImpl _value,
    $Res Function(_$CreatorVideoDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? views = null,
    Object? viewers = null,
    Object? totalWatchMs = null,
    Object? avgWatchMs = null,
    Object? completionRate = null,
    Object? likes = null,
    Object? comments = null,
    Object? shares = null,
    Object? saves = null,
    Object? newFollowers = null,
    Object? retention = null,
    Object? daily = null,
    Object? current = null,
    Object? previous = null,
    Object? trafficSources = null,
    Object? searchQueries = null,
    Object? audience = null,
  }) {
    return _then(
      _$CreatorVideoDetailImpl(
        videoId: null == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String,
        views: null == views
            ? _value.views
            : views // ignore: cast_nullable_to_non_nullable
                  as int,
        viewers: null == viewers
            ? _value.viewers
            : viewers // ignore: cast_nullable_to_non_nullable
                  as int,
        totalWatchMs: null == totalWatchMs
            ? _value.totalWatchMs
            : totalWatchMs // ignore: cast_nullable_to_non_nullable
                  as int,
        avgWatchMs: null == avgWatchMs
            ? _value.avgWatchMs
            : avgWatchMs // ignore: cast_nullable_to_non_nullable
                  as int,
        completionRate: null == completionRate
            ? _value.completionRate
            : completionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        likes: null == likes
            ? _value.likes
            : likes // ignore: cast_nullable_to_non_nullable
                  as int,
        comments: null == comments
            ? _value.comments
            : comments // ignore: cast_nullable_to_non_nullable
                  as int,
        shares: null == shares
            ? _value.shares
            : shares // ignore: cast_nullable_to_non_nullable
                  as int,
        saves: null == saves
            ? _value.saves
            : saves // ignore: cast_nullable_to_non_nullable
                  as int,
        newFollowers: null == newFollowers
            ? _value.newFollowers
            : newFollowers // ignore: cast_nullable_to_non_nullable
                  as int,
        retention: null == retention
            ? _value._retention
            : retention // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        daily: null == daily
            ? _value._daily
            : daily // ignore: cast_nullable_to_non_nullable
                  as List<CreatorDailyStats>,
        current: null == current
            ? _value.current
            : current // ignore: cast_nullable_to_non_nullable
                  as CreatorVideoTotals,
        previous: null == previous
            ? _value.previous
            : previous // ignore: cast_nullable_to_non_nullable
                  as CreatorVideoTotals,
        trafficSources: null == trafficSources
            ? _value._trafficSources
            : trafficSources // ignore: cast_nullable_to_non_nullable
                  as List<TrafficSourceRow>,
        searchQueries: null == searchQueries
            ? _value._searchQueries
            : searchQueries // ignore: cast_nullable_to_non_nullable
                  as List<SearchQueryRow>,
        audience: null == audience
            ? _value.audience
            : audience // ignore: cast_nullable_to_non_nullable
                  as CreatorVideoViewers,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorVideoDetailImpl implements _CreatorVideoDetail {
  const _$CreatorVideoDetailImpl({
    @JsonKey(fromJson: _idFromJson) required this.videoId,
    this.views = 0,
    this.viewers = 0,
    this.totalWatchMs = 0,
    this.avgWatchMs = 0,
    this.completionRate = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.newFollowers = 0,
    final List<double> retention = const [],
    final List<CreatorDailyStats> daily = const [],
    this.current = const CreatorVideoTotals(),
    this.previous = const CreatorVideoTotals(),
    final List<TrafficSourceRow> trafficSources = const [],
    final List<SearchQueryRow> searchQueries = const [],
    this.audience = const CreatorVideoViewers(),
  }) : _retention = retention,
       _daily = daily,
       _trafficSources = trafficSources,
       _searchQueries = searchQueries;

  factory _$CreatorVideoDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorVideoDetailImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String videoId;
  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int viewers;
  @override
  @JsonKey()
  final int totalWatchMs;
  @override
  @JsonKey()
  final int avgWatchMs;

  /// Share of views that reached the end, 0 to 1.
  @override
  @JsonKey()
  final double completionRate;
  @override
  @JsonKey()
  final int likes;
  @override
  @JsonKey()
  final int comments;
  @override
  @JsonKey()
  final int shares;
  @override
  @JsonKey()
  final int saves;
  @override
  @JsonKey()
  final int newFollowers;

  /// 21 points, 0% to 100% of the video in 5% steps: the share of views
  /// still watching there.
  final List<double> _retention;

  /// 21 points, 0% to 100% of the video in 5% steps: the share of views
  /// still watching there.
  @override
  @JsonKey()
  List<double> get retention {
    if (_retention is EqualUnmodifiableListView) return _retention;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_retention);
  }

  final List<CreatorDailyStats> _daily;
  @override
  @JsonKey()
  List<CreatorDailyStats> get daily {
    if (_daily is EqualUnmodifiableListView) return _daily;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_daily);
  }

  @override
  @JsonKey()
  final CreatorVideoTotals current;
  @override
  @JsonKey()
  final CreatorVideoTotals previous;
  final List<TrafficSourceRow> _trafficSources;
  @override
  @JsonKey()
  List<TrafficSourceRow> get trafficSources {
    if (_trafficSources is EqualUnmodifiableListView) return _trafficSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_trafficSources);
  }

  final List<SearchQueryRow> _searchQueries;
  @override
  @JsonKey()
  List<SearchQueryRow> get searchQueries {
    if (_searchQueries is EqualUnmodifiableListView) return _searchQueries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_searchQueries);
  }

  @override
  @JsonKey()
  final CreatorVideoViewers audience;

  @override
  String toString() {
    return 'CreatorVideoDetail(videoId: $videoId, views: $views, viewers: $viewers, totalWatchMs: $totalWatchMs, avgWatchMs: $avgWatchMs, completionRate: $completionRate, likes: $likes, comments: $comments, shares: $shares, saves: $saves, newFollowers: $newFollowers, retention: $retention, daily: $daily, current: $current, previous: $previous, trafficSources: $trafficSources, searchQueries: $searchQueries, audience: $audience)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorVideoDetailImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.viewers, viewers) || other.viewers == viewers) &&
            (identical(other.totalWatchMs, totalWatchMs) ||
                other.totalWatchMs == totalWatchMs) &&
            (identical(other.avgWatchMs, avgWatchMs) ||
                other.avgWatchMs == avgWatchMs) &&
            (identical(other.completionRate, completionRate) ||
                other.completionRate == completionRate) &&
            (identical(other.likes, likes) || other.likes == likes) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.shares, shares) || other.shares == shares) &&
            (identical(other.saves, saves) || other.saves == saves) &&
            (identical(other.newFollowers, newFollowers) ||
                other.newFollowers == newFollowers) &&
            const DeepCollectionEquality().equals(
              other._retention,
              _retention,
            ) &&
            const DeepCollectionEquality().equals(other._daily, _daily) &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.previous, previous) ||
                other.previous == previous) &&
            const DeepCollectionEquality().equals(
              other._trafficSources,
              _trafficSources,
            ) &&
            const DeepCollectionEquality().equals(
              other._searchQueries,
              _searchQueries,
            ) &&
            (identical(other.audience, audience) ||
                other.audience == audience));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    videoId,
    views,
    viewers,
    totalWatchMs,
    avgWatchMs,
    completionRate,
    likes,
    comments,
    shares,
    saves,
    newFollowers,
    const DeepCollectionEquality().hash(_retention),
    const DeepCollectionEquality().hash(_daily),
    current,
    previous,
    const DeepCollectionEquality().hash(_trafficSources),
    const DeepCollectionEquality().hash(_searchQueries),
    audience,
  );

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorVideoDetailImplCopyWith<_$CreatorVideoDetailImpl> get copyWith =>
      __$$CreatorVideoDetailImplCopyWithImpl<_$CreatorVideoDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorVideoDetailImplToJson(this);
  }
}

abstract class _CreatorVideoDetail implements CreatorVideoDetail {
  const factory _CreatorVideoDetail({
    @JsonKey(fromJson: _idFromJson) required final String videoId,
    final int views,
    final int viewers,
    final int totalWatchMs,
    final int avgWatchMs,
    final double completionRate,
    final int likes,
    final int comments,
    final int shares,
    final int saves,
    final int newFollowers,
    final List<double> retention,
    final List<CreatorDailyStats> daily,
    final CreatorVideoTotals current,
    final CreatorVideoTotals previous,
    final List<TrafficSourceRow> trafficSources,
    final List<SearchQueryRow> searchQueries,
    final CreatorVideoViewers audience,
  }) = _$CreatorVideoDetailImpl;

  factory _CreatorVideoDetail.fromJson(Map<String, dynamic> json) =
      _$CreatorVideoDetailImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get videoId;
  @override
  int get views;
  @override
  int get viewers;
  @override
  int get totalWatchMs;
  @override
  int get avgWatchMs;

  /// Share of views that reached the end, 0 to 1.
  @override
  double get completionRate;
  @override
  int get likes;
  @override
  int get comments;
  @override
  int get shares;
  @override
  int get saves;
  @override
  int get newFollowers;

  /// 21 points, 0% to 100% of the video in 5% steps: the share of views
  /// still watching there.
  @override
  List<double> get retention;
  @override
  List<CreatorDailyStats> get daily;
  @override
  CreatorVideoTotals get current;
  @override
  CreatorVideoTotals get previous;
  @override
  List<TrafficSourceRow> get trafficSources;
  @override
  List<SearchQueryRow> get searchQueries;
  @override
  CreatorVideoViewers get audience;

  /// Create a copy of CreatorVideoDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorVideoDetailImplCopyWith<_$CreatorVideoDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreatorViewers _$CreatorViewersFromJson(Map<String, dynamic> json) {
  return _CreatorViewers.fromJson(json);
}

/// @nodoc
mixin _$CreatorViewers {
  int get totalViewers => throw _privateConstructorUsedError;
  int get newViewers => throw _privateConstructorUsedError;
  int get previousTotalViewers => throw _privateConstructorUsedError;
  int get previousNewViewers => throw _privateConstructorUsedError;
  bool get breakdownAvailable => throw _privateConstructorUsedError;

  /// Distinct viewers by hour, 24 entries from 00:00 (Vietnam time).
  List<int>? get activeHours => throw _privateConstructorUsedError;

  /// Distinct viewers by weekday, 7 entries from Monday.
  List<int>? get activeDays => throw _privateConstructorUsedError;

  /// Serializes this CreatorViewers to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreatorViewers
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorViewersCopyWith<CreatorViewers> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorViewersCopyWith<$Res> {
  factory $CreatorViewersCopyWith(
    CreatorViewers value,
    $Res Function(CreatorViewers) then,
  ) = _$CreatorViewersCopyWithImpl<$Res, CreatorViewers>;
  @useResult
  $Res call({
    int totalViewers,
    int newViewers,
    int previousTotalViewers,
    int previousNewViewers,
    bool breakdownAvailable,
    List<int>? activeHours,
    List<int>? activeDays,
  });
}

/// @nodoc
class _$CreatorViewersCopyWithImpl<$Res, $Val extends CreatorViewers>
    implements $CreatorViewersCopyWith<$Res> {
  _$CreatorViewersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatorViewers
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalViewers = null,
    Object? newViewers = null,
    Object? previousTotalViewers = null,
    Object? previousNewViewers = null,
    Object? breakdownAvailable = null,
    Object? activeHours = freezed,
    Object? activeDays = freezed,
  }) {
    return _then(
      _value.copyWith(
            totalViewers: null == totalViewers
                ? _value.totalViewers
                : totalViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            newViewers: null == newViewers
                ? _value.newViewers
                : newViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            previousTotalViewers: null == previousTotalViewers
                ? _value.previousTotalViewers
                : previousTotalViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            previousNewViewers: null == previousNewViewers
                ? _value.previousNewViewers
                : previousNewViewers // ignore: cast_nullable_to_non_nullable
                      as int,
            breakdownAvailable: null == breakdownAvailable
                ? _value.breakdownAvailable
                : breakdownAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            activeHours: freezed == activeHours
                ? _value.activeHours
                : activeHours // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            activeDays: freezed == activeDays
                ? _value.activeDays
                : activeDays // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatorViewersImplCopyWith<$Res>
    implements $CreatorViewersCopyWith<$Res> {
  factory _$$CreatorViewersImplCopyWith(
    _$CreatorViewersImpl value,
    $Res Function(_$CreatorViewersImpl) then,
  ) = __$$CreatorViewersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalViewers,
    int newViewers,
    int previousTotalViewers,
    int previousNewViewers,
    bool breakdownAvailable,
    List<int>? activeHours,
    List<int>? activeDays,
  });
}

/// @nodoc
class __$$CreatorViewersImplCopyWithImpl<$Res>
    extends _$CreatorViewersCopyWithImpl<$Res, _$CreatorViewersImpl>
    implements _$$CreatorViewersImplCopyWith<$Res> {
  __$$CreatorViewersImplCopyWithImpl(
    _$CreatorViewersImpl _value,
    $Res Function(_$CreatorViewersImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatorViewers
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalViewers = null,
    Object? newViewers = null,
    Object? previousTotalViewers = null,
    Object? previousNewViewers = null,
    Object? breakdownAvailable = null,
    Object? activeHours = freezed,
    Object? activeDays = freezed,
  }) {
    return _then(
      _$CreatorViewersImpl(
        totalViewers: null == totalViewers
            ? _value.totalViewers
            : totalViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        newViewers: null == newViewers
            ? _value.newViewers
            : newViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        previousTotalViewers: null == previousTotalViewers
            ? _value.previousTotalViewers
            : previousTotalViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        previousNewViewers: null == previousNewViewers
            ? _value.previousNewViewers
            : previousNewViewers // ignore: cast_nullable_to_non_nullable
                  as int,
        breakdownAvailable: null == breakdownAvailable
            ? _value.breakdownAvailable
            : breakdownAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        activeHours: freezed == activeHours
            ? _value._activeHours
            : activeHours // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        activeDays: freezed == activeDays
            ? _value._activeDays
            : activeDays // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorViewersImpl implements _CreatorViewers {
  const _$CreatorViewersImpl({
    this.totalViewers = 0,
    this.newViewers = 0,
    this.previousTotalViewers = 0,
    this.previousNewViewers = 0,
    this.breakdownAvailable = false,
    final List<int>? activeHours,
    final List<int>? activeDays,
  }) : _activeHours = activeHours,
       _activeDays = activeDays;

  factory _$CreatorViewersImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorViewersImplFromJson(json);

  @override
  @JsonKey()
  final int totalViewers;
  @override
  @JsonKey()
  final int newViewers;
  @override
  @JsonKey()
  final int previousTotalViewers;
  @override
  @JsonKey()
  final int previousNewViewers;
  @override
  @JsonKey()
  final bool breakdownAvailable;

  /// Distinct viewers by hour, 24 entries from 00:00 (Vietnam time).
  final List<int>? _activeHours;

  /// Distinct viewers by hour, 24 entries from 00:00 (Vietnam time).
  @override
  List<int>? get activeHours {
    final value = _activeHours;
    if (value == null) return null;
    if (_activeHours is EqualUnmodifiableListView) return _activeHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Distinct viewers by weekday, 7 entries from Monday.
  final List<int>? _activeDays;

  /// Distinct viewers by weekday, 7 entries from Monday.
  @override
  List<int>? get activeDays {
    final value = _activeDays;
    if (value == null) return null;
    if (_activeDays is EqualUnmodifiableListView) return _activeDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CreatorViewers(totalViewers: $totalViewers, newViewers: $newViewers, previousTotalViewers: $previousTotalViewers, previousNewViewers: $previousNewViewers, breakdownAvailable: $breakdownAvailable, activeHours: $activeHours, activeDays: $activeDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorViewersImpl &&
            (identical(other.totalViewers, totalViewers) ||
                other.totalViewers == totalViewers) &&
            (identical(other.newViewers, newViewers) ||
                other.newViewers == newViewers) &&
            (identical(other.previousTotalViewers, previousTotalViewers) ||
                other.previousTotalViewers == previousTotalViewers) &&
            (identical(other.previousNewViewers, previousNewViewers) ||
                other.previousNewViewers == previousNewViewers) &&
            (identical(other.breakdownAvailable, breakdownAvailable) ||
                other.breakdownAvailable == breakdownAvailable) &&
            const DeepCollectionEquality().equals(
              other._activeHours,
              _activeHours,
            ) &&
            const DeepCollectionEquality().equals(
              other._activeDays,
              _activeDays,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalViewers,
    newViewers,
    previousTotalViewers,
    previousNewViewers,
    breakdownAvailable,
    const DeepCollectionEquality().hash(_activeHours),
    const DeepCollectionEquality().hash(_activeDays),
  );

  /// Create a copy of CreatorViewers
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorViewersImplCopyWith<_$CreatorViewersImpl> get copyWith =>
      __$$CreatorViewersImplCopyWithImpl<_$CreatorViewersImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorViewersImplToJson(this);
  }
}

abstract class _CreatorViewers implements CreatorViewers {
  const factory _CreatorViewers({
    final int totalViewers,
    final int newViewers,
    final int previousTotalViewers,
    final int previousNewViewers,
    final bool breakdownAvailable,
    final List<int>? activeHours,
    final List<int>? activeDays,
  }) = _$CreatorViewersImpl;

  factory _CreatorViewers.fromJson(Map<String, dynamic> json) =
      _$CreatorViewersImpl.fromJson;

  @override
  int get totalViewers;
  @override
  int get newViewers;
  @override
  int get previousTotalViewers;
  @override
  int get previousNewViewers;
  @override
  bool get breakdownAvailable;

  /// Distinct viewers by hour, 24 entries from 00:00 (Vietnam time).
  @override
  List<int>? get activeHours;

  /// Distinct viewers by weekday, 7 entries from Monday.
  @override
  List<int>? get activeDays;

  /// Create a copy of CreatorViewers
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorViewersImplCopyWith<_$CreatorViewersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$StudioPostQuery {
  List<String> get statuses => throw _privateConstructorUsedError;
  List<String> get visibilities => throw _privateConstructorUsedError;
  List<CountRange> get views => throw _privateConstructorUsedError;
  StudioPostSort get sort => throw _privateConstructorUsedError;
  bool get descending => throw _privateConstructorUsedError;
  String get q => throw _privateConstructorUsedError;

  /// Create a copy of StudioPostQuery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudioPostQueryCopyWith<StudioPostQuery> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudioPostQueryCopyWith<$Res> {
  factory $StudioPostQueryCopyWith(
    StudioPostQuery value,
    $Res Function(StudioPostQuery) then,
  ) = _$StudioPostQueryCopyWithImpl<$Res, StudioPostQuery>;
  @useResult
  $Res call({
    List<String> statuses,
    List<String> visibilities,
    List<CountRange> views,
    StudioPostSort sort,
    bool descending,
    String q,
  });
}

/// @nodoc
class _$StudioPostQueryCopyWithImpl<$Res, $Val extends StudioPostQuery>
    implements $StudioPostQueryCopyWith<$Res> {
  _$StudioPostQueryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudioPostQuery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statuses = null,
    Object? visibilities = null,
    Object? views = null,
    Object? sort = null,
    Object? descending = null,
    Object? q = null,
  }) {
    return _then(
      _value.copyWith(
            statuses: null == statuses
                ? _value.statuses
                : statuses // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            visibilities: null == visibilities
                ? _value.visibilities
                : visibilities // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as List<CountRange>,
            sort: null == sort
                ? _value.sort
                : sort // ignore: cast_nullable_to_non_nullable
                      as StudioPostSort,
            descending: null == descending
                ? _value.descending
                : descending // ignore: cast_nullable_to_non_nullable
                      as bool,
            q: null == q
                ? _value.q
                : q // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudioPostQueryImplCopyWith<$Res>
    implements $StudioPostQueryCopyWith<$Res> {
  factory _$$StudioPostQueryImplCopyWith(
    _$StudioPostQueryImpl value,
    $Res Function(_$StudioPostQueryImpl) then,
  ) = __$$StudioPostQueryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> statuses,
    List<String> visibilities,
    List<CountRange> views,
    StudioPostSort sort,
    bool descending,
    String q,
  });
}

/// @nodoc
class __$$StudioPostQueryImplCopyWithImpl<$Res>
    extends _$StudioPostQueryCopyWithImpl<$Res, _$StudioPostQueryImpl>
    implements _$$StudioPostQueryImplCopyWith<$Res> {
  __$$StudioPostQueryImplCopyWithImpl(
    _$StudioPostQueryImpl _value,
    $Res Function(_$StudioPostQueryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudioPostQuery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statuses = null,
    Object? visibilities = null,
    Object? views = null,
    Object? sort = null,
    Object? descending = null,
    Object? q = null,
  }) {
    return _then(
      _$StudioPostQueryImpl(
        statuses: null == statuses
            ? _value._statuses
            : statuses // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        visibilities: null == visibilities
            ? _value._visibilities
            : visibilities // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        views: null == views
            ? _value._views
            : views // ignore: cast_nullable_to_non_nullable
                  as List<CountRange>,
        sort: null == sort
            ? _value.sort
            : sort // ignore: cast_nullable_to_non_nullable
                  as StudioPostSort,
        descending: null == descending
            ? _value.descending
            : descending // ignore: cast_nullable_to_non_nullable
                  as bool,
        q: null == q
            ? _value.q
            : q // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$StudioPostQueryImpl extends _StudioPostQuery {
  const _$StudioPostQueryImpl({
    final List<String> statuses = const [],
    final List<String> visibilities = const [],
    final List<CountRange> views = const [],
    this.sort = StudioPostSort.newest,
    this.descending = true,
    this.q = '',
  }) : _statuses = statuses,
       _visibilities = visibilities,
       _views = views,
       super._();

  final List<String> _statuses;
  @override
  @JsonKey()
  List<String> get statuses {
    if (_statuses is EqualUnmodifiableListView) return _statuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statuses);
  }

  final List<String> _visibilities;
  @override
  @JsonKey()
  List<String> get visibilities {
    if (_visibilities is EqualUnmodifiableListView) return _visibilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_visibilities);
  }

  final List<CountRange> _views;
  @override
  @JsonKey()
  List<CountRange> get views {
    if (_views is EqualUnmodifiableListView) return _views;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_views);
  }

  @override
  @JsonKey()
  final StudioPostSort sort;
  @override
  @JsonKey()
  final bool descending;
  @override
  @JsonKey()
  final String q;

  @override
  String toString() {
    return 'StudioPostQuery(statuses: $statuses, visibilities: $visibilities, views: $views, sort: $sort, descending: $descending, q: $q)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudioPostQueryImpl &&
            const DeepCollectionEquality().equals(other._statuses, _statuses) &&
            const DeepCollectionEquality().equals(
              other._visibilities,
              _visibilities,
            ) &&
            const DeepCollectionEquality().equals(other._views, _views) &&
            (identical(other.sort, sort) || other.sort == sort) &&
            (identical(other.descending, descending) ||
                other.descending == descending) &&
            (identical(other.q, q) || other.q == q));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_statuses),
    const DeepCollectionEquality().hash(_visibilities),
    const DeepCollectionEquality().hash(_views),
    sort,
    descending,
    q,
  );

  /// Create a copy of StudioPostQuery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudioPostQueryImplCopyWith<_$StudioPostQueryImpl> get copyWith =>
      __$$StudioPostQueryImplCopyWithImpl<_$StudioPostQueryImpl>(
        this,
        _$identity,
      );
}

abstract class _StudioPostQuery extends StudioPostQuery {
  const factory _StudioPostQuery({
    final List<String> statuses,
    final List<String> visibilities,
    final List<CountRange> views,
    final StudioPostSort sort,
    final bool descending,
    final String q,
  }) = _$StudioPostQueryImpl;
  const _StudioPostQuery._() : super._();

  @override
  List<String> get statuses;
  @override
  List<String> get visibilities;
  @override
  List<CountRange> get views;
  @override
  StudioPostSort get sort;
  @override
  bool get descending;
  @override
  String get q;

  /// Create a copy of StudioPostQuery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudioPostQueryImplCopyWith<_$StudioPostQueryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$InboxQuery {
  /// Only this video's comments. Also unlocks [sort] and [replied].
  String? get videoId => throw _privateConstructorUsedError;

  /// Only comments held back for the owner to approve.
  bool get heldOnly => throw _privateConstructorUsedError;
  String get q => throw _privateConstructorUsedError;
  InboxSort get sort => throw _privateConstructorUsedError;

  /// true: only threads the owner answered; false: only unanswered ones.
  bool? get replied => throw _privateConstructorUsedError;

  /// Create a copy of InboxQuery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InboxQueryCopyWith<InboxQuery> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InboxQueryCopyWith<$Res> {
  factory $InboxQueryCopyWith(
    InboxQuery value,
    $Res Function(InboxQuery) then,
  ) = _$InboxQueryCopyWithImpl<$Res, InboxQuery>;
  @useResult
  $Res call({
    String? videoId,
    bool heldOnly,
    String q,
    InboxSort sort,
    bool? replied,
  });
}

/// @nodoc
class _$InboxQueryCopyWithImpl<$Res, $Val extends InboxQuery>
    implements $InboxQueryCopyWith<$Res> {
  _$InboxQueryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InboxQuery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = freezed,
    Object? heldOnly = null,
    Object? q = null,
    Object? sort = null,
    Object? replied = freezed,
  }) {
    return _then(
      _value.copyWith(
            videoId: freezed == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String?,
            heldOnly: null == heldOnly
                ? _value.heldOnly
                : heldOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            q: null == q
                ? _value.q
                : q // ignore: cast_nullable_to_non_nullable
                      as String,
            sort: null == sort
                ? _value.sort
                : sort // ignore: cast_nullable_to_non_nullable
                      as InboxSort,
            replied: freezed == replied
                ? _value.replied
                : replied // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InboxQueryImplCopyWith<$Res>
    implements $InboxQueryCopyWith<$Res> {
  factory _$$InboxQueryImplCopyWith(
    _$InboxQueryImpl value,
    $Res Function(_$InboxQueryImpl) then,
  ) = __$$InboxQueryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? videoId,
    bool heldOnly,
    String q,
    InboxSort sort,
    bool? replied,
  });
}

/// @nodoc
class __$$InboxQueryImplCopyWithImpl<$Res>
    extends _$InboxQueryCopyWithImpl<$Res, _$InboxQueryImpl>
    implements _$$InboxQueryImplCopyWith<$Res> {
  __$$InboxQueryImplCopyWithImpl(
    _$InboxQueryImpl _value,
    $Res Function(_$InboxQueryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InboxQuery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = freezed,
    Object? heldOnly = null,
    Object? q = null,
    Object? sort = null,
    Object? replied = freezed,
  }) {
    return _then(
      _$InboxQueryImpl(
        videoId: freezed == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String?,
        heldOnly: null == heldOnly
            ? _value.heldOnly
            : heldOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        q: null == q
            ? _value.q
            : q // ignore: cast_nullable_to_non_nullable
                  as String,
        sort: null == sort
            ? _value.sort
            : sort // ignore: cast_nullable_to_non_nullable
                  as InboxSort,
        replied: freezed == replied
            ? _value.replied
            : replied // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc

class _$InboxQueryImpl implements _InboxQuery {
  const _$InboxQueryImpl({
    this.videoId,
    this.heldOnly = false,
    this.q = '',
    this.sort = InboxSort.newest,
    this.replied,
  });

  /// Only this video's comments. Also unlocks [sort] and [replied].
  @override
  final String? videoId;

  /// Only comments held back for the owner to approve.
  @override
  @JsonKey()
  final bool heldOnly;
  @override
  @JsonKey()
  final String q;
  @override
  @JsonKey()
  final InboxSort sort;

  /// true: only threads the owner answered; false: only unanswered ones.
  @override
  final bool? replied;

  @override
  String toString() {
    return 'InboxQuery(videoId: $videoId, heldOnly: $heldOnly, q: $q, sort: $sort, replied: $replied)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InboxQueryImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.heldOnly, heldOnly) ||
                other.heldOnly == heldOnly) &&
            (identical(other.q, q) || other.q == q) &&
            (identical(other.sort, sort) || other.sort == sort) &&
            (identical(other.replied, replied) || other.replied == replied));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, videoId, heldOnly, q, sort, replied);

  /// Create a copy of InboxQuery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InboxQueryImplCopyWith<_$InboxQueryImpl> get copyWith =>
      __$$InboxQueryImplCopyWithImpl<_$InboxQueryImpl>(this, _$identity);
}

abstract class _InboxQuery implements InboxQuery {
  const factory _InboxQuery({
    final String? videoId,
    final bool heldOnly,
    final String q,
    final InboxSort sort,
    final bool? replied,
  }) = _$InboxQueryImpl;

  /// Only this video's comments. Also unlocks [sort] and [replied].
  @override
  String? get videoId;

  /// Only comments held back for the owner to approve.
  @override
  bool get heldOnly;
  @override
  String get q;
  @override
  InboxSort get sort;

  /// true: only threads the owner answered; false: only unanswered ones.
  @override
  bool? get replied;

  /// Create a copy of InboxQuery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InboxQueryImplCopyWith<_$InboxQueryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

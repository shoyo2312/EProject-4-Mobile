// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  @JsonKey(unknownEnumValue: SettingsAudience.unknown)
  SettingsAudience get commentAudience => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: SettingsAudience.unknown)
  SettingsAudience get dmAudience => throw _privateConstructorUsedError;

  /// 10–480, the same limit every day. Null when off or set per day.
  int? get screenTimeLimitMinutes => throw _privateConstructorUsedError;

  /// Seven limits of 10–480, Monday first. Null unless set per day.
  List<int>? get screenTimeLimitsByDay => throw _privateConstructorUsedError;

  /// The passcode itself is write-only; this says whether one is set.
  bool get hasScreenTimePasscode => throw _privateConstructorUsedError;

  /// "HH:mm" wall-clock, or null when sleep hours are off.
  String? get sleepHoursStart => throw _privateConstructorUsedError;

  /// Always the start plus eight hours, worked out by the server.
  String? get sleepHoursEnd => throw _privateConstructorUsedError;
  bool get weeklyScreenTimeDigest => throw _privateConstructorUsedError;

  /// On, only approved followers see the videos; turning it off approves
  /// every request still waiting.
  bool get privateAccount => throw _privateConstructorUsedError;
  String? get timeZone => throw _privateConstructorUsedError;

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
    UserSettings value,
    $Res Function(UserSettings) then,
  ) = _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call({
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    SettingsAudience commentAudience,
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    SettingsAudience dmAudience,
    int? screenTimeLimitMinutes,
    List<int>? screenTimeLimitsByDay,
    bool hasScreenTimePasscode,
    String? sleepHoursStart,
    String? sleepHoursEnd,
    bool weeklyScreenTimeDigest,
    bool privateAccount,
    String? timeZone,
  });
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commentAudience = null,
    Object? dmAudience = null,
    Object? screenTimeLimitMinutes = freezed,
    Object? screenTimeLimitsByDay = freezed,
    Object? hasScreenTimePasscode = null,
    Object? sleepHoursStart = freezed,
    Object? sleepHoursEnd = freezed,
    Object? weeklyScreenTimeDigest = null,
    Object? privateAccount = null,
    Object? timeZone = freezed,
  }) {
    return _then(
      _value.copyWith(
            commentAudience: null == commentAudience
                ? _value.commentAudience
                : commentAudience // ignore: cast_nullable_to_non_nullable
                      as SettingsAudience,
            dmAudience: null == dmAudience
                ? _value.dmAudience
                : dmAudience // ignore: cast_nullable_to_non_nullable
                      as SettingsAudience,
            screenTimeLimitMinutes: freezed == screenTimeLimitMinutes
                ? _value.screenTimeLimitMinutes
                : screenTimeLimitMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            screenTimeLimitsByDay: freezed == screenTimeLimitsByDay
                ? _value.screenTimeLimitsByDay
                : screenTimeLimitsByDay // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
            hasScreenTimePasscode: null == hasScreenTimePasscode
                ? _value.hasScreenTimePasscode
                : hasScreenTimePasscode // ignore: cast_nullable_to_non_nullable
                      as bool,
            sleepHoursStart: freezed == sleepHoursStart
                ? _value.sleepHoursStart
                : sleepHoursStart // ignore: cast_nullable_to_non_nullable
                      as String?,
            sleepHoursEnd: freezed == sleepHoursEnd
                ? _value.sleepHoursEnd
                : sleepHoursEnd // ignore: cast_nullable_to_non_nullable
                      as String?,
            weeklyScreenTimeDigest: null == weeklyScreenTimeDigest
                ? _value.weeklyScreenTimeDigest
                : weeklyScreenTimeDigest // ignore: cast_nullable_to_non_nullable
                      as bool,
            privateAccount: null == privateAccount
                ? _value.privateAccount
                : privateAccount // ignore: cast_nullable_to_non_nullable
                      as bool,
            timeZone: freezed == timeZone
                ? _value.timeZone
                : timeZone // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
    _$UserSettingsImpl value,
    $Res Function(_$UserSettingsImpl) then,
  ) = __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    SettingsAudience commentAudience,
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    SettingsAudience dmAudience,
    int? screenTimeLimitMinutes,
    List<int>? screenTimeLimitsByDay,
    bool hasScreenTimePasscode,
    String? sleepHoursStart,
    String? sleepHoursEnd,
    bool weeklyScreenTimeDigest,
    bool privateAccount,
    String? timeZone,
  });
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
    _$UserSettingsImpl _value,
    $Res Function(_$UserSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commentAudience = null,
    Object? dmAudience = null,
    Object? screenTimeLimitMinutes = freezed,
    Object? screenTimeLimitsByDay = freezed,
    Object? hasScreenTimePasscode = null,
    Object? sleepHoursStart = freezed,
    Object? sleepHoursEnd = freezed,
    Object? weeklyScreenTimeDigest = null,
    Object? privateAccount = null,
    Object? timeZone = freezed,
  }) {
    return _then(
      _$UserSettingsImpl(
        commentAudience: null == commentAudience
            ? _value.commentAudience
            : commentAudience // ignore: cast_nullable_to_non_nullable
                  as SettingsAudience,
        dmAudience: null == dmAudience
            ? _value.dmAudience
            : dmAudience // ignore: cast_nullable_to_non_nullable
                  as SettingsAudience,
        screenTimeLimitMinutes: freezed == screenTimeLimitMinutes
            ? _value.screenTimeLimitMinutes
            : screenTimeLimitMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        screenTimeLimitsByDay: freezed == screenTimeLimitsByDay
            ? _value._screenTimeLimitsByDay
            : screenTimeLimitsByDay // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
        hasScreenTimePasscode: null == hasScreenTimePasscode
            ? _value.hasScreenTimePasscode
            : hasScreenTimePasscode // ignore: cast_nullable_to_non_nullable
                  as bool,
        sleepHoursStart: freezed == sleepHoursStart
            ? _value.sleepHoursStart
            : sleepHoursStart // ignore: cast_nullable_to_non_nullable
                  as String?,
        sleepHoursEnd: freezed == sleepHoursEnd
            ? _value.sleepHoursEnd
            : sleepHoursEnd // ignore: cast_nullable_to_non_nullable
                  as String?,
        weeklyScreenTimeDigest: null == weeklyScreenTimeDigest
            ? _value.weeklyScreenTimeDigest
            : weeklyScreenTimeDigest // ignore: cast_nullable_to_non_nullable
                  as bool,
        privateAccount: null == privateAccount
            ? _value.privateAccount
            : privateAccount // ignore: cast_nullable_to_non_nullable
                  as bool,
        timeZone: freezed == timeZone
            ? _value.timeZone
            : timeZone // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl({
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    this.commentAudience = SettingsAudience.everyone,
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    this.dmAudience = SettingsAudience.everyone,
    this.screenTimeLimitMinutes,
    final List<int>? screenTimeLimitsByDay,
    this.hasScreenTimePasscode = false,
    this.sleepHoursStart,
    this.sleepHoursEnd,
    this.weeklyScreenTimeDigest = true,
    this.privateAccount = false,
    this.timeZone,
  }) : _screenTimeLimitsByDay = screenTimeLimitsByDay;

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey(unknownEnumValue: SettingsAudience.unknown)
  final SettingsAudience commentAudience;
  @override
  @JsonKey(unknownEnumValue: SettingsAudience.unknown)
  final SettingsAudience dmAudience;

  /// 10–480, the same limit every day. Null when off or set per day.
  @override
  final int? screenTimeLimitMinutes;

  /// Seven limits of 10–480, Monday first. Null unless set per day.
  final List<int>? _screenTimeLimitsByDay;

  /// Seven limits of 10–480, Monday first. Null unless set per day.
  @override
  List<int>? get screenTimeLimitsByDay {
    final value = _screenTimeLimitsByDay;
    if (value == null) return null;
    if (_screenTimeLimitsByDay is EqualUnmodifiableListView)
      return _screenTimeLimitsByDay;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// The passcode itself is write-only; this says whether one is set.
  @override
  @JsonKey()
  final bool hasScreenTimePasscode;

  /// "HH:mm" wall-clock, or null when sleep hours are off.
  @override
  final String? sleepHoursStart;

  /// Always the start plus eight hours, worked out by the server.
  @override
  final String? sleepHoursEnd;
  @override
  @JsonKey()
  final bool weeklyScreenTimeDigest;

  /// On, only approved followers see the videos; turning it off approves
  /// every request still waiting.
  @override
  @JsonKey()
  final bool privateAccount;
  @override
  final String? timeZone;

  @override
  String toString() {
    return 'UserSettings(commentAudience: $commentAudience, dmAudience: $dmAudience, screenTimeLimitMinutes: $screenTimeLimitMinutes, screenTimeLimitsByDay: $screenTimeLimitsByDay, hasScreenTimePasscode: $hasScreenTimePasscode, sleepHoursStart: $sleepHoursStart, sleepHoursEnd: $sleepHoursEnd, weeklyScreenTimeDigest: $weeklyScreenTimeDigest, privateAccount: $privateAccount, timeZone: $timeZone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.commentAudience, commentAudience) ||
                other.commentAudience == commentAudience) &&
            (identical(other.dmAudience, dmAudience) ||
                other.dmAudience == dmAudience) &&
            (identical(other.screenTimeLimitMinutes, screenTimeLimitMinutes) ||
                other.screenTimeLimitMinutes == screenTimeLimitMinutes) &&
            const DeepCollectionEquality().equals(
              other._screenTimeLimitsByDay,
              _screenTimeLimitsByDay,
            ) &&
            (identical(other.hasScreenTimePasscode, hasScreenTimePasscode) ||
                other.hasScreenTimePasscode == hasScreenTimePasscode) &&
            (identical(other.sleepHoursStart, sleepHoursStart) ||
                other.sleepHoursStart == sleepHoursStart) &&
            (identical(other.sleepHoursEnd, sleepHoursEnd) ||
                other.sleepHoursEnd == sleepHoursEnd) &&
            (identical(other.weeklyScreenTimeDigest, weeklyScreenTimeDigest) ||
                other.weeklyScreenTimeDigest == weeklyScreenTimeDigest) &&
            (identical(other.privateAccount, privateAccount) ||
                other.privateAccount == privateAccount) &&
            (identical(other.timeZone, timeZone) ||
                other.timeZone == timeZone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    commentAudience,
    dmAudience,
    screenTimeLimitMinutes,
    const DeepCollectionEquality().hash(_screenTimeLimitsByDay),
    hasScreenTimePasscode,
    sleepHoursStart,
    sleepHoursEnd,
    weeklyScreenTimeDigest,
    privateAccount,
    timeZone,
  );

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(this);
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings({
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    final SettingsAudience commentAudience,
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    final SettingsAudience dmAudience,
    final int? screenTimeLimitMinutes,
    final List<int>? screenTimeLimitsByDay,
    final bool hasScreenTimePasscode,
    final String? sleepHoursStart,
    final String? sleepHoursEnd,
    final bool weeklyScreenTimeDigest,
    final bool privateAccount,
    final String? timeZone,
  }) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  @JsonKey(unknownEnumValue: SettingsAudience.unknown)
  SettingsAudience get commentAudience;
  @override
  @JsonKey(unknownEnumValue: SettingsAudience.unknown)
  SettingsAudience get dmAudience;

  /// 10–480, the same limit every day. Null when off or set per day.
  @override
  int? get screenTimeLimitMinutes;

  /// Seven limits of 10–480, Monday first. Null unless set per day.
  @override
  List<int>? get screenTimeLimitsByDay;

  /// The passcode itself is write-only; this says whether one is set.
  @override
  bool get hasScreenTimePasscode;

  /// "HH:mm" wall-clock, or null when sleep hours are off.
  @override
  String? get sleepHoursStart;

  /// Always the start plus eight hours, worked out by the server.
  @override
  String? get sleepHoursEnd;
  @override
  bool get weeklyScreenTimeDigest;

  /// On, only approved followers see the videos; turning it off approves
  /// every request still waiting.
  @override
  bool get privateAccount;
  @override
  String? get timeZone;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

KeywordFilter _$KeywordFilterFromJson(Map<String, dynamic> json) {
  return _KeywordFilter.fromJson(json);
}

/// @nodoc
mixin _$KeywordFilter {
  @JsonKey(fromJson: _idFromJson)
  String get id => throw _privateConstructorUsedError;
  String get keyword => throw _privateConstructorUsedError;
  bool get forYou => throw _privateConstructorUsedError;
  bool get following => throw _privateConstructorUsedError;
  bool get friends => throw _privateConstructorUsedError;

  /// Serializes this KeywordFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KeywordFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KeywordFilterCopyWith<KeywordFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KeywordFilterCopyWith<$Res> {
  factory $KeywordFilterCopyWith(
    KeywordFilter value,
    $Res Function(KeywordFilter) then,
  ) = _$KeywordFilterCopyWithImpl<$Res, KeywordFilter>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String id,
    String keyword,
    bool forYou,
    bool following,
    bool friends,
  });
}

/// @nodoc
class _$KeywordFilterCopyWithImpl<$Res, $Val extends KeywordFilter>
    implements $KeywordFilterCopyWith<$Res> {
  _$KeywordFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KeywordFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? keyword = null,
    Object? forYou = null,
    Object? following = null,
    Object? friends = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            keyword: null == keyword
                ? _value.keyword
                : keyword // ignore: cast_nullable_to_non_nullable
                      as String,
            forYou: null == forYou
                ? _value.forYou
                : forYou // ignore: cast_nullable_to_non_nullable
                      as bool,
            following: null == following
                ? _value.following
                : following // ignore: cast_nullable_to_non_nullable
                      as bool,
            friends: null == friends
                ? _value.friends
                : friends // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KeywordFilterImplCopyWith<$Res>
    implements $KeywordFilterCopyWith<$Res> {
  factory _$$KeywordFilterImplCopyWith(
    _$KeywordFilterImpl value,
    $Res Function(_$KeywordFilterImpl) then,
  ) = __$$KeywordFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String id,
    String keyword,
    bool forYou,
    bool following,
    bool friends,
  });
}

/// @nodoc
class __$$KeywordFilterImplCopyWithImpl<$Res>
    extends _$KeywordFilterCopyWithImpl<$Res, _$KeywordFilterImpl>
    implements _$$KeywordFilterImplCopyWith<$Res> {
  __$$KeywordFilterImplCopyWithImpl(
    _$KeywordFilterImpl _value,
    $Res Function(_$KeywordFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KeywordFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? keyword = null,
    Object? forYou = null,
    Object? following = null,
    Object? friends = null,
  }) {
    return _then(
      _$KeywordFilterImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        keyword: null == keyword
            ? _value.keyword
            : keyword // ignore: cast_nullable_to_non_nullable
                  as String,
        forYou: null == forYou
            ? _value.forYou
            : forYou // ignore: cast_nullable_to_non_nullable
                  as bool,
        following: null == following
            ? _value.following
            : following // ignore: cast_nullable_to_non_nullable
                  as bool,
        friends: null == friends
            ? _value.friends
            : friends // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KeywordFilterImpl implements _KeywordFilter {
  const _$KeywordFilterImpl({
    @JsonKey(fromJson: _idFromJson) required this.id,
    required this.keyword,
    this.forYou = true,
    this.following = true,
    this.friends = true,
  });

  factory _$KeywordFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$KeywordFilterImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String id;
  @override
  final String keyword;
  @override
  @JsonKey()
  final bool forYou;
  @override
  @JsonKey()
  final bool following;
  @override
  @JsonKey()
  final bool friends;

  @override
  String toString() {
    return 'KeywordFilter(id: $id, keyword: $keyword, forYou: $forYou, following: $following, friends: $friends)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeywordFilterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.forYou, forYou) || other.forYou == forYou) &&
            (identical(other.following, following) ||
                other.following == following) &&
            (identical(other.friends, friends) || other.friends == friends));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, keyword, forYou, following, friends);

  /// Create a copy of KeywordFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KeywordFilterImplCopyWith<_$KeywordFilterImpl> get copyWith =>
      __$$KeywordFilterImplCopyWithImpl<_$KeywordFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KeywordFilterImplToJson(this);
  }
}

abstract class _KeywordFilter implements KeywordFilter {
  const factory _KeywordFilter({
    @JsonKey(fromJson: _idFromJson) required final String id,
    required final String keyword,
    final bool forYou,
    final bool following,
    final bool friends,
  }) = _$KeywordFilterImpl;

  factory _KeywordFilter.fromJson(Map<String, dynamic> json) =
      _$KeywordFilterImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get id;
  @override
  String get keyword;
  @override
  bool get forYou;
  @override
  bool get following;
  @override
  bool get friends;

  /// Create a copy of KeywordFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KeywordFilterImplCopyWith<_$KeywordFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScreenTimeDay _$ScreenTimeDayFromJson(Map<String, dynamic> json) {
  return _ScreenTimeDay.fromJson(json);
}

/// @nodoc
mixin _$ScreenTimeDay {
  /// "YYYY-MM-DD".
  String get date => throw _privateConstructorUsedError;
  int get daySeconds => throw _privateConstructorUsedError;
  int get nightSeconds => throw _privateConstructorUsedError;

  /// Serializes this ScreenTimeDay to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScreenTimeDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScreenTimeDayCopyWith<ScreenTimeDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScreenTimeDayCopyWith<$Res> {
  factory $ScreenTimeDayCopyWith(
    ScreenTimeDay value,
    $Res Function(ScreenTimeDay) then,
  ) = _$ScreenTimeDayCopyWithImpl<$Res, ScreenTimeDay>;
  @useResult
  $Res call({String date, int daySeconds, int nightSeconds});
}

/// @nodoc
class _$ScreenTimeDayCopyWithImpl<$Res, $Val extends ScreenTimeDay>
    implements $ScreenTimeDayCopyWith<$Res> {
  _$ScreenTimeDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScreenTimeDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? daySeconds = null,
    Object? nightSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            daySeconds: null == daySeconds
                ? _value.daySeconds
                : daySeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            nightSeconds: null == nightSeconds
                ? _value.nightSeconds
                : nightSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScreenTimeDayImplCopyWith<$Res>
    implements $ScreenTimeDayCopyWith<$Res> {
  factory _$$ScreenTimeDayImplCopyWith(
    _$ScreenTimeDayImpl value,
    $Res Function(_$ScreenTimeDayImpl) then,
  ) = __$$ScreenTimeDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, int daySeconds, int nightSeconds});
}

/// @nodoc
class __$$ScreenTimeDayImplCopyWithImpl<$Res>
    extends _$ScreenTimeDayCopyWithImpl<$Res, _$ScreenTimeDayImpl>
    implements _$$ScreenTimeDayImplCopyWith<$Res> {
  __$$ScreenTimeDayImplCopyWithImpl(
    _$ScreenTimeDayImpl _value,
    $Res Function(_$ScreenTimeDayImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScreenTimeDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? daySeconds = null,
    Object? nightSeconds = null,
  }) {
    return _then(
      _$ScreenTimeDayImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        daySeconds: null == daySeconds
            ? _value.daySeconds
            : daySeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        nightSeconds: null == nightSeconds
            ? _value.nightSeconds
            : nightSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScreenTimeDayImpl implements _ScreenTimeDay {
  const _$ScreenTimeDayImpl({
    required this.date,
    this.daySeconds = 0,
    this.nightSeconds = 0,
  });

  factory _$ScreenTimeDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScreenTimeDayImplFromJson(json);

  /// "YYYY-MM-DD".
  @override
  final String date;
  @override
  @JsonKey()
  final int daySeconds;
  @override
  @JsonKey()
  final int nightSeconds;

  @override
  String toString() {
    return 'ScreenTimeDay(date: $date, daySeconds: $daySeconds, nightSeconds: $nightSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScreenTimeDayImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.daySeconds, daySeconds) ||
                other.daySeconds == daySeconds) &&
            (identical(other.nightSeconds, nightSeconds) ||
                other.nightSeconds == nightSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, daySeconds, nightSeconds);

  /// Create a copy of ScreenTimeDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScreenTimeDayImplCopyWith<_$ScreenTimeDayImpl> get copyWith =>
      __$$ScreenTimeDayImplCopyWithImpl<_$ScreenTimeDayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScreenTimeDayImplToJson(this);
  }
}

abstract class _ScreenTimeDay implements ScreenTimeDay {
  const factory _ScreenTimeDay({
    required final String date,
    final int daySeconds,
    final int nightSeconds,
  }) = _$ScreenTimeDayImpl;

  factory _ScreenTimeDay.fromJson(Map<String, dynamic> json) =
      _$ScreenTimeDayImpl.fromJson;

  /// "YYYY-MM-DD".
  @override
  String get date;
  @override
  int get daySeconds;
  @override
  int get nightSeconds;

  /// Create a copy of ScreenTimeDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScreenTimeDayImplCopyWith<_$ScreenTimeDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScreenTimeWeek _$ScreenTimeWeekFromJson(Map<String, dynamic> json) {
  return _ScreenTimeWeek.fromJson(json);
}

/// @nodoc
mixin _$ScreenTimeWeek {
  String get weekStart => throw _privateConstructorUsedError;
  List<ScreenTimeDay> get days => throw _privateConstructorUsedError;

  /// Serializes this ScreenTimeWeek to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScreenTimeWeek
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScreenTimeWeekCopyWith<ScreenTimeWeek> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScreenTimeWeekCopyWith<$Res> {
  factory $ScreenTimeWeekCopyWith(
    ScreenTimeWeek value,
    $Res Function(ScreenTimeWeek) then,
  ) = _$ScreenTimeWeekCopyWithImpl<$Res, ScreenTimeWeek>;
  @useResult
  $Res call({String weekStart, List<ScreenTimeDay> days});
}

/// @nodoc
class _$ScreenTimeWeekCopyWithImpl<$Res, $Val extends ScreenTimeWeek>
    implements $ScreenTimeWeekCopyWith<$Res> {
  _$ScreenTimeWeekCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScreenTimeWeek
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? weekStart = null, Object? days = null}) {
    return _then(
      _value.copyWith(
            weekStart: null == weekStart
                ? _value.weekStart
                : weekStart // ignore: cast_nullable_to_non_nullable
                      as String,
            days: null == days
                ? _value.days
                : days // ignore: cast_nullable_to_non_nullable
                      as List<ScreenTimeDay>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScreenTimeWeekImplCopyWith<$Res>
    implements $ScreenTimeWeekCopyWith<$Res> {
  factory _$$ScreenTimeWeekImplCopyWith(
    _$ScreenTimeWeekImpl value,
    $Res Function(_$ScreenTimeWeekImpl) then,
  ) = __$$ScreenTimeWeekImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String weekStart, List<ScreenTimeDay> days});
}

/// @nodoc
class __$$ScreenTimeWeekImplCopyWithImpl<$Res>
    extends _$ScreenTimeWeekCopyWithImpl<$Res, _$ScreenTimeWeekImpl>
    implements _$$ScreenTimeWeekImplCopyWith<$Res> {
  __$$ScreenTimeWeekImplCopyWithImpl(
    _$ScreenTimeWeekImpl _value,
    $Res Function(_$ScreenTimeWeekImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScreenTimeWeek
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? weekStart = null, Object? days = null}) {
    return _then(
      _$ScreenTimeWeekImpl(
        weekStart: null == weekStart
            ? _value.weekStart
            : weekStart // ignore: cast_nullable_to_non_nullable
                  as String,
        days: null == days
            ? _value._days
            : days // ignore: cast_nullable_to_non_nullable
                  as List<ScreenTimeDay>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScreenTimeWeekImpl implements _ScreenTimeWeek {
  const _$ScreenTimeWeekImpl({
    required this.weekStart,
    final List<ScreenTimeDay> days = const <ScreenTimeDay>[],
  }) : _days = days;

  factory _$ScreenTimeWeekImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScreenTimeWeekImplFromJson(json);

  @override
  final String weekStart;
  final List<ScreenTimeDay> _days;
  @override
  @JsonKey()
  List<ScreenTimeDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'ScreenTimeWeek(weekStart: $weekStart, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScreenTimeWeekImpl &&
            (identical(other.weekStart, weekStart) ||
                other.weekStart == weekStart) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    weekStart,
    const DeepCollectionEquality().hash(_days),
  );

  /// Create a copy of ScreenTimeWeek
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScreenTimeWeekImplCopyWith<_$ScreenTimeWeekImpl> get copyWith =>
      __$$ScreenTimeWeekImplCopyWithImpl<_$ScreenTimeWeekImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ScreenTimeWeekImplToJson(this);
  }
}

abstract class _ScreenTimeWeek implements ScreenTimeWeek {
  const factory _ScreenTimeWeek({
    required final String weekStart,
    final List<ScreenTimeDay> days,
  }) = _$ScreenTimeWeekImpl;

  factory _ScreenTimeWeek.fromJson(Map<String, dynamic> json) =
      _$ScreenTimeWeekImpl.fromJson;

  @override
  String get weekStart;
  @override
  List<ScreenTimeDay> get days;

  /// Create a copy of ScreenTimeWeek
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScreenTimeWeekImplCopyWith<_$ScreenTimeWeekImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

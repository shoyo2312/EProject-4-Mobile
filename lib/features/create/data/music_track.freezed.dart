// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MusicTrack _$MusicTrackFromJson(Map<String, dynamic> json) {
  return _MusicTrack.fromJson(json);
}

/// @nodoc
mixin _$MusicTrack {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;

  /// A stream to preview with. Short-lived: play it now, never keep it.
  String get audioUrl => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  /// The Creative Commons licence; shown with the credit.
  String? get licenseUrl => throw _privateConstructorUsedError;
  String? get shareUrl => throw _privateConstructorUsedError;

  /// Serializes this MusicTrack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MusicTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MusicTrackCopyWith<MusicTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicTrackCopyWith<$Res> {
  factory $MusicTrackCopyWith(
    MusicTrack value,
    $Res Function(MusicTrack) then,
  ) = _$MusicTrackCopyWithImpl<$Res, MusicTrack>;
  @useResult
  $Res call({
    String id,
    String title,
    String artist,
    int durationSeconds,
    String audioUrl,
    String? imageUrl,
    String? licenseUrl,
    String? shareUrl,
  });
}

/// @nodoc
class _$MusicTrackCopyWithImpl<$Res, $Val extends MusicTrack>
    implements $MusicTrackCopyWith<$Res> {
  _$MusicTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MusicTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? durationSeconds = null,
    Object? audioUrl = null,
    Object? imageUrl = freezed,
    Object? licenseUrl = freezed,
    Object? shareUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            artist: null == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            audioUrl: null == audioUrl
                ? _value.audioUrl
                : audioUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            licenseUrl: freezed == licenseUrl
                ? _value.licenseUrl
                : licenseUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            shareUrl: freezed == shareUrl
                ? _value.shareUrl
                : shareUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MusicTrackImplCopyWith<$Res>
    implements $MusicTrackCopyWith<$Res> {
  factory _$$MusicTrackImplCopyWith(
    _$MusicTrackImpl value,
    $Res Function(_$MusicTrackImpl) then,
  ) = __$$MusicTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String artist,
    int durationSeconds,
    String audioUrl,
    String? imageUrl,
    String? licenseUrl,
    String? shareUrl,
  });
}

/// @nodoc
class __$$MusicTrackImplCopyWithImpl<$Res>
    extends _$MusicTrackCopyWithImpl<$Res, _$MusicTrackImpl>
    implements _$$MusicTrackImplCopyWith<$Res> {
  __$$MusicTrackImplCopyWithImpl(
    _$MusicTrackImpl _value,
    $Res Function(_$MusicTrackImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? durationSeconds = null,
    Object? audioUrl = null,
    Object? imageUrl = freezed,
    Object? licenseUrl = freezed,
    Object? shareUrl = freezed,
  }) {
    return _then(
      _$MusicTrackImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        artist: null == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        audioUrl: null == audioUrl
            ? _value.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        licenseUrl: freezed == licenseUrl
            ? _value.licenseUrl
            : licenseUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        shareUrl: freezed == shareUrl
            ? _value.shareUrl
            : shareUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MusicTrackImpl implements _MusicTrack {
  const _$MusicTrackImpl({
    required this.id,
    required this.title,
    required this.artist,
    this.durationSeconds = 0,
    required this.audioUrl,
    this.imageUrl,
    this.licenseUrl,
    this.shareUrl,
  });

  factory _$MusicTrackImpl.fromJson(Map<String, dynamic> json) =>
      _$$MusicTrackImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String artist;
  @override
  @JsonKey()
  final int durationSeconds;

  /// A stream to preview with. Short-lived: play it now, never keep it.
  @override
  final String audioUrl;
  @override
  final String? imageUrl;

  /// The Creative Commons licence; shown with the credit.
  @override
  final String? licenseUrl;
  @override
  final String? shareUrl;

  @override
  String toString() {
    return 'MusicTrack(id: $id, title: $title, artist: $artist, durationSeconds: $durationSeconds, audioUrl: $audioUrl, imageUrl: $imageUrl, licenseUrl: $licenseUrl, shareUrl: $shareUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MusicTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.licenseUrl, licenseUrl) ||
                other.licenseUrl == licenseUrl) &&
            (identical(other.shareUrl, shareUrl) ||
                other.shareUrl == shareUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    artist,
    durationSeconds,
    audioUrl,
    imageUrl,
    licenseUrl,
    shareUrl,
  );

  /// Create a copy of MusicTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MusicTrackImplCopyWith<_$MusicTrackImpl> get copyWith =>
      __$$MusicTrackImplCopyWithImpl<_$MusicTrackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MusicTrackImplToJson(this);
  }
}

abstract class _MusicTrack implements MusicTrack {
  const factory _MusicTrack({
    required final String id,
    required final String title,
    required final String artist,
    final int durationSeconds,
    required final String audioUrl,
    final String? imageUrl,
    final String? licenseUrl,
    final String? shareUrl,
  }) = _$MusicTrackImpl;

  factory _MusicTrack.fromJson(Map<String, dynamic> json) =
      _$MusicTrackImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get artist;
  @override
  int get durationSeconds;

  /// A stream to preview with. Short-lived: play it now, never keep it.
  @override
  String get audioUrl;
  @override
  String? get imageUrl;

  /// The Creative Commons licence; shown with the credit.
  @override
  String? get licenseUrl;
  @override
  String? get shareUrl;

  /// Create a copy of MusicTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MusicTrackImplCopyWith<_$MusicTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_filter_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommentFilterSettings _$CommentFilterSettingsFromJson(
  Map<String, dynamic> json,
) {
  return _CommentFilterSettings.fromJson(json);
}

/// @nodoc
mixin _$CommentFilterSettings {
  /// Hold comments the server flags as spam or offensive. Turning it off
  /// waives only profanity, insults and spam — never hate, sexual content,
  /// threats, scams or personal info.
  bool get filterSpamOffensive => throw _privateConstructorUsedError;

  /// Hold every comment from other people.
  bool get filterAllComments => throw _privateConstructorUsedError;

  /// Hold comments containing any of these.
  List<String> get commentKeywords => throw _privateConstructorUsedError;

  /// Serializes this CommentFilterSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentFilterSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentFilterSettingsCopyWith<CommentFilterSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentFilterSettingsCopyWith<$Res> {
  factory $CommentFilterSettingsCopyWith(
    CommentFilterSettings value,
    $Res Function(CommentFilterSettings) then,
  ) = _$CommentFilterSettingsCopyWithImpl<$Res, CommentFilterSettings>;
  @useResult
  $Res call({
    bool filterSpamOffensive,
    bool filterAllComments,
    List<String> commentKeywords,
  });
}

/// @nodoc
class _$CommentFilterSettingsCopyWithImpl<
  $Res,
  $Val extends CommentFilterSettings
>
    implements $CommentFilterSettingsCopyWith<$Res> {
  _$CommentFilterSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentFilterSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filterSpamOffensive = null,
    Object? filterAllComments = null,
    Object? commentKeywords = null,
  }) {
    return _then(
      _value.copyWith(
            filterSpamOffensive: null == filterSpamOffensive
                ? _value.filterSpamOffensive
                : filterSpamOffensive // ignore: cast_nullable_to_non_nullable
                      as bool,
            filterAllComments: null == filterAllComments
                ? _value.filterAllComments
                : filterAllComments // ignore: cast_nullable_to_non_nullable
                      as bool,
            commentKeywords: null == commentKeywords
                ? _value.commentKeywords
                : commentKeywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommentFilterSettingsImplCopyWith<$Res>
    implements $CommentFilterSettingsCopyWith<$Res> {
  factory _$$CommentFilterSettingsImplCopyWith(
    _$CommentFilterSettingsImpl value,
    $Res Function(_$CommentFilterSettingsImpl) then,
  ) = __$$CommentFilterSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool filterSpamOffensive,
    bool filterAllComments,
    List<String> commentKeywords,
  });
}

/// @nodoc
class __$$CommentFilterSettingsImplCopyWithImpl<$Res>
    extends
        _$CommentFilterSettingsCopyWithImpl<$Res, _$CommentFilterSettingsImpl>
    implements _$$CommentFilterSettingsImplCopyWith<$Res> {
  __$$CommentFilterSettingsImplCopyWithImpl(
    _$CommentFilterSettingsImpl _value,
    $Res Function(_$CommentFilterSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentFilterSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filterSpamOffensive = null,
    Object? filterAllComments = null,
    Object? commentKeywords = null,
  }) {
    return _then(
      _$CommentFilterSettingsImpl(
        filterSpamOffensive: null == filterSpamOffensive
            ? _value.filterSpamOffensive
            : filterSpamOffensive // ignore: cast_nullable_to_non_nullable
                  as bool,
        filterAllComments: null == filterAllComments
            ? _value.filterAllComments
            : filterAllComments // ignore: cast_nullable_to_non_nullable
                  as bool,
        commentKeywords: null == commentKeywords
            ? _value._commentKeywords
            : commentKeywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentFilterSettingsImpl implements _CommentFilterSettings {
  const _$CommentFilterSettingsImpl({
    this.filterSpamOffensive = true,
    this.filterAllComments = false,
    final List<String> commentKeywords = const <String>[],
  }) : _commentKeywords = commentKeywords;

  factory _$CommentFilterSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentFilterSettingsImplFromJson(json);

  /// Hold comments the server flags as spam or offensive. Turning it off
  /// waives only profanity, insults and spam — never hate, sexual content,
  /// threats, scams or personal info.
  @override
  @JsonKey()
  final bool filterSpamOffensive;

  /// Hold every comment from other people.
  @override
  @JsonKey()
  final bool filterAllComments;

  /// Hold comments containing any of these.
  final List<String> _commentKeywords;

  /// Hold comments containing any of these.
  @override
  @JsonKey()
  List<String> get commentKeywords {
    if (_commentKeywords is EqualUnmodifiableListView) return _commentKeywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commentKeywords);
  }

  @override
  String toString() {
    return 'CommentFilterSettings(filterSpamOffensive: $filterSpamOffensive, filterAllComments: $filterAllComments, commentKeywords: $commentKeywords)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentFilterSettingsImpl &&
            (identical(other.filterSpamOffensive, filterSpamOffensive) ||
                other.filterSpamOffensive == filterSpamOffensive) &&
            (identical(other.filterAllComments, filterAllComments) ||
                other.filterAllComments == filterAllComments) &&
            const DeepCollectionEquality().equals(
              other._commentKeywords,
              _commentKeywords,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    filterSpamOffensive,
    filterAllComments,
    const DeepCollectionEquality().hash(_commentKeywords),
  );

  /// Create a copy of CommentFilterSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentFilterSettingsImplCopyWith<_$CommentFilterSettingsImpl>
  get copyWith =>
      __$$CommentFilterSettingsImplCopyWithImpl<_$CommentFilterSettingsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentFilterSettingsImplToJson(this);
  }
}

abstract class _CommentFilterSettings implements CommentFilterSettings {
  const factory _CommentFilterSettings({
    final bool filterSpamOffensive,
    final bool filterAllComments,
    final List<String> commentKeywords,
  }) = _$CommentFilterSettingsImpl;

  factory _CommentFilterSettings.fromJson(Map<String, dynamic> json) =
      _$CommentFilterSettingsImpl.fromJson;

  /// Hold comments the server flags as spam or offensive. Turning it off
  /// waives only profanity, insults and spam — never hate, sexual content,
  /// threats, scams or personal info.
  @override
  bool get filterSpamOffensive;

  /// Hold every comment from other people.
  @override
  bool get filterAllComments;

  /// Hold comments containing any of these.
  @override
  List<String> get commentKeywords;

  /// Create a copy of CommentFilterSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentFilterSettingsImplCopyWith<_$CommentFilterSettingsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

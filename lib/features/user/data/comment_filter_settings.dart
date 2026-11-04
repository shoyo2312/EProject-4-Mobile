import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_filter_settings.freezed.dart';
part 'comment_filter_settings.g.dart';

/// The comment-filter part of `UserSettingsResponse` (user doc 3.14). The
/// response carries every account setting; only these three are read here.
///
/// interaction-service applies them to comments other people leave on this
/// account's videos: a comment they catch is held — stored, but shown to
/// nobody except its author.
@freezed
class CommentFilterSettings with _$CommentFilterSettings {
  const factory CommentFilterSettings({
    /// Hold comments the server flags as spam or offensive. Turning it off
    /// waives only profanity, insults and spam — never hate, sexual content,
    /// threats, scams or personal info.
    @Default(true) bool filterSpamOffensive,

    /// Hold every comment from other people.
    @Default(false) bool filterAllComments,

    /// Hold comments containing any of these.
    @Default(<String>[]) List<String> commentKeywords,
  }) = _CommentFilterSettings;

  factory CommentFilterSettings.fromJson(Map<String, dynamic> json) =>
      _$CommentFilterSettingsFromJson(json);

  /// Server limits on `commentKeywords` (user doc 3.15).
  static const maxKeywords = 50;
  static const maxKeywordLength = 30;
}

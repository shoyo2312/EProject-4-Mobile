import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_model.freezed.dart';
part 'story_model.g.dart';

// User ids are Snowflakes sent as JSON numbers; keep them as String so they
// are never round-tripped through a double. Story ids already arrive as
// strings (Mongo ids).
String _idFromJson(Object? value) => value.toString();

enum StoryMediaType {
  @JsonValue('IMAGE')
  image,
  @JsonValue('VIDEO')
  video,
  unknown,
}

enum StoryVisibility {
  @JsonValue('PUBLIC')
  public,
  @JsonValue('FRIENDS')
  friends,
  @JsonValue('PRIVATE')
  private,
  unknown,
}

/// Only the owner ever receives a status; everyone else gets null and only
/// ever sees ACTIVE stories (story doc §1).
enum StoryStatus {
  /// Waiting for media-worker's verdict. Owner-only.
  @JsonValue('PENDING_MODERATION')
  pendingModeration,

  /// Approved and live for 24h.
  @JsonValue('ACTIVE')
  active,

  /// The model was unsure. Owner-only; there is no admin queue for stories.
  @JsonValue('HELD')
  held,

  /// Refused — including a video longer than 60s. Owner-only.
  @JsonValue('REJECTED')
  rejected,
  unknown,
}

/// The five reactions, spelled as story-service spells them.
enum StoryReaction {
  @JsonValue('LIKE')
  like,
  @JsonValue('LOVE')
  love,
  @JsonValue('WOW')
  wow,
  @JsonValue('ANGRY')
  angry,
  @JsonValue('SAD')
  sad,
  unknown,
}

extension StoryReactionX on StoryReaction {
  String get emoji => switch (this) {
        StoryReaction.like => '👍',
        StoryReaction.love => '❤️',
        StoryReaction.wow => '😮',
        StoryReaction.angry => '😡',
        StoryReaction.sad => '😢',
        StoryReaction.unknown => '',
      };

  String get wire => switch (this) {
        StoryReaction.like => 'LIKE',
        StoryReaction.love => 'LOVE',
        StoryReaction.wow => 'WOW',
        StoryReaction.angry => 'ANGRY',
        StoryReaction.sad => 'SAD',
        StoryReaction.unknown => 'LIKE',
      };
}

/// The string story-service wants on the wire. `unknown` only ever comes back
/// from the server, so PUBLIC is the safe read of it.
String wireStoryVisibility(StoryVisibility visibility) => switch (visibility) {
      StoryVisibility.private => 'PRIVATE',
      StoryVisibility.friends => 'FRIENDS',
      StoryVisibility.public || StoryVisibility.unknown => 'PUBLIC',
    };

/// `reactionCounts` is keyed by reaction name; an unknown name is dropped
/// rather than failing the whole story.
Map<StoryReaction, int>? _countsFromJson(Object? value) {
  if (value is! Map) return null;
  final counts = <StoryReaction, int>{};
  value.forEach((key, count) {
    final reaction = $enumDecodeNullable(
      _$StoryReactionEnumMap,
      key,
      unknownValue: StoryReaction.unknown,
    );
    if (reaction != null && reaction != StoryReaction.unknown && count is num) {
      counts[reaction] = count.toInt();
    }
  });
  return counts;
}

Map<String, int>? _countsToJson(Map<StoryReaction, int>? counts) =>
    counts?.map((k, v) => MapEntry(k.wire, v));

/// One `StoryResponse`. [mediaUrl] is a presigned GET that lives one hour —
/// never store it; fetch the story again for a fresh one (story doc §3).
///
/// [status], [viewCount] and [reactionCounts] are owner-only: everyone else
/// receives null.
@freezed
class StoryModel with _$StoryModel {
  const factory StoryModel({
    required String id,
    @JsonKey(fromJson: _idFromJson) required String userId,
    required String mediaUrl,
    @JsonKey(unknownEnumValue: StoryMediaType.unknown)
    required StoryMediaType mediaType,
    String? caption,
    @JsonKey(unknownEnumValue: StoryVisibility.unknown)
    required StoryVisibility visibility,
    @JsonKey(unknownEnumValue: StoryStatus.unknown) StoryStatus? status,
    int? durationSeconds,
    int? viewCount,
    @Default(false) bool viewedByMe,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) StoryReaction? myReaction,
    @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
    Map<StoryReaction, int>? reactionCounts,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) = _StoryModel;

  factory StoryModel.fromJson(Map<String, dynamic> json) =>
      _$StoryModelFromJson(json);
}

/// One author's stories in the tray, oldest first — the order they play in.
/// The caller's own group is always first (story doc §4).
@freezed
class StoryGroup with _$StoryGroup {
  const factory StoryGroup({
    @JsonKey(fromJson: _idFromJson) required String userId,
    required List<StoryModel> stories,
    @Default(false) bool hasUnseen,
  }) = _StoryGroup;

  factory StoryGroup.fromJson(Map<String, dynamic> json) =>
      _$StoryGroupFromJson(json);
}

/// The ring around an avatar: present only when the account has a story the
/// caller may watch. No media, so nothing is signed.
@freezed
class StoryRing with _$StoryRing {
  const factory StoryRing({
    @JsonKey(fromJson: _idFromJson) required String userId,
    @Default(false) bool hasUnseen,
  }) = _StoryRing;

  factory StoryRing.fromJson(Map<String, dynamic> json) =>
      _$StoryRingFromJson(json);
}

/// One row of "who watched my story", newest first.
@freezed
class StoryViewer with _$StoryViewer {
  const factory StoryViewer({
    @JsonKey(fromJson: _idFromJson) required String viewerId,
    required DateTime viewedAt,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) StoryReaction? reaction,
  }) = _StoryViewer;

  factory StoryViewer.fromJson(Map<String, dynamic> json) =>
      _$StoryViewerFromJson(json);
}

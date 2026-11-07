import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_models.freezed.dart';
part 'follow_models.g.dart';

String _idFromJson(Object? value) => value.toString();

/// What `POST /{userId}/follow` did (user doc 3.4): followed at once, or —
/// for a private account — left a request for the owner to approve.
enum FollowStatus {
  @JsonValue('FOLLOWING')
  following,
  @JsonValue('REQUESTED')
  requested,
  unknown,
}

/// `GET /{userId}/friendship` — enough for the Follow button in one call
/// (user doc 3.17). An unknown id answers all false rather than 404.
@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    @JsonKey(fromJson: _idFromJson) required String userId,
    @Default(false) bool friends,
    @Default(false) bool following,
    @Default(false) bool requested,
    @Default(false) bool privateAccount,
  }) = _Friendship;

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String id,
    required String videoId,
    required String userId,
    required String username,
    String? avatarUrl,
    required String text,
    required DateTime createdAt,
    // Replies are one level deep — a reply never has replies of its own.
    // The live API sends neither field yet, hence the defaults.
    @Default(<CommentModel>[]) List<CommentModel> replies,
    @Default(0) int replyCount,
    @Default(0) int likeCount,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}

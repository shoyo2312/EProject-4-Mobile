import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

@freezed
class VideoModel with _$VideoModel {
  const factory VideoModel({
    required String id,
    required String url,
    required String thumbnailUrl,
    required String caption,
    required String username,
    String? avatarUrl,
    required int likeCount,
    required int commentCount,
    required int shareCount,
    required bool isLiked,
    required bool isSaved,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/user/data/comment_filter_settings.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'comment_filters_provider.g.dart';

/// The signed-in account's comment filters (user doc 3.14–3.15).
@riverpod
class CommentFilters extends _$CommentFilters {
  @override
  Future<CommentFilterSettings> build() =>
      ref.read(userRepositoryProvider).getCommentFilters();

  Future<void> setFilterSpamOffensive(bool value) => _save({
    'filterSpamOffensive': value,
  }, (s) => s.copyWith(filterSpamOffensive: value));

  Future<void> setFilterAllComments(bool value) => _save({
    'filterAllComments': value,
  }, (s) => s.copyWith(filterAllComments: value));

  /// The server replaces the whole list, so the whole list goes up.
  Future<void> setKeywords(List<String> keywords) => _save({
    'commentKeywords': keywords,
  }, (s) => s.copyWith(commentKeywords: keywords));

  /// Shows the change at once and puts the old value back if the server
  /// refuses it; the caller gets the error to show. Afterwards the state is
  /// what the server answered — it trims and cleans keywords on the way in.
  Future<void> _save(
    Map<String, dynamic> changes,
    CommentFilterSettings Function(CommentFilterSettings) apply,
  ) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData(apply(previous));
    try {
      final saved = await ref
          .read(userRepositoryProvider)
          .updateCommentFilters(changes);
      state = AsyncData(saved);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

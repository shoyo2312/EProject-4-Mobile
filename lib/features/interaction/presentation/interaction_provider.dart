import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_remote_datasource.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';

part 'interaction_provider.g.dart';

@Riverpod(keepAlive: true)
InteractionRepository interactionRepository(Ref ref) => InteractionRepository(
      InteractionRemoteDatasource(ref.watch(apiClientProvider)),
    );

/// Like state for **one** video, fetched on first watch and dropped when the
/// last watcher goes away.
///
/// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
/// budget is shared by every call the app makes, so the feed only ever watches
/// this for the clip on screen (interaction doc 3.3).
@riverpod
class LikeNotifier extends _$LikeNotifier {
  @override
  FutureOr<LikeStatus> build(String videoId) =>
      ref.read(interactionRepositoryProvider).getLikeStatus(videoId);

  /// Optimistic: the heart flips now and the server's own count replaces the
  /// guess when it answers. A failed write puts the previous state back —
  /// like/unlike are idempotent, so the next tap is safe to send again.
  Future<void> toggle() async {
    final current = state.valueOrNull;
    // Still loading: nothing to toggle away from, and guessing here would
    // fight the in-flight `like-status` answer.
    if (current == null) return;

    final wantLiked = !current.liked;
    state = AsyncData(current.copyWith(
      liked: wantLiked,
      likeCount: current.likeCount + (wantLiked ? 1 : -1),
    ));

    final repository = ref.read(interactionRepositoryProvider);
    try {
      state = AsyncData(
        wantLiked
            ? await repository.like(videoId)
            : await repository.unlike(videoId),
      );
    } on AppException {
      state = AsyncData(current);
    }
  }

  /// Double-tap: likes, never un-likes.
  Future<void> like() async {
    if (state.valueOrNull?.liked ?? true) return;
    await toggle();
  }
}

/// The four counters of one video, straight from interaction-service.
///
/// Watched only for the clip on screen, like [LikeNotifier] and for the same
/// reason: there is no batch endpoint and the gateway's per-IP budget is
/// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
@riverpod
Future<InteractionCounts> videoCounts(Ref ref, String videoId) =>
    ref.read(interactionRepositoryProvider).getCounts(videoId);

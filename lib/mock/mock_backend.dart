import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_remote_datasource.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/data/chat_socket.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_remote_datasource.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/data/notification_remote_datasource.dart';
import 'package:tiktok_mobile/features/notification/data/notification_repository.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/search/data/search_remote_datasource.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/data/settings_remote_datasource.dart';
import 'package:tiktok_mobile/features/settings/data/settings_repository.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/search/data/search_repository.dart';
import 'package:tiktok_mobile/features/search/presentation/search_provider.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/data/studio_remote_datasource.dart';
import 'package:tiktok_mobile/features/studio/data/studio_repository.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_remote_datasource.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/data/comment_filter_settings.dart';
import 'package:tiktok_mobile/features/user/data/follow_models.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_remote_datasource.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// In-memory stand-in for auth/user/video/comment services, switched on with
/// `--dart-define=USE_MOCK=true`. Nothing here touches the network; the
/// repositories are subclassed so every provider above them stays untouched.
List<Override> mockOverrides() => [
  authStateProvider.overrideWith(_MockAuthState.new),
  feedRepositoryProvider.overrideWith(
    (ref) =>
        _MockFeedRepository(FeedRemoteDatasource(ref.watch(apiClientProvider))),
  ),
  userRepositoryProvider.overrideWith(
    (ref) =>
        _MockUserRepository(UserRemoteDatasource(ref.watch(apiClientProvider))),
  ),
  commentRepositoryProvider.overrideWith(
    (ref) => _MockCommentRepository(
      CommentRemoteDatasource(ref.watch(apiClientProvider)),
    ),
  ),
  interactionRepositoryProvider.overrideWith(
    (ref) => _MockInteractionRepository(
      InteractionRemoteDatasource(ref.watch(apiClientProvider)),
    ),
  ),
  chatRepositoryProvider.overrideWith(
    (ref) => _MockChatRepository(
      ChatRemoteDatasource(ref.watch(apiClientProvider)),
      // Never asked for a token: every stream is overridden below.
      ChatSocket(() async => null),
    ),
  ),
  notificationRepositoryProvider.overrideWith(
    (ref) => _MockNotificationRepository(
      NotificationRemoteDatasource(ref.watch(apiClientProvider)),
    ),
  ),
  searchRepositoryProvider.overrideWith(
    (ref) => _MockSearchRepository(
      SearchRemoteDatasource(ref.watch(apiClientProvider)),
    ),
  ),
  settingsRepositoryProvider.overrideWith(
    (ref) => _MockSettingsRepository(
      SettingsRemoteDatasource(ref.watch(apiClientProvider)),
    ),
  ),
  storyRepositoryProvider.overrideWith(
    (ref) => _MockStoryRepository(
      StoryRemoteDatasource(ref.watch(apiClientProvider)),
    ),
  ),
  studioRepositoryProvider.overrideWith(
    (ref) => _MockStudioRepository(
      StudioRemoteDatasource(ref.watch(apiClientProvider)),
      // One catalogue: a caption changed here must survive a visibility
      // change made through the feed repository, as it does on the server.
      ref.watch(feedRepositoryProvider) as _MockFeedRepository,
    ),
  ),
];

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

const _meId = '1001';

final _me = UserModel(
  id: _meId,
  username: 'mihhuq1223',
  email: 'minhhung@test.com',
  role: UserRole.user,
  status: UserStatus.active,
  emailVerified: true,
  createdAt: DateTime(2025, 3, 4),
);

const _profiles = <String, UserProfileModel>{
  _meId: UserProfileModel(
    userId: _meId,
    displayName: 'Minh Hùng',
    bio: 'Code ban ngày, quay TikTok ban đêm 🌙',
    avatarUrl: 'https://i.pravatar.cc/300?img=12',
    followerCount: 5,
    followingCount: 6,
  ),
  '2002': UserProfileModel(
    userId: '2002',
    displayName: 'Hoàng Chi Tùng',
    bio: 'first date reviewer 🍕',
    avatarUrl: 'https://i.pravatar.cc/300?img=45',
    followerCount: 182400,
    followingCount: 312,
  ),
  '3003': UserProfileModel(
    userId: '3003',
    displayName: 'Sabine',
    bio: 'Sài Gòn · food & travel',
    avatarUrl: 'https://i.pravatar.cc/300?img=32',
    followerCount: 9412,
    followingCount: 128,
  ),
  '4004': UserProfileModel(
    userId: '4004',
    displayName: 'Benri Studio',
    bio: 'small cat, big opinions',
    avatarUrl: 'https://i.pravatar.cc/300?img=8',
    followerCount: 267000,
    followingCount: 91,
  ),
  '5005': UserProfileModel(
    userId: '5005',
    displayName: 'Hà Noodles',
    bio: 'Ba nguyên liệu, sáu phút 🍜',
    avatarUrl: 'https://i.pravatar.cc/300?img=24',
    followerCount: 84200,
    followingCount: 204,
  ),
  '6006': UserProfileModel(
    userId: '6006',
    displayName: 'Long An Daily',
    bio: 'phà 5:40 sáng mỗi ngày',
    avatarUrl: 'https://i.pravatar.cc/300?img=51',
    followerCount: 513000,
    followingCount: 12,
  ),
  '7007': UserProfileModel(
    userId: '7007',
    displayName: 'Duc Builds',
    bio: 'sửa đồ cũ thành đồ hay',
    avatarUrl: 'https://i.pravatar.cc/300?img=60',
    followerCount: 149000,
    followingCount: 388,
  ),
};

// Four public HLS test streams, rotated across the clips so every card in the
// feed actually plays instead of falling back to the striped placeholder.
const _hlsA = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
const _hlsB = 'https://test-streams.mux.dev/pts_shift/master.m3u8';
const _hlsC = 'https://test-streams.mux.dev/tos_ismc/main.m3u8';
const _hlsD =
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8';

final _videos = <VideoModel>[
  VideoModel(
    id: 'v1',
    userId: '2002',
    title: 'First date được đưa đi ăn pizza',
    description: '#POV #firstdate mà t nuốt không trôi bây ơi...',
    thumbnailUrl: 'https://picsum.photos/seed/tt1/360/640',
    hlsUrl: _hlsA,
    durationSeconds: 34,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 1284000,
    likeCount: 162000,
    commentCount: 1491,
    shareCount: 57100,
    createdAt: DateTime(2026, 8, 2),
  ),
  VideoModel(
    id: 'v2',
    userId: '3003',
    title: 'Một ngày ở Đà Lạt',
    description: 'Sương mù dày quá trời #dalat #vlog',
    thumbnailUrl: 'https://picsum.photos/seed/tt2/360/640',
    hlsUrl: _hlsB,
    durationSeconds: 58,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 88400,
    likeCount: 12300,
    commentCount: 217,
    shareCount: 3200,
    createdAt: DateTime(2026, 8, 5),
  ),
  VideoModel(
    id: 'v3',
    userId: _meId,
    title: 'Deploy lúc 3 giờ sáng',
    description: 'CI xanh là đi ngủ #devlife',
    thumbnailUrl: 'https://picsum.photos/seed/tt3/360/640',
    hlsUrl: _hlsC,
    durationSeconds: 21,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 4210,
    likeCount: 512,
    commentCount: 3204,
    shareCount: 41,
    createdAt: DateTime(2026, 8, 8),
  ),
  VideoModel(
    id: 'v4',
    userId: '2002',
    title: 'Thử món bún đậu 5 sao',
    description: 'Ngon thật hay ngon giả? #review',
    thumbnailUrl: 'https://picsum.photos/seed/tt4/360/640',
    hlsUrl: _hlsD,
    durationSeconds: 47,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 730000,
    likeCount: 91200,
    commentCount: 8760,
    shareCount: 6800,
    createdAt: DateTime(2026, 8, 10),
  ),
  VideoModel(
    id: 'v5',
    userId: '3003',
    title: 'Mèo nhà mình leo tủ lạnh',
    description: 'Không ai dạy nó cả 🐱',
    thumbnailUrl: 'https://picsum.photos/seed/tt5/360/640',
    hlsUrl: _hlsA,
    durationSeconds: 15,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 2900000,
    likeCount: 410000,
    commentCount: 9987,
    shareCount: 124000,
    createdAt: DateTime(2026, 8, 12),
  ),
  // The four clips carried over from the design mock (flutter/lib/data.dart).
  VideoModel(
    id: 'v8',
    userId: '4004',
    title: 'Small cat, big opinions',
    description:
        'He waited all evening for the projector to come on. #cat #projector',
    thumbnailUrl: 'https://picsum.photos/seed/tt8/360/640',
    hlsUrl: _hlsB,
    durationSeconds: 27,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 412000,
    likeCount: 26700,
    commentCount: 310,
    shareCount: 57100,
    createdAt: DateTime(2026, 8, 14, 9),
  ),
  VideoModel(
    id: 'v9',
    userId: '5005',
    title: 'Ba nguyên liệu, sáu phút, một cái chảo rất nóng',
    description: 'Full order nằm ở comment ghim nha #noodles #cooking',
    thumbnailUrl: 'https://picsum.photos/seed/tt9/360/640',
    hlsUrl: _hlsC,
    durationSeconds: 41,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 96000,
    likeCount: 8420,
    commentCount: 296,
    shareCount: 3200,
    createdAt: DateTime(2026, 8, 14, 6),
  ),
  VideoModel(
    id: 'v10',
    userId: '6006',
    title: 'Chuyến phà 5:40 sáng',
    description:
        'Không ai nói chuyện trên chuyến phà này, ai cũng chỉ nhìn mặt nước.',
    thumbnailUrl: 'https://picsum.photos/seed/tt10/360/640',
    hlsUrl: _hlsD,
    durationSeconds: 63,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 2400000,
    likeCount: 51300,
    commentCount: 742,
    shareCount: 12400,
    createdAt: DateTime(2026, 8, 13, 22),
  ),
  VideoModel(
    id: 'v11',
    userId: '7007',
    title: 'Biến đèn bàn hỏng thành đèn studio',
    description: 'Chi phí: một buổi chiều và ít băng keo #diy #build',
    thumbnailUrl: 'https://picsum.photos/seed/tt11/360/640',
    hlsUrl: _hlsA,
    durationSeconds: 52,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 640000,
    likeCount: 14900,
    commentCount: 208,
    shareCount: 5800,
    createdAt: DateTime(2026, 8, 13, 14),
  ),
  // Extra rows owned by me so the profile grid is more than one line.
  VideoModel(
    id: 'v12',
    userId: _meId,
    title: 'Review bàn phím 2 triệu',
    description: 'Gõ êm nhưng ồn kinh khủng 😅 #keyboard',
    thumbnailUrl: 'https://picsum.photos/seed/tt12/360/640',
    hlsUrl: _hlsB,
    durationSeconds: 38,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 84000,
    likeCount: 6300,
    commentCount: 412,
    shareCount: 1500,
    createdAt: DateTime(2026, 8, 11),
  ),
  VideoModel(
    id: 'v13',
    userId: _meId,
    title: 'Một ngày làm dev ở Sài Gòn',
    description: '7h dậy, 9h họp, 11h vẫn họp #devlife',
    thumbnailUrl: 'https://picsum.photos/seed/tt13/360/640',
    hlsUrl: _hlsC,
    durationSeconds: 74,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 1100000,
    likeCount: 78000,
    commentCount: 2140,
    shareCount: 8900,
    createdAt: DateTime(2026, 8, 9),
  ),
  VideoModel(
    id: 'v14',
    userId: _meId,
    title: 'Cà phê muối tự pha',
    description: 'Đỡ được 40k mỗi sáng ☕',
    thumbnailUrl: 'https://picsum.photos/seed/tt14/360/640',
    hlsUrl: _hlsD,
    durationSeconds: 29,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 340000,
    likeCount: 21000,
    commentCount: 604,
    shareCount: 2200,
    createdAt: DateTime(2026, 8, 6),
  ),
  VideoModel(
    id: 'v15',
    userId: _meId,
    title: 'Dọn bàn làm việc lần thứ 9',
    description: 'Lần này chắc trụ được 2 tuần #desksetup',
    thumbnailUrl: 'https://picsum.photos/seed/tt15/360/640',
    hlsUrl: _hlsA,
    durationSeconds: 45,
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 18000,
    likeCount: 1400,
    commentCount: 287,
    shareCount: 96,
    createdAt: DateTime(2026, 8, 3),
  ),
  // Owner-only rows, so the profile grid shows its overlays.
  VideoModel(
    id: 'v6',
    userId: _meId,
    title: 'Video đang xử lý',
    thumbnailUrl: 'https://picsum.photos/seed/tt6/360/640',
    status: VideoStatus.processing,
    visibility: VideoVisibility.public,
    viewCount: 0,
    likeCount: 0,
    commentCount: 0,
    createdAt: DateTime(2026, 8, 13),
  ),
  VideoModel(
    id: 'v7',
    userId: _meId,
    title: 'Note cho riêng mình',
    thumbnailUrl: 'https://picsum.photos/seed/tt7/360/640',
    hlsUrl: 'https://test-streams.mux.dev/pts_shift/master.m3u8',
    status: VideoStatus.published,
    visibility: VideoVisibility.private,
    viewCount: 12,
    likeCount: 1,
    commentCount: 0,
    createdAt: DateTime(2026, 7, 30),
  ),
];

const _usernames = [
  'n.',
  'Sabine',
  'Ước có sống mũi',
  'Kwinna',
  'quangdev',
  'mèo lười',
  'Trâm Anh',
  'bin_9x',
  'không tên',
  'Huyền 🍀',
  'tuandat',
  'Lan Chi',
];

const _texts = [
  'chiếm hữu ❌ chiếm chỗ ✅',
  'cứ tự nhiên như ở nhà nha anh',
  'cười khunggg 😂😂',
  'ai cũng như tui hết á',
  'sao mà dễ thương vậy trời',
  'coi đi coi lại 10 lần rồi',
  'nhạc nền tên gì vậy mn',
  'đúng bài của mình luôn',
  'thánh nhọ là đây chứ đâu',
  'quay tiếp phần 2 đi ạ',
];

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Hand-written comments carried over from the design mock, used for the
/// first page of every video so the sheet has something readable to show.
/// Anything past these is generated by [_comment].
///
/// Flat, like the real thing: interaction-service has no replies, no comment
/// likes and no author name on a comment — the name and picture come from the
/// profile cache, keyed by `userId`.
const _seedComments = <({String text, int hoursAgo})>[
  (text: 'cái kiểu nó đứng dậy như người thật á, chịu không nổi', hoursAgo: 2),
  (text: 'tối nào nó cũng làm vậy tầm 9h, đúng giờ luôn', hoursAgo: 2),
  (text: 'máy chiếu gì vậy ạ, phòng nhìn đẹp quá trời', hoursAgo: 1),
  (text: 'gửi cái này cho con mèo nhà mình học cách cư xử', hoursAgo: 1),
  (text: 'làm phần 2 đi ạ, phải xem sau đó ra sao chứ', hoursAgo: 1),
];

/// Deterministic per (video, index) so paging back and forth is stable.
CommentModel _comment(String videoId, int index) {
  final seed = index < _seedComments.length ? _seedComments[index] : null;
  return CommentModel(
    id: '$videoId-c$index',
    videoId: videoId,
    userId: '${7100 + index % 12}',
    text: seed?.text ?? _texts[(index * 7) % _texts.length],
    createdAt: DateTime(
      2026,
      8,
      14,
      11,
    ).subtract(Duration(hours: seed?.hoursAgo ?? index * 3)),
    replyCount: index == 0 ? _mockReplyCount : 0,
  );
}

const _mockReplyCount = 2;

/// Cursor is just the offset — 20 comments a page, up to the video's total.
CommentPage _commentPage(String videoId, String? cursor) {
  final total = _videos
      .firstWhere((v) => v.id == videoId, orElse: () => _videos.first)
      .commentCount;
  final offset = int.tryParse(cursor ?? '0') ?? 0;
  final end = min(offset + 20, total);
  return CommentPage(
    items: [for (var i = offset; i < end; i++) _comment(videoId, i)],
    hasMore: end < total,
    nextCursor: end >= total ? null : '$end',
  );
}

PageResponse<T> _singlePage<T>(List<T> items) => PageResponse(
  content: items,
  size: items.length,
  number: 0,
  totalElements: items.length,
  totalPages: 1,
);

UserProfileModel _profile(String userId) {
  final known = _profiles[userId];
  if (known != null) return known;
  // Anyone not in the seeded cast — a commenter, say — still gets a stable
  // name and picture, so the sheet is not a column of placeholders.
  final n = userId.hashCode.abs();
  return UserProfileModel(
    userId: userId,
    displayName: _usernames[n % _usernames.length],
    avatarUrl: 'https://i.pravatar.cc/100?img=${n % 70 + 1}',
    followerCount: n % 4000,
    followingCount: n % 300,
  );
}

/// Enough delay to see the loading states, little enough to not annoy.
Future<void> _latency() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

class _MockAuthState extends AuthState {
  @override
  Future<UserModel?> build() async => _me;

  @override
  Future<void> changeUsername(String username) async {
    final current = state.valueOrNull ?? _me;
    state = AsyncData(
      current.copyWith(
        username: username,
        usernameChangeableAt: DateTime.now().add(const Duration(days: 30)),
      ),
    );
  }

  @override
  Future<void> logout() async => state = const AsyncData(null);
}

/// Likes kept in a set, counters in a map — enough for the heart to flip and
/// the number next to it to move. View/watch/share are accepted and dropped:
/// nothing offline reads them back.
class _MockInteractionRepository extends InteractionRepository {
  _MockInteractionRepository(super.remoteDatasource);

  final _liked = <String>{};
  final _saved = <String>{};
  final _counts = <String, int>{};

  LikeStatus _status(String videoId) => LikeStatus(
    videoId: videoId,
    liked: _liked.contains(videoId),
    likeCount: _counts[videoId] ?? 0,
  );

  @override
  Future<LikeStatus> getLikeStatus(String videoId) async {
    await _latency();
    return _status(videoId);
  }

  @override
  Future<LikeStatus> like(String videoId) async {
    await _latency();
    if (_liked.add(videoId)) _counts[videoId] = (_counts[videoId] ?? 0) + 1;
    return _status(videoId);
  }

  @override
  Future<LikeStatus> unlike(String videoId) async {
    await _latency();
    if (_liked.remove(videoId)) _counts[videoId] = (_counts[videoId] ?? 1) - 1;
    return _status(videoId);
  }

  @override
  Future<void> recordView(String videoId, {required String playId}) =>
      _latency();

  @override
  Future<InteractionCounts> getCounts(String videoId) async {
    await _latency();
    final video = _videos.firstWhere(
      (v) => v.id == videoId,
      orElse: () => _videos.first,
    );
    return InteractionCounts(
      videoId: videoId,
      likeCount: _counts[videoId] ?? video.likeCount,
      commentCount: video.commentCount,
      shareCount: video.shareCount,
      viewCount: video.viewCount,
    );
  }

  @override
  Future<void> recordWatch(
    String videoId, {
    required int watchedMs,
    required int durationMs,
  }) => _latency();

  @override
  Future<List<LikeStatus>> getLikeStatuses(List<String> ids) async {
    await _latency();
    return [for (final id in ids) _status(id)];
  }

  @override
  Future<SaveStatus> getSaveStatus(String videoId) async {
    await _latency();
    return SaveStatus(videoId: videoId, saved: _saved.contains(videoId));
  }

  @override
  Future<SaveStatus> save(String videoId) async {
    await _latency();
    _saved.add(videoId);
    return SaveStatus(videoId: videoId, saved: true);
  }

  @override
  Future<SaveStatus> unsave(String videoId) async {
    await _latency();
    _saved.remove(videoId);
    return SaveStatus(videoId: videoId, saved: false);
  }

  /// One page, then the end: the offline catalogue is small enough that paging
  /// it would only exercise the cursor plumbing, not the screens.
  @override
  Future<VideoIdPage> getLikedVideoIds({String? cursor, int size = 20}) async {
    await _latency();
    return VideoIdPage(videoIds: _liked.toList(), hasMore: false);
  }

  @override
  Future<VideoIdPage> getSavedVideoIds({String? cursor, int size = 20}) async {
    await _latency();
    return VideoIdPage(videoIds: _saved.toList(), hasMore: false);
  }

  @override
  Future<void> share(String videoId) => _latency();

  final _reposted = <String>{};

  /// Only the signed-in mock user reposts anything offline.
  @override
  Future<VideoIdPage> getRepostedVideoIds(
    String userId, {
    String? cursor,
    int size = 20,
  }) async {
    await _latency();
    return VideoIdPage(
      videoIds: userId == _meId ? _reposted.toList().reversed.toList() : [],
      hasMore: false,
    );
  }

  @override
  Future<bool> repost(String videoId) async {
    await _latency();
    _reposted.add(videoId);
    return true;
  }

  @override
  Future<bool> unrepost(String videoId) async {
    await _latency();
    _reposted.remove(videoId);
    return false;
  }
}

class _MockFeedRepository extends FeedRepository {
  _MockFeedRepository(super.remoteDatasource);

  final _deleted = <String>{};

  List<VideoModel> get _live => [
    for (final v in _videos)
      if (!_deleted.contains(v.id)) _edits[v.id] ?? v,
  ];

  /// The offline leaderboard is the catalogue by view count — no recency
  /// decay, but the same contract: best first, ids the caller hydrates.
  @override
  Future<List<VideoModel>> fetchTrending({int limit = 24}) async {
    await _latency();
    final ranked = [
      for (final v in _live)
        if (v.status == VideoStatus.published &&
            v.visibility == VideoVisibility.public)
          v,
    ]..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return ranked.take(limit).toList();
  }

  /// No ranking offline: answering empty sends [FeedNotifier] straight to the
  /// chronological list below, which is the whole mock catalogue anyway.
  @override
  Future<List<VideoModel>> fetchRankedFeed({int limit = 10}) async => [];

  /// Offline everyone follows everyone, so this is the catalogue filtered by
  /// author — enough to exercise the empty case and the populated one.
  @override
  Future<VideoPage> fetchFollowingFeed({
    required List<String> followedUserIds,
    String? cursor,
    int size = 20,
    String feed = 'FOLLOWING',
  }) async {
    await _latency();
    final followed = followedUserIds.toSet();
    return VideoPage(
      items: [
        for (final v in _live)
          if (followed.contains(v.userId)) v,
      ],
    );
  }

  @override
  Future<VideoPage> fetchFeed({String? cursor, int size = 20}) async {
    await _latency();
    // One page then done — `nextCursor: null` is the only stop condition.
    if (cursor != null) return const VideoPage(items: []);
    return VideoPage(
      items: [
        for (final v in _live)
          if (v.status == VideoStatus.published &&
              v.visibility == VideoVisibility.public)
            v,
      ],
    );
  }

  @override
  Future<PageResponse<VideoModel>> getUserVideos(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    await _latency();
    if (page > 0) return _emptyPage();
    // Only the owner sees processing/private rows — same rule as the API.
    final own = userId == _meId;
    return _singlePage(pinnedFirst([
      for (final v in _live)
        if (v.userId == userId &&
            (own ||
                (v.status == VideoStatus.published &&
                    v.visibility == VideoVisibility.public)))
          v,
    ]));
  }

  /// Nothing is uploaded offline: the file is ignored and a PROCESSING row is
  /// added, which [getVideo] then reports as PUBLISHED — the same two states
  /// the real publish flow walks through.
  @override
  Future<VideoModel> uploadAndPublish({
    required File file,
    required String contentType,
    required String title,
    String? description,
    required VideoVisibility visibility,
    List<String> tags = const [],
    bool commentsDisabled = false,
    VideoEdit? edit,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    for (var sent = 0; sent <= 10; sent++) {
      await _latency();
      onProgress?.call(sent, 10);
    }
    final video = VideoModel(
      id: 'upload-${_videos.length + 1}',
      userId: _meId,
      title: title,
      description: description,
      status: VideoStatus.processing,
      visibility: visibility,
      commentsDisabled: commentsDisabled,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
    );
    _videos.insert(0, video);
    return video;
  }

  @override
  Future<VideoModel> getVideo(String videoId) async {
    final video = _live.where((v) => v.id == videoId).firstOrNull;
    if (video == null) {
      throw const ServerException(
        404,
        'Video not found',
        code: 'VIDEO_NOT_FOUND',
      );
    }
    if (video.status != VideoStatus.processing) return video;
    // Transcoding "finishes" on the first poll.
    final published = video.copyWith(
      status: VideoStatus.published,
      hlsUrl: _hlsA,
    );
    _videos[_videos.indexOf(video)] = published;
    return published;
  }

  /// Answers in the order asked and drops ids that no longer resolve, exactly
  /// as `GET /videos/batch` does — the Liked and Saved tabs depend on both.
  @override
  Future<List<VideoModel>> fetchByIds(List<String> ids) async {
    await _latency();
    final byId = {for (final v in _live) v.id: v};
    return [for (final id in ids) ?byId[id]];
  }

  final _edits = <String, VideoModel>{};

  @override
  Future<VideoModel> updateVisibility(
    String videoId,
    VideoVisibility visibility,
  ) async {
    await _latency();
    return _edit(videoId, (v) => v.copyWith(visibility: visibility));
  }

  @override
  Future<VideoModel> updateCommentsDisabled(
    String videoId,
    bool disabled,
  ) async {
    await _latency();
    return _edit(videoId, (v) => v.copyWith(commentsDisabled: disabled));
  }

  /// Same rules as video-service: three at most, and only a published video
  /// that is not private.
  @override
  Future<VideoModel> setPinned(String videoId, bool pinned) async {
    await _latency();
    final video = _live.firstWhere((v) => v.id == videoId);
    if (pinned && video.pinnedAt == null) {
      if (video.status != VideoStatus.published ||
          video.visibility == VideoVisibility.private) {
        throw const ServerException(409, 'Video not pinnable',
            code: 'VIDEO_NOT_PINNABLE');
      }
      final count = _live
          .where((v) => v.userId == video.userId && v.pinnedAt != null)
          .length;
      if (count >= 3) {
        throw const ServerException(409, 'Pin limit reached',
            code: 'PIN_LIMIT_REACHED');
      }
    }
    return _edit(
      videoId,
      (v) => v.copyWith(
        pinnedAt: pinned ? (v.pinnedAt ?? DateTime.now()) : null,
      ),
    );
  }

  /// `_live` already hands back the edited copy, so this reads through it
  /// rather than keeping a second notion of what the current video is.
  VideoModel _edit(String videoId, VideoModel Function(VideoModel) change) =>
      _edits[videoId] = change(_live.firstWhere((v) => v.id == videoId));

  @override
  Future<void> deleteVideo(String videoId) async => _deleted.add(videoId);

  PageResponse<VideoModel> _emptyPage() => const PageResponse(
    content: [],
    size: 20,
    number: 1,
    totalElements: 0,
    totalPages: 1,
  );
}

class _MockUserRepository extends UserRepository {
  _MockUserRepository(super.remoteDatasource);

  UserProfileModel _mine = _profiles[_meId]!;

  CommentFilterSettings _filters = const CommentFilterSettings();

  @override
  Future<CommentFilterSettings> getCommentFilters() async {
    await _latency();
    return _filters;
  }

  @override
  Future<CommentFilterSettings> updateCommentFilters(
    Map<String, dynamic> changes,
  ) async {
    await _latency();
    _filters = _filters.copyWith(
      filterSpamOffensive:
          changes['filterSpamOffensive'] as bool? ??
          _filters.filterSpamOffensive,
      filterAllComments:
          changes['filterAllComments'] as bool? ?? _filters.filterAllComments,
      commentKeywords:
          changes['commentKeywords'] as List<String>? ??
          _filters.commentKeywords,
    );
    return _filters;
  }

  @override
  Future<UserProfileModel> getMyProfile() async {
    await _latency();
    return _mine;
  }

  @override
  Future<UserProfileModel> updateMyProfile(Map<String, dynamic> changes) async {
    _mine = _mine.copyWith(
      displayName: changes['displayName'] as String? ?? _mine.displayName,
      bio: changes['bio'] as String? ?? _mine.bio,
      avatarUrl: changes['avatarUrl'] as String? ?? _mine.avatarUrl,
      displayNameChangeableAt: changes.containsKey('displayName')
          ? DateTime.now().add(const Duration(days: 7))
          : _mine.displayNameChangeableAt,
    );
    return _mine;
  }

  /// Offline there is nowhere to put the bytes, so the picked file's own path
  /// stands in for the URL the server would have chosen.
  @override
  Future<UserProfileModel> uploadAvatar(
    File file, {
    required String contentType,
  }) async {
    await _latency();
    _mine = _mine.copyWith(avatarUrl: file.path);
    return _mine;
  }

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    await _latency();
    return userId == _meId ? _mine : _profile(userId);
  }

  @override
  Future<Map<String, UserProfileModel>> getProfiles(List<String> ids) async {
    await _latency();
    return {
      for (final id in ids.toSet()) id: id == _meId ? _mine : _profile(id),
    };
  }

  final _following = <String>{};
  final _followRequests = <String>{'2001', '2002'};

  @override
  Future<FollowStatus> follow(String userId) async {
    _following.add(userId);
    return FollowStatus.following;
  }

  @override
  Future<void> unfollow(String userId) async => _following.remove(userId);

  @override
  Future<Friendship> getFriendship(String userId) async =>
      Friendship(userId: userId, following: _following.contains(userId));

  @override
  Future<PageResponse<UserProfileModel>> getFollowRequests({
    int page = 0,
    int size = 20,
  }) async {
    await _latency();
    return _singlePage([for (final id in _followRequests) _profile(id)]);
  }

  @override
  Future<void> approveFollowRequest(String requesterId) async =>
      _followRequests.remove(requesterId);

  @override
  Future<void> declineFollowRequest(String requesterId) async =>
      _followRequests.remove(requesterId);

  @override
  Future<void> block(String userId) async {}

  @override
  Future<void> unblock(String userId) async {}

  @override
  Future<void> mute(String userId) async {}

  @override
  Future<void> unmute(String userId) async {}

  @override
  Future<PageResponse<UserProfileModel>> getFollowers(
    String userId, {
    int page = 0,
    int size = 20,
  }) async => _singlePage(page > 0 ? [] : _profiles.values.toList());

  @override
  Future<PageResponse<UserProfileModel>> getFollowing(
    String userId, {
    int page = 0,
    int size = 20,
  }) async => _singlePage(page > 0 ? [] : _profiles.values.toList());

  /// Offline account search: display name contains the term, most followed
  /// first — the same order user-service answers in.
  @override
  Future<PageResponse<UserProfileModel>> searchUsers(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    await _latency();
    final term = query.trim().toLowerCase();
    if (page > 0 || term.isEmpty) return _singlePage([]);
    final matches = [
      for (final p in _profiles.values)
        if (p.displayName.toLowerCase().contains(term)) p,
    ]..sort((a, b) => b.followerCount.compareTo(a.followerCount));
    return _singlePage(matches);
  }

  @override
  Future<PageResponse<UserProfileModel>> getBlocked({int page = 0}) async =>
      _singlePage([]);

  @override
  Future<PageResponse<UserProfileModel>> getMuted({int page = 0}) async =>
      _singlePage([]);
}

class _MockCommentRepository extends CommentRepository {
  _MockCommentRepository(super.remoteDatasource);

  @override
  Future<CommentPage> fetchComments(String videoId, {String? cursor}) async {
    await _latency();
    return _commentPage(videoId, cursor);
  }

  /// Two replies under the first comment of every video, enough to open a
  /// thread offline.
  @override
  Future<CommentPage> fetchReplies(
    String videoId,
    String parentId, {
    String? cursor,
  }) async {
    await _latency();
    final items = parentId == '$videoId-c0' && cursor == null
        ? [
            for (var i = 0; i < _mockReplyCount; i++)
              CommentModel(
                id: '$parentId-r$i',
                videoId: videoId,
                userId: '${7200 + i}',
                text: _texts[(i * 5) % _texts.length],
                parentId: parentId,
                createdAt: DateTime(2026, 8, 14, 12 + i),
              ),
          ]
        : <CommentModel>[];
    return CommentPage(items: items, hasMore: false, nextCursor: null);
  }

  @override
  Future<CommentModel> postComment(
    String videoId,
    String text, {
    String? parentId,
    String? stickerId,
  }) async {
    await _latency();
    // The server flattens a reply to a reply onto its thread.
    final threadId = parentId?.replaceFirst(RegExp(r'-r\d+$'), '');
    return CommentModel(
      id: '$videoId-new-${DateTime.now().microsecondsSinceEpoch}',
      videoId: videoId,
      userId: _meId,
      text: text,
      parentId: threadId,
      sticker: stickerId == null
          ? null
          : CommentSticker(
              stickerId: stickerId,
              url: 'https://picsum.photos/seed/$stickerId/160',
              width: 160,
              height: 160,
            ),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CommentModel> editComment(
    String videoId,
    String commentId,
    String text,
  ) async {
    await _latency();
    return CommentModel(
      id: commentId,
      videoId: videoId,
      userId: _meId,
      text: text,
      createdAt: DateTime.now(),
      editedAt: DateTime.now(),
    );
  }

  @override
  Future<List<StickerPack>> listStickerPacks() async => const [];

  /// The offline catalogue's comments all start at zero likes, so the tally
  /// after one tap is exactly one.
  @override
  Future<CommentLikeResult> likeComment(
    String videoId,
    String commentId,
  ) async {
    await _latency();
    return const CommentLikeResult(liked: true, likeCount: 1);
  }

  @override
  Future<CommentLikeResult> unlikeComment(
    String videoId,
    String commentId,
  ) async {
    await _latency();
    return const CommentLikeResult(liked: false, likeCount: 0);
  }

  @override
  Future<void> deleteComment(String videoId, String commentId) => _latency();

  @override
  Future<void> removeCommentAsAdmin(
    String videoId,
    String commentId,
    String reason,
  ) => _latency();

  @override
  Future<void> reportComment(String videoId, String commentId, String reason) =>
      _latency();
}

/// Offline search. The mock catalogue carries no `tags` field, so a hashtag
/// is matched against the caption text the same way a free-text query is —
/// enough to exercise the chips, unlike the server where a tag is an exact
/// keyword match.
class _MockSearchRepository extends SearchRepository {
  _MockSearchRepository(super.remoteDatasource);

  @override
  Future<SearchIdPage> searchVideos({
    String? query,
    String? hashtag,
    int page = 0,
    int size = 24,
  }) async {
    await _latency();
    // One page then done, like the other mock listings.
    if (page > 0) return const SearchIdPage(ids: [], last: true);
    bool matches(VideoModel v, String term) {
      final haystack = '${v.title} ${v.description ?? ''}'.toLowerCase();
      return haystack.contains(term.toLowerCase());
    }

    return SearchIdPage(
      ids: [
        for (final v in _videos)
          if (v.status == VideoStatus.published &&
              v.visibility == VideoVisibility.public &&
              (query == null || matches(v, query)) &&
              (hashtag == null || matches(v, hashtag)))
            v.id,
      ],
      last: true,
    );
  }
}

/// Offline inbox. Holds the rows in memory so marking one read survives a tab
/// switch, the way the real service does.
class _MockNotificationRepository extends NotificationRepository {
  _MockNotificationRepository(super.remoteDatasource);

  final _rows = <NotificationModel>[
    NotificationModel(
      id: 'n1',
      type: NotificationKind.like,
      title: 'Benri Studio',
      body: 'liked your video',
      referenceId: 'v1',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'n2',
      type: NotificationKind.comment,
      title: 'Hà Noodles',
      body: 'commented: "công thức ở đâu vậy bạn"',
      referenceId: 'c1',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    NotificationModel(
      id: 'n3',
      type: NotificationKind.newFollower,
      title: 'Long An Daily',
      body: 'started following you',
      referenceId: '6006',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'n4',
      type: NotificationKind.system,
      title: 'Welcome to TikTok!',
      body: 'Hi mihhuq1223, thanks for joining us.',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  Future<List<NotificationModel>> list() async {
    await _latency();
    return List.unmodifiable(_rows);
  }

  @override
  Future<int> unreadCount() async {
    await _latency();
    return _rows.where((n) => !n.read).length;
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _latency();
    final index = _rows.indexWhere((n) => n.id == notificationId);
    if (index != -1) _rows[index] = _rows[index].copyWith(read: true);
  }

  @override
  Future<void> markAllRead() async {
    await _latency();
    for (var i = 0; i < _rows.length; i++) {
      _rows[i] = _rows[i].copyWith(read: true);
    }
  }
}

/// Offline chat. One thread with one other person, kept in memory so a sent
/// message survives leaving the screen. No socket: [liveMessages] is an empty
/// stream, and the thread still shows what it sends because the send path adds
/// the server's copy itself.
class _MockChatRepository extends ChatRepository {
  _MockChatRepository(super.remoteDatasource, super.socket);

  static const _conversationId = 'conv1';
  static const _otherId = '2002';

  final _messages = <MessageModel>[
    MessageModel(
      id: 'm2',
      conversationId: _conversationId,
      senderId: _otherId,
      content: 'quay ở đâu vậy bro',
      sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    MessageModel(
      id: 'm1',
      conversationId: _conversationId,
      senderId: _meId,
      content: 'clip mới lên rồi nha',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  Future<List<ConversationModel>> listConversations() async {
    await _latency();
    return [
      ConversationModel(
        id: _conversationId,
        participantIds: const [_meId, _otherId],
        lastMessageContent: _messages.first.content,
        lastMessageSenderId: _messages.first.senderId,
        lastMessageAt: _messages.first.sentAt,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        hasUnread: _messages.first.senderId != _meId,
        muteMode: _muteMode,
        mutedUntil: _mutedUntil,
        pinnedAt: _pinnedAt,
      ),
    ];
  }

  // Offline nobody new writes in, so the request box stays empty.
  @override
  Future<List<ConversationModel>> listRequests() async => const [];

  @override
  Future<ConversationModel> acceptRequest(String conversationId) async =>
      (await listConversations()).first;

  @override
  Future<ConversationModel> declineRequest(String conversationId) async =>
      (await listConversations()).first;

  @override
  Future<ConversationModel> openConversation(String participantId) async =>
      (await listConversations()).first;

  @override
  Future<ConversationModel> getConversation(String conversationId) async =>
      (await listConversations()).first;

  @override
  Future<MessagePage> listMessages(
    String conversationId, {
    String? cursor,
    int size = 30,
  }) async {
    await _latency();
    // One page then done — hasMore is the only stop condition.
    if (cursor != null) {
      return const MessagePage(items: [], hasMore: false);
    }
    return MessagePage(items: List.unmodifiable(_messages), hasMore: false);
  }

  @override
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    String? clientRequestId,
  }) async {
    await _latency();
    final message = MessageModel(
      id: 'm${_messages.length + 1}',
      conversationId: conversationId,
      senderId: _meId,
      content: content,
      sentAt: DateTime.now(),
    );
    _messages.insert(0, message);
    return message;
  }

  @override
  Future<MessageModel> sendStoryReply({
    required String storyId,
    required String content,
    required String clientRequestId,
  }) async {
    await _latency();
    final message = MessageModel(
      id: 'm${_messages.length + 1}',
      conversationId: _conversationId,
      senderId: _meId,
      content: content,
      sentAt: DateTime.now(),
      type: MessageType.storyReply,
    );
    _messages.insert(0, message);
    return message;
  }

  @override
  Future<void> markRead(String conversationId, {String? messageId}) async {}

  @override
  Future<void> markDelivered(
    String conversationId,
    List<String> messageIds,
  ) async {}

  // Offline the other person never reads anything: everything sent stays
  // "Sent", and so can always be taken back.
  @override
  Future<ReceiptView> receipts(String conversationId) async =>
      ReceiptView(conversationId: conversationId, userId: _otherId);

  @override
  Future<MessageUpdate> recall(String conversationId, String messageId) async {
    await _latency();
    final at = _messages.indexWhere((m) => m.id == messageId);
    final update = MessageUpdate(
      messageId: messageId,
      conversationId: conversationId,
      revision: (at < 0 ? 0 : _messages[at].revision) + 1,
      recalledAt: DateTime.now(),
    );
    if (at >= 0) _messages[at] = _messages[at].applying(update);
    return update;
  }

  @override
  Future<void> hide(String conversationId, String messageId) async {
    await _latency();
    _messages.removeWhere((m) => m.id == messageId);
  }

  MuteMode _muteMode = MuteMode.none;
  DateTime? _mutedUntil;

  @override
  Future<ConversationModel> mute(
    String conversationId,
    MuteLength length,
  ) async {
    await _latency();
    final span = switch (length) {
      MuteLength.oneHour => const Duration(hours: 1),
      MuteLength.eightHours => const Duration(hours: 8),
      MuteLength.oneDay => const Duration(hours: 24),
      MuteLength.indefinite => null,
    };
    _muteMode = span == null ? MuteMode.indefinite : MuteMode.timed;
    _mutedUntil = span == null ? null : DateTime.now().add(span);
    return (await listConversations()).first;
  }

  @override
  Future<ConversationModel> unmute(String conversationId) async {
    _muteMode = MuteMode.none;
    _mutedUntil = null;
    return (await listConversations()).first;
  }

  DateTime? _pinnedAt;

  @override
  Future<ConversationModel> pin(String conversationId) async {
    _pinnedAt ??= DateTime.now();
    return (await listConversations()).first;
  }

  @override
  Future<ConversationModel> unpin(String conversationId) async {
    _pinnedAt = null;
    return (await listConversations()).first;
  }

  @override
  Future<void> reportConversation({
    required String conversationId,
    required String reason,
    required List<String> messageIds,
    required String requestId,
  }) => _latency();

  @override
  Stream<MessageModel> liveMessages(String conversationId) =>
      const Stream.empty();

  @override
  Stream<ChatInboxEvent> inboxEvents() => const Stream.empty();

  // Offline there is no sticker bucket to draw from, so the picker is empty
  // and pictures stay on the device: the upload is remembered in memory and
  // the message draws from it.
  final _uploads = <String, Uint8List>{};

  @override
  Future<List<StickerPack>> listStickerPacks() async => const [];

  @override
  Future<ChatImageModel> uploadImage(
    String conversationId, {
    required List<int> bytes,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    await _latency();
    onProgress?.call(bytes.length, bytes.length);
    final id = 'img${_uploads.length + 1}';
    _uploads[id] = Uint8List.fromList(bytes);
    return ChatImageModel(imageId: id, url: '/mock/$id');
  }

  @override
  Future<MessageModel> sendImage(
    String conversationId,
    String imageId, {
    String? caption,
    required String clientRequestId,
  }) async {
    await _latency();
    final message = MessageModel(
      id: 'm${_messages.length + 1}',
      conversationId: conversationId,
      senderId: _meId,
      content: caption ?? '',
      sentAt: DateTime.now(),
      type: MessageType.image,
      image: ChatImageModel(imageId: imageId, url: '/mock/$imageId'),
    );
    _messages.insert(0, message);
    return message;
  }

  @override
  Future<Uint8List> imageBytes(ChatImageModel image) async =>
      _uploads[image.imageId] ?? Uint8List(0);

  @override
  void rememberImage(String imageId, Uint8List bytes) {}
}

/// Stories kept in memory. A posted story goes live at once — there is no
/// moderation offline — and plays from the file on the device.
class _MockStoryRepository extends StoryRepository {
  _MockStoryRepository(super.remoteDatasource);

  static StoryModel _story(
    String id,
    String userId,
    String url, {
    StoryMediaType type = StoryMediaType.image,
    String? caption,
    required Duration age,
  }) {
    final created = DateTime.now().subtract(age);
    return StoryModel(
      id: id,
      userId: userId,
      mediaUrl: url,
      mediaType: type,
      caption: caption,
      visibility: StoryVisibility.public,
      createdAt: created,
      expiresAt: created.add(const Duration(hours: 24)),
    );
  }

  final _stories = <StoryModel>[
    _story(
      's1',
      '2002',
      'https://picsum.photos/id/1011/1080/1920',
      caption: 'sáng nay ở Đà Lạt ☁️',
      age: const Duration(hours: 5),
    ),
    _story(
      's2',
      '2002',
      'https://picsum.photos/id/1015/1080/1920',
      age: const Duration(hours: 2),
    ),
    _story(
      's3',
      '3003',
      'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      type: StoryMediaType.video,
      caption: 'cuối tuần 🔥',
      age: const Duration(hours: 1),
    ),
    _story(
      's4',
      '4004',
      'https://picsum.photos/id/40/1080/1920',
      caption: 'mèo nhà ai đây',
      age: const Duration(minutes: 30),
    ),
  ];
  final _reactions = <String, StoryReaction>{};
  final _viewed = <String>{};

  StoryModel _forMe(StoryModel s) => s.userId == _meId
      ? s.copyWith(
          status: s.status ?? StoryStatus.active,
          // Matches the two rows [viewers] answers with.
          viewCount: 2,
          reactionCounts: const {StoryReaction.love: 1},
        )
      : s.copyWith(
          viewedByMe: _viewed.contains(s.id),
          myReaction: _reactions[s.id],
        );

  @override
  Future<StoryModel> uploadAndCreate({
    required File file,
    required String contentType,
    VideoEdit? edit,
    double? photoSeconds,
    String? caption,
    required StoryVisibility visibility,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final size = await file.length();
    for (var sent = 0; sent <= size; sent += (size ~/ 5).clamp(1, size + 1)) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      onProgress?.call(sent, size);
    }
    onProgress?.call(size, size);
    final created = DateTime.now();
    final story = StoryModel(
      id: 'mine${_stories.length + 1}',
      userId: _meId,
      mediaUrl: Uri.file(file.path).toString(),
      mediaType: isVideoContentType(contentType)
          ? StoryMediaType.video
          : StoryMediaType.image,
      caption: caption,
      visibility: visibility,
      status: StoryStatus.active,
      viewCount: 0,
      createdAt: created,
      expiresAt: created.add(const Duration(hours: 24)),
    );
    _stories.add(story);
    return story;
  }

  @override
  Future<List<StoryGroup>> feed(List<String> followedUserIds) async {
    await _latency();
    final byUser = <String, List<StoryModel>>{};
    for (final s in _stories) {
      byUser.putIfAbsent(s.userId, () => []).add(_forMe(s));
    }
    final groups = [
      for (final e in byUser.entries)
        StoryGroup(
          userId: e.key,
          stories: e.value,
          hasUnseen: e.key != _meId && e.value.any((s) => !s.viewedByMe),
        ),
    ];
    // Own first, then unseen, as the real service orders them.
    groups.sort((a, b) {
      if (a.userId == _meId) return -1;
      if (b.userId == _meId) return 1;
      return (b.hasUnseen ? 1 : 0) - (a.hasUnseen ? 1 : 0);
    });
    return groups;
  }

  @override
  Future<List<StoryRing>> rings(List<String> userIds) async {
    final groups = await feed(const []);
    return [
      for (final g in groups)
        if (userIds.contains(g.userId))
          StoryRing(
            userId: g.userId,
            hasUnseen: g.userId == _meId || g.hasUnseen,
          ),
    ];
  }

  @override
  Future<List<StoryModel>> userStories(String userId) async {
    await _latency();
    return [
      for (final s in _stories)
        if (s.userId == userId) _forMe(s),
    ];
  }

  @override
  Future<void> recordView(String storyId) async => _viewed.add(storyId);

  @override
  Future<List<StoryViewer>> viewers(String storyId, {DateTime? before}) async {
    await _latency();
    if (before != null) return const [];
    return [
      StoryViewer(
        viewerId: '2002',
        viewedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        reaction: StoryReaction.love,
      ),
      StoryViewer(
        viewerId: '3003',
        viewedAt: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
    ];
  }

  @override
  Future<void> setReaction(String storyId, StoryReaction reaction) async {
    _viewed.add(storyId);
    _reactions[storyId] = reaction;
  }

  @override
  Future<void> clearReaction(String storyId) async =>
      _reactions.remove(storyId);

  @override
  Future<StoryModel> updateVisibility(
    String storyId,
    StoryVisibility visibility,
  ) async {
    final index = _stories.indexWhere((s) => s.id == storyId);
    _stories[index] = _stories[index].copyWith(visibility: visibility);
    return _forMe(_stories[index]);
  }

  @override
  Future<void> delete(String storyId) async =>
      _stories.removeWhere((s) => s.id == storyId);
}

/// Settings, filter keywords and screen time kept in memory. The week is
/// made up, so the summary chart has something to draw offline.
class _MockSettingsRepository extends SettingsRepository {
  _MockSettingsRepository(super.remoteDatasource);

  var _settings = const UserSettings();
  final _filters = <KeywordFilter>[
    const KeywordFilter(id: '1', keyword: 'spoiler', following: false),
  ];
  var _nextFilterId = 2;
  String? _passcode;

  @override
  Future<UserSettings> getSettings() async {
    await _latency();
    return _settings;
  }

  @override
  Future<UserSettings> updateSettings(Map<String, dynamic> changes) async {
    await _latency();
    final json = {..._settings.toJson(), ...changes}
      ..remove('screenTimePasscode');
    if (changes.containsKey('screenTimePasscode')) {
      _passcode = changes['screenTimePasscode'] as String;
    }
    final limitOn =
        json['screenTimeLimitMinutes'] != null ||
        json['screenTimeLimitsByDay'] != null;
    if (!limitOn) _passcode = null;
    final start = json['sleepHoursStart'] as String?;
    if (start != null) {
      final h = (int.parse(start.split(':')[0]) + 8) % 24;
      json['sleepHoursEnd'] =
          '${h.toString().padLeft(2, '0')}:${start.split(':')[1]}';
    } else {
      json['sleepHoursEnd'] = null;
    }
    json['hasScreenTimePasscode'] = _passcode != null;
    _settings = UserSettings.fromJson(json);
    return _settings;
  }

  @override
  Future<List<KeywordFilter>> listKeywordFilters() async {
    await _latency();
    return List.of(_filters);
  }

  @override
  Future<KeywordFilter> createKeywordFilter({
    required String keyword,
    required bool forYou,
    required bool following,
    required bool friends,
  }) async {
    final filter = KeywordFilter(
      id: '${_nextFilterId++}',
      keyword: keyword,
      forYou: forYou,
      following: following,
      friends: friends,
    );
    _filters.insert(0, filter);
    return filter;
  }

  @override
  Future<KeywordFilter> updateKeywordFilter(KeywordFilter filter) async {
    final i = _filters.indexWhere((f) => f.id == filter.id);
    if (i >= 0) _filters[i] = filter;
    return filter;
  }

  @override
  Future<void> deleteKeywordFilter(String id) async =>
      _filters.removeWhere((f) => f.id == id);

  @override
  Future<void> sendScreenTimeHeartbeat(int seconds, String timeZone) async {}

  @override
  Future<ScreenTimeWeek> getScreenTimeWeek(String weekStart) async {
    await _latency();
    final monday = DateTime.parse(weekStart);
    return ScreenTimeWeek(
      weekStart: weekStart,
      days: [
        for (var i = 0; i < 7; i++)
          ScreenTimeDay(
            date: DateTime(
              monday.year,
              monday.month,
              monday.day + i,
            ).toIso8601String().substring(0, 10),
            daySeconds: 600 + i * 420,
            nightSeconds: 120 * (i % 3),
          ),
      ],
    );
  }

  @override
  Future<bool> verifyScreenTimePasscode(String passcode) async =>
      passcode == _passcode;
}

/// Nowa Studio offline: numbers made up from the mock catalogue, so every
/// Studio screen has something to draw. Deterministic, so screenshots and
/// tests see the same figures each run.
class _MockStudioRepository extends StudioRepository {
  _MockStudioRepository(super.remoteDatasource, this._feed);

  final _MockFeedRepository _feed;

  List<VideoModel> get _mine => [
        for (final v in _feed._live)
          if (v.userId == _meId) v,
      ];

  List<CreatorDailyStats> _daily(int days, int seed) {
    final today = DateTime(2026, 11, 7);
    String two(int n) => n.toString().padLeft(2, '0');
    return [
      for (var i = days - 1; i >= 0; i--)
        _day(today.subtract(Duration(days: i)), (seed + i * 7) % 11, two),
    ];
  }

  CreatorDailyStats _day(DateTime day, int wave, String Function(int) two) =>
      CreatorDailyStats(
        day: '${day.year}-${two(day.month)}-${two(day.day)}',
        views: 40 + wave * 13,
        likes: 6 + wave * 2,
        comments: wave ~/ 2,
        shares: wave ~/ 3,
        saves: wave ~/ 4,
        followersGained: wave ~/ 3,
        followersLost: wave ~/ 9,
      );

  CreatorTotals _sum(List<CreatorDailyStats> days) => CreatorTotals(
        views: days.fold(0, (s, d) => s + d.views),
        likes: days.fold(0, (s, d) => s + d.likes),
        comments: days.fold(0, (s, d) => s + d.comments),
        shares: days.fold(0, (s, d) => s + d.shares),
        saves: days.fold(0, (s, d) => s + d.saves),
        netFollowers:
            days.fold(0, (s, d) => s + d.followersGained - d.followersLost),
      );

  @override
  Future<CreatorOverview> getOverview(int days) async {
    await _latency();
    final current = _daily(days, 3);
    return CreatorOverview(
      current: _sum(current),
      previous: _sum(_daily(days, 5)),
      daily: current,
    );
  }

  @override
  Future<List<CreatorVideoStats>> getTopVideos(
    int days,
    CreatorVideoSort sort, {
    int limit = 10,
  }) async {
    await _latency();
    final rows = [
      for (final (i, v) in _mine.indexed)
        CreatorVideoStats(
          videoId: v.id,
          views: v.viewCount ~/ 4 + days * (i + 1),
          viewers: v.viewCount ~/ 6 + days,
          newViewers: v.viewCount ~/ 20 + i,
          likes: v.likeCount ~/ 4,
          comments: v.commentCount ~/ 4,
          shares: i * 3,
          saves: i * 2,
        ),
    ];
    int key(CreatorVideoStats r) => switch (sort) {
          CreatorVideoSort.views => r.views,
          CreatorVideoSort.viewers => r.viewers,
          CreatorVideoSort.newViewers => r.newViewers,
          CreatorVideoSort.likes => r.likes,
          CreatorVideoSort.comments => r.comments,
          CreatorVideoSort.shares => r.shares,
        };
    rows.sort((a, b) => key(b).compareTo(key(a)));
    return rows.take(limit).toList();
  }

  @override
  Future<CreatorVideoDetail> getVideoDetail(String videoId, int days) async {
    await _latency();
    final daily = _daily(days, videoId.hashCode % 7);
    final current = _sum(daily);
    final previous = _sum(_daily(days, 1));
    CreatorVideoTotals totals(CreatorTotals t) => CreatorVideoTotals(
          views: t.views,
          likes: t.likes,
          comments: t.comments,
          shares: t.shares,
          saves: t.saves,
          newFollowers: t.netFollowers,
        );
    return CreatorVideoDetail(
      videoId: videoId,
      views: current.views * 3,
      viewers: current.views * 2,
      totalWatchMs: current.views * 3 * 6400,
      avgWatchMs: 6400,
      completionRate: 0.38,
      likes: current.likes * 3,
      comments: current.comments * 3,
      shares: current.shares * 3,
      saves: current.saves * 3,
      newFollowers: current.netFollowers,
      // A steady fall with one sharp drop at 20%, the hook that lost people.
      retention: [
        for (var i = 0; i <= 20; i++)
          i == 0 ? 1.0 : 0.95 - i * 0.025 - (i >= 4 ? 0.15 : 0),
      ],
      daily: daily,
      current: totals(current),
      previous: totals(previous),
      trafficSources: const [
        TrafficSourceRow(source: TrafficSource.forYou, views: 320),
        TrafficSourceRow(source: TrafficSource.following, views: 74),
        TrafficSourceRow(source: TrafficSource.search, views: 41),
        TrafficSourceRow(source: TrafficSource.profile, views: 22),
      ],
      searchQueries: const [
        SearchQueryRow(query: 'street food', views: 18),
        SearchQueryRow(query: 'saigon night', views: 9),
      ],
      audience: const CreatorVideoViewers(
        total: 240,
        newViewers: 90,
        previousTotal: 180,
        previousNewViewers: 60,
        breakdownAvailable: true,
        returning: 150,
        followers: 70,
        nonFollowers: 170,
        ageGroups: {
          '13-17': 12,
          '18-24': 110,
          '25-34': 70,
          '35-44': 20,
          '45-54': 6,
          '55+': 0,
          'UNKNOWN': 22,
        },
      ),
    );
  }

  @override
  Future<CreatorViewers> getViewers(int days) async {
    await _latency();
    return CreatorViewers(
      totalViewers: 60 * days,
      newViewers: 18 * days,
      previousTotalViewers: 52 * days,
      previousNewViewers: 20 * days,
      breakdownAvailable: true,
      activeHours: [
        for (var h = 0; h < 24; h++) (h >= 18 ? 40 : 8) + (h * 7) % 13,
      ],
      activeDays: const [30, 26, 28, 35, 44, 58, 51],
    );
  }

  @override
  Future<PageResponse<VideoModel>> listMyVideos(
    StudioPostQuery query, {
    int page = 0,
    int size = 20,
  }) async {
    await _latency();
    final q = query.q.trim().toLowerCase();
    final rows = [
      for (final v in _mine)
        if (q.isEmpty || v.title.toLowerCase().contains(q))
          if (query.visibilities.isEmpty ||
              query.visibilities.contains(v.visibility.name.toUpperCase()))
            v,
    ];
    int key(VideoModel v) => switch (query.sort) {
          StudioPostSort.newest => v.createdAt.millisecondsSinceEpoch,
          StudioPostSort.views => v.viewCount,
          StudioPostSort.likes => v.likeCount,
          StudioPostSort.comments => v.commentCount,
        };
    rows.sort((a, b) =>
        query.descending ? key(b).compareTo(key(a)) : key(a).compareTo(key(b)));
    return PageResponse(
      content: rows.skip(page * size).take(size).toList(),
      size: size,
      number: page,
      totalElements: rows.length,
      totalPages: rows.isEmpty ? 1 : (rows.length / size).ceil(),
    );
  }

  @override
  Future<VideoModel> updateCaption(
    String videoId, {
    required String title,
    String? description,
  }) async {
    await _latency();
    return _feed._edit(
      videoId,
      (v) => v.copyWith(title: title, description: description),
    );
  }

  @override
  Future<VideoModel> setPinned(String videoId, bool pinned) =>
      _feed.setPinned(videoId, pinned);

  /// Every fifth comment comes back held, so the review queue has rows.
  @override
  Future<CommentPage> listInbox(
    InboxQuery query, {
    String? cursor,
    int size = 20,
  }) async {
    await _latency();
    if (cursor != null) return const CommentPage(items: [], hasMore: false);
    final videos = query.videoId != null
        ? [query.videoId!]
        : [for (final v in _mine) v.id];
    final q = query.q.trim().toLowerCase();
    final items = [
      for (final id in videos)
        for (final c in _commentPage(id, null).items)
          if (q.isEmpty || c.text.toLowerCase().contains(q)) c,
    ];
    final shaped = [
      for (final (i, c) in items.indexed)
        if (!query.heldOnly || i % 5 == 0)
          i % 5 == 0 ? c.copyWith(status: CommentStatus.held) : c,
    ];
    return CommentPage(items: shaped.take(size).toList(), hasMore: false);
  }

  @override
  Future<void> approveComment(String videoId, String commentId) => _latency();
}

/// Ids of the signed-in mock account's own videos, for tests that open one in
/// Studio.
List<String> get mockMyVideoIds => [
      for (final v in _videos)
        if (v.userId == _meId) v.id,
    ];

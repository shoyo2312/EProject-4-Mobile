import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
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
    saveCount: 29970,
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
    saveCount: 1140,
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
    saveCount: 88,
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
    saveCount: 12400,
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
    saveCount: 61000,
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
    saveCount: 2997,
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
    saveCount: 1140,
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
    saveCount: 6100,
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
    saveCount: 3410,
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
    saveCount: 920,
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
    saveCount: 15600,
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
    saveCount: 7300,
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
    saveCount: 210,
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

const _replyTexts = [
  'chuẩn luôn bà ơi',
  'giống mình ghê',
  'hahaha đúng rồi',
  'cho xin info với',
  'mình cũng nghĩ vậy',
  'thôi xin can 😅',
];

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Hand-written threads carried over from the design mock, used for the first
/// page of every video so the reply UI has something readable to show. Anything
/// past these falls through to [_comment].
final _seedThreads = <({
  String who,
  String text,
  int likes,
  int hoursAgo,
  List<({String who, String text, int likes, int hoursAgo})> replies,
})>[
  (
    who: 'thao.ng',
    text: 'cái kiểu nó đứng dậy như người thật á, chịu không nổi',
    likes: 1200,
    hoursAgo: 2,
    replies: [
      (who: 'benri', text: 'lmao y chang, coi lại chỉ vì đoạn đó', likes: 44, hoursAgo: 1),
      (who: 'minhquan', text: 'nó kiểu "tôi dậy rồi nè"', likes: 12, hoursAgo: 1),
      (who: 'Lan Chi', text: 'xem 3 lần vẫn cười 😂', likes: 8, hoursAgo: 1),
    ],
  ),
  (
    who: 'benri',
    text: 'tối nào nó cũng làm vậy tầm 9h, đúng giờ luôn',
    likes: 840,
    hoursAgo: 2,
    replies: [
      (who: 'thao.ng', text: 'đồng hồ sinh học xịn ghê', likes: 61, hoursAgo: 2),
      (who: 'kurua', text: 'cho xin lịch trình của bé với', likes: 9, hoursAgo: 1),
    ],
  ),
  (
    who: 'minhquan',
    text: 'máy chiếu gì vậy ạ, phòng nhìn đẹp quá trời',
    likes: 96,
    hoursAgo: 1,
    replies: [],
  ),
  (
    who: 'lan.pham',
    text: 'gửi cái này cho con mèo nhà mình học cách cư xử',
    likes: 312,
    hoursAgo: 1,
    replies: [
      (who: 'kurua', text: 'có tác dụng không 😭', likes: 5, hoursAgo: 1),
      (who: 'lan.pham', text: 'nó nhìn xong rồi bỏ đi', likes: 27, hoursAgo: 1),
    ],
  ),
  (
    who: 'kurua',
    text: 'làm phần 2 đi ạ, phải xem sau đó ra sao chứ',
    likes: 58,
    hoursAgo: 1,
    replies: [
      (who: 'Huyền 🍀', text: 'hóng phần 2', likes: 3, hoursAgo: 1),
    ],
  ),
];

/// Deterministic per (video, index) so paging back and forth is stable.
CommentModel _comment(String videoId, int index) {
  if (index < _seedThreads.length) return _seedComment(videoId, index);
  final rnd = Random(videoId.hashCode * 31 + index);
  // Roughly every other comment is a thread, some of them long ones.
  final replyCount = index.isEven ? 1 + rnd.nextInt(300) : 0;
  // Only the first few replies come down with the parent, same as the real
  // thing — the rest sit behind "View N replies".
  final loaded = min(replyCount, 5);
  return CommentModel(
    id: '$videoId-c$index',
    videoId: videoId,
    userId: '${9000 + index % 12}',
    username: _usernames[index % _usernames.length],
    avatarUrl: 'https://i.pravatar.cc/100?img=${index % 70 + 1}',
    text: _texts[(index * 7) % _texts.length],
    createdAt: DateTime(2026, 8, 1).add(Duration(hours: index * 3)),
    likeCount: rnd.nextInt(42000),
    replyCount: replyCount,
    replies: [
      for (var r = 0; r < loaded; r++)
        CommentModel(
          id: '$videoId-c$index-r$r',
          videoId: videoId,
          userId: '${8000 + r}',
          username: _usernames[(index + r + 3) % _usernames.length],
          avatarUrl: 'https://i.pravatar.cc/100?img=${(index + r * 5) % 70 + 1}',
          text: _replyTexts[(index + r) % _replyTexts.length],
          createdAt:
              DateTime(2026, 8, 1).add(Duration(hours: index * 3 + r + 1)),
          likeCount: rnd.nextInt(300),
        ),
    ],
  );
}

CommentModel _seedComment(String videoId, int index) {
  final seed = _seedThreads[index];
  final now = DateTime(2026, 8, 14, 11);
  return CommentModel(
    id: '$videoId-c$index',
    videoId: videoId,
    userId: '${7100 + index}',
    username: seed.who,
    avatarUrl: 'https://i.pravatar.cc/100?img=${index * 7 + 3}',
    text: seed.text,
    createdAt: now.subtract(Duration(hours: seed.hoursAgo)),
    likeCount: seed.likes,
    // Every reply of a seeded thread ships with the parent, so "View N
    // replies" always unfolds to exactly N rows.
    replyCount: seed.replies.length,
    replies: [
      for (var r = 0; r < seed.replies.length; r++)
        CommentModel(
          id: '$videoId-c$index-r$r',
          videoId: videoId,
          userId: '${7200 + index * 10 + r}',
          username: seed.replies[r].who,
          avatarUrl: 'https://i.pravatar.cc/100?img=${index * 7 + r + 20}',
          text: seed.replies[r].text,
          createdAt: now.subtract(Duration(hours: seed.replies[r].hoursAgo)),
          likeCount: seed.replies[r].likes,
        ),
    ],
  );
}

/// Cursor is just the offset — 20 comments a page, up to the video's total.
CommentPage _commentPage(String videoId, String? cursor) {
  final total = _videos
      .firstWhere((v) => v.id == videoId, orElse: () => _videos.first)
      .commentCount;
  final offset = int.tryParse(cursor ?? '0') ?? 0;
  final end = min(offset + 20, total);
  return CommentPage(
    items: [for (var i = offset; i < end; i++) _comment(videoId, i)],
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

UserProfileModel _profile(String userId) =>
    _profiles[userId] ??
    UserProfileModel(
      userId: userId,
      displayName: 'user_$userId',
      followerCount: 0,
      followingCount: 0,
    );

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
  Future<void> logout() async => state = const AsyncData(null);
}

class _MockFeedRepository extends FeedRepository {
  _MockFeedRepository(super.remoteDatasource);

  final _deleted = <String>{};

  List<VideoModel> get _live => [
        for (final v in _videos)
          if (!_deleted.contains(v.id)) v,
      ];

  @override
  Future<PageResponse<VideoModel>> fetchFeed({int page = 0, int size = 20}) async {
    await _latency();
    if (page > 0) return _emptyPage();
    return _singlePage([
      for (final v in _live)
        if (v.status == VideoStatus.published &&
            v.visibility == VideoVisibility.public)
          v,
    ]);
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
    return _singlePage([
      for (final v in _live)
        if (v.userId == userId &&
            (own ||
                (v.status == VideoStatus.published &&
                    v.visibility == VideoVisibility.public)))
          v,
    ]);
  }

  @override
  Future<VideoModel> getVideo(String videoId) async =>
      _live.firstWhere((v) => v.id == videoId);

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
    );
    return _mine;
  }

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    await _latency();
    return userId == _meId ? _mine : _profile(userId);
  }

  @override
  Future<void> follow(String userId) async {}

  @override
  Future<void> unfollow(String userId) async {}

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
  }) async =>
      _singlePage(page > 0 ? [] : _profiles.values.toList());

  @override
  Future<PageResponse<UserProfileModel>> getFollowing(
    String userId, {
    int page = 0,
  }) async =>
      _singlePage(page > 0 ? [] : _profiles.values.toList());

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

  @override
  Future<CommentModel> postComment(String videoId, String text) async {
    await _latency();
    return CommentModel(
      id: '$videoId-new-${DateTime.now().microsecondsSinceEpoch}',
      videoId: videoId,
      userId: _meId,
      username: _me.username,
      avatarUrl: _profiles[_meId]!.avatarUrl,
      text: text,
      createdAt: DateTime.now(),
    );
  }
}

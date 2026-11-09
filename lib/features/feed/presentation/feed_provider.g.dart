// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedRepositoryHash() => r'8668a2e4c1d428980ace2623cae5b5b8f9c12086';

/// See also [feedRepository].
@ProviderFor(feedRepository)
final feedRepositoryProvider = Provider<FeedRepository>.internal(
  feedRepository,
  name: r'feedRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRepositoryRef = ProviderRef<FeedRepository>;
String _$videoByIdHash() => r'f9b47f40726f7559e510d93a1ec33eef0b7c8d58';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// One video by id, for a link that names nothing else — a notification
/// about a comment on it, say.
///
/// Copied from [videoById].
@ProviderFor(videoById)
const videoByIdProvider = VideoByIdFamily();

/// One video by id, for a link that names nothing else — a notification
/// about a comment on it, say.
///
/// Copied from [videoById].
class VideoByIdFamily extends Family<AsyncValue<VideoModel>> {
  /// One video by id, for a link that names nothing else — a notification
  /// about a comment on it, say.
  ///
  /// Copied from [videoById].
  const VideoByIdFamily();

  /// One video by id, for a link that names nothing else — a notification
  /// about a comment on it, say.
  ///
  /// Copied from [videoById].
  VideoByIdProvider call(String videoId) {
    return VideoByIdProvider(videoId);
  }

  @override
  VideoByIdProvider getProviderOverride(covariant VideoByIdProvider provider) {
    return call(provider.videoId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'videoByIdProvider';
}

/// One video by id, for a link that names nothing else — a notification
/// about a comment on it, say.
///
/// Copied from [videoById].
class VideoByIdProvider extends AutoDisposeFutureProvider<VideoModel> {
  /// One video by id, for a link that names nothing else — a notification
  /// about a comment on it, say.
  ///
  /// Copied from [videoById].
  VideoByIdProvider(String videoId)
    : this._internal(
        (ref) => videoById(ref as VideoByIdRef, videoId),
        from: videoByIdProvider,
        name: r'videoByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$videoByIdHash,
        dependencies: VideoByIdFamily._dependencies,
        allTransitiveDependencies: VideoByIdFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  VideoByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.videoId,
  }) : super.internal();

  final String videoId;

  @override
  Override overrideWith(
    FutureOr<VideoModel> Function(VideoByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VideoByIdProvider._internal(
        (ref) => create(ref as VideoByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        videoId: videoId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<VideoModel> createElement() {
    return _VideoByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoByIdProvider && other.videoId == videoId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, videoId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VideoByIdRef on AutoDisposeFutureProviderRef<VideoModel> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _VideoByIdProviderElement
    extends AutoDisposeFutureProviderElement<VideoModel>
    with VideoByIdRef {
  _VideoByIdProviderElement(super.provider);

  @override
  String get videoId => (origin as VideoByIdProvider).videoId;
}

String _$videoEditorHash() => r'c44436ba2c63c52566a3a37b632078648bdb8459';

/// Every owner edit made outside Studio — from the profile grid or from the
/// player — goes through here, so each list showing the video follows.
///
/// Copied from [videoEditor].
@ProviderFor(videoEditor)
final videoEditorProvider = Provider<VideoEditor>.internal(
  videoEditor,
  name: r'videoEditorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoEditorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoEditorRef = ProviderRef<VideoEditor>;
String _$feedNotifierHash() => r'99a71a44fce67c817b8cc2eb13859cea8f8a3ec1';

/// See also [FeedNotifier].
@ProviderFor(FeedNotifier)
final feedNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FeedNotifier, List<VideoModel>>.internal(
      FeedNotifier.new,
      name: r'feedNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedNotifier = AutoDisposeAsyncNotifier<List<VideoModel>>;
String _$userVideosNotifierHash() =>
    r'209f7dbeba9b0de32d3081b0a6504cc6779c0765';

abstract class _$UserVideosNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<VideoModel>> {
  late final String userId;

  FutureOr<List<VideoModel>> build(String userId);
}

/// One user's videos. For the caller's own id the server also returns
/// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
///
/// Copied from [UserVideosNotifier].
@ProviderFor(UserVideosNotifier)
const userVideosNotifierProvider = UserVideosNotifierFamily();

/// One user's videos. For the caller's own id the server also returns
/// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
///
/// Copied from [UserVideosNotifier].
class UserVideosNotifierFamily extends Family<AsyncValue<List<VideoModel>>> {
  /// One user's videos. For the caller's own id the server also returns
  /// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
  ///
  /// Copied from [UserVideosNotifier].
  const UserVideosNotifierFamily();

  /// One user's videos. For the caller's own id the server also returns
  /// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
  ///
  /// Copied from [UserVideosNotifier].
  UserVideosNotifierProvider call(String userId) {
    return UserVideosNotifierProvider(userId);
  }

  @override
  UserVideosNotifierProvider getProviderOverride(
    covariant UserVideosNotifierProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userVideosNotifierProvider';
}

/// One user's videos. For the caller's own id the server also returns
/// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
///
/// Copied from [UserVideosNotifier].
class UserVideosNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          UserVideosNotifier,
          List<VideoModel>
        > {
  /// One user's videos. For the caller's own id the server also returns
  /// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
  ///
  /// Copied from [UserVideosNotifier].
  UserVideosNotifierProvider(String userId)
    : this._internal(
        () => UserVideosNotifier()..userId = userId,
        from: userVideosNotifierProvider,
        name: r'userVideosNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userVideosNotifierHash,
        dependencies: UserVideosNotifierFamily._dependencies,
        allTransitiveDependencies:
            UserVideosNotifierFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserVideosNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  FutureOr<List<VideoModel>> runNotifierBuild(
    covariant UserVideosNotifier notifier,
  ) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(UserVideosNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserVideosNotifierProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<UserVideosNotifier, List<VideoModel>>
  createElement() {
    return _UserVideosNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserVideosNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserVideosNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<VideoModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserVideosNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          UserVideosNotifier,
          List<VideoModel>
        >
    with UserVideosNotifierRef {
  _UserVideosNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as UserVideosNotifierProvider).userId;
}

String _$followingFeedNotifierHash() =>
    r'55d860aef92fe0b265fb5434df17dda0430c6c36';

/// The Following tab: only the accounts the viewer follows, newest first.
///
/// Copied from [FollowingFeedNotifier].
@ProviderFor(FollowingFeedNotifier)
final followingFeedNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      FollowingFeedNotifier,
      List<VideoModel>
    >.internal(
      FollowingFeedNotifier.new,
      name: r'followingFeedNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$followingFeedNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FollowingFeedNotifier = AutoDisposeAsyncNotifier<List<VideoModel>>;
String _$friendsFeedNotifierHash() =>
    r'b08bf6b7f12a9e23ebf9de848219e80dd803785f';

/// The Friends tab: mutual follows — accounts the viewer follows that follow
/// back. user-service has no friends listing, so it is the intersection of the
/// viewer's following and followers, the same way the web computes it.
///
/// Copied from [FriendsFeedNotifier].
@ProviderFor(FriendsFeedNotifier)
final friendsFeedNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      FriendsFeedNotifier,
      List<VideoModel>
    >.internal(
      FriendsFeedNotifier.new,
      name: r'friendsFeedNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$friendsFeedNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FriendsFeedNotifier = AutoDisposeAsyncNotifier<List<VideoModel>>;
String _$editedVideosHash() => r'20a80d9237c7fd3f273607a427ff160c3033ba05';

/// The latest copy of each video its owner edited this session. Screens that
/// hold their own snapshot of a video — a feed page, the viewer opened from a
/// grid — read through this so an edit shows at once.
///
/// Copied from [EditedVideos].
@ProviderFor(EditedVideos)
final editedVideosProvider =
    NotifierProvider<EditedVideos, Map<String, VideoModel>>.internal(
      EditedVideos.new,
      name: r'editedVideosProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$editedVideosHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EditedVideos = Notifier<Map<String, VideoModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studioRepositoryHash() => r'f0322c9a27b2e7232fa8f679f7b193cb50e51a4b';

/// See also [studioRepository].
@ProviderFor(studioRepository)
final studioRepositoryProvider = Provider<StudioRepository>.internal(
  studioRepository,
  name: r'studioRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studioRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioRepositoryRef = ProviderRef<StudioRepository>;
String _$studioOverviewHash() => r'14da39bb2423969fba20a593c43d6b29ae899895';

/// See also [studioOverview].
@ProviderFor(studioOverview)
final studioOverviewProvider =
    AutoDisposeFutureProvider<CreatorOverview>.internal(
      studioOverview,
      name: r'studioOverviewProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioOverviewHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioOverviewRef = AutoDisposeFutureProviderRef<CreatorOverview>;
String _$studioViewersHash() => r'01c056c1855ad35ac4e4ad93592c12de6beca07d';

/// See also [studioViewers].
@ProviderFor(studioViewers)
final studioViewersProvider =
    AutoDisposeFutureProvider<CreatorViewers>.internal(
      studioViewers,
      name: r'studioViewersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioViewersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioViewersRef = AutoDisposeFutureProviderRef<CreatorViewers>;
String _$studioTopVideosHash() => r'36522b2f93bbb6b69a22cd9d94407ca7b9f07fa7';

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

/// The analytics top list, its videos loaded into [StudioVideoCache].
///
/// Copied from [studioTopVideos].
@ProviderFor(studioTopVideos)
const studioTopVideosProvider = StudioTopVideosFamily();

/// The analytics top list, its videos loaded into [StudioVideoCache].
///
/// Copied from [studioTopVideos].
class StudioTopVideosFamily
    extends Family<AsyncValue<List<CreatorVideoStats>>> {
  /// The analytics top list, its videos loaded into [StudioVideoCache].
  ///
  /// Copied from [studioTopVideos].
  const StudioTopVideosFamily();

  /// The analytics top list, its videos loaded into [StudioVideoCache].
  ///
  /// Copied from [studioTopVideos].
  StudioTopVideosProvider call(CreatorVideoSort sort) {
    return StudioTopVideosProvider(sort);
  }

  @override
  StudioTopVideosProvider getProviderOverride(
    covariant StudioTopVideosProvider provider,
  ) {
    return call(provider.sort);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studioTopVideosProvider';
}

/// The analytics top list, its videos loaded into [StudioVideoCache].
///
/// Copied from [studioTopVideos].
class StudioTopVideosProvider
    extends AutoDisposeFutureProvider<List<CreatorVideoStats>> {
  /// The analytics top list, its videos loaded into [StudioVideoCache].
  ///
  /// Copied from [studioTopVideos].
  StudioTopVideosProvider(CreatorVideoSort sort)
    : this._internal(
        (ref) => studioTopVideos(ref as StudioTopVideosRef, sort),
        from: studioTopVideosProvider,
        name: r'studioTopVideosProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studioTopVideosHash,
        dependencies: StudioTopVideosFamily._dependencies,
        allTransitiveDependencies:
            StudioTopVideosFamily._allTransitiveDependencies,
        sort: sort,
      );

  StudioTopVideosProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sort,
  }) : super.internal();

  final CreatorVideoSort sort;

  @override
  Override overrideWith(
    FutureOr<List<CreatorVideoStats>> Function(StudioTopVideosRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudioTopVideosProvider._internal(
        (ref) => create(ref as StudioTopVideosRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sort: sort,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CreatorVideoStats>> createElement() {
    return _StudioTopVideosProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioTopVideosProvider && other.sort == sort;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudioTopVideosRef
    on AutoDisposeFutureProviderRef<List<CreatorVideoStats>> {
  /// The parameter `sort` of this provider.
  CreatorVideoSort get sort;
}

class _StudioTopVideosProviderElement
    extends AutoDisposeFutureProviderElement<List<CreatorVideoStats>>
    with StudioTopVideosRef {
  _StudioTopVideosProviderElement(super.provider);

  @override
  CreatorVideoSort get sort => (origin as StudioTopVideosProvider).sort;
}

String _$studioVideoAnalyticsHash() =>
    r'e305b3d7340a4556b4034d0aaea2ebb39e16b704';

/// See also [studioVideoAnalytics].
@ProviderFor(studioVideoAnalytics)
const studioVideoAnalyticsProvider = StudioVideoAnalyticsFamily();

/// See also [studioVideoAnalytics].
class StudioVideoAnalyticsFamily
    extends Family<AsyncValue<StudioVideoAnalytics>> {
  /// See also [studioVideoAnalytics].
  const StudioVideoAnalyticsFamily();

  /// See also [studioVideoAnalytics].
  StudioVideoAnalyticsProvider call(String videoId) {
    return StudioVideoAnalyticsProvider(videoId);
  }

  @override
  StudioVideoAnalyticsProvider getProviderOverride(
    covariant StudioVideoAnalyticsProvider provider,
  ) {
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
  String? get name => r'studioVideoAnalyticsProvider';
}

/// See also [studioVideoAnalytics].
class StudioVideoAnalyticsProvider
    extends AutoDisposeFutureProvider<StudioVideoAnalytics> {
  /// See also [studioVideoAnalytics].
  StudioVideoAnalyticsProvider(String videoId)
    : this._internal(
        (ref) => studioVideoAnalytics(ref as StudioVideoAnalyticsRef, videoId),
        from: studioVideoAnalyticsProvider,
        name: r'studioVideoAnalyticsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studioVideoAnalyticsHash,
        dependencies: StudioVideoAnalyticsFamily._dependencies,
        allTransitiveDependencies:
            StudioVideoAnalyticsFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  StudioVideoAnalyticsProvider._internal(
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
    FutureOr<StudioVideoAnalytics> Function(StudioVideoAnalyticsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudioVideoAnalyticsProvider._internal(
        (ref) => create(ref as StudioVideoAnalyticsRef),
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
  AutoDisposeFutureProviderElement<StudioVideoAnalytics> createElement() {
    return _StudioVideoAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioVideoAnalyticsProvider && other.videoId == videoId;
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
mixin StudioVideoAnalyticsRef
    on AutoDisposeFutureProviderRef<StudioVideoAnalytics> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _StudioVideoAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<StudioVideoAnalytics>
    with StudioVideoAnalyticsRef {
  _StudioVideoAnalyticsProviderElement(super.provider);

  @override
  String get videoId => (origin as StudioVideoAnalyticsProvider).videoId;
}

String _$studioRecentPostsHash() => r'bf7378ba32be52b4531d029d1f96e0fdcca09436';

/// The newest few of the creator's videos, in any status.
///
/// Copied from [studioRecentPosts].
@ProviderFor(studioRecentPosts)
final studioRecentPostsProvider =
    AutoDisposeFutureProvider<List<VideoModel>>.internal(
      studioRecentPosts,
      name: r'studioRecentPostsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioRecentPostsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioRecentPostsRef = AutoDisposeFutureProviderRef<List<VideoModel>>;
String _$studioRecentCommentsHash() =>
    r'35767af6579219458f4829de0a29daaa46829fb0';

/// The newest few comments on any of the creator's videos.
///
/// Copied from [studioRecentComments].
@ProviderFor(studioRecentComments)
final studioRecentCommentsProvider =
    AutoDisposeFutureProvider<List<CommentModel>>.internal(
      studioRecentComments,
      name: r'studioRecentCommentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioRecentCommentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioRecentCommentsRef =
    AutoDisposeFutureProviderRef<List<CommentModel>>;
String _$studioEditorHash() => r'00ca77a4d8fdd39abac8c663a750cfa334c9dd8b';

/// Every change Studio makes to a video goes through here, so the lists that
/// show it — Posts, Home, the profile grid — all follow.
///
/// Copied from [studioEditor].
@ProviderFor(studioEditor)
final studioEditorProvider = Provider<StudioEditor>.internal(
  studioEditor,
  name: r'studioEditorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studioEditorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioEditorRef = ProviderRef<StudioEditor>;
String _$studioVideoHash() => r'1b238aaf34eaac6496b5968858676818455c84c6';

/// One of the creator's videos as it stands now, for the edit page.
///
/// Copied from [studioVideo].
@ProviderFor(studioVideo)
const studioVideoProvider = StudioVideoFamily();

/// One of the creator's videos as it stands now, for the edit page.
///
/// Copied from [studioVideo].
class StudioVideoFamily extends Family<AsyncValue<VideoModel>> {
  /// One of the creator's videos as it stands now, for the edit page.
  ///
  /// Copied from [studioVideo].
  const StudioVideoFamily();

  /// One of the creator's videos as it stands now, for the edit page.
  ///
  /// Copied from [studioVideo].
  StudioVideoProvider call(String videoId) {
    return StudioVideoProvider(videoId);
  }

  @override
  StudioVideoProvider getProviderOverride(
    covariant StudioVideoProvider provider,
  ) {
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
  String? get name => r'studioVideoProvider';
}

/// One of the creator's videos as it stands now, for the edit page.
///
/// Copied from [studioVideo].
class StudioVideoProvider extends AutoDisposeFutureProvider<VideoModel> {
  /// One of the creator's videos as it stands now, for the edit page.
  ///
  /// Copied from [studioVideo].
  StudioVideoProvider(String videoId)
    : this._internal(
        (ref) => studioVideo(ref as StudioVideoRef, videoId),
        from: studioVideoProvider,
        name: r'studioVideoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studioVideoHash,
        dependencies: StudioVideoFamily._dependencies,
        allTransitiveDependencies: StudioVideoFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  StudioVideoProvider._internal(
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
    FutureOr<VideoModel> Function(StudioVideoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudioVideoProvider._internal(
        (ref) => create(ref as StudioVideoRef),
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
    return _StudioVideoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioVideoProvider && other.videoId == videoId;
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
mixin StudioVideoRef on AutoDisposeFutureProviderRef<VideoModel> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _StudioVideoProviderElement
    extends AutoDisposeFutureProviderElement<VideoModel>
    with StudioVideoRef {
  _StudioVideoProviderElement(super.provider);

  @override
  String get videoId => (origin as StudioVideoProvider).videoId;
}

String _$studioPickableVideosHash() =>
    r'4d60b25204c6470bad60196518b728fbecfda7c5';

/// The creator's videos for the comment inbox's video picker.
///
/// Copied from [studioPickableVideos].
@ProviderFor(studioPickableVideos)
final studioPickableVideosProvider =
    AutoDisposeFutureProvider<List<VideoModel>>.internal(
      studioPickableVideos,
      name: r'studioPickableVideosProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioPickableVideosHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioPickableVideosRef =
    AutoDisposeFutureProviderRef<List<VideoModel>>;
String _$studioTrendingHash() => r'b0f29079c6e123f45664f5daee987210a161d961';

/// What is trending across Nowa right now, with creators resolved.
///
/// Copied from [studioTrending].
@ProviderFor(studioTrending)
final studioTrendingProvider =
    AutoDisposeFutureProvider<List<VideoModel>>.internal(
      studioTrending,
      name: r'studioTrendingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioTrendingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StudioTrendingRef = AutoDisposeFutureProviderRef<List<VideoModel>>;
String _$studioRangeHash() => r'c7d912ea87c80bec9bcd840f24a069990c447e08';

/// The window every analytics screen reads, shared so a pick on one screen
/// holds on the next.
///
/// Copied from [StudioRange].
@ProviderFor(StudioRange)
final studioRangeProvider = NotifierProvider<StudioRange, int>.internal(
  StudioRange.new,
  name: r'studioRangeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studioRangeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudioRange = Notifier<int>;
String _$studioVideoCacheHash() => r'837299ad6ee02ab3e85c4850f41d47eb857b5130';

/// Videos Studio has seen by id — analytics and the comment inbox hand back
/// ids only, and the title and thumbnail come from `/videos/batch`.
///
/// Copied from [StudioVideoCache].
@ProviderFor(StudioVideoCache)
final studioVideoCacheProvider =
    NotifierProvider<StudioVideoCache, Map<String, VideoModel>>.internal(
      StudioVideoCache.new,
      name: r'studioVideoCacheProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioVideoCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudioVideoCache = Notifier<Map<String, VideoModel>>;
String _$studioPostFilterHash() => r'd6c3d2b45a15af691c8c7a19bd5dc5310ef4a5eb';

/// See also [StudioPostFilter].
@ProviderFor(StudioPostFilter)
final studioPostFilterProvider =
    AutoDisposeNotifierProvider<StudioPostFilter, StudioPostQuery>.internal(
      StudioPostFilter.new,
      name: r'studioPostFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioPostFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudioPostFilter = AutoDisposeNotifier<StudioPostQuery>;
String _$studioPostsHash() => r'aa0bcd7585d90b0a15d6ede11f2079d5444666f7';

/// The Posts list under the current [StudioPostFilter], offset paged.
///
/// Copied from [StudioPosts].
@ProviderFor(StudioPosts)
final studioPostsProvider =
    AutoDisposeAsyncNotifierProvider<StudioPosts, List<VideoModel>>.internal(
      StudioPosts.new,
      name: r'studioPostsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioPostsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudioPosts = AutoDisposeAsyncNotifier<List<VideoModel>>;
String _$studioInboxFilterHash() => r'314ca292650f693f5dd26dac1fc155537a379264';

abstract class _$StudioInboxFilter
    extends BuildlessAutoDisposeNotifier<InboxQuery> {
  late final String? initialVideoId;

  InboxQuery build(String? initialVideoId);
}

/// Keyed by the video the screen was opened on, so a deep link to one
/// video's comments starts filtered instead of loading everything first.
///
/// Copied from [StudioInboxFilter].
@ProviderFor(StudioInboxFilter)
const studioInboxFilterProvider = StudioInboxFilterFamily();

/// Keyed by the video the screen was opened on, so a deep link to one
/// video's comments starts filtered instead of loading everything first.
///
/// Copied from [StudioInboxFilter].
class StudioInboxFilterFamily extends Family<InboxQuery> {
  /// Keyed by the video the screen was opened on, so a deep link to one
  /// video's comments starts filtered instead of loading everything first.
  ///
  /// Copied from [StudioInboxFilter].
  const StudioInboxFilterFamily();

  /// Keyed by the video the screen was opened on, so a deep link to one
  /// video's comments starts filtered instead of loading everything first.
  ///
  /// Copied from [StudioInboxFilter].
  StudioInboxFilterProvider call(String? initialVideoId) {
    return StudioInboxFilterProvider(initialVideoId);
  }

  @override
  StudioInboxFilterProvider getProviderOverride(
    covariant StudioInboxFilterProvider provider,
  ) {
    return call(provider.initialVideoId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studioInboxFilterProvider';
}

/// Keyed by the video the screen was opened on, so a deep link to one
/// video's comments starts filtered instead of loading everything first.
///
/// Copied from [StudioInboxFilter].
class StudioInboxFilterProvider
    extends AutoDisposeNotifierProviderImpl<StudioInboxFilter, InboxQuery> {
  /// Keyed by the video the screen was opened on, so a deep link to one
  /// video's comments starts filtered instead of loading everything first.
  ///
  /// Copied from [StudioInboxFilter].
  StudioInboxFilterProvider(String? initialVideoId)
    : this._internal(
        () => StudioInboxFilter()..initialVideoId = initialVideoId,
        from: studioInboxFilterProvider,
        name: r'studioInboxFilterProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studioInboxFilterHash,
        dependencies: StudioInboxFilterFamily._dependencies,
        allTransitiveDependencies:
            StudioInboxFilterFamily._allTransitiveDependencies,
        initialVideoId: initialVideoId,
      );

  StudioInboxFilterProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialVideoId,
  }) : super.internal();

  final String? initialVideoId;

  @override
  InboxQuery runNotifierBuild(covariant StudioInboxFilter notifier) {
    return notifier.build(initialVideoId);
  }

  @override
  Override overrideWith(StudioInboxFilter Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudioInboxFilterProvider._internal(
        () => create()..initialVideoId = initialVideoId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialVideoId: initialVideoId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<StudioInboxFilter, InboxQuery>
  createElement() {
    return _StudioInboxFilterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioInboxFilterProvider &&
        other.initialVideoId == initialVideoId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialVideoId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudioInboxFilterRef on AutoDisposeNotifierProviderRef<InboxQuery> {
  /// The parameter `initialVideoId` of this provider.
  String? get initialVideoId;
}

class _StudioInboxFilterProviderElement
    extends AutoDisposeNotifierProviderElement<StudioInboxFilter, InboxQuery>
    with StudioInboxFilterRef {
  _StudioInboxFilterProviderElement(super.provider);

  @override
  String? get initialVideoId =>
      (origin as StudioInboxFilterProvider).initialVideoId;
}

String _$studioInboxHash() => r'd88a6526ccd9a8026fe30559caf4b6b8b9a5d412';

abstract class _$StudioInbox
    extends BuildlessAutoDisposeAsyncNotifier<List<CommentModel>> {
  late final String? initialVideoId;

  FutureOr<List<CommentModel>> build(String? initialVideoId);
}

/// Comments on the creator's videos under the current [StudioInboxFilter],
/// cursor paged.
///
/// Copied from [StudioInbox].
@ProviderFor(StudioInbox)
const studioInboxProvider = StudioInboxFamily();

/// Comments on the creator's videos under the current [StudioInboxFilter],
/// cursor paged.
///
/// Copied from [StudioInbox].
class StudioInboxFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// Comments on the creator's videos under the current [StudioInboxFilter],
  /// cursor paged.
  ///
  /// Copied from [StudioInbox].
  const StudioInboxFamily();

  /// Comments on the creator's videos under the current [StudioInboxFilter],
  /// cursor paged.
  ///
  /// Copied from [StudioInbox].
  StudioInboxProvider call(String? initialVideoId) {
    return StudioInboxProvider(initialVideoId);
  }

  @override
  StudioInboxProvider getProviderOverride(
    covariant StudioInboxProvider provider,
  ) {
    return call(provider.initialVideoId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studioInboxProvider';
}

/// Comments on the creator's videos under the current [StudioInboxFilter],
/// cursor paged.
///
/// Copied from [StudioInbox].
class StudioInboxProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<StudioInbox, List<CommentModel>> {
  /// Comments on the creator's videos under the current [StudioInboxFilter],
  /// cursor paged.
  ///
  /// Copied from [StudioInbox].
  StudioInboxProvider(String? initialVideoId)
    : this._internal(
        () => StudioInbox()..initialVideoId = initialVideoId,
        from: studioInboxProvider,
        name: r'studioInboxProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studioInboxHash,
        dependencies: StudioInboxFamily._dependencies,
        allTransitiveDependencies: StudioInboxFamily._allTransitiveDependencies,
        initialVideoId: initialVideoId,
      );

  StudioInboxProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialVideoId,
  }) : super.internal();

  final String? initialVideoId;

  @override
  FutureOr<List<CommentModel>> runNotifierBuild(
    covariant StudioInbox notifier,
  ) {
    return notifier.build(initialVideoId);
  }

  @override
  Override overrideWith(StudioInbox Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudioInboxProvider._internal(
        () => create()..initialVideoId = initialVideoId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialVideoId: initialVideoId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<StudioInbox, List<CommentModel>>
  createElement() {
    return _StudioInboxProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioInboxProvider &&
        other.initialVideoId == initialVideoId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialVideoId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudioInboxRef
    on AutoDisposeAsyncNotifierProviderRef<List<CommentModel>> {
  /// The parameter `initialVideoId` of this provider.
  String? get initialVideoId;
}

class _StudioInboxProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<StudioInbox, List<CommentModel>>
    with StudioInboxRef {
  _StudioInboxProviderElement(super.provider);

  @override
  String? get initialVideoId => (origin as StudioInboxProvider).initialVideoId;
}

String _$studioSavedVideosHash() => r'ed69ec3ad24b94bef663073adbaf0d6d9fa29a01';

/// "My inspiration": the videos the creator saved, newest save first.
///
/// Copied from [StudioSavedVideos].
@ProviderFor(StudioSavedVideos)
final studioSavedVideosProvider =
    AutoDisposeAsyncNotifierProvider<
      StudioSavedVideos,
      List<VideoModel>
    >.internal(
      StudioSavedVideos.new,
      name: r'studioSavedVideosProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studioSavedVideosHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudioSavedVideos = AutoDisposeAsyncNotifier<List<VideoModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

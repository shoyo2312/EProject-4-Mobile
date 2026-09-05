// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$interactionRepositoryHash() =>
    r'33df8dc1e0f52717f78ebfa1b5e4403b82a6aef4';

/// See also [interactionRepository].
@ProviderFor(interactionRepository)
final interactionRepositoryProvider = Provider<InteractionRepository>.internal(
  interactionRepository,
  name: r'interactionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$interactionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InteractionRepositoryRef = ProviderRef<InteractionRepository>;
String _$videoCountsHash() => r'a5915639c6bb563152493d27b61ca124811088e6';

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

/// The four counters of one video, straight from interaction-service.
///
/// Watched only for the clip on screen, like [LikeNotifier] and for the same
/// reason: there is no batch endpoint and the gateway's per-IP budget is
/// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
///
/// Copied from [videoCounts].
@ProviderFor(videoCounts)
const videoCountsProvider = VideoCountsFamily();

/// The four counters of one video, straight from interaction-service.
///
/// Watched only for the clip on screen, like [LikeNotifier] and for the same
/// reason: there is no batch endpoint and the gateway's per-IP budget is
/// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
///
/// Copied from [videoCounts].
class VideoCountsFamily extends Family<AsyncValue<InteractionCounts>> {
  /// The four counters of one video, straight from interaction-service.
  ///
  /// Watched only for the clip on screen, like [LikeNotifier] and for the same
  /// reason: there is no batch endpoint and the gateway's per-IP budget is
  /// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
  ///
  /// Copied from [videoCounts].
  const VideoCountsFamily();

  /// The four counters of one video, straight from interaction-service.
  ///
  /// Watched only for the clip on screen, like [LikeNotifier] and for the same
  /// reason: there is no batch endpoint and the gateway's per-IP budget is
  /// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
  ///
  /// Copied from [videoCounts].
  VideoCountsProvider call(String videoId) {
    return VideoCountsProvider(videoId);
  }

  @override
  VideoCountsProvider getProviderOverride(
    covariant VideoCountsProvider provider,
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
  String? get name => r'videoCountsProvider';
}

/// The four counters of one video, straight from interaction-service.
///
/// Watched only for the clip on screen, like [LikeNotifier] and for the same
/// reason: there is no batch endpoint and the gateway's per-IP budget is
/// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
///
/// Copied from [videoCounts].
class VideoCountsProvider extends AutoDisposeFutureProvider<InteractionCounts> {
  /// The four counters of one video, straight from interaction-service.
  ///
  /// Watched only for the clip on screen, like [LikeNotifier] and for the same
  /// reason: there is no batch endpoint and the gateway's per-IP budget is
  /// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
  ///
  /// Copied from [videoCounts].
  VideoCountsProvider(String videoId)
    : this._internal(
        (ref) => videoCounts(ref as VideoCountsRef, videoId),
        from: videoCountsProvider,
        name: r'videoCountsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$videoCountsHash,
        dependencies: VideoCountsFamily._dependencies,
        allTransitiveDependencies: VideoCountsFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  VideoCountsProvider._internal(
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
    FutureOr<InteractionCounts> Function(VideoCountsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VideoCountsProvider._internal(
        (ref) => create(ref as VideoCountsRef),
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
  AutoDisposeFutureProviderElement<InteractionCounts> createElement() {
    return _VideoCountsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoCountsProvider && other.videoId == videoId;
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
mixin VideoCountsRef on AutoDisposeFutureProviderRef<InteractionCounts> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _VideoCountsProviderElement
    extends AutoDisposeFutureProviderElement<InteractionCounts>
    with VideoCountsRef {
  _VideoCountsProviderElement(super.provider);

  @override
  String get videoId => (origin as VideoCountsProvider).videoId;
}

String _$likeStatusCacheHash() => r'c613b47a07a84a6a17aca5757e0397f974b23cf3';

/// Like state already fetched, keyed by `videoId`.
///
/// One place so a screen holding a page of videos resolves them in a single
/// `GET /like-status/batch` instead of one request per card: the gateway allows
/// 20 req/s per IP, and a feed page alone would spend the lot. Same arrangement
/// as `ProfileCache` (interaction doc 3.3b).
///
/// Copied from [LikeStatusCache].
@ProviderFor(LikeStatusCache)
final likeStatusCacheProvider =
    NotifierProvider<LikeStatusCache, Map<String, LikeStatus>>.internal(
      LikeStatusCache.new,
      name: r'likeStatusCacheProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$likeStatusCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LikeStatusCache = Notifier<Map<String, LikeStatus>>;
String _$likeNotifierHash() => r'3e7221742ee6cb46a8e2f0d1260cfa16b6075bd1';

abstract class _$LikeNotifier
    extends BuildlessAutoDisposeAsyncNotifier<LikeStatus> {
  late final String videoId;

  FutureOr<LikeStatus> build(String videoId);
}

/// Like state for **one** video.
///
/// Seeded from [LikeStatusCache] when the feed has already batched this page
/// in; only a video nobody prefetched — a profile grid, a deep link — pays for
/// its own `GET /like-status` (interaction doc 3.3).
///
/// Copied from [LikeNotifier].
@ProviderFor(LikeNotifier)
const likeNotifierProvider = LikeNotifierFamily();

/// Like state for **one** video.
///
/// Seeded from [LikeStatusCache] when the feed has already batched this page
/// in; only a video nobody prefetched — a profile grid, a deep link — pays for
/// its own `GET /like-status` (interaction doc 3.3).
///
/// Copied from [LikeNotifier].
class LikeNotifierFamily extends Family<AsyncValue<LikeStatus>> {
  /// Like state for **one** video.
  ///
  /// Seeded from [LikeStatusCache] when the feed has already batched this page
  /// in; only a video nobody prefetched — a profile grid, a deep link — pays for
  /// its own `GET /like-status` (interaction doc 3.3).
  ///
  /// Copied from [LikeNotifier].
  const LikeNotifierFamily();

  /// Like state for **one** video.
  ///
  /// Seeded from [LikeStatusCache] when the feed has already batched this page
  /// in; only a video nobody prefetched — a profile grid, a deep link — pays for
  /// its own `GET /like-status` (interaction doc 3.3).
  ///
  /// Copied from [LikeNotifier].
  LikeNotifierProvider call(String videoId) {
    return LikeNotifierProvider(videoId);
  }

  @override
  LikeNotifierProvider getProviderOverride(
    covariant LikeNotifierProvider provider,
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
  String? get name => r'likeNotifierProvider';
}

/// Like state for **one** video.
///
/// Seeded from [LikeStatusCache] when the feed has already batched this page
/// in; only a video nobody prefetched — a profile grid, a deep link — pays for
/// its own `GET /like-status` (interaction doc 3.3).
///
/// Copied from [LikeNotifier].
class LikeNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<LikeNotifier, LikeStatus> {
  /// Like state for **one** video.
  ///
  /// Seeded from [LikeStatusCache] when the feed has already batched this page
  /// in; only a video nobody prefetched — a profile grid, a deep link — pays for
  /// its own `GET /like-status` (interaction doc 3.3).
  ///
  /// Copied from [LikeNotifier].
  LikeNotifierProvider(String videoId)
    : this._internal(
        () => LikeNotifier()..videoId = videoId,
        from: likeNotifierProvider,
        name: r'likeNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$likeNotifierHash,
        dependencies: LikeNotifierFamily._dependencies,
        allTransitiveDependencies:
            LikeNotifierFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  LikeNotifierProvider._internal(
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
  FutureOr<LikeStatus> runNotifierBuild(covariant LikeNotifier notifier) {
    return notifier.build(videoId);
  }

  @override
  Override overrideWith(LikeNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LikeNotifierProvider._internal(
        () => create()..videoId = videoId,
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
  AutoDisposeAsyncNotifierProviderElement<LikeNotifier, LikeStatus>
  createElement() {
    return _LikeNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LikeNotifierProvider && other.videoId == videoId;
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
mixin LikeNotifierRef on AutoDisposeAsyncNotifierProviderRef<LikeStatus> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _LikeNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<LikeNotifier, LikeStatus>
    with LikeNotifierRef {
  _LikeNotifierProviderElement(super.provider);

  @override
  String get videoId => (origin as LikeNotifierProvider).videoId;
}

String _$saveNotifierHash() => r'a69f3dcf4c7c2ce02385d05e78c0c418005a089a';

abstract class _$SaveNotifier
    extends BuildlessAutoDisposeAsyncNotifier<SaveStatus> {
  late final String videoId;

  FutureOr<SaveStatus> build(String videoId);
}

/// Whether the calling user has this video in their favourites.
///
/// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
/// private, so there is nothing to prefetch for a page of videos and nothing to
/// show a signed-out viewer. The `save-status` read is answered locally for a
/// guest rather than spending a request on a guaranteed 401.
///
/// Copied from [SaveNotifier].
@ProviderFor(SaveNotifier)
const saveNotifierProvider = SaveNotifierFamily();

/// Whether the calling user has this video in their favourites.
///
/// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
/// private, so there is nothing to prefetch for a page of videos and nothing to
/// show a signed-out viewer. The `save-status` read is answered locally for a
/// guest rather than spending a request on a guaranteed 401.
///
/// Copied from [SaveNotifier].
class SaveNotifierFamily extends Family<AsyncValue<SaveStatus>> {
  /// Whether the calling user has this video in their favourites.
  ///
  /// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
  /// private, so there is nothing to prefetch for a page of videos and nothing to
  /// show a signed-out viewer. The `save-status` read is answered locally for a
  /// guest rather than spending a request on a guaranteed 401.
  ///
  /// Copied from [SaveNotifier].
  const SaveNotifierFamily();

  /// Whether the calling user has this video in their favourites.
  ///
  /// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
  /// private, so there is nothing to prefetch for a page of videos and nothing to
  /// show a signed-out viewer. The `save-status` read is answered locally for a
  /// guest rather than spending a request on a guaranteed 401.
  ///
  /// Copied from [SaveNotifier].
  SaveNotifierProvider call(String videoId) {
    return SaveNotifierProvider(videoId);
  }

  @override
  SaveNotifierProvider getProviderOverride(
    covariant SaveNotifierProvider provider,
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
  String? get name => r'saveNotifierProvider';
}

/// Whether the calling user has this video in their favourites.
///
/// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
/// private, so there is nothing to prefetch for a page of videos and nothing to
/// show a signed-out viewer. The `save-status` read is answered locally for a
/// guest rather than spending a request on a guaranteed 401.
///
/// Copied from [SaveNotifier].
class SaveNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<SaveNotifier, SaveStatus> {
  /// Whether the calling user has this video in their favourites.
  ///
  /// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
  /// private, so there is nothing to prefetch for a page of videos and nothing to
  /// show a signed-out viewer. The `save-status` read is answered locally for a
  /// guest rather than spending a request on a guaranteed 401.
  ///
  /// Copied from [SaveNotifier].
  SaveNotifierProvider(String videoId)
    : this._internal(
        () => SaveNotifier()..videoId = videoId,
        from: saveNotifierProvider,
        name: r'saveNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$saveNotifierHash,
        dependencies: SaveNotifierFamily._dependencies,
        allTransitiveDependencies:
            SaveNotifierFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  SaveNotifierProvider._internal(
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
  FutureOr<SaveStatus> runNotifierBuild(covariant SaveNotifier notifier) {
    return notifier.build(videoId);
  }

  @override
  Override overrideWith(SaveNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SaveNotifierProvider._internal(
        () => create()..videoId = videoId,
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
  AutoDisposeAsyncNotifierProviderElement<SaveNotifier, SaveStatus>
  createElement() {
    return _SaveNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveNotifierProvider && other.videoId == videoId;
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
mixin SaveNotifierRef on AutoDisposeAsyncNotifierProviderRef<SaveStatus> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _SaveNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<SaveNotifier, SaveStatus>
    with SaveNotifierRef {
  _SaveNotifierProviderElement(super.provider);

  @override
  String get videoId => (origin as SaveNotifierProvider).videoId;
}

String _$historyVideosNotifierHash() =>
    r'd5937ed2d652a681c1aed27ba2cae1b5cf56dc66';

abstract class _$HistoryVideosNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<VideoModel>> {
  late final VideoHistory history;

  FutureOr<List<VideoModel>> build(VideoHistory history);
}

/// The caller's own liked or saved videos, hydrated into playable rows.
///
/// Two hops on purpose: interaction-service holds no video metadata, so it
/// answers ids and video-service turns them into videos. Ids that no longer
/// resolve — deleted, or turned private since — are simply absent from the
/// hydration, so a page can come back shorter than the ids asked for, and
/// occasionally empty while there is still more (interaction doc 3.12).
///
/// Copied from [HistoryVideosNotifier].
@ProviderFor(HistoryVideosNotifier)
const historyVideosNotifierProvider = HistoryVideosNotifierFamily();

/// The caller's own liked or saved videos, hydrated into playable rows.
///
/// Two hops on purpose: interaction-service holds no video metadata, so it
/// answers ids and video-service turns them into videos. Ids that no longer
/// resolve — deleted, or turned private since — are simply absent from the
/// hydration, so a page can come back shorter than the ids asked for, and
/// occasionally empty while there is still more (interaction doc 3.12).
///
/// Copied from [HistoryVideosNotifier].
class HistoryVideosNotifierFamily extends Family<AsyncValue<List<VideoModel>>> {
  /// The caller's own liked or saved videos, hydrated into playable rows.
  ///
  /// Two hops on purpose: interaction-service holds no video metadata, so it
  /// answers ids and video-service turns them into videos. Ids that no longer
  /// resolve — deleted, or turned private since — are simply absent from the
  /// hydration, so a page can come back shorter than the ids asked for, and
  /// occasionally empty while there is still more (interaction doc 3.12).
  ///
  /// Copied from [HistoryVideosNotifier].
  const HistoryVideosNotifierFamily();

  /// The caller's own liked or saved videos, hydrated into playable rows.
  ///
  /// Two hops on purpose: interaction-service holds no video metadata, so it
  /// answers ids and video-service turns them into videos. Ids that no longer
  /// resolve — deleted, or turned private since — are simply absent from the
  /// hydration, so a page can come back shorter than the ids asked for, and
  /// occasionally empty while there is still more (interaction doc 3.12).
  ///
  /// Copied from [HistoryVideosNotifier].
  HistoryVideosNotifierProvider call(VideoHistory history) {
    return HistoryVideosNotifierProvider(history);
  }

  @override
  HistoryVideosNotifierProvider getProviderOverride(
    covariant HistoryVideosNotifierProvider provider,
  ) {
    return call(provider.history);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'historyVideosNotifierProvider';
}

/// The caller's own liked or saved videos, hydrated into playable rows.
///
/// Two hops on purpose: interaction-service holds no video metadata, so it
/// answers ids and video-service turns them into videos. Ids that no longer
/// resolve — deleted, or turned private since — are simply absent from the
/// hydration, so a page can come back shorter than the ids asked for, and
/// occasionally empty while there is still more (interaction doc 3.12).
///
/// Copied from [HistoryVideosNotifier].
class HistoryVideosNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          HistoryVideosNotifier,
          List<VideoModel>
        > {
  /// The caller's own liked or saved videos, hydrated into playable rows.
  ///
  /// Two hops on purpose: interaction-service holds no video metadata, so it
  /// answers ids and video-service turns them into videos. Ids that no longer
  /// resolve — deleted, or turned private since — are simply absent from the
  /// hydration, so a page can come back shorter than the ids asked for, and
  /// occasionally empty while there is still more (interaction doc 3.12).
  ///
  /// Copied from [HistoryVideosNotifier].
  HistoryVideosNotifierProvider(VideoHistory history)
    : this._internal(
        () => HistoryVideosNotifier()..history = history,
        from: historyVideosNotifierProvider,
        name: r'historyVideosNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$historyVideosNotifierHash,
        dependencies: HistoryVideosNotifierFamily._dependencies,
        allTransitiveDependencies:
            HistoryVideosNotifierFamily._allTransitiveDependencies,
        history: history,
      );

  HistoryVideosNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.history,
  }) : super.internal();

  final VideoHistory history;

  @override
  FutureOr<List<VideoModel>> runNotifierBuild(
    covariant HistoryVideosNotifier notifier,
  ) {
    return notifier.build(history);
  }

  @override
  Override overrideWith(HistoryVideosNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: HistoryVideosNotifierProvider._internal(
        () => create()..history = history,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        history: history,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    HistoryVideosNotifier,
    List<VideoModel>
  >
  createElement() {
    return _HistoryVideosNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryVideosNotifierProvider && other.history == history;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, history.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HistoryVideosNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<VideoModel>> {
  /// The parameter `history` of this provider.
  VideoHistory get history;
}

class _HistoryVideosNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          HistoryVideosNotifier,
          List<VideoModel>
        >
    with HistoryVideosNotifierRef {
  _HistoryVideosNotifierProviderElement(super.provider);

  @override
  VideoHistory get history => (origin as HistoryVideosNotifierProvider).history;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

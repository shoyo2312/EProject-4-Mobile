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

String _$likeNotifierHash() => r'363c0aa448126113377294b28c4c6515a10874fa';

abstract class _$LikeNotifier
    extends BuildlessAutoDisposeAsyncNotifier<LikeStatus> {
  late final String videoId;

  FutureOr<LikeStatus> build(String videoId);
}

/// Like state for **one** video, fetched on first watch and dropped when the
/// last watcher goes away.
///
/// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
/// budget is shared by every call the app makes, so the feed only ever watches
/// this for the clip on screen (interaction doc 3.3).
///
/// Copied from [LikeNotifier].
@ProviderFor(LikeNotifier)
const likeNotifierProvider = LikeNotifierFamily();

/// Like state for **one** video, fetched on first watch and dropped when the
/// last watcher goes away.
///
/// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
/// budget is shared by every call the app makes, so the feed only ever watches
/// this for the clip on screen (interaction doc 3.3).
///
/// Copied from [LikeNotifier].
class LikeNotifierFamily extends Family<AsyncValue<LikeStatus>> {
  /// Like state for **one** video, fetched on first watch and dropped when the
  /// last watcher goes away.
  ///
  /// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
  /// budget is shared by every call the app makes, so the feed only ever watches
  /// this for the clip on screen (interaction doc 3.3).
  ///
  /// Copied from [LikeNotifier].
  const LikeNotifierFamily();

  /// Like state for **one** video, fetched on first watch and dropped when the
  /// last watcher goes away.
  ///
  /// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
  /// budget is shared by every call the app makes, so the feed only ever watches
  /// this for the clip on screen (interaction doc 3.3).
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

/// Like state for **one** video, fetched on first watch and dropped when the
/// last watcher goes away.
///
/// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
/// budget is shared by every call the app makes, so the feed only ever watches
/// this for the clip on screen (interaction doc 3.3).
///
/// Copied from [LikeNotifier].
class LikeNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<LikeNotifier, LikeStatus> {
  /// Like state for **one** video, fetched on first watch and dropped when the
  /// last watcher goes away.
  ///
  /// There is no batch like-status endpoint, and the gateway's 20 req/s per-IP
  /// budget is shared by every call the app makes, so the feed only ever watches
  /// this for the clip on screen (interaction doc 3.3).
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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

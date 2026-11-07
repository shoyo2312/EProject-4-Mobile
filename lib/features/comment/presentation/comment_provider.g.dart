// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentRepositoryHash() => r'26095def2b997e20dbcaca3ff52c1635bd3a3947';

/// See also [commentRepository].
@ProviderFor(commentRepository)
final commentRepositoryProvider = Provider<CommentRepository>.internal(
  commentRepository,
  name: r'commentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommentRepositoryRef = ProviderRef<CommentRepository>;
String _$commentStickerPacksHash() =>
    r'1d4bed77ce449d390c9796181aed8f64149983de';

/// The sticker catalog for the comment composer — chat-service's catalog,
/// fetched once per session.
///
/// Copied from [commentStickerPacks].
@ProviderFor(commentStickerPacks)
final commentStickerPacksProvider = FutureProvider<List<StickerPack>>.internal(
  commentStickerPacks,
  name: r'commentStickerPacksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentStickerPacksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommentStickerPacksRef = FutureProviderRef<List<StickerPack>>;
String _$commentNotifierHash() => r'72d8f6ed1012a46d634431f7b7362de17a80c8d8';

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

abstract class _$CommentNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<CommentModel>> {
  late final String videoId;

  FutureOr<List<CommentModel>> build(String videoId);
}

/// The top-level comments of one video, most liked and replied first — the
/// server ranks them. Your own new comment still goes on top so you see it
/// land. Replies live in
/// [CommentReplies]; this notifier keeps the two in step (a reply posted or
/// deleted moves its thread's `replyCount` here).
///
/// Copied from [CommentNotifier].
@ProviderFor(CommentNotifier)
const commentNotifierProvider = CommentNotifierFamily();

/// The top-level comments of one video, most liked and replied first — the
/// server ranks them. Your own new comment still goes on top so you see it
/// land. Replies live in
/// [CommentReplies]; this notifier keeps the two in step (a reply posted or
/// deleted moves its thread's `replyCount` here).
///
/// Copied from [CommentNotifier].
class CommentNotifierFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// The top-level comments of one video, most liked and replied first — the
  /// server ranks them. Your own new comment still goes on top so you see it
  /// land. Replies live in
  /// [CommentReplies]; this notifier keeps the two in step (a reply posted or
  /// deleted moves its thread's `replyCount` here).
  ///
  /// Copied from [CommentNotifier].
  const CommentNotifierFamily();

  /// The top-level comments of one video, most liked and replied first — the
  /// server ranks them. Your own new comment still goes on top so you see it
  /// land. Replies live in
  /// [CommentReplies]; this notifier keeps the two in step (a reply posted or
  /// deleted moves its thread's `replyCount` here).
  ///
  /// Copied from [CommentNotifier].
  CommentNotifierProvider call(String videoId) {
    return CommentNotifierProvider(videoId);
  }

  @override
  CommentNotifierProvider getProviderOverride(
    covariant CommentNotifierProvider provider,
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
  String? get name => r'commentNotifierProvider';
}

/// The top-level comments of one video, most liked and replied first — the
/// server ranks them. Your own new comment still goes on top so you see it
/// land. Replies live in
/// [CommentReplies]; this notifier keeps the two in step (a reply posted or
/// deleted moves its thread's `replyCount` here).
///
/// Copied from [CommentNotifier].
class CommentNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          CommentNotifier,
          List<CommentModel>
        > {
  /// The top-level comments of one video, most liked and replied first — the
  /// server ranks them. Your own new comment still goes on top so you see it
  /// land. Replies live in
  /// [CommentReplies]; this notifier keeps the two in step (a reply posted or
  /// deleted moves its thread's `replyCount` here).
  ///
  /// Copied from [CommentNotifier].
  CommentNotifierProvider(String videoId)
    : this._internal(
        () => CommentNotifier()..videoId = videoId,
        from: commentNotifierProvider,
        name: r'commentNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentNotifierHash,
        dependencies: CommentNotifierFamily._dependencies,
        allTransitiveDependencies:
            CommentNotifierFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  CommentNotifierProvider._internal(
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
  FutureOr<List<CommentModel>> runNotifierBuild(
    covariant CommentNotifier notifier,
  ) {
    return notifier.build(videoId);
  }

  @override
  Override overrideWith(CommentNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<CommentNotifier, List<CommentModel>>
  createElement() {
    return _CommentNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentNotifierProvider && other.videoId == videoId;
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
mixin CommentNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<CommentModel>> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _CommentNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          CommentNotifier,
          List<CommentModel>
        >
    with CommentNotifierRef {
  _CommentNotifierProviderElement(super.provider);

  @override
  String get videoId => (origin as CommentNotifierProvider).videoId;
}

String _$commentRepliesHash() => r'71dc5970d42409a30319661b85680ff40f72276f';

abstract class _$CommentReplies
    extends BuildlessAutoDisposeNotifier<Map<String, ReplyThread>> {
  late final String videoId;

  Map<String, ReplyThread> build(String videoId);
}

/// The open reply threads of one video, keyed by top-level comment id. A
/// thread absent from the map is collapsed.
///
/// Copied from [CommentReplies].
@ProviderFor(CommentReplies)
const commentRepliesProvider = CommentRepliesFamily();

/// The open reply threads of one video, keyed by top-level comment id. A
/// thread absent from the map is collapsed.
///
/// Copied from [CommentReplies].
class CommentRepliesFamily extends Family<Map<String, ReplyThread>> {
  /// The open reply threads of one video, keyed by top-level comment id. A
  /// thread absent from the map is collapsed.
  ///
  /// Copied from [CommentReplies].
  const CommentRepliesFamily();

  /// The open reply threads of one video, keyed by top-level comment id. A
  /// thread absent from the map is collapsed.
  ///
  /// Copied from [CommentReplies].
  CommentRepliesProvider call(String videoId) {
    return CommentRepliesProvider(videoId);
  }

  @override
  CommentRepliesProvider getProviderOverride(
    covariant CommentRepliesProvider provider,
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
  String? get name => r'commentRepliesProvider';
}

/// The open reply threads of one video, keyed by top-level comment id. A
/// thread absent from the map is collapsed.
///
/// Copied from [CommentReplies].
class CommentRepliesProvider
    extends
        AutoDisposeNotifierProviderImpl<
          CommentReplies,
          Map<String, ReplyThread>
        > {
  /// The open reply threads of one video, keyed by top-level comment id. A
  /// thread absent from the map is collapsed.
  ///
  /// Copied from [CommentReplies].
  CommentRepliesProvider(String videoId)
    : this._internal(
        () => CommentReplies()..videoId = videoId,
        from: commentRepliesProvider,
        name: r'commentRepliesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentRepliesHash,
        dependencies: CommentRepliesFamily._dependencies,
        allTransitiveDependencies:
            CommentRepliesFamily._allTransitiveDependencies,
        videoId: videoId,
      );

  CommentRepliesProvider._internal(
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
  Map<String, ReplyThread> runNotifierBuild(covariant CommentReplies notifier) {
    return notifier.build(videoId);
  }

  @override
  Override overrideWith(CommentReplies Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentRepliesProvider._internal(
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
  AutoDisposeNotifierProviderElement<CommentReplies, Map<String, ReplyThread>>
  createElement() {
    return _CommentRepliesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentRepliesProvider && other.videoId == videoId;
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
mixin CommentRepliesRef
    on AutoDisposeNotifierProviderRef<Map<String, ReplyThread>> {
  /// The parameter `videoId` of this provider.
  String get videoId;
}

class _CommentRepliesProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          CommentReplies,
          Map<String, ReplyThread>
        >
    with CommentRepliesRef {
  _CommentRepliesProviderElement(super.provider);

  @override
  String get videoId => (origin as CommentRepliesProvider).videoId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

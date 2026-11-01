// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storyRepositoryHash() => r'fd2198c5444b14278f93a2af24546aabc04af9c5';

/// See also [storyRepository].
@ProviderFor(storyRepository)
final storyRepositoryProvider = Provider<StoryRepository>.internal(
  storyRepository,
  name: r'storyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StoryRepositoryRef = ProviderRef<StoryRepository>;
String _$storyRingHash() => r'5e48f6b589f57fda9295ed73a4081e404a5ed0e5';

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

/// The ring around one avatar (a profile header). Null when the account has
/// nothing the viewer may watch.
///
/// Copied from [storyRing].
@ProviderFor(storyRing)
const storyRingProvider = StoryRingFamily();

/// The ring around one avatar (a profile header). Null when the account has
/// nothing the viewer may watch.
///
/// Copied from [storyRing].
class StoryRingFamily extends Family<AsyncValue<StoryRing?>> {
  /// The ring around one avatar (a profile header). Null when the account has
  /// nothing the viewer may watch.
  ///
  /// Copied from [storyRing].
  const StoryRingFamily();

  /// The ring around one avatar (a profile header). Null when the account has
  /// nothing the viewer may watch.
  ///
  /// Copied from [storyRing].
  StoryRingProvider call(String userId) {
    return StoryRingProvider(userId);
  }

  @override
  StoryRingProvider getProviderOverride(covariant StoryRingProvider provider) {
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
  String? get name => r'storyRingProvider';
}

/// The ring around one avatar (a profile header). Null when the account has
/// nothing the viewer may watch.
///
/// Copied from [storyRing].
class StoryRingProvider extends AutoDisposeFutureProvider<StoryRing?> {
  /// The ring around one avatar (a profile header). Null when the account has
  /// nothing the viewer may watch.
  ///
  /// Copied from [storyRing].
  StoryRingProvider(String userId)
    : this._internal(
        (ref) => storyRing(ref as StoryRingRef, userId),
        from: storyRingProvider,
        name: r'storyRingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$storyRingHash,
        dependencies: StoryRingFamily._dependencies,
        allTransitiveDependencies: StoryRingFamily._allTransitiveDependencies,
        userId: userId,
      );

  StoryRingProvider._internal(
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
  Override overrideWith(
    FutureOr<StoryRing?> Function(StoryRingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StoryRingProvider._internal(
        (ref) => create(ref as StoryRingRef),
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
  AutoDisposeFutureProviderElement<StoryRing?> createElement() {
    return _StoryRingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StoryRingProvider && other.userId == userId;
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
mixin StoryRingRef on AutoDisposeFutureProviderRef<StoryRing?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _StoryRingProviderElement
    extends AutoDisposeFutureProviderElement<StoryRing?>
    with StoryRingRef {
  _StoryRingProviderElement(super.provider);

  @override
  String get userId => (origin as StoryRingProvider).userId;
}

String _$userStoryGroupHash() => r'dc46d8d9d446bfb427251c9a4a3b3f2518cdee07';

/// See also [userStoryGroup].
@ProviderFor(userStoryGroup)
const userStoryGroupProvider = UserStoryGroupFamily();

/// See also [userStoryGroup].
class UserStoryGroupFamily extends Family<AsyncValue<StoryGroup?>> {
  /// See also [userStoryGroup].
  const UserStoryGroupFamily();

  /// See also [userStoryGroup].
  UserStoryGroupProvider call(String userId) {
    return UserStoryGroupProvider(userId);
  }

  @override
  UserStoryGroupProvider getProviderOverride(
    covariant UserStoryGroupProvider provider,
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
  String? get name => r'userStoryGroupProvider';
}

/// See also [userStoryGroup].
class UserStoryGroupProvider extends AutoDisposeFutureProvider<StoryGroup?> {
  /// See also [userStoryGroup].
  UserStoryGroupProvider(String userId)
    : this._internal(
        (ref) => userStoryGroup(ref as UserStoryGroupRef, userId),
        from: userStoryGroupProvider,
        name: r'userStoryGroupProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userStoryGroupHash,
        dependencies: UserStoryGroupFamily._dependencies,
        allTransitiveDependencies:
            UserStoryGroupFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserStoryGroupProvider._internal(
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
  Override overrideWith(
    FutureOr<StoryGroup?> Function(UserStoryGroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserStoryGroupProvider._internal(
        (ref) => create(ref as UserStoryGroupRef),
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
  AutoDisposeFutureProviderElement<StoryGroup?> createElement() {
    return _UserStoryGroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserStoryGroupProvider && other.userId == userId;
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
mixin UserStoryGroupRef on AutoDisposeFutureProviderRef<StoryGroup?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserStoryGroupProviderElement
    extends AutoDisposeFutureProviderElement<StoryGroup?>
    with UserStoryGroupRef {
  _UserStoryGroupProviderElement(super.provider);

  @override
  String get userId => (origin as UserStoryGroupProvider).userId;
}

String _$storyTrayHash() => r'edf6520a02fbbcde0c4189885b9f72aa10676728';

/// The story tray: the viewer's own group first, then the people they follow
/// who have something to watch.
///
/// story-service holds no follow graph, so the ids come from user-service
/// first — the same two-step read the Following feed does.
///
/// Copied from [StoryTray].
@ProviderFor(StoryTray)
final storyTrayProvider =
    AsyncNotifierProvider<StoryTray, List<StoryGroup>>.internal(
      StoryTray.new,
      name: r'storyTrayProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$storyTrayHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StoryTray = AsyncNotifier<List<StoryGroup>>;
String _$storyViewersHash() => r'2423e8bc27d8b6b2b508f801bd5cb196a9a25dde';

abstract class _$StoryViewers
    extends BuildlessAutoDisposeAsyncNotifier<List<StoryViewer>> {
  late final String storyId;

  FutureOr<List<StoryViewer>> build(String storyId);
}

/// "Who watched my story", newest first, paged by `viewedAt`.
///
/// Copied from [StoryViewers].
@ProviderFor(StoryViewers)
const storyViewersProvider = StoryViewersFamily();

/// "Who watched my story", newest first, paged by `viewedAt`.
///
/// Copied from [StoryViewers].
class StoryViewersFamily extends Family<AsyncValue<List<StoryViewer>>> {
  /// "Who watched my story", newest first, paged by `viewedAt`.
  ///
  /// Copied from [StoryViewers].
  const StoryViewersFamily();

  /// "Who watched my story", newest first, paged by `viewedAt`.
  ///
  /// Copied from [StoryViewers].
  StoryViewersProvider call(String storyId) {
    return StoryViewersProvider(storyId);
  }

  @override
  StoryViewersProvider getProviderOverride(
    covariant StoryViewersProvider provider,
  ) {
    return call(provider.storyId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'storyViewersProvider';
}

/// "Who watched my story", newest first, paged by `viewedAt`.
///
/// Copied from [StoryViewers].
class StoryViewersProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<StoryViewers, List<StoryViewer>> {
  /// "Who watched my story", newest first, paged by `viewedAt`.
  ///
  /// Copied from [StoryViewers].
  StoryViewersProvider(String storyId)
    : this._internal(
        () => StoryViewers()..storyId = storyId,
        from: storyViewersProvider,
        name: r'storyViewersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$storyViewersHash,
        dependencies: StoryViewersFamily._dependencies,
        allTransitiveDependencies:
            StoryViewersFamily._allTransitiveDependencies,
        storyId: storyId,
      );

  StoryViewersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storyId,
  }) : super.internal();

  final String storyId;

  @override
  FutureOr<List<StoryViewer>> runNotifierBuild(
    covariant StoryViewers notifier,
  ) {
    return notifier.build(storyId);
  }

  @override
  Override overrideWith(StoryViewers Function() create) {
    return ProviderOverride(
      origin: this,
      override: StoryViewersProvider._internal(
        () => create()..storyId = storyId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storyId: storyId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<StoryViewers, List<StoryViewer>>
  createElement() {
    return _StoryViewersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StoryViewersProvider && other.storyId == storyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StoryViewersRef
    on AutoDisposeAsyncNotifierProviderRef<List<StoryViewer>> {
  /// The parameter `storyId` of this provider.
  String get storyId;
}

class _StoryViewersProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<StoryViewers, List<StoryViewer>>
    with StoryViewersRef {
  _StoryViewersProviderElement(super.provider);

  @override
  String get storyId => (origin as StoryViewersProvider).storyId;
}

String _$storyUploadHash() => r'64e7d447668e56392f21a5c1cae81e214b8ca2e1';

/// Kept alive so a switch of tab does not cancel an upload mid-file.
///
/// Copied from [StoryUpload].
@ProviderFor(StoryUpload)
final storyUploadProvider =
    NotifierProvider<StoryUpload, StoryUploadState>.internal(
      StoryUpload.new,
      name: r'storyUploadProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$storyUploadHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StoryUpload = Notifier<StoryUploadState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

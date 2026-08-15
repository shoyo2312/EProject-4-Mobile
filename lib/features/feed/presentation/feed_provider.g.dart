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
String _$feedNotifierHash() => r'5c27d108fb0452896adba354f2d8c04355eb7ec1';

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
    r'6f0d3437f3c0fd9572fadb6ee01ec0502da4fc6f';

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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

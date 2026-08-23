// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userRepositoryHash() => r'f4e55f5b693e2e6253d4978d9c409c50add31958';

/// See also [userRepository].
@ProviderFor(userRepository)
final userRepositoryProvider = Provider<UserRepository>.internal(
  userRepository,
  name: r'userRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRepositoryRef = ProviderRef<UserRepository>;
String _$myProfileHash() => r'6a40ea8b0cec8e928c113d967856cd90aae3f934';

/// See also [MyProfile].
@ProviderFor(MyProfile)
final myProfileProvider =
    AutoDisposeAsyncNotifierProvider<MyProfile, UserProfileModel>.internal(
      MyProfile.new,
      name: r'myProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyProfile = AutoDisposeAsyncNotifier<UserProfileModel>;
String _$profileCacheHash() => r'29740a737f6d924b2aba473b87658b0aafa19d5a';

/// Profiles already fetched, keyed by `userId`.
///
/// One place so a screen that already knows a list of ids — a feed page, a
/// page of comments — resolves them in a single `GET /users?ids=` instead of
/// one request per row: the gateway allows 20 req/s per IP, and a feed page
/// alone would spend the lot (user doc 3.3b).
///
/// Copied from [ProfileCache].
@ProviderFor(ProfileCache)
final profileCacheProvider =
    NotifierProvider<ProfileCache, Map<String, UserProfileModel>>.internal(
      ProfileCache.new,
      name: r'profileCacheProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileCache = Notifier<Map<String, UserProfileModel>>;
String _$profileNotifierHash() => r'eeb1dc0d165896eb3adeb47b0d5e420547af7ec3';

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

abstract class _$ProfileNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ProfileState> {
  late final String userId;

  FutureOr<ProfileState> build(String userId);
}

/// See also [ProfileNotifier].
@ProviderFor(ProfileNotifier)
const profileNotifierProvider = ProfileNotifierFamily();

/// See also [ProfileNotifier].
class ProfileNotifierFamily extends Family<AsyncValue<ProfileState>> {
  /// See also [ProfileNotifier].
  const ProfileNotifierFamily();

  /// See also [ProfileNotifier].
  ProfileNotifierProvider call(String userId) {
    return ProfileNotifierProvider(userId);
  }

  @override
  ProfileNotifierProvider getProviderOverride(
    covariant ProfileNotifierProvider provider,
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
  String? get name => r'profileNotifierProvider';
}

/// See also [ProfileNotifier].
class ProfileNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<ProfileNotifier, ProfileState> {
  /// See also [ProfileNotifier].
  ProfileNotifierProvider(String userId)
    : this._internal(
        () => ProfileNotifier()..userId = userId,
        from: profileNotifierProvider,
        name: r'profileNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$profileNotifierHash,
        dependencies: ProfileNotifierFamily._dependencies,
        allTransitiveDependencies:
            ProfileNotifierFamily._allTransitiveDependencies,
        userId: userId,
      );

  ProfileNotifierProvider._internal(
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
  FutureOr<ProfileState> runNotifierBuild(covariant ProfileNotifier notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(ProfileNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ProfileNotifier, ProfileState>
  createElement() {
    return _ProfileNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileNotifierProvider && other.userId == userId;
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
mixin ProfileNotifierRef on AutoDisposeAsyncNotifierProviderRef<ProfileState> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProfileNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<ProfileNotifier, ProfileState>
    with ProfileNotifierRef {
  _ProfileNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileNotifierProvider).userId;
}

String _$userListNotifierHash() => r'3f739705117ebbf2de2a2c73d0edaa2f8b2f66c7';

abstract class _$UserListNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<UserProfileModel>> {
  late final UserListArgs args;

  FutureOr<List<UserProfileModel>> build(UserListArgs args);
}

/// See also [UserListNotifier].
@ProviderFor(UserListNotifier)
const userListNotifierProvider = UserListNotifierFamily();

/// See also [UserListNotifier].
class UserListNotifierFamily
    extends Family<AsyncValue<List<UserProfileModel>>> {
  /// See also [UserListNotifier].
  const UserListNotifierFamily();

  /// See also [UserListNotifier].
  UserListNotifierProvider call(UserListArgs args) {
    return UserListNotifierProvider(args);
  }

  @override
  UserListNotifierProvider getProviderOverride(
    covariant UserListNotifierProvider provider,
  ) {
    return call(provider.args);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userListNotifierProvider';
}

/// See also [UserListNotifier].
class UserListNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          UserListNotifier,
          List<UserProfileModel>
        > {
  /// See also [UserListNotifier].
  UserListNotifierProvider(UserListArgs args)
    : this._internal(
        () => UserListNotifier()..args = args,
        from: userListNotifierProvider,
        name: r'userListNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userListNotifierHash,
        dependencies: UserListNotifierFamily._dependencies,
        allTransitiveDependencies:
            UserListNotifierFamily._allTransitiveDependencies,
        args: args,
      );

  UserListNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.args,
  }) : super.internal();

  final UserListArgs args;

  @override
  FutureOr<List<UserProfileModel>> runNotifierBuild(
    covariant UserListNotifier notifier,
  ) {
    return notifier.build(args);
  }

  @override
  Override overrideWith(UserListNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserListNotifierProvider._internal(
        () => create()..args = args,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        args: args,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    UserListNotifier,
    List<UserProfileModel>
  >
  createElement() {
    return _UserListNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserListNotifierProvider && other.args == args;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, args.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserListNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<UserProfileModel>> {
  /// The parameter `args` of this provider.
  UserListArgs get args;
}

class _UserListNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          UserListNotifier,
          List<UserProfileModel>
        >
    with UserListNotifierRef {
  _UserListNotifierProviderElement(super.provider);

  @override
  UserListArgs get args => (origin as UserListNotifierProvider).args;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$musicRepositoryHash() => r'f9489a990ce738ed8e2aee876737fed09f271d83';

/// See also [musicRepository].
@ProviderFor(musicRepository)
final musicRepositoryProvider = Provider<MusicRepository>.internal(
  musicRepository,
  name: r'musicRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$musicRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MusicRepositoryRef = ProviderRef<MusicRepository>;
String _$musicSearchHash() => r'40ba74432f644551056c893dbb4b8d0a39012dde';

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

/// One page of the catalogue for [query] (empty: the most popular). Dropped
/// once the picker stops showing it; the server caches pages anyway.
///
/// Copied from [musicSearch].
@ProviderFor(musicSearch)
const musicSearchProvider = MusicSearchFamily();

/// One page of the catalogue for [query] (empty: the most popular). Dropped
/// once the picker stops showing it; the server caches pages anyway.
///
/// Copied from [musicSearch].
class MusicSearchFamily extends Family<AsyncValue<List<MusicTrack>>> {
  /// One page of the catalogue for [query] (empty: the most popular). Dropped
  /// once the picker stops showing it; the server caches pages anyway.
  ///
  /// Copied from [musicSearch].
  const MusicSearchFamily();

  /// One page of the catalogue for [query] (empty: the most popular). Dropped
  /// once the picker stops showing it; the server caches pages anyway.
  ///
  /// Copied from [musicSearch].
  MusicSearchProvider call(String query) {
    return MusicSearchProvider(query);
  }

  @override
  MusicSearchProvider getProviderOverride(
    covariant MusicSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'musicSearchProvider';
}

/// One page of the catalogue for [query] (empty: the most popular). Dropped
/// once the picker stops showing it; the server caches pages anyway.
///
/// Copied from [musicSearch].
class MusicSearchProvider extends AutoDisposeFutureProvider<List<MusicTrack>> {
  /// One page of the catalogue for [query] (empty: the most popular). Dropped
  /// once the picker stops showing it; the server caches pages anyway.
  ///
  /// Copied from [musicSearch].
  MusicSearchProvider(String query)
    : this._internal(
        (ref) => musicSearch(ref as MusicSearchRef, query),
        from: musicSearchProvider,
        name: r'musicSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$musicSearchHash,
        dependencies: MusicSearchFamily._dependencies,
        allTransitiveDependencies: MusicSearchFamily._allTransitiveDependencies,
        query: query,
      );

  MusicSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<MusicTrack>> Function(MusicSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MusicSearchProvider._internal(
        (ref) => create(ref as MusicSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<MusicTrack>> createElement() {
    return _MusicSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MusicSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MusicSearchRef on AutoDisposeFutureProviderRef<List<MusicTrack>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _MusicSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<MusicTrack>>
    with MusicSearchRef {
  _MusicSearchProviderElement(super.provider);

  @override
  String get query => (origin as MusicSearchProvider).query;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

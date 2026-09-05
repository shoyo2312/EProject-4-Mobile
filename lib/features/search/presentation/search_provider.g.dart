// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchRepositoryHash() => r'06705c06ac00d387ef88fdfabda4ee4aa94a6176';

/// See also [searchRepository].
@ProviderFor(searchRepository)
final searchRepositoryProvider = Provider<SearchRepository>.internal(
  searchRepository,
  name: r'searchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchRepositoryRef = ProviderRef<SearchRepository>;
String _$trendingVideosHash() => r'773be6ffb75d31f160661f57c99d40a3bd587211';

/// The public leaderboard, hydrated into playable videos.
///
/// Kept out of [SearchResults] on purpose: it is the same list for everyone
/// and needs no token, so it survives the query changing under it and is
/// fetched once per visit rather than once per keystroke.
///
/// Copied from [TrendingVideos].
@ProviderFor(TrendingVideos)
final trendingVideosProvider =
    AutoDisposeAsyncNotifierProvider<TrendingVideos, List<VideoModel>>.internal(
      TrendingVideos.new,
      name: r'trendingVideosProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$trendingVideosHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TrendingVideos = AutoDisposeAsyncNotifier<List<VideoModel>>;
String _$searchResultsHash() => r'5d819a36f64c069ea22617bf8167b5135719cc28';

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

abstract class _$SearchResults
    extends BuildlessAutoDisposeAsyncNotifier<List<VideoModel>> {
  late final String query;
  late final String hashtag;

  FutureOr<List<VideoModel>> build(String query, String hashtag);
}

/// One search, in relevance order, paged.
///
/// Keyed on both inputs so the results of a query survive switching to a
/// hashtag chip and back. [hashtag] is `''` rather than null so the family key
/// stays a plain pair of strings; the datasource drops empty values.
///
/// Search hits carry no `hlsUrl`, so every page is hydrated through
/// video-service before it is handed over (search doc 4). Ids that vanished
/// between indexing and now simply come back short — a page can therefore
/// hydrate to fewer rows than it named, or to none, without being the end.
///
/// Copied from [SearchResults].
@ProviderFor(SearchResults)
const searchResultsProvider = SearchResultsFamily();

/// One search, in relevance order, paged.
///
/// Keyed on both inputs so the results of a query survive switching to a
/// hashtag chip and back. [hashtag] is `''` rather than null so the family key
/// stays a plain pair of strings; the datasource drops empty values.
///
/// Search hits carry no `hlsUrl`, so every page is hydrated through
/// video-service before it is handed over (search doc 4). Ids that vanished
/// between indexing and now simply come back short — a page can therefore
/// hydrate to fewer rows than it named, or to none, without being the end.
///
/// Copied from [SearchResults].
class SearchResultsFamily extends Family<AsyncValue<List<VideoModel>>> {
  /// One search, in relevance order, paged.
  ///
  /// Keyed on both inputs so the results of a query survive switching to a
  /// hashtag chip and back. [hashtag] is `''` rather than null so the family key
  /// stays a plain pair of strings; the datasource drops empty values.
  ///
  /// Search hits carry no `hlsUrl`, so every page is hydrated through
  /// video-service before it is handed over (search doc 4). Ids that vanished
  /// between indexing and now simply come back short — a page can therefore
  /// hydrate to fewer rows than it named, or to none, without being the end.
  ///
  /// Copied from [SearchResults].
  const SearchResultsFamily();

  /// One search, in relevance order, paged.
  ///
  /// Keyed on both inputs so the results of a query survive switching to a
  /// hashtag chip and back. [hashtag] is `''` rather than null so the family key
  /// stays a plain pair of strings; the datasource drops empty values.
  ///
  /// Search hits carry no `hlsUrl`, so every page is hydrated through
  /// video-service before it is handed over (search doc 4). Ids that vanished
  /// between indexing and now simply come back short — a page can therefore
  /// hydrate to fewer rows than it named, or to none, without being the end.
  ///
  /// Copied from [SearchResults].
  SearchResultsProvider call(String query, String hashtag) {
    return SearchResultsProvider(query, hashtag);
  }

  @override
  SearchResultsProvider getProviderOverride(
    covariant SearchResultsProvider provider,
  ) {
    return call(provider.query, provider.hashtag);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchResultsProvider';
}

/// One search, in relevance order, paged.
///
/// Keyed on both inputs so the results of a query survive switching to a
/// hashtag chip and back. [hashtag] is `''` rather than null so the family key
/// stays a plain pair of strings; the datasource drops empty values.
///
/// Search hits carry no `hlsUrl`, so every page is hydrated through
/// video-service before it is handed over (search doc 4). Ids that vanished
/// between indexing and now simply come back short — a page can therefore
/// hydrate to fewer rows than it named, or to none, without being the end.
///
/// Copied from [SearchResults].
class SearchResultsProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<SearchResults, List<VideoModel>> {
  /// One search, in relevance order, paged.
  ///
  /// Keyed on both inputs so the results of a query survive switching to a
  /// hashtag chip and back. [hashtag] is `''` rather than null so the family key
  /// stays a plain pair of strings; the datasource drops empty values.
  ///
  /// Search hits carry no `hlsUrl`, so every page is hydrated through
  /// video-service before it is handed over (search doc 4). Ids that vanished
  /// between indexing and now simply come back short — a page can therefore
  /// hydrate to fewer rows than it named, or to none, without being the end.
  ///
  /// Copied from [SearchResults].
  SearchResultsProvider(String query, String hashtag)
    : this._internal(
        () => SearchResults()
          ..query = query
          ..hashtag = hashtag,
        from: searchResultsProvider,
        name: r'searchResultsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$searchResultsHash,
        dependencies: SearchResultsFamily._dependencies,
        allTransitiveDependencies:
            SearchResultsFamily._allTransitiveDependencies,
        query: query,
        hashtag: hashtag,
      );

  SearchResultsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.hashtag,
  }) : super.internal();

  final String query;
  final String hashtag;

  @override
  FutureOr<List<VideoModel>> runNotifierBuild(
    covariant SearchResults notifier,
  ) {
    return notifier.build(query, hashtag);
  }

  @override
  Override overrideWith(SearchResults Function() create) {
    return ProviderOverride(
      origin: this,
      override: SearchResultsProvider._internal(
        () => create()
          ..query = query
          ..hashtag = hashtag,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        hashtag: hashtag,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<SearchResults, List<VideoModel>>
  createElement() {
    return _SearchResultsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchResultsProvider &&
        other.query == query &&
        other.hashtag == hashtag;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, hashtag.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchResultsRef
    on AutoDisposeAsyncNotifierProviderRef<List<VideoModel>> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `hashtag` of this provider.
  String get hashtag;
}

class _SearchResultsProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<SearchResults, List<VideoModel>>
    with SearchResultsRef {
  _SearchResultsProviderElement(super.provider);

  @override
  String get query => (origin as SearchResultsProvider).query;
  @override
  String get hashtag => (origin as SearchResultsProvider).hashtag;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
